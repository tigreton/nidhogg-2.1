# Tarea 10 — Polvo al aterrizar y al correr

**Dificultad:** baja · **Archivos:** `scripts/player.gd` · **Prerrequisitos:** ninguno

## Objetivo

Partículas grises pequeñas al aterrizar (nube) y chispitas continuas mientras se
corre. Vida y peso para el movimiento sin tocar la física.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/player.gd` — `class_name Player` (CharacterBody2D):
	- `_physics_process(delta)` llama a `move_and_slide()` y luego comprueba
	  `is_on_floor()` para aterrizar estados. Al final hace `queue_redraw()`.
	- Estados: `enum State {IDLE, RUN, JUMP, DIVEKICK, ATTACK, STUNNED, KNOCKDOWN, DEAD}`
	  (índices 0–7; el test headless depende de ellos).
	- El duelist se puede añadir hijos de nodo con normalidad
	  (`add_child(...)`); los pies quedan en y≈30 (local).
- Patrón de partículas del proyecto (ver `game.gd::_burst`): `CPUParticles2D`
  one_shot + `get_tree().create_timer(...).timeout.connect(cp.queue_free)`.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Variables

En `scripts/player.gd`, junto a las demás variables de instancia, añade:

```gdscript
var was_on_floor := true
var dust_cd := 0.0
```

### 2. Detectar aterrizaje y carrera

En `_physics_process`, después de la llamada a `move_and_slide()` (y de sus
comprobaciones de aterrizaje de estados), añade:

```gdscript
	dust_cd = maxf(0.0, dust_cd - delta)
	if is_on_floor() and not was_on_floor:
		_dust(10, 150.0)
	elif state == State.RUN and dust_cd <= 0.0:
		dust_cd = 0.16
		_dust(3, 60.0)
	was_on_floor = is_on_floor()
```

### 3. Función de polvo

Añade esta función a `player.gd`:

```gdscript
func _dust(amount: int, speed: float) -> void:
	var cp := CPUParticles2D.new()
	cp.position = Vector2(0, 30)
	cp.one_shot = true
	cp.emitting = true
	cp.amount = amount
	cp.lifetime = 0.4
	cp.explosiveness = 1.0
	cp.direction = Vector2.UP
	cp.spread = 70.0
	cp.initial_velocity_min = speed * 0.4
	cp.initial_velocity_max = speed
	cp.gravity = Vector2(0, -60.0)
	cp.scale_amount_min = 2.0
	cp.scale_amount_max = 4.0
	cp.color = Color(0.55, 0.52, 0.60, 0.5)
	add_child(cp)
	get_tree().create_timer(0.9).timeout.connect(cp.queue_free)
```

## Qué NO hacer

- No cambies la física (velocidades, gravedad, fricción).
- No sueltes polvo en el aire ni muerto (las condiciones del paso 2 ya lo evitan).
- No uses GPUParticles2D (el proyecto es gl_compatibility y el patrón existente
  es CPUParticles2D).

## Criterios de aceptación

1. Al aterrizar de un salto o patada sale una nubecita de polvo.
2. Correr deja un rastro sutil de partículas.
3. Pararse en quieto no suelta nada.
4. El smoke test sigue pasando.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
