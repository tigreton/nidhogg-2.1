class_name Player
extends CharacterBody2D
## Duelista estilo Nidhogg: estancias alta/media/baja, ataque, patada voladora,
## lanzamiento de espada y muerte de un golpe. Todo el dibujo es procedural.

signal died(player: Player)
signal threw_sword(player: Player)

enum State { IDLE, RUN, JUMP, DIVEKICK, ATTACK, STUNNED, KNOCKDOWN, DEAD, ROLL }
enum H { LOW, MID, HIGH }

const SPEED := 330.0
const DUCK_SPEED := 150.0
const JUMP_VELOCITY := -700.0
const GRAVITY := 1700.0
const ATTACK_DURATION := 0.30
const ATTACK_FROM := 0.07
const ATTACK_TO := 0.20
const ATTACK_RANGE := 86.0
const KNOCKDOWN_TIME := 1.0
const PUNCH_RANGE := 50.0
const ROLL_DURATION := 0.34
const ROLL_SPEED := 520.0
const ROLL_COOLDOWN := 0.55
const LUNGE_SPEED := 620.0

var player_id := 1
var color := Color("ffb324")
var goal_dir := 1
var frozen := false

var state: int = State.IDLE
var stance: int = H.MID
var facing := 1
var has_sword := true
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
var attack_dash_time := 0.0   # > 0 mientras la estocada empuja hacia delante


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

	match state:
		State.ATTACK:
			attack_time += delta
			if attack_time >= ATTACK_DURATION:
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

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if can_act:
		if hit("jump") and held("down") and is_on_floor() and roll_cd <= 0.0:
			# rodar: esquiva rápida agachado (cuenta como estancia baja)
			state = State.ROLL
			roll_time = 0.0
			roll_cd = ROLL_COOLDOWN
			stance = H.LOW
			_sfx("swing", -22.0)
		elif hit("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			state = State.JUMP
			_sfx("jump", -16.0)
		elif hit("attack"):
			if is_on_floor():
				# ataque de espada o puñetazo (sin espada): reutiliza ATTACK
				state = State.ATTACK
				attack_time = 0.0
				attack_resolved = false
				attack_height = stance
				if has_sword and (held("right") or held("left")):
					# estocada: embestida al atacar corriendo
					attack_dash_time = ATTACK_DURATION
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
		elif hit("throw") and has_sword:
			has_sword = false
			threw_sword.emit(self)

	var dir := 0.0
	if can_act:
		dir = (1.0 if held("right") else 0.0) - (1.0 if held("left") else 0.0)
		if dir != 0.0:
			facing = 1 if dir > 0.0 else -1

	match state:
		State.IDLE, State.RUN:
			var sp := DUCK_SPEED if stance == H.LOW else SPEED
			velocity.x = dir * sp
			state = State.RUN if absf(velocity.x) > 5.0 else State.IDLE
			run_phase += velocity.x * delta * 0.045
		State.JUMP:
			velocity.x = move_toward(velocity.x, dir * SPEED, 1100.0 * delta)
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

	if is_bot:
		bot_held_prev = bot_held.duplicate()


func _dust(amount: int, speed: float) -> void:
	var cp := CPUParticles2D.new()
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
	return state == State.ATTACK and attack_time >= ATTACK_FROM and attack_time <= ATTACK_TO and not attack_resolved


func attack_ext() -> float:
	if state != State.ATTACK:
		return 0.0
	var t := (attack_time - ATTACK_FROM) / (ATTACK_TO - ATTACK_FROM)
	return sin(clampf(t, 0.0, 1.0) * PI)


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


func _draw() -> void:
	if state == State.DEAD:
		return
	var c := color if flash_time <= 0.0 else Color.WHITE
	var dark := Color(0.05, 0.04, 0.08)
	var blade := Color(0.87, 0.9, 0.95)

	# halo pulsante bajo los pies de quien tiene el paso
	var g := get_parent()
	if g != null and g.get("right_of_way") == self:
		var pulse := 0.5 + 0.5 * sin(anim_time * 10.0)
		draw_circle(Vector2(0, 34), 20.0 + 4.0 * pulse, Color(color.r, color.g, color.b, 0.10 + 0.10 * pulse))
		draw_arc(Vector2(0, 34), 24.0, 0.0, TAU, 24, Color(color.r, color.g, color.b, 0.55), 2.0)

	var t_pos := Vector2.ZERO
	var t_rot := 0.0
	var t_scl := Vector2.ONE
	if state == State.KNOCKDOWN:
		t_rot = -PI * 0.46
		t_pos = Vector2(-6, 20)
		t_scl = Vector2(1.0, 0.9)
	elif state == State.ROLL:
		t_rot = -TAU * (roll_time / ROLL_DURATION)
		t_pos = Vector2(0, 14)
		t_scl = Vector2(0.9, 0.9)
	elif state == State.DIVEKICK:
		t_rot = 0.7
	elif state == State.STUNNED:
		t_rot = -0.28
	elif state == State.ATTACK and attack_dash_time > 0.0:
		# estocada: ligera inclinación hacia delante
		t_rot = 0.3
	elif stance == H.LOW and state in [State.IDLE, State.RUN]:
		t_pos = Vector2(0, 10)
		t_scl = Vector2(1.0, 0.72)
	draw_set_transform(t_pos, t_rot, t_scl)

	var hip := Vector2(0, 12)
	var f1 := Vector2(-5, 30)
	var f2 := Vector2(5, 30)
	if state == State.RUN:
		f1 = Vector2(11.0 * sin(run_phase), 30.0 - 5.0 * maxf(0.0, cos(run_phase)))
		f2 = Vector2(-11.0 * sin(run_phase), 30.0 - 5.0 * maxf(0.0, -cos(run_phase)))
	elif state == State.JUMP or state == State.DIVEKICK:
		f1 = Vector2(-3, 20)
		f2 = Vector2(9, 24)
	draw_line(hip, f1, dark, 6.0)
	draw_line(hip, f2, dark, 6.0)

	draw_line(Vector2(0, -16), Vector2(0, 12), dark, 24.0)
	draw_line(Vector2(0, -16), Vector2(0, 12), c, 19.0)
	draw_line(Vector2(-9, 4), Vector2(9, 4), dark, 4.0)

	draw_circle(Vector2(1, -28), 10.0, dark)
	draw_circle(Vector2(1, -28), 8.0, c)
	var wag := sin(anim_time * 12.0) * 3.0
	draw_line(Vector2(-4, -31), Vector2(-18, -29 + wag), c.darkened(0.25), 3.5)

	# en la hierba alta la espada no se dibuja: el rival no ve la estancia
	var hide_sword: bool = g != null and g.has_method("in_grass") and g.in_grass(global_position.x)
	if has_sword and not hide_sword:
		var h: int = attack_height if state == State.ATTACK else stance
		var ext := attack_ext()
		var hand := Vector2(6, -8)
		var tip := Vector2(42, -8)
		match h:
			H.HIGH:
				hand = Vector2(5, -36)
				tip = Vector2(10, -66)
			H.LOW:
				hand = Vector2(6, 6)
				tip = Vector2(42, 18)
		var dirv := (tip - hand).normalized()
		var blen := (tip - hand).length() + ext * 22.0
		var hpos := hand + dirv * ext * 6.0
		var tpos := hpos + dirv * blen
		draw_line(hpos - dirv * 7.0, hpos, Color(0.32, 0.2, 0.1), 6.0)
		draw_line(hpos, tpos, dark, 7.0)
		draw_line(hpos, tpos, blade, 4.0)
		draw_circle(hpos, 4.0, c)
		if ext > 0.15:
			var mid := (hpos + tpos) * 0.5
			draw_circle(mid, 13.0 * ext, Color(1, 1, 1, 0.25 * ext))
	elif state == State.ATTACK:
		# puñetazo a puño limpio
		var pext := attack_ext()
		if pext > 0.05:
			draw_circle(Vector2(10.0 + pext * 16.0, -6.0), 5.0, c)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
