# Tarea 15 — Pausa con ESC

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** ninguno

## Objetivo

Pausar el juego con **ESC**: pantalla oscurecida con el texto "PAUSA", todo el
juego congelado (jugadores, partículas, cámara). Con ESC de nuevo se reanuda.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/game.gd` — nodo principal:
	- `_setup_input()` registra acciones de teclado en runtime en el
	  diccionario `defs` (patrón: `"restart": [KEY_R],`).
	- `_ready()` construye todo; `_build_hud()` crea un `CanvasLayer` (`cl`,
	  layer 10) con labels (patrón: `Label.new()` + `add_child` a `cl`).
	- `_physics_process(delta)` empieza con `shake_time = maxf(...)`.
	- Vista: `VIEW_W=1152`, `VIEW_H=648`.
- Godot: `get_tree().paused = true` congela los nodos `PROCESS_MODE_PAUSABLE`
  (los jugadores lo son por defecto). Para que el nodo `game` SIGA leyendo ESC
  mientras está pausado, hay que ponerlo en `PROCESS_MODE_ALWAYS` y salir a
  mano de `_physics_process` cuando esté pausado (si no, seguiría simulando).
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Acción de pausa

En `_setup_input()`, añade al diccionario `defs`:

```gdscript
	"pause": [KEY_ESCAPE],
```

### 2. Modo de proceso del nodo game

En `_ready()`, como PRIMERA línea, añade:

```gdscript
	process_mode = Node.PROCESS_MODE_ALWAYS
```

### 3. Variables

Junto a `var msg_label: Label`, añade:

```gdscript
var dim: ColorRect
var pause_label: Label
```

### 4. Overlay de pausa

En `_build_hud()`, después del bloque que crea `hint`, añade:

```gdscript
	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size = Vector2(VIEW_W, VIEW_H)
	dim.visible = false
	cl.add_child(dim)

	pause_label = Label.new()
	pause_label.text = "PAUSA"
	pause_label.position = Vector2(0, VIEW_H * 0.4)
	pause_label.size = Vector2(VIEW_W, 80)
	pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_label.add_theme_font_size_override("font_size", 64)
	pause_label.add_theme_color_override("font_color", Color.WHITE)
	pause_label.visible = false
	cl.add_child(pause_label)
```

### 5. Toggle y corte de la simulación

En `_physics_process`, como PRIMERAS líneas (antes de `shake_time = ...`), añade:

```gdscript
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = not get_tree().paused
		dim.visible = get_tree().paused
		pause_label.visible = get_tree().paused
	if get_tree().paused:
		return
```

## Qué NO hacer

- No pongas `PROCESS_MODE_ALWAYS` en los jugadores o el HUD dinámico: solo el
  nodo `game` necesita seguir corriendo (para leer ESC).
- No dejes que R (revancha) funcione mientras está pausado: el `return` del
  paso 5 ya lo evita; no lo muevas de sitio.
- No pauses desde `_process` (el juego usa `_physics_process` para la lógica).

## Criterios de aceptación

1. ESC congela todo al instante y oscurece la pantalla con "PAUSA".
2. ESC de nuevo reanuda exactamente donde estaba (posiciones, timers, partículas).
3. Mientras está pausado, ningún input del juego tiene efecto.
4. El smoke test sigue pasando (ESC nunca se pulsa allí).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
