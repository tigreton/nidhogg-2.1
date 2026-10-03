# Manual de assets — manifiesto, prompts y generación (Track B)

> Ejecutable por el agente O por cualquier persona/LLM externo con acceso a un
> generador de imágenes. No hace falta leer nada más del proyecto: este archivo es
> autocontenido. Destino final de TODO: `godot/art/sprites/<nombre>.png` (PNG RGBA,
> fondo transparente, dimensiones del manifiesto). Materiales brutos: `art_raw/`.

## 0. Cómo usar este manual (3 modos)

| Modo | Quién | Cómo |
|---|---|---|
| **A. bl (primario)** | agente con CLI `bl` | Comandos del §5 con los prompts de §2–§4. 2 variantes por archivo, elegir con §6. |
| **B. qwencloud (fallback)** | agente sin `bl` | Mismos prompts vía skill `qwencloud-image-generation` (`wan2.7-image`, referencia = URL/local). |
| **C. ChatGPT manual (fallback)** | tú | Pega en el chat el bloque `{PERSONAJE} + {POSE} + {STYLE} + {BG}` (o el prompt de arma/escenario tal cual), descarga el PNG como `art_raw/manual/<nombre>.png` y ejecuta el post-proceso del §7. |

En TODOS los modos el post-proceso (§7) es obligatorio: convierte el fondo magenta en
transparencia, recorta y escala al tamaño exacto. Sin post-proceso, el archivo NO cuenta
como entregado.

## 1. Reglas fijas

- **Bloque de estilo `{STYLE}`** (siempre al final, antes del fondo):
  `"pixel art game sprite, side view, full body, grotesque colorful cartoon style like Nidhogg 2, thick black outline, limited color palette, flat shading, crisp pixel edges"`
- **Bloque de fondo `{BG}`** (siempre la ÚLTIMA frase del prompt):
  `"solid pure magenta background #FF00FF, no other background elements, no text, no watermark, no border"`
- **Orientación**: TODOS los sprites de personaje y armas miran a la **DERECHA** (el
  código voltea con `scale.x = -1`). El gusano mira a la **IZQUIERDA**.
- **Tinta de color**: los sprites de personaje ya llevan sus colores (azul Nacho /
  rojo Rodrigo). `arrow_neutral`, `pip_*` y `blood_*` se generan en **blanco/gris
  claro NEUTRO** porque el código los tiñe con `modulate`.
- **Variantes**: 2 por archivo (`_v1`, `_v2`); si ambas fallan el QA, 1 regeneración
  más; si vuelve a fallar, se anota en el informe y el juego usa el placeholder.

## 2. Personajes — 34 archivos `player_{pose}_p{1|2}.png`

**Bloques de personaje** (referencia: `media/personajes/nacho_hoja.png` y
`media/personajes/rodrigo_hoja.png`; usarlos SIEMPRE como `--image` para mantener el
parecido):

- **{NACHO}** = `"Nacho: 10 year old slender boy fencer, dark brown mop-top haircut,
  rectangular glasses with transparent lenses and visible eyes, serious focused
  expression, electric blue tunic over white long-sleeve shirt, beige shorts, blue
  sneakers, brown fencing glove, exact same character as the reference image"`
- **{RODRIGO}** = `"Rodrigo: 8 year old boy fencer, slightly compact build, round
  cheeks, blond hair with straight bangs, big happy smile, red and orange tunic with
  brown leather belt, khaki cargo shorts, dark blue sneakers, small leather shoulder
  pad, exact same character as the reference image"`

**Prompt por pose** = `{PERSONAJE}, {POSE}. {STYLE}, {BG}`

| pose | {POSE} (descriptor en inglés, usar tal cual) | tamaño final |
|---|---|---|
| `idle` | `"standing fencing en garde stance, knees bent, sword held forward at chest height"` | 56 px alto |
| `run_0` | `"running, contact pose: right leg extended forward heel down, left leg trailing back, arms pumping"` | 56 px |
| `run_1` | `"running, passing pose: legs crossing mid-air under the body"` | 56 px |
| `run_2` | `"running, push-off pose: left leg driving behind, body leaning forward"` | 56 px |
| `run_3` | `"running, recovery pose: front knee lifted high, arms swinging opposite"` | 56 px |
| `jump` | `"rising jump, legs tucked up, arms raised"` | 56 px |
| `fall` | `"falling down, arms up, legs apart"` | 56 px |
| `crouch` | `"crouching low on one knee, weapon pointing forward at knee height"` | 40 px alto |
| `slide` | `"feet-first ground slide, body leaning back low, one hand on the floor"` | 30 px alto |
| `divekick` | `"diving kick diagonally down towards the right at 45 degrees, one leg fully extended, arms back"` | 48 px |
| `attack_high` | `"deep fencing lunge, weapon thrust raised above head height"` | 56 px |
| `attack_mid` | `"deep fencing lunge, weapon thrust straight at chest height, back leg extended"` | 56 px |
| `attack_low` | `"kneeling low thrust, weapon pointing at ankle height"` | 44 px |
| `throw` | `"throwing pose, throwing arm fully extended forward, hand open, body twisted"` | 56 px |
| `downed` | `"lying flat on his back on the ground, stunned, stars around head"` | 30 px |
| `dead` | `"ragdoll lying limp on the ground, limbs loose, eyes as X marks"` | 28 px |

Ejemplo completo (Nacho idle):
`"Nacho: 10 year old slender boy fencer, dark brown mop-top haircut, rectangular glasses with transparent lenses and visible eyes, serious focused expression, electric blue tunic over white long-sleeve shirt, beige shorts, blue sneakers, brown fencing glove, exact same character as the reference image, standing fencing en garde stance, knees bent, sword held forward at chest height, facing RIGHT. pixel art game sprite, side view, full body, grotesque colorful cartoon style like Nidhogg 2, thick black outline, limited color palette, flat shading, crisp pixel edges, solid pure magenta background #FF00FF, no other background elements, no text, no watermark, no border"`

## 3. Armas — 5 archivos `weapon_*.png` (sin referencia, modo generate)

Prompt = `{ARMA}, horizontal, hilt on the LEFT side pointing the blade to the RIGHT,
no hand, {STYLE}, {BG}`

| archivo | {ARMA} | tamaño final |
|---|---|---|
| `weapon_rapier` | `"thin fencing rapier with a small bell guard"` | 90×8 px |
| `weapon_longsword` | `"heavy two-handed broadsword"` | 120×10 px |
| `weapon_dagger` | `"short fighting dagger"` | 55×7 px |
| `weapon_bow` | `"wooden recurve bow held VERTICAL, string facing left"` | 40×70 px |
| `weapon_arrow` | `"single arrow with feathers"` | 28×6 px |

## 4. Escenario, HUD/UI y gusano — 14 archivos

| archivo | prompt (añadir `{STYLE}` salvo indicación; `{BG}` SIEMPRE) | tamaño final |
|---|---|---|
| `tile_floor` | `"seamless tileable pixel art stone castle floor texture, top-down flat view, muted brown and gray"` (sin "side view/full body" del {STYLE}: usar solo `"pixel art, seamless tileable"`) | 48×48 |
| `tile_wall` | `"seamless tileable pixel art stone brick wall texture, large gray blocks with dark mortar"` | 48×48 |
| `pit_edge` | `"pixel art broken stone floor edge piece, top-down, cracked rim"` | 48×48 |
| `bg_layer0` | `"pixel art parallax background, far silhouettes of a dark gothic castle interior, very dark muted purples, no characters, wide horizontal composition"` (sin {BG}: este SÍ lleva fondo opaco; pedir `"full-bleed background, no transparency"`) | 960×540 |
| `bg_layer1` | `"pixel art parallax background layer, mid-distance castle columns, banners and torches, muted colors, no characters"` (fondo opaco) | 960×540 |
| `arrow_neutral` | `"hand-drawn crayon style big arrow pointing RIGHT, chunky outline, PURE WHITE fill, flat"` | 64×40 |
| `pip_hollow` | `"square UI pip, hollow, thick WHITE border, empty interior, slightly rounded corners, flat"` | 26×26 |
| `pip_filled` | `"square UI pip, solid LIGHT GRAY fill, slightly rounded corners, flat"` | 26×26 |
| `blood_0` | `"small blood splat decal blob, LIGHT GRAY, irregular round shape"` | 24×24 |
| `blood_1` | `"medium blood splat decal, LIGHT GRAY, irregular splashing shape"` | 40×24 |
| `blood_2` | `"large blood splat decal, LIGHT GRAY, irregular splash with droplets"` | 64×32 |
| `bg_title` | **NO SE GENERA**: copiar `media/personajes/duelo_versus.png` | 960×540 |
| `worm_body` | `"pixel art giant green cartoon serpent worm, huge open jaws with teeth facing LEFT, grotesque friendly monster"` | 300×120 |
| `stomp_burst` (opcional) | `"pixel art impact burst star, LIGHT GRAY, comic style"` | 48×48 |

## 5. Comandos `bl` (modo A, plantillas exactas)

```bash
# Personaje (con referencia — usar SIEMPRE la hoja):
bl image edit \
  --image "media/personajes/nacho_hoja.png" \
  --prompt "<PROMPT_COMPLETO_de_§2>" \
  --size 1024x1024 --watermark false \
  --out-dir art_raw/nacho/
# → guarda 2 variantes: revisar nombres generados y renombrar a
#   art_raw/nacho/<pose>_v1.png / _v2.png antes del post-proceso.

# Armas / escenario / HUD (sin referencia):
bl image generate \
  --prompt "<PROMPT_de_§3_o_§4>" \
  --size 1024x1024 --watermark false \
  --out-dir art_raw/weapons/
```

Si un flag no existe en tu versión de `bl`, consultar `bl image edit --help` y adaptar
SOLO el flag (el prompt no se toca). Los fondos opacos (`bg_layer0/1`, `bg_title`) NO
llevan `{BG}` magenta y se guardan como PNG RGB sin alfa.

## 6. Elección de variante (regla determinista)

Para cada archivo con `_v1/_v2`: correr `bl vision describe --image <variante> --prompt
"Does this image show exactly one {X} in {POSE} pose facing right on a magenta
background? Answer YES/NO + issues"` — gana la primera que responda YES sin issues; si
ninguna, regenerar 1 vez; si sigue fallando, anotar en `docs/ART_REPORT.md` y seguir
(placeholder).

## 7. Post-proceso obligatorio (pipeline B0, `tools/img_pipeline.py`)

```bash
py -3 tools/img_pipeline.py \
  --in  "art_raw/nacho/idle_v1.png" \
  --out "godot/art/sprites/player_idle_p1.png" \
  --height 56            # o --width para armas/bg (ver tamaño del manifiesto)
```

El script (se crea en B0, Python 3 + pillow): (1) quita el magenta → alfa (tolerancia
fija); (2) recorta al contenido; (3) escala NEAREST al tamaño objetivo; (4) exporta
PNG RGBA. **QA automática por archivo**: falla si no hay alfa, contenido vacío, tamaño
final fuera de ±20% o ratio disparado. Hoja de contacto global para revisión humana:

```bash
"$FF" -pattern_type glob -i 'godot/art/sprites/*.png' \
  -vf "scale=112:112:force_original_aspect_ratio=increase,pad=120:120:color=0x22AA44,tile=9x7" \
  -frames:v 1 art_raw/contact_sheet.png
```

## 8. Checklist de entregables (53 + 1 opcional)

- [ ] B0 pipeline + smoke test (un PNG sintético magenta → alfa OK)
- [ ] B3 armas: 5/5 QA OK (`dagger < rapier < longsword` en px)
- [ ] B4 escenario: 5 generados + `bg_title` copiado
- [ ] B5 HUD/UI: 7/7 (arrow/pips/blood en blanco/gris neutro)
- [ ] B1 Nacho: 17/17 poses, parecido con la hoja
- [ ] B2 Rodrigo: 17/17 poses
- [ ] B6 gusano + hoja de contacto + `docs/ART_REPORT.md` (what/how/variantes/fallos)
- [ ] Suite de tests del juego sigue en verde SIN y CON arte presente
