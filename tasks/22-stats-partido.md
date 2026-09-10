# Tarea 22 — Estadísticas en la pantalla de victoria

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** ninguno

## Objetivo

Medir el partido — bajas, muertes, espadas lanzadas y metros corridos de cada
jugador — y mostrarlo en la pantalla de victoria, bajo el "¡GANA P1!". Da
motivo de revancha y gratis, porque todos los eventos ya pasan por `game.gd`.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/game.gd` — nodo principal:
	- Variables: `players: Array[Player]`, `scores`, `match_over: bool`. Vista:
	  `VIEW_W=1152`, `VIEW_H=648`.
	- `_kill(def, atk)` es donde ocurren TODAS las muertes (`atk` es null en
	  dobles muertes y caídas al foso).
	- `_on_threw_sword(p)` se emite una vez por lanzamiento.
	- `_point(p)` gestiona el punto; su rama de victoria pone `match_over = true`
	  y muestra `show_msg("¡GANA P%d!  ·  R: revancha", ...)`.
	- El handler de revancha en `_physics_process` (`if match_over and
	  Input.is_action_just_pressed("restart")`) resetea `scores` y llama
	  `_start_round()`.
	- `_build_hud()` crea el `CanvasLayer` (`cl`) con labels (patrón: `Label.new()`
	  + overrides de tema + `cl.add_child`).
	- Los jugadores corren a 330 px/s ≈ 5,5 px por frame físico: un
	  desplazamiento > 60 px en un frame es un teletransporte (reaparición),
	  que NO debe contarse como carrera.
- Convención de "metro": 32 px = 1 m (el duelist mide ~58 px ≈ 1,80 m).
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Estado

Junto a las demás variables de instancia, añade:

```gdscript
var stats: Array[Dictionary] = []
var last_x := [0.0, 0.0]
var stats_label: Label


func _fresh_stats() -> Array[Dictionary]:
	return [
		{"kills": 0, "deaths": 0, "throws": 0, "dist": 0.0},
		{"kills": 0, "deaths": 0, "throws": 0, "dist": 0.0},
	]
```

Y en `_ready()`, como primera línea, inicializa: `stats = _fresh_stats()`.

### 2. Medir

2.1. En `_kill()`, justo después de `def.die()`, añade:

```gdscript
	stats[def.player_id - 1]["deaths"] += 1
	if atk != null:
		stats[atk.player_id - 1]["kills"] += 1
```

2.2. En `_on_threw_sword()`, después de la línea `sfx(p.position, "throw", -14.0)`, añade:

```gdscript
	stats[p.player_id - 1]["throws"] += 1
```

2.3. En `_physics_process`, después de la línea `p.frozen = match_over or
round_lock > 0.0` (el bucle que congela jugadores), añade:

```gdscript
	for i in players.size():
		var step := absf(players[i].position.x - last_x[i])
		if players[i].state != Player.State.DEAD and step < 60.0:
			stats[i]["dist"] += step
		last_x[i] = players[i].position.x
```

(El filtro `step < 60.0` descarta los teletransportes de reaparición y de
inicio de ronda.)

### 3. Mostrar

3.1. En `_build_hud()`, después del bloque de `hint`, añade:

```gdscript
	stats_label = Label.new()
	stats_label.position = Vector2(0, VIEW_H * 0.44)
	stats_label.size = Vector2(VIEW_W, 140)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 24)
	stats_label.add_theme_color_override("font_color", Color(0.85, 0.83, 0.90))
	stats_label.add_theme_color_override("font_outline_color", Color.BLACK)
	stats_label.add_theme_constant_override("outline_size", 6)
	stats_label.visible = false
	cl.add_child(stats_label)
```

3.2. Añade la función:

```gdscript
func _stats_text() -> String:
	var a := stats[0]
	var b := stats[1]
	return "P1   bajas %d   ·   muertes %d   ·   lanzó %d   ·   corrió %d m\nP2   bajas %d   ·   muertes %d   ·   lanzó %d   ·   corrió %d m" % [
		a["kills"], a["deaths"], a["throws"], int(round(float(a["dist"]) / 32.0)),
		b["kills"], b["deaths"], b["throws"], int(round(float(b["dist"]) / 32.0)),
	]
```

3.3. En `_point()`, dentro de la rama `if scores[...] >= WIN_SCORE:` (la de
`match_over = true`), después del `show_msg(...)`, añade:

```gdscript
		stats_label.text = _stats_text()
		stats_label.visible = true
```

### 4. Reset en la revancha

En el handler de revancha de `_physics_process`, el bloque
`if match_over and Input.is_action_just_pressed("restart"):` debe quedar:

```gdscript
	if match_over and Input.is_action_just_pressed("restart"):
		scores = [0, 0]
		stats = _fresh_stats()
		stats_label.visible = false
		match_over = false
		_update_hud()
		_start_round()
```

## Qué NO hacer

- No cuentes los teletransportes como metros (el filtro del paso 2.3 lo evita).
- No muestres las stats durante la partida: solo en la pantalla de victoria.
- No añadas archivos ni nodos nuevos: todo va en `game.gd` y el HUD existente.

## Criterios de aceptación

1. Al ganar un partido, bajo el "¡GANA Px!" aparecen las dos líneas de
   estadísticas con números plausibles.
2. Una muerte por foso cuenta como "muerte" del caído pero no como "baja" de
   nadie; una doble muerte suma una muerte a cada uno.
3. Los metros crecen solo corriendo (las reapariciones no inflan la cifra).
4. Tras la revancha con R, las estadísticas arrancan de cero y el panel
   desaparece.
5. El smoke test sigue pasando (si aplicaste la tarea del test ampliado, su
   final de partido verá el panel aparecer sin romper nada).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
