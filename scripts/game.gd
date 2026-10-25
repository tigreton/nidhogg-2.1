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
var hud: Hud               # HUD y mensajes (corte 3/7)
var bots: BotBrain         # IA de los duelistas (corte 4/7)
var modes: Modes           # modos de juego (corte 5/7)
var combat: Combat         # resolución de combate (corte 6/7)
var net_sync: NetSync      # sincronización online (corte 7/7; NODO hijo: los @rpc van por ruta)
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
var net_ping_ms := -1           # RTT del enlace (chispazos v3): -1 = aún sin medir
var ping_label: Label           # etiqueta del HUD online (la llena net_sync)
var rematch_pending := false    # fix bucle de cuenta atrás: expirar el lock ¿reinicia ronda?


func _fresh_stats() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in players.size():
		out.append({"kills": 0, "deaths": 0, "throws": 0, "dist": 0.0})
	return out


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	net_sync = NetSync.new(self)
	net_sync.name = "NetSync"
	add_child(net_sync)
	arena = ArenaBuilder.new(self)
	hud = Hud.new(self)
	bots = BotBrain.new(self)
	modes = Modes.new(self)
	combat = Combat.new(self)
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
		net_sync.ev_sfx.rpc(pos.x, pos.y, id, db, pitch)


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


# --- modos: la lógica vive en scripts/modes.gd (corte 5/7); el estado de
# los modos sigue siendo de game. Delegados para teclas, tests y el tick:

func set_mode_2v2(on: bool) -> void:
	modes.set_mode_2v2(on)


func set_chaos(on: bool) -> void:
	modes.set_chaos(on)


func set_sections(on: bool) -> void:
	modes.set_sections(on)


func set_arcade(on: bool) -> void:
	modes.set_arcade(on)


func set_cup(on: bool) -> void:
	modes.set_cup(on)


func _arcade_next() -> void:
	modes._arcade_next()


func _cup_stage(stage: int) -> void:
	modes._cup_stage(stage)


func _update_sections() -> void:
	modes._update_sections()


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


# --- HUD: la construcción y actualización viven en scripts/hud.gd (corte 3/7)
# los nodos del HUD siguen siendo miembros de game (los tests los leen);
# delegados finos para no cambiar ni una llamada externa.

func _build_hud() -> void:
	hud._build_hud()


func _apply_pixel_font(root: Node) -> void:
	hud._apply_pixel_font(root)


func _all_labels(node: Node) -> Array[Label]:
	return hud._all_labels(node)


func show_msg(text: String, dur: float) -> void:
	hud.show_msg(text, dur)
	if Net.is_host() and Net.client_ready:
		net_sync.ev_msg.rpc(text, dur)


func _show_fight() -> void:
	hud._show_fight()


func _show_step_arrow(p: Player) -> void:
	hud._show_step_arrow(p)


func _update_hud() -> void:
	hud._update_hud()


func _update_pips() -> void:
	hud._update_pips()


func _update_respawn_bar() -> void:
	hud._update_respawn_bar()


func _start_round() -> void:
	if random_arena or _shuffled:
		# arena barajada (tarea 86): cada punto, tramos nuevos
		_reshuffle_level()
	rematch_pending = false
	if Net.is_host() and Net.client_ready:
		net_sync.ev_round.rpc()
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
		net_sync.ev_burst.rpc(pos.x, pos.y, col, amount, speed)


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


# --- combate: la resolución vive en scripts/combat.gd (corte 6/7); el
# estado del duelo sigue siendo de game. Delegados para el tick, los
# proyectiles y el online:

func _resolve_pushbox() -> void:
	combat._resolve_pushbox()


func _resolve_attacks() -> void:
	combat._resolve_attacks()


func _resolve_divekicks() -> void:
	combat._resolve_divekicks()


func _resolve_dives() -> void:
	combat._resolve_dives()


func _resolve_sidekicks() -> void:
	combat._resolve_sidekicks()


func _resolve_roll_tackles() -> void:
	combat._resolve_roll_tackles()


func _resolve_guard_impale() -> void:
	combat._resolve_guard_impale()


func _resolve_stomps() -> void:
	combat._resolve_stomps()


func _kill(def: Player, atk: Player) -> void:
	combat._kill(def, atk)


func _clash(a: Player, b: Player) -> void:
	combat._clash(a, b)


func _spawn_corpse(def: Player, atk: Player) -> void:
	combat._spawn_corpse(def, atk)


func _respawn(p: Player) -> void:
	combat._respawn(p)


func _next_weapon(p: Player) -> String:
	return combat._next_weapon(p)


func _respawn_pos(p: Player) -> Vector2:
	return combat._respawn_pos(p)


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
		net_sync.ev_point.rpc(_team(p), p.position.x, p.position.y)
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
			net_sync.ev_match_over.rpc(p.player_id)
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


# --- IA: el cerebro vive en scripts/bot_brain.gd (corte 4/7); su memoria
# (_bot_mem, _bot_last_throw, _bot_feint_until) viajó con él. Delegados para
# que el tick no cambie ni una línea:

func _bot_think(p: Player, delta: float) -> void:
	bots._bot_think(p, delta)


func _bot_observe_all() -> void:
	bots._bot_observe_all()


func _bot_pit_jump(p: Player) -> void:
	bots._bot_pit_jump(p)


# --- online: la sincronización vive en scripts/net_sync.gd (corte 7/7),
# un nodo hijo (NetSync) porque los @rpc viajan por ruta de nodo. Los
# call-sites .rpc quedan como net_sync.ev_*.rpc(...). Delegados para el
# arranque (_ready), el tick y el combate:

func _host_setup() -> void:
	net_sync._host_setup()


func _client_setup() -> void:
	net_sync._client_setup()


func _on_net_drop() -> void:
	net_sync._on_net_drop()


func _position_players_for_round() -> void:
	net_sync._position_players_for_round()


func _client_step(delta: float) -> void:
	net_sync._client_step(delta)


func _host_net_step() -> void:
	net_sync._host_net_step()


func _net_ev_hit(p: Player, kind: int, sx := 0.0, sy := 0.0, st := 0.0) -> void:
	net_sync._net_ev_hit(p, kind, sx, sy, st)
