# Tarea 69 — Franja de hielo (arena que cambia las reglas)

**Dificultad:** baja · **Archivos:** `scripts/game.gd`, `scripts/player.gd` · **Prerrequisitos:** 44 aplicada (usa su aceleración/fricción)

## Objetivo

Primer hazard "normativo" del original (mapa Winter): una franja de suelo
helado en la que **se acelera igual pero frenar y cambiar de sentido cuesta**
— el duelo se desliza. Sigue el patrón de la hierba alta: constantes en
`game.gd` + consulta desde `player.gd` vía `get_parent()`.

## Contexto del proyecto (leer antes de tocar nada)

- La hierba alta es el patrón a imitar: `const GRASS_X0 := 1150.0` /
  `GRASS_X1` en `game.gd` (~línea 40) y `func in_grass(x: float) -> bool`
  (~línea 210); `player.gd` la consulta con
  `g != null and g.has_method("in_grass")`.
- La aceleración de la 44 vive en el `match state` de `player.gd`, rama
  `State.IDLE, State.RUN:` — hoy: `if push_time > 0.0: velocity.x = push_vel.x`
  y si no `var rate := GROUND_ACCEL if dir != 0.0 else GROUND_FRICTION` +
  `velocity.x = move_toward(velocity.x, dir * sp, rate * delta)`.
- Zona libre de interferencias (sin foso, sin hierba, bajo el puente alto):
  **x 1700–2000** (la hierba acaba en 1450, el foso empieza en 2210, el
  puente está arriba en y=288). Los tests operan en 1500–1800 y 4400: la
  franja está a >145 px del caso 1 y del runner (1600 + ~145 px de avance
  rozan el borde por debajo del umbral: el runner suelta la dirección antes
  de frenar dentro de la franja y su umbral es `>= 130`, con margen).
- El suelo se dibuja con `_tiled_rect(TEX_FLOOR, ...)` en `_floor_segment`
  (tarea 57): la franja visual va ENCIMA como poly translúcido azulado.
- Reglas de estilo: GDScript tipado, tabs, español.

## Instrucciones paso a paso

### 1. Constantes y consulta en `game.gd`

Junto a `GRASS_X0/GRASS_X1`:

```gdscript
const ICE_X0 := 1700.0   # franja de hielo (Winter): frena mal
const ICE_X1 := 2000.0
```

Junto a `func in_grass`:

```gdscript
func in_ice(x: float) -> bool:
	return x > ICE_X0 and x < ICE_X1
```

### 2. Física resbaladiza en `player.gd`

En la rama `State.IDLE, State.RUN:` del segundo `match`, sustituye las dos
líneas del `rate`:

```gdscript
				var rate := GROUND_ACCEL if dir != 0.0 else GROUND_FRICTION
				velocity.x = move_toward(velocity.x, dir * sp, rate * delta)
```

por:

```gdscript
				var rate := GROUND_ACCEL if dir != 0.0 else GROUND_FRICTION
				var g := get_parent()
				if g != null and g.has_method("in_ice") and g.in_ice(global_position.x) and is_on_floor():
					# hielo: aceleración mermada y frenado casi nulo
					rate = 700.0 if dir != 0.0 else 380.0
				velocity.x = move_toward(velocity.x, dir * sp, rate * delta)
```

### 3. Visual de la franja en `_build_level`

Tras el bloque de la hierba alta (las briznas), añade:

```gdscript
	# franja de hielo: tinte azulado brillante sobre los tiles
	var ice := _poly(PackedVector2Array([Vector2(ICE_X0, GROUND_Y), Vector2(ICE_X1, GROUND_Y), Vector2(ICE_X1, GROUND_Y - 5.0), Vector2(ICE_X0, GROUND_Y - 5.0)]), Color(0.62, 0.78, 0.95, 0.45), -3)
	ice.z_index = 2
```

## Qué NO hacer

- No pongas la franja sobre la hierba, los fosos o las metas (rompería los
  tests de estancia oculta y de meta).
- No toques la fricción GLOBAL (`GROUND_FRICTION`) ni la del aire: solo la
  franja.
- No apliques el hielo en el aire ni durante `push_time` (la parada debe
  seguir separando limpio).

## Criterios de aceptación

1. Correr sobre la franja cuesta arrancar y SOLTAR no te frena: te deslizas
   ~1 pantalla antes de parar; el giro de sentido es lento.
2. Fuera de la franja todo se siente igual (misma constantes).
3. Se ve el brillo azulado sobre las tiles del suelo.
4. `SMOKE OK`, `ALL PASSED (12)` y `SIM PASS` (los bots la cruzan corriendo:
   330 px/s de crucero superan el deslizamiento).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/sim_match.tscn
```

Últimas líneas esperadas: `SMOKE OK - todas las mecánicas funcionan` y
`SIM PASS`.
