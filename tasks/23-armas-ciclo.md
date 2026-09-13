# Tarea 23 — Armas con ciclo de muerte: florete, espadón y daga (+ game_config.gd)

**Dificultad:** alta · **Archivos:** nuevo `scripts/game_config.gd`, `scripts/player.gd`, `scripts/game.gd`, `scripts/pickup.gd`, `scripts/sword_projectile.gd`, `test/smoke_test.gd` · **Prerrequisitos:** ninguno

## Objetivo

Las tres armas con personalidad de Nidhogg 2 (sin arco, que es la tarea 24):
**florete** (equilibrado, como la espada actual), **espadón** (lento, largo, solo
guarda alta/baja, y sus golpes DESARMAN en vez de clavar) y **daga** (rapidísima
y corta, corres un 15 % más con ella, y su lanzamiento solo mata en alto).
Al morir reapareces con la SIGUIENTE arma del ciclo florete→espadón→daga, y la
que llevabas cae al suelo donde cualquiera puede recogerla.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**. Indentación con
  **tabs**, comentarios en español.
- `scripts/player.gd` — `class_name Player` (CharacterBody2D):
	- Enum `State { IDLE, RUN, JUMP, DIVEKICK, ATTACK, STUNNED, KNOCKDOWN, DEAD, ROLL }`.
	- Constantes de ataque: `ATTACK_DURATION := 0.30`, `ATTACK_FROM := 0.07`,
	  `ATTACK_TO := 0.20`, `ATTACK_RANGE := 86.0` (líneas 16–19).
	- `var has_sword := true` (línea 35).
	- En `_physics_process`: bloque de estancias `if can_act:` con
	  `if held("up"): stance = H.HIGH elif held("down"): stance = H.LOW else: stance = H.MID`;
	  primer `match state:` con el caso `State.ATTACK:` que compara
	  `attack_time >= ATTACK_DURATION`; velocidad en el segundo `match state:`
	  caso `State.IDLE, State.RUN:` con `var sp := DUCK_SPEED if stance == H.LOW else SPEED`.
	- `attack_is_active()` y `attack_ext()` usan ATTACK_FROM/ATTACK_TO.
	- El dibujo de la espada está en `_draw()` dentro de
	  `if has_sword and not hide_sword:` con `var blen := (tip - hand).length() + ext * 22.0`
	  y dos `draw_line(hpos, tpos, ...)` de anchos 7.0 y 4.0.
- `scripts/game.gd` — nodo raíz del duelo:
	- `_nearest_foe_in_range(atk)`: primera línea
	  `var rng := Player.PUNCH_RANGE if not atk.has_sword else Player.ATTACK_RANGE`.
	- `_melee_hit(atk, def)`: `if atk.has_sword: _kill(def, atk) else:` puñetazo.
	- `_clash(a, b)` desarma con `_drop_sword(p.position + Vector2(-float(p.facing) * 110.0, -30.0), Color(0.87, 0.9, 0.95))`.
	- `_kill(def, atk)` gestiona muerte y reaparición (`respawn_timers`).
	- `_respawn(p)` llama a `p.revive(pos, face)`.
	- `_on_threw_sword(p)` crea `SwordProjectile` con `s.vel = Vector2(p.facing * 760.0, 0.0)`.
	- `_update_projectiles(delta)`: `var blocks: bool = (p.stance == Player.H.MID and ...)`;
	  si no bloquea, `_kill(p, s.thrower)`.
	- `_drop_sword(pos: Vector2, col: Color)` crea `SwordPickup`; `_update_pickups()`
	  hace `p.has_sword = true` al recoger.
	- `_start_round()` reinicia proyectiles/pickups/rocas y posiciones.
- `scripts/pickup.gd` — `class_name SwordPickup` con `var color` y `var t`.
- `scripts/sword_projectile.gd` — `class_name SwordProjectile` con
  `vel`, `spin`, `thrower`, `color`.
- El smoke test (`test/smoke_test.gd`) usa SOLO el florete: sus esperas (0,14 /
  0,16 s dentro de la ventana 0,07–0,20) dependen de que el florete conserve los
  números actuales. Los estados se comprueban por número (7 = DEAD, 5 = STUNNED).
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Nuevo archivo `scripts/game_config.gd`

Créalo con este contenido exacto:

```gdscript
class_name GameConfig
## Stats de las armas y orden del ciclo de muerte. Compartido por game y player.

const WEAPON_ORDER := ["florete", "espada", "daga"]

const WEAPONS := {
	"florete": {
		"nombre": "FLORETE", "dur": 0.30, "from": 0.07, "to": 0.20, "reach": 86.0,
		"run_mult": 1.0, "thrown_speed": 760.0,
		"thrown_kills": ["LOW", "MID", "HIGH"],
		"blade_len": 1.0, "blade_w": 4.0, "disarms": false,
	},
	"espada": {
		"nombre": "ESPADÓN", "dur": 0.42, "from": 0.16, "to": 0.30, "reach": 118.0,
		"run_mult": 0.92, "thrown_speed": 620.0,
		"thrown_kills": ["LOW", "MID", "HIGH"],
		"blade_len": 1.3, "blade_w": 6.0, "disarms": true,
	},
	"daga": {
		"nombre": "DAGA", "dur": 0.20, "from": 0.05, "to": 0.13, "reach": 58.0,
		"run_mult": 1.15, "thrown_speed": 980.0,
		"thrown_kills": ["HIGH"],
		"blade_len": 0.6, "blade_w": 3.0, "disarms": false,
	},
}
```

### 2. `player.gd`: variable y helpers de arma

2.1. Junto a `var has_sword := true`, añade:

```gdscript
var weapon_id := "florete"
```

2.2. Debajo de `attack_ext()` (tras su cierre), añade estos helpers:

```gdscript
func weapon() -> Dictionary:
	return GameConfig.WEAPONS.get(weapon_id, GameConfig.WEAPONS["florete"])


func attack_from() -> float:
	return float(weapon()["from"])


func attack_to() -> float:
	return float(weapon()["to"])


func attack_dur() -> float:
	return float(weapon()["dur"])


func weapon_reach() -> float:
	return float(weapon()["reach"])


func run_mult() -> float:
	return float(weapon()["run_mult"])
```

### 3. `player.gd`: ventanas de ataque por arma

3.1. En el primer `match state:`, el caso `State.ATTACK:` dice
`if attack_time >= ATTACK_DURATION:`. Sustituye esa línea por:

```gdscript
			if attack_time >= attack_dur():
```

3.2. Sustituye TODO el cuerpo de `attack_is_active()` por:

```gdscript
func attack_is_active() -> bool:
	return state == State.ATTACK and attack_time >= attack_from() and attack_time <= attack_to() and not attack_resolved
```

3.3. En `attack_ext()`, sustituye la línea `var t := (attack_time - ATTACK_FROM) / (ATTACK_TO - ATTACK_FROM)` por:

```gdscript
	var t := (attack_time - attack_from()) / (attack_to() - attack_from())
```

3.4. En el bloque de ataque, la línea `attack_dash_time = ATTACK_DURATION`
(la de la estocada) pasa a:

```gdscript
					attack_dash_time = attack_dur()
```

### 4. `player.gd`: espadón sin guarda media y velocidad por arma

4.1. En el bloque de estancias dentro de `if can_act:`, el bloque completo
tiene esta pinta al terminar el paso (el `if` nuevo va al mismo nivel que
`if held("up"):`):

```gdscript
	if can_act:
		if held("up"):
			stance = H.HIGH
		elif held("down"):
			stance = H.LOW
		else:
			stance = H.MID
		if weapon_id == "espada" and stance == H.MID:
			stance = H.LOW
```

4.2. En el segundo `match state:`, caso `State.IDLE, State.RUN:`, sustituye
`var sp := DUCK_SPEED if stance == H.LOW else SPEED` por:

```gdscript
			var sp := DUCK_SPEED if stance == H.LOW else SPEED * run_mult()
```

### 5. `player.gd`: silueta del arma en `_draw()`

5.1. Dentro de `if has_sword and not hide_sword:`, sustituye
`var blen := (tip - hand).length() + ext * 22.0` por:

```gdscript
		var blen := ((tip - hand).length() + ext * 22.0) * float(weapon()["blade_len"])
```

5.2. Sustituye las dos líneas del filo:
`draw_line(hpos, tpos, dark, 7.0)` y `draw_line(hpos, tpos, blade, 4.0)` por:

```gdscript
		draw_line(hpos, tpos, dark, float(weapon()["blade_w"]) + 3.0)
		draw_line(hpos, tpos, blade, float(weapon()["blade_w"]))
```

(la línea del mango `draw_line(hpos - dirv * 7.0, hpos, ...)` no cambia).

### 6. `game.gd`: alcance y desarme del espadón

6.1. En `_nearest_foe_in_range`, sustituye
`var rng := Player.PUNCH_RANGE if not atk.has_sword else Player.ATTACK_RANGE` por:

```gdscript
	var rng := Player.PUNCH_RANGE if not atk.has_sword else atk.weapon_reach()
```

6.2. Sustituye TODO el cuerpo de `_melee_hit` por:

```gdscript
func _melee_hit(atk: Player, def: Player) -> void:
	if atk.has_sword and atk.weapon_id == "espada" and def.has_sword:
		# el espadón desarma en vez de clavar
		var push := 1 if def.position.x >= atk.position.x else -1
		def.has_sword = false
		_drop_sword(def.position + Vector2(-float(def.facing) * 110.0, -30.0), Color(0.87, 0.9, 0.95), def.weapon_id)
		def.knockdown(push)
		_burst(def.position + Vector2(0, -20), Color(0.95, 0.95, 1.0), 10, 260.0)
		sfx(def.position, "throw", -12.0)
		shake_time = maxf(shake_time, 0.12)
	elif atk.has_sword:
		_kill(def, atk)
	else:
		# el puñetazo derriba, no mata
		var push := 1 if def.position.x >= atk.position.x else -1
		def.knockdown(push)
		_burst(def.position, Color(1, 1, 1), 8, 200.0)
		sfx(def.position, "hit", -10.0)
```

### 7. `game.gd`: el arma cae al morir y el pickup guarda su tipo

7.1. En `_kill(def, atk)`, justo después de la línea
`_burst(def.position, def.color, 34, 440.0)`, añade:

```gdscript
	if def.has_sword:
		def.has_sword = false
		_drop_sword(def.position + Vector2(0.0, -20.0), Color(0.87, 0.9, 0.95), def.weapon_id)
```

7.2. En `_clash`, sustituye la llamada
`_drop_sword(p.position + Vector2(-float(p.facing) * 110.0, -30.0), Color(0.87, 0.9, 0.95))` por:

```gdscript
		_drop_sword(p.position + Vector2(-float(p.facing) * 110.0, -30.0), Color(0.87, 0.9, 0.95), p.weapon_id)
```

7.3. Cambia la firma de `_drop_sword` a:

```gdscript
func _drop_sword(pos: Vector2, col: Color, wid := "florete") -> void:
```

y dentro, en `var pk := SwordPickup.new()`, añade justo después:

```gdscript
	pk.weapon_id = wid
```

7.4. En `pickup.gd`, junto a `var t := 0.0`, añade:

```gdscript
var weapon_id := "florete"
```

7.5. En `_update_pickups()`, sustituye la línea `p.has_sword = true` por:

```gdscript
				p.weapon_id = pk.weapon_id
				p.has_sword = true
```

### 8. `game.gd`: lanzamiento por arma

8.1. En `sword_projectile.gd`, junto a `var color`, añade:

```gdscript
var weapon_id := "florete"
```

8.2. En `_on_threw_sword`, sustituye `s.vel = Vector2(p.facing * 760.0, 0.0)` por:

```gdscript
	s.vel = Vector2(p.facing * float(p.weapon()["thrown_speed"]), 0.0)
```

y añade después de `s.spin = p.facing * 18.0`:

```gdscript
	s.weapon_id = p.weapon_id
```

8.3. En `_update_projectiles`, sustituye el bloque completo de impacto
(el `if blocks:` y su `else:`, que hoy terminan con `_kill(p, s.thrower)`)
por:

```gdscript
				if blocks:
					_burst(s.position, Color(0.9, 0.9, 1.0), 10, 260.0)
					sfx(s.position, "clash", -12.0)
					_drop_sword(s.position, s.color, s.weapon_id)
				else:
					var kills: Array = GameConfig.WEAPONS[s.weapon_id]["thrown_kills"]
					var vs: String = ["LOW", "MID", "HIGH"][p.stance]
					if vs in kills:
						_kill(p, s.thrower)
					else:
						_burst(s.position, Color(0.9, 0.9, 1.0), 10, 260.0)
						sfx(s.position, "clash", -12.0)
						_drop_sword(s.position, s.color, s.weapon_id)
```

(la línea `var blocks: bool = ...` NO cambia: la guardia media sigue
desviando cualquier arma; ahora además el arma desviada conserva su tipo).

### 9. `game.gd`: ciclo de muerte

9.1. Junto a `var scores := [0, 0]`, añade:

```gdscript
var weapon_idx := [0, 0]
```

9.2. Debajo de `_respawn_pos`, añade:

```gdscript
func _next_weapon(p: Player) -> String:
	var i := p.player_id - 1
	if i < 0 or i >= weapon_idx.size():
		return "florete"
	weapon_idx[i] = (weapon_idx[i] + 1) % GameConfig.WEAPON_ORDER.size()
	return GameConfig.WEAPON_ORDER[weapon_idx[i]]
```

9.3. En `_respawn(p)`, ANTES de la línea `p.revive(pos, face)`, añade:

```gdscript
	p.weapon_id = _next_weapon(p)
```

9.4. En `_start_round()`, después de `right_of_way = null`, añade:

```gdscript
	weapon_idx = [0, 0]
	for p in players:
		p.weapon_id = "florete"
```

### 10. Smoke test: sección nueva

En `test/smoke_test.gd`, busca la línea `print("")` (la que precede al bloque
final de `SMOKE OK`) e inserta ANTES:

```gdscript
	# 17. Armas: la caída guarda su tipo y el ciclo avanza al reaparecer
	game.weapon_idx = [0, 0]
	p1.weapon_id = "florete"
	p2.weapon_id = "florete"
	p1.has_sword = true
	p2.has_sword = true
	p1.position = Vector2(1600.0, 531.0)
	p2.position = Vector2(1670.0, 531.0)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.state = 0
	p2.state = 0
	p1.facing = 1
	p2.invuln_time = 0.0
	await get_tree().physics_frame
	Input.action_press("p2_up")
	await get_tree().create_timer(0.1).timeout
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.16).timeout
	Input.action_release("p1_attack")
	Input.action_release("p2_up")
	_check(p2.state == 7, "Armas: P2 muere y suelta su arma")
	_check(game.pickups.size() == 1 and game.pickups[0].weapon_id == "florete", "Armas: la caída es un florete")
	await get_tree().create_timer(2.6).timeout
	_check(p2.weapon_id == "espada", "Armas: al reaparecer toca el espadón")
	p2.weapon_id = "florete"
```

## Qué NO hacer

- No cambies los valores del florete (dur 0,30 / from 0,07 / to 0,20 /
  reach 86 / thrown_speed 760): el smoke test depende de ellos.
- No toques el enum `State` ni los índices que usa el test.
- No cambies el dibujo de `pickup.gd` (solo se añade la variable `weapon_id`).
- No añadas el arco: es la tarea 24.
- No uses autoloads ni singletons: `GameConfig` se accede por su `class_name`.

## Criterios de aceptación

1. Empiezas con florete; al morir, tu arma cae al suelo y reapareces con el
   espadón; al morir de nuevo, con la daga; luego florete otra vez.
2. El espadón es más lento y largo, no tiene guarda media (neutro = baja) y su
   golpe desarma (el rival suelta el arma y cae derribado) en vez de matar.
3. Con daga corres más rápido y tu lanzamiento solo mata a quien está en alto.
4. Recoger un arma caída te cambia a esa arma.
5. El smoke test pasa completo, incluida la sección 17 nueva.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
