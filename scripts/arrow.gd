class_name Arrow
extends Node2D
## Flecha de arco: vuela recta a una altura, rebota en guardias a la misma
## altura y mata a quien atraviese. Tras 6 rebotes queda clavada.

var vel := Vector2(600.0, 0.0)
var height: int = 1        # H de la flecha: 0 LOW, 1 MID, 2 HIGH
var bounces := 0
var thrower: Player = null
var stuck := false

const ARROW_TEX := preload("res://art/sprites/weapon_arrow.png")


func _ready() -> void:
	z_index = 16


func tint() -> Color:
	var c := Color(0.82, 0.7, 0.4)
	return c.darkened(0.12 * float(bounces))


func _draw() -> void:
	var dir := 1.0 if vel.x >= 0.0 else -1.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1.0))
	draw_texture_rect(ARROW_TEX, Rect2(-14.0, -3.0, 28.0, 6.0), false, tint())
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
