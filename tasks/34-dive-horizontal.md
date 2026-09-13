# Tarea 34 — Dive horizontal: abajo + salto corriendo

**Dificultad:** media · **Archivos:** `scripts/player.gd`, `scripts/game.gd`, `test/smoke_test.gd` · **Prerrequisitos:** ninguno

## Objetivo

Movimiento del original calibrado contra vídeo: **corriendo**, mantener
**abajo** y pulsar **salto** lanza un **vuelo rasante horizontal** (546 px/s,
~3,5 cuerpos de distancia) que cruza fosos y, con la espada, MATA a quien
pilla. Al acabar el vuelo, el duelistat cae derribado (0,6 s). De pie (sin
correr), abajo + salto sigue siendo la rodada de siempre.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript), arte y sonido procedurales, indentación con
  **tabs**, comentarios en español.
- `scripts/player.gd`:
	- Enum `State { IDLE, RUN, JUMP, DIVEKICK, ATTACK, STUNNED, KNOCKDOWN, DEAD, ROLL }`
	  (índices 0–8; el smoke test usa números: **añade DIVE AL FINAL, índice 9**).
	- La rodada se dispara en el bloque `if can_act:` con
	  `if hit("jump") and held("down") and is_on_floor() and roll_cd <= 0.0:`
	  (comentario `# rodar: esquiva rápida agachado`).
	- Hay DOS `match state:`: el primero avanza temporizadores (casos ATTACK,
	  STUNNED, KNOCKDOWN, ROLL), el segundo fija `velocity.x` (IDLE/RUN, JUMP,
	  ATTACK, STUNNED/KNOCKDOWN, ROLL).
	- `_draw()` tiene una cadena de transforms `if state == State.KNOCKDOWN: ...
	  elif state == State.ROLL: ... elif ...` con `t_pos/t_rot/t_scl`.
- `scripts/game.gd`:
	- `func _resolve_divekicks() -> void:` resuelve la patada voladora con
	  `p.divekick_resolved`; en `_physics_process` se llama tras
	  `_resolve_attacks()`.
	- `_foes_of(p)`, `_kill(def, atk)`, `_clash(a, b)`, `_burst(...)`,
	  `shake_time` existen.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. `player.gd`: enum, constantes y variables

1.1. Sustituye la línea del enum por (DIVE al final, índice 9):

```gdscript
enum State { IDLE, RUN, JUMP, DIVEKICK, ATTACK, STUNNED, KNOCKDOWN, DEAD, ROLL, DIVE }
```

1.2. Junto a `const ROLL_COOLDOWN := 0.55`, añade:

```gdscript
const DIVE_SPEED := 546.0
const DIVE_TIME := 0.55
```

1.3. Junto a `var roll_cd := 0.0`, añade:

```gdscript
var dive_time := 0.0
var dive_resolved := false
```

### 2. `player.gd`: disparador (corriendo = dive, parado = rodar)

En el bloque `if can_act:`, ANTES de la línea
`if hit("jump") and held("down") and is_on_floor() and roll_cd <= 0.0:`,
inserta esta rama (la rodada pasa a ser `elif`):

```gdscript
		if hit("jump") and held("down") and state == State.RUN and absf(velocity.x) > 120.0 and roll_cd <= 0.0:
			# dive horizontal: vuelo rasante con la espada
			state = State.DIVE
			dive_time = 0.0
			dive_resolved = false
			roll_cd = DIVE_TIME
			stance = H.MID
			velocity = Vector2(facing * DIVE_SPEED, 0.0)
			_sfx("swing", -18.0)
```

y cambia el `if` de la rodada por `elif`:

```gdscript
		elif hit("jump") and held("down") and is_on_floor() and roll_cd <= 0.0:
```

### 3. `player.gd`: avance y velocidad del estado

3.1. En el PRIMER `match state:` añade el caso:

```gdscript
		State.DIVE:
			dive_time += delta
			if dive_time >= DIVE_TIME:
				state = State.KNOCKDOWN
				knockdown_time = 0.6
```

3.2. En el SEGUNDO `match state:` añade el caso:

```gdscript
		State.DIVE:
			velocity.x = facing * DIVE_SPEED
			velocity.y = 0.0
			stance = H.MID
```

(`velocity.y = 0.0` anula la gravedad cada frame: el vuelo es rasante y cruza
los fosos sin caerse.)

### 4. `player.gd`: dibujo

En la cadena de transforms de `_draw()`, después de la rama `elif state == State.ROLL:`,
añade:

```gdscript
	elif state == State.DIVE:
		t_rot = 1.35
		t_pos = Vector2(0, 6)
```

### 5. `game.gd`: resolución del impacto

5.1. Debajo de `_resolve_divekicks`, añade:

```gdscript
func _resolve_dives() -> void:
	for p in players:
		if p.state != Player.State.DIVE or p.dive_resolved:
			continue
		for def in _foes_of(p):
			if def.state == Player.State.DEAD or def.invuln_time > 0.0:
				continue
			if absf(def.position.x - p.position.x) > 40.0 or absf(def.position.y - p.position.y) > 50.0:
				continue
			p.dive_resolved = true
			if def.state == Player.State.ATTACK and def.attack_is_active() and def.attack_height == Player.H.MID:
				_clash(def, p)
			elif p.has_sword:
				_kill(def, p)
			else:
				var push := 1 if def.position.x >= p.position.x else -1
				def.knockdown(push)
			p.state = Player.State.KNOCKDOWN
			p.knockdown_time = 0.6
			p.velocity = Vector2(-float(p.facing) * 160.0, -160.0)
			shake_time = maxf(shake_time, 0.14)
			break
```

5.2. En `_physics_process`, después de la línea `_resolve_divekicks()`, añade:

```gdscript
	_resolve_dives()
```

### 6. Smoke test: sección nueva

En `test/smoke_test.gd`, busca la línea `print("")` e inserta ANTES:

```gdscript
	# 28. Dive horizontal: abajo + salto corriendo
	p1.has_sword = true
	p1.position = Vector2(1500.0, 531.0)
	p1.velocity = Vector2.ZERO
	p1.state = 1
	p2.position = Vector2(2600.0, 531.0)
	p2.velocity = Vector2.ZERO
	p2.state = 0
	await get_tree().physics_frame
	Input.action_press("p1_right")
	await get_tree().create_timer(0.2).timeout
	Input.action_press("p1_down")
	Input.action_press("p1_jump")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("p1_jump")
	Input.action_release("p1_down")
	_check(p1.state == 9 and absf(p1.velocity.x) > 400.0, "Dive horizontal: vuelo rasante")
	await get_tree().create_timer(0.8).timeout
	Input.action_release("p1_right")
	_check(p1.state in [0, 1, 6], "Dive horizontal: al acabar cae derribado o se levanta")
```

## Qué NO hacer

- No cambies la rodada (down + salto DE PIE sigue rodando): solo corriendo a
  velocidad sale el dive.
- No añadas DIVE a la lista de `can_act` (no se puede atacar ni saltar
  durante el vuelo).
- No hagas que el dive derribe con puños: si `has_sword`, mata; si no,
  derriba (ya está en `_resolve_dives`).
- No toques DIVEKICK ni su resolución: son mecánicas distintas.

## Criterios de aceptación

1. Corriendo, abajo + salto: vuelo rasante rápido que mantiene la altura y
   cruza el foso central sin caer.
2. El vuelo mata con espada (derriba sin ella) y termina con el que hizo el
   dive en el suelo 0,6 s.
3. De pie, abajo + salto sigue siendo la rodada de siempre.
4. No se puede atacar ni saltar durante el vuelo.
5. El smoke test pasa, incluida la sección 28 nueva.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
