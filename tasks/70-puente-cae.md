# Tarea 70 — Plataforma que se desmorona (cruce del foso central)

**Dificultad:** media · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** ninguno

## Objetivo

Hazard del original (Beach/Wilds): la vía alta sobre el foso central pasa de
ruta segura a **trampa** — sus 4 tramos tiemblan 0,4 s al pisarlos y caen.
Se restauran al empezar ronda. La vía baja (saltar el foso) sigue igual.

## Contexto del proyecto (leer antes de tocar nada)

- La plataforma del foso central la crea `_build_level()` con
  `_platform(PLAT_X0, PLAT_X1, PLAT_Y)` (2130–2460, y=448). `_platform`
  crea colisión `_static_box` + `_register_top` + dibujo `_tiled_rect`.
- `_start_round()` ya resetea rondas: ahí se restauran los tramos.
- `_tops` alimenta `_top_below` (corpse, arma caída): los tramos al caer
  deben dejar de contar como superficie — lo más simple es desactivar la
  colisión y "sacar" el top registrando un y absurdo NO: en su lugar, dada la
  complejidad, el tramo caído **elimina su StaticBody y su entrada de
  `_tops`** se marca como caída filtrando por referencia.
- El bot cruza por esa plataforma (`_bot_think` salta en la zona
  `PLAT_X0-130 .. PLAT_X1+130`): con 0,4 s de temblor el bot la cruza antes
  de que caiga; si un tramo cae bajo sus pies, el foso lo mata y el sim
  sigue pasando (hay victoria por kill y meta).
- `process_mode`: el decorado animado del nivel es `PROCESS_MODE_PAUSABLE`
  (nivel PAUSABLE) — los tramos son hijos de `level_root`, heredan.
- Reglas de estilo: GDScript tipado, tabs, español.

## Instrucciones paso a paso

### 1. Clase del tramo

Añade junto a las demás clases internas (p. ej. antes de `class Pip`):

```gdscript
class CrumbleTile extends Node2D:
	## Tramo de plataforma que tiembla al pisarlo y cae (tarea 70).
	var x0: float
	var x1: float
	var y: float
	var body: StaticBody2D
	var state := 0          # 0 intacto, 1 tiemblndo, 2 caído
	var t := 0.0

	func _init(px0: float, px1: float, py: float) -> void:
		x0 = px0
		x1 = px1
		y = py
		position = Vector2((x0 + x1) * 0.5, y + 8.0)
		body = StaticBody2D.new()
		body.collision_layer = 2
		body.collision_mask = 0
		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(x1 - x0, 16.0)
		cs.shape = rect
		body.add_child(cs)
		add_child(body)

	func restore(game: Node) -> void:
		state = 0
		t = 0.0
		position.y = y + 8.0
		body.get_child(0).set_deferred("disabled", false)
		if not game._tops.has(self):
			game._register_top(x0, x1, y)
		queue_redraw()

	func _process(delta: float) -> void:
		var game := get_parent().get_parent()
		if state == 0 and game.players.any(func(p): return p.is_on_floor() and p.position.y > y - 40.0 and p.position.y < y + 8.0 and p.position.x > x0 and p.position.x < x1):
			state = 1
			t = 0.0
		elif state == 1:
			t += delta
			position.x = (x0 + x1) * 0.5 + sin(t * 60.0) * 2.5
			if t >= 0.4:
				state = 2
				position.x = (x0 + x1) * 0.5
				body.get_child(0).set_deferred("disabled", true)
				game._tops.erase(game._tops.filter(func(top): return top.get("x0", -1.0) == x0 and top.get("y", -1.0) == y)[0]) if game._tops.any(func(top): return top.get("x0", -1.0) == x0 and top.get("y", -1.0) == y) else null
		elif state == 2:
			position.y += 620.0 * delta
			rotation += delta * 1.2
			if position.y > 900.0:
				position.y = 900.0
		queue_redraw()

	func _draw() -> void:
		if state == 2:
			draw_rect(Rect2(-(x1 - x0) * 0.5, -16.0, x1 - x0, 16.0), Color(0.16, 0.14, 0.22))
			return
		# intacto/temblando: mismo look que _platform (tile top claro)
		var host := get_parent().get_parent()
		draw_texture_rect(host.TEX_FLOOR, Rect2(-(x1 - x0) * 0.5, -8.0, x1 - x0, 16.0), true, host.col_plat)
		draw_texture_rect(host.TEX_FLOOR, Rect2(-(x1 - x0) * 0.5, -8.0, x1 - x0, 5.0), true, host.col_plat_top)
```

> NOTA de honestidad para el ejecutor: la línea de `_tops.erase(...)` con el
> ternario es frágil. Si Godot se queja, reescríbela como bucle `for` que
> borra la entrada con `x0 == x0 del tramo and y == y del tramo`. El resto
> no requiere improvisación.

### 2. Sustituir la plataforma fija por 4 tramos

En `_build_level()`, sustituye la línea `_platform(PLAT_X0, PLAT_X1, PLAT_Y)`
por:

```gdscript
	# crumble bridge: 4 tramos sobre el foso (tarea 70)
	crumble_tiles.clear()
	var tw := (PLAT_X1 - PLAT_X0) / 4.0
	for k in 4:
		var tile := CrumbleTile.new(PLAT_X0 + tw * float(k), PLAT_X0 + tw * (float(k) + 1.0), PLAT_Y)
		tile.z_index = -4
		_register_top(tile.x0, tile.x1, PLAT_Y)
		_add_level(tile)
		crumble_tiles.append(tile)
```

Y la variable junto a `var gates: Array[SectionGate] = []`:

```gdscript
var crumble_tiles: Array[CrumbleTile] = []
```

### 3. Restaurar en cada ronda

En `_start_round()`, junto a `right_of_way = null`:

```gdscript
	for tile in crumble_tiles:
		tile.restore(self)
```

## Qué NO hacer

- No toques `_platform` ni las demás plataformas (escalera, rocas): solo la
  del foso central.
- No hagas caer el tramo sin temblar (0,4 s dan margen al bot y al jugador).
- No dejes colisiones activas en tramos caídos (el foso tiene que tragar).
- Si el sim bajara de `kills >= 2` o dejara de anotar, NO lo maquilles:
  ajusta el temblor a 0,5 s y vuelve a probar.

## Criterios de aceptación

1. Pisar un tramo lo hace temblar 0,4 s y caer; desde caído no se puede
   volver a subir (el foso mata como siempre).
2. Saltar el foso por abajo sigue siendo la vía segura.
3. R de revancha restaura los 4 tramos.
4. `SMOKE OK`, `ALL PASSED (12)` y `SIM PASS`.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/sim_match.tscn
```

Últimas líneas esperadas: `SMOKE OK - todas las mecánicas funcionan` y
`SIM PASS`.
