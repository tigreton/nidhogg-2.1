class_name NetSync
extends Node
## Sincronización online 1v1 (corte 7/7 de la disolución de game.gd):
## host autoritativo + cliente con predicción del propio P2 y reconciliación
## (docs/online-netcode.md). Es un NODO (hijo de game, creado en _ready con
## nombre fijo "NetSync"): los @rpc viajan por RUTA DE NODO y al moverlos del
## game al hijo la ruta pasa a ser .../NetSync en AMBOS peers — el traslado
## es atómico porque ambos corren la misma versión.
## El ESTADO net (net_tick, net_last_snap, net_last_ser, net_wait_peer, ...)
## sigue VIVIENDO en game — el tick y test/online_client.gd lo leen
## (game.net_last_snap): el módulo lo toca vía `host`.
## El ciclo de vida de la conexión (ENet, puerto, señales) es del autoload
## Net: este nodo solo sincroniza la partida.

var host  # = game.gd


func _init(game) -> void:
	host = game


# =============================================================================
# ONLINE (tarea 85): host autoritativo + cliente con predicción del propio P2
# =============================================================================

func _host_setup() -> void:
	host.players[1].net_remote = true
	host.players[1].is_bot = false
	if host.hint_label != null:
		host.hint_label.text = "ONLINE — eres P1 (NACHO): A/D mover · W saltar/arriba · S agachar · F atacar · G lanzar\nGana P1 o P2 a 3 puntos  ·  R: revancha al terminar el partido"
	# posiciones de ronda ya: sin esto los duelistas nacen en (0,0) y caen
	# contra el muro izquierdo mientras llega el rival
	_position_players_for_round()
	if Net.client_ready:
		host._start_round()
	else:
		host.net_wait_peer = true   # el bucle principal congela con este flag
		host.show_msg("ESPERANDO AL RIVAL...", 9999.0)
		Net.client_became_ready.connect(_on_client_ready, CONNECT_ONE_SHOT)


func _on_client_ready() -> void:
	host.net_wait_peer = false
	host._start_round()


func _client_setup() -> void:
	host.players[0].net_puppet = true
	host.players[0].is_bot = false
	host.players[1].is_bot = false
	host.net_wait_peer = true   # hasta el primer ev_round del host
	_position_players_for_round()
	if host.hint_label != null:
		host.hint_label.text = "ONLINE — eres P2 (RODRIGO): ←/→ mover · ↑ saltar/arriba · ↓ agachar · K atacar · L lanzar\nLas reglas las fija el anfitrión (P1)"
	Net.net_ready.rpc_id(1)


## Coloca a los duelistas en la línea de inicio (lo usa host._start_round y los
## setups online para que nadie nazca en (0,0) esperando al rival).
func _position_players_for_round() -> void:
	var offs := [-220.0, 220.0, -620.0, 620.0]
	for i in host.players.size():
		var o: float = offs[i]
		# el barajado puede poner un foso bajo el centro: reaparición a suelo firme
		var sx := clampf(host._spawn_safe(host.LEVEL_W * 0.5 + o), host.GOAL_W + 60.0, host.LEVEL_W - host.GOAL_W - 60.0)
		host.players[i].reset_to(Vector2(sx, host.GROUND_Y - 29.0), -1 if o > 0.0 else 1)


func _on_net_drop() -> void:
	# se cortó el enlace en plena partida: volver al título sin colgar el árbol
	host.get_tree().paused = false
	Net.shutdown()
	host.get_tree().change_scene_to_file("res://scenes/title.tscn")


# --- host: aplicar input remoto y emitir snapshots --------------------------

# estado de sincronización interno del nodo (lo demás vive en host/game)
var _last_input_seq := 0          # host: último input del cliente aplicado
var _input_seq := 0               # cliente: contador de mis envíos de input
var _prev_p1 := Vector2.INF       # cliente: pos P1 del snapshot anterior
var _last_p1 := Vector2.INF       # cliente: pos P1 del último snapshot
var _snap_ms := 0                 # cliente: reloj de llegada del último snap


@rpc("any_peer", "unreliable")
func net_input(seq: int, h: Dictionary) -> void:
	if not Net.is_host() or host.players.size() < 2:
		return
	# el canal no fiable no ordena: un input VIEJO que llegue tarde no puede
	# pisar uno más nuevo (congelaría a P2 un tick al revés de lo que tocaba)
	if seq <= _last_input_seq:
		return
	_last_input_seq = seq
	host.players[1].net_held = h


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
	host.net_tick += 1
	if host.net_tick % host.NET_SNAP_EVERY != 0:
		return
	var proj := []
	for s in host.projectiles:
		proj.append({
			"x": s.position.x, "y": s.position.y, "vx": s.vel.x, "sp": s.spin,
			"wid": s.weapon_id, "t": s.thrower.player_id if s.thrower != null else 0,
		})
	var ars := []
	for a in host.arrows:
		if not a.stuck:
			ars.append({
				"x": a.position.x, "y": a.position.y, "vx": a.vel.x,
				"h": a.height, "b": a.bounces,
				"t": a.thrower.player_id if a.thrower != null else 0,
			})
	var piks := []
	for pk in host.pickups:
		piks.append({"x": pk.position.x, "y": pk.position.y, "wid": pk.weapon_id})
	net_snap.rpc({
		"ser": host.net_tick,
		"scores": host.scores,
		"rw": host.right_of_way.player_id if host.right_of_way != null else 0,
		"rl": host.round_lock,
		"mo": host.match_over,
		"sd": host.sudden_death,
		"rsp": [host.respawn_timers[0], host.respawn_timers[1]],
		"p1": _net_pack_player(host.players[0]),
		"p2": _net_pack_player(host.players[1]),
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
	if ser <= host.net_last_ser:
		return
	host.net_last_ser = ser
	host.net_last_snap = s
	# buffer de 2 snapshots para la marioneta: el que era último pasa a
	# previo y el reloj arranca ahora (la interpolación vive en _apply_puppet)
	var p1d: Dictionary = s.get("p1", {})
	if not p1d.is_empty():
		var pos := Vector2(float(p1d.get("x", 0.0)), float(p1d.get("y", 0.0)))
		_prev_p1 = _last_p1 if _last_p1 != Vector2.INF else pos
		_last_p1 = pos
		_snap_ms = Time.get_ticks_msec()


# --- cliente: paso por tick de física ---------------------------------------

func _client_step(delta: float) -> void:
	# 1) mi input local (P2) → host, cada tick (no fiable: si llega tarde, se ignora)
	var h := {}
	for a in ["left", "right", "up", "down", "jump", "attack", "throw"]:
		h[a] = Input.is_action_pressed("p2_" + a)
	_input_seq += 1
	net_input.rpc_id(1, _input_seq, h)
	# 2) aplicar el snapshot más reciente y sus efectos derivados
	if not host.net_last_snap.is_empty():
		_client_apply_common()
		for p in host.players:
			p.frozen = host.match_over or host.round_lock > 0.0 or host.net_wait_peer
		_apply_puppet(delta)
		_reconcile_own()
		_client_watch_effects()
	host._update_camera(delta)
	host._update_respawn_bar()


func _client_apply_common() -> void:
	var s = host.net_last_snap
	var sc: Array = s.get("scores", [0, 0])
	if host.scores[0] != int(sc[0]) or host.scores[1] != int(sc[1]):
		host.scores = [int(sc[0]), int(sc[1])]
		host._update_hud()
	var rw_pid := int(s.get("rw", 0))
	var rw: Player = null
	if rw_pid > 0:
		rw = host.players[rw_pid - 1]
	if rw != host.right_of_way:
		host.right_of_way = rw
		if rw != null:
			host._show_step_arrow(rw)
	host.round_lock = float(s.get("rl", 0.0))
	host.match_over = bool(s.get("mo", false))
	host.sudden_death = bool(s.get("sd", false))
	var rsp: Array = s.get("rsp", [0.0, 0.0])
	host.respawn_timers = [float(rsp[0]), float(rsp[1])]
	if host.net_last_ser != host.net_applied_ser:
		host.net_applied_ser = host.net_last_ser
		_sync_net_entities(s)


## El rival (P1) es una marioneta: posición interpolada entre los DOS
## últimos snapshots (uno de retraso, ~50 ms a 20 Hz: se mueve a velocidad
## constante en vez de saltar cada snapshot) y el resto de campos copiados.
func _apply_puppet(delta: float) -> void:
	var rp: Dictionary = host.net_last_snap.get("p1", {})
	if rp.is_empty() or _last_p1 == Vector2.INF:
		return
	var foe = host.players[0]
	var snap_ms := 1000.0 * float(host.NET_SNAP_EVERY) / 60.0
	var alpha := clampf(float(Time.get_ticks_msec() - _snap_ms) / snap_ms, 0.0, 1.0)
	var target := _prev_p1.lerp(_last_p1, alpha)
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
	var lp: Dictionary = host.net_last_snap.get("p2", {})
	if lp.is_empty():
		return
	var me = host.players[1]
	var host_st := int(lp.get("st", me.state))
	if me.state != Player.State.DEAD:
		var target := Vector2(float(lp.get("x", me.position.x)), float(lp.get("y", me.position.y)))
		var d = me.position.distance_to(target)
		if d > 120.0:
			# divergencia grande (derriba, rebote): confiar ciegamente en el host
			me.position = target
			me.velocity = Vector2(float(lp.get("vx", 0.0)), float(lp.get("vy", 0.0)))
		elif d > 3.0:
			me.position = me.position.lerp(target, 0.12)
		if host_st == Player.State.DEAD and not host.net_dead[1]:
			# salvavidas: el ev_kill fiable debería haber llegado antes
			host.net_dead[1] = true
			me.die()
			host.respawn_timers[1] = host.RESPAWN_DELAY
			host._burst(me.position, me.color, 34, 440.0)
			me.has_sword = false
	elif host_st != Player.State.DEAD and host.net_dead[1]:
		# auto-cura: creíamos muertos pero el host ya nos ha reviveído (el
		# ev_respawn fiable y el snapshot no fiable no comparten orden)
		host.net_dead[1] = false
		me.weapon_id = String(lp.get("wid", me.weapon_id))
		me.revive(Vector2(float(lp.get("x", 531.0)), float(lp.get("y", 531.0))), 1 if float(lp.get("vx", 0.0)) >= 0.0 else -1)
	# arma autoritativa (ciclo de reaparición y recogidas del host)
	me.has_sword = bool(lp.get("hs", me.has_sword))
	me.weapon_id = String(lp.get("wid", me.weapon_id))


func _client_watch_effects() -> void:
	if not host.net_had_sd and host.sudden_death:
		host.net_had_sd = true
		host.show_msg("¡MUERTE SÚBITA!", 1.4)
		host.sfx(host.camera.position, "alert", -4.0)
		host.shake_time = maxf(host.shake_time, 0.2)
	if host.net_last_rl > 0.0 and host.round_lock <= 0.0 and not host.match_over:
		host._show_fight()
	host.net_last_rl = host.round_lock


## Reconstrucción de proyectiles/flechas/espadas caídas: son pocos nodos, así
## que se recrean enteros con cada snapshot nuevo y nunca divergen.
func _sync_net_entities(s: Dictionary) -> void:
	for a in host.arrows:
		a.queue_free()
	host.arrows.clear()
	for x in s.get("arrows", []):
		var a := Arrow.new()
		a.process_mode = Node.PROCESS_MODE_PAUSABLE
		a.position = Vector2(float(x["x"]), float(x["y"]))
		a.vel = Vector2(float(x["vx"]), 0.0)
		a.height = int(x["h"])
		a.bounces = int(x["b"])
		var at := int(x["t"])
		a.thrower = host.players[at - 1] if at > 0 else null
		host.add_child(a)
		host.arrows.append(a)
	for spd in host.projectiles:
		spd.queue_free()
	host.projectiles.clear()
	for x in s.get("proj", []):
		var pr := SwordProjectile.new()
		pr.process_mode = Node.PROCESS_MODE_PAUSABLE
		pr.position = Vector2(float(x["x"]), float(x["y"]))
		pr.vel = Vector2(float(x["vx"]), 0.0)
		pr.spin = float(x["sp"])
		pr.weapon_id = String(x["wid"])
		var pt := int(x["t"])
		pr.thrower = host.players[pt - 1] if pt > 0 else null
		host.add_child(pr)
		host.projectiles.append(pr)
	for pk in host.pickups:
		pk.queue_free()
	host.pickups.clear()
	for x in s.get("picks", []):
		var npk := SwordPickup.new()
		npk.process_mode = Node.PROCESS_MODE_PAUSABLE
		npk.weapon_id = String(x["wid"])
		npk.position = Vector2(float(x["x"]), float(x["y"]))
		host.add_child(npk)
		host.pickups.append(npk)


# --- eventos fiables host → cliente ------------------------------------------

@rpc("authority", "reliable")
func ev_round() -> void:
	# espejo local del host._start_round del host
	for k in host.corpses:
		host.corpses[k].queue_free()
	host.corpses.clear()
	for b in host.blood:
		b.queue_free()
	host.blood.clear()
	for tile in host.crumble_tiles:
		tile.restore(self)
	host.right_of_way = null
	host.calm_time = 0.0
	host.sudden_death = false
	host.net_had_sd = false
	host.net_dead = [false, false]
	host.net_wait_peer = false
	host.weapon_idx.resize(host.players.size())
	host.weapon_idx.fill(0)
	for p in host.players:
		p.weapon_id = "florete"
	var offs := [-220.0, 220.0]
	for i in mini(host.players.size(), 2):
		host.players[i].reset_to(Vector2(host.LEVEL_W * 0.5 + offs[i], host.GROUND_Y - 29.0), -1 if offs[i] > 0.0 else 1)
	host.round_lock = host.COUNTDOWN_STEP * 3.0
	host.net_last_rl = host.round_lock


@rpc("authority", "reliable")
func ev_kill(vp: int, kp: int, x: float, y: float, dir: float) -> void:
	if host.net_dead[vp - 1]:
		return
	host.net_dead[vp - 1] = true
	var def = host.players[vp - 1]
	var atk = host.players[kp - 1] if kp > 0 else null
	def.position = Vector2(x, y)
	def.die()
	host.respawn_timers[vp - 1] = host.RESPAWN_DELAY
	host._burst(Vector2(x, y), def.color, 34, 440.0)
	host._burst(Vector2(x, y), Color(0.95, 0.95, 1.0), 12, 260.0)
	host._add_blood(Vector2(x, y), def.color)
	host._spawn_corpse(def, atk)
	if host.corpses.has(vp):
		host.corpses[vp].vel = Vector2(dir * 300.0, -260.0)
		host.corpses[vp].spin = dir * randf_range(2.0, 5.0)
	host.sfx(Vector2(x, y), "kill", -6.0)
	host.crowd_kill_flash = 1.0
	host.shake_time = maxf(host.shake_time, 0.3)


@rpc("authority", "reliable")
func ev_hit(pid: int, kind: int, sx: float, sy: float, st: float) -> void:
	var p = host.players[pid - 1]
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
	var p = host.players[pid - 1]
	if host.corpses.has(pid):
		host.corpses[pid].queue_free()
		host.corpses.erase(pid)
	host.net_dead[pid - 1] = false
	p.weapon_id = wid
	p.revive(Vector2(x, y), face)
	host.sfx(Vector2(x, y), "respawn", -12.0)


@rpc("authority", "reliable")
func ev_point(team_id: int, x: float, y: float) -> void:
	# el marcador llega por snapshot; aquí solo van el fx y el sonido
	host.sfx(Vector2(x, y), "point", -6.0)
	host._burst(Vector2(x, y - 30.0), host.P1_COLOR if team_id == 0 else host.P2_COLOR, 42, 480.0)


@rpc("authority", "reliable")
func ev_match_over(pid: int) -> void:
	host.match_over = true
	host._spawn_worm(host.players[pid - 1])


@rpc("authority", "reliable")
func ev_msg(text: String, dur: float) -> void:
	host.show_msg(text, dur)


@rpc("authority", "reliable")
func ev_sfx(x: float, y: float, id: String, db: float, pitch: float) -> void:
	Sfx.play(self, Vector2(x, y), id, db, pitch)


@rpc("authority", "reliable")
func ev_burst(x: float, y: float, col: Color, amount: int, speed: float) -> void:
	host._burst(Vector2(x, y), col, amount, speed)
