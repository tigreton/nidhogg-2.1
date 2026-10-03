# Tarea 73 — Levantamiento elegido (arriba = in situ, lateral = rodando)

**Dificultad:** media · **Archivos:** `scripts/player.gd`, `scripts/game.gd`, `test/smoke_test.gd` · **Prerrequisitos:** 12 aplicada (rodada)

## Objetivo

Como el original: derribado, ya no te levantas solo al agotarse el timer —
**tú eliges**: Arriba = levantarte en el sitio; izquierda/derecha =
levantarte rodando (con la i-frames y la recogida de armas de la rodada).
Mientras tanto, siguen pudiendo stompearte.

## Contexto del proyecto (leer antes de tocar nada)

- `player.gd`: `State.KNOCKDOWN` se descuenta en el primer `match` de
  `_physics_process` (`knockdown_time -= delta; if knockdown_time <= 0.0:
  state = State.IDLE`) y `can_act` es false durante él.
- El input se lee en `if can_act:`; el derribado NO puede. La lectura del
  "quiero levantarme" va en el juego (como el tackle de la rodada, tarea 45)
  o directamente en el jugador FUERA de `can_act`: aquí basta leer `held`
  fuera de `can_act` para up/left/right cuando `knockdown_time <= 0`.
- La rodada existente: `state = State.ROLL; roll_time = 0.0; roll_hit =
  false; roll_cd = ROLL_COOLDOWN; stance = H.LOW` + `_sfx("swing", -22.0)`.
- Recoger armas rodando YA funciona (`_update_pickups` recoge por cercanía).
- **El bot**: `_bot_think` rellena `bot_held`; un bot derribado sin órdenes
  no pulsaría nada — hay que enseñarle a levantarse (abajo, paso 3).
- Smoke: los casos 33/34 derriban a P2 y comprueban `p2.state == 6` ANTES de
  que expire `knockdown_time` (1,0 s y 1,2 s de espera vs 1,0 de timer):
  con esta tarea P2 SE QUEDA CAÍDO hasta input — los checks `== 6` pasan
  igual (sigue en 6). NADIE lo levanta en esos casos, y el caso siguiente
  hace `state = 0` a mano: sin cambios de test necesarios salvo el bot.
- `MatchRules.allow_roll` existe (regla T): el levantamiento rodando la
  respeta; el levantamiento in situ siempre existe.
- Reglas de estilo: GDScript tipado, tabs, español.

## Instrucciones paso a paso

### 1. Sin auto-levantamiento

En `player.gd`, primer `match` de `_physics_process`, sustituye:

```gdscript
		State.KNOCKDOWN:
			knockdown_time -= delta
			if knockdown_time <= 0.0:
				state = State.IDLE
```

por:

```gdscript
		State.KNOCKDOWN:
			knockdown_time -= delta
```

### 2. Levantamiento por input (fuera de `can_act`)

Añade justo después de ese `match` (antes de la gravedad):

```gdscript
	# levantarse tras el derribo: arriba = in situ; lateral = rodando (tarea 73)
	if state == State.KNOCKDOWN and knockdown_time <= 0.0:
		if held("up"):
			state = State.IDLE
			stance = H.MID
			_sfx("swing", -26.0)
		elif MatchRules.allow_roll and (held("left") or held("right")) and roll_cd <= 0.0:
			facing = 1 if held("right") else -1
			state = State.ROLL
			roll_time = 0.0
			roll_hit = false
			roll_cd = ROLL_COOLDOWN
			stance = H.LOW
			_sfx("swing", -22.0)
```

### 3. El bot se levanta

En `game.gd::_bot_think`, junto al resto de órdenes (antes de
`p.bot_held = want`), añade:

```gdscript
	# derribado: levantarse (arriba; con un poco de aleatorio, lateral)
	if p.state == Player.State.KNOCKDOWN and p.knockdown_time <= 0.0:
		want["up"] = true
		if randf() < 0.3:
			want["up"] = false
			want["right" if sd > 0.0 else "left"] = true
```

### 4. Válvula de seguridad del smoke

Un jugador humano que nunca pulse nada tras un derribo en los tests quedaría
caído para siempre: los casos que reutilizan a P2 tras derribarlo ya hacen
`state = 0` a mano — verifícalo (casos 33→34 y 35). Si algún caso espera la
recuperación automática, añade ahí `p2.knockdown_time = 0.0; p2.state = 0;`
con el mismo estilo de los resets existentes; NO cambies esperas globales.

## Qué NO hacer

- No pongas cooldown al levantamiento in situ (el original no lo tiene).
- No quites el stomp sobre el caído ni la invulnerabilidad de reaparición.
- No dejes al bot caído: sin el paso 3, el sim y el arcade se rompen
  (verifica `SIM PASS`).

## Criterios de aceptación

1. Derribado y expirado el timer, te mantienes caído; Arriba te levanta en
   el sitio; izquierda/derecha te levanta rodando en esa dirección (y recoges
   un arma del suelo al pasar sobre ella).
2. El stomp letal sigue disponible contra quien se queda caído.
3. Los bots se levantan solos (~70 % de pie, 30 % rodando).
4. `SMOKE OK`, `ALL PASSED (12)` y `SIM PASS`.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/sim_match.tscn
```

Últimas líneas esperadas: `SMOKE OK - todas las mecánicas funcionan` y
`SIM PASS`.
