class_name Torch
extends Node2D
## Antorcha con llama parpadeante para dar vida a las metas y la aldea.

var t := 0.0


func _ready() -> void:
	t = randf() * 10.0


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	draw_line(Vector2(0, 0), Vector2(0, -88), Color(0.16, 0.12, 0.10), 8.0)
	draw_line(Vector2(0, 0), Vector2(0, -88), Color(0.30, 0.22, 0.15), 4.0)
	draw_circle(Vector2(0, -94), 9.0, Color(0.20, 0.16, 0.13))
	var f := 1.0 + 0.16 * sin(t * 13.0) + 0.08 * sin(t * 29.0)
	draw_circle(Vector2(0, -102), 26.0 * f, Color(1.0, 0.55, 0.15, 0.09))
	draw_colored_polygon(PackedVector2Array([Vector2(-7, -96), Vector2(0, -96.0 - 24.0 * f), Vector2(7, -96)]), Color(1.0, 0.60, 0.16, 0.95))
	draw_colored_polygon(PackedVector2Array([Vector2(-3.4, -96), Vector2(0, -96.0 - 13.0 * f), Vector2(3.4, -96)]), Color(1.0, 0.88, 0.45))
