class_name GlowSpot
extends Node2D
## Resplandor cálido y pulsante (ventanas de la casa).

var t := 0.0
var radius := 30.0


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var f := 0.8 + 0.2 * sin(t * 2.2)
	draw_circle(Vector2.ZERO, radius * f, Color(1.0, 0.75, 0.3, 0.10))
