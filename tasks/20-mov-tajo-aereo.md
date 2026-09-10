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
