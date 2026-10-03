# Tarea 64 — Fuente pixel para título y HUD

**Dificultad:** baja (código) / bloqueada por asset (fuente) · **Archivos:** `scripts/title.gd`, `scripts/game.gd`, nuevo `art/fonts/` · **Prerrequisitos:** un TTF/OTF con licencia abierta

> **EN ESPERA (2026-10-03):** `bl` no genera fuentes. La fuente puede ser
> generada (tanda futura) o elegida de una libre (Pixel Operator, m5x7,
> Press Start 2P con acentos): decisión del usuario al traer el asset.

## Objetivo

Los textos (título, marcador, mensajes, ¡FIGHT!, stats) dejan de usar la
fuente default de Godot y pasan a una fuente pixel coherente con el arte de
sprites — SOLO si existe el fichero; sin él, todo queda como está.

## Especificación del asset

- Ruta: `res://art/fonts/pixel.ttf` (o `.otf`).
- Estilo pixel/bitmap, legible a 14–22 px (el hint usa 14 y el título 96:
  la fuente debe escalar dignamente).
- Cobertura: latín básico **con acentos españoles y signos** (á é í ó ú ñ ü
  ¡ ¿ · —), mayúsculas y minúsculas, dígitos.
- Licencia abierta (OFL o equivalente) y anotada en el commit.

## Instrucciones paso a paso (código, cuando exista la fuente)

### 1. Helper en `title.gd` y `game.gd`

```gdscript
const FONT_PATH := "res://art/fonts/pixel.ttf"

func _apply_font(roots: Array) -> void:
	if not ResourceLoader.exists(FONT_PATH):
		return
	var f: FontFile = load(FONT_PATH)
	for root in roots:
		for n in _all_labels(root):
			n.add_theme_font_override("font", f)
```

(con un `_all_labels(node)` recursivo que recoja los `Label` hijos; las
llamadas van al final de `_ready()` en `title.gd` y de `_build_hud()` en
`game.gd`, pasando la raíz de cada pantalla).

### 2. Contraste

La fuente pixel suele ser más fina que la default: revisar que el outline
negro de título y marcador sigue recortando sobre los fondos nuevos
(sube `outline_size` +4 si se pierde).

### 3. Import

Abrir el editor una vez para el `.import` del TTF y commitearlo con el
archivo (como `art/sprites`).

## Qué NO hacer

- No hardcodees la fuente sin `ResourceLoader.exists`: sin el fichero el
  juego debe arrancar idéntico a hoy.
- No cambies tamaños ni posiciones de labels: solo la fuente.
- No toques la fuente del test runner (logs headless).

## Criterios de aceptación

1. Con la fuente presente, título y HUD la usan en todas sus etiquetas;
   sin ella, cero cambios visibles.
2. Acentos y ¡¿ bien renderizados en el título y los mensajes.
3. `SMOKE OK` y capturas del recorrido revisadas (01, 13).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --path . res://test/screenshots.tscn
```

Últimas líneas esperadas: `SMOKE OK - todas las mecánicas funcionan` y
`CAPTURAS OK`.
