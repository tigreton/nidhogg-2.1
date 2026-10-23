extends Node
## Autoload Net: ciclo de vida de la conexión ENet para el 1v1 online.
## Host = servidor + P1 (autoridad de la simulación). Cliente = P2.
## El flujo de escenas lo llevan las señales: la pantalla de título crea/unre
## y salta a la partida cuando hay enlace; game.gd hace el handshake fino
## (net_ready) antes de arrancar la primera ronda.

enum Role { OFFLINE, HOST, CLIENT }

const DEFAULT_PORT := 24565

var role := Role.OFFLINE
var remote_id := 0        # id del rival (host: id del cliente; cliente: 1)
var client_ready := false # el cliente ya montó su escena de juego

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


func _ready() -> void:
	# el multiplayer API es global: conectamos una sola vez y discrimina role
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(func() -> void: connected_ok.emit())
	multiplayer.connection_failed.connect(func() -> void: connect_failed.emit())
	multiplayer.server_disconnected.connect(func() -> void: server_lost.emit())


func active() -> bool:
	return role != Role.OFFLINE


func is_host() -> bool:
	return role == Role.HOST


func is_client() -> bool:
	return role == Role.CLIENT


func host(port := DEFAULT_PORT) -> Error:
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


func shutdown() -> void:
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
