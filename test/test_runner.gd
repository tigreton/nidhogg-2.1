extends Node
## Runner de suites headless (portado del proyecto hermano). Uso:
##   godot --headless --path . res://test/test_runner.tscn
## Cada suite es un RefCounted con `var runner` y `get_tests() -> Array` de
## pares [nombre, Callable]; cada test es una corrutina que devuelve true/false.
## Avance determinista: los asserts usan step_physics (1 paso = 1 tick de
## física), nunca timers de reloj. Entre tests se sueltan todas las acciones.

const SUITES := [
	"res://test/suite_movimiento.gd",
	"res://test/suite_combate.gd",
]

var game: Node
var _current := "arranque"


func _ready() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	add_child(game)
	await get_tree().create_timer(0.2).timeout
	var fails := 0
	var total := 0
	for path in SUITES:
		var suite: RefCounted = (load(path) as Script).new()
		suite.runner = self
		for t in suite.get_tests():
			_current = "%s::%s" % [path.get_file().get_basename(), String(t[0])]
			var r = await t[1].call()
			total += 1
			if r != true:
				fails += 1
				print("FALLO: " + _current)
	if fails == 0:
		print("RESULT: ALL PASSED (%d)" % total)
		get_tree().quit(0)
	else:
		print("RESULT: FAILED (%d/%d)" % [fails, total])
		get_tree().quit(1)


## Assert acumulativo: devuelve la condición para encadenar con `and`.
func check(cond: bool, msg: String) -> bool:
	if not cond:
		print("  [%s] %s" % [_current, msg])
	return cond


func step_physics(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func step_frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


## Espera en tiempo real: SOLO tras muertes/choques (hitstop pausa el árbol
## 0,08 s y la cámara lenta escala el tiempo 0,5 s).
func wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func release_all() -> void:
	for a in ["p1_left", "p1_right", "p1_up", "p1_down", "p1_jump", "p1_attack", "p1_throw",
			"p2_left", "p2_right", "p2_up", "p2_down", "p2_jump", "p2_attack", "p2_throw"]:
		if InputMap.has_action(a):
			Input.action_release(a)
