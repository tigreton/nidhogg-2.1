# Tarea 85 — Torre de dos pisos (arena 4: TORRE DEL CENTINELA)

**Dificultad:** alta · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** ninguno
(promovida del backlog `secundarias.md`)

## Objetivo

Una cuarta arena (tecla **C** cicla hasta ella) cuyo cuerpo central es una
**sala vertical**: el pasillo inferior es el clásico (suelo, dos fosos,
hierba/hielo/cinta en el suelo) y encima corre un **piso superior continuo a
y=320 con dos huecos** por los que caer o tirarse en dive-kick. Escaleras de
plataformas flotantes en ambos extremos suben al piso sin bloquear el paso
por debajo, y el tramo del foso central queda a cielo abierto para que el
salto al puente tembloroso no se golpee con el techo.

## Contexto del proyecto (leer antes de tocar nada)

- `game.gd` construye el nivel en `_build_level()` con helpers:
  `_platform(x0, x1, y)` (caja de colisión de 16 px + tiles + `_register_top`),
  `_floor_segment`, `_static_box`, `_wall`, `_poly(points, col, z)`.
- Las arenas se definen en `_load_arena(id)`: un `match arena_id` que fija las
  variables de layout (`PIT_*`, `PIT2_*`, `PLAT_*`, `HOUSE_X`, `STEP_*`,
  `BOULDER_*`, `TOWER_*`, `FENCE_*`, paleta `col_*`, tintes `bg_tint_*`) y
  `ARENA_NAMES` (const) lista los nombres; `set_arena()` reconstruye con C.
- La cámara tiene `limit_top = 0` y `limit_bottom = 720`: un piso a y=320
  cabe entero en pantalla (los pies arriba quedan a y≈290).
- Física de salto (player.gd): parado ~66 px, con carrera ~144 px de ápice;
  hay salto doble. Peldaños de 64-112 px son triviales.
- El humo del smoke test y el sim usan la arena 0 por defecto: añadir una
  arena nueva no los toca (C no se pulsa en ningún harness).
- Reglas de estilo: GDScript tipado, indentación con tabs, comentarios en español.

## Instrucciones paso a paso

### 1. Nombre de la arena

En `ARENA_NAMES`, añade `"TORRE DEL CENTINELA"` como cuarta entrada.

### 2. Layout y paleta

En `_load_arena`, nueva rama `3:` antes del caso `_` por defecto:

- Foso central y puente tembloroso como siempre: `PIT_X0=2210`, `PIT_X1=2380`,
  `PLAT_X0=2130`, `PLAT_X1=2460`, `PLAT_Y=448`.
- Foso seco a la izquierda-centro: `PIT2_X0=1450`, `PIT2_X1=1630`.
- Casa en la boca derecha (`HOUSE_X=4150`, zona sin piso encima), peldaños
  bajos `STEP_L 340-432` y `STEP_R 3760-3852` (44 px, caben bajo el piso).
- Paleta verde cobre/teal nocturna: cielo `Color(0.03,0.06,0.07)`, suelo
  `(0.10,0.17,0.18)`, borde `(0.24,0.38,0.38)`, foso `(0.07,0.20,0.18)`,
  luna pálida `(0.65,0.85,0.80)` en `(2400,110)`, tintes
  `bg_tint_far=(0.60,0.85,0.80)` / `bg_tint_near=(0.80,0.95,0.90)`.

### 3. El piso superior

Nueva función `_tower_floor()`:

- Cuatro tramos con `_platform(x0, x1, 320.0)`:
  `[620,1170]`, `[1340,2130]`, `[2460,3240]`, `[3410,4120]`.
  Los huecos: **1170-1340** y **3240-3410** (170 px), y el tramo del foso
  central (2130-2460) queda abierto.
- Escaleras flotantes (el pasillo de abajo sigue transitable):
  izquierda `_platform(450,560,448)` + `_platform(520,610,384)`;
  derecha `_platform(4230,4340,448)` + `_platform(4180,4270,384)`.
- Cuatro `Torch` sobre el piso (`t.position = Vector2(tx, 320.0)`) a los
  lados de los huecos: x = 1120, 1390, 3190, 3460.

### 4. Composición con la decoración existente

- En `_build_level`, el puente alto de madera (`_bridge()`) se salta en esta
  arena (pisaría las alas del piso): `if arena_id != 3: _bridge()`.
- En `_rocks_zone`, tras los dos peldaños bajos, `return` si `arena_id == 3`:
  el peñasco y la torre de piedra (topes a 440/330) dejarían 46-104 px de
  hueco bajo el piso — no cabe un jugador de pie sobre ellos.
- Llamada: `if arena_id == 3: _tower_floor()` al final de la zona de
  decoración de `_build_level`.

## Qué NO hacer

- No pongas piso sobre el tramo 2130-2460: el bot salta al puente tembloroso
  desde el suelo y necesita el cielo despejado (el sim lo vigila).
- No uses `_rock_step` para las escaleras: son cajas sólidas hasta el suelo y
  cerrarían el pasillo inferior; solo `_platform` deja pasar por debajo.
- No toques `player.gd`, `_respawn_pos` ni el bot: sin muros nuevos, las
  reapariciones (y=200) caen donde caigan — al suelo o al piso, ambas válido.
- No cambies las arenas 0-2: ni una coordenada.

## Criterios de aceptación

1. C cicla hasta "TORRE DEL CENTINELA": pasillo inferior clásico + piso
   superior con dos huecos bien visibles (antorchas los flanquean).
2. Se sube por cualquiera de los dos extremos con la escalera de plataformas,
   y se pasa por debajo de cada escalera sin chocar.
3. Caer por un hueco o tirarse en dive-kick desde el piso funciona; el piso
   del ala izquierda desemboca en el puente tembloroso al correr a la derecha.
4. Los dos fosos del pasillo inferior siguen matando, y el bot cruza el
   central por el puente sin atascarse (sim en verde).
5. `SMOKE OK` (la arena 0 no cambia) y `SIM PASS`.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/sim_match.tscn
```

Últimas líneas esperadas: `SMOKE OK - todas las mecánicas funcionan` y `SIM PASS`
(el piso se comprueba a mano con F5 + C×3).

### Notas de composición (decisiones tomadas al aplicarla)

- **Con la 70 (puente que cae):** sin interacción — el piso está a y=320 y el
  puente a 448; se eligió dejar el foso central a cielo abierto en lugar de
  abrir el piso desde el puente.
- **Con el modo P (rejas):** las rejas cruzan el piso superior visualmente;
  el modo pantallas sigue jugable pero no fue pensado para esta arena.
- **Con el caos T:** las rocas caen hasta el suelo atravesando el piso
  (cosmético); los impactos solo se resuelven en el pasillo inferior.
