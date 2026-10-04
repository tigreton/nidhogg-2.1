# Índice de multimedia — importado de "Nidhogg 2"

**Origen:** `C:\Users\tigreton\Documents\zcode\Nidhogg 2`
**Destino:** este proyecto (`Nidhogg 2.1`)
**Fecha de importación:** 2026-10-01
**Total importado:** 7 975 archivos multimedia (≈ 758 MB: imágenes, audio y vídeo) + 58 ficheros `.import` de Godot + los scripts del pipeline, informes, logs, CSV de análisis y documentación de arte (ver §9).

## Estructura creada

```
Nidhogg 2.1/
├── art/                  ← LISTO PARA USAR EN GODOT (res://art/...)
│   ├── sprites/ (50 png + 50 .import)
│   └── sfx/ (8 wav + 8 .import)
├── art_raw/ (265)        ← material bruto de generación (oculto para Godot con .gdignore)
│   └── + report.json, report_chars.json, log_b3456.txt, log_chars.txt, tmp/prompt_idle*.txt
├── media/ (7 653)        ← vídeos, fotogramas extraídos, capturas y hojas de personaje (.gdignore)
│   └── videos/ + analyze_blobs.py, detect_transitions.py, tracker.py y *_blobs.csv
├── docs/ (7)             ← documentación del arte, del análisis multimedia y del netcode
└── tools/ (2)            ← scripts del pipeline de generación de arte
```

- `art/` equivale a `godot/art/` del proyecto origen. Al estar en la raíz del proyecto, las rutas Godot son `res://art/sprites/xxx.png` y `res://art/sfx/xxx.wav`.
- `art_raw/` y `media/` llevan un fichero `.gdignore`: Godot los ignora (no importa 7 900 imágenes ni genera `.import`). Si necesitas algo de ahí en el juego, cópialo a `art/`.

## Convenciones de nombres del pipeline original

En `art_raw/` cada elemento tiene dos variantes generadas (`_001`, `_002`) y su recorte procesado en `proc/` (`_v1`, `_v2`). El fichero definitivo en `art/sprites/` se derivó de una de ellas (columna "origen" abajo, según `report.json` / `report_chars.json` del origen).

---

## 1. Personajes (art/sprites/) — P1 "Nacho" y P2 "Rodrigo"

P1 = jugador 1, azul (túnica azul, gafas, pelo castaño). P2 = jugador 2, rojo/naranja (rubio). 16 poses cada uno; todos miran a la derecha.

| Pose | Elemento del juego | P1 (px) | P2 (px) | Origen (art_raw) |
|---|---|---|---|---|
| `player_idle` | parado / respirando | 66×56 | 45×56 | `nacho/…_001` · `rodrigo/…_001` |
| `player_run_0` | carrera, fase 1 | 56×56 | 45×56 | `…_001` |
| `player_run_1` | carrera, fase 2 | 61×56 | 50×56 | `…_001` |
| `player_run_2` | carrera, fase 3 (zancada amplia) | 86×56 | 51×56 | `…_001` |
| `player_run_3` | carrera, fase 4 | 54×56 | 36×56 | `…_001` |
| `player_jump` | salto | 35×56 | 31×56 | `…_001` |
| `player_fall` | caída | 68×56 | 43×56 | `…_001` |
| `player_crouch` | agachado | 44×40 | 36×40 | `…_001` |
| `player_slide` | deslizamiento por el suelo | 88×30 | 59×30 | `…_001` |
| `player_attack_high` | estocada alta | 45×56 | 45×56 | `…_001` |
| `player_attack_mid` | estocada media | 84×56 | 83×56 | `…_001` |
| `player_attack_low` | estocada baja | 60×44 | 55×44 | `…_001` |
| `player_throw` | lanzar el arma | 61×56 | 55×56 | `…_001` |
| `player_divekick` | patada voladora (salto + ataque) | 58×48 | 44×48 | `…_001` |
| `player_dead` | muerto (tumbado, fin de ronda) | 112×28 | 93×28 | `…_001` |
| `player_downed` | derribado/noqueado en el suelo | 124×30 | 68×30 | `…_001` |

Materia bruto correspondiente: `art_raw/nacho/` (P1) y `art_raw/rodrigo/`, 32 archivos cada uno (16 poses × 2 variantes) + 32 en `proc/`.

## 2. Armas (art/sprites/)

| Fichero | Elemento | Tamaño | Origen |
|---|---|---|---|
| `weapon_arrow.png` | flecha (proyectil del arco) | 28×6 | `weapons/weapon_arrow_001` |
| `weapon_bow.png` | arco | 38×70 | `weapons/weapon_bow_001` |
| `weapon_dagger.png` | daga | 55×8 | `weapons/dagger_001` |
| `weapon_longsword.png` | espada larga / montante | 120×9 | `weapons/weapon_longsword_002` (v2) |
| `weapon_rapier.png` | florete | 90×9 | `weapons/weapon_rapier_001` |

Materia bruto: `art_raw/weapons/` (12 + 10 en `proc/`).

## 3. HUD (art/sprites/)

| Fichero | Elemento | Tamaño | Origen |
|---|---|---|---|
| `arrow_neutral.png` | flecha indicadora de meta/dirección del HUD | 64×42 | `hud/arrow_neutral_002` |
| `pip_filled.png` | contador de rondas — punto lleno | 26×26 | `hud/pip_filled_001` |
| `pip_hollow.png` | contador de rondas — punto vacío | 26×26 | `hud/pip_hollow_001` |
| `blood_0.png` | salpicadura de sangre pequeña | 24×24 | `hud/blood_0_002` |
| `blood_1.png` | salpicadura de sangre mediana | 40×24 | `hud/blood_1_002` |
| `blood_2.png` | salpicadura de sangre grande | 64×36 | `hud/blood_2_001` |

Materia bruto: `art_raw/hud/` (12 + 12 en `proc/`). Vista previa del HUD montado: `art_raw/tmp/hudview/` (13 png con cada elemento sobre fondo oscuro).

## 4. Escenario y criatura (art/sprites/)

| Fichero | Elemento | Tamaño | Origen |
|---|---|---|---|
| `bg_layer0.png` | fondo capa 0 (lejana, 960×540) — parallax | 960×540 | `scenery/bg_layer0_001` |
| `bg_layer1.png` | fondo capa 1 (media, 960×540) — parallax | 960×540 | `scenery/bg_layer1_001` |
| `bg_title.png` | fondo de la pantalla de título | 960×540 | derivado de `media/personajes/duelo_versus.png` |
| `tile_floor.png` | tile de suelo | 48×48 | `scenery/tile_floor_001` |
| `tile_wall.png` | tile de muro | 48×48 | `scenery/tile_wall_001` |
| `pit_edge.png` | borde/esquina del foso | 48×47 | `scenery/pit_edge_002` |
| `worm_body.png` | cuerpo del gusano Nidhogg (verde, segmentado) | 300×103 | `worm/worm_body_002` |

Materia bruto: `art_raw/scenery/` (10 + 10 en `proc/`) y `art_raw/worm/` (2 + 2).

## 5. Efectos de sonido (art/sfx/)

| Fichero | Evento de juego |
|---|---|
| `attack_swipe.wav` | golpe/mandoble de ataque |
| `clash.wav` | choque de armas (parada) |
| `jump.wav` | salto |
| `throw.wav` | lanzamiento del arma |
| `arrow_bounce.wav` | flecha clavada/rebotando |
| `kill.wav` | muerte del rival |
| `stomp.wav` | pisotón/salto sobre el rival |
| `fight.wav` | anuncio de inicio de combate |

## 6. art_raw/ — resto del material bruto

- `contact_sheet.png` — hoja de contactos con **todos** los sprites finales a la vez (vista general rápida; es lo único de art_raw versionado en git).
- `hud/`, `nacho/`, `rodrigo/`, `scenery/`, `weapons/`, `worm/` — variantes crudas 1024–2048 px y recortes `proc/` (descritos arriba).
- `tmp/` — material de trabajo del pipeline: comparativas de reescalado (`cmp_box/lanczos/nearest`, `resample_cmp`), pruebas de idle (`test_idle*_00*`), hojas intermedias (`sheet_p1/p2/hud/wip`), vistas de zoom (`idle_zoom`, `ls_extreme`, `divekick_cmp`, `divekick_p2_antes`), dagas alternativas (`dagger_thin/wide`, `weapon_dagger`) y prompts de texto usados para generar.

## 7. media/ — referencia

### media/personajes/ (3 hojas grandes)
- `nacho_hoja.png` (3,9 MB) — hoja de referencia del personaje P1 "Nacho".
- `rodrigo_hoja.png` (4,8 MB) — hoja de referencia del P2 "Rodrigo".
- `duelo_versus.png` (5,9 MB) — ilustración de duelo; **origen del `bg_title.png`** del juego.

### media/screenshots/ (7 capturas de referencia, ~3 MB)
`01_castillo_daga_vs_espada`, `02_arquero_arco_tensado`, `03_florete_estocada_baja`, `04_gusano_nidhogg_victoria`, `05_salto_ataque_aereo`, `06_daga_guardia_alta`, `07_salon_florete_hud_progreso` — cada nombre describe la escena capturada (referencias visuales de estilo).

### media/videos/ (4 vídeos, ~296 MB)
- `nidhogg2_launch_trailer_1080p.mp4` (53 MB) + `nidhogg2_launch_trailer_esrb_1080p.mp4` (53 MB) — tráilers de lanzamiento (referencia).
- `gp_longplay_360p.mp4` (77 MB) — longplay de gameplay.
- `gp_2p_flesh_360p.mp4` (113 MB) — partida 2 jugadores, nivel "flesh".
- `thumb_trailer.jpg` / `thumb_trailer_esrb.jpg` — miniaturas de los tráilers.

### media/videos/frames/ (7 636 fotogramas JPG extraídos)
| Carpeta | Nº | Contenido |
|---|---|---|
| `flesh60/` | 3 600 | fotogramas numerados del gameplay "flesh" (60 fps) |
| `castle30/` | 2 700 | fotogramas del nivel castillo (30 fps) |
| `scan/` | 1 115 | barrido del tráiler/gameplay para análisis |
| `dive39/` | 150 | secuencia de divekick (39 fotogramas clave) |
| `flesh_scan/` | 32 | barrido del gameplay "flesh" |
| `sheets/` | 13 | hojas de contacto generadas de los fotogramas |
| `tiles/` | 5 | fotogramas recortados de tiles de escenario |
| `clone/` | 11 | fotogramas del clon (comparación contra el original) |
| *(raíz)* | 10 | fotogramas sueltos con nombre descriptivo: `frame_broadsword_invierno_t57s`, `frame_club_hud_t72s/t75s`, `frame_customizacion_t27s`, `frame_fight_banner_t31s`, `frame_volcano_hud_t7s`, `compare_real_vs_clone`, `real_castle_mid`, `sheet_launch_trailer(_esrb)` — extraídos en marcas de tiempo concretas (t##s = segundo) |

## 8. Estado de integración en Nidhogg 2.1 (tareas 53–60 y 62 aplicadas)

Los 58 `.import` viajan junto a sus png/wav (conservan los UID originales y su
`source_file` apunta a `res://art/...`); Godot solo regenera la caché de
`.godot/imported/`. El ciclo de carrera son 4 fases (`run_0 → … → run_3`) y
los sprites de P1/P2 existen por separado (azul/rojo; `flip` solo para
invertir orientación).

**Ya integrado en el juego:**

- **SFX (53):** los 8 WAV suenan — `clash`, `swing`←attack_swipe, `throw`,
  `kill`, `jump`, `hit`←stomp, más los eventos nuevos `fight` (cartel
  ¡FIGHT!) y `arrow_bounce` (rebote/clavado de flecha). `respawn`, `pickup`,
  `point`, `alert` y `crash` siguen sintetizados (no hay WAV para ellos).
- **Título (54):** `bg_title.png` de fondo y previsualización con los sprites
  idle de P1/P2. Las teclas de aspecto Z/X/N/M se retiraron.
- **HUD (55):** `pip_filled/pip_hollow` en los pips de secciones,
  `arrow_neutral` en las flechas de meta y `blood_0/1/2` como salpicaduras
  sobre los charcos.
- **Armas sueltas (56):** `weapon_rapier/longsword/dagger/bow` en el arma
  caída y lanzada, `weapon_arrow` en la flecha y `weapon_bow` en el arco en
  mano (cuerda animada procedural).
- **Desarmado (61):** 18 sprites nuevos `player_{pose}_noarme_{p1,p2}`
  (idle, run_0–3, jump, fall, crouch, throw) generados con
  `qwen-image-edit-plus` — al ir sin espada o con el arco el renderer usa la
  variante desarmada. Logs en `art_raw/log_noarme.txt` y
  `art_raw/report_noarme.json`.
- **Escenario (57/58):** `tile_floor/tile_wall` en suelos, plataformas y
  muros (teñidos con la paleta de cada arena), `pit_edge` en los bordes de
  foso, y `bg_layer0/1` como parallax con tinte por arena.
- **Gusano (59):** `worm_body` por regiones; mandíbulas y ojos procedurales.
- **Personajes (60):** las 32 poses en juego — P1 Nacho (azul), P2 Rodrigo
  (rojo), P3/P4 y bots reutilizan sprites con tinte; el cadáver usa
  `player_dead`. La customización de piel/peinado (antigua tarea 38) se
  retiró al adoptar diseños fijos.

**Pendiente / sin usar:**

- `player_{slide}`: espera la tarea 45 del porteo (slide tackle).
- `player_{throw}`: reservado (P2 inconsistente: desarmado frente a P1
  armado); candidato a regeneración.
- **Poses desarmadas (tarea 61): EN ESPERA** — requiere el CLI `bl`
  (Bailian) del pipeline `tools/`. Mientras tanto, el desarmado y el arco se
  muestran con la espada horneada de la pose (fallback aceptado).
- Música y fuente tipográfica: siguen procedurales (no hay assets).
- Nota de ajuste (62): el sprite rojo queda ~2 px hundido respecto al azul;
  tolerable. Si molesta: `POSE_Y_FIX` en `player.gd` (mapa por pose).

## 9. Documentación, scripts e informes del pipeline multimedia

### docs/ — documentación (proveniente del proyecto origen, salvo el netcode)
| Fichero | Contenido |
|---|---|
| `docs/ART_PROMPTS.md` | **Manual de assets (Track B)**: manifiesto de los 50 sprites con los prompts exactos de generación, comandos, modo manual, post-proceso y QA. |
| `docs/ART_REPORT.md` | Informe post-ejecución del Track B: QA 50/50 OK, ~140 generaciones, desviaciones. |
| `docs/PERSONAJES.md` | Fichas de diseño de Nacho (P1 azul) y Rodrigo (P2 rojo), ligado a `media/personajes/`. |
| `docs/VIDEO_ANALYSIS.md` | Análisis de los tráilers: hallazgos visuales (HUD, sangre por jugador, armas lanzadas) e inventario de fotogramas. |
| `docs/RESEARCH.md` | Investigación de mecánicas del juego a partir del análisis visual de las capturas y tráilers de `media/`. |
| `docs/plan_diseño_enparalelo.md` | Plan de trabajo en paralelo CÓDIGO ‖ ARTE (workers, contrato de desacople, externalización del arte). |
| `docs/online-netcode.md` | Documentación del 1v1 online (rama `online-multiplayer`, fusionada en main): arquitectura ENet host-autoridad, snapshots y predicción. |

### tools/ — scripts del pipeline de arte
| Fichero | Función |
|---|---|
| `tools/art_gen.py` | Generación de arte (Track B) que produjo `art_raw/`. |
| `tools/img_pipeline.py` | Post-proceso: recorte, escalado y QA de los sprites; genera `art_raw/report.json` y `report_chars.json` (la fuente de las tablas de §1–§4 de este índice). |

### media/videos/ — herramientas de análisis de vídeo
- `analyze_blobs.py`, `detect_transitions.py`, `tracker.py` — análisis de los mp4 (blobs, transiciones, seguimiento). Su salida son los `castle30_blobs.csv`, `dive39_blobs.csv` y `flesh60_blobs.csv` que les acompañan.

### art_raw/ — informes, logs y prompts
- `report.json` + `report_chars.json` — mapa autoritativo sprite → origen → recorte → tamaño final (versionado en git, igual que en el origen).
- `log_b3456.txt` + `log_chars.txt` — logs de ejecución de la generación.
- `tmp/prompt_idle.txt`, `tmp/prompt_idle2.txt` — prompts usados en las pruebas de idle.

### Qué se quedó en el proyecto origen
- `docs/PLAN.md`, `docs/PLAN_CREACION_RAMAS.md`, `docs/EXECUTION_PLAN.md`, `docs/FINAL_REPORT.md` — planificación general y Track A (código) del proyecto original, sin relación con el multimedia.
- `tools/godot/*.exe` — binarios del editor Godot 4.3 (≈100 MB, ajenos al arte).
