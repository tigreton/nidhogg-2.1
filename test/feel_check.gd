extends Node
## Verificación numérica headless: choque seco (sin vuelo) y pushbox (sin solape).

var fails := 0


func _ready() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	game.skip_countdown = true
	add_child(game)
	await get_tree().create_timer(0.2).timeout
	var p1: CharacterBody2D = game.players[0]
	var p2: CharacterBody2D = game.players[1]
	for p in [p1, p2]:
		p.is_bot = false
		p.invuln_time = 0.0
		p.has_sword = true

	# --- choque: rebote seco, ambos en el suelo, sin velocidad vertical ---
	p1.position = Vector2(1600.0, 531.0)
	p2.position = Vector2(1656.0, 531.0)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.take_clash(-1)
	p2.take_clash(1)
	var ok_vy: bool = p1.velocity.y == 0.0 and p2.velocity.y == 0.0
	print("%s choque: vy p1=%f p2=%f (0 esperado)" % ["ok  " if ok_vy else "FALLO", p1.velocity.y, p2.velocity.y])
	fails += 0 if ok_vy else 1
	await get_tree().create_timer(0.10).timeout
	var y0 := 531.0
	var ok_floor: bool = absf(p1.position.y - y0) < 24.0 and absf(p2.position.y - y0) < 24.0
	print("%s choque: a 0.1s y p1=%.0f p2=%.0f (en suelo +-24)" % ["ok  " if ok_floor else "FALLO", p1.position.y, p2.position.y])
	fails += 0 if ok_floor else 1
	var ok_slide: bool = p1.position.x < 1600.0 and p2.position.x > 1656.0
	print("%s choque: separados p1=%.0f p2=%.0f" % ["ok  " if ok_slide else "FALLO", p1.position.x, p2.position.x])
	fails += 0 if ok_slide else 1

	# --- pushbox: corriendo uno contra otro no se solapan ---
	p1.state = 0
	p2.state = 0
	p1.position = Vector2(1600.0, 531.0)
	p2.position = Vector2(1656.0, 531.0)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.facing = 1
	p2.facing = -1
	Input.action_press("p1_right")
	Input.action_press("p2_left")
	var min_gap := 999.0
	for i in 60:
		await get_tree().physics_frame
		min_gap = minf(min_gap, absf(p2.position.x - p1.position.x))
	Input.action_release("p1_right")
	Input.action_release("p2_left")
	var ok_gap: bool = min_gap >= 18.0   # 30 nominal menos el avance por frame
	print("%s pushbox: hueco minimo en 1s corriendo = %.1f px (>=18)" % ["ok  " if ok_gap else "FALLO", min_gap])
	fails += 0 if ok_gap else 1

	# --- derribo: 0.6 s de suelo, no 1.0 ---
	p1.state = 0
	p1.position = Vector2(1700.0, 531.0)
	p1.velocity = Vector2.ZERO
	p1.knockdown(1)
	var kd_ok: bool = absf(p1.knockdown_time - 0.6) < 0.35 and p1.knockdown_time < 0.75
	print("%s derribo: knockdown_time=%.2f (KNOCKDOWN_TIME=0.6)" % ["ok  " if kd_ok else "FALLO", Player.KNOCKDOWN_TIME])
	fails += 0 if kd_ok else 1

	print("RESULT: %s (%d fallos)" % ["ALL PASSED" if fails == 0 else "FAILED", fails])
	get_tree().quit(0 if fails == 0 else 1)
