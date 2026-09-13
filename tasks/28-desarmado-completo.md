# Tarea 28 — Juego desarmado completo: puñetazo que desarma, patada baja y carrera rápida

**Dificultad:** media · **Archivos:** `scripts/player.gd`, `scripts/game.gd`, `test/smoke_test.gd` · **Prerrequisitos:** ninguno

## Objetivo

El juego a puño limpio del original: el **puñetazo de pie DESARMA** (el rival
suelta el arma como pickup y queda aturdido 0,5 s), **agachado + ataque** sin
espada es una **patada baja que derriba**, **desarmado corres un 15 % más
rápido**, y la **patada voladora hace soltar el arma** a su víctima. Más duelos
a puño limpio, en sinergia con el desarme del choque en alto que ya existe.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript), arte y sonido procedurales, indentación con
  **tabs**, comentarios en español.
- `scripts/player.gd`:
	- `var has_sword := true`; `const SPEED := 330.0`, `const DUCK_SPEED := 150.0`.
	- En el segundo `match state:` de `_physics_process`, el caso
	  `State.IDLE, State.RUN:` empieza con
	  `var sp := DUCK_SPEED if stance == H.LOW else SPEED`.
- `scripts/game.gd`:
	- `func _resolve_attacks() -> void:` decide el resultado. El bloque de
	  defensa contiene, en este orden:
	  `var d: int = def.stance` → `if d == h:` → `outcome = "clash"`.
	- `func _melee_hit(atk: Player, def: Player) -> void:` hoy es:
	  `if atk.has_sword: _kill(def, atk) else:` (puñetazo que solo derriba,
	  con el comentario `# el puñetazo derriba, no mata`).
	- `func _resolve_divekicks() -> void:` en su rama final hace
	  `def.knockdown(push)` y manda al atacante arriba con
	  `p.state = Player.State.JUMP`.
	- `_drop_sword(pos, col)` crea el pickup; `_update_pickups()` lo recoge.
- Estados por número en el smoke test: 5 = STUNNED, 6 = KNOCKDOWN, 7 = DEAD.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. `player.gd`: velocidad desarmado

1.1. Junto a `const DUCK_SPEED := 150.0`, añade:

```gdscript
const UNARMED_SPEED_MULT := 1.15
```

1.2. En el caso `State.IDLE, State.RUN:`, sustituye
`var sp := DUCK_SPEED if stance == H.LOW else SPEED` por:

```gdscript
			var sp := DUCK_SPEED if stance == H.LOW else SPEED * (UNARMED_SPEED_MULT if not has_sword else 1.0)
```

### 2. `game.gd`: el puñetazo atraviesa la guardia

En `_resolve_attacks()`, sustituye la línea `if d == h:` (la que está justo
después de `var d: int = def.stance`) por:

```gdscript
			if d == h and atk.has_sword:
```

(a puño limpio no hay choque de espadas: el puñetazo entra aunque la guardia
sea de la misma altura, y `_melee_hit` decide).

### 3. `game.gd`: puñetazo desarma, patada baja derriba

Sustituye TODO el cuerpo de `_melee_hit` por (si ya aplicaste la tarea 23,
NO sustituyas todo: conserva su primera rama del espadón y solo sustituye la
parte que empieza en `if atk.has_sword: _kill(def, atk)` + el `else:` actual
por las dos ramas de abajo; el resultado debe tener las tres ramas):

```gdscript
func _melee_hit(atk: Player, def: Player) -> void:
	if atk.has_sword:
		_kill(def, atk)
	else:
		var push := 1 if def.position.x >= atk.position.x else -1
		if def.has_sword and atk.stance != Player.H.LOW:
			# puñetazo de pie: desarma y aturde
			def.has_sword = false
			_drop_sword(def.position + Vector2(-float(def.facing) * 110.0, -30.0), Color(0.87, 0.9, 0.95))
			def.state = Player.State.STUNNED
			def.stun_time = 0.5
			def.velocity = Vector2(push * 160.0, -120.0)
			_burst(def.position + Vector2(0, -20), Color(0.95, 0.95, 1.0), 8, 240.0)
			sfx(def.position, "throw", -12.0)
		else:
			# patada baja (agachado) o rival ya desarmado: derriba
			def.knockdown(push)
			_burst(def.position, Color(1, 1, 1), 8, 200.0)
			sfx(def.position, "hit", -10.0)
```

### 4. `game.gd`: la patada voladora desarma

En `_resolve_divekicks()`, la rama final hace `def.knockdown(push)`. Justo
DESPUÉS de esa línea, añade:

```gdscript
			if def.has_sword:
				def.has_sword = false
				_drop_sword(def.position + Vector2(0.0, -20.0), Color(0.87, 0.9, 0.95))
```

### 5. Smoke test: sección nueva

En `test/smoke_test.gd`, busca la línea `print("")` e inserta ANTES:

```gdscript
	# 22. Desarmado: el puñetazo desarma y la patada baja derriba
	p1.has_sword = false
	p1.position = Vector2(1600.0, 531.0)
	p2.position = Vector2(1645.0, 531.0)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.state = 0
	p2.state = 0
	p2.has_sword = true
	p2.invuln_time = 0.0
	p1.facing = 1
	await get_tree().physics_frame
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.2).timeout
	Input.action_release("p1_attack")
	_check(p2.has_sword == false and p2.state == 5, "Desarmado: el puñetazo desarma y aturde")
	p2.state = 0
	p2.has_sword = true
	p2.invuln_time = 0.0
	p2.position = Vector2(1645.0, 531.0)
	p2.velocity = Vector2.ZERO
	Input.action_press("p1_down")
	await get_tree().physics_frame
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.2).timeout
	Input.action_release("p1_attack")
	Input.action_release("p1_down")
	_check(p2.state == 6, "Desarmado: la patada baja derriba")
	for pk in game.pickups:
		pk.queue_free()
	game.pickups.clear()
	p1.has_sword = true
```

## Qué NO hacer

- No cambies `PUNCH_RANGE` (50): con él, el puñetazo ya entra a la distancia
  que usa el test (45 px).
- No desarmes con la patada baja: la patada SOLO derriba (el desarme es del
  puñetazo de pie).
- No apliques el desarme de la patada voladora cuando la víctima ya está
  desarmada (el `if def.has_sword:` ya lo evita).
- No toques la resolución del choque entre espadas (dos atacantes armados):
  el `and atk.has_sword` solo afecta al atacante desarmado.

## Criterios de aceptación

1. Sin espada, un puñetazo de pie le quita el arma al rival (cae al suelo como
   pickup) y lo aturde medio segundo.
2. Sin espada y agachado, el ataque es una patada baja que derriba.
3. Desarmado corres apreciablemente más rápido (330 → ~380).
4. Un puñetazo contra un rival desarmado lo derriba (no lo mata).
5. La patada voladora sigue derribando y ahora además suelta el arma de la
   víctima.
6. El smoke test pasa, incluida la sección 22 nueva.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
