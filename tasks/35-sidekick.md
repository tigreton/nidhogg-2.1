# Tarea 35 — Sidekick: patada lateral que derriba y desarma

**Dificultad:** media · **Archivos:** `scripts/player.gd`, `scripts/game.gd`, `test/smoke_test.gd` · **Prerrequisitos:** ninguno

## Objetivo

Movimiento del original: **corriendo con el arma**, mantener **abajo** y pulsar
**ataque** lanza una **patada lateral rasante** (sidekick) que DERRIBA al
rival y le hace **soltar el arma**; quien la ejecuta rebota hacia atrás en el
aire. Es el ataque de apertura del original: entra a media distancia, molesta
y sale.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript), arte y sonido procedurales, indentación con
  **tabs**, comentarios en español.
- `scripts/player.gd`:
	- Enum `State { IDLE, RUN, JUMP, DIVEKICK, ATTACK, STUNNED, KNOCKDOWN, DEAD, ROLL }`
	  (índices 0–8). **Añade SIDEKICK AL FINAL del enum** (índice 9; si ya
	  aplicaste la tarea 34, DIVE será el 9 y SIDEKICK el 10: añádelo SIEMPRE
	  como último valor, nunca en medio).
	- El bloque de ataque en `if can_act:` empieza con `elif hit("attack"):`
	  seguido de `if is_on_floor():` (ataque normal) y sus ramas.
	- DOS `match state:`: el primero avanza temporizadores; el segundo fija
	  `velocity.x`.
	- La cadena de transforms de `_draw()` tiene ramas
	  `if state == State.KNOCKDOWN: ... elif state == State.ROLL: ...`.
	- `var has_sword := true`; `held(n)`, `hit(n)`, `_sfx(...)`.
- `scripts/game.gd`:
	- `func _resolve_divekicks() -> void:` patrón a copiar (bucle jugadores,
	  marca `resolved`, elige objetivo por cercanía, resuelve).
	- En `_physics_process`: `_resolve_attacks()`, `_resolve_divekicks()`,
	  `_update_projectiles(delta)`, ... en ese orden.
	- `_foes_of(p)`, `def.knockdown(push)`, `_drop_sword(pos, col)`, `_burst(...)`,
	  `sfx(...)`, `shake_time` existen.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. `player.gd`: enum, constante y variables

1.1. Enum: añade SIDEKICK como ÚLTIMO valor (si la tarea 34 no está aplicada,
queda `..., ROLL, SIDEKICK`; si lo está, `..., ROLL, DIVE, SIDEKICK`).

1.2. Junto a `const LUNGE_SPEED := 620.0`, añade:

```gdscript
const SIDEKICK_TIME := 0.42
```

1.3. Junto a `var roll_cd := 0.0`, añade:

```gdscript
var sidekick_time := 0.0
var sidekick_resolved := false
```

### 2. `player.gd`: disparador

En el bloque de ataque, ANTES de la línea `if is_on_floor():` (la primera rama
de `elif hit("attack"):`), inserta:

```gdscript
			if is_on_floor() and has_sword and state == State.RUN and held("down"):
				# patada lateral (sidekick): derriba y desarma
				state = State.SIDEKICK
				sidekick_time = 0.0
				sidekick_resolved = false
				velocity = Vector2(facing * 440.0, -160.0)
				_sfx("swing", -18.0)
			elif is_on_floor():
```

(el `elif is_on_floor():` es la rama de ataque normal que ya existía; con
SIDEKICK añadido al enum, `can_act` sigue excluyéndolo automáticamente).

### 3. `player.gd`: avance y velocidad

3.1. En el PRIMER `match state:` añade el caso:

```gdscript
		State.SIDEKICK:
			sidekick_time += delta
			if sidekick_time >= SIDEKICK_TIME and is_on_floor():
				state = State.IDLE
```

3.2. En el SEGUNDO `match state:` añade el caso:

```gdscript
		State.SIDEKICK:
			velocity.x = facing * 440.0
```

### 4. `player.gd`: dibujo

En la cadena de transforms de `_draw()` (después de la rama de ROLL o de DIVE
si existe), añade:

```gdscript
	elif state == State.SIDEKICK:
		t_rot = 0.9
		t_pos = Vector2(0, 4)
```

### 5. `game.gd`: resolución

5.1. Debajo de `_resolve_divekicks` (o de `_resolve_dives` si aplicaste la
tarea 34), añade:

```gdscript
func _resolve_sidekicks() -> void:
	for p in players:
		if p.state != Player.State.SIDEKICK or p.sidekick_resolved:
			continue
		for def in _foes_of(p):
			if def.state == Player.State.DEAD or def.invuln_time > 0.0:
				continue
			if absf(def.position.x - p.position.x) > 42.0 or absf(def.position.y - p.position.y) > 56.0:
				continue
			p.sidekick_resolved = true
			var push := 1 if def.position.x >= p.position.x else -1
			def.knockdown(push)
			if def.has_sword:
				def.has_sword = false
				_drop_sword(def.position + Vector2(0.0, -20.0), Color(0.87, 0.9, 0.95))
			p.state = Player.State.JUMP
			p.velocity = Vector2(-float(p.facing) * 210.0, -440.0)
			_burst(def.position, Color(1, 1, 1), 10, 240.0)
			sfx(def.position, "hit", -10.0)
			shake_time = maxf(shake_time, 0.12)
			break
```

5.2. En `_physics_process`, después de la línea `_resolve_divekicks()` (o de
`_resolve_dives()` si existe), añade:

```gdscript
	_resolve_sidekicks()
```

### 6. Smoke test: sección nueva

En `test/smoke_test.gd`, busca la línea `print("")` e inserta ANTES:

```gdscript
	# 29. Sidekick: derriba y desarma
	p1.has_sword = true
	p2.has_sword = true
	p1.position = Vector2(1500.0, 531.0)
	p1.velocity = Vector2.ZERO
	p1.state = 0
	p2.position = Vector2(1650.0, 531.0)
	p2.velocity = Vector2.ZERO
	p2.state = 0
	p2.invuln_time = 0.0
	p1.facing = 1
	await get_tree().physics_frame
	Input.action_press("p1_right")
	await get_tree().create_timer(0.15).timeout
	Input.action_press("p1_down")
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.15).timeout
	Input.action_release("p1_attack")
	Input.action_release("p1_down")
	Input.action_release("p1_right")
	await get_tree().create_timer(0.4).timeout
	_check(p2.state == 6 and p2.has_sword == false, "Sidekick: derriba y desarma")
	for pk in game.pickups:
		pk.queue_free()
	game.pickups.clear()
```

## Qué NO hacer

- No apliques el sidekick al que va desarmado (requiere `has_sword`): el juego
  desarmado ya tiene su puñetazo y su patada baja.
- No conviertas el ataque normal agachado parado: el sidekick SOLO sale
  corriendo (state RUN) manteniendo abajo.
- No toques DIVEKICK ni la rodada: conviven con el sidekick.
- No añadas SIDEKICK a la lista de `can_act`.

## Criterios de aceptación

1. Corriendo con espada, abajo + ataque: patada rasante con pequeño salto que
   derriba al rival y le suelta el arma.
2. Quien ejecuta el sidekick rebota hacia atrás en el aire y puede encadenar
   acciones al aterrizar.
3. El ataque normal (parado, sin abajo) no cambia; la rodada tampoco.
4. El smoke test pasa, incluida la sección 29 nueva.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
