extends Node
## Recorrido de capturas del nivel para revisión visual (ejecutar sin --headless).
## Guarda PNGs en screens/ dentro del proyecto.

var game: Node
var out_dir := "res://screens"


func _snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(name))


func _place(px: float, py_px: float = 531.0) -> void:
	# coloca a los duelistas simétricos para que la cámara centre la zona
	game.players[0].position = Vector2(px - 170.0, py_px)
	game.players[0].velocity = Vector2.ZERO
	game.players[1].position = Vector2(px + 170.0, py_px)
	game.players[1].velocity = Vector2.ZERO


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	game = load("res://scenes/main.tscn").instantiate()
	add_child(game)
	await get_tree().create_timer(0.4).timeout
	var cam: Camera2D = game.camera
	cam.position_smoothing_enabled = false

	# zonas del mapa
	for z in [[1000.0, "01_casa_aldea"], [1600.0, "02_hierba_escalera"], [2300.0, "03_foso_puente"], [3250.0, "04_zona_rocosa"], [4400.0, "05_meta_p1"]]:
		_place(z[0])
		await get_tree().create_timer(0.25).timeout
		await _snap(z[1] + ".png")

	# 2v2 en el centro
	game.set_mode_2v2(true)
	await get_tree().create_timer(0.3).timeout
	var xs := [-620.0, -220.0, 220.0, 620.0]
	for i in 4:
		game.players[i].position = Vector2(2400.0 + xs[i], 531.0)
		game.players[i].velocity = Vector2.ZERO
		game.players[i].is_bot = false
	await get_tree().create_timer(0.25).timeout
	await _snap("06_modo_2v2.png")
	game.set_mode_2v2(false)

	# lluvia de rocas en fase de aviso
	game.set_chaos(true)
	game.chaos_timer = 0.05
	var tries := 0
	while game.rocks.size() == 0 and tries < 200:
		await get_tree().physics_frame
		tries += 1
	_place(2400.0)
	if not game.rocks.is_empty():
		game.rocks[0].position.x = 2450.0
	await get_tree().create_timer(0.2).timeout
	await _snap("07_lluvia_rocas_aviso.png")
	if not game.rocks.is_empty():
		game.rocks[0].phase = "fall"
		await get_tree().create_timer(0.06).timeout
		await _snap("08_lluvia_rocas_cayendo.png")
	game.set_chaos(false)

	# arena 2: Templo del Alba
	game.set_arena(1)
	await get_tree().create_timer(0.3).timeout
	for z in [[700.0, "09_alba_torre"], [2300.0, "10_alba_puente"], [3140.0, "11_alba_foso"], [3970.0, "12_alba_casa"]]:
		_place(z[0])
		await get_tree().create_timer(0.25).timeout
		await _snap(z[1] + ".png")
	game.set_arena(0)

	# banner ¡FIGHT!
	_place(1600.0)
	game._show_fight()
	await get_tree().create_timer(0.25).timeout
	await _snap("13_fight_banner.png")

	# muerte con estallido (cámara lenta: restaurar el tiempo tras capturar)
	_place(1600.0)
	game.players[0].facing = 1
	game.players[1].position = game.players[0].position + Vector2(70.0, 0.0)
	await get_tree().create_timer(0.1).timeout
	game._kill(game.players[1], game.players[0])
	# 0.25 s escalados: tras el hitstop (0.08) pero dentro de la cámara lenta
	# (0.5), con el estallido a medias — a 0.05 las partículas aún no simulan
	await get_tree().create_timer(0.25, true).timeout
	await _snap("14_muerte_estallido.png")
	Engine.time_scale = 1.0
	game.respawn_timers[1] = 0.0
	game.players[1].revive(Vector2(2000.0, 531.0), -1)
	await get_tree().create_timer(0.2).timeout

	# modo pantallas: pan de cámara al cruzar la reja (tarea 50)
	game.set_sections(true)
	await get_tree().create_timer(0.3).timeout
	# el round_lock que deja el _kill anterior bloquearía _update_sections
	game.round_lock = 0.0
	game.right_of_way = game.players[0]
	game.players[0].position = Vector2(2800.0, 531.0)
	await get_tree().create_timer(0.15).timeout
	await _snap("15_pan_seccion.png")
	await get_tree().create_timer(0.4).timeout
	await _snap("16_seccion_conquistada.png")
	game.set_sections(false)
	await get_tree().create_timer(0.2).timeout

	# poses de combate con sprites (tarea 62): ataques por altura y ciclo de carrera
	_place(2400.0)
	for h in [2, 1, 0]:
		game.players[0].state = Player.State.ATTACK
		game.players[0].attack_height = h
		game.players[0].attack_time = 0.0
		game.players[0].velocity = Vector2.ZERO
		await _snap("17_accion_%s.png" % ["alta", "media", "baja"][2 - h])
	Input.action_press("p1_right")
	for k in 4:
		game.players[0].run_phase = PI * 0.5 * float(k)
		await _snap("18_carrera_%d.png" % k)
	Input.action_release("p1_right")
	game.players[0].state = Player.State.IDLE
	game.players[0].velocity = Vector2(0.0, -400.0)
	await _snap("19_salto.png")
	game.players[0].state = Player.State.IDLE
	game.players[0].velocity = Vector2.ZERO
	Input.action_press("p1_down")
	await get_tree().create_timer(0.05).timeout
	await _snap("20_agachado.png")
	Input.action_release("p1_down")
	game.players[0].state = Player.State.KNOCKDOWN
	game.players[0].knockdown_time = 5.0
	await _snap("21_derribado.png")
	game.players[0].state = Player.State.IDLE

	# rodada: sprite de barrido (slide) girando con el transform del ROLL
	game.players[0].velocity = Vector2.ZERO
	await get_tree().physics_frame
	Input.action_press("p1_down")
	Input.action_press("p1_jump")
	await get_tree().create_timer(0.07).timeout
	await _snap("22_rodada_slide.png")
	Input.action_release("p1_jump")
	Input.action_release("p1_down")
	await get_tree().create_timer(0.6).timeout
	game.players[0].state = Player.State.IDLE
	game.players[0].velocity = Vector2.ZERO

	# lanzamiento: pose de suelta (throw) con el arma volando
	game.players[0].has_sword = true
	game.players[0].weapon_id = "florete"
	await get_tree().physics_frame
	Input.action_press("p1_throw")
	await get_tree().create_timer(0.1).timeout
	await _snap("23_lanzamiento.png")
	Input.action_release("p1_throw")
	await get_tree().create_timer(0.8).timeout
	game.players[0].state = Player.State.IDLE
	game.players[0].velocity = Vector2.ZERO

	print("CAPTURAS OK")
	get_tree().quit(0)
