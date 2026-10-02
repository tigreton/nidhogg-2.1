# Tarea 47 — Parada blanda por alturas y rebote mínimo contra guardia

**Dificultad:** media · **Archivos:** `scripts/player.gd`, `scripts/game.gd`, `test/smoke_test.gd`, `test/suite_combate.gd` · **Prerrequisitos:** 42 aplicada (actualiza su suite)

## Objetivo

Separar dos cosas que hoy viven juntas en el choque:
- **Parada blanda** (portada del hermano): si ATACAS contra un rival que
  simplemente GUARDA a tu misma altura, nadie muere, nadie queda aturdido y
  nadie pierde el arma: ambos rebotan lo justo para separarse (impulso 160
  px/s durante 0,15 s) con chispa. Parar deja de ser un castigo para quien
  guarda.
- **Clash fuerte** (se mantiene): dos ATAQUES simultáneos a la misma altura
  siguen siendo el choque actual (stun + desarme del que ataca en alto).
- Además, **correr contra una guardia a la misma altura** pasa de choque con
  stun a **rebote mínimo** (impulso 130, 0,12 s, cooldown compartido 0,3 s):
  te separas sin quedar a merced del rival.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/game.gd::_resolve_attacks()` — la cadena de outcomes distingue ya
  el doble ataque (`def.state == ATTACK and def.attack_is_active()` →
  clash/trade) ANTES de llegar al `else` donde está la guardia: la rama
  `if d == h and atk.has_sword and def.weapon_id != "arco": outcome = "clash"`
  solo se alcanza cuando el defensor NO está atacando → ahí va la parada.
  El `match outcome` ejecuta `"clash": _clash(atk, def)`.
- `_clash(a, b)` (stun 0,34, impulso ±380/−240, desarma al que ataca en HIGH)
  NO se toca: la siguen usando el doble ataque, la patada voladora contra
  ataque y el dive contra estocada MID.
- `_resolve_guard_impale()` — rama `if f.stance == g.stance:` llama hoy a
  `_clash(f, g)`; a distinta estancia mata (eso no cambia).
- `scripts/player.gd` — no hay mecanismo de empuje persistente: asignar
  `velocity.x` en IDLE se machaca al frame siguiente. La parada necesita un
  empuje que viva su tiempo (el hermano usa 0,15 s). La tarea 44 puede estar
  aplicada o no: el mecanismo funciona igual en ambos casos.
- El smoke caso 3 ("Choque con estancias iguales → ambos STUNNED") hoy solo
  ataca P1 contra P2 en guardia: con la parada pasa a rebote — la tarea lo
  reescribe.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en
  español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Empuje persistente en el jugador

En `scripts/player.gd`, junto a `var stun_time := 0.0`, añade:

```gdscript
var push_time := 0.0        # empuje activo de parada/rebote (segundos)
var push_vel := Vector2.ZERO
```

En `_physics_process`, junto al descuento de `roll_cd`, añade:

```gdscript
	push_time = maxf(0.0, push_time - delta)
```

En el SEGUNDO `match state:` (el de velocidad), el caso `State.IDLE, State.RUN:`
debe respetar el empuje: si aplicaste la tarea 44, queda así:

```gdscript
		State.IDLE, State.RUN:
			if push_time > 0.0:
				velocity.x = push_vel.x
			else:
				var sp := DUCK_SPEED if stance == H.LOW else SPEED * (UNARMED_SPEED_MULT if not has_sword else run_mult())
				# arranque en rampa: acelerar cuesta ~6 frames, frenar ~4
				var rate := GROUND_ACCEL if dir != 0.0 else GROUND_FRICTION
				velocity.x = move_toward(velocity.x, dir * sp, rate * delta)
			state = State.RUN if absf(velocity.x) > 5.0 else State.IDLE
			run_phase += velocity.x * delta * 0.045
```

Si NO aplicaste la 44, el `else` interno es el original
(`velocity.x = dir * sp` … sin `rate`). Y añade el método público:

```gdscript
## Empuje temporal de separación (parada/rebote): pisa la velocidad horizontal.
func apply_push(v: Vector2, t: float) -> void:
	push_vel = v
	push_time = t
```

### 2. Constantes y cooldown en el juego

En `scripts/game.gd`, junto a las constantes de la zona superior (p. ej. tras
`RESPAWN_DELAY`), añade:

```gdscript
const PARRY_IMPULSE := 160.0    # parada blanda: px/s de separación
const PARRY_PUSH_TIME := 0.15   # duración del empuje de parada
const CLASH_IMPULSE := 130.0    # rebote mínimo contra guardia
const CLASH_PUSH_TIME := 0.12
const PARRY_COOLDOWN := 0.3     # anti re-trigger del rebote sostenido
```

Junto a `var shake_time := 0.0`, añade:

```gdscript
var parry_cd := 0.0
```

En `_physics_process`, junto a `shake_time = maxf(0.0, shake_time - delta)`,
añade:

```gdscript
	parry_cd = maxf(0.0, parry_cd - delta)
```

### 3. La parada blanda

En `_resolve_attacks`, cambia la línea de la guardia a la misma altura:

```gdscript
			var d: int = def.stance
			if d == h and atk.has_sword and def.weapon_id != "arco":
				outcome = "clash"
```

por:

```gdscript
			var d: int = def.stance
			if d == h and atk.has_sword and def.weapon_id != "arco":
				outcome = "parry"   # guardia quieta a la misma altura: parada blanda
```

Y en el `match outcome:` añade la rama nueva (el `"clash"` se queda, lo usan
el doble ataque y los choques de dive/divekick):

```gdscript
			"clash":
				_clash(atk, def)
			"parry":
				_parry(atk, def)
```

Añade la función junto a `_clash`:

```gdscript
func _parry(a: Player, b: Player) -> void:
	# parada blanda: nadie muere, nadie se aturde; rebote de separación y chispa
	var mid := Vector2((a.position.x + b.position.x) * 0.5, minf(a.position.y, b.position.y) - 14.0)
	_burst(mid, Color(1.0, 0.93, 0.55), 8, 240.0)
	sfx(mid, "clash", -12.0)
	var push_b := 1 if b.position.x >= a.position.x else -1
	a.apply_push(Vector2(-float(push_b) * PARRY_IMPULSE, 0.0), PARRY_PUSH_TIME)
	b.apply_push(Vector2(float(push_b) * PARRY_IMPULSE, 0.0), PARRY_PUSH_TIME)
	parry_cd = PARRY_COOLDOWN
```

### 4. Rebote mínimo contra guardia (misma estancia)

En `_resolve_guard_impale`, sustituye la rama:

```gdscript
			if f.stance == g.stance:
				if f.position.x <= g.position.x:
					_clash(f, g)
				else:
					_clash(g, f)
```

por:

```gdscript
			if f.stance == g.stance:
				if parry_cd > 0.0:
					continue
				# rebote mínimo: ambos se separan sin stun ni desarme
				f.apply_push(Vector2(-float(f.facing) * CLASH_IMPULSE, 0.0), CLASH_PUSH_TIME)
				g.apply_push(Vector2(-float(g.facing) * CLASH_IMPULSE, 0.0), CLASH_PUSH_TIME)
				var mid := Vector2((f.position.x + g.position.x) * 0.5, minf(f.position.y, g.position.y) - 14.0)
				_burst(mid, Color(1.0, 0.93, 0.55), 6, 200.0)
				sfx(mid, "clash", -14.0)
				parry_cd = PARRY_COOLDOWN
```

(Ojo: esa rama termina con `return` al final del bucle exterior; déjalo como
está. El `continue` respeta la estructura del `for f in _foes_of(g):`.)

### 5. Reescribir el caso 3 del smoke

En `test/smoke_test.gd`, sustituye el caso 3 completo:

```gdscript
	# 3. Choque de espadas: misma estancia (MID vs MID) -> ambos aturdidos
	p2.position = p1.position + Vector2(70.0, 0.0)
	p1.facing = 1
	await get_tree().physics_frame
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.14).timeout
	Input.action_release("p1_attack")
	_check(p2.state == 5 and p1.state == 5, "Choque con estancias iguales (ambos STUNNED)")
	await get_tree().create_timer(1.1).timeout
```

por:

```gdscript
	# 3. Parada blanda: atacar contra guardia a la misma altura no aturde a nadie
	p2.position = p1.position + Vector2(70.0, 0.0)
	p1.facing = 1
	await get_tree().physics_frame
	Input.action_press("p1_attack")
	await get_tree().create_timer(0.14).timeout
	Input.action_release("p1_attack")
	var sep3: float = absf(p2.position.x - p1.position.x)
	_check(p1.state != 5 and p2.state != 5 and p2.state != 7, "Parada blanda con estancias iguales (nadie aturdido ni muerto)")
	_check(sep3 >= 70.0, "La parada separa (o al menos no acerca) a los duelistas")
	await get_tree().create_timer(0.8).timeout
```

### 6. Caso nuevo del smoke (rebote contra guardia)

Justo antes del `print("")` final, añade:

```gdscript
	# 35. Rebote contra guardia a la misma estancia: nadie muere
	game.round_lock = 0.0
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
	Input.action_press("p1_right")
	await get_tree().create_timer(0.5).timeout
	Input.action_release("p1_right")
	_check(p1.state != 7 and p2.state != 7, "Correr contra guardia a la misma estancia: rebote, no muerte")
	_check(p1.state != 5, "El rebote contra guardia no aturde")
	await get_tree().create_timer(0.6).timeout
```

### 7. Actualizar la suite

En `test/suite_combate.gd`:
- `choque_doble_ataque_misma_altura`: SIN cambios (el doble ataque sigue
  siendo clash fuerte con stun).
- Cambia `guardia_pasiva_distinta_altura_mata` NO: sigue igual (mata).
- Añade un test nuevo al array de `get_tests()`:

```gdscript
		["parada_blanda_ataque_vs_guardia", _t_parada],
```

y la función:

```gdscript
func _t_parada() -> bool:
	_reset(1600.0, 1670.0)
	await runner.step_physics(1)
	Input.action_press("p1_attack")
	await runner.step_physics(9)
	Input.action_release("p1_attack")
	var p1: Player = runner.game.players[0]
	var p2: Player = runner.game.players[1]
	var ok: bool = p1.state != Player.State.STUNNED and p2.state != Player.State.STUNNED \
			and p1.state != Player.State.DEAD and p2.state != Player.State.DEAD
	runner.release_all()
	await runner.wait(0.5)
	_reset(1600.0, 4400.0)
	return runner.check(ok, "atacar contra guardia a la misma altura: parada sin stun ni muerte")  # L47
```

## Qué NO hacer

- No toques `_clash` ni sus llamadas existentes (doble ataque, divekick vs
  ataque, dive vs estocada MID): siguen siendo choque fuerte.
- No desarmes a nadie en la parada ni en el rebote: eso es EXCLUSIVO del
  clash doble y del sidekick.
- No quites la muerte por guardia a DISTINTA estancia (`_kill(f, g)`).
- No dejes el rebote sin cooldown: se re-dispararía cada frame mientras el
  corredor siga apretando.

## Criterios de aceptación

1. Atacar a un rival quieto que guarda a tu altura: chispa, ambos se separan,
   nadie aturdido, nadie desarmado, ambos vivos.
2. Dos ataques simultáneos a la misma altura: choque fuerte como siempre.
3. Correr contra una guardia a tu misma estancia: rebote mínimo repetible
   cada ~0,3 s, sin muerte ni stun.
4. Correr a DISTINTA estancia contra guardia: muerte (sin cambios).
5. Runner `ALL PASSED (11)` y smoke `SMOKE OK` con los casos 3 y 35 nuevos.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/test_runner.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Últimas líneas esperadas: `RESULT: ALL PASSED (11)` y
`SMOKE OK - todas las mecánicas funcionan`.

## Nota de aplicación (2026-10-03)

Aplicada con un ajuste de mecánica no previsto: con el empuje pisando solo
IDLE/RUN, el **atacante seguía deslizándose a 110 px/s durante el resto de su
animación de ATTACK** y la parada acababa acercando a los duelistas (~9 px
netos), contrario al criterio "la parada separa". El caso `State.ATTACK` del
segundo `match` respeta ahora `push_time` antes que la deriva (la estocada
con `attack_dash_time` queda por debajo del empuje). Con eso: `SMOKE OK`
(casos 3 y 35) y `ALL PASSED (11)`. El caso 3 del smoke mide la separación
tras 0,8 s (cuando el ataque ya acabó) porque antes de ese punto la deriva
propia de la animación todavía contamina la medida.
