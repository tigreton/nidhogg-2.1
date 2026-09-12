# Nidhogg-like — Las 22 tareas en un solo documento

**Para el LLM que ejecuta:** este documento reúne las 22 tareas atómicas del
proyecto, concatenadas e íntegras. Cada tarea es autocontenida (duplica el
contexto que necesita) y está escrita para ejecutarse **sin preguntar nada**.
Lee primero esta cabecera completa; después trabaja una tarea cada vez.

## El proyecto

- Carpeta del proyecto: `C:\Users\tigreton\Documents\zcode\Nidhogg 2.1`
- Motor: **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg para
  2 jugadores en el mismo teclado. Un golpe mata: quien mata gana el "paso" y
  debe correr hasta su meta; el rival reaparece delante para frenarlo. Primero
  en anotar 3 veces gana el partido.
- Arte y sonido 100 % procedurales: **no hay assets externos**.
- Archivos principales:
  - `scenes/main.tscn` + `scripts/game.gd` — nivel, combate, cámara, rondas y HUD.
  - `scenes/player.tscn` + `scripts/player.gd` — control y dibujo procedural de los duelistas.
  - `scripts/sfx.gd` — efectos de sonido generados por código.
  - `scripts/sword_projectile.gd`, `scripts/pickup.gd` — espada lanzada y espada caída.
  - `test/smoke_test.gd` + `test/smoke_test.tscn` — prueba automática headless.

## Reglas globales de ejecución (obligatorias)

1. Trabaja **una sola tarea por sesión** y deja **un commit por tarea**, para
   que si algo sale mal se pueda revertir sola.
2. Ejecuta la tarea **exactamente como está escrita**, paso a paso, sin cambios
   creativos ni "mejoras" adicionales.
3. **No modifiques archivos que la tarea no mencione.**
4. Al terminar, ejecuta SIEMPRE el comando de verificación (más abajo) y
   comprueba que la última línea es `SMOKE OK - todas las mecánicas funcionan`.
5. Si el código real no encaja con lo que describe un paso (por ejemplo, la
   línea que la tarea dice buscar no existe), **DETENTE y explica la
   discrepancia. No improvises.**
6. Las tareas están escritas sobre el **código base sin ninguna tarea
   aplicada** (rama `main`, estado del commit `ccd7577`). Si al empezar una
   tarea descubres que esa funcionalidad YA existe en el código, detente y
   dilo: no la dupliques.
7. Estilo del proyecto: GDScript tipado, indentación con **tabs**, comentarios
   en español.

## Índice de tareas

| # | Archivo original | Tarea | Dificultad |
|---|---|---|---|
| 01 | `tasks/01-ia-bot.md` | Bot jugable para P2 (combate + correr a la meta) | alta |
| 02 | `tasks/02-ia-bot-dificultad.md` | Tres niveles de dificultad del bot | baja |
| 03 | `tasks/03-arena-hierba-alta.md` | Hierba alta que oculta la estancia | baja |
| 04 | `tasks/04-arena-plataformas.md` | Escalera de plataformas (verticalidad) | baja |
| 05 | `tasks/05-arena-segundo-foso.md` | Segundo foso sin plataforma | media |
| 06 | `tasks/06-feel-hitstop.md` | Hit-stop (congelar unos frames al matar) | baja |
| 07 | `tasks/07-feel-camara-lenta.md` | Cámara lenta al matar y al anotar | baja |
| 08 | `tasks/08-feel-indicador-meta.md` | Aviso "¡CORRE!" con dirección de meta | baja |
| 09 | `tasks/09-feel-marcador-paso.md` | Halo bajo los pies de quien tiene el paso | baja |
| 10 | `tasks/10-feel-polvo.md` | Polvo al aterrizar y al correr | baja |
| 11 | `tasks/11-feel-musica.md` | Música procedural en bucle | media |
| 12 | `tasks/12-mov-rodar.md` | Rodar (esquiva rápida agachado + salto) | media |
| 13 | `tasks/13-mov-punetazo.md` | Puñetazo cuando estás desarmado | media |
| 14 | `tasks/14-test-ampliar.md` | Ampliar el smoke test (5 casos nuevos) | media |
| 15 | `tasks/15-rob-pausa.md` | Pausa con ESC | baja |
| 16 | `tasks/16-rob-gamepad.md` | Soporte de mando (2 gamepads) | baja |
| 17 | `tasks/17-fix-espada-foso.md` | La espada desviada sobre el foso cae en el borde | baja |
| 18 | `tasks/18-mov-estocada.md` | Estocada al atacar corriendo | media |
| 19 | `tasks/19-mov-desarme.md` | El choque desarma al que ataca en alto | media |
| 20 | `tasks/20-mov-tajo-aereo.md` | Tajo de espada en el aire (elegir altura) | baja |
| 21 | `tasks/21-ia-bot-vs-bot.md` | Modo bot vs bot con la tecla N | baja |
| 22 | `tasks/22-stats-partido.md` | Estadísticas en la pantalla de victoria | baja |

## Orden recomendado

Aunque son independientes, si vas a hacer varias, este orden minimiza fricción:

1. Primero las que solo añaden: `06`, `07`, `08`, `09`, `10`, `15`, `16`, `17`.
2. Luego arena (`03`, `04`, `05`) y movilidad (`12`, `13`).
3. Después `14` (el test ampliado vigila que nada se rompa en lo sucesivo).
4. Al final `01` → `02` (bot) y `11` (música), que son las más grandes.
5. `18`–`20` (movilidad) van bien justo después de `12`/`13`; `21` después de
   `01`; `22` en cualquier momento.

## Conflictos conocidos (por tocar el mismo código)

| Tareas | Conflicto y qué hacer |
|---|---|
| `01` y `02` | `02` reescribe parte de lo que añade `01`. Aplica `01` antes que `02`. |
| `05` y `17` | Las dos modifican la gestión de fosos en `_drop_sword`. Si aplicas ambas, unifica el helper `_in_any_pit`. |
| `06` y `15` | Las dos usan `get_tree().paused`. Si aplicas ambas, acepta que pulsar ESC durante el hit-stop lo corta (o protege el toggle con una variable). |
| `06` y `07` | Las dos actúan en `_kill`. Son compatibles, pero revisa juntas el resultado. |
| `12` y `13` | Las dos tocan el bloque de ataque en `player.gd`. Aplica una, prueba, y luego la otra. |
| `03` y `09` | El halo del corredor de `09` sigue viéndose dentro de la hierba de `03` (aceptable, o envuélvelo también). |
| `12`, `13`, `18` y `20` | Las cuatro tocan el bloque de input de ataque en `player.gd`. Cada una está escrita para el código base: aplícalas de una en una y revisa el diff entre medias. |
| `01` y `21` | `21` necesita el bot de `01` (activar ambos con N). |
| `19` y `13` | Sinergia (no conflicto): el desarme de `19` crea los duelos a puñetazo que arma `13`. Aplicables en cualquier orden. |

## Comando de verificación (común a todas las tareas)

Desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea debe ser `SMOKE OK - todas las mecánicas funcionan`.

---

**A partir de aquí vienen las 22 tareas completas, en orden numérico. Cada
tarea empieza con el título `# Tarea NN — ...` y termina antes del siguiente
título. Ejecuta una, verifica, y pasa a la siguiente.**

Tras la Tarea 22 hay TRES APÉNDICES: el trabajo ya realizado fuera de las 22
tareas, la diferencia con el proyecto hermano `Nidhogg 2` (mecánicas que allí
existen y aquí faltan: tareas candidatas) y el backlog de ideas. **Los
apéndices NO se ejecutan tal cual**: son contexto y material pendiente de
convertir en tareas formales.


---

# Tarea 01 — Bot jugable para el jugador 2

**Dificultad:** alta · **Archivos:** `scripts/player.gd`, `scripts/game.gd` · **Prerrequisitos:** ninguno

## Objetivo

Añadir un bot que controla a P2. Se activa/desactiva con la tecla **B**. El bot
sabe: duelar (acercarse, elegir estancia ganadora, atacar, defenderse, lanzar la
espada), correr a su meta cuando tiene el paso, e interponerse cuando el paso
lo tiene el humano.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg para 2 jugadores
  en un mismo teclado. Todo el arte es procedural (`_draw()`) y los sonidos se generan
  por código: **no hay assets externos ni plugins, y no se pueden añadir**.
- Archivos:
	- `scripts/game.gd` — nodo principal: nivel, cámara, HUD y resolución de ataques,
	  proyectiles, muertes, reapariciones, puntos y rondas. Constantes: `LEVEL_W=4800`,
	  `GROUND_Y=560`, `PIT_X0=2210`, `PIT_X1=2380`, `PLAT_X0=2130`, `PLAT_X1=2460`,
	  `PLAT_Y=448`, `GOAL_W=130`, `WIN_SCORE=3`, `RESPAWN_DELAY=2.4`. Variables clave:
	  `right_of_way: Player` (quién tiene "el paso" tras matar) y `scores` (2 enteros).
	- `scripts/player.gd` — `class_name Player` (CharacterBody2D). Estados en
	  `enum State {IDLE, RUN, JUMP, DIVEKICK, ATTACK, STUNNED, KNOCKDOWN, DEAD}`
	  (índices 0–7; el test headless depende de ellos) y estancias `enum H {LOW, MID, HIGH}`.
	  Lee input con acciones `p1_*`/`p2_*` registradas en runtime por `game._setup_input()`
	  (en `game.gd`). Métodos de input: `held(n)` (pulsada) e `hit(n)` (recién pulsada),
	  donde `n` es `"left"`, `"right"`, `"up"`, `"down"`, `"jump"`, `"attack"` o `"throw"`.
	- `scripts/sfx.gd` — `class_name Sfx`, estático: `Sfx.play(parent, pos, id, db)`.
	- `test/smoke_test.gd` — prueba automática headless.
- Reglas de estilo: GDScript tipado (`:=`, tipos en firmas), indentación con **tabs**,
  identificadores en inglés, comentarios y textos de juego en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. `scripts/player.gd` — entrada virtual para el bot

1.1. Junto a las demás variables de instancia (después de `var anim_time := 0.0`),
añade exactamente:

```gdscript
var is_bot := false
var bot_held := {}          # acciones que el bot mantiene pulsadas (solo si is_bot)
var bot_held_prev := {}     # estado del tick anterior, para detectar "recién pulsada"
var bot_think := 0.0        # cronómetro entre decisiones del bot (lo usa game.gd)
```

1.2. Reemplaza POR COMPLETO las funciones `held()` y `hit()` por:

```gdscript
func held(n: String) -> bool:
	if is_bot:
		return bool(bot_held.get(n, false))
	return Input.is_action_pressed(_a(n))


func hit(n: String) -> bool:
	if is_bot:
		return bool(bot_held.get(n, false)) and not bool(bot_held_prev.get(n, false))
	return Input.is_action_just_pressed(_a(n))
```

1.3. Dentro de `_physics_process`, busca la línea (dentro del bloque `if can_act:`):

```gdscript
	dir = float(Input.is_action_pressed(_a("right"))) - float(Input.is_action_pressed(_a("left")))
```

y sustitúyela por:

```gdscript
	dir = (1.0 if held("right") else 0.0) - (1.0 if held("left") else 0.0)
```

1.4. Al final de `_physics_process` (justo después de `queue_redraw()`), añade:

```gdscript
	if is_bot:
		bot_held_prev = bot_held.duplicate()
```

### 2. `scripts/game.gd` — tecla de activación

2.1. En `_setup_input()`, dentro del diccionario `defs`, añade la entrada:

```gdscript
	"toggle_bot": [KEY_B],
```

2.2. En `_physics_process`, justo después del bloque `if match_over and Input.is_action_just_pressed("restart"):`,
añade:

```gdscript
	if Input.is_action_just_pressed("toggle_bot"):
		players[1].is_bot = not players[1].is_bot
		show_msg("BOT P2 %s" % ("ACTIVADO" if players[1].is_bot else "DESACTIVADO"), 0.7)
```

2.3. En el bucle `for p in players:` que asigna `p.frozen`, añade debajo (dentro del bucle):

```gdscript
		if p.is_bot:
			_bot_think(p, delta)
```

### 3. `scripts/game.gd` — cerebro del bot

Añade estas funciones nuevas al final del archivo:

```gdscript
func _bot_think(p: Player, delta: float) -> void:
	var foe := _other(p)
	p.bot_think -= delta
	if p.bot_think > 0.0:
		return
	p.bot_think = 0.12
	var want := {}
	var tap := ""
	var adx := absf(foe.position.x - p.position.x)
	var sd := 1.0 if foe.position.x >= p.position.x else -1.0
	var on_floor := p.is_on_floor()

	if right_of_way == p:
		# corredor: correr hacia su meta y cruzar el foso por la plataforma
		if p.goal_dir > 0:
			want["right"] = true
		else:
			want["left"] = true
		if on_floor and p.position.x > PLAT_X0 - 130.0 and p.position.x < PLAT_X1 + 130.0 and not (p.position.x > PLAT_X0 + 40.0 and p.position.x < PLAT_X1 - 40.0):
			tap = "jump"
	elif right_of_way == foe:
		# interceptor: adelantarse en la dirección hacia la que corre el rival
		var tx: float = foe.position.x + float(foe.goal_dir) * 200.0
		if tx > p.position.x + 20.0:
			want["right"] = true
		elif tx < p.position.x - 20.0:
			want["left"] = true
		if on_floor and p.position.x > PLAT_X0 - 130.0 and p.position.x < PLAT_X1 + 130.0 and not (p.position.x > PLAT_X0 + 40.0 and p.position.x < PLAT_X1 - 40.0):
			tap = "jump"
	else:
		# duelo: gestión de distancia y estancias
		if adx > 260.0:
			if sd > 0.0:
				want["right"] = true
			else:
				want["left"] = true
			if on_floor and randf() < 0.05:
				tap = "jump"
		elif adx < 55.0:
			if sd > 0.0:
				want["left"] = true
			else:
				want["right"] = true
		elif foe.state == Player.State.ATTACK and foe.attack_is_active():
			# cubrirse: igualar la altura del ataque rival para provocar choque
			match foe.attack_height:
				Player.H.HIGH:
					want["up"] = true
				Player.H.LOW:
					want["down"] = true
		else:
			# estancia ganadora: contra MID atacar LOW; contra HIGH y LOW, quedarse en MID
			if foe.stance == Player.H.MID:
				want["down"] = true
			if randf() < 0.30:
				tap = "attack"
			if p.has_sword and randf() < 0.03:
				tap = "throw"
	# patada voladora si el rival está abajo y cerca
	if not on_floor and adx < 100.0 and foe.position.y > p.position.y + 40.0:
		tap = "attack"
	p.bot_held = want
	if tap != "" and p.state in [Player.State.IDLE, Player.State.RUN, Player.State.JUMP]:
		p.bot_held[tap] = true
```

### 4. Pista visual

En `_build_hud()`, en el texto del label `hint`, añade al final `    B: bot P2`.

## Qué NO hacer

- No cambies el enum `State` ni los índices de estados existentes.
- No toques `scripts/sfx.gd`, `scripts/pickup.gd` ni `scripts/sword_projectile.gd`.
- No hagas al bot jugador 1; solo P2.
- No uses `Input.action_press()` para el bot: usa `bot_held` como se indica.

## Criterios de aceptación

1. El juego arranca normal; P2 sigue siendo humano hasta pulsar B.
2. Con B activado, P2 se acerca, cambia de estancia, ataca y en algún momento lanza la espada.
3. Si el bot te mata, corre hacia SU meta (la izquierda) y salta el foso por la plataforma.
4. Si tú matas al bot, al reaparecer se interpone en tu camino hacia la derecha.
5. Con B de nuevo, P2 vuelve a control humano.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`
(los criterios 2–5 se comprueban a mano abriendo el juego con F5).


---

# Tarea 02 — Tres niveles de dificultad del bot

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos: tarea 01 aplicada**

## Objetivo

Que la tecla **B** ciclie el bot de P2 entre OFF → FÁCIL → NORMAL → DIFÍCIL → OFF.
La dificultad cambia tres cosas: tiempo de reacción, frecuencia de ataque y
probabilidad de equivocarse con la estancia.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Todo el arte
  es procedural (`_draw()`) y los sonidos se generan por código: sin assets externos.
- Esta tarea asume que la **tarea 01 ya está aplicada**: `player.gd` tiene
  `is_bot`, `bot_held`, `bot_held_prev` y `bot_think`, y `game.gd` tiene la
  función `_bot_think(p: Player, delta: float)` y la acción `"toggle_bot"` (tecla B)
  gestionada en `_physics_process`.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Tabla de configuración

En `scripts/game.gd`, junto a las demás constantes (después de `const RESPAWN_DELAY`),
añade:

```gdscript
const BOT_CFG := [
	{"react": 0.26, "atk": 0.12, "err": 0.35},  # FÁCIL
	{"react": 0.13, "atk": 0.30, "err": 0.10},  # NORMAL
	{"react": 0.07, "atk": 0.50, "err": 0.02},  # DIFÍCIL
]
```

Y junto a las variables de instancia (después de `var shake_time := 0.0`):

```gdscript
var bot_level := 1   # 1 FÁCIL, 2 NORMAL, 3 DIFÍCIL (si is_bot está activo)
```

### 2. Ciclo de la tecla B

En `_physics_process`, reemplaza el bloque que añadiste para `"toggle_bot"`
(el que hacía `players[1].is_bot = not players[1].is_bot`) por:

```gdscript
	if Input.is_action_just_pressed("toggle_bot"):
		if not players[1].is_bot:
			bot_level = 1
			players[1].is_bot = true
		elif bot_level < 3:
			bot_level += 1
		else:
			players[1].is_bot = false
		var names := ["FÁCIL", "NORMAL", "DIFÍCIL"]
		if players[1].is_bot:
			show_msg("BOT P2: %s" % names[bot_level - 1], 0.7)
		else:
			show_msg("BOT P2: OFF", 0.7)
```

### 3. Usar la configuración en el cerebro

En `_bot_think`, haz estos tres reemplazos puntuales:

3.1. La línea `p.bot_think = 0.12` →

```gdscript
	var cfg: Dictionary = BOT_CFG[bot_level - 1]
	p.bot_think = float(cfg["react"])
```

3.2. La línea `if randf() < 0.30:` (la de atacar) →

```gdscript
			if randf() < float(cfg["atk"]):
```

3.3. El bloque de "estancia ganadora" empieza con el comentario
`# estancia ganadora: ...`. Justo ANTES de la línea `if foe.stance == Player.H.MID:`,
inserta la posibilidad de error:

```gdscript
			# con probabilidad "err" el bot se equivoca de estancia
			if randf() < float(cfg["err"]):
				var r := randi() % 3
				if r == 0:
					want["up"] = true
				elif r == 1:
					want["down"] = true
				else:
					pass  # se queda en media por error
			elif foe.stance == Player.H.MID:
				want["down"] = true
```

(ojo: esto sustituye al `if foe.stance == Player.H.MID:` original — ahora es un
`elif` del error). Las dos líneas siguientes (`if randf() < ...tap = "attack"` y
`if p.has_sword and randf() < ...tap = "throw"`) se quedan igual, dentro de este `else`.

## Qué NO hacer

- No toques `player.gd` ni el test.
- No cambies el comportamiento corredor/interceptor del bot, solo el duelo.
- No añadas menús: solo el ciclo con B y el mensaje en pantalla.

## Criterios de aceptación

1. B cicla OFF → FÁCIL → NORMAL → DIFÍCIL → OFF y el mensaje muestra el nivel.
2. En FÁCIL el bot reacciona tarde y falla estancias a menudo; en DIFÍCIL ataca
   en cuanto tiene estancia ganadora y casi no falla.
3. El bot humano (B en OFF) sigue funcionando igual que antes.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`
(el ciclo de B se comprueba a mano abriendo el juego con F5).


---

# Tarea 03 — Hierba alta que oculta la estancia

**Dificultad:** baja · **Archivos:** `scripts/game.gd`, `scripts/player.gd` · **Prerrequisitos:** ninguno

## Objetivo

Añadir una zona de hierba alta (entre x=1150 y x=1450) donde la espada del duelist
que esté dentro **no se dibuja**: el rival no puede ver tu estancia (alta/media/baja)
hasta que sales. Es el "juego mental" clásico de Nidhogg en la hierba.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg para 2 jugadores
  en un mismo teclado. Todo el arte es procedural (`_draw()`, `Polygon2D`) y los
  sonidos se generan por código: **no hay assets externos ni plugins**.
- Archivos:
	- `scripts/game.gd` — nodo principal: nivel, cámara, HUD y resolución de combate.
	  Constantes de nivel: `LEVEL_W=4800`, `GROUND_Y=560`, foso central
	  `PIT_X0=2210`/`PIT_X1=2380`, plataforma `PLAT_X0=2130`/`PLAT_X1=2460`/`PLAT_Y=448`.
	  El nivel se construye en `_build_level()`; los polígonos decorativos se crean con
	  `_poly(points, color, z_index)`. Los jugadores están en `GROUND_Y - 29` (y=531).
	- `scripts/player.gd` — `class_name Player` (CharacterBody2D). Se dibuja entero en
	  `_draw()`; la espada se dibuja dentro del bloque `if has_sword:` cerca del final.
	- `test/smoke_test.gd` — prueba headless. Coloca a los jugadores en x≈1600–1800,
	  FUERA de la zona de hierba: no debe verse afectada.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. `scripts/game.gd` — constantes y dibujo de la hierba

1.1. Junto a las demás constantes de nivel (después de `const PLAT_Y := 448.0`),
añade:

```gdscript
const GRASS_X0 := 1150.0
const GRASS_X1 := 1450.0
```

1.2. En `_build_level()`, después de la línea `_platform(PLAT_X0, PLAT_X1, PLAT_Y)`,
añade:

```gdscript
	# hierba alta: oculta la estancia de quien entra
	_poly(PackedVector2Array([Vector2(GRASS_X0, GROUND_Y), Vector2(GRASS_X1, GROUND_Y), Vector2(GRASS_X1, GROUND_Y - 34.0), Vector2(GRASS_X0, GROUND_Y - 34.0)]), Color(0.09, 0.18, 0.11), 2)
	for i in 22:
		var gx := GRASS_X0 + (GRASS_X1 - GRASS_X0) * (float(i) + 0.5) / 22.0
		var gh := 44.0 + 20.0 * randf()
		_poly(PackedVector2Array([Vector2(gx - 7, GROUND_Y), Vector2(gx + 7, GROUND_Y), Vector2(gx + randf_range(-7.0, 7.0), GROUND_Y - gh)]), Color(0.13, 0.30, 0.17).lightened(0.08 * randf()), 3)
```

(El `z_index` 3 dibuja la hierba POR ENCIMA de los jugadores, que están a z=0.)

1.3. Añade esta función pública en `game.gd` (junto a `sfx()` está bien):

```gdscript
func in_grass(x: float) -> bool:
	return x > GRASS_X0 and x < GRASS_X1
```

### 2. `scripts/player.gd` — no dibujar la espada dentro de la hierba

En `_draw()`, el bloque que dibuja la espada empieza con `if has_sword:`.
Sustituye esa línea por:

```gdscript
	var g := get_parent()
	var hide_sword: bool = g != null and g.has_method("in_grass") and g.in_grass(global_position.x)
	if has_sword and not hide_sword:
```

El resto del bloque se queda igual (solo cambia la condición de entrada).

## Qué NO hacer

- No ocultes el cuerpo del duelist ni su color: SOLO la espada.
- No cambies la lógica de combate: dentro de la hierba los ataques, choques y
  muertes se resuelven exactamente igual; esto es puramente visual.
- No sitúes la hierba entre x=1550 y x=2050 (el smoke test usa esa franja).

## Criterios de aceptación

1. Se ve una franja de hierba verde de ~300 px entre los dos pilares de la izquierda.
2. Al entrar en la hierba, la espada de tu duelist desaparece (no se ve si está
   en alta, media o baja); el cuerpo sigue visible.
3. Al salir, la espada vuelve a dibujarse.
4. Un ataque lanzado desde dentro de la hierba golpea con normalidad.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`
(la hierba se comprueba visualmente abriendo el juego con F5).


---

# Tarea 04 — Escalera de plataformas (verticalidad)

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** ninguno

## Objetivo

Añadir una escalera de tres plataformas en la zona x=1480–1900 para dar
verticalidad: se puede subir saltando y desde lo alto atacar o tirarse en
patada voladora sobre el rival que pasa por debajo.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Todo el arte
  es procedural y los sonidos se generan por código: **sin assets externos**.
- `scripts/game.gd` construye el nivel en `_build_level()` y ya tiene un helper:
  `_platform(x0: float, x1: float, y: float)` que crea la caja de colisión
  (`StaticBody2D` de 16 px de alto) y el dibujo de una plataforma.
- Física de salto (para que veas por qué estas alturas funcionan): velocidad de
  salto `-700`, gravedidad `1700` → el salto sube ~144 px. El suelo está a
  `GROUND_Y=560`; los "pies" del duelist quedan ~29 px por encima de su centro.
- Prohibido colocar plataformas con parte de su rango x en [1550, 2050] POR DEBAJO
  de y=520... en realidad al revés: el smoke test coloca jugadores en el suelo de
  x≈1600–1800 y solo comprueba `is_on_floor` tras un salto puntual, así que las
  plataformas deben quedar ALTAS (y ≥ 448) para no bloquear el paso por el suelo.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Plataformas

En `scripts/game.gd`, dentro de `_build_level()`, después de la línea
`_platform(PLAT_X0, PLAT_X1, PLAT_Y)`, añade exactamente:

```gdscript
	# escalera de plataformas (verticalidad en el tramo izquierdo-centro)
	_platform(1480.0, 1660.0, 448.0)
	_platform(1660.0, 1800.0, 368.0)
	_platform(1800.0, 1900.0, 288.0)
```

Alturas elegidas para que cada salto suba 80–112 px (factible con salto de 144 px).

### 2. Comprobación de alcance (no requiere código, solo entenderlo)

- Suelo (560) → plataforma 1 (448): sube 112 px. OK.
- Plataforma 1 (448) → plataforma 2 (368): sube 80 px. OK.
- Plataforma 2 (368) → plataforma 3 (288): sube 80 px. OK.

## Qué NO hacer

- No toques `_platform()` ni `_static_box()`: úsalos tal cual.
- No pongas plataformas por debajo de y=448 en la franja 1480–2050 (el test y el
  paso por el suelo deben quedar libres).
- No añadas rampas ni otras físicas nuevas.

## Criterios de aceptación

1. Se ven tres plataformas escalonadas y se puede subir de suelo a la más alta
   con tres saltos.
2. Se puede caminar por debajo de la escalera sin chocar (el suelo sigue libre).
3. Desde la plataforma más alta, un salto + ataque en el aire hace patada
   voladora sobre un rival que pase por el suelo.
4. El smoke test sigue pasando.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`
(la escalera se comprueba a mano con F5).


---

# Tarea 05 — Segundo foso sin plataforma

**Dificultad:** media · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** ninguno

## Objetivo

Abrir un segundo foso mortal en x=700–880, esta vez **sin plataforma**: hay que
saltarlo de un salto (180 px de ancho; un salto con carrera cubre ~270 px).
Aparecen así dos ritmos de cruce: el foso central con plataforma y este, seco.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural y sonidos por código: **sin assets externos**.
- `scripts/game.gd`:
	- Constantes: `LEVEL_W=4800`, `GROUND_Y=560`, foso central `PIT_X0=2210`,
	  `PIT_X1=2380`. La muerte por caída ya existe: en `_physics_process`, todo
	  jugador con `position.y > 820` muere (`_kill`).
	- `_build_level()` llama ahora a `_floor_segment(0.0, PIT_X0)` y
	  `_floor_segment(PIT_X1, LEVEL_W)`. `_floor_segment(x0, x1)` crea suelo
	  sólido + dibujo entre esas x.
	- El dibujo del hueco del foso central es el `_poly(...)` rojo oscuro
	  `Color(0.30, 0.07, 0.09)` con z_index -6 que hay justo después de los
	  `_floor_segment`.
	- `_drop_sword(pos, col)` descarta la espada si cae sobre el foso central
	  (`if x > PIT_X0 and x < PIT_X1: return`).
	- `_respawn_pos(p)` empuja la reaparición fuera del foso central
	  (`if x > PIT_X0 - 50.0 and x < PIT_X1 + 50.0:`).
- El smoke test trabaja en x≈1600–4800: el nuevo foso (700–880) no lo pisa.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Constantes

En `scripts/game.gd`, junto a `const PIT_X1 := 2380.0`, añade:

```gdscript
const PIT2_X0 := 700.0
const PIT2_X1 := 880.0
```

### 2. Suelo con dos huecos

En `_build_level()`, sustituye la línea `_floor_segment(0.0, PIT_X0)` por:

```gdscript
	_floor_segment(0.0, PIT2_X0)
	_floor_segment(PIT2_X1, PIT_X0)
```

### 3. Dibujo del hueco

Justo después del `_poly` rojo del foso central (mismo bloque), añade su gemelo:

```gdscript
	_poly(PackedVector2Array([Vector2(PIT2_X0, GROUND_Y + 4), Vector2(PIT2_X1, GROUND_Y + 4), Vector2(PIT2_X1 - 26, 800.0), Vector2(PIT2_X0 + 26, 800.0)]), Color(0.30, 0.07, 0.09), -6)
```

### 4. Helper común de fosos

Añade esta función a `game.gd` (si ya existe una igual por otra tarea, no la
duples; asegúrate de que incluya los DOS fosos):

```gdscript
func _in_any_pit(x: float) -> bool:
	return (x > PIT_X0 and x < PIT_X1) or (x > PIT2_X0 and x < PIT2_X1)
```

### 5. Usar el helper en los tres sitios que conocen el foso

5.1. En `_drop_sword()`, sustituye `if x > PIT_X0 and x < PIT_X1:` por `if _in_any_pit(x):`.

5.2. En `_respawn_pos()`, sustituye el bloque:

```gdscript
	if x > PIT_X0 - 50.0 and x < PIT_X1 + 50.0:
		x = PIT_X1 + 70.0 if dir > 0.0 else PIT_X0 - 70.0
```

por:

```gdscript
	if x > PIT_X0 - 50.0 and x < PIT_X1 + 50.0:
		x = PIT_X1 + 70.0 if dir > 0.0 else PIT_X0 - 70.0
	elif x > PIT2_X0 - 50.0 and x < PIT2_X1 + 50.0:
		x = PIT2_X1 + 70.0 if dir > 0.0 else PIT2_X0 - 70.0
```

5.3. En `_surface_y(x, from_y)` no hay cambio: la plataforma sigue siendo solo la
del foso central.

## Qué NO hacer

- No pongas plataforma sobre el foso nuevo: la gracia es saltarlo.
- No lo hagas más ancho de 200 px (con 180 px se salta con margen; con más, un
  jugador cuidado no puede cruzar corriendo).
- No toques la lógica de muerte por caída (ya es global).

## Criterios de aceptación

1. Se ve el segundo hueco rojo oscuro en x=700–880 y caer en él mata.
2. Cruzarlo de un salto con carrera es factible y cómodo.
3. Una espada desviada encima de ese foso no desaparece dentro: se descarta
   (igual que en el central; el fix del borde es otra tarea).
4. Nadie reaparece dentro del foso nuevo.
5. El smoke test sigue pasando.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`
(el cruce y la muerte se prueban a mano con F5).


---

# Tarea 06 — Hit-stop al matar

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** ninguno

## Objetivo

Congelar el juego unas centésimas al producirse una muerte (el "hit-stop" de los
juegos de lucha): todo se detiene 0,08 s en el instante del impacto y luego sigue.
Transmite el peso del golpe.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/game.gd` — nodo principal. Las muertes se producen todas en
  `_kill(def: Player, atk: Player)` (aterrizajes, ataques, proyectiles y foso la
  llaman). Ya hay sacudida de cámara (`shake_time`) y ráfagas de partículas
  (`_burst`) dentro de `_kill`.
- Godot: `get_tree().paused = true` detiene los nodos con
  `PROCESS_MODE_PAUSABLE` (los jugadores lo son por defecto). Un
  `get_tree().create_timer(dur, true)` (con `process_always=true`) SIGUE
  funcionando con el juego pausado, así que sirve para despausar.
- El smoke test espera con `create_timer` (que sigue corriendo en pausa), y sus
  márgenes de espera (≥ 0,12 s) absorben una pausa de 0,08 s sin romperse.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Función de hit-stop

En `scripts/game.gd`, añade esta función (junto a `show_msg()` está bien):

```gdscript
func _hitstop(dur: float) -> void:
	if get_tree().paused:
		return
	get_tree().paused = true
	get_tree().create_timer(dur, true).timeout.connect(func(): get_tree().paused = false)
```

### 2. Llamarla al matar

En `_kill()`, justo después de la línea `def.die()` (la primera línea útil de la
función, antes de `respawn_timers[...]`), añade:

```gdscript
	_hitstop(0.08)
```

## Qué NO hacer

- No uses `Engine.time_scale` aquí (eso es cámara lenta, otra tarea).
- No pauses en choques (`_clash`) ni patadas: solo muertes.
- No alargues el hit-stop más de 0,1 s: se sentiría un cuelgue.

## Criterios de aceptación

1. Cada muerte congela la imagen un instante y luego todo sigue.
2. La doble muerte (trade) también lo provoca, sin quedarse pausado.
3. Tras el hit-stop el juego SIEMPRE se reanuda solo.
4. El smoke test sigue pasando (incluida la muerte del test 4 y la del foso si
   se añadió en otras tareas).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`
(el efecto se aprecia abriendo el juego con F5).


---

# Tarea 07 — Cámara lenta al matar y al anotar

**Dificultad:** baja · **Archivos:** `scripts/game.gd`, `test/smoke_test.gd` · **Prerrequisitos:** ninguno

## Objetivo

Cámara lenta dramática (el sello de Nidhogg): al matar, el juego va a 35 % de
velocidad durante medio segundo real; al anotar un punto, a 25 % durante 0,9 s.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/game.gd`:
	- `_kill(def, atk)` es donde ocurren todas las muertes.
	- `_point(p)` es donde se anota (marca el score, muestra mensaje y gestiona
	  `round_lock = 1.4`, el bloqueo de 1,4 s antes de reiniciar la ronda).
	- `round_lock` se descuenta con `delta` en `_physics_process` (a velocidad
	  reducida tarda MÁS tiempo real).
- Godot: `Engine.time_scale` escala el `delta` de todo el juego.
  `get_tree().create_timer(dur, true, false, true)` —cuarto parámetro
  `ignore_time_scale=true`— cuenta tiempo REAL aunque el juego vaya lento.
  Perfecto para restaurar la velocidad.
- `test/smoke_test.gd` (test 6) espera 1,5 s reales a que la ronda se reinicie.
  Con la cámara lenta del punto (0,9 s reales a 0,25×) el reinicio tarda
  ~2,1 s reales, por lo que esa espera hay que ampliarla (paso 3).
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Función de cámara lenta

En `scripts/game.gd`, añade (junto a `show_msg()` está bien):

```gdscript
func _slowmo(scale: float, real_dur: float) -> void:
	Engine.time_scale = scale
	get_tree().create_timer(real_dur, true, false, true).timeout.connect(func():
		Engine.time_scale = 1.0)
```

### 2. Dispararla

2.1. En `_kill()`, después de la línea `_burst(def.position, def.color, 34, 440.0)`, añade:

```gdscript
	_slowmo(0.35, 0.5)
```

2.2. En `_point()`, después de la línea `_burst(p.position + Vector2(0, -30), p.color, 42, 480.0)`, añade:

```gdscript
	_slowmo(0.25, 0.9)
```

### 3. Dar margen al smoke test

En `test/smoke_test.gd`, busca el test 6:

```gdscript
	# 6. La ronda se reinicia sola
	await get_tree().create_timer(1.5).timeout
```

y cambia `1.5` por `2.4`. (Sin cámara lenta sobra; con ella, es necesario.)

## Qué NO hacer

- No dejes `Engine.time_scale` por debajo de 1 al salir del juego: SIEMPRE se
  restaura con el temporizador de tiempo real (ya lo hace la función).
- No apliques cámara lenta a choques ni patadas.
- No modifiques otros tiempos del test.

## Criterios de aceptación

1. Cada muerte ralentiza medio segundo y luego la velocidad vuelve a la normalidad.
2. Cada punto ralentiza casi un segundo (se ve la celebración a cámara lenta).
3. El juego jamás se queda "pegado" en cámara lenta permanente.
4. El smoke test pasa con el margen ampliado.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.


---

# Tarea 08 — Aviso "¡CORRE!" con la dirección de la meta

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** ninguno

## Objetivo

Cuando alguien tiene el paso (`right_of_way`), mostrar en la parte alta de la
pantalla un aviso con su color: "¡P1 CORRE! »»»" o "««« ¡P2 CORRE!" según hacia
qué meta corra. Ayuda a no perderse tras una muerte.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/game.gd`:
	- Variable clave `right_of_way: Player` (null si nadie tiene el paso) y
	  `match_over: bool`. El HUD se construye en `_build_hud()` dentro de un
	  `CanvasLayer` (`cl`, layer 10); `msg_label` y `score_labels` son ejemplos de
	  cómo se crean labels (copiar el patrón: `add_theme_font_size_override`,
	  `add_theme_color_override("font_color", ...)` etc.).
	- Vista: `VIEW_W=1152`, `VIEW_H=648`.
	- `Player` tiene `player_id` (1/2), `color` (Color), `goal_dir` (1 = meta a la
	  derecha, -1 = izquierda) y `State.DEAD`.
	- `_process(_delta)` ya existe (anima el brillo de las metas): es buen sitio
	  para refrescar el aviso cada frame.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Variable

En `scripts/game.gd`, junto a `var msg_label: Label`, añade:

```gdscript
var run_label: Label
```

### 2. Crear el label

En `_build_hud()`, después del bloque que crea `hint`, añade:

```gdscript
	run_label = Label.new()
	run_label.position = Vector2(0, 64)
	run_label.size = Vector2(VIEW_W, 44)
	run_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	run_label.add_theme_font_size_override("font_size", 30)
	run_label.add_theme_color_override("font_outline_color", Color.BLACK)
	run_label.add_theme_constant_override("outline_size", 8)
	run_label.visible = false
	cl.add_child(run_label)
```

### 3. Refrescarlo cada frame

En `_process(_delta)`, después del bucle que anima `goal_polys`, añade:

```gdscript
	var rw := right_of_way
	if rw != null and not match_over and rw.state != Player.State.DEAD and round_lock <= 0.0:
		run_label.visible = true
		run_label.text = "¡P%d CORRE!  %s" % [rw.player_id, "»»»" if rw.goal_dir > 0 else "«««"]
		run_label.add_theme_color_override("font_color", rw.color)
	else:
		run_label.visible = false
```

## Qué NO hacer

- No ocultes el marcador ni el mensaje central (`msg_label`).
- No dibujes flechas en el mundo 2D: el aviso es solo HUD.
- No lo muestres durante la celebración del punto ni con el partido acabado
  (las condiciones del paso 3 ya lo evitan).

## Criterios de aceptación

1. Tras tu primera muerte, aparece "¡P2 CORRE! «««" en color cian arriba.
2. Cuando el paso cambia de dueño, el aviso cambia de texto y color al instante.
3. Durante la celebración del punto y el final de partido no se ve.
4. El smoke test sigue pasando.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.


---

# Tarea 09 — Halo bajo los pies de quien tiene el paso

**Dificultad:** baja · **Archivos:** `scripts/player.gd` · **Prerrequisitos:** ninguno

## Objetivo

Un halo pulsante del color del jugador bajo los pies de quien tiene el paso:
se ve de un vistazo quién está obligado a correr y quién debe interceptar.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural: cada duelist se dibuja entero en su `_draw()`.
- `scripts/player.gd` — `class_name Player` (CharacterBody2D):
	- Variables útiles: `color: Color`, `state: int` (enum `State`, con `DEAD`),
	  `anim_time: float` (crece siempre, sirve para animar).
	- `_draw()` empieza con `if state == State.DEAD: return` y luego define
	  `var c := color ...`. LO QUE SE DIBUJA PRIMERO QUEDA DEBAJO.
	- El padre del jugador es el nodo `game` (`scripts/game.gd`), que tiene la
	  variable pública `right_of_way: Player`.
	- Los pies del duelist quedan en y≈30 (local).
- En GDScript, para leer una propiedad de un nodo sin tiparlo:
  `get_parent().get("right_of_way")` (devuelve null si no existe).
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

En `scripts/player.gd`, dentro de `_draw()`, justo después de las líneas que
definen `c`, `dark` y `blade` (y ANTES de `var t_pos := Vector2.ZERO`, para que
el halo quede debajo del cuerpo), añade:

```gdscript
	var g := get_parent()
	if g != null and g.get("right_of_way") == self:
		var pulse := 0.5 + 0.5 * sin(anim_time * 10.0)
		draw_circle(Vector2(0, 34), 20.0 + 4.0 * pulse, Color(color.r, color.g, color.b, 0.10 + 0.10 * pulse))
		draw_arc(Vector2(0, 34), 24.0, 0.0, TAU, 24, Color(color.r, color.g, color.b, 0.55), 2.0)
```

## Qué NO hacer

- No dibujes el halo si el jugador está muerto (el `return` inicial ya lo evita:
  no lo muevas).
- No apliques transform de tumbado/knockdown al halo (dibújalo antes de
  `draw_set_transform`).
- No lo pongas a ningún jugador fijo: depende de `right_of_way`.

## Criterios de aceptación

1. Al matar, al asesino le aparece un halo naranja/cian pulsante bajo los pies.
2. Si el paso cambia de dueño, el halo se mueve al otro jugador al instante.
3. Con `right_of_way == null` nadie lleva halo.
4. El humo del smoke test sigue pasando.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.


---

# Tarea 10 — Polvo al aterrizar y al correr

**Dificultad:** baja · **Archivos:** `scripts/player.gd` · **Prerrequisitos:** ninguno

## Objetivo

Partículas grises pequeñas al aterrizar (nube) y chispitas continuas mientras se
corre. Vida y peso para el movimiento sin tocar la física.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/player.gd` — `class_name Player` (CharacterBody2D):
	- `_physics_process(delta)` llama a `move_and_slide()` y luego comprueba
	  `is_on_floor()` para aterrizar estados. Al final hace `queue_redraw()`.
	- Estados: `enum State {IDLE, RUN, JUMP, DIVEKICK, ATTACK, STUNNED, KNOCKDOWN, DEAD}`
	  (índices 0–7; el test headless depende de ellos).
	- El duelist se puede añadir hijos de nodo con normalidad
	  (`add_child(...)`); los pies quedan en y≈30 (local).
- Patrón de partículas del proyecto (ver `game.gd::_burst`): `CPUParticles2D`
  one_shot + `get_tree().create_timer(...).timeout.connect(cp.queue_free)`.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Variables

En `scripts/player.gd`, junto a las demás variables de instancia, añade:

```gdscript
var was_on_floor := true
var dust_cd := 0.0
```

### 2. Detectar aterrizaje y carrera

En `_physics_process`, después de la llamada a `move_and_slide()` (y de sus
comprobaciones de aterrizaje de estados), añade:

```gdscript
	dust_cd = maxf(0.0, dust_cd - delta)
	if is_on_floor() and not was_on_floor:
		_dust(10, 150.0)
	elif state == State.RUN and dust_cd <= 0.0:
		dust_cd = 0.16
		_dust(3, 60.0)
	was_on_floor = is_on_floor()
```

### 3. Función de polvo

Añade esta función a `player.gd`:

```gdscript
func _dust(amount: int, speed: float) -> void:
	var cp := CPUParticles2D.new()
	cp.position = Vector2(0, 30)
	cp.one_shot = true
	cp.emitting = true
	cp.amount = amount
	cp.lifetime = 0.4
	cp.explosiveness = 1.0
	cp.direction = Vector2.UP
	cp.spread = 70.0
	cp.initial_velocity_min = speed * 0.4
	cp.initial_velocity_max = speed
	cp.gravity = Vector2(0, -60.0)
	cp.scale_amount_min = 2.0
	cp.scale_amount_max = 4.0
	cp.color = Color(0.55, 0.52, 0.60, 0.5)
	add_child(cp)
	get_tree().create_timer(0.9).timeout.connect(cp.queue_free)
```

## Qué NO hacer

- No cambies la física (velocidades, gravedad, fricción).
- No sueltes polvo en el aire ni muerto (las condiciones del paso 2 ya lo evitan).
- No uses GPUParticles2D (el proyecto es gl_compatibility y el patrón existente
  es CPUParticles2D).

## Criterios de aceptación

1. Al aterrizar de un salto o patada sale una nubecita de polvo.
2. Correr deja un rastro sutil de partículas.
3. Pararse en quieto no suelta nada.
4. El smoke test sigue pasando.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.


---

# Tarea 11 — Música procedural en bucle

**Dificultad:** media · **Archivos:** nuevo `scripts/music.gd`, `scripts/game.gd` · **Prerrequisitos:** ninguno

## Objetivo

Una pista musical oscura de 32 pasos (chiptune: bajo cuadrado + melodía escasa)
generada por código al arrancar y en bucle, con volumen bajo. Tecla **M** para
activar/desactivar. Sin assets externos, como todo el proyecto.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural; los sonidos se generan en `scripts/sfx.gd` escribiendo samples en
  un `AudioStreamWAV` (`FORMAT_16_BITS`, `mix_rate=22050`, mono). Esta tarea
  sigue el mismo patrón.
- `scripts/game.gd` — nodo principal: `_ready()` construye todo;
  `_setup_input()` registra acciones de teclado en runtime;
  `_physics_process()` lee `Input.is_action_just_pressed(...)`.
- En headless el audio usa un driver mudo: la música se puede añadir sin romper
  el test.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Crear `scripts/music.gd` (archivo nuevo)

Crea `scripts/music.gd` con EXACTAMENTE este contenido:

```gdscript
class_name Music
extends Node
## Música procedural: un bucle de 32 semicorcheas generado por código (sin assets).

const BPM := 132.0
const STEPS := 32
const MIX := 22050


static func _note(freq: float, dur: float, vol: float, duty := 0.5) -> PackedFloat32Array:
	var n := int(dur * MIX)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		phase += TAU * freq / MIX
		var s := 1.0 if fmod(phase, TAU) < TAU * duty else -1.0
		var env := 1.0 - float(i) / float(n)
		out[i] = s * vol * env * env
	return out


func _build_loop() -> AudioStreamWAV:
	var step := 60.0 / BPM / 4.0
	var bass: Array = [
		55.0, 0.0, 55.0, 0.0, 65.41, 0.0, 55.0, 0.0,
		82.41, 0.0, 55.0, 0.0, 73.42, 0.0, 65.41, 0.0,
		55.0, 0.0, 55.0, 0.0, 65.41, 0.0, 55.0, 0.0,
		98.0, 0.0, 82.41, 0.0, 73.42, 0.0, 65.41, 0.0,
	]
	var lead: Array = [
		220.0, 0.0, 261.63, 329.63, 0.0, 293.66, 0.0, 0.0,
		220.0, 0.0, 196.0, 0.0, 246.94, 0.0, 261.63, 0.0,
		220.0, 0.0, 261.63, 329.63, 0.0, 392.0, 0.0, 329.63,
		293.66, 0.0, 246.94, 0.0, 220.0, 0.0, 0.0, 0.0,
	]
	var total := int(STEPS * step * MIX)
	var buf := PackedFloat32Array()
	buf.resize(total)
	for s in STEPS:
		var off := int(s * step * MIX)
		if bass[s] > 0.0:
			var nb := Music._note(bass[s], step * 0.95, 0.20, 0.5)
			for i in nb.size():
				buf[off + i] += nb[i]
		if lead[s] > 0.0:
			var nl := Music._note(lead[s], step * 1.8, 0.10, 0.25)
			for i in nl.size():
				if off + i < total:
					buf[off + i] += nl[i]
	var b := PackedByteArray()
	b.resize(total * 2)
	for i in total:
		var v := int(clampf(buf[i] * 0.8, -1.0, 1.0) * 32000.0)
		b[i * 2] = v & 0xFF
		b[i * 2 + 1] = (v >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = total
	wav.data = b
	return wav


func _ready() -> void:
	var p := AudioStreamPlayer.new()
	p.stream = _build_loop()
	p.volume_db = -16.0
	p.name = "MusicPlayer"
	add_child(p)
	p.play()
```

### 2. `scripts/game.gd` — instanciar y tecla M

2.1. En `_setup_input()`, añade al diccionario `defs`:

```gdscript
	"toggle_music": [KEY_M],
```

2.2. Añade variable de instancia junto a `var msg_tween: Tween`:

```gdscript
var music: Music
```

2.3. Al final de `_ready()`, añade:

```gdscript
	music = Music.new()
	add_child(music)
```

2.4. En `_physics_process`, después del bloque de `"toggle_bot"` o del de
`match_over` (da igual, antes de la lógica de jugadores), añade:

```gdscript
	if Input.is_action_just_pressed("toggle_music"):
		var mp := music.get_node_or_null("MusicPlayer") as AudioStreamPlayer
		if mp != null:
			if mp.playing:
				mp.stop()
			else:
				mp.play()
```

### 3. Pista visual

En `_build_hud()`, en el texto del `hint`, añade al final `    M: música`.

## Qué NO hacer

- No uses archivos de audio ni importes nada: la música se genera en memoria.
- No pases de ~8 s de bucle (32 pasos a 132 BPM ≈ 3,6 s: perfecto).
- No subas el volumen por encima de -12 dB: los efectos sonoros deben oírse encima.

## Criterios de aceptación

1. Al arrancar suena un bucle musical tenue (bajo + melodía) que no se corta.
2. M lo silencia y lo reactiva.
3. El smoke test sigue pasando en headless sin errores de audio.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`
(el sonido se comprueba con F5).


---

# Tarea 12 — Rodar (esquiva rápida)

**Dificultad:** media · **Archivos:** `scripts/player.gd` · **Prerrequisitos:** ninguno

## Objetivo

Nueva movilidad: manteniendo **abajo** (estancia baja) y pulsando **saltar**, el
duelist rueda hacia donde mira: un voltereta rápida de 0,34 s que cuenta como
estancia baja (los ataques altos te fallan, los medios y bajos te pillan) y con
0,55 s de recuperación.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/player.gd` — `class_name Player` (CharacterBody2D):
	- `enum State {IDLE, RUN, JUMP, DIVEKICK, ATTACK, STUNNED, KNOCKDOWN, DEAD}`
	  (índices 0–7; el smoke test los usa por número: **añade ROLL AL FINAL del
	  enum, nunca en medio**).
	- Constantes de movimiento arriba del todo (`SPEED`, `JUMP_VELOCITY`, ...).
	- En `_physics_process` hay un bloque `if can_act:` que gestiona input:
	  primero salto (`if hit("jump") and is_on_floor():`), luego ataque, luego
	  lanzamiento. `can_act` exige `state in [State.IDLE, State.RUN, State.JUMP]`.
	- Después hay DOS `match state:`: uno avanza temporizadores/estados (casos
	  ATTACK, STUNNED, KNOCKDOWN) y otro fija `velocity.x` (casos IDLE/RUN, JUMP,
	  ATTACK, STUNNED/KNOCKDOWN).
	- La defensa de ataques la resuelve `game.gd::_resolve_attacks()` leyendo
	  `def.stance`: ataque alto contra estancia baja = "miss" (falla). Forzar
	  `stance = H.LOW` durante la rodada reutiliza esa regla sin tocar `game.gd`.
	- `_draw()` empieza con una cadena de `if state == State.KNOCKDOWN: ... elif
	  state == State.DIVEKICK: ...` que fija transform (`t_pos`, `t_rot`, `t_scl`).
	- Input: `held(n)` pulsada, `hit(n)` recién pulsada (n = "left", "right",
	  "up", "down", "jump", "attack", "throw").
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Enum, constantes y variables

1.1. Cambia la línea del enum State por (ROLL al final, índice 8):

```gdscript
enum State { IDLE, RUN, JUMP, DIVEKICK, ATTACK, STUNNED, KNOCKDOWN, DEAD, ROLL }
```

1.2. Junto a las demás constantes, añade:

```gdscript
const ROLL_DURATION := 0.34
const ROLL_SPEED := 520.0
const ROLL_COOLDOWN := 0.55
```

1.3. Junto a las demás variables de instancia, añade:

```gdscript
var roll_time := 0.0
var roll_cd := 0.0
```

### 2. Enfriamiento

En `_physics_process`, junto a `flash_time = maxf(...)` (los temporizadores que
se descuentan al principio), añade:

```gdscript
	roll_cd = maxf(0.0, roll_cd - delta)
```

### 3. Disparador (antes que el salto normal)

En el bloque `if can_act:`, la primera línea es `if hit("jump") and is_on_floor():`.
Inserta la rodada POR DELANTE, de modo que quede:

```gdscript
		if hit("jump") and held("down") and is_on_floor() and roll_cd <= 0.0:
			state = State.ROLL
			roll_time = 0.0
			roll_cd = ROLL_COOLDOWN
			stance = H.LOW
			_sfx("swing", -22.0)
		elif hit("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			state = State.JUMP
			_sfx("jump", -16.0)
```

(las ramas `elif hit("attack"):` y `elif hit("throw")...` siguientes no cambian).

### 4. Avance del estado

4.1. En el PRIMER `match state:` (el de temporizadores), añade el caso:

```gdscript
		State.ROLL:
			roll_time += delta
			if roll_time >= ROLL_DURATION:
				state = State.IDLE
```

4.2. En el SEGUNDO `match state:` (el de velocidad), añade el caso:

```gdscript
		State.ROLL:
			velocity.x = facing * ROLL_SPEED
			stance = H.LOW
```

### 5. Dibujo (voltereta)

En `_draw()`, en la cadena de transforms, añade una rama después de
`if state == State.KNOCKDOWN: ...`:

```gdscript
		elif state == State.ROLL:
			t_rot = -TAU * (roll_time / ROLL_DURATION)
			t_pos = Vector2(0, 14)
			t_scl = Vector2(0.9, 0.9)
```

## Qué NO hacer

- No cambies el orden del enum ni los índices 0–7.
- No hagas la rodada invulnerable a todo: solo hereda la regla de "ataque alto
  falla contra estancia baja" (ya pasa al forzar `stance`).
- No permitas atacar ni saltar durante la rodada (`can_act` ya lo impide: no
  añadas ROLL a esa lista).

## Criterios de aceptación

1. Mantener S (o ↓) y pulsar W (o ↑): voltereta rápida hacia donde miras.
2. Sin mantener abajo, W salta normal (el salto no se ha roto).
3. Durante la rodada, un ataque alto del rival falla; uno medio o bajo mata.
4. No puedes encadenar rodadas sin parar (hay 0,55 s de recuperación).
5. El smoke test sigue pasando.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.


---

# Tarea 13 — Puñetazo cuando estás desarmado

**Dificultad:** media · **Archivos:** `scripts/player.gd`, `scripts/game.gd` · **Prerrequisitos:** ninguno

## Objetivo

Que un duelist sin espada (porque la lanzó) pueda pelear: el botón de ataque en
el suelo hace un **puñetazo** corto que no mata, pero derriba al rival
(knockdown). Si el rival defiende a tu misma altura, hay choque como siempre.
Así, lanzar la espada deja de ser jugada suicida.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/player.gd` — `class_name Player` (CharacterBody2D):
	- En el bloque `if can_act:` de `_physics_process`, la rama de ataque es
	  `elif hit("attack"):` → si está en el suelo Y `has_sword`, entra en
	  `State.ATTACK`; si está en el aire, patada voladora.
	- `has_sword: bool`; `attack_is_active()`, `attack_ext()` y `attack_height`
	  sirven igual para el puñetazo (reutiliza el estado ATTACK).
	- `_draw()` dibuja la espada en el bloque `if has_sword:` (última parte).
- `scripts/game.gd`:
	- `_resolve_attacks()` es donde un ataque conecta: comprueba rango con la
	  constante `Player.ATTACK_RANGE` (86) y resuelve el `match outcome:` con
	  casos `"kill"`, `"trade"`, `"clash"` y `_`.
	- `_kill(def, atk)` mata de verdad; `def.knockdown(push)` derriba (lo usa la
	  patada voladora en `_resolve_divekicks()`).
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. `scripts/player.gd` — atacar sin espada

1.1. Junto a las demás constantes, añade:

```gdscript
const PUNCH_RANGE := 50.0
```

1.2. En el bloque `if can_act:`, la rama de ataque es hoy:

```gdscript
			elif hit("attack"):
				if is_on_floor():
					if has_sword:
						state = State.ATTACK
						...
```

Sustitúyela por (el puñetazo reutiliza ATTACK sin exigir espada):

```gdscript
			elif hit("attack"):
				if is_on_floor():
					state = State.ATTACK
					attack_time = 0.0
					attack_resolved = false
					attack_height = stance
					_sfx("swing", -20.0)
				else:
					state = State.DIVEKICK
					divekick_resolved = false
					stance = H.MID
					velocity = Vector2(facing * 430.0, 440.0)
					_sfx("swing", -20.0)
```

(el contenido es el mismo que ya había; solo desaparece el `if has_sword:`).

1.3. En `_draw()`, después del bloque `if has_sword:` completo, añade el puño:

```gdscript
		elif state == State.ATTACK:
			var pext := attack_ext()
			if pext > 0.05:
				draw_circle(Vector2(10.0 + pext * 16.0, -6.0), 5.0, c)
```

### 2. `scripts/game.gd` — alcance y efecto del puñetazo

2.1. Nueva helper (junto a `_clash()` está bien):

```gdscript
func _melee_hit(atk: Player, def: Player) -> void:
	if atk.has_sword:
		_kill(def, atk)
	else:
		var push := 1 if def.position.x >= atk.position.x else -1
		def.knockdown(push)
		_burst(def.position, Color(1, 1, 1), 8, 200.0)
		sfx(def.position, "hit", -10.0)
```

2.2. En `_resolve_attacks()`, sustituye la comprobación de rango:

```gdscript
		if dx < -16.0 or dx > Player.ATTACK_RANGE:
			continue
```

por:

```gdscript
		var rng := Player.PUNCH_RANGE if not atk.has_sword else Player.ATTACK_RANGE
		if dx < -16.0 or dx > rng:
			continue
```

2.3. En el `match outcome:` de `_resolve_attacks()`, sustituye los casos
`"kill"` y `"trade"` por:

```gdscript
			"kill":
				_melee_hit(atk, def)
			"trade":
				_melee_hit(atk, def)
				_kill(atk, null)
```

(`"clash"` y `_` se quedan igual: un puñetazo a la altura defendida choca
como una espada).

## Qué NO hacer

- No cambies la patada voladora (ataque en el aire): sigue igual con o sin espada.
- No dejes que el puñetazo mate: solo derriba. La espada mata; el puño controla.
- No toques el lanzamiento de espada ni su recogida.

## Criterios de aceptación

1. Tras lanzar la espada, atacar en el suelo saca el puño (visual de puño breve).
2. El puñetazo a un rival desprevenido lo derriba, no lo mata.
3. El puñetazo contra defensa a la misma altura produce choque (ambos rebotes).
4. Un puñetazo no alcanza a la distancia a la que sí llega una espada (50 vs 86).
5. Con espada equipada todo funciona exactamente como antes.
6. El smoke test sigue pasando (sus duelos usan espada).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.


---

# Tarea 14 — Ampliar el smoke test (5 casos nuevos)

**Dificultad:** media · **Archivos:** `test/smoke_test.gd` · **Prerrequisitos:** ninguno

## Objetivo

Añadir al test headless cinco verificaciones nuevas: patada voladora derriba,
el foso mata, la guardia media desvía la espada lanzada, el rival reaparece
DELANTE del corredor (la mecánica central del juego) y la revancha con R.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg.
- `test/smoke_test.gd` — prueba headless: instancia `res://scenes/main.tscn` en
  `game`, toma `p1`/`p2` de `game.players`, simula input con
  `Input.action_press/release` y espera con `await get_tree().create_timer(...)`.
  Termina con `print("")`, el bloque `if fails.is_empty()` y `get_tree().quit(...)`.
  Estados de Player por número: 0 IDLE, 1 RUN, 2 JUMP, 3 DIVEKICK, 4 ATTACK,
  5 STUNNED, 6 KNOCKDOWN, 7 DEAD.
- Datos del juego que usa esta prueba:
	- Suelo a y=560; los jugadores en pie están a y=531.
	- Foso central x∈(2210, 2380), cubierto por una plataforma a y=448: para
	  morir en él hay que colocarse DEBAJO de la plataforma (y≥500).
	- Muerte por caída: `position.y > 820`.
	- Reaparición: `RESPAWN_DELAY = 2.4` s, delante del corredor a ~540 px en la
	  dirección de su meta (P1 corre a la derecha).
	- Espada lanzada: vuela a 760 px/s a la altura del lanzador (~y-8); un rival
	  en pie SIN pulsar arriba/abajo está en guardia MEDIA y la desvía.
	- Partido a 3 puntos (`WIN_SCORE`); con `match_over`, la tecla R reinicia.
- Coordenadas elegidas para no chocar con las zonas que usan otros cambios
  posibles del proyecto (hierba 1150–1450, escalera 1480–1900, foso nuevo
  700–880): trabajamos en x≈1600–1750, 2295 y 2900–2955.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

En `test/smoke_test.gd`, inserta el siguiente bloque DESPUÉS del test 7 (el del
lanzamiento de espada, que acaba con `_check(game.projectiles.size() == 1, ...)`)
y ANTES de la línea `print("")` final:

```gdscript
	# 8. Patada voladora derriba al rival
	for s in game.projectiles:
		s.queue_free()
	game.projectiles.clear()
	p1.position = Vector2(2900.0, 380.0)
	p2.position = Vector2(2955.0, 531.0)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.facing = 1
	await get_tree().physics_frame
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.05).timeout
	Input.action_release("p1_attack")
	await get_tree().create_timer(0.5).timeout
	_check(p2.state == 6, "Patada voladora derriba al rival (KNOCKDOWN)")
	await get_tree().create_timer(1.2).timeout

	# 9. Caer al foso central mata (colocándolo bajo la plataforma)
	p1.position = Vector2(2295.0, 500.0)
	p1.velocity = Vector2.ZERO
	await get_tree().create_timer(1.2).timeout
	_check(p1.state == 7, "Caer al foso central mata")

	# 10. La guardia media desvía la espada lanzada
	await get_tree().create_timer(1.5).timeout
	for pk in game.pickups:
		pk.queue_free()
	game.pickups.clear()
	p1.position = Vector2(1600.0, 531.0)
	p2.position = Vector2(1750.0, 531.0)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.state = 0
	p2.state = 0
	p1.facing = 1
	p1.has_sword = true
	await get_tree().physics_frame
	Input.action_press("p1_throw")
	await get_tree().create_timer(0.05).timeout
	Input.action_release("p1_throw")
	await get_tree().create_timer(0.35).timeout
	_check(p2.state != 7, "La guardia media desvía la espada lanzada")
	_check(game.pickups.size() == 1, "La espada desviada cae al suelo")

	# 11. El rival reaparece delante del corredor, hacia su meta
	p1.has_sword = true
	p2.has_sword = true
	p1.position = Vector2(1600.0, 531.0)
	p2.position = Vector2(1670.0, 531.0)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.state = 0
	p2.state = 0
	p1.facing = 1
	Input.action_press("p2_up")
	await get_tree().create_timer(0.1).timeout
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.16).timeout
	Input.action_release("p1_attack")
	Input.action_release("p2_up")
	_check(p2.state == 7, "P2 muere de nuevo")
	var x_p1: float = p1.position.x
	await get_tree().create_timer(2.6).timeout
	_check(p2.state != 7, "P2 reaparece tras el retardo")
	_check(p2.position.x > x_p1 + 400.0, "Reaparece delante del corredor, hacia la meta de P1")

	# 12. Revancha: el tercer punto termina el partido y R lo reinicia
	game.scores = [2, 0]
	game.right_of_way = game.players[0]
	p1.position = Vector2(4770.0, 531.0)
	p1.velocity = Vector2.ZERO
	await get_tree().create_timer(0.2).timeout
	_check(game.match_over, "El tercer punto termina el partido")
	Input.action_press("restart")
	await get_tree().create_timer(0.05).timeout
	Input.action_release("restart")
	await get_tree().create_timer(0.3).timeout
	_check(game.scores == [0, 0] and not game.match_over, "R reinicia el marcador")
	_check(p1.state == 0 and p2.state == 0, "R reinicia la ronda")
```

Notas sobre por qué funciona (por si hay que depurar):

- Test 8: la patada se lanza en el aire (P1 está a y=380, sin suelo); su
  trayectoria fija es `x += 430·t`, `y = 380 + 440·t + 850·t²`, y pasa por la
  ventana de impacto de P2 (|dx|≤44, |dy|≤64) entre t≈0.15 y t≈0.23.
- Test 9: y=500 queda por debajo de la plataforma (448–464), así que P1 cae
  dentro del hueco hasta pasar y=820.
- Test 10: P2 en pie y sin pulsar arriba/abajo está en guardia media, la única
  que desvía el proyectil.
- Test 11: P2 defendiendo en HIGH contra ataque MID muere; P1 queda como
  corredor y P2 debe reaparecer a ~540 px a su derecha.
- Test 12: fijar `scores=[2,0]` y `right_of_way` al P1 junto a su meta dispara
  `_point` en el primer frame físico, completando el partido.

## Qué NO hacer

- No cambies los tests 1–7 existentes ni sus esperas.
- No acortes las esperas indicadas: absorben reapariciones y recuperaciones.
- No uses `game.right_of_way = p1` (error de tipos en GDScript): usa
  `game.players[0]` como está escrito.

## Criterios de aceptación

1. El test imprime los 12 "ok" (los 7 antiguos y los 5 bloques nuevos, que son
   7 comprobaciones) y termina con `SMOKE OK`.
2. Si lo ejecutas dos veces seguidas, pasa las dos veces (sin estado residual).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.


---

# Tarea 15 — Pausa con ESC

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** ninguno

## Objetivo

Pausar el juego con **ESC**: pantalla oscurecida con el texto "PAUSA", todo el
juego congelado (jugadores, partículas, cámara). Con ESC de nuevo se reanuda.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/game.gd` — nodo principal:
	- `_setup_input()` registra acciones de teclado en runtime en el
	  diccionario `defs` (patrón: `"restart": [KEY_R],`).
	- `_ready()` construye todo; `_build_hud()` crea un `CanvasLayer` (`cl`,
	  layer 10) con labels (patrón: `Label.new()` + `add_child` a `cl`).
	- `_physics_process(delta)` empieza con `shake_time = maxf(...)`.
	- Vista: `VIEW_W=1152`, `VIEW_H=648`.
- Godot: `get_tree().paused = true` congela los nodos `PROCESS_MODE_PAUSABLE`
  (los jugadores lo son por defecto). Para que el nodo `game` SIGA leyendo ESC
  mientras está pausado, hay que ponerlo en `PROCESS_MODE_ALWAYS` y salir a
  mano de `_physics_process` cuando esté pausado (si no, seguiría simulando).
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Acción de pausa

En `_setup_input()`, añade al diccionario `defs`:

```gdscript
	"pause": [KEY_ESCAPE],
```

### 2. Modo de proceso del nodo game

En `_ready()`, como PRIMERA línea, añade:

```gdscript
	process_mode = Node.PROCESS_MODE_ALWAYS
```

### 3. Variables

Junto a `var msg_label: Label`, añade:

```gdscript
var dim: ColorRect
var pause_label: Label
```

### 4. Overlay de pausa

En `_build_hud()`, después del bloque que crea `hint`, añade:

```gdscript
	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size = Vector2(VIEW_W, VIEW_H)
	dim.visible = false
	cl.add_child(dim)

	pause_label = Label.new()
	pause_label.text = "PAUSA"
	pause_label.position = Vector2(0, VIEW_H * 0.4)
	pause_label.size = Vector2(VIEW_W, 80)
	pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_label.add_theme_font_size_override("font_size", 64)
	pause_label.add_theme_color_override("font_color", Color.WHITE)
	pause_label.visible = false
	cl.add_child(pause_label)
```

### 5. Toggle y corte de la simulación

En `_physics_process`, como PRIMERAS líneas (antes de `shake_time = ...`), añade:

```gdscript
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = not get_tree().paused
		dim.visible = get_tree().paused
		pause_label.visible = get_tree().paused
	if get_tree().paused:
		return
```

## Qué NO hacer

- No pongas `PROCESS_MODE_ALWAYS` en los jugadores o el HUD dinámico: solo el
  nodo `game` necesita seguir corriendo (para leer ESC).
- No dejes que R (revancha) funcione mientras está pausado: el `return` del
  paso 5 ya lo evita; no lo muevas de sitio.
- No pauses desde `_process` (el juego usa `_physics_process` para la lógica).

## Criterios de aceptación

1. ESC congela todo al instante y oscurece la pantalla con "PAUSA".
2. ESC de nuevo reanuda exactamente donde estaba (posiciones, timers, partículas).
3. Mientras está pausado, ningún input del juego tiene efecto.
4. El smoke test sigue pasando (ESC nunca se pulsa allí).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.


---

# Tarea 16 — Soporte de mando (2 gamepads)

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** ninguno

## Objetivo

Mapear dos mandos: P1 usa el gamepad 0 y P2 el gamepad 1. Stick izquierdo para
moverse/estancias; botones: A (inferior) saltar, X (izquierdo) atacar,
B (derecho) lanzar espada; START para la revancha. El teclado sigue funcionando.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/game.gd` — `_setup_input()` registra las acciones de teclado en
  runtime: construye `InputEventKey` con `physical_keycode` y los añade con
  `InputMap.action_add_event(...)`. Las acciones son `p1_left`, `p1_right`,
  `p1_up`, `p1_down`, `p1_jump`, `p1_attack`, `p1_throw`, `p2_...` y `restart`.
- Godot: un mismo `InputMap` admite eventos de teclado Y de mando para la misma
  acción; basta añadir más eventos. Para sticks se usa `InputEventJoypadMotion`
  (`device`, `axis`, `axis_value` con signo −1/1); para botones
  `InputEventJoypadButton` (`device`, `button_index`). Con `device = -1` el
  evento acepta cualquier mando.
- El smoke test no tiene mandos conectados: como las acciones de teclado no se
  tocan, no puede romperse.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Mapeos

En `_setup_input()`, DESPUÉS del bucle `for action in defs.keys():` que registra
el teclado, añade:

```gdscript
	# mandos: P1 = gamepad 0, P2 = gamepad 1
	var pad_axes := {
		"p1_left": [0, JOY_AXIS_LEFT_X, -1.0], "p1_right": [0, JOY_AXIS_LEFT_X, 1.0],
		"p1_up": [0, JOY_AXIS_LEFT_Y, -1.0], "p1_down": [0, JOY_AXIS_LEFT_Y, 1.0],
		"p2_left": [1, JOY_AXIS_LEFT_X, -1.0], "p2_right": [1, JOY_AXIS_LEFT_X, 1.0],
		"p2_up": [1, JOY_AXIS_LEFT_Y, -1.0], "p2_down": [1, JOY_AXIS_LEFT_Y, 1.0],
	}
	var pad_buttons := {
		"p1_jump": [0, JOY_BUTTON_A], "p1_attack": [0, JOY_BUTTON_X], "p1_throw": [0, JOY_BUTTON_B],
		"p2_jump": [1, JOY_BUTTON_A], "p2_attack": [1, JOY_BUTTON_X], "p2_throw": [1, JOY_BUTTON_B],
		"restart": [-1, JOY_BUTTON_START],
	}
	for action in pad_axes.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var ev := InputEventJoypadMotion.new()
		ev.device = pad_axes[action][0]
		ev.axis = pad_axes[action][1]
		ev.axis_value = pad_axes[action][2]
		InputMap.action_add_event(action, ev)
	for action in pad_buttons.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var eb := InputEventJoypadButton.new()
		eb.device = pad_buttons[action][0]
		eb.button_index = pad_buttons[action][1]
		InputMap.action_add_event(action, eb)
```

### 2. Pista visual (opcional pero recomendada)

En `_build_hud()`, en el texto del `hint`, añade al final:
`    Mando: stick + A saltar · X atacar · B lanzar`.

## Qué NO hacer

- No elimines ni modifiques los eventos de teclado existentes.
- No uses `device = 0` para el `restart`: va con `-1` (cualquier mando).
- No inventes calibraciones de zona muerta: usa las acciones tal cual.

## Criterios de aceptación

1. Con dos mandos conectados, cada jugador controla a su duelist con el suyo.
2. El teclado sigue funcionando a la vez que los mandos.
3. START funciona para la revancha desde cualquier mando.
4. El smoke test sigue pasando sin mandos.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`
(los mandos se prueban a mano con F5).


---

# Tarea 17 — La espada desviada sobre el foso cae en el borde

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** ninguno

## Objetivo

Arreglar una pérdida permanente: hoy, si una espada lanzada es desviada (o te
matan) con la espada pasando por encima del foso central, `_drop_sword` la
descarta si su x cae dentro del foso y NADIE puede rearmarse hasta morir o
acabar la ronda. Tras el fix, la espada cae en el borde del foso más cercano y
siempre se puede recoger.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/game.gd`:
	- `_drop_sword(pos: Vector2, col: Color)` se llama cuando una espada
	  lanzada termina (golpea muro, matan a su dueño... o la desvía un rival).
	  Hoy hace:
	  ```gdscript
	  var x := clampf(pos.x, 30.0, LEVEL_W - 30.0)
	  if x > PIT_X0 and x < PIT_X1:
		  return   # <-- la espada se pierde para siempre
	  ```
	  y después crea un `SwordPickup` en `(x, _surface_y(x, pos.y) - 12)`.
	- Foso central: `PIT_X0=2210`, `PIT_X1=2380`. Suelo: `GROUND_Y=560`.
	- Caso típico: el rival espera en la PLATAFORMA del foso (y=448) en guardia
	  media y desvía la espada en x≈2300 → hoy desaparece.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Helper de expulsión del foso

Añade esta función a `scripts/game.gd` (junto a `_drop_sword`):

```gdscript
func _out_of_pit(x: float) -> float:
	if x > PIT_X0 - 34.0 and x < PIT_X1 + 34.0:
		return PIT_X0 - 40.0 if x < (PIT_X0 + PIT_X1) * 0.5 else PIT_X1 + 40.0
	return x
```

### 2. Usarlo en `_drop_sword`

Sustituye las dos líneas:

```gdscript
	var x := clampf(pos.x, 30.0, LEVEL_W - 30.0)
	if x > PIT_X0 and x < PIT_X1:
		return
```

por:

```gdscript
	var x := _out_of_pit(clampf(pos.x, 30.0, LEVEL_W - 30.0))
```

(El `return` desaparece: ya nunca se descarta la espada por caer en el foso.
El margen de 34 px hace que también se expulsen las caídas justo al filo.)

### 3. Si el proyecto tiene un segundo foso

Si en `game.gd` existen las constantes `PIT2_X0`/`PIT2_X1` (añadidas por la
tarea del segundo foso), extiende el helper así en lugar del paso 1:

```gdscript
func _out_of_pit(x: float) -> float:
	if x > PIT_X0 - 34.0 and x < PIT_X1 + 34.0:
		return PIT_X0 - 40.0 if x < (PIT_X0 + PIT_X1) * 0.5 else PIT_X1 + 40.0
	if x > PIT2_X0 - 34.0 and x < PIT2_X1 + 34.0:
		return PIT2_X0 - 40.0 if x < (PIT2_X0 + PIT2_X1) * 0.5 else PIT2_X1 + 40.0
	return x
```

## Qué NO hacer

- No cambies `_surface_y()` ni la posición vertical del pickup.
- No hagas reaparecer la espada en manos del dueño: cae al borde y hay que
  pasarse a por ella (así sigue habiendo riesgo al lanzar).
- No toques `_update_pickups()`.

## Criterios de aceptación

1. Colócate en la plataforma del foso en guardia media y desvía una espada
   lanzada: la espada cae ahora en un borde del foso (con su halo blanco
   pulsante) y se puede recoger.
2. Ya no existe ninguna x del nivel donde la espada desaparezca sin dejar pickup.
3. El smoke test sigue pasando.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`
(comprobación rápida extra desde el juego: lanzar la espada desde la plataforma
hacia un rival que la desvíe encima del foso).


---

# Tarea 18 — Estocada (embestida al atacar corriendo)

**Dificultad:** media · **Archivos:** `scripts/player.gd` · **Prerrequisitos:** ninguno

## Objetivo

El movimiento firma de Nidhogg: si atacas con espada MIENTRAS te mueves, el
ataque se convierte en una estocada — te lanzas hacia delante a 620 px/s con la
espada extendida. Atacar parado queda como está. Da juego ofensivo al suelo y
combina con la rodada (esquiva) para un juego de entradas y salidas.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Todo el
  arte es procedural (`_draw()`) y los sonidos se generan por código: **no hay
  assets externos ni plugins**.
- `scripts/player.gd` — `class_name Player` (CharacterBody2D):
	- Estados: `enum State {IDLE, RUN, JUMP, DIVEKICK, ATTACK, STUNNED, KNOCKDOWN,
	  DEAD}` (índices 0–7; el smoke test depende de ellos: no los cambies).
	- Constantes: `ATTACK_DURATION := 0.30`, `ATTACK_FROM/TO` (ventana activa del
	  golpe), `ATTACK_RANGE := 86`.
	- En `_physics_process`, el bloque `if can_act:` contiene la rama
	  `elif hit("attack"):` que entra en `State.ATTACK` si hay espada y suelo.
	- Más abajo hay un `match state:` que fija velocidades; su caso ATTACK es:
	  `velocity.x = move_toward(velocity.x, facing * 110.0, 900.0 * delta)`
	  (el pequeño avance del ataque actual).
	- Input: `held(n)` = pulsada, `hit(n)` = recién pulsada (n = "left",
	  "right", "up", "down", "jump", "attack", "throw").
	- La resolución de golpes la hace `game.gd` leyendo `attack_is_active()`;
	  reutilizar `State.ATTACK` para la estocada evita tocar `game.gd`.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Constante y variable

1.1. Junto a las demás constantes de combate, añade:

```gdscript
const LUNGE_SPEED := 620.0
```

1.2. Junto a las demás variables de instancia, añade:

```gdscript
var attack_dash_time := 0.0   # > 0 mientras la estocada empuja hacia delante
```

1.3. En `_physics_process`, junto a los temporizadores que se descuentan al
principio (`invuln_time = maxf(...)`, `flash_time = maxf(...)`), añade:

```gdscript
	attack_dash_time = maxf(0.0, attack_dash_time - delta)
```

### 2. Disparador

En el bloque `if can_act:`, rama `elif hit("attack"):`, el caso de suelo con
espada es hoy:

```gdscript
				if is_on_floor():
					if has_sword:
						state = State.ATTACK
						attack_time = 0.0
						attack_resolved = false
						attack_height = stance
						_sfx("swing", -20.0)
```

Sustitúyelo por:

```gdscript
				if is_on_floor():
					if has_sword:
						state = State.ATTACK
						attack_time = 0.0
						attack_resolved = false
						attack_height = stance
						if held("right") or held("left"):
							attack_dash_time = ATTACK_DURATION
							velocity.x = facing * LUNGE_SPEED
						_sfx("swing", -20.0)
```

### 3. Velocidad durante la estocada

En el `match state:` de velocidades, sustituye el caso ATTACK:

```gdscript
			State.ATTACK:
				if attack_dash_time > 0.0:
					velocity.x = facing * LUNGE_SPEED
				else:
					velocity.x = move_toward(velocity.x, facing * 110.0, 900.0 * delta)
```

### 4. Inclinación visual (opcional pero recomendada)

En `_draw()`, en la cadena de transforms (la de `if state == State.KNOCKDOWN:
... elif state == State.DIVEKICK: ... elif state == State.STUNNED: ...`),
añade una rama después de la de STUNNED:

```gdscript
		elif state == State.ATTACK and attack_dash_time > 0.0:
			t_rot = 0.3
```

## Qué NO hacer

- No crees un estado nuevo: la estocada ES un `State.ATTACK` con empuje, para
  que choques, muertes y ventana de golpe sigan funcionando igual.
- No apliques estocada a la patada voladora ni a ataques sin espada.
- No permitas estocada en el aire (el `is_on_floor()` del disparador ya lo evita).

## Criterios de aceptación

1. Atacar parado: golpe normal con su pequeño avance (igual que antes).
2. Atacar manteniendo A/D (o ←/→): embestida rápida hacia delante con la espada
   extendida, ~190 px de recorrido.
3. La estocada puede chocar (defensa a tu altura) y matar como cualquier ataque.
4. La estocada sale hacia donde YA mirabas, no hacia la tecla recién pulsada
   (comportamiento intencional: el ataque fija la dirección).
5. Si en partida resulta demasiado fuerte, baja `LUNGE_SPEED` a 540.
6. El smoke test sigue pasando (sus ataques son siempre parado).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.


---

# Tarea 19 — El choque desarma al que ataca en alto

**Dificultad:** media · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** ninguno

## Objetivo

Endurecer el riesgo de la estancia alta: cuando dos espadas chocan (`_clash`),
quien ATACABA con la espada en alto pierde la espada — sale despedida y cae al
suelo unos metros detrás, recogible como cualquier espada lanzada. Si ambos
atacaban en alto, los dos quedan desarmados. Esto convierte el spam de ataque
alto en una apuesta y crea duelos desesperados a puñetazo/patada hasta
recuperar el arma.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/game.gd`:
	- `_clash(a: Player, b: Player)` es donde se resuelve todo choque (lo llaman
	  el choque de ataques y el choque ataque-vs-patada). Hoy hace: destello
	  (`_burst`), sonido, sacudida (`shake_time`) y `take_clash(push)` para
	  empujar a los dos.
	- `take_clash()` cambia el estado del jugador a STUNNED: por eso las
	  condiciones del desarme hay que leerlas ANTES de llamarlo.
	- `_drop_sword(pos, col)` crea la espada caída (`SwordPickup`) en el suelo
	  bajo esa posición; se recoge pasando por encima (`_update_pickups` solo la
	  recogen jugadores con `has_sword == false`).
	- `Player` tiene `has_sword`, `attack_height` (estancia del golpe:
	  `H.LOW/MID/HIGH`) y `state` (`State.ATTACK`, `State.DIVEKICK`, ...).
	- La patada voladora choca vía `_clash(def, p)` con `p` en DIVEKICK: quien
	  patea NO debe poder ser desarmado (no lleva la espada en el golpe).
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

Sustituye en `scripts/game.gd` la función `_clash` COMPLETA por:

```gdscript
func _clash(a: Player, b: Player) -> void:
	var mid := Vector2((a.position.x + b.position.x) * 0.5, minf(a.position.y, b.position.y) - 14.0)
	_burst(mid, Color(1.0, 0.93, 0.55), 14, 320.0)
	sfx(mid, "clash", -8.0)
	shake_time = maxf(shake_time, 0.14)
	# el choque desarma a quien atacaba con la espada en alto
	var disarmed: Array[Player] = []
	for p in [a, b]:
		if p.state == Player.State.ATTACK and p.attack_height == Player.H.HIGH and p.has_sword:
			disarmed.append(p)
	var push_b := 1 if b.position.x >= a.position.x else -1
	b.take_clash(push_b)
	a.take_clash(-push_b)
	for p in disarmed:
		p.has_sword = false
		_drop_sword(p.position + Vector2(-float(p.facing) * 110.0, -30.0), Color(0.87, 0.9, 0.95))
		_burst(p.position + Vector2(0, -20), Color(0.95, 0.95, 1.0), 8, 240.0)
		sfx(p.position, "throw", -14.0)
```

Puntos clave del código (para que lo entiendas, no para cambiarlo):

- La comprobación `p.state == Player.State.ATTACK` se hace ANTES de
  `take_clash()` porque después ambos ya están STUNNED; además excluye a quien
  patea en el aire (DIVEKICK).
- La espada cae DETRÁS del desarmado (`-facing * 110`) y algo elevada; `_drop_sword`
  la apoya en el suelo de debajo.
- Al perder `has_sword`, el dibujo de la espada desaparece solo (el bloque
  `if has_sword:` de `_draw()`).

## Qué NO hacer

- No desarmes a quien DEFENDÍA (solo a quien estaba atacando en alto): el
  defensor ya "ganó" el choque al leer la altura.
- No desarmes en choques de patada voladora.
- No mandes la espada volando como proyectil (`SwordProjectile`): cae directa
  al suelo como pickup; cruzarla en vuelo sería demasiado castigo.

## Criterios de aceptación

1. Atacar en alto contra defensa alta: choque y TU espada sale despedida hacia
   atrás y cae; quedas desarmado (sin espada visible) hasta recogerla.
2. Choque de dos ataques altos: ambos quedan desarmados.
3. Choques en media o baja: nadie pierde la espada (igual que antes).
4. La espada caída se recoge pasando por encima, con su halo pulsante.
5. El desarmado sigue poder hacer patada voladora (y puñetazo si aplicaste esa
   tarea) mientras busca su espada.
6. El smoke test sigue pasando (su choque del test 3 es MID vs MID).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.

Nota: sobre el foso central, `_drop_sword` descarta la espada dentro del hueco
(comportamiento actual del juego); la tarea del fix del foso (`17`) la reubica
en el borde si también la aplicas.


---

# Tarea 20 — Tajo de espada en el aire

**Dificultad:** baja · **Archivos:** `scripts/player.gd` · **Prerrequisitos:** ninguno

## Objetivo

Dar opción aérea con espada: si estás en el aire CON espada y mantienes
**arriba** o **abajo** al atacar, haces un tajo descendente a esa altura
(alta/baja) que MATA como un ataque normal. Sin dirección pulsada (o sin
espada), el ataque aéreo sigue siendo la patada voladora de siempre.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/player.gd` — `class_name Player` (CharacterBody2D):
	- Estados: `enum State {IDLE, RUN, JUMP, DIVEKICK, ATTACK, STUNNED, KNOCKDOWN,
	  DEAD}` (índices 0–7; el smoke test depende de ellos: no los cambies).
	- En `_physics_process`, la rama `elif hit("attack"):` distingue suelo
	  (ataque de espada) de aire (patada voladora `State.DIVEKICK`).
	- La estancia en el aire ya se actualiza solita: con `can_act` activo en
	  JUMP, mantener arriba/abajo pone `stance` en `H.HIGH`/`H.LOW`.
	- `State.ATTACK` funciona en el aire sin cambios: `attack_time` avanza en el
	  `match`, la gravedad aplica (`if not is_on_floor()`), y al aterrizar el
	  ataque continúa hasta agotar su duración.
	- Input: `held(n)` = pulsada, `hit(n)` = recién pulsada (n = "left",
	  "right", "up", "down", "jump", "attack", "throw").
- La resolución de golpes (`game.gd::_resolve_attacks`) no distingue aire de
  suelo: vale con estar en `State.ATTACK` en la ventana activa y a rango
  (|dx| ≤ 86, |dy| ≤ 92). Un tajo alto contra rival agachado falla; uno bajo
  contra agachado choca; uno bajo o medio contra rival de pie mata.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. La rama de ataque

En el bloque `if can_act:`, sustituye la rama `elif hit("attack"):` COMPLETA
(que hoy es suelo-con-espada / si-no patada voladora) por:

```gdscript
			elif hit("attack"):
				if is_on_floor():
					if has_sword:
						state = State.ATTACK
						attack_time = 0.0
						attack_resolved = false
						attack_height = stance
						_sfx("swing", -20.0)
				elif has_sword and (held("up") or held("down")):
					state = State.ATTACK
					attack_time = 0.0
					attack_resolved = false
					attack_height = stance
					velocity.y = maxf(velocity.y, -80.0)
					_sfx("swing", -20.0)
				else:
					state = State.DIVEKICK
					divekick_resolved = false
					stance = H.MID
					velocity = Vector2(facing * 430.0, 440.0)
					_sfx("swing", -20.0)
```

(Solo es NUEVO el `elif` central del tajo aéreo; el suelo y la patada voladora
quedan exactamente como estaban.)

Detalle del tajo: `velocity.y = maxf(velocity.y, -80.0)` corta el impulso hacia
arriba — es un compromiso descendente: saltas, eliges altura y te dejas caer
con la espada. La altura del golpe es tu estancia en el aire (`stance`), o sea
la tecla que mantengas al atacar.

### 2. Nada más que cambiar

- El dibujo ya cubre el caso: `_draw()` dibuja la espada según `attack_height`
  en `State.ATTACK`, en el aire también.
- La resolución en `game.gd` ya trata igual cualquier `State.ATTACK` activo.

## Qué NO hacer

- No toques la patada voladora: sin dirección pulsada o sin espada debe salir
  IDÉNTICA a la de hoy (el smoke test ampliado depende de ello).
- No permitas el tajo aéreo a estancia media (sin tecla): esa entrada es de la
  patada; el tajo exige elegir altura.
- No anules la gravedad ni flotes: solo se recorta el ascenso al iniciar el tajo.

## Criterios de aceptación

1. Salto + mantener W/↑ + ataque: tajo descendente en alto; contra un rival de
   pie lo mata, contra uno agachado falla.
2. Salto + mantener S/↓ + ataque: tajo en bajo; castiga a quien aguantaba abajo
   tras tu salto.
3. Salto + ataque sin dirección: patada voladora de siempre (derriba, no mata).
4. Sin espada, el ataque aéreo siempre es patada voladora.
5. Si aterrizas a mitad del tajo, el golpe termina de animarse en el suelo sin
   quedarse colgado.
6. El smoke test sigue pasando.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.


---

# Tarea 21 — Modo bot vs bot (espectáculo)

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos: tarea 01 aplicada**

## Objetivo

Tecla **N** para poner los DOS duelistas como bots y verlos pelear: un modo
espectáculo que además sirve de prueba visual del cerebro del bot (tarea 01) —
si algo va mal en su lógica, aquí se ve en segundos sin jugar tú.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- Esta tarea asume que la **tarea 01 ya está aplicada**: `player.gd` tiene
  `is_bot` + `bot_held`, y `game.gd` tiene `_bot_think(p, delta)` (llamada para
  cada jugador con `is_bot`), la acción `"toggle_bot"` (tecla B, solo P2) y el
  HUD con `show_msg(texto, dur)`.
- El cerebro es simétrico: usa `_other(p)` y `p.goal_dir`, así que sirve igual
  para P1 (corre a la derecha) que para P2 (corre a la izquierda) sin cambios.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Acción de teclado

En `_setup_input()`, añade al diccionario `defs`:

```gdscript
	"bot_vs_bot": [KEY_N],
```

### 2. Toggle

En `_physics_process`, justo después del bloque de `"toggle_bot"`, añade:

```gdscript
	if Input.is_action_just_pressed("bot_vs_bot"):
		var on := not players[0].is_bot
		players[0].is_bot = on
		players[1].is_bot = on
		show_msg("BOT vs BOT %s" % ("ACTIVADO" if on else "DESACTIVADO"), 0.7)
```

### 3. Pista visual

En `_build_hud()`, en el texto del label `hint`, añade al final `    N: bot vs bot`.

## Qué NO hacer

- No toques `_bot_think` ni `player.gd`: el modo funciona porque el cerebro ya
  es simétrico.
- No desactives la cámara ni el HUD: ver la persecución completa es el punto.
- No hagas que N afecte solo a un jugador: enciende o apaga los DOS.

## Criterios de aceptación

1. N activa el modo: los dos duelistas luchan solos (se acercan, cubren,
   atacan, lanzan espadas a veces).
2. Cuando uno mata, corre hacia SU meta y el otro reaparece para frenarlo; los
   puntos suben hasta que alguien gana el partido.
3. R sigue funcionando: tras una revancha, los bots siguen peleando solos.
4. N de nuevo devuelve el control humano a ambos (y B sigue gobernando solo a
   P2 de forma independiente).
5. El smoke test sigue pasando (N nunca se pulsa allí).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`
(el modo se disfruta abriendo el juego con F5 y pulsando N).


---

# Tarea 22 — Estadísticas en la pantalla de victoria

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** ninguno

## Objetivo

Medir el partido — bajas, muertes, espadas lanzadas y metros corridos de cada
jugador — y mostrarlo en la pantalla de victoria, bajo el "¡GANA P1!". Da
motivo de revancha y gratis, porque todos los eventos ya pasan por `game.gd`.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/game.gd` — nodo principal:
	- Variables: `players: Array[Player]`, `scores`, `match_over: bool`. Vista:
	  `VIEW_W=1152`, `VIEW_H=648`.
	- `_kill(def, atk)` es donde ocurren TODAS las muertes (`atk` es null en
	  dobles muertes y caídas al foso).
	- `_on_threw_sword(p)` se emite una vez por lanzamiento.
	- `_point(p)` gestiona el punto; su rama de victoria pone `match_over = true`
	  y muestra `show_msg("¡GANA P%d!  ·  R: revancha", ...)`.
	- El handler de revancha en `_physics_process` (`if match_over and
	  Input.is_action_just_pressed("restart")`) resetea `scores` y llama
	  `_start_round()`.
	- `_build_hud()` crea el `CanvasLayer` (`cl`) con labels (patrón: `Label.new()`
	  + overrides de tema + `cl.add_child`).
	- Los jugadores corren a 330 px/s ≈ 5,5 px por frame físico: un
	  desplazamiento > 60 px en un frame es un teletransporte (reaparición),
	  que NO debe contarse como carrera.
- Convención de "metro": 32 px = 1 m (el duelist mide ~58 px ≈ 1,80 m).
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Estado

Junto a las demás variables de instancia, añade:

```gdscript
var stats: Array[Dictionary] = []
var last_x := [0.0, 0.0]
var stats_label: Label


func _fresh_stats() -> Array[Dictionary]:
	return [
		{"kills": 0, "deaths": 0, "throws": 0, "dist": 0.0},
		{"kills": 0, "deaths": 0, "throws": 0, "dist": 0.0},
	]
```

Y en `_ready()`, como primera línea, inicializa: `stats = _fresh_stats()`.

### 2. Medir

2.1. En `_kill()`, justo después de `def.die()`, añade:

```gdscript
	stats[def.player_id - 1]["deaths"] += 1
	if atk != null:
		stats[atk.player_id - 1]["kills"] += 1
```

2.2. En `_on_threw_sword()`, después de la línea `sfx(p.position, "throw", -14.0)`, añade:

```gdscript
	stats[p.player_id - 1]["throws"] += 1
```

2.3. En `_physics_process`, después de la línea `p.frozen = match_over or
round_lock > 0.0` (el bucle que congela jugadores), añade:

```gdscript
	for i in players.size():
		var step := absf(players[i].position.x - last_x[i])
		if players[i].state != Player.State.DEAD and step < 60.0:
			stats[i]["dist"] += step
		last_x[i] = players[i].position.x
```

(El filtro `step < 60.0` descarta los teletransportes de reaparición y de
inicio de ronda.)

### 3. Mostrar

3.1. En `_build_hud()`, después del bloque de `hint`, añade:

```gdscript
	stats_label = Label.new()
	stats_label.position = Vector2(0, VIEW_H * 0.44)
	stats_label.size = Vector2(VIEW_W, 140)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 24)
	stats_label.add_theme_color_override("font_color", Color(0.85, 0.83, 0.90))
	stats_label.add_theme_color_override("font_outline_color", Color.BLACK)
	stats_label.add_theme_constant_override("outline_size", 6)
	stats_label.visible = false
	cl.add_child(stats_label)
```

3.2. Añade la función:

```gdscript
func _stats_text() -> String:
	var a := stats[0]
	var b := stats[1]
	return "P1   bajas %d   ·   muertes %d   ·   lanzó %d   ·   corrió %d m\nP2   bajas %d   ·   muertes %d   ·   lanzó %d   ·   corrió %d m" % [
		a["kills"], a["deaths"], a["throws"], int(round(float(a["dist"]) / 32.0)),
		b["kills"], b["deaths"], b["throws"], int(round(float(b["dist"]) / 32.0)),
	]
```

3.3. En `_point()`, dentro de la rama `if scores[...] >= WIN_SCORE:` (la de
`match_over = true`), después del `show_msg(...)`, añade:

```gdscript
		stats_label.text = _stats_text()
		stats_label.visible = true
```

### 4. Reset en la revancha

En el handler de revancha de `_physics_process`, el bloque
`if match_over and Input.is_action_just_pressed("restart"):` debe quedar:

```gdscript
	if match_over and Input.is_action_just_pressed("restart"):
		scores = [0, 0]
		stats = _fresh_stats()
		stats_label.visible = false
		match_over = false
		_update_hud()
		_start_round()
```

## Qué NO hacer

- No cuentes los teletransportes como metros (el filtro del paso 2.3 lo evita).
- No muestres las stats durante la partida: solo en la pantalla de victoria.
- No añadas archivos ni nodos nuevos: todo va en `game.gd` y el HUD existente.

## Criterios de aceptación

1. Al ganar un partido, bajo el "¡GANA Px!" aparecen las dos líneas de
   estadísticas con números plausibles.
2. Una muerte por foso cuenta como "muerte" del caído pero no como "baja" de
   nadie; una doble muerte suma una muerte a cada uno.
3. Los metros crecen solo corriendo (las reapariciones no inflan la cifra).
4. Tras la revancha con R, las estadísticas arrancan de cero y el panel
   desaparece.
5. El smoke test sigue pasando (si aplicaste la tarea del test ampliado, su
   final de partido verá el panel aparecer sin romper nada).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.


---

# APÉNDICE — Trabajo ya realizado fuera de las 22 tareas (NO ejecutar)

> **Esta sección NO se ejecuta.** Describe el trabajo que ya está hecho y que
> no forma parte de las 22 tareas: el juego base sobre el que están escritas
> todas las tareas, y los ajustes de integración de cuando se aplicaron. Es
> contexto para entender el código que vas a encontrar; no hay que implementar
> nada de aquí.

## 1. El juego base (commit `ccd7577`, ya hecho)

Antes de existir las 22 tareas ya había un duelo completo y jugable, creado
desde cero (gráficos y sonido 100 % procedurales, sin assets):

- **Esgrima a un golpe** (`scripts/player.gd`): tres estancias (alta con W,
  media neutral, baja con S), ataque con ventana activa
  (`ATTACK_FROM`/`ATTACK_TO`), choque (clash) cuando ambos atacáis a la misma
  altura, doble muerte (trade) a alturas distintas, patada voladora en el aire
  (DIVEKICK) que derriba, y derribo/aturdimiento (KNOCKDOWN/STUNNED).
- **Lanzar y recoger la espada** (`scripts/sword_projectile.gd`,
  `scripts/pickup.gd`): el lanzamiento vuela recto a altura media, la guardia
  media o el ataque rival lo desvían, la espada cae al suelo y se recoge
  pasando por encima.
- **Estructura de partido** (`scripts/game.gd`): quien mata gana el "paso"
  (`right_of_way`) y debe correr hasta su meta; el muerto reaparece delante
  del corredor, cayendo del cielo, con 1,3 s de invulnerabilidad; foso central
  mortal con plataforma para cruzarlo; primero en anotar 3 (`WIN_SCORE`) gana;
  reinicio de ronda automático y revancha con R.
- **Presentación**: dibujo procedural de los duelistas (`_draw()`), cámara con
  límites y sacudida, HUD de marcador y mensajes, efectos de sonido generados
  por código (`scripts/sfx.gd`).
- **Prueba automática**: `test/smoke_test.gd` + `test/smoke_test.tscn`, con 7
  casos y 12 checks, que termina imprimiendo
  `SMOKE OK - todas las mecánicas funcionan`.

## 2. Aplicación de las 22 tareas (commit `a102f57`, ya hecho)

Las 22 tareas de este documento ya fueron aplicadas una vez, en la rama
`glm/aplicando-todo`. Durante la integración hubo estos ajustes respecto al
texto literal de las tareas (si el código difiere del enunciado, es por esto):

- Las tareas `05` y `17` se unificaron en los helpers `_in_any_pit(x)` y
  `_out_of_pit(x)` de `game.gd`, como recomendaba la tabla de conflictos.
- El hit-stop de `06` y la pausa de `15` comparten `get_tree().paused`: el
  toggle de ESC queda protegido con la variable `hitstop_active`, la opción que
  daba la tabla de conflictos.
- El smoke test ajustó la espera del test 6 (`1.5` → `2.4` s) por la cámara
  lenta de `07`, y añadió los 5 casos de `14` (tests 8 a 12).
- `game.gd` arranca con `process_mode = Node.PROCESS_MODE_ALWAYS` para que la
  pausa, el bot, la música y el resto de toggles respondan con el juego
  pausado.

## 3. Otros documentos de trabajo (ya hechos)

- `tasks/README.md` — guía de formato de las tareas y tablas de orden y
  conflictos (su contenido está integrado en la cabecera de este documento).
- `tasks/secundarias.md` — backlog de ideas no formales (apéndice siguiente).
- `README.md` — controles y mecánicas del juego tal como está ahora.

---

# APÉNDICE — Diferencia con el proyecto anterior "Nidhogg 2" (NO ejecutar aún)

> Existe un proyecto hermano: `C:\Users\tigreton\Documents\zcode\Nidhogg 2`
> (Godot 4.3, plan E0–E12 + arte B0–B6, todo implementado). Es el mismo duelo
> pero con otro diseño: 4 armas que ciclan al morir, 5 secciones con rejas y
> gore persistente. Este apéndice guarda **SOLO LA DIFERENCIA**: lo que aquel
> proyecto tiene y este NO ha desarrollado. Son **tareas candidatas**: antes de
> dárselas a un LLM básico hay que convertirlas al formato de 7 reglas (código
> literal paso a paso), igual que las 22 de arriba.

## A. Lo que el proyecto anterior tiene y aquí YA ESTÁ (no es diferencia)

| En "Nidhogg 2" | Aquí está cubierto por |
|---|---|
| Choque/parada por 3 alturas, doble muerte | Base del juego |
| Patada voladora (dive kick) | Base (derriba al rival) |
| Deslizamiento (slide) bajo ataques altos | El rodar de la tarea 12 cumple el mismo papel |
| Lanzar arma, guardia la desvía, recogida del suelo | Base (`sword_projectile.gd`, `pickup.gd`) |
| Desarme | Tarea 19 (choque desarma al que ataca en alto) |
| Flecha de avance / tug-of-war | `right_of_way` + aviso ¡CORRE! (08) + halo (09) |
| Reaparición delante del corredor | Base |
| Mando | Tarea 16 (el anterior no lo tenía) |
| Música | Tarea 11 (el anterior no la tenía) |
| Bot/IA rival | Tareas 01, 02 y 21 (el anterior la excluyó por diseño) |
| Hit-stop, cámara lenta, pausa, stats | Tareas 06, 07, 15, 22 (el anterior no las tenía) |
| Sonido proceducional | Aquí `sfx.gd`; allí WAVs generados con ffmpeg |

## B. Excluido a propósito (choca con las reglas de ESTE proyecto)

- **Arte IA pixel art** (sprite registry, 50 assets, pipeline magenta→alfa):
  aquí todo es procedural y las tareas prohíben añadir assets externos.
  Requeriría una decisión de proyecto, no es una tarea.
- **Sonido por WAVs con ffmpeg**: cubierto de sobra por `sfx.gd` y `music.gd`.
- **Infraestructura Godot 4.3 / test runner multi-suite**: aquí es Godot 4.6 y
  el smoke test ampliado (14) cumple el mismo papel.

## C. La diferencia real: tareas candidatas (ordenadas por valor)

### D1 — Armas múltiples con ciclo de muerte (alta · `game.gd`, `player.gd`, `pickup.gd`)
Hoy los dos jugadores llevan la misma espada eterna. Allí había 4 armas con
personalidad, definidas por stats: **florete** equilibrado (3 alturas, empala),
**espada larga** (lenta y larga, SOLO alta/baja, sus golpes desarman en vez de
clavar), **daga** (rapidísima, startup 0,08, 3 alturas, corres un 15 % más con
ella, lanzada solo mata en alto) y **arco** (ver D2). Al morir reapareces con
la SIGUIENTE arma del ciclo florete→espada→daga→arco, y la que llevabas cae al
suelo donde cualquiera puede recogerla. Enfoque aquí: diccionario de stats por
arma en `game.gd` (startup/recuperación/alcance/alturas/multiplicador de
carrera), `weapon_id` en `Player`, siluetas distintas en `_draw()`, y
generalizar `pickup.gd`. Es la pieza que más identidad aporta.

### D2 — Arco y flechas que rebotan (alta · nuevo `arrow.gd`, `game.gd`)
Mantener ataque tensa el arco 1 s; al soltar sale una flecha recta a la altura
de tu estancia (600 px/s). Contra un arma en guardia A LA MISMA altura rebota
(velocidad ×−0,85); a otra altura atraviesa y mata. La flecha mata a
CUALQUIERA, incluido el tirador si le vuelve. Tras 6 rebotes se clava como
decoración (no recogible). Enfoque: script hermano de `sword_projectile.gd`,
reutilizando su lógica de desvío como base del rebote.

### D3 — Arena por secciones con rejas (alta · `game.gd`) — modo alternativo
Este proyecto juega en una arena continua con meta fija; el anterior encadenaba
5 secciones con muros invisibles que solo se abren para el atacante, reset de
posiciones al cruzar (cámara con tween 0,4 s, "como empezar de nuevo") y
victoria al cruzar el borde final. Como `right_of_way` y el tug-of-war ya
existen aquí, el trabajo real es trocear `_build_level()` en secciones, muros
condicionales y victoria por borde. Debe convivir como MODO alternativo
(tecla para elegir estructura), no sustituir el actual.

### D4 — HUD estilo Nidhogg 2: pips, barra de respawn, ¡FIGHT! (media · `game.gd`)
Fila de 5 cuadros arriba: los conquistados rellenos del color del atacante, el
resto huecos con borde del color del defensor (solo con sentido si existe D3).
Además, barra de progreso sobre el punto de reaparición mientras cuenta el
respawn, y cartel "¡FIGHT!" al empezar la ronda (conecta con la secundaria de
cuenta atrás). El marcador numérico y el ¡CORRE! actuales cubren otra parte.

### D5 — Stomp letal sobre caído (baja · `game.gd`, `player.gd`)
Pulsar abajo sobre un rival en KNOCKDOWN con solape lo mata, y el cadáver
estalla en partículas grandes del color de la víctima. El estado KNOCKDOWN ya
existe; es añadir una resolución junto a `_resolve_divekicks()`.

### D6 — Juego desarmado completo (media · `player.gd`, `game.gd`)
Aquí el puñetazo (13) solo derriba. Allí: el puñetazo DESARMA (el rival suelta
el arma como pickup) y aturde 0,5 s; agachado+ataque = patada baja que
derriba; desarmado corres más rápido (320 vs 260 px/s); la patada voladora
hace soltar el arma a la víctima. Encaja con el desarme del choque en alto
(19): más duelos a puño limpio.

### D7 — Sangre persistente que gotea (media · `game.gd`)
Manchas del color de la víctima como hijas del suelo (máx ~200, FIFO) que
"gotean" por los bordes de las plataformas (trazos verticales que crecen tras
0,4 s). El escenario recuerda el partido; se limpia en `_start_round()`. Todo
procedural con `_poly()`, como el resto.

### D8 — Cadáver persistente y empalamiento (media · `game.gd`, `player.gd`)
Aquí el muerto estalla y desaparece (la secundaria "cadáver con físicas" ya lo
apunta). Matices nuevos del proyecto anterior: el cuerpo permanece tumbado
(rotado 90°) hasta la reaparición, y con florete/daga el golpe letal EMPALA: el
cadáver queda clavado en la hoja y se mueve con ella. Convertir JUNTO con esa
secundaria, en una sola tarea.

### D9 — Guardia pasiva y ventana al correr (media · `game.gd`) — decisión de diseño antes
Fiel al original: el arma EN GUARDIA (parado/agachado) mata al cuerpo que se
empala contra ella (correr contra el rival armado es morir), y mientras corres
bajas la guardia (ventana vulnerable). Aquí el duelo es activo contra activo.
ADVERTENCIA: cambia el equilibrio del proyecto y puede dejar al bot (01/02)
muriendo de paseo; decidir antes de convertir en tarea.

### D10 — Rastro de armas lanzadas (baja · `sword_projectile.gd`)
El proyectil actual vuela "limpio": añadir una estela (Line2D con los últimos
~10 puntos, color del lanzador y giro visible). Es el mismo objetivo readability
que la secundaria de la estela del tajo, pero para el arma voladora.

### D11 — Gusano gigante de victoria (media · `game.gd`)
Al ganar el partido, un gusano procedural (poly verde con dos mandíbulas
triangulares) baja del techo y envuelve al ganador en ~1,2 s antes del cartel
de victoria. Es EL momento icónico de Nidhogg y cabe sin assets.

### Nota de infraestructura (opcional)
El proyecto anterior centralizaba TODA cifra de gameplay en un único
`game_config.gd`. Aquí las constantes viven repartidas entre `game.gd` y
`player.gd`. Si D1 aterriza (muchos números nuevos por arma), conviene crear
ese archivo en la misma tarea.

---

# APÉNDICE — Backlog de ideas (NO ejecutar)

> **Esta sección NO contiene tareas ejecutables.** Son ideas sin código literal,
> guardadas solo como referencia del rumbo futuro del proyecto. **NO intentes
> implementarlas**: les falta el detalle paso a paso obligatorio de las tareas
> de arriba. Ignóralas salvo que el humano te pida expresamente convertir una
> de estas ideas en tarea formal.

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
