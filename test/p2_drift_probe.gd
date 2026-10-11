extends Node
## Diagnóstico del bug "P2 se mueve solo desde el principio": partida fresca,
## cero input, P2 humano; se registra su x cada 30 frames durante 8 segundos.
##   godot --headless --path . res://test/p2_drift_probe.tscn

var game: Node


func _ready() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.skip_countdown = true
	add_child(game)
	var p2: Player = game.players[1]
	print("PROBE p2.is_bot=", p2.is_bot, " net_remote=", p2.net_remote,
			" net_puppet=", p2.net_puppet, " frozen=", p2.frozen)
	var x0 := p2.position.x
	var frames := int(8.0 * 60.0)
	var t := 0
	var max_drift := 0.0
	var right_held := false
	var any_input := false
	while t < frames:
		await get_tree().physics_frame
		t += 1
		if Input.is_action_pressed("p2_right") or Input.is_action_pressed("p2_left"):
			any_input = true
		if p2.position.x > x0 + 30.0 or p2.position.x < x0 - 30.0:
			right_held = true
		max_drift = maxf(max_drift, absf(p2.position.x - x0))
	var drift: float = p2.position.x - x0
	print("PROBE x0=%.1f x_end=%.1f drift=%.1f max_drift=%.1f" % [x0, p2.position.x, drift, max_drift])
	print("PROBE phantom_input=", any_input, " moved_over_30px=", right_held)
	print("PROBE ", "FAIL: P2 SE MOVIÓ SIN INPUT" if max_drift > 30.0 else "PASS: P2 quieto sin input")
	get_tree().quit(0 if max_drift <= 30.0 else 1)
