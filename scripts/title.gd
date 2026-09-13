extends Control
## Pantalla de título: reglas del partido y arranque.

var rules_label: Label

const SKY := Color(0.055, 0.05, 0.09)


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = SKY
	bg.size = Vector2(1152, 648)
	add_child(bg)
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
	add_child(rules_label)
	var hint := Label.new()
	hint.text = "P1: A/D mover · W/S alturas · F atacar · G lanzar      P2: ←/→ · ↑/↓ · K atacar · L lanzar\nB: bot · V: 2v2 · P: pantallas · Y: arcade"
	hint.position = Vector2(0, 560)
	hint.size = Vector2(1152, 60)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.6, 0.58, 0.7))
	add_child(hint)
	_update_rules()


func _update_rules() -> void:
	rules_label.text = "PUNTOS PARA GANAR: %d    (teclas 1 / 3 / 5)\nLANZAR ARMA: %s (T)      RODAR: %s (R)\nZ/X: aspecto P1   ·   N/M: aspecto P2\n\nENTER o ESPACIO: jugar" % [
		MatchRules.win_score,
		"SÍ" if MatchRules.allow_throw else "NO",
		"SÍ" if MatchRules.allow_roll else "NO",
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
		KEY_Z:
			MatchRules.hair[0] = (MatchRules.hair[0] + 1) % 3
		KEY_X:
			MatchRules.skin[0] = (MatchRules.skin[0] + 1) % 3
		KEY_N:
			MatchRules.hair[1] = (MatchRules.hair[1] + 1) % 3
		KEY_M:
			MatchRules.skin[1] = (MatchRules.skin[1] + 1) % 3
		KEY_ENTER, KEY_SPACE:
			get_tree().change_scene_to_file("res://scenes/main.tscn")
		_:
			return
	_update_rules()


class PreviewFigure extends Control:
	## Dos duelistas en miniatura con el aspecto elegido.
	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		for i in 2:
			var hx := 420.0 + 312.0 * float(i)
			var skin_cols := [Color(0.93, 0.78, 0.62), Color(0.72, 0.52, 0.36), Color(0.45, 0.30, 0.20)]
			var skin: Color = skin_cols[MatchRules.skin[i] % skin_cols.size()]
			var body := Color("ffb324") if i == 0 else Color("39d7ff")
			draw_line(Vector2(hx, 470), Vector2(hx, 430), body, 16.0)
			draw_circle(Vector2(hx, 418), 9.0, skin)
			match MatchRules.hair[i] % 3:
				1:
					draw_colored_polygon(PackedVector2Array([Vector2(hx - 8, 416), Vector2(hx + 10, 416), Vector2(hx + 1, 402)]), Color(0.12, 0.09, 0.07))
				2:
					draw_arc(Vector2(hx, 418), 10.5, PI, TAU, 12, Color(0.05, 0.04, 0.08), 5.0)
					draw_line(Vector2(hx, 406), Vector2(hx, 396), body, 4.0)
