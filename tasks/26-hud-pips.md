# Tarea 26 — HUD estilo Nidhogg 2: pips de secciones, barra de reaparición y ¡FIGHT!

**Dificultad:** media · **Archivos:** `scripts/game.gd`, `test/smoke_test.gd` · **Prerrequisitos:** tarea 25 (modo pantallas con `sections_mode`, `sect_conquered` y `SectionGate`)

## Objetivo

El HUD del original: una **fila de 7 pips** arriba (las secciones conquistadas
se rellenan del color del equipo atacante, el resto queda hueco), una **barra
de progreso** sobre el punto de reaparición mientras cuenta el respawn, y el
cartel **¡FIGHT!** con golpe de escala al empezar cada ronda (sustituye al
"¡LUCHA!" actual).

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript), arte y sonido procedurales, indentación con
  **tabs**, comentarios en español.
- La tarea 25 ya aplicó en `scripts/game.gd`: `sections_mode`, `section_index`,
  `sect_conquered := [0, 0]`, `set_sections(on)` y `SECTION_COUNT := 7`.
- `scripts/game.gd`:
	- `func _build_hud() -> void:` crea un `CanvasLayer` en la variable local
	  `cl` y añade labels (`score_labels`, `msg_label`, un `hint`, `run_label`,
	  `dim`, `pause_label`, `stats_label`). Ahí se añadirán los elementos nuevos.
	- `func _update_hud() -> void:` actualiza los textos de `score_labels`.
	- `const VIEW_W := 1152.0`, `const VIEW_H := 648.0`,
	  `const RESPAWN_DELAY := 2.4`, `const P1_COLOR`, `const P2_COLOR`.
	- En `_physics_process` hay un bucle de reaparición:
	  `for i in players.size(): if respawn_timers[i] > 0.0: ... _respawn(players[i])`.
	- `func _respawn_pos(p: Player) -> Vector2:` calcula dónde reaparece cada
	  uno (con la tarea 25, en la sección delantera en modo pantallas).
	- `func _start_round() -> void:` termina con `show_msg("¡LUCHA!", 1.0)`.
	- `show_msg(text, dur)` anima `msg_label` con un tween guardado en
	  `msg_tween` (`var msg_tween: Tween` junto a las demás variables).
	- Hay clases internas de ejemplo (`class Pip` no existe aún; sí
	  `class Cloud extends Node2D:` para copiar el patrón).
- El smoke test termina con varias secciones y la línea `print("")`.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Variables

Junto a `var stats_label: Label`, añade:

```gdscript
var fight_label: Label
var fight_tween: Tween
var pips: Array[Pip] = []
var pips_row: Node2D
var respawn_bar: RespawnBar
```

### 2. Clases internas Pip y RespawnBar

Añádelas junto a las demás clases internas (al lado de `class GlowSpot ...`):

```gdscript
class Pip extends Node2D:
	## Cuadro del HUD de secciones: hueco o relleno del color conquistador.
	var fill_col := Color(0, 0, 0, 0)
	var edge_col := Color(0.65, 0.63, 0.72)

	func _draw() -> void:
		draw_rect(Rect2(-16, -10, 32, 20), edge_col, false, 2.5)
		if fill_col.a > 0.0:
			draw_rect(Rect2(-12, -6, 24, 12), fill_col)


class RespawnBar extends Node2D:
	## Barra de progreso sobre el punto de reaparición.
	var frac := 0.0
	var col := Color.WHITE

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(-30, -6, 60, 12), Color(0, 0, 0, 0.55))
		draw_rect(Rect2(-28, -4, 56.0 * clampf(frac, 0.0, 1.0), 8.0), col)
```

### 3. Construir los elementos en `_build_hud()`

3.1. Al final de `_build_hud()` (después de crear `stats_label`), añade:

```gdscript
	pips_row = Node2D.new()
	pips_row.position = Vector2(VIEW_W * 0.5 - 2.0 * 44.0 + 16.0, 36.0)
	pips_row.visible = false
	cl.add_child(pips_row)
	pips.clear()
	for k in SECTION_COUNT:
		var pip := Pip.new()
		pip.position = Vector2(44.0 * float(k), 0.0)
		pips_row.add_child(pip)
		pips.append(pip)

	respawn_bar = RespawnBar.new()
	respawn_bar.visible = false
	respawn_bar.z_index = 40
	cl.add_child(respawn_bar)

	fight_label = Label.new()
	fight_label.text = "¡FIGHT!"
	fight_label.position = Vector2(0, VIEW_H * 0.30)
	fight_label.size = Vector2(VIEW_W, 110)
	fight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fight_label.add_theme_font_size_override("font_size", 88)
	fight_label.add_theme_color_override("font_color", Color.WHITE)
	fight_label.add_theme_color_override("font_outline_color", Color.BLACK)
	fight_label.add_theme_constant_override("outline_size", 16)
	fight_label.pivot_offset = Vector2(VIEW_W * 0.5, 55.0)
	fight_label.visible = false
	cl.add_child(fight_label)
```

### 4. Actualizar pips y barra

4.1. Al final de `_update_hud()`, añade:

```gdscript
	_update_pips()
```

4.2. Debajo de `_update_hud`, añade:

```gdscript
func _update_pips() -> void:
	pips_row.visible = sections_mode
	if not sections_mode:
		return
	for k in SECTION_COUNT:
		var fill := Color(0, 0, 0, 0)
		var edge := Color(0.65, 0.63, 0.72)
		if k < 3 and sect_conquered[1] >= 3 - k:
			fill = P2_COLOR
			edge = P2_COLOR
		elif k > 3 and sect_conquered[0] >= k - 3:
			fill = P1_COLOR
			edge = P1_COLOR
		pips[k].fill_col = fill
		pips[k].edge_col = edge
		pips[k].queue_redraw()


func _update_respawn_bar() -> void:
	var shown := false
	for i in players.size():
		if respawn_timers[i] > 0.0:
			var p := players[i]
			respawn_bar.position = _respawn_pos(p) + Vector2(0, -96)
			respawn_bar.col = p.color
			respawn_bar.frac = respawn_timers[i] / RESPAWN_DELAY
			shown = true
			break
	respawn_bar.visible = shown
```

4.3. En `_physics_process`, justo después del bucle de reaparición
(`for i in players.size(): if respawn_timers[i] > 0.0: ...`), añade:

```gdscript
	_update_respawn_bar()
```

### 5. Cartel ¡FIGHT!

5.1. Debajo de `show_msg`, añade:

```gdscript
func _show_fight() -> void:
	fight_label.visible = true
	fight_label.modulate.a = 1.0
	fight_label.scale = Vector2(1.7, 1.7)
	if fight_tween:
		fight_tween.kill()
	fight_tween = fight_label.create_tween()
	fight_tween.tween_property(fight_label, "scale", Vector2.ONE, 0.22)
	fight_tween.tween_interval(0.45)
	fight_tween.tween_property(fight_label, "modulate:a", 0.0, 0.3)
	fight_tween.tween_callback(func(): fight_label.visible = false)
```

5.2. En `_start_round()`, sustituye la línea `show_msg("¡LUCHA!", 1.0)` por:

```gdscript
	_show_fight()
```

### 6. Smoke test: sección nueva

En `test/smoke_test.gd`, busca la línea `print("")` e inserta ANTES:

```gdscript
	# 20. HUD: pips de secciones y barra de reaparición
	game.set_sections(true)
	_check(game.pips_row.visible and game.pips.size() == 7, "HUD: fila de 7 pips en modo pantallas")
	game.sect_conquered = [1, 0]
	game._update_hud()
	_check(game.pips[4].fill_col == game.P1_COLOR, "HUD: pip conquistado del color del atacante")
	p1.position = Vector2(2200.0, 531.0)
	p2.position = Vector2(2270.0, 531.0)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.state = 0
	p2.state = 0
	p2.invuln_time = 0.0
	p2.has_sword = true
	await get_tree().physics_frame
	Input.action_press("p2_up")
	await get_tree().create_timer(0.1).timeout
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.16).timeout
	Input.action_release("p1_attack")
	Input.action_release("p2_up")
	await get_tree().create_timer(0.3).timeout
	_check(p2.state == 7 and game.respawn_bar.visible, "HUD: barra de reaparición visible")
	_check(game.fight_tween != null, "HUD: cartel FIGHT lanzado en la ronda")
	game.set_sections(false)
	_check(not game.pips_row.visible, "HUD: sin modo pantallas no hay pips")
```

## Qué NO hacer

- No quites ni cambies `show_msg` ni los mensajes existentes ("¡PUNTO!",
  "¡CORRE!", avisos de modo): solo el "¡LUCHA!" de `_start_round` se sustituye.
- No muestres los pips fuera del modo pantallas (en el modo continuo no hay
  secciones que contar).
- No toques `_cross_section` ni `_update_gates` de la tarea 25.

## Criterios de aceptación

1. En modo pantallas se ve la fila de 7 pips: los conquistados van rellenos
   del color del equipo (azul hacia la izquierda, naranja hacia la derecha).
2. Al morir alguien, sobre su punto de reaparición se ve una barra del color
   de la víctima vaciándose hasta que reaparece.
3. Cada ronda empieza con el cartel "¡FIGHT!" encogiéndose y desvaneciéndose.
4. En modo continuo no hay pips y el resto del HUD no cambia.
5. El smoke test pasa, incluida la sección 20 nueva.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
