# Tarea 25 — Modo pantallas: arena por secciones con rejas (tecla P)

**Dificultad:** alta · **Archivos:** `scripts/game.gd`, `test/smoke_test.gd` · **Prerrequisitos:** ninguno

## Objetivo

La estructura de Nidhogg 2 como MODO alternativo (tecla **P**): el nivel se
trocea en **7 secciones** con rejas visibles entre ellas. Las rejas bloquean a
todos; solo se abre la que el portador del paso va a cruzar. Al cruzarla, la
sección queda conquistada: el corredor entra por su borde y los rivales vivos
pasan al fondo de la sección (con 0,8 s de invulnerabilidad). Llegar a la meta
del final anota el punto como siempre. El modo normal (arena continua) no
cambia y sigue siendo el que arranca por defecto.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript), arte y sonido procedurales, indentación con
  **tabs**, comentarios en español.
- `scripts/game.gd` — nodo raíz. Datos clave:
	- `const LEVEL_W := 4800.0`, `const GROUND_Y := 560.0`, `const VIEW_W := 1152.0`.
	- `var right_of_way: Player = null` (el portador del paso / corredor).
	- `_setup_input()` define acciones en un diccionario `defs` que incluye
	  `"toggle_arena": [KEY_C],`; los toggles se procesan en `_physics_process`
	  con bloques `if Input.is_action_just_pressed("toggle_xxx"):` (hay uno para
	  `toggle_arena` que llama `set_arena(arena_id + 1)`).
	- `func _start_round() -> void:` limpia proyectiles/pickups/rocas, pone
	  `right_of_way = null` y coloca a los jugadores en el centro
	  (`LEVEL_W * 0.5 + o` con `offs := [-220.0, 220.0, -620.0, 620.0]`).
	- `func _respawn_pos(p: Player) -> Vector2:` empieza con
	  `if right_of_way == null:` (devuelve el centro) y después coloca al que
	  reaparece delante del corredor (`right_of_way.position.x + dir * 540.0`).
	- `_physics_process` llama al final, en este orden: `_resolve_attacks()`,
	  `_resolve_divekicks()`, `_update_projectiles(delta)`, `_update_rocks(delta)`,
	  `_update_pickups()`, `_check_goals()`, `_update_camera()`.
	- Hay clases internas de ejemplo (`class Cloud extends Node2D:`,
	  `class Torch ...`, `class GlowSpot ...`) y helpers `_poly()`, `_static_box()`.
	- El suelo tiene fosos en el centro (PIT 2210–2380) y un puente alto
	  (y = 288) que los cruza: las rejas deben bloquear también en alto.
- El smoke test (`test/smoke_test.gd`) prueba el modo normal; el modo pantallas
  arranca DESACTIVADO, así que nada de lo existente cambia. Se añade una
  sección nueva antes de la línea `print("")`.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Constantes y variables nuevas

1.1. Junto a `const LEVEL_W := 4800.0`, añade:

```gdscript
const SECTION_COUNT := 7
```

1.2. Junto a `var mode_2v2 := false`, añade:

```gdscript
var sections_mode := false
var section_index := 3
var sect_conquered := [0, 0]
var gates: Array[SectionGate] = []
```

### 2. Tecla P

2.1. En `_setup_input()`, la línea `"toggle_arena": [KEY_C],` queda seguida de:

```gdscript
		"toggle_sections": [KEY_P],
```

2.2. En `_physics_process`, justo después del bloque
`if Input.is_action_just_pressed("toggle_arena"):` (llama a `set_arena`), añade:

```gdscript
	if Input.is_action_just_pressed("toggle_sections"):
		set_sections(not sections_mode)
```

### 3. Clase interna SectionGate (reja con cuerpo físico)

Añádela junto a las demás clases internas (al lado de `class GlowSpot ...`):

```gdscript
class SectionGate extends Node2D:
	## Reja entre secciones: cuerpo estático + barrotes visibles. Al abrirse,
	## los barrotes se recogen hacia arriba y la colisión se desactiva.
	var body: StaticBody2D
	var open := false

	func _init(cx: float) -> void:
		position = Vector2(cx, 0.0)
		body = StaticBody2D.new()
		body.collision_layer = 2
		body.collision_mask = 0
		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(14.0, 700.0)
		cs.shape = rect
		cs.position = Vector2(0, 350.0)
		body.add_child(cs)
		add_child(body)

	func set_open(v: bool) -> void:
		open = v
		body.get_child(0).set_deferred("disabled", v)
		queue_redraw()

	func _draw() -> void:
		var iron := Color(0.16, 0.15, 0.19)
		var lite := Color(0.27, 0.26, 0.32)
		draw_rect(Rect2(-14, 60.0, 8.0, 508.0), iron)
		draw_rect(Rect2(6.0, 60.0, 8.0, 508.0), iron)
		var top := 66.0 if open else 130.0
		var bot := 126.0 if open else 560.0
		var bx := -6.0
		while bx <= 6.0:
			draw_rect(Rect2(bx - 2.5, top, 5.0, bot - top), lite)
			bx += 6.0
		draw_rect(Rect2(-10.0, top - 6.0, 20.0, 6.0), iron)
```

### 4. Activar y desactivar el modo

Debajo de `set_chaos(on)` (o debajo de `set_mode_2v2`), añade:

```gdscript
func set_sections(on: bool) -> void:
	if on == sections_mode:
		return
	sections_mode = on
	for g in gates:
		g.queue_free()
	gates.clear()
	if on:
		var w := LEVEL_W / float(SECTION_COUNT)
		for k in range(1, SECTION_COUNT):
			var g := SectionGate.new(w * float(k))
			g.z_index = 5
			add_child(g)
			gates.append(g)
	section_index = 3
	sect_conquered = [0, 0]
	scores = [0, 0]
	stats = _fresh_stats()
	match_over = false
	stats_label.visible = false
	set_chaos(false)
	_update_hud()
	_start_round()
	show_msg("MODO PANTALLAS: %s" % ("ACTIVADO" if on else "DESACTIVADO"), 1.0)
```

(Las rejas se añaden con `add_child(g)` directo, NO con `_add_level`: así
sobreviven a los cambios de arena de la tecla C.)

### 5. Apertura de rejas y detección de cruce

5.1. En `_start_round()`, después de la línea `right_of_way = null`, añade:

```gdscript
	section_index = 3
	sect_conquered = [0, 0]
```

5.2. Debajo de `set_sections`, añade:

```gdscript
func _update_gates() -> void:
	var w := LEVEL_W / float(SECTION_COUNT)
	var rw := right_of_way
	for i in gates.size():
		var border := float(i + 1) * w
		var open := false
		if rw != null and rw.state != Player.State.DEAD:
			if rw.goal_dir > 0:
				open = rw.position.x > border - w and rw.position.x < border + 40.0
			else:
				open = rw.position.x < border + w and rw.position.x > border - 40.0
		if gates[i].open != open:
			gates[i].set_open(open)


func _cross_section(sec: int) -> void:
	var w := LEVEL_W / float(SECTION_COUNT)
	var dir := 1 if sec > section_index else -1
	section_index = sec
	sect_conquered[_team(right_of_way)] += 1
	show_msg("¡SECCIÓN CONQUISTADA!", 0.9)
	sfx(right_of_way.position, "point", -14.0)
	var x_entry := w * float(sec) + 70.0 if dir > 0 else w * float(sec + 1) - 70.0
	var x_far := w * float(sec + 1) - 90.0 if dir > 0 else w * float(sec) + 90.0
	right_of_way.position.x = x_entry
	for p in players:
		if p == right_of_way or p.state == Player.State.DEAD:
			continue
		p.position.x = x_far
		p.invuln_time = maxf(p.invuln_time, 0.8)


func _update_sections() -> void:
	if not sections_mode:
		return
	_update_gates()
	var rw := right_of_way
	if rw == null or rw.state == Player.State.DEAD or round_lock > 0.0:
		return
	var w := LEVEL_W / float(SECTION_COUNT)
	var sec := clampi(int(rw.position.x / w), 0, SECTION_COUNT - 1)
	if sec != section_index:
		_cross_section(sec)
```

5.3. En `_physics_process`, después de la línea `_update_pickups()` y ANTES de
`_check_goals()`, añade:

```gdscript
	_update_sections()
```

### 6. Reaparecer en la sección delantera

En `_respawn_pos(p)`, después del bloque `if right_of_way == null:` (que
termina con su `return`) y antes de `var dir := float(right_of_way.goal_dir)`,
inserta:

```gdscript
	if sections_mode:
		var w := LEVEL_W / float(SECTION_COUNT)
		var sdir := 1 if right_of_way.goal_dir > 0 else -1
		var sec := clampi(section_index + sdir, 0, SECTION_COUNT - 1)
		var cx := w * (float(sec) + 0.5)
		if sec == section_index:
			# ya no hay sección delante: reaparece al fondo de la actual
			cx = w * float(sec + 1) - 100.0 if sdir > 0 else w * float(sec) + 100.0
		return Vector2(cx, 200.0)
```

### 7. Smoke test: sección nueva

En `test/smoke_test.gd`, busca la línea `print("")` e inserta ANTES:

```gdscript
	# 19. Modo pantallas (P): rejas que solo cruza quien tiene el paso
	game.set_sections(true)
	_check(game.sections_mode and game.gates.size() == 6, "Pantallas: 6 rejas activas")
	_check(game.section_index == 3, "Pantallas: empieza en la sección central")
	p1.position = Vector2(2300.0, 531.0)
	p2.position = Vector2(2600.0, 531.0)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.state = 0
	p2.state = 0
	game.right_of_way = p1
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(game.gates[3].open, "Pantallas: la reja del corredor se abre")
	p2.position = Vector2(3000.0, 531.0)
	p2.velocity = Vector2.ZERO
	Input.action_press("p2_right")
	await get_tree().create_timer(1.6).timeout
	Input.action_release("p2_right")
	_check(p2.position.x < 3420.0, "Pantallas: la reja cerrada bloquea al defensor")
	Input.action_press("p1_right")
	await get_tree().create_timer(2.0).timeout
	Input.action_release("p1_right")
	_check(game.section_index == 4, "Pantallas: P1 conquistó la sección 5")
	_check(game.sect_conquered[0] == 1, "Pantallas: conquista contada por equipo")
	game.set_sections(false)
	_check(not game.sections_mode and game.gates.is_empty(), "Pantallas: desactivar quita las rejas")
```

## Qué NO hacer

- No cambies `_build_level()`: las secciones son rejas sobre el MISMO nivel
  continuo, no salas nuevas.
- No limites la cámara a la sección (los límites ya funcionan en todo el
  nivel; restringirlos rompería el modo normal al desactivar).
- No hagas que las rejas se abran para el equipo defensor.
- No cambies `_point()` ni `_check_goals()`: la meta del final sigue anotando.
- No pongas las rejas como hijas de `level_root` (se perderían al cambiar de
  arena y el array `gates` quedaría apuntando a nodos liberados).

## Criterios de aceptación

1. Con P se activa el modo pantallas: 6 rejas reparten el nivel en 7 secciones
   y la partida se reinicia en la sección central.
2. Solo la reja que el corredor va a cruzar se abre (los barrotes se recogen);
   el defensor queda bloqueado por la suya.
3. Al cruzar, suena el aviso, la sección cuenta como conquistada y los vivos
   se reubican (rivales al fondo, con invulnerabilidad breve).
4. Reaparecer te deja delante del corredor, en la sección que va a conquistar.
5. P de nuevo vuelve al modo continuo y quita las rejas.
6. El smoke test pasa, incluida la sección 19 nueva.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
