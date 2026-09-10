# Tarea 16 — Soporte de mando (2 gamepads)

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** ninguno

## Objetivo

Mapear dos mandos: P1 usa el gamepad 0 y P2 el gamepad 1. Stick izquierdo para
moverse/estancias; botones: A (inferior) saltar, X (izquierdo) atacar,
B (derecho) lanzar espada; START para la revancha. El teclado sigue funcionando.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Arte
  procedural, sonidos por código: **sin assets externos**.
- `scripts/game.gd` — `_setup_input()` registra las acciones de teclado en
  runtime: construye `InputEventKey` con `physical_keycode` y los añade con
  `InputMap.action_add_event(...)`. Las acciones son `p1_left`, `p1_right`,
  `p1_up`, `p1_down`, `p1_jump`, `p1_attack`, `p1_throw`, `p2_...` y `restart`.
- Godot: un mismo `InputMap` admite eventos de teclado Y de mando para la misma
  acción; basta añadir más eventos. Para sticks se usa `InputEventJoypadMotion`
  (`device`, `axis`, `axis_value` con signo −1/1); para botones
  `InputEventJoypadButton` (`device`, `button_index`). Con `device = -1` el
  evento acepta cualquier mando.
- El smoke test no tiene mandos conectados: como las acciones de teclado no se
  tocan, no puede romperse.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Mapeos

En `_setup_input()`, DESPUÉS del bucle `for action in defs.keys():` que registra
el teclado, añade:

```gdscript
	# mandos: P1 = gamepad 0, P2 = gamepad 1
	var pad_axes := {
		"p1_left": [0, JOY_AXIS_LEFT_X, -1.0], "p1_right": [0, JOY_AXIS_LEFT_X, 1.0],
		"p1_up": [0, JOY_AXIS_LEFT_Y, -1.0], "p1_down": [0, JOY_AXIS_LEFT_Y, 1.0],
		"p2_left": [1, JOY_AXIS_LEFT_X, -1.0], "p2_right": [1, JOY_AXIS_LEFT_X, 1.0],
		"p2_up": [1, JOY_AXIS_LEFT_Y, -1.0], "p2_down": [1, JOY_AXIS_LEFT_Y, 1.0],
	}
	var pad_buttons := {
		"p1_jump": [0, JOY_BUTTON_A], "p1_attack": [0, JOY_BUTTON_X], "p1_throw": [0, JOY_BUTTON_B],
		"p2_jump": [1, JOY_BUTTON_A], "p2_attack": [1, JOY_BUTTON_X], "p2_throw": [1, JOY_BUTTON_B],
		"restart": [-1, JOY_BUTTON_START],
	}
	for action in pad_axes.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var ev := InputEventJoypadMotion.new()
		ev.device = pad_axes[action][0]
		ev.axis = pad_axes[action][1]
		ev.axis_value = pad_axes[action][2]
		InputMap.action_add_event(action, ev)
	for action in pad_buttons.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var eb := InputEventJoypadButton.new()
		eb.device = pad_buttons[action][0]
		eb.button_index = pad_buttons[action][1]
		InputMap.action_add_event(action, eb)
```

### 2. Pista visual (opcional pero recomendada)

En `_build_hud()`, en el texto del `hint`, añade al final:
`    Mando: stick + A saltar · X atacar · B lanzar`.

## Qué NO hacer

- No elimines ni modifiques los eventos de teclado existentes.
- No uses `device = 0` para el `restart`: va con `-1` (cualquier mando).
- No inventes calibraciones de zona muerta: usa las acciones tal cual.

## Criterios de aceptación

1. Con dos mandos conectados, cada jugador controla a su duelist con el suyo.
2. El teclado sigue funcionando a la vez que los mandos.
3. START funciona para la revancha desde cualquier mando.
4. El smoke test sigue pasando sin mandos.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`
(los mandos se prueban a mano con F5).
