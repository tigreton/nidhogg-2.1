# Tarea 71 — Cinta transportadora (suelo que empuja)

**Dificultad:**: media · **Archivos:** `scripts/game.gd`, `scripts/player.gd` · **Prerrequisitos:** 44 aplicada

## Objetivo

Hazard del original (Volcano/Airship): un tramo de suelo que **empuja
horizontalmente** (aquí hacia la izquierda, en contra de la carrera de P1):
pararse es derivar, y correr a contracorriente cuesta lo que la cinta da.
Franja elegida: **x 2500–2650** (suelo llano bajo el puente alto, lejos de
los tests que operan en 1500–1800 y 4400).

## Contexto del proyecto (leer antes de tocar nada)

- Patrón de zona: `GRASS_X0/X1` + `in_grass(x)` en `game.gd`, consultada
  desde `player.gd` vía `get_parent()` (copia exacta del patrón de la
  tarea 69, que puede estar o no aplicada: son independientes).
- `player.gd::_physics_process` termina el movimiento con `move_and_slide()`
  (línea ~292, dentro del segundo `match`); el empuje va DESPUÉS, sumando a
  la posición, para que no interactúe con la fricción de la 44.
- El suelo visible lo pintan tiles (`_tiled_rect`, tarea 57); las flechas de
  la cinta son un poly animado encima (z 2, como la franja de hielo si
  existiera).
- `grounded`-check: solo empuja si `p.is_on_floor()`.
- Reglas de estilo: GDScript tipado, tabs, español.

## Instrucciones paso a paso

### 1. Constantes y consulta en `game.gd`

Junto a `GRASS_X0`:

```gdscript
const BELT_X0 := 2500.0   # cinta transportadora (Volcano): empuja a la izquierda
const BELT_X1 := 2650.0
const BELT_V := -120.0
```

Junto a `in_grass`:

```gdscript
func in_belt(x: float) -> bool:
	return x > BELT_X0 and x < BELT_X1


func belt_velocity() -> float:
	return BELT_V
```

### 2. Empuje en `player.gd`

Inmediatamente después de `move_and_slide()` (misma indentación de método):

```gdscript
	move_and_slide()

	# cinta transportadora: deriva horizontal sobre el suelo de la franja
	if is_on_floor():
		var gb := get_parent()
		if gb != null and gb.has_method("belt_velocity") and gb.in_belt(global_position.x):
			position.x += gb.belt_velocity() * delta
```

### 3. Visual animado en `game.gd`

Variable junto a `var level_root: Node2D`... (usa la que ya exista para el
nivel) y añade a `_build_level()`, tras el bloque de la hierba:

```gdscript
	# cinta: base más oscura + flechas desplazándose
	_poly(PackedVector2Array([Vector2(BELT_X0, GROUND_Y), Vector2(BELT_X1, GROUND_Y), Vector2(BELT_X1, GROUND_Y - 4.0), Vector2(BELT_X0, GROUND_Y - 4.0)]), Color(0.1, 0.09, 0.14, 0.85), 2)
	for k in 4:
		var bx := BELT_X0 + 40.0 + k * 40.0
		_belt_arrows.append(_poly(PackedVector2Array([Vector2(bx, GROUND_Y - 10.0), Vector2(bx + 16.0, GROUND_Y - 10.0), Vector2(bx + 16.0, GROUND_Y - 14.0), Vector2(bx + 26.0, GROUND_Y - 8.0), Vector2(bx + 16.0, GROUND_Y - 2.0), Vector2(bx + 16.0, GROUND_Y - 6.0), Vector2(bx, GROUND_Y - 6.0)]), Color(0.42, 0.4, 0.5), 3))
```

Con la variable `var _belt_arrows: Array[Polygon2D] = []` junto a las demás
de decorado, y animación en `_process` (el juego ya tiene `_process` con
parpadeo ambiental: añade al final de ese `_process`):

```gdscript
	for a in _belt_arrows:
		a.position.x -= 60.0 * _delta_si_existe
```

> Si `_process` no recibe delta con ese nombre, usa su parámetro real
> (`_delta`, `delta`...). Las flechas derivan a la izquierda en bucle:
> cuando `a.position.x < BELT_X0 - 30.0`, suma `150.0` para reciclarlas.

## Qué NO hacer

- No pongas la cinta en la zona de los tests (1500–1800), en la hierba, los
  fosos ni las metas.
- No apliques el empuje en el aire ni a cadáveres/proyectiles: solo jugadores
  en pie.
- No anules la velocidad del jugador: se SUMA a su movimiento (contracorriente
  330−120=210 px/s efectivos; a favor, 450).

## Criterios de aceptación

1. Parado sobre la cinta derivas a la izquierda (~2 personajes por segundo).
2. Correr hacia la derecha en la cinta es más lento; hacia la izquierda,
   más rápido.
3. Las flechas del suelo se mueven en la dirección del empuje.
4. `SMOKE OK`, `ALL PASSED (12)` y `SIM PASS` (los bots la cruzan: 210 px/s
   netos siguen siendo avance).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/sim_match.tscn
```

Últimas líneas esperadas: `SMOKE OK - todas las mecánicas funcionan` y
`SIM PASS`.
