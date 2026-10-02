# Tarea 58 — Fondos parallax bg_layer0/1 con tinte por arena

**Dificultad:** media · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** que existan `bg_layer0/bg_layer1.png` (ya importados)

## Objetivo

Añadir al juego la infraestructura de fondo parallax (hoy no existe nada
parecido) usando las dos capas de 960×540: la lejana (`bg_layer0`) se mueve
poco y la media (`bg_layer1`) algo más. Las dos se tiñen con la paleta de la
arena activa para que las tres arenas (noche azulada, amanecer, ocaso)
sigan teniendo identidad propia con un único juego de fondos. El cielo plano
`col_sky` desaparece (las capas lo cubren); la luna/sol, las colinas y las
nubes procedurales se conservan por delante.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript), renderer `gl_compatibility` (el
  `ParallaxBackground` funciona en él; es un `CanvasLayer`, no 3D).
- El viewport es **1152×648** y las texturas 960×540: hay que escalarlas
  ×1.2 para cubrir la pantalla; con `motion_mirroring` igual al ancho
  escalado (1152) la capa se repite a lo largo del nivel.
- `_build_level()` (~línea 277) empieza pintando el cielo:
  `_poly(... Vector2(LEVEL_W, 720) ..., col_sky, -10)`. **Esa línea se
  elimina**: taparía el parallax (el `CanvasLayer` del parallax va detrás
  del canvas por defecto, y el polígono del cielo está en el canvas por
  defecto).
- La cámara (`_build_camera`, ~línea 1230) sigue al jugador; el nivel mide
  `LEVEL_W` de ancho. `set_arena()` (~línea 469) libera `level_root` y
  reconstruye: el parallax se cuelga de `self`, así que hay que liberarlo
  allí también.
- `_load_arena()` asigna la paleta de cada arena antes de construir. Las
  variables de tinte nuevas se asignan ahí, en las mismas ramas.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en
  español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Variables de instancia y tintes por arena

Junto a las demás variables de escenario (cerca de `var level_root`), añade:

```gdscript
var parallax_bg: ParallaxBackground
var bg_tint_far := Color(0.7, 0.72, 0.9)
var bg_tint_near := Color(0.85, 0.85, 0.95)
```

En `_load_arena()`, dentro de cada rama, añade los tintes (además de los
`col_*` que ya asigna):

```gdscript
		1:
			... # Templo del alba: amanecer cálido
			bg_tint_far = Color(1.0, 0.72, 0.5)
			bg_tint_near = Color(1.0, 0.85, 0.68)
		2:
			... # Cripta del ocaso: atardecer púrpura
			bg_tint_far = Color(0.68, 0.5, 0.9)
			bg_tint_near = Color(0.85, 0.68, 0.95)
		_:
			... # Ruinas de medianoche: noche azulada
			bg_tint_far = Color(0.55, 0.62, 0.85)
			bg_tint_near = Color(0.72, 0.74, 0.92)
```

### 2. Constructor del parallax

Añade la función junto a `_build_level`:

```gdscript
func _parallax_layer(pb: ParallaxBackground, path: String, motion: float, tint: Color) -> ParallaxLayer:
	# capa de fondo repetida: textura 960x540 escalada a viewport y espejada
	var l := ParallaxLayer.new()
	l.motion_scale = Vector2(motion, motion)
	var s := Sprite2D.new()
	s.texture = load(path)
	s.centered = false
	s.scale = Vector2(1152.0 / 960.0, 648.0 / 540.0)
	s.modulate = tint
	l.motion_mirroring = Vector2(1152.0, 0.0)
	l.add_child(s)
	pb.add_child(l)
	return l


func _build_parallax() -> void:
	parallax_bg = ParallaxBackground.new()
	parallax_bg.layer = -20
	add_child(parallax_bg)
	_parallax_layer(parallax_bg, "res://art/sprites/bg_layer0.png", 0.15, bg_tint_far)
	_parallax_layer(parallax_bg, "res://art/sprites/bg_layer1.png", 0.4, bg_tint_near)
```

### 3. Engancharlo y quitar el cielo plano

En `_build_level()`:

- Elimina la primera línea (el `_poly` del cielo con `col_sky`).
- Añade la llamada al principio: `_build_parallax()`.

En `set_arena()`, donde se libera `level_root` antes de reconstruir, añade
encima:

```gdscript
	if parallax_bg != null:
		parallax_bg.queue_free()
		parallax_bg = null
```

### 4. Comprobación de costuras

Las texturas no son tileables por diseño: con `motion_mirroring = 1152` puede
verse una costura vertical cada pantalla. Si en la pasada visual se nota,
prueba `l.motion_mirroring = Vector2(2304.0, 0.0)` y desplaza el sprite hijo
`s.position.x = -576.0` para que la repetición caiga fuera de las zonas por
donde pasa la cámara. Anota lo que quede: la tarea 62 hace el ajuste fino.

## Qué NO hacer

- No borres `_hills()`, `_clouds()` ni el astro (luna/sol): siguen siendo la
  capa cercana procedural; solo desaparece el cielo plano.
- No toques la cámara ni su zoom (modo 2v2/secciones): el parallax convive
  con ambos sin cambios.
- No asignes el tinte después de construir: `_load_arena` corre antes que
  `_build_level`, así que los tintes ya están al crear las capas.
- No pongas el parallax dentro de `level_root` (se liberaría solo al cambiar
  de arena, pero perderíamos el control del orden de liberación; y `_poly`
  del cielo demostró que el canvas por defecto tapa el `-20`).

## Criterios de aceptación

1. Al moverse por el nivel, las dos capas de fondo se desplazan a distinta
   velocidad (parallax real) y cubren toda la pantalla sin huecos.
2. Cambiar de arena con C re-tiñe los fondos (azulado / cálido / púrpura)
   sin fugas de nodos.
3. La luna/sol, colinas y nubes se siguen viendo por delante de las capas.
4. El smoke test termina en `SMOKE OK`.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
Y una pasada con render corriendo de lado a lado del nivel en las 3 arenas.
