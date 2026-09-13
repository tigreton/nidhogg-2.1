# Tarea 31 — Guardia pasiva: correr contra el arma es morir

**Dificultad:** media · **Archivos:** `scripts/game.gd`, `test/smoke_test.gd` · **Prerrequisitos:** ninguno

## Objetivo

Regla fiel al original: el arma **EN GUARDIA** (de pie, parado, con espada y
sin atacar) mata al cuerpo que se empala contra ella. Si el que corre entra a
la MISMA altura que la guardia, hay choque (clash) y no muerte. Y para
equilibrar: **mientras corres tu guardia no es pasiva** (ventana vulnerable):
el arma solo mata por sí sola si el dueño está parado.

> **ADVERTENCIA de diseño (leer antes de aplicar):** esta tarea cambia el
> equilibrio del duelo: acercarse caminando/corriendo a un rival parado con la
> espada en guardia pasa a ser letal. Incluye el ajuste del bot para que no se
> suicide. Si el resultado no convence, se revierte con un solo commit.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript), arte y sonido procedurales, indentación con
  **tabs**, comentarios en español.
- `scripts/game.gd`:
	- `func _resolve_attacks() -> void:` resuelve SOLO ataques activos
	  (`atk.attack_is_active()`). Un cuerpo que corre contra una espada quieta
	  hoy NO pasa nada: eso es lo que añade esta tarea.
	- `func _clash(a: Player, b: Player) -> void:` choque genérico: empuja a
	  ambos, suena y desarma al que atacara en alto. Sirve tal cual.
	- `func _kill(def: Player, atk: Player) -> void:`.
	- `_foes_of(p)` y `Player.weapon_reach()`... ojo: `weapon_reach()` SOLO
	  existe si aplicaste la tarea 23. Sin ella usa `Player.ATTACK_RANGE`.
	  Esta tarea está escrita para el código BASE: usa `Player.ATTACK_RANGE`.
	- `func _bot_think(p: Player, delta: float) -> void:` la rama del duelo
	  empieza con `if adx > 260.0:` (acercarse) y sigue con
	  `elif adx < 55.0:` (retirarse).
	- En `_physics_process` las resoluciones se llaman en este orden:
	  `_resolve_attacks()`, `_resolve_divekicks()`, `_update_projectiles(delta)`, ...
- `scripts/player.gd`: `var velocity`, `var stance` (H.LOW/MID/HIGH),
  `attack_is_active()`, `has_sword`, `invuln_time`.
- El smoke test NO tiene bots activos y coloca a los jugadores parados antes
  de atacar, así que la guardia pasiva no dispara por accidente (solo se
  activa con velocidad hacia la guardia). Se añade una sección nueva.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Resolución de empalamiento

Debajo de `_nearest_divekick_target` (junto a las demás resoluciones), añade:

```gdscript
func _resolve_guard_impale() -> void:
	# guardia pasiva: solo de pie y parado (correr no guarda)
	for g in players:
		if g.state != Player.State.IDLE or not g.has_sword or g.invuln_time > 0.0:
			continue
		for f in _foes_of(g):
			if f.state == Player.State.DEAD or f.invuln_time > 0.0:
				continue
			if f.attack_is_active():
				continue
			var dx := (f.position.x - g.position.x) * g.facing
			if dx < 8.0 or dx > Player.ATTACK_RANGE * 0.85:
				continue
			if absf(f.position.y - g.position.y) > 56.0:
				continue
			# solo empala a quien se mueve HACIA la guardia (o cae sobre ella)
			var hacia := f.velocity.x * -float(g.facing) > 140.0
			if not hacia:
				continue
			if f.stance == g.stance:
				if f.position.x <= g.position.x:
					_clash(f, g)
				else:
					_clash(g, f)
			else:
				_kill(f, g)
			return
```

### 2. Llamarla cada frame

En `_physics_process`, justo después de la línea `_resolve_attacks()`, añade:

```gdscript
	_resolve_guard_impale()
```

### 3. El bot no camina contra la guardia

En `_bot_think`, la rama del duelo tiene este orden: `if adx > 260.0:`
(acercarse), `elif adx < 55.0:` (retirarse), `elif foe.state == ...ATTACK...`
(cubrirse), `else:` (estancias y atacar). Inserta una rama NUEVA después del
`elif adx < 55.0:` y antes del `elif foe.state == Player.State.ATTACK ...`:

```gdscript
		elif foe.has_sword and foe.state == Player.State.IDLE and adx < 150.0:
			# no caminar contra la guardia: atacar o retroceder
			if randf() < float(cfg["atk"]) * 2.0:
				tap = "attack"
			elif sd > 0.0:
				want["left"] = true
			else:
				want["right"] = true
```

### 4. Smoke test: sección nueva

En `test/smoke_test.gd`, busca la línea `print("")` e inserta ANTES:

```gdscript
	# 25. Guardia pasiva: correr contra el arma en guardia es morir
	p1.has_sword = true
	p2.has_sword = true
	p1.position = Vector2(1500.0, 531.0)
	p2.position = Vector2(1650.0, 531.0)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.state = 0
	p2.state = 0
	p1.invuln_time = 0.0
	p2.invuln_time = 0.0
	p1.facing = 1
	await get_tree().physics_frame
	Input.action_press("p2_down")
	Input.action_press("p1_right")
	await get_tree().create_timer(0.6).timeout
	Input.action_release("p1_right")
	Input.action_release("p2_down")
	_check(p1.state == 7 and p2.state != 7, "Guardia pasiva: correr contra el arma empala")
	p1.revive(Vector2(2600.0, 200.0), 1)
	p1.invuln_time = 0.0
```

(P1 corre en estancia media contra la guardia baja de P2: alturas distintas,
muerte. Si ambas estancias coincidieran, sería choque.)

## Qué NO hacer

- No cambies `_resolve_attacks`: la guardia pasiva es una resolución NUEVA y
  separada; los ataques activos siguen su curso (el `if f.attack_is_active():
  continue` evita dobles resoluciones).
- No apliques la guardia pasiva a quien corre (RUN) ni salta: solo IDLE.
- No la apliques a jugadores aturdidos, derribados o invulnerables.
- No hagas que el empalamiento mate a distancias mayores de
  `ATTACK_RANGE * 0.85`.
- Si ya aplicaste la tarea 24 (arco), excluye también a quien lleve arco:
  añade `and g.weapon_id != "arco"` a la condición de guardián del paso 1
  (el arco no empala: no tiene hoja).

## Criterios de aceptación

1. Correr contra un rival parado con la espada en guardia, a altura distinta,
   mata al que corre (empalado en el arma).
2. Entrar a la misma altura produce un choque normal (ambos salen despedidos).
3. Parado delante de un rival parado, sin moverse, no pasa nada (nadie muere
   por estar cerca: hace falta VELOCIDAD hacia la guardia).
4. El bot ya no se lanza a caminar contra la guardia: ataca o retrocede.
5. El smoke test pasa completo, incluida la sección 25 nueva.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
