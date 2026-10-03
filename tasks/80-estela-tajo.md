# Tarea 80 — Estela del tajo cuerpo a cuerpo

**Dificultad:** baja · **Archivos:** `scripts/player.gd` · **Prerrequisitos:** 60 aplicada (renderer de poses)

## Objetivo

El ataque cuerpo a cuerpo con arma deja una **estela de tajo** (3–4 segmentos
desvaneciéndose a lo largo del arco) en vez del solo destello circular. Con
las poses sprite (la espada va horneada), la estela es la capa de "energía"
que vende el golpe, como el original.

## Contexto del proyecto (leer antes de tocar nada)

- `player.gd::_draw()` dibuja la pose y luego efectos; el ataque activo ya
  expone `attack_ext()` (seno 0→1→0 entre `attack_from()` y `attack_to()`)
  y `attack_height` (H.LOW/MID/HIGH).
- El flash actual (si sigue presente tras la 60) es el círculo blanco
  `if ext > 0.15: draw_circle(mid, ...)` — se SUSTITUYE por la estela.
- El dibujo corre en espacio local (mirando a la derecha; el volteo lo hace
  `scale.x = facing` del nodo) — dibuja la estela hacia +X.
- `draw_line(from, to, color, width)` y `Color(r,g,b,a)` bastan; nada de
  nodos nuevos (es un efecto efímero del `_draw`).
- La mano según altura (guía de arcos, en px locales):
  HIGH: nace en (6,−34) y barre hasta (64,−52); MID: (6,−8)→(86,−8);
  LOW: (6,6)→(60,16).
- Reglas de estilo: GDScript tipado, tabs, español.

## Instrucciones paso a paso

### 1. La estela

En `player.gd::_draw()`, localiza el flash del ataque (o el hueco tras
dibujar la pose si la 60 lo retiró) y añade/sustituye:

```gdscript
	# estela del tajo: arco desvaneciéndose mientras dura el golpe activo
	if state == State.ATTACK and has_sword and weapon_id != "arco":
		var ext := attack_ext()
		if ext > 0.05:
			var a0: Vector2
			var a1: Vector2
			match (attack_height if state == State.ATTACK else stance):
				H.HIGH:
					a0 = Vector2(6.0, -34.0)
					a1 = Vector2(64.0, -52.0)
				H.LOW:
					a0 = Vector2(6.0, 6.0)
					a1 = Vector2(60.0, 16.0)
				_:
					a0 = Vector2(6.0, -8.0)
					a1 = Vector2(86.0, -8.0)
			for k in 4:
				var t0 := lerp(0.15, 1.0, float(k) / 4.0) * ext
				var t1 := lerp(0.15, 1.0, float(k + 1) / 4.0) * ext
				var col := Color(1.0, 0.95, 0.8, 0.34 * ext * (1.0 - float(k) / 4.0))
				draw_line(a0.lerp(a1, t0), a0.lerp(a1, t1), col, 7.0 - float(k) * 1.5)
```

Y borra el destello circular viejo (`draw_circle(mid, 13.0 * ext, ...)`)
si todavía existe, para no duplicar efectos.

## Qué NO hacer

- No dibujes estela en el aire del salto con arco ni desarmado (el
  `weapon_id != "arco" and has_sword` la filtra).
- No la hagas persistente: vive del `attack_ext()` (se desvanece sola).
- No añadas nodos ni partículas: es dibujo directo en `_draw`.

## Criterios de aceptación

1. Cada estocada con arma pinta un barrido claro que crece y muere con el
   golpe, con el arco correcto por altura (alta sube, media recta, baja
   ras).
2. Desarmado y arco: sin estela (el puñetazo es otro lenguaje).
3. `SMOKE OK` (visual puro) y una captura a mano con render (correr y
   atacar) para revisión.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --path . res://test/screenshots.tscn
```

Últimas líneas esperadas: `SMOKE OK - todas las mecánicas funcionan` y
`CAPTURAS OK`.
