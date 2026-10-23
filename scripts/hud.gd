class_name Hud
extends RefCounted
## HUD y mensajes (corte 3/7 de la disolución de game.gd): construcción del
## CanvasLayer, marcador, pips de secciones, barra de reaparición, mensajes
## y banners. Los NODOS (msg_label, pips, tweens, ...) siguen VIVIENDO en
## game (tests y el tick los leen como game.msg_label / ...): el hud los
## toca vía `host`. La replicación online (ev_msg/ev_sfx) no vive aquí:
## cada delegado de game la aplica después de la parte visual.

var host  # = game.gd


func _init(game) -> void:
	host = game


func _build_hud() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 10
	host.add_child(cl)

	var l1 := Label.new()
	l1.text = "P1  0  »"
	l1.position = Vector2(28, 16)
	l1.add_theme_font_size_override("font_size", 40)
	l1.add_theme_color_override("font_color", host.P1_COLOR)
	l1.add_theme_color_override("font_outline_color", Color.BLACK)
	l1.add_theme_constant_override("outline_size", 10)
	cl.add_child(l1)
	host.score_labels.append(l1)

	var l2 := Label.new()
	l2.text = "«  0  P2"
	l2.position = Vector2(host.VIEW_W - 340.0, 16)
	l2.size = Vector2(312, 60)
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l2.add_theme_font_size_override("font_size", 40)
	l2.add_theme_color_override("font_color", host.P2_COLOR)
	l2.add_theme_color_override("font_outline_color", Color.BLACK)
	l2.add_theme_constant_override("outline_size", 10)
	cl.add_child(l2)
	host.score_labels.append(l2)

	host.msg_label = Label.new()
	host.msg_label.position = Vector2(0, host.VIEW_H * 0.26)
	host.msg_label.size = Vector2(host.VIEW_W, 130)
	host.msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	host.msg_label.add_theme_font_size_override("font_size", 76)
	host.msg_label.add_theme_color_override("font_color", Color.WHITE)
	host.msg_label.add_theme_color_override("font_outline_color", Color.BLACK)
	host.msg_label.add_theme_constant_override("outline_size", 14)
	host.msg_label.modulate.a = 0.0
	cl.add_child(host.msg_label)

	var hint := Label.new()
	hint.text = "P1: A/D mover · W saltar/arriba · S agachar · F atacar · G lanzar    P2: ←/→ · ↑ · ↓ · K atacar · L lanzar    R: revancha\nB: bot P2 · H: aliado P3 · N: bot vs bot · V: 2v2 · T: lluvia de rocas · C: cambiar arena · X: arena barajada · M: música\nMando P1 (0) / P2 (1): stick o cruceta · A saltar · X atacar · B lanzar    solo P1: START revancha · SELECT pausa · L1 arena · R1 música"
	hint.position = Vector2(22, host.VIEW_H - 80)
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.62, 0.60, 0.72))
	cl.add_child(hint)
	host.hint_label = hint

	host.run_label = Label.new()
	host.run_label.position = Vector2(0, 64)
	host.run_label.size = Vector2(host.VIEW_W, 44)
	host.run_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	host.run_label.add_theme_font_size_override("font_size", 30)
	host.run_label.add_theme_color_override("font_outline_color", Color.BLACK)
	host.run_label.add_theme_constant_override("outline_size", 8)
	host.run_label.visible = false
	cl.add_child(host.run_label)

	host.dim = ColorRect.new()
	host.dim.color = Color(0, 0, 0, 0.55)
	host.dim.size = Vector2(host.VIEW_W, host.VIEW_H)
	host.dim.visible = false
	cl.add_child(host.dim)

	host.pause_label = Label.new()
	host.pause_label.text = "PAUSA"
	host.pause_label.position = Vector2(0, host.VIEW_H * 0.4)
	host.pause_label.size = Vector2(host.VIEW_W, 80)
	host.pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	host.pause_label.add_theme_font_size_override("font_size", 64)
	host.pause_label.add_theme_color_override("font_color", Color.WHITE)
	host.pause_label.visible = false
	cl.add_child(host.pause_label)

	host.stats_label = Label.new()
	host.stats_label.position = Vector2(0, host.VIEW_H * 0.40)
	host.stats_label.size = Vector2(host.VIEW_W, 190)
	host.stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	host.stats_label.add_theme_font_size_override("font_size", 22)
	host.stats_label.add_theme_color_override("font_color", Color(0.85, 0.83, 0.90))
	host.stats_label.add_theme_color_override("font_outline_color", Color.BLACK)
	host.stats_label.add_theme_constant_override("outline_size", 6)
	host.stats_label.visible = false
	cl.add_child(host.stats_label)

	host.pips_row = Node2D.new()
	host.pips_row.position = Vector2(host.VIEW_W * 0.5 - 2.0 * 44.0 + 16.0, 36.0)
	host.pips_row.visible = false
	cl.add_child(host.pips_row)
	host.pips.clear()
	for k in host.SECTION_COUNT:
		var pip := Pip.new()
		pip.position = Vector2(44.0 * float(k), 0.0)
		host.pips_row.add_child(pip)
		host.pips.append(pip)

	host.respawn_bar = RespawnBar.new()
	host.respawn_bar.visible = false
	host.respawn_bar.z_index = 40
	cl.add_child(host.respawn_bar)

	host.fight_label = Label.new()
	host.fight_label.text = "¡FIGHT!"
	host.fight_label.position = Vector2(0, host.VIEW_H * 0.30)
	host.fight_label.size = Vector2(host.VIEW_W, 110)
	host.fight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	host.fight_label.add_theme_font_size_override("font_size", 88)
	host.fight_label.add_theme_color_override("font_color", Color.WHITE)
	host.fight_label.add_theme_color_override("font_outline_color", Color.BLACK)
	host.fight_label.add_theme_constant_override("outline_size", 16)
	host.fight_label.pivot_offset = Vector2(host.VIEW_W * 0.5, 55.0)
	host.fight_label.visible = false
	cl.add_child(host.fight_label)

	_apply_pixel_font(cl)

	# flecha grande del derecho de avance (tarea 65)
	host.step_arrow = TextureRect.new()
	host.step_arrow.texture = ArtPack.tex("arrow_neutral")
	host.step_arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	host.step_arrow.pivot_offset = Vector2(32.0, 21.0)
	host.step_arrow.position = Vector2(host.VIEW_W * 0.5 - 32.0, 108.0)
	host.step_arrow.modulate.a = 0.0
	cl.add_child(host.step_arrow)


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


func show_msg(text: String, dur: float) -> void:
	host.msg_label.text = text
	host.msg_label.modulate.a = 1.0
	if host.msg_tween:
		host.msg_tween.kill()
	host.msg_tween = host.msg_label.create_tween()
	host.msg_tween.tween_interval(dur)
	host.msg_tween.tween_property(host.msg_label, "modulate:a", 0.0, 0.4)


func _show_fight() -> void:
	host.sfx(Vector2(host.LEVEL_W * 0.5, 300.0), "fight", -4.0)
	host.fight_label.visible = true
	host.fight_label.modulate.a = 1.0
	host.fight_label.scale = Vector2(1.7, 1.7)
	if host.fight_tween:
		host.fight_tween.kill()
	host.fight_tween = host.fight_label.create_tween()
	host.fight_tween.tween_property(host.fight_label, "scale", Vector2.ONE, 0.22)
	host.fight_tween.tween_interval(0.45)
	host.fight_tween.tween_property(host.fight_label, "modulate:a", 0.0, 0.3)
	host.fight_tween.tween_callback(func(): host.fight_label.visible = false)


func _show_step_arrow(p: Player) -> void:
	# flecha grande del derecho de avance (tarea 65): color del verdugo, hacia su meta
	if host.step_arrow == null:
		return
	host.step_arrow.flip_h = p.goal_dir < 0
	host.step_arrow.modulate = Color(p.color.r, p.color.g, p.color.b, 0.0)
	host.step_arrow.scale = Vector2(2.6, 2.6)
	if host.step_arrow_tween:
		host.step_arrow_tween.kill()
	host.step_arrow_tween = host.step_arrow.create_tween()
	host.step_arrow_tween.tween_property(host.step_arrow, "modulate:a", 1.0, 0.12)
	host.step_arrow_tween.tween_interval(0.9)
	host.step_arrow_tween.tween_property(host.step_arrow, "modulate:a", 0.0, 0.3)


func _update_hud() -> void:
	if host.mode_2v2:
		host.score_labels[0].text = "P1·P3  %d  »" % host.scores[0]
		host.score_labels[1].text = "«  %d  P2·P4" % host.scores[1]
	else:
		host.score_labels[0].text = "P1  %d  »" % host.scores[0]
		host.score_labels[1].text = "«  %d  P2" % host.scores[1]
	_update_pips()


func _update_pips() -> void:
	host.pips_row.visible = host.sections_mode
	if not host.sections_mode:
		return
	for k in host.SECTION_COUNT:
		var fill := Color(0, 0, 0, 0)
		var edge := Color(0.65, 0.63, 0.72)
		if k < 3 and host.sect_conquered[1] >= 3 - k:
			fill = host.P2_COLOR
			edge = host.P2_COLOR
		elif k > 3 and host.sect_conquered[0] >= k - 3:
			fill = host.P1_COLOR
			edge = host.P1_COLOR
		host.pips[k].fill_col = fill
		host.pips[k].edge_col = edge
		host.pips[k].queue_redraw()


func _update_respawn_bar() -> void:
	var shown := false
	for i in host.players.size():
		if host.respawn_timers[i] > 0.0:
			var p: Player = host.players[i]
			host.respawn_bar.position = host._respawn_pos(p) + Vector2(0, -96)
			host.respawn_bar.col = p.color
			host.respawn_bar.frac = host.respawn_timers[i] / host.RESPAWN_DELAY
			shown = true
			break
	host.respawn_bar.visible = shown

