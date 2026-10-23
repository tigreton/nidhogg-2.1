extends Node2D
## Juego estilo Nidhogg: duelo de esgrima a un golpe. Quien mata gana el "paso"
## y debe correr hasta su meta; el rival reaparece delante para frenarlo.
## Primero en llegar a MatchRules.win_score puntos (1/3/5, se elige en el
## título) gana el partido.
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
var arena: ArenaBuilder   # construcción de arenas (corte 2/7)
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
const VIEW_W := 1152.0
const VIEW_H := 648.0
const RESPAWN_DELAY := 2.4
const PARRY_IMPULSE := 160.0    # parada blanda: px/s de separación
const PARRY_PUSH_TIME := 0.15   # duración del empuje de parada
const CLASH_IMPULSE := 130.0    # rebote mínimo contra guardia
const CLASH_PUSH_TIME := 0.12
const PARRY_COOLDOWN := 0.3     # anti re-trigger del rebote sostenido
const PUSHBOX_W := 34.0        # pushbox: separación mínima entre cuerpos (eje x)
const PUSHBOX_STEP := 8.0      # corrección tope por frame y duelista: suave, sin tirones
const PUSHBOX_Y := 52.0        # solape vertical para contar como cuerpo a cuerpo
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
# sprites de HUD (tarea 55) — vía ArtPack: packs de arte conmutables (tecla A en el título)
var TEX_ARROW: Texture2D = ArtPack.tex("arrow_neutral")
var TEX_BLOOD: Array[Texture2D] = [
	ArtPack.tex("blood_0"),
	ArtPack.tex("blood_1"),
	ArtPack.tex("blood_2"),
]
# tiles de escenario (tarea 57)
var TEX_FLOOR: Texture2D = ArtPack.tex("tile_floor")
var TEX_WALL: Texture2D = ArtPack.tex("tile_wall")
var TEX_PIT_EDGE: Texture2D = ArtPack.tex("pit_edge")

var players: Array[Player] = []
var right_of_way: Player = null
var scores := [0, 0]
var weapon_idx := [0, 0]
var match_over := false
var round_lock := 0.0
var skip_countdown := false   # los tests headless lo ponen a true (tarea 66)
const COUNTDOWN_STEP := 0.45
# hitstop de contacto (solo offline, como el de la muerte): 40-60 ms congelan
# el golpe sin robar ritmo; más grado = más metal
const HITSTOP_CLASH := 0.055   # hoja contra hoja a fondo
const HITSTOP_DISARM := 0.05   # el arma sale despedida
const HITSTOP_PARRY := 0.045   # parada blanda
const HITSTOP_KNOCK := 0.04    # derribo (carne, no metal)
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
	arena = ArenaBuilder.new(self)
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
	# mandos: P1 = gamepad 0, P2 = gamepad 1. Stick izquierdo y cruceta son
	# equivalentes; A salta, X ataca, B lanza. La gestión del juego (revancha,
	# pausa, arena, música) vive SOLO en el mando de P1: el rival no administra
	for dev in 2:
		var p := "p%d_" % (dev + 1)
		_pad_motion(p + "left", dev, JOY_AXIS_LEFT_X, -1.0)
		_pad_motion(p + "right", dev, JOY_AXIS_LEFT_X, 1.0)
		_pad_motion(p + "up", dev, JOY_AXIS_LEFT_Y, -1.0)
		_pad_motion(p + "down", dev, JOY_AXIS_LEFT_Y, 1.0)
		_pad_button(p + "left", dev, JOY_BUTTON_DPAD_LEFT)
		_pad_button(p + "right", dev, JOY_BUTTON_DPAD_RIGHT)
		_pad_button(p + "up", dev, JOY_BUTTON_DPAD_UP)
		_pad_button(p + "down", dev, JOY_BUTTON_DPAD_DOWN)
		_pad_button(p + "jump", dev, JOY_BUTTON_A)
		_pad_button(p + "attack", dev, JOY_BUTTON_X)
		_pad_button(p + "throw", dev, JOY_BUTTON_B)
	_pad_button("restart", 0, JOY_BUTTON_START)
	_pad_button("pause", 0, JOY_BUTTON_BACK)
	_pad_button("toggle_arena", 0, JOY_BUTTON_LEFT_SHOULDER)
	_pad_button("toggle_music", 0, JOY_BUTTON_RIGHT_SHOULDER)
	if Net.is_client():
		# cliente online: aquí el humano es P2 y suele tener un solo mando,
		# que Godot numera como device 0 — se le añaden las acciones de P2
		# (las de P1 no las lee nadie: P1 es marioneta del snapshot del host)
		for n in ["left", "right", "up", "down", "jump", "attack", "throw"]:
			for ev in InputMap.action_get_events("p1_" + n):
				if ev is InputEventJoypadMotion or ev is InputEventJoypadButton:
					InputMap.action_add_event("p2_" + n, ev.duplicate())


func _pad_motion(action: String, dev: int, axis: int, val: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventJoypadMotion.new()
	ev.device = dev
	ev.axis = axis
	ev.axis_value = val
	InputMap.action_add_event(action, ev)


func _pad_button(action: String, dev: int, btn: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var eb := InputEventJoypadButton.new()
	eb.device = dev
	eb.button_index = btn
	InputMap.action_add_event(action, eb)


## Mando que vibra con este jugador (-1 = ninguno): bots, marionetas y el rival
## por red no tienen mando en esta máquina. En el cliente online el humano es
## P2 y su mando es el device 0 (igual que el remapeo de _setup_input).
func pad_of(p: Player) -> int:
	if p.is_bot or p.net_remote or p.net_puppet:
		return -1
	var dev := 0 if Net.is_client() else p.player_id - 1
	return dev if Input.get_connected_joypads().has(dev) else -1


func _on_died_pad(p: Player) -> void:
	# la muerte sacude el mando del jugador humano local
	var dev := pad_of(p)
	if dev >= 0:
		Input.start_joy_vibration(dev, 0.45, 0.8, 0.4)


# --- arenas: la construcción vive en scripts/arena_builder.gd (corte 2/7) --
# la GEOMETRÍA, la paleta y _tops siguen SIENDO de game (tests, bots y HUD
# leen game.PIT_X0 / game.PLAT_X0 / ...): el builder los toca vía `host`.
# Delegados finos para no cambiar ni una llamada externa.

func _build_level() -> void:
	arena._build_level()


func _load_arena(id: int) -> void:
	arena._load_arena(id)


func _add_level(node: Node) -> void:
	arena._add_level(node)


func _register_top(x0: float, x1: float, y: float) -> void:
	_tops.append({"x0": x0, "x1": x1, "y": y})


func set_arena(id: int) -> void:
	if id % ARENA_NAMES.size() == arena_id:
		return
	if random_arena and id % ARENA_NAMES.size() == 3:
		# la torre de dos pisos no admite barajado (el piso fija el centro)
		random_arena = false
	_load_arena(id)
	arena._rebuild_level()
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


func _reshuffle_level() -> void:
	# reconstruye el nivel con el layout barajado (o el por defecto) sin
	# tocar marcador ni estadísticas
	if random_arena:
		arena._random_layout()
	else:
		_load_arena(arena_id)
	arena._rebuild_level()


func _top_below(x: float, from_y: float) -> float:
	var best := -1.0
	for t in _tops:
		if x > t["x0"] and x < t["x1"] and t["y"] >= from_y - 4.0:
			if best < 0.0 or t["y"] < best:
				best = t["y"]
	return best


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
		p.died.connect(_on_died_pad)
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
			p.died.connect(_on_died_pad)
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
	# solo el AVANCE hacia la meta conquista: retroceder no infla los pips
	var prog := (sec - 3) if right_of_way.goal_dir > 0 else (3 - sec)
	if prog > sect_conquered[_team(right_of_way)]:
		sect_conquered[_team(right_of_way)] = prog
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
	if on and sections_mode:
		set_sections(false)
	arcade = on
	arcade_over = false
	if on:
		arcade_level = 1
		bot_level = _arcade_difficulty()
		players[1].is_bot = true
		if arena_id != 0:
			set_arena(0)
		else:
			# ya en la arena 1: set_arena saltaría por el guard de "misma
			# arena" y el marcador/match_over quedarían sin resetear
			scores = [0, 0]
			stats = _fresh_stats()
			match_over = false
			stats_label.visible = false
			_update_hud()
			_start_round()
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
	if on and sections_mode:
		set_sections(false)
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
	hint.text = "P1: A/D mover · W saltar/arriba · S agachar · F atacar · G lanzar    P2: ←/→ · ↑ · ↓ · K atacar · L lanzar    R: revancha\nB: bot P2 · H: aliado P3 · N: bot vs bot · V: 2v2 · T: lluvia de rocas · C: cambiar arena · X: arena barajada · M: música\nMando P1 (0) / P2 (1): stick o cruceta · A saltar · X atacar · B lanzar    solo P1: START revancha · SELECT pausa · L1 arena · R1 música"
	hint.position = Vector2(22, VIEW_H - 80)
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
	step_arrow.texture = ArtPack.tex("arrow_neutral")
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
	weapon_idx.resize(players.size())
	weapon_idx.fill(0)
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
		if Input.is_action_just_pressed("toggle_sections") and not arcade and not cup:
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
	_bot_observe_all()
	for p in players:
		if p.is_bot:
			_bot_think(p, delta)
			_bot_pit_jump(p)
	for i in players.size():
		var step := absf(players[i].position.x - last_x[i])
		if players[i].state != Player.State.DEAD and step < 60.0:
			stats[i]["dist"] += step
		last_x[i] = players[i].position.x
	_resolve_pushbox()
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


func _resolve_pushbox() -> void:
	# cuerpo contra cuerpo (pushbox suave): los duelistas no se atraviesan.
	# Cada par solapado se separa medio solape por cabeza, con tope por frame
	# para que empujar se sienta como una pulsación constante, no un teletransporte.
	# Quien embiste (rodada/dive/patadas) cede él: no arrea al rival por delante.
	# Los muertos no ocupan sitio; la marioneta de red no se toca (la coloca el
	# snapshot del host), aunque sí ocupa sitio para el jugador local.
	for i in players.size():
		var p := players[i]
		if p.state == Player.State.DEAD:
			continue
		for j in range(i + 1, players.size()):
			var q := players[j]
			if q.state == Player.State.DEAD or _team(p) == _team(q):
				continue
			if absf(p.position.y - q.position.y) > PUSHBOX_Y:
				continue
			var dx := q.position.x - p.position.x
			var overlap := PUSHBOX_W - absf(dx)
			if overlap <= 0.0:
				continue
			var sgn := 1.0 if dx >= 0.0 else -1.0
			if absf(dx) < 0.5:
				sgn = 1.0 if p.player_id < q.player_id else -1.0
			var step := minf(overlap * 0.5, PUSHBOX_STEP)
			var dash := [Player.State.ROLL, Player.State.DIVE, Player.State.DIVEKICK, Player.State.SIDEKICK]
			var p_yields: bool = p.net_puppet or (p.state in dash and not q.state in dash)
			var q_yields: bool = q.net_puppet or (q.state in dash and not p.state in dash)
			if p_yields and q_yields:
				# caso degenerado (ambas marionetas): nadie corrige
				continue
			elif p_yields:
				p.position.x -= sgn * step * 2.0
			elif q_yields:
				q.position.x += sgn * step * 2.0
			else:
				p.position.x -= sgn * step
				q.position.x += sgn * step


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
		_hitstop(HITSTOP_DISARM)
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
			_hitstop(HITSTOP_DISARM)
		else:
			# patada baja (agachado) o rival ya desarmado: derriba
			def.knockdown(push)
			_net_ev_hit(def, 1, float(push) * 260.0)
			_burst(def.position, Color(1, 1, 1), 8, 200.0)
			sfx(def.position, "hit", -10.0)
			_hitstop(HITSTOP_KNOCK)


func _clash(a: Player, b: Player) -> void:
	var mid := Vector2((a.position.x + b.position.x) * 0.5, minf(a.position.y, b.position.y) - 14.0)
	_burst(mid, Color(1.0, 0.93, 0.55), 14, 320.0)
	sfx(mid, "clash", -8.0)
	_hitstop(HITSTOP_CLASH)
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
	_hitstop(HITSTOP_PARRY)
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
			_hitstop(HITSTOP_KNOCK)


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
				_hitstop(HITSTOP_KNOCK)
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
			_hitstop(HITSTOP_KNOCK)
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
			_hitstop(HITSTOP_KNOCK)
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
				_hitstop(HITSTOP_PARRY)
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
	var was_sudden := sudden_death
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
	# la cámara lenta ya no acompaña cada muerte: solo cuando esa baja decide
	# (muerte súbita). El hitstop del contacto la sustituye en el día a día.
	if was_sudden:
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
	# por defecto el arma es siempre la misma: los timing aprendidos valen
	# de por vida. El ciclo (espadón/daga/arco) queda como modo alternativo.
	if not MatchRules.weapon_variety:
		return "florete"
	var i := p.player_id - 1
	if i < 0 or i >= weapon_idx.size():
		return "florete"
	weapon_idx[i] = (weapon_idx[i] + 1) % GameConfig.WEAPON_ORDER.size()
	return GameConfig.WEAPON_ORDER[weapon_idx[i]]


func _respawn_pos(p: Player) -> Vector2:
	if right_of_way == null:
		var offs := [220.0, -220.0, 620.0, -620.0]
		var fx := clampf(_spawn_safe(LEVEL_W * 0.5 + offs[p.player_id - 1]), GOAL_W + 60.0, LEVEL_W - GOAL_W - 60.0)
		return Vector2(fx, 200.0)
	if sections_mode:
		var w := LEVEL_W / float(SECTION_COUNT)
		var sdir := 1 if right_of_way.goal_dir > 0 else -1
		var sec := clampi(section_index + sdir, 0, SECTION_COUNT - 1)
		var cx := w * (float(sec) + 0.5)
		if sec == section_index:
			# ya no hay sección delante: reaparece al fondo de la actual
			cx = w * float(sec + 1) - 100.0 if sdir > 0 else w * float(sec) + 100.0
		return Vector2(_spawn_safe(cx), 200.0)
	var dir := float(right_of_way.goal_dir)
	var x := right_of_way.position.x + dir * 540.0
	x = clampf(x, GOAL_W + 60.0, LEVEL_W - GOAL_W - 60.0)
	x = _spawn_safe(x)
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


func _spawn_safe(x: float) -> float:
	# x de nacimiento/reaparición a suelo firme: fuera de los fosos (como
	# _out_of_pit) y de la cinta transportadora — la cinta empuja al que
	# reaparece encima, así que P2 nacía en 2620 (dentro de la franja
	# 2500-2650) y se deslizaba solo desde el principio de la ronda.
	# Dos pasadas: el empujón de una franja puede caer dentro de la otra.
	for i in 2:
		x = _out_of_pit(x)
		if x > BELT_X0 - 24.0 and x < BELT_X1 + 24.0:
			x = BELT_X0 - 30.0 if x < (BELT_X0 + BELT_X1) * 0.5 else BELT_X1 + 30.0
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
	# cámara lenta reservada: gol decisivo o el que instala el match point;
	# el resto de puntos entran limpios para no desensibilizar
	if scores[_team(p)] >= MatchRules.win_score - 1:
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
		round_lock = 1.0   # antes 1.4: el mensaje ¡PUNTO! dura 1.0 y sobra
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
	var c: Dictionary = BOT_CFG[lvl - 1].duplicate()
	c["lvl"] = lvl
	return c


# =============================================================================
# IA: percibir → puntuar → elegir
# =============================================================================
# El tick de reacción por nivel (bot_think/BOT_CFG) no cambia. Lo que era una
# cadena de if/elif se descompone en tres dimensiones puntuadas con términos
# aditivos (movimiento, estancia, tap) más capas duras que no se negocian
# (salto de muro, divekick, arco, levantarse). Los sorteos randf()/randi()
# viven en _bot_scores, dentro de cada rama en el mismo orden que la cadena
# original: la equivalencia del esqueleto se probó con la semilla fija del
# sim (trayectoria idéntica tic a tic, 83,2 s); los términos nuevos
# (predicción, castigo, memoria de patrones) son la única divergencia, y es
# buscada.

func _bot_think(p: Player, delta: float) -> void:
	var foe := _nearest_foe(p)
	p.bot_think -= delta
	if p.bot_think > 0.0:
		return
	var cfg := _bot_cfg(p)
	p.bot_think = float(cfg["react"])
	if foe == null:
		p.bot_held = {}
		return
	var ctx := _bot_perceive(p, foe)
	if _bot_tower_floor(p, foe, ctx):
		return
	var s := _bot_scores(p, foe, cfg, ctx)
	_bot_commit(p, foe, ctx, s)


## Torre del Centinela (tarea 89): si el rival juega en el otro piso, cambiar
## de piso — subir por la escalera flotante más cercana (izq: se embarca
## desde x<450 yendo a la derecha; dcha: desde x>4340 yendo a la izquierda)
## o bajar andando hasta el hueco más cercano y caer por él. Nunca el
## corredor: su ruta válida es el pasillo inferior. Capa dura con return: en
## las arenas 0–2 no roba ni una decisión (y no adelanta ningún randf, así el
## sim de la arena 0 mantiene su trayectoria tic a tic).
func _bot_tower_floor(p: Player, foe: Player, ctx: Dictionary) -> bool:
	if arena_id != 3 or String(ctx["role"]) == "run":
		return false
	var foe_up := foe.position.y < 450.0
	var me_up := p.position.y < 330.0
	if foe_up == me_up or p.state not in [Player.State.IDLE, Player.State.RUN, Player.State.JUMP]:
		return false
	var want := {}
	var tap := ""
	if foe_up:
		var use_left := absf(p.position.x - 500.0) < absf(p.position.x - 4290.0)
		if use_left:
			if p.position.y > 450.0 and p.position.x > 450.0:
				want["left"] = true
			else:
				want["right"] = true
				if p.is_on_floor():
					tap = "jump"
		else:
			if p.position.y > 450.0 and p.position.x < 4340.0:
				want["right"] = true
			else:
				want["left"] = true
				if p.is_on_floor():
					tap = "jump"
	else:
		# bajar: andar hasta el centro del hueco más cercano y seguir: la
		# gravedad hace el resto (no saltar dentro del hueco)
		var hx := 1255.0 if absf(p.position.x - 1255.0) < absf(p.position.x - 3325.0) else 3325.0
		want["right"] = hx > p.position.x
		want["left"] = hx <= p.position.x
	p.bot_held = want
	if tap != "":
		p.bot_held[tap] = true
	return true


## Memoria de patrones (IA): lo que el rival HACE, no lo que es. Se observa a
## TODOS los jugadores cada frame — humanos incluidos: aquí es donde el bot
## "aprende" tus costumbres. Contextos observados: altura de ataque tras
## aterrizar, tras rodar, altura favorita global y ritmo (cada cuánto ataca).
## Vive mientras viva la partida: de una revancha a otra, ya te conoce.
var _bot_mem := {}   # player_id → {"air","was_atk","was_roll","land_ms","roll_end_ms",
                     #   "last_atk_ms","after_land":{},"after_roll":{},"heights":{},"gaps":[]}


func _bot_observe_all() -> void:
	var now := Time.get_ticks_msec()
	for q in players:
		var m: Dictionary = _bot_mem.get_or_add(q.player_id,
				{"air": false, "was_atk": false, "was_roll": false, "land_ms": 0,
				"roll_end_ms": 0, "last_atk_ms": 0,
				"after_land": {}, "after_roll": {}, "heights": {}, "gaps": []})
		var air := not q.is_on_floor()
		if m["air"] and not air:
			m["land_ms"] = now
		m["air"] = air
		var roll: bool = q.state == Player.State.ROLL
		if m["was_roll"] and not roll:
			m["roll_end_ms"] = now
		m["was_roll"] = roll
		var atk: bool = q.state == Player.State.ATTACK
		if atk and not m["was_atk"]:
			# ataque nuevo: contarlo en sus contextos y medir el ritmo
			if now - int(m["land_ms"]) < 700:
				m["after_land"][q.attack_height] = int(m["after_land"].get(q.attack_height, 0)) + 1
			if now - int(m["roll_end_ms"]) < 700:
				m["after_roll"][q.attack_height] = int(m["after_roll"].get(q.attack_height, 0)) + 1
			m["heights"][q.attack_height] = int(m["heights"].get(q.attack_height, 0)) + 1
			if int(m["last_atk_ms"]) > 0:
				var gaps: Array = m["gaps"]
				gaps.append(float(now - int(m["last_atk_ms"])))
				if gaps.size() > 8:
					gaps.pop_front()
			m["last_atk_ms"] = now
		m["was_atk"] = atk


## Enfriamiento del lanzamiento (IA): sin esto, el DIFÍCIL detecta una ventana
## de compromiso cada tick (0,07 s) y desangra el campo de espadas — el sim
## degradaba a puñetazos y derribos sin muertes (y sin muertes no reaparecen
## armas). Un lanzamiento cada 3,5 s como mucho: sigue siendo un tiro
## inteligente, deja de ser una metralleta.
var _bot_last_throw := {}   # player_id → msec del último lanzamiento real

## Enfriamiento de la finta (IA): la probabilidad es por TICK de decisión y
## el DIFÍCIL decide cada 0,07 s — sin puerta temporal, finta el 99% de las
## aproximaciones y dos DIFÍCIL se finton mutuamente para siempre (el sim se
## rompía a saltos por encima + divekick + derribo). Ocasionales o nada.
var _bot_feint_until := {}   # player_id → msec hasta el que no se re-finta


## Altura preferida de este rival en un contexto dado ("after_land",
## "after_roll", "heights"), si el patrón es claro (muestras mínimas y mayoría
## estricta). Sin patrón → -1: nada que anticipar.
func _bot_pattern_height(foe: Player, key: String, min_samples := 3) -> int:
	var c: Dictionary = _bot_mem.get(foe.player_id, {}).get(key, {})
	var best := -1
	var best_n := 0
	var total := 0
	for h in [Player.H.LOW, Player.H.MID, Player.H.HIGH]:
		var n := int(c.get(h, 0))
		total += n
		if n > best_n:
			best_n = n
			best = h
	if total < min_samples or best_n * 2 <= total:
		return -1
	return best


## ¿Toca ya el siguiente ataque de este rival? Con ≥3 intervalos medidos hay
## ritmo medio; si desde el último ataque ha pasado más de ese medio más un
## 20% de margen, el swing está al caer — hora de cubrir su altura favorita.
func _bot_attack_due(foe: Player) -> bool:
	var m: Dictionary = _bot_mem.get(foe.player_id, {})
	var gaps: Array = m.get("gaps", [])
	if gaps.size() < 3 or int(m.get("last_atk_ms", 0)) <= 0:
		return false
	var avg := 0.0
	for g in gaps:
		avg += float(g)
	avg /= float(gaps.size())
	if avg < 400.0 or avg > 3000.0:
		return false   # sin ritmo exploitable: spam (<0,4 s) o pasividad (>3 s)
	return Time.get_ticks_msec() - int(m["last_atk_ms"]) > avg * 1.2 + 120.0


## Percepción: todo lo observable que alimenta la puntuación. Aquí no se
## sortea nada (ver cabecera de sección).
func _bot_perceive(p: Player, foe: Player) -> Dictionary:
	var row_team := -1 if right_of_way == null else _team(right_of_way)
	var role := "duel"
	if right_of_way != null and row_team == _team(p):
		role = "run"
	elif row_team >= 0:
		role = "intercept"
	var target_x := foe.position.x
	if role == "run":
		target_x = p.position.x + float(p.goal_dir) * 4000.0
	elif role == "intercept":
		# predicción (IA): interceptar donde el portador VA a estar, no donde
		# está. A carrera completa (330 px/s) la lead es ~165 px — comparable a
		# los 200 fijos de antes pero adaptativa: si frena o retrocede, el bot
		# no se pasa de largo. Parado o dudando, suelo de 100 px hacia SU meta
		# (la ventaja es suya: acabará corriendo hacia allí).
		var lead := right_of_way.velocity.x * 0.5
		if absf(right_of_way.velocity.x) < 80.0:
			lead = float(right_of_way.goal_dir) * 100.0
		target_x = right_of_way.position.x + lead
	return {
		"adx": absf(foe.position.x - p.position.x),
		"sd": 1.0 if foe.position.x >= p.position.x else -1.0,
		"on_floor": p.is_on_floor(),
		"role": role,
		"target_x": target_x,
		# línea temporal del ataque rival (IA): windup legible → parry anticipado
		# o castigo; hoja gastada en recuperación → golpe gratis
		"foe_windup": foe.attack_windup(),
		"foe_windup_left": foe.attack_from() - foe.attack_time,
		"foe_recovery": foe.state == Player.State.ATTACK and foe.attack_time > foe.attack_to(),
		# terreno (IA): el hielo invalida el juego de pies — frenar cuesta ~4x
		"on_ice": in_ice(p.position.x),
		# ¿viene el rival hacia nosotros? (señal para el cebo de la finta)
		"foe_closing": foe.velocity.x * (p.position.x - foe.position.x) > 60.0,
	}


## Puntuación aditiva. Los términos base reproducen las bandas exactas de la
## cadena original; los conocimientos nuevos (predicción del rival, memoria
## de patrones) entran aquí como términos sin reordenar lo existente.
func _bot_scores(p: Player, foe: Player, cfg: Dictionary, ctx: Dictionary) -> Dictionary:
	var s := {"toward": 0.0, "away": 0.0, "hold": 0.0, "high": 0.0, "low": 0.0,
			"jump": -1.0, "attack": -1.0, "throw": -1.0}
	var adx: float = ctx["adx"]
	match String(ctx["role"]):
		"run":
			# corredor (o aliado escoltando): correr hacia la meta y cruzar el
			# foso central por la plataforma
			s["toward"] = 1.0
			if ctx["on_floor"] and _bot_near_plat_edge(p):
				s["jump"] = 0.0
		"intercept":
			# interceptor: adelantarse en la dirección hacia la que corre el
			# portador (histéresis de 20 px como la cadena original)
			if absf(float(ctx["target_x"]) - p.position.x) > 20.0:
				s["toward"] = 1.0
			else:
				s["hold"] = 1.0
			if ctx["on_floor"] and _bot_near_plat_edge(p):
				s["jump"] = 0.0
		_:
			# duelo: gestión de distancia y estancias. En hielo el frenado se
			# alarga ~4x (tarea 69): la banda de "demasiado cerca" se ensancha y
			# no se salta hacia dentro — el aterrizaje patinaría bajo su hoja.
			var near: float = 85.0 if ctx["on_ice"] else 55.0
			if adx > 260.0:
				s["toward"] = 1.0
				if ctx["on_floor"] and randf() < (0.0 if ctx["on_ice"] else 0.05):
					s["jump"] = 0.0
			elif adx < near:
				s["away"] = 1.0
			elif foe.has_sword and foe.state == Player.State.IDLE and adx < 150.0:
				# no caminar contra la guardia: atacar o retroceder
				if randf() < float(cfg["atk"]) * 2.0:
					s["attack"] = 0.0
				else:
					s["away"] = 1.0
			elif foe.state == Player.State.ATTACK and (foe.attack_is_active() or foe.attack_windup()):
				# cubrirse o castigar. Igualar la altura = parada (parry blando);
				# el windup está telegrafiado, así que la cobertura empieza YA,
				# no cuando la hoja ya vuela. El castigo (golpear a OTRA altura
				# durante el windup) solo es de DIFÍCIL y solo si nuestra hoja
				# saldría antes que la suya — un castigo desacertado degenera en
				# parry (misma altura), nunca en comerse la hoja.
				if int(cfg["lvl"]) >= 3 and ctx["foe_windup"] \
						and float(ctx["foe_windup_left"]) > p.attack_from() + 0.02 \
						and adx < p.weapon_reach() + 40.0 \
						and _bot_kill_height_now(p, foe):
					s["attack"] = maxf(float(s["attack"]), 1.5)
					_bot_punish_stance(s, foe.stance)
				else:
					match foe.attack_height:
						Player.H.HIGH:
							s["high"] = 1.0
						Player.H.LOW:
							s["low"] = 1.0
			else:
				# con probabilidad "err" el bot se equivoca de estancia
				if randf() < float(cfg["err"]):
					var r := randi() % 3
					if r == 0:
						s["high"] = 1.0
					elif r == 1:
						s["low"] = 1.0
				elif foe.stance == Player.H.MID:
					s["low"] = 1.0
				if randf() < float(cfg["atk"]):
					s["attack"] = 0.0
				# economía del lanzamiento (IA): la hoja vuela a ~760 px/s y la
				# desvía cualquier guardia quieta a altura alcanzable — tirarla
				# a un rival parado es regalar el arma. Un rival COMPROMETIDO
				# (windup, recuperación, rodada sin gracia, aturdido, patada
				# voladora) no puede desviar: muere si su altura es alcanzable
				# y si no, cae derribado. El arco no se lanza nunca: no mata a
				# ninguna altura, como proyectil es un palo que derriba.
				var thr := 0.03
				if p.weapon_id != "arco" \
						and Time.get_ticks_msec() - int(_bot_last_throw.get(p.player_id, 0)) >= 3500:
					var k: Array = GameConfig.WEAPONS[p.weapon_id]["thrown_kills"]
					var vs: String = ["LOW", "MID", "HIGH"][foe.stance]
					var guard: bool = foe.state in [Player.State.IDLE, Player.State.RUN, Player.State.JUMP]
					var committed: bool = foe.state in [Player.State.STUNNED, Player.State.DIVEKICK] \
							or (foe.state == Player.State.ROLL and foe.invuln_time <= 0.0) \
							or (foe.state == Player.State.ATTACK and not foe.attack_is_active())
					if committed and adx > 80.0 and adx < 560.0:
						thr = 0.35 if vs in k else 0.12
					elif guard and vs in k and adx < 620.0:
						thr = 0.0
					elif adx < 160.0:
						thr = 0.008
				if p.has_sword and randf() < thr:
					s["throw"] = 0.0
	# castigo de la recuperación (IA): la hoja gastada deja al rival indefenso
	# el resto de la animación. Se planta la estancia de castigo SIEMPRE; el
	# golpe solo si ya estamos a altura de kill (si no, sale en el próximo
	# tick, cuando la hoja haya viajado).
	if ctx["foe_recovery"] and int(cfg["lvl"]) >= 2 and adx < p.weapon_reach() + 40.0:
		_bot_punish_stance(s, foe.stance)
		if _bot_kill_height_now(p, foe):
			s["attack"] = maxf(float(s["attack"]), 1.5)
	elif foe.state == Player.State.STUNNED and int(cfg["lvl"]) >= 2 and p.has_sword \
			and adx < p.weapon_reach() + 20.0:
		# aturdido: kill a cualquier altura, no hay guardia que valga
		s["attack"] = maxf(float(s["attack"]), 1.5)
	# memoria de patrones (IA): si este rival suele atacar a una altura al
	# aterrizar y ahora mismo cae hacia nosotros, la guardia se planta en esa
	# altura mientras su hoja aún ni existe — parar sin reaccionar. La MEDIA
	# no se puede cubrir con una tecla (limitación de siempre), solo se
	# anticipan HIGH y LOW.
	if String(ctx["role"]) == "duel" and int(cfg["lvl"]) >= 2 \
			and not foe.is_on_floor() and foe.velocity.y > 0.0 and adx < 240.0:
		var h := _bot_pattern_height(foe, "after_land", 3)
		if h == Player.H.HIGH:
			s["high"] = maxf(float(s["high"]), 1.2)
		elif h == Player.H.LOW:
			s["low"] = maxf(float(s["low"]), 1.2)
	# finta y cebo (IA): contra el rival PLANTADO en guardia a distancia de
	# estocada, un paso atrás le invita a lanzar — la hoja pasa corta y el
	# castigo de recuperación hace el resto. SOLO contra humanos: dos bots
	# finton mutuamente y el partido degrada a bucle de derribos sin muertes
	# (el sim DIFÍCIL lo cazó dos veces, con la finta por aproximación y con
	# la de cebo a tortuga). Contra el arco no se aleja uno (se sale de la
	# flecha al revés: acercarse), y en hielo el pie no obedece para un paso
	# quirúrgico.
	if String(ctx["role"]) == "duel" and int(cfg["lvl"]) >= 2 and ctx["on_floor"] \
			and not ctx["on_ice"] and foe.has_sword and foe.weapon_id != "arco" \
			and not foe.is_bot \
			and foe.state == Player.State.IDLE and not ctx["foe_closing"] \
			and adx > p.weapon_reach() + 20.0 and adx < p.weapon_reach() + 150.0 \
			and Time.get_ticks_msec() >= int(_bot_feint_until.get(p.player_id, 0)) \
			and randf() < (0.35 if int(cfg["lvl"]) >= 3 else 0.18):
		s["away"] = maxf(float(s["away"]), 1.3)
		s["attack"] = -1.0   # el cebo es limpio: nada de hojas al aire
		_bot_feint_until[p.player_id] = Time.get_ticks_msec() + 2500
	# ritmo (IA): cuando el swing del rival está al caer según SU propio ritmo
	# medio, la guardia se planta en su altura favorita antes de que exista un
	# windup que leer.
	if String(ctx["role"]) == "duel" and int(cfg["lvl"]) >= 2 and _bot_attack_due(foe) \
			and adx > 55.0 and adx < 300.0:
		var rh := _bot_pattern_height(foe, "heights", 4)
		if rh == Player.H.HIGH:
			s["high"] = maxf(float(s["high"]), 1.1)
		elif rh == Player.H.LOW:
			s["low"] = maxf(float(s["low"]), 1.1)
	# tras rodar (IA): el que rueda suele salir atacando (y sale en LOW, la
	# estancia de la rodada) — guardia plantada antes del desenlace.
	if int(cfg["lvl"]) >= 2 and foe.state == Player.State.ROLL and adx < 220.0:
		var ph := _bot_pattern_height(foe, "after_roll", 3)
		if ph == Player.H.HIGH:
			s["high"] = maxf(float(s["high"]), 1.2)
		elif ph == Player.H.LOW:
			s["low"] = maxf(float(s["low"]), 1.2)
	return s


## ¿La estancia ACTUAL golpearía a este rival? La guardia quieta para la
## altura IGUAL a la estancia del defensor (parry blando) y un HIGH contra un
## rival agachado vuela por encima (miss).
func _bot_kill_height_now(p: Player, foe: Player) -> bool:
	return p.stance != foe.stance \
			and not (p.stance == Player.H.HIGH and foe.stance == Player.H.LOW)


## Estancia del castigo: golpear donde el rival NO tiene la hoja. Su guardia
## para su propia altura; LOW nuestra golpea a cualquiera de pie, así que su
## MID y su HIGH se castigan con nuestra LOW. Contra su LOW nos plantamos en
## MID (sin tecla) — HIGH volaría por encima y su misma LOW se pararía sola.
func _bot_punish_stance(s: Dictionary, foe_stance: int) -> void:
	s["high"] = 0.0
	s["low"] = 0.0
	if foe_stance != Player.H.LOW:
		s["low"] = 2.0


## Franja de borde de la plataforma del foso central (para saltarla al correr).
func _bot_near_plat_edge(p: Player) -> bool:
	return p.position.x > PLAT_X0 - 130.0 and p.position.x < PLAT_X1 + 130.0 \
			and not (p.position.x > PLAT_X0 + 40.0 and p.position.x < PLAT_X1 - 40.0)


## Elección: argmax por dimensión + capas duras en el orden de la cadena
## original (tap puntuado → salto de muro → divekick → arco → levantarse).
## Las capas duras son correcciones ganadas a pulso (sim clavado a 0 puntos,
## foso de ~4 frames) y no deben poder perder contra un argmax.
func _bot_commit(p: Player, foe: Player, ctx: Dictionary, s: Dictionary) -> void:
	var want := {}
	# movimiento sobre el eje bot → objetivo (rival, portador de la ventaja o meta)
	var dir := signf(float(ctx["target_x"]) - p.position.x)
	var mv := "hold"
	if float(s["toward"]) >= float(s["away"]) and float(s["toward"]) > float(s["hold"]):
		mv = "toward"
	elif float(s["away"]) > float(s["hold"]):
		mv = "away"
	if mv == "toward" and dir != 0.0:
		want["right" if dir > 0.0 else "left"] = true
	elif mv == "away" and dir != 0.0:
		want["left" if dir > 0.0 else "right"] = true
	# estancia: sin tecla = media (como siempre)
	if float(s["high"]) > float(s["low"]) and float(s["high"]) > 0.0:
		want["up"] = true
	elif float(s["low"]) > 0.0:
		want["down"] = true
	# tap: uno solo — empate = prioridad de la cadena original (throw > attack > jump)
	var tap := ""
	for k in ["throw", "attack", "jump"]:
		if float(s[k]) >= 0.0 and (tap == "" or float(s[k]) > float(s[tap])):
			tap = k
	# (el foso pequeño se salta por frame en _bot_pit_jump: la ventana segura
	# son ~4 frames y un tick de reacción del bot FÁCIL —0,26 s— la saltaría)
	# saltar cualquier muro bajo (peldaños de roca, etc.) al chocar de frente
	if tap == "" and ctx["on_floor"] and p.is_on_wall() and (want.get("right", false) or want.get("left", false)):
		tap = "jump"
	# patada voladora si el rival está abajo y cerca — pero no contra un
	# derribado: re-derribarlo refresca su caída y el bucle no termina nunca; ni
	# rodando ni recién levantado (gracia de 0,3 s): el bot saltaba el peñasco
	# en bucle divekickeando a un rival perpetuamente en el suelo y el partido
	# quedaba clavado (el sim moría a 0 puntos exactamente así)
	if not ctx["on_floor"] and foe != null and float(ctx["adx"]) < 100.0 \
			and foe.position.y > p.position.y + 40.0 \
			and foe.state != Player.State.KNOCKDOWN and foe.state != Player.State.ROLL \
			and foe.invuln_time <= 0.0:
		tap = "attack"
	# con el arco: tensar mientras el rival está a distancia de flecha
	# (soltará al acercarse o alejarse → dispara con el tensado completo)
	if p.weapon_id == "arco" and p.has_sword and foe != null and ctx["on_floor"] \
			and float(ctx["adx"]) > 100.0 and float(ctx["adx"]) < 620.0:
		want["attack"] = true
		tap = ""
	# derribado: levantarse (arriba; con un poco de aleatorio, lateral)
	if p.state == Player.State.KNOCKDOWN and p.knockdown_time <= 0.0:
		want["up"] = true
		if randf() < 0.3:
			want["up"] = false
			# rodar ALEJÁNDOSE del rival: hacia él solo re-alimenta la patada voladora
			want["left" if float(ctx["sd"]) > 0.0 else "right"] = true
	p.bot_held = want
	if tap != "" and p.state in [Player.State.IDLE, Player.State.RUN, Player.State.JUMP]:
		p.bot_held[tap] = true
		if tap == "throw":
			_bot_last_throw[p.player_id] = Time.get_ticks_msec()


## Salto del foso pequeño (sin plataforma): con el salto firme del feel el
## alcance es ~231 px y la ventana que limpia los 180 px del foso son ~4
## frames — un tick de reacción del bot FÁCIL (hasta 0,26 s = 86 px) caería
## fuera y caminaría hasta caer dentro. El tap se inyecta por frame cuando
## el borde está a <45 px en la dirección en la que corre.
func _bot_pit_jump(p: Player) -> void:
	if not p.is_on_floor() or p.state not in [Player.State.IDLE, Player.State.RUN]:
		return
	var want_r := bool(p.bot_held.get("right", false))
	var want_l := bool(p.bot_held.get("left", false))
	if want_r and p.position.x > PIT2_X0 - 45.0 and p.position.x < PIT2_X0 + 25.0:
		p.bot_held["jump"] = true
	elif want_l and p.position.x > PIT2_X1 - 10.0 and p.position.x < PIT2_X1 + 45.0:
		p.bot_held["jump"] = true


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
		var sx := clampf(_spawn_safe(LEVEL_W * 0.5 + o), GOAL_W + 60.0, LEVEL_W - GOAL_W - 60.0)
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
	weapon_idx.resize(players.size())
	weapon_idx.fill(0)
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
