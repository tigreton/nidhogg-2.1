# Tarea 49 — Lanzamiento de arma desviado por las alturas que mata

**Dificultad:** media · **Archivos:** `scripts/game.gd`, `scripts/game_config.gd`, `test/smoke_test.gd`, `test/suite_combate.gd` · **Prerrequisitos:** 42 aplicada (actualiza su suite)

## Objetivo

Regla portada del proyecto hermano para el arma lanzada: la guardia del
rival la **desvía solo si su estancia está entre las alturas a las que esa
arma mata al ser lanzada** (`thrown_kills`). Hoy cualquier arma se desvía
únicamente con la guardia MEDIA; con esto:
- **Florete/espadón** (matan a LOW/MID/HIGH): cualquier guardia los desvía
  (como hasta ahora, generalizado).
- **Daga** (solo mata en HIGH): la guardia ALTA la desvía; una guardia MEDIA
  o BAJA la recibe y solo queda **derribada** (el arma cae al suelo).
- **Arco lanzable**: el arco se puede lanzar (400 px/s) y **nunca mata**:
  siempre derriba al impacto.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/game_config.gd` — `WEAPONS`: cada arma tiene `thrown_speed` y
  `thrown_kills` (lista de "LOW"/"MID"/"HIGH"). El arco hoy tiene
  `thrown_speed: 0.0` y `thrown_kills: []`.
- `scripts/game.gd::_update_projectiles(delta)` — la línea que decide el
  desvío:

```gdscript
				var blocks: bool = (p.stance == Player.H.MID and p.state in [Player.State.IDLE, Player.State.RUN, Player.State.JUMP]) or (p.state == Player.State.ATTACK and p.attack_is_active())
```

  y más abajo, en la rama de impacto, recalcula
  `var kills: Array = GameConfig.WEAPONS[s.weapon_id]["thrown_kills"]` y
  `var vs: String = ["LOW", "MID", "HIGH"][p.stance]` para decidir mata vs
  derriba (el derribo deja el arma como pickup).
- `scripts/player.gd` — el lanzamiento es `hit("throw") and has_sword` (con
  `MatchRules.allow_throw`): `has_sword` es cierto también con el arco
  equipado, así que el arco lanzable no necesita tocar el jugador.
- El smoke caso 10 ("La guardia media desvía la espada lanzada") usa florete
  lanzado contra guardia MEDIA: con la regla nueva sigue desviando (el
  florete mata a las tres alturas) — no hay que cambiarlo.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en
  español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. El arco se puede lanzar

En `scripts/game_config.gd`, en el arma `"arco"`, cambia:

```gdscript
		"run_mult": 0.92, "thrown_speed": 0.0,
```

por:

```gdscript
		"run_mult": 0.92, "thrown_speed": 400.0,
```

(`thrown_kills: []` ya está: el arco lanzado nunca mata.)

### 2. Desvío por alturas del arma

En `scripts/game.gd::_update_projectiles`, sustituye el bloque de decisión
completo (desde `var blocks` hasta el final del `if/else`):

```gdscript
				if absf(p.position.x - s.position.x) < 30.0 and absf(p.position.y - s.position.y) < 36.0:
					var blocks: bool = (p.stance == Player.H.MID and p.state in [Player.State.IDLE, Player.State.RUN, Player.State.JUMP]) or (p.state == Player.State.ATTACK and p.attack_is_active())
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
					done.append(s)
					break
```

por:

```gdscript
				if absf(p.position.x - s.position.x) < 30.0 and absf(p.position.y - s.position.y) < 36.0:
					# desvía solo si la estancia del guardián está entre las
					# alturas a las que el arma lanzada mata (regla del hermano)
					var kills: Array = GameConfig.WEAPONS[s.weapon_id]["thrown_kills"]
					var vs: String = ["LOW", "MID", "HIGH"][p.stance]
					var blocks: bool = (vs in kills and p.state in [Player.State.IDLE, Player.State.RUN, Player.State.JUMP]) or (p.state == Player.State.ATTACK and p.attack_is_active())
					if blocks:
						_burst(s.position, Color(0.9, 0.9, 1.0), 10, 260.0)
						sfx(s.position, "clash", -12.0)
						_drop_sword(s.position, s.color, s.weapon_id)
					else:
						if vs in kills:
							_kill(p, s.thrower)
						else:
							# no mata a esa altura (o nunca mata, como el arco): derriba
							var push := 1 if p.position.x >= s.position.x else -1
							p.knockdown(push)
							_burst(s.position, Color(0.9, 0.9, 1.0), 10, 260.0)
							sfx(s.position, "clash", -12.0)
							_drop_sword(s.position, s.color, s.weapon_id)
					done.append(s)
					break
```

Nota: la espada que golpea a un jugador en el aire mantiene el
comportamiento de siempre (`p.stance` en el aire es su última estancia); el
cambio real es la condición de `blocks` y el derribo en la rama contraria.

### 3. Casos nuevos del smoke

En `test/smoke_test.gd`, justo antes del `print("")` final, añade:

```gdscript
	# 36. Daga lanzada: solo la guardia alta la desvía; la media la recibe derribada
	p1.has_sword = true
	p1.weapon_id = "daga"
	p2.has_sword = true
	p2.weapon_id = "florete"
	p1.position = Vector2(1600.0, 531.0)
	p2.position = Vector2(1750.0, 531.0)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.state = 0
	p2.state = 0
	p1.invuln_time = 0.0
	p2.invuln_time = 0.0
	p1.facing = 1
	await get_tree().physics_frame
	Input.action_press("p1_throw")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("p1_throw")
	await get_tree().create_timer(0.4).timeout
	_check(p2.state == 6, "Daga lanzada contra guardia MEDIA: derriba (no la desvía)")
	_check(game.pickups.size() >= 1, "La daga cae al suelo tras el impacto")
	await get_tree().create_timer(1.2).timeout

	# 37. El arco lanzado nunca mata: derriba
	p1.has_sword = true
	p1.weapon_id = "arco"
	p1.position = Vector2(1600.0, 531.0)
	p2.position = Vector2(1750.0, 531.0)
	p2.velocity = Vector2.ZERO
	p2.state = 0
	p2.invuln_time = 0.0
	p1.velocity = Vector2.ZERO
	p1.state = 0
	p1.invuln_time = 0.0
	p1.facing = 1
	await get_tree().physics_frame
	Input.action_press("p1_throw")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("p1_throw")
	await get_tree().create_timer(0.5).timeout
	_check(p2.state == 6 and p2.state != 7, "Arco lanzado: derriba y no mata")
	await get_tree().create_timer(1.2).timeout
```

### 4. Actualizar la suite

En `test/suite_combate.gd`, cambia la nota del test
`espada_lanzada_desviada_por_guardia` (marcado `# L49`) por:

```gdscript
	return runner.check(alive, "la guardia a una altura que el arma mata la desvía") \
			and runner.check(pickup, "el arma desviada cae al suelo")  # L49: generalizado a thrown_kills
```

## Qué NO hacer

- No cambies `thrown_kills` de florete/espadón/daga: la tabla ya está bien
  (es la intención de la tarea).
- No hagas desviar el arma a un rival en JUMP salvo que su estancia esté en
  `thrown_kills` (antes JUMP desviaba con MID: ahora cuenta su estancia).
- No mates nunca con el arco lanzado: su gracia es el derribo.

## Criterios de aceptación

1. Florete/espadón lanzados: cualquier guardia en suelo los desvía (igual
   que antes con la media).
2. Daga lanzada contra guardia ALTA: desviada; contra MEDIA/BAJA: derribo y
   arma en el suelo.
3. Arco lanzado (tecla L / botón B del mando con arco equipado): vuela a
   400 px/s y siempre derriba.
4. Runner `ALL PASSED` y smoke `SMOKE OK` con los casos 36 y 37.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/test_runner.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Últimas líneas esperadas: `RESULT: ALL PASSED (12)` y
`SMOKE OK - todas las mecánicas funcionan`.
