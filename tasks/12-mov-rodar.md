# Tarea 12 — Rodar (esquiva rápida)

**Dificultad:** media · **Archivos:** `scripts/player.gd` · **Prerrequisitos:** ninguno

## Objetivo

Nueva movilidad: manteniendo **abajo** (estancia baja) y pulsando **saltar**, el
duelist rueda hacia donde mira: un voltereta rápida de 0,34 s que cuenta como
estancia baja (los ataques altos te fallan, los medios y bajos te pillan) y con
0,55 s de recuperación.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/player.gd` — `class_name Player` (CharacterBody2D):
	- `enum State {IDLE, RUN, JUMP, DIVEKICK, ATTACK, STUNNED, KNOCKDOWN, DEAD}`
	  (índices 0–7; el smoke test los usa por número: **añade ROLL AL FINAL del
	  enum, nunca en medio**).
	- Constantes de movimiento arriba del todo (`SPEED`, `JUMP_VELOCITY`, ...).
	- En `_physics_process` hay un bloque `if can_act:` que gestiona input:
	  primero salto (`if hit("jump") and is_on_floor():`), luego ataque, luego
	  lanzamiento. `can_act` exige `state in [State.IDLE, State.RUN, State.JUMP]`.
	- Después hay DOS `match state:`: uno avanza temporizadores/estados (casos
	  ATTACK, STUNNED, KNOCKDOWN) y otro fija `velocity.x` (casos IDLE/RUN, JUMP,
	  ATTACK, STUNNED/KNOCKDOWN).
	- La defensa de ataques la resuelve `game.gd::_resolve_attacks()` leyendo
	  `def.stance`: ataque alto contra estancia baja = "miss" (falla). Forzar
	  `stance = H.LOW` durante la rodada reutiliza esa regla sin tocar `game.gd`.
	- `_draw()` empieza con una cadena de `if state == State.KNOCKDOWN: ... elif
	  state == State.DIVEKICK: ...` que fija transform (`t_pos`, `t_rot`, `t_scl`).
	- Input: `held(n)` pulsada, `hit(n)` recién pulsada (n = "left", "right",
	  "up", "down", "jump", "attack", "throw").
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Enum, constantes y variables

1.1. Cambia la línea del enum State por (ROLL al final, índice 8):

```gdscript
enum State { IDLE, RUN, JUMP, DIVEKICK, ATTACK, STUNNED, KNOCKDOWN, DEAD, ROLL }
```

1.2. Junto a las demás constantes, añade:

```gdscript
const ROLL_DURATION := 0.34
const ROLL_SPEED := 520.0
const ROLL_COOLDOWN := 0.55
```

1.3. Junto a las demás variables de instancia, añade:

```gdscript
var roll_time := 0.0
var roll_cd := 0.0
```

### 2. Enfriamiento

En `_physics_process`, junto a `flash_time = maxf(...)` (los temporizadores que
se descuentan al principio), añade:

```gdscript
	roll_cd = maxf(0.0, roll_cd - delta)
```

### 3. Disparador (antes que el salto normal)

En el bloque `if can_act:`, la primera línea es `if hit("jump") and is_on_floor():`.
Inserta la rodada POR DELANTE, de modo que quede:

```gdscript
		if hit("jump") and held("down") and is_on_floor() and roll_cd <= 0.0:
			state = State.ROLL
			roll_time = 0.0
			roll_cd = ROLL_COOLDOWN
			stance = H.LOW
			_sfx("swing", -22.0)
		elif hit("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			state = State.JUMP
			_sfx("jump", -16.0)
```

(las ramas `elif hit("attack"):` y `elif hit("throw")...` siguientes no cambian).

### 4. Avance del estado

4.1. En el PRIMER `match state:` (el de temporizadores), añade el caso:

```gdscript
		State.ROLL:
			roll_time += delta
			if roll_time >= ROLL_DURATION:
				state = State.IDLE
```

4.2. En el SEGUNDO `match state:` (el de velocidad), añade el caso:

```gdscript
		State.ROLL:
			velocity.x = facing * ROLL_SPEED
			stance = H.LOW
```

### 5. Dibujo (voltereta)

En `_draw()`, en la cadena de transforms, añade una rama después de
`if state == State.KNOCKDOWN: ...`:

```gdscript
		elif state == State.ROLL:
			t_rot = -TAU * (roll_time / ROLL_DURATION)
			t_pos = Vector2(0, 14)
			t_scl = Vector2(0.9, 0.9)
```

## Qué NO hacer

- No cambies el orden del enum ni los índices 0–7.
- No hagas la rodada invulnerable a todo: solo hereda la regla de "ataque alto
  falla contra estancia baja" (ya pasa al forzar `stance`).
- No permitas atacar ni saltar durante la rodada (`can_act` ya lo impide: no
  añadas ROLL a esa lista).

## Criterios de aceptación

1. Mantener S (o ↓) y pulsar W (o ↑): voltereta rápida hacia donde miras.
2. Sin mantener abajo, W salta normal (el salto no se ha roto).
3. Durante la rodada, un ataque alto del rival falla; uno medio o bajo mata.
4. No puedes encadenar rodadas sin parar (hay 0,55 s de recuperación).
5. El smoke test sigue pasando.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
