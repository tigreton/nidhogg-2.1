# Tarea 78 — Cámara teatral: encuadrar a los vivos (personaje ~14% de pantalla)

**Dificultad:** media · **Archivos:** `scripts/game.gd`, `test/screenshots.gd` (una línea) · **Prerrequisitos:** ninguno (independiente de la 50)

## Objetivo

Reescrita (2026-10-03) tras la comparativa de feel: no es "zoom por distancia"
sino **encuadre del original** — la cámara SIEMPRE enseña a los duelistas
vivos, acerca el plano cuando están cerca (el personaje pasa del ~10% actual
al **~13–14%** de la altura de pantalla, como el original medido en vídeo) y
aleja lo justo cuando la persecución se separa, con transición suave y sin
teleports. El defensor nunca vuelve a quedar fuera de pantalla en la
persecución.

## Contexto del proyecto (leer antes de tocar nada)

- `_update_camera()` (game.gd): hace early-return a `_update_section_camera()`
  si `sections_mode`; si no, calcula `tx` (corredor o media de vivos) y fija
  `camera.position` + shake. El clamp de bordes ya usa el zoom:
  `var half := VIEW_W * 0.5 / camera.zoom.x` — con zoom variable sigue
  siendo correcto sin tocarlo.
- `camera` se crea en `_build_camera()` con `position_smoothing_enabled =
  true` (velocidad 6,5): el suavizado X ya existe; el del zoom va a mano con
  `move_toward`.
- Medidas de referencia (`docs/VIDEO_ANALYSIS.md` §3): personaje real ≈
  **14–15 %** de la altura de pantalla; pans de 0,1–0,8 s solo tras kill o
  cruce de borde (nunca persecución fuera de plano). Nuestro sprite mide
  58 px: a zoom 1,5 ocupa 87 px = 13,4 % de 648 ✓.
- `set_mode_2v2` fija `camera.zoom = Vector2(0.9, 0.9)` (con guard de la
  50): el 2v2 queda fuera del zoom dinámico, como ya está.
- El recorrido de capturas fija la cámara a mano al inicio
  (`cam.position_smoothing_enabled = false`) con jugadores a 340 px: el paso
  3 lo exime también del zoom para no reencuadrar las 23 capturas.
- Reglas de estilo: GDScript tipado, tabs, español.

## Instrucciones paso a paso

### 1. Constantes y flag

Junto a `var shake_time := 0.0`:

```gdscript
const CAM_ZOOM_NEAR := 1.5   # duelo cerrado: personaje ~13-14% de pantalla
const CAM_ZOOM_FAR := 1.0    # persecución abierta (nunca menos: no perder presencia)
const CAM_FIT_USE := 0.72    # fracción del ancho que pueden ocupar los duelistas
var dynamic_zoom := true
```

### 2. Encuadre y zoom

En `_update_camera()`, tras el early-return de `sections_mode`, sustituye el
cálculo de `tx` (el bloque `if right_of_way != null ... tx = sum / float(n)`)
por:

```gdscript
	# encuadre teatral (tarea 78): los vivos siempre en pantalla
	var alive_x: Array[float] = []
	for p in players:
		if p.state != Player.State.DEAD:
			alive_x.append(p.position.x)
	var tx := camera.position.x
	if alive_x.size() > 0:
		var lo := alive_x[0]
		var hi := alive_x[0]
		for x in alive_x:
			lo = minf(lo, x)
			hi = maxf(hi, x)
		tx = (lo + hi) * 0.5
	if dynamic_zoom and not mode_2v2 and alive_x.size() >= 2:
		var spread := hi - lo
		var zt := clampf(VIEW_W * CAM_FIT_USE / maxf(spread, 220.0), CAM_ZOOM_FAR, CAM_ZOOM_NEAR)
		var z := move_toward(camera.zoom.x, zt, delta * 0.9)
		camera.zoom = Vector2(z, z)
```

(declara `var hi := 0.0` antes del `if` si el tipado se queja del alcance;
`delta` llega por parámetro de `_physics_process` — comprueba que
`_update_camera()` lo recibe; si no, añádeselo y actualiza su llamada.)

### 3. El 2v2 restaura; el recorrido de capturas queda exento

En `set_mode_2v2`, la línea protegida de la 50 pasa a:

```gdscript
	if not sections_mode:
		dynamic_zoom = not mode_2v2
		camera.zoom = Vector2(0.9, 0.9) if mode_2v2 else Vector2.ONE
```

En `test/screenshots.gd`, junto a `cam.position_smoothing_enabled = false`:

```gdscript
	game.dynamic_zoom = false
```

## Qué NO hacer

- No bajes de 1,0 el zoom: menos pierde presencia y enseña fosos vacíos.
- No toques el modo pantallas (`_section_cam_target` manda ahí con su 1,68).
- No sigas SOLO al corredor: el punto es ver a los dos (el original es
  teatral, no chase-cam).
- No metas el zoom en el shake (`offset`): son ejes distintos.

## Criterios de aceptación

1. Con los duelistas juntos, el plano acerca hasta ~1,5 (el personaje se ve
   grande, como el original); al separarse la persecución, aleja hasta 1,0
   manteniendo SIEMPRE a los dos en pantalla.
2. El defensor ya no desaparece cuando el corredor arranca a sprint.
3. 2v2 mantiene su 0,9; modo pantallas su 1,68; capturas con encuadre fijo.
4. `SMOKE OK` y `ALL PASSED (12)`.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/screenshots.tscn
```

Últimas líneas esperadas: `SMOKE OK - todas las mecánicas funcionan` y
`CAPTURAS OK`.
