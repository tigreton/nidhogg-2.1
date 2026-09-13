# Tarea 40 — Tercera arena: "Cripta del Ocaso"

**Dificultad:** media · **Archivos:** `scripts/game.gd`, `test/smoke_test.gd` · **Prerrequisitos:** ninguno

## Objetivo

Tercera arena para el selector (tecla C): **CRIPTA DEL OCASO**, atardecer
púrpura con luna moribunda, torre junto a la meta izquierda, casa junto a la
derecha, velas fantasmales (llama verde) y lápidas decorativas. El patrón de
arena ya existe: solo se añade la variante de paleta + anclajes + decoración.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript), arte y sonido procedurales, indentación con
  **tabs**, comentarios en español.
- `scripts/game.gd`:
	- `const ARENA_NAMES := ["RUINAS DE MEDIANOCHE", "TEMPLO DEL ALBA"]`
	  (línea 43). El selector C hace `set_arena(arena_id + 1)` y
	  `_load_arena(id)` hace `arena_id = id % ARENA_NAMES.size()`: añadir el
	  nombre basta para que la rotación incluya la tercera.
	- `func _load_arena(id: int) -> void:` es un `match arena_id:` con caso
	  `1:` (Templo del Alba) y caso `_:` (Ruinas de Medianoche, los valores
	  por defecto). Cada caso fija anclajes (PIT2_X0/X1, HOUSE_X, TOWER_X0/X1,
	  BOULDER_X0/X1, STEP_*, FENCE_*) y paleta (col_sky, col_floor, cel_pos...).
	  Al final del método se recalculan los tejados a partir de HOUSE_X.
	- `func _build_level() -> void:` construye TODO el nivel con helpers
	  (`_poly`, `_static_box`, `_platform`, `_rock_step`, `_house`,
	  `_rocks_zone`, `_torch_at`, `_fence`...) y termina con
	  `_fence(FENCE_X0, FENCE_X1)`.
	- Hay clases internas con animación (mira `class Torch extends Node2D:`
	  con `_process`/`_draw` y `t` parpadeante: es el molde para las velas).
	- `_add_level(node)` cuelga nodos del nivel; `GROUND_Y := 560.0`.
	- `set_arena(id)` reconstruye `level_root` (los nodos de decoración se
	  limpian solos) y reinicia el partido.
- El smoke test ya comprueba las arenas 0 y 1 (sección 16) y termina en
  `game.set_arena(0)`; se añade una sección nueva antes de `print("")`.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Nombre de la arena

Sustituye la línea del `const ARENA_NAMES` por:

```gdscript
const ARENA_NAMES := ["RUINAS DE MEDIANOCHE", "TEMPLO DEL ALBA", "CRIPTA DEL OCASO"]
```

### 2. Paleta y anclajes en `_load_arena`

En el `match arena_id:` de `_load_arena`, ANTES del caso `_:`, añade el caso
nuevo (los tejados se derivan solos de HOUSE_X al final del método):

```gdscript
		2:
			# Cripta del ocaso: atardecer púrpura, torre a la izquierda,
			# casa a la derecha y foso pequeño junto a la meta de P1
			PIT_X0 = 2210.0
			PIT_X1 = 2380.0
			PIT2_X0 = 3620.0
			PIT2_X1 = 3800.0
			PLAT_X0 = 2130.0
			PLAT_X1 = 2460.0
			PLAT_Y = 448.0
			BRIDGE_X0 = 1900.0
			BRIDGE_X1 = 2690.0
			BRIDGE_Y = 288.0
			HOUSE_X = 3850.0
			STEP_R_X0 = 1550.0
			STEP_R_X1 = 1642.0
			STEP_R_Y = 516.0
			BOULDER_X0 = 3050.0
			BOULDER_X1 = 3278.0
			BOULDER_Y = 440.0
			TOWER_X0 = 380.0
			TOWER_X1 = 548.0
			TOWER_Y = 330.0
			STEP_L_X0 = 4180.0
			STEP_L_X1 = 4272.0
			STEP_L_Y = 516.0
			FENCE_X0 = 940.0
			FENCE_X1 = 1030.0
			col_sky = Color(0.10, 0.06, 0.13)
			col_hill_far = Color(0.14, 0.08, 0.16)
			col_hill_near = Color(0.11, 0.07, 0.13)
			col_pillar = Color(0.13, 0.10, 0.15)
			col_pillar_cap = Color(0.17, 0.13, 0.19)
			col_pit = Color(0.16, 0.05, 0.14)
			col_floor = Color(0.16, 0.13, 0.18)
			col_floor_top = Color(0.34, 0.28, 0.38)
			col_plat = Color(0.22, 0.18, 0.26)
			col_plat_top = Color(0.38, 0.32, 0.44)
			col_wall = Color(0.15, 0.11, 0.17)
			cel_pos = Vector2(1200.0, 130.0)
			cel_col = Color(0.75, 0.45, 0.30)
			cel_detail = Color(0.66, 0.38, 0.26)
```

### 3. Clase interna Candle y decoración

3.1. Junto a `class Torch ...`, añade:

```gdscript
class Candle extends Node2D:
	## Vela fantasmal de la cripta: llama verde parpadeante.
	var t := 0.0

	func _ready() -> void:
		t = randf() * 10.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		draw_line(Vector2(0, 0), Vector2(0, -26.0), Color(0.75, 0.72, 0.6), 8.0)
		var f := 1.0 + 0.2 * sin(t * 9.0)
		draw_circle(Vector2(0, -32.0), 18.0 * f, Color(0.4, 0.9, 0.55, 0.10))
		draw_colored_polygon(PackedVector2Array([Vector2(-4, -28), Vector2(0, -28.0 - 14.0 * f), Vector2(4, -28)]), Color(0.55, 0.95, 0.65, 0.95))
```

3.2. Debajo de `_fence`, añade:

```gdscript
func _candles() -> void:
	for cx in [HOUSE_X + 260.0, 1420.0, 2500.0, 4050.0]:
		var c := Candle.new()
		c.position = Vector2(cx, GROUND_Y)
		c.z_index = 1
		_add_level(c)


func _tombstones() -> void:
	for tx in [300.0, 1180.0, 2450.0, 4320.0]:
		_poly(PackedVector2Array([Vector2(tx - 16, GROUND_Y), Vector2(tx + 16, GROUND_Y), Vector2(tx + 14, GROUND_Y - 44.0), Vector2(tx, GROUND_Y - 54.0), Vector2(tx - 14, GROUND_Y - 44.0)]), Color(0.24, 0.22, 0.28), -3)
```

3.3. En `_build_level()`, después de la línea `_fence(FENCE_X0, FENCE_X1)`,
añade:

```gdscript
	if arena_id == 2:
		_candles()
		_tombstones()
```

### 4. Smoke test: sección nueva

En `test/smoke_test.gd`, busca la línea `print("")` e inserta ANTES:

```gdscript
	# 32. Tercera arena: Cripta del Ocaso
	game.set_arena(2)
	_check(game.arena_id == 2 and game.ARENA_NAMES[2] == "CRIPTA DEL OCASO", "Arena 3: nombre y selector")
	_check(game.PIT2_X0 == 3620.0, "Arena 3: foso pequeño a la derecha")
	p1.position = Vector2(460.0, 296.0)
	p1.velocity = Vector2.ZERO
	await get_tree().create_timer(0.4).timeout
	_check(p1.is_on_floor() and absf(p1.position.y - 301.0) < 6.0, "Arena 3: la torre izquierda es subible")
	game.set_arena(0)
	_check(game.arena_id == 0 and game.PIT2_X0 == 700.0, "Vuelta a Ruinas de Medianoche")
```

## Qué NO hacer

- No cambies los casos `1:` ni `_:` de `_load_arena` (las arenas existentes
  y el smoke test de la sección 16 dependen de ellos).
- No toques `_build_level()` fuera del `if arena_id == 2:` final: la
  decoración solo existe en la cripta.
- No añadas fosos nuevos ni muevas el foso central: la reaparición, la cámara
  y el bot asumen PIT 2210–2380 y puente 1900–2690.
- No uses assets: velas y lápidas son polígonos y líneas.

## Criterios de aceptación

1. La tecla C rota ahora entre tres arenas; la tercera se llama "CRIPTA DEL
   OCASO" y tiene cielo púrpura con luna naranja baja.
2. En la cripta hay velas con llama verde parpadeante y lápidas decorativas.
3. La torre de la izquierda (junto a la meta de P2) es subible y la casa está
   junto a la meta derecha; el foso pequeño está a la derecha (3620–3800).
4. El cambio de arena reinicia el partido como con las otras dos arenas.
5. El smoke test pasa, incluida la sección 32 nueva.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
