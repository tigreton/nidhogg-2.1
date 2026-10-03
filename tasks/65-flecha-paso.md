# Tarea 65 — Flecha grande del paso (anuncio del derecho de avance)

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** ninguno

## Objetivo

La seña de identidad de Nidhogg: al ganar el paso (matar), aparece una
**flecha grande en el color del verdugo apuntando hacia SU meta** durante
~1,4 s (la ventana de `round_lock`). Hoy el paso solo se lee en el halo sutil
bajo los pies y el "¡CORRE!" del portador; con la flecha, el ping-pong del
tug-of-war se entiende de un vistazo.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript), monolito `scripts/game.gd`.
- El paso se otorga en `_after_death(def, atk)` (línea ~2074): la rama
  `if atk != null and atk.state != Player.State.DEAD: right_of_way = atk`
  es el punto de anclaje principal; también hay herencia al compañero
  (`right_of_way = mate`).
- `_build_hud()` crea el `CanvasLayer` `cl` con `fight_label` y su patrón de
  tween (`create_tween()`, `tween_property(...modulate:a...)`) — imítalo.
- Sprite disponible: `res://art/sprites/arrow_neutral.png` (64×42, apunta a
  la derecha; ya se usa teñido en `_goal_zone` con `modulate`).
- `P1_COLOR`/`P2_COLOR` son los colores de equipo; el portador tiene
  `p.goal_dir` (+1 meta a la derecha, −1 a la izquierda) y `p.color`.
- Tras `_kill` hay hitstop (pausa 0,08 s) y cámara lenta: usa
  `create_tween()` normal (escala con Engine.time_scale como el cartel de
  FIGHT, que ya convive con ello).
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en
  español. Al terminar ejecuta el smoke (última línea `SMOKE OK - ...`).

## Instrucciones paso a paso

### 1. Nodo de la flecha en el HUD

En `_build_hud()`, justo después del bloque de `fight_label`, añade:

```gdscript
	step_arrow = TextureRect.new()
	step_arrow.texture = preload("res://art/sprites/arrow_neutral.png")
	step_arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	step_arrow.pivot_offset = Vector2(32.0, 21.0)
	step_arrow.position = Vector2(VIEW_W * 0.5 - 32.0, 108.0)
	step_arrow.modulate.a = 0.0
	cl.add_child(step_arrow)
```

Y la variable junto a `var fight_label: Label`:

```gdscript
var step_arrow: TextureRect
var step_arrow_tween: Tween
```

### 2. Función que la muestra

Junto a `_show_fight()`:

```gdscript
func _show_step_arrow(p: Player) -> void:
	# flecha grande del derecho de avance: color del verdugo, hacia su meta
	if step_arrow == null:
		return
	step_arrow.flip_h = p.goal_dir < 0
	step_arrow.modulate = Color(p.color.r, p.color.g, p.color.b, 0.0)
	step_arrow.scale = Vector2(2.6, 2.6)
	if step_arrow_tween != null:
		step_arrow_tween.kill()
	step_arrow_tween = step_arrow.create_tween()
	step_arrow_tween.tween_property(step_arrow, "modulate:a", 1.0, 0.12)
	step_arrow_tween.tween_interval(0.9)
	step_arrow_tween.tween_property(step_arrow, "modulate:a", 0.0, 0.3)
```

### 3. Llamarla al ganar el paso

En `_after_death`, rama del asesino:

```gdscript
	if atk != null and atk.state != Player.State.DEAD:
		right_of_way = atk
		_show_step_arrow(atk)
		return
```

Y en la herencia al compañero, justo tras `right_of_way = mate`:

```gdscript
			_show_step_arrow(mate)
```

## Qué NO hacer

- No la muestres al PERDER el paso (solo al ganarlo): el silencio al morir
  también comunica.
- No uses `Label` ni texto: es una flecha dibujada, como el original.
- No la hagas persistente: ~1,4 s y fuera (el HUD ya tiene el halo permanente
  para el estado).

## Criterios de aceptación

1. Matar a un rival muestra la flecha grande en el color del matador,
   apuntando hacia la meta de ese jugador (volteada si corre a la izquierda).
2. En 2v2, heredar el paso al compañero también la muestra.
3. Desaparece sola en ~1,4 s y no interfiere con el cartel ¡FIGHT! (posición
   distinta: y=108 vs 0,30·VIEW_H).
4. Smoke `SMOKE OK` (esta tarea no toca lógica de juego).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
