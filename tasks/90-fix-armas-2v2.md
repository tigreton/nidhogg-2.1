# Tarea 90 — Fix: P3 y P4 nunca ciclan armas en 2v2

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** 23 aplicada
(bug de la revisión post-fusión online, 2026-10-04)

## Objetivo

El ciclo de armas al reaparecer (florete → espadón → daga → arco) vive en
`weapon_idx`, un array de tamaño 2: `_next_weapon` devuelve "florete" fijo
para cualquier índice ≥ 2, así que en 2v2 los aliados P3/P4 reviven SIEMPRE
con florete mientras P1/P2 rotan. Redimensionar el array al número de
jugadores en cada reset para que los cuatro ciclen.

## Contexto del proyecto (leer antes de tocar nada)

- `var weapon_idx := [0, 0]` (declaración ~línea 122 de game.gd).
- `_next_weapon(p)` usa `weapon_idx[p.player_id - 1]` con guard de rango:
  hoy el guard es el que "protege" del crash y a la vez romde el ciclo.
- Hay DOS sitios que resetean con `weapon_idx = [0, 0]`:
  1. `_start_round()` — busca la línea `weapon_idx = [0, 0]` entre
     `sect_conquered = [0, 0]` y el bucle `for p in players: p.weapon_id =
     "florete"`.
  2. El setup online (bloque `_host_setup`/posicionado de la rama online) —
     la otra línea `weapon_idx = [0, 0]` del archivo (busca
     `net_wait_peer = false` dos líneas más arriba).
- `Array.resize()` sobre un array con valores mantiene los existentes y
  añade `null` en las posiciones nuevas; `fill(0)` lo deja todo a cero.

## Instrucciones paso a paso

### 1. Sustituir los DOS resets de `weapon_idx`

En cada uno de los dos sitios busca la línea:

```gdscript
	weapon_idx = [0, 0]
```

y sustitúyela por:

```gdscript
	weapon_idx.resize(players.size())
	weapon_idx.fill(0)
```

### 2. Comprobar que `_next_weapon` no necesita cambios

`_next_weapon` ya incrementa módulo `GameConfig.WEAPON_ORDER.size()` para
cualquier índice dentro del array: con el array redimensionado, P3/P4
ciclan solos. NO toques la función.

## Qué NO hacer

- No cambies `WEAPON_ORDER` ni las stats de las armas.
- No "arregles" `_next_weapon` devolviendo aleatorio: el ciclo es por
  jugador y secuencial, igual que P1/P2.
- No asignes el array a mano por modo (`[0,0,0,0]` literal): el resize
  cubre también futuros tamaños y el online (2 jugadores).

## Criterios de aceptación

1. 2v2 (V) con aliado P3 activo: mata a P3 → reaparece con ESPADÓN, luego
   DAGA, luego ARCO (el ciclo completo).
2. P1 y P2 siguen ciclando igual que antes.
3. En 1v1 nada cambia (el array sigue siendo de tamaño 2).
4. Online 1v1 no se ve afectado (sus resets también usan el resize).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan` (los casos
2v2 y del ciclo de armas del smoke siguen pasando).
