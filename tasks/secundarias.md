# Tareas secundarias (backlog)

Ideas que NO son tareas formales todavía: cada una tiene su descripción, enfoque
sugerido y dificultad, pero sin código literal. Cuando quieras convertir una en
tarea de verdad, sigue la guía del final ("Cómo promocionar una idea a tarea")
y guárdala en esta carpeta como `NN-slug.md` siguiendo la numeración.

---

## Combate

### Cadáver con físicas falsas (media · `game.gd`)
Ahora el muerto desaparece en un estallido de partículas. En su lugar, el
cuerpo debe salir despedido girando (un `Node2D` dibujado a mano, reutilizando
las formas de `player.gd::_draw()` en posición tumbada) y quedar en el suelo
hasta que el jugador reaparezca, donde se desvanece. Es el detalle más
"Nidhogg" que queda por poner. Enfoque: en `_kill()`, crear el nodo cadáver con
velocidad de salida opuesta al golpe + rotación; física simple manual
(gravedad + roce, sin CharacterBody); `queue_free()` cuando `respawn_timers`
llegue a cero.

### Rastro de la espada al atacar (baja · `player.gd::_draw`)
Sustituir el destello circular actual del ataque (`if ext > 0.15:`) por una
estela: dibujar 4–5 segmentos decrecientes a lo largo del arco del tajo, con
alfa decreciente. Todo dentro del `_draw()` existente usando `attack_ext()`.

## Arena

### Puente que se desmorona (media · `game.gd`)
Sobre el foso central, plataformas (`StaticBody2D` + dibujo) en tramos de ~80 px
que, al pisarlos, tiemblan 0,4 s y luego caen (quitar colisión + animar el
poly hacia abajo). Se restauran al reiniciar la ronda (`_start_round`). Enfoque:
guardar los tramos en un array con estado (`intacto → temblando → caído`).

### Tramo de hielo (baja · `player.gd`)
Franja de suelo (p. ej. x=2600–3100) donde la fricción baja: en el `match` de
IDLE/RUN, si `position.x` está en la franja, usar `move_toward(..., 300.0 *
delta)` en vez de asignar `velocity.x` directo, para que se deslice. Dibujar el
suelo con tinte azulado brillante en esa franja. Conviene exponer la franja
como constantes `ICE_X0/ICE_X1` en `game.gd` y consultarlas desde `player.gd`
(vía `get_parent()`, como hace la hierba alta).

### Cinta transportadora (media · `game.gd`, `player.gd`)
Tramo de suelo que empuja horizontalmente (p. ej. 120 px/s hacia la izquierda
para dificultar la carrera de P1). Enfoque: constante `BELT_X0/X1/BELT_V`; en
`player.gd`, tras `move_and_slide()`, sumar `BELT_V * delta` a la posición si
está en pie dentro del tramo; animar el dibujo con flechas desplazándose.

### Torre de dos pisos (alta · `game.gd`)
Sala vertical: suelo superior continuo con dos huecos, y el pasillo inferior
actual. Hay que crear el suelo superior con `_platform` (o un nuevo
`_floor_at(y)`), escaleras de acceso en ambos extremos y reapariciones que no
caigan dentro de muros. La cámara ya limita en Y (`limit_top=0`), así que cabe.

## Estructura del partido

### Cuenta atrás al empezar la ronda (baja · `game.gd`)
En `_start_round()`, congelar a los jugadores (`round_lock`-like) 2,4 s y
mostrar "3… 2… 1… ¡LUCHA!" con `show_msg()`. Enfoque: un temporizador propio
`countdown` que cada 0,8 s actualiza el mensaje y desbloquea al acabar;
asegurarse de que el humo del test sigue pasando (sus esperas tras el reinicio
deben absorber el añadido o el test debe ajustarse en la propia tarea).

### Muerte súbita con temporizador (baja/media · `game.gd`)
Si pasan 45 s sin muertes, aviso "¡MUERTE SÚBITA!" y a partir de ahí todo
choque mata (o llueven espadas lanzadas desde los laterales cada 3 s). Enfoque:
contador `calm_time` que se resetea en `_kill()`; HUD con un pequeño label del
tiempo. Evita duelos circulares eternos entre jugadores cautos.

### Partido configurable + pantalla de título (media · `game.gd` o escena nueva)
Menú mínimo al arrancar (título, controles, "elige puntos: 1/3/5 con teclas,
ENTER para empezar") y `WIN_SCORE` convertido en variable. Enfoque: puede ser
una escena nueva que instancia `main.tscn` al aceptar, o un estado de menú
dentro de `game.gd` con `match_over`-like.

## Presentación

### Fondo con parallax (baja · `game.gd`)
Montañas, luna y estrellas a 2–3 profundidades: en Godot 4 el patrón correcto
es `ParallaxBackground` + `ParallaxLayer` hijos del juego, con `motion_scale`
0.2/0.4/0.7 por capa y polígonos procedurales dentro (el cielo actual ya es un
poly; muévelo a la capa más lejana). Mayor mejora visual por hora de trabajo
del proyecto.

### Zoom dinámico de cámara (media · `game.gd::_update_camera`)
Cuando ambos viven, `camera.zoom` hacia `x = clamp(1.0 - (distancia - 400) /
2400, 0.55, 1.0)` con `move_toward` para suavidad; durante la carrera, alejar
un poco en la dirección de la meta (`camera.position.x` ya sigue al corredor).
Cuidado con los límites del viewport vertical (`limit_bottom=720`).

### Murmullo de público (media · `sfx.gd`, `game.gd`)
Ruido rosa en bucle a volumen bajo que sube con la "emoción": +bajas seguidas,
corredor a <600 px de su meta. Enfoque: generar un `AudioStreamWAV` de ruido
rosa de 2 s en `sfx.gd`, reproducirlo en loop con un `AudioStreamPlayer` global
y mover `volume_db` desde `game.gd` con `move_toward`.

### Música dinámica (alta · `music.gd`)
Extender la tarea de música: generar DOS mezclas del mismo bucle (base y base
+ batería/arpegio rápido) sincronizadas, y hacer crossfade según la emoción
(corredor cerca de la meta). Lo difícil es la sincronía: ambas pistas suenan
siempre y solo cambia el volumen, nunca se paran.

### Arena aleatoria por puntos (alta · `game.gd`)
Cada punto se juega con un orden distinto de tramos: convertir `_build_level()`
en una lista de "salas" (funciones que construyen cada tramo y devuelven su
ancho), barajarlas (excepto metas fijas) y reconstruir el nivel en
`_start_round()`. Requiere recalcular `PIT_*`, respawn y cámara en función de
las salas elegidas. Solo si hay ya varias tareas de arena aplicadas.

---

## Cómo promocionar una idea a tarea (formato obligatorio)

Las tareas de esta carpeta están pensadas para lanzarse sueltas a un LLM básico,
así que cada una debe cumplir SIETE reglas:

1. **Atómica**: una sola característica cerrada, aplicable en una sesión. Si
   necesitas dos sesiones, son dos tareas.
2. **Independiente**: debe funcionar sobre el código ACTUAL del proyecto sin
   ninguna otra tarea aplicada. Si hereda de otra (como la dificultad del bot),
   decláralo en la cabecera como `Prerrequisitos:` y dilo en el contexto.
3. **Autocontenida**: duplica el bloque "Contexto del proyecto" con los
   archivos, constantes y funciones QUE ESA TAREA TOCA — no confíes en que el
   lector conoció el proyecto ni las demás tareas.
4. **Código literal**: pasos numerados con el código exacto a pegar. Di QUÉ
   línea existente buscar (cítala) y si el paso añade o sustituye. Un LLM básico
   no debe improvisar nada.
5. **Límites explícitos**: sección "Qué NO hacer" con las formas fáciles de
   estropear algo (tocar enums, romper el test, cambiar física global...).
6. **Aceptación verificable**: criterios que se comprueban a mano en 2 minutos
   de partida, más el comando headless del test.
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
