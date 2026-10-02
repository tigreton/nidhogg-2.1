# Tarea 44 — Aceleración y fricción de suelo (arranque en rampa)

**Dificultad:** media · **Archivos:** `scripts/player.gd`, `test/suite_movimiento.gd`, quizá `test/smoke_test.gd` (caso 1) · **Prerrequisitos:** 43 aplicada (misma zona de constantes)

## Objetivo

Calibración portada del proyecto hermano: la velocidad horizontal ya no es
instantánea — se acelera hacia la velocidad objetivo en ~6 frames, se frena en
~4 y el control aéreo es parcial. Da inercia arcade a la carrera sin tocar la
velocidad máxima (330) ni los estados que fijan su propia velocidad (rodada,
dive, sidekick, estocada).

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/player.gd` — en el SEGUNDO `match state:` de `_physics_process`
  (el que fija velocidad) hay tres casos a tocar:
	- `State.IDLE, State.RUN:` → hoy `velocity.x = dir * sp` (instantáneo).
	- `State.JUMP:` → hoy `move_toward(velocity.x, dir * SPEED, 1100.0 * delta)`.
	- Los casos `ROLL`, `DIVE`, `SIDEKICK` y `ATTACK` (estocada) fijan su
	  velocidad propia: NO los toques.
- El `dir` se calcula justo antes (`held("right") - held("left")`, y fija
  `facing` si es distinto de 0).
- La tarea 43 ya sustituyó `JUMP_VELOCITY`/`GRAVITY` por las constantes
  dobles; esta tarea NO toca la vertical.
- El bot necesita `absf(velocity.x) > 120` para el dive: con 2800 px/s² los
  alcanza en ~3 frames desde parado (sin impacto real).
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en
  español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Constantes nuevas

En `player.gd`, junto a las demás constantes de movimiento (tras
`JUMP_VY_STAND`…`MAX_FALL` de la tarea 43), añade:

```gdscript
const GROUND_ACCEL := 2800.0    # 0 → 330 px/s en ~6 frames
const GROUND_FRICTION := 5200.0 # frenado en ~4 frames
const AIR_ACCEL := 1500.0       # control aéreo parcial hacia la carrera
```

### 2. Caso IDLE/RUN con rampa

Sustituye:

```gdscript
		State.IDLE, State.RUN:
			var sp := DUCK_SPEED if stance == H.LOW else SPEED * (UNARMED_SPEED_MULT if not has_sword else run_mult())
			velocity.x = dir * sp
			state = State.RUN if absf(velocity.x) > 5.0 else State.IDLE
			run_phase += velocity.x * delta * 0.045
```

por:

```gdscript
		State.IDLE, State.RUN:
			var sp := DUCK_SPEED if stance == H.LOW else SPEED * (UNARMED_SPEED_MULT if not has_sword else run_mult())
			# arranque en rampa: acelerar cuesta ~6 frames, frenar ~4
			var rate := GROUND_ACCEL if dir != 0.0 else GROUND_FRICTION
			velocity.x = move_toward(velocity.x, dir * sp, rate * delta)
			state = State.RUN if absf(velocity.x) > 5.0 else State.IDLE
			run_phase += velocity.x * delta * 0.045
```

### 3. Caso JUMP con control parcial

Sustituye:

```gdscript
		State.JUMP:
			velocity.x = move_toward(velocity.x, dir * SPEED, 1100.0 * delta)
```

por:

```gdscript
		State.JUMP:
			velocity.x = move_toward(velocity.x, dir * SPEED, AIR_ACCEL * delta)
```

### 4. Actualizar la suite

En `test/suite_movimiento.gd`, `correr_30_frames` (marcado `# L44`): con la
rampa, 30 frames + 5 de frenado recorren ~145 px:

```gdscript
	return runner.check(dx >= 130.0, "correr recorre >=130 px en 35 frames con aceleración (hoy ~145)")  # L44
```

### 5. Smoke test

Ejecuta el smoke. Los casos de distancia/tiempo pueden quedarse justos:

- Caso 1 ("P1 se mueve a la derecha"): 0,25 s pulsado → ahora recorre ~73 px;
  el umbral es `> x0 + 60.0` y sigue pasando. Si por timing falla, baja ese
  umbral a `50.0` (es lo esperado con aceleración, no un bug).
- Casos de correr hasta una meta o cruzar una reja con espera justa: si
  fallan por milésimas, añade `+0.2` a la espera de ese caso, nada más.

## Qué NO hacer

- No toques `ROLL`, `DIVE`, `SIDEKICK` ni el `ATTACK` de la estocada: fijan
  velocidad propia a propósito.
- No cambies `SPEED`, `DUCK_SPEED` ni `run_mult`.
- No subas `GROUND_FRICTION` por encima de 6000: frenar en seco del todo es
  justo lo que esta tarea quita.

## Criterios de aceptación

1. Arrancar a correr se nota con inercia (~0,1 s hasta velocidad plena);
   soltar la dirección frena en ~4 frames, no al instante.
2. La estocada, rodada, dive y sidekick conservan su velocidad plena
   inmediata.
3. En el aire se corrige la trayectoria, pero menos que en el suelo.
4. Runner `ALL PASSED` y smoke `SMOKE OK`.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/trace_motion.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/test_runner.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Últimas líneas esperadas: `TRAZAS OK - …`, `RESULT: ALL PASSED (10)` y
`SMOKE OK - todas las mecánicas funcionan`. En `trace_motion.csv` la fase
`# run` debe mostrar `vx` creciendo de 0 a 330 en ~6 filas.
