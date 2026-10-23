# ARQUITECTURA del código (post-disolución de game.gd, 2026-10-23)

Estado tras los 7 cortes de la disolución: `game.gd` pasó de **4.068 a
**1.371 líneas** y cada responsabilidad vive en su módulo. La regla que
hizo esto posible sin romper nada: **la superficie pública de `game` no
cambió** — tests, title.gd y los módulos entre sí leen `game.PIT_X0`,
`game.scores`, `game.msg_label` exactamente como antes.

## Mapa de módulos

| Archivo | Líneas | Responsabilidad |
|---|---|---|
| `scripts/game.gd` | 1.371 | **Orquestador + estado**: tick de física, rondas/marcador/goles, armas/proyectiles/pickups, lluvia de rocas, feel (hitstop/slowmo/burst), cámara, input local, y TODAS las variables de estado (geometría del nivel, players, scores, colas de entidades, estado net). Delega en los módulos. |
| `scripts/arena_builder.gd` | 709 | Construcción de arenas/terreno: 4 paletas+geometrías, barajado (tarea 86), props y primitivas de dibujo/colisión. Escribe la geometría EN game vía `host`. |
| `scripts/combat.gd` | 507 | Resolución de combate: pushbox, ataques (choque/parada/impacto), divekick/dive/sidekick/rodada/empalado/stomp, muerte y reaparición. |
| `scripts/bot_brain.gd` | 491 | IA completa (percibir→puntuar→elegir + capas duras + memoria de patrones). **Las tareas de IA futuras caen aquí.** |
| `scripts/net_sync.gd` | 431 | Sincronización online: snapshots 20 Hz, input del cliente, reconciliación y eventos `ev_*`. **Es un NODO hijo de game llamado `NetSync`** (los `@rpc` viajan por ruta de nodo; ver abajo). |
| `scripts/modes.gd` | 279 | Modos: 2v2, lluvia de rocas, pantallas/rejas, arcade, copa. |
| `scripts/hud.gd` | 241 | HUD: marcador, mensajes, pips, barra de reaparición, banners. |
| `scripts/entities/*.gd` | ~330 | Las 11 clases visuales (Cloud, Torch, Candle, GlowSpot, VictoryWorm, Corpse, BloodPool, CrumbleTile, Pip, RespawnBar, SectionGate). |
| `scripts/net.gd` (autoload) | 109 | Ciclo de vida de la conexión ENet: `host()/join()/shutdown()`, puerto 24565, señales. **No sincroniza nada**: eso es NetSync. |
| `scripts/player.gd` | 845 | Duelista: input/física/estados (fuera de esta disolución). |

## El patrón `host` (cómo se hablan)

Cada módulo es un `RefCounted` (salvo NetSync, `Node`) con `var host`
creado en `game._ready()`:

```gdscript
arena = ArenaBuilder.new(self)
hud = Hud.new(self)
bots = BotBrain.new(self)
modes = Modes.new(self)
combat = Combat.new(self)
net_sync = NetSync.new(self)   # + add_child: los @rpc necesitan ruta de árbol
```

- El **estado vive en game**; los módulos lo leen/escriben con `host.X`.
- game llama a los módulos por **delegados finos con el nombre original**
  (`func set_arena(id): arena._load_arena...`) para que NINGÚN call-site
  externo (teclas, tests, tick) haya cambiado.
- Los tests (smoke/suites/sondas/sim/E2E) **no se tocaron en toda la
  disolución**: son el oráculo. Si un corte rompía la batería, el corte
  estaba mal.

## El caso especial NetSync (por qué es un Node)

Los `@rpc` de Godot se enrutan por **ruta de nodo**. Al bajar los métodos
`net_input/net_snap/ev_*` de game a un hijo, la ruta pasa a ser
`/root/Main/NetSync` en **ambos peers a la vez** (mismo ejecutable en los
dos lados): el traslado es atómico y el E2E (`tools/online_e2e.sh`) lo
verificó. Regla: **no renombrar ni mover el nodo NetSync** sin correr la
pareja online después.

## Dónde caen las tareas futuras

- **IA** (niveles, memoria, terreno) → `bot_brain.gd`.
- **Combate/nuevas mecánicas de duelo** → `combat.gd` (+ constantes en game).
- **Arenas/props** → `arena_builder.gd` (la geometría resultante queda en
  game para que bots/tests la lean).
- **Modos nuevos** → `modes.gd`.
- **Netcode** → `net_sync.gd` (sincronización) o `net.gd` (conexión).
- **HUD/mensajes** → `hud.gd` (los nodos siguen siendo de game).

## Validación (la batería)

`tools/online_e2e.sh` (pareja online completa) + smoke (~110 checks) +
suites 17 + feel_check + sondas countdown/p2-drift/pad/torre + sims
SIM_LVL=1/2/3. En CI (`.github/workflows/ci.yml`) corre todo en cada push.
Los sims exigen tiempos/bajas/puntos/match_over EXACTOS (47.9/48.4/49.3 s,
kills=6, puntos=3): los histogramas de estados varían ±12 muestras entre
corridas del mismo binario porque la memoria de ritmo de la IA usa reloj
real (`Time.get_ticks_msec`) — ruido inherente, no regresión.
