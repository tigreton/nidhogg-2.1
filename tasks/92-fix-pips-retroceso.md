# Tarea 92 — Fix: los pips de conquista se inflan retrocediendo

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** 25 aplicada
(bug de la revisión post-fusión online, 2026-10-04)

## Objetivo

En el modo pantallas, `_cross_section` suma +1 conquista en CUALQUIER cruce
de reja, también hacia atrás: un corredor que retrocede y vuelve a avanzar
infla `sect_conquered` y el HUD marca secciones conquistadas fantasma.
Pasar a semántica de PROGRESO MÁXIMO: solo el avance hacia la meta del
portador actualiza la marca (y el mensaje/sfx van con el avance).

## Contexto del proyecto (leer antes de tocar nada)

- `_cross_section(sec)`: la primera línea calcula `dir`, la segunda fija
  `section_index = sec`, la tercera hace el `+= 1` incondicional y luego
  `show_msg`/`sfx` también incondicionales.
- `section_index` arranca en 3 (centro) cada ronda. El portador P1 corre a
  la derecha (`goal_dir > 0`): su avance es `sec - 3`; P2 a la izquierda:
  `3 - sec`. Rango útil 0–3.
- `_update_pips` pinta `sect_conquered[0] >= k - 3` (derecha) y
  `sect_conquered[1] >= 3 - k` (izquierda): la semántica de progreso máximo
  encaja sin tocar nada del HUD.
- El smoke test cruza la reja hacia delante y asienta
  `sect_conquered[0] == 1` (avance 3→4→…): con progreso máximo sigue
  valiendo 1. No hay caso de cruce hacia atrás en el smoke.
- Si el portador muere, el paso cambia de dueño: cada equipo acumula SU
  propio progreso; el máximo por equipo es lo correcto (no se resta).

## Instrucciones paso a paso

### 1. En `_cross_section`, condicionar conquista, mensaje y sonido

Busca el arranque de `_cross_section`:

```gdscript
	var dir := 1 if sec > section_index else -1
	section_index = sec
	sect_conquered[_team(right_of_way)] += 1
	show_msg("¡SECCIÓN CONQUISTADA!", 0.9)
	sfx(right_of_way.position, "point", -14.0)
```

y sustitúyelo por:

```gdscript
	var dir := 1 if sec > section_index else -1
	section_index = sec
	# solo el AVANCE hacia la meta conquista: retroceder no infla los pips
	var prog := (sec - 3) if right_of_way.goal_dir > 0 else (3 - sec)
	if prog > sect_conquered[_team(right_of_way)]:
		sect_conquered[_team(right_of_way)] = prog
		show_msg("¡SECCIÓN CONQUISTADA!", 0.9)
		sfx(right_of_way.position, "point", -14.0)
```

El resto de la función (teleports de entrada/fondo y el pan de cámara) se
queda igual: un cruce hacia atrás también recoloca cámara y jugadores.

## Qué NO hacer

- No cambies `section_index` ni la lógica de rejas (`_update_sections`):
  solo se toca el conteo de conquista.
- No resetees el progreso del otro equipo al cambiar el portador: los pips
  de cada equipo son acumulados de suya.
- No toques `_update_pips` (la semántica `>=` ya pinta el progreso máximo).

## Criterios de aceptación

1. Modo pantallas: cruza una reja hacia delante → pip conquistado y mensaje.
2. Vuelve hacia atrás y avanza de nuevo por la MISMA reja → el número de
   pips NO sube (antes subía con cada cruce).
3. Gana el paso el rival: sus avances pintan SUS pips sin borrar los del
   otro equipo.
4. El caso del smoke "Pantallas: P1 conquistó la sección 5" sigue pasando.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
