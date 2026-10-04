extends Control
## Pantalla de título: reglas del partido y arranque.
## Online (tarea 85): O abre el menú para crear partida (host) o unirse por IP.
## Args de usuario para pruebas: godot --path . -- --host   /   -- --join IP

var rules_label: Label
var hint_label: Label
var net_panel: Control        # menú online (se crea al pulsar O)
var net_status: Label
var net_edit: LineEdit
var net_mode := ""            # "", "menu", "host_wait", "join_ip", "connecting"

const SKY := Color(0.055, 0.05, 0.09)
const CFG_PATH := "user://online.cfg"


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = SKY
	bg.size = Vector2(1152, 648)
	add_child(bg)
	var art := TextureRect.new()
	art.texture = preload("res://art/sprites/bg_title.png")
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.size = Vector2(1152, 648)
	add_child(art)
	var preview := PreviewFigure.new()
	add_child(preview)
	var title := Label.new()
	title.text = "NIDHOGG 2.1"
	title.position = Vector2(0, 90)
	title.size = Vector2(1152, 120)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", Color("ffb324"))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 14)
	add_child(title)
	rules_label = Label.new()
	rules_label.position = Vector2(0, 260)
	rules_label.size = Vector2(1152, 150)
	rules_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rules_label.add_theme_font_size_override("font_size", 26)
	rules_label.add_theme_color_override("font_color", Color(0.85, 0.83, 0.9))
	rules_label.add_theme_color_override("font_outline_color", Color.BLACK)
	rules_label.add_theme_constant_override("outline_size", 8)
	add_child(rules_label)
	hint_label = Label.new()
	hint_label.text = "P1: A/D mover · W/S alturas · F atacar · G lanzar      P2: ←/→ · ↑/↓ · K atacar · L lanzar\nB: bot · V: 2v2 · P: pantallas · Y: arcade    ·    O: ONLINE (1v1 por red)"
	hint_label.position = Vector2(0, 560)
	hint_label.size = Vector2(1152, 60)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 18)
	hint_label.add_theme_color_override("font_color", Color(0.6, 0.58, 0.7))
	add_child(hint_label)
	_update_rules()
	_apply_pixel_font(self)
	_parse_cli_args()


## Fuente pixel opcional (tarea 64): si existe res://art/fonts/pixel.ttf se
## aplica a todos los Labels del HUD; si no, todo queda con la fuente por defecto.
const FONT_PATH := "res://art/fonts/pixel.ttf"


func _apply_pixel_font(root: Node) -> void:
	if not ResourceLoader.exists(FONT_PATH):
		return
	var f: FontFile = load(FONT_PATH)
	for n in _all_labels(root):
		n.add_theme_font_override("font", f)


func _all_labels(node: Node) -> Array[Label]:
	var out: Array[Label] = []
	for c in node.get_children():
		if c is Label:
			out.append(c)
		out.append_array(_all_labels(c))
	return out


func _update_rules() -> void:
	rules_label.text = "PUNTOS PARA GANAR: %d    (teclas 1 / 3 / 5)\nLANZAR ARMA: %s (T)      RODAR: %s (R)\nP1: NACHO   ·   P2: RODRIGO\n\nENTER o ESPACIO: jugar    ·    O: ONLINE" % [
		MatchRules.win_score,
		"SÍ" if MatchRules.allow_throw else "NO",
		"SÍ" if MatchRules.allow_roll else "NO",
	]


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	# dentro del menú online, ESC cancela y vuelve al título
	if net_mode != "" and k.keycode == KEY_ESCAPE:
		if net_mode == "connecting":
			return   # una conexión en curso no se aborta con ESC (cierra sola)
		_close_net_menu()
		return
	if net_mode != "":
		_net_key(k)
		return
	match k.keycode:
		KEY_1:
			MatchRules.win_score = 1
		KEY_3:
			MatchRules.win_score = 3
		KEY_5:
			MatchRules.win_score = 5
		KEY_T:
			MatchRules.allow_throw = not MatchRules.allow_throw
		KEY_R:
			MatchRules.allow_roll = not MatchRules.allow_roll
		KEY_O:
			_open_net_menu()
			return
		KEY_ENTER, KEY_SPACE:
			get_tree().change_scene_to_file("res://scenes/main.tscn")
		_:
			return
	_update_rules()


# =============================================================================
# ONLINE: menú de host / unirse
# =============================================================================

func _parse_cli_args() -> void:
	# godot --path . -- --host  ·  godot --path . -- --join 192.168.1.50
	for a in OS.get_cmdline_user_args():
		if a == "--host":
			_open_net_menu()
			_do_host()
			return
		if a == "--join":
			_open_net_menu()
			_do_join("127.0.0.1")
			return
		if a.begins_with("--join="):
			_open_net_menu()
			_do_join(a.trim_prefix("--join="))
			return


func _open_net_menu() -> void:
	net_mode = "menu"
	net_panel = Control.new()
	net_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(net_panel)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	net_panel.add_child(dim)
	var head := Label.new()
	head.text = "ONLINE — DUELO 1v1 POR RED"
	head.position = Vector2(0, 150)
	head.size = Vector2(1152, 60)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 48)
	head.add_theme_color_override("font_color", Color("ffb324"))
	head.add_theme_color_override("font_outline_color", Color.BLACK)
	head.add_theme_constant_override("outline_size", 10)
	net_panel.add_child(head)
	net_status = Label.new()
	net_status.position = Vector2(0, 250)
	net_status.size = Vector2(1152, 220)
	net_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	net_status.add_theme_font_size_override("font_size", 26)
	net_status.add_theme_color_override("font_color", Color(0.9, 0.88, 0.95))
	net_status.add_theme_color_override("font_outline_color", Color.BLACK)
	net_status.add_theme_constant_override("outline_size", 6)
	net_panel.add_child(net_status)
	_apply_pixel_font(net_panel)
	_net_show_menu()
	if not Net.peer_joined.is_connected(_on_peer_joined):
		Net.peer_joined.connect(_on_peer_joined)
		Net.connected_ok.connect(_on_connected_ok)
		Net.connect_failed.connect(_on_connect_failed)
		Net.server_lost.connect(_on_net_lost_title)
		Net.peer_left.connect(_on_net_lost_title)


func _net_show_menu() -> void:
	net_mode = "menu"
	net_status.text = "1 — CREAR PARTIDA (eres P1, anfitrión)\n2 — UNIRSE A UNA PARTIDA (eres P2)\n\nLas reglas del partido las fija el anfitrión.\nESC: volver"
	if net_edit != null:
		net_edit.visible = false


func _net_key(k: InputEventKey) -> void:
	if net_mode == "menu":
		match k.keycode:
			KEY_1:
				_do_host()
			KEY_2:
				_show_join_ip()
	elif net_mode == "join_ip" and k.keycode == KEY_ENTER and net_edit != null:
		var ip := net_edit.text.strip_edges()
		if ip.is_empty():
			ip = "127.0.0.1"
		_do_join(ip)


func _do_host() -> void:
	var err := Net.host()
	if err != OK:
		net_mode = "menu"
		net_status.text = "No se pudo abrir el puerto %d (¿otra partida abierta?).\nESC: volver" % Net.DEFAULT_PORT
		return
	net_mode = "host_wait"
	var ips := "  ·  ".join(Net.lan_addresses())
	net_status.text = "PARTIDA CREADA — esperando al rival...\nDale esta IP: %s (puerto %d)\n\nTu rival elige «2 — UNIRSE» y la escribe.\nESC: cancelar" % [ips, Net.DEFAULT_PORT]


func _show_join_ip() -> void:
	net_mode = "join_ip"
	if net_edit == null:
		net_edit = LineEdit.new()
		net_edit.position = Vector2(1152 * 0.5 - 180.0, 330.0)
		net_edit.size = Vector2(360, 46)
		net_edit.add_theme_font_size_override("font_size", 28)
		net_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
		net_edit.text = _load_last_ip()
		net_panel.add_child(net_edit)
		net_edit.text_submitted.connect(func(_t: String) -> void:
			var ip := net_edit.text.strip_edges()
			if ip.is_empty():
				ip = "127.0.0.1"
			_do_join(ip))
	net_edit.visible = true
	net_edit.grab_focus()
	net_status.text = "Escribe la IP del anfitrión y pulsa ENTER\n(vacío = 127.0.0.1, partida en este mismo PC)\nESC: volver"


func _do_join(ip: String) -> void:
	var err := Net.join(ip)
	if err != OK:
		net_mode = "menu"
		net_status.text = "IP no válida: %s\nESC: volver" % ip
		return
	_save_last_ip(ip)
	net_mode = "connecting"
	net_status.text = "Conectando a %s ..." % ip


func _on_peer_joined() -> void:
	# host: el rival ya está — a pelear
	_enter_game()


func _on_connected_ok() -> void:
	# cliente: enlace listo — a pelear
	_enter_game()


func _on_connect_failed() -> void:
	if net_panel == null:
		return
	Net.shutdown()
	net_mode = "menu"
	net_status.text = "No se pudo conectar. ¿Está la IP bien escrita?\n¿Ha creado la partida tu rival antes?\n\n1 — CREAR PARTIDA      2 — UNIRSE      ESC: volver"


func _on_net_lost_title() -> void:
	# el rival se cayó estando aún en el título/espera
	if net_panel == null or net_mode == "":
		return
	Net.shutdown()
	net_mode = "menu"
	_net_show_menu()


func _enter_game() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _close_net_menu() -> void:
	Net.shutdown()
	if net_panel != null:
		net_panel.queue_free()
		net_panel = null
	net_edit = null
	net_mode = ""


func _load_last_ip() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) == OK:
		return cfg.get_value("online", "last_ip", "127.0.0.1")
	return "127.0.0.1"


func _save_last_ip(ip: String) -> void:
	var cfg := ConfigFile.new()
	cfg.load(CFG_PATH)
	cfg.set_value("online", "last_ip", ip)
	cfg.save(CFG_PATH)


class PreviewFigure extends Control:
	## Los dos duelistas del título, con sus sprites definitivos.
	func _ready() -> void:
		for i in 2:
			var s := Sprite2D.new()
			s.texture = preload("res://art/sprites/player_idle_p1.png") if i == 0 \
					else preload("res://art/sprites/player_idle_p2.png")
			s.scale = Vector2(2.2, 2.2)
			s.position = Vector2(420.0 + 312.0 * float(i), 462.0)
			s.flip_h = i == 1
			add_child(s)
