# Tarea 75 — Tensar el arco en pleno dive-kick (y disparar al levantarte)

**Dificultad:** baja · **Archivos:** `scripts/player.gd`, `test/suite_movimiento.gd` · **Prerrequisitos:** 48 aplicada (tensado 1 s)

## Objetivo

Truco documentado del original: puedes **mantener el tensado durante el
dive-kick y el derribo** y disparar al recuperarte. Hoy soltar el estado de
suelo cancela el tensado.

## Contexto del proyecto (leer antes de tocar nada)

- El bloque del arco vive al final de `player.gd::_physics_process`:

```gdscript
	if bow_time > 0.0:
		if held("attack") and state in [State.IDLE, State.RUN, State.JUMP]:
			bow_time = minf(bow_time + delta, 1.0)
		elif bow_time >= BOW_DRAW_TIME:
			...
```

- `State.DIVEKICK` aterriza en `KNOCKDOWN` (0,3 s) y este expira a IDLE.
- El disparo sale al SOLTAR el botón (rama `elif bow_time >= BOW_DRAW_TIME`),
  así que mantener pulsado a través del vuelo+caída y soltar de pie dispara.
- El tensado NO debe congelar el dive-kick: solo se CONSERVA lo ya tensado;
  no crece en el aire del dive (el original tampoco: se tensa quieto).
- Reglas de estilo: GDScript tipado, tabs, español.

## Instrucciones paso a paso

### 1. Conservar el tensado en vuelo/caída

Sustituye la condición de conservación:

```gdscript
		if held("attack") and state in [State.IDLE, State.RUN, State.JUMP]:
			bow_time = minf(bow_time + delta, 1.0)
```

por:

```gdscript
		if held("attack") and state in [State.IDLE, State.RUN, State.JUMP]:
			bow_time = minf(bow_time + delta, 1.0)
		elif held("attack") and state in [State.DIVEKICK, State.DIVE, State.KNOCKDOWN]:
			# tensado en pleno dive-kick: se conserva (no crece) hasta levantarse
			pass
```

### 2. Caso de suite

En `test/suite_movimiento.gd`, añade al array de `get_tests()`:

```gdscript
		["arco_tensado_en_divekick", _t_arco_dive],
```

y la función:

```gdscript
func _t_arco_dive() -> bool:
	_reset(1600.0, 4400.0)
	runner.game.players[0].weapon_id = "arco"
	await runner.step_physics(1)
	# tensar completo en el suelo
	Input.action_press("p1_attack")
	await runner.step_physics(66)
	# dive-kick SIN soltar ataque (correr + saltar + atacar ya pulsado)
	Input.action_press("p1_right")
	await runner.step_physics(6)
	Input.action_press("p1_jump")
	await runner.step_physics(20)
	Input.action_release("p1_jump")
	Input.action_release("p1_right")
	await runner.step_physics(50)   # aterriza, knockdown, se levanta (0,3+0,3 s)
	var bow_ok: bool = runner.game.players[0].bow_time >= 1.0
	Input.action_release("p1_attack")
	await runner.step_physics(6)
	var fired: bool = runner.game.arrows.size() >= 1
	runner.release_all()
	await runner.wait(0.6)
	_reset(1600.0, 4400.0)
	return runner.check(bow_ok, "el tensado se conserva a través del dive-kick") \
			and runner.check(fired, "al soltar de pie, dispara")
```

## Qué NO hacer

- No dejes CRECER el tensado en DIVEKICK/KNOCKDOWN (solo conservarse).
- No permitas EMPEZAR a tensar en el aire del dive (el arranque sigue siendo
  por input de ataque con can_act — el arco ya lo permite en JUMP).
- No toques `BOW_DRAW_TIME` ni la velocidad de la flecha.

## Criterios de aceptación

1. Tensar, dive-kick sin soltar, aterrizar y soltar de pie: la flecha sale.
2. Soltar en pleno vuelo sigue cancelando/disparando según lo tensado
   (comportamiento previo intacto).
3. Runner `ALL PASSED (13)` y `SMOKE OK`.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/test_runner.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Últimas líneas esperadas: `RESULT: ALL PASSED (13)` y
`SMOKE OK - todas las mecánicas funcionan`.
