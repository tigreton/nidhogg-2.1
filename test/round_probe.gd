extends SceneTree
## Sonda headless: observa round_lock y posiciones 9 s para ver si la cuenta
## atrás de _start_round termina o buclea. Uso:
##   godot --headless --path . --script test/round_probe.gd

var t := 0.0
var game: Node


func _initialize() -> void:
	game = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)


func _process(delta: float) -> bool:
	t += delta
	if fmod(t, 0.5) < delta:
		var rl: float = game.round_lock
		var rw = game.right_of_way
		print("t=%.1f  round_lock=%.2f  msg=%s  p1x=%.0f p2x=%.0f  st1=%d st2=%d" % [
			t, rl, game.msg_label.text,
			game.players[0].position.x, game.players[1].position.x,
			game.players[0].state, game.players[1].state,
		])
		if rw != null:
			print("   right_of_way=P%d" % rw.player_id)
	return t > 9.0
