#!/usr/bin/env python3
"""Relay UDP para el online de Nidhogg (el pendiente de hosting).

Un solo socket UDP (24565 por defecto) y salas de dos puntas: el anfitrion
y el rival conectan AMBOS hacia fuera al relay (nadie abre puertos) y este
reenvia los bytes crudos de ENet de uno al otro. Es netem_proxy.py sin la
red mala y con muchas salas a la vez.

Protocolo (los frames de control empiezan por "NRELAY1 ", que un datagrama
ENet jamas empezara; los de datos, por "NRELAY1D "):
  anfitrion -> relay:  "NRELAY1 CREATE"          -> "NRELAY1 CREATED <code>"
                       "NRELAY1 PING <code>"     -> "NRELAY1 PONG <code>"
                       "NRELAY1 CLOSE <code>"    -> "NRELAY1 PONG <code>" + sala fuera
  rival -> relay:      "NRELAY1 JOIN <code>"     -> "NRELAY1 JOINED <code>"
                                                     | "NRELAY1 NOROOM <code>"
  datos (ambos):       "NRELAY1D <code> <H|C> <bytes crudos de ENet>"
  relay -> puntas:     los bytes crudos de ENet, tal cual.

El enrutado es por CODIGO+ROL, no por direccion: cada frame de datos
actualiza la direccion de esa punta (NAT que renueva el mapping, proxy que
enmascara IPs mientras los puertos de origen difieran...). ENet lleva
checksum propio: si el relay entregara algo raro, ENet lo tira y
retransmite; por eso no hace falta nada mas. El "autenticador" de una sala
es el codigo de 4 letras (1v1 entre amigos; a un intruso le haria falta
adivinarlo y esnifarlo).

Solo stdlib (socket/random/time): python 3.8+ sin dependencias, igual en
VPS, contenedor Fly.io, WSL o CI.

Uso:
  python relay.py                  # 0.0.0.0:24565
  python relay.py --port 24566
  PORT=24566 python relay.py       # (Docker/fly)
"""
import argparse
import os
import random
import socket
import time

MAGIC = b"NRELAY1 "    # frames de control
MAGIC_D = b"NRELAY1D "  # frames de datos (payload binario detras)
ALPHABET = "23456789ABCDEFGHJKMNPQRSTUVWXYZ"  # sin 0/O 1/I/L: legible al telefono
CODE_LEN = 4
MAX_ROOMS = 256
ROOM_TTL = 2 * 3600.0  # sala muerta de puro antigua (sin trafico, seg)
OPEN_TTL = 10 * 60.0   # sala creada a la que nunca llega rival (seg)


def now() -> float:
    return time.time()


def new_code(used) -> str:
    rng = random.SystemRandom()
    for _ in range(200):
        code = "".join(rng.choice(ALPHABET) for _ in range(CODE_LEN))
        if code not in used:
            return code
    raise RuntimeError("sin codigos libres (¿256 salas?)")


def main() -> None:
    ap = argparse.ArgumentParser(description="Relay UDP de salas 1v1 para Nidhogg")
    ap.add_argument("--port", type=int, default=int(os.environ.get("PORT", "24565")),
                    help="puerto UDP a la escucha (default 24565, o $PORT)")
    ap.add_argument("--bind", default="0.0.0.0", help="IP a la escucha (default 0.0.0.0)")
    args = ap.parse_args()

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((args.bind, args.port))
    sock.settimeout(5.0)  # el bucle caduca y aprovecha para barrer salas muertas

    rooms = {}  # code -> {"addr_h": ..., "addr_c": ..., "last": ...}
    rng = random.SystemRandom()

    def reply(text: str, addr) -> None:
        sock.sendto(MAGIC + text.encode("ascii"), addr)

    def sweep() -> None:
        t = now()
        for code in [c for c, r in rooms.items()
                     if t - r["last"] > ROOM_TTL
                     or (r["addr_c"] is None and t - r["last"] > OPEN_TTL)]:
            del rooms[code]
            print("relay: sala %s caducada (%d vivas)" % (code, len(rooms)), flush=True)

    print("relay: escuchando udp %s:%d  (Ctrl+C para cortar)" % (args.bind, args.port), flush=True)
    while True:
        try:
            data, addr = sock.recvfrom(65535)
        except socket.timeout:
            sweep()
            continue
        except KeyboardInterrupt:
            print("relay: cierre", flush=True)
            return

        # ---- frames de datos: "NRELAY1D <code> <H|C> <bytes ENet>" ----------
        if data.startswith(MAGIC_D):
            try:
                _, code_b, role_b, payload = data.split(b" ", 3)
                code = code_b.decode("ascii")
            except ValueError:
                continue  # frame truncado: fuera
            room = rooms.get(code)
            if room is None:
                reply("NOROOM %s" % code, addr)
                continue
            room["last"] = now()
            # la punta se reaprende de cada frame: NAT/proxy pueden moverla
            peer = None
            if role_b == b"H":
                room["addr_h"] = addr
                peer = room["addr_c"]
            elif role_b == b"C":
                room["addr_c"] = addr
                peer = room["addr_h"]
            if peer is not None:
                sock.sendto(payload, peer)
            continue

        # ---- frames de control: "NRELAY1 <CMD> [code]" ----------------------
        if not data.startswith(MAGIC):
            continue  # ENet directo sin codigo o ruido: ignorar
        try:
            parts = data.decode("ascii").split()
        except UnicodeDecodeError:
            continue
        cmd = parts[1] if len(parts) > 1 else ""
        code = parts[2] if len(parts) > 2 else ""

        if cmd == "CREATE":
            if len(rooms) >= MAX_ROOMS:
                # antes de rechazar: recicla las caducadas
                sweep()
                if len(rooms) >= MAX_ROOMS:
                    reply("FULL", addr)
                    continue
            code = new_code(rooms)
            rooms[code] = {"addr_h": addr, "addr_c": None, "last": now()}
            reply("CREATED %s" % code, addr)
            print("relay: sala %s creada por %s:%d" % (code, addr[0], addr[1]), flush=True)

        elif cmd == "JOIN":
            room = rooms.get(code)
            if room is None:
                reply("NOROOM %s" % code, addr)
            else:
                room["addr_c"] = addr
                room["last"] = now()
                reply("JOINED %s" % code, addr)
                print("relay: %s:%d entro en la sala %s" % (addr[0], addr[1], code), flush=True)

        elif cmd == "PING":
            room = rooms.get(code)
            if room is not None:
                room["last"] = now()
            reply("PONG %s" % code, addr)

        elif cmd == "CLOSE":
            if code in rooms and rooms[code]["addr_h"] == addr:
                del rooms[code]
                print("relay: sala %s cerrada por el anfitrion (%d vivas)"
                      % (code, len(rooms)), flush=True)
            reply("PONG %s" % code, addr)

        else:
            reply("WHAT", addr)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
