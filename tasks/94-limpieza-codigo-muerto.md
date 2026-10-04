# Tarea 94 — Limpieza: código muerto de `game.gd` y `player.gd`

**Dificultad:** baja · **Archivos:** `scripts/game.gd`, `scripts/player.gd` ·
**Prerrequisitos:** ninguno (hallazgos de la revisión post-fusión, 2026-10-04)

## Objetivo

Tres piezas de código muerto que confunden al leer:
1. `const WIN_SCORE := 3` — la victoria real usa `MatchRules.win_score`
   (configurable 1/3/5 desde el título); la constante solo la cita el
   comentario de cabecera.
2. Una rama inalcanzable en la guardia de flechas (la tarea 74 quedó
   absorbida por la condición general).
3. La señal `died` de player.gd, emitida y nunca conectada (game.gd conecta
   `threw_sword` y `fired_arrow`; la muerte la resuelve `_kill` a mano).

## Contexto del proyecto (leer antes de tocar nada)

- La condición de guardia contra flechas (en `_update_projectiles`) es:
  `var guards: bool = (p.stance == a.height and p.state in [IDLE, RUN]) or
  p.attack_is_active()`; justamente debajo hay un `if not guards and
  p.attack_is_active() and not p.has_sword: guards = true` que no puede
  ejecutarse nunca (si `attack_is_active()` fuera cierto, `guards` ya lo
  sería).
- `player.gd` declara `signal died(player: Player)` y lo emite en `die()`;
  no hay conexión en `game.gd`, ni en `title.gd`, ni en los `.tscn`
  (verificado con grep el 2026-10-04).
- El online no usa ninguna de las tres piezas (la sincronización de
  muertes va por `ev_kill`).

## Instrucciones paso a paso

### 1. `game.gd` — eliminar `WIN_SCORE` y arreglar la cabecera

Busca en la cabecera del archivo la línea de comentario:

```gdscript
## Primero en llegar a WIN_SCORE puntos gana el partido.
```

y sustitúyela por:

```gdscript
## Primero en llegar a MatchRules.win_score puntos (1/3/5, se elige en el
## título) gana el partido.
```

Después busca y BORRA la línea:

```gdscript
const WIN_SCORE := 3
```

### 2. `game.gd` — eliminar la rama muerta de la guardia de flechas

En `_update_projectiles`, busca el par de líneas:

```gdscript
			if not guards and p.attack_is_active() and not p.has_sword:
				guards = true
```

y BÓRRALAS (la variable `guards` de la línea superior ya cubre ese caso).

### 3. `player.gd` — eliminar la señal `died` sin receptores

Busca y BORRA la línea de declaración:

```gdscript
signal died(player: Player)
```

Y dentro de `func die()`, busca y BORRA la línea:

```gdscript
	died.emit(self)
```

## Qué NO hacer

- No toques `MatchRules`, ni la pantalla de título, ni el online.
- No borres las señales `threw_sword`/`fired_arrow` (SÍ están conectadas).
- Si algún harness externo usara `died` (no lo hace a día de hoy), el paso
  3 se salta y se anota en el commit; no improvises conexiones nuevas.

## Criterios de aceptación

1. `grep -n "WIN_SCORE" scripts/game.gd` no devuelve nada.
2. `grep -n "died" scripts/*.gd scenes/*.tscn` no devuelve nada.
3. Batería completa en verde (los tres cambios son sustracción pura).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/test_runner.tscn
```

Últimas líneas esperadas: `SMOKE OK - todas las mecánicas funcionan` y
`RESULT: ALL PASSED (16)`.
