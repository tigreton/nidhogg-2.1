# Tareas del proyecto Nidhogg-like

Cada archivo de esta carpeta es una **tarea atómica e independiente**: está pensada
para lanzarse suelta a un LLM básico como único objetivo, sin conocimiento previo
del proyecto (cada tarea duplica el contexto necesario).

## Cómo lanzar una tarea a un LLM básico

Copia esta plantilla como prompt y sustituye el nombre del archivo:

```
Trabajas en el proyecto Godot 4.6 que está en la carpeta
C:\Users\tigreton\Documents\zcode\Nidhogg 2.1

1. Lee el archivo tasks/<nombre-de-la-tarea>.md completo.
2. Ejecuta la tarea EXACTAMENTE como está escrita, paso a paso, sin cambios creativos.
3. No modifiques archivos que la tarea no mencione.
4. Al terminar, ejecuta el comando de verificación que indica la tarea y comprueba
   que la última línea es: SMOKE OK - todas las mecánicas funcionan
5. Si el código real no encaja con lo que describe un paso, DETENTE y explica la
   discrepancia. No improvises.
```

Reglas de oro para ti (el humano que supervisa):

- **Una tarea = un commit.** Así si una sale mal, se revierte sola.
- Verifica siempre el test headless antes de aceptar el resultado.
- Las tareas son independientes, pero algunas **tocan el mismo código** (ver tabla
  de conflictos abajo): si aplicas dos que se pisan, revisa el diff con cuidado.

## Índice de tareas

| Archivo | Tarea | Dificultad | Archivos que toca |
|---|---|---|---|
| `01-ia-bot.md` | Bot jugable para P2 (combate + correr a la meta) | alta | `player.gd`, `game.gd` |
| `02-ia-bot-dificultad.md` | Tres niveles de dificultad del bot | baja | `game.gd` |
| `03-arena-hierba-alta.md` | Hierba alta que oculta la estancia | baja | `game.gd`, `player.gd` |
| `04-arena-plataformas.md` | Escalera de plataformas (verticalidad) | baja | `game.gd` |
| `05-arena-segundo-foso.md` | Segundo foso sin plataforma | media | `game.gd` |
| `06-feel-hitstop.md` | Hit-stop (congelar unos frames al matar) | baja | `game.gd` |
| `07-feel-camara-lenta.md` | Cámara lenta al matar y al anotar | baja | `game.gd`, `test` |
| `08-feel-indicador-meta.md` | Aviso "¡CORRE!" con dirección de meta | baja | `game.gd` |
| `09-feel-marcador-paso.md` | Halo bajo los pies de quien tiene el paso | baja | `player.gd` |
| `10-feel-polvo.md` | Polvo al aterrizar y al correr | baja | `player.gd` |
| `11-feel-musica.md` | Música procedural en bucle | media | nuevo `music.gd`, `game.gd` |
| `12-mov-rodar.md` | Rodar (esquiva rápida agachado + salto) | media | `player.gd` |
| `13-mov-punetazo.md` | Puñetazo cuando estás desarmado | media | `player.gd`, `game.gd` |
| `14-test-ampliar.md` | Ampliar el smoke test (5 casos nuevos) | media | `test/smoke_test.gd` |
| `15-rob-pausa.md` | Pausa con ESC | baja | `game.gd` |
| `16-rob-gamepad.md` | Soporte de mando (2 gamepads) | baja | `game.gd` |
| `17-fix-espada-foso.md` | La espada desviada sobre el foso cae en el borde | baja | `game.gd` |
| `18-mov-estocada.md` | Estocada al atacar corriendo | media | `player.gd` |
| `19-mov-desarme.md` | El choque desarma al que ataca en alto | media | `game.gd` |
| `20-mov-tajo-aereo.md` | Tajo de espada en el aire (elegir altura) | baja | `player.gd` |
| `21-ia-bot-vs-bot.md` | Modo bot vs bot con la tecla N | baja | `game.gd` |
| `22-stats-partido.md` | Estadísticas en la pantalla de victoria | baja | `game.gd` |
| `23-armas-ciclo.md` | Armas con ciclo de muerte (florete, espadón, daga) | alta | nuevo `game_config.gd`, `player.gd`, `game.gd`, `pickup.gd`, `sword_projectile.gd`, `test` |
| `24-arco-flechas.md` | Arco: tensar y soltar flechas que rebotan | alta | nuevo `arrow.gd`, `game_config.gd`, `player.gd`, `game.gd`, `test` |
| `25-secciones-rejas.md` | Modo pantallas: 7 secciones con rejas (tecla P) | alta | `game.gd`, `test` |
| `26-hud-pips.md` | HUD Nidhogg 2: pips, barra de respawn, ¡FIGHT! | media | `game.gd`, `test` |
| `27-stomp-letal.md` | Stomp letal sobre el rival derribado | baja | `game.gd`, `test` |
| `28-desarmado-completo.md` | Puñetazo que desarma, patada baja, carrera rápida | media | `player.gd`, `game.gd`, `test` |
| `29-sangre-persistente.md` | Charcos de sangre persistentes que gotean | media | `game.gd`, `test` |
| `30-cadaver-empalamiento.md` | Cadáver persistente que sale despedido y empala | media | `game.gd`, `test` |
| `31-guardia-pasiva.md` | Guardia pasiva: correr contra el arma es morir | media | `game.gd`, `test` |
| `32-estela-arma-lanzada.md` | Estela del arma lanzada | baja | `sword_projectile.gd`, `test` |
| `33-gusano-victoria.md` | Gusano gigante de victoria | media | `game.gd`, `test` |
| `34-dive-horizontal.md` | Dive horizontal (abajo + salto corriendo) | media | `player.gd`, `game.gd`, `test` |
| `35-sidekick.md` | Sidekick: patada lateral que derriba y desarma | media | `player.gd`, `game.gd`, `test` |
| `36-arcade-1p.md` | Modo arcade: escalera de bots con tecla Y | media | `game.gd`, `test` |
| `37-titulo-reglas.md` | Pantalla de título + reglas configurables | media | nuevos `match_rules.gd`, `title.gd`, `title.tscn`; `project.godot`, `game.gd`, `player.gd` |
| `38-customizacion.md` | Customización de personajes (pelo y piel) | media | `match_rules.gd`, `player.gd`, `title.gd` |
| `39-copa.md` | Modo Copa: semis contra bots y final (tecla O) | media | `game.gd`, `test` |
| `40-tercera-arena.md` | Tercera arena "Cripta del Ocaso" | media | `game.gd`, `test` |
| `41-infra-trazas-movimiento.md` | Trazas de movimiento CSV (calibración de física) | baja | nuevos `test/trace_motion.*` |
| `42-infra-test-runner.md` | Runner de suites deterministas + 2 suites base | media | nuevos `test/test_runner.*`, `test/suite_*.gd` |
| `43-mov-salto-doble.md` | Salto parado/carrerilla + gravedad asimétrica (porteo) | media | `player.gd`, `test/suite_movimiento.gd` |
| `44-mov-aceleracion-friccion.md` | Aceleración y fricción de suelo (porteo) | media | `player.gd`, `test/suite_movimiento.gd`, `test/smoke_test.gd` |
| `45-mov-slide-tackle.md` | Slide tackle: atacar rodando derriba (porteo) | media | `player.gd`, `game.gd`, `test` |
| `46-mov-sidekick-agachado.md` | Sidekick desde agachado con la rodada en cooldown (porteo) | baja | `player.gd`, `test` |
| `47-combate-parada-rebote.md` | Parada blanda por alturas + rebote en guardia (porteo) | media | `player.gd`, `game.gd`, `test` |
| `48-arco-tensado-completo.md` | Arco: tensado mínimo 1 s, velocidad fija y máx. 6 rebotes (porteo) | media | `player.gd`, `game.gd`, `test` |
| `49-lanzar-por-alturas.md` | Lanzamiento desviado por las alturas que mata + arco lanzable (porteo) | media | `game.gd`, `game_config.gd`, `test` |
| `50-camara-secciones.md` | Cámara 1 sección = 1 pantalla + pan 0,28 s en modo P (porteo) | media | `game.gd`, `test` |
| `51-infra-sim-match.md` | Simulación de partida completa bot vs bot (porteo) | media | nuevos `test/sim_match.*` |
| `52-capturas-acciones.md` | Capturas coreografiadas: FIGHT, muerte, pan de sección | baja | `test/screenshots.gd` |
| `53-sfx-reales.md` | SFX reales: WAVs de art/sfx + eventos fight y arrow_bounce | baja | `sfx.gd`, `game.gd` |
| `54-titulo-arte.md` | Título con bg_title y preview con sprites | baja | `title.gd` |
| `55-hud-sprites.md` | HUD con sprites: pips, flecha de meta, salpicaduras | baja | `game.gd` |
| `56-armas-sprites.md` | Armas sueltas con sprites (suelo, lanzada, flecha, arco) | baja | `pickup.gd`, `sword_projectile.gd`, `arrow.gd`, `player.gd` |
| `57-tiles-suelo.md` | Suelos y muros con tiles + bordes de foso | media | `game.gd` |
| `58-fondos-parallax.md` | Fondos parallax bg_layer0/1 con tinte por arena | media | `game.gd` |
| `59-gusano-sprite.md` | Gusano de victoria con worm_body | baja | `game.gd` |
| `60-personajes-sprites.md` | Personajes con sprites (retira la customización de 38) | alta | `player.gd`, `game.gd`, `match_rules.gd`, `title.gd` |
| `61-desarmado-hueco.md` | Genera las 14 poses desarmadas que faltan y las enchufa | media | pipeline `tools/` + `player.gd` |
| `62-ajuste-capturas.md` | Ajuste fino visual con capturas y cierre del track arte | media | `player.gd`, `game.gd`, `test/screenshots.gd`, `INDICE-MULTIMEDIA.md` |
| `63-musica-generada.md` | Bucle de música real con fallback procedural | baja | `music.gd`, `game.gd`, nuevo `art/music/` — **EN ESPERA** (falta asset; `bl` no genera música) |
| `64-fuente-pixel.md` | Fuente pixel opcional para título y HUD | baja | `title.gd`, `game.gd`, nuevo `art/fonts/` — **EN ESPERA** (falta fuente con licencia abierta) |

Las tareas 41–52 portan lo único técnico del proyecto hermano
(`Nidhogg 2`): visión de conjunto, mapa de valores y orden en
**`PLAN-PORT.md`**. Las tareas 53–62 integran el arte y sonido reales
importados del hermano a `res://art/` (50 sprites + 8 WAV): mapa completo
asset→código, decisiones y lista de lo que no encaja en **`PLAN-ARTE.md`**.
Las ideas que aún no son tareas formales viven en `secundarias.md`, junto con
la guía para convertirlas en tareas con este mismo formato.

## Orden recomendado

Aunque son independientes, si vas a hacer varias, este orden minimiza fricción:

1. Primero las que solo añaden (`06`, `07`, `08`, `09`, `10`, `15`, `16`, `17`).
2. Luego arena (`03`, `04`, `05`) y movilidad (`12`, `13`).
3. Después `14` (el test ampliado vigila que nada se rompa en lo sucesivo).
4. Al final `01` → `02` (bot) y `11` (música), que son las más grandes.
5. `18`–`20` (movilidad) van bien justo después de `12`/`13`; `21` después de
   `01`; `22` en cualquier momento.
6. Para acercarse al Nidhogg 2 original: `23` → `24` (armas) y `25` → `26`
   (secciones con rejas y su HUD).
7. Combate nuevo, de una en una porque tocan el mismo bloque de input:
   `27`, `28`, `34` → `35`.
8. Gore y presentación: `29`, `30`, `33` en cualquier orden; `32` y `40` cuando
   quieras.
9. `31` (guardia pasiva) al final del combate, probando el equilibrio con el
   bot (incluye su ajuste).
10. Estructura: `37` → `38` (título y customización) y `36` → `39` (arcade y
    copa).
11. Porteo del proyecto hermano (41–52): infra primero (`41` → `42`), luego
    física (`43` → `44`), combate de una en una (`45`…`49`), presentación
    (`50` → `52`, con `51` tras el combate). Detalle completo en
    `PLAN-PORT.md`.
12. Integración del arte importado (53–62): `53` → `54` → `55` → `56` son
    independientes y de bajo riesgo; luego `57` → `58` → `59` (escenario);
    al final `60` → `61` → `62` (personajes, hueco desarmado y ajuste).
    Idealmente con el porteo 41–52 ya aplicado (la 45 trae el estado slide
    que usa `player_slide`). Detalle completo en `PLAN-ARTE.md`.

## Conflictos conocidos (por tocar el mismo código)

| Tareas | Conflicto y qué hacer |
|---|---|
| `01` y `02` | `02` reescribe parte de lo que añade `01`. Aplica `01` antes que `02`. |
| `05` y `17` | Las dos modifican la gestión de fosos en `_drop_sword`. Si aplicas ambas, unifica el helper `_in_any_pit`. |
| `06` y `15` | Las dos usan `get_tree().paused`. Si aplicas ambas, acepta que pulsar ESC durante el hit-stop lo corta (o protege el toggle con una variable). |
| `06` y `07` | Las dos actúan en `_kill`. Son compatibles, pero revisa juntas el resultado. |
| `12` y `13` | Las dos tocan el bloque de ataque en `player.gd`. Aplica una, prueba, y luego la otra. |
| `03` y `09` | El halo del corredor de `09` sigue viéndose dentro de la hierba de `03` (aceptable, o envuélvelo también). |
| `12`, `13`, `18` y `20` | Las cuatro tocan el bloque de input de ataque en `player.gd`. Cada una está escrita para el código base: aplícalas de una en una y revisa el diff entre medias. |
| `01` y `21` | `21` necesita el bot de `01` (activar ambos con N). |
| `19` y `13` | Sinergia (no conflicto): el desarme de `19` crea los duelos a puñetazo que arma `13`. Aplicables en cualquier orden. |
| `23` y `24` | `24` extiende lo que añade `23` (`WEAPON_ORDER`, `WEAPONS`). Aplica `23` antes que `24`. |
| `23` y `28` | Las dos reescriben `_melee_hit`. Aplica `23` primero; la `28` ya está escrita para conservar la rama del espadón (ver su nota en el paso 3). |
| `24`, `28` y `31` | Las tres tocan la resolución de guardias/choques. La `28` cambia `if d == h:`, la `24` añade el arco a esa misma línea (con nota de composición) y la `31` excluye el arco de la guardia pasiva. Aplícalas de una en una revisando el diff. |
| `25` y `26` | `26` necesita `sections_mode`/`sect_conquered` de `25`. Aplica `25` antes. |
| `27`, `30` y `29` | Las tres enganchan cosas en `_kill`. Sus anclas son distintas (`_burst` de color, `sfx("kill")`) y componen sin pisarse; revisa el diff igualmente. |
| `33`, `36` y `39` | Las tres insertan dentro de la rama de fin de partido de `_point`. Están escritas como inserciones y componen en cualquier orden, pero revisa el `if/return` final. |
| `34`, `35`, `28` y `12/13/18/20` | Todas tocan el bloque de input de ataque en `player.gd`. Aplícalas de una en una y revisa el diff entre medias. |
| `37` y `12`/`34` | `37` añade `MatchRules.allow_roll` a la condición de la rodada; si `34` ya cambió esa línea (dive), el paso 5.3 de `37` lo indica. |
| `36` y `39` | `39` necesita `set_arcade` y la tecla Y de `36`. Aplica `36` antes. |
| `37` y `38` | `38` necesita `MatchRules` y `title.gd` de `37`. Aplica `37` antes. |
| `43` y `44` | Las dos reescriben la física de `player.gd` (vertical y horizontal). Aplica `43` antes que `44`; la `44` está escrita contando con las constantes de la `43`. |
| `42` y `43`/`44` | Las suites de `42` assertan la física anterior a propósito (línea base). `43` y `44` incluyen los números nuevos que deben quedar en las suites (marcados `# L43`/`# L44`). |
| `47` y smoke caso 3 | La parada blanda sustituye al choque con stun cuando solo uno ataca. La `47` reescribe el caso 3 del smoke (código incluido). |
| `48` y smoke caso 18 | El tensado pasa a mín. 1,0 s; el caso 18 cambia sus dos esperas de 0,4 s a 1,1 s (código incluido en la `48`). |
| `45`, `46` y `12`/`34`/`35` | Todas añaden ramas al mismo bloque de input de `player.gd`. La `46` inserta su rama ANTES de la rodada; revisa el diff tras cada una. |
| `47` y `31` | La guardia pasiva sigue matando a distinta estancia; la rama de misma estancia pasa de choque con stun a rebote mínimo. Componen. |
| `49` y `24` | La `49` generaliza el desvío del arma lanzada (la `24` solo desviaba con guardia media). El caso 10 del smoke sigue pasando sin cambios. |
| `50` y `25`/`26` | La `50` usa `sections_mode`/`section_index` de la `25` sin tocar rejas ni pips: solo cambia la cámara en ese modo. |
| `50` y `V` (2v2) | `set_mode_2v2` fija `camera.zoom`; la `50` añade el guard para respetar el zoom de sección con P activo. |
| `52` y `50` | La captura del pan de sección (`52`) necesita la cámara de la `50`. Aplica `50` antes. |
| `54` y `60` | Las dos tocan `title.gd` (preview y teclas de aspecto). Aplica `54` antes; la `60` solo limpia `match_rules.gd`. |
| `56` y `60` | Las dos tocan `player.gd`. La `56` reescribe `_draw_bow`; la `60` reescribe `_draw` conservándolo. Aplica `56` antes. |
| `57` y `58` | Las dos añaden helpers y tocan `_build_level`/`set_arena`. Componen; revisa el diff si van seguidas. |
| `60` y `38` | La `60` retira la customización que añadió la `38` (los sprites son diseños fijos; decisión de `PLAN-ARTE.md`). |
| `60` y `43`/`44` | El ritmo del ciclo `run_0..3` depende de `run_phase`, que `43`/`44` recalibran. Aplica el porteo antes de la `60`, o re-tuna el factor de ciclo (lo revisa la `62`). |
| `61` y pipeline | La `61` genera sprites con `tools/art_gen.py` y requiere el CLI `bl` (Bailian). Sin él, queda en espera con el fallback documentado. |

## Comando de verificación (común a todas las tareas)

Desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea debe ser `SMOKE OK - todas las mecánicas funcionan`.
