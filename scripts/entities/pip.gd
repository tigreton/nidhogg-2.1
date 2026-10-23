class_name Pip
extends Node2D
## Cuadro del HUD de secciones: hueco o relleno del color conquistador.

var TEX_FILLED: Texture2D = ArtPack.tex("pip_filled")
var TEX_HOLLOW: Texture2D = ArtPack.tex("pip_hollow")
var fill_col := Color(0, 0, 0, 0)
var edge_col := Color(0.65, 0.63, 0.72)


func _draw() -> void:
	draw_texture(TEX_HOLLOW, Vector2(-13.0, -13.0))
	if fill_col.a > 0.0:
		draw_texture_rect(TEX_FILLED, Rect2(-13.0, -13.0, 26.0, 26.0), false, fill_col)
