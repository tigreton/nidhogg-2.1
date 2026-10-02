# Tarea 51 — Simulación de partida completa bot vs bot

**Dificultad:** media · **Archivos:** nuevos `test/sim_match.gd`, `test/sim_match.tscn` · **Prerrequisitos:** recomendado tras 43–49 (valida el juego recalibrado)

## Objetivo

Portar la simulación de punta a punta del proyecto hermano: dos bots NORMAL
juegan una partida real de hasta 2 minutos (o hasta que alguien gane) y la
herramienta verifica que el flujo completo funciona: se matan, se anotan
puntos, se pasa por todos los estados de movimiento. Con semilla fija es
**reproducible**. Es la red de seguridad final: si tras las tareas 43–49 el
juego siguiera siendo jugable de punta a punta, esto lo demuestra.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- El bot ya existe (tareas 01/02): `game.gd::_bot_think(p, delta)` rellena
  `p.bot_held` cuando `p.is_bot`. Dificultades en `BOT_CFG`
  (`bot_level` para P2/P4, `ally_bot_level` para P1/P3; 2 = NORMAL).
- Patrón de herramienta: `test/smoke_test.gd` (escena + Node que instancia
  `res://scenes/main.tscn`). Sigue ESE patrón, no `extends SceneTree`.
- Señales útiles: `Player.died(player)`. Marcador: `game.scores`,
  fin: `game.match_over`. Estados: `Player.State.find_key(p.state)`.
- El `_kill` pausa el árbol 0,08 s (hitstop): los `await physics_frame`
  simplemente esperan a la reanudación (el unpause lo hace un timer
  `process_always`), no hay que hacer nada especial.
- La aleatoriedad del bot usa `randf()` global: con `seed(...)` fijo al
  arrancar, la simulación es reproducible.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en
  español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Crear `test/sim_match.tscn`

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://test/sim_match.gd" id="1_sim"]

[node name="SimMatch" type="Node"]
script = ExtResource("1_sim")
```

### 2. Crear `test/sim_match.gd` completo

```gdscript
extends Node
## Simulación bot vs bot de una partida completa (portada del hermano):
## dos bots NORMAL juegan hasta 2 minutos; con semilla fija es reproducible.
## Verifica el flujo de punta a punta: bajas, puntos y cobertura de estados.
##   godot --headless --path . res://test/sim_match.tscn

const SIM_SECONDS := 120.0
const SIM_SEED := 20260907

var game: Node
var _kills := 0
var _points := 0
var _states := {}


func _ready() -> void:
	seed(SIM_SEED)
	game = load("res://scenes/main.tscn").instantiate()
	add_child(game)
	await get_tree().create_timer(0.2).timeout
	game.bot_level = 2        # P2/P4 a NORMAL
	game.ally_bot_level = 2   # P1/P3 a NORMAL
	for p in game.players:
		p.is_bot = true
		p.died.connect(func(_pl): _kills += 1)

	var score_sum := game.scores[0] + game.scores[1]
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
```

### 3. Ejecutar y ajustar (si hiciera falta) los mínimos

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/sim_match.tscn
```

Última línea esperada: `SIM PASS`. Criterios del PASS:
- `kills >= 2`: el combate funciona y respawnea (con dos bots NORMAL en 2
  minutos lo normal son >10 bajas; si sale 0–1 algo de 43–49 rompió el
  combate o el respawn).
- `RUN` y `JUMP` vistos: el movimiento funciona.
- `puntos >= 1` o partida completa: la carrera a la meta funciona.

Si falla SOLO por `puntos` (bots que se matan pero nunca llegan a la meta en
2 min), sube `SIM_SECONDS` a 180 — es límite de tiempo de simulación, no un
bug. Si falla por kills o estados, NO toques los mínimos: es una regresión
real de 43–49 y hay que revisarla antes de cerrar esta tarea.

## Qué NO hacer

- No escribas una IA nueva: usa `_bot_think` tal cual (`is_bot = true`).
- No fuerces el resultado (matar a mano, sumar puntos a mano): la simulación
  debe ganar el PASS jugando.
- No uses timers de reloj dentro del bucle: solo `physics_frame` (el hitstop
  ya se maneja solo).

## Criterios de aceptación

1. `res://test/sim_match.tscn` termina con `SIM PASS` en menos de ~1 min de
   reloj (headless corre más rápido que tiempo real).
2. Dos ejecuciones seguales imprimen los mismos `kills`/`puntos` (semilla).
3. El smoke test sigue pasando (esta tarea no toca el juego).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/sim_match.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Últimas líneas esperadas: `SIM PASS` y `SMOKE OK - todas las mecánicas funcionan`.
