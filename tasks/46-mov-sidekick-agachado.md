# Tarea 46 — Sidekick desde agachado

**Dificultad:** baja · **Archivos:** `scripts/player.gd`, `test/smoke_test.gd` · **Prerrequisitos:** ninguno (recomendado tras 42)

## Objetivo

En el proyecto hermano el sidekick se lanza desde agachado (agachado + salto).
Aquí ese slot de input ya lo ocupa la rodada, así que la adaptación acordada
es: **abajo + salto estando quieto mientras la rodada enfría** lanza el
SIDEKICK existente. Encadena naturalmente rodada → sidekick (la rodada deja
0,55 s de cooldown) y reutiliza la resolución actual (derriba, desarma, el
pateador rebota): solo añadimos un punto de entrada nuevo.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/player.gd` — bloque `if can_act:` de `_physics_process`. Orden
  actual de ramas de salto: (1) dive (`hit("jump") and held("down") and
  state == State.RUN and absf(velocity.x) > 120.0 and roll_cd <= 0.0`),
  (2) rodada (`elif hit("jump") and held("down") and is_on_floor() and
  roll_cd <= 0.0 and MatchRules.allow_roll`), (3) salto normal
  (`elif hit("jump") and is_on_floor():`).
  El sidekick actual sale por otra rama: `hit("attack")` con `is_on_floor()
  and has_sword and state == State.RUN and held("down")` → `State.SIDEKICK`
  con `velocity = Vector2(facing * 440.0, -160.0)`.
- `State.SIDEKICK` ya existe (índice 10) y `_resolve_sidekicks()` en
  `game.gd` ya derriba + desarma + rebota al pateador. NO hay que tocar
  `game.gd`.
- El smoke test termina con el caso 27 (pausa) — o el 33 si aplicaste la
  tarea 45 — seguido de `print("")` y el bloque final `SMOKE OK`: los casos
  nuevos van justo antes de ese `print("")`.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en
  español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Nueva rama de entrada (ANTES de la rodada)

En el bloque `if can_act:` de `player.gd`, inserta esta rama entre el dive y
la rodada, de modo que quede:

```gdscript
		if hit("jump") and held("down") and state == State.RUN and absf(velocity.x) > 120.0 and roll_cd <= 0.0:
			# dive horizontal: vuelo rasante con la espada
			...(sin cambios)...
		elif hit("jump") and held("down") and is_on_floor() and roll_cd > 0.0 and has_sword and absf(velocity.x) < 120.0:
			# sidekick desde agachado (adaptación del hermano: el slot
			# agachado+salto libre solo existe mientras la rodada enfría)
			if held("right"):
				facing = 1
			elif held("left"):
				facing = -1
			state = State.SIDEKICK
			sidekick_time = 0.0
			sidekick_resolved = false
			velocity = Vector2(facing * 440.0, -160.0)
			_sfx("swing", -18.0)
		elif hit("jump") and held("down") and is_on_floor() and roll_cd <= 0.0 and MatchRules.allow_roll:
			# rodar: esquiva rápida agachado (cuenta como estancia baja)
			...(sin cambios)...
```

(Las dos ramas existentes quedan exactamente igual; solo se inserta la nueva
`elif` entre medias.)

### 2. Caso nuevo del smoke

En `test/smoke_test.gd`, justo antes del `print("")` final, añade:

```gdscript
	# 34. Sidekick desde agachado: rodada y, con el cooldown activo, abajo+salto
	p1.has_sword = true
	p1.weapon_id = "florete"
	p2.has_sword = true
	p2.weapon_id = "florete"
	p1.position = Vector2(1600.0, 531.0)
	p2.position = Vector2(1655.0, 531.0)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.state = 0
	p2.state = 0
	p1.invuln_time = 0.0
	p2.invuln_time = 0.0
	p1.facing = 1
	p1.roll_cd = 0.0
	await get_tree().physics_frame
	Input.action_press("p1_down")
	Input.action_press("p1_jump")
	await get_tree().create_timer(0.08).timeout
	Input.action_release("p1_jump")
	Input.action_release("p1_down")
	# la rodada acaba a los 0,34 s pero su cooldown (0,55 s) sigue activo:
	# el segundo abajo+salto se pulsa a los ~0,42 s del primero
	await get_tree().create_timer(0.34).timeout
	Input.action_press("p1_down")
	Input.action_press("p1_jump")
	await get_tree().create_timer(0.12).timeout
	Input.action_release("p1_jump")
	Input.action_release("p1_down")
	_check(p1.state == 10, "Sidekick desde agachado con la rodada en cooldown")
	_check(p2.state == 6 and not p2.has_sword, "El sidekick desde agachado derriba y desarma")
	Input.action_release("p1_attack")
	await get_tree().create_timer(1.2).timeout
```

Notas: `p1.state == 10` es `State.SIDEKICK`. El segundo abajo+salto se pulsa
a los ~0,42 s del primero: la rodada (0,34 s) ya acabó pero su cooldown
(0,55 s) no → rama nueva.

## Qué NO hacer

- No quites ni reordenes las ramas existentes (dive, rodada, salto, sidekick
  corriendo): solo se AÑADE la `elif` nueva.
- No pongas esta rama detrás de la rodada: con `roll_cd <= 0.0` la rodada
  ganaría siempre y la rama nueva sería inalcanzable.
- No gatees la rama nueva con `MatchRules.allow_roll`: no es una rodada.
- No toques `game.gd` ni `_resolve_sidekicks`: la resolución es la misma.

## Criterios de aceptación

1. Abajo+salto en parado sigue rodando (con el cooldown a cero).
2. Justo tras rodar, abajo+salto lanza el sidekick (no otra rodada).
3. El sidekick desde agachado derriba, desarma y te rebota hacia atrás igual
   que el corriendo.
4. El smoke test (con el caso 34) termina en `SMOKE OK`.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.

## Nota de aplicación (2026-10-03)

Aplicada con dos ajustes al caso 34 (la mecánica y su rama, tal cual):

1. **Timing con la tarea 44:** la fricción tarda ~0,1 s en frenar los 520 px/s
   de la rodada, así que a los 0,42 s aún había |vx|>120 y la rama no entraba.
   La espera pasa de 0,34 a **0,40 s** (segundo abajo+salto a los ~0,48 s,
   aún dentro del cooldown de 0,55 s).
2. **Geometría:** la rodada cruza a P2 de largo (sin colisión entre
   jugadores), dejando a P1 a ~150 px; el caso repositiona a P1 en 1600 antes
   del segundo abajo+salto. Y al resolver el sidekick el pateador rebota a
   JUMP en ~0,03 s: el primer check acepta `state == 10 or sidekick_resolved`
   (eran contradictorios con el segundo check).

Tras los ajustes: `SMOKE OK` (casos 33-34) y `ALL PASSED (10)`.
