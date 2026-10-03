extends RefCounted
## Suite de combate: reglas actuales como línea base. Las tareas 47/48/49
## actualizan los casos marcados con `# L47`/`# L48`/`# L49`.

var runner


func get_tests() -> Array:
	return [
		["choque_doble_ataque_misma_altura", _t_choque],
		["parada_blanda_ataque_vs_guardia", _t_parada],
		["guardia_pasiva_distinta_altura_mata", _t_guardia],
		["espada_lanzada_desviada_por_guardia", _t_lanzada],
		["punetazo_desarma", _t_punetazo],
		["flecha_rebota_en_guardia_igual", _t_flecha],
		["lanza_con_salto_ataque", _t_lanza_salto],
		["arco_soltar_antes_de_tiempo_no_dispara", _t_arco_cancel],
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
	# hermeticidad (tarea 84): flechas/proyectiles/pickups de tests previos
	# (una flecha reboteando tarda >1 s en clavarse) no deben filtrarse
	for a in g.arrows:
		a.queue_free()
	g.arrows.clear()
	for pr in g.projectiles:
		pr.queue_free()
	g.projectiles.clear()
	for pk in g.pickups:
		pk.queue_free()
	g.pickups.clear()
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


func _t_parada() -> bool:
	_reset(1600.0, 1670.0)
	await runner.step_physics(1)
	Input.action_press("p1_attack")
	await runner.step_physics(9)
	Input.action_release("p1_attack")
	var p1: Player = runner.game.players[0]
	var p2: Player = runner.game.players[1]
	var ok: bool = p1.state != Player.State.STUNNED and p2.state != Player.State.STUNNED \
			and p1.state != Player.State.DEAD and p2.state != Player.State.DEAD
	runner.release_all()
	await runner.wait(0.5)
	_reset(1600.0, 4400.0)
	return runner.check(ok, "atacar contra guardia a la misma altura: parada sin stun ni muerte")  # L47


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
	return runner.check(alive, "la guardia a una altura que el arma mata la desvía") \
			and runner.check(pickup, "el arma desviada cae al suelo")  # L49: generalizado a thrown_kills


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


func _t_arco_cancel() -> bool:
	_reset(1600.0, 1750.0)
	runner.game.players[0].weapon_id = "arco"
	await runner.step_physics(1)
	Input.action_press("p1_attack")
	await runner.step_physics(45)   # 0,75 s: se queda corto
	Input.action_release("p1_attack")
	await runner.step_physics(10)
	var no_arrow: bool = runner.game.arrows.is_empty()
	runner.release_all()
	await runner.wait(0.3)
	_reset(1600.0, 4400.0)
	return runner.check(no_arrow, "soltar el arco antes de 1,0 s no dispara")  # L48


func _t_lanza_salto() -> bool:
	_reset(1600.0, 4400.0)
	await runner.step_physics(1)
	# en el aire: mantener salto y pulsar ataque lanza el arma
	Input.action_press("p1_jump")
	await runner.step_physics(2)
	Input.action_release("p1_jump")
	Input.action_press("p1_jump")
	Input.action_press("p1_attack")
	await runner.step_physics(4)
	var thrown: bool = not runner.game.players[0].has_sword and runner.game.projectiles.size() >= 1
	Input.action_release("p1_attack")
	Input.action_release("p1_jump")
	runner.release_all()
	await runner.wait(0.5)
	_reset(1600.0, 4400.0)
	return runner.check(thrown, "salto+ataque en el aire lanza el arma")  # L84


func _t_flecha() -> bool:
	_reset(1600.0, 1750.0)
	runner.game.players[0].weapon_id = "arco"
	# sin up/down la flecha sale en MEDIA: guardia MEDIA = misma altura
	await runner.step_physics(1)
	Input.action_press("p1_attack")
	await runner.step_physics(66)   # tensado completo obligatorio (1,1 s)  # L48
	Input.action_release("p1_attack")
	await runner.step_physics(30)
	var g: Node = runner.game
	var p2: Player = g.players[1]
	var bounced: bool = g.arrows.size() >= 1 and g.arrows[0].bounces >= 1 and p2.state != Player.State.DEAD
	runner.release_all()
	await runner.wait(0.5)
	_reset(1600.0, 4400.0)
	return runner.check(bounced, "la flecha rebota en la guardia a su misma altura")
