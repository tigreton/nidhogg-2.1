# Plan de integración del arte y sonido importados ("track arte")

Las tareas **53–62** sustituyen el arte y sonido 100 % procedurales de este repo
por los **58 assets reales** importados el 2026-10-01 desde el proyecto hermano
`Nidhogg 2` (ver `INDICE-MULTIMEDIA.md`): 50 sprites en `res://art/sprites/`
y 8 WAV en `res://art/sfx/`, ya con sus `.import` generados.

Este plan **supersede** la decisión de `PLAN-PORT.md` de "no portar los
sprites/arte PNG": el material ya está en el repo y aquí se describe cómo se
adopta. El resto de convenciones se mantiene: monolito `game.gd` + `player.gd`,
tareas atómicas ejecutables por un LLM básico, una tarea = un commit.

## Decisiones tomadas

1. **Reemplazo directo**, sin modo dual: los sprites sustituyen al dibujo
   procedural; el rollback es el historial git.
2. **La customización de la tarea 38 se retira**: los sprites son diseños
   fijos (P1 "Nacho" azul, P2 "Rodrigo" rojo). P3/P4 y bots reutilizan los
   sprites con tinte (`modulate`).
3. **Un solo juego de fondos parallax** (`bg_layer0/1`) para las 3 arenas,
   tiñido con la paleta de cada una (noche azulada / amanecer / ocaso).
4. **Siguen procedurales** lo que no tiene asset: los ids de sonido
   `respawn`, `pickup`, `point`, `alert`, `crash`; la música (`music.gd`);
   la fuente tipográfica; y el decorado menor (casa, antorchas, velas,
   lápidas, flores, nubes, colinas, rejas).

## Mapa asset → anclaje en el código

| Asset (res://art/) | Código actual que lo sustituye | Tarea |
|---|---|---|
| `sprites/player_{16 poses}_{p1,p2}.png` (32) | `player.gd:374-476` `_draw()` | 60 |
| `sprites/weapon_{rapier,longsword,dagger}.png` | `pickup.gd:19-28` (caída), `sword_projectile.gd:37-44` (lanzada). En mano NO: la espada va horneada en las poses | 56 |
| `sprites/weapon_bow.png` | `player.gd:479-490` `_draw_bow()` | 56 |
| `sprites/weapon_arrow.png` | `arrow.gd:22-29` `_draw()` | 56 |
| `sprites/pip_{filled,hollow}.png` | `game.gd:716-724` clase `Pip` | 55 |
| `sprites/arrow_neutral.png` | `game.gd:974-979` `_goal_zone` (triángulo de la meta) | 55 |
| `sprites/blood_{0,1,2}.png` | `game.gd:2063-2075` `_add_blood` + clase `BloodPool` | 55 |
| `sprites/tile_floor.png`, `tile_wall.png` | `game.gd:956-971` `_floor_segment`/`_wall`/`_platform` | 57 |
| `sprites/pit_edge.png` | bordes de foso (`game.gd:298-299`) | 57 |
| `sprites/bg_layer0/1.png` | no hay anclaje: infraestructura parallax nueva. Sustituye el cielo plano `game.gd:278` | 58 |
| `sprites/bg_title.png` | `title.gd:9-41` (ColorRect + Labels) | 54 |
| `sprites/worm_body.png` | `game.gd:609-639` clase `VictoryWorm` | 59 |
| `sfx/*.wav` (8) | `sfx.gd:18-53` `stream()` (síntesis) | 53 |

### Mapeo de sonidos (tarea 53)

| id del juego | WAV | Dónde suena hoy |
|---|---|---|
| `clash` | `clash.wav` | choque de armas, desvío de espada |
| `swing` | `attack_swipe.wav` | ataques, estocada, rodar, tensar arco |
| `throw` | `throw.wav` | desarmes, lanzar espada, disparar flecha |
| `kill` | `kill.wav` | muerte |
| `jump` | `jump.wav` | salto |
| `hit` | `stomp.wav` | impactos de cuerpo (patadas, divekick, stomp) |
| `fight` (nuevo evento) | `fight.wav` | cartel ¡FIGHT! (hoy mudo) |
| `arrow_bounce` (nuevo evento) | `arrow_bounce.wav` | rebote de flecha en guardia (hoy `clash`) |
| `respawn`, `pickup`, `point`, `alert`, `crash` | — | siguen sintetizados |

### Mapa estado → pose (tarea 60)

| Estado del enum | Sprite |
|---|---|
| IDLE | `idle` (estancia baja → `crouch`) |
| RUN | `run_0..run_3` en ciclo por `run_phase` (baja → `crouch`) |
| JUMP | `jump` subiendo / `fall` cayendo |
| DIVEKICK / DIVE | `divekick` (+ rotación del transform) |
| ATTACK | `attack_high` / `attack_mid` / `attack_low` según `attack_height` |
| KNOCKDOWN | `downed` (la pose ya está tumbada: sin rotación) |
| STUNNED | `idle` inclinado (transform) |
| ROLL | `jump` girando (transform, como hoy) |
| SIDEKICK | `crouch` + transform |
| DEAD | no se dibuja; el `Corpse` usa `dead` |
| SLIDE (tras tarea 45) | `slide` |

## Qué NO tiene cabida (y por qué)

1. **`media/` completo (7.652 archivos)** — vídeos, fotogramas extraídos,
   capturas y hojas de personaje: material de referencia/análisis, oculto con
   `.gdignore`. Nunca se referencia desde el juego. Ya consumido:
   `duelo_versus.png` → `bg_title.png`.
2. **`art_raw/` completo (265 archivos)** — variantes crudas, recortes
   `proc/` y QA del pipeline: materia prima para regenerar, no arte del juego.
3. **`player_slide_{p1,p2}.png`** — la mecánica slide tackle no existe en el
   código (tarea 45 del porteo, pendiente). Encajará al aplicarla.
4. **`player_throw_p2.png`** — inconsistente: P2 aparece desarmado en la
   suelta y P1 armado. No se usa en v1 (la 62 puede regenerarlo).
5. **`stomp.wav`, `fight.wav`, `arrow_bounce.wav`** — sus eventos no existen
   en el código: los crea la tarea 53 (mapeo stomp→`hit`, más los eventos
   nuevos `fight` y `arrow_bounce`).
6. **`bg_layer0/1.png`** — no hay parallax ni "capa de fondo" donde
   enchufarlos (lo crea la 58) y solo existe un juego para 3 arenas.
7. **Poses desarmadas / con arco** — NO existen y el juego las necesita
   (tras lanzar, tras desarme, con el arco equipado): las 32 poses llevan la
   espada horneada. Las genera la tarea 61 con el pipeline del repo.
8. **Customización de la tarea 38** (3 pieles × 3 peinados) — imposible sobre
   sprites fijos; la retira la tarea 60.
9. **Diferencia visual del arma en mano** — florete/espadón/daga comparten la
   espada horneada de la pose; los `weapon_*.png` solo se ven sueltos
   (suelo, vuelo, flecha, arco). No es un bug, es un límite del set.
10. **P3/P4 (2v2)** — sin sprites propios: reutilización con tinte.
    **Música y fuente** — sin assets importados: siguen procedurales.

## Orden de ejecución

```
53 (sfx) → 54 (título) → 55 (hud) → 56 (armas)     ← fases A–C, independientes
→ 57 (tiles) → 58 (fondos) → 59 (gusano)            ← fase D
→ 60 (personajes) → 61 (desarmado) → 62 (ajuste)    ← fases E–F
```

- 53–59 son independientes entre sí y del porteo 41–52: aplicables en
  cualquier orden (el smoke debe pasar tras cada una).
- **Recomendado aplicar 41–52 antes de la fase E**: la 45 crea el estado
  slide que usa `player_slide`; la 48 cambia el tensado del arco que pinta la
  56; 43/44 mueven la física que marca el ritmo del ciclo `run`.
- 60 después de 54/56 (comparten `title.gd`/`player.gd`); 61 requiere 60;
  62 cierra ajustando con capturas.

## Conflictos entre estas tareas (y con las pendientes)

| Tareas | Conflicto y qué hacer |
|---|---|
| `54` y `60` | Las dos tocan `title.gd` (preview y teclas de aspecto). Aplica 54 antes; la 60 solo limpia `match_rules.gd`. |
| `56` y `60` | Las dos tocan `player.gd`. La 56 reescribe `_draw_bow`; la 60 reescribe `_draw` conservando `_draw_bow`. Aplica 56 antes. |
| `57` y `58` | Las dos añaden helpers y tocan `_build_level`/`set_arena`. Componen (helpers distintos); revisa el diff si van seguidas. |
| `60` y `38` | La 60 retira la customización que añadió la 38 (decisión 2). |
| `60` y `43`/`44` | El ritmo del ciclo `run_0..3` depende de `run_phase`, que 43/44 recalibran. Si el porteo va después, re-tunea el factor de ciclo en la 60 (lo revisa la 62). |
| `58` y `50` | El parallax convive con la cámara por secciones (zoom fijo); sin acción, solo verificación visual en la 62. |
| `61` y pipeline | La 61 usa `tools/art_gen.py` + `tools/img_pipeline.py` y requiere el CLI `bl` (Bailian). Si no está disponible, la tarea queda en espera y el fallback es usar poses armadas. |

## Verificación por tarea

Comando común (desde la raíz del proyecto):

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

- Las tareas visuales (54, 55, 57, 58, 59, 60) añaden además una pasada con
  render: `--path . res://test/screenshots.tscn` → `CAPTURAS OK`, revisando
  las capturas generadas en `screens/`.
- La 62 es exclusivamente verificación y ajuste con capturas.

## Estado de aplicación (2026-10-03) y pendientes

**Aplicadas y commiteadas: 53–60 y 62.** El porteo hermano 41–52 también
está completo. Detalle del estado de integración de cada asset en la §8 de
`INDICE-MULTIMEDIA.md`.

Pendientes del track arte:

| Pendiente | Qué hace falta | Dónde retomarlo |
|---|---|---|
| Tarea 61 (poses desarmadas) | Instalar/configurar el CLI `bl` (Bailian) y correr el pipeline `tools/art_gen.py` + `tools/img_pipeline.py`. Mientras tanto, desarmado y arco se ven con la espada horneada | `tasks/61-desarmado-hueco.md` (EN ESPERA documentada) |
| `player_throw` sin uso | P2 sale desarmado y P1 armado (inconsistente): regenerar la pose | junto con la tanda de la 61 |
| Sprite rojo ~2 px hundido | Tolerable según la 62; si molesta, mapa `POSE_Y_FIX` por pose | `player.gd` |
| Música y fuente | Siguen procedurales: no existen assets para ellas | nueva tanda de generación (backlog) |

Notas de cierre:

- La captura `15_pan_seccion.png` ya muestra el pan real de sección desde
  que la 50 está aplicada (recorrido regenerado a las 01:40 junto a su
  commit).
- Si el recorrido de capturas se queda colgado, casi siempre es la ventana
  del juego minimizada/tapada (sin `frame_post_draw`): re-ejecutar sin
  minimizar.
