class_name CrumbleTile
extends Node2D
## Tramo de plataforma que tiembla al pisarlo y cae (tarea 70).

var x0: float
var x1: float
var y: float
var body: StaticBody2D
var state := 0          # 0 intacto, 1 temblando, 2 caído
var t := 0.0


func _init(px0: float, px1: float, py: float) -> void:
	x0 = px0
	x1 = px1
	y = py
	position = Vector2((x0 + x1) * 0.5, y + 8.0)
	body = StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(x1 - x0, 16.0)
	cs.shape = rect
	body.add_child(cs)
	add_child(body)


func restore(game: Node) -> void:
	state = 0
	t = 0.0
	position = Vector2((x0 + x1) * 0.5, y + 8.0)
	rotation = 0.0
	body.get_child(0).set_deferred("disabled", false)
	var ya := false
	for top in game._tops:
		if absf(float(top["x0"]) - x0) < 0.5 and absf(float(top["y"]) - y) < 0.5:
			ya = true
			break
	if not ya:
		game._register_top(x0, x1, y)
	queue_redraw()


func _top_drop(game: Node) -> void:
	# quita la entrada de _tops de este tramo (por x0 e y)
	for i in range(game._tops.size() - 1, -1, -1):
		var top: Dictionary = game._tops[i]
		if absf(float(top["x0"]) - x0) < 0.5 and absf(float(top["y"]) - y) < 0.5:
			game._tops.remove_at(i)


func _process(delta: float) -> void:
	var game := get_parent().get_parent()
	match state:
		0:
			for p in game.players:
				if p.is_on_floor() and p.position.y > y - 40.0 and p.position.y < y + 8.0 and p.position.x > x0 and p.position.x < x1:
					state = 1
					t = 0.0
					break
		1:
			t += delta
			position.x = (x0 + x1) * 0.5 + sin(t * 60.0) * 2.5
			if t >= 0.4:
				state = 2
				position.x = (x0 + x1) * 0.5
				body.get_child(0).set_deferred("disabled", true)
				_top_drop(game)
		2:
			position.y += 620.0 * delta
			rotation += delta * 1.2
			if position.y > 900.0:
				position.y = 900.0
	queue_redraw()


func _draw() -> void:
	if state == 2:
		draw_rect(Rect2(-(x1 - x0) * 0.5, -16.0, x1 - x0, 16.0), Color(0.16, 0.14, 0.22))
		return
	var host := get_parent().get_parent()
	draw_texture_rect(host.TEX_FLOOR, Rect2(-(x1 - x0) * 0.5, -8.0, x1 - x0, 16.0), true, host.col_plat)
	draw_texture_rect(host.TEX_FLOOR, Rect2(-(x1 - x0) * 0.5, -8.0, x1 - x0, 5.0), true, host.col_plat_top)
