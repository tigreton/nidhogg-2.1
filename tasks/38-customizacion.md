# Tarea 38 — Customización de personajes (pelo y piel)

**Dificultad:** media · **Archivos:** `scripts/match_rules.gd`, `scripts/player.gd`, `scripts/title.gd` · **Prerrequisitos:** tarea 37 (pantalla de título con `MatchRules` y `title.gd`)

## Objetivo

Customización básica como el original: cada jugador elige **peinado** (calvo,
melena puntiaguda, casco con penacho) y **tono de piel** (3 tonos), con teclas
en la propia pantalla de título y dos figuras de previsualización dibujadas
proceduralmente.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript), arte y sonido procedurales, indentación con
  **tabs**, comentarios en español.
- La tarea 37 ya aplicó: `scripts/match_rules.gd` con `class_name MatchRules`
  (variables estáticas), `scripts/title.gd` (Control con `rules_label`,
  `_update_rules()` y `_unhandled_key_input` con un `match k.keycode:` que
  termina con `_:` → `return` y luego llama `_update_rules()`), y
  `scenes/title.tscn` como escena principal.
- `scripts/player.gd` — el dibujo procedural está en `_draw()`; la cabeza es:
  `draw_circle(Vector2(1, -28), 10.0, dark)` seguida de
  `draw_circle(Vector2(1, -28), 8.0, c)`. Tras la cabeza viene
  `var wag := sin(anim_time * 12.0) * 3.0` (la cola del color del jugador).
  `var c := color if flash_time <= 0.0 else Color.WHITE` (parpadeo blanco al
  recibir un choque) y `var dark := Color(0.05, 0.04, 0.08)`.
  `player_id` es 1..4 (en 2v2 los aliados comparten estilo con P1/P2).
- En `title.gd` hay un `bg` (ColorRect) hijo: cualquier dibujo del título debe
  ir en un nodo hijo AÑADIDO DESPUÉS del bg, si no quedaría tapado.
- El smoke test no toca el título ni los estilos: no hay que tocarlo.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. `match_rules.gd`: estilos por jugador

Añade debajo de `static var allow_roll := true`:

```gdscript
static var hair := [1, 2]   # 0 calvo, 1 melena, 2 casco con penacho
static var skin := [0, 1]   # índice en la paleta de 3 tonos
```

### 2. `player.gd`: dibujar piel y pelo

2.1. Sustituye las dos líneas de la cabeza
(`draw_circle(Vector2(1, -28), 10.0, dark)` y
`draw_circle(Vector2(1, -28), 8.0, c)`) por:

```gdscript
	var skin_cols := [Color(0.93, 0.78, 0.62), Color(0.72, 0.52, 0.36), Color(0.45, 0.30, 0.20)]
	var skin: Color = skin_cols[MatchRules.skin[clampi(player_id - 1, 0, 1)] % skin_cols.size()] if flash_time <= 0.0 else Color.WHITE
	draw_circle(Vector2(1, -28), 10.0, dark)
	draw_circle(Vector2(1, -28), 8.0, skin)
	_match_hair(skin, c, dark)
```

(la línea de la cola `var wag := ...` y su `draw_line` quedan justo después,
sin cambios.)

2.2. Al final del archivo (después de `_draw()`), añade:

```gdscript
func _match_hair(skin: Color, c: Color, dark: Color) -> void:
	match MatchRules.hair[clampi(player_id - 1, 0, 1)] % 3:
		1:
			# melena puntiaguda
			draw_colored_polygon(PackedVector2Array([Vector2(-8, -30), Vector2(10, -30), Vector2(1, -44)]), Color(0.12, 0.09, 0.07))
			draw_line(Vector2(-9, -28), Vector2(-13, -22), Color(0.12, 0.09, 0.07), 3.0)
		2:
			# casco con penacho del color del jugador
			draw_arc(Vector2(1, -28), 10.5, PI, TAU, 12, dark, 5.0)
			draw_line(Vector2(1, -40), Vector2(1, -50), c, 4.0)
		_:
			pass
```

### 3. `title.gd`: teclas y previsualización

3.1. Sustituye TODO el cuerpo de `_update_rules()` por esta versión (añade la
línea de teclas de aspecto):

```gdscript
func _update_rules() -> void:
	rules_label.text = "PUNTOS PARA GANAR: %d    (teclas 1 / 3 / 5)\nLANZAR ARMA: %s (T)      RODAR: %s (R)\nZ/X: aspecto P1   ·   N/M: aspecto P2\n\nENTER o ESPACIO: jugar" % [
		MatchRules.win_score,
		"SÍ" if MatchRules.allow_throw else "NO",
		"SÍ" if MatchRules.allow_roll else "NO",
	]
```

3.2. En `_unhandled_key_input`, añade estos casos al `match` (antes del
`KEY_ENTER, KEY_SPACE:`):

```gdscript
		KEY_Z:
			MatchRules.hair[0] = (MatchRules.hair[0] + 1) % 3
		KEY_X:
			MatchRules.skin[0] = (MatchRules.skin[0] + 1) % 3
		KEY_N:
			MatchRules.hair[1] = (MatchRules.hair[1] + 1) % 3
		KEY_M:
			MatchRules.skin[1] = (MatchRules.skin[1] + 1) % 3
```

3.3. En `_ready()`, justo después de `add_child(bg)`, añade la figura de
previsualización:

```gdscript
	var preview := PreviewFigure.new()
	add_child(preview)
```

3.4. Al final del archivo, añade la clase interna:

```gdscript
class PreviewFigure extends Control:
	## Dos duelistas en miniatura con el aspecto elegido.
	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		for i in 2:
			var hx := 420.0 + 312.0 * float(i)
			var skin_cols := [Color(0.93, 0.78, 0.62), Color(0.72, 0.52, 0.36), Color(0.45, 0.30, 0.20)]
			var skin: Color = skin_cols[MatchRules.skin[i] % skin_cols.size()]
			var body := Color("ffb324") if i == 0 else Color("39d7ff")
			draw_line(Vector2(hx, 470), Vector2(hx, 430), body, 16.0)
			draw_circle(Vector2(hx, 418), 9.0, skin)
			match MatchRules.hair[i] % 3:
				1:
					draw_colored_polygon(PackedVector2Array([Vector2(hx - 8, 416), Vector2(hx + 10, 416), Vector2(hx + 1, 402)]), Color(0.12, 0.09, 0.07))
				2:
					draw_arc(Vector2(hx, 418), 10.5, PI, TAU, 12, Color(0.05, 0.04, 0.08), 5.0)
					draw_line(Vector2(hx, 406), Vector2(hx, 396), body, 4.0)
```

## Qué NO hacer

- No cambies los colores de equipo (`P1_COLOR`/`P2_COLOR`): la identidad del
  color se conserva; solo cambian piel y pelo.
- No añadas más opciones de las 3×3 (mantén el formato simple).
- No hagas que los bots cambien de aspecto en caliente: se ven al reaparecer
  y en cada frame de `_draw`, así que se actualizan solos.
- No toques el smoke test.

## Criterios de aceptación

1. En el título se ven dos duelistas en miniatura con el aspecto actual.
2. Z/X cicla pelo y piel de P1; N/M los de P2; la previsualización cambia al
   instante.
3. En partida, cada duelistat muestra su piel y su peinado (también los
   aliados del 2v2).
4. El parpadeo blanco al chocar sigue funcionando (la piel también parpadea).
5. El smoke test sigue pasando sin cambios.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
