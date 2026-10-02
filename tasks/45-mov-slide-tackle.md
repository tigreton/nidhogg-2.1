# Tarea 45 — Slide tackle: atacar durante la rodada derriba

**Dificultad:** media · **Archivos:** `scripts/player.gd`, `scripts/game.gd`, `test/smoke_test.gd` · **Prerrequisitos:** ninguno (recomendado tras 42)

## Objetivo

Mecánica portada del proyecto hermano (su "slide tackle"): si pulsas **atacar
mientras ruedas**, la voltereta se convierte en un barrido que **derriba** (no
mata) al rival que esté delante. La rodada pasa de esquiva pura a opción
ofensiva de corto alcance, y solo puede tocar a uno por rodada.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/player.gd` — la rodada vive en `State.ROLL` (índice 8, añadido al
  final del enum). Sus variables son `roll_time`/`roll_cd`. Durante ROLL
  `can_act` es false, así que el input de ataque NO lo lee el jugador: lo
  tiene que leer el juego. `held("attack")` funciona igual para humanos y
  bots.
- `scripts/game.gd` — la cadena de resolución está al final de
  `_physics_process`:

```gdscript
	_resolve_attacks()
	_resolve_guard_impale()
	_resolve_divekicks()
	_resolve_dives()
	_resolve_sidekicks()
	_resolve_stomps()
```

  El juego (padre) procesa antes que los jugadores (hijos), pero `held()` lee
  el estado del Input del frame, igual para ambos. Los derribos usan
  `def.knockdown(push)` (empuje ±1) más `_burst` + `sfx("hit")` — patrón de
  `_resolve_sidekicks`.
- `Player.PUNCH_RANGE = 50.0` (alcance del juego desarmado).
- El smoke test termina con el caso 27 (pausa) seguido de `print("")` y el
  bloque final que imprime `SMOKE OK`: los casos nuevos se añaden justo antes
  de ese `print("")`.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en
  español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Flag de un impacto por rodada

En `scripts/player.gd`, junto a `var roll_time := 0.0` / `var roll_cd := 0.0`,
añade:

```gdscript
var roll_hit := false   # el tackle de la rodada solo golpea a uno
```

En el disparador de la rodada (bloque `if can_act:`, rama
`elif hit("jump") and held("down") and is_on_floor() and roll_cd <= 0.0 and MatchRules.allow_roll:`),
añade el reset junto a `roll_time = 0.0`:

```gdscript
			state = State.ROLL
			roll_time = 0.0
			roll_hit = false
			roll_cd = ROLL_COOLDOWN
```

Haz lo mismo en la rama del dive (`state = State.DIVE` … `dive_resolved = false`)
por simetría: añade `roll_hit = false` bajo `dive_resolved = false`.

### 2. Resolución del tackle

En `scripts/game.gd`, añade la función junto a `_resolve_sidekicks`:

```gdscript
func _resolve_roll_tackles() -> void:
	# slide tackle: atacar durante la rodada derriba (no mata) al rival cercano
	for p in players:
		if p.state != Player.State.ROLL or p.roll_hit:
			continue
		if not p.held("attack"):
			continue
		for def in _foes_of(p):
			if def.state == Player.State.DEAD or def.invuln_time > 0.0:
				continue
			if absf(def.position.x - p.position.x) > Player.PUNCH_RANGE + 24.0 or absf(def.position.y - p.position.y) > 50.0:
				continue
			p.roll_hit = true
			var push := 1 if def.position.x >= p.position.x else -1
			def.knockdown(push)
			_burst(def.position, Color(1, 1, 1), 8, 200.0)
			sfx(def.position, "hit", -10.0)
			shake_time = maxf(shake_time, 0.1)
			break
```

### 3. Engancharla en la cadena

En `_physics_process`, tras `_resolve_sidekicks()` añade la llamada:

```gdscript
	_resolve_dives()
	_resolve_sidekicks()
	_resolve_roll_tackles()
	_resolve_stomps()
```

### 4. Caso nuevo del smoke

En `test/smoke_test.gd`, justo antes del `print("")` final, añade:

```gdscript
	# 33. Slide tackle: atacar durante la rodada derriba (no mata)
	p1.has_sword = true
	p1.weapon_id = "florete"
	p2.has_sword = true
	p2.weapon_id = "florete"
	p1.position = Vector2(1600.0, 531.0)
	p2.position = Vector2(1650.0, 531.0)
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
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.12).timeout
	Input.action_release("p1_attack")
	Input.action_release("p1_down")
	_check(p2.state == 6 and p2.state != 7, "Slide tackle: atacar rodando derriba al rival")
	await get_tree().create_timer(1.2).timeout
```

## Qué NO hacer

- No permitas que el tackle mate: siempre `knockdown` (el hermano lo define
  así: la rodada derriba, no mata).
- No añadas ROLL a `can_act` ni dejes atacar en mitad de la rodada: el input
  lo lee `_resolve_roll_tackles`, no el jugador.
- No golpees a más de un rival por rodada (`roll_hit` lo impide).

## Criterios de aceptación

1. Rodar hacia un rival y pulsar ataque lo derriba; él conserva su arma (a
   diferencia del sidekick, esto no desarma).
2. Un segundo rival cercano no recibe nada si ya hubo impacto en esa rodada.
3. Rodar sin pulsar ataque sigue siendo una esquiva pura.
4. El smoke test (con el caso 33) termina en `SMOKE OK`.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.

## Nota de aplicación (2026-10-03)

Aplicada con un ajuste no previsto en el texto: el caso 33 fallaba porque la
**guardia pasiva empalaba al rodador** antes de que el tackle existiera (P2
heredaba `facing=-1` de casos previos; rodar fuerza estancia LOW y la guardia
MID a distinta altura mata). Como el dive y el sidekick ya estaban exentos del
empalamiento por tener resolución propia, se añadió `Player.State.ROLL` a esa
lista de exenciones en `_resolve_guard_impale` (comentario actualizado a
34/35/45). Sin eso, la mecánica no funcionaría en partida real, no solo en el
test. Tras el ajuste: `SMOKE OK` (caso 33 incluido) y `ALL PASSED (10)`.
