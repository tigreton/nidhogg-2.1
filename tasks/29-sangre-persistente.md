# Tarea 29 — Sangre persistente que gotea

**Dificultad:** media · **Archivos:** `scripts/game.gd`, `test/smoke_test.gd` · **Prerrequisitos:** ninguno

## Objetivo

Gore del original: cada muerte deja un **charco de sangre persistente** del
color de la víctima en el suelo, con un máximo de 200 manchas (FIFO). Tras
0,4 s, cada charco **gotea**: 2–3 trazos verticales que crecen hacia abajo,
como si la sangre se escurriera. Se limpia al reiniciar la ronda y al cambiar
de arena. Todo procedural, sin assets.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript), arte y sonido procedurales, indentación con
  **tabs**, comentarios en español.
- `scripts/game.gd`:
	- `const GROUND_Y := 560.0`.
	- `func _kill(def: Player, atk: Player) -> void:` contiene
	  `_burst(def.position, def.color, 34, 440.0)`; ahí se engancha la sangre.
	- `func _out_of_pit(x: float) -> float:` devuelve la x más cercana fuera de
	  cualquier foso (útil para no pintar sangre dentro del foso).
	- `func _start_round() -> void:` limpia proyectiles, pickups y rocas al
	  principio; ahí se limpia también la sangre.
	- `func set_arena(id) -> void:` libera `level_root` y hace `_tops.clear()`;
	  los nodos de sangre viven en `level_root`, así que al reconstruir hay que
	  vaciar también su array.
	- `_add_level(node)` cuelga nodos de `level_root` (z_index ordena el dibujo).
	- Hay clases internas de ejemplo para copiar el patrón
	  (`class Cloud extends Node2D:`, `class Torch ...`).
	- `var right_of_way: Player = null` y demás variables viven arriba del todo.
- El smoke test mata a P2 varias veces (secciones 4, 11...); la sangre es solo
  visual, pero se añade una comprobación del array antes de `print("")`.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Variable y clase interna

1.1. Junto a `var rocks: Array[FallingRock] = []`, añade:

```gdscript
var blood: Array[Node] = []
```

1.2. Junto a las demás clases internas (al lado de `class GlowSpot ...`),
añade:

```gdscript
class BloodPool extends Node2D:
	## Charco de sangre persistente que gotea hacia abajo.
	var col := Color(0.5, 0.1, 0.1)
	var t := 0.0
	var drips: Array[float] = []

	func _init(c: Color) -> void:
		col = c
		for i in 2 + randi() % 2:
			drips.append(randf_range(6.0, 15.0))

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var a := 0.85
		draw_colored_polygon(PackedVector2Array([
			Vector2(-22, -3), Vector2(-8, -6), Vector2(10, -5), Vector2(23, -2),
			Vector2(14, 4), Vector2(-6, 5), Vector2(-18, 3),
		]), Color(col.r, col.g, col.b, a))
		if t > 0.4:
			var g := clampf((t - 0.4) * 1.6, 0.0, 1.0)
			for i in drips.size():
				var dx := -14.0 + 12.0 * float(i)
				draw_rect(Rect2(dx, 0.0, 3.0, drips[i] * g), Color(col.r, col.g, col.b, a * 0.8))
```

### 2. Función que pinta el charco

Debajo de `_out_of_pit`, añade:

```gdscript
func _add_blood(pos: Vector2, col: Color) -> void:
	# solo hay sangre si la víctima cayó cerca de un suelo pisable
	if absf(pos.y - (GROUND_Y - 29.0)) > 80.0:
		return
	var c := Color(0.5, 0.1, 0.1).lerp(col.darkened(0.3), 0.45)
	var bp := BloodPool.new(c)
	bp.position = Vector2(_out_of_pit(pos.x) + randf_range(-14.0, 14.0), GROUND_Y + randf_range(-2.0, 2.0))
	bp.z_index = 3
	_add_level(bp)
	blood.append(bp)
	if blood.size() > 200:
		var old: Node = blood.pop_front()
		old.queue_free()
```

### 3. Engancharla a la muerte

En `_kill(def, atk)`, justo después de la línea
`_burst(def.position, def.color, 34, 440.0)`, añade:

```gdscript
	_add_blood(def.position, def.color)
```

### 4. Limpieza

4.1. En `_start_round()`, junto a la limpieza de las rocas
(`for r in rocks: r.queue_free()` y `rocks.clear()`), añade:

```gdscript
	for b in blood:
		b.queue_free()
	blood.clear()
```

4.2. En `set_arena(id)`, después de la línea `_tops.clear()`, añade:

```gdscript
	blood.clear()
```

(Los charcos son hijos de `level_root`, que ya se libera al cambiar de arena;
solo hay que vaciar el array para no apuntar a nodos muertos.)

### 5. Smoke test: sección nueva

En `test/smoke_test.gd`, busca la línea `print("")` e inserta ANTES:

```gdscript
	# 23. Sangre: cada muerte deja un charco persistente
	p1.has_sword = true
	p2.has_sword = true
	p1.position = Vector2(1600.0, 531.0)
	p2.position = Vector2(1670.0, 531.0)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.state = 0
	p2.state = 0
	p1.facing = 1
	p2.invuln_time = 0.0
	await get_tree().physics_frame
	Input.action_press("p2_up")
	await get_tree().create_timer(0.1).timeout
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.16).timeout
	Input.action_release("p1_attack")
	Input.action_release("p2_up")
	await get_tree().create_timer(0.3).timeout
	_check(p2.state == 7 and game.blood.size() >= 1, "Sangre: la muerte deja charco")
```

## Qué NO hacer

- No pintes sangre flotando en el aire: el filtro de altura (±80 px del suelo)
  lo evita; no lo quites.
- No pintes sangre dentro de los fosos (`_out_of_pit` lo evita).
- No uses partículas para los charcos: son `Node2D` dibujados, persistentes.
- No subas el límite de 200 ni cambies el FIFO.

## Criterios de aceptación

1. Cada muerte deja un charco rojo oscuro (teñido con el color de la víctima)
   donde cayó el cuerpo, y sigue ahí hasta el reinicio de la ronda.
2. Medio segundo después, del charco cuelgan 2–3 gotas que crecen hacia abajo.
3. Al reiniciar la ronda o cambiar de arena, la arena queda limpia.
4. Partidas larguísimas no acumulan charcos sin límite (máx 200, los viejos
   desaparecen).
5. El smoke test pasa, incluida la sección 23 nueva.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
