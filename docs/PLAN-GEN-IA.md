# Plan: diseño propio de personajes y armas con generación IA (Bailian)

**Rama:** `replicando-imagenes` · **Proveedor:** Alibaba Bailian vía CLI `bl` (qwen-image-3.0)
**Regla de oro:** NINGÚN retoque, recorte ni sobrescritura de `art/sprites/` sin el
visto bueno previo del usuario en la puerta correspondiente. Regenerar con
indicaciones NO cuesta puertas: se repite la fase con los ajustes pedidos.

## Fase 0 — Brief de estilo (gratis, ya hecho)

Estética extraída de las referencias de Nidhogg 2 del propio repo
(`media/screenshots`, fotogramas de tráilers; ver análisis en el historial):

| Parámetro | Valor |
|---|---|
| Proporción | cabezón ~1:4 (cabeza = ¼ de la altura), caras expresivas grandes |
| Extremidades | gruesas (4-6 px), silueta compacta de esgrimista |
| Contorno | línea oscura gruesa alrededor de toda la silueta |
| Color | plano, 2-3 tonos por material, paleta limitada, sin degradados |
| Vista | perfil lateral mirando a la derecha (el juego voltea con scale.x) |
| Vestuario | chaqueta acolchada de esgrima colorida, calzas, botas, cinturón |
| Firmas visuales | crestas/penachos de pelo, cintas, equipo excéntrico por duelistas |
| Equipos | P1 azul (castaño) · P2 rojo (rubio) — heredado del sistema de tinte |

Los personajes son **diseño propio original** (no se copian los sprites del juego
comercial): se replica el lenguaje visual, no los pixels.

## PUERTA 1 — Diseño base (⏸ requiere visto bueno)

- 3 candidatos por jugador (hoja de personaje: retrato + cuerpo entero en guardia
  con florete + paleta), semillas fijas (P1: 1101-1103, P2: 2201-2203).
- Salida: `art_raw/redesign_ia/candidatos/` + montaje `candidatos_vista.png`.
- **El usuario elige** un candidato por jugador ("P1: B, P2: A") o pide
  regenerar con indicaciones ("P2 más fornido, sin hombrera…").

## PUERTA 2 — Sprites grandes (⏸ requiere visto bueno de la Puerta 1)

Los diseños más importantes, imagen completa por prompt con la hoja aprobada
como referencia de consistencia (`bl image edit --image`):

- idle · attack_high · attack_mid · attack_low · dead · downed · divekick (×2 jugadores)
- 5 armas: florete, espada larga, daga, arco, flecha (1 imagen con las 5 + recorte)
- Contrato técnico en el prompt: fondo liso, perfil derecho, pies a ras de suelo.
- **Visto bueno por lote** → regeneraciones puntuales con indicaciones.

## PUERTA 3 — Resto de poses (⏸ requiere visto bueno de la Puerta 2)

Por edición con referencia (`bl image edit`, entrada = hoja aprobada + pose
aprobada más parecida): run_0-3, jump, fall, crouch, slide, throw, y las 9
variantes noarme. Lote con montaje de revisión → visto bueno.

## PUERTA 4 — Post-proceso y final (⏸ SOLO con visto bueno de todo lo anterior)

1. Recorte/escalado/QA siguiendo las convenciones de `tools/img_pipeline.py`
   (feet-al-borde, centrado, tamaños objetivo del contrato de `player.gd`).
2. QA visual por hoja de contactos + comparativa con los sprites actuales.
3. Sobrescritura de `art/sprites/` (55 ficheros, mismos nombres) y commit.
4. Actualización de `INDICE-MULTIMEDIA.md` (tamaños nuevos).

## Coste estimado

~6 imágenes (Puerta 1) + ~20 (Puerta 2) + ~45 (Puerta 3) + regeneraciones ≈ 100-150
generaciones a ~¥0.2-0.3 ⇒ **¥20-45 (~$3-6)** en total.
