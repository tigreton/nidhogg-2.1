# Tarea 42 — Runner de tests por suites (determinista)

**Dificultad:** media · **Archivos:** nuevos `test/test_runner.gd`, `test/test_runner.tscn`, `test/suite_movimiento.gd`, `test/suite_combate.gd` · **Prerrequisitos:** ninguno (recomendado tras la 41)

## Objetivo

Portar el harness de tests del proyecto hermano: un runner que ejecuta suites
independientes con **física frame a frame determinista** (nada de timers de
reloj dentro de los asserts) y aislamiento entre tests. Hoy toda la regresión
vive en un único smoke test secuencial; si algo se rompe a mitad, contamina el
resto. Las suites assertan el comportamiento ACTUAL (línea base): las tareas
43/44/47/48/49 actualizarán estos números al cambiar la física y el combate.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `test/smoke_test.gd` es la referencia del patrón de arranque: instancia
  `res://scenes/main.tscn` como hijo, `await get_tree().create_timer(0.2).timeout`,
  y usa `game.players[0]` / `game.players[1]`. El InputMap lo registra
  `game.gd::_ready()` → `_setup_input()` al entrar en el árbol.
- `scripts/player.gd` — `class_name Player`: `enum State { IDLE=0, RUN=1,
  JUMP=2, DIVEKICK=3, ATTACK=4, STUNNED=5, KNOCKDOWN=6, DEAD=7, ROLL=8,
  DIVE=9, SIDEKICK=10 }`, `enum H { LOW=0, MID=1, HIGH=2 }`. Constantes
  actuales: `SPEED 330`, `JUMP_VELOCITY -700`, `GRAVITY 1700`,
  `ROLL_SPEED 520`, `DIVE_SPEED 546`.
- `scripts/game.gd` — relevantes para los tests: `players`, `scores`,
  `right_of_way`, `round_lock`, `match_over`, `respawn_timers`, `projectiles`,
  `pickups`, `arrows`; la cadena de resolución corre en `_physics_process`
  (padre procesa antes que los hijos, así que el juego ve el input del mismo
  tick). El `_kill` pausa el árbol 0,08 s (hitstop) y ralentiza el tiempo
  0,5 s: por eso tras matar/derribar se espera con `create_timer` (tiempo
  real), no con frames.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en
  español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Crear `test/test_runner.tscn`

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://test/test_runner.gd" id="1_runner"]

[node name="TestRunner" type="Node"]
script = ExtResource("1_runner")
```

### 2. Crear `test/test_runner.gd` completo

```gdscript
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
```

### 3. Crear `test/suite_movimiento.gd` completo (línea base ACTUAL)

```gdscript
extends RefCounted
## Suite de movimiento: física actual como línea base. Las tareas 43/44
## (salto doble y aceleración) actualizan los rangos marcados con `# L43`/`# L44`.

var runner


func get_tests() -> Array:
	return [
		["correr_30_frames", _t_correr],
		["salto_parado_apice", _t_salto_parado],
		["salto_carrerilla_distancia", _t_salto_carrera],
		["rodada_estado_y_duracion", _t_rodada],
		["dive_corriendo", _t_dive],
	]


func _reset(x1: float, x2: float) -> void:
	var g: Node = runner.game
	for pair in [[g.players[0], x1], [g.players[1], x2]]:
		var p: Player = pair[0]
		p.position = Vector2(pair[1], 531.0)
		p.velocity = Vector2.ZERO
		p.state = Player.State.IDLE
		p.has_sword = true
		p.weapon_id = "florete"
		p.invuln_time = 0.0
		p.facing = 1
		p.attack_time = 0.0
		p.bow_time = 0.0
		g.respawn_timers[p.player_id - 1] = 0.0
	g.round_lock = 0.0
	g.right_of_way = null


func _t_correr() -> bool:
	_reset(1600.0, 4400.0)
	var x0: float = runner.game.players[0].position.x
	Input.action_press("p1_right")
	await runner.step_physics(30)
	Input.action_release("p1_right")
	await runner.step_physics(5)
	var dx: float = runner.game.players[0].position.x - x0
	runner.release_all()
	return runner.check(dx >= 150.0, "correr recorre >=150 px en 35 frames (hoy ~175)")  # L44: >=130


func _t_salto_parado() -> bool:
	_reset(1600.0, 4400.0)
	Input.action_press("p1_jump")
	await runner.step_physics(1)
	Input.action_release("p1_jump")
	var min_y: float = runner.game.players[0].position.y
	for i in 55:
		await runner.step_physics(1)
		min_y = minf(min_y, runner.game.players[0].position.y)
	var rise: float = 531.0 - min_y
	runner.release_all()
	return runner.check(rise >= 120.0 and rise <= 170.0, "salto parado sube 120-170 px (hoy ~144)")  # L43: 55-80


func _t_salto_carrera() -> bool:
	_reset(1600.0, 4400.0)
	Input.action_press("p1_right")
	await runner.step_physics(8)
	var x0: float = runner.game.players[0].position.x
	Input.action_press("p1_jump")
	await runner.step_physics(1)
	Input.action_release("p1_jump")
	await runner.step_physics(70)
	var p: Player = runner.game.players[0]
	runner.release_all()
	return runner.check(p.is_on_floor() and p.position.x - x0 >= 220.0,
			"salto con carrerilla recorre >=220 px en el aire (hoy ~270)")  # L43/L44: >=180


func _t_rodada() -> bool:
	_reset(1600.0, 4400.0)
	Input.action_press("p1_down")
	await runner.step_physics(1)
	Input.action_press("p1_jump")
	await runner.step_physics(3)
	var rolling: bool = runner.game.players[0].state == Player.State.ROLL
	Input.action_release("p1_jump")
	Input.action_release("p1_down")
	await runner.step_physics(30)
	var done: bool = runner.game.players[0].state == Player.State.IDLE
	runner.release_all()
	return runner.check(rolling, "down+jump entra en ROLL") \
			and runner.check(done, "la rodada termina sola en IDLE (~20 frames)")


func _t_dive() -> bool:
	_reset(1550.0, 4400.0)
	Input.action_press("p1_right")
	await runner.step_physics(12)
	Input.action_press("p1_down")
	Input.action_press("p1_jump")
	await runner.step_physics(4)
	var p: Player = runner.game.players[0]
	var diving: bool = p.state == Player.State.DIVE and absf(absf(p.velocity.x) - 546.0) < 10.0
	Input.action_release("p1_jump")
	Input.action_release("p1_down")
	Input.action_release("p1_right")
	await runner.step_physics(10)
	runner.release_all()
	return runner.check(diving, "corriendo+abajo+salto entra en DIVE a 546 px/s")
```

### 4. Crear `test/suite_combate.gd` completo (línea base ACTUAL)

```gdscript
extends RefCounted
## Suite de combate: reglas actuales como línea base. Las tareas 47/48/49
## actualizan los casos marcados con `# L47`/`# L48`/`# L49`.

var runner


func get_tests() -> Array:
	return [
		["choque_doble_ataque_misma_altura", _t_choque],
		["guardia_pasiva_distinta_altura_mata", _t_guardia],
		["espada_lanzada_desviada_por_guardia", _t_lanzada],
		["punetazo_desarma", _t_punetazo],
		["flecha_rebota_en_guardia_igual", _t_flecha],
	]


func _reset(x1: float, x2: float) -> void:
	var g: Node = runner.game
	for pair in [[g.players[0], x1], [g.players[1], x2]]:
		var p: Player = pair[0]
		p.position = Vector2(pair[1], 531.0)
		p.velocity = Vector2.ZERO
		p.state = Player.State.IDLE
		p.has_sword = true
		p.weapon_id = "florete"
		p.invuln_time = 0.0
		p.facing = 1
		p.attack_time = 0.0
		p.bow_time = 0.0
		g.respawn_timers[p.player_id - 1] = 0.0
	g.round_lock = 0.0
	g.right_of_way = null


func _t_choque() -> bool:
	_reset(1600.0, 1670.0)
	await runner.step_physics(1)
	Input.action_press("p1_attack")
	Input.action_press("p2_attack")
	await runner.step_physics(9)
	var p1: Player = runner.game.players[0]
	var p2: Player = runner.game.players[1]
	var stunned: bool = p1.state == Player.State.STUNNED and p2.state == Player.State.STUNNED
	runner.release_all()
	await runner.wait(0.6)
	return runner.check(stunned, "doble ataque MID simultáneo: ambos STUNNED")  # L47: sigue igual (doble ataque)


func _t_guardia() -> bool:
	_reset(1500.0, 1650.0)
	Input.action_press("p2_down")   # guardia baja
	Input.action_press("p1_right")  # corre en MID contra la guardia
	await runner.step_physics(40)
	var p1: Player = runner.game.players[0]
	runner.release_all()
	var dead: bool = p1.state == Player.State.DEAD
	await runner.wait(0.7)
	_reset(1600.0, 4400.0)
	return runner.check(dead, "correr en MID contra guardia LOW: empalamiento")


func _t_lanzada() -> bool:
	_reset(1600.0, 1750.0)
	await runner.step_physics(1)
	Input.action_press("p1_throw")
	await runner.step_physics(2)
	Input.action_release("p1_throw")
	await runner.step_physics(6)
	var p2: Player = runner.game.players[1]
	var alive: bool = p2.state != Player.State.DEAD
	runner.release_all()
	await runner.wait(0.4)
	var pickup: bool = runner.game.pickups.size() >= 1
	_reset(1600.0, 4400.0)
	return runner.check(alive, "la guardia MEDIA desvía la espada lanzada") \
			and runner.check(pickup, "la espada desviada cae al suelo")  # L49: la guardia a CUALQUIER altura que mate el arma la desvía


func _t_punetazo() -> bool:
	_reset(1600.0, 1650.0)
	runner.game.players[0].has_sword = false
	await runner.step_physics(1)
	Input.action_press("p1_attack")
	await runner.step_physics(9)
	Input.action_release("p1_attack")
	var p2: Player = runner.game.players[1]
	var ok: bool = p2.state == Player.State.STUNNED and not p2.has_sword
	runner.release_all()
	await runner.wait(0.8)
	_reset(1600.0, 4400.0)
	return runner.check(ok, "el puñetazo de pie desarma y aturde")


func _t_flecha() -> bool:
	_reset(1600.0, 1750.0)
	runner.game.players[0].weapon_id = "arco"
	Input.action_press("p2_up")   # guardia alta = misma altura que la flecha
	await runner.step_physics(1)
	Input.action_press("p1_attack")
	await runner.step_physics(32)   # tensar 0,53 s  # L48: 66 frames (1,1 s obligatorios)
	Input.action_release("p1_attack")
	await runner.step_physics(30)
	var g: Node = runner.game
	var p2: Player = g.players[1]
	var bounced: bool = g.arrows.size() >= 1 and g.arrows[0].bounces >= 1 and p2.state != Player.State.DEAD
	runner.release_all()
	await runner.wait(0.5)
	_reset(1600.0, 4400.0)
	return runner.check(bounced, "la flecha rebota en la guardia a su misma altura")
```

### 5. Ejecutar

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/test_runner.tscn
```

Última línea esperada: `RESULT: ALL PASSED (10)`. Si una suite falla por
timing (un frame antes/después), ajusta SOLO el número de frames de esa
espera — nunca conviertas los pasos de física en timers.

## Qué NO hacer

- No toques `scripts/`, `scenes/` ni `test/smoke_test.gd`: esta tarea solo
  AÑADE archivos. El smoke test sigue siendo la verificación de las tareas.
- No uses `assert()` de Godot (se compila fuera en release): usa
  `runner.check(...)`.
- No registres timers dentro de los asserts de movimiento: solo
  `step_physics`. `wait()` solo tras muertes/choques (hitstop).
- No cambies el orden del enum de Player ni añadas estados.

## Criterios de aceptación

1. `res://test/test_runner.tscn` termina con `RESULT: ALL PASSED (10)`.
2. Cada test deja el juego en estado limpio (el siguiente no hereda posiciones
   ni timers de respawn).
3. El smoke test sigue pasando.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/test_runner.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Últimas líneas esperadas: `RESULT: ALL PASSED (10)` y `SMOKE OK - todas las mecánicas funcionan`.
