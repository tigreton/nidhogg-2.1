extends Node
## Autoload Net: ciclo de vida de la conexión ENet para el 1v1 online.
## Host = servidor + P1 (autoridad de la simulación). Cliente = P2.
## El flujo de escenas lo llevan las señales: la pantalla de título crea/unre
## y salta a la partida cuando hay enlace; game.gd hace el handshake fino
## (net_ready) antes de arrancar la primera ronda.

const NET_RELAY_SCRIPT := preload("res://scripts/net_relay.gd")

enum Role { OFFLINE, HOST, CLIENT }

const DEFAULT_PORT := 24565
## Relay publico del juego (fly.io, docs/online-netcode.md § Relay): jugar
## por Internet sin abrir puertos ni dar IPs — solo un codigo de 4 letras.
const RELAY_DEFAULT := "188.93.145.30:24565"
const RELAY_CLIENT_PORT := DEFAULT_PORT + 1  # escucha local del puente rival

var role := Role.OFFLINE
var remote_id := 0        # id del rival (host: id del cliente; cliente: 1)
var client_ready := false # el cliente ya montó su escena de juego
var relay_node: Node = null  # scripts/net_relay.gd (modo relay)
var relay_code := ""         # host: codigo de sala asignado por el relay

# NAT traversal casero (online v2): resultado del intento UPnP al hacer host
var _upnp_dev: UPNP = null
var _upnp_port := 0
var public_ip := ""      # IP pública del router (vía UPnP; "" si no se supo)
var upnp_mapped := false # true si el router abrió el puerto él solo (IGD)

signal peer_joined
signal peer_left
signal connected_ok
signal connect_failed
signal server_lost
signal client_became_ready
signal relay_room_ready(code: String)  # host: sala creada, codigo a mostrar
signal relay_join_ok                   # cliente: sala encontrada
signal relay_failed(reason: String)    # relay: fallo (p.ej. "NOROOM")


func _ready() -> void:
	# el multiplayer API es global: conectamos una sola vez y discrimina role
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(func() -> void: connected_ok.emit())
	multiplayer.connection_failed.connect(_on_conn_failed)
	multiplayer.server_disconnected.connect(func() -> void: server_lost.emit())


func _on_conn_failed() -> void:
	connect_failed.emit()
	# modo relay: el ENet ha fallado contra el puente local — casi siempre el
	# ayudante seguia booteando; reintentar SIN matarlo (el puerto es suyo)
	if _relay_helper_pid > 0:
		get_tree().create_timer(1.0).timeout.connect(_relay_join_tick)


func active() -> bool:
	return role != Role.OFFLINE


func is_host() -> bool:
	return role == Role.HOST


func is_client() -> bool:
	return role == Role.CLIENT


func host(port := DEFAULT_PORT, use_upnp := true) -> Error:
	if multiplayer == null:
		return ERR_UNAVAILABLE   # API aún no montada (arranque exótico): reintenta
	var p := ENetMultiplayerPeer.new()
	var err := p.create_server(port, 1)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = p
	role = Role.HOST
	remote_id = 0
	client_ready = false
	if use_upnp:
		_try_upnp(port)
	return OK


func _try_upnp(port: int) -> void:
	# Intenta mapear el puerto en el router vía UPnP/IGD para jugar por
	# Internet sin abrir puertos a mano. Todo es silencioso y opcional: sin
	# UPnP se juega igual por LAN o con port-forwarding manual
	# (docs/online-netcode.md § jugar por Internet). En headless (tests/CI)
	# ni lo intenta: no hay router que descubrir y el multicast solo
	# añadiría segundos de arranque al E2E.
	if DisplayServer.get_name() == "headless":
		return
	var u := UPNP.new()
	if u.discover(2000, 2, "InternetGatewayDevice") <= 0:
		return
	var ext := u.query_external_address()
	if not ext.is_empty() and ext != "0.0.0.0":
		public_ip = ext
	if u.add_port_mapping(port, port, "nidhogg-duel", "UDP") == OK:
		upnp_mapped = true
		_upnp_dev = u
		_upnp_port = port


func join(ip: String, port := DEFAULT_PORT) -> Error:
	if multiplayer == null:
		return ERR_UNAVAILABLE   # API aún no montada (arranque exótico): reintenta
	var p := ENetMultiplayerPeer.new()
	var err := p.create_client(ip, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = p
	role = Role.CLIENT
	remote_id = 1
	return OK


# =============================================================================
# MODO RELAY (online v3): nadie abre puertos; anfitrion y rival conectan
# ambos hacia fuera al relay y el puente (scripts/net_relay.gd) traduce.
# =============================================================================

## Anfitrion: servidor ENet local (sin UPnP, no hace falta) + sala en el
## relay. El codigo llega asincrono por la senal relay_room_ready (y queda
## en relay_code).
func host_relay(port := DEFAULT_PORT, relay_addr := RELAY_DEFAULT) -> Error:
	var err := host(port, false)
	if err != OK:
		return err
	return _spawn_relay().setup_host(relay_addr, port)


## Rival: busca la sala por codigo. El puente C va en un PROCESO APARTE (el
## propio ejecutable re-lanzado con --headless --relay-helper, ver title.gd):
## el ENet cliente y su puente en el mismo proceso rompen el dialogo con
## latencia en el relay (v3 2/3: tormentas de retransmision con el servidor
## sordo; el mismo net_relay.gd en proceso aparte, verde a 80 ms y en fly).
## Cuando el ayudante ha tenido tiempo de entrar en la sala (~1,5 s), se
## conecta el ENet como en una partida normal (reintenta solo si llega tarde).
func join_relay(room_code: String, relay_addr := RELAY_DEFAULT) -> Error:
	room_code = room_code.to_upper()
	if room_code.length() != 4:
		return ERR_INVALID_PARAMETER
	# el ayudante es el juego entero re-lanzado: tarda unos segundos en
	# bootear — se reusa entre reintentos y muere solo si este proceso muere
	if _relay_helper_pid <= 0 or not OS.is_process_running(_relay_helper_pid):
		var args: Array[String] = []
		if not OS.has_feature("template"):
			# binario Godot pelado (dev/E2E): hace falta el --path del proyecto;
			# en un juego exportado el exe lleva el proyecto dentro y sobra
			args.append("--path")
			args.append(ProjectSettings.globalize_path("res://"))
		args.append("--headless")
		args.append("--")
		args.append_array(["--relay-helper", "--code=" + room_code,
				"--relay=" + relay_addr, "--listen=%d" % RELAY_CLIENT_PORT])
		_relay_helper_pid = OS.create_process(OS.get_executable_path(), args)
		if _relay_helper_pid < 0:
			return ERR_CANT_CREATE
		_relay_join_tries = 0
	get_tree().create_timer(1.5).timeout.connect(_relay_join_tick)
	return OK


## Sondeo del join relay para scripts SceneTree (test/online_client.gd): los
## SceneTreeTimer no cuentan bajo un MainLoop script, asi que el test llama
## aqui cada ~2 s; en el juego normal el timer de arriba hace lo mismo.
func relay_join_poll() -> void:
	_relay_join_tick()


var _relay_helper_pid := 0
var _relay_join_tries := 0


func _relay_join_tick() -> void:
	# conectar el ENet contra el puente local, reintentando mientras el
	# ayudante bootea (sin matarlo: el puente y su puerto siguen suyos)
	if _relay_helper_pid <= 0:
		return   # no hay ayudante (modo no-relay)
	# OJO: sin peer real, multiplayer.multiplayer_peer es un OfflineMultiplayerPeer
	# que dice CONNECTED — solo un join() de verdad pone role=CLIENT
	if role == Role.CLIENT and multiplayer.multiplayer_peer != null \
			and multiplayer.multiplayer_peer.get_connection_status() in \
			[MultiplayerPeer.CONNECTION_CONNECTING, MultiplayerPeer.CONNECTION_CONNECTED]:
		return   # ya conectado o conectando
	_relay_join_tries += 1
	if _relay_join_tries == 1:
		relay_join_ok.emit()   # el titulo pasa a "conectando..."
	if _relay_join_tries > 20:
		relay_failed.emit("helper")
		return
	var err := join("127.0.0.1", RELAY_CLIENT_PORT)
	if err != OK:
		get_tree().create_timer(2.0).timeout.connect(_relay_join_tick)


func _spawn_relay() -> Node:
	relay_node = NET_RELAY_SCRIPT.new()
	add_child(relay_node)
	relay_node.room_ready.connect(func(c: String) -> void:
		relay_code = c
		relay_room_ready.emit(c))
	relay_node.join_ok.connect(func() -> void:
		relay_join_ok.emit()
		# el relay ya conoce nuestra punta: a conectar como en una partida
		# normal, solo que contra el puente local
		join("127.0.0.1", RELAY_CLIENT_PORT))
	relay_node.failed.connect(func(reason: String) -> void:
		relay_failed.emit(reason))
	return relay_node


func shutdown() -> void:
	if _relay_helper_pid > 0:
		OS.kill(_relay_helper_pid)
		_relay_helper_pid = 0
	if relay_node != null:
		relay_node.close()
		relay_node.queue_free()
		relay_node = null
	relay_code = ""
	# cierra el mapeo UPnP si lo abrimos (el router lo caduca solo, pero
	# ser educados cuesta una línea)
	if _upnp_dev != null:
		_upnp_dev.delete_port_mapping(_upnp_port, "UDP")
		_upnp_dev = null
		_upnp_port = 0
	upnp_mapped = false
	public_ip = ""
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	role = Role.OFFLINE
	remote_id = 0
	client_ready = false


## IPs locales (para mostrarlas al host mientras espera al rival).
func lan_addresses() -> Array[String]:
	var out: Array[String] = []
	for a in IP.get_local_addresses():
		var s := String(a)
		if s.count(".") == 3 and not s.begins_with("127."):
			out.append(s)
	if out.is_empty():
		out.append("127.0.0.1")
	return out


## Handshake: el cliente lo llama cuando su escena de juego está montada.
@rpc("any_peer", "reliable")
func net_ready() -> void:
	if is_host() and not client_ready:
		client_ready = true
		client_became_ready.emit()


func _on_peer_connected(id: int) -> void:
	if is_host():
		remote_id = id
		peer_joined.emit()


func _on_peer_disconnected(id: int) -> void:
	if is_host() and id == remote_id:
		peer_left.emit()
