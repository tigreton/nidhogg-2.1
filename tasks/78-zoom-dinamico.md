# Tarea 78 — Zoom dinámico de cámara (respirar con la distancia)

**Dificultad:** media · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** ninguno (independiente de la 50)

## Objetivo

La cámara deja de ser plana: cuando los duelistas están cerca, **acerca** el
encuadre (hasta ×1,15); separados, **aleja** (hasta ×0,75) para ver la
carrera. Transición suave con `move_toward`. Solo en el modo normal: el modo
pantallas (zoom 1,68 de la 50) y el 2v2 (0,9 fijo) no se tocan.

## Contexto del proyecto (leer antes de tocar nada)

- `_update_camera()` (game.gd): early-return a `_update_section_camera()`
  si `sections_mode`; si no, fija `camera.position` según el corredor/media
  y aplica shake. La llamada corre cada `_physics_process`.
- `set_mode_2v2` fija `camera.zoom = Vector2(0.9, 0.9)` (con el guard de
  la 50) — el zoom dinámico debe respetar el 2v2 apagándose.
- Vista: `VIEW_W 1152`, `LEVEL_W 4800`, límites horizontales ya clampeados
  con `half := VIEW_W * 0.5 / camera.zoom.x` — el clamp usa el zoom actual,
  así que alejar no rompe bordes (el margen ya existe en la fórmula).
- `camera.zoom` también lo toca el shake? No: el shake usa `offset`.
- Reglas de estilo: GDScript tipado, tabs, español.

## Instrucciones paso a paso

### 1. Estado

Junto a `var shake_time := 0.0`:

```gdscript
const ZOOM_NEAR := 1.15
const ZOOM_FAR := 0.75
var dynamic_zoom := true
```

### 2. Objetivo y suavizado

En `_update_camera()`, tras el early-return de `sections_mode` y ANTES de
calcular `tx`, añade:

```gdscript
	# zoom dinámico: cerca = emoción; lejos = carrera (tarea 78)
	if dynamic_zoom and not mode_2v2:
		var alive_x: Array[float] = []
		for p in players:
			if p.state != Player.State.DEAD:
				alive_x.append(p.position.x)
		if alive_x.size() >= 2:
			var spread := 0.0
			for x in alive_x:
				spread = maxf(spread, absf(x - alive_x[0]))
			var zt := clampf(1.05 - (spread - 500.0) / 2600.0, ZOOM_FAR, ZOOM_NEAR)
			var z := move_toward(camera.zoom.x, zt, 0.35 * get_physics_process_delta_time() * 4.0)
			camera.zoom = Vector2(z, z)
```

### 3. El 2v2 lo apaga y enciende

En `set_mode_2v2`, la línea protegida de la 50 (`if not sections_mode:
camera.zoom = ...`) pasa a restaurar también el flag:

```gdscript
	if not sections_mode:
		dynamic_zoom = not mode_2v2
		camera.zoom = Vector2(0.9, 0.9) if mode_2v2 else Vector2.ONE
```

## Qué NO hacer

- No bajes de 0,75: menos enseñaría fosos vacíos y bordes del nivel.
- No toques el modo pantallas (`_section_cam_target` manda ahí).
- No metas el zoom en el shake (`offset`): son ejes distintos.
- El recorrido de capturas fija la cámara a mano (`position_smoothing` off,
  jugadores a 340 px de separación → zoom 1,0+): si alguna captura cambia
  de encuadre, revisa; NO clipees el zoom para arreglar capturas.

## Criterios de aceptación

1. Acercarse los duelistas ~500 px acerca el plano suavemente (sin saltos);
   separarse en la carrera aleja hasta 0,75.
2. 2v2 mantiene su 0,9 fijo; modo pantallas su 1,68.
3. Nadie sale por los bordes del nivel al alejar (el clamp usa el zoom).
4. `SMOKE OK` y `ALL PASSED (12)` (la lógica no depende del zoom).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/test_runner.tscn
```

Últimas líneas esperadas: `SMOKE OK - todas las mecánicas funcionan` y
`RESULT: ALL PASSED (12)`.
