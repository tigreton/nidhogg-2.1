class_name SwordProjectile
extends Node2D
## Espada lanzada: vuela recta girando, la lógica de impacto la resuelve el juego.

var vel := Vector2(760.0, 0.0)
var spin := 18.0
var thrower: Player = null
var color := Color(0.87, 0.9, 0.95)


func _ready() -> void:
	z_index = 15


func _process(delta: float) -> void:
	rotation += spin * delta


func _draw() -> void:
	var dark := Color(0.05, 0.04, 0.08)
	draw_line(Vector2(-21, 0), Vector2(-13, 0), Color(0.35, 0.22, 0.1), 5.0)
	draw_line(Vector2(-14, -4), Vector2(-14, 4), dark, 3.0)
	draw_line(Vector2(-14, 0), Vector2(16, 0), dark, 7.0)
	draw_line(Vector2(-14, 0), Vector2(16, 0), color, 4.0)
	draw_circle(Vector2(16, 0), 2.5, Color.WHITE)
