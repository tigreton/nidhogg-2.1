class_name Cloud
extends Node2D
## Nube que deriva lentamente y se envuelve por los bordes del nivel.

var speed := 12.0
var extent := 4800.0


func _init(s: float, ext: float) -> void:
	speed = s
	extent = ext


func _process(delta: float) -> void:
	position.x += speed * delta
	if position.x > extent + 300.0:
		position.x = -300.0


func _draw() -> void:
	var col := Color(0.13, 0.125, 0.19, 0.85)
	for b in [Vector2(-46, 4), Vector2(0, -8), Vector2(46, 4)]:
		var r: float = 30.0 if b.y < 0.0 else 24.0
		draw_circle(b, r, col)
	draw_rect(Rect2(-60, 0, 120, 18), col)
