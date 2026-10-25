# Online 1v1 — decisiones de diseño

Rama de origen: `online-multiplayer` (worktree `nidhogg-online`; su commit la
numeró «tarea 85», número que en main pertenece a la torre de dos pisos —
fusionada en main el 2026-10-04). Objetivo: dos jugadores jugando por red,
versión simple pero sólida.

## Modelo de red

**ENet host-cliente (listen server).** El anfitrión es P1 (Nacho) y ejecuta la
simulación autoritativa completa; el cliente es P2 (Rodrigo). Sin servidor
dedicado, puerto **24565** (UDP). Para jugar más allá de la LAN ver
§ *Jugar por Internet* más abajo.

Decisión: es el modelo con menos infraestructura y encaja con el código
existente (toda la resolución de combate ya vive en `game.gd`). Un lockstep
determinista se descartó porque el código usa `randf()` en caminos del gameplay
(sangre, cadáveres) y la física por floats no es portable entre plataformas.

## Jugar por Internet (NAT, online v2)

Por LAN siempre funciona (IP directa). Para jugar por Internet, del más al
menos cómodo:

1. **UPnP automático (lo normal).** Al crear partida, `Net.host()` intenta
   mapear el 24565/UDP en el router con UPnP/IGD (timeout 2 s, silencioso).
   Si lo logra, el título muestra la IP pública con la nota *"UPnP ya abrió
   el puerto"*: se la pasas al rival y a jugar. Al cerrar (`Net.shutdown()`)
   el mapeo se elimina. En headless (tests/CI) no se intenta.
2. **Port-forwarding manual.** Si el router no tiene UPnP (o está apagado),
   abre el **24565/UDP** apuntando a la IP local de tu PC y pásale al rival
   tu IP pública (el título la muestra si UPnP la descubrió; si no,
   cuál-es-mi-ip en el navegador). Receta genérica:
   - Entra en la administración del router (suele ser `192.168.0.1` o
     `192.168.1.1`; a veces `10.0.0.1`) y busca *Port Forwarding* /
     *Virtual Server* / *Abrir puertos*.
   - Regla: puerto externo **24565**, protocolo **UDP**, IP interna = la
     IP local de tu PC (la que muestra el título al crear partida),
     puerto interno 24565.
   - Deja el protocolo en UDP solo (ENet no usa TCP aquí).
3. **Diagnóstico rápido si no conecta**: ¿ambos ven la misma versión? ¿el
   host dio la IP pública y no la local? ¿el rival escribió la IP sin
   espacios? ¿el firewall del anfitrión permite a Godot por UDP? El error
   típico es dar una IP `192.168.x.x` a alguien que está en otra red.

Un **relay** (servidor de retransmisión para jugar sin abrir nada) ya está
desplegado: ver § *Relay* más abajo.

## Chispazos de comodidad (2026-10-25)

- **RTT en el HUD**: `net_sync.gd` manda un ping ida y vuelta cada segundo
  desde AMBOS lados (`ev_ping`/`ev_pong`, unreliable — si se pierde, al
  segundo siguiente llega) y el RTT se pinta entre los dos marcadores.
  Responde a «¿va tirando mi red o es la suya?»; con el relay os dice lo
  que cuesta el salto a París. Los E2E imprimen `ping=N ms` en su
  veredicto (local directo: ~8 ms; por el puente del juego: ~14 ms).
- **C copia el código de sala** en la pantalla de espera del anfitrión
  (`DisplayServer.clipboard_set`), con confirmación en pantalla.
- **Fanfarria al entrar el rival** (SFX «fight») en la espera del anfitrión.
- **Nota de caducidad**: la pantalla de sala avisa de que a los 10 min sin
  rival la sala se renueva sola con un código nuevo (ya pasaba; ahora se
  sabe).

## Relay (online v3, 1/3) — jugar sin abrir NADA

**Desplegado el 2026-10-24 en fly.io**: `nidhogg2-relay`, IP pública
**188.93.145.30:24565/UDP**, una máquina de 256 MB en París (`cdg` — la
región `mad` de fly está deprecated para recursos nuevos; `cdg` queda a
~20-35 ms de España). Coste real: **~4 $/mes** (máquina ~2 $ + IPv4
dedicada 2 $; sin ella el UDP no es alcanzable públicamente en fly).
Despliegue automático en cada push que toque el relay
(`.github/workflows/relay-deploy.yml`, ya ARMADO con el secret
`FLY_API_TOKEN` y la variable `RELAY_DEPLOY=true`).

El relay reenvía bytes crudos de ENet entre dos puntas que conectan AMBAS
hacia fuera: ni el anfitrión ni el rival abren puerto alguno. La base del
riesgo técnico la había demostrado `netem_proxy.py` (ENet atraviesa un
forwarder UDP tonto sin enterarse).

**Piezas:**

- `tools/relay.py` — el servidor: UN socket UDP (24565) y salas de dos
  puntas por **código de 4 letras**. Frames que empiezan por
  `NRELAY1`/`NRELAY1D` (que un datagrama ENet jamás empezará): CREATE /
  JOIN / PING / CLOSE de control y datos `NRELAY1D <código> <H|C> <bytes>`.
  El enrutado es por **código+rol**, no por dirección: cada frame
  reaprende la punta (NAT que renueva, proxy que enmascara IPs mientras
  los puertos de origen difieran). Solo stdlib. GC de salas (10 min sin
  rival, 2 h de vida máxima). «Autenticación» = el código (1v1 entre
  amigos). En fly arranca con `--bind fly-global-services`: el proxy de
  fly entrega el UDP externo por esa dirección mágica y lo que sale de
  ella vuelve al cliente con la IP pública correcta (bind 0.0.0.0 recibe
  igual pero RESPONDE por la IP de egreso de la máquina y el NAT del
  cliente lo tira — 33 ms de diagnóstico con `fly logs`).
- `tools/relay_bench.py` — las dos patas locales (H hacia el host ENet,
  C a la escucha para el cliente): es exactamente lo que hará `net.gd`
  dentro del juego. Soporta relay local o externo (con relay externo la
  pata C abre una segunda toma hacia internet: una atada a 127.0.0.1 no
  puede salir, WinError 10051). Todos los bucles tragan `OSError`
  (Windows materializa un ICMP de puerto caído como
  `ConnectionResetError` aunque la tome siga sana: sin la coraza, un hilo
  muerto parte la partida a medias — visto y arreglado).
- `tools/online_e2e.sh --relay` monta todo (relay en `PORT+3`, pata C en
  `PORT+2`), combinable con `--latency`; `--relay-ip IP:PUERTO` hace lo
  mismo contra un relay ya desplegado (solo levanta el bench: el tráfico
  atraviesa internet de verdad).
- `Dockerfile` + `fly.toml` + `.dockerignore` — el contenedor (solo
  sube `relay.py` al builder) y la config de la app.

**Curiosidad de CI**: en los runners de GitHub una toma UDP atada a
`0.0.0.0` enviando a `127.0.0.1` no llega (el kernel elige una fuente
que el receptor nunca ve; probes A/B/C del efímero `relay-debug.yml`,
que ya está borrado). El bench ata `127.0.0.1` explícito contra relay
local. En Windows/WSL pasa en ambos modos.

**Validación (2026-10-24)**: smoke de protocolo en local y contra fly
(CREATE/JOIN, datos binarios ida y vuelta, PING/NOROOM/CLOSE) OK; E2E
`--relay` local OK (deriva 68 px); `--relay --latency 80` OK (99 px);
**E2E `--relay-ip 188.93.145.30:24565` contra el relay REAL por internet
OK (deriva 92 px)** — dos Godot jugando un duelo completo a través de
París. Job `relay-e2e` del CI para regression en cada push.

**Pendiente (online v3 2/3)**: ~~integrarlo en el juego~~ — **HECHO
(2026-10-24)**: el menú del título gana «3 — CREAR POR RELAY» (el anfitrión
ve su código de 4 letras en grande) y «4 — UNIRSE POR RELAY» (teclear el
código). El anfitrión lleva el puente DENTRO del proceso (`net_relay.gd`,
hilos por socket); el rival lo lleva en un **proceso ayudante** — el propio
ejecutable re-lanzado `--headless --relay-helper` (Net lo crea con
`OS.create_process`, lo mata en `shutdown()` y el ayudante se va solo tras
60 s sin tráfico del juego: un kill duro del juego no deja huérfanos
agarrando el puerto). E2E: `tools/online_e2e.sh --relay-game [--latency N |
--relay-game-ip IP:PUERTO]` — en CI cada push; validado en local a 0 ms
(136 px), 80 ms en la pata cliente (109 px) y **contra el relay real de
fly por internet (68 px de deriva)**.

**Las dos trampas de Godot que costaron la tarde** (documentadas para la
próxima): (1) sin peer montado, `multiplayer.multiplayer_peer` es un
`OfflineMultiplayerPeer` que reporta `CONNECTION_CONNECTED` — cualquier
"¿estoy conectado?" debe exigir además que `Net` haya llamado `join()`;
(2) el ENet **cliente** no tolera convivir en su mismo proceso con el
puente UDP bajo latencia del relay (handshake OK y luego el servidor se
queda sordo con tormentas de retransmisión; mismo `net_relay.gd` en
proceso aparte, verde) — el anfitrión en cambio convive sin problema.

**Pendiente (online v3 3/3) — HECHO (2026-10-25)**: la UX del código
equivocado ya no acaba en un «sin conexión» genérico — `join_relay` lanza
primero una **sonda de sala** (un JOIN de prueba desde una toma efímera en
su propio hilo, hasta 6 rondas de 500 ms): `NORROOM` → al instante «No hay
ninguna sala con ese código» en el título; sala existente o relay mudo →
se arranca el ayudante como siempre. La revancha por relay ya funcionaba
por diseño (la R es del anfitrión y el relay es transparente al enlace), y
«recordar el último relay» queda sin sentido habiendo un solo relay. **Con
esto, online v3 está COMPLETO.**

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

Dos procesos Godot headless jugando de verdad por ENet en 127.0.0.1. Cada lado
"pulsa" teclas con `Input.action_press` (correr, ataque rítmico, saltar
fosos/muros como el bot) y verifica lo suyo.

### Forma canónica: el orquestador (un solo comando)

```bash
tools/online_e2e.sh          # o: GODOT=/ruta/a/godot tools/online_e2e.sh
```

El orquestador (ítem "Orquestador del E2E online" de `tasks/secundarias.md`)
hace TODO el procedimiento por ti: copia el proyecto a dos carpetas temporales
(sin `.git`/`art_raw`/`media`/`build`/`screens`/`.godot`, ~15 MB por copia —
dos instancias del MISMO directorio pisan la caché de `.godot` y la segunda
puede no ver su script, "File not found"), importa los recursos en cada copia,
lanza el host en segundo plano, espera 6 s, lanza el cliente, y reporta los
dos `RESULT` con un exit code agregado (0 = ambos OK). Opciones: `--port N`
(por defecto 24575, para no pisar el 24565 de una partida de desarrollo),
`--ip IP`, `--keep` (conserva copias y logs para depurar). Ambos scripts de
test aceptan `--port=` como user arg (tras `--`; el cliente también `--ip=`).

Resultado de la última ejecución del orquestador (2026-10-23):

```
HOST_RESULT:   OK — cliente_listo=true p1_movio=true p2_movio=true bajas=2 score=[0, 0]
CLIENT_RESULT: OK — snapshots=true deriva_max=69px bajas_vistas=3 score=[0, 0]
E2E ONLINE: OK (host rc=0, cliente rc=0)
```

### Forma manual (fallback / depuración a mano)

```bash
# cada instancia desde su propia copia del proyecto (ver aviso arriba):
cp -r nidhogg nidhogg-client && rm -rf nidhogg-client/.git
cd nidhogg && godot --headless --path . --audio-driver Dummy \
    --script test/online_host.gd -- --port=24575 > /tmp/host.log 2>&1 &
sleep 6
cd ../nidhogg-client && godot --headless --path . --audio-driver Dummy \
    --script test/online_client.gd -- --ip=127.0.0.1 --port=24575 > /tmp/client.log 2>&1
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

- ~~Predicción del rival / interpolación con buffer de 2 snapshots reales~~ —
  **HECHO (online v2)**: la marioneta P1 interpola entre los 2 últimos
  snapshots con uno de retraso (~50 ms) — movimiento a velocidad constante.
- ~~Reenvío de input con número de secuencia~~ — **HECHO (online v2)**: el
  input del cliente viaja con seq y el host descarta los desordenados.
  La reconciliación con rebobinado queda fuera (el juego es 1v1 y la
  predicción propia ya reconcilia contra el snapshot).
- ~~NAT punch / relay para jugar sin IP pública.~~ UPnP automático y guía de
  port-forwarding: HECHO (§ *Jugar por Internet*). El relay: DESPLEGADO en
  fly.io y validado por internet (§ *Relay* arriba); queda la integración
  en el menú del juego (online v3 2/3).
- E2E bajo latencia: `tools/online_e2e.sh --latency 150` (proxy UDP
  `tools/netem_proxy.py` con delay/jitter/pérdida por dirección); validado
  OK a 80 y 150 ms de RTT con deriva ~120 px.
