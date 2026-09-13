# Tarea 32 — Estela del arma lanzada

**Dificultad:** baja · **Archivos:** `scripts/sword_projectile.gd`, `test/smoke_test.gd` · **Prerrequisitos:** ninguno

## Objetivo

La espada lanzada vuela "limpia": ahora deja una **estela** de los últimos ~10
puntos (Line2D con alpha decreciente, del color del lanzador) para que se lea
mejor su trayectoria. Mismo objetivo de legibilidad que la estela del tajo.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript), arte y sonido procedurales, indentación con
  **tabs**, comentarios en español.
- `scripts/sword_projectile.gd` — `class_name SwordProjectile extends Node2D`:
	- Variables `vel`, `spin`, `thrower`, `color`.
	- `_ready()` solo pone `z_index = 15`.
	- `_process(delta)` hace `rotation += spin * delta`.
	- El proyectil se MUEVE desde fuera (`game.gd::_update_projectiles` suma
	  `s.position += s.vel * delta`), por eso la estela se registra por
	  `global_position` en `_process`.
- La espada se libera con `queue_free()` cuando golpea o cae: la estela debe
  desaparecer con ella (por eso será hija del proyectil con `top_level = true`,
  que ignora el transform del padre pero muere con él).
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Variables

Junto a `var color := Color(0.87, 0.9, 0.95)`, añade:

```gdscript
var trail: Line2D
const TRAIL_POINTS := 10
```

### 2. Crear la estela en `_ready()`

Sustituye TODO el cuerpo de `_ready()` por:

```gdscript
func _ready() -> void:
	z_index = 15
	trail = Line2D.new()
	trail.top_level = true
	trail.width = 4.0
	trail.z_index = 14
	var grad := Gradient.new()
	grad.set_color(0, Color(color.r, color.g, color.b, 0.0))
	grad.set_color(1, Color(color.r, color.g, color.b, 0.55))
	trail.gradient = grad
	add_child(trail)
```

### 3. Registrar puntos en `_process()`

Sustituye TODO el cuerpo de `_process(delta)` por:

```gdscript
func _process(delta: float) -> void:
	rotation += spin * delta
	if trail != null:
		while trail.get_point_count() >= TRAIL_POINTS:
			trail.remove_point(0)
		var last := trail.get_point_count() - 1
		if last < 0 or trail.get_point_position(last).distance_to(global_position) > 6.0:
			trail.add_point(global_position)
```

(Con `top_level = true`, los puntos son coordenadas globales aunque el nodo
gire: la estela queda recta detrás del arma giratoria, que es el efecto buscado.)

### 4. Smoke test: sección nueva

En `test/smoke_test.gd`, busca la línea `print("")` e inserta ANTES:

```gdscript
	# 26. Estela del arma lanzada
	p1.has_sword = true
	p1.position = Vector2(1600.0, 531.0)
	p2.position = Vector2(2600.0, 531.0)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.state = 0
	p2.state = 0
	p1.facing = 1
	await get_tree().physics_frame
	Input.action_press("p1_throw")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("p1_throw")
	await get_tree().create_timer(0.2).timeout
	var proj: Node = game.projectiles[0]
	_check(game.projectiles.size() == 1 and proj.trail != null and proj.trail.get_point_count() >= 2, "Estela: el arma lanzada deja rastro")
	for s in game.projectiles:
		s.queue_free()
	game.projectiles.clear()
	for pk in game.pickups:
		pk.queue_free()
	game.pickups.clear()
```

## Qué NO hacer

- No cambies cómo se mueve el proyectil (`game.gd` sigue sumando velocidad):
  la estela solo lee `global_position`.
- No pongas la estela como hija del juego: si el arma se libera, la estela
  debe liberarse con ella.
- No toques el dibujo de la espada (`_draw`).

## Criterios de aceptación

1. Lanzar la espada deja un rastro corto del color del arma que se desvanece
   por la cola.
2. El rastro no gira con la espada (queda recto detrás de ella).
3. Cuando la espada golpea o cae, el rastro desaparece con ella.
4. El smoke test pasa, incluida la sección 26 nueva.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
