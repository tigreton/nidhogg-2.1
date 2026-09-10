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
