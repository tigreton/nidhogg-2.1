# Tarea 74 — Reflejar flechas con patada (estando desarmado)

**Dificultad:** baja · **Archivos:** `scripts/game.gd`, `test/suite_combate.gd` · **Prerrequisitos:** 24 (arco) y 28 (puñetazo) aplicadas

## Objetivo

Detalle del original: hasta desarmado puedes **reflejar una flecha con el
timing de tu patada/puñetazo**. Aquí: el ataque desarmado activo
(`attack_is_active()` sin espada) desvía flechas a la altura de tu estancia,
igual que una guardia.

## Contexto del proyecto (leer antes de tocar nada)

- `game.gd::_update_arrows` decide por flecha y jugador:
  `var guards: bool = (p.stance == a.height and p.state in [IDLE, RUN]) or
  p.attack_is_active()` — o sea, **cualquier ataque activo YA desvía**
  flechas (armado o no). Lo que falta es el matiz del original: la patada
  desarmada desvía a CUALQUIER altura que cubra su estancia, no solo la
  propia... según el diseño portado, lo honesto y jugable es: **desarmado,
  el ataque activo desvía a las tres alturas** (es una patada, no una hoja
  con una línea) pero **solo mientras dura el golpe activo** (0,05–0,13 s
  según arma; sin espada usa el puñetazo: 0,07–0,20).
- Rama actual `if guards:` → rebote (`a.vel.x *= -0.85`, `bounces += 1`,
  tope de 6 por la 48, `_burst`, `sfx("arrow_bounce")`).
- Reglas de estilo: GDScript tipado, tabs, español.

## Instrucciones paso a paso

### 1. La patada refleja

En `_update_arrows`, sustituye la línea de `guards`:

```gdscript
			var guards: bool = (p.stance == a.height and p.state in [Player.State.IDLE, Player.State.RUN]) or p.attack_is_active()
```

por:

```gdscript
			var guards: bool = (p.stance == a.height and p.state in [Player.State.IDLE, Player.State.RUN]) or p.attack_is_active()
			# patada desarmada: el puñetazo activo refleja a cualquier altura (tarea 74)
			if not guards and p.attack_is_active() and not p.has_sword:
				guards = true
```

### 2. Test de suite

En `test/suite_combate.gd`, añade al array de `get_tests()`:

```gdscript
		["patada_refleja_flecha", _t_patada_flecha],
```

y la función:

```gdscript
func _t_patada_flecha() -> bool:
	_reset(1600.0, 1750.0)
	runner.game.players[0].weapon_id = "arco"
	runner.game.players[1].has_sword = false
	await runner.step_physics(1)
	Input.action_press("p1_attack")
	await runner.step_physics(66)   # tensado completo (tarea 48)
	Input.action_release("p1_attack")
	await runner.step_physics(22)   # la flecha llega: P2 golpea en ese margen
	Input.action_press("p2_attack")
	await runner.step_physics(6)
	Input.action_release("p2_attack")
	var g: Node = runner.game
	var p2: Player = g.players[1]
	var ok: bool = p2.state != Player.State.DEAD and g.arrows.size() >= 1 and g.arrows[0].bounces >= 1
	runner.release_all()
	await runner.wait(0.5)
	_reset(1600.0, 4400.0)
	return runner.check(ok, "el puñetazo desarmado refleja la flecha a tiempo")
```

(Si el timing de 22+6 frames no caza el golpe activo por carga de máquina,
ajusta SOLO esos dos números hasta que el puñetazo pille la flecha a media
altura; nunca conviertas las esperas en timers.)

## Qué NO hacer

- No hagas reflejar con el mero salto o el divekick (solo el ataque activo).
- No desvíes flechas con el arco equipado: el arco NO guarda (regla del
  original); el reflejo es del desarmado.
- No toques el tope de 6 rebotes ni la velocidad de la flecha.

## Criterios de aceptación

1. Desarmado, golpear justo cuando la flecha llega la devuelve (chispa y
   sonido de rebote); sin timing, la flecha te mata igual.
2. Armado, todo como estaba (la hoja ya desviaba con guardia/ataque).
3. Runner `ALL PASSED (13)` y `SMOKE OK`.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/test_runner.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Últimas líneas esperadas: `RESULT: ALL PASSED (13)` y
`SMOKE OK - todas las mecánicas funcionan`.
