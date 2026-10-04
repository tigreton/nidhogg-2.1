# Rediseño de personajes y armas — réplica del estilo del juego original

**Rama/worktree:** `replicando-imagenes`
**Fecha:** 2026-10-04
**Herramienta:** `tools/redesign_sprites.py` (nuevo, pipeline de arte — NO es código del juego)
**Alcance:** 50 sprites de personaje + 5 armas regenerados en `art/sprites/` con los
mismos nombres de fichero. **Cero cambios de código del juego.**

## 1. Objetivo y enfoque

Sustituir los sprites pictóricos generados por IA (bordes blandos, proporciones
inconsistentes entre poses, P1/P2 desparejos) por un rediseño **pixel art nítido**
que imita el lenguaje visual del juego original:

| Parámetro de estilo (del original) | Aplicado aquí |
|---|---|
| Proporción cabezona ~1:4 | Cabeza 11-12 px sobre cuerpo de 56 px |
| Extremidades gruesas | Brazos 4 px, piernas 5 px, torso 9-11 px |
| Contorno oscuro de silueta | `#1a1226` exterior + halo de 1 px entre piezas |
| Colores planos, 2 tonos por material | Luz arriba/frente, sombra abajo/atrás (bisel automático) |
| Hoja recta de bordes paralelos | Núcleo claro + filo base + punta oscura (3 tonos) |
| Vista lateral de esgrima | Todos los poses miran a +x; el juego invierte con `scale.x` |

**Nota de honestidad:** los sprites del juego comercial original no se han
extraído ni calcado pixel a pixel (son material ajeno con copyright). Lo que se
replica es su *lenguaje visual* con dibujo original propio generado por el rig
paramétrico.

## 2. Contrato técnico (por qué no hace falta tocar código)

`scripts/player.gd` dibuja cada pose con:

```gdscript
draw_texture_rect(tex, Rect2(-w * 0.5, POSE_FEET_Y - h, w, h), false, tint)
```

El rediseño respetaba tres reglas, verificadas programáticamente:

1. **Mismos nombres** de fichero en `res://art/sprites/` (los `.import` y sus
   UID siguen válidos; Godot reimporta al cambiar el contenido).
2. **Pies en el borde inferior**: el píxel más bajo de cada pose es la suela
   (o el pie que pisa, en carrera). Anclaje `POSE_FEET_Y = 32` intacto.
3. **Eje del cuerpo en el centro horizontal**: canvas de ancho impar centrado
   en x=0 del rig. Se acabó el desfase de ~2 px del sprite rojo (tarea 62):
   ahora P1 y P2 usan la MISMA geometría y solo cambia la paleta.

Los canvas cambian de tamaño respecto a los antiguos (p. ej. `attack_mid`
117×56 en vez de 84×56) pero el código lee `tex.get_width/height()` en
tiempo de dibujo, así que se adapta solo.

## 3. Paletas

Colores exactos (RGB hex) usados por el rig:

### P1 — azul, pelo castaño
| Pieza | Base | Luz | Sombra |
|---|---|---|---|
| Chaqueta | `3a66c8` | `5c8ae8` | `24448c` |
| Calzón | `e6dcc4` | `f6efdc` | `b8ae94` |
| Bota | `6a4630` | — | `46291a` (suela) |
| Piel | `f0c090` | — | `c89066` |
| Pelo | `52351f` | `6d4a2a` | `3a2515` (ceja) |

### P2 — rojo, rubio
| Pieza | Base | Luz | Sombra |
|---|---|---|---|
| Chaqueta | `c84632` | `e87050` | `8c2820` |
| Calzón / piel / botas | igual que P1 (botas `55341f`/`382012`) | | |
| Pelo | `e0a83c` | `f0c860` | `a87626` |

### Comunes
Contorno `1a1226` · acero `eef4fa`/`c2ccd8`/`8a96a8` · latón `e8c860`/`c9a23a`/`8a6a1e` ·
empuñadura `5a3a24` · cinturón `2a2330` con hebilla de latón.

P3/P4 y bots reutilizan estos sprites con tinte (`modulate`), igual que antes.

## 4. Inventario de poses (tamaños finales, idénticos P1/P2)

| Pose | Tamaño | Lectura |
|---|---|---|
| `idle` | 81×56 | Guardia: rodillas flexionadas, florete a 18°, brazo trasero en arco |
| `run_0` | 77×56 | Contacto A: talón delante, pie trasero empujando |
| `run_1` | 79×56 | Paso A: cuerpo alto (bob −2), pies bajo el cuerpo |
| `run_2` | 77×56 | Contacto B: zancada amplia, pie delante plantado |
| `run_3` | 79×56 | Paso B |
| `jump` | 71×56 | Rodillas recogidas, florete a 40° |
| `fall` | 81×56 | Piernas abiertas, brazos fuera |
| `crouch` | 77×40 | Sentadilla profunda, florete bajo |
| `slide` | 65×33 | Cuerpo echado, pierna delantera estirada rasante |
| `attack_high` | 95×56 | Estocada alta 32°, pie trasero plantado |
| `attack_mid` | 117×56 | Estocada clásica: rodilla sobre tobillo, hoja 33 px |
| `attack_low` | 107×44 | Estocada baja agachada |
| `throw` | 105×56 | Suelta: espada 2 px por delante del puño |
| `throw` noarme | 47×56 | Mano abierta + estela de suelta de 3 trazos |
| `divekick` | 41×48 | Patada voladora: cuerpo diagonal, hoja plana atrás |
| `dead` | 69×28 | Tendido de espaldas con ojos X, florete en la mano |
| `downed` | 61×30 | Derribado con rodilla alzada, espiral de mareo |
| noarme (9 poses) | 35-47 px de ancho | idle, run_0-3, jump, fall, crouch, throw sin arma |

## 5. Armas

| Fichero | Tamaño | Diseño |
|---|---|---|
| `weapon_rapier.png` | 90×9 | Pomo latón, empuñadura trenzada, concha, hoja 2 tonos |
| `weapon_longsword.png` | 120×9 | Gola ancha, hoja 3 tonos con filo oscuro |
| `weapon_dagger.png` | 55×8 | Guarda estrecha, hoja corta |
| `weapon_bow.png` | 38×70 | Recurvo vertical; **puntas exactas en y=10 e y=60** porque `_draw_bow()` ancla ahí la cuerda procedural |
| `weapon_arrow.png` | 28×6 | Punta romboidal a la derecha, plumas naranjas (se dibuja a 28×6 exacto en `arrow.gd`) |

Todas apuntan a la derecha y centradas (el pickup las rota −0.25 rad y el
proyectil gira libre). El florete "horneado" en las poses usa la misma paleta
que `weapon_rapier` para que mano y arma suelta parezcan la misma arma.

## 6. Pipeline y QA

- Regenerar todo: `python tools/redesign_sprites.py sheets`
  (escribe `art/sprites/*.png` + hojas de revisión en `art_raw/redesign/`).
- Hojas: `sheet_p1.png`, `sheet_p2.png`, `sheet_weapons.png`,
  `compare_old_vs_new.png` (viejo del repo principal vs nuevo, P1 y P2).
- 5 pasadas de QA visual + QA programático (pies al borde, margen lateral,
  despeckle). Correcciones aplicadas por ronda:
  1. pies anclados de verdad (el recorte dejaba filas vacías abajo);
  2. halo de separación entre piezas (brazos/torso, hoja/cuerpo);
  3. guarda del florete solapando el puño (la hoja ya no "flota");
  4. pies traseros de las estocadas plantados + margen de aire en bordes;
  5. despeckle de px de contorno huérfanos + ajuste fino de talones.
- Veredicto final del QA visual: **SHIPPABLE** (P1 y P2).

## 7. Pendiente / decisiones de diseño asumidas

- El arma horneada en poses es SIEMPRE el florete (como antes): ver
  `CAMBIOS-CODIGO-PENDIENTES.md` §1 si se quieren poses por arma.
- `slide` sigue siendo el sprite de la rodada (usado por `State.ROLL`).
- Los rostros usan ojo 2×2 con brillo, ceja, nariz, boca y oreja; `dead`
  tiene ojos X y `downed` espiral de mareo.
