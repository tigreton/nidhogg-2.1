# Tarea 41 — Trazas de movimiento (CSV de calibración)

**Dificultad:** baja · **Archivos:** nuevos `test/trace_motion.gd`, `test/trace_motion.tscn` · **Prerrequisitos:** ninguno

## Objetivo

Herramienta de medición (portada del proyecto hermano): registrar frame a
frame la posición, velocidad, estado y estancia de P1 mientras corre, salta
parado, salta con carrerilla, hace dive, rueda y ataca. Escribe un CSV que
sirve para calibrar la física (las tareas 43/44 lo usan para verificar sus
cambios) comparando el ápice del salto, la distancia del dive, etc.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- El patrón de herramienta headless ya existe: `test/smoke_test.gd` es un
  `Node` en una escena `.tscn` que instancia `res://scenes/main.tscn`, espera
  `create_timer(0.2)` y usa `game.players[0]`. Copia ese patrón (NO uses
  `extends SceneTree` con `--script`).
- `scripts/player.gd` — `class_name Player`: `state` es un **enum int**
  (`State.IDLE=0 … SIDEKICK=10`); `Player.State.find_key(p.state)` devuelve el
  nombre ("IDLE", "RUN"…). `stance` es int (`H.LOW=0, MID=1, HIGH=2`).
- Zona segura para medir: suelo a `y=531` (centro del jugador), `x` entre
  1000 y 2100 no tiene foso (los fosos están en 700–880 y 2210–2380).
  **Ojo con los techos**: la escalera de plataformas ocupa x=1480–1900
  (y=448/368/288) y el puente x=1900–2690 (y=288): un salto medido en x=1600
  golpea la cabeza en y=493 (464+29) y arruina la línea base. Los saltos se
  miden en x=1300 (parado) y x=1152 (carrerilla: 8 frames de carrera + 270 px
  de vuelo aterrizan en ~1466, antes de la escalera).
- Acciones registradas en runtime por `game.gd::_setup_input()`:
  `p1_left, p1_right, p1_up, p1_down, p1_jump, p1_attack, p1_throw` (y `p2_*`).
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en
  español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Crear `test/trace_motion.tscn`

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://test/trace_motion.gd" id="1_trace"]

[node name="TraceMotion" type="Node"]
script = ExtResource("1_trace")
```

### 2. Crear `test/trace_motion.gd` completo

```gdscript
extends Node
## Trazas de movimiento: registra posición/velocidad/estado de P1 frame a
## frame de física en 6 fases (correr, salto parado, salto con carrerilla,
## dive, rodada, ataque) y escribe res://trace_motion.csv para calibrar.
##   godot --headless --path . res://test/trace_motion.tscn

var game: Node
var p1: Player
var _rows: Array = []
var _f := 0


func _release_all() -> void:
	for a in ["p1_left", "p1_right", "p1_up", "p1_down", "p1_jump", "p1_attack"]:
		Input.action_release(a)


## Reubica a P1 en pie, quieto y sin velocidad en una x segura.
func _at(x: float) -> void:
	p1.position = Vector2(x, 531.0)
	p1.velocity = Vector2.ZERO
	p1.state = Player.State.IDLE
	p1.roll_cd = 0.0
	await _idle(2)


## Avanza n frames de física registrando una fila por frame.
func _idle(frames: int) -> void:
	for i in frames:
		await get_tree().physics_frame
		_f += 1
		_rows.append([_f, "%.4f" % (_f / 60.0), p1.position.x, p1.position.y,
				p1.velocity.x, p1.velocity.y, Player.State.find_key(p1.state), p1.stance])


## Marcador de fase (una fila con solo el nombre, para leer el CSV a ojo).
func _phase(name: String) -> void:
	_rows.append(["# " + name])


func _ready() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	add_child(game)
	await get_tree().create_timer(0.2).timeout
	p1 = game.players[0]
	# P2 lejos (x=4400) para que no interfiera en ninguna fase
	game.players[1].position = Vector2(4400.0, 531.0)
	game.round_lock = 0.0

	# Fase 1: correr 60 frames
	await _at(1600.0)
	_phase("run")
	Input.action_press("p1_right")
	await _idle(60)
	Input.action_release("p1_right")
	await _idle(10)

	# Fase 2: salto de parado (x=1300: sin techo, la escalera está en 1480-1900)
	await _at(1300.0)
	_phase("jump_stand")
	Input.action_press("p1_jump")
	await _idle(1)
	Input.action_release("p1_jump")
	await _idle(55)

	# Fase 3: salto con carrerilla (8 frames de carrera antes; aterriza ~1466)
	await _at(1152.0)
	Input.action_press("p1_right")
	await _idle(8)
	_phase("jump_run")
	Input.action_press("p1_jump")
	await _idle(1)
	Input.action_release("p1_jump")
	await _idle(75)
	Input.action_release("p1_right")

	# Fase 4: dive horizontal (corriendo + abajo + salto)
	await _at(1550.0)
	Input.action_press("p1_right")
	await _idle(10)
	_phase("dive")
	Input.action_press("p1_down")
	Input.action_press("p1_jump")
	await _idle(6)
	Input.action_release("p1_jump")
	Input.action_release("p1_down")
	Input.action_release("p1_right")
	await _idle(60)

	# Fase 5: rodada (parado + abajo + salto)
	await _at(1600.0)
	_phase("roll")
	Input.action_press("p1_down")
	Input.action_press("p1_jump")
	await _idle(2)
	Input.action_release("p1_jump")
	Input.action_release("p1_down")
	await _idle(45)

	# Fase 6: ataque en parado
	await _at(1600.0)
	_phase("attack")
	Input.action_press("p1_attack")
	await _idle(1)
	Input.action_release("p1_attack")
	await _idle(30)

	_release_all()
	var f := FileAccess.open("res://trace_motion.csv", FileAccess.WRITE)
	f.store_line("frame,t,x,y,vx,vy,state,stance")
	for row in _rows:
		f.store_line(",".join(row.map(func(v): return str(v))))
	f.close()
	print("TRAZAS OK - %d filas en res://trace_motion.csv" % _rows.size())
	get_tree().quit(0)
```

### 3. Ejecutar y comprobar el CSV

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/trace_motion.tscn
```

Última línea esperada: `TRAZAS OK - N filas en res://trace_motion.csv` con
N > 300. Abre `trace_motion.csv` (raíz del proyecto) y comprueba a ojo los
valores de referencia del juego ACTUAL (los usará la tarea 43 como línea base):

- `jump_stand`: el `y` mínimo debe rondar **387** (ápice ≈ 144 px sobre 531).
- `jump_run`: mismo ápice que el parado (~387) pero avanzando ~270 px.
- `dive`: filas con `state=DIVE` y `vx ≈ 546`.
- `roll`: filas con `state=ROLL` y `vx ≈ 520` durante ~20 frames.
- `attack`: filas con `state=ATTACK` ~18 frames (dur 0.30 s del florete).

## Qué NO hacer

- No uses `extends SceneTree` ni `--script`: sigue el patrón escena+Node del
  smoke test (el InputMap lo registra `game.gd` al entrar en el árbol).
- No toques `scripts/`, `scenes/` ni `test/smoke_test.gd`: esta tarea solo
  AÑADE archivos.
- No registres con timers de reloj (`create_timer`) dentro de las fases: solo
  `await get_tree().physics_frame` (una fila = un tick de física).

## Criterios de aceptación

1. `res://test/trace_motion.tscn` ejecuta headless y termina con `TRAZAS OK`.
2. El CSV contiene las 6 marcas de fase (`# run`, `# jump_stand`, …).
3. En `jump_stand` el jugador sube y baja hasta volver a `y ≈ 531`; en `dive`
   hay filas `DIVE`; en `roll` hay filas `ROLL`.
4. El smoke test sigue pasando (esta tarea no toca el juego).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/trace_motion.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Últimas líneas esperadas: `TRAZAS OK - …` y `SMOKE OK - todas las mecánicas funcionan`.

## Nota de aplicación (2026-10-03)

Aplicada tal cual: `TRAZAS OK - 382 filas`, las 6 marcas presentes, dive
(33 filas a vx≈546), roll (21 filas) y attack (18 filas) correctos. OJO con
la línea base del salto: **a x=1600 el ápice mide y≈493, no 387**, porque el
salto choca con la parte inferior de la plataforma de la escalera
(`_platform(1480–1660, y=448)`, tarea 04: cabeza en 464 = techo). El ápice
físico puro (700²/2·1700 ≈ 144 px → y≈387) es medible en la franja libre
x∈[1000,1450]. La tarea 43 debe usar esa franja (o descontar el techo) al
verificar su línea base.
