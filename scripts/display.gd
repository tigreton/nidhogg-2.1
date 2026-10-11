extends Node
## Autoload de pantalla: alterna ventana / pantalla completa en cualquier
## escena con F11 o Alt+Enter. La resolución de diseño (1152x648) escala con
## stretch canvas_items + keep (project.godot), así la ventana agrandada o la
## pantalla completa nunca deforman la arena.
##
## Al arrancar corrige además el tamaño de la ventana en Windows con escalado
## de pantalla > 100% (p.ej. 4K al 200%): Godot crea ahí la ventana en píxeles
## FÍSICOS con screen_get_scale() == 1.0, así que 1152x648 salía diminuta
## (un cuarto de pantalla). La agrandamos 1152x648 · dpi/96 y la re-centramos.

func _ready() -> void:
	var scr := DisplayServer.window_get_current_screen()
	var scale := DisplayServer.screen_get_scale(scr)
	var dpi_scale: float = roundf(DisplayServer.screen_get_dpi(scr) / 96.0)
	# solo donde Godot no aplica escala propia (el hueco de Windows: scale 1.0
	# con dpi 192/200%); en macOS/Android screen_get_scale ya es 2.0 y no se toca
	if scale <= 1.0 and dpi_scale > 1.0 \
			and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		var size := Vector2i(DisplayServer.window_get_size()) * int(dpi_scale)
		DisplayServer.window_set_size(size)
		var us := DisplayServer.screen_get_usable_rect(scr)
		DisplayServer.window_set_position(us.position + (us.size - size) / 2)

func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var alt_enter: bool = key.keycode == KEY_ENTER and key.alt_pressed
	if key.keycode == KEY_F11 or alt_enter:
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
