# Tarea 06 — Hit-stop al matar

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** ninguno

## Objetivo

Congelar el juego unas centésimas al producirse una muerte (el "hit-stop" de los
juegos de lucha): todo se detiene 0,08 s en el instante del impacto y luego sigue.
Transmite el peso del golpe.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/game.gd` — nodo principal. Las muertes se producen todas en
  `_kill(def: Player, atk: Player)` (aterrizajes, ataques, proyectiles y foso la
  llaman). Ya hay sacudida de cámara (`shake_time`) y ráfagas de partículas
  (`_burst`) dentro de `_kill`.
- Godot: `get_tree().paused = true` detiene los nodos con
  `PROCESS_MODE_PAUSABLE` (los jugadores lo son por defecto). Un
  `get_tree().create_timer(dur, true)` (con `process_always=true`) SIGUE
  funcionando con el juego pausado, así que sirve para despausar.
- El smoke test espera con `create_timer` (que sigue corriendo en pausa), y sus
  márgenes de espera (≥ 0,12 s) absorben una pausa de 0,08 s sin romperse.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Función de hit-stop

En `scripts/game.gd`, añade esta función (junto a `show_msg()` está bien):

```gdscript
func _hitstop(dur: float) -> void:
	if get_tree().paused:
		return
	get_tree().paused = true
	get_tree().create_timer(dur, true).timeout.connect(func(): get_tree().paused = false)
```

### 2. Llamarla al matar

En `_kill()`, justo después de la línea `def.die()` (la primera línea útil de la
función, antes de `respawn_timers[...]`), añade:

```gdscript
	_hitstop(0.08)
```

## Qué NO hacer

- No uses `Engine.time_scale` aquí (eso es cámara lenta, otra tarea).
- No pauses en choques (`_clash`) ni patadas: solo muertes.
- No alargues el hit-stop más de 0,1 s: se sentiría un cuelgue.

## Criterios de aceptación

1. Cada muerte congela la imagen un instante y luego todo sigue.
2. La doble muerte (trade) también lo provoca, sin quedarse pausado.
3. Tras el hit-stop el juego SIEMPRE se reanuda solo.
4. El smoke test sigue pasando (incluida la muerte del test 4 y la del foso si
   se añadió en otras tareas).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`
(el efecto se aprecia abriendo el juego con F5).
