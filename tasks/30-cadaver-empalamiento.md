# Tarea 30 — Cadáver persistente que sale despedido (y empalamiento)

**Dificultad:** media · **Archivos:** `scripts/game.gd`, `test/smoke_test.gd` · **Prerrequisitos:** ninguno

## Objetivo

El detalle más "Nidhogg" que falta: al matar, el cuerpo **no desaparece**:
sale despedido girando, cae, y queda **tumbado en el suelo** hasta que el
jugador reaparece (entonces se desvanece). Y lo icónico: si el golpe fue de
espada, el cadáver queda **EMPALADO** en la hoja del asesino y se mueve con
él, hasta que el asesino da un tajo (lo sacude) o muere.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript), arte y sonido procedurales, indentación con
  **tabs**, comentarios en español.
- `scripts/game.gd`:
	- `func _kill(def: Player, atk: Player) -> void:` termina con
	  `_after_death(def, atk)` y antes llama a `sfx(def.position, "kill", -6.0)`.
	  Ahí se engancha el cadáver. `def.die()` (en player.gd) oculta al jugador
	  (`visible = false`), así que el cadáver lo sustituye visualmente.
	- `func _respawn(p: Player) -> void:` se llama cuando el contador de
	  `respawn_timers` llega a cero; empieza con
	  `if p.state != Player.State.DEAD: return`.
	- `func _start_round() -> void:` limpia todo al empezar la ronda.
	- `func _top_below(x: float, from_y: float) -> float:` devuelve la y de la
	  primera superficie elevada bajo un punto (o -1 si no hay).
	- `const GROUND_Y := 560.0`.
	- Hay clases internas de ejemplo para copiar el patrón
	  (`class Cloud extends Node2D:`, `class Torch ...`).
- El smoke test comprueba estados por número (7 = DEAD) y usa esperas de
  2,6 s para las reapariciones (RESPAWN_DELAY = 2,4).
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Variable y clase interna Corpse

1.1. Junto a `var projectiles: Array[SwordProjectile] = []`, añade:

```gdscript
var corpses := {}
```

1.2. Junto a las demás clases internas (al lado de `class GlowSpot ...`),
añade:

```gdscript
class Corpse extends Node2D:
	## Cadáver persistente: sale despedido girando, cae y queda tumbado.
	## Con arma de hoja puede quedar empalado en la espada del asesino.
	var col := Color.WHITE
	var vel := Vector2.ZERO
	var spin := 0.0
	var rot := 0.0
	var impaler: Player = null
	var grounded := false

	func _process(delta: float) -> void:
		if impaler != null:
			if impaler.state == Player.State.DEAD or not impaler.has_sword or impaler.attack_is_active():
				impaler = null
			else:
				position = impaler.position + Vector2(impaler.facing * 44.0, -6.0)
				queue_redraw()
				return
		if not grounded:
			vel.y += 1500.0 * delta
			position += vel * delta
			rot += spin * delta
			var g := get_parent()
			var floor_y := 560.0
			if g != null and g.has_method("_top_below"):
				var top: float = g._top_below(position.x, position.y)
				if top > 0.0:
					floor_y = top
			if position.y >= floor_y - 8.0:
				position.y = floor_y - 8.0
				grounded = true
		queue_redraw()

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0 if grounded else rot, Vector2.ONE)
		var dark := Color(0.05, 0.04, 0.08)
		draw_line(Vector2(-16, 0), Vector2(14, 0), dark, 20.0)
		draw_line(Vector2(-16, 0), Vector2(14, 0), col, 15.0)
		draw_circle(Vector2(-22, 0), 8.0, dark)
		draw_circle(Vector2(-22, 0), 6.5, col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
```

### 2. Crear el cadáver al morir

2.1. Debajo de `_kill`, añade:

```gdscript
func _spawn_corpse(def: Player, atk: Player) -> void:
	var c := Corpse.new(Color(def.color))
	c.position = def.position
	if atk != null:
		var dir := signf(def.position.x - atk.position.x)
		if dir == 0.0:
			dir = -float(def.facing)
		c.vel = Vector2(dir * 300.0, -260.0)
		c.spin = dir * randf_range(2.0, 5.0)
		if atk.has_sword:
			c.impaler = atk
	else:
		c.vel = Vector2(-float(def.facing) * 160.0, -200.0)
		c.spin = randf_range(-3.0, 3.0)
	c.z_index = 8
	add_child(c)
	corpses[def.player_id] = c
```

(Nota: si aplicaste la tarea 23, deja el empalamiento solo para las armas de
hoja cambiando el `if atk.has_sword:` por
`if atk.has_sword and atk.weapon_id in ["florete", "daga"]:`.)

2.2. En `_kill(def, atk)`, justo ANTES de la línea
`sfx(def.position, "kill", -6.0)`, añade:

```gdscript
	_spawn_corpse(def, atk)
```

### 3. Limpieza

3.1. En `_respawn(p)`, después de la guardia inicial
`if p.state != Player.State.DEAD: return`, añade:

```gdscript
	if corpses.has(p.player_id):
		corpses[p.player_id].queue_free()
		corpses.erase(p.player_id)
```

3.2. En `_start_round()`, junto a la limpieza de las rocas, añade:

```gdscript
	for k in corpses:
		corpses[k].queue_free()
	corpses.clear()
```

### 4. Smoke test: sección nueva

En `test/smoke_test.gd`, busca la línea `print("")` e inserta ANTES:

```gdscript
	# 24. Cadáver: empalado en la espada, suelto con un tajo, limpiado al reaparecer
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
	await get_tree().create_timer(0.2).timeout
	_check(p2.state == 7 and game.corpses.has(2), "Cadáver: el cuerpo queda en escena")
	var cx0: float = game.corpses[2].position.x
	Input.action_press("p1_right")
	await get_tree().create_timer(0.25).timeout
	Input.action_release("p1_right")
	_check(game.corpses[2].position.x > cx0 + 30.0, "Cadáver: empalado sigue a la espada del asesino")
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.2).timeout
	Input.action_release("p1_attack")
	await get_tree().create_timer(0.6).timeout
	_check(game.corpses[2].grounded, "Cadáver: tras el tajo cae y queda en el suelo")
	await get_tree().create_timer(2.2).timeout
	_check(game.corpses.is_empty(), "Cadáver: se limpia al reaparecer el jugador")
```

## Qué NO hacer

- No hagas al jugador visible durante la muerte: `die()` lo oculta y el
  cadáver lo sustituye; no restaures `visible` hasta `revive()`.
- No des física real (CharacterBody/RigidBody) al cadáver: es un `Node2D` con
  manual de gravedad y tope de suelo, como está escrito.
- No dejes cadáveres de rondas anteriores: `_start_round` los limpia todos.
- No empales con muertes de entorno (`atk == null`): solo cuerpo a cuerpo.

## Criterios de aceptación

1. Al matar, el cuerpo sale despedido en dirección contraria al asesino,
   gira en el aire y queda tumbado en el suelo (o sobre la plataforma).
2. Si el golpe fue de espada, el cadáver cuelga de la hoja y acompaña al
   asesino; un tajo del asesino lo sacude y cae al suelo.
3. Los cadáveres desaparecen cuando su jugador reaparece, y todos al reiniciar
   la ronda o cambiar de arena.
4. En 2v2 cada muerte deja su propio cadáver (van por player_id).
5. El smoke test pasa, incluida la sección 24 nueva.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
