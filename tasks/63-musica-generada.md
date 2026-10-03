# Tarea 63 — Música generada (bucle real con fallback procedural)

**Dificultad:** baja (código) / bloqueada por asset (generación) · **Archivos:** `scripts/music.gd`, `scripts/game.gd`, nuevo `art/music/` · **Prerrequisitos:** el asset de música (ver abajo)

> **EN ESPERA (2026-10-03):** el pipeline actual no genera música (`bl` cubre
> imágenes y TTS, no composición). La parte de código es aplicable en cuanto
> exista el fichero; la generación va en la misma tanda que la 61.

## Objetivo

Sustituir el bucle chiptune procedural de `music.gd` por un bucle real
generado, conservando el sintetizado como **fallback automático** si el
fichero no existe (un clon sin assets sigue sonando). La tecla M sigue
silenciando.

## Especificación del asset

- Ruta: `res://art/music/loop_main.ogg` (OGG vorbis; WAV si pesa < 8 MB).
- Duración 60–90 s, **loop perfecto** (el primer y último compás encajan sin
  silencio; Godot lo reproduce con `LOOP_DISABLED` + reintroducción manual o
  import con loop activado).
- Estilo: tenso y minimalista, estilo Nidhogg 2 (sintetizador + percusión
  seca); mezcla sobria, pico ≈ −12 dB, arranque SIN golpe fuerte (suena bajo
  el gameplay desde el inicio del partido).
- Referencia de estado: `docs/RESEARCH.md` y el análisis de los tráilers en
  `media/videos/` describen el pulso del original.

## Instrucciones paso a paso (código, cuando el asset exista)

### 1. Carga con fallback en `music.gd`

En `_ready()` de `Music`, antes de construir el bucle sintetizado:

```gdscript
const MUSIC_PATH := "res://art/music/loop_main.ogg"

var player: AudioStreamPlayer

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.volume_db = -16.0
	add_child(player)
	if ResourceLoader.exists(MUSIC_PATH):
		player.stream = load(MUSIC_PATH)
		player.finished.connect(player.play)
		player.play()
		return
	_build_loop()   # fallback: el chiptune procedural actual
	...
```

(Conserva `_build_loop()` y todo lo existente tal cual: es el camino sin
asset. El `AudioStreamWAV` sintetizado pasa a `player.stream` y se reproduce
igual.)

### 2. Tecla M sin cambios

El toggle de `game.gd` (silenciar/activar) debe actuar sobre `player.playing`
/ `player.stream_paused` — adaptar la referencia que hoy apunta al stream
viejo.

### 3. Import

Abrir el editor una vez para que genere el `.import` del OGG (y commitearlo
junto al asset, como se hizo con `art/sprites`).

## Qué NO hacer

- No borres `_build_loop()`: es el fallback y la referencia del estilo.
- No metas la música por `Sfx.play`: es un bucle global, no posicional.
- No subas el volumen por encima de −14 dB: taparía los SFX del combate.

## Criterios de aceptación

1. Con `art/music/loop_main.ogg` presente suena el bucle real en bucle
   perfecto; sin él, el chiptune de siempre (sin tocar nada más).
2. M silencia y reactiva en ambos modos.
3. `SMOKE OK` (la música no forma parte del smoke) y escucha manual.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.

## Nota de aplicación (2026-10-03): APLICADA

El bucle se **compuso y renderizó offline** (Python/numpy, semilla fija) en
vez de esperar a un modelo de música: 40 compases a 132 BPM (72,7 s, E menor,
4 secciones: pulso → arpegio + melodía → pulso → variación con melodía),
eco de corchea con puntillo aplicado **circularmente** (loop perfecto) y
normalizado a pico 0,55. Fichero: `art/music/loop_main.wav` (3,2 MB, PCM16
mono 22050).

**Cambio importante respecto al paso 1 de esta tarea:** el importador de
Godot **trunca el WAV** (72,7 s entraban como 14,7 s), así que `music.gd` lee
el PCM a mano (`FileAccess` + busca el chunk `data`) y monta el
`AudioStreamWAV` con `LOOP_FORWARD` nativo — sin re-encolar. El fallback
procedural (`_build_loop`) se conserva intacto: sin el fichero, el chiptune.
Verificado: stream de 72,7 s en bucle sonando, tecla M intacta, `SMOKE OK`.

Una tanda futura con modelo de música solo tendrá que dejar un WAV/OGG en
`art/music/` (mismo formato PCM16 mono) para sustituirlo.
