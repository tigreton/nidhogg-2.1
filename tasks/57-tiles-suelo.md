# Tarea 57 — Suelos y muros con tiles + bordes de foso

**Dificultad:** media · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** que existan `tile_floor/tile_wall/pit_edge.png` (ya importados)

## Objetivo

Los segmentos de suelo, plataformas y muros dejan de ser polígonos de color
plano y pasan a rellenarse con las texturas tileables de 48×48
(`tile_floor.png`, `tile_wall.png`), teñidas con la paleta de cada arena. Los
bordes de los fosos reciben el remate decorativo `pit_edge.png`. Las
colisiones no cambian en absoluto.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript), monolito `scripts/game.gd`, 3 arenas que
  solo cambian paleta de `Color` en `_load_arena()` (~línea 332):
  `col_floor`, `col_floor_top`, `col_plat`, `col_plat_top`, `col_wall`.
- Constructores actuales (todos combinan `_static_box` para la colisión con
  uno o dos `_poly` para el dibujo):
  - `_floor_segment(x0, x1)` (~línea 956): caja + cuerpo 140 px alto + franja
    superior de 6 px.
  - `_platform(x0, x1, y)` (~línea 962): caja 16 px + franja de 5 px.
  - `_wall(x0, x1)` (~línea 969): caja de altura completa + polígono.
- Los fosos son dos por arena (`PIT_X0/X1`, `PIT2_X0/X1`); en
  `_build_level()` (~líneas 298-299) se pintan como trapecios `col_pit`.
- Helper disponible: `_add_level(nodo)` engancha al escenario y lo libera al
  cambiar de arena (tecla C → `set_arena`, que vacía `level_root`).
- En Godot 4, un `Sprite2D` con `region_enabled`, `region_rect` mayor que la
  textura y `texture_repeat = TEXTURE_REPEAT_ENABLED` repite la textura hasta
  cubrir la región: es la forma estándar de "azujelear" un tile.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en
  español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Texturas y helper

Junto a las constantes de color de `game.gd` añade:

```gdscript
const TEX_FLOOR := preload("res://art/sprites/tile_floor.png")
const TEX_WALL := preload("res://art/sprites/tile_wall.png")
const TEX_PIT_EDGE := preload("res://art/sprites/pit_edge.png")
```

Y junto a `_floor_segment` añade el helper:

```gdscript
func _tiled_rect(tex: Texture2D, rect: Rect2, col: Color, z: int) -> void:
	# sprite con repetición de textura: pinta rect rellenándolo con tiles
	var sp := Sprite2D.new()
	sp.texture = tex
	sp.centered = false
	sp.position = rect.position
	sp.region_enabled = true
	sp.region_rect = Rect2(0.0, 0.0, rect.size.x, rect.size.y)
	sp.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sp.modulate = col
	sp.z_index = z
	_add_level(sp)
```

### 2. Suelo y plataformas

`_floor_segment` queda así (la caja de colisión no se toca; los dos `_poly`
se sustituyen):

```gdscript
func _floor_segment(x0: float, x1: float) -> void:
	_static_box(x0, GROUND_Y, x1, GROUND_Y + 140.0)
	_tiled_rect(TEX_FLOOR, Rect2(x0, GROUND_Y, x1 - x0, 140.0), col_floor, -4)
	_tiled_rect(TEX_FLOOR, Rect2(x0, GROUND_Y, x1 - x0, 6.0), col_floor_top, -4)
```

`_platform` igual (franja superior de 5 px con `col_plat_top`):

```gdscript
func _platform(x0: float, x1: float, y: float) -> void:
	_static_box(x0, y, x1, y + 16.0)
	_register_top(x0, x1, y)
	_tiled_rect(TEX_FLOOR, Rect2(x0, y, x1 - x0, 16.0), col_plat, -4)
	_tiled_rect(TEX_FLOOR, Rect2(x0, y, x1 - x0, 5.0), col_plat_top, -4)
```

(La región de 6/5 px de alto muestra solo la fila superior del tile: funciona
como la franja clara de antes.)

### 3. Muros

```gdscript
func _wall(x0: float, x1: float) -> void:
	_static_box(x0, 0.0, x1, GROUND_Y + 140.0)
	_tiled_rect(TEX_WALL, Rect2(x0, 0.0, x1 - x0, GROUND_Y + 140.0), col_wall, -4)
```

### 4. Bordes de foso

En `_build_level()`, justo después de los dos `_poly` de los fosos
(~líneas 298-299), añade:

```gdscript
	_pit_edges(PIT_X0, PIT_X1)
	_pit_edges(PIT2_X0, PIT2_X1)
```

Y la función junto a los otros constructores:

```gdscript
func _pit_edges(x0: float, x1: float) -> void:
	# remate decorativo en los dos bordes de cada foso
	for side in [x0, x1]:
		var e := Sprite2D.new()
		e.texture = TEX_PIT_EDGE
		e.position = Vector2(side, GROUND_Y - 23.0)
		e.flip_h = side == x1
		e.z_index = -5
		_add_level(e)
```

## Qué NO hacer

- No toques `_static_box`, `_register_top` ni ninguna colisión: el gameplay
  debe quedar idéntico.
- No cambies los trapecios del interior del foso (`col_pit`): solo se
  rematan los bordes.
- No pintes los techos/torres/casa con tiles: eso sigue procedural (no hay
  asset).
- No hardcodees colores: usa siempre `col_*` de la arena para el `modulate`,
  así la tecla C re-tiñe todo al reconstruir.

## Criterios de aceptación

1. Los suelos, plataformas y muros muestran la textura del tile repetida,
   teñida con la paleta de la arena activa.
2. Al pulsar C (cambiar arena) el tinte cambia con la paleta, sin fugas de
   nodos (el `set_arena` sigue liberando el escenario).
3. Los cuatro bordes de los fosos muestran el remate `pit_edge` (los del
   lado derecho volteados).
4. Nadie se cae por ningún sitio nuevo y el smoke test termina en
   `SMOKE OK` (las colisiones no cambiaron).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
Y una pasada con render recorriendo el nivel y cambiando de arena con C.
