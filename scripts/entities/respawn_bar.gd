class_name RespawnBar
extends Node2D
## Barra de progreso sobre el punto de reaparición.

var frac := 0.0
var col := Color.WHITE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-30, -6, 60, 12), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(-28, -4, 56.0 * clampf(frac, 0.0, 1.0), 8.0), col)
