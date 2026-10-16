extends SceneTree
## Captura del título con el hint ampliado (issue 8). Ventana breve:
##   godot --path . -s test/title_snap.gd
## Guarda .godot/title_snap.png (carpeta ignorada).

func _initialize() -> void:
	_run()


func _run() -> void:
	var title: Node = load("res://scenes/title.tscn").instantiate()
	get_root().add_child(title)
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	var img := get_root().get_texture().get_image()
	img.save_png("res://.godot/title_snap.png")
	var hint: Label = title.get("hint_label")
	var ms: Vector2 = hint.get_minimum_size()
	print("hint min_size=%s pos=%s box=%s" % [ms, hint.position, hint.size])
	print("hint lineas=%d ancho_max=%.0f (viewport 1152) alto_total=%.0f (fin y=%.0f < 648)" % [
		hint.text.split("\n").size(), ms.x, ms.y, hint.position.y + ms.y])
	print("TITULO OK")
	quit(0)
