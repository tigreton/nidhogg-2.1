extends Control
## Pantalla de título: reglas del partido y arranque.

var rules_label: Label

const SKY := Color(0.055, 0.05, 0.09)


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
	var hint := Label.new()
	hint.text = "P1: A/D mover · W/S alturas · F atacar · G lanzar      P2: ←/→ · ↑/↓ · K atacar · L lanzar\nB: bot · V: 2v2 · P: pantallas · Y: arcade · A: pack de arte"
	hint.position = Vector2(0, 560)
	hint.size = Vector2(1152, 60)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.6, 0.58, 0.7))
	add_child(hint)
	_update_rules()
	_apply_pixel_font(self)


## Fuente pixel opcional (tarea 64): si existe res://art/fonts/pixel.ttf se
## aplica a todos los Labels; si no, todo queda con la fuente por defecto.
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
	rules_label.text = "PUNTOS PARA GANAR: %d    (teclas 1 / 3 / 5)\nLANZAR ARMA: %s (T)      RODAR: %s (R)\nARTE: %s (A)\nP1: NACHO   ·   P2: RODRIGO\n\nENTER o ESPACIO: jugar" % [
		MatchRules.win_score,
		"SÍ" if MatchRules.allow_throw else "NO",
		"SÍ" if MatchRules.allow_roll else "NO",
		ArtPack.active_pack() if ArtPack.active_pack() != "" else "default",
	]


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
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
