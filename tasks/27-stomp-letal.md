# Tarea 27 — Stomp letal: pisotón sobre el rival derribado

**Dificultad:** baja · **Archivos:** `scripts/game.gd`, `test/smoke_test.gd` · **Prerrequisitos:** ninguno

## Objetivo

Castigo del original: si el rival está **derribado** (KNOCKDOWN) y te colocas
encima **agachado** (mantener abajo), lo rematas: muere y su cadáver estalla
en una explosión de partículas grande del color de la víctima.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript), arte y sonido procedurales, indentación con
  **tabs**, comentarios en español.
- `scripts/player.gd`: `held(n)` es true mientras se mantiene la acción
  ("down" = abajo). Estado `KNOCKDOWN` con temporizador `knockdown_time`
  (1,0 s al ser derribado, 0,3 s al aterrizar de patada voladora).
- `scripts/game.gd`:
	- `func _resolve_divekicks() -> void:` resuelve los impactos de la patada
	  voladora; en `_physics_process` se llama en este orden:
	  `_resolve_attacks()`, `_resolve_divekicks()`, `_update_projectiles(delta)`,
	  `_update_rocks(delta)`, `_update_pickups()`, `_check_goals()`,
	  `_update_camera()`.
	- `_foes_of(p)` devuelve los enemigos vivos del otro equipo.
	- `_kill(def, atk)` mata (cuenta la baja en stats, suelta el arma, lanza
	  partículas de 34 piezas).
	- `_burst(pos, col, amount, speed)` crea una explosión de partículas.
	- `shake_time` alimenta el temblor de cámara (`shake_time = maxf(...)`).
- El smoke test termina con varias secciones y la línea `print("")`.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Función de resolución

Debajo de `_resolve_divekicks` (y de su helper `_nearest_divekick_target`),
añade:

```gdscript
func _resolve_stomps() -> void:
	for p in players:
		if p.state not in [Player.State.IDLE, Player.State.RUN] or not p.is_on_floor():
			continue
		if not p.held("down"):
			continue
		for def in _foes_of(p):
			if def.state != Player.State.KNOCKDOWN or def.invuln_time > 0.0:
				continue
			if absf(def.position.x - p.position.x) > 34.0 or absf(def.position.y - p.position.y) > 50.0:
				continue
			# pisotón letal: el derribado estalla
			_burst(def.position, def.color, 60, 560.0)
			_kill(def, p)
			shake_time = maxf(shake_time, 0.2)
			break
```

### 2. Llamarla cada frame

En `_physics_process`, después de la línea `_resolve_divekicks()` y ANTES de
`_update_projectiles(delta)`, añade:

```gdscript
	_resolve_stomps()
```

### 3. Smoke test: sección nueva

En `test/smoke_test.gd`, busca la línea `print("")` e inserta ANTES:

```gdscript
	# 21. Stomp: pisotón letal sobre el rival derribado
	p1.position = Vector2(1600.0, 531.0)
	p2.position = Vector2(1620.0, 531.0)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.state = 0
	p2.state = 6
	p2.knockdown_time = 0.9
	p2.invuln_time = 0.0
	p1.has_sword = true
	p2.has_sword = true
	await get_tree().physics_frame
	Input.action_press("p1_down")
	await get_tree().create_timer(0.3).timeout
	Input.action_release("p1_down")
	_check(p2.state == 7, "Stomp: pisotón sobre el derribado mata")
```

## Qué NO hacer

- No mates al derribado si el rival está en el aire: el stomp es de pie/agachado
  sobre el caído (la patada voladora ya tiene su propia resolución).
- No apliques el stomp a rivales en STUNNED: solo KNOCKDOWN.
- No cambies `_kill` ni el orden de llamadas existente en `_physics_process`
  (solo se inserta la nueva llamada).
- No mates dos rivales con un mismo pisotón (el `break` del bucle interno).

## Criterios de aceptación

1. Derriba al rival (patada voladora o puñetazo), quédate encima manteniendo
   abajo: el derribado muere con una explosión grande de su color.
2. Estar agachado al lado de un rival levantándose NO mata hasta que esté
   derribado de nuevo; los aturdidos no mueren por pisotón.
3. El invulnerable (recién reaparecido) no se puede rematar.
4. La baja cuenta en las estadísticas (el pisotón es un kill del rematador).
5. El smoke test pasa, incluida la sección 21 nueva.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
