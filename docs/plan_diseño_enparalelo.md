# Plan de ejecución en paralelo — CÓDIGO ‖ ARTE

> Aprobado el 2026-09-06. Decisiones fijadas: **primario de imágenes = CLI `bl`
> (wan2.7-image, ya configurado; es el que generó las hojas de Nacho y Rodrigo)** ·
> **vía de arte = manual `docs/ART_PROMPTS.md` + generación por lotes por parte del
> agente** · Claude descartado (no genera imágenes) y Higgsfield descartado (vídeo/efectos,
> sin control de alfa) · el código NUNCA se bloquea por falta de arte.

## 1. Estructura en paralelo

```
        ┌── TRACK A (CÓDIGO, Godot) ──────────────────────────────┐
        │ E0 Godot → E1 esqueleto → E2 tests + STUB de señales    │
        │   ├─ W1: E3 arena → E4 jugador → E5 melee → E6 armas    │
        │   │       → E7 arco        (cadena core, 1 worker)      │
        │   └─ W2: E9 HUD + E11 SFX sintetizado (contra el stub   │
        │           de señales de E2; 100% paralelo con W1)       │
        │ E8 flujo de partida (tras E4)                           │
        └──────────────────────────────────────────────────────────┘
        ┌── TRACK B (ARTE, sin Godot, sin dependencias) ──────────┐
        │ B0 contrato + pipeline                                  │
        │ B1 Nacho (17) ‖ B2 Rodrigo (17) ‖ B3 armas (5)           │
        │ ‖ B4 escenario (6) ‖ B5 HUD/UI (7) ‖ B6 gusano + QA     │
        │ B1–B6 ejecutables en cualquier orden y a la vez         │
        │ (salidas disjuntas: nunca se pisan archivos)            │
        └──────────────────────────────────────────────────────────┘
              └── GATE FINAL: E10-integración + E12 (requiere A completo;
                  B puede llegar tarde: si no está, placeholders)
```

**Contrato de desacople (la regla que lo hace posible):** Track B solo entrega PNG RGBA
con nombres EXACTOS en `godot/art/sprites/` (las claves del `sprite_registry` de
`EXECUTION_PLAN.md`). Track A consume vía `get_texture(clave)` con fallback
`null → placeholder geométrico`. Ninguna de las dos vías espera a la otra hasta el gate.

**Requisito nuevo en E2 (código):** el stub de `match_manager.gd` (solo señales y
variables públicas, sin lógica) se crea en E2 para que W2 pueda construir HUD y SFX
contra la interfaz sin esperar a W1/E8. Señales del stub: `player_died(victim, killer)`,
`arrow_flipped(attacker)`, `section_changed(idx)`, `match_won(player)`,
`respawned(player)`, `pit_fell(player)`.

## 2. Manifiesto de assets (53 archivos finales, ~100 generaciones)

| Grupo | Archivos | Nombres exactos | Tamaño final | Referencia |
|---|---|---|---|---|
| Personaje P1 (Nacho) | 17 | `player_{pose}_p1.png` | altura 56 px | `media/personajes/nacho_hoja.png` |
| Personaje P2 (Rodrigo) | 17 | `player_{pose}_p2.png` | altura 56 px | `media/personajes/rodrigo_hoja.png` |
| Armas | 5 | `weapon_{rapier,longsword,dagger,bow,arrow}.png` | 90/120/55/70/28 px | — |
| Escenario | 6 | `tile_floor, tile_wall, pit_edge, bg_layer0, bg_layer1` (+tinte por código) | 48×48 / 960×540 | — |
| HUD/UI | 7 | `arrow_neutral, pip_hollow, pip_filled, blood_0..2, bg_title` | ver manual | `duelo_versus.png` (reúso) |
| Gusano | 1 | `worm_body.png` | 300×120 | — |

Poses (17 por personaje): `idle, run_0..3, jump, fall, crouch, slide, divekick,
attack_high, attack_mid, attack_low, throw, downed, dead`. TODAS de perfil mirando a la
DERECHA (el código voltea con `scale.x = -1`). Textos dinámicos ("¡FIGHT!",
"¡NACHO GANA!") son `Label` de código, no assets.

El detalle archivo por archivo con prompts exactos está en **`docs/ART_PROMPTS.md`**.

## 3. Pipeline técnico de Track B (determinista, QA automática)

1. **Generación**: `bl image edit --image <referencia> --prompt "<prompt>"
   --size 1024x1024 --watermark false --out-dir art_raw/<grupo>/` con 2 variantes por
   archivo. Todo prompt termina en: `"solid pure magenta background #FF00FF, no other
   background elements"` (el magenta se convierte en alfa después).
2. **Post-proceso**: `tools/img_pipeline.py` (Python + pillow): magenta→alfa,
   autocrop al contenido, escala NEAREST a la altura del manifiesto, PNG RGBA +
   reporte por archivo.
3. **QA automática** (el archivo FALLA si): sin canal alfa · contenido vacío ·
   dimensiones finales fuera de ±20% · ratio de aspecto fuera de rango.
   Elección de variante: `bl vision describe` + checklist del manual.
4. **QA visual**: hoja de contacto sobre fondo ajedrez (una imagen con todos los
   sprites) para revisión humana de un vistazo.
5. **Fallbacks** si `bl` falla: skill `qwencloud-image-generation` (misma cuenta
   DashScope) → ChatGPT manual con los mismos prompts (guardar en
   `art_raw/manual/`) → placeholder geométrico (el juego sigue funcionando).

## 4. Reparto de trabajo recomendado

- **Coste estimado**: ~100 generaciones × 0,02–0,05 € ≈ **2–5 €** (con posible cuota
  gratuita de bienvenida de la cuenta).
- **Orden recomendado**: primero B0 (pipeline), luego B3+B4+B5 (baratos, definen el
  look ya) y B1/B2 (personajes, los más lentos) mientras W1/W2 avanzan el código.
  Gate E10/E12 al final.
- **Paralelización externa**: cualquier humano o LLM con acceso a un generador de
  imágenes puede ejecutar B1–B6 usando SOLO `docs/ART_PROMPTS.md` (no necesita leer
  nada del proyecto Godot) y dejando los PNG en `art_raw/manual/`; el pipeline de B0
  los normaliza al contrato.

## 5. Relación con los otros documentos

- `EXECUTION_PLAN.md`: sigue siendo el plan autoritativo del CÓDIGO (tareas E0–E12);
  E10 se reconvirtió en GATE de integración y se le añadió el Track B (B0–B6).
- `ART_PROMPTS.md`: manifiesto + prompts + instrucciones de generación (Track B).
- `PLAN.md` / `RESEARCH.md` / `VIDEO_ANALYSIS.md` / `PERSONAJES.md`: diseño y contexto.
