#!/usr/bin/env python3
"""Puentes locales contra el relay (tools/relay.py), para validar con el E2E.

Monta las dos patas que en el juego montara net.gd:
  - pata H (anfitrion): toma que hace CREATE al relay y reenvia hacia el
    servidor ENet local (--host-target); el host de verdad ve un unico peer
    (esta toma), como veia al netem_proxy.
  - pata C (rival): toma a la escucha (--client-listen) a la que conecta el
    ENet del cliente; sus bytes viajan al relay como C y lo que llega se
    devuelve a la ultima direccion del cliente.

El relay puede ser local (uno lanzado a mano o el del propio E2E) o externo
-- el de produccion en fly.io--, y en ese caso la pata C abre una segunda
toma hacia internet porque una atada a 127.0.0.1 no puede salir (WinError
10051 / network unreachable).

Con esto el E2E completo (dos Godot jugando de verdad) atraviesa el relay
sin tocar una linea del juego: host -> host-target, cliente -> client-listen.

  python relay_bench.py --relay 127.0.0.1:24678 \
      --host-target 127.0.0.1:24676 --client-listen 127.0.0.1:24677

Solo stdlib. Ctrl+C para cortar.
"""
import argparse
import socket
import threading
import time

MAGIC = b"NRELAY1 "
MAGIC_D = b"NRELAY1D "
PING_EVERY = 10.0  # mantiene el mapping NAT y la sala fresca mientras se espera


def parse_addr(text):
    host, _, port = text.rpartition(":")
    return (host or "127.0.0.1", int(port))


def main():
    ap = argparse.ArgumentParser(description="Dos patas locales contra el relay")
    ap.add_argument("--relay", required=True, help="ip:puerto del relay")
    ap.add_argument("--host-target", required=True, help="ip:puerto del servidor ENet del host")
    ap.add_argument("--client-listen", required=True, help="ip:puerto donde conecta el cliente")
    ap.add_argument("--code", default=None,
                    help="codigo de sala existente: hace JOIN en vez de CREATE "
                         "(la pata H reenviara igual; util para pruebas mixtas)")
    args = ap.parse_args()

    relay_addr = parse_addr(args.relay)
    host_addr = parse_addr(args.host_target)
    relay_is_local = relay_addr[0] in ("127.0.0.1", "localhost")

    state = {"code": args.code, "client": None, "joined": False}

    # pata H: una sola toma para el relay y para el host (el host le responde
    # a esta direccion, como hacia con netem_proxy). Contra un relay LOCAL se
    # ata a 127.0.0.1 explicito: con 0.0.0.0 el kernel de los runners de
    # GitHub Actions elige una fuente que el receptor en 127.0.0.1 nunca ve
    # y el datagrama se pierde (probes A/B del relay-debug, 2026-10-24);
    # contra un relay externo (fly.io) se deja 0.0.0.0 para que el routing
    # elija la fuente normal de cada destino.
    s_h = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s_h.bind(("127.0.0.1", 0) if relay_is_local else ("0.0.0.0", 0))

    # pata C: toma a la escucha para el ENet del cliente. Si el relay es
    # externo, una toma aparte para hablar con el (la de escucha esta atada
    # a 127.0.0.1 y no puede salir a internet); si es local, la misma.
    s_c = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s_c.bind(parse_addr(args.client_listen))
    if relay_is_local:
        s_c_r = s_c
    else:
        s_c_r = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s_c_r.bind(("0.0.0.0", 0))

    def recv_h():
        # Windows materializa los ICMP de puerto inalcanzable (p.ej. el host
        # ya cerro) como ConnectionResetError en el recvfrom SIGUIENTE, aunque
        # la toma siga sana: tragarlo y seguir, o un hilo muerto parte la
        # partida a medias (host sin input, cliente sin snapshots)
        while True:
            try:
                data, addr = s_h.recvfrom(65535)
            except OSError:
                continue
            try:
                if addr == relay_addr:
                    if data.startswith(MAGIC):
                        text = data.decode("ascii", "replace").split()
                        if len(text) >= 3 and text[1] == "CREATED":
                            state["code"] = text[2]
                            print("bench: sala %s creada; enviando JOIN desde la pata C"
                                  % state["code"], flush=True)
                            s_c_r.sendto(MAGIC + b"JOIN " + text[2].encode(), relay_addr)
                        # PONG/otras respuestas: nada que hacer
                    else:  # bytes de ENet del rival via relay: al host
                        s_h.sendto(data, host_addr)
                elif addr == host_addr:  # bytes de ENet del host: al relay como H
                    code = state["code"]
                    if code is not None:
                        s_h.sendto(MAGIC_D + code.encode() + b" H " + data, relay_addr)
            except OSError:
                continue

    def recv_c():
        while True:
            try:
                data, addr = s_c.recvfrom(65535)
                if relay_is_local and addr == relay_addr:
                    relay_frame(data)
                else:
                    # el cliente real: guardar su direccion y viajar al relay como C
                    state["client"] = addr
                    code = state["code"]
                    if code is not None:
                        s_c_r.sendto(MAGIC_D + code.encode() + b" C " + data, relay_addr)
            except OSError:
                continue

    def relay_frame(data):
        """Frame del relay sobre la toma C: control o bytes para el cliente."""
        if data.startswith(MAGIC):
            text = data.decode("ascii", "replace").split()
            if len(text) >= 2 and text[1] == "JOINED":
                state["joined"] = True
                print("bench: rival dentro de la sala %s" % state["code"], flush=True)
            elif len(text) >= 2 and text[1] == "NOROOM":
                print("bench: NOROOM (%s) — ¿caduco la sala?" % state["code"], flush=True)
        else:  # bytes de ENet del rival-via-host: al cliente real
            client = state["client"]
            if client is not None:
                s_c.sendto(data, client)

    def recv_c_r():
        # solo existe con relay externo: lo que llega del relay por la toma C
        while True:
            try:
                data, addr = s_c_r.recvfrom(65535)
                if addr == relay_addr:
                    relay_frame(data)
            except OSError:
                continue

    def pinger():
        while True:
            time.sleep(PING_EVERY)
            code = state["code"]
            if code is not None:
                try:
                    s_h.sendto(MAGIC + b"PING " + code.encode(), relay_addr)
                    if not state["joined"]:
                        s_c_r.sendto(MAGIC + b"JOIN " + code.encode(), relay_addr)
                except OSError:
                    pass

    threading.Thread(target=recv_h, daemon=True).start()
    threading.Thread(target=recv_c, daemon=True).start()
    if not relay_is_local:
        threading.Thread(target=recv_c_r, daemon=True).start()
    threading.Thread(target=pinger, daemon=True).start()
    print("bench: relay=%s:%d  host-target=%s:%d  client-listen=%s:%d%s"
          % (relay_addr + host_addr + parse_addr(args.client_listen)
             + ("" if relay_is_local else "  (relay externo)",)), flush=True)
    if state["code"] is not None:
        print("bench: uniendome a la sala %s desde la pata C" % state["code"], flush=True)
        s_c_r.sendto(MAGIC + b"JOIN " + state["code"].encode(), relay_addr)
    else:
        s_h.sendto(MAGIC + b"CREATE", relay_addr)
    while True:
        time.sleep(3600)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
