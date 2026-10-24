#!/usr/bin/env python3
"""Puentes locales contra el relay (tools/relay.py), para validar con el E2E.

Monta las dos patas que en el juego montara net.gd:
  - pata H (anfitrion): toma efimera que hace CREATE al relay y reenvia
    hacia el servidor ENet local (--host-target); el host de verdad ve un
    unico peer (esta toma), como veia al netem_proxy.
  - pata C (rival): toma a la escucha (--client-listen) a la que conecta el
    ENet del cliente; sus bytes viajan al relay como C y lo que llega se
    devuelve a la ultima direccion del cliente.

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
    args = ap.parse_args()

    relay_addr = parse_addr(args.relay)
    host_addr = parse_addr(args.host_target)

    state = {"code": None, "client": None, "joined": False}

    # pata H: misma toma para el relay y para el host (el host le responde a
    # esta direccion, como hacia con netem_proxy)
    s_h = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s_h.bind(("0.0.0.0", 0))
    # pata C: a la escucha para el ENet del cliente, y de aqui salen los C
    s_c = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s_c.bind(parse_addr(args.client_listen))

    def recv_h():
        while True:
            data, addr = s_h.recvfrom(65535)
            if addr == relay_addr:
                if data.startswith(MAGIC):
                    text = data.decode("ascii", "replace").split()
                    if len(text) >= 3 and text[1] == "CREATED":
                        state["code"] = text[2]
                        print("bench: sala %s creada; enviando JOIN desde la pata C"
                              % state["code"], flush=True)
                        s_c.sendto(MAGIC + b"JOIN " + text[2].encode(), relay_addr)
                    # PONG/otras respuestas: nada que hacer
                else:  # bytes de ENet del rival via relay: al host
                    s_h.sendto(data, host_addr)
            elif addr == host_addr:  # bytes de ENet del host: al relay como H
                code = state["code"]
                if code is not None:
                    s_h.sendto(MAGIC_D + code.encode() + b" H " + data, relay_addr)

    def recv_c():
        while True:
            data, addr = s_c.recvfrom(65535)
            if addr == relay_addr:
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
            else:  # bytes de ENet del cliente real: al relay como C
                state["client"] = addr
                code = state["code"]
                if code is not None:
                    s_c.sendto(MAGIC_D + code.encode() + b" C " + data, relay_addr)

    def pinger():
        while True:
            time.sleep(PING_EVERY)
            code = state["code"]
            if code is not None:
                s_h.sendto(MAGIC + b"PING " + code.encode(), relay_addr)
                if not state["joined"]:
                    s_c.sendto(MAGIC + b"JOIN " + code.encode(), relay_addr)

    threading.Thread(target=recv_h, daemon=True).start()
    threading.Thread(target=recv_c, daemon=True).start()
    threading.Thread(target=pinger, daemon=True).start()
    print("bench: relay=%s:%d  host-target=%s:%d  client-listen=%s:%d"
          % (relay_addr + host_addr + parse_addr(args.client_listen)), flush=True)
    s_h.sendto(MAGIC + b"CREATE", relay_addr)
    while True:
        time.sleep(3600)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
