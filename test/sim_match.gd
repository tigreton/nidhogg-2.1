extends Node
## Simulación bot vs bot de una partida completa (portada del hermano):
## dos bots NORMAL juegan hasta 2 minutos; con semilla fija es reproducible.
## Verifica el flujo de punta a punta: bajas, puntos y cobertura de estados.
##   godot --headless --path . res://test/sim_match.tscn

const SIM_SECONDS := 180.0
const SIM_SEED := 20260907

var game: Node
var _kills := 0
var _points := 0
var _states := {}


func _ready() -> void:
	seed(SIM_SEED)
	game = load("res://scenes/main.tscn").instantiate()
	game.skip_countdown = true   # antes de entrar al árbol: _ready ya arranca la ronda (tarea 66)
	add_child(game)
	# arranque determinista: frames de física fijos en lugar de create_timer
	# (el timer de reloj varía con la carga en headless y desincroniza el RNG)
	for i in 12:
		await get_tree().physics_frame
	game.bot_level = 2        # P2/P4 a NORMAL
	game.ally_bot_level = 2   # P1/P3 a NORMAL
	for p in game.players:
		p.is_bot = true
		p.died.connect(func(_pl): _kills += 1)

	var score_sum: int = game.scores[0] + game.scores[1]
	var frames := int(SIM_SECONDS * 60.0)
	var t := 0
	while t < frames and not game.match_over:
		await get_tree().physics_frame
		t += 1
		var s: int = game.scores[0] + game.scores[1]
		if s > score_sum:
			score_sum = s
			_points += 1
		if t % 6 == 0:
			for p in game.players:
				var k: String = Player.State.find_key(p.state)
				_states[k] = int(_states.get(k, 0)) + 6

	var ok: bool = _kills >= 2 and _states.has("RUN") and _states.has("JUMP") \
			and (_points >= 1 or game.match_over)
	print("SIM RESULT t=%.1fs kills=%d puntos=%d match_over=%s" % [t / 60.0, _kills, _points, game.match_over])
	print("SIM states=", _states)
	print("SIM ", "PASS" if ok else "FAIL")
	get_tree().quit(0 if ok else 1)
