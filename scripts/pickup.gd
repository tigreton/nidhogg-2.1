class_name SwordPickup
extends Node2D
## Espada caída en el suelo: se recoge pasando por encima.

var color := Color(0.87, 0.9, 0.95)
var t := 0.0


func _ready() -> void:
	z_index = 6


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var a := 0.22 + 0.1 * sin(t * 5.0)
	draw_arc(Vector2.ZERO, 17.0 + 1.5 * sin(t * 5.0), 0.0, TAU, 24, Color(1, 1, 1, a), 2.0)
	draw_set_transform(Vector2.ZERO, -0.25, Vector2.ONE)
	var dark := Color(0.05, 0.04, 0.08)
	draw_line(Vector2(-19, 2), Vector2(-11, 2), Color(0.35, 0.22, 0.1), 5.0)
	draw_line(Vector2(-12, -2), Vector2(-12, 6), dark, 3.0)
	draw_line(Vector2(-12, 2), Vector2(18, 2), dark, 7.0)
	draw_line(Vector2(-12, 2), Vector2(18, 2), color, 4.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
