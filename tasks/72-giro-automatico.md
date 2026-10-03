# Tarea 72 — Giro automático al ser rebasado

**Dificultad:** baja · **Archivos:** `scripts/player.gd` · **Prerrequisitos:** ninguno

## Objetivo

Como el original: si el rival te pasa corriendo por detrás (o te tienen
pegado por tu espalda), tu duelistaa **se gira solo** hacia él. Sin esto, los
cruces al ras quedan ciegos para quien mira al vacío.

## Contexto del proyecto (leer antes de tocar nada)

- `player.gd`: `facing` hoy solo cambia con el input (`facing = 1 if dir > 0.0 else -1`
  dentro de `if can_act:` cuando `dir != 0`), y puntuales en el sidekick.
- El juego expone los rivales vía el padre: no hay helper, pero
  `get_parent().players` existe (el smoke usa `game.players`). Itera y filtra
  `_team` no es visible aquí: usa `player_id` distinto Y, en 2v2, la
  convención de equipos (id 1/3 vs 2/4) con la misma fórmula local:
  `var my_team := (player_id - 1) % 2`.
- El giro debe respetar los estados con lectura de facing propia (DIVE,
  ROLL, SIDEKICK, ATTACK): SOLO en IDLE/RUN.
- La guardia pasiva usa `g.facing` (empala a quien entra por delante): tras
  el giro, la guardia apunta al intruso — correcto, es el comportamiento
  del original.
- Reglas de estilo: GDScript tipado, tabs, español.

## Instrucciones paso a paso

### 1. El giro

En `player.gd::_physics_process`, justo después del bloque `if can_act:` que
fija `facing` por input (y antes del `match state:` de velocidad), añade:

```gdscript
	# giro automático: un rival pegado por la espalda te obliga a mirarlo
	if state in [State.IDLE, State.RUN]:
		var g := get_parent()
		if g != null and g.get("players") != null:
			var my_team := (player_id - 1) % 2
			for q in g.players:
				if q == self or q.state == State.DEAD:
					continue
				if (q.player_id - 1) % 2 == my_team:
					continue
				if absf(q.position.x - position.x) < 46.0 and absf(q.position.y - position.y) < 56.0:
					facing = 1 if q.position.x >= position.x else -1
```

## Qué NO hacer

- No lo apliques en el aire ni en DIVE/ROLL/SIDEKICK/ATTACK (sus facings son
  compromisos).
- No lo hagas "memoria" de quien pasó: es estado presente (rival cerca y
  detrás), no un histórico.
- No lo quites si el rival está invulnerable o derribado: el original también
  se gira ante caídos (sean amenaza o no).

## Criterios de aceptación

1. Un rival que te cruza pegado te voltea hacia él al pasar (se ve el sprite
   girar); al alejarse >46 px, recuperas control total de mirada.
2. La guardia pasiva tras el giro apunta al intruso (te empala si corre
   contra ti).
3. Tus saltos, dives y rodadas conservan su facing propio.
4. `SMOKE OK` y `ALL PASSED (12)` (los casos sitúan a los rivales de frente:
   el giro no cambia nada que asserten).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
