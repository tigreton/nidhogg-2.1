# Tarea 55 — HUD con sprites: pips, flecha de meta y salpicaduras de sangre

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** que existan `pip_filled/pip_hollow/arrow_neutral/blood_0/1/2.png` (ya importados)

## Objetivo

Tres elementos del HUD/presentación dejan de dibujarse con primitivas y pasan
a sprites reales: los cuadros de progreso de secciones (`Pip`), la flecha
indicadora de la zona de meta (`_goal_zone`) y la sangre (salpicadura
texturizada sobre el charco procedural de `BloodPool`).

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript), monolito `scripts/game.gd`.
- Clase `Pip` (~línea 716): hoy dos `draw_rect` (marco 32×20 y relleno).
  `_update_pips()` (~línea 1441) le pasa `fill_col`/`edge_col` con los colores
  de equipo (`P1_COLOR`/`P2_COLOR`). Los sprites `pip_filled/pip_hollow.png`
  miden **26×26** y son aptos para teñir.
- `_goal_zone(x0, x1, col)` (~línea 974): pinta la zona translúcida, un poste
  y un **triángulo** (flecha) con `_poly`, como última línea de la función.
  `arrow_neutral.png` mide **64×42** y apunta a la derecha.
- `_add_blood(pos, col)` (~línea 2063): crea un `BloodPool` (charco poligonal
  con goteo, clase en ~línea 688) y lo registra en `blood` con límite FIFO de
  200. `blood_0/1/2.png` son salpicaduras neutras (24×24, 40×24, 64×36) para
  teñir.
- Helper disponible: `_add_level(nodo)` engancha un nodo al escenario actual
  (`level_root`) para que se libere al cambiar de arena. `_poly` es solo para
  `Polygon2D`: para sprites usa `_add_level` con un `Sprite2D`.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en
  español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Texturas al inicio de `game.gd`

Junto a las constantes de color (`P1_COLOR`, etc., ~línea 82), añade las que
usan las funciones del script:

```gdscript
const TEX_ARROW := preload("res://art/sprites/arrow_neutral.png")
const TEX_BLOOD := [
	preload("res://art/sprites/blood_0.png"),
	preload("res://art/sprites/blood_1.png"),
	preload("res://art/sprites/blood_2.png"),
]
```

### 2. `Pip` con sprites

Sustituye el `_draw()` de la clase `Pip` (las texturas del pip van **dentro**
de la clase, que es una clase interna):

```gdscript
class Pip extends Node2D:
	## Cuadro del HUD de secciones: hueco o relleno del color conquistador.
	const TEX_FILLED := preload("res://art/sprites/pip_filled.png")
	const TEX_HOLLOW := preload("res://art/sprites/pip_hollow.png")
	var fill_col := Color(0, 0, 0, 0)
	var edge_col := Color(0.65, 0.63, 0.72)

	func _draw() -> void:
		draw_texture(TEX_HOLLOW, Vector2(-13.0, -13.0))
		if fill_col.a > 0.0:
			draw_texture_rect(TEX_FILLED, Rect2(-13.0, -13.0, 26.0, 26.0), false, fill_col)
```

(`edge_col` se conserva como variable para no romper `_update_pits`, pero ya
no se dibuja: el hueco ya trae su borde en la textura.)

### 3. Flecha de meta con sprite

En `_goal_zone`, sustituye la última línea (el `_poly` del triángulo) por un
sprite. La función queda así al final:

```gdscript
	var inward := 1.0 if x0 > LEVEL_W * 0.5 else -1.0
	var ar := Sprite2D.new()
	ar.texture = TEX_ARROW
	ar.position = Vector2(cx + inward * 4.0, 214.0)
	ar.flip_h = inward < 0.0
	ar.modulate = col
	ar.z_index = -3
	_add_level(ar)
```

(La zona translúcida y el poste se quedan como están.)

### 4. Salpicadura en el charco de sangre

En `_add_blood`, tras crear el `BloodPool` y antes de `_add_level(bp)`, añade
la salpicadura como **hijo del charco** (así el FIFO de `blood` la limpia
también):

```gdscript
	var bp := BloodPool.new(c)
	bp.position = Vector2(_out_of_pit(pos.x) + randf_range(-14.0, 14.0), GROUND_Y + randf_range(-2.0, 2.0))
	var splat := Sprite2D.new()
	splat.texture = TEX_BLOOD[randi() % TEX_BLOOD.size()]
	splat.position = Vector2(randf_range(-8.0, 8.0), -8.0)
	splat.modulate = c
	bp.add_child(splat)
	bp.z_index = 3
	_add_level(bp)
	...
```

El charco poligonal con goteo de `BloodPool._draw()` se conserva: la
salpicadura se suma encima.

## Qué NO hacer

- No cambies `_update_pips()` ni el espaciado de la fila (`pips_row`): solo
  cambia cómo se dibuja cada pip.
- No borres la clase `BloodPool` ni su goteo: la salpicadura es aditiva.
- No toques las colisiones de la meta ni `goal_polys`.
- No sustituyas la barra de respawn (`RespawnBar`): no tiene asset.

## Criterios de aceptación

1. Con el modo pantallas (tecla P), la fila de pips muestra los sprites
   (huecos grises; rellenos teñidos del color del equipo conquistador).
2. En cada extremo del nivel, la flecha de la meta es el sprite
   `arrow_neutral` teñido del color del jugador, apuntando hacia dentro.
3. Al matar cerca del suelo, además del charco aparece una salpicadura
   texturizada del color de la víctima; a los 200 charcos se limpia todo
   (hijo incluido).
4. El smoke test termina en `SMOKE OK`.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
Y una pasada con render activando P (pips), acercándose a una meta y matando
a un rival junto al suelo.
