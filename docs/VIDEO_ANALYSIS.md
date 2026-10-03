# Análisis de los vídeos oficiales de Nidhogg 2

> Procesamiento propio del material descargado en `media/videos/`.
> Método: hojas de contactos (1 frame cada 5 s, cuadrícula 4×4, 16 frames por tráiler,
> ~78 s de duración) + 5 frames extraídos a resolución completa 1920×1080 en momentos
> clave. Los archivos generados están en `media/videos/frames/`.

## 0. Conclusión general sobre los dos tráilers

Los dos tráilers (`nidhogg2_launch_trailer_1080p.mp4` y
`nidhogg2_launch_trailer_esrb_1080p.mp4`) son **idénticos en contenido** (misma duración
1:18, mismos planos frame a frame al muestreo de 5 s). La única diferencia es la tarjeta
de clasificación por edades inicial:

- Versión normal: **ESRB TEEN — "Violence / Blood"**.
- Versión ESRB: **ESRB TEEN — "Violence / Blood and Gore / Crude Humor"**.

No hace falta conservar más que una de las dos para consulta de gameplay (se mantienen
ambas porque ya estaban descargadas).

## 1. Información mecánica nueva extraída del vídeo (no estaba en las fuentes de texto)

Estos hallazgos son **confirmaciones visuales directas** que afectan al diseño del clon:

1. **HUD de progreso: exactamente 7 cuadros** (t≈7 s: 3 rellenos amarillos + 4 huecos
   con borde rojo; t≈57 s: 5 huecos turquesa + 2 rellenos amarillos; t≈75,5 s: 4 huecos
   morados + 3 rellenos naranjas). Los cuadros **huecos se dibujan con el borde del color
   del defensor** y los **rellenos con el color del jugador que conquista**. La barra se
   lee como territorio: tus cuadros de origen quedan rellenos de tu color y avanzas
   hacia los huecos del rival.
2. **Flecha grande de derecho de avance**: aparece en la esquina superior en el **color
   del atacante** apuntando a su meta (t≈7 s: flecha amarilla → derecha; t≈75,5 s:
   flecha naranja → izquierda). Estilo dibujado a mano con trazo grueso.
3. **La sangre es del color de cada jugador y persiste/gotea**: t≈75,5 s muestra
   salpicaduras naranjas Y moradas escurriendo por los bordes de las plataformas en el
   mismo escenario. El escenario "recuerda" las muertes de ambos jugadores.
4. **Estado derribado + arma en el suelo**: t≈7 s, personaje naranja tumbado en el suelo
   junto a un florete turquesa caído — tras el kill, el arma del muerto queda en el suelo
   recogible.
5. **Arma lanzada en vuelo**: t≈57 s, una espada larga lanzada cruza la pantalla girando,
   con un **rastro/línea amarilla de trayectoria** detrás (trayectoria casi recta con
   leve arco). Es grande y se ve venir: confirma el rol de proyectil esquivable/parable.
6. **Pantalla de personalización "STYLISH THREADS"** (t≈27 s): personalización **por
   partes del cuerpo** (categorías visibles: HAIR, ACCESSORY, TORSO, LEGS) con una
   **paleta de ~7 colores por jugador** (selector con flechas laterales), etiquetas
   PLAYER 1 / PLAYER 2, botones SET RULES, QUIT y NEXT. Los 4 cuerpos base tienen
   siluetas distintas (pelo mohawk, calvo, melena, etc.).
7. **Pantalla de selección de mapa**: t≈31 s muestra una **isla-mundo** con todos los
   escenarios conviviendo (castillo, volcán, cristal de hielo, árbol del bosque,
   naufragio, nubes con arcoíris y barcos voladores) y el prompt **"START GAME"**
   (botón X de PlayStation). Menú tipo overworld, no lista plana.
8. **Cartel "FIGHT"**: en el muestreo de la hoja de contactos (frame del naufragio,
   t≈30–35 s) aparece un texto **"FIGHT"** sobre la escena — indicador de inicio de
   enfrentamiento. Dato útil para el clon: mostrar "¡FIGHT!" al comenzar cada duelo
   de sección (la investigación de texto decía que no hay cuenta atrás; el cartel
   existe como señal de arranque).
9. **Tarjetas de arma**: el tráiler presenta armas con tarjetas de texto grandes
   (**"RAPIER"** t≈50–55 s sobre un mástil de barco, **"BROADSWORD"** t≈57 s en la
   caverna de hielo). Son overlays de marketing, no UI in-game, pero confirman los
   sprites/silueta de cada arma.
10. **Mapas visibles en el tráiler** (9-10 de los 13): volcán nocturno con pilares de
    vértebras y suelo de lava (t≈5–10 s), nubes con arcoíris y el gusano Nidhogg volando
    (t≈10–15 s), castillo con lámparas y puertas (t≈15–20 s), club/dungeon morado con
    eyeballs por el suelo (t≈20–25 s), naufragio en playa (t≈30–35 s), caverna de hielo
    con cráneos en las plataformas (t≈55–60 s), bosque otoñal (Wilds, t≈40–45 s), mástil
    de barco (t≈50–55 s), interior verde tipo tren/oficina (t≈60–65 s), interior de
    nave/carnicería con ganchos de carne y ojos de buey (t≈75–78 s), pista de baile con
    focos (Club, final del tráiler).
11. **Elementos de escenario observados**: plataformas de cráneos decorados (Winter),
    pilares de costillas (Volcano/Nidhogg innards), ganchos y trozos de carne colgando
    (Airship), focos que siguen a los jugadores (Club), puertas de madera (Castle),
    rejas verticales en los bordes de sección (visibles en capturas y tráiler).

## 2. Inventario de los archivos generados (`media/videos/frames/`)

| Archivo | Qué es | Momento |
|---|---|---|
| `sheet_launch_trailer.png` | Hoja de contactos 4×4, 16 frames (1 cada 5 s) del tráiler normal | t = 0–78 s |
| `sheet_launch_trailer_esrb.png` | Idem del tráiler ESRB (idéntico salvo tarjeta inicial) | t = 0–78 s |
| `frame_volcano_hud_t7s.png` | Volcán nocturno: **HUD 7 cuadros (3 amarillos + 4 huecos rojos), flecha amarilla derecha**, naranja derribado con florete en el suelo, sangre amarilla | t = 7 s |
| `frame_customizacion_t27s.png` | Pantalla "STYLISH THREADS": personalización por partes (HAIR/ACCESSORY/TORSO/LEGS), paletas por jugador, SET RULES/QUIT/NEXT | t = 27 s |
| `frame_fight_banner_t31s.png` | Isla-mundo de selección de escenario con "START GAME" (el cartel FIGHT del naufragio queda registrado en la hoja de contactos) | t = 31 s |
| `frame_broadsword_invierno_t57s.png` | Tarjeta "BROADSWORD": **espada larga lanzada en vuelo con rastro**, HUD 5 huecos turquesa + 2 rellenos amarillos, plataforma de cráneos | t = 57 s |
| `frame_club_hud_t75s.png` | Interior carnicería/nave: **HUD 4 huecos morados + 3 rellenos naranjas, flecha naranja izquierda**, sangre naranja y morada goteando, arquero morado con arco vs esgrimista naranja | t = 75,5 s |

## 3. Lectura frame a frame de las hojas de contactos (resumen)

Ambas hojas son prácticamente iguales; orden de escenas del tráiler (índice de tile,
t≈índice×5 s):

0. Tarjeta ESRB (única diferencia entre versiones).
1. Volcán nocturno, duelista amarillo con florete salta entre pilares de vértebras sobre
   lava; naranja derribado; HUD amarillo/rojo.
2. Nubes al atardecer: el gusano Nidhogg rosa vuela con estela de arcoíris; flecha
   turquesa arriba a la izquierda.
3. Castillo: overlay de marketing "SOME COMBAT"; lámparas, puertas, público.
4. Club/dungeon morado: personajes morados, eyeballs en el suelo.
5. "STYLISH THREADS": personalización (ver §1.6).
6. Naufragio en la playa con cartel **"FIGHT"**; HUD turquesa + 1 naranja.
7. Caverna de hielo (Winter) con icono de espadas cruzadas y flecha naranja a la derecha;
   duelo bajo un cráneo gigante tallado.
8. Bosque otoñal (Wilds): HUD amarillo + flecha naranja a la izquierda; hierba alta.
9. Mástil de barco: tarjeta **"RAPIER"**; flecha naranja izquierda; HUD naranja.
10. Interior verde (Tren/Office): personaje verde deslizado/derribado en el suelo; HUD
    verde completo + flecha verde derecha.
11. Tarjeta **"BROADSWORD"** en caverna de hielo (ver §1.5).
12. Interior de Nidhogg (pilares de carne sobre lava) con flecha amarilla izquierda.
13. Transición de sangre (charco rojo/naranja a pantalla completa).
14-15. Club: pista de baile con focos siguiendo a los personajes, flechas naranja
    izquierda y derecha, duelos entre morado y naranja; HUD naranja/morado.

## 4. Impacto en el plan del clon (`docs/PLAN.md`)

- **HUD**: la fila pasa a diseñarse exactamente como el original: N cuadros (5 en
  nuestro caso), huecos con borde del color del defensor + rellenos del color del
  conquistador, flecha grande en la esquina superior en el color del atacante.
- **Sangre por jugador** persistente que gotea por los bordes: efecto barato en Godot
  (partículas + manchas PersistentDecoration) y de mucho "juice".
- **Cartel "FIGHT!"** al (re)iniciar cada duelo de sección: confirmado por el vídeo,
  lo añadimos al flujo.
- **Rastro de trayectoria** en armas lanzadas: línea corta del color del lanzador,
  ayuda a leer el proyectil.
- **Arma del muerto caída en el suelo** visible junto al cadáver (confirmado t≈7 s).
- El overworld/mapa-mundo y la personalización por partes **no entran** en el alcance
  v1 (ya estaba decidido); se registran como referencia de estilo para el menú.

## 3. Mediciones de movimiento (2026-09-07, gameplay 30 fps 360p)

Material: `gp_longplay_360p.mp4` (arcade completo, 18:35) y `gp_2p_flesh_360p.mp4`
(versus 2P con checkpoints, 23:47), descargados con yt-dlp (cliente mweb).
Herramientas: `tracker.py` (blobs por diferencia contra fondo mediano),
`analyze_blobs.py` (pistas + estadísticas), `detect_transitions.py` (pans por
correlación de columnas). Altura de personaje H ≈ 50 px a 360p.

Resultados clave (usados para recalibrar `game_config.gd`):

| Métrica | Real (medido) | Clon antes | Clon después |
|---|---|---|---|
| Correr | 3.6–5 H/s (mediana de pistas 150–270 px/s) | 4.6 H/s instantáneo | 4.6 H/s con rampa de ~6 frames |
| Salto de parado | ápice ~1 H, aire 0.3–0.5 s | 1.38 H, 0.73 s | 1.04 H, ~0.5 s |
| Salto con carrerilla | ápice ~2–2.5 H | igual al de parado | 2.0 H |
| Dive horizontal | dx 3–4 H, ~1 H de alto, ~2×correr, cae boca abajo | no existía | 0.49 H de alto, ~3.1–4.2 H, aterriza downed |
| Rodada/slide | ~0.35 s, ~1.5×correr | 0.4 s a 1.3× | 0.35 s a 1.54× |
| Pantallas | 7 (HUD de 7 cuadros) | 5 | 7 |
| Transición | pan rápido ~0.2–0.8 s, sin teleport | tween 0.4 s + reset de posiciones | pan 0.28 s, posiciones continuas |
| Encuadre | personaje ≈14–15 % de la altura de pantalla | ~10 % | zoom 4:3 → ~14 % |

Pans de cámara detectados en el versus 2P (t=40–160 s): ráfagas de 0.1–0.8 s
a 7–15 px/frame, siempre precedidas de kill del defensor o cruce por el borde
(consulta `detect_transitions.py`).

Capturas del clon con las acciones clave: `media/videos/frames/clone/cap_*.png`
(se regeneran con `tests/capture_action.gd`); comparación lado a lado con el
juego real en `media/videos/frames/compare_real_vs_clone.png`.
