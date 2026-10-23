class_name BotBrain
extends RefCounted
## IA de los duelistas (corte 4/7 de la disolución de game.gd): percibir ->
## puntuar -> elegir, con capas duras (torre, foso, divekick, arco), castigo
## y memoria de patrones. La MEMORIA (_bot_mem, _bot_last_throw,
## _bot_feint_until) vive AQUÍ: es estado puro de IA y nadie más lo toca —
## las tareas de IA futuras caen en este archivo, no en game.gd.
## El resto del estado (players, terreno, marcador, right_of_way) es de
## game y se lee vía `host`.

var host  # = game.gd


func _init(game) -> void:
	host = game


func _bot_cfg(p: Player) -> Dictionary:
	var lvl: int = host.bot_level
	if p.player_id == 1 or p.player_id == 3:
		lvl = maxi(host.ally_bot_level, 1)
	var c: Dictionary = host.BOT_CFG[lvl - 1].duplicate()
	c["lvl"] = lvl
	return c


# =============================================================================
# IA: percibir → puntuar → elegir
# =============================================================================
# El tick de reacción por nivel (bot_think/host.BOT_CFG) no cambia. Lo que era una
# cadena de if/elif se descompone en tres dimensiones puntuadas con términos
# aditivos (movimiento, estancia, tap) más capas duras que no se negocian
# (salto de muro, divekick, arco, levantarse). Los sorteos randf()/randi()
# viven en _bot_scores, dentro de cada rama en el mismo orden que la cadena
# original: la equivalencia del esqueleto se probó con la semilla fija del
# sim (trayectoria idéntica tic a tic, 83,2 s); los términos nuevos
# (predicción, castigo, memoria de patrones) son la única divergencia, y es
# buscada.

func _bot_think(p: Player, delta: float) -> void:
	var foe: Player = host._nearest_foe(p)
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
## sim de la host.arena 0 mantiene su trayectoria tic a tic).
func _bot_tower_floor(p: Player, foe: Player, ctx: Dictionary) -> bool:
	if host.arena_id != 3 or String(ctx["role"]) == "run":
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
	for q in host.players:
		var m: Dictionary = _bot_mem.get_or_add(q.player_id,
				{"air": false, "was_atk": false, "was_roll": false, "land_ms": 0,
				"roll_end_ms": 0, "last_atk_ms": 0,
				"after_land": {}, "after_roll": {}, "heights": {}, "gaps": []})
		var air: bool = not q.is_on_floor()
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
	var row_team: int = -1 if host.right_of_way == null else host._team(host.right_of_way)
	var role := "duel"
	if host.right_of_way != null and row_team == host._team(p):
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
		var lead: float = host.right_of_way.velocity.x * 0.5
		if absf(host.right_of_way.velocity.x) < 80.0:
			lead = float(host.right_of_way.goal_dir) * 100.0
		target_x = host.right_of_way.position.x + lead
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
		"on_ice": host.in_ice(p.position.x),
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
	return p.position.x > host.PLAT_X0 - 130.0 and p.position.x < host.PLAT_X1 + 130.0 \
			and not (p.position.x > host.PLAT_X0 + 40.0 and p.position.x < host.PLAT_X1 - 40.0)


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
	if want_r and p.position.x > host.PIT2_X0 - 45.0 and p.position.x < host.PIT2_X0 + 25.0:
		p.bot_held["jump"] = true
	elif want_l and p.position.x > host.PIT2_X1 - 10.0 and p.position.x < host.PIT2_X1 + 45.0:
		p.bot_held["jump"] = true

