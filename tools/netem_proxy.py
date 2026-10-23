#!/usr/bin/env python3
"""Proxy UDP con latencia/pérdida/jitter inyectadas, para el E2E online.

El E2E normal (tools/online_e2e.sh) corre en localhost: latencia ~0 y sin
pérdida, nada parecido a Internet. Este proxy se cuela entre cliente y host
y añade retraso/pérdida POR DIRECCIÓN a cada paquete, con un solo socket
hacia el host (el host ve un único peer, como en una partida real).

Uso:
  python netem_proxy.py --listen 127.0.0.1:24600 --target 127.0.0.1:24575 \
      --delay 40 --jitter 10 --loss 0.5

--delay es MILISEGUNDOS POR DIRECCIÓN (40 y 40 = ~80 ms de ida y vuelta).
Solo stdlib (socket/threading/queue/random/time): corre en Windows, WSL y
CI sin instalar nada.
"""
import argparse
import queue
import random
import socket
import threading
import time


def parse_addr(text):
	host, _, port = text.rpartition(":")
	return (host or "127.0.0.1", int(port))


def main():
	ap = argparse.ArgumentParser(description="Proxy UDP con red mala inyectada")
	ap.add_argument("--listen", required=True, help="ip:puerto donde conecta el cliente")
	ap.add_argument("--target", required=True, help="ip:puerto real del host")
	ap.add_argument("--delay", type=float, default=0.0, help="ms por dirección")
	ap.add_argument("--jitter", type=float, default=0.0, help="± ms por dirección")
	ap.add_argument("--loss", type=float, default=0.0, help="% de paquetes tirados")
	ap.add_argument("--seed", type=int, default=None, help="semilla para reproducir")
	args = ap.parse_args()
	if args.seed is not None:
		random.seed(args.seed)

	listen_addr = parse_addr(args.listen)
	target_addr = parse_addr(args.target)

	ls = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
	ls.bind(listen_addr)
	ts = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
	# en Windows, recvfrom sobre un socket SIN atar lanza WinError 10022:
	# atamos a un puerto efímero (el host verá ese origen como su único peer)
	ts.bind(("0.0.0.0", 0))

	client_addr = [None]
	scheduled = queue.Queue()  # (enviar_en, socket, datos, destino)

	def later(sock, data, addr):
		d = max(0.0, args.delay + random.uniform(-args.jitter, args.jitter)) / 1000.0
		scheduled.put((time.monotonic() + d, sock, data, addr))

	def pump():
		while True:
			t, sock, data, addr = scheduled.get()
			wait = t - time.monotonic()
			if wait > 0:
				time.sleep(wait)
			try:
				sock.sendto(data, addr)
			except OSError:
				pass

	def drop():
		return random.random() * 100.0 < args.loss

	def recv_client():
		while True:
			data, addr = ls.recvfrom(4096)
			client_addr[0] = addr
			if not drop():
				later(ts, data, target_addr)

	def recv_host():
		while True:
			data, _ = ts.recvfrom(4096)
			ca = client_addr[0]
			if ca is not None and not drop():
				later(ls, data, ca)

	threading.Thread(target=pump, daemon=True).start()
	threading.Thread(target=recv_client, daemon=True).start()
	print("netem: %s -> %s  delay=%.0fms±%.0f  loss=%.1f%%  (Ctrl+C para cortar)"
	      % (listen_addr, target_addr, args.delay, args.jitter, args.loss), flush=True)
	recv_host()


if __name__ == "__main__":
	try:
		main()
	except KeyboardInterrupt:
		pass
