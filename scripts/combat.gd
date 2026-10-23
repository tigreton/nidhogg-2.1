class_name Combat
extends RefCounted
## Resolución de combate (corte 6/7 de la disolución de game.gd): pushbox,
## ataques cuerpo a cuerpo (choque/parada/impacto), divekicks, dives,
## sidekicks, derribos de rodada, empalados contra guardia, stomps, la
## muerte (_kill + cadáver + consecuencias) y la reaparición (posición
## segura, arma rotada, timers). El ESTADO (players, right_of_way, scores,
## respawn_timers, weapon_idx, stats, ...) sigue VIVIENDO en game — el tick
## y el online lo leen: el módulo lo toca vía `host`.
## El feel (hitstop/slowmo/burst) y la replicación ev_* son de game: el
## combate los pide por host y game decide (online: no-op).

var host  # = game.gd


func _init(game) -> void:
	host = game


func _resolve_pushbox() -> void:
	# cuerpo contra cuerpo (pushbox suave): los duelistas no se atraviesan.
	# Cada par solapado se separa medio solape por cabeza, con tope por frame
	# para que empujar se sienta como una pulsación constante, no un teletransporte.
	# Quien embiste (rodada/dive/patadas) cede él: no arrea al rival por delante.
	# Los muertos no ocupan sitio; la marioneta de red no se toca (la coloca el
	# snapshot del host), aunque sí ocupa sitio para el jugador local.
	for i in host.players.size():
		var p = host.players[i]
		if p.state == Player.State.DEAD:
			continue
		for j in range(i + 1, host.players.size()):
			var q = host.players[j]
			if q.state == Player.State.DEAD or host._team(p) == host._team(q):
				continue
			if absf(p.position.y - q.position.y) > host.PUSHBOX_Y:
				continue
			var dx = q.position.x - p.position.x
			var overlap = host.PUSHBOX_W - absf(dx)
			if overlap <= 0.0:
				continue
			var sgn := 1.0 if dx >= 0.0 else -1.0
			if absf(dx) < 0.5:
				sgn = 1.0 if p.player_id < q.player_id else -1.0
			var step := minf(overlap * 0.5, host.PUSHBOX_STEP)
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
	for atk in host.players:
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
		if host.sudden_death and outcome in ["clash", "parry", "miss"]:
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
	for def in host._foes_of(atk):
		if def.state == Player.State.DEAD or def.invuln_time > 0.0:
			continue
		var dx = (def.position.x - atk.position.x) * atk.facing
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
		host._drop_sword(def.position + Vector2(-float(def.facing) * 110.0, -30.0), Color(0.87, 0.9, 0.95), def.weapon_id)
		def.knockdown(push)
		host._net_ev_hit(def, 1, float(push) * 260.0)
		host._burst(def.position + Vector2(0, -20), Color(0.95, 0.95, 1.0), 10, 260.0)
		host.sfx(def.position, "throw", -12.0)
		host.shake_time = maxf(host.shake_time, 0.12)
		host._hitstop(host.HITSTOP_DISARM)
	elif atk.has_sword:
		_kill(def, atk)
	else:
		var push := 1 if def.position.x >= atk.position.x else -1
		if def.has_sword and atk.stance != Player.H.LOW:
			# puñetazo de pie: desarma y aturde
			def.has_sword = false
			host._drop_sword(def.position + Vector2(-float(def.facing) * 110.0, -30.0), Color(0.87, 0.9, 0.95), def.weapon_id)
			def.state = Player.State.STUNNED
			def.stun_time = 0.5
			def.velocity = Vector2(push * 160.0, -120.0)
			host._net_ev_hit(def, 2, float(push) * 160.0, -120.0, 0.5)
			host._burst(def.position + Vector2(0, -20), Color(0.95, 0.95, 1.0), 8, 240.0)
			host.sfx(def.position, "throw", -12.0)
			host._hitstop(host.HITSTOP_DISARM)
		else:
			# patada baja (agachado) o rival ya desarmado: derriba
			def.knockdown(push)
			host._net_ev_hit(def, 1, float(push) * 260.0)
			host._burst(def.position, Color(1, 1, 1), 8, 200.0)
			host.sfx(def.position, "hit", -10.0)
			host._hitstop(host.HITSTOP_KNOCK)


func _clash(a: Player, b: Player) -> void:
	var mid := Vector2((a.position.x + b.position.x) * 0.5, minf(a.position.y, b.position.y) - 14.0)
	host._burst(mid, Color(1.0, 0.93, 0.55), 14, 320.0)
	host.sfx(mid, "clash", -8.0)
	host._hitstop(host.HITSTOP_CLASH)
	host.shake_time = maxf(host.shake_time, 0.14)
	# el choque desarma a quien atacaba con la espada en alto
	var disarmed: Array[Player] = []
	for p in [a, b]:
		if p.state == Player.State.ATTACK and p.attack_height == Player.H.HIGH and p.has_sword:
			disarmed.append(p)
	var push_b := 1 if b.position.x >= a.position.x else -1
	b.take_clash(push_b)
	a.take_clash(-push_b)
	host._net_ev_hit(b, 0, float(push_b) * 380.0)
	host._net_ev_hit(a, 0, -float(push_b) * 380.0)
	for p in disarmed:
		p.has_sword = false
		host._drop_sword(p.position + Vector2(-float(p.facing) * 110.0, -30.0), Color(0.87, 0.9, 0.95), p.weapon_id)
		host._burst(p.position + Vector2(0, -20), Color(0.95, 0.95, 1.0), 8, 240.0)
		host.sfx(p.position, "throw", -14.0)


func _parry(a: Player, b: Player) -> void:
	# parada blanda: nadie muere, nadie se aturde; rebote de separación y chispa
	var mid := Vector2((a.position.x + b.position.x) * 0.5, minf(a.position.y, b.position.y) - 14.0)
	host._burst(mid, Color(1.0, 0.93, 0.55), 8, 240.0)
	host.sfx(mid, "clash", -12.0)
	host._hitstop(host.HITSTOP_PARRY)
	var push_b := 1 if b.position.x >= a.position.x else -1
	a.apply_push(Vector2(-float(push_b) * host.PARRY_IMPULSE, 0.0), host.PARRY_PUSH_TIME)
	b.apply_push(Vector2(float(push_b) * host.PARRY_IMPULSE, 0.0), host.PARRY_PUSH_TIME)
	host._net_ev_hit(a, 3, -float(push_b) * host.PARRY_IMPULSE, 0.0, host.PARRY_PUSH_TIME)
	host._net_ev_hit(b, 3, float(push_b) * host.PARRY_IMPULSE, 0.0, host.PARRY_PUSH_TIME)
	host.parry_cd = host.PARRY_COOLDOWN


func _resolve_divekicks() -> void:
	for p in host.players:
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
			host._net_ev_hit(def, 1, float(push) * 260.0)
			# la patada voladora hace soltar el arma a su víctima (lejos de ella)
			if def.has_sword:
				def.has_sword = false
				host._drop_sword(def.position + Vector2(-float(def.facing) * 110.0, -30.0), Color(0.87, 0.9, 0.95), def.weapon_id)
			p.state = Player.State.JUMP
			p.velocity = Vector2(-p.facing * 210.0, -440.0)
			host._net_ev_hit(p, 5, -float(p.facing) * 210.0, -440.0)
			host._burst(def.position, Color(1, 1, 1), 10, 240.0)
			host.sfx(def.position, "hit", -10.0)
			host.shake_time = maxf(host.shake_time, 0.12)
			host._hitstop(host.HITSTOP_KNOCK)


func _nearest_divekick_target(p: Player) -> Player:
	var best: Player = null
	var bd := INF
	for def in host._foes_of(p):
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
	for p in host.players:
		if p.state != Player.State.DIVE or p.dive_resolved:
			continue
		for def in host._foes_of(p):
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
				host._net_ev_hit(def, 1, float(push) * 260.0)
				host._hitstop(host.HITSTOP_KNOCK)
			p.state = Player.State.KNOCKDOWN
			p.knockdown_time = 0.6
			p.velocity = Vector2(-float(p.facing) * 160.0, -160.0)
			host._net_ev_hit(p, 4, -float(p.facing) * 160.0, -160.0, 0.6)
			host.shake_time = maxf(host.shake_time, 0.14)
			break


func _resolve_sidekicks() -> void:
	for p in host.players:
		if p.state != Player.State.SIDEKICK or p.sidekick_resolved:
			continue
		for def in host._foes_of(p):
			if def.state == Player.State.DEAD or def.invuln_time > 0.0:
				continue
			if absf(def.position.x - p.position.x) > 42.0 or absf(def.position.y - p.position.y) > 56.0:
				continue
			p.sidekick_resolved = true
			var push := 1 if def.position.x >= p.position.x else -1
			def.knockdown(push)
			host._net_ev_hit(def, 1, float(push) * 260.0)
			if def.has_sword:
				def.has_sword = false
				# el arma sale despedida lejos: si no, el caído la recogería al instante
				host._drop_sword(def.position + Vector2(-float(def.facing) * 110.0, -30.0), Color(0.87, 0.9, 0.95), def.weapon_id)
			p.state = Player.State.JUMP
			p.velocity = Vector2(-p.facing * 210.0, -440.0)
			host._net_ev_hit(p, 5, -float(p.facing) * 210.0, -440.0)
			host._burst(def.position, Color(1, 1, 1), 10, 240.0)
			host.sfx(def.position, "hit", -10.0)
			host.shake_time = maxf(host.shake_time, 0.12)
			host._hitstop(host.HITSTOP_KNOCK)
			break


func _resolve_roll_tackles() -> void:
	# slide tackle: atacar durante la rodada derriba (no mata) al rival cercano
	for p in host.players:
		if p.state != Player.State.ROLL or p.roll_hit:
			continue
		if not p.held("attack"):
			continue
		for def in host._foes_of(p):
			if def.state == Player.State.DEAD or def.invuln_time > 0.0:
				continue
			if absf(def.position.x - p.position.x) > Player.PUNCH_RANGE + 24.0 or absf(def.position.y - p.position.y) > 50.0:
				continue
			p.roll_hit = true
			var push := 1 if def.position.x >= p.position.x else -1
			def.knockdown(push)
			host._net_ev_hit(def, 1, float(push) * 260.0)
			host._burst(def.position, Color(1, 1, 1), 8, 200.0)
			host.sfx(def.position, "hit", -10.0)
			host.shake_time = maxf(host.shake_time, 0.1)
			host._hitstop(host.HITSTOP_KNOCK)
			break


func _resolve_guard_impale() -> void:
	# guardia pasiva: solo de pie y parado (correr no guarda)
	for g in host.players:
		if g.state != Player.State.IDLE or not g.has_sword or g.invuln_time > 0.0:
			continue
		if g.weapon_id == "arco":
			# el arco no empala: no tiene hoja (tarea 24)
			continue
		for f in host._foes_of(g):
			if f.state == Player.State.DEAD or f.invuln_time > 0.0:
				continue
			if f.attack_is_active():
				continue
			# el dive, el sidekick y la rodada tienen su propia resolución (tareas 34/35/45)
			if f.state in [Player.State.DIVE, Player.State.SIDEKICK, Player.State.ROLL]:
				continue
			var dx = (f.position.x - g.position.x) * g.facing
			if dx < 8.0 or dx > Player.ATTACK_RANGE * 0.85:
				continue
			if absf(f.position.y - g.position.y) > 56.0:
				continue
			# solo empala a quien se mueve HACIA la guardia (o cae sobre ella)
			var hacia = f.velocity.x * -float(g.facing) > 140.0
			if not hacia:
				continue
			if f.stance == g.stance:
				if host.sudden_death:
					_kill(f, g)   # en muerte súbita el rebote también mata (tarea 67)
					return
				if host.parry_cd > 0.0:
					continue
				# rebote mínimo: ambos se separan sin stun ni desarme
				f.apply_push(Vector2(-float(f.facing) * host.CLASH_IMPULSE, 0.0), host.CLASH_PUSH_TIME)
				g.apply_push(Vector2(-float(g.facing) * host.CLASH_IMPULSE, 0.0), host.CLASH_PUSH_TIME)
				host._net_ev_hit(f, 3, -float(f.facing) * host.CLASH_IMPULSE, 0.0, host.CLASH_PUSH_TIME)
				host._net_ev_hit(g, 3, -float(g.facing) * host.CLASH_IMPULSE, 0.0, host.CLASH_PUSH_TIME)
				var mid := Vector2((f.position.x + g.position.x) * 0.5, minf(f.position.y, g.position.y) - 14.0)
				host._burst(mid, Color(1.0, 0.93, 0.55), 6, 200.0)
				host.sfx(mid, "clash", -14.0)
				host._hitstop(host.HITSTOP_PARRY)
				host.parry_cd = host.PARRY_COOLDOWN
			else:
				_kill(f, g)
			return


func _resolve_stomps() -> void:
	for p in host.players:
		if p.state not in [Player.State.IDLE, Player.State.RUN] or not p.is_on_floor():
			continue
		if not p.held("down"):
			continue
		for def in host._foes_of(p):
			if def.state != Player.State.KNOCKDOWN or def.invuln_time > 0.0:
				continue
			if absf(def.position.x - p.position.x) > 34.0 or absf(def.position.y - p.position.y) > 50.0:
				continue
			# pisotón letal: el derribado estalla; el ejecutor, invulnerable (tarea 76)
			host._burst(def.position, def.color, 60, 560.0)
			p.invuln_time = maxf(p.invuln_time, 0.4)
			_kill(def, p)
			host.shake_time = maxf(host.shake_time, 0.2)
			break


func _kill(def: Player, atk: Player) -> void:
	if def.state == Player.State.DEAD:
		return
	var was_sudden = host.sudden_death
	host.calm_time = 0.0        # cualquier muerte apaga la muerte súbita (tarea 67)
	host.sudden_death = false
	def.die()
	host.stats[def.player_id - 1]["deaths"] += 1
	if atk != null:
		host.stats[atk.player_id - 1]["kills"] += 1
	host._hitstop(0.08)
	host.respawn_timers[def.player_id - 1] = host.RESPAWN_DELAY
	if Net.is_host() and Net.client_ready:
		var dir := -float(def.facing)
		if atk != null:
			var d2 := signf(def.position.x - atk.position.x)
			if d2 != 0.0:
				dir = d2
		host.net_sync.ev_kill.rpc(def.player_id, atk.player_id if atk != null else 0, def.position.x, def.position.y, dir)
	host._burst(def.position, def.color, 34, 440.0)
	host._add_blood(def.position, def.color)
	if def.has_sword:
		def.has_sword = false
		host._drop_sword(def.position + Vector2(0.0, -20.0), Color(0.87, 0.9, 0.95), def.weapon_id)
	# la cámara lenta ya no acompaña cada muerte: solo cuando esa baja decide
	# (muerte súbita). El hitstop del contacto la sustituye en el día a día.
	if was_sudden:
		host._slowmo(0.35, 0.5)
	host._burst(def.position, Color(0.95, 0.95, 1.0), 12, 260.0)
	_spawn_corpse(def, atk)
	host.sfx(def.position, "kill", -6.0)
	host.crowd_kill_flash = 1.0   # el público responde a la baja (tarea 68)
	host.shake_time = maxf(host.shake_time, 0.3)
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
	host.add_child(c)
	host.corpses[def.player_id] = c


func _after_death(def: Player, atk: Player) -> void:
	# el asesino toma el paso; si la muerte es del entorno, el compañero
	# hereda el paso del portador caído (o lo gana el último vivo en 1v1)
	if atk != null and atk.state != Player.State.DEAD:
		host.right_of_way = atk
		host._show_step_arrow(atk)
		return
	if host.right_of_way == def:
		var mate = host._living_teammate(def)
		if mate != null:
			host.right_of_way = mate
			host._show_step_arrow(mate)
			return
		host.right_of_way = null
	var alive := 0
	var last: Player = null
	for p in host.players:
		if p.state != Player.State.DEAD:
			alive += 1
			last = p
	if alive == 1 and host.right_of_way == null:
		host.right_of_way = last


func _respawn(p: Player) -> void:
	if p.state != Player.State.DEAD:
		return
	if host.corpses.has(p.player_id):
		host.corpses[p.player_id].queue_free()
		host.corpses.erase(p.player_id)
	var pos := _respawn_pos(p)
	var face := 1
	if host.right_of_way != null:
		face = 1 if host.right_of_way.position.x > pos.x else -1
	else:
		face = 1 if pos.x < host.LEVEL_W * 0.5 else -1
	p.weapon_id = _next_weapon(p)
	p.revive(pos, face)
	host.sfx(pos, "respawn", -12.0)
	if Net.is_host() and Net.client_ready:
		host.net_sync.ev_respawn.rpc(p.player_id, pos.x, pos.y, face, p.weapon_id)


func _next_weapon(p: Player) -> String:
	# por defecto el arma es siempre la misma: los timing aprendidos valen
	# de por vida. El ciclo (espadón/daga/arco) queda como modo alternativo.
	if not MatchRules.weapon_variety:
		return "florete"
	var i := p.player_id - 1
	if i < 0 or i >= host.weapon_idx.size():
		return "florete"
	host.weapon_idx[i] = (host.weapon_idx[i] + 1) % GameConfig.WEAPON_ORDER.size()
	return GameConfig.WEAPON_ORDER[host.weapon_idx[i]]


func _respawn_pos(p: Player) -> Vector2:
	if host.right_of_way == null:
		var offs := [220.0, -220.0, 620.0, -620.0]
		var fx := clampf(host._spawn_safe(host.LEVEL_W * 0.5 + offs[p.player_id - 1]), host.GOAL_W + 60.0, host.LEVEL_W - host.GOAL_W - 60.0)
		return Vector2(fx, 200.0)
	if host.sections_mode:
		var w = host.LEVEL_W / float(host.SECTION_COUNT)
		var sdir := 1 if host.right_of_way.goal_dir > 0 else -1
		var sec := clampi(host.section_index + sdir, 0, host.SECTION_COUNT - 1)
		var cx = w * (float(sec) + 0.5)
		if sec == host.section_index:
			# ya no hay sección delante: reaparece al fondo de la actual
			cx = w * float(sec + 1) - 100.0 if sdir > 0 else w * float(sec) + 100.0
		return Vector2(host._spawn_safe(cx), 200.0)
	var dir := float(host.right_of_way.goal_dir)
	var x = host.right_of_way.position.x + dir * 540.0
	x = clampf(x, host.GOAL_W + 60.0, host.LEVEL_W - host.GOAL_W - 60.0)
	x = host._spawn_safe(x)
	return Vector2(x, 200.0)

