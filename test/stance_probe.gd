extends Node
## Sonda visual de la hoja legible (tarea 87): duelistas frente a frente a
## distancia de guardia en cada combinación de estancias. Guarda PNGs en
## screens/ para revisión. Uso (sin --headless para que renderice):
##   godot --path . res://test/stance_probe.tscn

var game: Node
var out_dir := "res://screens"


func _snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(name))


func _stance(p: Node, h: int) -> void:
	p.stance = h
	p.stance_target = h
	p.stance_shift = 0.0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	game = load("res://scenes/main.tscn").instantiate()
	game.skip_countdown = true
	add_child(game)
	await get_tree().create_timer(0.4).timeout
	var cam: Camera2D = game.camera
	cam.position_smoothing_enabled = false
	game.dynamic_zoom = false
	var p1: Node = game.players[0]
	var p2: Node = game.players[1]
	for p in [p1, p2]:
		p.velocity = Vector2.ZERO
		p.state = 0
		p.has_sword = true
		p.weapon_id = "florete"
		p.invuln_time = 0.0
	# frente a frente a distancia de empalamiento (rango 86*0.85 ≈ 73)
	p1.position = Vector2(2363.0, 531.0)
	p2.position = Vector2(2437.0, 531.0)
	p1.facing = 1
	p2.facing = -1

	# combinaciones de estancia: fila P1, fila P2
	for combo in [["alta", "baja"], ["media", "media"], ["baja", "alta"], ["alta", "alta"]]:
		_stance(p1, ["baja", "media", "alta"].find(combo[0]))
		_stance(p2, ["baja", "media", "alta"].find(combo[1]))
		await get_tree().create_timer(0.25).timeout
		await _snap("st87_p1_%s_p2_%s.png" % [combo[0], combo[1]])

	# viaje de la hoja (estancias con peso): P2 pasa de MEDIA a ALTA
	_stance(p2, 1)
	await get_tree().create_timer(0.15).timeout
	Input.action_press("p2_up")
	await get_tree().create_timer(0.05).timeout
	await _snap("st87_viaje_hoja_1.png")
	await get_tree().create_timer(0.10).timeout
	await _snap("st87_viaje_hoja_2.png")
	Input.action_release("p2_up")
	await get_tree().create_timer(0.2).timeout

	# armas distintas: espadón (guardia baja por peso) y daga
	p1.weapon_id = "espada"
	p2.weapon_id = "daga"
	Input.action_press("p1_up")
	Input.action_press("p2_up")
	await get_tree().create_timer(0.3).timeout
	Input.action_release("p1_up")
	Input.action_release("p2_up")
	await get_tree().create_timer(0.15).timeout
	await _snap("st87_espadon_daga.png")

	# arco tensado a la estancia alta
	p1.weapon_id = "arco"
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.7).timeout
	await _snap("st87_arco_alto.png")
	Input.action_release("p1_attack")
	await get_tree().create_timer(0.3).timeout

	print("SONDA ESTANCIAS OK")
	get_tree().quit(0)
