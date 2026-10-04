extends SceneTree
## E2E online — HOST. Lanza el servidor, monta la partida y "juega" con P1
## (corre a la derecha y ataca cada 0,5 s). Verifica que el input del cliente
## mueve a P2, que hay bajas y que la partida avanza de verdad.
##   godot --headless --path . --script test/online_host.gd
## Nota: el script de entrada se parsea antes que los autoloads, así que Net
## se rescata por ruta (/root/Net), nunca por identificador global.
## Código de salida: 0 OK, 1 FALLO.

const DUR := 40.0
var t := 0.0
var game: Node
var net: Node
var kills := 0
var p1_moved := false
var p2_moved := false
var _tap_tick := -1
var _tick := 0
var _started := false


func _initialize() -> void:
	net = root.get_node_or_null("Net")


func _try_start() -> bool:
	# la API multiplayer puede tardar un frame en existir: reintenta hasta que
	# host() devuelva algo distinto de ERR_UNAVAILABLE
	var err: int = net.host()
	if err == ERR_UNAVAILABLE:
		return false
	if err != OK:
		print("HOST_RESULT: FALLO — no se pudo abrir el puerto %d (err=%d)" % [net.DEFAULT_PORT, err])
		quit(1)
		return true
	_started = true
	print("HOST: servidor ENet escuchando en el puerto %d (is_host=%s)" % [net.DEFAULT_PORT, net.is_host()])
	game = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	print("HOST: partida montada, esperando handshake del cliente...")
	return true


func _process(delta: float) -> bool:
	t += delta
	_tick += 1
	if net == null:
		net = root.get_node_or_null("Net")
		if net == null:
			return t > 15.0
	if not _started:
		if _try_start():
			if game == null:
				return true   # fallo definitivo: ya se imprimió el resultado
		elif t > 15.0:
			print("HOST_RESULT: FALLO — host() no disponible en 15 s")
			quit(1)
			return true
		return false
	if game == null:
		return true
	var p1: Node = game.players[0]
	var p2: Node = game.players[1]
	# "jugador humano" P1: corre a la derecha, ataca, y salta muros y fosos
	# (pulsos de 2 ticks: si un just_pressed cae en pleno ataque, se repite)
	if net.client_ready and game.round_lock <= 0.0 and not game.match_over:
		Input.action_press("p1_right")
		if _tick % 30 == 0:
			Input.action_press("p1_attack")
			_tap_tick = _tick
		if _tap_tick >= 0 and _tick > _tap_tick:
			Input.action_release("p1_attack")
			_tap_tick = -1
		var px: float = p1.position.x
		var want_jump: bool = (p1.is_on_wall() and p1.is_on_floor()) \
			or (p1.is_on_floor() and px > game.PLAT_X0 - 130.0 and px < game.PLAT_X1 + 130.0 \
				and not (px > game.PLAT_X0 + 40.0 and px < game.PLAT_X1 - 40.0)) \
			or (p1.is_on_floor() and px > game.PIT2_X0 - 130.0 and px < game.PIT2_X1 + 130.0)
		if want_jump and _tick % 12 < 2:
			Input.action_press("p1_jump")
		else:
			Input.action_release("p1_jump")
	else:
		Input.action_release("p1_right")
		Input.action_release("p1_attack")
		Input.action_release("p1_jump")
	# contadores de evidencia
	if absf(p1.position.x - 2180.0) > 80.0:
		p1_moved = true
	if absf(p2.position.x - 2620.0) > 80.0 and net.client_ready:
		p2_moved = true
	for p in game.players:
		if p.state == 7 and not p.get_meta("was_dead", false):   # 7 = DEAD
			kills += 1
			print("HOST: baja detectada (P%d muere en t=%.1fs)" % [p.player_id, t])
		p.set_meta("was_dead", p.state == 7)
	if fmod(t, 2.0) < delta:
		print("HOST t=%.1f rl=%.2f p1=(%.0f,%.0f) st1=%d p2=(%.0f,%.0f) st2=%d score=%s rw=%s" % [
			t, game.round_lock,
			p1.position.x, p1.position.y, p1.state,
			p2.position.x, p2.position.y, p2.state,
			str(game.scores),
			"P%d" % game.right_of_way.player_id if game.right_of_way != null else "-",
		])
	if t >= DUR:
		var ok: bool = net.client_ready and p2_moved and kills > 0
		print("HOST_RESULT: %s — cliente_listo=%s p1_movio=%s p2_movio=%s bajas=%d score=%s" % [
			"OK" if ok else "FALLO", net.client_ready, p1_moved, p2_moved, kills, str(game.scores),
		])
		net.shutdown()
		quit(0 if ok else 1)
		return true
	return false
