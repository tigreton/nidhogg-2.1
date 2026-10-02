# Tarea 52 — Capturas coreografiadas de combate

**Dificultad:** baja · **Archivos:** `test/screenshots.gd` · **Prerrequisitos:** 50 aplicada (la captura del pan necesita la cámara por secciones)

## Objetivo

Portar las capturas de acciones del proyecto hermano al recorrido existente
(`test/screenshots.gd`): además de las zonas del mapa, fotografiar tres
momentos coreografiados — el banner **¡FIGHT!**, una **muerte con estallido**
(con la cámara lenta congelada a medias) y el **pan de sección** del modo
pantallas. Material de revisión visual rápida tras las tareas 43–50.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `test/screenshots.gd` — recorrido existente que acaba con:

```gdscript
	game.set_arena(0)

	print("CAPTURAS OK")
	get_tree().quit(0)
```

  Helpers disponibles: `_snap(name)` (espera `frame_post_draw` y guarda PNG
  en `res://screens`), `_place(px)` (coloca a los duelistas simétricos a
  y=531). `game` es la instancia de `main.tscn`.
- `game.gd` — `_show_fight()` anima el banner; `_kill(def, atk)` mata con
  estallido + hitstop (pausa 0,08 s; los timers `create_timer(t, true)`
  siguen funcionando en pausa) + cámara lenta (`Engine.time_scale = 0.35`
  durante 0,5 s reales, restaurada por un timer que también la devuelve a
  1,0). El modo pantallas está en `set_sections(true)` y el cruce de sección
  lo dispara `_update_sections()` cuando el portador del paso (`right_of_way`)
  cambia de sección.
- Se ejecuta CON render (sin `--headless`).
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en
  español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Añadir las tres capturas

En `test/screenshots.gd`, sustituye el final del recorrido:

```gdscript
	game.set_arena(0)

	print("CAPTURAS OK")
	get_tree().quit(0)
```

por:

```gdscript
	game.set_arena(0)

	# banner ¡FIGHT!
	_place(1600.0)
	game._show_fight()
	await get_tree().create_timer(0.25).timeout
	await _snap("13_fight_banner.png")

	# muerte con estallido (cámara lenta: restaurar el tiempo tras capturar)
	_place(1600.0)
	game.players[0].facing = 1
	game.players[1].position = game.players[0].position + Vector2(70.0, 0.0)
	await get_tree().create_timer(0.1).timeout
	game._kill(game.players[1], game.players[0])
	await get_tree().create_timer(0.05, true).timeout
	await _snap("14_muerte_estallido.png")
	Engine.time_scale = 1.0
	game.respawn_timers[1] = 0.0
	game.players[1].revive(Vector2(2000.0, 531.0), -1)
	await get_tree().create_timer(0.2).timeout

	# modo pantallas: pan de cámara al cruzar la reja (tarea 50)
	game.set_sections(true)
	await get_tree().create_timer(0.3).timeout
	game.right_of_way = game.players[0]
	game.players[0].position = Vector2(2800.0, 531.0)
	await get_tree().create_timer(0.15).timeout
	await _snap("15_pan_seccion.png")
	await get_tree().create_timer(0.4).timeout
	await _snap("16_seccion_conquistada.png")
	game.set_sections(false)
	await get_tree().create_timer(0.2).timeout

	print("CAPTURAS OK")
	get_tree().quit(0)
```

Notas:
- `create_timer(0.05, true)` es always-process: avanza aunque el hitstop
  pause el árbol (queremos fotografiar el estallido congelado).
- Tras `_kill` el juego queda 0,5 s en cámara lenta; restauramos
  `Engine.time_scale` a mano (el timer interno también lo hará: es idempotente).
- El cruce se fuerza colocando al portador en x=2800 (sección 4; arranca en
  la 3): `_update_sections` hace el pan de 0,28 s y la captura de 0,15 s cae
  a mitad del recorrido.

### 2. Ejecutar CON render

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --path . res://test/screenshots.tscn
```

Última línea esperada: `CAPTURAS OK`. Comprueba en `screens/`:
- `13_fight_banner.png`: el ¡FIGHT! grande centrado sobre los duelistas.
- `14_muerte_estallido.png`: P2 desintegrándose en partículas de su color
  (P1 intacto a su izquierda).
- `15_pan_seccion.png`: la cámara a mitad de camino entre dos secciones (se
  ven las dos a medias).
- `16_seccion_conquistada.png`: la sección nueva encuadrada completa con su
  reja en el borde y el cartel de conquista.

## Qué NO hacer

- No ejecutes este recorrido con `--headless` (no hay framebuffer que
  capturar; para headless ya están el smoke, el runner y el sim).
- No dejes `Engine.time_scale` distinto de 1,0 al salir (restáuralo tras la
  captura de la muerte, como en el código de arriba).
- No toques las capturas existentes (01–12) ni `_snap`/`_place`.

## Criterios de aceptación

1. El recorrido termina en `CAPTURAS OK` y genera `13_`…`16_` en `screens/`.
2. En `14` se ve el estallido de partículas (no un frame vacío).
3. En `15` la cámara está entre secciones (pan a medias, sin corte).
4. El smoke test sigue pasando.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --path . res://test/screenshots.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Últimas líneas esperadas: `CAPTURAS OK` y `SMOKE OK - todas las mecánicas funcionan`.

## Nota de aplicación (2026-10-03, sin la tarea 50 aplicada)

Aplicada con dos ajustes mínimos para cumplir los criterios de aceptación con
el código actual:

1. **Estallido (14):** con `create_timer(0.05, true)` la captura cae en mitad
   del hitstop (0,08 s) y las partículas (PAUSABLE) aún no han simulado: se
   veía el cadáver pero no el estallido. El timer pasa a **0,25 s escalados**:
   tras el hitstop y dentro de la cámara lenta, con el estallido a medias
   (verificado por visión y por píxeles: ~2 000 px cian dispersos frente a
   ~1 300 del cadáver solo).
2. **Conquista (15/16):** el `round_lock` (~1,4 s) que deja el `_kill` de la
   coreografía anterior hace que `_update_sections` salga pronto y nunca
   cruce sección (sin "¡SECCIÓN CONQUISTADA!"). Se añade
   `game.round_lock = 0.0` antes de forzar el cruce.

**Pendiente hasta aplicar la 50:** sin cámara por secciones no hay pan de
0,28 s, así que la 15 muestra el encuadre entre las dos rejas (cámara ya
asentada), no el barrido a medias. Re-ejecutar este recorrido tras la 50.
