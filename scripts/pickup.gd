class_name SwordPickup
extends Node2D
## Espada caída en el suelo: se recoge pasando por encima.

var color := Color(0.87, 0.9, 0.95)
var t := 0.0
var weapon_id := "florete"

var WEAPON_TEX := {
	"florete": ArtPack.tex("weapon_rapier"),
	"espada": ArtPack.tex("weapon_longsword"),
	"daga": ArtPack.tex("weapon_dagger"),
	"arco": ArtPack.tex("weapon_bow"),
}


func _ready() -> void:
	z_index = 6


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var a := 0.22 + 0.1 * sin(t * 5.0)
	draw_arc(Vector2.ZERO, 17.0 + 1.5 * sin(t * 5.0), 0.0, TAU, 24, Color(1, 1, 1, a), 2.0)
	draw_set_transform(Vector2.ZERO, -0.25, Vector2(0.8, 0.8))
	var tex: Texture2D = WEAPON_TEX.get(weapon_id, WEAPON_TEX["florete"])
	draw_texture(tex, -tex.get_size() * 0.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
