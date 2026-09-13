# Tarea 33 — El gusano gigante de victoria

**Dificultad:** media · **Archivos:** `scripts/game.gd`, `test/smoke_test.gd` · **Prerrequisitos:** ninguno

## Objetivo

EL momento icónico de Nidhogg: al ganar el partido, un **gusano gigante verde**
baja del techo y **envuelve al ganador** en ~1,2 s, con las mandíbulas
cerrándose, antes de que aparezcan las estadísticas. Todo procedural (polígonos
y círculos), sin assets. La revancha (R) lo limpia.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript), arte y sonido procedurales, indentación con
  **tabs**, comentarios en español.
- `scripts/game.gd`:
	- `func _point(p: Player) -> void:` anota el punto. Su rama de fin de
	  partido es:
	  `if scores[_team(p)] >= WIN_SCORE:` → `match_over = true` → `show_msg(...)`
	  → `stats_label.text = _stats_text()` → `stats_label.visible = true`.
	  (Escribe la tarea como INSERCIONES, no reemplazando el bloque entero,
	  para convivir con las tareas 36 y 39.)
	- `var msg_tween: Tween` y demás variables de HUD viven arriba.
	- `func _start_round() -> void:` se ejecuta al empezar cada ronda y al
	  reiniciar con R (ahí se limpia el gusano).
	- Hay clases internas de ejemplo para copiar el patrón
	  (`class Cloud extends Node2D:`, `class Torch ...`).
	- `var right_of_way: Player = null`; `_team(p)` devuelve 0 (P1/P3) o 1 (P2/P4).
- El smoke test termina el partido en la sección 12 (scores [2,0] + meta) y
  reinicia con R; se añade una sección propia antes de `print("")`.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Variable y clase interna VictoryWorm

1.1. Junto a `var mode_2v2 := false`, añade:

```gdscript
var worm: Node = null
```

1.2. Junto a las demás clases internas (al lado de `class GlowSpot ...`),
añade:

```gdscript
class VictoryWorm extends Node2D:
	## El gusano del Nidhogg: baja del techo y envuelve al ganador.
	var t := 0.0
	var target := Vector2.ZERO
	var col := Color(0.22, 0.5, 0.2)

	func _init(pos: Vector2) -> void:
		target = pos
		position = pos + Vector2(0, -620.0)

	func _process(delta: float) -> void:
		t = minf(t + delta / 1.2, 1.0)
		position.y = lerpf(target.y - 620.0, target.y - 10.0, t)
		queue_redraw()

	func _draw() -> void:
		var chomp := 0.35 + 0.65 * t
		for i in 6:
			var r := 34.0 - 3.0 * float(i)
			draw_circle(Vector2(0, -float(i) * 44.0 - 30.0), r, col.darkened(0.05 * i))
		draw_circle(Vector2(0, -30.0), 36.0, col)
		var open_ang := 1.2 * (1.0 - chomp)
		for s in [-1.0, 1.0]:
			var pts := PackedVector2Array([
				Vector2(0, -20),
				Vector2(s * 44.0 * cos(open_ang), -20.0 + 44.0 * sin(open_ang)),
				Vector2(s * 10.0, 26.0),
			])
			draw_colored_polygon(pts, col.darkened(0.15))
		draw_circle(Vector2(-12, -34), 4.0, Color.YELLOW)
		draw_circle(Vector2(12, -34), 4.0, Color.YELLOW)
```

### 2. Invocarlo al ganar el partido

2.1. Debajo de `_point`, añade:

```gdscript
func _spawn_worm(p: Player) -> void:
	if worm != null:
		worm.queue_free()
	worm = VictoryWorm.new(p.position + Vector2(0, -30.0))
	worm.z_index = 30
	add_child(worm)
```

2.2. En `_point`, dentro de la rama `if scores[_team(p)] >= WIN_SCORE:`, justo
DESPUÉS de la línea `match_over = true`, añade:

```gdscript
		_spawn_worm(p)
```

2.3. En la MISMA rama, sustituye las dos líneas finales
`stats_label.text = _stats_text()` y `stats_label.visible = true` por:

```gdscript
		stats_label.text = _stats_text()
		get_tree().create_timer(1.5).timeout.connect(func():
			if match_over:
				stats_label.visible = true)
```

(las estadísticas aparecen cuando el gusano ya se ha comido al ganador).

### 3. Limpieza

Al principio de `_start_round()` (junto a la limpieza de proyectiles), añade:

```gdscript
	if worm != null:
		worm.queue_free()
		worm = null
```

### 4. Smoke test: sección nueva

En `test/smoke_test.gd`, busca la línea `print("")` e inserta ANTES:

```gdscript
	# 27. Gusano de victoria
	game.scores = [2, 0]
	game.right_of_way = game.players[0]
	p1.position = Vector2(4770.0, 531.0)
	p1.velocity = Vector2.ZERO
	p1.state = 0
	await get_tree().create_timer(0.3).timeout
	_check(game.match_over and game.worm != null, "Gusano: baja al ganar el partido")
	Input.action_press("restart")
	await get_tree().create_timer(0.05).timeout
	Input.action_release("restart")
	await get_tree().create_timer(0.3).timeout
	_check(game.worm == null, "Gusano: la revancha lo limpia")
```

## Qué NO hacer

- No bloquees el input durante el gusano: `match_over` ya congela a los
  jugadores (`p.frozen`) y R sigue funcionando para la revancha.
- No cambies el flujo de puntos normales (`¡PUNTO!` + `round_lock`): el gusano
  SOLO sale al terminar el partido.
- No pongas el gusano como hijo de `level_root` (moriría al cambiar de arena
  sin limpiar la variable).

## Criterios de aceptación

1. El punto que cierra el partido lanza al gusano: baja desde arriba del
   ganador en ~1,2 s con las mandíbulas cerrándose.
2. Las estadísticas no aparecen hasta ~1,5 s después (cuando el gusano ya
   envolvió al ganador).
3. R (revancha), cambiar de arena o de modo limpia el gusano y empieza limpio.
4. Ganar un punto normal NO saca el gusano.
5. El smoke test pasa, incluida la sección 27 nueva.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
