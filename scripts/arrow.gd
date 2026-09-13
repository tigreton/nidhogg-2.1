class_name Arrow
extends Node2D
## Flecha de arco: vuela recta a una altura, rebota en guardias a la misma
## altura y mata a quien atraviese. Tras 6 rebotes queda clavada.

var vel := Vector2(600.0, 0.0)
var height: int = 1        # H de la flecha: 0 LOW, 1 MID, 2 HIGH
var bounces := 0
var thrower: Player = null
var stuck := false


func _ready() -> void:
	z_index = 16


func tint() -> Color:
	var c := Color(0.82, 0.7, 0.4)
	return c.darkened(0.12 * float(bounces))


func _draw() -> void:
	var dark := Color(0.05, 0.04, 0.08)
	var dir := 1.0 if vel.x >= 0.0 else -1.0
	draw_line(Vector2(-18 * dir, 0), Vector2(12 * dir, 0), dark, 4.0)
	draw_line(Vector2(-18 * dir, 0), Vector2(12 * dir, 0), tint(), 2.5)
	draw_colored_polygon(PackedVector2Array([Vector2(12 * dir, 0), Vector2(4 * dir, -4), Vector2(4 * dir, 4)]), Color(0.9, 0.9, 0.95))
	draw_line(Vector2(-18 * dir, -4), Vector2(-14 * dir, 4), Color(0.6, 0.45, 0.25), 2.0)
	draw_line(Vector2(-16 * dir, -4), Vector2(-12 * dir, 4), Color(0.6, 0.45, 0.25), 2.0)
