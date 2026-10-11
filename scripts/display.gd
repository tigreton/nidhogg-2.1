extends Node
## Autoload de pantalla: alterna ventana / pantalla completa en cualquier
## escena con F11 o Alt+Enter. La resolución de diseño (1152x648) escala con
## stretch canvas_items + keep (project.godot), así la ventana agrandada o la
## pantalla completa nunca deforman la arena.

func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var alt_enter := key.keycode == KEY_ENTER and key.alt_pressed
	if key.keycode == KEY_F11 or alt_enter:
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
