# Tarea 93 — Sangre en las superficies elevadas (puente, piso de la torre)

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** 29 y 85
aplicadas (bug/limitación de la revisión post-fusión, 2026-10-04)

## Objetivo

`_add_blood` solo admite muertes a ±80 px de `GROUND_Y`: no hay charco ni
en el puente alto (y=288), ni en la plataforma del foso, ni en el piso
superior de la torre (y=320). Reutilizar `_top_below` (que `_drop_sword` ya
usa para lo mismo) para apoyar el charco en la superficie elevada que
corresponda.

## Contexto del proyecto (leer antes de tocar nada)

- `_add_blood(pos, col)`: hoy `if absf(pos.y - (GROUND_Y - 29.0)) > 80.0:
  return` y luego fija el charco en `Vector2(_out_of_pit(pos.x) ± jitter,
  GROUND_Y ± jitter)`.
- `_top_below(x, y)` devuelve la y de la primera superficie registrada por
  debajo de y (puente, plataformas, pisos; `_register_top`), o `<= 0` si no
  hay nada: así `_drop_sword` elige dónde cae el arma.
- Los pies del jugador están a `superficie − 29`: muerto en el piso de la
  torre y≈291, en el puente y≈259. El suelo normal es y=531.
- CUIDADO con `_out_of_pit`: el puente CRUZA el foso central, así que un
  charco en el puente con `_out_of_pit(x)` saldría desplazado al borde: el
  empuje anti-foso solo aplica a nivel de suelo.

## Instrucciones paso a paso

### 1. En `game.gd`, sustituir el arranque de `_add_blood`

Busca:

```gdscript
func _add_blood(pos: Vector2, col: Color) -> void:
	# solo hay sangre si la víctima cayó cerca de un suelo pisable
	if absf(pos.y - (GROUND_Y - 29.0)) > 80.0:
		return
```

y sustitúyelo por:

```gdscript
func _add_blood(pos: Vector2, col: Color) -> void:
	# solo hay sangre si la víctima cayó cerca de un suelo pisable: el de
	# abajo o cualquiera de las superficies elevadas (puente, torre…)
	var surface := GROUND_Y
	if absf(pos.y - (GROUND_Y - 29.0)) > 80.0:
		var top := _top_below(pos.x, pos.y)
		if top <= 0.0 or absf(pos.y - (top - 29.0)) > 80.0:
			return
		surface = top
```

### 2. Ajustar la posición del charco a la superficie elegida

En la misma función, busca la línea:

```gdscript
	var bp := BloodPool.new(c)
	bp.position = Vector2(_out_of_pit(pos.x) + randf_range(-14.0, 14.0), GROUND_Y + randf_range(-2.0, 2.0))
```

y sustitúyela por:

```gdscript
	var bp := BloodPool.new(c)
	# el anti-foso solo aplica a nivel de suelo: el puente cruza EL foso
	var px := _out_of_pit(pos.x) if surface == GROUND_Y else pos.x
	bp.position = Vector2(px + randf_range(-14.0, 14.0), surface + randf_range(-2.0, 2.0))
```

## Qué NO hacer

- No toques el FIFO de 200 charcos ni el `z_index`.
- No llames a `_register_top` para nada nuevo: las superficies ya están
  registradas (puente, peldaños, piso de la torre).
- No pongas sangre en el aire (el `return` con `top <= 0` lo evita: sin
  superficie debajo, no hay charco).

## Criterios de aceptación

1. Mata a alguien sobre el PUENTE alto: charco persistente sobre las tablas
   (y≈288), no en el suelo de abajo ni empujado al borde del foso.
2. Mata a alguien en el PISO SUPERIOR de la torre: charco a y≈320.
3. Las muertes a nivel de suelo siguen dejando charco igual que siempre
   (mismo jitter, mismo anti-foso).
4. Una muerte en pleno salto sobre el vacío (sin superficie bajo ella en
   80 px) no deja charco, como hasta ahora.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan` (el caso
"Sangre: la muerte deja charco" es a nivel de suelo y no cambia).
