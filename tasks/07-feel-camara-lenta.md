# Tarea 07 — Cámara lenta al matar y al anotar

**Dificultad:** baja · **Archivos:** `scripts/game.gd`, `test/smoke_test.gd` · **Prerrequisitos:** ninguno

## Objetivo

Cámara lenta dramática (el sello de Nidhogg): al matar, el juego va a 35 % de
velocidad durante medio segundo real; al anotar un punto, a 25 % durante 0,9 s.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/game.gd`:
	- `_kill(def, atk)` es donde ocurren todas las muertes.
	- `_point(p)` es donde se anota (marca el score, muestra mensaje y gestiona
	  `round_lock = 1.4`, el bloqueo de 1,4 s antes de reiniciar la ronda).
	- `round_lock` se descuenta con `delta` en `_physics_process` (a velocidad
	  reducida tarda MÁS tiempo real).
- Godot: `Engine.time_scale` escala el `delta` de todo el juego.
  `get_tree().create_timer(dur, true, false, true)` —cuarto parámetro
  `ignore_time_scale=true`— cuenta tiempo REAL aunque el juego vaya lento.
  Perfecto para restaurar la velocidad.
- `test/smoke_test.gd` (test 6) espera 1,5 s reales a que la ronda se reinicie.
  Con la cámara lenta del punto (0,9 s reales a 0,25×) el reinicio tarda
  ~2,1 s reales, por lo que esa espera hay que ampliarla (paso 3).
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Función de cámara lenta

En `scripts/game.gd`, añade (junto a `show_msg()` está bien):

```gdscript
func _slowmo(scale: float, real_dur: float) -> void:
	Engine.time_scale = scale
	get_tree().create_timer(real_dur, true, false, true).timeout.connect(func():
		Engine.time_scale = 1.0)
```

### 2. Dispararla

2.1. En `_kill()`, después de la línea `_burst(def.position, def.color, 34, 440.0)`, añade:

```gdscript
	_slowmo(0.35, 0.5)
```

2.2. En `_point()`, después de la línea `_burst(p.position + Vector2(0, -30), p.color, 42, 480.0)`, añade:

```gdscript
	_slowmo(0.25, 0.9)
```

### 3. Dar margen al smoke test

En `test/smoke_test.gd`, busca el test 6:

```gdscript
	# 6. La ronda se reinicia sola
	await get_tree().create_timer(1.5).timeout
```

y cambia `1.5` por `2.4`. (Sin cámara lenta sobra; con ella, es necesario.)

## Qué NO hacer

- No dejes `Engine.time_scale` por debajo de 1 al salir del juego: SIEMPRE se
  restaura con el temporizador de tiempo real (ya lo hace la función).
- No apliques cámara lenta a choques ni patadas.
- No modifiques otros tiempos del test.

## Criterios de aceptación

1. Cada muerte ralentiza medio segundo y luego la velocidad vuelve a la normalidad.
2. Cada punto ralentiza casi un segundo (se ve la celebración a cámara lenta).
3. El juego jamás se queda "pegado" en cámara lenta permanente.
4. El smoke test pasa con el margen ampliado.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
