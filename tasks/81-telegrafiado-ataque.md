# Tarea 81 — Telegrafiado del ataque (windup legible, squash e inclinación)

**Dificultad:** media · **Archivos:** `scripts/player.gd`, `test/screenshots.gd` (ajuste del bloque 17) · **Prerrequisitos:** 60 aplicada (renderer de poses)

## Objetivo

La divergencia de feel nº 1 contra el original: aquí la pose de ataque
aparece en el mismo frame del input; en el original, la estocada se ANUNCIA.
Esta tarea vende el windup con los assets actuales: **la pose neutra se
mantiene hasta `attack_from()`** (el espadón telegrafía 0,16 s, la daga 0,05
— el peso del arma se lee solo), más **squash de aterrizaje** de un frame y
**inclinación al correr** proporcional a la velocidad.

## Contexto del proyecto (leer antes de tocar nada)

- `player.gd::_pose_name()`: rama `State.ATTACK:` con `match attack_height`
  → `attack_high/mid/low`. La ventana activa es `attack_from()`…`attack_to()`
  (por arma: florete 0,07–0,20; espadón 0,16–0,30; daga 0,05–0,13) y
  `attack_time` se acumula en el primer `match` de `_physics_process`.
- El bloque de transform de `_draw()` calcula `t_pos/t_rot/t_scl` por estado
  (KNOCKDOWN, ROLL, DIVE…) y luego dibuja la pose. La detección de
  aterrizaje existe: `if is_on_floor() and not was_on_floor: _dust(...)`.
- `velocity.x` y `facing` están disponibles en `_draw`; correr es
  `State.RUN`.
- El sonido del swing ya suena AL PULSAR (audio-telegraph ✓): esta tarea
  añade el visual, no más sonido.
- El bloque 17 del recorrido de capturas fuerza `attack_time = 0.0` y
  captura: con el windup, esa captura saldría en pose neutra — el paso 4 lo
  corrige.
- Reglas de estilo: GDScript tipado, tabs, español.

## Instrucciones paso a paso

### 1. Windup: pose neutra hasta la ventana activa

En `_pose_name()`, sustituye la rama `State.ATTACK:` (las tres primeras
líneas: `State.ATTACK:` + `match attack_height:` + primer `return`) por:

```gdscript
		State.ATTACK:
			# telegrafiado (tarea 81): hasta attack_from() se mantiene la
			# pose neutra — el windup dura lo que el arma tarda en golpear
			if attack_time < attack_from():
				if not is_on_floor():
					return "jump" if velocity.y < 0.0 else "fall"
				return "crouch" if stance == H.LOW else "idle"
			match attack_height:
				H.HIGH:
					return "attack_high"
```

(el resto de la rama, igual).

### 2. Squash de aterrizaje

Junto a `var was_on_floor := true`, añade `var land_squash := 0.0`. En la
detección de aterrizaje:

```gdscript
	if is_on_floor() and not was_on_floor:
		land_squash = 0.12
		_dust(10, 150.0)
```

(en el mismo sitio donde ya está el `_dust`; la línea del `_dust` no se
duplica: solo se AÑADE `land_squash = 0.12` encima). Descuento junto a los
demás timers: `land_squash = maxf(0.0, land_squash - delta)`.

En `_draw()`, dentro del bloque de transform (tras calcular `t_rot`/`t_scl`,
aplicando después de los `match` de estado para no ser pisado):

```gdscript
	if land_squash > 0.0:
		# squash de aterrizaje: se recupera en 0,12 s
		var k := land_squash / 0.12
		t_scl = Vector2(1.0 + 0.14 * k, 1.0 - 0.16 * k)
```

### 3. Inclinación al correr

En el mismo bloque de transform, tras el squash:

```gdscript
	elif state == State.RUN and push_time <= 0.0:
		# inclinación hacia delante proporcional a la velocidad
		t_rot = signf(velocity.x) * minf(absf(velocity.x) / 330.0, 1.0) * 0.10
```

(el `elif` cuelga del `if land_squash`: el squash manda al aterrizar).

### 4. Bloque 17 de capturas

En `test/screenshots.gd`, bloque de `17_accion_*`: tras
`game.players[0].attack_time = 0.0`, añade:

```gdscript
		game.players[0].attack_time = game.players[0].attack_from() + 0.03
```

(sustituye la asignación a 0.0: captura ya en pleno golpe, no en windup).

## Qué NO hacer

- No alargues el windup con timers nuevos: dura EXACTAMENTE `attack_from()`
  del arma (esa es la gracia: la daga casi no telegrafía, el espadón mucho).
- No apliques el squash a KNOCKDOWN/ROLL (sus transforms son lectura de
  estado; el squash es solo del aterrizaje de salto/caída).
- No inclines en DIVE/DIVEKICK/SIDEKICK (sus rotaciones ya son el gesto).

## Criterios de aceptación

1. Espadón: se ve la preparación (~0,16 s en pose neutra) antes del barrido;
   daga: casi sin aviso. El ojo aprende el arma sin leer números.
2. Aterrizar de un salto hunde el sprite un instante; correr inclina el
   cuerpo hacia delante según la velocidad (más corriendo desarmado).
3. Las capturas 17 vuelven a salir en pleno ataque.
4. `SMOKE OK` y `CAPTURAS OK`.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --path . res://test/screenshots.tscn
```

Últimas líneas esperadas: `SMOKE OK - todas las mecánicas funcionan` y
`CAPTURAS OK`.
