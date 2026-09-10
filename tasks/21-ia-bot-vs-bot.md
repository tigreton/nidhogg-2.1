# Tarea 21 — Modo bot vs bot (espectáculo)

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos: tarea 01 aplicada**

## Objetivo

Tecla **N** para poner los DOS duelistas como bots y verlos pelear: un modo
espectáculo que además sirve de prueba visual del cerebro del bot (tarea 01) —
si algo va mal en su lógica, aquí se ve en segundos sin jugar tú.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- Esta tarea asume que la **tarea 01 ya está aplicada**: `player.gd` tiene
  `is_bot` + `bot_held`, y `game.gd` tiene `_bot_think(p, delta)` (llamada para
  cada jugador con `is_bot`), la acción `"toggle_bot"` (tecla B, solo P2) y el
  HUD con `show_msg(texto, dur)`.
- El cerebro es simétrico: usa `_other(p)` y `p.goal_dir`, así que sirve igual
  para P1 (corre a la derecha) que para P2 (corre a la izquierda) sin cambios.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Acción de teclado

En `_setup_input()`, añade al diccionario `defs`:

```gdscript
	"bot_vs_bot": [KEY_N],
```

### 2. Toggle

En `_physics_process`, justo después del bloque de `"toggle_bot"`, añade:

```gdscript
	if Input.is_action_just_pressed("bot_vs_bot"):
		var on := not players[0].is_bot
		players[0].is_bot = on
		players[1].is_bot = on
		show_msg("BOT vs BOT %s" % ("ACTIVADO" if on else "DESACTIVADO"), 0.7)
```

### 3. Pista visual

En `_build_hud()`, en el texto del label `hint`, añade al final `    N: bot vs bot`.

## Qué NO hacer

- No toques `_bot_think` ni `player.gd`: el modo funciona porque el cerebro ya
  es simétrico.
- No desactives la cámara ni el HUD: ver la persecución completa es el punto.
- No hagas que N afecte solo a un jugador: enciende o apaga los DOS.

## Criterios de aceptación

1. N activa el modo: los dos duelistas luchan solos (se acercan, cubren,
   atacan, lanzan espadas a veces).
2. Cuando uno mata, corre hacia SU meta y el otro reaparece para frenarlo; los
   puntos suben hasta que alguien gana el partido.
3. R sigue funcionando: tras una revancha, los bots siguen peleando solos.
4. N de nuevo devuelve el control humano a ambos (y B sigue gobernando solo a
   P2 de forma independiente).
5. El smoke test sigue pasando (N nunca se pulsa allí).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`
(el modo se disfruta abriendo el juego con F5 y pulsando N).
