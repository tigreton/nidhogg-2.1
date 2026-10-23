class_name Candle
extends Node2D
## Vela fantasmal de la cripta: llama verde parpadeante.

var t := 0.0


func _ready() -> void:
	t = randf() * 10.0


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	draw_line(Vector2(0, 0), Vector2(0, -26.0), Color(0.75, 0.72, 0.6), 8.0)
	var f := 1.0 + 0.2 * sin(t * 9.0)
	draw_circle(Vector2(0, -32.0), 18.0 * f, Color(0.4, 0.9, 0.55, 0.10))
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -28), Vector2(0, -28.0 - 14.0 * f), Vector2(4, -28)]), Color(0.55, 0.95, 0.65, 0.95))
