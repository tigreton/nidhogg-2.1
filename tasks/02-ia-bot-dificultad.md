# Tarea 02 — Tres niveles de dificultad del bot

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos: tarea 01 aplicada**

## Objetivo

Que la tecla **B** ciclie el bot de P2 entre OFF → FÁCIL → NORMAL → DIFÍCIL → OFF.
La dificultad cambia tres cosas: tiempo de reacción, frecuencia de ataque y
probabilidad de equivocarse con la estancia.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Todo el arte
  es procedural (`_draw()`) y los sonidos se generan por código: sin assets externos.
- Esta tarea asume que la **tarea 01 ya está aplicada**: `player.gd` tiene
  `is_bot`, `bot_held`, `bot_held_prev` y `bot_think`, y `game.gd` tiene la
  función `_bot_think(p: Player, delta: float)` y la acción `"toggle_bot"` (tecla B)
  gestionada en `_physics_process`.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Tabla de configuración

En `scripts/game.gd`, junto a las demás constantes (después de `const RESPAWN_DELAY`),
añade:

```gdscript
const BOT_CFG := [
	{"react": 0.26, "atk": 0.12, "err": 0.35},  # FÁCIL
	{"react": 0.13, "atk": 0.30, "err": 0.10},  # NORMAL
	{"react": 0.07, "atk": 0.50, "err": 0.02},  # DIFÍCIL
]
```

Y junto a las variables de instancia (después de `var shake_time := 0.0`):

```gdscript
var bot_level := 1   # 1 FÁCIL, 2 NORMAL, 3 DIFÍCIL (si is_bot está activo)
```

### 2. Ciclo de la tecla B

En `_physics_process`, reemplaza el bloque que añadiste para `"toggle_bot"`
(el que hacía `players[1].is_bot = not players[1].is_bot`) por:

```gdscript
	if Input.is_action_just_pressed("toggle_bot"):
		if not players[1].is_bot:
			bot_level = 1
			players[1].is_bot = true
		elif bot_level < 3:
			bot_level += 1
		else:
			players[1].is_bot = false
		var names := ["FÁCIL", "NORMAL", "DIFÍCIL"]
		if players[1].is_bot:
			show_msg("BOT P2: %s" % names[bot_level - 1], 0.7)
		else:
			show_msg("BOT P2: OFF", 0.7)
```

### 3. Usar la configuración en el cerebro

En `_bot_think`, haz estos tres reemplazos puntuales:

3.1. La línea `p.bot_think = 0.12` →

```gdscript
	var cfg: Dictionary = BOT_CFG[bot_level - 1]
	p.bot_think = float(cfg["react"])
```

3.2. La línea `if randf() < 0.30:` (la de atacar) →

```gdscript
			if randf() < float(cfg["atk"]):
```

3.3. El bloque de "estancia ganadora" empieza con el comentario
`# estancia ganadora: ...`. Justo ANTES de la línea `if foe.stance == Player.H.MID:`,
inserta la posibilidad de error:

```gdscript
			# con probabilidad "err" el bot se equivoca de estancia
			if randf() < float(cfg["err"]):
				var r := randi() % 3
				if r == 0:
					want["up"] = true
				elif r == 1:
					want["down"] = true
				else:
					pass  # se queda en media por error
			elif foe.stance == Player.H.MID:
				want["down"] = true
```

(ojo: esto sustituye al `if foe.stance == Player.H.MID:` original — ahora es un
`elif` del error). Las dos líneas siguientes (`if randf() < ...tap = "attack"` y
`if p.has_sword and randf() < ...tap = "throw"`) se quedan igual, dentro de este `else`.

## Qué NO hacer

- No toques `player.gd` ni el test.
- No cambies el comportamiento corredor/interceptor del bot, solo el duelo.
- No añadas menús: solo el ciclo con B y el mensaje en pantalla.

## Criterios de aceptación

1. B cicla OFF → FÁCIL → NORMAL → DIFÍCIL → OFF y el mensaje muestra el nivel.
2. En FÁCIL el bot reacciona tarde y falla estancias a menudo; en DIFÍCIL ataca
   en cuanto tiene estancia ganadora y casi no falla.
3. El bot humano (B en OFF) sigue funcionando igual que antes.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`
(el ciclo de B se comprueba a mano abriendo el juego con F5).
