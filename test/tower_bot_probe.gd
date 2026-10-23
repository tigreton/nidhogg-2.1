extends Node
## Sonda del bot en la Torre del Centinela (tarea 89): el bot debe subir al
## piso superior cuando el rival juega arriba y bajar por el hueco más
## cercano cuando juega abajo. Headless, sin render: solo posiciones.
##   godot --headless --path . res://test/tower_bot_probe.tscn

const TIMEOUT := 10.0

var game: Node
var fails := 0


func _pin(p: Node, pos: Vector2) -> void:
	# fija al "rival humano" en su piso: la sonda mide navegación vertical,
	# no combate (invuln para que nada muera y ensucie la medición)
	p.position = pos
	p.velocity = Vector2.ZERO
	p.invuln_time = 1.0


func _phase(name: String, bot: Node, human: Node, human_pos: Vector2, want_up: bool) -> float:
	var t0 := Time.get_ticks_msec()
	var deadline := t0 + int(TIMEOUT * 1000.0)
	var reached := false
	while Time.get_ticks_msec() < deadline:
		await get_tree().create_timer(0.1).timeout
		_pin(human, human_pos)
		bot.invuln_time = 1.0
		var up: bool = bot.position.y < 330.0
		var down: bool = bot.position.y > 450.0
		if (want_up and up) or (not want_up and down):
			reached = true
			break
	var dt := float(Time.get_ticks_msec() - t0) / 1000.0
	var ok := reached and dt < TIMEOUT
	print("%s: %s en %.1fs (y=%.0f, x=%.0f)" % [name, "OK" if ok else "FALLO", dt, bot.position.y, bot.position.x])
	if not ok:
		fails += 1
	return dt


func _ready() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.skip_countdown = true
	add_child(game)
	await get_tree().create_timer(0.4).timeout
	game.set_arena(3)
	await get_tree().create_timer(0.3).timeout
	var p1: Node = game.players[0]
	var p2: Node = game.players[1]
	p2.is_bot = true
	game.bot_level = 3   # DIFÍCIL: react 0.07s, el más decidido al subir

	# SUBIR: humano arriba del todo (piso 320 → pies y=291), bot en el suelo
	p1.has_sword = true
	p2.has_sword = true
	p2.position = Vector2(1800.0, 531.0)   # suelo a la izquierda del foso central
	p2.velocity = Vector2.ZERO
	var t_up := await _phase("SUBIR a piso superior", p2, p1, Vector2(800.0, 291.0), true)
	_check(t_up < 8.0, "SUBIR llega en <8s (criterio de la tarea)")

	# BAJAR: humano al pasillo inferior, bot arriba → hueco más cercano
	var t_down := await _phase("BAJAR al pasillo", p2, p1, Vector2(1500.0, 531.0), false)
	_check(t_down < 8.0, "BAJAR llega en <8s (criterio de la tarea)")

	# sanity: la rama no existe fuera de la torre — en arena 0 el mismo bot
	# con el rival arriba (puente) sigue su juego de suelo, no orbita escaleras
	game.set_arena(0)
	await get_tree().create_timer(0.3).timeout
	_pin(p1, Vector2(2300.0, 259.0))   # puente alto (y=288 → pies 259)
	p2.position = Vector2(1500.0, 531.0)
	await get_tree().create_timer(1.0).timeout
	_check(absf(p2.position.x - 450.0) > 40.0 and absf(p2.position.x - 4290.0) > 40.0,
			"ARENA 0: el bot no va a buscar escaleras de torre que no existen")

	if fails == 0:
		print("RESULT: TOWER BOT OK")
		get_tree().quit(0)
	else:
		print("RESULT: TOWER BOT FAIL (%d)" % fails)
		get_tree().quit(1)


func _check(cond: bool, what: String) -> void:
	print("  %s - %s" % ["ok" if cond else "FALLO", what])
	if not cond:
		fails += 1
