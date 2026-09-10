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
