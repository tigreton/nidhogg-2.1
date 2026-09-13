extends Node
## Prueba de humo headless: simula input y verifica las mecánicas principales.
## Estados de Player: 0 IDLE, 1 RUN, 2 JUMP, 3 DIVEKICK, 4 ATTACK, 5 STUNNED, 6 KNOCKDOWN, 7 DEAD.

var game: Node
var p1: CharacterBody2D
var p2: CharacterBody2D
var fails: Array[String] = []


func _check(cond: bool, what: String) -> void:
	if cond:
		print("  ok  - " + what)
	else:
		fails.append(what)
		print("  FALLO - " + what)


func _ready() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	add_child(game)
	await get_tree().create_timer(0.2).timeout
	p1 = game.players[0]
	p2 = game.players[1]
	# Suelo seguro, lejos del foso central (2210-2380)
	p1.position = Vector2(1600.0, 531.0)
	p2.position = Vector2(1800.0, 531.0)

	# 1. Movimiento P1 a la derecha
	var x0: float = p1.position.x
	Input.action_press("p1_right")
	await get_tree().create_timer(0.25).timeout
	Input.action_release("p1_right")
	_check(p1.position.x > x0 + 60.0, "P1 se mueve a la derecha")

	# 2. Salto
	Input.action_press("p1_jump")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("p1_jump")
	_check(not p1.is_on_floor(), "P1 salta")
	await get_tree().create_timer(0.9).timeout

	# 3. Choque de espadas: misma estancia (MID vs MID) -> ambos aturdidos
	p2.position = p1.position + Vector2(70.0, 0.0)
	p1.facing = 1
	await get_tree().physics_frame
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.14).timeout
	Input.action_release("p1_attack")
	_check(p2.state == 5 and p1.state == 5, "Choque con estancias iguales (ambos STUNNED)")
	await get_tree().create_timer(1.1).timeout

	# 4. Muerte: P2 defiende en HIGH, P1 ataca MID
	p2.position = p1.position + Vector2(70.0, 0.0)
	p1.facing = 1
	Input.action_press("p2_up")
	await get_tree().create_timer(0.1).timeout
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.16).timeout
	Input.action_release("p1_attack")
	Input.action_release("p2_up")
	_check(p2.state == 7, "Estancia distinta mata (P2 DEAD)")
	_check(game.right_of_way == p1, "P1 gana el paso")
	_check(game.scores[0] == 0, "Todavía sin puntos")

	# 5. Meta: P1 corre a su zona derecha
	p1.position = Vector2(4770.0, 500.0)
	await get_tree().create_timer(0.12).timeout
	_check(game.scores[0] == 1, "P1 anota al llegar a su meta")
	_check(game.round_lock > 0.0, "Ronda bloqueada tras el punto")
	await get_tree().create_timer(0.5).timeout
	_check(p2.state == 7, "P2 sigue muerto durante la celebración")

	# 6. La ronda se reinicia sola
	await get_tree().create_timer(2.4).timeout
	_check(p2.state == 0 and p1.state == 0, "Ronda reiniciada (ambos IDLE)")

	# 7. Lanzamiento de espada
	Input.action_press("p1_throw")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("p1_throw")
	_check(not p1.has_sword, "P1 lanza su espada (queda desarmado)")
	_check(game.projectiles.size() == 1, "Proyectil de espada en vuelo")

	# 8. Patada voladora derriba al rival
	for s in game.projectiles:
		s.queue_free()
	game.projectiles.clear()
	p1.position = Vector2(2900.0, 380.0)
	p2.position = Vector2(2955.0, 531.0)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.facing = 1
	await get_tree().physics_frame
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.05).timeout
	Input.action_release("p1_attack")
	await get_tree().create_timer(0.5).timeout
	_check(p2.state == 6, "Patada voladora derriba al rival (KNOCKDOWN)")
	await get_tree().create_timer(1.2).timeout

	# 9. Caer al foso central mata (colocándolo bajo la plataforma)
	p1.position = Vector2(2295.0, 500.0)
	p1.velocity = Vector2.ZERO
	await get_tree().create_timer(1.2).timeout
	_check(p1.state == 7, "Caer al foso central mata")

	# 10. La guardia media desvía la espada lanzada
	await get_tree().create_timer(1.5).timeout
	for pk in game.pickups:
		pk.queue_free()
	game.pickups.clear()
	p1.position = Vector2(1600.0, 531.0)
	p2.position = Vector2(1750.0, 531.0)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.state = 0
	p2.state = 0
	p1.facing = 1
	p1.has_sword = true
	p2.has_sword = true
	await get_tree().physics_frame
	Input.action_press("p1_throw")
	await get_tree().create_timer(0.05).timeout
	Input.action_release("p1_throw")
	await get_tree().create_timer(0.35).timeout
	_check(p2.state != 7, "La guardia media desvía la espada lanzada")
	_check(game.pickups.size() == 1, "La espada desviada cae al suelo")

	# 11. El rival reaparece delante del corredor, hacia su meta
	p1.has_sword = true
	p2.has_sword = true
	p1.position = Vector2(1600.0, 531.0)
	p2.position = Vector2(1670.0, 531.0)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.state = 0
	p2.state = 0
	p1.facing = 1
	Input.action_press("p2_up")
	await get_tree().create_timer(0.1).timeout
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.16).timeout
	Input.action_release("p1_attack")
	Input.action_release("p2_up")
	_check(p2.state == 7, "P2 muere de nuevo")
	var x_p1: float = p1.position.x
	await get_tree().create_timer(2.6).timeout
	_check(p2.state != 7, "P2 reaparece tras el retardo")
	_check(p2.position.x > x_p1 + 400.0, "Reaparece delante del corredor, hacia la meta de P1")

	# 12. Revancha: el tercer punto termina el partido y R lo reinicia
	game.scores = [2, 0]
	game.right_of_way = game.players[0]
	p1.position = Vector2(4770.0, 531.0)
	p1.velocity = Vector2.ZERO
	await get_tree().create_timer(0.2).timeout
	_check(game.match_over, "El tercer punto termina el partido")
	Input.action_press("restart")
	await get_tree().create_timer(0.05).timeout
	Input.action_release("restart")
	await get_tree().create_timer(0.3).timeout
	_check(game.scores == [0, 0] and not game.match_over, "R reinicia el marcador")
	_check(p1.state == 0 and p2.state == 0, "R reinicia la ronda")

	# 13. Alturas nuevas: peldaño de roca, tejado de la casa y puente alto
	p1.position = Vector2(2902.0, 480.0)
	p1.velocity = Vector2.ZERO
	await get_tree().create_timer(0.3).timeout
	_check(p1.is_on_floor() and absf(p1.position.y - 487.0) < 6.0, "Se puede subir al peldaño de roca")
	p1.position = Vector2(950.0, 436.0)
	p1.velocity = Vector2.ZERO
	await get_tree().create_timer(0.3).timeout
	_check(p1.is_on_floor() and absf(p1.position.y - 443.0) < 6.0, "El tejado de la casa es subible")
	p1.position = Vector2(2300.0, 220.0)
	p1.velocity = Vector2.ZERO
	await get_tree().create_timer(0.5).timeout
	_check(p1.is_on_floor() and absf(p1.position.y - 259.0) < 6.0 and p1.state != 7, "El puente alto cruza sobre el foso")

	# 14. Modo caos: lluvia de rocas (una roca directa mata)
	game.set_chaos(true)
	game.chaos_timer = 0.05
	var tries := 0
	while game.rocks.size() == 0 and tries < 200:
		await get_tree().physics_frame
		tries += 1
	_check(game.rocks.size() > 0, "La lluvia de rocas genera rocas")
	_check(game.chaos_count >= 1, "Contador de rocas del modo caos")
	var rock: FallingRock = game.rocks[0]
	rock.phase = "fall"
	rock.position.y = rock.target_y - 220.0
	p2.position = Vector2(rock.position.x, rock.target_y - 29.0)
	p2.velocity = Vector2.ZERO
	p2.state = 0
	p2.invuln_time = 0.0
	await get_tree().create_timer(0.4).timeout
	_check(p2.state == 7, "Una roca directa mata")
	game.set_chaos(false)
	_check(game.rocks.is_empty(), "Desactivar el modo caos limpia las rocas")

	# 15. Modo 2v2: equipos, sin fuego amigo y punto por equipos
	game.set_mode_2v2(true)
	_check(game.players.size() == 4, "2v2: cuatro duelistas")
	var p3: CharacterBody2D = game.players[2]
	var p4: CharacterBody2D = game.players[3]
	p3.is_bot = false
	p4.is_bot = false
	for q in [p1, p2, p3, p4]:
		q.has_sword = true
		q.velocity = Vector2.ZERO
		q.state = 0
		q.invuln_time = 0.0
	p1.position = Vector2(1600.0, 531.0)
	p3.position = Vector2(1670.0, 531.0)
	p2.position = Vector2(4000.0, 531.0)
	p4.position = Vector2(4200.0, 531.0)
	p1.facing = 1
	await get_tree().physics_frame
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.16).timeout
	Input.action_release("p1_attack")
	_check(p3.state != 7, "2v2: sin fuego amigo")
	await get_tree().create_timer(0.4).timeout
	p2.position = p1.position + Vector2(70.0, 0.0)
	p2.velocity = Vector2.ZERO
	p2.state = 0
	p2.invuln_time = 0.0
	Input.action_press("p2_up")
	await get_tree().create_timer(0.1).timeout
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.16).timeout
	Input.action_release("p1_attack")
	Input.action_release("p2_up")
	_check(p2.state == 7, "2v2: P1 mata a P2")
	_check(game.right_of_way == p1, "2v2: el paso es del asesino")
	p1.position = Vector2(4770.0, 500.0)
	p1.velocity = Vector2.ZERO
	await get_tree().create_timer(0.12).timeout
	_check(game.scores[0] == 1, "2v2: el punto es por equipos")
	game.set_mode_2v2(false)
	_check(game.players.size() == 2, "Desactivar 2v2 vuelve al duelo")
	_check(game.scores == [0, 0], "Al cambiar de modo el marcador se reinicia")

	# 16. Selector de arenas (C): reconstruye el nivel y reinicia el partido
	game.set_arena(1)
	_check(game.arena_id == 1, "Arena cambiada a Templo del Alba")
	_check(game.PIT2_X0 == 3050.0, "La arena 2 mueve el foso pequeño")
	_check(game.players.size() == 2, "El cambio de arena mantiene el duelo")
	p1.position = Vector2(784.0, 296.0)
	p1.velocity = Vector2.ZERO
	await get_tree().create_timer(0.4).timeout
	_check(p1.is_on_floor() and absf(p1.position.y - 301.0) < 6.0, "Arena 2: torre a la izquierda subible")
	p1.position = Vector2(3900.0, 436.0)
	p1.velocity = Vector2.ZERO
	await get_tree().create_timer(0.4).timeout
	_check(p1.is_on_floor() and absf(p1.position.y - 443.0) < 6.0, "Arena 2: casa junto a la meta derecha")
	game.set_arena(0)
	_check(game.arena_id == 0 and game.PIT2_X0 == 700.0, "Vuelta a Ruinas de Medianoche")

	# 17. Armas: la caída guarda su tipo y el ciclo avanza al reaparecer
	game.round_lock = 0.0
	game.right_of_way = null
	game.weapon_idx = [0, 0]
	p1.weapon_id = "florete"
	p2.weapon_id = "florete"
	p1.has_sword = true
	p2.has_sword = true
	p1.position = Vector2(1600.0, 531.0)
	p2.position = Vector2(1670.0, 531.0)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.state = 0
	p2.state = 0
	p1.facing = 1
	p2.invuln_time = 0.0
	await get_tree().physics_frame
	Input.action_press("p2_up")
	await get_tree().create_timer(0.1).timeout
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.16).timeout
	Input.action_release("p1_attack")
	Input.action_release("p2_up")
	_check(p2.state == 7, "Armas: P2 muere y suelta su arma")
	_check(game.pickups.size() == 1 and game.pickups[0].weapon_id == "florete", "Armas: la caída es un florete")
	await get_tree().create_timer(2.6).timeout
	_check(p2.weapon_id == "espada", "Armas: al reaparecer toca el espadón")
	p2.weapon_id = "florete"

	# 18. Arco: la flecha mata a distinta altura y rebota en guardia igual
	p1.weapon_id = "arco"
	p1.has_sword = true
	p1.bow_time = 0.0
	p1.position = Vector2(1600.0, 531.0)
	p1.velocity = Vector2.ZERO
	p1.state = 0
	p1.facing = 1
	p2.position = Vector2(1850.0, 531.0)
	p2.velocity = Vector2.ZERO
	p2.state = 0
	p2.has_sword = true
	p2.invuln_time = 0.0
	await get_tree().physics_frame
	Input.action_press("p2_up")
	await get_tree().create_timer(0.1).timeout
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.4).timeout
	Input.action_release("p1_attack")
	await get_tree().create_timer(0.8).timeout
	_check(p2.state == 7, "Arco: la flecha mata a quien no cubre su altura")
	Input.action_release("p2_up")
	p2.revive(Vector2(1850.0, 531.0), -1)
	p2.invuln_time = 0.0
	p2.state = 0
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.4).timeout
	Input.action_release("p1_attack")
	await get_tree().create_timer(0.8).timeout
	_check(p2.state != 7, "Arco: la guardia a la misma altura rebota la flecha")
	_check(game.arrows.size() == 1 and game.arrows[0].bounces >= 1, "Arco: la flecha quedó rebotada en vuelo")
	p1.weapon_id = "florete"

	# 19. Modo pantallas (P): rejas que solo cruza quien tiene el paso
	game.set_sections(true)
	_check(game.sections_mode and game.gates.size() == 6, "Pantallas: 6 rejas activas")
	_check(game.section_index == 3, "Pantallas: empieza en la sección central")
	# suelo firme dentro de la ventana de apertura de la reja 4 (no sobre el foso)
	p1.position = Vector2(2500.0, 531.0)
	p2.position = Vector2(2600.0, 531.0)
	# P2 desarmado: P1 corre hacia su posición y la guardia pasiva no debe matarlo aquí
	p2.has_sword = false
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.state = 0
	p2.state = 0
	game.right_of_way = p1
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(game.gates[3].open, "Pantallas: la reja del corredor se abre")
	p2.position = Vector2(3000.0, 531.0)
	p2.velocity = Vector2.ZERO
	Input.action_press("p2_right")
	await get_tree().create_timer(1.6).timeout
	Input.action_release("p2_right")
	_check(p2.position.x < 3420.0, "Pantallas: la reja cerrada bloquea al defensor")
	Input.action_press("p1_right")
	await get_tree().create_timer(2.0).timeout
	Input.action_release("p1_right")
	_check(game.section_index == 4, "Pantallas: P1 conquistó la sección 5")
	_check(game.sect_conquered[0] == 1, "Pantallas: conquista contada por equipo")
	game.set_sections(false)
	_check(not game.sections_mode and game.gates.is_empty(), "Pantallas: desactivar quita las rejas")

	# 20. HUD: pips de secciones y barra de reaparición
	game.set_sections(true)
	_check(game.pips_row.visible and game.pips.size() == 7, "HUD: fila de 7 pips en modo pantallas")
	game.sect_conquered = [1, 0]
	game._update_hud()
	_check(game.pips[4].fill_col == game.P1_COLOR, "HUD: pip conquistado del color del atacante")
	p1.position = Vector2(2200.0, 531.0)
	p2.position = Vector2(2270.0, 531.0)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.state = 0
	p2.state = 0
	p2.invuln_time = 0.0
	p2.has_sword = true
	await get_tree().physics_frame
	Input.action_press("p2_up")
	await get_tree().create_timer(0.1).timeout
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.16).timeout
	Input.action_release("p1_attack")
	Input.action_release("p2_up")
	await get_tree().create_timer(0.3).timeout
	_check(p2.state == 7 and game.respawn_bar.visible, "HUD: barra de reaparición visible")
	_check(game.fight_tween != null, "HUD: cartel FIGHT lanzado en la ronda")
	game.set_sections(false)
	_check(not game.pips_row.visible, "HUD: sin modo pantallas no hay pips")

	# 21. Stomp: pisotón letal sobre el rival derribado
	p1.position = Vector2(1600.0, 531.0)
	p2.position = Vector2(1620.0, 531.0)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.state = 0
	p2.state = 6
	p2.knockdown_time = 0.9
	p2.invuln_time = 0.0
	p1.has_sword = true
	p2.has_sword = true
	await get_tree().physics_frame
	Input.action_press("p1_down")
	await get_tree().create_timer(0.3).timeout
	Input.action_release("p1_down")
	_check(p2.state == 7, "Stomp: pisotón sobre el derribado mata")

	# 22. Desarmado: el puñetazo desarma y la patada baja derriba
	game.round_lock = 0.0
	# limpiar armas caídas (el stomp de la sección 21 deja una junto a P1)
	for pk in game.pickups:
		pk.queue_free()
	game.pickups.clear()
	p1.has_sword = false
	p1.position = Vector2(1600.0, 531.0)
	p2.position = Vector2(1645.0, 531.0)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.state = 0
	p2.state = 0
	p2.has_sword = true
	p2.invuln_time = 0.0
	p1.facing = 1
	await get_tree().physics_frame
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.2).timeout
	Input.action_release("p1_attack")
	_check(p2.has_sword == false and p2.state == 5, "Desarmado: el puñetazo desarma y aturde")
	p2.state = 0
	p2.has_sword = true
	p2.invuln_time = 0.0
	p2.position = Vector2(1645.0, 531.0)
	p2.velocity = Vector2.ZERO
	Input.action_press("p1_down")
	# esperar a que P1 salga del ATTACK del puñetazo (0,30 s) antes de patear
	await get_tree().create_timer(0.15).timeout
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.2).timeout
	Input.action_release("p1_attack")
	Input.action_release("p1_down")
	_check(p2.state == 6, "Desarmado: la patada baja derriba")
	for pk in game.pickups:
		pk.queue_free()
	game.pickups.clear()
	p1.has_sword = true

	# 28. Dive horizontal: abajo + salto corriendo
	game.round_lock = 0.0
	p1.has_sword = true
	p1.position = Vector2(1500.0, 531.0)
	p1.velocity = Vector2.ZERO
	p1.state = 1
	p2.position = Vector2(2600.0, 531.0)
	p2.velocity = Vector2.ZERO
	p2.state = 0
	await get_tree().physics_frame
	Input.action_press("p1_right")
	await get_tree().create_timer(0.2).timeout
	Input.action_press("p1_down")
	Input.action_press("p1_jump")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("p1_jump")
	Input.action_release("p1_down")
	_check(p1.state == 9 and absf(p1.velocity.x) > 400.0, "Dive horizontal: vuelo rasante")
	await get_tree().create_timer(0.8).timeout
	Input.action_release("p1_right")
	_check(p1.state in [0, 1, 6], "Dive horizontal: al acabar cae derribado o se levanta")

	# 29. Sidekick: derriba y desarma
	game.round_lock = 0.0
	p1.has_sword = true
	p2.has_sword = true
	p1.position = Vector2(1500.0, 531.0)
	p1.velocity = Vector2.ZERO
	p1.state = 0
	p2.position = Vector2(1650.0, 531.0)
	p2.velocity = Vector2.ZERO
	p2.state = 0
	p2.invuln_time = 0.0
	p1.facing = 1
	await get_tree().physics_frame
	Input.action_press("p1_right")
	await get_tree().create_timer(0.15).timeout
	Input.action_press("p1_down")
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.15).timeout
	Input.action_release("p1_attack")
	Input.action_release("p1_down")
	Input.action_release("p1_right")
	await get_tree().create_timer(0.4).timeout
	_check(p2.state == 6 and p2.has_sword == false, "Sidekick: derriba y desarma")
	for pk in game.pickups:
		pk.queue_free()
	game.pickups.clear()

	# 23. Sangre: cada muerte deja un charco persistente
	game.round_lock = 0.0
	p1.has_sword = true
	p2.has_sword = true
	p1.position = Vector2(1600.0, 531.0)
	p2.position = Vector2(1670.0, 531.0)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.state = 0
	p2.state = 0
	p1.facing = 1
	p2.invuln_time = 0.0
	await get_tree().physics_frame
	Input.action_press("p2_up")
	await get_tree().create_timer(0.1).timeout
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.16).timeout
	Input.action_release("p1_attack")
	Input.action_release("p2_up")
	await get_tree().create_timer(0.3).timeout
	_check(p2.state == 7 and game.blood.size() >= 1, "Sangre: la muerte deja charco")

	# 24. Cadáver: empalado en la espada, suelto con un tajo, limpiado al reaparecer
	game.round_lock = 0.0
	p1.has_sword = true
	p2.has_sword = true
	p1.position = Vector2(1600.0, 531.0)
	p2.position = Vector2(1670.0, 531.0)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.state = 0
	p2.state = 0
	p1.facing = 1
	p2.invuln_time = 0.0
	await get_tree().physics_frame
	Input.action_press("p2_up")
	await get_tree().create_timer(0.1).timeout
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.16).timeout
	Input.action_release("p1_attack")
	Input.action_release("p2_up")
	await get_tree().create_timer(0.2).timeout
	_check(p2.state == 7 and game.corpses.has(2), "Cadáver: el cuerpo queda en escena")
	var cx0: float = game.corpses[2].position.x
	Input.action_press("p1_right")
	await get_tree().create_timer(0.25).timeout
	Input.action_release("p1_right")
	_check(game.corpses[2].position.x > cx0 + 30.0, "Cadáver: empalado sigue a la espada del asesino")
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.2).timeout
	Input.action_release("p1_attack")
	await get_tree().create_timer(0.6).timeout
	_check(game.corpses[2].grounded, "Cadáver: tras el tajo cae y queda en el suelo")
	await get_tree().create_timer(2.2).timeout
	_check(game.corpses.is_empty(), "Cadáver: se limpia al reaparecer el jugador")

	# 27. Gusano de victoria
	game.scores = [2, 0]
	game.right_of_way = game.players[0]
	p1.position = Vector2(4770.0, 531.0)
	p1.velocity = Vector2.ZERO
	p1.state = 0
	await get_tree().create_timer(0.3).timeout
	_check(game.match_over and game.worm != null, "Gusano: baja al ganar el partido")
	Input.action_press("restart")
	await get_tree().create_timer(0.05).timeout
	Input.action_release("restart")
	await get_tree().create_timer(0.3).timeout
	_check(game.worm == null, "Gusano: la revancha lo limpia")

	# 26. Estela del arma lanzada
	game.round_lock = 0.0
	p1.has_sword = true
	p1.position = Vector2(1600.0, 531.0)
	p2.position = Vector2(2600.0, 531.0)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.state = 0
	p2.state = 0
	p1.facing = 1
	await get_tree().physics_frame
	Input.action_press("p1_throw")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("p1_throw")
	await get_tree().create_timer(0.2).timeout
	var proj: Node = game.projectiles[0]
	_check(game.projectiles.size() == 1 and proj.trail != null and proj.trail.get_point_count() >= 2, "Estela: el arma lanzada deja rastro")
	for s in game.projectiles:
		s.queue_free()
	game.projectiles.clear()
	for pk in game.pickups:
		pk.queue_free()
	game.pickups.clear()

	# 32. Tercera arena: Cripta del Ocaso
	game.set_arena(2)
	_check(game.arena_id == 2 and game.ARENA_NAMES[2] == "CRIPTA DEL OCASO", "Arena 3: nombre y selector")
	_check(game.PIT2_X0 == 3620.0, "Arena 3: foso pequeño a la derecha")
	p1.position = Vector2(460.0, 296.0)
	p1.velocity = Vector2.ZERO
	await get_tree().create_timer(0.4).timeout
	_check(p1.is_on_floor() and absf(p1.position.y - 301.0) < 6.0, "Arena 3: la torre izquierda es subible")
	game.set_arena(0)
	_check(game.arena_id == 0 and game.PIT2_X0 == 700.0, "Vuelta a Ruinas de Medianoche")

	# 25. Guardia pasiva: correr contra el arma en guardia es morir
	game.round_lock = 0.0
	p1.has_sword = true
	p2.has_sword = true
	p1.position = Vector2(1500.0, 531.0)
	p2.position = Vector2(1650.0, 531.0)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.state = 0
	p2.state = 0
	p1.invuln_time = 0.0
	p2.invuln_time = 0.0
	p1.facing = 1
	await get_tree().physics_frame
	Input.action_press("p2_down")
	Input.action_press("p1_right")
	await get_tree().create_timer(0.6).timeout
	Input.action_release("p1_right")
	Input.action_release("p2_down")
	_check(p1.state == 7 and p2.state != 7, "Guardia pasiva: correr contra el arma empala")
	p1.revive(Vector2(2600.0, 200.0), 1)
	p1.invuln_time = 0.0

	# 30. Arcade: ganar sube de nivel, perder termina la escalera
	game.set_arcade(true)
	_check(game.arcade and game.players[1].is_bot, "Arcade: activado con bot")
	game.scores = [2, 0]
	game.right_of_way = game.players[0]
	p1.position = Vector2(4770.0, 531.0)
	p1.velocity = Vector2.ZERO
	p1.state = 0
	await get_tree().create_timer(0.2).timeout
	_check(game.arcade_level == 2 and game.scores == [0, 0], "Arcade: ganar sube de nivel y resetea")
	game.scores = [0, 2]
	game.right_of_way = game.players[1]
	p2.is_bot = false
	p2.position = Vector2(30.0, 531.0)
	p2.velocity = Vector2.ZERO
	p2.state = 0
	await get_tree().create_timer(0.2).timeout
	_check(game.arcade_over and game.match_over, "Arcade: perder termina la escalera")
	game.set_arcade(false)
	_check(not game.arcade, "Arcade: desactivado")

	print("")
	if fails.is_empty():
		print("SMOKE OK - todas las mecánicas funcionan")
		get_tree().quit(0)
	else:
		print("SMOKE FAIL: " + ", ".join(fails))
		get_tree().quit(1)
