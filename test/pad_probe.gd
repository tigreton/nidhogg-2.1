extends Node
## Prueba headless del mapeo de mandos: inyecta eventos reales de gamepad
## (Input.parse_input_event) y verifica que el juego los lee como teclado.
## P1 = device 0, P2 = device 1; la gestión (revancha, pausa, arena, música)
## solo puede salir del mando de P1.

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


func _btn(dev: int, idx: int, pressed: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.device = dev
	e.button_index = idx
	e.pressed = pressed
	Input.parse_input_event(e)


func _axis(dev: int, axis: int, val: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.device = dev
	e.axis = axis
	e.axis_value = val
	Input.parse_input_event(e)


func _settle() -> void:
	# frames de proceso: el InputSingleton traga el evento inyectado
	await get_tree().process_frame
	await get_tree().process_frame


func _psettle() -> void:
	# frames de FÍSICA: en headless el proceso gira más rápido que la física,
	# y just_pressed caduca a un tick de física — las comprobaciones sobre el
	# jugador esperan aquí para que su _physics_process haya corrido seguro
	for i in 4:
		await get_tree().physics_frame


func _ready() -> void:
	# --- título: el mando de P1 configura la partida y el menú online ---
	var title: Node = load("res://scenes/title.tscn").instantiate()
	add_child(title)
	await get_tree().create_timer(0.2).timeout
	var ws0: int = MatchRules.win_score
	_btn(0, JOY_BUTTON_DPAD_DOWN, true)
	await _settle()
	_btn(0, JOY_BUTTON_DPAD_DOWN, false)
	await _settle()
	_check(MatchRules.win_score != ws0, "Cruceta del mando de P1 cambia los puntos en el título")
	MatchRules.win_score = ws0
	var throw0: bool = MatchRules.allow_throw
	_btn(0, JOY_BUTTON_X, true)
	await _settle()
	_btn(0, JOY_BUTTON_X, false)
	await _settle()
	_check(MatchRules.allow_throw != throw0, "Botón X del mando de P1 alterna lanzar arma")
	MatchRules.allow_throw = throw0
	# SELECT abre el menú online, la cruceta elige y B vuelve
	_btn(0, JOY_BUTTON_BACK, true)
	await _settle()
	_btn(0, JOY_BUTTON_BACK, false)
	await _settle()
	_check(title.net_mode == "menu", "SELECT del mando de P1 abre el menú online")
	var sel0: int = title.net_sel
	_btn(0, JOY_BUTTON_DPAD_DOWN, true)
	await _settle()
	_btn(0, JOY_BUTTON_DPAD_DOWN, false)
	await _settle()
	_check(title.net_sel != sel0, "La cruceta mueve la selección del menú online")
	_btn(0, JOY_BUTTON_B, true)
	await _settle()
	_btn(0, JOY_BUTTON_B, false)
	await _settle()
	_check(title.net_mode == "", "Botón B cierra el menú online")
	title.queue_free()
	await get_tree().process_frame

	# --- juego: mandos de ambos jugadores ---
	game = load("res://scenes/main.tscn").instantiate()
	game.skip_countdown = true
	add_child(game)   # _ready registra teclado + mandos en el InputMap
	await get_tree().create_timer(0.2).timeout
	p1 = game.players[0]
	p2 = game.players[1]
	# suelo limpio y separados (el hielo de 1700-2000 merma la aceleración)
	p1.position = Vector2(1600.0, 531.0)
	p2.position = Vector2(1000.0, 531.0)

	# 1. Stick izquierdo de P1: derecha y estancia alta
	_axis(0, JOY_AXIS_LEFT_X, 0.8)
	await _settle()
	_check(Input.is_action_pressed("p1_right"), "Stick P1 a la derecha activa p1_right")
	var x0: float = p1.position.x
	await get_tree().create_timer(0.25).timeout
	_check(p1.position.x > x0 + 60.0, "P1 corre con el stick de su mando")
	_axis(0, JOY_AXIS_LEFT_X, 0.0)
	await _settle()
	_check(not Input.is_action_pressed("p1_right"), "Stick P1 neutro suelta p1_right")

	# 2. Cruceta de P2 (device 1): izquierda
	_axis(1, JOY_AXIS_LEFT_Y, -0.8)
	await _settle()
	_check(Input.is_action_pressed("p2_up"), "Stick P2 arriba activa p2_up")
	_axis(1, JOY_AXIS_LEFT_Y, 0.0)
	await _settle()
	_btn(1, JOY_BUTTON_DPAD_LEFT, true)
	await _settle()
	_check(Input.is_action_pressed("p2_left"), "Cruceta P2 izquierda activa p2_left")
	var x2: float = p2.position.x
	await get_tree().create_timer(0.25).timeout
	_check(p2.position.x < x2 - 60.0, "P2 corre con la cruceta de su mando")
	_btn(1, JOY_BUTTON_DPAD_LEFT, false)
	await _settle()

	# 3. Botones de acción: A salta (P2), X ataca y B lanza (P1)
	_btn(1, JOY_BUTTON_A, true)
	await _psettle()
	_check(Input.is_action_pressed("p2_jump") and not p2.is_on_floor(), "P2 salta con A")
	_btn(1, JOY_BUTTON_A, false)
	await get_tree().create_timer(1.0).timeout
	_btn(0, JOY_BUTTON_B, true)
	await _psettle()
	_check(Input.is_action_pressed("p1_throw"), "Botón B de P1 activa p1_throw")
	_check(not p1.has_sword, "P1 lanza la espada con B")
	_btn(0, JOY_BUTTON_B, false)
	await get_tree().create_timer(0.3).timeout
	for s in game.projectiles:
		s.queue_free()
	game.projectiles.clear()
	p1.has_sword = true
	_btn(0, JOY_BUTTON_X, true)
	await _psettle()
	_check(Input.is_action_pressed("p1_attack"), "Botón X de P1 activa p1_attack")
	_check(p1.state == 4, "P1 ataca con X")
	_btn(0, JOY_BUTTON_X, false)
	await get_tree().create_timer(0.5).timeout

	# 4. Gestión SOLO en el mando de P1: START de P2 no reinicia
	_btn(1, JOY_BUTTON_START, true)
	await _settle()
	_check(not Input.is_action_pressed("restart"), "START del mando de P2 NO activa revancha")
	_btn(1, JOY_BUTTON_START, false)
	await _settle()
	_btn(0, JOY_BUTTON_START, true)
	await _settle()
	_check(Input.is_action_pressed("restart"), "START del mando de P1 activa revancha")
	_btn(0, JOY_BUTTON_START, false)
	await _settle()
	_btn(1, JOY_BUTTON_BACK, true)
	await _settle()
	_check(not Input.is_action_pressed("pause"), "SELECT del mando de P2 NO pausa")
	_btn(1, JOY_BUTTON_BACK, false)
	await _settle()

	# 5. SELECT de P1 pausa y reanuda (el árbol se congela de verdad)
	_btn(0, JOY_BUTTON_BACK, true)
	await _settle()
	_btn(0, JOY_BUTTON_BACK, false)
	await _settle()
	_check(get_tree().paused, "SELECT del mando de P1 pausa el juego")
	var xp: float = p1.position.x
	Input.action_press("p1_right")
	await get_tree().create_timer(0.25, true).timeout
	Input.action_release("p1_right")
	_check(p1.position.x < xp + 1.0, "Con la pausa del mando P1 no se mueve")
	_btn(0, JOY_BUTTON_BACK, true)
	await _settle()
	_btn(0, JOY_BUTTON_BACK, false)
	await _settle()
	_check(not get_tree().paused, "SELECT de nuevo reanuda")

	# 6. Hombros de P1: arena (L1) y música (R1)
	_btn(1, JOY_BUTTON_LEFT_SHOULDER, true)
	await _settle()
	_check(not Input.is_action_pressed("toggle_arena"), "L1 del mando de P2 NO cambia arena")
	_btn(1, JOY_BUTTON_LEFT_SHOULDER, false)
	await _settle()
	var arena0: int = game.arena_id
	_btn(0, JOY_BUTTON_LEFT_SHOULDER, true)
	await _settle()
	_check(Input.is_action_pressed("toggle_arena"), "L1 del mando de P1 activa toggle_arena")
	_btn(0, JOY_BUTTON_LEFT_SHOULDER, false)
	await get_tree().create_timer(0.1).timeout
	_check(game.arena_id != arena0, "L1 de P1 cambia de arena")
	_btn(0, JOY_BUTTON_RIGHT_SHOULDER, true)
	await _settle()
	_check(Input.is_action_pressed("toggle_music"), "R1 del mando de P1 activa toggle_music")
	_btn(0, JOY_BUTTON_RIGHT_SHOULDER, false)
	await _settle()

	# 7. Vibración al morir: la señal de muerte está conectada y las guardas
	# excluyen a bots, marionetas y al rival por red (sin mando en este PC)
	var wired := false
	for c in p1.died.get_connections():
		if c.callable.get_object() == game:
			wired = true
	_check(wired, "La señal de muerte llega al vibrador del mando")
	_check(game.pad_of(p1) == -1, "Sin mando conectado no hay vibración (headless)")
	p2.is_bot = true
	_check(game.pad_of(p2) == -1, "Un bot no vibra ningún mando")
	p2.is_bot = false
	p2.net_remote = true
	_check(game.pad_of(p2) == -1, "El rival por red no vibra el mando local")
	p2.net_remote = false
	p2.net_puppet = true
	_check(game.pad_of(p2) == -1, "La marioneta del host no vibra aquí")
	p2.net_puppet = false

	# 8. Toast de mandos (autoload PadToast): anuncia a qué jugador pertenece
	PadToast._on_joy_changed(1, true)
	_check(PadToast._label.text.contains("MANDO DE P2"), "Conectar el mando 1 avisa «MANDO DE P2 CONECTADO»")
	PadToast._on_joy_changed(0, true)
	_check(PadToast._label.text.contains("MANDO DE P1"), "Conectar el mando 0 avisa «MANDO DE P1 CONECTADO»")
	PadToast._on_joy_changed(0, false)
	_check(PadToast._label.text.contains("DESCONECTADO"), "Desconectar un mando también se anuncia")

	print("")
	if fails.is_empty():
		print("PAD OK - mandos y gestión de P1 funcionan")
		get_tree().quit(0)
	else:
		print("PAD FAIL: " + ", ".join(fails))
		get_tree().quit(1)
