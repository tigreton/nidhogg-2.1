# Diseño final con generación IA (Bailian) — personajes y armas

**Rama:** `replicando-imagenes` · **Fecha:** 2026-10-04 · **Modelo:** `qwen-image-3.0` vía CLI `bl` 2.1.0
**Sustituye a** la versión rig paramétrico (commit `6c89584`), descartada por el usuario.

## Qué hay en `art/sprites/`

Los 55 ficheros oficiales regenerados con diseño propio generado por IA en estilo
Nidhogg 2 (cabeza 1:4, extremidades gruesas, contorno oscuro, colores planos),
**sin copiar assets del juego comercial**: 32 poses armadas + 18 noarme + 5 armas.

- **P1 (azul):** chaqueta azul acolchada, calzas beige, botas marrones, pelo
  castaño corto y liso bajo cinta blanca (candidato B + edición "pelo más liso").
- **P2 (rojo):** chaqueta granate/naranja, hombrera de acero, rubio peinado atrás
  con flequillo (candidato A + edición "más flequillo").
- Arma horneada: florete fino en todas las poses armadas (la que empuña el juego
  por defecto); variantes `noarme` sin arma (las usa el juego al desarmar/con arco).

## Pipeline (reproducible)

`tools/finalize_ia_sprites.py` post-procesa `art_raw/redesign_ia/poses/` (51 PNG
generados, 1728×2368, fondo gris) → chroma-key del fondo, recorte bbox, escalado
LANCZOS a la altura del contrato (pies al borde inferior), alfa duro. La hoja
`weapons.png` se segmenta en 5 clusters por columnas EN ORDEN del prompt
(florete, espadón, daga, arco, flecha) y las hojas se rotan −90° (el modelo las
dibuja apuntando arriba) para que apunten a la derecha; el arco queda vertical.

### Semillas (todas reproducibles con los prompts del historial)

| Lote | Semillas |
|---|---|
| Candidatos P1 (A/B/C) | 1101 / 1102 / 1103 |
| Candidatos P2 (A/B/C) | 2201 / 2202 / 2203 |
| Ediciones de base (pelo liso / flequillo) | 1150 / 2250 |
| PUERTA 2 P1 (idle→divekick) | 1111-1117 (regeneraciones: 1212, 1214, 1314, 1313, 1414) |
| PUERTA 2 P2 | 2211-2217 (regeneraciones: 2311, 2316) |
| PUERTA 2 armas (hoja única) | 3001 |
| PUERTA 3 P1 armadas (run→throw) | 1510-1518 |
| PUERTA 3 P2 armadas | 2510-2518 |
| noarme P1 / P2 | 1610-1618 / 2610-2618 (regeneraciones: 7162, 7165, 7261, 7262, 7266) |

### Coste real

71 generaciones + 5 regeneraciones de noarme ≈ **76 imágenes ≈ ¥16-22 (~$2.3-3)**.

## Contrato respetado (cero cambios de código)

- Mismos nombres de fichero; `.import` intactos; Godot reimporta solo.
- Pies al borde inferior (verificado programáticamente en los 50 personajes).
- Canvas = bbox del personaje (convención del pipeline original): el renderer
  centra el canvas y ancla `POSE_FEET_Y`.
- Alturas objetivo por pose: 56 (de pie/carrera/estocadas/throw), 40 crouch,
  44 attack_low, 48 divekick, 30 slide/downed, 28 dead.
- `weapon_arrow` 28×6 con la punta a la derecha; `weapon_bow` 38×70 vertical.

## QA

- 4 puertas de aprobación del usuario (diseño, poses grandes, set completo, final).
- 6 regeneraciones por indicación del usuario + 5 noarme con florete residual.
- QA visual final del set en tamaño de juego: SHIPPABLE.
- Nota menor: posible resto gris del chroma-key junto a los pies en 1-2 sprites;
  si molesta en juego, micro-retoca con `finalize_ia_sprites.py` (subir TOL) y
  regenerar del material bruto (no hace falta volver a pagar API).

## Materiales de revisión

`art_raw/redesign_ia/`: `candidatos_vista.png`, `puerta2_vista.png`,
`puerta3_vista.png`, `final_sheet.png`, `qa_p1.png`, `qa_p2.png`, bases en
`base/`, prompts íntegros en el historial de la sesión.
