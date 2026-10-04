# Tarea 87 — Fix: la barra de reaparición casi nunca se ve

**Dificultad:** media · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** ninguno
(bug de la revisión post-fusión online, 2026-10-04)

## Objetivo

La barra de progreso de reaparición (`RespawnBar`) es hija de un
**CanvasLayer**, pero se posiciona en **coordenadas de mundo**
(`_respawn_pos` devuelve x hasta 4800 en un viewport de 1152 px): solo se ve
si el muerto reaparece en el primer cuarto izquierdo del nivel. Convertir
mundo→pantalla (centro de cámara + zoom, con clamp a los bordes) para que la
barra siempre aparezca sobre (o señalando hacia) el punto de reaparición.

## Contexto del proyecto (leer antes de tocar nada)

- `respawn_bar` (Node2D, clase interna `RespawnBar`) se crea en
  `_build_hud` y se añade a `cl` (el CanvasLayer del HUD): su `position` es
  píxel de pantalla, no de mundo.
- La actualiza `_update_respawn_bar()` (llamada cada tick desde
  `_physics_process`), que hoy hace
  `respawn_bar.position = _respawn_pos(p) + Vector2(0, -96)`.
- `camera` es la Camera2D del juego; su `position` es el CENTRO de lo
  renderizado. La vista mide `VIEW_W=1152` × `VIEW_H=648`, pero el zoom
  varía: 1,0 normal, 0,9 en 2v2 y dinámico por separación (tarea 78).
  Fórmula pantalla = (mundo − camera.position) · zoom + viewport/2.
- El smoke test solo comprueba `respawn_bar.visible` tras una muerte
  (caso "HUD: barra de reaparición visible"): no posiciona nada, no se rompe.

## Instrucciones paso a paso

### 1. En `game.gd`, sustituir el cuerpo de `_update_respawn_bar`

Busca la función (única con ese nombre) y sustituye la línea
`respawn_bar.position = _respawn_pos(p) + Vector2(0, -96)` junto con su
bloque, dejando:

```gdscript
func _update_respawn_bar() -> void:
	var shown := false
	for i in players.size():
		if respawn_timers[i] > 0.0:
			var p := players[i]
			# la barra vive en un CanvasLayer: mundo→pantalla (centro de
			# cámara + zoom) y clamp para que nunca salga del viewport
			var vp := get_viewport_rect().size
			var wp := _respawn_pos(p) + Vector2(0, -96.0)
			var sx := clampf((wp.x - camera.position.x) * camera.zoom.x + vp.x * 0.5, 46.0, vp.x - 46.0)
			var sy := clampf((wp.y - camera.position.y) * camera.zoom.y + vp.y * 0.5, 30.0, vp.y - 30.0)
			respawn_bar.position = Vector2(sx, sy)
			respawn_bar.col = p.color
			respawn_bar.frac = respawn_timers[i] / RESPAWN_DELAY
			shown = true
			break
	respawn_bar.visible = shown
```

## Qué NO hacer

- No cambies la clase `RespawnBar` (el dibujo ya está bien).
- No la muevas de CanvasLayer ni le añadas una cámara propia: la conversión
  de coordenadas basta.
- No toques `_respawn_pos`: la siguen usando el juego y el online.

## Criterios de aceptación

1. Mata al rival en el centro del nivel y espera su reaparición: la barra
   aparece ARRIBA del punto de caída, visible, aunque esté lejos de la
   cámara.
2. En 2v2 (zoom 0,9) y con el zoom dinámico de la 78 sigue clavada al punto.
3. La barra nunca se sale de la pantalla (clamp a 46 px del borde).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/test_runner.tscn
```

Últimas líneas esperadas: `SMOKE OK - todas las mecánicas funcionan` y
`RESULT: ALL PASSED (16)`.
