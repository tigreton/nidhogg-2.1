# Tarea 48 — Arco: tensado completo obligatorio, apuntado y límite de rebotes

**Dificultad:** media · **Archivos:** `scripts/player.gd`, `scripts/game.gd`, `test/smoke_test.gd`, `test/suite_combate.gd` · **Prerrequisitos:** 42 aplicada (actualiza su suite)

## Objetivo

Portar las tres reglas del arco del proyecto hermano:
1. **Tensado mínimo**: soltar antes de 1,0 s NO dispara (la flecha sale solo
   con el tensado completo). Antes disparaba con carga parcial.
2. **Velocidad fija**: la flecha sale siempre a 600 px/s (se elimina el
   multiplicador de carga, que ya no tiene sentido con tensado completo).
3. **Límite de rebotes**: tras 6 rebotes (o si la velocidad cae de 100 px/s)
   la flecha queda clavada — el docstring de `arrow.gd` ya lo prometía pero
   no estaba implementado. El apuntado con up/down durante el tensado ya
   funciona (la estancia se actualiza en `can_act`): se documenta y se cubre
   con test.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/player.gd` — al final de `_physics_process` está el bloque del
  arco:

```gdscript
	if bow_time > 0.0:
		if held("attack") and state in [State.IDLE, State.RUN, State.JUMP]:
			bow_time = minf(bow_time + delta, 1.0)
		else:
			fired_arrow.emit(self, stance, bow_time)
			bow_time = 0.0
```

  El tensado arranca en la rama de ataque (`weapon_id == "arco"` →
  `bow_time = 0.0001`). Mientras tensas sigues en IDLE/RUN → el bloque
  `can_act` de arriba ya actualiza `stance` con up/down: el apuntado ya
  funciona; NO lo dupliques.
- `scripts/game.gd::_on_fired_arrow(p, height, charge)` — hoy
  `a.vel = Vector2(p.facing * 600.0 * clampf(charge + 0.2, 0.5, 1.2), 0.0)`.
  La velocidad base 600 también vive en
  `GameConfig.WEAPONS["arco"]["arrow_speed"]`.
- `_update_arrows(delta)` — la flecha rebota si el rival guarda a su altura
  (`a.vel.x *= -0.85`, `a.bounces += 1`); las clavadas (`a.stuck = true`) se
  borran del array al frame siguiente y quedan como decoración.
- `scripts/arrow.gd` — docstring: "Tras 6 rebotes queda clavada" (a hacer
  verdad).
- El bot (`_bot_think` en `game.gd`) suelta el ataque en cada decisión
  (~0,13–0,26 s): tras este cambio nunca tensaría del todo → el paso 5 le
  enseña a tensar con el arco.
- El smoke caso 18 ("Arco: la flecha mata…") tensa 0,4 s → pasará a 1,1 s
  (paso 6).
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en
  español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Constante y bloque del arco en el jugador

En `scripts/player.gd`, junto a las demás constantes, añade:

```gdscript
const BOW_DRAW_TIME := 1.0     # tensado mínimo: antes de esto no dispara
```

Sustituye el bloque final del arco por:

```gdscript
	if bow_time > 0.0:
		if held("attack") and state in [State.IDLE, State.RUN, State.JUMP]:
			bow_time = minf(bow_time + delta, 1.0)
		elif bow_time >= BOW_DRAW_TIME:
			# soltar con el tensado completo: dispara a la estancia actual
			fired_arrow.emit(self, stance, bow_time)
			bow_time = 0.0
		else:
			# soltar antes de tiempo: se cancela, no dispara
			bow_time = 0.0
```

### 2. Velocidad fija de la flecha

En `scripts/game.gd::_on_fired_arrow`, sustituye la línea de `a.vel`:

```gdscript
	a.vel = Vector2(p.facing * 600.0 * clampf(charge + 0.2, 0.5, 1.2), 0.0)
```

por:

```gdscript
	a.vel = Vector2(p.facing * float(GameConfig.WEAPONS["arco"]["arrow_speed"]), 0.0)
```

### 3. Límite de rebotes

En `scripts/game.gd`, junto a las constantes del paso 2 de la tarea 47
(`PARRY_IMPULSE`…), añade:

```gdscript
const ARROW_MAX_BOUNCES := 6   # tras 6 rebotes la flecha se clava
const ARROW_MIN_SPEED := 100.0 # demasiado lenta: se clava
```

En `_update_arrows`, dentro de la rama `if guards:` (el rebote), añade el
tope tras incrementar el contador:

```gdscript
			if guards:
				a.vel = Vector2(a.vel.x * -0.85, 0.0)
				a.bounces += 1
				if a.bounces >= ARROW_MAX_BOUNCES or absf(a.vel.x) < ARROW_MIN_SPEED:
					a.stuck = true
					a.vel = Vector2.ZERO
					break
				_burst(a.position, Color(0.9, 0.9, 1.0), 8, 220.0)
				sfx(a.position, "clash", -14.0)
```

### 4. Docstring de la flecha

En `scripts/arrow.gd` el docstring ya dice la verdad; no hace falta tocarlo.
Verifica que no quede ningún otro comentario que hable de carga parcial.

### 5. El bot tensa el arco

En `scripts/game.gd::_bot_think`, justo antes de `p.bot_held = want`, añade:

```gdscript
	# con el arco: tensar mientras el rival está a distancia de flecha
	# (soltará al acercarse o alejarse → dispara con el tensado completo)
	if p.weapon_id == "arco" and p.has_sword and foe != null and on_floor \
			and adx > 100.0 and adx < 620.0:
		want["attack"] = true
		tap = ""
```

### 6. Caso 18 del smoke: esperas de 0,4 → 1,1 s

En `test/smoke_test.gd`, caso 18, hay DOS pulsaciones de tensado con espera
`0.4`. Sustituye cada una:

```gdscript
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.4).timeout
	Input.action_release("p1_attack")
```

por:

```gdscript
	Input.action_press("p1_attack")
	await get_tree().create_timer(1.1).timeout
	Input.action_release("p1_attack")
```

(son las dos únicas esperas de 0,4 del bloque del arco, líneas ~305-307 y
~314-316; el resto del caso no cambia).

### 7. Actualizar la suite

En `test/suite_combate.gd`, en `_t_flecha`, cambia el tensado (marcado
`# L48`):

```gdscript
	Input.action_press("p1_attack")
	await runner.step_physics(66)   # tensado completo obligatorio (1,1 s)  # L48
	Input.action_release("p1_attack")
```

y añade un test nuevo al array de `get_tests()`:

```gdscript
		["arco_soltar_antes_de_tiempo_no_dispara", _t_arco_cancel],
```

con:

```gdscript
func _t_arco_cancel() -> bool:
	_reset(1600.0, 1750.0)
	runner.game.players[0].weapon_id = "arco"
	await runner.step_physics(1)
	Input.action_press("p1_attack")
	await runner.step_physics(45)   # 0,75 s: se queda corto
	Input.action_release("p1_attack")
	await runner.step_physics(10)
	var no_arrow: bool = runner.game.arrows.is_empty()
	runner.release_all()
	await runner.wait(0.3)
	_reset(1600.0, 4400.0)
	return runner.check(no_arrow, "soltar el arco antes de 1,0 s no dispara")  # L48
```

## Qué NO hacer

- No dupliques la lógica de apuntado en el bloque del arco (la estancia ya
  se actualiza arriba, en `can_act`).
- No dejes ningún camino que dispare con carga parcial: o tensado completo o
  nada.
- No apliques el límite de rebotes a la flecha ANTES de rebotar (el primer
  rebote siempre ocurre: el tope es "tras 6").

## Criterios de aceptación

1. Soltar el arco a 0,5 s no dispara nada; tras 1,0 s completo sí, siempre a
   600 px/s.
2. Mantener up/down mientras tensas cambia la altura de salida de la flecha.
3. Una flecha rebotada 6 veces (o casi parada) queda clavada en el aire.
4. El bot con arco vuelve a disparar (tensa a distancia).
5. Runner `ALL PASSED` (11→12 tests) y smoke `SMOKE OK` con el caso 18
   actualizado.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/test_runner.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Últimas líneas esperadas: `RESULT: ALL PASSED (12)` y
`SMOKE OK - todas las mecánicas funcionan`.
