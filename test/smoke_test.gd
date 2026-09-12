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

	print("")
	if fails.is_empty():
		print("SMOKE OK - todas las mecánicas funcionan")
		get_tree().quit(0)
	else:
		print("SMOKE FAIL: " + ", ".join(fails))
		get_tree().quit(1)
