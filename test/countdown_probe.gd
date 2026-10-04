extends Node
## Probe temporal del ciclo round_lock / cuenta atrás / punto:
##  1. arranca SIN skip_countdown: 3·2·1 una sola vez y descongelado
##  2. anota un punto forzado: congelado 1,4 s → nueva 3·2·1 → descongelado
##   godot --headless --path . res://test/countdown_probe.tscn

var game: Node
var t0 := 0.0
var fails := 0

func _ready() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	add_child(game)
	t0 = Time.get_ticks_msec()
	for i in 9:
		await get_tree().create_timer(0.5).timeout
		_sample()
	# punto forzado: P1 con el derecho de avance, pegado a la meta derecha
	var p1 = game.players[0]
	game.right_of_way = p1
	p1.position.x = game.LEVEL_W - 10.0
	print("PUNTO FORZADO")
	for i in 16:
		await get_tree().create_timer(0.5).timeout
		_sample()
	_veredicto()
	get_tree().quit(0 if fails == 0 else 1)

func _sample() -> void:
	var ms := Time.get_ticks_msec() - t0
	print("t=%.1f rl=%.2f msg=%s frozen=%s pos=(%.0f,%.0f)" % [
		ms / 1000.0, game.round_lock, game.msg_label.text,
		game.players[0].frozen, game.players[0].position.x, game.players[0].position.y])

func _veredicto() -> void:
	var p1 = game.players[0]
	# tras el punto: se anotó, hubo recongelado y YA se descongeló de nuevo
	if game.scores[0] != 1:
		fails += 1
		print("FAIL: el punto no se anotó, scores=%s" % [game.scores])
	if game.pending_restart:
		fails += 1
		print("FAIL: pending_restart quedó a true")
	if p1.frozen:
		fails += 1
		print("FAIL: P1 sigue congelado tras la segunda cuenta atrás")
	if game.round_lock > 0.0:
		fails += 1
		print("FAIL: round_lock=%.2f > 0 al final" % game.round_lock)
	print("RESULT: %s (scores=%s)" % ["ALL OK" if fails == 0 else "FAILED", game.scores])
