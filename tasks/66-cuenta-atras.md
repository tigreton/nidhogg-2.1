# Tarea 66 — Cuenta atrás de ronda (3·2·1·¡FIGHT!)

**Dificultad:** baja · **Archivos:** `scripts/game.gd`, `test/smoke_test.gd`, `test/test_runner.gd`, `test/sim_match.gd`, `test/suite_*.gd` (una línea cada uno) · **Prerrequisitos:** ninguno

## Objetivo

Ritual de inicio como el original: cada ronda arranca con **3·2·1** (0,7 s por
número, jugadores congelados) y el **¡FIGHT!** existente al terminar. Los
tests headless quedan exentos con un flag para no multiplicar sus esperas.

## Contexto del proyecto (leer antes de tocar nada)

- `_start_round()` resetea el partido y termina llamando `_show_fight()`.
- Ya existe congelado por ronda: `_physics_process` fija
  `p.frozen = match_over or round_lock > 0.0` para todos los jugadores, y
  `round_lock` se descuenta con delta. **Reutilízalo**: no inventes otro
  mecanismo de pausa.
- `show_msg(texto, dur)` muestra texto grande centrado (76 px, fade).
- Los harnesses instancian `main.tscn` y esperan `create_timer(0.2)`
  (`smoke_test.gd:16`-ish, `test_runner.gd` `_ready`, `sim_match.gd` con 12
  physics frames). Sin flag, todos los casos que actúan tras el arranque
  morirían esperando la cuenta.
- Reglas de estilo: GDScript tipado, tabs, comentarios en español.

## Instrucciones paso a paso

### 1. Flag y constantes

Junto a `var round_lock := 0.0`:

```gdscript
var skip_countdown := false   # los tests headless lo ponen a true
const COUNTDOWN_STEP := 0.7
```

### 2. La cuenta en `_start_round`

Sustituye la última línea de `_start_round()` (`_show_fight()`) por:

```gdscript
	if skip_countdown:
		_show_fight()
	else:
		# 3·2·1 con los jugadores congelados (round_lock ya congela via frozen)
		round_lock = COUNTDOWN_STEP * 3.0
		for n in 3:
			show_msg("%d" % (3 - n), COUNTDOWN_STEP * 0.8)
			await get_tree().create_timer(COUNTDOWN_STEP).timeout
		_show_fight()
```

(`_start_round` ya es async-friendly: se llama sin await desde `_ready` y las
teclas de modo; el `await` interno solo retrasa el cartel, no el retorno a
quien la llamó, porque nadie espera su valor.)

### 3. Eximir los harnesses (una línea tras instanciar, en cada uno)

En `test/smoke_test.gd`, `test/test_runner.gd`, `test/sim_match.gd`, tras
`add_child(game)` y antes de su primera espera:

```gdscript
	game.skip_countdown = true
```

(En el runner y el sim, `game` es la variable que instancian en `_ready`.
Las suites `suite_*.gd` NO tocan nada: heredan el flag del runner.)

## Qué NO hacer

- No uses `get_tree().paused` (rompería el hitstop y la pausa de ESC).
- No toques `RESPAWN_DELAY` ni el respawn entre puntos de una MISMA ronda:
  la cuenta es SOLO al empezar ronda (tras `_start_round`), no tras cada
  muerte (eso ya tiene su propio `round_lock = 1.4`).
- No pongas el flag a true en el juego real: cuenta atrás por defecto.

## Criterios de aceptación

1. Al arrancar (y con R de revancha) se ve 3·2·1·¡FIGHT! y nadie se mueve
   hasta el FIGHT.
2. Los dos harnesses headless pasan sin tocar ninguna otra espera:
   `SMOKE OK`, `ALL PASSED`, `SIM PASS`.
3. El bot tampoco se mueve durante la cuenta (está `frozen` como todos).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/sim_match.tscn
```

Últimas líneas esperadas: `SMOKE OK - todas las mecánicas funcionan` y
`SIM PASS`.

## Nota de aplicación (2026-10-03)

Aplicada con una corrección de orden importante: el flag hay que asignarlo
ANTES de `add_child(game)` — el `_ready` del juego (y con él
`_start_round`) corre DENTRO del `add_child`, y con el flag después la
cuenta atrás arrancaba igualmente y congelaba los primeros 2,1 s de los
tests (el smoke fallaba los casos 1-2). Con el flag premultiplicado por
árbol: `SMOKE OK`, `ALL PASSED (13)` y `SIM PASS`.
