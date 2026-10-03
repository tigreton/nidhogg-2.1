# Tarea 68 — Murmullo de público (pista de ambiente reactiva)

**Dificultad:** media · **Archivos:** `scripts/sfx.gd`, `scripts/game.gd` · **Prerrequisitos:** ninguno

## Objetivo

La última pantalla del original tiene público animando; su murmullo sube con
la emoción. Aquí: ruido rosa en bucle a volumen casi inaudible que **sube**
con la actividad (bajas recientes) y cuando el corredor se acerca a su meta
(< 600 px). Todo procedural, sin assets.

## Contexto del proyecto (leer antes de tocar nada)

- `sfx.gd` sintetiza `AudioStreamWAV` en memoria (`_noise`, `_sweep`, `_arp`,
  conversión `_to_bytes`) a 22050 Hz mono; patrón a copiar para el bucle.
- `game.gd` instancia `music` (Music) y llama `sfx(pos, id, db)` posicional;
  el público NO es posicional: un `AudioStreamPlayer` global colgado del
  juego con `LOOP_FORWARD` (como `Music._build_loop` hace con su WAV).
- "Emoción": `right_of_way` es el corredor; su meta está en
  `LEVEL_W - GOAL_W` (goal_dir 1) o `GOAL_W` (goal_dir −1). `GOAL_W` existe.
- `stats[i]["kills"]` existe, pero es más simple un contador propio de bajas
  recientes: `_kill(def, atk)` es el punto de anclaje.
- Reglas de estilo: GDScript tipado, tabs, español.

## Instrucciones paso a paso

### 1. Ruido rosa en `sfx.gd`

Añade junto a `_noise`:

```gdscript
## Bucle de ruido rosa (público): energía -3 dB/octava, sin clic de bucle
## (los extremos se funden por crossfade del 5% inicial contra el final).
static func crowd_loop() -> AudioStreamWAV:
	var n := 22050 * 2
	var pink := PackedFloat32Array()
	pink.resize(n)
	var b0 := 0.0
	var b1 := 0.0
	var b2 := 0.0
	for i in n:
		var white := randf() * 2.0 - 1.0
		b0 = 0.997 * b0 + white * 0.029
		b1 = 0.985 * b1 + white * 0.032
		b2 = 0.95 * b2 + white * 0.048
		pink[i] = (b0 + b1 + b2) * 0.55
	var xf := n / 20
	for i in xf:
		var k := float(i) / float(xf)
		pink[i] = pink[i] * k + pink[n - xf + i] * (1.0 - k)
	var out := pink.slice(0, n - xf)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = out.size()
	wav.data = _to_bytes(out)
	return wav
```

### 2. El jugador de ambiente en `game.gd`

Variables junto a `var music: Music`:

```gdscript
var crowd: AudioStreamPlayer
var crowd_excite := 0.0   # 0..1
var crowd_kill_flash := 0.0
```

En `_ready()`, tras `add_child(music)`:

```gdscript
	crowd = AudioStreamPlayer.new()
	crowd.stream = Sfx.crowd_loop()
	crowd.volume_db = -44.0
	crowd.name = "Crowd"
	add_child(crowd)
	crowd.play()
```

### 3. Emoción y volumen

En `_kill(def, atk)`, junto a `sfx(def.position, "kill", -6.0)`:

```gdscript
	crowd_kill_flash = 1.0
```

En `_physics_process(delta)`, junto al descuento de `parry_cd`:

```gdscript
	crowd_kill_flash = maxf(0.0, crowd_kill_flash - delta * 0.5)
	var near_goal := 0.0
	if right_of_way != null and right_of_way.state != Player.State.DEAD:
		var gx := LEVEL_W - GOAL_W if right_of_way.goal_dir > 0 else GOAL_W
		near_goal = clampf(1.0 - absf(right_of_way.position.x - gx) / 600.0, 0.0, 1.0)
	crowd_excite = move_toward(crowd_excite, clampf(near_goal + crowd_kill_flash, 0.0, 1.0), delta * 0.6)
	if crowd != null:
		crowd.volume_db = lerpf(-44.0, -26.0, crowd_excite)
```

## Qué NO hacer

- No pases de −26 dB: es ambiente, no una avalancha.
- No lo hagas `AudioStreamPlayer2D` ni posicional.
- No lo silencies con la tecla M (esa es de la MÚSICA): el público es
  atmósfera; si algún día se quiere, tecla aparte.

## Criterios de aceptación

1. Desde el arranque se oye un murmullo tenue de fondo (sube el volumen del
   sistema para notarlo).
2. Matar produce una crecida audible que decae en ~2 s.
3. El corredor acercándose a su meta lo sube progresivamente ( audible a
   <600 px, máximo pegado a la meta).
4. `SMOKE OK` (el audio no forma parte del smoke).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
