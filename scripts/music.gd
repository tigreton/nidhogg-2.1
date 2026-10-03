class_name Music
extends Node
## Música: bucle real de res://art/music si existe; si no, el chiptune
## procedural de siempre (fallback automático, sin tocar nada más).

const BPM := 132.0
const STEPS := 32
const MIX := 22050
const MUSIC_PATH := "res://art/music/loop_main.wav"


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


## Lee el PCM de un WAV de nuestro pipeline (PCM16 mono) y monta un
## AudioStreamWAV con bucle nativo. No usa el importador de Godot: su
## compress/mode por defecto es QOA con pérdida, así que el `data` del recurso
## importado NO es PCM crudo (medirlo como PCM daba "14,7 s" para 72,7 s de
## audio). El parser manual garantiza PCM intacto y LOOP_FORWARD, libre de
## los ajustes de importación. (Alternativa oficial 4.4+: el estático
## AudioStreamWAV.load_from_file(), que hace lo mismo.)
func _load_music_file(path: String) -> AudioStreamWAV:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var raw := f.get_buffer(f.get_length())
	f.close()
	var idx := -1
	for i in range(raw.size() - 12):
		if raw[i] == 0x64 and raw[i + 1] == 0x61 and raw[i + 2] == 0x74 and raw[i + 3] == 0x61:
			idx = i
			break
	if idx < 0:
		return null
	var pcm := raw.slice(idx + 8)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = pcm.size() / 2
	wav.data = pcm
	return wav


const MUSIC_BASE := "res://art/music/loop_base.wav"

var full: AudioStreamPlayer
var base: AudioStreamPlayer
var intensity := 0.0   # 0 = calma (base), 1 = combate (completa) — tarea 79


func _ready() -> void:
	full = AudioStreamPlayer.new()
	full.name = "MusicPlayer"   # la tecla M sigue encontrándolo
	full.volume_db = -16.0
	add_child(full)
	var s_full := _load_music_file(MUSIC_PATH)
	var s_base := _load_music_file(MUSIC_BASE)
	if s_full == null:
		full.stream = _build_loop()   # fallback procedural (una sola voz)
	elif s_base == null:
		full.stream = s_full
	else:
		full.stream = s_full
		base = AudioStreamPlayer.new()
		base.name = "MusicBase"
		base.volume_db = -60.0    # arranca inaudible
		base.stream = s_base
		add_child(base)
		base.play()
	full.play()


func set_intensity(f: float, delta: float) -> void:
	# crossfade suave (tarea 79); con una sola voz, no hace nada
	if base == null or base.stream == null:
		return
	intensity = move_toward(intensity, clampf(f, 0.0, 1.0), delta * 0.8)
	full.volume_db = lerpf(-26.0, -14.0, intensity)
	base.volume_db = lerpf(-16.0, -38.0, intensity)
