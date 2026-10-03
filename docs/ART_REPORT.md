# Informe del Track B — arte (B0–B6)

> Ejecutado el 2026-09-06 en la rama `claude/track-b-inicio-f9d616`.
> Estado final: **`QA: 50/50 OK`** (`py -3 tools/img_pipeline.py --qa godot/art/sprites --strict`).
> Track A (código) no ha sido tocado: el contrato es solo dejar los PNG en
> `godot/art/sprites/` con las claves del `sprite_registry`.

## 1. Qué se ha entregado

| Tarea | Entregable | Estado |
|---|---|---|
| B0 | `tools/img_pipeline.py` (magenta→alfa, autocrop, escala, QA) + `art_raw/` + `godot/art/sprites/` | OK — `--selftest` → `QA: 1/1 OK` |
| B1 | Nacho, 16 poses `player_{pose}_p1.png` | OK — 16/16 |
| B2 | Rodrigo, 16 poses `player_{pose}_p2.png` | OK — 16/16 |
| B3 | 5 `weapon_*.png` | OK — 5/5; `dagger 55 < rapier 90 < longsword 120` px |
| B4 | `tile_floor`, `tile_wall`, `pit_edge`, `bg_layer0`, `bg_layer1` + `bg_title` copiado | OK — 6/6; bgs 960×540 opacos |
| B5 | `arrow_neutral`, `pip_hollow`, `pip_filled`, `blood_0..2` | OK — 6/6, blanco/gris neutro tintable |
| B6 | `worm_body` + `art_raw/contact_sheet.png` + este informe | OK |

Extra del B0 no pedido pero necesario para reproducir el lote:
**`tools/art_gen.py`** — tabla completa de prompts + driver de `bl` + selección de
variante + QA. Regenerar todo el arte es `py -3 tools/art_gen.py --group all`.

## 2. Cómo se ha hecho

- Servicio primario **`bl` 1.18.2 / `wan2.7-image`** (no hizo falta ningún fallback).
- 2 variantes por archivo (`--n 2`), post-proceso de ambas y elección automática por
  puntuación: primero las que pasan QA, desempate por cercanía del ratio del recorte al
  del manifiesto. No se usó `bl vision describe` (el criterio geométrico + revisión
  visual de la hoja de contacto bastó); el flag `--vision` queda implementado por si
  hace falta.
- **≈140 generaciones** en total (50 archivos × 2 variantes + regeneraciones + sondas).
  El coste en euros no se pudo leer: `bl usage` exige `bl auth login --console`, que es
  un OAuth interactivo no disponible en esta sesión. Comprobable en la consola de
  DashScope.

## 3. Desviaciones respecto a `docs/ART_PROMPTS.md` (todas justificadas y verificadas)

1. **Remuestreo `NEAREST` → `BOX` (area-average).** El manual pide NEAREST, pero los
   downscales son de ~28× (1580 px → 55 px): el muestreo puntual caía sobre las filas
   del contorno negro y el filo de las armas salía **completamente negro**. Con BOX el
   sprite se lee bien. Comparativa en `art_raw/tmp/resample_cmp.png`. `nearest` y
   `lanczos` siguen disponibles vía `--resample`.
2. **Se escala por UNA dimensión, no por las dos.** Forzar `W×H` deformaba los sprites
   (una daga de recorte 2.4:1 aplastada a 7.9:1). Es además lo que dice el propio §7
   del manual (`--height 56` *o* `--width` para armas/bg): manda la dimensión mayor del
   manifiesto y la otra sale del arte, y el QA comprueba que cae dentro de ±20%.
3. **Prompts de armas: cláusula de silueta fina.** Con el prompt literal el modelo
   dibujaba guardas gruesas (ratio 6.5:1 frente al 12:1 que pide el manifiesto). Se
   añadió *"at least 11 times longer than it is tall, hair-thin profile, no wide
   pommel"* y lienzo `2048*512` para florete y espada larga.
4. **Prompts de HUD: `{STYLE}` sustituido por un estilo de icono.** Con el `{STYLE}`
   completo (*"game sprite, side view, full body… like Nidhogg 2"*) los `pip_*` salieron
   como **guerreros de cuerpo entero**, no como cuadraditos de UI. Se usa
   `STYLE_UI` (*"flat pixel art UI icon, no characters, no people…"*) + *"strictly
   monochrome"* para que el tintado por `modulate` funcione. El manual ya hacía esta
   misma excepción para los tiles.
5. **Prompts de personaje: cláusula de encuadre.** Sin ella la hoja del arma se salía
   del lienzo y el sprite quedaba cortado. Se añadió *"whole body and whole weapon
   completely inside the frame with wide empty margins, nothing cropped"*. Resultado:
   0 sprites cortados en 32.
6. **Flags de `bl` adaptados** (el manual lo autoriza): `--size` usa `W*H`, no `WxH`; se
   añade `--prompt-extend false` para que la reescritura del prompt no se coma el
   contrato del fondo magenta; `--n 2` genera las dos variantes en una sola llamada.
7. **Hoja de contacto en Python en vez de ffmpeg.** `img_pipeline.contact_sheet()` pinta
   fondo ajedrez + nombre + banda verde/roja con el QA de cada archivo — cumple mejor el
   "fondo ajedrez" de `plan_diseño_enparalelo.md` y sirve de QA visual de un vistazo.

## 4. Corrección de recuento del manifiesto

Los documentos hablan de **53** assets; los archivos únicos reales son **50** (+1
opcional `stomp_burst`, no generado). El desfase es aritmético en la documentación, no
un entregable que falte:

- `plan_diseño_enparalelo.md` y `EXECUTION_PLAN.md` dicen "17 poses por personaje", pero
  la lista que dan y la tabla de `ART_PROMPTS.md` §2 tienen **16** (`idle`, `run_0..3`,
  `jump`, `fall`, `crouch`, `slide`, `divekick`, `attack_high/mid/low`, `throw`,
  `downed`, `dead`). → −2 archivos.
- `bg_title` se cuenta dos veces: en el grupo "Escenario (6)" y en el "HUD/UI (7)".
  → −1 archivo.

32 personajes + 5 armas + 5 escenario + 6 HUD + 1 `bg_title` + 1 gusano = **50**.
`tools/img_pipeline.py` usa 50 como manifiesto y `--qa --strict` falla si falta alguno.

## 5. Incidencias resueltas durante la ejecución

| Problema | Causa | Solución |
|---|---|---|
| `bl` no arrancaba desde Python (`WinError 2`) | en Windows `bl` es un shim `.cmd`; `CreateProcess` no lo resuelve sin extensión | `shutil.which("bl")` en `art_gen.BL`. No se gastó ninguna generación en el intento fallido |
| El recorte devolvía el lienzo entero | el degradado del generador deja algún píxel suelto que sobrevive al keying | `content_bbox()` erosiona la máscara (`MinFilter`) antes del bbox |
| Sprites cortados sin que el QA lo viera | tras recortar y escalar ya no hay lienzo que comparar | `edges_touched()` marca "cortado por el marco" durante el post-proceso |
| Distorsión invisible para el QA | se escalaba al tamaño exacto, así que el ratio final siempre cuadraba | se compara el ratio del **recorte** con el del manifiesto |
| `pip_hollow` / `pip_filled` eran personajes | ver desviación 4 | prompts de UI |
| Flecha y gusano oscilaron (demasiado gruesos → demasiado finos) | proporción numérica + lienzo extremo se pasaron de frenada | 2ª regeneración con proporción intermedia y lienzo `wide`/`long` |
| `player_divekick_p2` no leía como patada en picado | pose ambigua del generador | regenerado (`art_raw/tmp/divekick_cmp.png`: antes/después) |

## 6. Calidad: lo que un humano debería mirar

Ningún archivo falla el QA automático, pero estas cosas son de criterio y quedan
anotadas para el gate E10:

- **`tile_floor`** salió en tono arena/piedra clara, no en el gris apagado del prompt.
  Es losa de piedra y tilea, pero si el escenario pide más gris, una regeneración lo
  arregla.
- **Ligera variación de tono** del azul de Nacho y del naranja de Rodrigo entre poses
  (inevitable generando pose a pose). Se nota poco a 56 px; si molesta, se puede
  cuantizar la paleta en el pipeline.
- **`player_run_0_p2`** aparece sin arma visible, mientras el resto de poses la llevan.
- **`player_downed_p2`** arrastra una franja oscura de suelo bajo el cuerpo.
- Los sprites de personaje **llevan el arma dibujada**, tal y como piden los
  descriptores de pose del manual, a la vez que existen los `weapon_*.png` sueltos.
  Decidir en E10 cómo se combinan es cosa del Track A.

## 7. Reproducir / retocar

```bash
py -3 tools/img_pipeline.py --selftest                      # smoke test de B0
py -3 tools/img_pipeline.py --qa godot/art/sprites --strict # QA global -> 50/50 OK
py -3 tools/art_gen.py --group all --only-missing           # generar lo que falte
py -3 tools/art_gen.py --key player_idle_p1 --variants 2    # rehacer un archivo
py -3 tools/art_gen.py --group weapons --reuse-raw          # reprocesar sin pagar
```

`art_raw/` (material bruto, ~120 PNG de 1–2 MP) está en `.gitignore` salvo
`contact_sheet.png` y `report.json`. Los logs de cada lote están en
`art_raw/log_b3456.txt` y `art_raw/log_chars.txt`.
