class_name SwordPickup
extends Node2D
## Espada caída en el suelo: se recoge pasando por encima.

var color := Color(0.87, 0.9, 0.95)
var t := 0.0
var weapon_id := "florete"

const WEAPON_TEX := {
	"florete": preload("res://art/sprites/weapon_rapier.png"),
	"espada": preload("res://art/sprites/weapon_longsword.png"),
	"daga": preload("res://art/sprites/weapon_dagger.png"),
	"arco": preload("res://art/sprites/weapon_bow.png"),
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
