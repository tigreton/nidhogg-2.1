class_name SectionGate
extends Node2D
## Reja entre secciones: cuerpo estático + barrotes visibles. Al abrirse,
## los barrotes se recogen hacia arriba y la colisión se desactiva.

var body: StaticBody2D
var open := false


func _init(cx: float) -> void:
	position = Vector2(cx, 0.0)
	body = StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14.0, 700.0)
	cs.shape = rect
	cs.position = Vector2(0, 350.0)
	body.add_child(cs)
	add_child(body)


func set_open(v: bool) -> void:
	open = v
	body.get_child(0).set_deferred("disabled", v)
	queue_redraw()


func _draw() -> void:
	var iron := Color(0.16, 0.15, 0.19)
	var lite := Color(0.27, 0.26, 0.32)
	draw_rect(Rect2(-14, 60.0, 8.0, 508.0), iron)
	draw_rect(Rect2(6.0, 60.0, 8.0, 508.0), iron)
	var top := 66.0 if open else 130.0
	var bot := 126.0 if open else 560.0
	var bx := -6.0
	while bx <= 6.0:
		draw_rect(Rect2(bx - 2.5, top, 5.0, bot - top), lite)
		bx += 6.0
	draw_rect(Rect2(-10.0, top - 6.0, 20.0, 6.0), iron)
