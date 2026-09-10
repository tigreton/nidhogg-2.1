# Tarea 18 — Estocada (embestida al atacar corriendo)

**Dificultad:** media · **Archivos:** `scripts/player.gd` · **Prerrequisitos:** ninguno

## Objetivo

El movimiento firma de Nidhogg: si atacas con espada MIENTRAS te mueves, el
ataque se convierte en una estocada — te lanzas hacia delante a 620 px/s con la
espada extendida. Atacar parado queda como está. Da juego ofensivo al suelo y
combina con la rodada (esquiva) para un juego de entradas y salidas.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Todo el
  arte es procedural (`_draw()`) y los sonidos se generan por código: **no hay
  assets externos ni plugins**.
- `scripts/player.gd` — `class_name Player` (CharacterBody2D):
	- Estados: `enum State {IDLE, RUN, JUMP, DIVEKICK, ATTACK, STUNNED, KNOCKDOWN,
	  DEAD}` (índices 0–7; el smoke test depende de ellos: no los cambies).
	- Constantes: `ATTACK_DURATION := 0.30`, `ATTACK_FROM/TO` (ventana activa del
	  golpe), `ATTACK_RANGE := 86`.
	- En `_physics_process`, el bloque `if can_act:` contiene la rama
	  `elif hit("attack"):` que entra en `State.ATTACK` si hay espada y suelo.
	- Más abajo hay un `match state:` que fija velocidades; su caso ATTACK es:
	  `velocity.x = move_toward(velocity.x, facing * 110.0, 900.0 * delta)`
	  (el pequeño avance del ataque actual).
	- Input: `held(n)` = pulsada, `hit(n)` = recién pulsada (n = "left",
	  "right", "up", "down", "jump", "attack", "throw").
	- La resolución de golpes la hace `game.gd` leyendo `attack_is_active()`;
	  reutilizar `State.ATTACK` para la estocada evita tocar `game.gd`.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Constante y variable

1.1. Junto a las demás constantes de combate, añade:

```gdscript
const LUNGE_SPEED := 620.0
```

1.2. Junto a las demás variables de instancia, añade:

```gdscript
var attack_dash_time := 0.0   # > 0 mientras la estocada empuja hacia delante
```

1.3. En `_physics_process`, junto a los temporizadores que se descuentan al
principio (`invuln_time = maxf(...)`, `flash_time = maxf(...)`), añade:

```gdscript
	attack_dash_time = maxf(0.0, attack_dash_time - delta)
```

### 2. Disparador

En el bloque `if can_act:`, rama `elif hit("attack"):`, el caso de suelo con
espada es hoy:

```gdscript
				if is_on_floor():
					if has_sword:
						state = State.ATTACK
						attack_time = 0.0
						attack_resolved = false
						attack_height = stance
						_sfx("swing", -20.0)
```

Sustitúyelo por:

```gdscript
				if is_on_floor():
					if has_sword:
						state = State.ATTACK
						attack_time = 0.0
						attack_resolved = false
						attack_height = stance
						if held("right") or held("left"):
							attack_dash_time = ATTACK_DURATION
							velocity.x = facing * LUNGE_SPEED
						_sfx("swing", -20.0)
```

### 3. Velocidad durante la estocada

En el `match state:` de velocidades, sustituye el caso ATTACK:

```gdscript
			State.ATTACK:
				if attack_dash_time > 0.0:
					velocity.x = facing * LUNGE_SPEED
				else:
					velocity.x = move_toward(velocity.x, facing * 110.0, 900.0 * delta)
```

### 4. Inclinación visual (opcional pero recomendada)

En `_draw()`, en la cadena de transforms (la de `if state == State.KNOCKDOWN:
... elif state == State.DIVEKICK: ... elif state == State.STUNNED: ...`),
añade una rama después de la de STUNNED:

```gdscript
		elif state == State.ATTACK and attack_dash_time > 0.0:
			t_rot = 0.3
```

## Qué NO hacer

- No crees un estado nuevo: la estocada ES un `State.ATTACK` con empuje, para
  que choques, muertes y ventana de golpe sigan funcionando igual.
- No apliques estocada a la patada voladora ni a ataques sin espada.
- No permitas estocada en el aire (el `is_on_floor()` del disparador ya lo evita).

## Criterios de aceptación

1. Atacar parado: golpe normal con su pequeño avance (igual que antes).
2. Atacar manteniendo A/D (o ←/→): embestida rápida hacia delante con la espada
   extendida, ~190 px de recorrido.
3. La estocada puede chocar (defensa a tu altura) y matar como cualquier ataque.
4. La estocada sale hacia donde YA mirabas, no hacia la tecla recién pulsada
   (comportamiento intencional: el ataque fija la dirección).
5. Si en partida resulta demasiado fuerte, baja `LUNGE_SPEED` a 540.
6. El smoke test sigue pasando (sus ataques son siempre parado).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
