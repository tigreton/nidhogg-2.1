# Tarea 08 — Aviso "¡CORRE!" con la dirección de la meta

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** ninguno

## Objetivo

Cuando alguien tiene el paso (`right_of_way`), mostrar en la parte alta de la
pantalla un aviso con su color: "¡P1 CORRE! »»»" o "««« ¡P2 CORRE!" según hacia
qué meta corra. Ayuda a no perderse tras una muerte.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/game.gd`:
	- Variable clave `right_of_way: Player` (null si nadie tiene el paso) y
	  `match_over: bool`. El HUD se construye en `_build_hud()` dentro de un
	  `CanvasLayer` (`cl`, layer 10); `msg_label` y `score_labels` son ejemplos de
	  cómo se crean labels (copiar el patrón: `add_theme_font_size_override`,
	  `add_theme_color_override("font_color", ...)` etc.).
	- Vista: `VIEW_W=1152`, `VIEW_H=648`.
	- `Player` tiene `player_id` (1/2), `color` (Color), `goal_dir` (1 = meta a la
	  derecha, -1 = izquierda) y `State.DEAD`.
	- `_process(_delta)` ya existe (anima el brillo de las metas): es buen sitio
	  para refrescar el aviso cada frame.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Variable

En `scripts/game.gd`, junto a `var msg_label: Label`, añade:

```gdscript
var run_label: Label
```

### 2. Crear el label

En `_build_hud()`, después del bloque que crea `hint`, añade:

```gdscript
	run_label = Label.new()
	run_label.position = Vector2(0, 64)
	run_label.size = Vector2(VIEW_W, 44)
	run_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	run_label.add_theme_font_size_override("font_size", 30)
	run_label.add_theme_color_override("font_outline_color", Color.BLACK)
	run_label.add_theme_constant_override("outline_size", 8)
	run_label.visible = false
	cl.add_child(run_label)
```

### 3. Refrescarlo cada frame

En `_process(_delta)`, después del bucle que anima `goal_polys`, añade:

```gdscript
	var rw := right_of_way
	if rw != null and not match_over and rw.state != Player.State.DEAD and round_lock <= 0.0:
		run_label.visible = true
		run_label.text = "¡P%d CORRE!  %s" % [rw.player_id, "»»»" if rw.goal_dir > 0 else "«««"]
		run_label.add_theme_color_override("font_color", rw.color)
	else:
		run_label.visible = false
```

## Qué NO hacer

- No ocultes el marcador ni el mensaje central (`msg_label`).
- No dibujes flechas en el mundo 2D: el aviso es solo HUD.
- No lo muestres durante la celebración del punto ni con el partido acabado
  (las condiciones del paso 3 ya lo evitan).

## Criterios de aceptación

1. Tras tu primera muerte, aparece "¡P2 CORRE! «««" en color cian arriba.
2. Cuando el paso cambia de dueño, el aviso cambia de texto y color al instante.
3. Durante la celebración del punto y el final de partido no se ve.
4. El smoke test sigue pasando.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
