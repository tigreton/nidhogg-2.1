class_name SwordProjectile
extends Node2D
## Espada lanzada: vuela recta girando, la lógica de impacto la resuelve el juego.

var vel := Vector2(760.0, 0.0)
var spin := 18.0
var thrower: Player = null
var color := Color(0.87, 0.9, 0.95)
var weapon_id := "florete"
var trail: Line2D
const TRAIL_POINTS := 10


func _ready() -> void:
	z_index = 15
	trail = Line2D.new()
	trail.top_level = true
	trail.width = 4.0
	trail.z_index = 14
	var grad := Gradient.new()
	grad.set_color(0, Color(color.r, color.g, color.b, 0.0))
	grad.set_color(1, Color(color.r, color.g, color.b, 0.55))
	trail.gradient = grad
	add_child(trail)


func _process(delta: float) -> void:
	rotation += spin * delta
	if trail != null:
		while trail.get_point_count() >= TRAIL_POINTS:
			trail.remove_point(0)
		var last := trail.get_point_count() - 1
		if last < 0 or trail.get_point_position(last).distance_to(global_position) > 6.0:
			trail.add_point(global_position)


func _draw() -> void:
	var dark := Color(0.05, 0.04, 0.08)
	draw_line(Vector2(-21, 0), Vector2(-13, 0), Color(0.35, 0.22, 0.1), 5.0)
	draw_line(Vector2(-14, -4), Vector2(-14, 4), dark, 3.0)
	draw_line(Vector2(-14, 0), Vector2(16, 0), dark, 7.0)
	draw_line(Vector2(-14, 0), Vector2(16, 0), color, 4.0)
	draw_circle(Vector2(16, 0), 2.5, Color.WHITE)
