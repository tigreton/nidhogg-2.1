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

var WEAPON_TEX := {
	"florete": ArtPack.tex("weapon_rapier"),
	"espada": ArtPack.tex("weapon_longsword"),
	"daga": ArtPack.tex("weapon_dagger"),
	"arco": ArtPack.tex("weapon_bow"),
}


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
	var tex: Texture2D = WEAPON_TEX.get(weapon_id, WEAPON_TEX["florete"])
	var w := tex.get_width() * 0.8
	var h := tex.get_height() * 0.8
	draw_texture_rect(tex, Rect2(-w * 0.5, -h * 0.5, w, h), false)
