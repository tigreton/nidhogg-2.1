# Tarea 84 — Lanzamiento con salto+ataque (el input del original, en suelo y aire)

**Dificultad:** baja · **Archivos:** `scripts/player.gd`, `test/suite_combate.gd` · **Prerrequisitos:** 49 aplicada (thrown por alturas)

## Objetivo

El gesto de lanzamiento del original, además del botón dedicado: **mantener
SALTO y pulsar ATAQUE lanza el arma** — en el suelo y en pleno salto. Con el
esquema de dos botones del original, quien viene de allí lo tiene en los
dedos; G/L sigue funcionando igual.

## Contexto del proyecto (leer antes de tocar nada)

- El input de ataque vive en `player.gd::_physics_process`, bloque
  `if can_act:` (IDLE/RUN/JUMP): rama `elif hit("attack"):` que hoy
  empieza con `if weapon_id == "arco": ... tensado`.
- El lanzamiento existente (botón): `elif hit("throw") and has_sword and
  MatchRules.allow_throw: has_sword = false; throw_pose_time = 0.22;
  threw_sword.emit(self)` — reutiliza el mismo cuerpo.
- `threw_sword` lo escucha el juego (crea el proyectil con la velocidad y
  reglas de la 49; el arco lanzado derriba, nunca mata).
- El disparo de arco sale al SOLTAR ataque, no al pulsar: sin conflicto con
  mantener salto.
- Interacción con el divekick: en el aire, ataque sin up/down = divekick.
  Si mantienes salto al pulsar ataque, ahora LANZAS (el gesto es
  deliberado: hay que estar manteniendo el botón de salto). Los bots nunca
  mantienen las dos a la vez.
- Reglas de estilo: GDScript tipado, tabs, español.

## Instrucciones paso a paso

### 1. La rama nueva (la primera del ataque)

En `player.gd`, rama `elif hit("attack"):`, añade como PRIMERA comprobación:

```gdscript
			elif hit("attack"):
				if held("jump") and has_sword and MatchRules.allow_throw:
					# lanzamiento del original: salto+ataque (suelo o aire)
					has_sword = false
					throw_pose_time = 0.22
					threw_sword.emit(self)
				elif weapon_id == "arco":
					... (todo lo demás igual, indentado un nivel más)
```

(OJO: al añadir el `if` interno, TODAS las ramas anteriores del ataque
quedan anidadas bajo él — reindéntalas con un tab más.)

### 2. Caso de suite

En `test/suite_combate.gd`, añade al array de `get_tests()`:

```gdscript
		["lanza_con_salto_ataque", _t_lanza_salto],
```

y la función:

```gdscript
func _t_lanza_salto() -> bool:
	_reset(1600.0, 4400.0)
	await runner.step_physics(1)
	# en el aire: mantener salto y pulsar ataque lanza el arma
	Input.action_press("p1_jump")
	await runner.step_physics(2)
	Input.action_release("p1_jump")
	Input.action_press("p1_jump")
	Input.action_press("p1_attack")
	await runner.step_physics(4)
	var thrown: bool = not runner.game.players[0].has_sword and runner.game.projectiles.size() >= 1
	Input.action_release("p1_attack")
	Input.action_release("p1_jump")
	runner.release_all()
	await runner.wait(0.5)
	_reset(1600.0, 4400.0)
	return runner.check(thrown, "salto+ataque en el aire lanza el arma")
```

## Qué NO hacer

- No quites el botón de lanzar (G/L / B del mando): son DOS entradas para el
  mismo gesto, como pedirán los que vienen del original.
- No lances con salto+ataque si `allow_throw` está desactivado (respeta la
  regla T del título).
- No lo apliques cuando la rodada/fase especial: la rama vive en `can_act`,
  déjala ahí.

## Criterios de aceptación

1. En suelo y en el aire, mantener salto + pulsar ataque lanza el arma con
   su estela; la pose de suelta (tarea 60/25f11ca) se ve igual que con G/L.
2. Sin mantener salto, ataque hace todo lo de siempre (estocada, divekick,
   tajo aéreo, tensado de arco).
3. El arco también se lanza así (derriba, no mata — regla de la 49).
4. Runner `ALL PASSED (13)` y `SMOKE OK` (ningún caso del smoke mantiene
   salto al pulsar ataque; si alguno fallara, revisa ese caso concreto).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/test_runner.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Últimas líneas esperadas: `RESULT: ALL PASSED (13)` y
`SMOKE OK - todas las mecánicas funcionan`.

## Nota de aplicación (2026-10-03)

Aplicada tal cual, con una enmienda de higiene en la suite: el test nuevo,
al insertarse entre el de la flecha rebotada y el del arco, hacía que la
flecha HEREDADA del test anterior (una flecha tarda >1 s en clavarse) ya no
desembocara limpia — el `_reset` de `suite_combate.gd` ahora libera
`arrows`/`projectiles`/`pickups` para que cada test arranque hermético.
Con eso: `RESULT: ALL PASSED (13)` y `SMOKE OK`.
