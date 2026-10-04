extends Node2D
## Juego estilo Nidhogg: duelo de esgrima a un golpe. Quien mata gana el "paso"
## y debe correr hasta su meta; el rival reaparece delante para frenarlo.
## Primero en llegar a WIN_SCORE puntos gana el partido.
## Extras: mapa con alturas (puente alto, casa, torre de rocas), modo caos con
## lluvia de rocas (T) y modo 2v2 por equipos (V).

const LEVEL_W := 4800.0
const SECTION_COUNT := 7
const GROUND_Y := 560.0
# --- geometría por arena (la fija _load_arena; estos son los valores de la arena 0) ---
var PIT_X0 := 2210.0
var PIT_X1 := 2380.0
var PIT2_X0 := 700.0
var PIT2_X1 := 880.0
var PLAT_X0 := 2130.0
var PLAT_X1 := 2460.0
var PLAT_Y := 448.0
# --- paleta por arena ---
var col_sky := Color(0.055, 0.05, 0.09)
var col_hill_far := Color(0.075, 0.068, 0.115)
var col_hill_near := Color(0.065, 0.06, 0.10)
var col_pillar := Color(0.085, 0.08, 0.135)
var col_pillar_cap := Color(0.11, 0.10, 0.17)
var col_pit := Color(0.30, 0.07, 0.09)
var col_floor := Color(0.14, 0.13, 0.19)
var col_floor_top := Color(0.30, 0.27, 0.37)
var col_plat := Color(0.20, 0.18, 0.27)
var col_plat_top := Color(0.34, 0.31, 0.42)
var col_wall := Color(0.11, 0.10, 0.16)
var cel_pos := Vector2(2400.0, 118.0)
var cel_col := Color(0.14, 0.13, 0.20)
var cel_detail := Color(0.10, 0.09, 0.15)
var arena_id := 0
var level_root: Node2D
var parallax_bg: ParallaxBackground
var bg_tint_far := Color(0.7, 0.72, 0.9)
var bg_tint_near := Color(0.85, 0.85, 0.95)

# hazards de suelo: var (no const) porque la arena barajada los reposiciona (tarea 86)
var GRASS_X0 := 1150.0
var ICE_X0 := 1700.0   # franja de hielo (Winter): frena mal (tarea 69)
var ICE_X1 := 2000.0
var BELT_X0 := 2500.0   # cinta transportadora (Volcano, tarea 71): empuja a la izquierda
var BELT_X1 := 2650.0
const BELT_V := -120.0
var GRASS_X1 := 1450.0
var LADDER_X := 1480.0  # escalera de plataformas: origen del primer peldaño
var random_arena := false  # arena barajada por puntos (tarea 86, tecla X)
var _shuffled := false     # el nivel del disco actual viene de un barajado
const GOAL_W := 130.0
const WIN_SCORE := 3
const VIEW_W := 1152.0
const VIEW_H := 648.0
const RESPAWN_DELAY := 2.4
const PARRY_IMPULSE := 160.0    # parada blanda: px/s de separación
const PARRY_PUSH_TIME := 0.15   # duración del empuje de parada
const CLASH_IMPULSE := 130.0    # rebote mínimo contra guardia
const CLASH_PUSH_TIME := 0.12
const PARRY_COOLDOWN := 0.3     # anti re-trigger del rebote sostenido
const ARROW_MAX_BOUNCES := 6   # tras 6 rebotes la flecha se clava
const ARROW_MIN_SPEED := 100.0 # demasiado lenta: se clava
const SECTION_PAN_TIME := 0.28       # pan al cruzar reja (sin teleport)
const SECTION_BOTTOM_MARGIN := 88.0  # margen visible bajo la línea de suelo
const ARENA_NAMES := ["RUINAS DE MEDIANOCHE", "TEMPLO DEL ALBA", "CRIPTA DEL OCASO", "TORRE DEL CENTINELA"]
const BOT_CFG := [
	{"react": 0.26, "atk": 0.12, "err": 0.35},  # FÁCIL
	{"react": 0.13, "atk": 0.30, "err": 0.10},  # NORMAL
	{"react": 0.07, "atk": 0.50, "err": 0.02},  # DIFÍCIL
]
# ruta alta: puente de madera sobre el foso central
var BRIDGE_X0 := 1900.0
var BRIDGE_X1 := 2690.0
var BRIDGE_Y := 288.0
# casa con tejado subible (dos faldones escalonados), anclada a HOUSE_X
var HOUSE_X := 908.0
var ROOF_L_X0 := 908.0
var ROOF_L_X1 := 1010.0
var ROOF_L_Y := 472.0
var ROOF_H_X0 := 1020.0
var ROOF_H_X1 := 1152.0
var ROOF_H_Y := 406.0
# zona rocosa: peldaños, peñasco y torre
var STEP_R_X0 := 2856.0
var STEP_R_X1 := 2948.0
var STEP_R_Y := 516.0
var BOULDER_X0 := 3116.0
var BOULDER_X1 := 3344.0
var BOULDER_Y := 440.0
var TOWER_X0 := 3476.0
var TOWER_X1 := 3644.0
var TOWER_Y := 330.0
# peldaño rocoso cerca de la meta izquierda
var STEP_L_X0 := 500.0
var STEP_L_X1 := 592.0
var STEP_L_Y := 516.0
var FENCE_X0 := 600.0
var FENCE_X1 := 690.0

const ROCK_WARN_TIME := 0.85
const ROCK_FALL_SPEED := 1900.0

const P1_COLOR := Color("4a7bd0")   # azul de la túnica de Nacho (P1)
const P2_COLOR := Color("d84f35")   # rojo de Rodrigo (P2)
const P3_COLOR := Color("ff7847")
const P4_COLOR := Color("4f8dff")
# sprites de HUD (tarea 55)
const TEX_ARROW := preload("res://art/sprites/arrow_neutral.png")
const TEX_BLOOD := [
	preload("res://art/sprites/blood_0.png"),
	preload("res://art/sprites/blood_1.png"),
	preload("res://art/sprites/blood_2.png"),
]
# tiles de escenario (tarea 57)
const TEX_FLOOR := preload("res://art/sprites/tile_floor.png")
const TEX_WALL := preload("res://art/sprites/tile_wall.png")
const TEX_PIT_EDGE := preload("res://art/sprites/pit_edge.png")

var players: Array[Player] = []
var right_of_way: Player = null
var scores := [0, 0]
var weapon_idx := [0, 0]
var match_over := false
var round_lock := 0.0
var skip_countdown := false   # los tests headless lo ponen a true (tarea 66)
const COUNTDOWN_STEP := 0.7
var respawn_timers := [0.0, 0.0]
var shake_time := 0.0
var parry_cd := 0.0
var calm_time := 0.0            # segundos sin muertes (tarea 67)
var sudden_death := false
const SUDDEN_DEATH_AFTER := 45.0
const CAM_ZOOM_NEAR := 1.5   # duelo cerrado: personaje ~13-14% de pantalla (tarea 78)
const CAM_ZOOM_FAR := 1.0    # persecución abierta (nunca menos: no perder presencia)
const CAM_FIT_USE := 0.72    # fracción del ancho que pueden ocupar los duelistas
var dynamic_zoom := true
var bot_level := 1        # dificultad bots equipo derecho (0 = OFF solo afecta a P2)
var ally_bot_level := 2   # dificultad del aliado P3 (0 = OFF)
var hitstop_active := false
var projectiles: Array[SwordProjectile] = []
var corpses := {}
var arrows: Array[Arrow] = []
var pickups: Array[SwordPickup] = []
var rocks: Array[FallingRock] = []
var blood: Array[Node] = []
var goal_polys: Array[Polygon2D] = []
var _belt_arrows: Array[Polygon2D] = []
var stats: Array[Dictionary] = []
var last_x := [0.0, 0.0]
var _tops: Array[Dictionary] = []   # superficies elevadas {x0, x1, y}
var chaos := false
var chaos_timer := 0.0
var chaos_count := 0
var mode_2v2 := false
var worm: Node = null
var arcade := false
var arcade_level := 1
var arcade_over := false
var cup := false
var cup_stage := 0
var cup_alive := [true, true]
var cup_over := false
var sections_mode := false
var section_index := 3
var sect_conquered := [0, 0]
var gates: Array[SectionGate] = []
var crumble_tiles: Array[CrumbleTile] = []

var camera: Camera2D
var section_cam_tween: Tween
var msg_label: Label
var hint_label: Label
var run_label: Label
var dim: ColorRect
var pause_label: Label
var stats_label: Label
var fight_label: Label
var fight_tween: Tween
var step_arrow: TextureRect
var step_arrow_tween: Tween
var pips: Array[Pip] = []
var pips_row: Node2D
var respawn_bar: RespawnBar
var score_labels: Array[Label] = []
var msg_tween: Tween
var music: Music
var crowd: AudioStreamPlayer
var crowd_excite := 0.0    # 0..1 (tarea 68)
var crowd_kill_flash := 0.0
# --- online: host autoritativo, cliente con predicción del propio jugador ---
const NET_SNAP_EVERY := 3  # snapshot cada 3 ticks de física (20 Hz a 60 fps)
var net_tick := 0
var net_last_snap := {}    # cliente: último snapshot recibido del host
var net_last_ser := -1     # cliente: serie del último snapshot aceptado (orden)
var net_applied_ser := -1  # cliente: serie cuyo rebuild de entidades ya se hizo
var net_last_rl := 0.0     # cliente: round_lock del tick anterior (para el ¡FIGHT!)
var net_had_sd := false    # cliente: muerte súbita ya anunciada
var net_dead := [false, false]  # cliente: muertes ya aplicadas localmente
var net_wait_peer := false      # host: congelado esperando el handshake del cliente
var rematch_pending := false    # fix bucle de cuenta atrás: expirar el lock ¿reinicia ronda?


func _fresh_stats() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in players.size():
		out.append({"kills": 0, "deaths": 0, "throws": 0, "dist": 0.0})
	return out


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	level_root = Node2D.new()
	# la raíz del juego es ALWAYS (para leer ESC con el árbol en pausa), así que
	# los hijos heredarían ALWAYS: el escenario y su decoración animada (humo,
	# antorchas, nubes, velas, charcos) deben marcarse PAUSABLE explícito
	level_root.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(level_root)
	_load_arena(0)
	_build_level()
	_build_players()
	stats = _fresh_stats()
	_build_camera()
	_build_hud()
	music = Music.new()
	add_child(music)
	crowd = AudioStreamPlayer.new()
	crowd.stream = Sfx.crowd_loop()
	crowd.volume_db = -44.0
	crowd.name = "Crowd"
	add_child(crowd)
	crowd.play()
	# online: el host manda (handshake fino con el cliente); el cliente espeja
	if Net.active():
		Net.peer_left.connect(_on_net_drop)
		Net.server_lost.connect(_on_net_drop)
	if Net.is_client():
		_client_setup()
	elif Net.is_host():
		_host_setup()
	else:
		_start_round()


func _process(_delta: float) -> void:
	var a := 0.13 + 0.06 * sin(Time.get_ticks_msec() * 0.003)
	for gp in goal_polys:
		gp.color.a = a
	# cinta transportadora (tarea 71): las flechas derivan con el empuje
	for ar in _belt_arrows:
		ar.position.x -= 60.0 * _delta
		if ar.position.x < BELT_X0 - 30.0:
			ar.position.x += 150.0
	var rw := right_of_way
	if rw != null and not match_over and rw.state != Player.State.DEAD and round_lock <= 0.0:
		run_label.visible = true
		run_label.text = "¡P%d CORRE!  %s" % [rw.player_id, "»»»" if rw.goal_dir > 0 else "«««"]
		run_label.add_theme_color_override("font_color", rw.color)
	else:
		run_label.visible = false


func sfx(pos: Vector2, id: String, db := -10.0, pitch := 1.0) -> void:
	Sfx.play(self, pos, id, db, pitch)
	if Net.is_host() and Net.client_ready:
		ev_sfx.rpc(pos.x, pos.y, id, db, pitch)


func in_grass(x: float) -> bool:
	return x > GRASS_X0 and x < GRASS_X1


func in_ice(x: float) -> bool:
	return x > ICE_X0 and x < ICE_X1


func in_belt(x: float) -> bool:
	return x > BELT_X0 and x < BELT_X1


func belt_velocity() -> float:
	return BELT_V


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
		"toggle_arena": [KEY_C],
		"toggle_sections": [KEY_P],
		"toggle_arcade": [KEY_Y],
		"toggle_cup": [KEY_O],
		"toggle_random": [KEY_X],
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


func _parallax_layer(pb: ParallaxBackground, path: String, motion: float, tint: Color) -> ParallaxLayer:
	# capa de fondo repetida: textura 960x540 escalada a viewport y espejada
	var l := ParallaxLayer.new()
	l.motion_scale = Vector2(motion, motion)
	var s := Sprite2D.new()
	s.texture = load(path)
	s.centered = false
	s.scale = Vector2(1152.0 / 960.0, 648.0 / 540.0)
	s.modulate = tint
	l.motion_mirroring = Vector2(1152.0, 0.0)
	l.add_child(s)
	pb.add_child(l)
	return l


func _build_parallax() -> void:
	parallax_bg = ParallaxBackground.new()
	parallax_bg.layer = -20
	add_child(parallax_bg)
	_parallax_layer(parallax_bg, "res://art/sprites/bg_layer0.png", 0.15, bg_tint_far)
	_parallax_layer(parallax_bg, "res://art/sprites/bg_layer1.png", 0.4, bg_tint_near)


func _build_level() -> void:
	_build_parallax()
	_poly(_circle_points(cel_pos.x, cel_pos.y, 74.0), cel_col, -9)
	_poly(_circle_points(cel_pos.x - 30.0, cel_pos.y - 26.0, 13.0), cel_detail, -9)
	_poly(_circle_points(cel_pos.x + 26.0, cel_pos.y + 32.0, 9.0), cel_detail, -9)
	_hills()
	_clouds()
	var px := 340.0
	while px < LEVEL_W - 200.0:
		if not (px > PIT_X0 - 130.0 and px < PIT_X1 + 130.0):
			_poly(PackedVector2Array([Vector2(px - 26, GROUND_Y), Vector2(px + 26, GROUND_Y), Vector2(px + 26, 130.0), Vector2(px - 26, 130.0)]), col_pillar, -5)
			_poly(PackedVector2Array([Vector2(px - 36, 142.0), Vector2(px + 36, 142.0), Vector2(px + 36, 122.0), Vector2(px - 36, 122.0)]), col_pillar_cap, -5)
		px += 640.0
	# suelo entre los fosos, ordenados por posición (valgan donde valgan)
	var pits := [[PIT_X0, PIT_X1], [PIT2_X0, PIT2_X1]]
	pits.sort_custom(func(u, v): return u[0] < v[0])
	var seg_a := 0.0
	for b in pits:
		_floor_segment(seg_a, b[0])
		seg_a = b[1]
	_floor_segment(seg_a, LEVEL_W)
	_poly(PackedVector2Array([Vector2(PIT_X0, GROUND_Y + 4), Vector2(PIT_X1, GROUND_Y + 4), Vector2(PIT_X1 - 26, 800.0), Vector2(PIT_X0 + 26, 800.0)]), col_pit, -6)
	_poly(PackedVector2Array([Vector2(PIT2_X0, GROUND_Y + 4), Vector2(PIT2_X1, GROUND_Y + 4), Vector2(PIT2_X1 - 26, 800.0), Vector2(PIT2_X0 + 26, 800.0)]), col_pit, -6)
	_pit_edges(PIT_X0, PIT_X1)
	_pit_edges(PIT2_X0, PIT2_X1)
	# crumble bridge (tarea 70): 4 tramos sobre el foso en vez de plataforma fija
	_make_crumbles()
	if arena_id != 3:
		# el puente alto de madera pisaría el piso superior de la torre
		_bridge()
	_house()
	_rocks_zone()
	if arena_id == 3:
		_tower_floor()
	_draw_grass()
	_draw_ice()
	_draw_belt()
	_ladder(LADDER_X)
	_wall(-46.0, 6.0)
	_wall(LEVEL_W - 6.0, LEVEL_W + 46.0)
	_goal_zone(LEVEL_W - GOAL_W, LEVEL_W, P1_COLOR)
	_goal_zone(0.0, GOAL_W, P2_COLOR)
	_torch_at(210.0)
	_torch_at(LEVEL_W - 210.0)
	_torch_at(HOUSE_X + 124.0)
	_fence(FENCE_X0, FENCE_X1)
	if arena_id == 2 and not _shuffled:
		# velas y lápidas van en x fijas: fuera de la arena barajada
		_candles()
		_tombstones()


func _make_crumbles() -> void:
	crumble_tiles.clear()
	var tw := (PLAT_X1 - PLAT_X0) / 4.0
	for k in 4:
		var tile := CrumbleTile.new(PLAT_X0 + tw * float(k), PLAT_X0 + tw * (float(k) + 1.0), PLAT_Y)
		tile.z_index = -4
		_register_top(tile.x0, tile.x1, PLAT_Y)
		_add_level(tile)
		crumble_tiles.append(tile)


func _draw_grass() -> void:
	# hierba alta: oculta la estancia de quien entra
	_poly(PackedVector2Array([Vector2(GRASS_X0, GROUND_Y), Vector2(GRASS_X1, GROUND_Y), Vector2(GRASS_X1, GROUND_Y - 34.0), Vector2(GRASS_X0, GROUND_Y - 34.0)]), Color(0.09, 0.18, 0.11), 2)
	for i in 22:
		var gx := GRASS_X0 + (GRASS_X1 - GRASS_X0) * (float(i) + 0.5) / 22.0
		var gh := 44.0 + 20.0 * randf()
		_poly(PackedVector2Array([Vector2(gx - 7, GROUND_Y), Vector2(gx + 7, GROUND_Y), Vector2(gx + randf_range(-7.0, 7.0), GROUND_Y - gh)]), Color(0.13, 0.30, 0.17).lightened(0.08 * randf()), 3)
	_flowers()


func _draw_ice() -> void:
	# franja de hielo (tarea 69): tinte azulado brillante sobre los tiles
	_poly(PackedVector2Array([Vector2(ICE_X0, GROUND_Y), Vector2(ICE_X1, GROUND_Y), Vector2(ICE_X1, GROUND_Y - 5.0), Vector2(ICE_X0, GROUND_Y - 5.0)]), Color(0.62, 0.78, 0.95, 0.45), 2)


func _draw_belt() -> void:
	# cinta transportadora (tarea 71): base más oscura + flechas que derivan
	_poly(PackedVector2Array([Vector2(BELT_X0, GROUND_Y), Vector2(BELT_X1, GROUND_Y), Vector2(BELT_X1, GROUND_Y - 4.0), Vector2(BELT_X0, GROUND_Y - 4.0)]), Color(0.1, 0.09, 0.14, 0.85), 2)
	_belt_arrows.clear()
	for k in 4:
		var bx := BELT_X0 + 40.0 + k * 40.0
		_belt_arrows.append(_poly(PackedVector2Array([Vector2(bx, GROUND_Y - 10.0), Vector2(bx + 16.0, GROUND_Y - 10.0), Vector2(bx + 16.0, GROUND_Y - 14.0), Vector2(bx + 26.0, GROUND_Y - 8.0), Vector2(bx + 16.0, GROUND_Y - 2.0), Vector2(bx + 16.0, GROUND_Y - 6.0), Vector2(bx, GROUND_Y - 6.0)]), Color(0.42, 0.4, 0.5), 3))


func _ladder(x0: float) -> void:
	# escalera de plataformas (subida a la ruta alta)
	_platform(x0, x0 + 180.0, 448.0)
	_platform(x0 + 180.0, x0 + 320.0, 368.0)
	_platform(x0 + 320.0, x0 + 420.0, 288.0)


func _register_top(x0: float, x1: float, y: float) -> void:
	_tops.append({"x0": x0, "x1": x1, "y": y})


func _load_arena(id: int) -> void:
	arena_id = id % ARENA_NAMES.size()
	match arena_id:
		1:
			# Templo del alba: amanecer cálido, rocas y torre a la izquierda,
			# foso pequeño y casa junto a la meta derecha
			PIT_X0 = 2210.0
			PIT_X1 = 2380.0
			PIT2_X0 = 3050.0
			PIT2_X1 = 3230.0
			PLAT_X0 = 2130.0
			PLAT_X1 = 2460.0
			PLAT_Y = 448.0
			BRIDGE_X0 = 1900.0
			BRIDGE_X1 = 2690.0
			BRIDGE_Y = 288.0
			HOUSE_X = 3850.0
			STEP_R_X0 = 2740.0
			STEP_R_X1 = 2832.0
			STEP_R_Y = 516.0
			BOULDER_X0 = 380.0
			BOULDER_X1 = 608.0
			BOULDER_Y = 440.0
			TOWER_X0 = 700.0
			TOWER_X1 = 868.0
			TOWER_Y = 330.0
			STEP_L_X0 = 4180.0
			STEP_L_X1 = 4272.0
			STEP_L_Y = 516.0
			FENCE_X0 = 940.0
			FENCE_X1 = 1030.0
			col_sky = Color(0.16, 0.09, 0.105)
			col_hill_far = Color(0.215, 0.115, 0.115)
			col_hill_near = Color(0.175, 0.095, 0.10)
			col_pillar = Color(0.15, 0.10, 0.10)
			col_pillar_cap = Color(0.19, 0.13, 0.12)
			col_pit = Color(0.42, 0.12, 0.06)
			col_floor = Color(0.235, 0.16, 0.13)
			col_floor_top = Color(0.47, 0.33, 0.24)
			col_plat = Color(0.31, 0.21, 0.16)
			col_plat_top = Color(0.52, 0.37, 0.26)
			col_wall = Color(0.20, 0.14, 0.12)
			cel_pos = Vector2(3560.0, 120.0)
			cel_col = Color(0.55, 0.32, 0.16)
			cel_detail = Color(0.48, 0.27, 0.13)
			bg_tint_far = Color(1.0, 0.72, 0.5)
			bg_tint_near = Color(1.0, 0.85, 0.68)
		2:
			# Cripta del ocaso: atardecer púrpura, torre a la izquierda,
			# casa a la derecha y foso pequeño junto a la meta de P1
			PIT_X0 = 2210.0
			PIT_X1 = 2380.0
			PIT2_X0 = 3620.0
			PIT2_X1 = 3800.0
			PLAT_X0 = 2130.0
			PLAT_X1 = 2460.0
			PLAT_Y = 448.0
			BRIDGE_X0 = 1900.0
			BRIDGE_X1 = 2690.0
			BRIDGE_Y = 288.0
			HOUSE_X = 3850.0
			STEP_R_X0 = 1550.0
			STEP_R_X1 = 1642.0
			STEP_R_Y = 516.0
			BOULDER_X0 = 3050.0
			BOULDER_X1 = 3278.0
			BOULDER_Y = 440.0
			TOWER_X0 = 380.0
			TOWER_X1 = 548.0
			TOWER_Y = 330.0
			STEP_L_X0 = 4180.0
			STEP_L_X1 = 4272.0
			STEP_L_Y = 516.0
			FENCE_X0 = 940.0
			FENCE_X1 = 1030.0
			col_sky = Color(0.10, 0.06, 0.13)
			col_hill_far = Color(0.14, 0.08, 0.16)
			col_hill_near = Color(0.11, 0.07, 0.13)
			col_pillar = Color(0.13, 0.10, 0.15)
			col_pillar_cap = Color(0.17, 0.13, 0.19)
			col_pit = Color(0.16, 0.05, 0.14)
			col_floor = Color(0.16, 0.13, 0.18)
			col_floor_top = Color(0.34, 0.28, 0.38)
			col_plat = Color(0.22, 0.18, 0.26)
			col_plat_top = Color(0.38, 0.32, 0.44)
			col_wall = Color(0.15, 0.11, 0.17)
			cel_pos = Vector2(1200.0, 130.0)
			cel_col = Color(0.75, 0.45, 0.30)
			cel_detail = Color(0.66, 0.38, 0.26)
			bg_tint_far = Color(0.68, 0.5, 0.9)
			bg_tint_near = Color(0.85, 0.68, 0.95)
		3:
			# Torre del Centinela (tarea 85): pasillo inferior clásico y piso
			# superior corrido (y=320) con dos huecos; el foso central queda
			# a cielo abierto para no pisar el salto al puente
			PIT_X0 = 2210.0
			PIT_X1 = 2380.0
			PIT2_X0 = 1450.0
			PIT2_X1 = 1630.0
			PLAT_X0 = 2130.0
			PLAT_X1 = 2460.0
			PLAT_Y = 448.0
			BRIDGE_X0 = 1900.0
			BRIDGE_X1 = 2690.0
			BRIDGE_Y = 288.0
			HOUSE_X = 4150.0
			STEP_R_X0 = 3760.0
			STEP_R_X1 = 3852.0
			STEP_R_Y = 516.0
			BOULDER_X0 = 380.0
			BOULDER_X1 = 608.0
			BOULDER_Y = 440.0
			TOWER_X0 = 3476.0
			TOWER_X1 = 3644.0
			TOWER_Y = 330.0
			STEP_L_X0 = 340.0
			STEP_L_X1 = 432.0
			STEP_L_Y = 516.0
			FENCE_X0 = 940.0
			FENCE_X1 = 1030.0
			col_sky = Color(0.03, 0.06, 0.07)
			col_hill_far = Color(0.05, 0.10, 0.11)
			col_hill_near = Color(0.045, 0.085, 0.095)
			col_pillar = Color(0.07, 0.12, 0.13)
			col_pillar_cap = Color(0.10, 0.16, 0.17)
			col_pit = Color(0.07, 0.20, 0.18)
			col_floor = Color(0.10, 0.17, 0.18)
			col_floor_top = Color(0.24, 0.38, 0.38)
			col_plat = Color(0.14, 0.24, 0.25)
			col_plat_top = Color(0.28, 0.44, 0.44)
			col_wall = Color(0.08, 0.14, 0.15)
			cel_pos = Vector2(2400.0, 110.0)
			cel_col = Color(0.65, 0.85, 0.80)
			cel_detail = Color(0.50, 0.70, 0.66)
			bg_tint_far = Color(0.60, 0.85, 0.80)
			bg_tint_near = Color(0.80, 0.95, 0.90)
		_:
			# Ruinas de medianoche: noche azulada con luna (valores por defecto)
			PIT_X0 = 2210.0
			PIT_X1 = 2380.0
			PIT2_X0 = 700.0
			PIT2_X1 = 880.0
			PLAT_X0 = 2130.0
			PLAT_X1 = 2460.0
			PLAT_Y = 448.0
			BRIDGE_X0 = 1900.0
			BRIDGE_X1 = 2690.0
			BRIDGE_Y = 288.0
			HOUSE_X = 908.0
			STEP_R_X0 = 2856.0
			STEP_R_X1 = 2948.0
			STEP_R_Y = 516.0
			BOULDER_X0 = 3116.0
			BOULDER_X1 = 3344.0
			BOULDER_Y = 440.0
			TOWER_X0 = 3476.0
			TOWER_X1 = 3644.0
			TOWER_Y = 330.0
			STEP_L_X0 = 500.0
			STEP_L_X1 = 592.0
			STEP_L_Y = 516.0
			FENCE_X0 = 600.0
			FENCE_X1 = 690.0
			col_sky = Color(0.055, 0.05, 0.09)
			col_hill_far = Color(0.075, 0.068, 0.115)
			col_hill_near = Color(0.065, 0.06, 0.10)
			col_pillar = Color(0.085, 0.08, 0.135)
			col_pillar_cap = Color(0.11, 0.10, 0.17)
			col_pit = Color(0.30, 0.07, 0.09)
			col_floor = Color(0.14, 0.13, 0.19)
			col_floor_top = Color(0.30, 0.27, 0.37)
			col_plat = Color(0.20, 0.18, 0.27)
			col_plat_top = Color(0.34, 0.31, 0.42)
			col_wall = Color(0.11, 0.10, 0.16)
			cel_pos = Vector2(2400.0, 118.0)
			cel_col = Color(0.14, 0.13, 0.20)
			cel_detail = Color(0.10, 0.09, 0.15)
			bg_tint_far = Color(0.55, 0.62, 0.85)
			bg_tint_near = Color(0.72, 0.74, 0.92)
	# hazards y escalera a sus posiciones por defecto (la barajada los mueve)
	GRASS_X0 = 1150.0
	GRASS_X1 = 1450.0
	ICE_X0 = 1700.0
	ICE_X1 = 2000.0
	BELT_X0 = 2500.0
	BELT_X1 = 2650.0
	LADDER_X = 1480.0
	_shuffled = false
	# tejados derivados del anclaje de la casa
	_derive_roofs()


func _derive_roofs() -> void:
	ROOF_L_X0 = HOUSE_X
	ROOF_L_X1 = HOUSE_X + 102.0
	ROOF_L_Y = 472.0
	ROOF_H_X0 = HOUSE_X + 112.0
	ROOF_H_X1 = HOUSE_X + 244.0
	ROOF_H_Y = 406.0


func set_arena(id: int) -> void:
	if id % ARENA_NAMES.size() == arena_id:
		return
	if random_arena and id % ARENA_NAMES.size() == 3:
		# la torre de dos pisos no admite barajado (el piso fija el centro)
		random_arena = false
	_load_arena(id)
	if parallax_bg != null:
		parallax_bg.queue_free()
		parallax_bg = null
	if level_root != null:
		level_root.queue_free()
	level_root = Node2D.new()
	level_root.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(level_root)
	goal_polys.clear()
	_tops.clear()
	blood.clear()
	crumble_tiles.clear()
	_build_level()
	scores = [0, 0]
	stats = _fresh_stats()
	match_over = false
	stats_label.visible = false
	set_chaos(false)
	_update_hud()
	_start_round()
	show_msg("ARENA: %s" % ARENA_NAMES[arena_id], 1.2)


func set_random_arena(on: bool) -> void:
	# arena barajada (tarea 86): al activar, el siguiente _start_round baraja;
	# al desactivar, se reconstruye el layout por defecto de la arena actual
	random_arena = on
	if not on:
		_reshuffle_level()
	_start_round()
	show_msg("ARENA BARAJADA: %s" % ("ACTIVADA" if on else "DESACTIVADA"), 1.0)


func _random_layout() -> void:
	# baraja los seis tramos del medio entre las dos bocas de meta y fija
	# las estructuras grandes en las bocas (metas siempre en los extremos)
	_load_arena(arena_id)   # paleta y valores por defecto como base
	_shuffled = true
	# boca izquierda: meta + peldaño + valla + casa con tejado
	STEP_L_X0 = 200.0
	STEP_L_X1 = 292.0
	STEP_L_Y = 516.0
	FENCE_X0 = 330.0
	FENCE_X1 = 420.0
	HOUSE_X = 500.0
	_derive_roofs()
	# boca derecha: meta + peldaño + peñasco + torre de piedra
	STEP_R_X0 = 4070.0
	STEP_R_X1 = 4162.0
	STEP_R_Y = 516.0
	BOULDER_X0 = 4180.0
	BOULDER_X1 = 4408.0
	BOULDER_Y = 440.0
	TOWER_X0 = 4420.0
	TOWER_X1 = 4588.0
	TOWER_Y = 330.0
	# los seis tramos: foso con puente (560), foso seco (240), hierba (340),
	# hielo (340), cinta (190) y escalera (470) — 2140 en total
	var feats := ["foso_central", "foso_seco", "hierba", "hielo", "cinta", "escalera"]
	feats.shuffle()
	var span_x0 := 770.0
	var span_x1 := 4060.0
	var gap := (span_x1 - span_x0 - 2140.0) / 7.0
	var x := span_x0 + gap
	for f in feats:
		match f:
			"foso_central":
				var cx := x + 280.0
				PLAT_X0 = cx - 165.0
				PLAT_X1 = cx + 165.0
				PLAT_Y = 448.0
				PIT_X0 = cx - 85.0
				PIT_X1 = cx + 85.0
				BRIDGE_X0 = PLAT_X0 - 230.0
				BRIDGE_X1 = PLAT_X1 + 230.0
				BRIDGE_Y = 288.0
				x += 560.0
			"foso_seco":
				PIT2_X0 = x + 30.0
				PIT2_X1 = x + 210.0
				x += 240.0
			"hierba":
				GRASS_X0 = x + 20.0
				GRASS_X1 = x + 320.0
				x += 340.0
			"hielo":
				ICE_X0 = x + 20.0
				ICE_X1 = x + 320.0
				x += 340.0
			"cinta":
				BELT_X0 = x + 20.0
				BELT_X1 = x + 170.0
				x += 190.0
			"escalera":
				LADDER_X = x + 25.0
				x += 470.0
		x += gap
	# PIT_* queda anclado a la zona del puente (PLAT_*): _build_level ya ordena
	# los dos fosos por posición al tender los segmentos de suelo


func _reshuffle_level() -> void:
	# reconstruye el nivel con el layout barajado (o el por defecto) sin
	# tocar marcador ni estadísticas
	if random_arena:
		_random_layout()
	else:
		_load_arena(arena_id)
	if parallax_bg != null:
		parallax_bg.queue_free()
		parallax_bg = null
	if level_root != null:
		level_root.queue_free()
	level_root = Node2D.new()
	level_root.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(level_root)
	goal_polys.clear()
	_tops.clear()
	blood.clear()
	crumble_tiles.clear()
	_build_level()


func _top_below(x: float, from_y: float) -> float:
	var best := -1.0
	for t in _tops:
		if x > t["x0"] and x < t["x1"] and t["y"] >= from_y - 4.0:
			if best < 0.0 or t["y"] < best:
				best = t["y"]
	return best


func _hills() -> void:
	# dos capas de colinas tras las ruinas
	var cx := -100.0
	var i := 0
	while cx < LEVEL_W + 200.0:
		var r := 150.0 + 90.0 * ((i * 37) % 5)
		_poly(_circle_points(cx, 700.0, r), col_hill_far, -8)
		cx += r * 0.9
		i += 1
	cx = -150.0
	i = 2
	while cx < LEVEL_W + 200.0:
		var r := 90.0 + 60.0 * ((i * 53) % 4)
		_poly(_circle_points(cx, 720.0, r), col_hill_near, -7)
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
		_add_level(c)


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
	_add_level(t)


class Candle extends Node2D:
	## Vela fantasmal de la cripta: llama verde parpadeante.
	var t := 0.0

	func _ready() -> void:
		t = randf() * 10.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		draw_line(Vector2(0, 0), Vector2(0, -26.0), Color(0.75, 0.72, 0.6), 8.0)
		var f := 1.0 + 0.2 * sin(t * 9.0)
		draw_circle(Vector2(0, -32.0), 18.0 * f, Color(0.4, 0.9, 0.55, 0.10))
		draw_colored_polygon(PackedVector2Array([Vector2(-4, -28), Vector2(0, -28.0 - 14.0 * f), Vector2(4, -28)]), Color(0.55, 0.95, 0.65, 0.95))


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


class VictoryWorm extends Node2D:
	## El gusano del Nidhogg: baja del techo y envuelve al ganador.
	const WORM_TEX := preload("res://art/sprites/worm_body.png")
	# la tira de 300x103 se corta en 3 segmentos de 100 px
	const WORM_SEGS := [
		Rect2(0.0, 0.0, 100.0, 103.0),
		Rect2(100.0, 0.0, 100.0, 103.0),
		Rect2(200.0, 0.0, 100.0, 103.0),
	]
	var t := 0.0
	var target := Vector2.ZERO
	var col := Color(0.22, 0.5, 0.2)

	func _init(pos: Vector2) -> void:
		target = pos
		position = pos + Vector2(0, -620.0)

	func _process(delta: float) -> void:
		t = minf(t + delta / 1.2, 1.0)
		position.y = lerpf(target.y - 620.0, target.y - 10.0, t)
		queue_redraw()

	func _draw() -> void:
		var chomp := 0.35 + 0.65 * t
		# cuerpo: 6 segmentos con la textura (las 3 regiones, repetidas)
		for i in 6:
			var cy := -float(i) * 44.0 - 30.0
			draw_texture_rect_region(WORM_TEX, Rect2(-32.0, cy - 33.0, 64.0, 66.0), WORM_SEGS[i % 3])
		# cabeza: el segmento 0 un punto más grande
		draw_texture_rect_region(WORM_TEX, Rect2(-37.0, -66.0, 74.0, 76.0), WORM_SEGS[0])
		# mandíbulas y ojos (procedurales, como antes)
		var open_ang := 1.2 * (1.0 - chomp)
		for s in [-1.0, 1.0]:
			var pts := PackedVector2Array([
				Vector2(0, -20),
				Vector2(s * 44.0 * cos(open_ang), -20.0 + 44.0 * sin(open_ang)),
				Vector2(s * 10.0, 26.0),
			])
			draw_colored_polygon(pts, Color(0.16, 0.38, 0.16))
		draw_circle(Vector2(-12, -34), 4.0, Color.YELLOW)
		draw_circle(Vector2(12, -34), 4.0, Color.YELLOW)


class Corpse extends Node2D:
	## Cadáver persistente: sale despedido girando, cae y queda tumbado.
	## Con arma de hoja puede quedar empalado en la espada del asesino.
	var col := Color.WHITE
	var body_side := "p1"
	var vel := Vector2.ZERO
	var spin := 0.0
	var rot := 0.0
	var impaler: Player = null
	var grounded := false

	func _init(c: Color, side := "p1") -> void:
		col = c
		body_side = side

	func _process(delta: float) -> void:
		if impaler != null:
			if impaler.state == Player.State.DEAD or not impaler.has_sword or impaler.attack_is_active():
				impaler = null
			else:
				# el cadáver sigue la línea de la hoja según la estancia (tarea 77)
				match impaler.stance:
					Player.H.HIGH:
						position = impaler.position + Vector2(impaler.facing * 26.0, -34.0)
					Player.H.LOW:
						position = impaler.position + Vector2(impaler.facing * 40.0, 14.0)
					_:
						position = impaler.position + Vector2(impaler.facing * 44.0, -6.0)
				queue_redraw()
				return
		if not grounded:
			vel.y += 1500.0 * delta
			position += vel * delta
			rot += spin * delta
			var g := get_parent()
			var floor_y := 560.0
			if g != null and g.has_method("_top_below"):
				var top: float = g._top_below(position.x, position.y)
				if top > 0.0:
					floor_y = top
			if position.y >= floor_y - 8.0:
				position.y = floor_y - 8.0
				grounded = true
		queue_redraw()

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0 if grounded else rot, Vector2.ONE)
		var tex: Texture2D = Player.pose_texture("dead", body_side)
		var w := tex.get_width() * Player.POSE_SCALE
		var h := tex.get_height() * Player.POSE_SCALE
		draw_texture_rect(tex, Rect2(-w * 0.5, 8.0 - h, w, h), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


class BloodPool extends Node2D:
	## Charco de sangre persistente que gotea hacia abajo.
	var col := Color(0.5, 0.1, 0.1)
	var t := 0.0
	var drips: Array[float] = []

	func _init(c: Color) -> void:
		col = c
		for i in 2 + randi() % 2:
			drips.append(randf_range(6.0, 15.0))

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var a := 0.85
		draw_colored_polygon(PackedVector2Array([
			Vector2(-22, -3), Vector2(-8, -6), Vector2(10, -5), Vector2(23, -2),
			Vector2(14, 4), Vector2(-6, 5), Vector2(-18, 3),
		]), Color(col.r, col.g, col.b, a))
		if t > 0.4:
			var g := clampf((t - 0.4) * 1.6, 0.0, 1.0)
			for i in drips.size():
				var dx := -14.0 + 12.0 * float(i)
				draw_rect(Rect2(dx, 0.0, 3.0, drips[i] * g), Color(col.r, col.g, col.b, a * 0.8))


class CrumbleTile extends Node2D:
	## Tramo de plataforma que tiembla al pisarlo y cae (tarea 70).
	var x0: float
	var x1: float
	var y: float
	var body: StaticBody2D
	var state := 0          # 0 intacto, 1 temblando, 2 caído
	var t := 0.0

	func _init(px0: float, px1: float, py: float) -> void:
		x0 = px0
		x1 = px1
		y = py
		position = Vector2((x0 + x1) * 0.5, y + 8.0)
		body = StaticBody2D.new()
		body.collision_layer = 2
		body.collision_mask = 0
		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(x1 - x0, 16.0)
		cs.shape = rect
		body.add_child(cs)
		add_child(body)

	func restore(game: Node) -> void:
		state = 0
		t = 0.0
		position = Vector2((x0 + x1) * 0.5, y + 8.0)
		rotation = 0.0
		body.get_child(0).set_deferred("disabled", false)
		var ya := false
		for top in game._tops:
			if absf(float(top["x0"]) - x0) < 0.5 and absf(float(top["y"]) - y) < 0.5:
				ya = true
				break
		if not ya:
			game._register_top(x0, x1, y)
		queue_redraw()

	func _top_drop(game: Node) -> void:
		# quita la entrada de _tops de este tramo (por x0 e y)
		for i in range(game._tops.size() - 1, -1, -1):
			var top: Dictionary = game._tops[i]
			if absf(float(top["x0"]) - x0) < 0.5 and absf(float(top["y"]) - y) < 0.5:
				game._tops.remove_at(i)

	func _process(delta: float) -> void:
		var game := get_parent().get_parent()
		match state:
			0:
				for p in game.players:
					if p.is_on_floor() and p.position.y > y - 40.0 and p.position.y < y + 8.0 and p.position.x > x0 and p.position.x < x1:
						state = 1
						t = 0.0
						break
			1:
				t += delta
				position.x = (x0 + x1) * 0.5 + sin(t * 60.0) * 2.5
				if t >= 0.4:
					state = 2
					position.x = (x0 + x1) * 0.5
					body.get_child(0).set_deferred("disabled", true)
					_top_drop(game)
			2:
				position.y += 620.0 * delta
				rotation += delta * 1.2
				if position.y > 900.0:
					position.y = 900.0
		queue_redraw()

	func _draw() -> void:
		if state == 2:
			draw_rect(Rect2(-(x1 - x0) * 0.5, -16.0, x1 - x0, 16.0), Color(0.16, 0.14, 0.22))
			return
		var host := get_parent().get_parent()
		draw_texture_rect(host.TEX_FLOOR, Rect2(-(x1 - x0) * 0.5, -8.0, x1 - x0, 16.0), true, host.col_plat)
		draw_texture_rect(host.TEX_FLOOR, Rect2(-(x1 - x0) * 0.5, -8.0, x1 - x0, 5.0), true, host.col_plat_top)


class Pip extends Node2D:
	## Cuadro del HUD de secciones: hueco o relleno del color conquistador.
	const TEX_FILLED := preload("res://art/sprites/pip_filled.png")
	const TEX_HOLLOW := preload("res://art/sprites/pip_hollow.png")
	var fill_col := Color(0, 0, 0, 0)
	var edge_col := Color(0.65, 0.63, 0.72)

	func _draw() -> void:
		draw_texture(TEX_HOLLOW, Vector2(-13.0, -13.0))
		if fill_col.a > 0.0:
			draw_texture_rect(TEX_FILLED, Rect2(-13.0, -13.0, 26.0, 26.0), false, fill_col)


class RespawnBar extends Node2D:
	## Barra de progreso sobre el punto de reaparición.
	var frac := 0.0
	var col := Color.WHITE

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(-30, -6, 60, 12), Color(0, 0, 0, 0.55))
		draw_rect(Rect2(-28, -4, 56.0 * clampf(frac, 0.0, 1.0), 8.0), col)


class SectionGate extends Node2D:
	## Reja entre secciones: cuerpo estático + barrotes visibles. Al abrirse,
	## los barrotes se recogen hacia arriba y la colisión se desactiva.
	var body: StaticBody2D
	var open := false

	func _init(cx: float) -> void:
		position = Vector2(cx, 0.0)
		body = StaticBody2D.new()
		body.collision_layer = 2
		body.collision_mask = 0
		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(14.0, 700.0)
		cs.shape = rect
		cs.position = Vector2(0, 350.0)
		body.add_child(cs)
		add_child(body)

	func set_open(v: bool) -> void:
		open = v
		body.get_child(0).set_deferred("disabled", v)
		queue_redraw()

	func _draw() -> void:
		var iron := Color(0.16, 0.15, 0.19)
		var lite := Color(0.27, 0.26, 0.32)
		draw_rect(Rect2(-14, 60.0, 8.0, 508.0), iron)
		draw_rect(Rect2(6.0, 60.0, 8.0, 508.0), iron)
		var top := 66.0 if open else 130.0
		var bot := 126.0 if open else 560.0
		var bx := -6.0
		while bx <= 6.0:
			draw_rect(Rect2(bx - 2.5, top, 5.0, bot - top), lite)
			bx += 6.0
		draw_rect(Rect2(-10.0, top - 6.0, 20.0, 6.0), iron)


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


func _tower_floor() -> void:
	# torre de dos pisos (tarea 85): piso superior a y=320 con dos huecos
	# (1170-1340 y 3240-3410) y el tramo del foso central a cielo abierto
	# para no pisar el salto al puente; el pasillo inferior queda libre
	for span in [[620.0, 1170.0], [1340.0, 2130.0], [2460.0, 3240.0], [3410.0, 4120.0]]:
		_platform(span[0], span[1], 320.0)
	# escaleras de acceso en ambos extremos (flotantes: se pasa por debajo)
	_platform(450.0, 560.0, 448.0)
	_platform(520.0, 610.0, 384.0)
	_platform(4230.0, 4340.0, 448.0)
	_platform(4180.0, 4270.0, 384.0)
	# antorchas sobre el piso superior, a cada lado de los dos huecos
	for tx in [1120.0, 1390.0, 3190.0, 3460.0]:
		var t := Torch.new()
		t.position = Vector2(tx, 320.0)
		t.z_index = 1
		_add_level(t)


func _house() -> void:
	# fachada y tejado de la aldea; el muro es decorativo: se pasa por la puerta
	var bx := HOUSE_X
	var wall_col := Color(0.23, 0.17, 0.15)
	var wall_lite := Color(0.29, 0.22, 0.19)
	_poly(PackedVector2Array([Vector2(bx + 12, GROUND_Y), Vector2(bx + 232, GROUND_Y), Vector2(bx + 232, 430.0), Vector2(bx + 12, 430.0)]), wall_col, -5)
	_poly(PackedVector2Array([Vector2(bx + 12, 430.0), Vector2(bx + 232, 430.0), Vector2(bx + 232, 424.0), Vector2(bx + 12, 424.0)]), wall_lite, -5)
	# puerta (paso libre) y ventana cálida
	_poly(PackedVector2Array([Vector2(bx + 48, GROUND_Y), Vector2(bx + 100, GROUND_Y), Vector2(bx + 100, 498.0), Vector2(bx + 74, 486.0), Vector2(bx + 48, 498.0)]), Color(0.12, 0.08, 0.07), -4)
	_poly(PackedVector2Array([Vector2(bx + 91, 530.0), Vector2(bx + 95, 530.0), Vector2(bx + 95, 534.0), Vector2(bx + 91, 534.0)]), Color(0.75, 0.62, 0.30), -3)
	var win := GlowSpot.new()
	win.position = Vector2(bx + 164, 514)
	win.radius = 34.0
	win.z_index = -3
	_add_level(win)
	_poly(PackedVector2Array([Vector2(bx + 142, 494.0), Vector2(bx + 186, 494.0), Vector2(bx + 186, 534.0), Vector2(bx + 142, 534.0)]), Color(1.0, 0.78, 0.35, 0.85), -4)
	_poly(PackedVector2Array([Vector2(bx + 162, 494.0), Vector2(bx + 166, 494.0), Vector2(bx + 166, 534.0), Vector2(bx + 162, 534.0)]), Color(0.14, 0.10, 0.08), -3)
	_poly(PackedVector2Array([Vector2(bx + 142, 512.0), Vector2(bx + 186, 512.0), Vector2(bx + 186, 516.0), Vector2(bx + 142, 516.0)]), Color(0.14, 0.10, 0.08), -3)
	# chimenea con humo
	_poly(PackedVector2Array([Vector2(bx + 180, 330.0), Vector2(bx + 208, 330.0), Vector2(bx + 208, 412.0), Vector2(bx + 180, 412.0)]), Color(0.20, 0.15, 0.14), -4)
	_poly(PackedVector2Array([Vector2(bx + 176, 330.0), Vector2(bx + 212, 330.0), Vector2(bx + 212, 320.0), Vector2(bx + 176, 320.0)]), Color(0.26, 0.19, 0.17), -4)
	var smoke := CPUParticles2D.new()
	smoke.position = Vector2(bx + 194, 314)
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
	_add_level(smoke)
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


func _candles() -> void:
	for cx in [HOUSE_X + 260.0, 1420.0, 2500.0, 4050.0]:
		var c := Candle.new()
		c.position = Vector2(cx, GROUND_Y)
		c.z_index = 1
		_add_level(c)


func _tombstones() -> void:
	for tx in [300.0, 1180.0, 2450.0, 4320.0]:
		_poly(PackedVector2Array([Vector2(tx - 16, GROUND_Y), Vector2(tx + 16, GROUND_Y), Vector2(tx + 14, GROUND_Y - 44.0), Vector2(tx, GROUND_Y - 54.0), Vector2(tx - 14, GROUND_Y - 44.0)]), Color(0.24, 0.22, 0.28), -3)


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
	if arena_id == 3:
		# en la torre de dos pisos el peñasco y la torre de piedra estorban
		# el pasillo inferior (no cabe un jugador de pie sobre ellos)
		return
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
	# piedras sueltas decorativas (en sitios libres; x fijas, fuera del barajado)
	if not _shuffled:
		for r in [[1700.0, 12.0], [2050.0, 16.0], [2600.0, 10.0], [4420.0, 11.0]]:
			_poly(_circle_points(r[0], GROUND_Y - r[1] * 0.4, r[1], 9), Color(0.19, 0.18, 0.23), -3)


func _add_level(node: Node) -> void:
	level_root.add_child(node)


func _poly(points: PackedVector2Array, col: Color, z: int) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = points
	p.color = col
	p.z_index = z
	_add_level(p)
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
	_add_level(body)


func _tiled_rect(tex: Texture2D, rect: Rect2, col: Color, z: int) -> void:
	# sprite con repetición de textura: pinta rect rellenándolo con tiles
	var sp := Sprite2D.new()
	sp.texture = tex
	sp.centered = false
	sp.position = rect.position
	sp.region_enabled = true
	sp.region_rect = Rect2(0.0, 0.0, rect.size.x, rect.size.y)
	sp.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sp.modulate = col
	sp.z_index = z
	_add_level(sp)


func _floor_segment(x0: float, x1: float) -> void:
	_static_box(x0, GROUND_Y, x1, GROUND_Y + 140.0)
	_tiled_rect(TEX_FLOOR, Rect2(x0, GROUND_Y, x1 - x0, 140.0), col_floor, -4)
	_tiled_rect(TEX_FLOOR, Rect2(x0, GROUND_Y, x1 - x0, 6.0), col_floor_top, -4)


func _platform(x0: float, x1: float, y: float) -> void:
	_static_box(x0, y, x1, y + 16.0)
	_register_top(x0, x1, y)
	_tiled_rect(TEX_FLOOR, Rect2(x0, y, x1 - x0, 16.0), col_plat, -4)
	_tiled_rect(TEX_FLOOR, Rect2(x0, y, x1 - x0, 5.0), col_plat_top, -4)


func _wall(x0: float, x1: float) -> void:
	_static_box(x0, 0.0, x1, GROUND_Y + 140.0)
	_tiled_rect(TEX_WALL, Rect2(x0, 0.0, x1 - x0, GROUND_Y + 140.0), col_wall, -4)


func _pit_edges(x0: float, x1: float) -> void:
	# remate decorativo en los dos bordes de cada foso
	for side in [x0, x1]:
		var e := Sprite2D.new()
		e.texture = TEX_PIT_EDGE
		e.position = Vector2(side, GROUND_Y - 23.0)
		e.flip_h = side == x1
		e.z_index = -5
		_add_level(e)


func _goal_zone(x0: float, x1: float, col: Color) -> void:
	goal_polys.append(_poly(PackedVector2Array([Vector2(x0, 110.0), Vector2(x1, 110.0), Vector2(x1, GROUND_Y), Vector2(x0, GROUND_Y)]), Color(col.r, col.g, col.b, 0.15), -3))
	var cx := (x0 + x1) * 0.5
	_poly(PackedVector2Array([Vector2(cx - 3, 190.0), Vector2(cx + 3, 190.0), Vector2(cx + 3, GROUND_Y), Vector2(cx - 3, GROUND_Y)]), Color(0.12, 0.11, 0.18), -3)
	var inward := 1.0 if x0 > LEVEL_W * 0.5 else -1.0
	var ar := Sprite2D.new()
	ar.texture = TEX_ARROW
	ar.position = Vector2(cx + inward * 4.0, 214.0)
	ar.flip_h = inward < 0.0
	ar.modulate = col
	ar.z_index = -3
	_add_level(ar)


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
		p.fired_arrow.connect(_on_fired_arrow)
		# con el nodo game en PROCESS_MODE_ALWAYS, los hijos heredarían ALWAYS:
		# los jugadores deben pausarse de verdad con el hit-stop y la pausa (ESC)
		p.process_mode = Node.PROCESS_MODE_PAUSABLE


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
			p.fired_arrow.connect(_on_fired_arrow)
			p.process_mode = Node.PROCESS_MODE_PAUSABLE
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
	if not sections_mode:
		dynamic_zoom = not mode_2v2
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


func set_sections(on: bool) -> void:
	if on == sections_mode:
		return
	sections_mode = on
	for g in gates:
		g.queue_free()
	gates.clear()
	if on:
		var w := LEVEL_W / float(SECTION_COUNT)
		for k in range(1, SECTION_COUNT):
			var g := SectionGate.new(w * float(k))
			g.z_index = 5
			add_child(g)
			gates.append(g)
	section_index = 3
	if section_cam_tween != null and section_cam_tween.is_valid():
		section_cam_tween.kill()
	if on:
		var z := VIEW_W / (LEVEL_W / float(SECTION_COUNT))
		camera.zoom = Vector2(z, z)
		camera.position_smoothing_enabled = false
		camera.position = _section_cam_target()
	else:
		camera.zoom = Vector2(0.9, 0.9) if mode_2v2 else Vector2.ONE
		camera.position_smoothing_enabled = true
	sect_conquered = [0, 0]
	scores = [0, 0]
	stats = _fresh_stats()
	match_over = false
	stats_label.visible = false
	set_chaos(false)
	_update_hud()
	_start_round()
	show_msg("MODO PANTALLAS: %s" % ("ACTIVADO" if on else "DESACTIVADO"), 1.0)


func _update_gates() -> void:
	var w := LEVEL_W / float(SECTION_COUNT)
	var rw := right_of_way
	for i in gates.size():
		var border := float(i + 1) * w
		var open := false
		if rw != null and rw.state != Player.State.DEAD:
			if rw.goal_dir > 0:
				open = rw.position.x > border - w and rw.position.x < border + 40.0
			else:
				open = rw.position.x < border + w and rw.position.x > border - 40.0
		if gates[i].open != open:
			gates[i].set_open(open)


func _cross_section(sec: int) -> void:
	var w := LEVEL_W / float(SECTION_COUNT)
	var dir := 1 if sec > section_index else -1
	section_index = sec
	sect_conquered[_team(right_of_way)] += 1
	show_msg("¡SECCIÓN CONQUISTADA!", 0.9)
	sfx(right_of_way.position, "point", -14.0)
	var x_entry := w * float(sec) + 70.0 if dir > 0 else w * float(sec + 1) - 70.0
	var x_far := w * float(sec + 1) - 90.0 if dir > 0 else w * float(sec) + 90.0
	right_of_way.position.x = x_entry
	for p in players:
		if p == right_of_way or p.state == Player.State.DEAD:
			continue
		p.position.x = x_far
		p.invuln_time = maxf(p.invuln_time, 0.8)
	# pan suave hasta la nueva sección (nunca teleport)
	if section_cam_tween != null and section_cam_tween.is_valid():
		section_cam_tween.kill()
	section_cam_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	section_cam_tween.tween_property(camera, "position", _section_cam_target(), SECTION_PAN_TIME)


func _update_sections() -> void:
	if not sections_mode:
		return
	_update_gates()
	var rw := right_of_way
	if rw == null or rw.state == Player.State.DEAD or round_lock > 0.0:
		return
	var w := LEVEL_W / float(SECTION_COUNT)
	var sec := clampi(int(rw.position.x / w), 0, SECTION_COUNT - 1)
	if sec != section_index:
		_cross_section(sec)


func set_arcade(on: bool) -> void:
	if on == arcade:
		return
	if on and mode_2v2:
		set_mode_2v2(false)
	if on and chaos:
		set_chaos(false)
	arcade = on
	arcade_over = false
	if on:
		arcade_level = 1
		bot_level = _arcade_difficulty()
		players[1].is_bot = true
		set_arena(0)
		show_msg("ARCADE — NIVEL 1", 1.2)
	else:
		# sin esto el bot del arcade quedaba pegado a P2 al salir del modo:
		# Rodrigo seguía moviéndose solo en partidas "normales"
		players[1].is_bot = false
		show_msg("ARCADE: DESACTIVADO", 0.8)


func _arcade_difficulty() -> int:
	return clampi(1 + (arcade_level - 1) / 2, 1, 3)


func _arcade_next() -> void:
	arcade_level += 1
	bot_level = _arcade_difficulty()
	right_of_way = null
	scores = [0, 0]
	stats = _fresh_stats()
	_update_hud()
	var want := (arcade_level - 1) % ARENA_NAMES.size()
	if want != arena_id:
		set_arena(want)
	else:
		match_over = false
		stats_label.visible = false
		_start_round()
	show_msg("ARCADE — NIVEL %d  ·  BOT %s" % [arcade_level, ["FÁCIL", "NORMAL", "DIFÍCIL"][_arcade_difficulty() - 1]], 1.4)


func set_cup(on: bool) -> void:
	if on == cup:
		return
	if on and arcade:
		set_arcade(false)
	if on and mode_2v2:
		set_mode_2v2(false)
	if on and chaos:
		set_chaos(false)
	cup = on
	cup_over = false
	if on:
		_cup_stage(0)
	else:
		players[0].is_bot = false
		players[1].is_bot = false
		show_msg("COPA: DESACTIVADA", 0.8)


func _cup_stage(stage: int) -> void:
	cup_stage = stage
	bot_level = 2
	if stage == 0:
		cup_alive = [true, true]
	scores = [0, 0]
	stats = _fresh_stats()
	match_over = false
	stats_label.visible = false
	_update_hud()
	match stage:
		0:
			players[0].is_bot = false
			players[1].is_bot = true
			show_msg("COPA — SEMIFINAL 1: P1 vs BOT", 1.6)
		1:
			players[0].is_bot = true
			players[1].is_bot = false
			show_msg("COPA — SEMIFINAL 2: P2 vs BOT", 1.6)
		2:
			if not cup_alive[0] and not cup_alive[1]:
				cup_over = true
				match_over = true
				show_msg("EL BOT GANA LA COPA  ·  O: nueva copa", 12.0)
				return
			players[0].is_bot = not cup_alive[0]
			players[1].is_bot = not cup_alive[1]
			show_msg("COPA — FINAL", 1.6)
	_start_round()


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
	hint.text = "P1: A/D mover · W saltar/arriba · S agachar · F atacar · G lanzar    P2: ←/→ · ↑ · ↓ · K atacar · L lanzar    R: revancha\nB: bot P2 · H: aliado P3 · N: bot vs bot · V: 2v2 · T: lluvia de rocas · C: cambiar arena · X: arena barajada · M: música · Mando: stick · A saltar · X atacar · B lanzar"
	hint.position = Vector2(22, VIEW_H - 64)
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.62, 0.60, 0.72))
	cl.add_child(hint)
	hint_label = hint

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

	pips_row = Node2D.new()
	pips_row.position = Vector2(VIEW_W * 0.5 - 2.0 * 44.0 + 16.0, 36.0)
	pips_row.visible = false
	cl.add_child(pips_row)
	pips.clear()
	for k in SECTION_COUNT:
		var pip := Pip.new()
		pip.position = Vector2(44.0 * float(k), 0.0)
		pips_row.add_child(pip)
		pips.append(pip)

	respawn_bar = RespawnBar.new()
	respawn_bar.visible = false
	respawn_bar.z_index = 40
	cl.add_child(respawn_bar)

	fight_label = Label.new()
	fight_label.text = "¡FIGHT!"
	fight_label.position = Vector2(0, VIEW_H * 0.30)
	fight_label.size = Vector2(VIEW_W, 110)
	fight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fight_label.add_theme_font_size_override("font_size", 88)
	fight_label.add_theme_color_override("font_color", Color.WHITE)
	fight_label.add_theme_color_override("font_outline_color", Color.BLACK)
	fight_label.add_theme_constant_override("outline_size", 16)
	fight_label.pivot_offset = Vector2(VIEW_W * 0.5, 55.0)
	fight_label.visible = false
	cl.add_child(fight_label)

	_apply_pixel_font(cl)

	# flecha grande del derecho de avance (tarea 65)
	step_arrow = TextureRect.new()
	step_arrow.texture = preload("res://art/sprites/arrow_neutral.png")
	step_arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	step_arrow.pivot_offset = Vector2(32.0, 21.0)
	step_arrow.position = Vector2(VIEW_W * 0.5 - 32.0, 108.0)
	step_arrow.modulate.a = 0.0
	cl.add_child(step_arrow)


## Fuente pixel opcional (tarea 64): si existe res://art/fonts/pixel.ttf se
## aplica a todos los Labels del HUD; si no, todo queda con la fuente por defecto.
const FONT_PATH := "res://art/fonts/pixel.ttf"


func _apply_pixel_font(root: Node) -> void:
	if not ResourceLoader.exists(FONT_PATH):
		return
	var f: FontFile = load(FONT_PATH)
	for n in _all_labels(root):
		n.add_theme_font_override("font", f)


func _all_labels(node: Node) -> Array[Label]:
	var out: Array[Label] = []
	for c in node.get_children():
		if c is Label:
			out.append(c)
		out.append_array(_all_labels(c))
	return out


func _start_round() -> void:
	if random_arena or _shuffled:
		# arena barajada (tarea 86): cada punto, tramos nuevos
		_reshuffle_level()
	rematch_pending = false
	if Net.is_host() and Net.client_ready:
		ev_round.rpc()
	if worm != null:
		worm.queue_free()
		worm = null
	for s in projectiles:
		s.queue_free()
	projectiles.clear()
	for a in arrows:
		a.queue_free()
	arrows.clear()
	for pk in pickups:
		pk.queue_free()
	pickups.clear()
	for r in rocks:
		r.queue_free()
	rocks.clear()
	for b in blood:
		b.queue_free()
	blood.clear()
	for k in corpses:
		corpses[k].queue_free()
	corpses.clear()
	right_of_way = null
	calm_time = 0.0        # la muerte súbita no sobrevive a la revancha (tarea 67)
	for tile in crumble_tiles:
		tile.restore(self)   # el puente vuelve a estar (tarea 70)
	sudden_death = false
	section_index = 3
	sect_conquered = [0, 0]
	weapon_idx = [0, 0]
	for p in players:
		p.weapon_id = "florete"
	respawn_timers.resize(players.size())
	respawn_timers.fill(0.0)
	_position_players_for_round()
	if skip_countdown:
		_show_fight()
	else:
		# 3·2·1 con los jugadores congelados (tarea 66); round_lock ya congela.
		# El desbloqueo lo da la expiración del lock en _physics_process:
		# _show_fight() aquí provocaba el doble disparo del bucle de cuenta
		round_lock = COUNTDOWN_STEP * 3.0
		for n in 3:
			show_msg("%d" % (3 - n), COUNTDOWN_STEP * 0.8)
			await get_tree().create_timer(COUNTDOWN_STEP).timeout


func show_msg(text: String, dur: float) -> void:
	msg_label.text = text
	msg_label.modulate.a = 1.0
	if msg_tween:
		msg_tween.kill()
	msg_tween = msg_label.create_tween()
	msg_tween.tween_interval(dur)
	msg_tween.tween_property(msg_label, "modulate:a", 0.0, 0.4)
	if Net.is_host() and Net.client_ready:
		ev_msg.rpc(text, dur)


func _show_fight() -> void:
	sfx(Vector2(LEVEL_W * 0.5, 300.0), "fight", -4.0)
	fight_label.visible = true
	fight_label.modulate.a = 1.0
	fight_label.scale = Vector2(1.7, 1.7)
	if fight_tween:
		fight_tween.kill()
	fight_tween = fight_label.create_tween()
	fight_tween.tween_property(fight_label, "scale", Vector2.ONE, 0.22)
	fight_tween.tween_interval(0.45)
	fight_tween.tween_property(fight_label, "modulate:a", 0.0, 0.3)
	fight_tween.tween_callback(func(): fight_label.visible = false)


func _show_step_arrow(p: Player) -> void:
	# flecha grande del derecho de avance (tarea 65): color del verdugo, hacia su meta
	if step_arrow == null:
		return
	step_arrow.flip_h = p.goal_dir < 0
	step_arrow.modulate = Color(p.color.r, p.color.g, p.color.b, 0.0)
	step_arrow.scale = Vector2(2.6, 2.6)
	if step_arrow_tween:
		step_arrow_tween.kill()
	step_arrow_tween = step_arrow.create_tween()
	step_arrow_tween.tween_property(step_arrow, "modulate:a", 1.0, 0.12)
	step_arrow_tween.tween_interval(0.9)
	step_arrow_tween.tween_property(step_arrow, "modulate:a", 0.0, 0.3)


func _hitstop(dur: float) -> void:
	if Net.active():
		return   # pausar el árbol solo en un lado desincronizaría la predicción
	if get_tree().paused:
		return
	hitstop_active = true
	get_tree().paused = true
	get_tree().create_timer(dur, true).timeout.connect(func():
		get_tree().paused = false
		hitstop_active = false)


func _slowmo(scale: float, real_dur: float) -> void:
	if Net.active():
		return   # idem hitstop: la escala de tiempo debe ser idéntica en ambos
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
	_update_pips()


func _update_pips() -> void:
	pips_row.visible = sections_mode
	if not sections_mode:
		return
	for k in SECTION_COUNT:
		var fill := Color(0, 0, 0, 0)
		var edge := Color(0.65, 0.63, 0.72)
		if k < 3 and sect_conquered[1] >= 3 - k:
			fill = P2_COLOR
			edge = P2_COLOR
		elif k > 3 and sect_conquered[0] >= k - 3:
			fill = P1_COLOR
			edge = P1_COLOR
		pips[k].fill_col = fill
		pips[k].edge_col = edge
		pips[k].queue_redraw()


func _update_respawn_bar() -> void:
	var shown := false
	for i in players.size():
		if respawn_timers[i] > 0.0:
			var p := players[i]
			respawn_bar.position = _respawn_pos(p) + Vector2(0, -96)
			respawn_bar.col = p.color
			respawn_bar.frac = respawn_timers[i] / RESPAWN_DELAY
			shown = true
			break
	respawn_bar.visible = shown


func _burst(pos: Vector2, col: Color, amount := 24, speed := 380.0) -> void:
	var cp := CPUParticles2D.new()
	cp.process_mode = Node.PROCESS_MODE_PAUSABLE
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
	if Net.is_host() and Net.client_ready:
		ev_burst.rpc(pos.x, pos.y, col, amount, speed)


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("pause") and not hitstop_active and not Net.active():
		get_tree().paused = not get_tree().paused
		dim.visible = get_tree().paused
		pause_label.visible = get_tree().paused
	if get_tree().paused:
		return
	if Net.is_client():
		# el cliente no simula: manda input, aplica snapshots y predice su jugador
		_client_step(delta)
		return
	shake_time = maxf(0.0, shake_time - delta)
	parry_cd = maxf(0.0, parry_cd - delta)
	# muerte súbita (tarea 67): 45 s sin sangre y todo choque mata
	if not match_over and round_lock <= 0.0:
		calm_time += delta
		if not sudden_death and calm_time >= SUDDEN_DEATH_AFTER:
			sudden_death = true
			show_msg("¡MUERTE SÚBITA!", 1.4)
			sfx(camera.position, "alert", -4.0)
			shake_time = maxf(shake_time, 0.2)
	# murmullo de público (tarea 68): sube con bajas y con el corredor cerca de meta
	crowd_kill_flash = maxf(0.0, crowd_kill_flash - delta * 0.5)
	var near_goal := 0.0
	if right_of_way != null and right_of_way.state != Player.State.DEAD:
		var gx := LEVEL_W - GOAL_W if right_of_way.goal_dir > 0 else GOAL_W
		near_goal = clampf(1.0 - absf(right_of_way.position.x - gx) / 600.0, 0.0, 1.0)
	crowd_excite = move_toward(crowd_excite, clampf(near_goal + crowd_kill_flash, 0.0, 1.0), delta * 0.6)
	if crowd != null:
		crowd.volume_db = lerpf(-44.0, -26.0, crowd_excite)
	# música dinámica (tarea 79): el corredor cerca de meta sube la mezcla
	if music != null:
		var em := 0.0
		if right_of_way != null and right_of_way.state != Player.State.DEAD:
			var gx2 := LEVEL_W - GOAL_W if right_of_way.goal_dir > 0 else GOAL_W
			em = clampf(1.0 - absf(right_of_way.position.x - gx2) / 600.0, 0.0, 1.0)
		if round_lock > 0.0:
			em = 1.0
		music.set_intensity(em, delta)
	if round_lock > 0.0:
		round_lock -= delta
		if round_lock <= 0.0:
			round_lock = 0.0
			# fix del bucle de cuenta atrás (preexistente en main): antes se
			# re-llamaba _start_round() aquí dentro, que volvía a fijar
			# round_lock=2.1 → cuenta 3·2·1 infinita con jugadores congelados
			if rematch_pending:
				rematch_pending = false
				_start_round()
			else:
				_show_fight()
	if match_over and Input.is_action_just_pressed("restart") and not Net.is_client():
		scores = [0, 0]
		stats = _fresh_stats()
		stats_label.visible = false
		match_over = false
		_update_hud()
		_start_round()
	if not Net.active():
		# los modos locales (bots, 2v2, caos, arenas, arcade, copa) no se
		# tocan en partidas online: el 1v1 es la única modalidad sincronizada
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
		if Input.is_action_just_pressed("toggle_2v2") and not arcade and not cup:
			set_mode_2v2(not mode_2v2)
		if Input.is_action_just_pressed("toggle_arena") and not arcade and not cup:
			set_arena(arena_id + 1)
		if Input.is_action_just_pressed("toggle_random") and not arcade and not cup:
			# arena barajada (tarea 86): cada punto se juega con tramos distintos
			if arena_id == 3:
				show_msg("ARENA BARAJADA: NO DISPONIBLE EN LA TORRE", 1.0)
			else:
				set_random_arena(not random_arena)
		if Input.is_action_just_pressed("toggle_sections"):
			set_sections(not sections_mode)
		if Input.is_action_just_pressed("toggle_arcade"):
			set_arcade(not arcade)
		if Input.is_action_just_pressed("toggle_cup"):
			set_cup(not cup)
		if Input.is_action_just_pressed("toggle_chaos"):
			set_chaos(not chaos)
	if Input.is_action_just_pressed("toggle_music"):
		var mp := music.get_node_or_null("MusicPlayer") as AudioStreamPlayer
		if mp != null:
			if mp.playing:
				mp.stop()
			else:
				mp.play()
		# la voz base de la música dinámica sigue a la principal (tarea 79)
		var mb := music.get_node_or_null("MusicBase") as AudioStreamPlayer
		if mb != null:
			if mb.playing:
				mb.stop()
			else:
				mb.play()
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
	_update_respawn_bar()
	for p in players:
		if p.state != Player.State.DEAD and p.position.y > 820.0:
			_kill(p, null)
	for p in players:
		p.frozen = match_over or round_lock > 0.0 or net_wait_peer
		if p.is_bot:
			_bot_think(p, delta)
	for i in players.size():
		var step := absf(players[i].position.x - last_x[i])
		if players[i].state != Player.State.DEAD and step < 60.0:
			stats[i]["dist"] += step
		last_x[i] = players[i].position.x
	_resolve_attacks()
	_resolve_guard_impale()
	_resolve_divekicks()
	_resolve_dives()
	_resolve_sidekicks()
	_resolve_roll_tackles()
	_resolve_stomps()
	_update_projectiles(delta)
	_update_arrows(delta)
	_update_rocks(delta)
	_update_pickups()
	_update_sections()
	_check_goals()
	_update_camera(delta)
	if Net.is_host():
		_host_net_step()


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
			if d == h and atk.has_sword and def.weapon_id != "arco":
				outcome = "parry"   # guardia quieta a la misma altura: parada blanda
			elif h == Player.H.HIGH and d == Player.H.LOW:
				outcome = "miss"
			elif h == Player.H.LOW and not def.is_on_floor():
				outcome = "miss"
		if sudden_death and outcome in ["clash", "parry", "miss"]:
			outcome = "trade"   # muerte súbita: todo contacto mata a ambos
		atk.attack_resolved = true
		match outcome:
			"kill":
				_melee_hit(atk, def)
			"trade":
				_melee_hit(atk, def)
				_kill(atk, null)
			"clash":
				_clash(atk, def)
			"parry":
				_parry(atk, def)
			_:
				pass


func _nearest_foe_in_range(atk: Player) -> Player:
	var rng := Player.PUNCH_RANGE if not atk.has_sword else atk.weapon_reach()
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
	if atk.has_sword and atk.weapon_id == "espada" and def.has_sword:
		# el espadón desarma en vez de clavar
		var push := 1 if def.position.x >= atk.position.x else -1
		def.has_sword = false
		_drop_sword(def.position + Vector2(-float(def.facing) * 110.0, -30.0), Color(0.87, 0.9, 0.95), def.weapon_id)
		def.knockdown(push)
		_net_ev_hit(def, 1, float(push) * 260.0)
		_burst(def.position + Vector2(0, -20), Color(0.95, 0.95, 1.0), 10, 260.0)
		sfx(def.position, "throw", -12.0)
		shake_time = maxf(shake_time, 0.12)
	elif atk.has_sword:
		_kill(def, atk)
	else:
		var push := 1 if def.position.x >= atk.position.x else -1
		if def.has_sword and atk.stance != Player.H.LOW:
			# puñetazo de pie: desarma y aturde
			def.has_sword = false
			_drop_sword(def.position + Vector2(-float(def.facing) * 110.0, -30.0), Color(0.87, 0.9, 0.95), def.weapon_id)
			def.state = Player.State.STUNNED
			def.stun_time = 0.5
			def.velocity = Vector2(push * 160.0, -120.0)
			_net_ev_hit(def, 2, float(push) * 160.0, -120.0, 0.5)
			_burst(def.position + Vector2(0, -20), Color(0.95, 0.95, 1.0), 8, 240.0)
			sfx(def.position, "throw", -12.0)
		else:
			# patada baja (agachado) o rival ya desarmado: derriba
			def.knockdown(push)
			_net_ev_hit(def, 1, float(push) * 260.0)
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
	_net_ev_hit(b, 0, float(push_b) * 380.0)
	_net_ev_hit(a, 0, -float(push_b) * 380.0)
	for p in disarmed:
		p.has_sword = false
		_drop_sword(p.position + Vector2(-float(p.facing) * 110.0, -30.0), Color(0.87, 0.9, 0.95), p.weapon_id)
		_burst(p.position + Vector2(0, -20), Color(0.95, 0.95, 1.0), 8, 240.0)
		sfx(p.position, "throw", -14.0)


func _parry(a: Player, b: Player) -> void:
	# parada blanda: nadie muere, nadie se aturde; rebote de separación y chispa
	var mid := Vector2((a.position.x + b.position.x) * 0.5, minf(a.position.y, b.position.y) - 14.0)
	_burst(mid, Color(1.0, 0.93, 0.55), 8, 240.0)
	sfx(mid, "clash", -12.0)
	var push_b := 1 if b.position.x >= a.position.x else -1
	a.apply_push(Vector2(-float(push_b) * PARRY_IMPULSE, 0.0), PARRY_PUSH_TIME)
	b.apply_push(Vector2(float(push_b) * PARRY_IMPULSE, 0.0), PARRY_PUSH_TIME)
	_net_ev_hit(a, 3, -float(push_b) * PARRY_IMPULSE, 0.0, PARRY_PUSH_TIME)
	_net_ev_hit(b, 3, float(push_b) * PARRY_IMPULSE, 0.0, PARRY_PUSH_TIME)
	parry_cd = PARRY_COOLDOWN


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
			_net_ev_hit(def, 1, float(push) * 260.0)
			# la patada voladora hace soltar el arma a su víctima (lejos de ella)
			if def.has_sword:
				def.has_sword = false
				_drop_sword(def.position + Vector2(-float(def.facing) * 110.0, -30.0), Color(0.87, 0.9, 0.95), def.weapon_id)
			p.state = Player.State.JUMP
			p.velocity = Vector2(-p.facing * 210.0, -440.0)
			_net_ev_hit(p, 5, -float(p.facing) * 210.0, -440.0)
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


func _resolve_dives() -> void:
	for p in players:
		if p.state != Player.State.DIVE or p.dive_resolved:
			continue
		for def in _foes_of(p):
			if def.state == Player.State.DEAD or def.invuln_time > 0.0:
				continue
			if absf(def.position.x - p.position.x) > 40.0 or absf(def.position.y - p.position.y) > 50.0:
				continue
			p.dive_resolved = true
			if def.state == Player.State.ATTACK and def.attack_is_active() and def.attack_height == Player.H.MID:
				_clash(def, p)
			elif p.has_sword:
				_kill(def, p)
			else:
				var push := 1 if def.position.x >= p.position.x else -1
				def.knockdown(push)
				_net_ev_hit(def, 1, float(push) * 260.0)
			p.state = Player.State.KNOCKDOWN
			p.knockdown_time = 0.6
			p.velocity = Vector2(-float(p.facing) * 160.0, -160.0)
			_net_ev_hit(p, 4, -float(p.facing) * 160.0, -160.0, 0.6)
			shake_time = maxf(shake_time, 0.14)
			break


func _resolve_sidekicks() -> void:
	for p in players:
		if p.state != Player.State.SIDEKICK or p.sidekick_resolved:
			continue
		for def in _foes_of(p):
			if def.state == Player.State.DEAD or def.invuln_time > 0.0:
				continue
			if absf(def.position.x - p.position.x) > 42.0 or absf(def.position.y - p.position.y) > 56.0:
				continue
			p.sidekick_resolved = true
			var push := 1 if def.position.x >= p.position.x else -1
			def.knockdown(push)
			_net_ev_hit(def, 1, float(push) * 260.0)
			if def.has_sword:
				def.has_sword = false
				# el arma sale despedida lejos: si no, el caído la recogería al instante
				_drop_sword(def.position + Vector2(-float(def.facing) * 110.0, -30.0), Color(0.87, 0.9, 0.95), def.weapon_id)
			p.state = Player.State.JUMP
			p.velocity = Vector2(-p.facing * 210.0, -440.0)
			_net_ev_hit(p, 5, -float(p.facing) * 210.0, -440.0)
			_burst(def.position, Color(1, 1, 1), 10, 240.0)
			sfx(def.position, "hit", -10.0)
			shake_time = maxf(shake_time, 0.12)
			break


func _resolve_roll_tackles() -> void:
	# slide tackle: atacar durante la rodada derriba (no mata) al rival cercano
	for p in players:
		if p.state != Player.State.ROLL or p.roll_hit:
			continue
		if not p.held("attack"):
			continue
		for def in _foes_of(p):
			if def.state == Player.State.DEAD or def.invuln_time > 0.0:
				continue
			if absf(def.position.x - p.position.x) > Player.PUNCH_RANGE + 24.0 or absf(def.position.y - p.position.y) > 50.0:
				continue
			p.roll_hit = true
			var push := 1 if def.position.x >= p.position.x else -1
			def.knockdown(push)
			_net_ev_hit(def, 1, float(push) * 260.0)
			_burst(def.position, Color(1, 1, 1), 8, 200.0)
			sfx(def.position, "hit", -10.0)
			shake_time = maxf(shake_time, 0.1)
			break


func _resolve_guard_impale() -> void:
	# guardia pasiva: solo de pie y parado (correr no guarda)
	for g in players:
		if g.state != Player.State.IDLE or not g.has_sword or g.invuln_time > 0.0:
			continue
		if g.weapon_id == "arco":
			# el arco no empala: no tiene hoja (tarea 24)
			continue
		for f in _foes_of(g):
			if f.state == Player.State.DEAD or f.invuln_time > 0.0:
				continue
			if f.attack_is_active():
				continue
			# el dive, el sidekick y la rodada tienen su propia resolución (tareas 34/35/45)
			if f.state in [Player.State.DIVE, Player.State.SIDEKICK, Player.State.ROLL]:
				continue
			var dx := (f.position.x - g.position.x) * g.facing
			if dx < 8.0 or dx > Player.ATTACK_RANGE * 0.85:
				continue
			if absf(f.position.y - g.position.y) > 56.0:
				continue
			# solo empala a quien se mueve HACIA la guardia (o cae sobre ella)
			var hacia := f.velocity.x * -float(g.facing) > 140.0
			if not hacia:
				continue
			if f.stance == g.stance:
				if sudden_death:
					_kill(f, g)   # en muerte súbita el rebote también mata (tarea 67)
					return
				if parry_cd > 0.0:
					continue
				# rebote mínimo: ambos se separan sin stun ni desarme
				f.apply_push(Vector2(-float(f.facing) * CLASH_IMPULSE, 0.0), CLASH_PUSH_TIME)
				g.apply_push(Vector2(-float(g.facing) * CLASH_IMPULSE, 0.0), CLASH_PUSH_TIME)
				_net_ev_hit(f, 3, -float(f.facing) * CLASH_IMPULSE, 0.0, CLASH_PUSH_TIME)
				_net_ev_hit(g, 3, -float(g.facing) * CLASH_IMPULSE, 0.0, CLASH_PUSH_TIME)
				var mid := Vector2((f.position.x + g.position.x) * 0.5, minf(f.position.y, g.position.y) - 14.0)
				_burst(mid, Color(1.0, 0.93, 0.55), 6, 200.0)
				sfx(mid, "clash", -14.0)
				parry_cd = PARRY_COOLDOWN
			else:
				_kill(f, g)
			return


func _resolve_stomps() -> void:
	for p in players:
		if p.state not in [Player.State.IDLE, Player.State.RUN] or not p.is_on_floor():
			continue
		if not p.held("down"):
			continue
		for def in _foes_of(p):
			if def.state != Player.State.KNOCKDOWN or def.invuln_time > 0.0:
				continue
			if absf(def.position.x - p.position.x) > 34.0 or absf(def.position.y - p.position.y) > 50.0:
				continue
			# pisotón letal: el derribado estalla; el ejecutor, invulnerable (tarea 76)
			_burst(def.position, def.color, 60, 560.0)
			p.invuln_time = maxf(p.invuln_time, 0.4)
			_kill(def, p)
			shake_time = maxf(shake_time, 0.2)
			break


func _kill(def: Player, atk: Player) -> void:
	if def.state == Player.State.DEAD:
		return
	calm_time = 0.0        # cualquier muerte apaga la muerte súbita (tarea 67)
	sudden_death = false
	def.die()
	stats[def.player_id - 1]["deaths"] += 1
	if atk != null:
		stats[atk.player_id - 1]["kills"] += 1
	_hitstop(0.08)
	respawn_timers[def.player_id - 1] = RESPAWN_DELAY
	if Net.is_host() and Net.client_ready:
		var dir := -float(def.facing)
		if atk != null:
			var d2 := signf(def.position.x - atk.position.x)
			if d2 != 0.0:
				dir = d2
		ev_kill.rpc(def.player_id, atk.player_id if atk != null else 0, def.position.x, def.position.y, dir)
	_burst(def.position, def.color, 34, 440.0)
	_add_blood(def.position, def.color)
	if def.has_sword:
		def.has_sword = false
		_drop_sword(def.position + Vector2(0.0, -20.0), Color(0.87, 0.9, 0.95), def.weapon_id)
	_slowmo(0.35, 0.5)
	_burst(def.position, Color(0.95, 0.95, 1.0), 12, 260.0)
	_spawn_corpse(def, atk)
	sfx(def.position, "kill", -6.0)
	crowd_kill_flash = 1.0   # el público responde a la baja (tarea 68)
	shake_time = maxf(shake_time, 0.3)
	_after_death(def, atk)


func _spawn_corpse(def: Player, atk: Player) -> void:
	var c := Corpse.new(Color(def.color), "p1" if (def.player_id == 1 or def.player_id == 3) else "p2")
	c.position = def.position
	if atk != null:
		var dir := signf(def.position.x - atk.position.x)
		if dir == 0.0:
			dir = -float(def.facing)
		c.vel = Vector2(dir * 300.0, -260.0)
		c.spin = dir * randf_range(2.0, 5.0)
		if atk.has_sword and atk.weapon_id in ["florete", "daga"]:
			# solo las armas de hoja empalan (la tarea 23 añadió los tipos)
			c.impaler = atk
	else:
		c.vel = Vector2(-float(def.facing) * 160.0, -200.0)
		c.spin = randf_range(-3.0, 3.0)
	c.z_index = 8
	c.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(c)
	corpses[def.player_id] = c


func _after_death(def: Player, atk: Player) -> void:
	# el asesino toma el paso; si la muerte es del entorno, el compañero
	# hereda el paso del portador caído (o lo gana el último vivo en 1v1)
	if atk != null and atk.state != Player.State.DEAD:
		right_of_way = atk
		_show_step_arrow(atk)
		return
	if right_of_way == def:
		var mate := _living_teammate(def)
		if mate != null:
			right_of_way = mate
			_show_step_arrow(mate)
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
	if corpses.has(p.player_id):
		corpses[p.player_id].queue_free()
		corpses.erase(p.player_id)
	var pos := _respawn_pos(p)
	var face := 1
	if right_of_way != null:
		face = 1 if right_of_way.position.x > pos.x else -1
	else:
		face = 1 if pos.x < LEVEL_W * 0.5 else -1
	p.weapon_id = _next_weapon(p)
	p.revive(pos, face)
	sfx(pos, "respawn", -12.0)
	if Net.is_host() and Net.client_ready:
		ev_respawn.rpc(p.player_id, pos.x, pos.y, face, p.weapon_id)


func _next_weapon(p: Player) -> String:
	var i := p.player_id - 1
	if i < 0 or i >= weapon_idx.size():
		return "florete"
	weapon_idx[i] = (weapon_idx[i] + 1) % GameConfig.WEAPON_ORDER.size()
	return GameConfig.WEAPON_ORDER[weapon_idx[i]]


func _respawn_pos(p: Player) -> Vector2:
	if right_of_way == null:
		var offs := [220.0, -220.0, 620.0, -620.0]
		var fx := clampf(_out_of_pit(LEVEL_W * 0.5 + offs[p.player_id - 1]), GOAL_W + 60.0, LEVEL_W - GOAL_W - 60.0)
		return Vector2(fx, 200.0)
	if sections_mode:
		var w := LEVEL_W / float(SECTION_COUNT)
		var sdir := 1 if right_of_way.goal_dir > 0 else -1
		var sec := clampi(section_index + sdir, 0, SECTION_COUNT - 1)
		var cx := w * (float(sec) + 0.5)
		if sec == section_index:
			# ya no hay sección delante: reaparece al fondo de la actual
			cx = w * float(sec + 1) - 100.0 if sdir > 0 else w * float(sec) + 100.0
		return Vector2(_out_of_pit(cx), 200.0)
	var dir := float(right_of_way.goal_dir)
	var x := right_of_way.position.x + dir * 540.0
	if x > PIT_X0 - 50.0 and x < PIT_X1 + 50.0:
		x = PIT_X1 + 70.0 if dir > 0.0 else PIT_X0 - 70.0
	elif x > PIT2_X0 - 50.0 and x < PIT2_X1 + 50.0:
		x = PIT2_X1 + 70.0 if dir > 0.0 else PIT2_X0 - 70.0
	x = clampf(x, GOAL_W + 60.0, LEVEL_W - GOAL_W - 60.0)
	return Vector2(x, 200.0)


func _on_threw_sword(p: Player) -> void:
	if Net.is_client():
		return   # los proyectiles del cliente llegan dentro del snapshot
	var s := SwordProjectile.new()
	s.process_mode = Node.PROCESS_MODE_PAUSABLE
	s.thrower = p
	s.color = Color(0.87, 0.9, 0.95)
	s.position = p.position + Vector2(p.facing * 26.0, -8.0)
	s.vel = Vector2(p.facing * float(p.weapon()["thrown_speed"]), 0.0)
	s.spin = p.facing * 18.0
	s.weapon_id = p.weapon_id
	add_child(s)
	projectiles.append(s)
	sfx(p.position, "throw", -14.0)
	stats[p.player_id - 1]["throws"] += 1


func _on_fired_arrow(p: Player, height: int, charge: float) -> void:
	if Net.is_client():
		return   # idem lanzamientos: las flechas viajan en el snapshot
	var a := Arrow.new()
	a.process_mode = Node.PROCESS_MODE_PAUSABLE
	a.thrower = p
	a.height = height
	a.position = p.position + Vector2(p.facing * 22.0, [-40.0, -8.0, 16.0][height])
	a.vel = Vector2(p.facing * float(GameConfig.WEAPONS["arco"]["arrow_speed"]), 0.0)
	add_child(a)
	arrows.append(a)
	sfx(p.position, "throw", -16.0)


func _update_arrows(delta: float) -> void:
	var w := LEVEL_W
	for a in arrows.duplicate():
		if a.stuck:
			arrows.erase(a)
			continue
		a.position += a.vel * delta
		if a.position.x < 26.0 or a.position.x > w - 26.0:
			sfx(a.position, "arrow_bounce", -20.0)
			a.stuck = true
			a.vel = Vector2.ZERO
			continue
		for p in players:
			if p.state == Player.State.DEAD or p.invuln_time > 0.0:
				continue
			# antes de rebotar solo amenaza al equipo rival
			if a.bounces == 0 and a.thrower != null and _team(p) == _team(a.thrower):
				continue
			if absf(p.position.x - a.position.x) > 24.0 or absf(p.position.y - a.position.y) > 34.0:
				continue
			var guards: bool = (p.stance == a.height and p.state in [Player.State.IDLE, Player.State.RUN]) or p.attack_is_active()
			# patada desarmada (tarea 74): el puñetazo activo refleja a cualquier altura
			if not guards and p.attack_is_active() and not p.has_sword:
				guards = true
			if guards:
				a.vel = Vector2(a.vel.x * -0.85, 0.0)
				a.bounces += 1
				if a.bounces >= ARROW_MAX_BOUNCES or absf(a.vel.x) < ARROW_MIN_SPEED:
					a.stuck = true
					a.vel = Vector2.ZERO
					break
				_burst(a.position, Color(0.9, 0.9, 1.0), 8, 220.0)
				sfx(a.position, "arrow_bounce", -14.0)
			else:
				_kill(p, a.thrower if a.bounces == 0 else null)
				arrows.erase(a)
				a.queue_free()
			break


func _update_projectiles(delta: float) -> void:
	var done: Array[SwordProjectile] = []
	for s in projectiles:
		s.position += s.vel * delta
		if s.position.x < 26.0 or s.position.x > LEVEL_W - 26.0:
			_drop_sword(s.position, s.color, s.weapon_id)
			done.append(s)
			continue
		for p in players:
			if s.thrower != null and _team(p) == _team(s.thrower):
				continue
			if p.state == Player.State.DEAD or p.invuln_time > 0.0:
				continue
			if absf(p.position.x - s.position.x) < 30.0 and absf(p.position.y - s.position.y) < 36.0:
				# desvía solo si la estancia del guardián está entre las
				# alturas a las que el arma lanzada mata (regla del hermano)
				var kills: Array = GameConfig.WEAPONS[s.weapon_id]["thrown_kills"]
				var vs: String = ["LOW", "MID", "HIGH"][p.stance]
				var blocks: bool = (vs in kills and p.state in [Player.State.IDLE, Player.State.RUN, Player.State.JUMP]) or (p.state == Player.State.ATTACK and p.attack_is_active())
				if blocks:
					_burst(s.position, Color(0.9, 0.9, 1.0), 10, 260.0)
					sfx(s.position, "clash", -12.0)
					_drop_sword(s.position, s.color, s.weapon_id)
				else:
					if vs in kills:
						_kill(p, s.thrower)
					else:
						# no mata a esa altura (o nunca mata, como el arco): derriba
						var push := 1 if p.position.x >= s.position.x else -1
						p.knockdown(push)
						_net_ev_hit(p, 1, float(push) * 260.0)
						_burst(s.position, Color(0.9, 0.9, 1.0), 10, 260.0)
						sfx(s.position, "clash", -12.0)
						_drop_sword(s.position, s.color, s.weapon_id)
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


func _add_blood(pos: Vector2, col: Color) -> void:
	# solo hay sangre si la víctima cayó cerca de un suelo pisable
	if absf(pos.y - (GROUND_Y - 29.0)) > 80.0:
		return
	var c := Color(0.5, 0.1, 0.1).lerp(col.darkened(0.3), 0.45)
	var bp := BloodPool.new(c)
	bp.position = Vector2(_out_of_pit(pos.x) + randf_range(-14.0, 14.0), GROUND_Y + randf_range(-2.0, 2.0))
	var splat := Sprite2D.new()
	splat.texture = TEX_BLOOD[randi() % TEX_BLOOD.size()]
	splat.position = Vector2(randf_range(-8.0, 8.0), -8.0)
	splat.modulate = c
	bp.add_child(splat)
	bp.z_index = 3
	_add_level(bp)
	blood.append(bp)
	if blood.size() > 200:
		var old: Node = blood.pop_front()
		old.queue_free()


func _drop_sword(pos: Vector2, col: Color, wid := "florete") -> void:
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
	pk.process_mode = Node.PROCESS_MODE_PAUSABLE
	pk.weapon_id = wid
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
				p.weapon_id = pk.weapon_id
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
	r.process_mode = Node.PROCESS_MODE_PAUSABLE
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
	if Net.is_host() and Net.client_ready:
		ev_point.rpc(_team(p), p.position.x, p.position.y)
	if scores[_team(p)] >= MatchRules.win_score:
		if arcade:
			if _team(p) == 0:
				_arcade_next()
				return
			match_over = true
			arcade_over = true
			show_msg("ARCADE TERMINADO EN EL NIVEL %d  ·  Y: reintentar" % arcade_level, 12.0)
			return
		if cup:
			if cup_stage < 2:
				var human_team: int = cup_stage
				cup_alive[human_team] = (_team(p) == human_team)
				match_over = true
				show_msg("FIN DE LA %s" % ("SEMIFINAL 1" if cup_stage == 0 else "SEMIFINAL 2"), 1.6)
				get_tree().create_timer(1.8).timeout.connect(func():
					if cup and not cup_over:
						_cup_stage(cup_stage + 1))
				return
			cup_over = true
			match_over = true
			show_msg("¡P%d GANA LA COPA!  ·  O: nueva copa" % p.player_id, 12.0)
			return
		match_over = true
		_spawn_worm(p)
		if mode_2v2:
			var team_name := "AZUL" if _team(p) == 0 else "ROJO"
			show_msg("¡GANA EL EQUIPO %s!  ·  R: revancha" % team_name, 12.0)
		else:
			show_msg("¡GANA P%d!  ·  R: revancha" % p.player_id, 12.0)
		if Net.is_host() and Net.client_ready:
			ev_match_over.rpc(p.player_id)
		stats_label.text = _stats_text()
		get_tree().create_timer(1.5).timeout.connect(func():
			if match_over:
				stats_label.visible = not Net.active())  # las stats locales mienten a medias online
	else:
		round_lock = 1.4
		rematch_pending = true   # al expirar el lock se arranca ronda nueva
		show_msg("¡PUNTO!", 1.0)


func _spawn_worm(p: Player) -> void:
	if worm != null:
		worm.queue_free()
	worm = VictoryWorm.new(p.position + Vector2(0, -30.0))
	worm.z_index = 30
	worm.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(worm)


func _stats_text() -> String:
	var lines: Array[String] = []
	for i in players.size():
		var s := stats[i]
		lines.append("P%d   bajas %d   ·   muertes %d   ·   lanzó %d   ·   corrió %d m" % [
			i + 1, s["kills"], s["deaths"], s["throws"], int(round(float(s["dist"]) / 32.0)),
		])
	return "\n".join(lines)


func _update_camera(delta: float) -> void:
	if sections_mode:
		_update_section_camera()
		return
	# encuadre teatral (tarea 78): los vivos siempre en pantalla
	var alive_x: Array[float] = []
	for p in players:
		if p.state != Player.State.DEAD:
			alive_x.append(p.position.x)
	var tx := camera.position.x
	var lo := 0.0
	var hi := 0.0
	if alive_x.size() > 0:
		lo = alive_x[0]
		hi = alive_x[0]
		for x in alive_x:
			lo = minf(lo, x)
			hi = maxf(hi, x)
		tx = (lo + hi) * 0.5
	if dynamic_zoom and not mode_2v2 and alive_x.size() >= 2:
		var spread := hi - lo
		var zt := clampf(VIEW_W * CAM_FIT_USE / maxf(spread, 220.0), CAM_ZOOM_FAR, CAM_ZOOM_NEAR)
		var z := move_toward(camera.zoom.x, zt, delta * 0.9)
		camera.zoom = Vector2(z, z)
	var half := VIEW_W * 0.5 / camera.zoom.x
	tx = clampf(tx, half, LEVEL_W - half)
	camera.position = Vector2(tx, VIEW_H * 0.5 + 6.0)
	if shake_time > 0.0:
		camera.offset = Vector2(randf_range(-9.0, 9.0), randf_range(-7.0, 7.0)) * (shake_time * 4.0)
	else:
		camera.offset = Vector2.ZERO


## Centro que encuadra la sección actual completa (1 sección = 1 pantalla).
func _section_cam_target() -> Vector2:
	var w := LEVEL_W / float(SECTION_COUNT)
	var z := VIEW_W / w
	var cx := w * (float(section_index) + 0.5)
	return Vector2(cx, GROUND_Y + SECTION_BOTTOM_MARGIN - (VIEW_H / z) * 0.5)


## Modo pantallas: cámara enclavada en la sección; solo el pan del cruce la mueve.
func _update_section_camera() -> void:
	if section_cam_tween == null or not section_cam_tween.is_valid():
		camera.position = _section_cam_target()
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
		elif foe.has_sword and foe.state == Player.State.IDLE and adx < 150.0:
			# no caminar contra la guardia: atacar o retroceder
			if randf() < float(cfg["atk"]) * 2.0:
				tap = "attack"
			elif sd > 0.0:
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
	# con el arco: tensar mientras el rival está a distancia de flecha
	# (soltará al acercarse o alejarse → dispara con el tensado completo)
	if p.weapon_id == "arco" and p.has_sword and foe != null and on_floor \
			and adx > 100.0 and adx < 620.0:
		want["attack"] = true
		tap = ""
	# derribado: levantarse (arriba; con un poco de aleatorio, lateral)
	if p.state == Player.State.KNOCKDOWN and p.knockdown_time <= 0.0:
		want["up"] = true
		if randf() < 0.3:
			want["up"] = false
			want["right" if sd > 0.0 else "left"] = true
	p.bot_held = want
	if tap != "" and p.state in [Player.State.IDLE, Player.State.RUN, Player.State.JUMP]:
		p.bot_held[tap] = true


# =============================================================================
# ONLINE (tarea 85): host autoritativo + cliente con predicción del propio P2
# =============================================================================

func _host_setup() -> void:
	players[1].net_remote = true
	players[1].is_bot = false
	if hint_label != null:
		hint_label.text = "ONLINE — eres P1 (NACHO): A/D mover · W saltar/arriba · S agachar · F atacar · G lanzar\nGana P1 o P2 a 3 puntos  ·  R: revancha al terminar el partido"
	# posiciones de ronda ya: sin esto los duelistas nacen en (0,0) y caen
	# contra el muro izquierdo mientras llega el rival
	_position_players_for_round()
	if Net.client_ready:
		_start_round()
	else:
		net_wait_peer = true   # el bucle principal congela con este flag
		show_msg("ESPERANDO AL RIVAL...", 9999.0)
		Net.client_became_ready.connect(_on_client_ready, CONNECT_ONE_SHOT)


func _on_client_ready() -> void:
	net_wait_peer = false
	_start_round()


func _client_setup() -> void:
	players[0].net_puppet = true
	players[0].is_bot = false
	players[1].is_bot = false
	net_wait_peer = true   # hasta el primer ev_round del host
	_position_players_for_round()
	if hint_label != null:
		hint_label.text = "ONLINE — eres P2 (RODRIGO): ←/→ mover · ↑ saltar/arriba · ↓ agachar · K atacar · L lanzar\nLas reglas las fija el anfitrión (P1)"
	Net.net_ready.rpc_id(1)


## Coloca a los duelistas en la línea de inicio (lo usa _start_round y los
## setups online para que nadie nazca en (0,0) esperando al rival).
func _position_players_for_round() -> void:
	var offs := [-220.0, 220.0, -620.0, 620.0]
	for i in players.size():
		var o: float = offs[i]
		# el barajado puede poner un foso bajo el centro: reaparición a suelo firme
		var sx := clampf(_out_of_pit(LEVEL_W * 0.5 + o), GOAL_W + 60.0, LEVEL_W - GOAL_W - 60.0)
		players[i].reset_to(Vector2(sx, GROUND_Y - 29.0), -1 if o > 0.0 else 1)


func _on_net_drop() -> void:
	# se cortó el enlace en plena partida: volver al título sin colgar el árbol
	get_tree().paused = false
	Net.shutdown()
	get_tree().change_scene_to_file("res://scenes/title.tscn")


# --- host: aplicar input remoto y emitir snapshots --------------------------

@rpc("any_peer", "unreliable")
func net_input(h: Dictionary) -> void:
	if not Net.is_host() or players.size() < 2:
		return
	players[1].net_held = h


func _net_ev_hit(p: Player, kind: int, sx := 0.0, sy := 0.0, st := 0.0) -> void:
	if Net.is_host() and Net.client_ready:
		ev_hit.rpc(p.player_id, kind, sx, sy, st)


func _net_pack_player(p: Player) -> Dictionary:
	return {
		"x": p.position.x, "y": p.position.y, "vx": p.velocity.x, "vy": p.velocity.y,
		"st": p.state, "sc": p.stance, "fc": p.facing, "hs": p.has_sword,
		"wid": p.weapon_id, "rp": p.run_phase, "at": p.attack_time,
		"ah": p.attack_height, "iv": p.invuln_time, "kd": p.knockdown_time,
		"rt": p.roll_time, "sd": p.sidekick_time, "dv": p.dive_time,
		"bw": p.bow_time, "tp": p.throw_pose_time, "am": p.anim_time,
	}


func _host_net_step() -> void:
	if not Net.client_ready:
		return
	net_tick += 1
	if net_tick % NET_SNAP_EVERY != 0:
		return
	var proj := []
	for s in projectiles:
		proj.append({
			"x": s.position.x, "y": s.position.y, "vx": s.vel.x, "sp": s.spin,
			"wid": s.weapon_id, "t": s.thrower.player_id if s.thrower != null else 0,
		})
	var ars := []
	for a in arrows:
		if not a.stuck:
			ars.append({
				"x": a.position.x, "y": a.position.y, "vx": a.vel.x,
				"h": a.height, "b": a.bounces,
				"t": a.thrower.player_id if a.thrower != null else 0,
			})
	var piks := []
	for pk in pickups:
		piks.append({"x": pk.position.x, "y": pk.position.y, "wid": pk.weapon_id})
	net_snap.rpc({
		"ser": net_tick,
		"scores": scores,
		"rw": right_of_way.player_id if right_of_way != null else 0,
		"rl": round_lock,
		"mo": match_over,
		"sd": sudden_death,
		"rsp": [respawn_timers[0], respawn_timers[1]],
		"p1": _net_pack_player(players[0]),
		"p2": _net_pack_player(players[1]),
		"proj": proj,
		"arrows": ars,
		"picks": piks,
	})


@rpc("authority", "unreliable")
func net_snap(s: Dictionary) -> void:
	if not Net.is_client():
		return
	# el canal no fiable no ordena: un snapshot viejo llegando tarde (p.ej.
	# tras un ev_respawn fiable) "mataría" de nuevo al jugador local
	var ser := int(s.get("ser", -1))
	if ser <= net_last_ser:
		return
	net_last_ser = ser
	net_last_snap = s


# --- cliente: paso por tick de física ---------------------------------------

func _client_step(delta: float) -> void:
	# 1) mi input local (P2) → host, cada tick (no fiable: si llega tarde, se ignora)
	var h := {}
	for a in ["left", "right", "up", "down", "jump", "attack", "throw"]:
		h[a] = Input.is_action_pressed("p2_" + a)
	net_input.rpc_id(1, h)
	# 2) aplicar el snapshot más reciente y sus efectos derivados
	if not net_last_snap.is_empty():
		_client_apply_common()
		for p in players:
			p.frozen = match_over or round_lock > 0.0 or net_wait_peer
		_apply_puppet(delta)
		_reconcile_own()
		_client_watch_effects()
	_update_camera(delta)
	_update_respawn_bar()


func _client_apply_common() -> void:
	var s := net_last_snap
	var sc: Array = s.get("scores", [0, 0])
	if scores[0] != int(sc[0]) or scores[1] != int(sc[1]):
		scores = [int(sc[0]), int(sc[1])]
		_update_hud()
	var rw_pid := int(s.get("rw", 0))
	var rw: Player = null
	if rw_pid > 0:
		rw = players[rw_pid - 1]
	if rw != right_of_way:
		right_of_way = rw
		if rw != null:
			_show_step_arrow(rw)
	round_lock = float(s.get("rl", 0.0))
	match_over = bool(s.get("mo", false))
	sudden_death = bool(s.get("sd", false))
	var rsp: Array = s.get("rsp", [0.0, 0.0])
	respawn_timers = [float(rsp[0]), float(rsp[1])]
	if net_last_ser != net_applied_ser:
		net_applied_ser = net_last_ser
		_sync_net_entities(s)


## El rival (P1) es una marioneta: interpola posición y copia el resto.
func _apply_puppet(delta: float) -> void:
	var rp: Dictionary = net_last_snap.get("p1", {})
	if rp.is_empty():
		return
	var foe := players[0]
	var target := Vector2(float(rp.get("x", foe.position.x)), float(rp.get("y", foe.position.y)))
	if foe.position.distance_to(target) > 200.0:
		foe.position = target
	else:
		foe.position = foe.position.lerp(target, clampf(delta * 14.0, 0.0, 1.0))
	foe.velocity = Vector2(float(rp.get("vx", 0.0)), float(rp.get("vy", 0.0)))
	foe.state = int(rp.get("st", 0))
	foe.stance = int(rp.get("sc", 1))
	foe.stance_target = foe.stance
	foe.facing = int(rp.get("fc", 1))
	foe.scale.x = foe.facing
	foe.has_sword = bool(rp.get("hs", true))
	foe.weapon_id = String(rp.get("wid", "florete"))
	foe.run_phase = float(rp.get("rp", 0.0))
	foe.attack_time = float(rp.get("at", 0.0))
	foe.attack_height = int(rp.get("ah", 1))
	foe.attack_resolved = true   # el cliente nunca resuelve combate
	foe.invuln_time = float(rp.get("iv", 0.0))
	foe.knockdown_time = float(rp.get("kd", 0.0))
	foe.roll_time = float(rp.get("rt", 0.0))
	foe.sidekick_time = float(rp.get("sd", 0.0))
	foe.dive_time = float(rp.get("dv", 0.0))
	foe.bow_time = float(rp.get("bw", 0.0))
	foe.throw_pose_time = float(rp.get("tp", 0.0))
	foe.anim_time = float(rp.get("am", 0.0))


## Mi jugador (P2) corre en local (predicción); aquí solo se corrige suave.
func _reconcile_own() -> void:
	var lp: Dictionary = net_last_snap.get("p2", {})
	if lp.is_empty():
		return
	var me := players[1]
	var host_st := int(lp.get("st", me.state))
	if me.state != Player.State.DEAD:
		var target := Vector2(float(lp.get("x", me.position.x)), float(lp.get("y", me.position.y)))
		var d := me.position.distance_to(target)
		if d > 120.0:
			# divergencia grande (derriba, rebote): confiar ciegamente en el host
			me.position = target
			me.velocity = Vector2(float(lp.get("vx", 0.0)), float(lp.get("vy", 0.0)))
		elif d > 3.0:
			me.position = me.position.lerp(target, 0.12)
		if host_st == Player.State.DEAD and not net_dead[1]:
			# salvavidas: el ev_kill fiable debería haber llegado antes
			net_dead[1] = true
			me.die()
			respawn_timers[1] = RESPAWN_DELAY
			_burst(me.position, me.color, 34, 440.0)
			me.has_sword = false
	elif host_st != Player.State.DEAD and net_dead[1]:
		# auto-cura: creíamos muertos pero el host ya nos ha reviveído (el
		# ev_respawn fiable y el snapshot no fiable no comparten orden)
		net_dead[1] = false
		me.weapon_id = String(lp.get("wid", me.weapon_id))
		me.revive(Vector2(float(lp.get("x", 531.0)), float(lp.get("y", 531.0))), 1 if float(lp.get("vx", 0.0)) >= 0.0 else -1)
	# arma autoritativa (ciclo de reaparición y recogidas del host)
	me.has_sword = bool(lp.get("hs", me.has_sword))
	me.weapon_id = String(lp.get("wid", me.weapon_id))


func _client_watch_effects() -> void:
	if not net_had_sd and sudden_death:
		net_had_sd = true
		show_msg("¡MUERTE SÚBITA!", 1.4)
		sfx(camera.position, "alert", -4.0)
		shake_time = maxf(shake_time, 0.2)
	if net_last_rl > 0.0 and round_lock <= 0.0 and not match_over:
		_show_fight()
	net_last_rl = round_lock


## Reconstrucción de proyectiles/flechas/espadas caídas: son pocos nodos, así
## que se recrean enteros con cada snapshot nuevo y nunca divergen.
func _sync_net_entities(s: Dictionary) -> void:
	for a in arrows:
		a.queue_free()
	arrows.clear()
	for x in s.get("arrows", []):
		var a := Arrow.new()
		a.process_mode = Node.PROCESS_MODE_PAUSABLE
		a.position = Vector2(float(x["x"]), float(x["y"]))
		a.vel = Vector2(float(x["vx"]), 0.0)
		a.height = int(x["h"])
		a.bounces = int(x["b"])
		var at := int(x["t"])
		a.thrower = players[at - 1] if at > 0 else null
		add_child(a)
		arrows.append(a)
	for spd in projectiles:
		spd.queue_free()
	projectiles.clear()
	for x in s.get("proj", []):
		var pr := SwordProjectile.new()
		pr.process_mode = Node.PROCESS_MODE_PAUSABLE
		pr.position = Vector2(float(x["x"]), float(x["y"]))
		pr.vel = Vector2(float(x["vx"]), 0.0)
		pr.spin = float(x["sp"])
		pr.weapon_id = String(x["wid"])
		var pt := int(x["t"])
		pr.thrower = players[pt - 1] if pt > 0 else null
		add_child(pr)
		projectiles.append(pr)
	for pk in pickups:
		pk.queue_free()
	pickups.clear()
	for x in s.get("picks", []):
		var npk := SwordPickup.new()
		npk.process_mode = Node.PROCESS_MODE_PAUSABLE
		npk.weapon_id = String(x["wid"])
		npk.position = Vector2(float(x["x"]), float(x["y"]))
		add_child(npk)
		pickups.append(npk)


# --- eventos fiables host → cliente ------------------------------------------

@rpc("authority", "reliable")
func ev_round() -> void:
	# espejo local del _start_round del host
	for k in corpses:
		corpses[k].queue_free()
	corpses.clear()
	for b in blood:
		b.queue_free()
	blood.clear()
	for tile in crumble_tiles:
		tile.restore(self)
	right_of_way = null
	calm_time = 0.0
	sudden_death = false
	net_had_sd = false
	net_dead = [false, false]
	net_wait_peer = false
	weapon_idx = [0, 0]
	for p in players:
		p.weapon_id = "florete"
	var offs := [-220.0, 220.0]
	for i in mini(players.size(), 2):
		players[i].reset_to(Vector2(LEVEL_W * 0.5 + offs[i], GROUND_Y - 29.0), -1 if offs[i] > 0.0 else 1)
	round_lock = COUNTDOWN_STEP * 3.0
	net_last_rl = round_lock


@rpc("authority", "reliable")
func ev_kill(vp: int, kp: int, x: float, y: float, dir: float) -> void:
	if net_dead[vp - 1]:
		return
	net_dead[vp - 1] = true
	var def := players[vp - 1]
	var atk := players[kp - 1] if kp > 0 else null
	def.position = Vector2(x, y)
	def.die()
	respawn_timers[vp - 1] = RESPAWN_DELAY
	_burst(Vector2(x, y), def.color, 34, 440.0)
	_burst(Vector2(x, y), Color(0.95, 0.95, 1.0), 12, 260.0)
	_add_blood(Vector2(x, y), def.color)
	_spawn_corpse(def, atk)
	if corpses.has(vp):
		corpses[vp].vel = Vector2(dir * 300.0, -260.0)
		corpses[vp].spin = dir * randf_range(2.0, 5.0)
	sfx(Vector2(x, y), "kill", -6.0)
	crowd_kill_flash = 1.0
	shake_time = maxf(shake_time, 0.3)


@rpc("authority", "reliable")
func ev_hit(pid: int, kind: int, sx: float, sy: float, st: float) -> void:
	var p := players[pid - 1]
	if p.net_puppet:
		return   # al rival ya lo trae el snapshot
	match kind:
		0: p.take_clash(1 if sx >= 0.0 else -1)
		1: p.knockdown(1 if sx >= 0.0 else -1)
		2:
			p.state = Player.State.STUNNED
			p.stun_time = st
			p.velocity = Vector2(sx, sy)
			p.flash_time = 0.15
		3: p.apply_push(Vector2(sx, 0.0), st)
		4:
			p.state = Player.State.KNOCKDOWN
			p.knockdown_time = st
			p.velocity = Vector2(sx, sy)
			p.flash_time = 0.2
		5:
			p.state = Player.State.JUMP
			p.velocity = Vector2(sx, sy)


@rpc("authority", "reliable")
func ev_respawn(pid: int, x: float, y: float, face: int, wid: String) -> void:
	var p := players[pid - 1]
	if corpses.has(pid):
		corpses[pid].queue_free()
		corpses.erase(pid)
	net_dead[pid - 1] = false
	p.weapon_id = wid
	p.revive(Vector2(x, y), face)
	sfx(Vector2(x, y), "respawn", -12.0)


@rpc("authority", "reliable")
func ev_point(team_id: int, x: float, y: float) -> void:
	# el marcador llega por snapshot; aquí solo van el fx y el sonido
	sfx(Vector2(x, y), "point", -6.0)
	_burst(Vector2(x, y - 30.0), P1_COLOR if team_id == 0 else P2_COLOR, 42, 480.0)


@rpc("authority", "reliable")
func ev_match_over(pid: int) -> void:
	match_over = true
	_spawn_worm(players[pid - 1])


@rpc("authority", "reliable")
func ev_msg(text: String, dur: float) -> void:
	show_msg(text, dur)


@rpc("authority", "reliable")
func ev_sfx(x: float, y: float, id: String, db: float, pitch: float) -> void:
	Sfx.play(self, Vector2(x, y), id, db, pitch)


@rpc("authority", "reliable")
func ev_burst(x: float, y: float, col: Color, amount: int, speed: float) -> void:
	_burst(Vector2(x, y), col, amount, speed)
