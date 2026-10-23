class_name Corpse
extends Node2D
## Cadáver persistente: sale despedido girando, cae y queda tumbado.
## Con arma de hoja puede quedar empalado en la espada del asesino.

var col := Color.WHITE
var body_side := "p1"
var vel := Vector2.ZERO
var spin := 0.0
var rot := 0.0
var impaler: Player = null
var grounded := false


func _init(c: Color, side := "p1") -> void:
	col = c
	body_side = side


func _process(delta: float) -> void:
	if impaler != null:
		if impaler.state == Player.State.DEAD or not impaler.has_sword or impaler.attack_is_active():
			impaler = null
		else:
			# el cadáver sigue la línea de la hoja según la estancia (tarea 77);
			# los puntos caen sobre el arma del overlay de guardia (tarea 87)
			match impaler.stance:
				Player.H.HIGH:
					position = impaler.position + Vector2(impaler.facing * 26.0, -34.0)
				Player.H.LOW:
					position = impaler.position + Vector2(impaler.facing * 38.0, 22.0)
				_:
					position = impaler.position + Vector2(impaler.facing * 44.0, -6.0)
			queue_redraw()
			return
	if not grounded:
		vel.y += 1500.0 * delta
		position += vel * delta
		rot += spin * delta
		var g := get_parent()
		var floor_y := 560.0
		if g != null and g.has_method("_top_below"):
			var top: float = g._top_below(position.x, position.y)
			if top > 0.0:
				floor_y = top
		if position.y >= floor_y - 8.0:
			position.y = floor_y - 8.0
			grounded = true
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0 if grounded else rot, Vector2.ONE)
	var tex: Texture2D = Player.pose_texture("dead", body_side)
	var w := tex.get_width() * Player.POSE_SCALE
	var h := tex.get_height() * Player.POSE_SCALE
	draw_texture_rect(tex, Rect2(-w * 0.5, 8.0 - h, w, h), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
