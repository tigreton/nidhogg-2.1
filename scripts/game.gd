extends Node2D
## Juego estilo Nidhogg: duelo de esgrima a un golpe. Quien mata gana el "paso"
## y debe correr hasta su meta; el rival reaparece delante para frenarlo.
## Primero en llegar a WIN_SCORE puntos gana el partido.

const LEVEL_W := 4800.0
const GROUND_Y := 560.0
const PIT_X0 := 2210.0
const PIT_X1 := 2380.0
const PLAT_X0 := PIT_X0 - 80.0
const PLAT_X1 := PIT_X1 + 80.0
const PLAT_Y := 448.0
const GOAL_W := 130.0
const WIN_SCORE := 3
const VIEW_W := 1152.0
const VIEW_H := 648.0
const RESPAWN_DELAY := 2.4

const P1_COLOR := Color("ffb324")
const P2_COLOR := Color("39d7ff")

var players: Array[Player] = []
var right_of_way: Player = null
var scores := [0, 0]
var match_over := false
var round_lock := 0.0
var respawn_timers := [0.0, 0.0]
var shake_time := 0.0
var projectiles: Array[SwordProjectile] = []
var pickups: Array[SwordPickup] = []
var goal_polys: Array[Polygon2D] = []

var camera: Camera2D
var msg_label: Label
var score_labels: Array[Label] = []
var msg_tween: Tween


func _ready() -> void:
	_setup_input()
	_build_level()
	_build_players()
	_build_camera()
	_build_hud()
	_start_round()


func _process(_delta: float) -> void:
	var a := 0.13 + 0.06 * sin(Time.get_ticks_msec() * 0.003)
	for gp in goal_polys:
		gp.color.a = a


func sfx(pos: Vector2, id: String, db := -10.0) -> void:
	Sfx.play(self, pos, id, db)


func _setup_input() -> void:
	var defs := {
		"p1_left": [KEY_A], "p1_right": [KEY_D], "p1_up": [KEY_W], "p1_down": [KEY_S],
		"p1_jump": [KEY_W], "p1_attack": [KEY_F], "p1_throw": [KEY_G],
		"p2_left": [KEY_LEFT], "p2_right": [KEY_RIGHT], "p2_up": [KEY_UP], "p2_down": [KEY_DOWN],
		"p2_jump": [KEY_UP], "p2_attack": [KEY_K], "p2_throw": [KEY_L],
		"restart": [KEY_R],
	}
	for action in defs.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in defs[action]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(action, e)


func _build_level() -> void:
	_poly(PackedVector2Array([Vector2(0, 0), Vector2(LEVEL_W, 0), Vector2(LEVEL_W, 720), Vector2(0, 720)]), Color(0.055, 0.05, 0.09), -10)
	_poly(_circle_points(LEVEL_W * 0.5, 118.0, 74.0), Color(0.14, 0.13, 0.20), -9)
	_poly(_circle_points(LEVEL_W * 0.5 - 30.0, 92.0, 13.0), Color(0.10, 0.09, 0.15), -9)
	_poly(_circle_points(LEVEL_W * 0.5 + 26.0, 150.0, 9.0), Color(0.10, 0.09, 0.15), -9)
	var px := 340.0
	while px < LEVEL_W - 200.0:
		if not (px > PIT_X0 - 130.0 and px < PIT_X1 + 130.0):
			_poly(PackedVector2Array([Vector2(px - 26, GROUND_Y), Vector2(px + 26, GROUND_Y), Vector2(px + 26, 130.0), Vector2(px - 26, 130.0)]), Color(0.085, 0.08, 0.135), -5)
			_poly(PackedVector2Array([Vector2(px - 36, 142.0), Vector2(px + 36, 142.0), Vector2(px + 36, 122.0), Vector2(px - 36, 122.0)]), Color(0.11, 0.10, 0.17), -5)
		px += 640.0
	_floor_segment(0.0, PIT_X0)
	_floor_segment(PIT_X1, LEVEL_W)
	_poly(PackedVector2Array([Vector2(PIT_X0, GROUND_Y + 4), Vector2(PIT_X1, GROUND_Y + 4), Vector2(PIT_X1 - 26, 800.0), Vector2(PIT_X0 + 26, 800.0)]), Color(0.30, 0.07, 0.09), -6)
	_platform(PLAT_X0, PLAT_X1, PLAT_Y)
	_wall(-46.0, 6.0)
	_wall(LEVEL_W - 6.0, LEVEL_W + 46.0)
	_goal_zone(LEVEL_W - GOAL_W, LEVEL_W, P1_COLOR)
	_goal_zone(0.0, GOAL_W, P2_COLOR)


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
	hint.text = "P1: A/D mover · W saltar/arriba · S agachar · F atacar · G lanzar    P2: ←/→ · ↑ · ↓ · K atacar · L lanzar    R: revancha"
	hint.position = Vector2(22, VIEW_H - 42)
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.62, 0.60, 0.72))
	cl.add_child(hint)


func _start_round() -> void:
	for s in projectiles:
		s.queue_free()
	projectiles.clear()
	for pk in pickups:
		pk.queue_free()
	pickups.clear()
	right_of_way = null
	respawn_timers = [0.0, 0.0]
	players[0].reset_to(Vector2(LEVEL_W * 0.5 - 220.0, GROUND_Y - 29.0), 1)
	players[1].reset_to(Vector2(LEVEL_W * 0.5 + 220.0, GROUND_Y - 29.0), -1)
	show_msg("¡LUCHA!", 1.0)


func show_msg(text: String, dur: float) -> void:
	msg_label.text = text
	msg_label.modulate.a = 1.0
	if msg_tween:
		msg_tween.kill()
	msg_tween = msg_label.create_tween()
	msg_tween.tween_interval(dur)
	msg_tween.tween_property(msg_label, "modulate:a", 0.0, 0.4)


func _update_hud() -> void:
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
	shake_time = maxf(0.0, shake_time - delta)
	if round_lock > 0.0:
		round_lock -= delta
		if round_lock <= 0.0:
			_start_round()
	if match_over and Input.is_action_just_pressed("restart"):
		scores = [0, 0]
		match_over = false
		_update_hud()
		_start_round()
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
	_resolve_attacks()
	_resolve_divekicks()
	_update_projectiles(delta)
	_update_pickups()
	_check_goals()
	_update_camera()


func _other(p: Player) -> Player:
	return players[1] if p == players[0] else players[0]


func _resolve_attacks() -> void:
	for atk in players:
		if not atk.attack_is_active():
			continue
		var def := _other(atk)
		if def.state == Player.State.DEAD or def.invuln_time > 0.0:
			continue
		var dx := (def.position.x - atk.position.x) * atk.facing
		if dx < -16.0 or dx > Player.ATTACK_RANGE:
			continue
		if absf(def.position.y - atk.position.y) > 92.0:
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
				_kill(def, atk)
			"trade":
				_kill(def, atk)
				_kill(atk, null)
			"clash":
				_clash(atk, def)
			_:
				pass


func _clash(a: Player, b: Player) -> void:
	var mid := Vector2((a.position.x + b.position.x) * 0.5, minf(a.position.y, b.position.y) - 14.0)
	_burst(mid, Color(1.0, 0.93, 0.55), 14, 320.0)
	sfx(mid, "clash", -8.0)
	shake_time = maxf(shake_time, 0.14)
	var push_b := 1 if b.position.x >= a.position.x else -1
	b.take_clash(push_b)
	a.take_clash(-push_b)


func _resolve_divekicks() -> void:
	for p in players:
		if p.state != Player.State.DIVEKICK or p.divekick_resolved:
			continue
		var def := _other(p)
		if def.state == Player.State.DEAD or def.invuln_time > 0.0:
			continue
		if absf(def.position.x - p.position.x) > 44.0 or absf(def.position.y - p.position.y) > 64.0:
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


func _kill(def: Player, atk: Player) -> void:
	if def.state == Player.State.DEAD:
		return
	def.die()
	respawn_timers[def.player_id - 1] = RESPAWN_DELAY
	_burst(def.position, def.color, 34, 440.0)
	_burst(def.position, Color(0.95, 0.95, 1.0), 12, 260.0)
	sfx(def.position, "kill", -6.0)
	shake_time = maxf(shake_time, 0.3)
	if atk != null and atk.state != Player.State.DEAD:
		right_of_way = atk
	else:
		var alive: Array[Player] = []
		for p in players:
			if p.state != Player.State.DEAD:
				alive.append(p)
		if alive.size() == 1:
			right_of_way = alive[0]
		else:
			right_of_way = null


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
		return Vector2(LEVEL_W * 0.5 + (220.0 if p.player_id == 2 else -220.0), 200.0)
	var dir := float(right_of_way.goal_dir)
	var x := right_of_way.position.x + dir * 540.0
	if x > PIT_X0 - 50.0 and x < PIT_X1 + 50.0:
		x = PIT_X1 + 70.0 if dir > 0.0 else PIT_X0 - 70.0
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


func _update_projectiles(delta: float) -> void:
	var done: Array[SwordProjectile] = []
	for s in projectiles:
		s.position += s.vel * delta
		if s.position.x < 26.0 or s.position.x > LEVEL_W - 26.0:
			_drop_sword(s.position, s.color)
			done.append(s)
			continue
		for p in players:
			if p == s.thrower or p.state == Player.State.DEAD or p.invuln_time > 0.0:
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


func _drop_sword(pos: Vector2, col: Color) -> void:
	var x := clampf(pos.x, 30.0, LEVEL_W - 30.0)
	if x > PIT_X0 and x < PIT_X1:
		return
	var pk := SwordPickup.new()
	pk.color = col
	pk.position = Vector2(x, _surface_y(x, pos.y) - 12.0)
	add_child(pk)
	pickups.append(pk)


func _surface_y(x: float, from_y: float) -> float:
	if from_y < PLAT_Y and x > PLAT_X0 and x < PLAT_X1:
		return PLAT_Y
	return GROUND_Y


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
	scores[p.player_id - 1] += 1
	_update_hud()
	sfx(p.position, "point", -6.0)
	_burst(p.position + Vector2(0, -30), p.color, 42, 480.0)
	right_of_way = null
	if scores[p.player_id - 1] >= WIN_SCORE:
		match_over = true
		show_msg("¡GANA P%d!  ·  R: revancha" % p.player_id, 12.0)
	else:
		round_lock = 1.4
		show_msg("¡PUNTO!", 1.0)


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
	tx = clampf(tx, VIEW_W * 0.5, LEVEL_W - VIEW_W * 0.5)
	camera.position = Vector2(tx, VIEW_H * 0.5 + 6.0)
	if shake_time > 0.0:
		camera.offset = Vector2(randf_range(-9.0, 9.0), randf_range(-7.0, 7.0)) * (shake_time * 4.0)
	else:
		camera.offset = Vector2.ZERO
