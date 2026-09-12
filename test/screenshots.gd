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

	print("CAPTURAS OK")
	get_tree().quit(0)
