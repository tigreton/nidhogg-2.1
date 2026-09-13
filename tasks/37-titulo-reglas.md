# Tarea 37 — Pantalla de título + reglas configurables

**Dificultad:** media · **Archivos:** nuevo `scripts/match_rules.gd`, nuevo `scripts/title.gd`, nueva `scenes/title.tscn`, `project.godot`, `scripts/game.gd`, `scripts/player.gd` · **Prerrequisitos:** ninguno

## Objetivo

Al arrancar se ve una **pantalla de título** (como el original): título,
controles y reglas del partido configurables: **puntos para ganar (1/3/5)**,
**desactivar lanzar el arma (T)** y **desactivar rodar (R)**. ENTER o ESPACIO
empieza el duelo. El juego lee esas reglas en vez de las constantes fijas.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript), arte y sonido procedurales, indentación con
  **tabs**, comentarios en español.
- `project.godot` tiene `run/main_scene="res://scenes/main.tscn"` (línea 14).
- `scripts/game.gd`:
	- `const WIN_SCORE := 3` y en `func _point(p: Player) -> void:` la línea
	  `if scores[_team(p)] >= WIN_SCORE:` decide el fin del partido.
	- Los colores de equipo son `P1_COLOR` (naranja `ffb324`) y
	  `P2_COLOR` (cian `39d7ff`).
- `scripts/player.gd`:
	- El lanzamiento está en el bloque de ataque:
	  `elif hit("throw") and has_sword:`.
	- La rodada se dispara con `if hit("jump") and held("down") and is_on_floor()
	  and roll_cd <= 0.0:` (comentario `# rodar: esquiva rápida agachado`).
	  Si ya aplicaste la tarea 34, esa línea será
	  `elif hit("jump") and held("down") and is_on_floor() and roll_cd <= 0.0:`
	  precedida del dive: la condición a tocar es la MISMA (la de la rodada).
	- `class_name Player` ya existe: los `class_name` son globales al proyecto.
- El smoke test (`test/smoke_test.gd`) carga `res://scenes/main.tscn`
  DIRECTAMENTE, así que no pasa por el título: no hay que tocarlo (solo
  comprobar que sigue en verde: por defecto win_score = 3 y todo permitido).
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Nuevo archivo `scripts/match_rules.gd`

```gdscript
class_name MatchRules
## Reglas del partido configurables desde la pantalla de título.

static var win_score := 3
static var allow_throw := true
static var allow_roll := true
```

### 2. Nuevo archivo `scripts/title.gd`

```gdscript
extends Control
## Pantalla de título: reglas del partido y arranque.

var rules_label: Label

const SKY := Color(0.055, 0.05, 0.09)


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = SKY
	bg.size = Vector2(1152, 648)
	add_child(bg)
	var title := Label.new()
	title.text = "NIDHOGG 2.1"
	title.position = Vector2(0, 90)
	title.size = Vector2(1152, 120)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", Color("ffb324"))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 14)
	add_child(title)
	rules_label = Label.new()
	rules_label.position = Vector2(0, 260)
	rules_label.size = Vector2(1152, 150)
	rules_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rules_label.add_theme_font_size_override("font_size", 26)
	rules_label.add_theme_color_override("font_color", Color(0.85, 0.83, 0.9))
	add_child(rules_label)
	var hint := Label.new()
	hint.text = "P1: A/D mover · W/S alturas · F atacar · G lanzar      P2: ←/→ · ↑/↓ · K atacar · L lanzar\nB: bot · V: 2v2 · P: pantallas · Y: arcade"
	hint.position = Vector2(0, 560)
	hint.size = Vector2(1152, 60)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.6, 0.58, 0.7))
	add_child(hint)
	_update_rules()


func _update_rules() -> void:
	rules_label.text = "PUNTOS PARA GANAR: %d    (teclas 1 / 3 / 5)\nLANZAR ARMA: %s (T)      RODAR: %s (R)\n\nENTER o ESPACIO: jugar" % [
		MatchRules.win_score,
		"SÍ" if MatchRules.allow_throw else "NO",
		"SÍ" if MatchRules.allow_roll else "NO",
	]


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	match k.keycode:
		KEY_1:
			MatchRules.win_score = 1
		KEY_3:
			MatchRules.win_score = 3
		KEY_5:
			MatchRules.win_score = 5
		KEY_T:
			MatchRules.allow_throw = not MatchRules.allow_throw
		KEY_R:
			MatchRules.allow_roll = not MatchRules.allow_roll
		KEY_ENTER, KEY_SPACE:
			get_tree().change_scene_to_file("res://scenes/main.tscn")
		_:
			return
	_update_rules()
```

### 3. Nueva escena `scenes/title.tscn`

Créala con este contenido exacto:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/title.gd" id="1_title"]

[node name="Title" type="Control"]
script = ExtResource("1_title")
```

### 4. `project.godot`: arrancar en el título

Sustituye la línea `run/main_scene="res://scenes/main.tscn"` por:

```
run/main_scene="res://scenes/title.tscn"
```

### 5. `game.gd` y `player.gd`: leer las reglas

5.1. En `_point(p)`, sustituye `if scores[_team(p)] >= WIN_SCORE:` por:

```gdscript
	if scores[_team(p)] >= MatchRules.win_score:
```

5.2. En `player.gd`, sustituye `elif hit("throw") and has_sword:` por:

```gdscript
		elif hit("throw") and has_sword and MatchRules.allow_throw:
```

5.3. En `player.gd`, en la condición de la rodada (la que tiene el comentario
`# rodar: esquiva rápida agachado`, sea `if` o `elif`), añade al final,
antes de los dos puntos:

```gdscript
 and MatchRules.allow_roll
```

(es decir, la condición queda `... and roll_cd <= 0.0 and MatchRules.allow_roll:`)

## Qué NO hacer

- No toques `test/smoke_test.gd`: carga `main.tscn` directamente y las reglas
  por defecto (3 puntos, todo permitido) mantienen todos sus resultados.
- No muevas lógica de combate al título: solo define `MatchRules` y lee.
- No uses autoloads ni `config_file`: las reglas viven en variables estáticas.
- No cambies la escena `main.tscn`.

## Criterios de aceptación

1. Al arrancar (F5) se ve el título con controles y reglas; el juego no
   empieza hasta dar ENTER o ESPACIO.
2. 1/3/5 cambia los puntos para ganar; T activa/desactiva lanzar; R
   activa/desactiva rodar (el texto se actualiza al momento).
3. Con lanzar desactivado, G/L no lanzan el arma; con rodar desactivado,
   abajo+salto no rueda (salta normal).
4. Un partido a 1 punto termina con el primer punto ganado.
5. El smoke test sigue pasando sin cambios.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
