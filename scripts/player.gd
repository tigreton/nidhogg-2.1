class_name Player
extends CharacterBody2D
## Duelista estilo Nidhogg: estancias alta/media/baja, ataque, patada voladora,
## lanzamiento de espada y muerte de un golpe. Dibujo con sprites de art/sprites.

signal died(player: Player)
signal threw_sword(player: Player)
signal fired_arrow(player: Player, height: int, charge: float)

enum State { IDLE, RUN, JUMP, DIVEKICK, ATTACK, STUNNED, KNOCKDOWN, DEAD, ROLL, DIVE, SIDEKICK }
enum H { LOW, MID, HIGH }

const SPEED := 330.0
const DUCK_SPEED := 150.0
const UNARMED_SPEED_MULT := 1.15
const JUMP_VY_STAND := -460.0   # ápice ≈ 66 px ≈ 1,1 · altura del jugador (58)
const JUMP_VY_RUN := -680.0     # ápice ≈ 144 px (el actual: no rompe la arena)
const GRAVITY_UP := 1600.0      # subida suave (el salto "flota" arriba)
const GRAVITY_FALL := 1900.0    # bajada pesada (pegada arcade)
const MAX_FALL := 980.0         # tope de velocidad de caída
const GROUND_ACCEL := 2800.0    # 0 → 330 px/s en ~6 frames
const GROUND_FRICTION := 5200.0 # frenado en ~4 frames
const AIR_ACCEL := 1500.0       # control aéreo parcial hacia la carrera
const ATTACK_DURATION := 0.30
const ATTACK_FROM := 0.07
const ATTACK_TO := 0.20
const ATTACK_RANGE := 86.0
const KNOCKDOWN_TIME := 1.0
const PUNCH_RANGE := 50.0
const ROLL_DURATION := 0.34
const ROLL_SPEED := 520.0
const ROLL_COOLDOWN := 0.55
const DIVE_SPEED := 546.0
const DIVE_TIME := 0.55
const LUNGE_SPEED := 620.0
const SIDEKICK_TIME := 0.42

const POSES := ["idle", "run_0", "run_1", "run_2", "run_3", "jump", "fall", "crouch", "slide", "attack_high", "attack_mid", "attack_low", "throw", "divekick", "dead", "downed"]
const POSE_SCALE := 58.0 / 56.0   # el sprite mide 56 px de alto; la colisión 58
const POSE_FEET_Y := 32.0        # dónde quedan los pies respecto al origen

static var _pose_tex := {}

static func pose_texture(pose: String, side: String) -> Texture2D:
	# carga perezosa de las 32 poses (p1 azul, p2 rojo)
	if _pose_tex.is_empty():
		for p in POSES:
			for s in ["p1", "p2"]:
				_pose_tex["%s_%s" % [p, s]] = load("res://art/sprites/player_%s_%s.png" % [p, s])
	return _pose_tex.get("%s_%s" % [pose, side], _pose_tex["idle_p1"])

var player_id := 1
var color := Color("ffb324")
var goal_dir := 1
var frozen := false

var state: int = State.IDLE
var stance: int = H.MID
var facing := 1
var has_sword := true
var weapon_id := "florete"
var invuln_time := 0.0
var flash_time := 0.0
var stun_time := 0.0
var knockdown_time := 0.0
var attack_time := 0.0
var attack_height: int = H.MID
var attack_resolved := false
var divekick_resolved := false
var run_phase := 0.0
var anim_time := 0.0
var is_bot := false
var bot_held := {}          # acciones que el bot mantiene pulsadas (solo si is_bot)
var bot_held_prev := {}     # estado del tick anterior, para detectar "recién pulsada"
var bot_think := 0.0        # cronómetro entre decisiones del bot (lo usa game.gd)
var was_on_floor := true
var dust_cd := 0.0
var roll_time := 0.0
var roll_cd := 0.0
var dive_time := 0.0
var dive_resolved := false
var sidekick_time := 0.0
var sidekick_resolved := false
var attack_dash_time := 0.0   # > 0 mientras la estocada empuja hacia delante
var bow_time := 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(26, 58)
	cs.shape = rect
	add_child(cs)


func _a(n: String) -> StringName:
	return StringName("p%d_%s" % [player_id, n])


func held(n: String) -> bool:
	if is_bot:
		return bool(bot_held.get(n, false))
	return Input.is_action_pressed(_a(n))


func hit(n: String) -> bool:
	if is_bot:
		return bool(bot_held.get(n, false)) and not bool(bot_held_prev.get(n, false))
	return Input.is_action_just_pressed(_a(n))


func _sfx(id: String, db := -12.0) -> void:
	var g := get_parent()
	if g != null and g.has_method("sfx"):
		g.sfx(position, id, db)


func _physics_process(delta: float) -> void:
	anim_time += delta
	invuln_time = maxf(0.0, invuln_time - delta)
	flash_time = maxf(0.0, flash_time - delta)
	roll_cd = maxf(0.0, roll_cd - delta)
	attack_dash_time = maxf(0.0, attack_dash_time - delta)

	if state == State.DEAD:
		return

	var can_act: bool = (not frozen) and state in [State.IDLE, State.RUN, State.JUMP]

	if can_act:
		if held("up"):
			stance = H.HIGH
		elif held("down"):
			stance = H.LOW
		else:
			stance = H.MID
		if weapon_id == "espada" and stance == H.MID:
			stance = H.LOW

	match state:
		State.ATTACK:
			attack_time += delta
			if attack_time >= attack_dur():
				state = State.IDLE
		State.STUNNED:
			stun_time -= delta
			if stun_time <= 0.0 and is_on_floor():
				state = State.IDLE
		State.KNOCKDOWN:
			knockdown_time -= delta
			if knockdown_time <= 0.0:
				state = State.IDLE
		State.ROLL:
			roll_time += delta
			if roll_time >= ROLL_DURATION:
				state = State.IDLE
		State.DIVE:
			dive_time += delta
			if dive_time >= DIVE_TIME:
				state = State.KNOCKDOWN
				knockdown_time = 0.6
		State.SIDEKICK:
			sidekick_time += delta
			if sidekick_time >= SIDEKICK_TIME and is_on_floor():
				state = State.IDLE

	if not is_on_floor():
		# gravedad asimétrica: sube frenando suave, cae pesado y con tope
		velocity.y += (GRAVITY_UP if velocity.y < 0.0 else GRAVITY_FALL) * delta
		velocity.y = minf(velocity.y, MAX_FALL)

	if can_act:
		if hit("jump") and held("down") and state == State.RUN and absf(velocity.x) > 120.0 and roll_cd <= 0.0:
			# dive horizontal: vuelo rasante con la espada
			state = State.DIVE
			dive_time = 0.0
			dive_resolved = false
			roll_cd = DIVE_TIME
			stance = H.MID
			velocity = Vector2(facing * DIVE_SPEED, 0.0)
			_sfx("swing", -18.0)
		elif hit("jump") and held("down") and is_on_floor() and roll_cd <= 0.0 and MatchRules.allow_roll:
			# rodar: esquiva rápida agachado (cuenta como estancia baja)
			state = State.ROLL
			roll_time = 0.0
			roll_cd = ROLL_COOLDOWN
			stance = H.LOW
			_sfx("swing", -22.0)
		elif hit("jump") and is_on_floor():
			# salto doble: parado ~1 personaje, con carrerilla el ápice completo
			velocity.y = JUMP_VY_RUN if state == State.RUN else JUMP_VY_STAND
			state = State.JUMP
			_sfx("jump", -16.0)
		elif hit("attack"):
			if weapon_id == "arco":
				# tensar el arco: el disparo sale al soltar
				bow_time = 0.0001
				_sfx("swing", -26.0)
			elif is_on_floor() and has_sword and state == State.RUN and held("down"):
				# patada lateral (sidekick): derriba y desarma
				state = State.SIDEKICK
				sidekick_time = 0.0
				sidekick_resolved = false
				velocity = Vector2(facing * 440.0, -160.0)
				_sfx("swing", -18.0)
			elif is_on_floor():
				# ataque de espada o puñetazo (sin espada): reutiliza ATTACK
				state = State.ATTACK
				attack_time = 0.0
				attack_resolved = false
				attack_height = stance
				if has_sword and (held("right") or held("left")):
					# estocada: embestida al atacar corriendo
					attack_dash_time = attack_dur()
					velocity.x = facing * LUNGE_SPEED
				_sfx("swing", -20.0)
			elif has_sword and (held("up") or held("down")):
				# tajo aéreo: elegir altura manteniendo arriba/abajo
				state = State.ATTACK
				attack_time = 0.0
				attack_resolved = false
				attack_height = stance
				velocity.y = maxf(velocity.y, -80.0)
				_sfx("swing", -20.0)
			else:
				state = State.DIVEKICK
				divekick_resolved = false
				stance = H.MID
				velocity = Vector2(facing * 430.0, 440.0)
				_sfx("swing", -20.0)
		elif hit("throw") and has_sword and MatchRules.allow_throw:
			has_sword = false
			threw_sword.emit(self)

	var dir := 0.0
	if can_act:
		dir = (1.0 if held("right") else 0.0) - (1.0 if held("left") else 0.0)
		if dir != 0.0:
			facing = 1 if dir > 0.0 else -1

	match state:
		State.IDLE, State.RUN:
			var sp := DUCK_SPEED if stance == H.LOW else SPEED * (UNARMED_SPEED_MULT if not has_sword else run_mult())
			# arranque en rampa: acelerar cuesta ~6 frames, frenar ~4
			var rate := GROUND_ACCEL if dir != 0.0 else GROUND_FRICTION
			velocity.x = move_toward(velocity.x, dir * sp, rate * delta)
			state = State.RUN if absf(velocity.x) > 5.0 else State.IDLE
			run_phase += velocity.x * delta * 0.045
		State.JUMP:
			velocity.x = move_toward(velocity.x, dir * SPEED, AIR_ACCEL * delta)
		State.ATTACK:
			if attack_dash_time > 0.0:
				velocity.x = facing * LUNGE_SPEED
			else:
				velocity.x = move_toward(velocity.x, facing * 110.0, 900.0 * delta)
		State.STUNNED, State.KNOCKDOWN:
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
		State.ROLL:
			velocity.x = facing * ROLL_SPEED
			stance = H.LOW
		State.DIVE:
			velocity.x = facing * DIVE_SPEED
			velocity.y = 0.0
			stance = H.MID
		State.SIDEKICK:
			velocity.x = facing * 440.0

	move_and_slide()

	if is_on_floor():
		if state == State.JUMP:
			state = State.IDLE
		elif state == State.DIVEKICK:
			state = State.KNOCKDOWN
			knockdown_time = 0.3
			velocity.x *= 0.3

	dust_cd = maxf(0.0, dust_cd - delta)
	if is_on_floor() and not was_on_floor:
		_dust(10, 150.0)
	elif state == State.RUN and dust_cd <= 0.0:
		dust_cd = 0.16
		_dust(3, 60.0)
	was_on_floor = is_on_floor()

	scale.x = facing
	var blink: bool = invuln_time > 0.0 and fmod(anim_time, 0.16) < 0.08
	self_modulate.a = 0.35 if blink else 1.0
	queue_redraw()

	if bow_time > 0.0:
		if held("attack") and state in [State.IDLE, State.RUN, State.JUMP]:
			bow_time = minf(bow_time + delta, 1.0)
		else:
			fired_arrow.emit(self, stance, bow_time)
			bow_time = 0.0

	if is_bot:
		bot_held_prev = bot_held.duplicate()


func _dust(amount: int, speed: float) -> void:
	var cp := CPUParticles2D.new()
	cp.process_mode = Node.PROCESS_MODE_PAUSABLE
	cp.position = Vector2(0, 30)
	cp.one_shot = true
	cp.emitting = true
	cp.amount = amount
	cp.lifetime = 0.4
	cp.explosiveness = 1.0
	cp.direction = Vector2.UP
	cp.spread = 70.0
	cp.initial_velocity_min = speed * 0.4
	cp.initial_velocity_max = speed
	cp.gravity = Vector2(0, -60.0)
	cp.scale_amount_min = 2.0
	cp.scale_amount_max = 4.0
	cp.color = Color(0.55, 0.52, 0.60, 0.5)
	add_child(cp)
	get_tree().create_timer(0.9).timeout.connect(cp.queue_free)


func attack_is_active() -> bool:
	return state == State.ATTACK and attack_time >= attack_from() and attack_time <= attack_to() and not attack_resolved


func attack_ext() -> float:
	if state != State.ATTACK:
		return 0.0
	var t := (attack_time - attack_from()) / (attack_to() - attack_from())
	return sin(clampf(t, 0.0, 1.0) * PI)


func weapon() -> Dictionary:
	return GameConfig.WEAPONS.get(weapon_id, GameConfig.WEAPONS["florete"])


func attack_from() -> float:
	return float(weapon()["from"])


func attack_to() -> float:
	return float(weapon()["to"])


func attack_dur() -> float:
	return float(weapon()["dur"])


func weapon_reach() -> float:
	return float(weapon()["reach"])


func run_mult() -> float:
	return float(weapon()["run_mult"])


func take_clash(push: int) -> void:
	state = State.STUNNED
	stun_time = 0.34
	velocity = Vector2(push * 380.0, -240.0)
	flash_time = 0.15


func knockdown(push: int) -> void:
	state = State.KNOCKDOWN
	knockdown_time = KNOCKDOWN_TIME
	velocity = Vector2(push * 260.0, -260.0)
	flash_time = 0.2


func die() -> void:
	state = State.DEAD
	visible = false
	velocity = Vector2.ZERO
	died.emit(self)


func revive(pos: Vector2, face: int) -> void:
	position = pos
	facing = face
	velocity = Vector2.ZERO
	state = State.JUMP
	has_sword = true
	invuln_time = 1.3
	flash_time = 0.0
	visible = true
	scale.x = face


func reset_to(pos: Vector2, face: int) -> void:
	revive(pos, face)
	invuln_time = 0.0
	state = State.IDLE


func _pose_name() -> String:
	match state:
		State.RUN:
			if stance == H.LOW:
				return "crouch"
			return "run_%d" % int(fposmod(run_phase * 2.0 / PI, 4.0))
		State.JUMP:
			return "jump" if velocity.y < 0.0 else "fall"
		State.DIVEKICK, State.DIVE:
			return "divekick"
		State.ATTACK:
			match attack_height:
				H.HIGH:
					return "attack_high"
				H.LOW:
					return "attack_low"
				_:
					return "attack_mid"
		State.KNOCKDOWN:
			return "downed"
		State.ROLL:
			return "jump"
		State.SIDEKICK:
			return "crouch"
		_:
			if stance == H.LOW:
				return "crouch"
			return "idle"


func _draw() -> void:
	if state == State.DEAD:
		return
	# halo pulsante bajo los pies de quien tiene el paso
	var g := get_parent()
	if g != null and g.get("right_of_way") == self:
		var pulse := 0.5 + 0.5 * sin(anim_time * 10.0)
		draw_circle(Vector2(0, 34), 20.0 + 4.0 * pulse, Color(color.r, color.g, color.b, 0.10 + 0.10 * pulse))
		draw_arc(Vector2(0, 34), 24.0, 0.0, TAU, 24, Color(color.r, color.g, color.b, 0.55), 2.0)

	# transform por estado (la pose ya aporta gran parte del gesto)
	var t_pos := Vector2.ZERO
	var t_rot := 0.0
	var t_scl := Vector2.ONE
	match state:
		State.ROLL:
			t_rot = -TAU * (roll_time / ROLL_DURATION)
			t_pos = Vector2(0, 10)
		State.DIVE:
			t_rot = 0.35
		State.SIDEKICK:
			t_rot = 0.45
		State.DIVEKICK:
			t_rot = 0.15
		State.STUNNED:
			t_rot = -0.28
		State.ATTACK:
			if attack_dash_time > 0.0:
				t_rot = 0.15

	# sprite de la pose, anclado por los pies; P3/P4 reutilizan el de su par teñido
	var side := "p1" if (player_id == 1 or player_id == 3) else "p2"
	var tint := Color.WHITE if player_id <= 2 else color
	if flash_time > 0.0:
		tint = Color(2.5, 2.5, 2.5)
	var tex := pose_texture(_pose_name(), side)
	var w := tex.get_width() * POSE_SCALE
	var h := tex.get_height() * POSE_SCALE
	draw_set_transform(t_pos, t_rot, t_scl)
	draw_texture_rect(tex, Rect2(-w * 0.5, POSE_FEET_Y - h, w, h), false, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if has_sword and weapon_id == "arco":
		_draw_bow()
		return

	# puñetazo a puño limpio (sin pose propia: overlay corto)
	if state == State.ATTACK and not has_sword:
		var c := color if flash_time <= 0.0 else Color.WHITE
		var pext := attack_ext()
		if pext > 0.05:
			draw_circle(Vector2(10.0 + pext * 16.0, -6.0), 5.0, c)


const TEX_BOW := preload("res://art/sprites/weapon_bow.png")


func _draw_bow() -> void:
	var c := color if flash_time <= 0.0 else Color.WHITE
	var dark := Color(0.05, 0.04, 0.08)
	var pull := 0.0 if bow_time <= 0.0 else clampf(bow_time, 0.0, 1.0)
	draw_set_transform(Vector2(8, -8), 0.0, Vector2(0.55, 0.55))
	draw_texture(TEX_BOW, -TEX_BOW.get_size() * 0.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var py := -8.0
	var px := 8.0 - pull * 12.0
	draw_line(Vector2(8.0 - 14.0, -8.0 - 14.0), Vector2(px, py), Color(0.85, 0.85, 0.8), 1.5)
	draw_line(Vector2(8.0 - 14.0, -8.0 + 14.0), Vector2(px, py), Color(0.85, 0.85, 0.8), 1.5)
	if pull > 0.0:
		draw_line(Vector2(px, py), Vector2(px + 26.0, py), dark, 2.5)
		draw_line(Vector2(px + 26.0, py), Vector2(px + 26.0 + 6.0, py), c, 2.0)
