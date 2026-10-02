extends RefCounted
## Suite de combate: reglas actuales como línea base. Las tareas 47/48/49
## actualizan los casos marcados con `# L47`/`# L48`/`# L49`.

var runner


func get_tests() -> Array:
	return [
		["choque_doble_ataque_misma_altura", _t_choque],
		["guardia_pasiva_distinta_altura_mata", _t_guardia],
		["espada_lanzada_desviada_por_guardia", _t_lanzada],
		["punetazo_desarma", _t_punetazo],
		["flecha_rebota_en_guardia_igual", _t_flecha],
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


func _t_choque() -> bool:
	_reset(1600.0, 1670.0)
	await runner.step_physics(1)
	Input.action_press("p1_attack")
	Input.action_press("p2_attack")
	await runner.step_physics(9)
	var p1: Player = runner.game.players[0]
	var p2: Player = runner.game.players[1]
	var stunned: bool = p1.state == Player.State.STUNNED and p2.state == Player.State.STUNNED
	runner.release_all()
	await runner.wait(0.6)
	return runner.check(stunned, "doble ataque MID simultáneo: ambos STUNNED")  # L47: sigue igual (doble ataque)


func _t_guardia() -> bool:
	_reset(1500.0, 1650.0)
	runner.game.players[1].facing = -1   # el guardián mira al corredor
	Input.action_press("p2_down")   # guardia baja
	Input.action_press("p1_right")  # corre en MID contra la guardia
	await runner.step_physics(40)
	var p1: Player = runner.game.players[0]
	runner.release_all()
	var dead: bool = p1.state == Player.State.DEAD
	await runner.wait(0.7)
	_reset(1600.0, 4400.0)
	return runner.check(dead, "correr en MID contra guardia LOW: empalamiento")


func _t_lanzada() -> bool:
	_reset(1600.0, 1750.0)
	await runner.step_physics(1)
	Input.action_press("p1_throw")
	await runner.step_physics(2)
	Input.action_release("p1_throw")
	await runner.step_physics(6)
	var p2: Player = runner.game.players[1]
	var alive: bool = p2.state != Player.State.DEAD
	runner.release_all()
	await runner.wait(0.4)
	var pickup: bool = runner.game.pickups.size() >= 1
	_reset(1600.0, 4400.0)
	return runner.check(alive, "la guardia MEDIA desvía la espada lanzada") \
			and runner.check(pickup, "la espada desviada cae al suelo")  # L49: la guardia a CUALQUIER altura que mate el arma la desvía


func _t_punetazo() -> bool:
	_reset(1600.0, 1650.0)
	runner.game.players[0].has_sword = false
	await runner.step_physics(1)
	Input.action_press("p1_attack")
	await runner.step_physics(9)
	Input.action_release("p1_attack")
	var p2: Player = runner.game.players[1]
	var ok: bool = p2.state == Player.State.STUNNED and not p2.has_sword
	runner.release_all()
	await runner.wait(0.8)
	_reset(1600.0, 4400.0)
	return runner.check(ok, "el puñetazo de pie desarma y aturde")


func _t_flecha() -> bool:
	_reset(1600.0, 1750.0)
	runner.game.players[0].weapon_id = "arco"
	# sin up/down la flecha sale en MEDIA: guardia MEDIA = misma altura
	await runner.step_physics(1)
	Input.action_press("p1_attack")
	await runner.step_physics(32)   # tensar 0,53 s  # L48: 66 frames (1,1 s obligatorios)
	Input.action_release("p1_attack")
	await runner.step_physics(30)
	var g: Node = runner.game
	var p2: Player = g.players[1]
	var bounced: bool = g.arrows.size() >= 1 and g.arrows[0].bounces >= 1 and p2.state != Player.State.DEAD
	runner.release_all()
	await runner.wait(0.5)
	_reset(1600.0, 4400.0)
	return runner.check(bounced, "la flecha rebota en la guardia a su misma altura")
