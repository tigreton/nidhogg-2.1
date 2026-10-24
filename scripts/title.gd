extends Control
## Pantalla de título: reglas del partido y arranque.
## Online (tarea 85): O abre el menú para crear partida (host) o unirse por IP.
## Online v3: 3/4 son el modo RELAY — jugar por Internet sin abrir puertos ni
## dar IPs, solo un código de 4 letras (docs/online-netcode.md § Relay).
## Args de usuario para pruebas: godot --path . -- --host   /   -- --join IP
##   --host-relay [--relay IP:PUERTO]  /  --join-relay=CODE [--relay IP:PUERTO]

var rules_label: Label
var hint_label: Label
var net_panel: Control        # menú online (se crea al pulsar O)
var net_status: Label
var net_edit: LineEdit
var net_mode := ""            # "", "menu", "host_wait", "join_ip", "connecting",
                              # "relay_wait" (host esperando sala/rival),
                              # "join_relay" (tecleando código)
var net_sel := 0              # menú online: 0..3 (mando P1)

const SKY := Color(0.055, 0.05, 0.09)
const CFG_PATH := "user://online.cfg"


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = SKY
	bg.size = Vector2(1152, 648)
	add_child(bg)
	var art := TextureRect.new()
	art.texture = ArtPack.tex("bg_title")
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
	hint_label.text = "P1: A/D mover · W/S alturas · F atacar · G lanzar      P2: ←/→ · ↑/↓ · K atacar · L lanzar\nB: bot · V: 2v2 · P: pantallas · Y: arcade · A: pack de arte    ·    O: ONLINE (1v1 por red)    ·    F11: pantalla completa\nMando P1: ↑/↓ puntos · X lanzar · Y rodar · B arte · A/START jugar · SELECT online\nESPECIALES — SALTO+↓: dive corriendo · rodada parado (ATAQUE durante: tackle) · sobre el caído mantén ↓: pisotón\nATAQUE corriendo: estocada · ATAQUE+↓ corriendo: patada lateral · ATAQUE en el aire: patada voladora (con ↑/↓: tajo alto/bajo)"
	hint_label.position = Vector2(0, 528)
	hint_label.size = Vector2(1152, 116)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 15)
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
	rules_label.text = "PUNTOS PARA GANAR: %d    (teclas 1 / 3 / 5 · mando ↑/↓)\nLANZAR ARMA: %s (T · mando X)      RODAR: %s (R · mando Y)\nARMA AL REAPARECER: %s (W · mando LB)\nARTE: %s (A · mando B)\nP1: NACHO   ·   P2: RODRIGO\n\nENTER o ESPACIO: jugar    ·    O: ONLINE (o SELECT del mando)" % [
		MatchRules.win_score,
		"SÍ" if MatchRules.allow_throw else "NO",
		"SÍ" if MatchRules.allow_roll else "NO",
		"CICLO (ESPADÓN/DAGA/ARCO)" if MatchRules.weapon_variety else "FLORETE FIJO",
		ArtPack.active_pack() if ArtPack.active_pack() != "" else "default",
	]


func _unhandled_key_input(event: InputEvent) -> void:
	if _helper_mode:
		return  # proceso ayudante del relay: nada de UI ni teclas
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
		KEY_W:
			MatchRules.weapon_variety = not MatchRules.weapon_variety
		KEY_O:
			_open_net_menu()
			return
		KEY_A:
			# pack de arte: alterna (default <-> originales) y recarga el título
			ArtPack.cycle_pack()
			get_tree().reload_current_scene()
			return
		KEY_ENTER, KEY_SPACE:
			get_tree().change_scene_to_file("res://scenes/main.tscn")
		_:
			return
	_update_rules()


func _unhandled_input(event: InputEvent) -> void:
	if _helper_mode:
		return  # proceso ayudante del relay: nada de UI ni mandos
	# la configuración del título se maneja también con el mando de P1
	# (device 0): P1 es quien configura y arranca, P2 solo juega
	var jb := event as InputEventJoypadButton
	if jb == null or not jb.pressed or jb.device != 0:
		return
	if net_mode != "":
		_net_pad(jb)
		return
	match jb.button_index:
		JOY_BUTTON_A, JOY_BUTTON_START:
			get_tree().change_scene_to_file("res://scenes/main.tscn")
		JOY_BUTTON_X:
			MatchRules.allow_throw = not MatchRules.allow_throw
		JOY_BUTTON_Y:
			MatchRules.allow_roll = not MatchRules.allow_roll
		JOY_BUTTON_LEFT_SHOULDER:
			MatchRules.weapon_variety = not MatchRules.weapon_variety
		JOY_BUTTON_B:
			ArtPack.cycle_pack()
			get_tree().reload_current_scene()
			return
		JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN:
			var opts := [1, 3, 5]
			var step := 1 if jb.button_index == JOY_BUTTON_DPAD_UP else -1
			MatchRules.win_score = opts[wrapi(opts.find(MatchRules.win_score) + step, 0, opts.size())]
		JOY_BUTTON_BACK:
			_open_net_menu()
			return
		_:
			return
	_update_rules()


func _net_pad(jb: InputEventJoypadButton) -> void:
	# menú online con mando: ↑/↓ elige (4 opciones), A confirma, B vuelve
	# (la IP y el código se teclean)
	match net_mode:
		"menu":
			match jb.button_index:
				JOY_BUTTON_DPAD_UP:
					net_sel = wrapi(net_sel - 1, 0, 4)
					_net_show_menu()
				JOY_BUTTON_DPAD_DOWN:
					net_sel = wrapi(net_sel + 1, 0, 4)
					_net_show_menu()
				JOY_BUTTON_A:
					match net_sel:
						0: _do_host()
						1: _show_join_ip()
						2: _do_host_relay()
						3: _show_join_relay()
				JOY_BUTTON_B, JOY_BUTTON_BACK:
					_close_net_menu()
		"join_ip":
			match jb.button_index:
				JOY_BUTTON_A:
					var ip := net_edit.text.strip_edges() if net_edit != null else ""
					_do_join(ip if not ip.is_empty() else "127.0.0.1")
				JOY_BUTTON_B, JOY_BUTTON_BACK:
					_net_show_menu()
		"join_relay":
			match jb.button_index:
				JOY_BUTTON_A:
					if net_edit != null:
						_do_join_relay(net_edit.text)
				JOY_BUTTON_B, JOY_BUTTON_BACK:
					_net_show_menu()
		"host_wait", "relay_wait":
			if jb.button_index == JOY_BUTTON_B or jb.button_index == JOY_BUTTON_BACK:
				_close_net_menu()


# =============================================================================
# ONLINE: menú de host / unirse
# =============================================================================

func _parse_cli_args() -> void:
	# modo ayudante del relay (proceso aparte lanzado por Net.join_relay):
	# ni título ni juego — solo el puente C vivo hasta que lo maten
	for a in OS.get_cmdline_user_args():
		if a == "--relay-helper":
			_run_relay_helper()
			return
	# godot --path . -- --host  ·  --join 192.168.1.50  ·  --host-relay
	#   --join-relay=AB3F [--relay 127.0.0.1:24578] (relay a mano para tests)
	var relay := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--relay="):
			relay = a.trim_prefix("--relay=")
	for a in OS.get_cmdline_user_args():
		if a == "--host":
			_open_net_menu()
			_do_host()
			return
		if a == "--host-relay":
			_open_net_menu()
			_do_host_relay(relay)
			return
		if a == "--join":
			_open_net_menu()
			_do_join("127.0.0.1")
			return
		if a.begins_with("--join="):
			_open_net_menu()
			_do_join(a.trim_prefix("--join="))
			return
		if a.begins_with("--join-relay="):
			_open_net_menu()
			_do_join_relay(a.trim_prefix("--join-relay="), relay)
			return


## Puente C del relay como proceso aparte (lo lanza Net.join_relay con el
## propio ejecutable --headless): el ENet cliente del juego no tolera
## convivir con su puente en el mismo proceso bajo latencia (v3 2/3).
## Mismo net_relay.gd que el anfitrión usa dentro del proceso (ese sí va bien).
var _helper_mode := false


func _run_relay_helper() -> void:
	_helper_mode = true
	var code := ""
	var relay := ""
	var listen := Net.RELAY_CLIENT_PORT
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--code="):
			code = a.trim_prefix("--code=")
		elif a.begins_with("--relay="):
			relay = a.trim_prefix("--relay=")
		elif a.begins_with("--listen="):
			listen = int(a.trim_prefix("--listen="))
	var bridge: Node = load("res://scripts/net_relay.gd").new()
	add_child(bridge)
	var err: int = bridge.setup_client(relay, code, listen)
	print("RELAY_HELPER: sala=%s relay=%s escucha=%d err=%d" % [code, relay, listen, err])
	# trazas a archivo (su stdout no se ve desde el juego que lo lanza)
	var log_path := "user://relay_helper.log"
	var f := FileAccess.open(log_path, FileAccess.WRITE)
	if f != null:
		f.store_line("helper pid=%d sala=%s relay=%s escucha=%d err=%d" % [
			OS.get_process_id(), code, relay, listen, err])
		f.close()
	_helper_bridge = bridge


var _helper_bridge: Node = null
var _helper_last_line := ""


func _helper_log(line: String) -> void:
	# append (FileAccess no tiene modo APPEND en 4.x): abrir, ir al final
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists("user://relay_helper.log") \
			else FileAccess.WRITE
	var f := FileAccess.open("user://relay_helper.log", mode)
	if f != null:
		f.seek_end(0)
		f.store_line(line)
		f.close()


func _process(_d: float) -> void:
	# ayudante: watchdog de actividad — si el juego muere o lo abandona (un
	# kill duro no mata el arbol en Windows), el puente deja de recibir y este
	# proceso se va solo en vez de quedar eterno agarrando el puerto
	if not _helper_mode:
		return
	if _helper_bridge != null and _helper_bridge.idle_msec() > 60000:
		print("RELAY_HELPER: sin actividad 60 s — cierro")
		get_tree().quit()
		return
	if _helper_bridge != null:
		var line := "%s" % _helper_bridge.stats()
		if line != _helper_last_line:
			_helper_last_line = line
			_helper_log("%d ms  %s" % [Time.get_ticks_msec(), line])


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
		Net.relay_room_ready.connect(_on_relay_room_ready)
		Net.relay_join_ok.connect(_on_relay_join_ok)
		Net.relay_failed.connect(_on_relay_failed)


func _net_show_menu() -> void:
	net_mode = "menu"
	net_status.text = "%s 1 — CREAR PARTIDA (eres P1, anfitrión: IP o UPnP)\n%s 2 — UNIRSE A UNA PARTIDA (IP del anfitrión)\n%s 3 — CREAR POR RELAY (sin abrir nada: te sale un CÓDIGO)\n%s 4 — UNIRSE POR RELAY (teclea el código de 4 letras)\n\nLas reglas del partido las fija el anfitrión.\nMando: ↑/↓ elegir · A aceptar · B volver      ESC: volver" % [
		"▶" if net_sel == 0 else " ",
		"▶" if net_sel == 1 else " ",
		"▶" if net_sel == 2 else " ",
		"▶" if net_sel == 3 else " ",
	]
	if net_edit != null:
		net_edit.visible = false


func _net_key(k: InputEventKey) -> void:
	if net_mode == "menu":
		match k.keycode:
			KEY_1:
				_do_host()
			KEY_2:
				_show_join_ip()
			KEY_3:
				_do_host_relay()
			KEY_4:
				_show_join_relay()
	elif net_mode == "join_ip" and k.keycode == KEY_ENTER and net_edit != null:
		var ip := net_edit.text.strip_edges()
		if ip.is_empty():
			ip = "127.0.0.1"
		_do_join(ip)
	elif net_mode == "join_relay" and k.keycode == KEY_ENTER and net_edit != null:
		_do_join_relay(net_edit.text)


func _do_host() -> void:
	var err := Net.host()
	if err != OK:
		net_mode = "menu"
		net_status.text = "No se pudo abrir el puerto %d (¿otra partida abierta?).\nESC: volver" % Net.DEFAULT_PORT
		return
	net_mode = "host_wait"
	var ips := "  ·  ".join(Net.lan_addresses())
	var pub := ""
	if Net.upnp_mapped:
		pub = "\nDesde INTERNET (UPnP ya abrió el puerto): %s" % Net.public_ip
	elif not Net.public_ip.is_empty():
		pub = "\nDesde INTERNET: %s  (UPnP no disponible: abre el %d/UDP en tu router)" % [Net.public_ip, Net.DEFAULT_PORT]
	net_status.text = "PARTIDA CREADA — esperando al rival...\nDale esta IP: %s (puerto %d)%s\n\nTu rival elige «2 — UNIRSE» y la escribe.\nESC: cancelar" % [ips, Net.DEFAULT_PORT, pub]


func _show_join_ip() -> void:
	net_mode = "join_ip"
	_ensure_net_edit()
	net_edit.text = _load_last_ip()
	net_edit.max_length = 0
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


# =============================================================================
# MODO RELAY (online v3): sin abrir puertos, sin IPs — solo un código
# =============================================================================

func _do_host_relay(relay_override := "") -> void:
	var err := Net.host_relay(Net.DEFAULT_PORT, relay_override if not relay_override.is_empty() else Net.RELAY_DEFAULT)
	if err != OK:
		net_mode = "menu"
		net_status.text = "No se pudo abrir el puerto %d (¿otra partida abierta?).\nESC: volver" % Net.DEFAULT_PORT
		return
	net_mode = "relay_wait"
	net_status.text = "Creando la sala en el relay...\n(nadie abre puertos: el rival solo necesita el código)"


func _show_join_relay() -> void:
	net_mode = "join_relay"
	_ensure_net_edit()
	net_edit.text = ""
	net_edit.max_length = 4
	net_edit.visible = true
	net_edit.grab_focus()
	net_status.text = "Teclea el CÓDIGO de 4 letras del anfitrión y pulsa ENTER\n(ejemplo: 7KXW)      ESC: volver"


## LineEdit compartido por «unirse por IP» y «unirse por relay»: el ENTER se
## despacha por net_mode (un solo handler conectado, así reutilizar el edit
## no dispara el handler del otro modo).
func _ensure_net_edit() -> void:
	if net_edit != null:
		return
	net_edit = LineEdit.new()
	net_edit.position = Vector2(1152 * 0.5 - 180.0, 330.0)
	net_edit.size = Vector2(360, 46)
	net_edit.add_theme_font_size_override("font_size", 28)
	net_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	net_panel.add_child(net_edit)
	net_edit.text_submitted.connect(_on_edit_submitted)


func _on_edit_submitted(txt: String) -> void:
	if net_mode == "join_ip":
		var ip := txt.strip_edges()
		_do_join(ip if not ip.is_empty() else "127.0.0.1")
	elif net_mode == "join_relay":
		_do_join_relay(txt)


func _do_join_relay(code_txt: String, relay_override := "") -> void:
	var code := code_txt.strip_edges().to_upper()
	if code.length() != 4:
		net_status.text = "El código son 4 letras: %s\nESC: volver" % code_txt.strip_edges()
		return
	var err := Net.join_relay(code, relay_override if not relay_override.is_empty() else Net.RELAY_DEFAULT)
	if err != OK:
		net_status.text = "Código no válido (4 letras, sin la O ni la I).\nESC: volver"
		return
	net_mode = "connecting"
	net_status.text = "Buscando la sala %s en el relay..." % code


func _on_relay_room_ready(code: String) -> void:
	# host: la sala existe — el código es lo único que el rival necesita
	if net_panel == null:
		return
	net_status.text = "SALA CREADA — dale este CÓDIGO a tu rival:\n\n        %s\n\nEl rival elige «4 — UNIRSE POR RELAY» y lo teclea.\nESC: cancelar" % code


func _on_relay_join_ok() -> void:
	if net_panel == null:
		return
	net_status.text = "Sala encontrada — conectando...\n"


func _on_relay_failed(reason: String) -> void:
	if net_panel == null:
		return
	Net.shutdown()
	net_mode = "menu"
	if reason == "NOROOM":
		net_status.text = "No hay ninguna sala con ese código.\n¿Está el anfitrión en «3 — CREAR POR RELAY» aún?\n\nESC: volver"
	else:
		net_status.text = "El relay falló (%s). ¿Internet bien?\n\nESC: volver" % reason


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
	## Los dos duelistas del título, con los sprites del pack activo.
	func _ready() -> void:
		for i in 2:
			var s := Sprite2D.new()
			s.texture = ArtPack.tex("player_idle_p1") if i == 0 \
					else ArtPack.tex("player_idle_p2")
			s.scale = Vector2(2.2, 2.2)
			s.position = Vector2(420.0 + 312.0 * float(i), 462.0)
			s.flip_h = i == 1
			add_child(s)
