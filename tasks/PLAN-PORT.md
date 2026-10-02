# Plan de porteo técnico desde el proyecto hermano "Nidhogg 2"

Las tareas **41–52** portan a ESTE repo lo que el proyecto hermano
(`C:\Users\tigreton\Documents\zcode\Nidhogg 2`) tiene de único en lo técnico.
Su gameplay fue **calibrado contra vídeo real de Nidhogg 2** (saltos medidos en
alturas de personaje, cámara de pantalla completa por sección) y su suite de
tests es determinista (física frame a frame). Este plan traslada esas ideas
respetando las convenciones de aquí: monolito `game.gd` + `player.gd`, arte y
sonido 100 % procedurales, tareas atómicas ejecutables por un LLM básico.

## Qué se porta y qué no

| Se porta (tareas) | Origen en el hermano |
|---|---|
| Trazas de movimiento CSV (41) | `tests/trace_motion.gd` |
| Runner de suites deterministas (42) | `tests/test_runner.gd` + suites |
| Salto doble parado/carrerilla + gravedad asimétrica (43) | `GameConfig.JUMP_VY_STAND/-615`, `GRAVITY/GRAVITY_FALL` |
| Aceleración y fricción de suelo (44) | `GROUND_ACCEL 2800 / FRICTION 5200 / AIR_ACCEL 1500` |
| Slide tackle: atacar rodando derriba (45) | `states/slide.gd` (slide tackle) |
| Sidekick desde agachado (46) | `states/crouch.gd:50` (adaptado: aquí el slot agachado+salto lo ocupa la rodada) |
| Parada blanda por alturas + rebote en guardia (47) | `attack.gd::_parry` (PARRY_IMPULSE 160 / 0.15 s) y `weapon_area.gd` (CLASH_IMPULSE 130 / cooldown 0.3) |
| Arco: tensado completo, apuntar tensando, máx. 6 rebotes (48) | `bow_draw.gd` (BOW_DRAW_TIME 1.0, no dispara antes) + `arrow.gd` (ARROW_MAX_BOUNCES 6) |
| Lanzamiento desviado por las alturas que mata del arma (49) | `thrown_weapon.gd` (desvía si la estancia ∈ thrown_kills) |
| Cámara por secciones: 1 sección = 1 pantalla + pan 0,28 s (50) | `match_manager.gd` (CAMERA_ZOOM 4:3, CAMERA_PAN 0.28 QUAD/OUT) — aquí solo en modo pantallas (P) |
| Simulación bot vs bot de partida completa (51) | `tests/sim_match.gd` (semilla fija, stats mínimas) |
| Capturas coreografiadas de combate (52) | `tests/capture_action.gd` (FIGHT, kill, pan) |

**No se porta** (decisión del porteo): la arquitectura de máquina de estados
(aquí el monolito funciona y el smoke test depende de los índices del enum),
la media y documentación de referencia, música/SFX sintéticos propios, y todo
lo que este repo ya tiene (dive, estocada, guardia pasiva, stomp, ciclo de
armas, modos, mando, empalamiento de cadáveres, hitstop, cámara lenta).

> **Actualización (2026-10-01):** los sprites/arte PNG y su pipeline SÍ se
> integran ahora en este repo (tareas **53–62**, mapa completo y decisiones
> en `PLAN-ARTE.md`); la exclusión original queda supersada. El audio también
> adopta los WAV reales donde existe correspondencia (tarea 53).

## Mapa de valores hermano → aquí

| Concepto | Hermano (referencia) | Aquí (tras las tareas) |
|---|---|---|
| Salto parado | −445 → ápice ≈ 1,1·altura (62 px) | −460 → ápice ≈ 66 px (jugador mide 58) |
| Salto con carrerilla | −615 → ápice ≈ 2,1·altura (118 px) | −680 → ápice ≈ 144 px (= el actual, para no romper la arena) |
| Gravedad subida/bajada | 1600 / 1900, caída máx 980 | igual |
| Acel./freno/control aéreo | 2800 / 5200 / 1500 px/s² | igual |
| Parada (ataque vs guardia igual altura) | impulso 160 px/s durante 0,15 s, sin stun ni desarme | igual |
| Rebote contra guardia (cuerpo) | impulso 130, 0,12 s, cooldown 0,3 s | igual |
| Arco | tensado mínimo 1,0 s obligatorio, flecha 600 px/s fija, 6 rebotes máx. | igual |
| Pan de cámara entre secciones | 0,28 s TRANS_QUAD EASE_OUT, sin teleport | igual (solo modo pantallas) |

## Orden de ejecución

```
41 (trazas) → 42 (runner) → 43 → 44        ← infra primero, luego movimiento
→ 45, 46, 47, 48, 49 (combate, de una en una; actualizan suites de 42)
→ 50 (cámara por secciones) → 51 (sim bot vs bot) → 52 (capturas)
```

- **41 y 42 no tocan el juego**: solo añaden herramientas en `test/`.
- **43 y 44 son las únicas que cambian la física global**; el resto no depende
  de sus valores, pero 44 asume que 43 ya está aplicada (misma línea de
  gravedad/salto).
- **45–49 tocan todas el bloque de input/combate**: aplícalas de una en una,
  ejecutando el smoke y el runner entre medias (misma regla que 27–35).
- **51 al final del combate**: valida el juego recalibrado de punta a punta.

## Conflictos entre estas tareas (y con las viejas)

| Tareas | Conflicto y qué hacer |
|---|---|
| `43` y `44` | Las dos reescriben la física de `player.gd` (salto/gravedad y velocidad horizontal). Aplica 43 antes que 44; 44 ya está escrita contando con las constantes de 43. |
| `43`/`44` y `42` | Las suites de 42 assertan la física ANTERIOR a propósito (línea base). 43 y 44 incluyen los números nuevos que deben quedar en las suites. |
| `43` y smoke `1/19/22-24/34/35` | El salto parado pasa de ~144 px a ~66 px de ápice. Si un caso de alturas falla, la 43 trae una sección de contingencia (ajustar solo esa plataforma ≤30 px o usar carrerilla). |
| `47` y smoke caso 3 | La parada blanda sustituye al choque con stun en ataque-vs-guardia. La 47 reescribe ese caso del smoke (código incluido). |
| `48` y smoke caso 18 | El tensado pasa a mín. 1,0 s; la 18 cambia sus dos esperas de 0,4 s a 1,1 s (código incluido en la tarea). |
| `45`, `46` y `12/34/35` | Las tres añaden ramas al mismo bloque de input de `player.gd`. La 46 inserta su rama ANTES de la rodada; revisa el diff tras cada una. |
| `47` y `31` | La guardia pasiva (31) sigue matando a distinta estancia; la rama de misma estancia pasa de choque con stun a rebote mínimo (47). Componen. |
| `49` y `24` | La 49 generaliza el desvío del arma lanzada (24 solo desviaba con guardia MEDIA). El caso 10 del smoke sigue pasando (el florete mata a las tres alturas → toda guardia desvía). |
| `50` y `25/26` | La 50 usa `sections_mode`/`section_index` de 25 sin tocar rejas ni pips. Solo cambio de cámara en ese modo. |
| `50` y 2v2 | `set_mode_2v2` fija `camera.zoom`; con pantallas activo debe respetarlo: la 50 incluye el guard. |
| `52` y `50` | La captura del pan de sección (52) necesita la cámara de 50. Aplica 50 antes. |

## Verificación por tarea

Comando común (desde la raíz del proyecto):

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

- 41: además `--headless --path . res://test/trace_motion.tscn` → `TRAZAS OK`.
- 42: además `--headless --path . res://test/test_runner.tscn` → `RESULT: ALL PASSED (n)`.
- 43/44: además el runner y las trazas (números objetivo en cada tarea).
- 51: además `--headless --path . res://test/sim_match.tscn` → `SIM PASS`.
- 52: `--path . res://test/screenshots.tscn` (CON render) → `CAPTURAS OK`.
