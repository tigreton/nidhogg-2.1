# Tarea 54 — Título con arte: fondo bg_title y preview con sprites

**Dificultad:** baja · **Archivos:** `scripts/title.gd` · **Prerrequisitos:** que exista `res://art/sprites/bg_title.png` (ya importado)

## Objetivo

La pantalla de título deja de ser un `ColorRect` oscuro con texto: pasa a usar
la ilustración `bg_title.png` (derivada del duelo versus) como fondo, y la
previsualización de personajes deja de dibujarse con líneas para mostrar los
sprites reales de P1 y P2. También se retiran las teclas de aspecto (Z/X/N/M),
que dejan de tener efecto visual: los sprites son diseños fijos (decisión de
`PLAN-ARTE.md`; la limpieza de `match_rules.gd` la hace la tarea 60).

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). `scenes/title.tscn` es un `Control` con
  `scripts/title.gd`. El viewport del juego es **1152×648** y el fondo actual
  es un `ColorRect` azul oscuro (`SKY`) de ese tamaño.
- `bg_title.png` mide **960×540**: misma proporción 16:9 que el viewport
  (1152/648 = 960/540), así que un `TextureRect` con `STRETCH_SCALE` cubre
  exacto sin recortes.
- Los sprites de personaje miden 56 px de alto y **miran a la derecha**:
  `player_idle_p1.png` (66×56, azul) y `player_idle_p2.png` (45×56, rojo).
- La clase interna `PreviewFigure` (al final de `title.gd`) se redibuja cada
  frame con `draw_line`/`draw_circle` y lee `MatchRules.hair`/`MatchRules.skin`.
- `_unhandled_key_input` maneja Z/X (pelo/piel P1) y N/M (P2); `_update_rules`
  imprime la línea "Z/X: aspecto P1 · N/M: aspecto P2".
- **No borres** `var hair`/`var skin` de `match_rules.gd` en esta tarea:
  `player.gd` sigue leyéndolas hasta la tarea 60.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en
  español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Fondo con textura

En `_ready()` de `scripts/title.gd`, después del `ColorRect` (consérvalo como
fondo de respaldo por si la textura falla) añade el `TextureRect`:

```gdscript
func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = SKY
	bg.size = Vector2(1152, 648)
	add_child(bg)
	var art := TextureRect.new()
	art.texture = preload("res://art/sprites/bg_title.png")
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.size = Vector2(1152, 648)
	add_child(art)
	...
```

### 2. Preview con los sprites reales

Sustituye por completo la clase `PreviewFigure` del final del archivo por esta
versión con `Sprite2D` (P2 mira a la izquierda para encarar a P1):

```gdscript
class PreviewFigure extends Control:
	## Los dos duelistas del título, con sus sprites definitivos.
	func _ready() -> void:
		for i in 2:
			var s := Sprite2D.new()
			s.texture = preload("res://art/sprites/player_idle_p1.png") if i == 0 \
					else preload("res://art/sprites/player_idle_p2.png")
			s.scale = Vector2(2.2, 2.2)
			s.position = Vector2(420.0 + 312.0 * float(i), 462.0)
			s.flip_h = i == 1
			add_child(s)
```

(Se borran `_process` y `_draw` de esa clase: ya no dibujan nada.)

### 3. Retirar las teclas de aspecto

En `_unhandled_key_input`, elimina los cuatro casos `KEY_Z`, `KEY_X`,
`KEY_N`, `KEY_M`. En `_update_rules`, sustituye la línea
`"Z/X: aspecto P1   ·   N/M: aspecto P2\n"` por
`"P1: NACHO   ·   P2: RODRIGO\n"` dentro de la cadena formateada (cuida que
los `%s` y el formato sigan cuadrando).

### 4. Contraste del texto

El fondo es una ilustración con zonas claras: comprueba que el título
(orangea con outline negro) y el `rules_label` (gris claro) se siguen
leyendo. Si una zona pisa el texto, sube `outline_size` del título de 14 a 18
y añade al `rules_label` un outline propio:

```gdscript
	rules_label.add_theme_color_override("font_outline_color", Color.BLACK)
	rules_label.add_theme_constant_override("outline_size", 8)
```

## Qué NO hacer

- No borres `MatchRules.hair`/`MatchRules.skin` de `match_rules.gd` (la
  tarea 60 lo hace junto con el resto de la customización).
- No toques las teclas de reglas (1/3/5, T, R) ni el arranque con
  ENTER/ESPACIO.
- No cambies el tamaño del viewport ni añadas nodos al `.tscn`: todo se
  construye por código como hasta ahora.

## Criterios de aceptación

1. El título muestra la ilustración `bg_title.png` a pantalla completa, sin
   deformar (misma ratio que el viewport).
2. Los dos personajes se ven con sus sprites (P1 azul mirando a la derecha,
   P2 rojo mirando a la izquierda), a escala ~2.2.
3. Z/X/N/M ya no hacen nada y el texto de reglas ya no las menciona.
4. ENTER/ESPACIO sigue arrancando la partida.
5. El smoke test termina en `SMOKE OK`.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
Y una pasada visual con render (abrir el proyecto normal) de la pantalla de
título.
