# Tarea 36 — Modo arcade: escalera de rivales con dificultad progresiva (tecla Y)

**Dificultad:** media · **Archivos:** `scripts/game.gd`, `test/smoke_test.gd` · **Prerrequisitos:** ninguno

## Objetivo

El modo single player del original: **arcade**. Con la tecla **Y** arranca una
escalera infinita: cada partido ganado sube el nivel, la dificultad del bot
(fácil → normal → difícil) y rota la arena. Perder un partido termina la
escalera ("ARCADE TERMINADO EN EL NIVEL X"); con Y se vuelve a empezar. Gana
qui llegue: el marcador es la racha de niveles.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript), arte y sonido procedurales, indentación con
  **tabs**, comentarios en español.
- `scripts/game.gd`:
	- `var bot_level := 1` (dificultad del bot de P2, 1..3) y `BOT_CFG` con 3
	  niveles; `players[1].is_bot` activa el bot.
	- `func set_arena(id: int) -> void:` cambia de arena y REINICIA marcador,
	  stats y ronda... pero OJO: empieza con
	  `if id % ARENA_NAMES.size() == arena_id: return` (si pides la misma arena,
	  no hace nada). Tenlo en cuenta al subir de nivel.
	- `const ARENA_NAMES := ["RUINAS DE MEDIANOCHE", "TEMPLO DEL ALBA"]`.
	- `func _point(p: Player) -> void:` empieza con `scores[_team(p)] += 1` y
	  tiene la rama `if scores[_team(p)] >= WIN_SCORE:` (fin de partido).
	  Esta tarea se inserta ANTES de `match_over = true` de esa rama.
	- `_setup_input()` define acciones en `defs` (hay `"toggle_arena": [KEY_C],`);
	  los toggles se procesan en `_physics_process` con
	  `if Input.is_action_just_pressed("toggle_xxx"):` (existe el bloque de
	  `toggle_2v2` que llama `set_mode_2v2(not mode_2v2)`).
	- `func set_mode_2v2(on: bool)`, `func set_chaos(on: bool)`,
	  `func _start_round()`, `show_msg(text, dur)` existen.
	- `stats = _fresh_stats()` y `_update_hud()` reinician el HUD.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Variables y tecla

1.1. Junto a `var mode_2v2 := false`, añade:

```gdscript
var arcade := false
var arcade_level := 1
var arcade_over := false
```

1.2. En `_setup_input()`, después de la línea `"toggle_arena": [KEY_C],`, añade:

```gdscript
		"toggle_arcade": [KEY_Y],
```

1.3. En `_physics_process`, justo después del bloque de `toggle_arena`, añade:

```gdscript
	if Input.is_action_just_pressed("toggle_arcade"):
		set_arcade(not arcade)
```

### 2. Funciones del modo

2.1. Debajo de `set_chaos(on)`, añade:

```gdscript
func set_arcade(on: bool) -> void:
	if on == arcade:
		return
	if on and mode_2v2:
		set_mode_2v2(false)
	if on and chaos:
		set_chaos(false)
	arcade = on
	arcade_over = false
	if on:
		arcade_level = 1
		bot_level = _arcade_difficulty()
		players[1].is_bot = true
		set_arena(0)
		show_msg("ARCADE — NIVEL 1", 1.2)
	else:
		show_msg("ARCADE: DESACTIVADO", 0.8)


func _arcade_difficulty() -> int:
	return clampi(1 + (arcade_level - 1) / 2, 1, 3)


func _arcade_next() -> void:
	arcade_level += 1
	bot_level = _arcade_difficulty()
	right_of_way = null
	scores = [0, 0]
	stats = _fresh_stats()
	_update_hud()
	var want := (arcade_level - 1) % ARENA_NAMES.size()
	if want != arena_id:
		set_arena(want)
	else:
		match_over = false
		stats_label.visible = false
		_start_round()
	show_msg("ARCADE — NIVEL %d  ·  BOT %s" % [arcade_level, ["FÁCIL", "NORMAL", "DIFÍCIL"][_arcade_difficulty() - 1]], 1.4)
```

(Con 2 arenas, `set_arena` solo reconstruye si la arena cambia; si toca la
misma, se reinicia la ronda a mano. Cuando añadas más arenas, la rotación ya
funciona sola.)

### 3. Engancharlo a los puntos

3.1. En `_point(p)`, dentro de la rama `if scores[_team(p)] >= WIN_SCORE:`,
JUSTO DESPUÉS de la primera línea de la rama (antes de
`match_over = true`), inserta:

```gdscript
		if arcade:
			if _team(p) == 0:
				_arcade_next()
				return
			match_over = true
			arcade_over = true
			show_msg("ARCADE TERMINADO EN EL NIVEL %d  ·  Y: reintentar" % arcade_level, 12.0)
			return
```

(Ganar el partido en arcade sube de nivel sin pantalla de fin; perder termina
la escalera. El `return` evita el fin de partido normal y el resto del bloque
queda intacto para el modo normal.)

3.2. En `_physics_process`, busca el bloque de `toggle_2v2`
(`if Input.is_action_just_pressed("toggle_2v2"):`) y añádele la guardia para
que el 2v2 no pise el arcade:

```gdscript
	if Input.is_action_just_pressed("toggle_2v2") and not arcade:
```

### 4. Smoke test: sección nueva

En `test/smoke_test.gd`, busca la línea `print("")` e inserta ANTES:

```gdscript
	# 30. Arcade: ganar sube de nivel, perder termina la escalera
	game.set_arcade(true)
	_check(game.arcade and game.players[1].is_bot, "Arcade: activado con bot")
	game.scores = [2, 0]
	game.right_of_way = game.players[0]
	p1.position = Vector2(4770.0, 531.0)
	p1.velocity = Vector2.ZERO
	p1.state = 0
	await get_tree().create_timer(0.2).timeout
	_check(game.arcade_level == 2 and game.scores == [0, 0], "Arcade: ganar sube de nivel y resetea")
	game.scores = [0, 2]
	game.right_of_way = game.players[1]
	p2.is_bot = false
	p2.position = Vector2(30.0, 531.0)
	p2.velocity = Vector2.ZERO
	p2.state = 0
	await get_tree().create_timer(0.2).timeout
	_check(game.arcade_over and game.match_over, "Arcade: perder termina la escalera")
	game.set_arcade(false)
	_check(not game.arcade, "Arcade: desactivado")
```

## Qué NO hacer

- No cambies WIN_SCORE ni `_point` fuera de la inserción indicada: el modo
  normal sigue terminando el partido como siempre.
- No hagas que el arcade active el modo 2v2 ni el caos (se apagan al entrar).
- No rompas el bot existente: arcade solo fuerza `players[1].is_bot = true`
  y ajusta `bot_level`.
- No uses `Engine.time_scale` ni pausas: la escalera es solo de partidos.

## Criterios de aceptación

1. Y activa el arcade: bot siempre encendido, nivel 1 con bot FÁCIL, arena
   reiniciada y cartel "ARCADE — NIVEL 1".
2. Cada partido ganado suma un nivel: el bot pasa a NORMAL en el nivel 3 y a
   DIFÍCIL en el 5, y la arena rota.
3. Perder un partido muestra "ARCADE TERMINADO EN EL NIVEL X"; Y vuelve a
   empezar la escalera desde el nivel 1.
4. En arcade no se puede entrar en 2v2; activar 2v2 fuera del arcade funciona
   como siempre.
5. El smoke test pasa, incluida la sección 30 nueva.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
