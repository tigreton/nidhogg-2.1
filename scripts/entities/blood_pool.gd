class_name BloodPool
extends Node2D
## Charco de sangre persistente que gotea hacia abajo.

var col := Color(0.5, 0.1, 0.1)
var t := 0.0
var drips: Array[float] = []


func _init(c: Color) -> void:
	col = c
	for i in 2 + randi() % 2:
		drips.append(randf_range(6.0, 15.0))


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var a := 0.85
	draw_colored_polygon(PackedVector2Array([
		Vector2(-22, -3), Vector2(-8, -6), Vector2(10, -5), Vector2(23, -2),
		Vector2(14, 4), Vector2(-6, 5), Vector2(-18, 3),
	]), Color(col.r, col.g, col.b, a))
	if t > 0.4:
		var g := clampf((t - 0.4) * 1.6, 0.0, 1.0)
		for i in drips.size():
			var dx := -14.0 + 12.0 * float(i)
			draw_rect(Rect2(dx, 0.0, 3.0, drips[i] * g), Color(col.r, col.g, col.b, a * 0.8))
