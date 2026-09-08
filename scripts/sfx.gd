class_name Sfx
## Efectos de sonido generados proceduralmente (sin assets externos).

static var _cache: Dictionary = {}


static func play(parent: Node, pos: Vector2, id: String, db := -10.0) -> void:
	var p := AudioStreamPlayer2D.new()
	p.stream = stream(id)
	p.volume_db = db
	p.position = pos
	p.max_distance = 2400.0
	parent.add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


static func stream(id: String) -> AudioStreamWAV:
	if _cache.has(id):
		return _cache[id]
	var data := PackedFloat32Array()
	match id:
		"clash":
			data = _noise(0.16, 26.0, 0.5)
		"hit":
			data = _noise(0.09, 34.0, 0.4)
		"swing":
			data = _noise(0.07, 50.0, 0.16)
		"throw":
			data = _noise(0.12, 30.0, 0.2)
		"kill":
			data = _sweep(0.3, 480.0, 70.0, 0.32)
		"jump":
			data = _sweep(0.09, 170.0, 330.0, 0.2)
		"respawn":
			data = _sweep(0.16, 760.0, 1250.0, 0.18, true)
		"pickup":
			data = _sweep(0.07, 540.0, 700.0, 0.22, true)
		"point":
			data = _arp([523.0, 659.0, 784.0], 0.11, 0.22)
		_:
			data = _noise(0.05, 40.0, 0.2)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	wav.data = _to_bytes(data)
	_cache[id] = wav
	return wav


static func _noise(dur: float, decay: float, vol: float) -> PackedFloat32Array:
	var n := int(dur * 22050.0)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / 22050.0
		out[i] = (randf() * 2.0 - 1.0) * vol * exp(-t * decay)
	return out


static func _sweep(dur: float, f0: float, f1: float, vol: float, sine := false) -> PackedFloat32Array:
	var n := int(dur * 22050.0)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / 22050.0
		var f := lerpf(f0, f1, t / dur)
		phase += TAU * f / 22050.0
		var s := sin(phase)
		if not sine:
			s = signf(s) * 0.7 + s * 0.3
		out[i] = s * vol * (1.0 - 0.6 * t / dur)
	return out


static func _arp(freqs: Array, note: float, vol: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for f in freqs:
		out.append_array(_sweep(note, f, f * 1.01, vol, true))
	return out


static func _to_bytes(samples: PackedFloat32Array) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(samples.size() * 2)
	for i in samples.size():
		var v := int(clampf(samples[i], -1.0, 1.0) * 32000.0)
		b[i * 2] = v & 0xFF
		b[i * 2 + 1] = (v >> 8) & 0xFF
	return b
