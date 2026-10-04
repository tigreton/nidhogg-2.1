# Online 1v1 — decisiones de diseño

Rama de origen: `online-multiplayer` (worktree `nidhogg-online`; su commit la
numeró «tarea 85», número que en main pertenece a la torre de dos pisos —
fusionada en main el 2026-10-04). Objetivo: dos jugadores jugando por red,
versión simple pero sólida.

## Modelo de red

**ENet host-cliente (listen server).** El anfitrión es P1 (Nacho) y ejecuta la
simulación autoritativa completa; el cliente es P2 (Rodrigo). Sin servidor
dedicado, sin NAT traversal: IP directa o LAN, puerto **24565**.

Decisión: es el modelo con menos infraestructura y encaja con el código
existente (toda la resolución de combate ya vive en `game.gd`). Un lockstep
determinista se descartó porque el código usa `randf()` en caminos del gameplay
(sangre, cadáveres) y la física por floats no es portable entre plataformas.

## Autoridad y sincronización

- **Host autoritativo**: combate, muertes, puntos, rondas, reapariciones y
  recogidas se resuelven SOLO en el host.
- **Cliente predice su propio P2**: `player.gd` corre entero en local con el
  input propio; la predicción se reconcilia con el snapshot (snap si drift
  > 120 px, atracción suave si > 3 px).
- **El rival (P1) es una marioneta** en el cliente: sin física local, posición
  interpolada hacia el snapshot, resto de campos copiados del snapshot.
- **Snapshots a 20 Hz** (cada 3 ticks de física), no fiables: estado de ambos
  jugadores (~20 campos), marcador, `right_of_way`, locks, muerte súbita,
  temporizadores de reaparición, y las listas completas de proyectiles /
  flechas / espadas caídas (se reconstruyen enteras: son pocos nodos y así
  nunca divergen).
- **Input del cliente a 60 Hz**, no fiable, como diccionario de acciones
  mantenidas. El host lo aplica vía `net_held`/`net_held_prev` en
  `player.held()/hit()` — el mismo mecanismo que ya usaban los bots.
- **Eventos fiables** (RPC reliable) para lo discreto: `ev_round`, `ev_kill`,
  `ev_hit` (derribos/aturdimientos/rebotes con velocidades exactas),
  `ev_respawn`, `ev_point`, `ev_match_over`, `ev_msg`, `ev_sfx`, `ev_burst`.

## Handshake

1. Título → O → host abre puerto (o cliente conecta por IP).
2. Con enlace, ambos cambian a `main.tscn`.
3. El cliente monta su escena y llama `Net.net_ready` (RPC al autoload).
4. El host arranca la primera ronda al recibirlo (evita RPCs a nodos inexistentes).

Caída de enlace en partida → ambos vuelven al título (`Net.shutdown()`).

## Qué se desactiva en partidas online (v1, 1v1 puro)

- Bots, 2v2, lluvia de rocas, modo pantallas, arcade, copa (los toggles se
  ignoran con `Net.active()`).
- Pausa ESC (pausar un solo lado rompería la predicción).
- Hit-stop y cámara lenta (`_hitstop`/`_slowmo` no-op online): son pausas/escalas
  de tiempo locales que desincronizarían los relojes de simulación.
- Arena fija 0 («Ruinas de medianoche») y armas en su ciclo normal.
- R (revancha) solo lo pulsa el anfitrión. Las reglas (puntos para ganar,
  lanzar, rodar) son las del anfitrión.
- Panel de estadísticas final oculto online (las stats locales no cruzan la red).

## Fix adicional (bug preexistente en main)

La cuenta atrás 3·2·1 bucleaba infinitamente: `_physics_process` re-llamaba
`_start_round()` al expirar `round_lock`, que volvía a fijar `round_lock=2.1`.
Los sims no lo veían por `skip_countdown=true`. Fix: la expiración solo muestra
el ¡FIGHT!; la ronda nueva tras un punto se pide con `rematch_pending`.
Verificado con `test/round_probe.gd` (antes: lock reiniciándose cada 2,1 s;
después: llega a 0 y se queda).

## UI y pruebas

- Menú online en el título: **O** → `1` crear partida (muestra las IPs LAN),
  `2` unirse (línea de IP, recuerda la última en `user://online.cfg`).
- Args de usuario para lanzar instancias de prueba:
  `godot --path . -- --host` y `godot --path . -- --join 127.0.0.1`
- Sonda de la cuenta atrás: `godot --headless --path . --script test/round_probe.gd`

## E2E automatizado (test/online_host.gd + test/online_client.gd)

Dos procesos Godot headless jugando de verdad por ENet en 127.0.0.1:24565.
Cada lado "pulsa" teclas con `Input.action_press` (correr, ataque rítmico,
saltar fosos/muros como el bot) y verifica lo suyo:

```bash
# ojo: dos instancias del MISMO directorio pisan la caché de .godot y la
# segunda puede no ver su script ("File not found"). Se lanza cada una desde
# su propia copia del proyecto:
cp -r nidhogg-online nidhogg-online-client && rm -rf nidhogg-online-client/.git
cd nidhogg-online && godot --headless --path . --audio-driver Dummy \
    --script test/online_host.gd > /tmp/host.log 2>&1 &
sleep 6
cd ../nidhogg-online-client && godot --headless --path . --audio-driver Dummy \
    --script test/online_client.gd > /tmp/client.log 2>&1
```

Resultado de la última ejecución (2026-10-04, ya sobre main fusionado):

```
HOST_RESULT:   OK — cliente_listo=true p1_movio=true p2_movio=true bajas=7 score=[1, 0]
CLIENT_RESULT: OK — snapshots=true deriva_max=74px bajas_vistas=14 score=[1, 0]
```

Es decir: handshake, cuenta atrás, duelo con bajas y reapariciones,
`right_of_way`, carrera hasta la meta, **punto anotado y marcador idéntico
en ambos lados**, segunda ronda con cuenta atrás. La deriva de la predicción
del cliente se mantiene < 100 px durante el juego estable.

### Bichos encontrados por el camino (y su fix)

- `rpc_id(1, [])` pasa `[]` como argumento: el host rechazaba el handshake
  ("Method expected 0 argument(s)"). Llamada correcta: `rpc_id(1)`.
- Los snapshots no fiables **no se ordenan** entre sí, y además no hay orden
  entre canal fiable y no fiable: un snapshot viejo (jugador muerto) podía
  llegar tras el `ev_respawn` y "rematar" al jugador local. Fix: guard
  monótono por `ser` en `net_snap` + auto-cura en `_reconcile_own` (si el
  snapshot fresco dice vivo y creíamos muertos, revive en la posición host).
- La API `multiplayer` es null durante el arranque como MainLoop script:
  `Net.host()/join()` devuelven `ERR_UNAVAILABLE` y hay que reintentar un
  frame (en el juego normal, desde el título, nunca pasa).
- Bug preexistente en main: la cuenta atrás 3·2·1 bucleaba (ver arriba).

## Pendiente (no v1)

- Predicción del rival / interpolación con buffer de 2 snapshots reales
  (ahora es suavizado exponencial hacia el último snapshot).
- Reenvío de input con número de secuencia + reconciliación con rebobinado.
- NAT punch / relay para jugar sin IP pública.
