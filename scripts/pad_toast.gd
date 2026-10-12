extends Node
## Aviso global de mandos: toast arriba al conectar o desconectar un gamepad,
## en cualquier escena. El mando 0 es el de P1 y el 1 el de P2 (igual que el
## mapeo de _setup_input), así el mensaje dice a quién pertenece el mando.
## Al conectarse, el mando vibra brevemente de saludo para confirmar.

const FONT_PATH := "res://art/fonts/pixel.ttf"

var _label: Label
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 30   # por encima del HUD (10)
	add_child(layer)
	_label = Label.new()
	_label.position = Vector2(0, 62)
	_label.size = Vector2(1152, 32)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", Color(0.95, 0.93, 0.85))
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 8)
	_label.modulate.a = 0.0
	layer.add_child(_label)
	if ResourceLoader.exists(FONT_PATH):
		_label.add_theme_font_override("font", load(FONT_PATH))
	Input.joy_connection_changed.connect(_on_joy_changed)
	# los mandos ya conectados al arrancar no emiten señal: avisar igual
	var pads: Array = Input.get_connected_joypads()
	if not pads.is_empty():
		var who: Array[String] = []
		for d in pads:
			who.append(_slot_name(d))
		_toast("MANDOS LISTOS: %s" % " · ".join(who), 2.2)


func _slot_name(dev: int) -> String:
	match dev:
		0:
			return "P1"
		1:
			return "P2"
		_:
			return "LIBRE %d" % (dev + 1)   # P3/P4 son bots: sin dueño humano


func _on_joy_changed(device: int, connected: bool) -> void:
	if connected:
		var n := Input.get_joy_name(device)
		if n.length() > 26:
			n = n.substr(0, 26)
		_toast("MANDO DE %s CONECTADO%s" % [_slot_name(device), (" — " + n) if n != "" else ""], 2.4)
		Input.start_joy_vibration(device, 0.3, 0.5, 0.15)
	else:
		_toast("MANDO DE %s DESCONECTADO" % _slot_name(device), 2.4)


func _toast(text: String, dur: float) -> void:
	_label.text = text
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_label.modulate.a = 1.0
	_tween = _label.create_tween()
	_tween.tween_interval(dur)
	_tween.tween_property(_label, "modulate:a", 0.0, 0.4)
