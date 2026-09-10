# Tarea 11 — Música procedural en bucle

**Dificultad:** media · **Archivos:** nuevo `scripts/music.gd`, `scripts/game.gd` · **Prerrequisitos:** ninguno

## Objetivo

Una pista musical oscura de 32 pasos (chiptune: bajo cuadrado + melodía escasa)
generada por código al arrancar y en bucle, con volumen bajo. Tecla **M** para
activar/desactivar. Sin assets externos, como todo el proyecto.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural; los sonidos se generan en `scripts/sfx.gd` escribiendo samples en
  un `AudioStreamWAV` (`FORMAT_16_BITS`, `mix_rate=22050`, mono). Esta tarea
  sigue el mismo patrón.
- `scripts/game.gd` — nodo principal: `_ready()` construye todo;
  `_setup_input()` registra acciones de teclado en runtime;
  `_physics_process()` lee `Input.is_action_just_pressed(...)`.
- En headless el audio usa un driver mudo: la música se puede añadir sin romper
  el test.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Crear `scripts/music.gd` (archivo nuevo)

Crea `scripts/music.gd` con EXACTAMENTE este contenido:

```gdscript
class_name Music
extends Node
## Música procedural: un bucle de 32 semicorcheas generado por código (sin assets).

const BPM := 132.0
const STEPS := 32
const MIX := 22050


static func _note(freq: float, dur: float, vol: float, duty := 0.5) -> PackedFloat32Array:
	var n := int(dur * MIX)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		phase += TAU * freq / MIX
		var s := 1.0 if fmod(phase, TAU) < TAU * duty else -1.0
		var env := 1.0 - float(i) / float(n)
		out[i] = s * vol * env * env
	return out


func _build_loop() -> AudioStreamWAV:
	var step := 60.0 / BPM / 4.0
	var bass: Array = [
		55.0, 0.0, 55.0, 0.0, 65.41, 0.0, 55.0, 0.0,
		82.41, 0.0, 55.0, 0.0, 73.42, 0.0, 65.41, 0.0,
		55.0, 0.0, 55.0, 0.0, 65.41, 0.0, 55.0, 0.0,
		98.0, 0.0, 82.41, 0.0, 73.42, 0.0, 65.41, 0.0,
	]
	var lead: Array = [
		220.0, 0.0, 261.63, 329.63, 0.0, 293.66, 0.0, 0.0,
		220.0, 0.0, 196.0, 0.0, 246.94, 0.0, 261.63, 0.0,
		220.0, 0.0, 261.63, 329.63, 0.0, 392.0, 0.0, 329.63,
		293.66, 0.0, 246.94, 0.0, 220.0, 0.0, 0.0, 0.0,
	]
	var total := int(STEPS * step * MIX)
	var buf := PackedFloat32Array()
	buf.resize(total)
	for s in STEPS:
		var off := int(s * step * MIX)
		if bass[s] > 0.0:
			var nb := Music._note(bass[s], step * 0.95, 0.20, 0.5)
			for i in nb.size():
				buf[off + i] += nb[i]
		if lead[s] > 0.0:
			var nl := Music._note(lead[s], step * 1.8, 0.10, 0.25)
			for i in nl.size():
				if off + i < total:
					buf[off + i] += nl[i]
	var b := PackedByteArray()
	b.resize(total * 2)
	for i in total:
		var v := int(clampf(buf[i] * 0.8, -1.0, 1.0) * 32000.0)
		b[i * 2] = v & 0xFF
		b[i * 2 + 1] = (v >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = total
	wav.data = b
	return wav


func _ready() -> void:
	var p := AudioStreamPlayer.new()
	p.stream = _build_loop()
	p.volume_db = -16.0
	p.name = "MusicPlayer"
	add_child(p)
	p.play()
```

### 2. `scripts/game.gd` — instanciar y tecla M

2.1. En `_setup_input()`, añade al diccionario `defs`:

```gdscript
	"toggle_music": [KEY_M],
```

2.2. Añade variable de instancia junto a `var msg_tween: Tween`:

```gdscript
var music: Music
```

2.3. Al final de `_ready()`, añade:

```gdscript
	music = Music.new()
	add_child(music)
```

2.4. En `_physics_process`, después del bloque de `"toggle_bot"` o del de
`match_over` (da igual, antes de la lógica de jugadores), añade:

```gdscript
	if Input.is_action_just_pressed("toggle_music"):
		var mp := music.get_node_or_null("MusicPlayer") as AudioStreamPlayer
		if mp != null:
			if mp.playing:
				mp.stop()
			else:
				mp.play()
```

### 3. Pista visual

En `_build_hud()`, en el texto del `hint`, añade al final `    M: música`.

## Qué NO hacer

- No uses archivos de audio ni importes nada: la música se genera en memoria.
- No pases de ~8 s de bucle (32 pasos a 132 BPM ≈ 3,6 s: perfecto).
- No subas el volumen por encima de -12 dB: los efectos sonoros deben oírse encima.

## Criterios de aceptación

1. Al arrancar suena un bucle musical tenue (bajo + melodía) que no se corta.
2. M lo silencia y lo reactiva.
3. El smoke test sigue pasando en headless sin errores de audio.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`
(el sonido se comprueba con F5).
