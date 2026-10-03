# Tarea 83 — El movimiento suena: pasos, aterrizaje y whoosh por arma

**Dificultad:** baja/media · **Archivos:** `scripts/sfx.gd`, `scripts/game.gd`, `scripts/player.gd` · **Prerrequisitos:** 53 aplicada (WAVs)

## Objetivo

Divergencia de feel nº 4: en el original OYES al rival acercarse (pasos) y
cada arma corta el aire distinto. Aquí correr es mudo y todos los ataques
comparten un único `attack_swipe`. Tres sonidos sintetizados con el patrón
de `sfx.gd` + pitch por arma en el whoosh: el radar auditivo de la
aproximación y el peso del arma.

## Contexto del proyecto (leer antes de tocar nada)

- `sfx.gd`: catálogo por id con síntesis `_noise/_sweep/_arp` → WAV en
  memoria, y la tabla `WAVS` de la 53 (ids con WAV real: `swing` usa
  `attack_swipe.wav`). El resto se sintetiza.
- `Sfx.play(parent, pos, id, db)` crea un `AudioStreamPlayer2D`:
  `pitch_scale` es del player, no del stream — un pitch por llamada no
  requiere duplicar assets.
- `game.gd::sfx(pos, id, db)` es el wrapper del juego; `player.gd::_sfx(id,
  db)` el del jugador.
- El paso del corredor: `run_phase` crece con `velocity.x * delta * 0.045`
  (rad); un ciclo de zancada es PI (dos pasos). El aterrizaje ya se detecta
  (`is_on_floor() and not was_on_floor`) y tiene polvo.
- Los ataques llaman `_sfx("swing", -20.0)` (y variantes de dB) en
  `player.gd`; el arco tensa con `"swing", -26.0`.
- Reglas de estilo: GDScript tipado, tabs, español.

## Instrucciones paso a paso

### 1. Tres sonidos nuevos en `sfx.gd`

En el `match id` de `stream()`, añade:

```gdscript
		"step":
			data = _noise(0.03, 90.0, 0.10)
		"land":
			data = _sweep(0.09, 130.0, 55.0, 0.30)
```

### 2. Pitch opcional en la cadena

`Sfx.play` y el wrapper `game.gd::sfx` ganan un parámetro:

```gdscript
static func play(parent: Node, pos: Vector2, id: String, db := -10.0, pitch := 1.0) -> void:
	var p := AudioStreamPlayer2D.new()
	p.stream = stream(id)
	p.volume_db = db
	p.pitch_scale = pitch
	...
```

(y en `game.gd`: `func sfx(pos: Vector2, id: String, db := -10.0, pitch := 1.0)
-> void:` pasándolo a `Sfx.play(self, pos, id, db, pitch)`).

### 3. Whoosh por arma en `player.gd`

Helper junto a `_sfx`:

```gdscript
func _swing_sfx(db := -20.0) -> void:
	# el whoosh del arma: el espadón corta grave, la daga agudo
	var pitch := 1.0
	if weapon_id == "espada":
		pitch = 0.78
	elif weapon_id == "daga":
		pitch = 1.3
	var g := get_parent()
	if g != null and g.has_method("sfx"):
		g.sfx(position, "swing", db, pitch)
```

Y sustituye las llamadas de ataque `_sfx("swing", ...)` por `_swing_sfx(...)`
(la del ataque en suelo, la estocada, el tajo aéreo, el divekick, el dive,
la rodada y el sidekick; la del tensado del arco se queda como está).

### 4. Pasos y aterrizaje en `player.gd`

Variable junto a `var run_phase := 0.0`:

```gdscript
var step_phase := 0.0   # acumula PI por zancada para el pie
```

En `_physics_process`, tras actualizar `run_phase` (rama IDLE/RUN del
segundo `match`):

```gdscript
			step_phase += absf(velocity.x) * delta * 0.045
			if step_phase >= PI:
				step_phase -= PI
				if is_on_floor() and absf(velocity.x) > 60.0:
					_sfx("step", -26.0)
```

Y en la detección de aterrizaje, junto al `_dust`:

```gdscript
		_sfx("land", -18.0)
```

## Qué NO hacer

- No pongas pasos en el aire ni a velocidad de agachado (<60 px/s: andar
  quedo no suena).
- No metas el paso en el bot aparte: el bot corre con el mismo código.
- No dupliques el whoosh con nuevo WAV: el pitch del player basta.
- Volúmenes: paso a −26, aterrizaje a −18; son atmósfera, no protagonistas.

## Criterios de aceptación

1. Correr suena al ritmo de las zancadas (más rápido = más pasos/s); pararse
   silencia. Un rival acercándose fuera de plano se OYE.
2. Aterrizar de un salto da un golpe seco.
3. El espadón suena grave al agitarse, la daga agudo, florete neutro —
   incluso a ciegas sabes qué arma te busca.
4. `SMOKE OK` (audio fuera del smoke).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
