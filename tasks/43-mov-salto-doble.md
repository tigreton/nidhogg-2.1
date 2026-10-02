# Tarea 43 — Salto doble (parado vs carrerilla) y gravedad asimétrica

**Dificultad:** media · **Archivos:** `scripts/player.gd`, `test/suite_movimiento.gd` · **Prerrequisitos:** 41 (trazas) y 42 (runner) aplicados

## Objetivo

Calibración portada del proyecto hermano (medida contra gameplay real de
Nidhogg 2): saltar **parado** debe elevar ~1 personaje (~66 px) y saltar **con
carrerilla** ~2,5 personajes (~144 px, el ápice actual, para no romper la
arena ya tuneada). Además la gravedad pasa a ser asimétrica: subida suave,
bajada más pesada, con velocidad de caída máxima — el salto "flota" arriba y
cae con pegada arcade.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/player.gd` — constantes arriba del todo (líneas ~13-30):
  `JUMP_VELOCITY := -700.0` y `GRAVITY := 1700.0`. La gravedad se aplica en
  `_physics_process` con `if not is_on_floor(): velocity.y += GRAVITY * delta`
  (~línea 150). El salto se dispara en el bloque `if can_act:` con
  `elif hit("jump") and is_on_floor(): velocity.y = JUMP_VELOCITY` — el estado
  AÚN es `State.RUN` en ese instante (el cambio a JUMP va después), así que
  distinguir parado/carrerilla es mirar `state == State.RUN`.
- Verifica con `grep -n "JUMP_VELOCITY\|GRAVITY" scripts/*.gd` que solo
  `player.gd` las usa (la flecha y las rocas no tienen gravedad propia).
- El smoke test tiene casos de salto a tejados/peldaños/puente escritos para
  el salto único de ~144 px: si uno falla por el salto parado más corto,
  aplica la Contingencia del final.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en
  español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Constantes nuevas

En `player.gd`, sustituye las dos constantes:

```gdscript
const JUMP_VELOCITY := -700.0
const GRAVITY := 1700.0
```

por:

```gdscript
const JUMP_VY_STAND := -460.0   # ápice ≈ 66 px ≈ 1,1 · altura del jugador (58)
const JUMP_VY_RUN := -680.0     # ápice ≈ 144 px (el actual: no rompe la arena)
const GRAVITY_UP := 1600.0      # subida suave (el salto "flota" arriba)
const GRAVITY_FALL := 1900.0    # bajada pesada (pegada arcade)
const MAX_FALL := 980.0         # tope de velocidad de caída
```

### 2. Gravedad asimétrica

Sustituye en `_physics_process`:

```gdscript
	if not is_on_floor():
		velocity.y += GRAVITY * delta
```

por:

```gdscript
	if not is_on_floor():
		# gravedad asimétrica: sube frenando suave, cae pesado y con tope
		velocity.y += (GRAVITY_UP if velocity.y < 0.0 else GRAVITY_FALL) * delta
		velocity.y = minf(velocity.y, MAX_FALL)
```

### 3. Salto doble

Sustituye la rama del salto:

```gdscript
		elif hit("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			state = State.JUMP
			_sfx("jump", -16.0)
```

por:

```gdscript
		elif hit("jump") and is_on_floor():
			# salto doble: parado ~1 personaje, con carrerilla el ápice completo
			velocity.y = JUMP_VY_RUN if state == State.RUN else JUMP_VY_STAND
			state = State.JUMP
			_sfx("jump", -16.0)
```

### 4. Actualizar la suite (línea base → valores nuevos)

En `test/suite_movimiento.gd`:

- `salto_parado_apice`: cambia el rango y el comentario marcado `# L43`:

```gdscript
	return runner.check(rise >= 55.0 and rise <= 80.0, "salto parado sube 55-80 px (ahora ~66)")  # L43
```

- `salto_carrerilla_distancia`: el aire se acorta (~0,70 s total), cambia:

```gdscript
	return runner.check(p.is_on_floor() and p.position.x - x0 >= 180.0,
			"salto con carrerilla recorre >=180 px en el aire (ahora ~230)")  # L43
```

### 5. Verificar con las trazas

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/trace_motion.tscn
```

En `trace_motion.csv`:
- `# jump_stand`: `y` mínimo ≈ **465** (531 − 66).
- `# jump_run`: `y` mínimo ≈ **387** (531 − 144).
- En `jump_run`, tras el ápice la velocidad `vy` crece más deprisa que antes
  (1900 de bajada vs 1600 de subida).

### 6. Smoke test

Ejecuta el smoke. Los casos de "alturas" (peldaño, tejado, puente, torre) que
subían con salto PARADO desde el suelo pueden quedarse cortos.

**Contingencia** (solo si un caso falla): elígela en este orden —
1. Si el caso salta desde parado pero el juego real permitiría coger
   carrerilla, cambia el input del caso (mantener `p1_right` antes de
   `p1_jump`).
2. Si es una plataforma del mapa que SOLO se alcanza con salto parado, baja
   esa plataforma en `game.gd` lo mínimo (≤30 px, p. ej. `ROOF_H_Y 406 → 380`)
   y ajusta en el mismo caso el valor esperado de `y` si lo asserta.
3. NUNCA vuelvas a una sola `JUMP_VELOCITY` ni subas `JUMP_VY_STAND` por
   encima de −500: el salto parado corto es la característica.

## Qué NO hacer

- No toques `SPEED`, `DUCK_SPEED` ni las velocidades de dive/rodada/sidekick
  (la 44 se ocupa del arranque horizontal).
- No apliques gravedad asimétrica al DIVE (ya fuerza `velocity.y = 0` cada
  frame; déjalo estar).
- No cambies el smoke salvo lo que exija la contingencia.

## Criterios de aceptación

1. Saltar parado sube poco (~1 personaje): no alcanza un tejado que antes sí.
2. Saltar corriendo mantiene el alcance actual (cruza el foso pequeño igual).
3. La caída es visiblemente más rápida que la subida.
4. `trace_motion.csv` muestra los dos ápices (≈465 y ≈387).
5. Runner `ALL PASSED` y smoke `SMOKE OK`.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/trace_motion.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/test_runner.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Últimas líneas esperadas: `TRAZAS OK - …`, `RESULT: ALL PASSED (10)` y
`SMOKE OK - todas las mecánicas funcionan`.
