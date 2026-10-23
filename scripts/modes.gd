class_name Modes
extends RefCounted
## Modos de juego (corte 5/7 de la disolución de game.gd): 2v2, lluvia de
## rocas (toggle), modo pantallas con rejas y pips de conquista, arcade por
## niveles y copa con bracket. El ESTADO de los modos (mode_2v2, chaos,
## sections_mode, arcade_*, cup_*, gates, sect_conquered, ...) sigue
## VIVIENDO en game — el tick, la IA y los tests lo leen: el módulo lo
## toca vía `host`.

var host  # = game.gd


func _init(game) -> void:
	host = game


func set_mode_2v2(on: bool) -> void:
	if on == host.mode_2v2:
		return
	host.mode_2v2 = on
	if on:
		var ps := preload("res://scenes/player.tscn")
		var p3 := ps.instantiate() as Player
		p3.player_id = 3
		p3.color = host.P3_COLOR
		p3.goal_dir = 1
		p3.is_bot = true
		host.add_child(p3)
		host.players.append(p3)
		var p4 := ps.instantiate() as Player
		p4.player_id = 4
		p4.color = host.P4_COLOR
		p4.goal_dir = -1
		p4.is_bot = true
		host.add_child(p4)
		host.players.append(p4)
		for p in [p3, p4]:
			p.threw_sword.connect(host._on_threw_sword)
			p.fired_arrow.connect(host._on_fired_arrow)
			p.died.connect(host._on_died_pad)
			p.process_mode = Node.PROCESS_MODE_PAUSABLE
		host.ally_bot_level = 2
	else:
		for i in [3, 2]:
			if host.players.size() > i:
				host.players[i].queue_free()
				host.players.remove_at(i)
	for s in host.projectiles:
		s.queue_free()
	host.projectiles.clear()
	for pk in host.pickups:
		pk.queue_free()
	host.pickups.clear()
	set_chaos(false)
	host.respawn_timers.resize(host.players.size())
	host.respawn_timers.fill(0.0)
	host.last_x.resize(host.players.size())
	host.last_x.fill(0.0)
	host.stats = host._fresh_stats()
	host.scores = [0, 0]
	host.match_over = false
	host.stats_label.visible = false
	if not host.sections_mode:
		host.dynamic_zoom = not host.mode_2v2
		host.camera.zoom = Vector2(0.9, 0.9) if host.mode_2v2 else Vector2.ONE
	host._update_hud()
	host._start_round()
	host.show_msg("MODO 2v2: %s" % ("P1·P3 vs P2·P4" if host.mode_2v2 else "DESACTIVADO"), 1.0)


func set_chaos(on: bool) -> void:
	if on == host.chaos:
		return
	host.chaos = on
	host.chaos_timer = 1.0
	for r in host.rocks:
		r.queue_free()
	host.rocks.clear()
	if on:
		host.show_msg("LLUVIA DE ROCAS: ACTIVADA", 1.0)
	else:
		host.show_msg("LLUVIA DE ROCAS: DESACTIVADA", 0.8)


func set_sections(on: bool) -> void:
	if on == host.sections_mode:
		return
	host.sections_mode = on
	for g in host.gates:
		g.queue_free()
	host.gates.clear()
	if on:
		var w = host.LEVEL_W / float(host.SECTION_COUNT)
		for k in range(1, host.SECTION_COUNT):
			var g := SectionGate.new(w * float(k))
			g.z_index = 5
			host.add_child(g)
			host.gates.append(g)
	host.section_index = 3
	if host.section_cam_tween != null and host.section_cam_tween.is_valid():
		host.section_cam_tween.kill()
	if on:
		var z = host.VIEW_W / (host.LEVEL_W / float(host.SECTION_COUNT))
		host.camera.zoom = Vector2(z, z)
		host.camera.position_smoothing_enabled = false
		host.camera.position = host._section_cam_target()
	else:
		host.camera.zoom = Vector2(0.9, 0.9) if host.mode_2v2 else Vector2.ONE
		host.camera.position_smoothing_enabled = true
	host.sect_conquered = [0, 0]
	host.scores = [0, 0]
	host.stats = host._fresh_stats()
	host.match_over = false
	host.stats_label.visible = false
	set_chaos(false)
	host._update_hud()
	host._start_round()
	host.show_msg("MODO PANTALLAS: %s" % ("ACTIVADO" if on else "DESACTIVADO"), 1.0)


func _update_gates() -> void:
	var w = host.LEVEL_W / float(host.SECTION_COUNT)
	var rw = host.right_of_way
	for i in host.gates.size():
		var border = float(i + 1) * w
		var open := false
		if rw != null and rw.state != Player.State.DEAD:
			if rw.goal_dir > 0:
				open = rw.position.x > border - w and rw.position.x < border + 40.0
			else:
				open = rw.position.x < border + w and rw.position.x > border - 40.0
		if host.gates[i].open != open:
			host.gates[i].set_open(open)


func _cross_section(sec: int) -> void:
	var w = host.LEVEL_W / float(host.SECTION_COUNT)
	var dir := 1 if sec > host.section_index else -1
	host.section_index = sec
	# solo el AVANCE hacia la meta conquista: retroceder no infla los host.pips
	var prog := (sec - 3) if host.right_of_way.goal_dir > 0 else (3 - sec)
	if prog > host.sect_conquered[host._team(host.right_of_way)]:
		host.sect_conquered[host._team(host.right_of_way)] = prog
		host.show_msg("¡SECCIÓN CONQUISTADA!", 0.9)
		host.sfx(host.right_of_way.position, "point", -14.0)
	var x_entry = w * float(sec) + 70.0 if dir > 0 else w * float(sec + 1) - 70.0
	var x_far = w * float(sec + 1) - 90.0 if dir > 0 else w * float(sec) + 90.0
	host.right_of_way.position.x = x_entry
	for p in host.players:
		if p == host.right_of_way or p.state == Player.State.DEAD:
			continue
		p.position.x = x_far
		p.invuln_time = maxf(p.invuln_time, 0.8)
	# pan suave hasta la nueva sección (nunca teleport)
	if host.section_cam_tween != null and host.section_cam_tween.is_valid():
		host.section_cam_tween.kill()
	host.section_cam_tween = host.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	host.section_cam_tween.tween_property(host.camera, "position", host._section_cam_target(), host.SECTION_PAN_TIME)


func _update_sections() -> void:
	if not host.sections_mode:
		return
	_update_gates()
	var rw = host.right_of_way
	if rw == null or rw.state == Player.State.DEAD or host.round_lock > 0.0:
		return
	var w = host.LEVEL_W / float(host.SECTION_COUNT)
	var sec := clampi(int(rw.position.x / w), 0, host.SECTION_COUNT - 1)
	if sec != host.section_index:
		_cross_section(sec)


func set_arcade(on: bool) -> void:
	if on == host.arcade:
		return
	if on and host.mode_2v2:
		set_mode_2v2(false)
	if on and host.chaos:
		set_chaos(false)
	if on and host.sections_mode:
		set_sections(false)
	host.arcade = on
	host.arcade_over = false
	if on:
		host.arcade_level = 1
		host.bot_level = _arcade_difficulty()
		host.players[1].is_bot = true
		if host.arena_id != 0:
			host.set_arena(0)
		else:
			# ya en la host.arena 1: host.set_arena saltaría por el guard de "misma
			# host.arena" y el marcador/host.match_over quedarían sin resetear
			host.scores = [0, 0]
			host.stats = host._fresh_stats()
			host.match_over = false
			host.stats_label.visible = false
			host._update_hud()
			host._start_round()
		host.show_msg("ARCADE — NIVEL 1", 1.2)
	else:
		# sin esto el bot del host.arcade quedaba pegado a P2 al salir del modo:
		# Rodrigo seguía moviéndose solo en partidas "normales"
		host.players[1].is_bot = false
		host.show_msg("ARCADE: DESACTIVADO", 0.8)


func _arcade_difficulty() -> int:
	return clampi(1 + (host.arcade_level - 1) / 2, 1, 3)


func _arcade_next() -> void:
	host.arcade_level += 1
	host.bot_level = _arcade_difficulty()
	host.right_of_way = null
	host.scores = [0, 0]
	host.stats = host._fresh_stats()
	host._update_hud()
	var want = (host.arcade_level - 1) % host.ARENA_NAMES.size()
	if want != host.arena_id:
		host.set_arena(want)
	else:
		host.match_over = false
		host.stats_label.visible = false
		host._start_round()
	host.show_msg("ARCADE — NIVEL %d  ·  BOT %s" % [host.arcade_level, ["FÁCIL", "NORMAL", "DIFÍCIL"][_arcade_difficulty() - 1]], 1.4)


func set_cup(on: bool) -> void:
	if on == host.cup:
		return
	if on and host.arcade:
		set_arcade(false)
	if on and host.mode_2v2:
		set_mode_2v2(false)
	if on and host.chaos:
		set_chaos(false)
	if on and host.sections_mode:
		set_sections(false)
	host.cup = on
	host.cup_over = false
	if on:
		_cup_stage(0)
	else:
		host.players[0].is_bot = false
		host.players[1].is_bot = false
		host.show_msg("COPA: DESACTIVADA", 0.8)


func _cup_stage(stage: int) -> void:
	host.cup_stage = stage
	host.bot_level = 2
	if stage == 0:
		host.cup_alive = [true, true]
	host.scores = [0, 0]
	host.stats = host._fresh_stats()
	host.match_over = false
	host.stats_label.visible = false
	host._update_hud()
	match stage:
		0:
			host.players[0].is_bot = false
			host.players[1].is_bot = true
			host.show_msg("COPA — SEMIFINAL 1: P1 vs BOT", 1.6)
		1:
			host.players[0].is_bot = true
			host.players[1].is_bot = false
			host.show_msg("COPA — SEMIFINAL 2: P2 vs BOT", 1.6)
		2:
			if not host.cup_alive[0] and not host.cup_alive[1]:
				host.cup_over = true
				host.match_over = true
				host.show_msg("EL BOT GANA LA COPA  ·  O: nueva copa", 12.0)
				return
			host.players[0].is_bot = not host.cup_alive[0]
			host.players[1].is_bot = not host.cup_alive[1]
			host.show_msg("COPA — FINAL", 1.6)
	host._start_round()

