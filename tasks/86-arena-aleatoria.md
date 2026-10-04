# Tarea 86 — Arena aleatoria por puntos (tramos barajados, tecla X)

**Dificultad:** alta · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** ninguno
(promovida del backlog `secundarias.md`; pensada con los hazards 69-71 aplicados)

## Objetivo

Modo **ARENA BARAJADA** (tecla **X**): cada punto se juega con un orden distinto
de los seis tramos del medio — foso central con puente tembloroso, foso seco,
hierba alta, franja de hielo, cinta transportadora y escalera de plataformas —
mientras las dos bocas de meta quedan fijas con sus estructuras (peldaño,
valla, casa y peñasco/torre de piedra). Con el modo apagado el nivel es
**exactamente** el de siempre: los harnesses (smoke, suites, sim, arcade) no
cambian ni una coordenada.

## Contexto del proyecto (leer antes de tocar nada)

- `game.gd::_build_level()` ya construye casi todo desde **variables** de
  layout (`PIT_*`, `PIT2_*`, `PLAT_*`, `HOUSE_X`, `STEP_*`, `BOULDER_*`,
  `TOWER_*`, `FENCE_*`, `BRIDGE_*`): los segmentos de suelo se tienden
  ordenando la lista de fosos, y bot/respawns/flechas consultan esas vars.
  Las excepciones eran `const`: `GRASS_X0/X1`, `ICE_X0/X1`, `BELT_X0/X1` y la
  escalera, dibujada con literales en 1480-1900.
- `_load_arena(id)` fija los valores por defecto de cada arena; `set_arena`
  reconstruye el nivel (reseteando marcador) con la tecla C.
- `_start_round()` limpia la ronda, restaura los `crumble_tiles` y recoloca a
  los jugadores en `LEVEL_W*0.5 ± 220/620` (¡a ciegas respecto a fosos!).
- `_out_of_pit(x)` empuja una x fuera de los dos fosos con margen.
- La torre de dos pisos (tarea 85, arena 3) tiene el piso superior FIJO: no
  admite barajado (los tramos caerían debajo del piso).
- Reglas de estilo: GDScript tipado, tabs, comentarios en español.

## Instrucciones paso a paso

### 1. Hazores móviles

`GRASS_X0/X1`, `ICE_X0/X1`, `BELT_X0/X1` pasan de `const` a `var`, y nace
`var LADDER_X := 1480.0` (origen de la escalera), `var random_arena := false`
y `var _shuffled := false`. `_load_arena` los resetea a sus valores por
defecto en su cola común (más `_shuffled = false`) y el bloque de tejados se
extrae a `_derive_roofs()`.

### 2. `_build_level` por funciones

Extrae en funciones los bloques dibujados inline (contenido idéntico):
`_make_crumbles()`, `_draw_grass()` (incluye `_flowers()`), `_draw_ice()`,
`_draw_belt()`, `_ladder(x0)` (los tres `_platform` con offsets +0/+180/+320,
ancho total 420) y llama `_ladder(LADDER_X)`. Las piedras sueltas de
`_rocks_zone` y las velas/lápidas de la arena 2 (x fijas) se saltan si
`_shuffled`.

### 3. El barajado

`_random_layout()`: llama a `_load_arena(arena_id)` de base, marca
`_shuffled`, fija las **bocas** (izq: `STEP_L 200-292@516`, `FENCE 330-420`,
`HOUSE_X 500` + tejados; der: `STEP_R 4070-4162@516`, `BOULDER 4180-4408@440`,
`TOWER 4420-4588@330`), baraja los seis tramos y los reparte en el corredor
770→4060 con anchos fijos — foso_central 560 (`PLAT = centro ± 165`,
`PIT = centro ± 85`, `BRIDGE = PLAT ± 230`), foso_seco 240 (`PIT2 = x+30 …
x+210`), hierba 340, hielo 340, cinta 190, escalera 470 (`LADDER_X = x+25`) —
separados por `gap = (3290 - 2140) / 7`. `PIT_*` queda anclado al puente.

### 4. Reconstrucción sin tocar marcador

`_reshuffle_level()`: aplica `_random_layout()` (o `_load_arena` si el modo
está apagado) y reconstruye `level_root`/parallax igual que `set_arena` PERO
sin resetear `scores`/`stats`; limpia `crumble_tiles` antes de reconstruir.
`set_random_arena(on)`: activa el flag (el siguiente `_start_round` baraja) o
desactiva reconstruyendo el layout por defecto.

### 5. Enganches

- `_start_round()` arranca con `if random_arena or _shuffled:
  _reshuffle_level()` (antes del bucle que restaura los crumbles).
- Tecla **X**: `"toggle_random": [KEY_X]` en `_setup_input`; en
  `_physics_process`, si `arena_id == 3` muestra "NO DISPONIBLE EN LA TORRE";
  si no, `set_random_arena(not random_arena)`.
- `set_arena`: si el modo está activo y la arena destino es la 3, lo apaga.
- **Spawns a ciegas → blindados**: `_start_round` pasa las x de aparición por
  `_out_of_pit` + clamp a `[GOAL_W+60, LEVEL_W-GOAL-W-60]`; `_respawn_pos`
  hace lo mismo en sus ramas de centro fijo y de secciones.

## Qué NO hacer

- No toques el orden del enum, la física ni `player.gd`.
- No barajes las estructuras de las bocas ni las metas: son el ancla del
  corredor (y el clamp de respawn depende de `GOAL_W`).
- No dejes `PIT_*` sin su puente: `PLAT_*` y `PIT_*` se mueven JUNTOS (el
  bot salta el foso central por el puente y el sim lo vigila).
- No apliques el barajado en la arena 3 (piso superior fijo).
- No resetees el marcador al re-barajar: es el mismo partido, otra sala.

## Criterios de aceptación

1. X activa "ARENA BARAJADA": los seis tramos cambian de orden, sin solapes,
   y las metas y sus estructuras siguen en los extremos.
2. Cada punto re-baraja solo; X de nuevo restaura el layout clásico exacto.
3. Nadie nace ni reaparece sobre un foso (spawn blindado con `_out_of_pit`).
4. El bot corre, cruza el puente donde esté y anota (sim en verde con el modo
   APAGADO, que es como corren los harnesses).
5. `SMOKE OK`, `ALL PASSED` y `SIM PASS` sin tocar ningún harness.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/sim_match.tscn
```

Últimas líneas esperadas: `SMOKE OK - todas las mecánicas funcionan` y `SIM PASS`
(el barajado se prueba a mano con F5 + X, jugando un par de puntos).

### Notas de composición (decisiones tomadas al aplicarla)

- **Puente de madera alto (ruta de `_bridge`):** se baraja con el foso central
  (`BRIDGE = PLAT ± 230`); puede coincidir en y=288 con el peldaño alto de una
  escalera cercana (dos suelos a la misma altura: cosmético).
- **Modo P (rejas):** combinable; una reja puede caer sobre un foso barajado
  (visual). El barajado no toca secciones.
- **Con la torre (85):** X en la arena 3 avisa y no actúa; C hacia la torre
  con el modo activo lo apaga automáticamente.
