extends SceneTree
## E2E online — CLIENTE. Conecta al host, monta la partida y "juega" con P2
## (corre a la izquierda y ataca cada 0,5 s). Verifica que llegan snapshots,
## que su predicción de P2 sigue al host y que ve las mismas bajas.
##   godot --headless --path . --script test/online_client.gd -- --ip=127.0.0.1 --port=24575
## (--ip/--port opcionales: sin ellos, 127.0.0.1 y Net.DEFAULT_PORT; los
## argumentos tras "--" son user args, ver OS.get_cmdline_user_args()).
## Net se rescata por ruta (el script de entrada se parsea antes que autoloads).
## Código de salida: 0 OK, 1 FALLO.

const DUR := 42.0
const CONNECT_TIMEOUT := 12.0
const CONNECT_TIMEOUT_RELAY := 30.0  # el ayudante tarda unos s en bootear
var t := 0.0
var game: Node
var net: Node
var relay_mode := false
var got_snap := false
var max_drift := 0.0
var kills_seen := 0
var calm_since := -99.0   # t de la última transición vida↔muerte (para medir deriva)
var _tick := 0
var _tap_tick := -1


var _started := false


func _initialize() -> void:
	net = root.get_node_or_null("Net")


func _try_start() -> bool:
	var ip := "127.0.0.1"
	var port := 0
	var relay_code := ""
	var relay_addr := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ip="):
			ip = a.trim_prefix("--ip=")
		elif a.begins_with("--port="):
			port = int(a.trim_prefix("--port="))
		elif a.begins_with("--relay-join="):
			relay_code = a.trim_prefix("--relay-join=")
		elif a.begins_with("--relay="):
			relay_addr = a.trim_prefix("--relay=")
	var err: int
	if not relay_code.is_empty():
		# modo relay (online v3): sala por codigo con el puente DEL JUEGO
		relay_mode = true
		err = net.join_relay(relay_code, relay_addr if not relay_addr.is_empty() else net.RELAY_DEFAULT)
		net.relay_failed.connect(func(reason: String) -> void:
			print("CLIENT_RESULT: FALLO — relay (%s), ¿código correcto y anfitrión dentro?" % reason)
			quit(1))
	else:
		err = net.join(ip, port if port > 0 else net.DEFAULT_PORT)
	if err == ERR_UNAVAILABLE:
		return false   # la API multiplayer tarda un frame: reintentar
	if err != OK:
		print("CLIENT_RESULT: FALLO — join(%s) devolvió error %d" % [ip, err])
		quit(1)
		return true
	_started = true
	net.connect_failed.connect(_on_connect_failed)
	net.server_lost.connect(_on_server_lost)
	print("CLIENT: conectando a %s ..." % ("sala %s del relay" % relay_code if not relay_code.is_empty() else ip))
	return true


var _retries := 0


func _on_connect_failed() -> void:
	if relay_mode:
		# modo relay: Net reintenta el ENet el solo contra el puente local
		# (matar el ayudante a mitad de boot fue la fuente de zombis)
		_retries += 1
		print("CLIENT: reintento de ENet contra el puente local (%d)..." % _retries)
		if _retries > 15:
			print("CLIENT_RESULT: FALLO — el puente local nunca contestó")
			quit(1)
		return
	# el host puede tardar en abrir (o estar reescaneando el proyecto): reintentar
	_retries += 1
	if _retries > 10:
		print("CLIENT_RESULT: FALLO — 10 intentos de conexión sin éxito")
		quit(1)
		return
	print("CLIENT: reintento %d (sin host aún)..." % _retries)
	net.shutdown()
	_started = false


func _process(delta: float) -> bool:
	t += delta
	_tick += 1
	if net == null:
		net = root.get_node_or_null("Net")
		if net == null:
			return t > 15.0
	if not _started:
		if _try_start():
			if not _started:
				return true   # fallo definitivo: ya se imprimió el resultado
		elif t > 15.0:
			print("CLIENT_RESULT: FALLO — join() no disponible en 15 s")
			quit(1)
			return true
		return false
	if game != null and not is_instance_valid(game):
		return true   # el juego se desmontó (host fuera): el handler de drop evalúa
	# 1) esperar el enlace antes de montar la partida (el juego hace handshake)
	# OJO: sin peer montado, multiplayer.multiplayer_peer es un OfflineMultiplayerPeer
	# que dice CONNECTED — hay que exigir ademas que Net haya llamado join()
	if game == null:
		if relay_mode and t > 1.5 and fmod(t, 2.0) < delta:
			net.relay_join_poll()  # los SceneTreeTimer no van bajo MainLoop script
		if net.is_client() and root.get_multiplayer().multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			print("CLIENT: enlace OK en t=%.1f — montando partida" % t)
			game = (load("res://scenes/main.tscn") as PackedScene).instantiate()
			root.add_child(game)
		elif t > (CONNECT_TIMEOUT_RELAY if relay_mode else CONNECT_TIMEOUT):
			print("CLIENT_RESULT: FALLO — sin conexión en %.0fs" % (CONNECT_TIMEOUT_RELAY if relay_mode else CONNECT_TIMEOUT))
			quit(1)
			return true
		return false
	# 2) "jugador humano" P2: corre a la izquierda, ataca y salta muros y fosos
	if game.round_lock <= 0.0 and not game.match_over:
		Input.action_press("p2_left")
		if _tick % 30 == 0:
			Input.action_press("p2_attack")
			_tap_tick = _tick
		if _tap_tick >= 0 and _tick > _tap_tick:
			Input.action_release("p2_attack")
			_tap_tick = -1
		var me: Node = game.players[1]
		var mx: float = me.position.x
		var want_jump: bool = (me.is_on_wall() and me.is_on_floor()) \
			or (me.is_on_floor() and mx > game.PLAT_X0 - 130.0 and mx < game.PLAT_X1 + 130.0 \
				and not (mx > game.PLAT_X0 + 40.0 and mx < game.PLAT_X1 - 40.0)) \
			or (me.is_on_floor() and mx > game.PIT2_X0 - 130.0 and mx < game.PIT2_X1 + 130.0)
		if want_jump and _tick % 12 < 2:
			Input.action_press("p2_jump")
		else:
			Input.action_release("p2_jump")
	else:
		Input.action_release("p2_left")
		Input.action_release("p2_attack")
		Input.action_release("p2_jump")
	# 3) evidencia: snapshots, deriva de mi predicción, bajas vistas
	if not game.net_last_snap.is_empty():
		got_snap = true
		var p2s: Dictionary = game.net_last_snap.get("p2", {})
		var me: Node = game.players[1]
		# la deriva se mide solo en juego estable: los teletransportes legítimos
		# (muerte/reaparición) y el staleness del snapshot falsearían la lectura
		var now_dead: bool = me.state == 7
		if now_dead != bool(me.get_meta("was_dead_me", false)):
			calm_since = t
		me.set_meta("was_dead_me", now_dead)
		var host_alive: bool = int(p2s.get("st", 0)) != 7
		if p2s.has("x") and not now_dead and host_alive and t - calm_since > 1.0:
			max_drift = maxf(max_drift, absf(float(p2s["x"]) - me.position.x))
		for p in game.players:
			if p.state == 7 and not p.get_meta("was_dead", false):
				kills_seen += 1
				print("CLIENT: veo morir a P%d en t=%.1fs" % [p.player_id, t])
			p.set_meta("was_dead", p.state == 7)
	if fmod(t, 2.0) < delta:
		var me: Node = game.players[1]
		var foe: Node = game.players[0]
		print("CLIENT t=%.1f rl=%.2f yo=(%.0f,%.0f) st=%d rival=(%.0f,%.0f) score=%s rw=%s" % [
			t, game.round_lock, me.position.x, me.position.y, me.state,
			foe.position.x, foe.position.y, str(game.scores),
			"P%d" % game.right_of_way.player_id if game.right_of_way != null else "-",
		])
	if t >= DUR:
		_finish()
		return true
	return false


func _on_server_lost() -> void:
	# el host cierra al terminar su ventana de prueba: evaluar con lo recolectado
	if t < 30.0:
		print("CLIENT_RESULT: FALLO — el host se cayó en t=%.1f" % t)
		quit(1)
		return
	_finish()


func _finish() -> void:
	var ok := got_snap and max_drift < 200.0 and kills_seen > 0
	var score_txt := "?"
	if is_instance_valid(game):
		score_txt = str(game.scores)
	if net.relay_node != null:
		print("CLIENT: %s" % net.relay_node.stats())
	print("CLIENT_RESULT: %s — snapshots=%s deriva_max=%.0fpx bajas_vistas=%d score=%s" % [
		"OK" if ok else "FALLO", got_snap, max_drift, kills_seen, score_txt,
	])
	net.shutdown()
	quit(0 if ok else 1)
