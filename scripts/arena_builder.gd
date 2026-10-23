class_name ArenaBuilder
extends RefCounted
## Construcción de arenas y terreno (corte 2/7 de la disolución de game.gd).
## La GEOMETRÍA, la PALETA y las listas (_tops, goal_polys, crumble_tiles,
## _belt_arrows) siguen VIVIENDO en game: tests, bots, HUD y entidades las
## leen como game.PIT_X0 / game.PLAT_X0 / ... — el builder solo las lee y
## escribe a través de `host` (mismo patrón `host.` de las entidades).

var host  # = game.gd (sin tipar: despacho dinámico de miembros del host)


func _init(game) -> void:
	host = game


func _rebuild_level() -> void:
	# común a set_arena y _reshuffle_level: tira el nivel actual y lo rehace
	if host.parallax_bg != null:
		host.parallax_bg.queue_free()
		host.parallax_bg = null
	if host.level_root != null:
		host.level_root.queue_free()
	host.level_root = Node2D.new()
	host.level_root.process_mode = Node.PROCESS_MODE_PAUSABLE
	host.add_child(host.level_root)
	host.goal_polys.clear()
	host._tops.clear()
	host.blood.clear()
	host.crumble_tiles.clear()
	_build_level()


func _parallax_layer(pb: ParallaxBackground, asset: String, motion: float, tint: Color) -> ParallaxLayer:
	# capa de fondo repetida: textura 960x540 escalada a viewport y espejada
	var l := ParallaxLayer.new()
	l.motion_scale = Vector2(motion, motion)
	var s := Sprite2D.new()
	s.texture = ArtPack.tex(asset)
	s.centered = false
	s.scale = Vector2(1152.0 / 960.0, 648.0 / 540.0)
	s.modulate = tint
	l.motion_mirroring = Vector2(1152.0, 0.0)
	l.add_child(s)
	pb.add_child(l)
	return l


func _build_parallax() -> void:
	host.parallax_bg = ParallaxBackground.new()
	host.parallax_bg.layer = -20
	host.add_child(host.parallax_bg)
	_parallax_layer(host.parallax_bg, "bg_layer0", 0.15, host.bg_tint_far)
	_parallax_layer(host.parallax_bg, "bg_layer1", 0.4, host.bg_tint_near)


func _build_level() -> void:
	_build_parallax()
	_poly(_circle_points(host.cel_pos.x, host.cel_pos.y, 74.0), host.cel_col, -9)
	_poly(_circle_points(host.cel_pos.x - 30.0, host.cel_pos.y - 26.0, 13.0), host.cel_detail, -9)
	_poly(_circle_points(host.cel_pos.x + 26.0, host.cel_pos.y + 32.0, 9.0), host.cel_detail, -9)
	_hills()
	_clouds()
	var px := 340.0
	while px < host.LEVEL_W - 200.0:
		if not (px > host.PIT_X0 - 130.0 and px < host.PIT_X1 + 130.0):
			_poly(PackedVector2Array([Vector2(px - 26, host.GROUND_Y), Vector2(px + 26, host.GROUND_Y), Vector2(px + 26, 130.0), Vector2(px - 26, 130.0)]), host.col_pillar, -5)
			_poly(PackedVector2Array([Vector2(px - 36, 142.0), Vector2(px + 36, 142.0), Vector2(px + 36, 122.0), Vector2(px - 36, 122.0)]), host.col_pillar_cap, -5)
		px += 640.0
	# suelo entre los fosos, ordenados por posición (valgan donde valgan)
	var pits := [[host.PIT_X0, host.PIT_X1], [host.PIT2_X0, host.PIT2_X1]]
	pits.sort_custom(func(u, v): return u[0] < v[0])
	var seg_a := 0.0
	for b in pits:
		_floor_segment(seg_a, b[0])
		seg_a = b[1]
	_floor_segment(seg_a, host.LEVEL_W)
	_poly(PackedVector2Array([Vector2(host.PIT_X0, host.GROUND_Y + 4), Vector2(host.PIT_X1, host.GROUND_Y + 4), Vector2(host.PIT_X1 - 26, 800.0), Vector2(host.PIT_X0 + 26, 800.0)]), host.col_pit, -6)
	_poly(PackedVector2Array([Vector2(host.PIT2_X0, host.GROUND_Y + 4), Vector2(host.PIT2_X1, host.GROUND_Y + 4), Vector2(host.PIT2_X1 - 26, 800.0), Vector2(host.PIT2_X0 + 26, 800.0)]), host.col_pit, -6)
	_pit_edges(host.PIT_X0, host.PIT_X1)
	_pit_edges(host.PIT2_X0, host.PIT2_X1)
	# crumble bridge (tarea 70): 4 tramos sobre el foso en vez de plataforma fija
	_make_crumbles()
	if host.arena_id != 3:
		# el puente alto de madera pisaría el piso superior de la torre
		_bridge()
	_house()
	_rocks_zone()
	if host.arena_id == 3:
		_tower_floor()
	_draw_grass()
	_draw_ice()
	_draw_belt()
	_ladder(host.LADDER_X)
	_wall(-46.0, 6.0)
	_wall(host.LEVEL_W - 6.0, host.LEVEL_W + 46.0)
	_goal_zone(host.LEVEL_W - host.GOAL_W, host.LEVEL_W, host.P1_COLOR)
	_goal_zone(0.0, host.GOAL_W, host.P2_COLOR)
	_torch_at(210.0)
	_torch_at(host.LEVEL_W - 210.0)
	_torch_at(host.HOUSE_X + 124.0)
	_fence(host.FENCE_X0, host.FENCE_X1)
	if host.arena_id == 2 and not host._shuffled:
		# velas y lápidas van en x fijas: fuera de la arena barajada
		_candles()
		_tombstones()


func _make_crumbles() -> void:
	host.crumble_tiles.clear()
	var tw: float = (host.PLAT_X1 - host.PLAT_X0) / 4.0
	for k in 4:
		var tile := CrumbleTile.new(host.PLAT_X0 + tw * float(k), host.PLAT_X0 + tw * (float(k) + 1.0), host.PLAT_Y)
		tile.z_index = -4
		host._register_top(tile.x0, tile.x1, host.PLAT_Y)
		_add_level(tile)
		host.crumble_tiles.append(tile)


func _draw_grass() -> void:
	# hierba alta: oculta la estancia de quien entra
	_poly(PackedVector2Array([Vector2(host.GRASS_X0, host.GROUND_Y), Vector2(host.GRASS_X1, host.GROUND_Y), Vector2(host.GRASS_X1, host.GROUND_Y - 34.0), Vector2(host.GRASS_X0, host.GROUND_Y - 34.0)]), Color(0.09, 0.18, 0.11), 2)
	for i in 22:
		var gx: float = host.GRASS_X0 + (host.GRASS_X1 - host.GRASS_X0) * (float(i) + 0.5) / 22.0
		var gh := 44.0 + 20.0 * randf()
		_poly(PackedVector2Array([Vector2(gx - 7, host.GROUND_Y), Vector2(gx + 7, host.GROUND_Y), Vector2(gx + randf_range(-7.0, 7.0), host.GROUND_Y - gh)]), Color(0.13, 0.30, 0.17).lightened(0.08 * randf()), 3)
	_flowers()


func _draw_ice() -> void:
	# franja de hielo (tarea 69): tinte azulado brillante sobre los tiles
	_poly(PackedVector2Array([Vector2(host.ICE_X0, host.GROUND_Y), Vector2(host.ICE_X1, host.GROUND_Y), Vector2(host.ICE_X1, host.GROUND_Y - 5.0), Vector2(host.ICE_X0, host.GROUND_Y - 5.0)]), Color(0.62, 0.78, 0.95, 0.45), 2)


func _draw_belt() -> void:
	# cinta transportadora (tarea 71): base más oscura + flechas que derivan
	_poly(PackedVector2Array([Vector2(host.BELT_X0, host.GROUND_Y), Vector2(host.BELT_X1, host.GROUND_Y), Vector2(host.BELT_X1, host.GROUND_Y - 4.0), Vector2(host.BELT_X0, host.GROUND_Y - 4.0)]), Color(0.1, 0.09, 0.14, 0.85), 2)
	host._belt_arrows.clear()
	for k in 4:
		var bx: float = host.BELT_X0 + 40.0 + k * 40.0
		host._belt_arrows.append(_poly(PackedVector2Array([Vector2(bx, host.GROUND_Y - 10.0), Vector2(bx + 16.0, host.GROUND_Y - 10.0), Vector2(bx + 16.0, host.GROUND_Y - 14.0), Vector2(bx + 26.0, host.GROUND_Y - 8.0), Vector2(bx + 16.0, host.GROUND_Y - 2.0), Vector2(bx + 16.0, host.GROUND_Y - 6.0), Vector2(bx, host.GROUND_Y - 6.0)]), Color(0.42, 0.4, 0.5), 3))


func _ladder(x0: float) -> void:
	# escalera de plataformas (subida a la ruta alta)
	_platform(x0, x0 + 180.0, 448.0)
	_platform(x0 + 180.0, x0 + 320.0, 368.0)
	_platform(x0 + 320.0, x0 + 420.0, 288.0)


func _load_arena(id: int) -> void:
	host.arena_id = id % host.ARENA_NAMES.size()
	match host.arena_id:
		1:
			# Templo del alba: amanecer cálido, rocas y torre a la izquierda,
			# foso pequeño y casa junto a la meta derecha
			host.PIT_X0 = 2210.0
			host.PIT_X1 = 2380.0
			host.PIT2_X0 = 3050.0
			host.PIT2_X1 = 3230.0
			host.PLAT_X0 = 2130.0
			host.PLAT_X1 = 2460.0
			host.PLAT_Y = 448.0
			host.BRIDGE_X0 = 1900.0
			host.BRIDGE_X1 = 2690.0
			host.BRIDGE_Y = 288.0
			host.HOUSE_X = 3850.0
			host.STEP_R_X0 = 2740.0
			host.STEP_R_X1 = 2832.0
			host.STEP_R_Y = 516.0
			host.BOULDER_X0 = 380.0
			host.BOULDER_X1 = 608.0
			host.BOULDER_Y = 440.0
			host.TOWER_X0 = 700.0
			host.TOWER_X1 = 868.0
			host.TOWER_Y = 330.0
			host.STEP_L_X0 = 4180.0
			host.STEP_L_X1 = 4272.0
			host.STEP_L_Y = 516.0
			host.FENCE_X0 = 940.0
			host.FENCE_X1 = 1030.0
			host.col_sky = Color(0.16, 0.09, 0.105)
			host.col_hill_far = Color(0.215, 0.115, 0.115)
			host.col_hill_near = Color(0.175, 0.095, 0.10)
			host.col_pillar = Color(0.15, 0.10, 0.10)
			host.col_pillar_cap = Color(0.19, 0.13, 0.12)
			host.col_pit = Color(0.42, 0.12, 0.06)
			host.col_floor = Color(0.235, 0.16, 0.13)
			host.col_floor_top = Color(0.47, 0.33, 0.24)
			host.col_plat = Color(0.31, 0.21, 0.16)
			host.col_plat_top = Color(0.52, 0.37, 0.26)
			host.col_wall = Color(0.20, 0.14, 0.12)
			host.cel_pos = Vector2(3560.0, 120.0)
			host.cel_col = Color(0.55, 0.32, 0.16)
			host.cel_detail = Color(0.48, 0.27, 0.13)
			host.bg_tint_far = Color(1.0, 0.72, 0.5)
			host.bg_tint_near = Color(1.0, 0.85, 0.68)
		2:
			# Cripta del ocaso: atardecer púrpura, torre a la izquierda,
			# casa a la derecha y foso pequeño junto a la meta de P1
			host.PIT_X0 = 2210.0
			host.PIT_X1 = 2380.0
			host.PIT2_X0 = 3620.0
			host.PIT2_X1 = 3800.0
			host.PLAT_X0 = 2130.0
			host.PLAT_X1 = 2460.0
			host.PLAT_Y = 448.0
			host.BRIDGE_X0 = 1900.0
			host.BRIDGE_X1 = 2690.0
			host.BRIDGE_Y = 288.0
			host.HOUSE_X = 3850.0
			host.STEP_R_X0 = 1550.0
			host.STEP_R_X1 = 1642.0
			host.STEP_R_Y = 516.0
			host.BOULDER_X0 = 3050.0
			host.BOULDER_X1 = 3278.0
			host.BOULDER_Y = 440.0
			host.TOWER_X0 = 380.0
			host.TOWER_X1 = 548.0
			host.TOWER_Y = 330.0
			host.STEP_L_X0 = 4180.0
			host.STEP_L_X1 = 4272.0
			host.STEP_L_Y = 516.0
			host.FENCE_X0 = 940.0
			host.FENCE_X1 = 1030.0
			host.col_sky = Color(0.10, 0.06, 0.13)
			host.col_hill_far = Color(0.14, 0.08, 0.16)
			host.col_hill_near = Color(0.11, 0.07, 0.13)
			host.col_pillar = Color(0.13, 0.10, 0.15)
			host.col_pillar_cap = Color(0.17, 0.13, 0.19)
			host.col_pit = Color(0.16, 0.05, 0.14)
			host.col_floor = Color(0.16, 0.13, 0.18)
			host.col_floor_top = Color(0.34, 0.28, 0.38)
			host.col_plat = Color(0.22, 0.18, 0.26)
			host.col_plat_top = Color(0.38, 0.32, 0.44)
			host.col_wall = Color(0.15, 0.11, 0.17)
			host.cel_pos = Vector2(1200.0, 130.0)
			host.cel_col = Color(0.75, 0.45, 0.30)
			host.cel_detail = Color(0.66, 0.38, 0.26)
			host.bg_tint_far = Color(0.68, 0.5, 0.9)
			host.bg_tint_near = Color(0.85, 0.68, 0.95)
		3:
			# Torre del Centinela (tarea 85): pasillo inferior clásico y piso
			# superior corrido (y=320) con dos huecos; el foso central queda
			# a cielo abierto para no pisar el salto al puente
			host.PIT_X0 = 2210.0
			host.PIT_X1 = 2380.0
			host.PIT2_X0 = 1450.0
			host.PIT2_X1 = 1630.0
			host.PLAT_X0 = 2130.0
			host.PLAT_X1 = 2460.0
			host.PLAT_Y = 448.0
			host.BRIDGE_X0 = 1900.0
			host.BRIDGE_X1 = 2690.0
			host.BRIDGE_Y = 288.0
			host.HOUSE_X = 4150.0
			host.STEP_R_X0 = 3760.0
			host.STEP_R_X1 = 3852.0
			host.STEP_R_Y = 516.0
			host.BOULDER_X0 = 380.0
			host.BOULDER_X1 = 608.0
			host.BOULDER_Y = 440.0
			host.TOWER_X0 = 3476.0
			host.TOWER_X1 = 3644.0
			host.TOWER_Y = 330.0
			host.STEP_L_X0 = 340.0
			host.STEP_L_X1 = 432.0
			host.STEP_L_Y = 516.0
			host.FENCE_X0 = 940.0
			host.FENCE_X1 = 1030.0
			host.col_sky = Color(0.03, 0.06, 0.07)
			host.col_hill_far = Color(0.05, 0.10, 0.11)
			host.col_hill_near = Color(0.045, 0.085, 0.095)
			host.col_pillar = Color(0.07, 0.12, 0.13)
			host.col_pillar_cap = Color(0.10, 0.16, 0.17)
			host.col_pit = Color(0.07, 0.20, 0.18)
			host.col_floor = Color(0.10, 0.17, 0.18)
			host.col_floor_top = Color(0.24, 0.38, 0.38)
			host.col_plat = Color(0.14, 0.24, 0.25)
			host.col_plat_top = Color(0.28, 0.44, 0.44)
			host.col_wall = Color(0.08, 0.14, 0.15)
			host.cel_pos = Vector2(2400.0, 110.0)
			host.cel_col = Color(0.65, 0.85, 0.80)
			host.cel_detail = Color(0.50, 0.70, 0.66)
			host.bg_tint_far = Color(0.60, 0.85, 0.80)
			host.bg_tint_near = Color(0.80, 0.95, 0.90)
		_:
			# Ruinas de medianoche: noche azulada con luna (valores por defecto)
			host.PIT_X0 = 2210.0
			host.PIT_X1 = 2380.0
			host.PIT2_X0 = 700.0
			host.PIT2_X1 = 880.0
			host.PLAT_X0 = 2130.0
			host.PLAT_X1 = 2460.0
			host.PLAT_Y = 448.0
			host.BRIDGE_X0 = 1900.0
			host.BRIDGE_X1 = 2690.0
			host.BRIDGE_Y = 288.0
			host.HOUSE_X = 908.0
			host.STEP_R_X0 = 2856.0
			host.STEP_R_X1 = 2948.0
			host.STEP_R_Y = 516.0
			host.BOULDER_X0 = 3116.0
			host.BOULDER_X1 = 3344.0
			host.BOULDER_Y = 440.0
			host.TOWER_X0 = 3476.0
			host.TOWER_X1 = 3644.0
			host.TOWER_Y = 330.0
			host.STEP_L_X0 = 500.0
			host.STEP_L_X1 = 592.0
			host.STEP_L_Y = 516.0
			host.FENCE_X0 = 600.0
			host.FENCE_X1 = 690.0
			host.col_sky = Color(0.055, 0.05, 0.09)
			host.col_hill_far = Color(0.075, 0.068, 0.115)
			host.col_hill_near = Color(0.065, 0.06, 0.10)
			host.col_pillar = Color(0.085, 0.08, 0.135)
			host.col_pillar_cap = Color(0.11, 0.10, 0.17)
			host.col_pit = Color(0.30, 0.07, 0.09)
			host.col_floor = Color(0.14, 0.13, 0.19)
			host.col_floor_top = Color(0.30, 0.27, 0.37)
			host.col_plat = Color(0.20, 0.18, 0.27)
			host.col_plat_top = Color(0.34, 0.31, 0.42)
			host.col_wall = Color(0.11, 0.10, 0.16)
			host.cel_pos = Vector2(2400.0, 118.0)
			host.cel_col = Color(0.14, 0.13, 0.20)
			host.cel_detail = Color(0.10, 0.09, 0.15)
			host.bg_tint_far = Color(0.55, 0.62, 0.85)
			host.bg_tint_near = Color(0.72, 0.74, 0.92)
	# hazards y escalera a sus posiciones por defecto (la barajada los mueve)
	host.GRASS_X0 = 1150.0
	host.GRASS_X1 = 1450.0
	host.ICE_X0 = 1700.0
	host.ICE_X1 = 2000.0
	host.BELT_X0 = 2500.0
	host.BELT_X1 = 2650.0
	host.LADDER_X = 1480.0
	host._shuffled = false
	# tejados derivados del anclaje de la casa
	_derive_roofs()


func _derive_roofs() -> void:
	host.ROOF_L_X0 = host.HOUSE_X
	host.ROOF_L_X1 = host.HOUSE_X + 102.0
	host.ROOF_L_Y = 472.0
	host.ROOF_H_X0 = host.HOUSE_X + 112.0
	host.ROOF_H_X1 = host.HOUSE_X + 244.0
	host.ROOF_H_Y = 406.0


func _random_layout() -> void:
	# baraja los seis tramos del medio entre las dos bocas de meta y fija
	# las estructuras grandes en las bocas (metas siempre en los extremos)
	_load_arena(host.arena_id)   # paleta y valores por defecto como base
	host._shuffled = true
	# boca izquierda: meta + peldaño + valla + casa con tejado
	host.STEP_L_X0 = 200.0
	host.STEP_L_X1 = 292.0
	host.STEP_L_Y = 516.0
	host.FENCE_X0 = 330.0
	host.FENCE_X1 = 420.0
	host.HOUSE_X = 500.0
	_derive_roofs()
	# boca derecha: meta + peldaño + peñasco + torre de piedra
	host.STEP_R_X0 = 4070.0
	host.STEP_R_X1 = 4162.0
	host.STEP_R_Y = 516.0
	host.BOULDER_X0 = 4180.0
	host.BOULDER_X1 = 4408.0
	host.BOULDER_Y = 440.0
	host.TOWER_X0 = 4420.0
	host.TOWER_X1 = 4588.0
	host.TOWER_Y = 330.0
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
				host.PLAT_X0 = cx - 165.0
				host.PLAT_X1 = cx + 165.0
				host.PLAT_Y = 448.0
				host.PIT_X0 = cx - 85.0
				host.PIT_X1 = cx + 85.0
				host.BRIDGE_X0 = host.PLAT_X0 - 230.0
				host.BRIDGE_X1 = host.PLAT_X1 + 230.0
				host.BRIDGE_Y = 288.0
				x += 560.0
			"foso_seco":
				host.PIT2_X0 = x + 30.0
				host.PIT2_X1 = x + 210.0
				x += 240.0
			"hierba":
				host.GRASS_X0 = x + 20.0
				host.GRASS_X1 = x + 320.0
				x += 340.0
			"hielo":
				host.ICE_X0 = x + 20.0
				host.ICE_X1 = x + 320.0
				x += 340.0
			"cinta":
				host.BELT_X0 = x + 20.0
				host.BELT_X1 = x + 170.0
				x += 190.0
			"escalera":
				host.LADDER_X = x + 25.0
				x += 470.0
		x += gap
	# PIT_* queda anclado a la zona del puente (PLAT_*): _build_level ya ordena
	# los dos fosos por posición al tender los segmentos de suelo


func _hills() -> void:
	# dos capas de colinas tras las ruinas
	var cx := -100.0
	var i := 0
	while cx < host.LEVEL_W + 200.0:
		var r := 150.0 + 90.0 * ((i * 37) % 5)
		_poly(_circle_points(cx, 700.0, r), host.col_hill_far, -8)
		cx += r * 0.9
		i += 1
	cx = -150.0
	i = 2
	while cx < host.LEVEL_W + 200.0:
		var r := 90.0 + 60.0 * ((i * 53) % 4)
		_poly(_circle_points(cx, 720.0, r), host.col_hill_near, -7)
		cx += r * 1.1
		i += 1


func _clouds() -> void:
	for i in 6:
		var c := Cloud.new(6.0 + 4.0 * ((i * 29) % 4), host.LEVEL_W)
		c.position = Vector2(200.0 + 730.0 * i + 120.0 * ((i * 41) % 3), 70.0 + 46.0 * ((i * 17) % 4))
		c.z_index = -6
		_add_level(c)


func _torch_at(x: float) -> void:
	var t := Torch.new()
	t.position = Vector2(x, host.GROUND_Y)
	t.z_index = 1
	_add_level(t)


func _bridge() -> void:
	# puente de madera en alto: ruta alternativa sobre el foso central
	_static_box(host.BRIDGE_X0, host.BRIDGE_Y, host.BRIDGE_X1, host.BRIDGE_Y + 16.0)
	host._register_top(host.BRIDGE_X0, host.BRIDGE_X1, host.BRIDGE_Y)
	_poly(PackedVector2Array([Vector2(host.BRIDGE_X0, host.BRIDGE_Y), Vector2(host.BRIDGE_X1, host.BRIDGE_Y), Vector2(host.BRIDGE_X1, host.BRIDGE_Y + 16.0), Vector2(host.BRIDGE_X0, host.BRIDGE_Y + 16.0)]), Color(0.30, 0.21, 0.13), -4)
	_poly(PackedVector2Array([Vector2(host.BRIDGE_X0, host.BRIDGE_Y), Vector2(host.BRIDGE_X1, host.BRIDGE_Y), Vector2(host.BRIDGE_X1, host.BRIDGE_Y + 5), Vector2(host.BRIDGE_X0, host.BRIDGE_Y + 5)]), Color(0.45, 0.33, 0.20), -4)
	var bx: float = host.BRIDGE_X0 + 34.0
	while bx < host.BRIDGE_X1 - 10.0:
		_poly(PackedVector2Array([Vector2(bx - 2, host.BRIDGE_Y + 5), Vector2(bx + 2, host.BRIDGE_Y + 5), Vector2(bx + 2, host.BRIDGE_Y + 16.0), Vector2(bx - 2, host.BRIDGE_Y + 16.0)]), Color(0.20, 0.14, 0.09), -4)
		bx += 52.0
	# postes y cuerda en los extremos
	for endx in [host.BRIDGE_X0 + 6.0, host.BRIDGE_X1 - 6.0]:
		_poly(PackedVector2Array([Vector2(endx - 4, host.BRIDGE_Y), Vector2(endx + 4, host.BRIDGE_Y), Vector2(endx + 4, host.BRIDGE_Y - 46.0), Vector2(endx - 4, host.BRIDGE_Y - 46.0)]), Color(0.25, 0.18, 0.11), -4)
	_poly(PackedVector2Array([Vector2(host.BRIDGE_X0 + 6.0, host.BRIDGE_Y - 44.0), Vector2(host.BRIDGE_X1 - 6.0, host.BRIDGE_Y - 44.0), Vector2(host.BRIDGE_X1 - 6.0, host.BRIDGE_Y - 40.0), Vector2(host.BRIDGE_X0 + 6.0, host.BRIDGE_Y - 40.0)]), Color(0.35, 0.28, 0.20), -4)


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
	var bx: float = host.HOUSE_X
	var wall_col := Color(0.23, 0.17, 0.15)
	var wall_lite := Color(0.29, 0.22, 0.19)
	_poly(PackedVector2Array([Vector2(bx + 12, host.GROUND_Y), Vector2(bx + 232, host.GROUND_Y), Vector2(bx + 232, 430.0), Vector2(bx + 12, 430.0)]), wall_col, -5)
	_poly(PackedVector2Array([Vector2(bx + 12, 430.0), Vector2(bx + 232, 430.0), Vector2(bx + 232, 424.0), Vector2(bx + 12, 424.0)]), wall_lite, -5)
	# puerta (paso libre) y ventana cálida
	_poly(PackedVector2Array([Vector2(bx + 48, host.GROUND_Y), Vector2(bx + 100, host.GROUND_Y), Vector2(bx + 100, 498.0), Vector2(bx + 74, 486.0), Vector2(bx + 48, 498.0)]), Color(0.12, 0.08, 0.07), -4)
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
	_roof_slab(host.ROOF_L_X0, host.ROOF_L_X1, host.ROOF_L_Y)
	_roof_slab(host.ROOF_H_X0, host.ROOF_H_X1, host.ROOF_H_Y)
	# tejas decorativas bajo cada faldón
	for slab in [[host.ROOF_L_X0, host.ROOF_L_X1, host.ROOF_L_Y], [host.ROOF_H_X0, host.ROOF_H_X1, host.ROOF_H_Y]]:
		var x0: float = slab[0]
		var x1: float = slab[1]
		var y: float = slab[2]
		var sx := x0 + 14.0
		while sx < x1 - 8.0:
			_poly(PackedVector2Array([Vector2(sx, y + 16.0), Vector2(sx + 10.0, y + 16.0), Vector2(sx + 16.0, y + 30.0), Vector2(sx + 6.0, y + 30.0)]), Color(0.16, 0.10, 0.10), -4)
			sx += 26.0


func _roof_slab(x0: float, x1: float, y: float) -> void:
	_static_box(x0, y, x1, y + 16.0)
	host._register_top(x0, x1, y)
	_poly(PackedVector2Array([Vector2(x0, y), Vector2(x1, y), Vector2(x1, y + 16.0), Vector2(x0, y + 16.0)]), Color(0.33, 0.15, 0.13), -4)
	_poly(PackedVector2Array([Vector2(x0, y), Vector2(x1, y), Vector2(x1, y + 5), Vector2(x0, y + 5)]), Color(0.48, 0.24, 0.20), -4)


func _fence(x0: float, x1: float) -> void:
	var fx := x0
	while fx <= x1:
		_poly(PackedVector2Array([Vector2(fx - 3, host.GROUND_Y), Vector2(fx + 3, host.GROUND_Y), Vector2(fx + 3, host.GROUND_Y - 42.0), Vector2(fx - 3, host.GROUND_Y - 42.0)]), Color(0.22, 0.16, 0.12), -3)
		fx += 30.0
	_poly(PackedVector2Array([Vector2(x0 - 6, host.GROUND_Y - 34.0), Vector2(x1 + 6, host.GROUND_Y - 34.0), Vector2(x1 + 6, host.GROUND_Y - 29.0), Vector2(x0 - 6, host.GROUND_Y - 29.0)]), Color(0.26, 0.19, 0.14), -3)
	_poly(PackedVector2Array([Vector2(x0 - 6, host.GROUND_Y - 18.0), Vector2(x1 + 6, host.GROUND_Y - 18.0), Vector2(x1 + 6, host.GROUND_Y - 13.0), Vector2(x0 - 6, host.GROUND_Y - 13.0)]), Color(0.26, 0.19, 0.14), -3)


func _candles() -> void:
	for cx in [host.HOUSE_X + 260.0, 1420.0, 2500.0, 4050.0]:
		var c := Candle.new()
		c.position = Vector2(cx, host.GROUND_Y)
		c.z_index = 1
		_add_level(c)


func _tombstones() -> void:
	for tx in [300.0, 1180.0, 2450.0, 4320.0]:
		_poly(PackedVector2Array([Vector2(tx - 16, host.GROUND_Y), Vector2(tx + 16, host.GROUND_Y), Vector2(tx + 14, host.GROUND_Y - 44.0), Vector2(tx, host.GROUND_Y - 54.0), Vector2(tx - 14, host.GROUND_Y - 44.0)]), Color(0.24, 0.22, 0.28), -3)


func _flowers() -> void:
	for i in 12:
		var fx: float = host.GRASS_X0 + 20.0 + randf() * (host.GRASS_X1 - host.GRASS_X0 - 40.0)
		var col: Color = [Color(0.9, 0.5, 0.6), Color(0.95, 0.85, 0.4), Color(0.7, 0.6, 0.95)][i % 3]
		_poly(PackedVector2Array([Vector2(fx - 2.5, host.GROUND_Y - 26.0), Vector2(fx + 2.5, host.GROUND_Y - 26.0), Vector2(fx + 2.5, host.GROUND_Y - 38.0), Vector2(fx - 2.5, host.GROUND_Y - 38.0)]), Color(0.10, 0.24, 0.13), 2)
		_poly(_circle_points(fx, host.GROUND_Y - 42.0, 4.5, 10), col, 2)


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
	_static_box(x0, top, x1, host.GROUND_Y + 60.0)
	host._register_top(x0, x1, top)
	_boulder_shape(x0, x1, top, host.GROUND_Y + 8.0, Color(0.24, 0.22, 0.28), -4)
	_poly(PackedVector2Array([Vector2(x0, top), Vector2(x1, top), Vector2(x1, top + 5), Vector2(x0, top + 5)]), Color(0.38, 0.35, 0.42), -4)


func _rocks_zone() -> void:
	# peldaño rocoso junto a la meta izquierda
	_rock_step(host.STEP_L_X0, host.STEP_L_X1, host.STEP_L_Y)
	# zona rocosa de la derecha: peldaño, peñasco y torre de piedra
	_rock_step(host.STEP_R_X0, host.STEP_R_X1, host.STEP_R_Y)
	if host.arena_id == 3:
		# en la torre de dos pisos el peñasco y la torre de piedra estorban
		# el pasillo inferior (no cabe un jugador de pie sobre ellos)
		return
	_static_box(host.BOULDER_X0, host.BOULDER_Y, host.BOULDER_X1, host.GROUND_Y + 60.0)
	host._register_top(host.BOULDER_X0, host.BOULDER_X1, host.BOULDER_Y)
	_boulder_shape(host.BOULDER_X0, host.BOULDER_X1, host.BOULDER_Y, host.GROUND_Y + 8.0, Color(0.26, 0.24, 0.31), -4)
	_poly(PackedVector2Array([Vector2(host.BOULDER_X0, host.BOULDER_Y), Vector2(host.BOULDER_X1, host.BOULDER_Y), Vector2(host.BOULDER_X1, host.BOULDER_Y + 5), Vector2(host.BOULDER_X0, host.BOULDER_Y + 5)]), Color(0.40, 0.37, 0.46), -4)
	# torre: pilar visual + plataforma de piedra en la cima
	_poly(PackedVector2Array([Vector2(host.TOWER_X0 + 24, host.GROUND_Y), Vector2(host.TOWER_X1 - 24, host.GROUND_Y), Vector2(host.TOWER_X1 - 34, host.TOWER_Y + 16.0), Vector2(host.TOWER_X0 + 34, host.TOWER_Y + 16.0)]), Color(0.22, 0.20, 0.27), -4)
	_static_box(host.TOWER_X0, host.TOWER_Y, host.TOWER_X1, host.TOWER_Y + 16.0)
	host._register_top(host.TOWER_X0, host.TOWER_X1, host.TOWER_Y)
	_poly(PackedVector2Array([Vector2(host.TOWER_X0, host.TOWER_Y), Vector2(host.TOWER_X1, host.TOWER_Y), Vector2(host.TOWER_X1, host.TOWER_Y + 16.0), Vector2(host.TOWER_X0, host.TOWER_Y + 16.0)]), Color(0.29, 0.27, 0.35), -4)
	_poly(PackedVector2Array([Vector2(host.TOWER_X0, host.TOWER_Y), Vector2(host.TOWER_X1, host.TOWER_Y), Vector2(host.TOWER_X1, host.TOWER_Y + 5), Vector2(host.TOWER_X0, host.TOWER_Y + 5)]), Color(0.44, 0.41, 0.52), -4)
	# gallardete en la torre
	_poly(PackedVector2Array([Vector2((host.TOWER_X0 + host.TOWER_X1) * 0.5, host.TOWER_Y - 2.0), Vector2((host.TOWER_X0 + host.TOWER_X1) * 0.5, host.TOWER_Y - 52.0)]), Color(0.30, 0.22, 0.14), -3)
	_poly(PackedVector2Array([Vector2((host.TOWER_X0 + host.TOWER_X1) * 0.5, host.TOWER_Y - 50.0), Vector2((host.TOWER_X0 + host.TOWER_X1) * 0.5 + 34.0, host.TOWER_Y - 44.0), Vector2((host.TOWER_X0 + host.TOWER_X1) * 0.5, host.TOWER_Y - 30.0)]), Color(0.75, 0.30, 0.22), -3)
	# piedras sueltas decorativas (en sitios libres; x fijas, fuera del barajado)
	if not host._shuffled:
		for r in [[1700.0, 12.0], [2050.0, 16.0], [2600.0, 10.0], [4420.0, 11.0]]:
			_poly(_circle_points(r[0], host.GROUND_Y - r[1] * 0.4, r[1], 9), Color(0.19, 0.18, 0.23), -3)


func _add_level(node: Node) -> void:
	host.level_root.add_child(node)


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
	_static_box(x0, host.GROUND_Y, x1, host.GROUND_Y + 140.0)
	_tiled_rect(host.TEX_FLOOR, Rect2(x0, host.GROUND_Y, x1 - x0, 140.0), host.col_floor, -4)
	_tiled_rect(host.TEX_FLOOR, Rect2(x0, host.GROUND_Y, x1 - x0, 6.0), host.col_floor_top, -4)


func _platform(x0: float, x1: float, y: float) -> void:
	_static_box(x0, y, x1, y + 16.0)
	host._register_top(x0, x1, y)
	_tiled_rect(host.TEX_FLOOR, Rect2(x0, y, x1 - x0, 16.0), host.col_plat, -4)
	_tiled_rect(host.TEX_FLOOR, Rect2(x0, y, x1 - x0, 5.0), host.col_plat_top, -4)


func _wall(x0: float, x1: float) -> void:
	_static_box(x0, 0.0, x1, host.GROUND_Y + 140.0)
	_tiled_rect(host.TEX_WALL, Rect2(x0, 0.0, x1 - x0, host.GROUND_Y + 140.0), host.col_wall, -4)


func _pit_edges(x0: float, x1: float) -> void:
	# remate decorativo en los dos bordes de cada foso
	for side in [x0, x1]:
		var e := Sprite2D.new()
		e.texture = host.TEX_PIT_EDGE
		e.position = Vector2(side, host.GROUND_Y - 23.0)
		e.flip_h = side == x1
		e.z_index = -5
		_add_level(e)


func _goal_zone(x0: float, x1: float, col: Color) -> void:
	host.goal_polys.append(_poly(PackedVector2Array([Vector2(x0, 110.0), Vector2(x1, 110.0), Vector2(x1, host.GROUND_Y), Vector2(x0, host.GROUND_Y)]), Color(col.r, col.g, col.b, 0.15), -3))
	var cx := (x0 + x1) * 0.5
	_poly(PackedVector2Array([Vector2(cx - 3, 190.0), Vector2(cx + 3, 190.0), Vector2(cx + 3, host.GROUND_Y), Vector2(cx - 3, host.GROUND_Y)]), Color(0.12, 0.11, 0.18), -3)
	var inward := 1.0 if x0 > host.LEVEL_W * 0.5 else -1.0
	var ar := Sprite2D.new()
	ar.texture = host.TEX_ARROW
	ar.position = Vector2(cx + inward * 4.0, 214.0)
	ar.flip_h = inward < 0.0
	ar.modulate = col
	ar.z_index = -3
	_add_level(ar)

