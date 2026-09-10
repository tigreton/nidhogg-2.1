# Tarea 19 — El choque desarma al que ataca en alto

**Dificultad:** media · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** ninguno

## Objetivo

Endurecer el riesgo de la estancia alta: cuando dos espadas chocan (`_clash`),
quien ATACABA con la espada en alto pierde la espada — sale despedida y cae al
suelo unos metros detrás, recogible como cualquier espada lanzada. Si ambos
atacaban en alto, los dos quedan desarmados. Esto convierte el spam de ataque
alto en una apuesta y crea duelos desesperados a puñetazo/patada hasta
recuperar el arma.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/game.gd`:
	- `_clash(a: Player, b: Player)` es donde se resuelve todo choque (lo llaman
	  el choque de ataques y el choque ataque-vs-patada). Hoy hace: destello
	  (`_burst`), sonido, sacudida (`shake_time`) y `take_clash(push)` para
	  empujar a los dos.
	- `take_clash()` cambia el estado del jugador a STUNNED: por eso las
	  condiciones del desarme hay que leerlas ANTES de llamarlo.
	- `_drop_sword(pos, col)` crea la espada caída (`SwordPickup`) en el suelo
	  bajo esa posición; se recoge pasando por encima (`_update_pickups` solo la
	  recogen jugadores con `has_sword == false`).
	- `Player` tiene `has_sword`, `attack_height` (estancia del golpe:
	  `H.LOW/MID/HIGH`) y `state` (`State.ATTACK`, `State.DIVEKICK`, ...).
	- La patada voladora choca vía `_clash(def, p)` con `p` en DIVEKICK: quien
	  patea NO debe poder ser desarmado (no lleva la espada en el golpe).
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

Sustituye en `scripts/game.gd` la función `_clash` COMPLETA por:

```gdscript
func _clash(a: Player, b: Player) -> void:
	var mid := Vector2((a.position.x + b.position.x) * 0.5, minf(a.position.y, b.position.y) - 14.0)
	_burst(mid, Color(1.0, 0.93, 0.55), 14, 320.0)
	sfx(mid, "clash", -8.0)
	shake_time = maxf(shake_time, 0.14)
	# el choque desarma a quien atacaba con la espada en alto
	var disarmed: Array[Player] = []
	for p in [a, b]:
		if p.state == Player.State.ATTACK and p.attack_height == Player.H.HIGH and p.has_sword:
			disarmed.append(p)
	var push_b := 1 if b.position.x >= a.position.x else -1
	b.take_clash(push_b)
	a.take_clash(-push_b)
	for p in disarmed:
		p.has_sword = false
		_drop_sword(p.position + Vector2(-float(p.facing) * 110.0, -30.0), Color(0.87, 0.9, 0.95))
		_burst(p.position + Vector2(0, -20), Color(0.95, 0.95, 1.0), 8, 240.0)
		sfx(p.position, "throw", -14.0)
```

Puntos clave del código (para que lo entiendas, no para cambiarlo):

- La comprobación `p.state == Player.State.ATTACK` se hace ANTES de
  `take_clash()` porque después ambos ya están STUNNED; además excluye a quien
  patea en el aire (DIVEKICK).
- La espada cae DETRÁS del desarmado (`-facing * 110`) y algo elevada; `_drop_sword`
  la apoya en el suelo de debajo.
- Al perder `has_sword`, el dibujo de la espada desaparece solo (el bloque
  `if has_sword:` de `_draw()`).

## Qué NO hacer

- No desarmes a quien DEFENDÍA (solo a quien estaba atacando en alto): el
  defensor ya "ganó" el choque al leer la altura.
- No desarmes en choques de patada voladora.
- No mandes la espada volando como proyectil (`SwordProjectile`): cae directa
  al suelo como pickup; cruzarla en vuelo sería demasiado castigo.

## Criterios de aceptación

1. Atacar en alto contra defensa alta: choque y TU espada sale despedida hacia
   atrás y cae; quedas desarmado (sin espada visible) hasta recogerla.
2. Choque de dos ataques altos: ambos quedan desarmados.
3. Choques en media o baja: nadie pierde la espada (igual que antes).
4. La espada caída se recoge pasando por encima, con su halo pulsante.
5. El desarmado sigue poder hacer patada voladora (y puñetazo si aplicaste esa
   tarea) mientras busca su espada.
6. El smoke test sigue pasando (su choque del test 3 es MID vs MID).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.

Nota: sobre el foso central, `_drop_sword` descarta la espada dentro del hueco
(comportamiento actual del juego); la tarea del fix del foso (`17`) la reubica
en el borde si también la aplicas.
