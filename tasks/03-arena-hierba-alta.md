# Tarea 03 — Hierba alta que oculta la estancia

**Dificultad:** baja · **Archivos:** `scripts/game.gd`, `scripts/player.gd` · **Prerrequisitos:** ninguno

## Objetivo

Añadir una zona de hierba alta (entre x=1150 y x=1450) donde la espada del duelist
que esté dentro **no se dibuja**: el rival no puede ver tu estancia (alta/media/baja)
hasta que sales. Es el "juego mental" clásico de Nidhogg en la hierba.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg para 2 jugadores
  en un mismo teclado. Todo el arte es procedural (`_draw()`, `Polygon2D`) y los
  sonidos se generan por código: **no hay assets externos ni plugins**.
- Archivos:
	- `scripts/game.gd` — nodo principal: nivel, cámara, HUD y resolución de combate.
	  Constantes de nivel: `LEVEL_W=4800`, `GROUND_Y=560`, foso central
	  `PIT_X0=2210`/`PIT_X1=2380`, plataforma `PLAT_X0=2130`/`PLAT_X1=2460`/`PLAT_Y=448`.
	  El nivel se construye en `_build_level()`; los polígonos decorativos se crean con
	  `_poly(points, color, z_index)`. Los jugadores están en `GROUND_Y - 29` (y=531).
	- `scripts/player.gd` — `class_name Player` (CharacterBody2D). Se dibuja entero en
	  `_draw()`; la espada se dibuja dentro del bloque `if has_sword:` cerca del final.
	- `test/smoke_test.gd` — prueba headless. Coloca a los jugadores en x≈1600–1800,
	  FUERA de la zona de hierba: no debe verse afectada.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. `scripts/game.gd` — constantes y dibujo de la hierba

1.1. Junto a las demás constantes de nivel (después de `const PLAT_Y := 448.0`),
añade:

```gdscript
const GRASS_X0 := 1150.0
const GRASS_X1 := 1450.0
```

1.2. En `_build_level()`, después de la línea `_platform(PLAT_X0, PLAT_X1, PLAT_Y)`,
añade:

```gdscript
	# hierba alta: oculta la estancia de quien entra
	_poly(PackedVector2Array([Vector2(GRASS_X0, GROUND_Y), Vector2(GRASS_X1, GROUND_Y), Vector2(GRASS_X1, GROUND_Y - 34.0), Vector2(GRASS_X0, GROUND_Y - 34.0)]), Color(0.09, 0.18, 0.11), 2)
	for i in 22:
		var gx := GRASS_X0 + (GRASS_X1 - GRASS_X0) * (float(i) + 0.5) / 22.0
		var gh := 44.0 + 20.0 * randf()
		_poly(PackedVector2Array([Vector2(gx - 7, GROUND_Y), Vector2(gx + 7, GROUND_Y), Vector2(gx + randf_range(-7.0, 7.0), GROUND_Y - gh)]), Color(0.13, 0.30, 0.17).lightened(0.08 * randf()), 3)
```

(El `z_index` 3 dibuja la hierba POR ENCIMA de los jugadores, que están a z=0.)

1.3. Añade esta función pública en `game.gd` (junto a `sfx()` está bien):

```gdscript
func in_grass(x: float) -> bool:
	return x > GRASS_X0 and x < GRASS_X1
```

### 2. `scripts/player.gd` — no dibujar la espada dentro de la hierba

En `_draw()`, el bloque que dibuja la espada empieza con `if has_sword:`.
Sustituye esa línea por:

```gdscript
	var g := get_parent()
	var hide_sword: bool = g != null and g.has_method("in_grass") and g.in_grass(global_position.x)
	if has_sword and not hide_sword:
```

El resto del bloque se queda igual (solo cambia la condición de entrada).

## Qué NO hacer

- No ocultes el cuerpo del duelist ni su color: SOLO la espada.
- No cambies la lógica de combate: dentro de la hierba los ataques, choques y
  muertes se resuelven exactamente igual; esto es puramente visual.
- No sitúes la hierba entre x=1550 y x=2050 (el smoke test usa esa franja).

## Criterios de aceptación

1. Se ve una franja de hierba verde de ~300 px entre los dos pilares de la izquierda.
2. Al entrar en la hierba, la espada de tu duelist desaparece (no se ve si está
   en alta, media o baja); el cuerpo sigue visible.
3. Al salir, la espada vuelve a dibujarse.
4. Un ataque lanzado desde dentro de la hierba golpea con normalidad.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`
(la hierba se comprueba visualmente abriendo el juego con F5).
