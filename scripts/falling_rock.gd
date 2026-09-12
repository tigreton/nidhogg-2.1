class_name FallingRock
extends Node2D
## Roca que cae del cielo (modo caos): fase de aviso con diana en el suelo
## y luego caída; el impacto lo resuelve game.gd.

var phase := "warn"   # warn | fall
var t := 0.85         # segundos de aviso restantes
var target_y := 560.0
var spin := 0.0


func _ready() -> void:
	z_index = 18


func _process(delta: float) -> void:
	if phase == "fall":
		rotation += spin * delta
	queue_redraw()


func _draw() -> void:
	var ty := target_y - position.y
	if phase == "warn":
		var pulse := 0.5 + 0.5 * sin(t * 18.0)
		var a := 0.35 + 0.4 * pulse
		draw_arc(Vector2(0, ty), 30.0 + 6.0 * pulse, 0.0, TAU, 26, Color(1.0, 0.25, 0.2, a), 3.0)
		draw_arc(Vector2(0, ty), 12.0, 0.0, TAU, 16, Color(1.0, 0.25, 0.2, a), 2.0)
		# haz de aviso desde el cielo
		draw_rect(Rect2(-3, -200, 6, ty + 150.0), Color(1.0, 0.25, 0.2, 0.10 + 0.08 * pulse))
		_rock_shape(Vector2(0, -60.0 - 40.0 * pulse), 0.9)
	else:
		# estela de caída
		draw_rect(Rect2(-5, -260, 10, 262), Color(0.8, 0.75, 0.7, 0.12))
		_rock_shape(Vector2.ZERO, 1.0)


func _rock_shape(at: Vector2, s: float) -> void:
	var pts := PackedVector2Array([
		Vector2(-16, -8), Vector2(-6, -18), Vector2(10, -15), Vector2(17, -2),
		Vector2(9, 14), Vector2(-8, 15), Vector2(-17, 4),
	])
	var scaled := PackedVector2Array()
	for p in pts:
		scaled.append(at + p * s)
	draw_colored_polygon(scaled, Color(0.45, 0.42, 0.48))
	draw_circle(at + Vector2(-5, -4) * s, 3.5 * s, Color(0.32, 0.30, 0.36))
	draw_circle(at + Vector2(6, 4) * s, 2.5 * s, Color(0.32, 0.30, 0.36))
