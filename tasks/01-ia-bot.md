# Tarea 01 — Bot jugable para el jugador 2

**Dificultad:** alta · **Archivos:** `scripts/player.gd`, `scripts/game.gd` · **Prerrequisitos:** ninguno

## Objetivo

Añadir un bot que controla a P2. Se activa/desactiva con la tecla **B**. El bot
sabe: duelar (acercarse, elegir estancia ganadora, atacar, defenderse, lanzar la
espada), correr a su meta cuando tiene el paso, e interponerse cuando el paso
lo tiene el humano.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg para 2 jugadores
  en un mismo teclado. Todo el arte es procedural (`_draw()`) y los sonidos se generan
  por código: **no hay assets externos ni plugins, y no se pueden añadir**.
- Archivos:
	- `scripts/game.gd` — nodo principal: nivel, cámara, HUD y resolución de ataques,
	  proyectiles, muertes, reapariciones, puntos y rondas. Constantes: `LEVEL_W=4800`,
	  `GROUND_Y=560`, `PIT_X0=2210`, `PIT_X1=2380`, `PLAT_X0=2130`, `PLAT_X1=2460`,
	  `PLAT_Y=448`, `GOAL_W=130`, `WIN_SCORE=3`, `RESPAWN_DELAY=2.4`. Variables clave:
	  `right_of_way: Player` (quién tiene "el paso" tras matar) y `scores` (2 enteros).
	- `scripts/player.gd` — `class_name Player` (CharacterBody2D). Estados en
	  `enum State {IDLE, RUN, JUMP, DIVEKICK, ATTACK, STUNNED, KNOCKDOWN, DEAD}`
	  (índices 0–7; el test headless depende de ellos) y estancias `enum H {LOW, MID, HIGH}`.
	  Lee input con acciones `p1_*`/`p2_*` registradas en runtime por `game._setup_input()`
	  (en `game.gd`). Métodos de input: `held(n)` (pulsada) e `hit(n)` (recién pulsada),
	  donde `n` es `"left"`, `"right"`, `"up"`, `"down"`, `"jump"`, `"attack"` o `"throw"`.
	- `scripts/sfx.gd` — `class_name Sfx`, estático: `Sfx.play(parent, pos, id, db)`.
	- `test/smoke_test.gd` — prueba automática headless.
- Reglas de estilo: GDScript tipado (`:=`, tipos en firmas), indentación con **tabs**,
  identificadores en inglés, comentarios y textos de juego en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. `scripts/player.gd` — entrada virtual para el bot

1.1. Junto a las demás variables de instancia (después de `var anim_time := 0.0`),
añade exactamente:

```gdscript
var is_bot := false
var bot_held := {}          # acciones que el bot mantiene pulsadas (solo si is_bot)
var bot_held_prev := {}     # estado del tick anterior, para detectar "recién pulsada"
var bot_think := 0.0        # cronómetro entre decisiones del bot (lo usa game.gd)
```

1.2. Reemplaza POR COMPLETO las funciones `held()` y `hit()` por:

```gdscript
func held(n: String) -> bool:
	if is_bot:
		return bool(bot_held.get(n, false))
	return Input.is_action_pressed(_a(n))


func hit(n: String) -> bool:
	if is_bot:
		return bool(bot_held.get(n, false)) and not bool(bot_held_prev.get(n, false))
	return Input.is_action_just_pressed(_a(n))
```

1.3. Dentro de `_physics_process`, busca la línea (dentro del bloque `if can_act:`):

```gdscript
	dir = float(Input.is_action_pressed(_a("right"))) - float(Input.is_action_pressed(_a("left")))
```

y sustitúyela por:

```gdscript
	dir = (1.0 if held("right") else 0.0) - (1.0 if held("left") else 0.0)
```

1.4. Al final de `_physics_process` (justo después de `queue_redraw()`), añade:

```gdscript
	if is_bot:
		bot_held_prev = bot_held.duplicate()
```

### 2. `scripts/game.gd` — tecla de activación

2.1. En `_setup_input()`, dentro del diccionario `defs`, añade la entrada:

```gdscript
	"toggle_bot": [KEY_B],
```

2.2. En `_physics_process`, justo después del bloque `if match_over and Input.is_action_just_pressed("restart"):`,
añade:

```gdscript
	if Input.is_action_just_pressed("toggle_bot"):
		players[1].is_bot = not players[1].is_bot
		show_msg("BOT P2 %s" % ("ACTIVADO" if players[1].is_bot else "DESACTIVADO"), 0.7)
```

2.3. En el bucle `for p in players:` que asigna `p.frozen`, añade debajo (dentro del bucle):

```gdscript
		if p.is_bot:
			_bot_think(p, delta)
```

### 3. `scripts/game.gd` — cerebro del bot

Añade estas funciones nuevas al final del archivo:

```gdscript
func _bot_think(p: Player, delta: float) -> void:
	var foe := _other(p)
	p.bot_think -= delta
	if p.bot_think > 0.0:
		return
	p.bot_think = 0.12
	var want := {}
	var tap := ""
	var adx := absf(foe.position.x - p.position.x)
	var sd := 1.0 if foe.position.x >= p.position.x else -1.0
	var on_floor := p.is_on_floor()

	if right_of_way == p:
		# corredor: correr hacia su meta y cruzar el foso por la plataforma
		if p.goal_dir > 0:
			want["right"] = true
		else:
			want["left"] = true
		if on_floor and p.position.x > PLAT_X0 - 130.0 and p.position.x < PLAT_X1 + 130.0 and not (p.position.x > PLAT_X0 + 40.0 and p.position.x < PLAT_X1 - 40.0):
			tap = "jump"
	elif right_of_way == foe:
		# interceptor: adelantarse en la dirección hacia la que corre el rival
		var tx: float = foe.position.x + float(foe.goal_dir) * 200.0
		if tx > p.position.x + 20.0:
			want["right"] = true
		elif tx < p.position.x - 20.0:
			want["left"] = true
		if on_floor and p.position.x > PLAT_X0 - 130.0 and p.position.x < PLAT_X1 + 130.0 and not (p.position.x > PLAT_X0 + 40.0 and p.position.x < PLAT_X1 - 40.0):
			tap = "jump"
	else:
		# duelo: gestión de distancia y estancias
		if adx > 260.0:
			if sd > 0.0:
				want["right"] = true
			else:
				want["left"] = true
			if on_floor and randf() < 0.05:
				tap = "jump"
		elif adx < 55.0:
			if sd > 0.0:
				want["left"] = true
			else:
				want["right"] = true
		elif foe.state == Player.State.ATTACK and foe.attack_is_active():
			# cubrirse: igualar la altura del ataque rival para provocar choque
			match foe.attack_height:
				Player.H.HIGH:
					want["up"] = true
				Player.H.LOW:
					want["down"] = true
		else:
			# estancia ganadora: contra MID atacar LOW; contra HIGH y LOW, quedarse en MID
			if foe.stance == Player.H.MID:
				want["down"] = true
			if randf() < 0.30:
				tap = "attack"
			if p.has_sword and randf() < 0.03:
				tap = "throw"
	# patada voladora si el rival está abajo y cerca
	if not on_floor and adx < 100.0 and foe.position.y > p.position.y + 40.0:
		tap = "attack"
	p.bot_held = want
	if tap != "" and p.state in [Player.State.IDLE, Player.State.RUN, Player.State.JUMP]:
		p.bot_held[tap] = true
```

### 4. Pista visual

En `_build_hud()`, en el texto del label `hint`, añade al final `    B: bot P2`.

## Qué NO hacer

- No cambies el enum `State` ni los índices de estados existentes.
- No toques `scripts/sfx.gd`, `scripts/pickup.gd` ni `scripts/sword_projectile.gd`.
- No hagas al bot jugador 1; solo P2.
- No uses `Input.action_press()` para el bot: usa `bot_held` como se indica.

## Criterios de aceptación

1. El juego arranca normal; P2 sigue siendo humano hasta pulsar B.
2. Con B activado, P2 se acerca, cambia de estancia, ataca y en algún momento lanza la espada.
3. Si el bot te mata, corre hacia SU meta (la izquierda) y salta el foso por la plataforma.
4. Si tú matas al bot, al reaparecer se interpone en tu camino hacia la derecha.
5. Con B de nuevo, P2 vuelve a control humano.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`
(los criterios 2–5 se comprueban a mano abriendo el juego con F5).
