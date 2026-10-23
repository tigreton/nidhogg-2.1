class_name VictoryWorm
extends Node2D
## El gusano del Nidhogg: baja del techo y envuelve al ganador.

# la tira de 300x103 se corta en 3 segmentos de 100 px
const WORM_SEGS := [
	Rect2(0.0, 0.0, 100.0, 103.0),
	Rect2(100.0, 0.0, 100.0, 103.0),
	Rect2(200.0, 0.0, 100.0, 103.0),
]
var t := 0.0
var target := Vector2.ZERO
var col := Color(0.22, 0.5, 0.2)


func _init(pos: Vector2) -> void:
	target = pos
	position = pos + Vector2(0, -620.0)


func _process(delta: float) -> void:
	t = minf(t + delta / 1.2, 1.0)
	position.y = lerpf(target.y - 620.0, target.y - 10.0, t)
	queue_redraw()


func _draw() -> void:
	var chomp := 0.35 + 0.65 * t
	var wt: Texture2D = ArtPack.tex("worm_body")
	# cuerpo: 6 segmentos con la textura (las 3 regiones, repetidas)
	for i in 6:
		var cy := -float(i) * 44.0 - 30.0
		draw_texture_rect_region(wt, Rect2(-32.0, cy - 33.0, 64.0, 66.0), WORM_SEGS[i % 3])
	# cabeza: el segmento 0 un punto más grande
	draw_texture_rect_region(wt, Rect2(-37.0, -66.0, 74.0, 76.0), WORM_SEGS[0])
	# mandíbulas y ojos (procedurales, como antes)
	var open_ang := 1.2 * (1.0 - chomp)
	for s in [-1.0, 1.0]:
		var pts := PackedVector2Array([
			Vector2(0, -20),
			Vector2(s * 44.0 * cos(open_ang), -20.0 + 44.0 * sin(open_ang)),
			Vector2(s * 10.0, 26.0),
		])
		draw_colored_polygon(pts, Color(0.16, 0.38, 0.16))
	draw_circle(Vector2(-12, -34), 4.0, Color.YELLOW)
	draw_circle(Vector2(12, -34), 4.0, Color.YELLOW)
