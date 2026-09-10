# Tarea 17 — La espada desviada sobre el foso cae en el borde

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** ninguno

## Objetivo

Arreglar una pérdida permanente: hoy, si una espada lanzada es desviada (o te
matan) con la espada pasando por encima del foso central, `_drop_sword` la
descarta si su x cae dentro del foso y NADIE puede rearmarse hasta morir o
acabar la ronda. Tras el fix, la espada cae en el borde del foso más cercano y
siempre se puede recoger.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/game.gd`:
	- `_drop_sword(pos: Vector2, col: Color)` se llama cuando una espada
	  lanzada termina (golpea muro, matan a su dueño... o la desvía un rival).
	  Hoy hace:
	  ```gdscript
	  var x := clampf(pos.x, 30.0, LEVEL_W - 30.0)
	  if x > PIT_X0 and x < PIT_X1:
		  return   # <-- la espada se pierde para siempre
	  ```
	  y después crea un `SwordPickup` en `(x, _surface_y(x, pos.y) - 12)`.
	- Foso central: `PIT_X0=2210`, `PIT_X1=2380`. Suelo: `GROUND_Y=560`.
	- Caso típico: el rival espera en la PLATAFORMA del foso (y=448) en guardia
	  media y desvía la espada en x≈2300 → hoy desaparece.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Helper de expulsión del foso

Añade esta función a `scripts/game.gd` (junto a `_drop_sword`):

```gdscript
func _out_of_pit(x: float) -> float:
	if x > PIT_X0 - 34.0 and x < PIT_X1 + 34.0:
		return PIT_X0 - 40.0 if x < (PIT_X0 + PIT_X1) * 0.5 else PIT_X1 + 40.0
	return x
```

### 2. Usarlo en `_drop_sword`

Sustituye las dos líneas:

```gdscript
	var x := clampf(pos.x, 30.0, LEVEL_W - 30.0)
	if x > PIT_X0 and x < PIT_X1:
		return
```

por:

```gdscript
	var x := _out_of_pit(clampf(pos.x, 30.0, LEVEL_W - 30.0))
```

(El `return` desaparece: ya nunca se descarta la espada por caer en el foso.
El margen de 34 px hace que también se expulsen las caídas justo al filo.)

### 3. Si el proyecto tiene un segundo foso

Si en `game.gd` existen las constantes `PIT2_X0`/`PIT2_X1` (añadidas por la
tarea del segundo foso), extiende el helper así en lugar del paso 1:

```gdscript
func _out_of_pit(x: float) -> float:
	if x > PIT_X0 - 34.0 and x < PIT_X1 + 34.0:
		return PIT_X0 - 40.0 if x < (PIT_X0 + PIT_X1) * 0.5 else PIT_X1 + 40.0
	if x > PIT2_X0 - 34.0 and x < PIT2_X1 + 34.0:
		return PIT2_X0 - 40.0 if x < (PIT2_X0 + PIT2_X1) * 0.5 else PIT2_X1 + 40.0
	return x
```

## Qué NO hacer

- No cambies `_surface_y()` ni la posición vertical del pickup.
- No hagas reaparecer la espada en manos del dueño: cae al borde y hay que
  pasarse a por ella (así sigue habiendo riesgo al lanzar).
- No toques `_update_pickups()`.

## Criterios de aceptación

1. Colócate en la plataforma del foso en guardia media y desvía una espada
   lanzada: la espada cae ahora en un borde del foso (con su halo blanco
   pulsante) y se puede recoger.
2. Ya no existe ninguna x del nivel donde la espada desaparezca sin dejar pickup.
3. El smoke test sigue pasando.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`
(comprobación rápida extra desde el juego: lanzar la espada desde la plataforma
hacia un rival que la desvíe encima del foso).
