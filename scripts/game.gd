extends Node2D
## Juego estilo Nidhogg: duelo de esgrima a un golpe. Quien mata gana el "paso"
## y debe correr hasta su meta; el rival reaparece delante para frenarlo.
## Primero en llegar a WIN_SCORE puntos gana el partido.
## Extras: mapa con alturas (puente alto, casa, torre de rocas), modo caos con
## lluvia de rocas (T) y modo 2v2 por equipos (V).

const LEVEL_W := 4800.0
const GROUND_Y := 560.0
const PIT_X0 := 2210.0
const PIT_X1 := 2380.0
const PIT2_X0 := 700.0
const PIT2_X1 := 880.0
const PLAT_X0 := PIT_X0 - 80.0
const PLAT_X1 := PIT_X1 + 80.0
const PLAT_Y := 448.0
const GRASS_X0 := 1150.0
const GRASS_X1 := 1450.0
const GOAL_W := 130.0
const WIN_SCORE := 3
const VIEW_W := 1152.0
const VIEW_H := 648.0
const RESPAWN_DELAY := 2.4
const BOT_CFG := [
	{"react": 0.26, "atk": 0.12, "err": 0.35},  # FÁCIL
	{"react": 0.13, "atk": 0.30, "err": 0.10},  # NORMAL
	{"react": 0.07, "atk": 0.50, "err": 0.02},  # DIFÍCIL
]
# ruta alta: puente de madera sobre el foso central
const BRIDGE_X0 := 1900.0
const BRIDGE_X1 := 2690.0
const BRIDGE_Y := 288.0
# casa con tejado subible (dos faldones escalonados)
const ROOF_L_X0 := 908.0
const ROOF_L_X1 := 1010.0
const ROOF_L_Y := 472.0
const ROOF_H_X0 := 1020.0
const ROOF_H_X1 := 1152.0
const ROOF_H_Y := 406.0
# zona rocosa (derecha del foso): peldaño, peñasco y torre
const STEP_R_X0 := 2856.0
const STEP_R_X1 := 2948.0
const STEP_R_Y := 516.0
const BOULDER_X0 := 3116.0
const BOULDER_X1 := 3344.0
const BOULDER_Y := 440.0
const TOWER_X0 := 3476.0
const TOWER_X1 := 3644.0
const TOWER_Y := 330.0
# peldaño rocoso cerca de la meta izquierda
const STEP_L_X0 := 500.0
const STEP_L_X1 := 592.0
const STEP_L_Y := 516.0

const ROCK_WARN_TIME := 0.85
const ROCK_FALL_SPEED := 1900.0

const P1_COLOR := Color("ffb324")
const P2_COLOR := Color("39d7ff")
const P3_COLOR := Color("ff7847")
const P4_COLOR := Color("4f8dff")

var players: Array[Player] = []
var right_of_way: Player = null
var scores := [0, 0]
var match_over := false
var round_lock := 0.0
var respawn_timers := [0.0, 0.0]
var shake_time := 0.0
var bot_level := 1        # dificultad bots equipo derecho (0 = OFF solo afecta a P2)
var ally_bot_level := 2   # dificultad del aliado P3 (0 = OFF)
var hitstop_active := false
var projectiles: Array[SwordProjectile] = []
var pickups: Array[SwordPickup] = []
var rocks: Array[FallingRock] = []
var goal_polys: Array[Polygon2D] = []
var stats: Array[Dictionary] = []
var last_x := [0.0, 0.0]
var _tops: Array[Dictionary] = []   # superficies elevadas {x0, x1, y}
var chaos := false
var chaos_timer := 0.0
var chaos_count := 0
var mode_2v2 := false

var camera: Camera2D
var msg_label: Label
var run_label: Label
var dim: ColorRect
var pause_label: Label
var stats_label: Label
var score_labels: Array[Label] = []
var msg_tween: Tween
var music: Music


func _fresh_stats() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in players.size():
		out.append({"kills": 0, "deaths": 0, "throws": 0, "dist": 0.0})
	return out


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	_build_level()
	_build_players()
	stats = _fresh_stats()
	_build_camera()
	_build_hud()
	music = Music.new()
	add_child(music)
	_start_round()


func _process(_delta: float) -> void:
	var a := 0.13 + 0.06 * sin(Time.get_ticks_msec() * 0.003)
	for gp in goal_polys:
		gp.color.a = a
	var rw := right_of_way
	if rw != null and not match_over and rw.state != Player.State.DEAD and round_lock <= 0.0:
		run_label.visible = true
		run_label.text = "¡P%d CORRE!  %s" % [rw.player_id, "»»»" if rw.goal_dir > 0 else "«««"]
		run_label.add_theme_color_override("font_color", rw.color)
	else:
		run_label.visible = false


func sfx(pos: Vector2, id: String, db := -10.0) -> void:
	Sfx.play(self, pos, id, db)


func in_grass(x: float) -> bool:
	return x > GRASS_X0 and x < GRASS_X1


func _team(p: Player) -> int:
	return (p.player_id - 1) % 2


func _foes_of(p: Player) -> Array[Player]:
	var out: Array[Player] = []
	for q in players:
		if q != p and _team(q) != _team(p):
			out.append(q)
	return out


func _nearest_foe(p: Player) -> Player:
	var best: Player = null
	var bd := INF
	for q in _foes_of(p):
		if q.state == Player.State.DEAD:
			continue
		var d := absf(q.position.x - p.position.x)
		if d < bd:
			bd = d
			best = q
	return best


func _living_teammate(p: Player) -> Player:
	for q in players:
		if q != p and _team(q) == _team(p) and q.state != Player.State.DEAD:
			return q
	return null


func _setup_input() -> void:
	var defs := {
		"p1_left": [KEY_A], "p1_right": [KEY_D], "p1_up": [KEY_W], "p1_down": [KEY_S],
		"p1_jump": [KEY_W], "p1_attack": [KEY_F], "p1_throw": [KEY_G],
		"p2_left": [KEY_LEFT], "p2_right": [KEY_RIGHT], "p2_up": [KEY_UP], "p2_down": [KEY_DOWN],
		"p2_jump": [KEY_UP], "p2_attack": [KEY_K], "p2_throw": [KEY_L],
		"restart": [KEY_R],
		"toggle_bot": [KEY_B], "toggle_music": [KEY_M],
		"pause": [KEY_ESCAPE], "bot_vs_bot": [KEY_N],
		"toggle_ally": [KEY_H], "toggle_2v2": [KEY_V], "toggle_chaos": [KEY_T],
		# P3/P4 solo se controlan por bot: acciones registradas vacías
		"p3_left": [], "p3_right": [], "p3_up": [], "p3_down": [],
		"p3_jump": [], "p3_attack": [], "p3_throw": [],
		"p4_left": [], "p4_right": [], "p4_up": [], "p4_down": [],
		"p4_jump": [], "p4_attack": [], "p4_throw": [],
	}
	for action in defs.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in defs[action]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(action, e)
	# mandos: P1 = gamepad 0, P2 = gamepad 1
	var pad_axes := {
		"p1_left": [0, JOY_AXIS_LEFT_X, -1.0], "p1_right": [0, JOY_AXIS_LEFT_X, 1.0],
		"p1_up": [0, JOY_AXIS_LEFT_Y, -1.0], "p1_down": [0, JOY_AXIS_LEFT_Y, 1.0],
		"p2_left": [1, JOY_AXIS_LEFT_X, -1.0], "p2_right": [1, JOY_AXIS_LEFT_X, 1.0],
		"p2_up": [1, JOY_AXIS_LEFT_Y, -1.0], "p2_down": [1, JOY_AXIS_LEFT_Y, 1.0],
	}
	var pad_buttons := {
		"p1_jump": [0, JOY_BUTTON_A], "p1_attack": [0, JOY_BUTTON_X], "p1_throw": [0, JOY_BUTTON_B],
		"p2_jump": [1, JOY_BUTTON_A], "p2_attack": [1, JOY_BUTTON_X], "p2_throw": [1, JOY_BUTTON_B],
		"restart": [-1, JOY_BUTTON_START],
	}
	for action in pad_axes.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var ev := InputEventJoypadMotion.new()
		ev.device = pad_axes[action][0]
		ev.axis = pad_axes[action][1]
		ev.axis_value = pad_axes[action][2]
		InputMap.action_add_event(action, ev)
	for action in pad_buttons.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var eb := InputEventJoypadButton.new()
		eb.device = pad_buttons[action][0]
		eb.button_index = pad_buttons[action][1]
		InputMap.action_add_event(action, eb)


func _build_level() -> void:
	_poly(PackedVector2Array([Vector2(0, 0), Vector2(LEVEL_W, 0), Vector2(LEVEL_W, 720), Vector2(0, 720)]), Color(0.055, 0.05, 0.09), -10)
	_poly(_circle_points(LEVEL_W * 0.5, 118.0, 74.0), Color(0.14, 0.13, 0.20), -9)
	_poly(_circle_points(LEVEL_W * 0.5 - 30.0, 92.0, 13.0), Color(0.10, 0.09, 0.15), -9)
	_poly(_circle_points(LEVEL_W * 0.5 + 26.0, 150.0, 9.0), Color(0.10, 0.09, 0.15), -9)
	_hills()
	_clouds()
	var px := 340.0
	while px < LEVEL_W - 200.0:
		if not (px > PIT_X0 - 130.0 and px < PIT_X1 + 130.0):
			_poly(PackedVector2Array([Vector2(px - 26, GROUND_Y), Vector2(px + 26, GROUND_Y), Vector2(px + 26, 130.0), Vector2(px - 26, 130.0)]), Color(0.085, 0.08, 0.135), -5)
			_poly(PackedVector2Array([Vector2(px - 36, 142.0), Vector2(px + 36, 142.0), Vector2(px + 36, 122.0), Vector2(px - 36, 122.0)]), Color(0.11, 0.10, 0.17), -5)
		px += 640.0
	_floor_segment(0.0, PIT2_X0)
	_floor_segment(PIT2_X1, PIT_X0)
	_floor_segment(PIT_X1, LEVEL_W)
	_poly(PackedVector2Array([Vector2(PIT_X0, GROUND_Y + 4), Vector2(PIT_X1, GROUND_Y + 4), Vector2(PIT_X1 - 26, 800.0), Vector2(PIT_X0 + 26, 800.0)]), Color(0.30, 0.07, 0.09), -6)
	_poly(PackedVector2Array([Vector2(PIT2_X0, GROUND_Y + 4), Vector2(PIT2_X1, GROUND_Y + 4), Vector2(PIT2_X1 - 26, 800.0), Vector2(PIT2_X0 + 26, 800.0)]), Color(0.30, 0.07, 0.09), -6)
	_platform(PLAT_X0, PLAT_X1, PLAT_Y)
	_bridge()
	_house()
	_rocks_zone()
	# hierba alta: oculta la estancia de quien entra
	_poly(PackedVector2Array([Vector2(GRASS_X0, GROUND_Y), Vector2(GRASS_X1, GROUND_Y), Vector2(GRASS_X1, GROUND_Y - 34.0), Vector2(GRASS_X0, GROUND_Y - 34.0)]), Color(0.09, 0.18, 0.11), 2)
	for i in 22:
		var gx := GRASS_X0 + (GRASS_X1 - GRASS_X0) * (float(i) + 0.5) / 22.0
		var gh := 44.0 + 20.0 * randf()
		_poly(PackedVector2Array([Vector2(gx - 7, GROUND_Y), Vector2(gx + 7, GROUND_Y), Vector2(gx + randf_range(-7.0, 7.0), GROUND_Y - gh)]), Color(0.13, 0.30, 0.17).lightened(0.08 * randf()), 3)
	_flowers()
	# escalera de plataformas (subida a la ruta alta por la izquierda)
	_platform(1480.0, 1660.0, 448.0)
	_platform(1660.0, 1800.0, 368.0)
	_platform(1800.0, 1900.0, 288.0)
	_wall(-46.0, 6.0)
	_wall(LEVEL_W - 6.0, LEVEL_W + 46.0)
	_goal_zone(LEVEL_W - GOAL_W, LEVEL_W, P1_COLOR)
	_goal_zone(0.0, GOAL_W, P2_COLOR)
	_torch_at(210.0)
	_torch_at(LEVEL_W - 210.0)
	_torch_at(1032.0)


func _register_top(x0: float, x1: float, y: float) -> void:
	_tops.append({"x0": x0, "x1": x1, "y": y})


func _top_below(x: float, from_y: float) -> float:
	var best := -1.0
	for t in _tops:
		if x > t["x0"] and x < t["x1"] and t["y"] >= from_y - 4.0:
			if best < 0.0 or t["y"] < best:
				best = t["y"]
	return best


func _hills() -> void:
	# dos capas de colinas nocturnas tras las ruinas
	var cx := -100.0
	var i := 0
	while cx < LEVEL_W + 200.0:
		var r := 150.0 + 90.0 * ((i * 37) % 5)
		_poly(_circle_points(cx, 700.0, r), Color(0.075, 0.068, 0.115), -8)
		cx += r * 0.9
		i += 1
	cx = -150.0
	i = 2
	while cx < LEVEL_W + 200.0:
		var r := 90.0 + 60.0 * ((i * 53) % 4)
		_poly(_circle_points(cx, 720.0, r), Color(0.065, 0.06, 0.10), -7)
		cx += r * 1.1
		i += 1


class Cloud extends Node2D:
	## Nube que deriva lentamente y se envuelve por los bordes del nivel.
	var speed := 12.0
	var extent := 4800.0

	func _init(s: float, ext: float) -> void:
		speed = s
		extent = ext

	func _process(delta: float) -> void:
		position.x += speed * delta
		if position.x > extent + 300.0:
			position.x = -300.0

	func _draw() -> void:
		var col := Color(0.13, 0.125, 0.19, 0.85)
		for b in [Vector2(-46, 4), Vector2(0, -8), Vector2(46, 4)]:
			var r: float = 30.0 if b.y < 0.0 else 24.0
			draw_circle(b, r, col)
		draw_rect(Rect2(-60, 0, 120, 18), col)


func _clouds() -> void:
	for i in 6:
		var c := Cloud.new(6.0 + 4.0 * ((i * 29) % 4), LEVEL_W)
		c.position = Vector2(200.0 + 730.0 * i + 120.0 * ((i * 41) % 3), 70.0 + 46.0 * ((i * 17) % 4))
		c.z_index = -6
		add_child(c)


class Torch extends Node2D:
	## Antorcha con llama parpadeante para dar vida a las metas y la aldea.
	var t := 0.0

	func _ready() -> void:
		t = randf() * 10.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		draw_line(Vector2(0, 0), Vector2(0, -88), Color(0.16, 0.12, 0.10), 8.0)
		draw_line(Vector2(0, 0), Vector2(0, -88), Color(0.30, 0.22, 0.15), 4.0)
		draw_circle(Vector2(0, -94), 9.0, Color(0.20, 0.16, 0.13))
		var f := 1.0 + 0.16 * sin(t * 13.0) + 0.08 * sin(t * 29.0)
		draw_circle(Vector2(0, -102), 26.0 * f, Color(1.0, 0.55, 0.15, 0.09))
		draw_colored_polygon(PackedVector2Array([Vector2(-7, -96), Vector2(0, -96.0 - 24.0 * f), Vector2(7, -96)]), Color(1.0, 0.60, 0.16, 0.95))
		draw_colored_polygon(PackedVector2Array([Vector2(-3.4, -96), Vector2(0, -96.0 - 13.0 * f), Vector2(3.4, -96)]), Color(1.0, 0.88, 0.45))


func _torch_at(x: float) -> void:
	var t := Torch.new()
	t.position = Vector2(x, GROUND_Y)
	t.z_index = 1
	add_child(t)


class GlowSpot extends Node2D:
	## Resplandor cálido y pulsante (ventanas de la casa).
	var t := 0.0
	var radius := 30.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var f := 0.8 + 0.2 * sin(t * 2.2)
		draw_circle(Vector2.ZERO, radius * f, Color(1.0, 0.75, 0.3, 0.10))


func _bridge() -> void:
	# puente de madera en alto: ruta alternativa sobre el foso central
	_static_box(BRIDGE_X0, BRIDGE_Y, BRIDGE_X1, BRIDGE_Y + 16.0)
	_register_top(BRIDGE_X0, BRIDGE_X1, BRIDGE_Y)
	_poly(PackedVector2Array([Vector2(BRIDGE_X0, BRIDGE_Y), Vector2(BRIDGE_X1, BRIDGE_Y), Vector2(BRIDGE_X1, BRIDGE_Y + 16.0), Vector2(BRIDGE_X0, BRIDGE_Y + 16.0)]), Color(0.30, 0.21, 0.13), -4)
	_poly(PackedVector2Array([Vector2(BRIDGE_X0, BRIDGE_Y), Vector2(BRIDGE_X1, BRIDGE_Y), Vector2(BRIDGE_X1, BRIDGE_Y + 5), Vector2(BRIDGE_X0, BRIDGE_Y + 5)]), Color(0.45, 0.33, 0.20), -4)
	var bx := BRIDGE_X0 + 34.0
	while bx < BRIDGE_X1 - 10.0:
		_poly(PackedVector2Array([Vector2(bx - 2, BRIDGE_Y + 5), Vector2(bx + 2, BRIDGE_Y + 5), Vector2(bx + 2, BRIDGE_Y + 16.0), Vector2(bx - 2, BRIDGE_Y + 16.0)]), Color(0.20, 0.14, 0.09), -4)
		bx += 52.0
	# postes y cuerda en los extremos
	for endx in [BRIDGE_X0 + 6.0, BRIDGE_X1 - 6.0]:
		_poly(PackedVector2Array([Vector2(endx - 4, BRIDGE_Y), Vector2(endx + 4, BRIDGE_Y), Vector2(endx + 4, BRIDGE_Y - 46.0), Vector2(endx - 4, BRIDGE_Y - 46.0)]), Color(0.25, 0.18, 0.11), -4)
	_poly(PackedVector2Array([Vector2(BRIDGE_X0 + 6.0, BRIDGE_Y - 44.0), Vector2(BRIDGE_X1 - 6.0, BRIDGE_Y - 44.0), Vector2(BRIDGE_X1 - 6.0, BRIDGE_Y - 40.0), Vector2(BRIDGE_X0 + 6.0, BRIDGE_Y - 40.0)]), Color(0.35, 0.28, 0.20), -4)


func _house() -> void:
	# fachada y tejado de la aldea; el muro es decorativo: se pasa por la puerta
	var wall_col := Color(0.23, 0.17, 0.15)
	var wall_lite := Color(0.29, 0.22, 0.19)
	_poly(PackedVector2Array([Vector2(920, GROUND_Y), Vector2(1140, GROUND_Y), Vector2(1140, 430.0), Vector2(920, 430.0)]), wall_col, -5)
	_poly(PackedVector2Array([Vector2(920, 430.0), Vector2(1140, 430.0), Vector2(1140, 424.0), Vector2(920, 424.0)]), wall_lite, -5)
	# puerta (paso libre) y ventana cálida
	_poly(PackedVector2Array([Vector2(956, GROUND_Y), Vector2(1008, GROUND_Y), Vector2(1008, 498.0), Vector2(982, 486.0), Vector2(956, 498.0)]), Color(0.12, 0.08, 0.07), -4)
	_poly(PackedVector2Array([Vector2(999, 530.0), Vector2(1003, 530.0), Vector2(1003, 534.0), Vector2(999, 534.0)]), Color(0.75, 0.62, 0.30), -3)
	var win := GlowSpot.new()
	win.position = Vector2(1072, 514)
	win.radius = 34.0
	win.z_index = -3
	add_child(win)
	_poly(PackedVector2Array([Vector2(1050, 494.0), Vector2(1094, 494.0), Vector2(1094, 534.0), Vector2(1050, 534.0)]), Color(1.0, 0.78, 0.35, 0.85), -4)
	_poly(PackedVector2Array([Vector2(1070, 494.0), Vector2(1074, 494.0), Vector2(1074, 534.0), Vector2(1070, 534.0)]), Color(0.14, 0.10, 0.08), -3)
	_poly(PackedVector2Array([Vector2(1050, 512.0), Vector2(1094, 512.0), Vector2(1094, 516.0), Vector2(1050, 516.0)]), Color(0.14, 0.10, 0.08), -3)
	# chimenea con humo
	_poly(PackedVector2Array([Vector2(1088, 330.0), Vector2(1116, 330.0), Vector2(1116, 412.0), Vector2(1088, 412.0)]), Color(0.20, 0.15, 0.14), -4)
	_poly(PackedVector2Array([Vector2(1084, 330.0), Vector2(1120, 330.0), Vector2(1120, 320.0), Vector2(1084, 320.0)]), Color(0.26, 0.19, 0.17), -4)
	var smoke := CPUParticles2D.new()
	smoke.position = Vector2(1102, 314)
	smoke.z_index = -3
	smoke.amount = 10
	smoke.lifetime = 2.6
	smoke.direction = Vector2.UP
	smoke.spread = 16.0
	smoke.initial_velocity_min = 14.0
	smoke.initial_velocity_max = 30.0
	smoke.gravity = Vector2(0, -34)
	smoke.scale_amount_min = 3.0
	smoke.scale_amount_max = 7.0
	smoke.color = Color(0.5, 0.5, 0.55, 0.16)
	add_child(smoke)
	# faldones de tejado subibles (superficies reales)
	_roof_slab(ROOF_L_X0, ROOF_L_X1, ROOF_L_Y)
	_roof_slab(ROOF_H_X0, ROOF_H_X1, ROOF_H_Y)
	# tejas decorativas bajo cada faldón
	for slab in [[ROOF_L_X0, ROOF_L_X1, ROOF_L_Y], [ROOF_H_X0, ROOF_H_X1, ROOF_H_Y]]:
		var x0: float = slab[0]
		var x1: float = slab[1]
		var y: float = slab[2]
		var sx := x0 + 14.0
		while sx < x1 - 8.0:
			_poly(PackedVector2Array([Vector2(sx, y + 16.0), Vector2(sx + 10.0, y + 16.0), Vector2(sx + 16.0, y + 30.0), Vector2(sx + 6.0, y + 30.0)]), Color(0.16, 0.10, 0.10), -4)
			sx += 26.0
	# valla entre el peldaño rocoso y el foso pequeño
	_fence(600.0, 690.0)


func _roof_slab(x0: float, x1: float, y: float) -> void:
	_static_box(x0, y, x1, y + 16.0)
	_register_top(x0, x1, y)
	_poly(PackedVector2Array([Vector2(x0, y), Vector2(x1, y), Vector2(x1, y + 16.0), Vector2(x0, y + 16.0)]), Color(0.33, 0.15, 0.13), -4)
	_poly(PackedVector2Array([Vector2(x0, y), Vector2(x1, y), Vector2(x1, y + 5), Vector2(x0, y + 5)]), Color(0.48, 0.24, 0.20), -4)


func _fence(x0: float, x1: float) -> void:
	var fx := x0
	while fx <= x1:
		_poly(PackedVector2Array([Vector2(fx - 3, GROUND_Y), Vector2(fx + 3, GROUND_Y), Vector2(fx + 3, GROUND_Y - 42.0), Vector2(fx - 3, GROUND_Y - 42.0)]), Color(0.22, 0.16, 0.12), -3)
		fx += 30.0
	_poly(PackedVector2Array([Vector2(x0 - 6, GROUND_Y - 34.0), Vector2(x1 + 6, GROUND_Y - 34.0), Vector2(x1 + 6, GROUND_Y - 29.0), Vector2(x0 - 6, GROUND_Y - 29.0)]), Color(0.26, 0.19, 0.14), -3)
	_poly(PackedVector2Array([Vector2(x0 - 6, GROUND_Y - 18.0), Vector2(x1 + 6, GROUND_Y - 18.0), Vector2(x1 + 6, GROUND_Y - 13.0), Vector2(x0 - 6, GROUND_Y - 13.0)]), Color(0.26, 0.19, 0.14), -3)


func _flowers() -> void:
	for i in 12:
		var fx := GRASS_X0 + 20.0 + randf() * (GRASS_X1 - GRASS_X0 - 40.0)
		var col: Color = [Color(0.9, 0.5, 0.6), Color(0.95, 0.85, 0.4), Color(0.7, 0.6, 0.95)][i % 3]
		_poly(PackedVector2Array([Vector2(fx - 2.5, GROUND_Y - 26.0), Vector2(fx + 2.5, GROUND_Y - 26.0), Vector2(fx + 2.5, GROUND_Y - 38.0), Vector2(fx - 2.5, GROUND_Y - 38.0)]), Color(0.10, 0.24, 0.13), 2)
		_poly(_circle_points(fx, GROUND_Y - 42.0, 4.5, 10), col, 2)


func _boulder_shape(x0: float, x1: float, top: float, base: float, col: Color, z: int) -> void:
	var mid := (x0 + x1) * 0.5
	var pts := PackedVector2Array([
		Vector2(x0 - 8, base), Vector2(x0 - 3, top + 22.0), Vector2(mid - (x1 - x0) * 0.22, top),
		Vector2(mid + (x1 - x0) * 0.10, top - 6.0), Vector2(x1 + 2, top + 18.0), Vector2(x1 + 9, base),
	])
	_poly(pts, col, z)
	_poly(PackedVector2Array([Vector2(mid - (x1 - x0) * 0.22, top), Vector2(mid + (x1 - x0) * 0.10, top - 6.0), Vector2(mid + (x1 - x0) * 0.18, top + 5.0), Vector2(mid - (x1 - x0) * 0.12, top + 6.0)]), col.lightened(0.10), z)
	# grietas
	_poly(PackedVector2Array([Vector2(mid - 8, top + 20.0), Vector2(mid - 4, top + 26.0), Vector2(mid - 9, top + 34.0), Vector2(mid - 13, top + 27.0)]), col.darkened(0.25), z)


func _rock_step(x0: float, x1: float, top: float) -> void:
	_static_box(x0, top, x1, GROUND_Y + 60.0)
	_register_top(x0, x1, top)
	_boulder_shape(x0, x1, top, GROUND_Y + 8.0, Color(0.24, 0.22, 0.28), -4)
	_poly(PackedVector2Array([Vector2(x0, top), Vector2(x1, top), Vector2(x1, top + 5), Vector2(x0, top + 5)]), Color(0.38, 0.35, 0.42), -4)


func _rocks_zone() -> void:
	# peldaño rocoso junto a la meta izquierda
	_rock_step(STEP_L_X0, STEP_L_X1, STEP_L_Y)
	# zona rocosa de la derecha: peldaño, peñasco y torre de piedra
	_rock_step(STEP_R_X0, STEP_R_X1, STEP_R_Y)
	_static_box(BOULDER_X0, BOULDER_Y, BOULDER_X1, GROUND_Y + 60.0)
	_register_top(BOULDER_X0, BOULDER_X1, BOULDER_Y)
	_boulder_shape(BOULDER_X0, BOULDER_X1, BOULDER_Y, GROUND_Y + 8.0, Color(0.26, 0.24, 0.31), -4)
	_poly(PackedVector2Array([Vector2(BOULDER_X0, BOULDER_Y), Vector2(BOULDER_X1, BOULDER_Y), Vector2(BOULDER_X1, BOULDER_Y + 5), Vector2(BOULDER_X0, BOULDER_Y + 5)]), Color(0.40, 0.37, 0.46), -4)
	# torre: pilar visual + plataforma de piedra en la cima
	_poly(PackedVector2Array([Vector2(TOWER_X0 + 24, GROUND_Y), Vector2(TOWER_X1 - 24, GROUND_Y), Vector2(TOWER_X1 - 34, TOWER_Y + 16.0), Vector2(TOWER_X0 + 34, TOWER_Y + 16.0)]), Color(0.22, 0.20, 0.27), -4)
	_static_box(TOWER_X0, TOWER_Y, TOWER_X1, TOWER_Y + 16.0)
	_register_top(TOWER_X0, TOWER_X1, TOWER_Y)
	_poly(PackedVector2Array([Vector2(TOWER_X0, TOWER_Y), Vector2(TOWER_X1, TOWER_Y), Vector2(TOWER_X1, TOWER_Y + 16.0), Vector2(TOWER_X0, TOWER_Y + 16.0)]), Color(0.29, 0.27, 0.35), -4)
	_poly(PackedVector2Array([Vector2(TOWER_X0, TOWER_Y), Vector2(TOWER_X1, TOWER_Y), Vector2(TOWER_X1, TOWER_Y + 5), Vector2(TOWER_X0, TOWER_Y + 5)]), Color(0.44, 0.41, 0.52), -4)
	# gallardete en la torre
	_poly(PackedVector2Array([Vector2((TOWER_X0 + TOWER_X1) * 0.5, TOWER_Y - 2.0), Vector2((TOWER_X0 + TOWER_X1) * 0.5, TOWER_Y - 52.0)]), Color(0.30, 0.22, 0.14), -3)
	_poly(PackedVector2Array([Vector2((TOWER_X0 + TOWER_X1) * 0.5, TOWER_Y - 50.0), Vector2((TOWER_X0 + TOWER_X1) * 0.5 + 34.0, TOWER_Y - 44.0), Vector2((TOWER_X0 + TOWER_X1) * 0.5, TOWER_Y - 30.0)]), Color(0.75, 0.30, 0.22), -3)
	# piedras sueltas decorativas
	for r in [[2560.0, 12.0], [3760.0, 16.0], [4180.0, 10.0], [640.0, 11.0]]:
		_poly(_circle_points(r[0], GROUND_Y - r[1] * 0.4, r[1], 9), Color(0.19, 0.18, 0.23), -3)


func _poly(points: PackedVector2Array, col: Color, z: int) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = points
	p.color = col
	p.z_index = z
	add_child(p)
	return p


func _circle_points(cx: float, cy: float, r: float, seg := 26) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in seg:
		var a := TAU * float(i) / float(seg)
		pts.append(Vector2(cx + cos(a) * r, cy + sin(a) * r))
	return pts


func _static_box(x0: float, y0: float, x1: float, y1: float) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(x1 - x0, y1 - y0)
	cs.shape = rect
	cs.position = Vector2((x0 + x1) * 0.5, (y0 + y1) * 0.5)
	body.add_child(cs)
	add_child(body)


func _floor_segment(x0: float, x1: float) -> void:
	_static_box(x0, GROUND_Y, x1, GROUND_Y + 140.0)
	_poly(PackedVector2Array([Vector2(x0, GROUND_Y), Vector2(x1, GROUND_Y), Vector2(x1, GROUND_Y + 140.0), Vector2(x0, GROUND_Y + 140.0)]), Color(0.14, 0.13, 0.19), -4)
	_poly(PackedVector2Array([Vector2(x0, GROUND_Y), Vector2(x1, GROUND_Y), Vector2(x1, GROUND_Y + 6), Vector2(x0, GROUND_Y + 6)]), Color(0.30, 0.27, 0.37), -4)


func _platform(x0: float, x1: float, y: float) -> void:
	_static_box(x0, y, x1, y + 16.0)
	_register_top(x0, x1, y)
	_poly(PackedVector2Array([Vector2(x0, y), Vector2(x1, y), Vector2(x1, y + 16.0), Vector2(x0, y + 16.0)]), Color(0.20, 0.18, 0.27), -4)
	_poly(PackedVector2Array([Vector2(x0, y), Vector2(x1, y), Vector2(x1, y + 5), Vector2(x0, y + 5)]), Color(0.34, 0.31, 0.42), -4)


func _wall(x0: float, x1: float) -> void:
	_static_box(x0, 0.0, x1, GROUND_Y + 140.0)
	_poly(PackedVector2Array([Vector2(x0, 0.0), Vector2(x1, 0.0), Vector2(x1, GROUND_Y + 140.0), Vector2(x0, GROUND_Y + 140.0)]), Color(0.11, 0.10, 0.16), -4)


func _goal_zone(x0: float, x1: float, col: Color) -> void:
	goal_polys.append(_poly(PackedVector2Array([Vector2(x0, 110.0), Vector2(x1, 110.0), Vector2(x1, GROUND_Y), Vector2(x0, GROUND_Y)]), Color(col.r, col.g, col.b, 0.15), -3))
	var cx := (x0 + x1) * 0.5
	_poly(PackedVector2Array([Vector2(cx - 3, 190.0), Vector2(cx + 3, 190.0), Vector2(cx + 3, GROUND_Y), Vector2(cx - 3, GROUND_Y)]), Color(0.12, 0.11, 0.18), -3)
	var inward := 1.0 if x0 > LEVEL_W * 0.5 else -1.0
	_poly(PackedVector2Array([Vector2(cx, 196.0), Vector2(cx + inward * 52.0, 210.0), Vector2(cx, 226.0)]), col, -3)


func _build_players() -> void:
	var ps := preload("res://scenes/player.tscn")
	var p1 := ps.instantiate() as Player
	p1.player_id = 1
	p1.color = P1_COLOR
	p1.goal_dir = 1
	add_child(p1)
	players.append(p1)
	var p2 := ps.instantiate() as Player
	p2.player_id = 2
	p2.color = P2_COLOR
	p2.goal_dir = -1
	add_child(p2)
	players.append(p2)
	for p in players:
		p.threw_sword.connect(_on_threw_sword)


func set_mode_2v2(on: bool) -> void:
	if on == mode_2v2:
		return
	mode_2v2 = on
	if on:
		var ps := preload("res://scenes/player.tscn")
		var p3 := ps.instantiate() as Player
		p3.player_id = 3
		p3.color = P3_COLOR
		p3.goal_dir = 1
		p3.is_bot = true
		add_child(p3)
		players.append(p3)
		var p4 := ps.instantiate() as Player
		p4.player_id = 4
		p4.color = P4_COLOR
		p4.goal_dir = -1
		p4.is_bot = true
		add_child(p4)
		players.append(p4)
		for p in [p3, p4]:
			p.threw_sword.connect(_on_threw_sword)
		ally_bot_level = 2
	else:
		for i in [3, 2]:
			if players.size() > i:
				players[i].queue_free()
				players.remove_at(i)
	for s in projectiles:
		s.queue_free()
	projectiles.clear()
	for pk in pickups:
		pk.queue_free()
	pickups.clear()
	set_chaos(false)
	respawn_timers.resize(players.size())
	respawn_timers.fill(0.0)
	last_x.resize(players.size())
	last_x.fill(0.0)
	stats = _fresh_stats()
	scores = [0, 0]
	match_over = false
	stats_label.visible = false
	camera.zoom = Vector2(0.9, 0.9) if mode_2v2 else Vector2.ONE
	_update_hud()
	_start_round()
	show_msg("MODO 2v2: %s" % ("P1·P3 vs P2·P4" if mode_2v2 else "DESACTIVADO"), 1.0)


func set_chaos(on: bool) -> void:
	if on == chaos:
		return
	chaos = on
	chaos_timer = 1.0
	for r in rocks:
		r.queue_free()
	rocks.clear()
	if on:
		show_msg("LLUVIA DE ROCAS: ACTIVADA", 1.0)
	else:
		show_msg("LLUVIA DE ROCAS: DESACTIVADA", 0.8)


func _build_camera() -> void:
	camera = Camera2D.new()
	camera.position = Vector2(VIEW_W * 0.5, VIEW_H * 0.5 + 6.0)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.5
	camera.limit_left = 0
	camera.limit_right = int(LEVEL_W)
	camera.limit_top = 0
	camera.limit_bottom = 720
	add_child(camera)
	camera.make_current()


func _build_hud() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 10
	add_child(cl)

	var l1 := Label.new()
	l1.text = "P1  0  »"
	l1.position = Vector2(28, 16)
	l1.add_theme_font_size_override("font_size", 40)
	l1.add_theme_color_override("font_color", P1_COLOR)
	l1.add_theme_color_override("font_outline_color", Color.BLACK)
	l1.add_theme_constant_override("outline_size", 10)
	cl.add_child(l1)
	score_labels.append(l1)

	var l2 := Label.new()
	l2.text = "«  0  P2"
	l2.position = Vector2(VIEW_W - 340.0, 16)
	l2.size = Vector2(312, 60)
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l2.add_theme_font_size_override("font_size", 40)
	l2.add_theme_color_override("font_color", P2_COLOR)
	l2.add_theme_color_override("font_outline_color", Color.BLACK)
	l2.add_theme_constant_override("outline_size", 10)
	cl.add_child(l2)
	score_labels.append(l2)

	msg_label = Label.new()
	msg_label.position = Vector2(0, VIEW_H * 0.26)
	msg_label.size = Vector2(VIEW_W, 130)
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.add_theme_font_size_override("font_size", 76)
	msg_label.add_theme_color_override("font_color", Color.WHITE)
	msg_label.add_theme_color_override("font_outline_color", Color.BLACK)
	msg_label.add_theme_constant_override("outline_size", 14)
	msg_label.modulate.a = 0.0
	cl.add_child(msg_label)

	var hint := Label.new()
	hint.text = "P1: A/D mover · W saltar/arriba · S agachar · F atacar · G lanzar    P2: ←/→ · ↑ · ↓ · K atacar · L lanzar    R: revancha\nB: bot P2 · H: aliado P3 · N: bot vs bot · V: 2v2 · T: lluvia de rocas · M: música · Mando: stick mover · A saltar · X atacar · B lanzar"
	hint.position = Vector2(22, VIEW_H - 64)
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.62, 0.60, 0.72))
	cl.add_child(hint)

	run_label = Label.new()
	run_label.position = Vector2(0, 64)
	run_label.size = Vector2(VIEW_W, 44)
	run_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	run_label.add_theme_font_size_override("font_size", 30)
	run_label.add_theme_color_override("font_outline_color", Color.BLACK)
	run_label.add_theme_constant_override("outline_size", 8)
	run_label.visible = false
	cl.add_child(run_label)

	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size = Vector2(VIEW_W, VIEW_H)
	dim.visible = false
	cl.add_child(dim)

	pause_label = Label.new()
	pause_label.text = "PAUSA"
	pause_label.position = Vector2(0, VIEW_H * 0.4)
	pause_label.size = Vector2(VIEW_W, 80)
	pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_label.add_theme_font_size_override("font_size", 64)
	pause_label.add_theme_color_override("font_color", Color.WHITE)
	pause_label.visible = false
	cl.add_child(pause_label)

	stats_label = Label.new()
	stats_label.position = Vector2(0, VIEW_H * 0.40)
	stats_label.size = Vector2(VIEW_W, 190)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 22)
	stats_label.add_theme_color_override("font_color", Color(0.85, 0.83, 0.90))
	stats_label.add_theme_color_override("font_outline_color", Color.BLACK)
	stats_label.add_theme_constant_override("outline_size", 6)
	stats_label.visible = false
	cl.add_child(stats_label)


func _start_round() -> void:
	for s in projectiles:
		s.queue_free()
	projectiles.clear()
	for pk in pickups:
		pk.queue_free()
	pickups.clear()
	for r in rocks:
		r.queue_free()
	rocks.clear()
	right_of_way = null
	respawn_timers.resize(players.size())
	respawn_timers.fill(0.0)
	var offs := [-220.0, 220.0, -620.0, 620.0]
	for i in players.size():
		var o: float = offs[i]
		players[i].reset_to(Vector2(LEVEL_W * 0.5 + o, GROUND_Y - 29.0), -1 if o > 0.0 else 1)
	show_msg("¡LUCHA!", 1.0)


func show_msg(text: String, dur: float) -> void:
	msg_label.text = text
	msg_label.modulate.a = 1.0
	if msg_tween:
		msg_tween.kill()
	msg_tween = msg_label.create_tween()
	msg_tween.tween_interval(dur)
	msg_tween.tween_property(msg_label, "modulate:a", 0.0, 0.4)


func _hitstop(dur: float) -> void:
	if get_tree().paused:
		return
	hitstop_active = true
	get_tree().paused = true
	get_tree().create_timer(dur, true).timeout.connect(func():
		get_tree().paused = false
		hitstop_active = false)


func _slowmo(scale: float, real_dur: float) -> void:
	Engine.time_scale = scale
	get_tree().create_timer(real_dur, true, false, true).timeout.connect(func():
		Engine.time_scale = 1.0)


func _update_hud() -> void:
	if mode_2v2:
		score_labels[0].text = "P1·P3  %d  »" % scores[0]
		score_labels[1].text = "«  %d  P2·P4" % scores[1]
	else:
		score_labels[0].text = "P1  %d  »" % scores[0]
		score_labels[1].text = "«  %d  P2" % scores[1]


func _burst(pos: Vector2, col: Color, amount := 24, speed := 380.0) -> void:
	var cp := CPUParticles2D.new()
	cp.position = pos
	cp.z_index = 20
	cp.one_shot = true
	cp.emitting = true
	cp.amount = amount
	cp.lifetime = 0.7
	cp.explosiveness = 1.0
	cp.direction = Vector2.UP
	cp.spread = 180.0
	cp.initial_velocity_min = speed * 0.25
	cp.initial_velocity_max = speed
	cp.gravity = Vector2(0, 950)
	cp.scale_amount_min = 3.0
	cp.scale_amount_max = 6.0
	cp.color = col
	add_child(cp)
	get_tree().create_timer(1.3).timeout.connect(cp.queue_free)


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("pause") and not hitstop_active:
		get_tree().paused = not get_tree().paused
		dim.visible = get_tree().paused
		pause_label.visible = get_tree().paused
	if get_tree().paused:
		return
	shake_time = maxf(0.0, shake_time - delta)
	if round_lock > 0.0:
		round_lock -= delta
		if round_lock <= 0.0:
			_start_round()
	if match_over and Input.is_action_just_pressed("restart"):
		scores = [0, 0]
		stats = _fresh_stats()
		stats_label.visible = false
		match_over = false
		_update_hud()
		_start_round()
	if Input.is_action_just_pressed("toggle_bot"):
		if not players[1].is_bot:
			bot_level = 1
			players[1].is_bot = true
		elif bot_level < 3:
			bot_level += 1
		else:
			players[1].is_bot = false
		var names := ["FÁCIL", "NORMAL", "DIFÍCIL"]
		if players[1].is_bot:
			show_msg("BOT P2: %s" % names[bot_level - 1], 0.7)
		else:
			show_msg("BOT P2: OFF", 0.7)
	if Input.is_action_just_pressed("toggle_ally") and players.size() > 2:
		ally_bot_level = (ally_bot_level + 1) % 4
		players[2].is_bot = ally_bot_level > 0
		var anames := ["OFF", "FÁCIL", "NORMAL", "DIFÍCIL"]
		show_msg("ALIADO P3: %s" % anames[ally_bot_level], 0.7)
	if Input.is_action_just_pressed("bot_vs_bot"):
		var on := not players[0].is_bot
		for p in players:
			p.is_bot = on
		if not on:
			# restaurar: P3 según su nivel, P4 siempre bot en 2v2
			if players.size() > 2:
				players[2].is_bot = ally_bot_level > 0
			if players.size() > 3:
				players[3].is_bot = true
		show_msg("BOT vs BOT %s" % ("ACTIVADO" if on else "DESACTIVADO"), 0.7)
	if Input.is_action_just_pressed("toggle_2v2"):
		set_mode_2v2(not mode_2v2)
	if Input.is_action_just_pressed("toggle_chaos"):
		set_chaos(not chaos)
	if Input.is_action_just_pressed("toggle_music"):
		var mp := music.get_node_or_null("MusicPlayer") as AudioStreamPlayer
		if mp != null:
			if mp.playing:
				mp.stop()
			else:
				mp.play()
	if chaos and not match_over and round_lock <= 0.0:
		chaos_timer -= delta
		if chaos_timer <= 0.0:
			_spawn_rock()
			chaos_timer = randf_range(2.0, 4.2)
	for i in players.size():
		if respawn_timers[i] > 0.0:
			respawn_timers[i] -= delta
			if respawn_timers[i] <= 0.0:
				_respawn(players[i])
	for p in players:
		if p.state != Player.State.DEAD and p.position.y > 820.0:
			_kill(p, null)
	for p in players:
		p.frozen = match_over or round_lock > 0.0
		if p.is_bot:
			_bot_think(p, delta)
	for i in players.size():
		var step := absf(players[i].position.x - last_x[i])
		if players[i].state != Player.State.DEAD and step < 60.0:
			stats[i]["dist"] += step
		last_x[i] = players[i].position.x
	_resolve_attacks()
	_resolve_divekicks()
	_update_projectiles(delta)
	_update_rocks(delta)
	_update_pickups()
	_check_goals()
	_update_camera()


func _resolve_attacks() -> void:
	for atk in players:
		if not atk.attack_is_active():
			continue
		var def := _nearest_foe_in_range(atk)
		if def == null:
			continue
		var h: int = atk.attack_height
		var outcome := "kill"
		if def.state == Player.State.ATTACK and def.attack_is_active():
			outcome = "clash" if h == def.attack_height else "trade"
		elif def.state == Player.State.DIVEKICK:
			outcome = "clash" if h == Player.H.MID else "kill"
		elif def.state == Player.State.STUNNED or def.state == Player.State.KNOCKDOWN:
			outcome = "kill"
		else:
			var d: int = def.stance
			if d == h:
				outcome = "clash"
			elif h == Player.H.HIGH and d == Player.H.LOW:
				outcome = "miss"
			elif h == Player.H.LOW and not def.is_on_floor():
				outcome = "miss"
		atk.attack_resolved = true
		match outcome:
			"kill":
				_melee_hit(atk, def)
			"trade":
				_melee_hit(atk, def)
				_kill(atk, null)
			"clash":
				_clash(atk, def)
			_:
				pass


func _nearest_foe_in_range(atk: Player) -> Player:
	var rng := Player.PUNCH_RANGE if not atk.has_sword else Player.ATTACK_RANGE
	var best: Player = null
	var bd := INF
	for def in _foes_of(atk):
		if def.state == Player.State.DEAD or def.invuln_time > 0.0:
			continue
		var dx := (def.position.x - atk.position.x) * atk.facing
		if dx < -16.0 or dx > rng:
			continue
		if absf(def.position.y - atk.position.y) > 92.0:
			continue
		if absf(dx) < bd:
			bd = absf(dx)
			best = def
	return best


func _melee_hit(atk: Player, def: Player) -> void:
	if atk.has_sword:
		_kill(def, atk)
	else:
		# el puñetazo derriba, no mata
		var push := 1 if def.position.x >= atk.position.x else -1
		def.knockdown(push)
		_burst(def.position, Color(1, 1, 1), 8, 200.0)
		sfx(def.position, "hit", -10.0)


func _clash(a: Player, b: Player) -> void:
	var mid := Vector2((a.position.x + b.position.x) * 0.5, minf(a.position.y, b.position.y) - 14.0)
	_burst(mid, Color(1.0, 0.93, 0.55), 14, 320.0)
	sfx(mid, "clash", -8.0)
	shake_time = maxf(shake_time, 0.14)
	# el choque desarma a quien atacaba con la espada en alto
	var disarmed: Array[Player] = []
	for p in [a, b]:
		if p.state == Player.State.ATTACK and p.attack_height == Player.H.HIGH and p.has_sword:
			disarmed.append(p)
	var push_b := 1 if b.position.x >= a.position.x else -1
	b.take_clash(push_b)
	a.take_clash(-push_b)
	for p in disarmed:
		p.has_sword = false
		_drop_sword(p.position + Vector2(-float(p.facing) * 110.0, -30.0), Color(0.87, 0.9, 0.95))
		_burst(p.position + Vector2(0, -20), Color(0.95, 0.95, 1.0), 8, 240.0)
		sfx(p.position, "throw", -14.0)


func _resolve_divekicks() -> void:
	for p in players:
		if p.state != Player.State.DIVEKICK or p.divekick_resolved:
			continue
		var def := _nearest_divekick_target(p)
		if def == null:
			continue
		p.divekick_resolved = true
		if def.state == Player.State.ATTACK and def.attack_is_active():
			def.attack_resolved = true
			_clash(def, p)
		else:
			var push := 1 if def.position.x >= p.position.x else -1
			def.knockdown(push)
			p.state = Player.State.JUMP
			p.velocity = Vector2(-p.facing * 210.0, -440.0)
			_burst(def.position, Color(1, 1, 1), 10, 240.0)
			sfx(def.position, "hit", -10.0)
			shake_time = maxf(shake_time, 0.12)


func _nearest_divekick_target(p: Player) -> Player:
	var best: Player = null
	var bd := INF
	for def in _foes_of(p):
		if def.state == Player.State.DEAD or def.invuln_time > 0.0:
			continue
		if absf(def.position.x - p.position.x) > 44.0 or absf(def.position.y - p.position.y) > 64.0:
			continue
		var d := absf(def.position.x - p.position.x)
		if d < bd:
			bd = d
			best = def
	return best


func _kill(def: Player, atk: Player) -> void:
	if def.state == Player.State.DEAD:
		return
	def.die()
	stats[def.player_id - 1]["deaths"] += 1
	if atk != null:
		stats[atk.player_id - 1]["kills"] += 1
	_hitstop(0.08)
	respawn_timers[def.player_id - 1] = RESPAWN_DELAY
	_burst(def.position, def.color, 34, 440.0)
	_slowmo(0.35, 0.5)
	_burst(def.position, Color(0.95, 0.95, 1.0), 12, 260.0)
	sfx(def.position, "kill", -6.0)
	shake_time = maxf(shake_time, 0.3)
	_after_death(def, atk)


func _after_death(def: Player, atk: Player) -> void:
	# el asesino toma el paso; si la muerte es del entorno, el compañero
	# hereda el paso del portador caído (o lo gana el último vivo en 1v1)
	if atk != null and atk.state != Player.State.DEAD:
		right_of_way = atk
		return
	if right_of_way == def:
		var mate := _living_teammate(def)
		if mate != null:
			right_of_way = mate
			return
		right_of_way = null
	var alive := 0
	var last: Player = null
	for p in players:
		if p.state != Player.State.DEAD:
			alive += 1
			last = p
	if alive == 1 and right_of_way == null:
		right_of_way = last


func _respawn(p: Player) -> void:
	if p.state != Player.State.DEAD:
		return
	var pos := _respawn_pos(p)
	var face := 1
	if right_of_way != null:
		face = 1 if right_of_way.position.x > pos.x else -1
	else:
		face = 1 if pos.x < LEVEL_W * 0.5 else -1
	p.revive(pos, face)
	sfx(pos, "respawn", -12.0)


func _respawn_pos(p: Player) -> Vector2:
	if right_of_way == null:
		var offs := [220.0, -220.0, 620.0, -620.0]
		return Vector2(LEVEL_W * 0.5 + offs[p.player_id - 1], 200.0)
	var dir := float(right_of_way.goal_dir)
	var x := right_of_way.position.x + dir * 540.0
	if x > PIT_X0 - 50.0 and x < PIT_X1 + 50.0:
		x = PIT_X1 + 70.0 if dir > 0.0 else PIT_X0 - 70.0
	elif x > PIT2_X0 - 50.0 and x < PIT2_X1 + 50.0:
		x = PIT2_X1 + 70.0 if dir > 0.0 else PIT2_X0 - 70.0
	x = clampf(x, GOAL_W + 60.0, LEVEL_W - GOAL_W - 60.0)
	return Vector2(x, 200.0)


func _on_threw_sword(p: Player) -> void:
	var s := SwordProjectile.new()
	s.thrower = p
	s.color = Color(0.87, 0.9, 0.95)
	s.position = p.position + Vector2(p.facing * 26.0, -8.0)
	s.vel = Vector2(p.facing * 760.0, 0.0)
	s.spin = p.facing * 18.0
	add_child(s)
	projectiles.append(s)
	sfx(p.position, "throw", -14.0)
	stats[p.player_id - 1]["throws"] += 1


func _update_projectiles(delta: float) -> void:
	var done: Array[SwordProjectile] = []
	for s in projectiles:
		s.position += s.vel * delta
		if s.position.x < 26.0 or s.position.x > LEVEL_W - 26.0:
			_drop_sword(s.position, s.color)
			done.append(s)
			continue
		for p in players:
			if s.thrower != null and _team(p) == _team(s.thrower):
				continue
			if p.state == Player.State.DEAD or p.invuln_time > 0.0:
				continue
			if absf(p.position.x - s.position.x) < 30.0 and absf(p.position.y - s.position.y) < 36.0:
				var blocks: bool = (p.stance == Player.H.MID and p.state in [Player.State.IDLE, Player.State.RUN, Player.State.JUMP]) or (p.state == Player.State.ATTACK and p.attack_is_active())
				if blocks:
					_burst(s.position, Color(0.9, 0.9, 1.0), 10, 260.0)
					sfx(s.position, "clash", -12.0)
					_drop_sword(s.position, s.color)
				else:
					_kill(p, s.thrower)
				done.append(s)
				break
	for s in done:
		projectiles.erase(s)
		s.queue_free()


func _in_any_pit(x: float) -> bool:
	return (x > PIT_X0 and x < PIT_X1) or (x > PIT2_X0 and x < PIT2_X1)


func _out_of_pit(x: float) -> float:
	if x > PIT_X0 - 34.0 and x < PIT_X1 + 34.0:
		return PIT_X0 - 40.0 if x < (PIT_X0 + PIT_X1) * 0.5 else PIT_X1 + 40.0
	if x > PIT2_X0 - 34.0 and x < PIT2_X1 + 34.0:
		return PIT2_X0 - 40.0 if x < (PIT2_X0 + PIT2_X1) * 0.5 else PIT2_X1 + 40.0
	return x


func _drop_sword(pos: Vector2, col: Color) -> void:
	var x := clampf(pos.x, 30.0, LEVEL_W - 30.0)
	var y := GROUND_Y
	if pos.y < GROUND_Y - 80.0:
		# soltada en alto: cae sobre la primera superficie elevada que haya
		var top := _top_below(x, pos.y)
		if top > 0.0:
			y = top
		elif _in_any_pit(x):
			x = _out_of_pit(x)
	else:
		x = _out_of_pit(x)
	var pk := SwordPickup.new()
	pk.color = col
	pk.position = Vector2(x, y - 12.0)
	add_child(pk)
	pickups.append(pk)


func _update_pickups() -> void:
	for pk in pickups.duplicate():
		for p in players:
			if p.state == Player.State.DEAD or p.has_sword:
				continue
			if absf(p.position.x - pk.position.x) < 34.0 and absf(p.position.y - pk.position.y) < 60.0:
				p.has_sword = true
				pickups.erase(pk)
				pk.queue_free()
				sfx(pk.position, "pickup", -14.0)
				break


# --- modo caos: lluvia de rocas -------------------------------------------

func _spawn_rock() -> void:
	var x := 0.0
	var target := -1.0
	for attempt in 10:
		x = randf_range(140.0, LEVEL_W - 140.0)
		target = _top_below(x, 0.0)
		if target > 0.0:
			break
	if target < 0.0:
		return
	var r := FallingRock.new()
	r.target_y = target
	r.t = ROCK_WARN_TIME
	r.spin = randf_range(-3.0, 3.0)
	r.position = Vector2(x, -40.0)
	add_child(r)
	rocks.append(r)
	chaos_count += 1
	sfx(Vector2(x, 300.0), "alert", -16.0)


func _update_rocks(delta: float) -> void:
	var done: Array[FallingRock] = []
	for r in rocks:
		match r.phase:
			"warn":
				r.t -= delta
				if r.t <= 0.0:
					r.phase = "fall"
			"fall":
				r.position.y += ROCK_FALL_SPEED * delta
				if r.position.y >= r.target_y:
					_rock_impact(r)
					done.append(r)
	for r in done:
		rocks.erase(r)
		r.queue_free()


func _rock_impact(r: FallingRock) -> void:
	_burst(Vector2(r.position.x, r.target_y), Color(0.55, 0.5, 0.55), 26, 420.0)
	_burst(Vector2(r.position.x, r.target_y - 6.0), Color(0.9, 0.85, 0.8), 8, 240.0)
	sfx(Vector2(r.position.x, r.target_y), "crash", -6.0)
	shake_time = maxf(shake_time, 0.22)
	for p in players:
		if p.state == Player.State.DEAD or p.invuln_time > 0.0:
			continue
		if absf(p.position.y - (r.target_y - 29.0)) > 60.0:
			continue
		var dx := absf(p.position.x - r.position.x)
		if dx < 44.0:
			_kill(p, null)
		elif dx < 100.0:
			var push := 1 if p.position.x >= r.position.x else -1
			p.knockdown(push)


func _check_goals() -> void:
	if match_over or round_lock > 0.0:
		return
	if right_of_way == null or right_of_way.state == Player.State.DEAD:
		return
	var p := right_of_way
	if p.goal_dir > 0 and p.position.x > LEVEL_W - GOAL_W:
		_point(p)
	elif p.goal_dir < 0 and p.position.x < GOAL_W:
		_point(p)


func _point(p: Player) -> void:
	scores[_team(p)] += 1
	_update_hud()
	sfx(p.position, "point", -6.0)
	_burst(p.position + Vector2(0, -30), p.color, 42, 480.0)
	_slowmo(0.25, 0.9)
	right_of_way = null
	if scores[_team(p)] >= WIN_SCORE:
		match_over = true
		if mode_2v2:
			var team_name := "NARANJA" if _team(p) == 0 else "CYAN"
			show_msg("¡GANA EL EQUIPO %s!  ·  R: revancha" % team_name, 12.0)
		else:
			show_msg("¡GANA P%d!  ·  R: revancha" % p.player_id, 12.0)
		stats_label.text = _stats_text()
		stats_label.visible = true
	else:
		round_lock = 1.4
		show_msg("¡PUNTO!", 1.0)


func _stats_text() -> String:
	var lines: Array[String] = []
	for i in players.size():
		var s := stats[i]
		lines.append("P%d   bajas %d   ·   muertes %d   ·   lanzó %d   ·   corrió %d m" % [
			i + 1, s["kills"], s["deaths"], s["throws"], int(round(float(s["dist"]) / 32.0)),
		])
	return "\n".join(lines)


func _update_camera() -> void:
	var tx := camera.position.x
	if right_of_way != null and right_of_way.state != Player.State.DEAD:
		tx = right_of_way.position.x
	else:
		var sum := 0.0
		var n := 0
		for p in players:
			if p.state != Player.State.DEAD:
				sum += p.position.x
				n += 1
		if n > 0:
			tx = sum / float(n)
	var half := VIEW_W * 0.5 / camera.zoom.x
	tx = clampf(tx, half, LEVEL_W - half)
	camera.position = Vector2(tx, VIEW_H * 0.5 + 6.0)
	if shake_time > 0.0:
		camera.offset = Vector2(randf_range(-9.0, 9.0), randf_range(-7.0, 7.0)) * (shake_time * 4.0)
	else:
		camera.offset = Vector2.ZERO


func _bot_cfg(p: Player) -> Dictionary:
	var lvl := bot_level
	if p.player_id == 1 or p.player_id == 3:
		lvl = maxi(ally_bot_level, 1)
	return BOT_CFG[lvl - 1]


func _bot_think(p: Player, delta: float) -> void:
	var foe := _nearest_foe(p)
	p.bot_think -= delta
	if p.bot_think > 0.0:
		return
	var cfg := _bot_cfg(p)
	p.bot_think = float(cfg["react"])
	var want := {}
	var tap := ""
	if foe == null:
		p.bot_held = want
		return
	var adx := absf(foe.position.x - p.position.x)
	var sd := 1.0 if foe.position.x >= p.position.x else -1.0
	var on_floor := p.is_on_floor()
	var row_team := -1 if right_of_way == null else _team(right_of_way)

	if right_of_way != null and row_team == _team(p):
		# corredor (o aliado escoltando): correr hacia la meta y cruzar el foso
		# central por la plataforma
		if p.goal_dir > 0:
			want["right"] = true
		else:
			want["left"] = true
		if on_floor and p.position.x > PLAT_X0 - 130.0 and p.position.x < PLAT_X1 + 130.0 and not (p.position.x > PLAT_X0 + 40.0 and p.position.x < PLAT_X1 - 40.0):
			tap = "jump"
	elif row_team >= 0 and foe != null:
		# interceptor: adelantarse en la dirección hacia la que corre el portador
		var tx: float = right_of_way.position.x + float(right_of_way.goal_dir) * 200.0
		if tx > p.position.x + 20.0:
			want["right"] = true
		elif tx < p.position.x - 20.0:
			want["left"] = true
		if on_floor and p.position.x > PLAT_X0 - 130.0 and p.position.x < PLAT_X1 + 130.0 and not (p.position.x > PLAT_X0 + 40.0 and p.position.x < PLAT_X1 - 40.0):
			tap = "jump"
	elif foe != null:
		# duelo: gestión de distancia y estancias
		if adx > 260.0:
			if sd > 0.0:
				want["right"] = true
			else:
				want["left"] = true
			if on_floor and randf() < 0.05:
				tap = "jump"
		elif adx < 55.0:
			if sd > 0.0:
				want["left"] = true
			else:
				want["right"] = true
		elif foe.state == Player.State.ATTACK and foe.attack_is_active():
			# cubrirse: igualar la altura del ataque rival para provocar choque
			match foe.attack_height:
				Player.H.HIGH:
					want["up"] = true
				Player.H.LOW:
					want["down"] = true
		else:
			# con probabilidad "err" el bot se equivoca de estancia
			if randf() < float(cfg["err"]):
				var r := randi() % 3
				if r == 0:
					want["up"] = true
				elif r == 1:
					want["down"] = true
				else:
					pass  # se queda en media por error
			elif foe.stance == Player.H.MID:
				want["down"] = true
			if randf() < float(cfg["atk"]):
				tap = "attack"
			if p.has_sword and randf() < 0.03:
				tap = "throw"
	# saltar el foso pequeño (sin plataforma) acercándose al borde
	if on_floor and want.get("right", false) and p.position.x > PIT2_X0 - 110.0 and p.position.x < PIT2_X0 + 30.0:
		tap = "jump"
	elif on_floor and want.get("left", false) and p.position.x > PIT2_X1 - 30.0 and p.position.x < PIT2_X1 + 110.0:
		tap = "jump"
	# saltar cualquier muro bajo (peldaños de roca, etc.) al chocar de frente
	if tap == "" and on_floor and p.is_on_wall() and (want.get("right", false) or want.get("left", false)):
		tap = "jump"
	# patada voladora si el rival está abajo y cerca
	if not on_floor and foe != null and adx < 100.0 and foe.position.y > p.position.y + 40.0:
		tap = "attack"
	p.bot_held = want
	if tap != "" and p.state in [Player.State.IDLE, Player.State.RUN, Player.State.JUMP]:
		p.bot_held[tap] = true
