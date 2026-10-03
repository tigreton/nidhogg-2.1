# Tarea 79 — Música dinámica (crossfade base ↔ completa por emoción)

**Dificultad:** alta · **Archivos:** `scripts/music.gd`, `scripts/game.gd`, `tools/render_music.py` (ejecutarlo) · **Prerrequisitos:** 63 aplicada

## Objetivo

Dos mezclas del MISMO bucle —base (sin percusión) y completa— suenan
**sincronizadas siempre** y solo cambia el volumen: calma → base; emoción
(corredor a <600 px de su meta, o ventana de ronda) → crossfade a completa.
Nunca se paran: la sincronía es la gracia.

## Contexto del proyecto (leer antes de tocar nada)

- `music.gd` (tras la 63): `_load_music_file()` lee el PCM a mano y monta
  un `AudioStreamWAV` con `LOOP_FORWARD`; `_ready()` crea el
  `AudioStreamPlayer` "MusicPlayer" (la tecla M hace stop/play sobre él).
- El compositor es una herramienta: `python tools/render_music.py --base
  art/music/loop_base.wav` genera la mezcla sin percusión — misma semilla,
  misma longitud y mismo eco circular que `loop_main.wav` (quedan alineadas
  muestra a muestra).
- La "emoción" la calcula el juego (la 68 usa `crowd_excite`; esta tarea
  usa su propia señal mínima si la 68 no está: corredor cerca de meta).
- `game.gd` instancia `music = Music.new()`; la comunicación será
  `music.set_intensity(f)` desde `_physics_process`.
- Reglas de estilo: GDScript tipado, tabs, español.

## Instrucciones paso a paso

### 1. Render de la base

```
python tools/render_music.py --base art/music/loop_base.wav
```

(verifica: misma duración 72,7 s que loop_main.wav).

### 2. Dos jugadores sincronizados en `music.gd`

Sustituye `_ready()` por:

```gdscript
const MUSIC_BASE := "res://art/music/loop_base.wav"

var full: AudioStreamPlayer
var base: AudioStreamPlayer
var intensity := 0.0   # 0 = calma (base), 1 = combate (completa)


func _ready() -> void:
	var s_full := _load_music_file(MUSIC_PATH)
	var s_base := _load_music_file(MUSIC_BASE)
	full = AudioStreamPlayer.new()
	full.name = "MusicPlayer"   # la tecla M sigue encontrándolo
	full.volume_db = -16.0
	add_child(full)
	base = AudioStreamPlayer.new()
	base.name = "MusicBase"
	base.volume_db = -60.0     # arranca inaudible
	add_child(base)
	if s_full == null:
		full.stream = _build_loop()   # fallback procedural (una sola voz)
	elif s_base == null:
		full.stream = s_full
	else:
		full.stream = s_full
		base.stream = s_base
		base.play()
	full.play()


func set_intensity(f: float, delta: float) -> void:
	# crossfade suave; con fallback de una sola voz, no hace nada
	if base == null or base.stream == null:
		return
	intensity = move_toward(intensity, clampf(f, 0.0, 1.0), delta * 0.8)
	full.volume_db = lerpf(-26.0, -14.0, intensity)
	base.volume_db = lerpf(-16.0, -38.0, intensity)
```

(`_load_music_file` pasa a recibir la ruta como parámetro: cambia su firma
a `func _load_music_file(path: String) -> AudioStreamWAV:` y sus dos
referencias internas a `path`.)

### 3. La tecla M silencia las dos voces

En `game.gd`, el toggle de M (~línea 1675) opera sobre
`music.get_node_or_null("MusicPlayer")`: extiéndelo para que también pare
`MusicBase`:

```gdscript
		var mb := music.get_node_or_null("MusicBase") as AudioStreamPlayer
		if mb != null:
			if mb.playing:
				mb.stop()
			else:
				mb.play()
```

(con la misma rama if/else que ya usa para MusicPlayer, dentro del mismo
toggle.)

### 4. Emoción desde el juego

En `game.gd::_physics_process`, junto al descuento de `parry_cd`:

```gdscript
	# música dinámica: el corredor acercándose a su meta sube la mezcla
	if music != null:
		var em := 0.0
		if right_of_way != null and right_of_way.state != Player.State.DEAD:
			var gx := LEVEL_W - GOAL_W if right_of_way.goal_dir > 0 else GOAL_W
			em = clampf(1.0 - absf(right_of_way.position.x - gx) / 600.0, 0.0, 1.0)
		if round_lock > 0.0:
			em = 1.0
		music.set_intensity(em, delta)
```

## Qué NO hacer

- No pares nunca las voces para cambiar (perderías la sincronía para
  siempre): solo volumen.
- No mezcles pistas de distinta longitud: renderiza la base con la
  herramienta, no a mano.
- Si la 68 está aplicada, NO dupliques su crowd: esta señal es aparte
  (música), aunque compartan la métrica de cercanía.

## Criterios de aceptación

1. En calma suena la base (sin batería); el corredor acercándose a la meta
   funde a la mezcla completa en ~1 s; alejarse la baja.
2. M silencia/activa las dos voces a la vez.
3. Sin `loop_base.wav` presente, todo funciona como hoy (una voz, tecla M).
4. `SMOKE OK` y `SIM PASS`.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/sim_match.tscn
```

Últimas líneas esperadas: `SMOKE OK - todas las mecánicas funcionan` y
`SIM PASS`.

## Nota de aplicación (2026-10-03)

Aplicada tal cual: `loop_base.wav` renderizada con la herramienta (misma
semilla/longitud/eco → sincronía muestra a muestra), `music.gd` con dos
voces y `set_intensity`, y el juego alimenta la intensidad (corredor a
<600 px de meta, o ventana de ronda). Diagnóstico del crossfade: intensidad
1 → −14/−38 dB, intensidad 0 → −26/−16 dB, ambas voces presentes y la
tecla M para las dos. `SMOKE OK` y `SIM PASS`.
