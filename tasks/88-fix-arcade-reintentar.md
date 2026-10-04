# Tarea 88 — Fix: "Y: reintentar" no arranca si la derrota fue en la arena 1

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** ninguno
(bug de la revisión post-fusión online, 2026-10-04)

## Objetivo

Al perder en el arcade aparece "ARCADE TERMINADO EN EL NIVEL N · Y:
reintentar". Y apaga el arcade y, al volver a pulsarlo, `set_arcade(true)`
llama `set_arena(0)` para reconstruir el nivel… pero si la derrota llegó en
un nivel de la arena 1 (niveles 1, 5, 9…), `set_arena(0)` se sale por el
guard de "misma arena" (`if id % ARENA_NAMES.size() == arena_id: return`)
sin resetear marcador ni `match_over` ni arrancar ronda: la pantalla queda
congelada con el mensaje de derrota para siempre. Replicar el patrón que
`_arcade_next` ya usa para el caso mismo-arena.

## Contexto del proyecto (leer antes de tocar nada)

- `set_arcade(on)` (game.gd): al activar pone `arcade_level = 1`, activa el
  bot y llama `set_arena(0)` incondicionalmente.
- `set_arena(id)`: primera línea `if id % ARENA_NAMES.size() == arena_id:
  return` — todo el reset (marcador, stats, `match_over`, `_start_round`)
  vive DESPUÉS de ese guard.
- `_arcade_next()` ya resuelve el mismo caso correctamente:
  `if want != arena_id: set_arena(want) else: match_over = false …
  _start_round()`. Esta tarea copia ese patrón en `set_arcade`.
- La tecla Y es `toggle_arcade`; el flujo de reintento real es Y (apaga) +
  Y (enciende de nuevo): el bug pisa la segunda pulsación.

## Instrucciones paso a paso

### 1. En `set_arcade`, sustituir la llamada incondicional a `set_arena`

Busca en `set_arcade` el bloque:

```gdscript
	if on:
		arcade_level = 1
		bot_level = _arcade_difficulty()
		players[1].is_bot = true
		set_arena(0)
		show_msg("ARCADE — NIVEL 1", 1.2)
```

y sustitúyelo por:

```gdscript
	if on:
		arcade_level = 1
		bot_level = _arcade_difficulty()
		players[1].is_bot = true
		if arena_id != 0:
			set_arena(0)
		else:
			# ya en la arena 1: set_arena saltaría por el guard de "misma
			# arena" y el marcador/match_over quedarían sin resetear
			scores = [0, 0]
			stats = _fresh_stats()
			match_over = false
			stats_label.visible = false
			_update_hud()
			_start_round()
		show_msg("ARCADE — NIVEL 1", 1.2)
```

## Qué NO hacer

- No quites el guard de `set_arena` (lo protegen la C del selector de
  arenas y el smoke test del cambio de arena).
- No toques `_arcade_next` (ya está bien).
- No cambies el texto ni el mapeo de la tecla Y.

## Criterios de aceptación

1. Arcade, pierde en el NIVEL 1, pulsa Y dos veces: cartel "ARCADE — NIVEL
   1", cuenta atrás 3·2·1 y partida jugable (antes: congelado).
2. Perder en el nivel 5 (también arena 1) y reintentar funciona igual.
3. Entrar al arcade desde la arena 1 en partida normal sigue funcionando
   (la ronda se rearranca sin corromper nada).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
