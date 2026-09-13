# Tarea 24 — Arco: tensar y soltar flechas que rebotan

**Dificultad:** alta · **Archivos:** nuevo `scripts/arrow.gd`, `scripts/game_config.gd`, `scripts/player.gd`, `scripts/game.gd`, `test/smoke_test.gd` · **Prerrequisitos:** tarea 23 (sistema de armas con `GameConfig` y `weapon_id`)

## Objetivo

La cuarta arma del ciclo: el **arco**. Mantener el ataque tensa el arco (máx
1 s); al soltar sale una flecha recta a la altura de tu estancia. Contra una
guardia A LA MISMA altura rebota (velocidad × −0,85); a otra altura atraviesa y
mata. Tras el primer rebote la flecha mata a CUALQUIERA (también a su tirador
si le vuelve). Tras 6 rebotes se queda clavada como decoración.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript), arte y sonido procedurales, indentación con
  **tabs**, comentarios en español.
- La tarea 23 ya aplicó: `scripts/game_config.gd` con `GameConfig.WEAPONS`
  (diccionario) y `GameConfig.WEAPON_ORDER` (array
  `["florete", "espada", "daga"]`); `Player.weapon_id` con helpers
  `weapon()`, `weapon_reach()`; ciclo de muerte en `game.gd::_next_weapon()`.
- `scripts/player.gd`:
	- Bloque de ataque en `if can_act:` empieza con `elif hit("attack"):`
	  y su primera rama interna es `if is_on_floor():`.
	- `held(n)` devuelve true mientras se mantiene pulsado (o el bot lo
	  mantiene en `bot_held`); `hit(n)` solo el frame en que se pulsa.
	- `var stance: int = H.MID` con `enum H { LOW, MID, HIGH }`.
	- `signal threw_sword(player: Player)` al inicio del archivo.
	- `_draw()` dibuja el arma dentro de `if has_sword and not hide_sword:`.
- `scripts/game.gd`:
	- `var projectiles: Array[SwordProjectile] = []` junto a las demás listas.
	- `_build_players()` termina con `for p in players: p.threw_sword.connect(_on_threw_sword)`;
	  el modo 2v2 (`set_mode_2v2`) repite `p.threw_sword.connect(_on_threw_sword)`
	  para P3/P4.
	- `_resolve_attacks()` contiene `var d: int = def.stance` seguido de
	  `if d == h:` → `outcome = "clash"`.
	- `_physics_process` llama a `_resolve_attacks()`, `_resolve_divekicks()`,
	  `_update_projectiles(delta)`, `_update_rocks(delta)`, `_update_pickups()`,
	  `_check_goals()`, `_update_camera()` en ese orden.
	- `_start_round()` limpia `projectiles`, `pickups` y `rocks` al principio.
- El smoke test (`test/smoke_test.gd`) termina con la sección 17 (armas) y
  luego la línea `print("")`; los estados se comprueban por número
  (7 = DEAD, 0 = IDLE) y `stance`: 0 = LOW, 1 = MID, 2 = HIGH.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. `game_config.gd`: registrar el arco

1.1. Sustituye la línea `const WEAPON_ORDER := ["florete", "espada", "daga"]` por:

```gdscript
const WEAPON_ORDER := ["florete", "espada", "daga", "arco"]
```

1.2. Añade esta entrada como último elemento del diccionario `WEAPONS`
(después de la entrada `"daga"`, con una coma tras la llave de cierre de la daga):

```gdscript
	"arco": {
		"nombre": "ARCO", "dur": 0.0, "from": 0.0, "to": 0.0, "reach": 0.0,
		"run_mult": 0.92, "thrown_speed": 0.0,
		"thrown_kills": [],
		"blade_len": 1.0, "blade_w": 4.0, "disarms": false,
		"bow": true, "arrow_speed": 600.0,
	},
```

### 2. Nuevo archivo `scripts/arrow.gd`

```gdscript
class_name Arrow
extends Node2D
## Flecha de arco: vuela recta a una altura, rebota en guardias a la misma
## altura y mata a quien atraviese. Tras 6 rebotes queda clavada.

var vel := Vector2(600.0, 0.0)
var height: int = 1        # H de la flecha: 0 LOW, 1 MID, 2 HIGH
var bounces := 0
var thrower: Player = null
var stuck := false


func _ready() -> void:
	z_index = 16


func tint() -> Color:
	var c := Color(0.82, 0.7, 0.4)
	return c.darkened(0.12 * float(bounces))


func _draw() -> void:
	var dark := Color(0.05, 0.04, 0.08)
	var dir := 1.0 if vel.x >= 0.0 else -1.0
	draw_line(Vector2(-18 * dir, 0), Vector2(12 * dir, 0), dark, 4.0)
	draw_line(Vector2(-18 * dir, 0), Vector2(12 * dir, 0), tint(), 2.5)
	draw_colored_polygon(PackedVector2Array([Vector2(12 * dir, 0), Vector2(4 * dir, -4), Vector2(4 * dir, 4)]), Color(0.9, 0.9, 0.95))
	draw_line(Vector2(-18 * dir, -4), Vector2(-14 * dir, 4), Color(0.6, 0.45, 0.25), 2.0)
	draw_line(Vector2(-16 * dir, -4), Vector2(-12 * dir, 4), Color(0.6, 0.45, 0.25), 2.0)
```

### 3. `player.gd`: tensar y soltar

3.1. Junto a la señal `threw_sword`, añade:

```gdscript
signal fired_arrow(player: Player, height: int, charge: float)
```

3.2. Junto a las demás variables de instancia, añade:

```gdscript
var bow_time := 0.0
```

3.3. En el bloque de ataque, ANTES de la rama `if is_on_floor():` (que es la
primera dentro de `elif hit("attack"):`), inserta esta rama nueva:

```gdscript
			if weapon_id == "arco":
				# tensar el arco: el disparo sale al soltar
				bow_time = 0.0001
				_sfx("swing", -26.0)
			elif is_on_floor():
```

(la rama `elif is_on_floor():` y las suyas no cambian; con arco no se puede
golpear cuerpo a cuerpo, `reach` es 0).

3.4. Al FINAL de `_physics_process`, justo antes del bloque
`if is_bot:` que copia `bot_held_prev`, añade:

```gdscript
	if bow_time > 0.0:
		if held("attack") and state in [State.IDLE, State.RUN, State.JUMP]:
			bow_time = minf(bow_time + delta, 1.0)
		else:
			fired_arrow.emit(self, stance, bow_time)
			bow_time = 0.0
```

3.5. En `_draw()`, dentro de `if has_sword and not hide_sword:`, añade al
principio de ese bloque (antes del `var h: int = ...`):

```gdscript
		if weapon_id == "arco":
			_draw_bow()
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			return
```

3.6. Y al final del archivo (después de `_draw()`), añade:

```gdscript
func _draw_bow() -> void:
	var c := color if flash_time <= 0.0 else Color.WHITE
	var dark := Color(0.05, 0.04, 0.08)
	var pull := 0.0 if bow_time <= 0.0 else clampf(bow_time, 0.0, 1.0)
	draw_arc(Vector2(8, -8), 16.0, -PI * 0.42, PI * 0.42, 12, Color(0.35, 0.22, 0.1), 4.0)
	var py := -8.0
	var px := 8.0 - pull * 12.0
	draw_line(Vector2(8.0 - 14.0, -8.0 - 14.0), Vector2(px, py), Color(0.85, 0.85, 0.8), 1.5)
	draw_line(Vector2(8.0 - 14.0, -8.0 + 14.0), Vector2(px, py), Color(0.85, 0.85, 0.8), 1.5)
	if pull > 0.0:
		draw_line(Vector2(px, py), Vector2(px + 26.0, py), dark, 2.5)
		draw_line(Vector2(px + 26.0, py), Vector2(px + 26.0 + 6.0, py), c, 2.0)
```

### 4. `game.gd`: disparar, volar, rebotar y clavarse

4.1. Junto a `var projectiles: Array[SwordProjectile] = []`, añade:

```gdscript
var arrows: Array[Arrow] = []
```

4.2. En `_build_players()`, dentro del `for p in players:` que ya conecta
`threw_sword`, añade la línea:

```gdscript
		p.fired_arrow.connect(_on_fired_arrow)
```

y en `set_mode_2v2`, dentro del `for p in [p3, p4]:`, la misma línea.

4.3. Debajo de `_on_threw_sword`, añade:

```gdscript
func _on_fired_arrow(p: Player, height: int, charge: float) -> void:
	var a := Arrow.new()
	a.thrower = p
	a.height = height
	a.position = p.position + Vector2(p.facing * 22.0, [-40.0, -8.0, 16.0][height])
	a.vel = Vector2(p.facing * 600.0 * clampf(charge + 0.2, 0.5, 1.2), 0.0)
	add_child(a)
	arrows.append(a)
	sfx(p.position, "throw", -16.0)
```

4.4. Debajo, añade la actualización:

```gdscript
func _update_arrows(delta: float) -> void:
	var w := LEVEL_W
	for a in arrows.duplicate():
		if a.stuck:
			arrows.erase(a)
			continue
		a.position += a.vel * delta
		if a.position.x < 26.0 or a.position.x > w - 26.0:
			a.stuck = true
			a.vel = Vector2.ZERO
			continue
		for p in players:
			if p.state == Player.State.DEAD or p.invuln_time > 0.0:
				continue
			# antes de rebotar solo amenaza al equipo rival
			if a.bounces == 0 and a.thrower != null and _team(p) == _team(a.thrower):
				continue
			if absf(p.position.x - a.position.x) > 24.0 or absf(p.position.y - a.position.y) > 34.0:
				continue
			var guards: bool = (p.stance == a.height and p.state in [Player.State.IDLE, Player.State.RUN]) or p.attack_is_active()
			if guards:
				a.vel = Vector2(a.vel.x * -0.85, 0.0)
				a.bounces += 1
				_burst(a.position, Color(0.9, 0.9, 1.0), 8, 220.0)
				sfx(a.position, "clash", -14.0)
			else:
				_kill(p, a.thrower if a.bounces == 0 else null)
				arrows.erase(a)
				a.queue_free()
			break
```

4.5. En `_physics_process`, después de la línea `_update_projectiles(delta)`, añade:

```gdscript
	_update_arrows(delta)
```

4.6. En `_start_round()`, junto a la limpieza de `projectiles`, añade:

```gdscript
	for a in arrows:
		a.queue_free()
	arrows.clear()
```

4.7. En `_resolve_attacks()`, sustituye la línea `if d == h:` por:

```gdscript
			if d == h and def.weapon_id != "arco":
```

(con el arco en guardia no hay choque: la flecha o el tajo atraviesan).

Nota: si ya aplicaste la tarea 28, esa línea dirá
`if d == h and atk.has_sword:` — déjalo todo junto:
`if d == h and atk.has_sword and def.weapon_id != "arco":`.

### 5. Smoke test: sección nueva

En `test/smoke_test.gd`, busca la línea `print("")` e inserta ANTES:

```gdscript
	# 18. Arco: la flecha mata a distinta altura y rebota en guardia igual
	p1.weapon_id = "arco"
	p1.has_sword = true
	p1.bow_time = 0.0
	p1.position = Vector2(1600.0, 531.0)
	p1.velocity = Vector2.ZERO
	p1.state = 0
	p1.facing = 1
	p2.position = Vector2(1850.0, 531.0)
	p2.velocity = Vector2.ZERO
	p2.state = 0
	p2.has_sword = true
	p2.invuln_time = 0.0
	await get_tree().physics_frame
	Input.action_press("p2_up")
	await get_tree().create_timer(0.1).timeout
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.4).timeout
	Input.action_release("p1_attack")
	Input.action_release("p2_up")
	await get_tree().create_timer(0.6).timeout
	_check(p2.state == 7, "Arco: la flecha mata a quien no cubre su altura")
	p2.revive(Vector2(1850.0, 531.0), -1)
	p2.invuln_time = 0.0
	p2.state = 0
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.4).timeout
	Input.action_release("p1_attack")
	await get_tree().create_timer(0.4).timeout
	_check(p2.state != 7, "Arco: la guardia a la misma altura rebota la flecha")
	_check(game.arrows.size() == 1 and game.arrows[0].bounces >= 1, "Arco: la flecha quedó rebotada en vuelo")
	p1.weapon_id = "florete"
```

## Qué NO hacer

- No cambies las armas de la tarea 23 ni el orden del ciclo salvo añadir
  `"arco"` al final.
- No dejes que el arco golpee cuerpo a cuerpo (reach 0,00: el bucle de
  `_nearest_foe_in_range` lo excluye solo; no añadas excepciones).
- No hagas que la flecha rebote contra el suelo ni los muros verticales: solo
  en guardias y en los bordes del nivel (donde se clava).
- No toques `_resolve_divekicks` ni el humo del test salvo añadir la sección 18.

## Criterios de aceptación

1. Con arco, mantener el ataque tensa (se ve la cuerda tirando) y soltar
   dispara una flecha a la altura de tu estancia.
2. Flecha contra guardia a la misma altura: rebota hacia atrás y puede matar
   a cualquiera, incluido el tirador que la reciba de vuelta.
3. Flecha contra cuerpo a otra altura: muerte.
4. Tras 6 rebotes o al tocar el borde, la flecha se queda clavada como
   decoración hasta el siguiente reinicio de ronda.
5. El smoke test pasa, incluida la sección 18 nueva.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
