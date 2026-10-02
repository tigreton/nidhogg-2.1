extends Node
## Trazas de movimiento: registra posición/velocidad/estado de P1 frame a
## frame de física en 6 fases (correr, salto parado, salto con carrerilla,
## dive, rodada, ataque) y escribe res://trace_motion.csv para calibrar.
##   godot --headless --path . res://test/trace_motion.tscn

var game: Node
var p1: Player
var _rows: Array = []
var _f := 0


func _release_all() -> void:
	for a in ["p1_left", "p1_right", "p1_up", "p1_down", "p1_jump", "p1_attack"]:
		Input.action_release(a)


## Reubica a P1 en pie, quieto y sin velocidad en una x segura.
func _at(x: float) -> void:
	p1.position = Vector2(x, 531.0)
	p1.velocity = Vector2.ZERO
	p1.state = Player.State.IDLE
	p1.roll_cd = 0.0
	await _idle(2)


## Avanza n frames de física registrando una fila por frame.
func _idle(frames: int) -> void:
	for i in frames:
		await get_tree().physics_frame
		_f += 1
		_rows.append([_f, "%.4f" % (_f / 60.0), p1.position.x, p1.position.y,
				p1.velocity.x, p1.velocity.y, Player.State.find_key(p1.state), p1.stance])


## Marcador de fase (una fila con solo el nombre, para leer el CSV a ojo).
func _phase(name: String) -> void:
	_rows.append(["# " + name])


func _ready() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	add_child(game)
	await get_tree().create_timer(0.2).timeout
	p1 = game.players[0]
	# P2 lejos (x=4400) para que no interfiera en ninguna fase
	game.players[1].position = Vector2(4400.0, 531.0)
	game.round_lock = 0.0

	# Fase 1: correr 60 frames
	await _at(1600.0)
	_phase("run")
	Input.action_press("p1_right")
	await _idle(60)
	Input.action_release("p1_right")
	await _idle(10)

	# Fase 2: salto de parado (x=1300: sin techo, la escalera está en 1480-1900)
	await _at(1300.0)
	_phase("jump_stand")
	Input.action_press("p1_jump")
	await _idle(1)
	Input.action_release("p1_jump")
	await _idle(55)

	# Fase 3: salto con carrerilla (8 frames de carrera antes; aterriza ~1466)
	await _at(1152.0)
	Input.action_press("p1_right")
	await _idle(8)
	_phase("jump_run")
	Input.action_press("p1_jump")
	await _idle(1)
	Input.action_release("p1_jump")
	await _idle(75)
	Input.action_release("p1_right")

	# Fase 4: dive horizontal (corriendo + abajo + salto)
	await _at(1550.0)
	Input.action_press("p1_right")
	await _idle(10)
	_phase("dive")
	Input.action_press("p1_down")
	Input.action_press("p1_jump")
	await _idle(6)
	Input.action_release("p1_jump")
	Input.action_release("p1_down")
	Input.action_release("p1_right")
	await _idle(60)

	# Fase 5: rodada (parado + abajo + salto)
	await _at(1600.0)
	_phase("roll")
	Input.action_press("p1_down")
	Input.action_press("p1_jump")
	await _idle(2)
	Input.action_release("p1_jump")
	Input.action_release("p1_down")
	await _idle(45)

	# Fase 6: ataque en parado
	await _at(1600.0)
	_phase("attack")
	Input.action_press("p1_attack")
	await _idle(1)
	Input.action_release("p1_attack")
	await _idle(30)

	_release_all()
	var f := FileAccess.open("res://trace_motion.csv", FileAccess.WRITE)
	f.store_line("frame,t,x,y,vx,vy,state,stance")
	for row in _rows:
		f.store_line(",".join(row.map(func(v): return str(v))))
	f.close()
	print("TRAZAS OK - %d filas en res://trace_motion.csv" % _rows.size())
	get_tree().quit(0)
