# Tarea 09 — Halo bajo los pies de quien tiene el paso

**Dificultad:** baja · **Archivos:** `scripts/player.gd` · **Prerrequisitos:** ninguno

## Objetivo

Un halo pulsante del color del jugador bajo los pies de quien tiene el paso:
se ve de un vistazo quién está obligado a correr y quién debe interceptar.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural: cada duelist se dibuja entero en su `_draw()`.
- `scripts/player.gd` — `class_name Player` (CharacterBody2D):
	- Variables útiles: `color: Color`, `state: int` (enum `State`, con `DEAD`),
	  `anim_time: float` (crece siempre, sirve para animar).
	- `_draw()` empieza con `if state == State.DEAD: return` y luego define
	  `var c := color ...`. LO QUE SE DIBUJA PRIMERO QUEDA DEBAJO.
	- El padre del jugador es el nodo `game` (`scripts/game.gd`), que tiene la
	  variable pública `right_of_way: Player`.
	- Los pies del duelist quedan en y≈30 (local).
- En GDScript, para leer una propiedad de un nodo sin tiparlo:
  `get_parent().get("right_of_way")` (devuelve null si no existe).
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

En `scripts/player.gd`, dentro de `_draw()`, justo después de las líneas que
definen `c`, `dark` y `blade` (y ANTES de `var t_pos := Vector2.ZERO`, para que
el halo quede debajo del cuerpo), añade:

```gdscript
	var g := get_parent()
	if g != null and g.get("right_of_way") == self:
		var pulse := 0.5 + 0.5 * sin(anim_time * 10.0)
		draw_circle(Vector2(0, 34), 20.0 + 4.0 * pulse, Color(color.r, color.g, color.b, 0.10 + 0.10 * pulse))
		draw_arc(Vector2(0, 34), 24.0, 0.0, TAU, 24, Color(color.r, color.g, color.b, 0.55), 2.0)
```

## Qué NO hacer

- No dibujes el halo si el jugador está muerto (el `return` inicial ya lo evita:
  no lo muevas).
- No apliques transform de tumbado/knockdown al halo (dibújalo antes de
  `draw_set_transform`).
- No lo pongas a ningún jugador fijo: depende de `right_of_way`.

## Criterios de aceptación

1. Al matar, al asesino le aparece un halo naranja/cian pulsante bajo los pies.
2. Si el paso cambia de dueño, el halo se mueve al otro jugador al instante.
3. Con `right_of_way == null` nadie lleva halo.
4. El humo del smoke test sigue pasando.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
