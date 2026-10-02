# Tarea 53 — SFX reales: WAVs de art/sfx + eventos fight y arrow_bounce

**Dificultad:** baja · **Archivos:** `scripts/sfx.gd`, `scripts/game.gd` · **Prerrequisitos:** que exista `res://art/sfx/` (ya importado, con `.import`)

## Objetivo

Sustituir la síntesis procedural por los 8 WAV reales de `res://art/sfx/`
donde exista correspondencia, y añadir dos sonidos a eventos que hoy están
mudos: el cartel **¡FIGHT!** y el **rebote de flecha**. Los ids sin WAV
(`respawn`, `pickup`, `point`, `alert`, `crash`) siguen sintetizados como
hasta ahora.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript), duelo de esgrima 2D estilo Nidhogg.
- `scripts/sfx.gd` — clase estática `Sfx`. Todo sonido se pide por id de
  texto: `Sfx.play(parent, pos, id, db)` crea un `AudioStreamPlayer2D` con
  `stream(id)`. `stream()` sintetiza muestras en un `AudioStreamWAV`
  (22050 Hz, mono) y las cachea en `_cache`. Los ids existentes están en el
  `match id` de `stream()`: `clash`, `hit`, `swing`, `throw`, `kill`, `jump`,
  `respawn`, `pickup`, `point`, `alert`, `crash` y un default.
- `scripts/game.gd` — el wrapper `func sfx(pos: Vector2, id: String, db := -10.0)`
  está en la línea ~181; todo el juego llama a `sfx(...)`.
  - El cartel ¡FIGHT! vive en `_show_fight()` (línea ~1402): hoy solo hace el
    tween de escala/opacidad, sin sonido.
  - El rebote de flecha contra guardia está en la resolución de flechas
    (línea ~2004-2008): rama `if guards:` → `a.vel` se invierte,
    `a.bounces += 1` y suena `sfx(a.position, "clash", -14.0)`. Además, cuando
    la flecha agota sus rebotes queda clavada (`a.vel = Vector2.ZERO`,
    unas líneas antes, en el mismo bucle de `arrows`).
- Los 8 WAV disponibles (`res://art/sfx/`): `attack_swipe`, `clash`, `jump`,
  `throw`, `arrow_bounce`, `kill`, `stomp`, `fight`.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en
  español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Tabla de WAVs en `sfx.gd`

En `scripts/sfx.gd`, actualiza el comentario de cabecera de la clase (ya no
es "sin assets externos") y añade la tabla de sonidos reales justo después de
`static var _cache: Dictionary = {}`:

```gdscript
## Efectos de sonido: WAVs reales de res://art/sfx cuando existen;
## el resto se sintetiza como siempre.
class_name Sfx

# sonidos reales importados; los ids que no están aquí se sintetizan abajo
const WAVS := {
	"clash": preload("res://art/sfx/clash.wav"),
	"swing": preload("res://art/sfx/attack_swipe.wav"),
	"throw": preload("res://art/sfx/throw.wav"),
	"kill": preload("res://art/sfx/kill.wav"),
	"jump": preload("res://art/sfx/jump.wav"),
	"hit": preload("res://art/sfx/stomp.wav"),
	"fight": preload("res://art/sfx/fight.wav"),
	"arrow_bounce": preload("res://art/sfx/arrow_bounce.wav"),
}
```

(No dupliques `class_name Sfx`; solo reemplaza el comentario doc `##` de
arriba del todo por el nuevo.)

### 2. `stream()` consulta primero los WAVs

En `stream(id)`, justo después del chequeo de caché:

```gdscript
static func stream(id: String) -> AudioStreamWAV:
	if _cache.has(id):
		return _cache[id]
	if WAVS.has(id):
		_cache[id] = WAVS[id]
		return WAVS[id]
	var data := PackedFloat32Array()
	... (el match de síntesis se queda igual, sin cambios)
```

### 3. Evento "fight" en el cartel

En `scripts/game.gd`, primera línea de `_show_fight()`:

```gdscript
func _show_fight() -> void:
	sfx(Vector2(LEVEL_W * 0.5, 300.0), "fight", -4.0)
	fight_label.visible = true
	...
```

### 4. Evento "arrow_bounce" en el rebote

En el bloque de resolución de flechas, rama `if guards:` (donde hoy suena
`"clash"`), sustituye esa llamada:

```gdscript
			if guards:
				a.vel = Vector2(a.vel.x * -0.85, 0.0)
				a.bounces += 1
				_burst(a.position, Color(0.9, 0.9, 1.0), 8, 220.0)
				sfx(a.position, "arrow_bounce", -14.0)
```

Y en el mismo bucle de `arrows`, donde la flecha agota rebotes y queda
clavada (la línea `a.vel = Vector2.ZERO` que va seguida de `continue`),
añade encima:

```gdscript
			sfx(a.position, "arrow_bounce", -20.0)
			a.vel = Vector2.ZERO
			continue
```

## Qué NO hacer

- No borres ni toques la síntesis (`_noise`, `_sweep`, `_arp`, `_to_bytes`)
  ni las ramas del `match`: son el fallback de `respawn`, `pickup`, `point`,
  `alert`, `crash` y del default.
- No renombres ids existentes: el juego entero llama a `clash`/`swing`/etc.
  por su nombre de siempre.
- No conviertas la clase en nodo ni añadas autoloads: `Sfx` es estática.

## Criterios de aceptación

1. Al lanzar el juego suenan los WAV reales en ataque, choque, salto,
   lanzamiento y muerte (se nota: dejan de sonar "chip").
2. El cartel ¡FIGHT! de cada ronda suena `fight.wav`.
3. Una flecha que rebota en una guardia suena `arrow_bounce.wav` (antes era
   el clash sintetizado).
4. Reaparecer, recoger arma, anotar punto, aviso de roca y choque de roca
   siguen sonando (sintetizados).
5. El smoke test termina en `SMOKE OK`.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
(Con `--headless` no se oye nada: la comprobación de sonido es manual, con
el juego abierto con render.)
