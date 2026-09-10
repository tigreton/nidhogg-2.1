# Tarea 05 — Segundo foso sin plataforma

**Dificultad:** media · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** ninguno

## Objetivo

Abrir un segundo foso mortal en x=700–880, esta vez **sin plataforma**: hay que
saltarlo de un salto (180 px de ancho; un salto con carrera cubre ~270 px).
Aparecen así dos ritmos de cruce: el foso central con plataforma y este, seco.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural y sonidos por código: **sin assets externos**.
- `scripts/game.gd`:
	- Constantes: `LEVEL_W=4800`, `GROUND_Y=560`, foso central `PIT_X0=2210`,
	  `PIT_X1=2380`. La muerte por caída ya existe: en `_physics_process`, todo
	  jugador con `position.y > 820` muere (`_kill`).
	- `_build_level()` llama ahora a `_floor_segment(0.0, PIT_X0)` y
	  `_floor_segment(PIT_X1, LEVEL_W)`. `_floor_segment(x0, x1)` crea suelo
	  sólido + dibujo entre esas x.
	- El dibujo del hueco del foso central es el `_poly(...)` rojo oscuro
	  `Color(0.30, 0.07, 0.09)` con z_index -6 que hay justo después de los
	  `_floor_segment`.
	- `_drop_sword(pos, col)` descarta la espada si cae sobre el foso central
	  (`if x > PIT_X0 and x < PIT_X1: return`).
	- `_respawn_pos(p)` empuja la reaparición fuera del foso central
	  (`if x > PIT_X0 - 50.0 and x < PIT_X1 + 50.0:`).
- El smoke test trabaja en x≈1600–4800: el nuevo foso (700–880) no lo pisa.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Constantes

En `scripts/game.gd`, junto a `const PIT_X1 := 2380.0`, añade:

```gdscript
const PIT2_X0 := 700.0
const PIT2_X1 := 880.0
```

### 2. Suelo con dos huecos

En `_build_level()`, sustituye la línea `_floor_segment(0.0, PIT_X0)` por:

```gdscript
	_floor_segment(0.0, PIT2_X0)
	_floor_segment(PIT2_X1, PIT_X0)
```

### 3. Dibujo del hueco

Justo después del `_poly` rojo del foso central (mismo bloque), añade su gemelo:

```gdscript
	_poly(PackedVector2Array([Vector2(PIT2_X0, GROUND_Y + 4), Vector2(PIT2_X1, GROUND_Y + 4), Vector2(PIT2_X1 - 26, 800.0), Vector2(PIT2_X0 + 26, 800.0)]), Color(0.30, 0.07, 0.09), -6)
```

### 4. Helper común de fosos

Añade esta función a `game.gd` (si ya existe una igual por otra tarea, no la
duples; asegúrate de que incluya los DOS fosos):

```gdscript
func _in_any_pit(x: float) -> bool:
	return (x > PIT_X0 and x < PIT_X1) or (x > PIT2_X0 and x < PIT2_X1)
```

### 5. Usar el helper en los tres sitios que conocen el foso

5.1. En `_drop_sword()`, sustituye `if x > PIT_X0 and x < PIT_X1:` por `if _in_any_pit(x):`.

5.2. En `_respawn_pos()`, sustituye el bloque:

```gdscript
	if x > PIT_X0 - 50.0 and x < PIT_X1 + 50.0:
		x = PIT_X1 + 70.0 if dir > 0.0 else PIT_X0 - 70.0
```

por:

```gdscript
	if x > PIT_X0 - 50.0 and x < PIT_X1 + 50.0:
		x = PIT_X1 + 70.0 if dir > 0.0 else PIT_X0 - 70.0
	elif x > PIT2_X0 - 50.0 and x < PIT2_X1 + 50.0:
		x = PIT2_X1 + 70.0 if dir > 0.0 else PIT2_X0 - 70.0
```

5.3. En `_surface_y(x, from_y)` no hay cambio: la plataforma sigue siendo solo la
del foso central.

## Qué NO hacer

- No pongas plataforma sobre el foso nuevo: la gracia es saltarlo.
- No lo hagas más ancho de 200 px (con 180 px se salta con margen; con más, un
  jugador cuidado no puede cruzar corriendo).
- No toques la lógica de muerte por caída (ya es global).

## Criterios de aceptación

1. Se ve el segundo hueco rojo oscuro en x=700–880 y caer en él mata.
2. Cruzarlo de un salto con carrera es factible y cómodo.
3. Una espada desviada encima de ese foso no desaparece dentro: se descarta
   (igual que en el central; el fix del borde es otra tarea).
4. Nadie reaparece dentro del foso nuevo.
5. El smoke test sigue pasando.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`
(el cruce y la muerte se prueban a mano con F5).
