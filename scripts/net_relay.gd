extends Node
## Puente relay dentro del juego (online v3): lo que relay_bench.py hace en
## los E2E, en GDScript como hijo del autoload Net. Nadie abre puertos:
## anfitrion y rival conectan AMBOS hacia fuera al relay (ver
## docs/online-netcode.md § Relay para el protocolo y su porque).
##
## Lados:
##   H (anfitrion): Net.host() deja el servidor ENet en 127.0.0.1:server_port
##     y este nodo hace de tuberia entre ese servidor y el relay; el servidor
##     ENet ve al puente como su unico peer (como veia al netem_proxy).
##   C (rival): escucha en 127.0.0.1:c_listen_port para el ENet del propio
##     juego (Net.join apunta ahi) y traduce hacia el relay.
## Frames: control "NRELAY1 ..." / datos "NRELAY1D <codigo> <H|C> <bytes>";
## del relay llegan control o bytes crudos de ENet (sin prefijo).
##
## ARQUITECTURA (leccion de la v3 2/3): cada socket vive en SU PROPIO HILO
## con drenaje continuo (~1 ms), igual que relay_bench.py — que SI atravesaba
## fly con latencia — y no cuantizado por fotograma: un drenaje por frame
## rompia el dialogo ENet. Reglas de hilo: un socket solo se toca desde su
## hilo (creacion incluida); el estado compartido va detras de un mutex; las
## senales, call_deferred.
##
## Binds por el quirk de los runners de GitHub (relay-debug 2026-10): quien
## envia a loopback se ata a 127.0.0.1 si el relay es local; la escucha del
## lado C va en 0.0.0.0 (el patron emisor-0.0.0.0 -> receptor-0.0.0.0 es el
## del E2E directo, verde en CI desde siempre).

const MAGIC_C := "NRELAY1 "
const MAGIC_D := "NRELAY1D "
const PING_EVERY := 10.0  # mantiene el mapping NAT y la sala fresca

signal room_ready(code: String)  # H: la sala existe en el relay (y su codigo)
signal join_ok                    # C: sala encontrada — a conectar el ENet
signal failed(reason: String)     # algo insalvable (p.ej. NORROOM sin entrar)

var relay_ip := "127.0.0.1"
var relay_port := 24565
var is_host_side := false
var server_port := 0     # H: donde escucha el servidor ENet local
var c_listen_port := 0   # C: donde conectara el ENet del propio juego
var code := ""
var joined := false

var _sock: PacketPeerUDP = null    # H: relay+host local / C: escucha del ENet
var _sock_r: PacketPeerUDP = null  # C: hacia el relay (en H no existe)
var _threads: Array[Thread] = []
var _mutex := Mutex.new()
var _client_ip := ""              # C: ultima direccion vista del ENet local
var _client_port := 0
var _alive := true
var _last_rx_msec := 0   # ultimo paquete del ENet local: watchdog del ayudante
var _to_local: Array[PackedByteArray] = []  # C: relay→hilo local (ver abajo)


## ms desde el ultimo paquete del ENet local: el proceso ayudante muere de
## hambre con esto si el juego lo abandona (arranca en setup, asi que un
## ayudante al que nadie conecta nunca tambien se va solo).
func idle_msec() -> int:
	return Time.get_ticks_msec() - _last_rx_msec


func _touch_watchdog() -> void:
	_last_rx_msec = Time.get_ticks_msec()

# contadores de diagnostico (los tests los imprimen en su veredicto)
var stat_data_in := 0    # bytes crudos recibidos DEL relay
var stat_data_out := 0   # bytes crudos enviados AL relay
var stat_local_in := 0   # paquetes del ENet local recibidos
var stat_ctrl_in := 0    # frames de control del relay
var stat_put_ok := 0     # put_packet aceptados (cualquier camino)
var stat_put_err := 0    # put_packet rechazados
var _dump_left := 0      # RELAY_DUMP=N: volcar en hex los primeros N datos


func _dump(tag: String, pkt: PackedByteArray) -> void:
	if _dump_left <= 0:
		return
	_dump_left -= 1
	var hex := ""
	for i in mini(32, pkt.size()):
		hex += "%02x " % pkt[i]
	print("RELAY_DUMP %s %dB: %s" % [tag, pkt.size(), hex])


func stats() -> String:
	return "relay_bridge in=%d out=%d local_in=%d ctrl_in=%d put_ok=%d put_err=%d" % [
		stat_data_in, stat_data_out, stat_local_in, stat_ctrl_in, stat_put_ok, stat_put_err]


static func _is_loopback(ip: String) -> bool:
	return ip == "127.0.0.1" or ip == "localhost"


func setup_host(relay_addr: String, srv_port: int) -> Error:
	_dump_left = int(OS.get_environment("RELAY_DUMP"))
	is_host_side = true
	server_port = srv_port
	_parse_relay(relay_addr)
	_sock = PacketPeerUDP.new()
	var err := _sock.bind(0, "127.0.0.1" if _is_loopback(relay_ip) else "*")
	if err != OK:
		return err
	_start_thread(_host_loop)
	_send_ctrl("CREATE")
	return OK


func setup_client(relay_addr: String, room_code: String, listen_port: int) -> Error:
	_dump_left = int(OS.get_environment("RELAY_DUMP"))
	is_host_side = false
	_mutex.lock()
	code = room_code
	_mutex.unlock()
	c_listen_port = listen_port
	_parse_relay(relay_addr)
	_sock = PacketPeerUDP.new()
	# 127.0.0.1 explicito (como la pata C de relay_bench.py, que SI funciona):
	# con "*" (dual-stack de Godot) el dialogo handshake del ENet cliente por
	# loopback se desincroniza y ambas partes se ignoran (v3 2/3: tormentas de
	# retransmision espejadas). El emisor-0.0.0.0 -> receptor-127.0.0.1 solo
	# falla en los runners de GH, y el E2E --relay-game de CI usara relay
	# local... asi que si CI protesta, se reintenta con "*".
	if _sock.bind(listen_port, "127.0.0.1") != OK:
		if _sock.bind(listen_port, "*") != OK:
			return ERR_CANT_CREATE
	_sock_r = PacketPeerUDP.new()
	var err := _sock_r.bind(0, "127.0.0.1" if _is_loopback(relay_ip) else "*")
	if err != OK:
		return err
	_start_thread(_client_local_loop)
	_start_thread(_client_relay_loop)
	_touch_watchdog()  # el watchdog del ayudante cuenta desde aqui
	_send_ctrl("JOIN " + room_code)
	return OK


func close() -> void:
	_mutex.lock()
	_alive = false
	_mutex.unlock()
	for t in _threads:
		t.wait_to_finish()
	_threads.clear()


func _parse_relay(addr: String) -> void:
	if addr.contains(":"):
		var parts := addr.rsplit(":", true, 1)
		relay_ip = parts[0] if not parts[0].is_empty() else "127.0.0.1"
		relay_port = int(parts[1])
	else:
		relay_ip = addr if not addr.is_empty() else "127.0.0.1"
		relay_port = 24565


func _start_thread(fn: Callable) -> void:
	var t := Thread.new()
	t.start(fn)
	_threads.append(t)


func _alive_() -> bool:
	_mutex.lock()
	var a := _alive
	_mutex.unlock()
	return a


## ————— lado H: un hilo, una toma para todo (relay y host ENet local) —————

func _host_loop() -> void:
	var last_ping := Time.get_ticks_msec()
	while _alive_():
		OS.delay_usec(1000)  # ~1 ms de granularidad: reenvio casi inmediato
		var now := Time.get_ticks_msec()
		if now - last_ping >= int(PING_EVERY * 1000.0):
			last_ping = now
			_mutex.lock()
			var c := code
			_mutex.unlock()
			if not c.is_empty():
				_send_ctrl("PING %s" % c)
			else:
				_send_ctrl("CREATE")  # reintento: el relay no respondio aun
		while _alive_() and _sock.get_available_packet_count() > 0:
			var pkt := _sock.get_packet()
			var from_relay := _sock.get_packet_ip() == relay_ip \
					and _sock.get_packet_port() == relay_port
			if from_relay:
				_on_relay_frame(pkt, _sock)
			else:
				# bytes del servidor ENet local: al relay como H
				_mutex.lock()
				stat_local_in += 1
				_mutex.unlock()
				_send_data(pkt)
	# al morir: cerrar la sala si la teniamos
	_mutex.lock()
	var c2 := code
	_mutex.unlock()
	if not c2.is_empty():
		_send_ctrl("CLOSE %s" % c2)


## ————— lado C: un hilo por toma (escucha local / relay) —————

func _client_local_loop() -> void:
	# el ENet del propio juego entra por aqui; los datos del rival le
	# llegan por la cola _to_local (los mete el hilo del relay) y SALEN por
	# ESTA toma: el ENet cliente exige que las respuestas vengan del mismo
	# puerto al que envio (la escucha), no del socket del relay
	while _alive_():
		OS.delay_usec(1000)
		while _alive_() and _sock.get_available_packet_count() > 0:
			var pkt := _sock.get_packet()
			# SOLO el trafico del ENet local alimenta el watchdog: los PONG
			# del pinger no deben mantener vivo a un ayudante huerfano
			_touch_watchdog()
			_mutex.lock()
			_client_ip = _sock.get_packet_ip()
			_client_port = _sock.get_packet_port()
			stat_local_in += 1
			_mutex.unlock()
			_send_data(pkt)
		_mutex.lock()
		var pending := _to_local
		_to_local = []
		_mutex.unlock()
		for p in pending:
			_mutex.lock()
			var cip := _client_ip
			var cpt := _client_port
			_mutex.unlock()
			if cip.is_empty():
				continue
			_sock.set_dest_address(cip, cpt)
			if _sock.put_packet(p) == OK:
				stat_put_ok += 1
			else:
				stat_put_err += 1


func _client_relay_loop() -> void:
	# el relay por aqui; tambien lleva el PING/re-JOIN de esta pata
	var last_ping := Time.get_ticks_msec()
	while _alive_():
		OS.delay_usec(1000)
		var now := Time.get_ticks_msec()
		if now - last_ping >= int(PING_EVERY * 1000.0):
			last_ping = now
			_mutex.lock()
			var c := code
			var j := joined
			_mutex.unlock()
			if not c.is_empty():
				_send_ctrl("PING %s" % c)
				if not j:
					_send_ctrl("JOIN " + c)
		while _alive_() and _sock_r.get_available_packet_count() > 0:
			var pkt := _sock_r.get_packet()
			if _sock_r.get_packet_ip() == relay_ip and _sock_r.get_packet_port() == relay_port:
				_on_relay_frame(pkt, _sock_r)


# ————— envios (llamados desde el hilo dueno de la toma) —————

func _rsock() -> PacketPeerUDP:
	return _sock_r if _sock_r != null else _sock


func _send_ctrl(text: String) -> void:
	var s := _rsock()
	s.set_dest_address(relay_ip, relay_port)
	if s.put_packet((MAGIC_C + text).to_ascii_buffer()) == OK:
		stat_put_ok += 1
	else:
		stat_put_err += 1


func _send_data(payload: PackedByteArray) -> void:
	_mutex.lock()
	var c := code
	_mutex.unlock()
	if c.is_empty():
		return
	var head := ("%s%s %s " % [MAGIC_D, c, "H" if is_host_side else "C"]).to_ascii_buffer()
	head.append_array(payload)
	stat_data_out += head.size()
	_dump("out-%s" % ("H" if is_host_side else "C"), payload)
	var s := _rsock()
	s.set_dest_address(relay_ip, relay_port)
	if s.put_packet(head) == OK:
		stat_put_ok += 1
	else:
		stat_put_err += 1


func _on_relay_frame(pkt: PackedByteArray, from: PacketPeerUDP) -> void:
	if pkt.size() >= 8 and pkt.slice(0, 8) == MAGIC_C.to_ascii_buffer():
		_mutex.lock()
		stat_ctrl_in += 1
		_mutex.unlock()
		var words := pkt.get_string_from_ascii().split(" ")
		match words[1] if words.size() > 1 else "":
			"CREATED":
				_mutex.lock()
				code = words[2]
				_mutex.unlock()
				room_ready.emit.call_deferred(words[2])
			"JOINED":
				_mutex.lock()
				joined = true
				_mutex.unlock()
				join_ok.emit.call_deferred()
			"NOROOM":
				var was_joined := false
				_mutex.lock()
				was_joined = joined
				_mutex.unlock()
				if is_host_side:
					_mutex.lock()
					code = ""  # recrear: el CREATED nuevo re-emite room_ready
					_mutex.unlock()
					_send_ctrl("CREATE")
				elif not was_joined:
					failed.emit.call_deferred("NOROOM")
				# si YA estabamos dentro: el anfitrion cerro la sala; el
				# enlace ENet lo notifica por su via (server_lost/peer_left)
			_:
				pass  # PONG y demas: nada
	else:
		# bytes crudos de ENet del rival → al ENet local (desde SU hilo)
		_dump("in ", pkt)
		_mutex.lock()
		stat_data_in += pkt.size()
		_mutex.unlock()
		if is_host_side:
			# H: la misma toma habla con el relay y con el ENet local
			from.set_dest_address("127.0.0.1", server_port)
			if from.put_packet(pkt) == OK:
				stat_put_ok += 1
			else:
				stat_put_err += 1
		else:
			# C: debe salir por la ESCUCHA (el ENet cliente espera respuestas
			# del puerto al que envio); esa toma es de otro hilo → cola
			_mutex.lock()
			_to_local.append(pkt)
			_mutex.unlock()
