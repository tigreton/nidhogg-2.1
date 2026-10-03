# Tarea 60 — Personajes con sprites (retira la customización de la 38)

**Dificultad:** alta · **Archivos:** `scripts/player.gd`, `scripts/game.gd`, `scripts/match_rules.gd`, `scripts/title.gd` · **Prerrequisitos:** tareas 54 y 56 aplicadas; que existan los 32 `player_*.png` (ya importados)

## Objetivo

El duelistas dejan de dibujarse con líneas y círculos: cada estado del enum
se mapea a una pose sprite (P1 "Nacho" azul, P2 "Rodrigo" rojo). Se retira la
customización de piel/peinado de la tarea 38 (los sprites son diseños fijos:
decisión 2 de `PLAN-ARTE.md`), los colores de equipo pasan a la paleta de los
sprites, y el cadáver usa la pose `dead`. P3/P4 y bots reutilizan los sprites
de su par con tinte de equipo.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). `player.gd` dibuja todo en `_draw()`
  (~líneas 374-476): halo, transform por estado, piernas/torso/cabeza,
  peinado (`_match_hair`, ~493-504) y espada/arco. Redibuja cada frame con
  `queue_redraw()`.
- `enum State { IDLE, RUN, JUMP, DIVEKICK, ATTACK, STUNNED, KNOCKDOWN, DEAD,
  ROLL, DIVE, SIDEKICK }` y `enum H { LOW, MID, HIGH }`. Variables clave:
  `run_phase` (ciclo de carrera en radianes), `velocity.y` (subida/bajada),
  `attack_height`, `roll_time`, `attack_dash_time`, `flash_time`,
  `weapon_id`, `has_sword`, `player_id` (1-4), `color`.
- El volteo ya existe: `scale.x = facing` (~línea 263) — un espejado del nodo
  que también voltea lo dibujado en `_draw()`. **No se cambia**: el sprite se
  dibuja mirando a la derecha y el espejado lo voltea.
- Colisión: rectángulo 26×58 centrado en el origen (`_ready()`). Los pies del
  dibujo procedural quedan en y≈+32. Los sprites miden **56 px de alto**
  (crouch 40, slide 30, dead/downed ~28-30 tumbados) y ancho variable.
- Sprites: `res://art/sprites/player_{pose}_{p1,p2}.png` con poses `idle,
  run_0..3, jump, fall, crouch, slide, attack_high, attack_mid, attack_low,
  throw, divekick, dead, downed`. Todas miran a la derecha y **todas llevan
  la espada horneada** (salvo divekick): el desarmado/arco se resuelve en la
  tarea 61; mientras tanto el desarmado se ve con espada (aceptado).
- `game.gd`: colores de equipo `P1_COLOR`/`P2_COLOR` (~línea 82), nombres de
  equipo 2v2 "NARANJA"/"CYAN" (~línea 2218), clase `Corpse` (~642, dibujo con
  líneas, instanciada en `_spawn_corpse` ~1866 con `Corpse.new(Color(def.color))`).
- `match_rules.gd`: `static var hair`/`skin` (se borran). `title.gd`: si la
  tarea 54 ya retiró las teclas Z/X/N/M, no hay nada que tocar.
- La hierba alta (`game.gd` ~305-309, blades con `z_index` 2-3) ya se dibuja
  por delante del jugador (z 0): el branch `hide_sword` de `player.gd`
  pierde sentido y se elimina.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en
  español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Registro de poses en `player.gd`

Junto a las constantes de arriba (después de `SIDEKICK_TIME`), añade:

```gdscript
const POSES := ["idle", "run_0", "run_1", "run_2", "run_3", "jump", "fall", "crouch", "slide", "attack_high", "attack_mid", "attack_low", "throw", "divekick", "dead", "downed"]
const POSE_SCALE := 58.0 / 56.0   # el sprite mide 56 px de alto; la colisión 58
const POSE_FEET_Y := 32.0        # dónde quedan los pies respecto al origen

static var _pose_tex := {}

static func pose_texture(pose: String, side: String) -> Texture2D:
	# carga perezosa de las 32 poses (p1 azul, p2 rojo)
	if _pose_tex.is_empty():
		for p in POSES:
			for s in ["p1", "p2"]:
				_pose_tex["%s_%s" % [p, s]] = load("res://art/sprites/player_%s_%s.png" % [p, s])
	return _pose_tex.get("%s_%s" % [pose, side], _pose_tex["idle_p1"])
```

### 2. Selección de pose

Añade esta función junto a `_draw`:

```gdscript
func _pose_name() -> String:
	match state:
		State.RUN:
			if stance == H.LOW:
				return "crouch"
			return "run_%d" % int(fposmod(run_phase * 2.0 / PI, 4.0))
		State.JUMP:
			return "jump" if velocity.y < 0.0 else "fall"
		State.DIVEKICK, State.DIVE:
			return "divekick"
		State.ATTACK:
			match attack_height:
				H.HIGH:
					return "attack_high"
				H.LOW:
					return "attack_low"
				_:
					return "attack_mid"
		State.KNOCKDOWN:
			return "downed"
		State.ROLL:
			return "jump"
		State.SIDEKICK:
			return "crouch"
		_:
			if stance == H.LOW:
				return "crouch"
			return "idle"
```

(`slide`, `throw` y `dead` quedan reservados: slide llega con la tarea 45,
throw se estudia en la 62, dead lo usa el Corpse.)

### 3. Sustituir `_draw()`

Reemplaza **todo** el cuerpo de `_draw()` y borra la función `_match_hair`
entera. El nuevo `_draw()`:

```gdscript
func _draw() -> void:
	if state == State.DEAD:
		return
	# halo pulsante bajo los pies de quien tiene el paso
	var g := get_parent()
	if g != null and g.get("right_of_way") == self:
		var pulse := 0.5 + 0.5 * sin(anim_time * 10.0)
		draw_circle(Vector2(0, 34), 20.0 + 4.0 * pulse, Color(color.r, color.g, color.b, 0.10 + 0.10 * pulse))
		draw_arc(Vector2(0, 34), 24.0, 0.0, TAU, 24, Color(color.r, color.g, color.b, 0.55), 2.0)

	# transform por estado (la pose ya aporta gran parte del gesto)
	var t_pos := Vector2.ZERO
	var t_rot := 0.0
	var t_scl := Vector2.ONE
	match state:
		State.ROLL:
			t_rot = -TAU * (roll_time / ROLL_DURATION)
			t_pos = Vector2(0, 10)
		State.DIVE:
			t_rot = 0.35
		State.SIDEKICK:
			t_rot = 0.45
		State.DIVEKICK:
			t_rot = 0.15
		State.STUNNED:
			t_rot = -0.28
		State.ATTACK:
			if attack_dash_time > 0.0:
				t_rot = 0.15

	# sprite de la pose, anclado por los pies; P3/P4 reutilizan el de su par teñido
	var side := "p1" if (player_id == 1 or player_id == 3) else "p2"
	var tint := Color.WHITE if player_id <= 2 else color
	if flash_time > 0.0:
		tint = Color(2.5, 2.5, 2.5)
	var tex := pose_texture(_pose_name(), side)
	var w := tex.get_width() * POSE_SCALE
	var h := tex.get_height() * POSE_SCALE
	draw_set_transform(t_pos, t_rot, t_scl)
	draw_texture_rect(tex, Rect2(-w * 0.5, POSE_FEET_Y - h, w, h), false, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if has_sword and weapon_id == "arco":
		_draw_bow()
		return

	# puñetazo a puño limpio (sin pose propia: overlay corto)
	if state == State.ATTACK and not has_sword:
		var c := color if flash_time <= 0.0 else Color.WHITE
		var pext := attack_ext()
		if pext > 0.05:
			draw_circle(Vector2(10.0 + pext * 16.0, -6.0), 5.0, c)
```

Notas: se elimina el branch `hide_sword` (la espada va horneada y la hierba
ya se dibuja por delante), el squash de estancia baja (la pose `crouch` lo
aporta) y la rotación de KNOCKDOWN (la pose `downed` ya está tumbada).
`_draw_bow()` (tarea 56) se conserva tal cual.

### 4. Cadáver con la pose `dead` en `game.gd`

En la clase `Corpse`, añade la variable y el parámetro, y sustituye su
`_draw()`:

```gdscript
class Corpse extends Node2D:
	var col := Color.WHITE
	var body_side := "p1"
	...

	func _init(c: Color, side := "p1") -> void:
		col = c
		body_side = side

	...

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0 if grounded else rot, Vector2.ONE)
		var tex: Texture2D = Player.pose_texture("dead", body_side)
		var w := tex.get_width() * Player.POSE_SCALE
		var h := tex.get_height() * Player.POSE_SCALE
		draw_texture_rect(tex, Rect2(-w * 0.5, 8.0 - h, w, h), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
```

Y en `_spawn_corpse()` (~línea 1867):

```gdscript
	var c := Corpse.new(Color(def.color), "p1" if (def.player_id == 1 or def.player_id == 3) else "p2")
```

### 5. Colores de equipo = paleta de los sprites

En `game.gd` (~línea 82):

```gdscript
const P1_COLOR := Color("4a7bd0")   # azul de la túnica de Nacho (P1)
const P2_COLOR := Color("d84f35")   # rojo de Rodrigo (P2)
```

Y en el mensaje de victoria 2v2 (~línea 2218), sustituye
`"NARANJA" if _team(p) == 0 else "CYAN"` por
`"AZUL" if _team(p) == 0 else "ROJO"`. P3/P4 (`ff7847`, `4f8dff`) no cambian:
son el tinte con el que se dibujan sus sprites.

### 6. Retirar la customización (tarea 38)

- `scripts/match_rules.gd`: borra las líneas `static var hair := [1, 2]` y
  `static var skin := [0, 1]`.
- `scripts/title.gd`: si la tarea 54 no se hubiera aplicado aún, borra ahora
  los casos Z/X/N/M de `_unhandled_key_input` y la línea "Z/X: aspecto..." de
  `_update_rules`, y comprueba que no quede ninguna referencia a
  `MatchRules.hair`/`MatchRules.skin` en todo el proyecto (busca con grep:
  solo estaban en `player.gd` —ya borradas en el paso 3—, `title.gd` y
  `match_rules.gd`).

## Qué NO hacer

- No toques la física, el enum de estados, el input ni las colisiones: solo
  cambia cómo se ve. El smoke test debe pasar sin editar ni un caso.
- No borres `_dust()`, `_draw_bow()`, `take_clash`/`knockdown`/`die` ni las
  señales.
- No cambies el mecanismo `scale.x = facing`: es el que voltea el sprite.
- No tintes a P1/P2 (solo P3/P4): sus sprites ya traen el color.

## Criterios de aceptación

1. Correr anima el ciclo `run_0→run_3`; saltar usa `jump` subiendo y `fall`
   bajando; atacar usa la estancia correcta (alta/media/baja); el derribado
   queda con la pose `downed`; la rodada es un giro del sprite `jump`.
2. P1 es el personaje azul y P2 el rojo en partida, HUD (marcador, halo,
   barra de respawn) y cadáveres; el 2v2 muestra a P3/P4 como tintes de sus
   pares con nombres AZUL/ROJO.
3. Z/X/N/M ya no existen y no queda ninguna referencia a hair/skin.
4. El parpadeo de invulnerabilidad y el flash blanco al recibir golpe
   siguen viéndose.
5. El smoke test termina en `SMOKE OK` sin cambios en el test.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
Y una pasada con render: correr, saltar, atacar en las 3 alturas, rodar,
divekick, derribo, muerte (cadáver) y revancha.

## Nota posterior (2026-10-03)

El mapeo `State.ROLL` del paso 2 cambió de `"jump"` a `"slide"` para estrenar
el sprite de barrido (la 45 no creó estado SLIDE propio). Detalle en
`PLAN-ARTE.md` y verificación en `screens/22_rodada_slide.png`.
