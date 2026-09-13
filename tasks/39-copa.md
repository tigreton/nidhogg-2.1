# Tarea 39 — Modo Copa: semifinales contra bots y final humano vs humano (tecla O)

**Dificultad:** media · **Archivos:** `scripts/game.gd`, `test/smoke_test.gd` · **Prerrequisitos:** tarea 36 (arcade: `set_arcade`, `arcade`, `toggle_arcade` con tecla Y)

## Objetivo

El torneo local del original, adaptado a 2 humanos: con la tecla **O** arranca
una **Copa** de dos semifinales y final. **Semifinal 1: P1 vs BOT**;
**semifinal 2: P2 vs BOT**; y la **FINAL** entre los supervivientes (si ganan
los dos humanos, es humano vs humano; si un humano pierde, juega contra el
bot; si pierden los dos, gana el bot). El bot juega en nivel NORMAL.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript), arte y sonido procedurales, indentación con
  **tabs**, comentarios en español.
- La tarea 36 ya aplicó en `scripts/game.gd`: `var arcade`, `set_arcade(on)`,
  tecla `"toggle_arcade": [KEY_Y],` y el bloque de `toggle_2v2` con guardia
  `if Input.is_action_just_pressed("toggle_2v2") and not arcade:`.
- `scripts/game.gd`:
	- `func _point(p: Player) -> void:` la rama de fin de partido empieza con
	  `if scores[_team(p)] >= WIN_SCORE:` y, si aplicaste la 36, contiene el
	  bloque `if arcade:` con sus `return`. La copa se inserta justo DESPUÉS
	  de ese bloque `if arcade:` (y su `return`), antes de `match_over = true`.
	- `func _start_round()` reinicia posiciones; `show_msg(text, dur)`;
	  `stats = _fresh_stats()`; `_update_hud()`; `set_mode_2v2(on)`;
	  `set_chaos(on)`; `bot_level` (1..3); `players[0].is_bot` / `players[1].is_bot`.
	- Los toggles se procesan en `_physics_process` con bloques
	  `if Input.is_action_just_pressed("toggle_xxx"):` (existe el de
	  `toggle_arena` que llama `set_arena(arena_id + 1)`).
	- `right_of_way` controla quién corre; en el test se asigna a mano.
- El smoke test usa `game.set_*` y posiciones manuales; se añade una sección.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Variables y tecla

1.1. Junto a `var arcade := false` (tarea 36), añade:

```gdscript
var cup := false
var cup_stage := 0
var cup_alive := [true, true]
var cup_over := false
```

1.2. En `_setup_input()`, después de la línea `"toggle_arcade": [KEY_Y],`
(tarea 36), añade:

```gdscript
		"toggle_cup": [KEY_O],
```

1.3. En `_physics_process`, después del bloque de `toggle_arcade`, añade:

```gdscript
	if Input.is_action_just_pressed("toggle_cup"):
		set_cup(not cup)
```

### 2. Funciones de la copa

Debajo de `set_arcade` / `_arcade_next`, añade:

```gdscript
func set_cup(on: bool) -> void:
	if on == cup:
		return
	if on and arcade:
		set_arcade(false)
	if on and mode_2v2:
		set_mode_2v2(false)
	if on and chaos:
		set_chaos(false)
	cup = on
	cup_over = false
	if on:
		_cup_stage(0)
	else:
		players[0].is_bot = false
		players[1].is_bot = false
		show_msg("COPA: DESACTIVADA", 0.8)


func _cup_stage(stage: int) -> void:
	cup_stage = stage
	bot_level = 2
	if stage == 0:
		cup_alive = [true, true]
	scores = [0, 0]
	stats = _fresh_stats()
	match_over = false
	stats_label.visible = false
	_update_hud()
	match stage:
		0:
			players[0].is_bot = false
			players[1].is_bot = true
			show_msg("COPA — SEMIFINAL 1: P1 vs BOT", 1.6)
		1:
			players[0].is_bot = true
			players[1].is_bot = false
			show_msg("COPA — SEMIFINAL 2: P2 vs BOT", 1.6)
		2:
			if not cup_alive[0] and not cup_alive[1]:
				cup_over = true
				match_over = true
				show_msg("EL BOT GANA LA COPA  ·  O: nueva copa", 12.0)
				return
			players[0].is_bot = not cup_alive[0]
			players[1].is_bot = not cup_alive[1]
			show_msg("COPA — FINAL", 1.6)
	_start_round()
```

### 3. Engancharla a los puntos

En `_point(p)`, dentro de `if scores[_team(p)] >= WIN_SCORE:`, JUSTO DESPUÉS
del bloque `if arcade:` (tarea 36, que termina con `return`) y ANTES de la
línea `match_over = true` del flujo normal, inserta:

```gdscript
		if cup:
			if cup_stage < 2:
				var human_team: int = cup_stage
				cup_alive[human_team] = (_team(p) == human_team)
				match_over = true
				show_msg("FIN DE LA %s" % ("SEMIFINAL 1" if cup_stage == 0 else "SEMIFINAL 2"), 1.6)
				get_tree().create_timer(1.8).timeout.connect(func():
					if cup and not cup_over:
						_cup_stage(cup_stage + 1))
				return
			cup_over = true
			match_over = true
			show_msg("¡P%d GANA LA COPA!  ·  O: nueva copa" % p.player_id, 12.0)
			return
```

### 4. Guardias de modo

4.1. En `_physics_process`, en el bloque de `toggle_2v2` (tarea 36:
`if Input.is_action_just_pressed("toggle_2v2") and not arcade:`), amplía la
guardia:

```gdscript
	if Input.is_action_just_pressed("toggle_2v2") and not arcade and not cup:
```

4.2. En el bloque de `toggle_arena` (base:
`if Input.is_action_just_pressed("toggle_arena"):`), amplíala también:

```gdscript
	if Input.is_action_just_pressed("toggle_arena") and not arcade and not cup:
```

(cambiar de arena a mitad de copa rompería la llave).

### 5. Smoke test: sección nueva

En `test/smoke_test.gd`, busca la línea `print("")` e inserta ANTES:

```gdscript
	# 31. Copa: semifinales contra bots y final
	game.set_cup(true)
	_check(game.cup and game.players[1].is_bot, "Copa: semifinal 1 con bot")
	game.scores = [2, 0]
	game.right_of_way = game.players[0]
	p1.position = Vector2(4770.0, 531.0)
	p1.velocity = Vector2.ZERO
	p1.state = 0
	await get_tree().create_timer(0.2).timeout
	_check(game.match_over, "Copa: la semifinal 1 termina")
	await get_tree().create_timer(2.2).timeout
	_check(game.cup_stage == 1 and game.players[0].is_bot and not game.players[1].is_bot, "Copa: semifinal 2 lista")
	game.scores = [0, 2]
	game.right_of_way = game.players[1]
	p2.position = Vector2(30.0, 531.0)
	p2.velocity = Vector2.ZERO
	p2.state = 0
	await get_tree().create_timer(0.2).timeout
	_check(game.match_over, "Copa: la semifinal 2 termina")
	await get_tree().create_timer(2.2).timeout
	_check(game.cup_stage == 2, "Copa: final preparada")
	game.set_cup(false)
	_check(not game.cup and not game.players[0].is_bot and not game.players[1].is_bot, "Copa: desactivar devuelve el duelo")
```

## Qué NO hacer

- No repliques partidas de bots contra bots: la copa de este proyecto es solo
  la escalera de los dos humanos.
- No cambies el flujo de puntos normal ni el arcade: la copa se INSERTA y
  sale con `return`.
- No permitas cambiar de arena ni entrar en 2v2 durante la copa (guardias del
  paso 4).
- No uses archivos de guardado ni escenas nuevas: la copa vive en variables
  de `game.gd`.

## Criterios de aceptación

1. O activa la copa: semifinal 1 con P1 humano contra bot NORMAL.
2. Ganada la semifinal 1, sola arranca la semifinal 2 (P2 humano contra bot).
3. La final enfrenta a los supervivientes: dos humanos, un humano contra bot,
   o el cartel de que el bot gana la copa si cayeron los dos.
4. La final ganada muestra "¡P1/P2 GANA LA COPA!"; O apaga la copa y O de
   nuevo la reinicia desde la semifinal 1.
5. El smoke test pasa, incluida la sección 31 nueva.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
