extends RefCounted
## Suite de movimiento: física actual como línea base. Las tareas 43/44
## (salto doble y aceleración) actualizan los rangos marcados con `# L43`/`# L44`.

var runner


func get_tests() -> Array:
	return [
		["correr_30_frames", _t_correr],
		["salto_parado_apice", _t_salto_parado],
		["salto_carrerilla_distancia", _t_salto_carrera],
		["rodada_estado_y_duracion", _t_rodada],
		["dive_corriendo", _t_dive],
		["arco_tensado_en_divekick", _t_arco_dive],
	]


func _reset(x1: float, x2: float) -> void:
	var g: Node = runner.game
	for pair in [[g.players[0], x1], [g.players[1], x2]]:
		var p: Player = pair[0]
		p.position = Vector2(pair[1], 531.0)
		p.velocity = Vector2.ZERO
		p.state = Player.State.IDLE
		p.has_sword = true
		p.weapon_id = "florete"
		p.invuln_time = 0.0
		p.facing = 1
		p.attack_time = 0.0
		p.bow_time = 0.0
		g.respawn_timers[p.player_id - 1] = 0.0
	g.round_lock = 0.0
	g.right_of_way = null


func _t_correr() -> bool:
	_reset(1600.0, 4400.0)
	var x0: float = runner.game.players[0].position.x
	Input.action_press("p1_right")
	await runner.step_physics(30)
	Input.action_release("p1_right")
	await runner.step_physics(5)
	var dx: float = runner.game.players[0].position.x - x0
	runner.release_all()
	return runner.check(dx >= 130.0, "correr recorre >=130 px en 35 frames con aceleración (hoy ~145)")  # L44


func _t_salto_parado() -> bool:
	# x=1300: franja sin el techo de la plataforma de la tarea 04 (1480–1660)
	_reset(1300.0, 4400.0)
	Input.action_press("p1_jump")
	await runner.step_physics(1)
	Input.action_release("p1_jump")
	var min_y: float = runner.game.players[0].position.y
	for i in 55:
		await runner.step_physics(1)
		min_y = minf(min_y, runner.game.players[0].position.y)
	var rise: float = 531.0 - min_y
	runner.release_all()
	return runner.check(rise >= 55.0 and rise <= 80.0, "salto parado sube 55-80 px (ahora ~66)")  # L43


func _t_salto_carrera() -> bool:
	_reset(1600.0, 4400.0)
	Input.action_press("p1_right")
	await runner.step_physics(8)
	var x0: float = runner.game.players[0].position.x
	Input.action_press("p1_jump")
	await runner.step_physics(1)
	Input.action_release("p1_jump")
	await runner.step_physics(70)
	var p: Player = runner.game.players[0]
	runner.release_all()
	return runner.check(p.is_on_floor() and p.position.x - x0 >= 180.0,
			"salto con carrerilla recorre >=180 px en el aire (ahora ~230)")  # L43


func _t_rodada() -> bool:
	_reset(1600.0, 4400.0)
	Input.action_press("p1_down")
	await runner.step_physics(1)
	Input.action_press("p1_jump")
	await runner.step_physics(3)
	var rolling: bool = runner.game.players[0].state == Player.State.ROLL
	Input.action_release("p1_jump")
	Input.action_release("p1_down")
	await runner.step_physics(30)
	var done: bool = runner.game.players[0].state == Player.State.IDLE
	runner.release_all()
	return runner.check(rolling, "down+jump entra en ROLL") \
			and runner.check(done, "la rodada termina sola en IDLE (~20 frames)")


func _t_dive() -> bool:
	_reset(1550.0, 4400.0)
	Input.action_press("p1_right")
	await runner.step_physics(12)
	Input.action_press("p1_down")
	Input.action_press("p1_jump")
	await runner.step_physics(4)
	var p: Player = runner.game.players[0]
	var diving: bool = p.state == Player.State.DIVE and absf(absf(p.velocity.x) - 546.0) < 10.0
	Input.action_release("p1_jump")
	Input.action_release("p1_down")
	Input.action_release("p1_right")
	await runner.step_physics(10)
	runner.release_all()
	return runner.check(diving, "corriendo+abajo+salto entra en DIVE a 546 px/s")


func _t_arco_dive() -> bool:
	_reset(1600.0, 4400.0)
	runner.game.players[0].weapon_id = "arco"
	await runner.step_physics(1)
	# tensar completo en el suelo
	Input.action_press("p1_attack")
	await runner.step_physics(66)
	# dive SIN soltar ataque (correr + abajo + salto)
	Input.action_press("p1_right")
	await runner.step_physics(6)
	Input.action_press("p1_down")
	Input.action_press("p1_jump")
	await runner.step_physics(20)
	Input.action_release("p1_jump")
	Input.action_release("p1_down")
	Input.action_release("p1_right")
	await runner.step_physics(50)   # aterriza, derribo, se levanta
	var bow_ok: bool = runner.game.players[0].bow_time >= 1.0
	Input.action_release("p1_attack")
	await runner.step_physics(6)
	var fired: bool = runner.game.arrows.size() >= 1
	runner.release_all()
	await runner.wait(0.6)
	_reset(1600.0, 4400.0)
	return runner.check(bow_ok, "el tensado se conserva a través del dive") \
			and runner.check(fired, "al soltar de pie, dispara")  # L75
