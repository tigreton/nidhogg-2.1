# Tareas secundarias (backlog)

> **2026-10-04: BACKLOG AGOTADO… y reabierto con lo estructural.** Las dos
> últimas ideas grandes ya son tareas formales aplicadas: la torre de dos
> pisos (`85`, cuarta arena TORRE DEL CENTINELA) y la arena aleatoria por
> puntos (`86`, tecla X). Ese mismo día se fusionó además la rama
> `online-multiplayer` (duelo 1v1 por red, ver `tasks/README.md` y
> `docs/online-netcode.md`) y la revisión profunda posterior dejó DOS
> colas: los **bugs de juego** ya están como tareas formales **87–94**
> (aplicadas el 2026-10-23, en `tasks/`), y las **mejoras estructurales** —ideas que NO
> caben en una tarea atómica de una sesión— entran abajo. Cuando entre una
> idea nueva, sigue la guía del final para convertirla en tarea con este
> formato.
>
> **2026-10-24: SECCIÓN ESTRUCTURAL COMPLETADA.** Los 4 items de abajo,
> resueltos — el último en cerrarse fue el CI headless, hoy mismo: el
> scope `workflow` del token gh ya está concedido, el push subió y el
> primer run de Actions pasó en verde. Backlog cerrado de nuevo hasta
> que entre una idea nueva (el relay de online quedó COMPLETO los días
> 2026-24/25, online v3 1/3+2/3+3/3: servidor en fly.io + despliegue
> automático + modo relay en el menú del juego validado por internet +
> sonda de sala para el código equivocado — ver `docs/online-netcode.md`
> § Relay).

---

## Estructural (revisión post-fusión, 2026-10-04) — COMPLETADO (2026-10-24)

No son tareas atómicas: cada una necesita su propio plan (o una mini-serie
de tareas). Se promueven diseñándolas, no copiando la plantilla tal cual.

- ~~**Dividir `game.gd`**~~ — **HECHO (2026-10-23), 7 cortes**: 4.068 →
  1.371 líneas. Cortes ejecutados en orden de desacoplamiento, un commit
  cada uno con batería completa verde (smoke + suites + sondas + sims
  exactos + E2E online): (1) las 11 clases internas → `scripts/entities/`;
  (2) construcción de arenas → `arena_builder.gd`; (3) HUD → `hud.gd`;
  (4) IA completa con su memoria → `bot_brain.gd` (las tareas de IA futuras
  caen ahí: game.gd ya no crece con la IA); (5) modos → `modes.gd`;
  (6) resolución de combate → `combat.gd`; (7) sync online → `net_sync.gd`
  como NODO hijo (los @rpc van por ruta de nodo). Regla que lo hizo seguro:
  el estado y la superficie pública siguen en game (`game.PIT_X0`,
  `game.scores`...), los módulos lo tocan con `host.` y game delega con los
  nombres originales — ni un test se tocó. Mapa completo en
  `docs/ARQUITECTURA.md`.
- ~~**Orquestador del E2E online**~~ — **HECHO (2026-10-23)**:
  `tools/online_e2e.sh` copia el proyecto a dos carpetas (excludes de lo
  pesado), importa recursos en cada una (caché `.godot` propia), lanza
  host+cliente headless con puerto configurable (`--port`, por defecto 24575
  para no pisar el 24565 de dev) y reporta los dos `RESULT` con exit code
  agregado. Los scripts `test/online_*.gd` aceptan `--port=` (y `--ip=`) como
  user args. `docs/online-netcode.md` documenta el comando canónico.
- **CI headless**: **HECHO (2026-10-23), empujado y en verde (2026-10-24)**:
  `.github/workflows/ci.yml` (jobs `bateria` + `online-e2e` en ubuntu con
  Godot 4.6.2 linux descargado del release oficial y cacheado) +
  `.github/run_test.sh` (corre un test y exige exit 0 Y su línea de
  aprobación; sirve también en local con `GODOT=<binario>`). El bloqueo
  del push inicial se resolvió con `gh auth refresh -s workflow` (flujo
  de dispositivo, autorizado en el navegador): el token gh del equipo ya
  tiene el scope `workflow` para siempre. Primer run en Actions en verde:
  batería 4m30s + E2E online 1m1s. Validación previa en WSL Debian con
  el mismo binario linux que usa CI.
- ~~**Online v2**~~ — **HECHO (2026-10-23), sin infraestructura**: UPnP
  automático del 24565/UDP al crear partida (silencioso, saltado en
  headless, mapeo liberado al cerrar) + IP pública en el menú del
  anfitrión; guía de port-forwarding en `docs/online-netcode.md`
  (§ *Jugar por Internet*, con diagnóstico de fallos típicos); netcode
  endurecido (input con número de secuencia contra el canal no fiable
  desordenado + marioneta interpolando entre los 2 últimos snapshots con
  uno de retraso); y E2E bajo red mala (`tools/netem_proxy.py` +
  `tools/online_e2e.sh --latency N`): verde a 80 y 150 ms de RTT con
  0,5 % de pérdida. El **relay** quedó fuera de v2... y el 2026-10-24
  (online v3 1/3) se desplegó en fly.io: servidor de salas por código
  listo, validado por internet y con deploy automático por CI —
  `docs/online-netcode.md` § Relay.

---

## Cómo promocionar una idea a tarea (formato obligatorio)

Las tareas de esta carpeta están pensadas para lanzarse sueltas a un LLM
básico, así que cada una debe cumplir SIETE reglas:

1. **Atómica**: una sola característica cerrada, aplicable en una sesión. Si
   necesitas dos sesiones, son dos tareas.
2. **Independiente**: debe funcionar sobre el código ACTUAL del proyecto sin
   ninguna otra tarea aplicada. Si hereda de otra (como la dificultad del
   bot), decláralo en la cabecera como `Prerrequisitos:` y dilo en el
   contexto.
3. **Autocontenida**: duplica el bloque "Contexto del proyecto" con los
   archivos, constantes y funciones QUE ESA TAREA TOCA — no confíes en que
   el lector conoció el proyecto ni las demás tareas.
4. **Código literal**: pasos numerados con el código exacto a pegar. Di QUÉ
   línea existente buscar (cítala) y si el paso añade o sustituye. Un LLM
   básico no debe improvisar nada.
5. **Límites explícitos**: sección "Qué NO hacer" con las formas fáciles de
   estropear algo (tocar enums, romper el test, cambiar física global...).
6. **Aceptación verificable**: criterios que se comprueban a mano en 2
   minutos de partida, más el comando headless del test.
7. **Verificación común**: toda tarea termina con:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

y la última línea debe ser `SMOKE OK - todas las mecánicas funcionan`.

Plantilla exacta (copia esto y rellena):

```markdown
# Tarea NN — Título corto

**Dificultad:** baja|media|alta · **Archivos:** `ruta/a/tocar.gd` · **Prerrequisitos:** ninguno

## Objetivo
Qué se añade y para qué (2–4 frases, con el "por qué" del diseño).

## Contexto del proyecto (leer antes de tocar nada)
- Juego Godot 4.6 (GDScript)... — describe SOLO lo que esta tarea necesita:
  archivos, constantes, funciones, patrones existentes (con nombres exactos).
- Reglas de estilo: GDScript tipado, indentación con tabs, comentarios en español.

## Instrucciones paso a paso
### 1. Lo primero que hay que crear/cambiar
"En `archivo.gd`, busca la línea `código existente exacto` y ..."
```gdscript
	código nuevo literal (con tabs de indentación reales)
```
### 2. Lo siguiente...
(repite por cada paso, numerado, sin saltos)

## Qué NO hacer
- ...

## Criterios de aceptación
1. ... (comprobables a mano)

## Verificación
(comando headless + "última línea esperada: SMOKE OK...")
```

Checklist final antes de publicar la tarea:

- [ ] ¿Funciona sobre el código base sin ninguna otra tarea? (o prerrequisito declarado)
- [ ] ¿El código pegado usa TABS y compila tal cual (nombres exactos de variables)?
- [ ] ¿Cada línea que cito como "busca esto" existe realmente en el código actual?
- [ ] ¿Deja el smoke test en verde sin tocarlo (o ajusta sus esperas explicándolo)?
- [ ] ¿Toca el mínimo de archivos posible?
- [ ] ¿Actualicé `README.md` (tabla, conflictos, orden) con la nueva tarea?
- [ ] ¿Un LLM básico podría seguirla sin preguntar nada?
