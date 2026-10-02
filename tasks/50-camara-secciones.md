# Tarea 50 — Cámara por secciones: 1 sección = 1 pantalla + pan suave

**Dificultad:** media · **Archivos:** `scripts/game.gd`, `test/smoke_test.gd` · **Prerrequisitos:** 25 (modo pantallas) aplicada

## Objetivo

Cámara portada del proyecto hermano, SOLO en modo pantallas (tecla P): la
cámara deja de seguir al corredor y **encuadra la sección actual completa**
(zoom ~1,68 para que los 686 px de sección llenen los 1152 px de ventana),
se queda quieta durante el duelo y al cruzar una reja hace un **pan suave de
0,28 s** (TRANS_QUAD EASE_OUT, sin teleport). El resto de modos conserva la
cámara actual. Es el encuadre de Nidhogg 2: una pantalla por sección.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/game.gd` — geometría: `LEVEL_W 4800`, `SECTION_COUNT 7`,
  `GROUND_Y 560`, `VIEW_W 1152`, `VIEW_H 648`. Ancho de sección =
  4800/7 ≈ 685,7 px → zoom = 1152/685,7 ≈ **1,68**.
- `_build_camera()` crea la `Camera2D` con `position_smoothing_enabled = true`
  (velocidad 6,5) y límites 0…4800. `_update_camera()` sigue al portador del
  paso (o la media de los vivos) y aplica el shake. En modo pantallas NO debe
  seguir: se early-return a un encuadre fijo.
- Modo pantallas (tarea 25): `set_sections(on)` crea las rejas,
  resetea `section_index = 3`…; `_update_sections()` detecta el cruce del
  portador y llama a `_cross_section(sec)`, que reposiciona a los jugadores;
  `_respawn_pos` ya reaparece en la sección delantera.
- `set_mode_2v2` también fija `camera.zoom` (`0.9` en 2v2): con pantallas
  activo debe respetar el zoom de sección (paso 5).
- Con zoom 1,68 la vista vertical es 648/1,68 ≈ 386 px: se ancla por abajo
  (suelo + 88 px de margen, foso incluido) para que torre/puente/tejados
  sigan visibles; la luna decorativa queda fuera — aceptado.
- El HUD (`_build_hud`) es un `CanvasLayer`: no le afecta el zoom.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en
  español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Constantes y variable

En `scripts/game.gd`, junto a las constantes de cámara/geom (p. ej. tras
`RESPAWN_DELAY`), añade:

```gdscript
const SECTION_PAN_TIME := 0.28       # pan al cruzar reja (sin teleport)
const SECTION_BOTTOM_MARGIN := 88.0  # margen visible bajo la línea de suelo
```

Junto a `var camera: Camera2D`, añade:

```gdscript
var section_cam_tween: Tween
```

### 2. Objetivo de cámara por sección

Añade la función junto a `_update_camera`:

```gdscript
## Centro que encuadra la sección actual completa (1 sección = 1 pantalla).
func _section_cam_target() -> Vector2:
	var w := LEVEL_W / float(SECTION_COUNT)
	var z := VIEW_W / w
	var cx := w * (float(section_index) + 0.5)
	return Vector2(cx, GROUND_Y + SECTION_BOTTOM_MARGIN - (VIEW_H / z) * 0.5)
```

### 3. Activar/desactivar en `set_sections`

En `set_sections(on: bool)`, tras `section_index = 3` (y antes de
`_update_hud()` / `_start_round()`), añade:

```gdscript
	if section_cam_tween != null and section_cam_tween.is_valid():
		section_cam_tween.kill()
	if on:
		var z := VIEW_W / (LEVEL_W / float(SECTION_COUNT))
		camera.zoom = Vector2(z, z)
		camera.position_smoothing_enabled = false
		camera.position = _section_cam_target()
	else:
		camera.zoom = Vector2(0.9, 0.9) if mode_2v2 else Vector2.ONE
		camera.position_smoothing_enabled = true
```

### 4. Encuadre fijo durante el duelo + pan al cruzar

En `_update_camera()`, primeras líneas:

```gdscript
func _update_camera() -> void:
	if sections_mode:
		_update_section_camera()
		return
	var tx := camera.position.x
	...(resto sin cambios)
```

Y añade la función:

```gdscript
## Modo pantallas: cámara enclavada en la sección; solo el pan del cruce la mueve.
func _update_section_camera() -> void:
	if section_cam_tween == null or not section_cam_tween.is_valid():
		camera.position = _section_cam_target()
	if shake_time > 0.0:
		camera.offset = Vector2(randf_range(-9.0, 9.0), randf_range(-7.0, 7.0)) * (shake_time * 4.0)
	else:
		camera.offset = Vector2.ZERO
```

En `_cross_section(sec)`, al final (tras reposicionar a los jugadores),
añade el pan:

```gdscript
	# pan suave hasta la nueva sección (nunca teleport)
	if section_cam_tween != null and section_cam_tween.is_valid():
		section_cam_tween.kill()
	section_cam_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	section_cam_tween.tween_property(camera, "position", _section_cam_target(), SECTION_PAN_TIME)
```

### 5. Guard del zoom en 2v2

En `set_mode_2v2`, la línea:

```gdscript
	camera.zoom = Vector2(0.9, 0.9) if mode_2v2 else Vector2.ONE
```

pasa a:

```gdscript
	if not sections_mode:
		camera.zoom = Vector2(0.9, 0.9) if mode_2v2 else Vector2.ONE
```

### 6. Caso nuevo del smoke

En `test/smoke_test.gd`, justo antes del `print("")` final, añade:

```gdscript
	# 38. Cámara por secciones: encuadra la sección actual y zoom de pantalla completa
	game.set_sections(true)
	await get_tree().create_timer(0.4).timeout
	var w38: float = game.LEVEL_W / 7.0
	var cx38: float = w38 * (float(game.section_index) + 0.5)
	_check(absf(game.camera.position.x - cx38) < 2.0, "Pantallas: la cámara centra la sección actual")
	_check(game.camera.zoom.x > 1.5, "Pantallas: zoom de pantalla completa (1 sección = 1 pantalla)")
	game.set_sections(false)
	_check(game.camera.zoom == Vector2.ONE, "Al salir del modo pantallas se restaura la cámara normal")
```

## Qué NO hacer

- No apliques este encuadre fuera del modo pantallas: los demás modos siguen
  con la cámara que sigue al corredor.
- No quites el shake en modo pantallas (se mantiene dentro de
  `_update_section_camera`).
- No teleportees la cámara en el cruce: SIEMPRE tween de `SECTION_PAN_TIME`.
- No toques `_respawn_pos` (la reaparición en la sección delantera ya está).

## Criterios de aceptación

1. Con P activado, la sección actual llena exactamente la pantalla (las rejas
   laterales quedan en los bordes) y la cámara no se mueve al correr.
2. Al cruzar una reja, pan suave de ~0,3 s hasta la nueva sección.
3. Al desactivar P, la cámara y el zoom vuelven a la normalidad (y el 2v2
   sigue pudiendo poner su zoom 0,9 con P desactivado).
4. El smoke (con el caso 38) termina en `SMOKE OK`.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.

Comprobación visual opcional (con render):

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --path . res://test/screenshots.tscn
```
