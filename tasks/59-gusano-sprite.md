# Tarea 59 — Gusano de victoria con worm_body

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** que exista `worm_body.png` (ya importado)

## Objetivo

El gusano del Nidhogg que baja a devorar al ganador (`VictoryWorm`) deja de
dibujar el cuerpo con círculos verdes y pasa a usar la textura
`worm_body.png` (300×103, tira horizontal con el cuerpo segmentado). Las
mandíbulas que se cierran y los ojos amarillos siguen procedurales: la
textura no trae cabeza articulada.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript), monolito `scripts/game.gd`.
- Clase `VictoryWorm` (~líneas 609-639): `Node2D` que baja del techo en 1,2 s
  (`t` de 0 a 1 interpolando `position.y`) y redibuja cada frame. Su
  `_draw()` pinta 6 círculos decrecientes en `Vector2(0, -i*44 - 30)` (radio
  34→19), la cabeza (radio 36 en `(0, -30)`), las dos mandíbulas
  triangulares cuyo ángulo `open_ang` depende de `chomp` y los dos ojos.
- Se instancia en `_spawn_worm(p)` (~línea 2231) al cerrar un partido
  (victoria por puntos, no en arcade/copa).
- La textura `worm_body.png` mide **300×103**: son 3 segmentos de ~100 px de
  ancho en horizontal. Se dibuja por regiones con
  `draw_texture_rect_region(tex, dest_rect, src_rect)`.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en
  español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Textura y regiones

Dentro de la clase `VictoryWorm` (o justo encima, como constante del
script), añade:

```gdscript
const WORM_TEX := preload("res://art/sprites/worm_body.png")
# la tira de 300x103 se corta en 3 segmentos de 100 px
const WORM_SEGS := [
	Rect2(0.0, 0.0, 100.0, 103.0),
	Rect2(100.0, 0.0, 100.0, 103.0),
	Rect2(200.0, 0.0, 100.0, 103.0),
]
```

### 2. Cuerpo con textura

Sustituye en `_draw()` el bucle de los 6 círculos y el círculo de la cabeza
por regiones de la textura, **manteniendo los mismos anclajes** (segmentos
centrados en `(0, -i*44 - 30)`, cabeza más ancha en `(0, -30)`):

```gdscript
	func _draw() -> void:
		var chomp := 0.35 + 0.65 * t
		# cuerpo: 6 segmentos con la textura (las 3 regiones, repetidas)
		for i in 6:
			var cy := -float(i) * 44.0 - 30.0
			draw_texture_rect_region(WORM_TEX, Rect2(-32.0, cy - 33.0, 64.0, 66.0), WORM_SEGS[i % 3])
		# cabeza: el segmento 0 un punto más grande
		draw_texture_rect_region(WORM_TEX, Rect2(-37.0, -66.0, 74.0, 76.0), WORM_SEGS[0])
		# mandíbulas y ojos (procedurales, como antes)
		var open_ang := 1.2 * (1.0 - chomp)
		for s in [-1.0, 1.0]:
			var pts := PackedVector2Array([
				Vector2(0, -20),
				Vector2(s * 44.0 * cos(open_ang), -20.0 + 44.0 * sin(open_ang)),
				Vector2(s * 10.0, 26.0),
			])
			draw_colored_polygon(pts, Color(0.16, 0.38, 0.16))
		draw_circle(Vector2(-12, -34), 4.0, Color.YELLOW)
		draw_circle(Vector2(12, -34), 4.0, Color.YELLOW)
```

### 3. Verificar el corte real de la tira

Abre `art/sprites/worm_body.png` (o la hoja de contactos
`art_raw/contact_sheet.png`) y comprueba que los 3 cortes de 100 px caen
donde toca (segmentos enteros, sin medias escamas). Si la tira tiene otra
disposición (por ejemplo una sola pieza continua), cambia `WORM_SEGS` a una
sola región `Rect2(0, 0, 300, 103)` usada para todos los segmentos y para la
cabeza: quedará estirada pero continua.

## Qué NO hacer

- No toques la animación de bajada (`_process`, `t`, `position.y`): ni el
  timing ni el comportamiento de `_spawn_worm`.
- No borres las mandíbulas ni los ojos: el "mordisco" al final es lectura de
  victoria.
- No cambies `z_index` (30) ni `process_mode` (PAUSABLE) del worm.

## Criterios de aceptación

1. Al ganar un partido (tecla 1 para partida a 1 punto + kill), el gusano
   baja con cuerpo texturizado verde segmentado y las mandíbulas se cierran
   al llegar abajo.
2. La cabeza se distingue del cuerpo (segmento más ancho).
3. El smoke test termina en `SMOKE OK`.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
Y una partida corta con render para ver al gusano en acción.
