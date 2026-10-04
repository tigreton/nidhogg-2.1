# Tarea 91 — Fix: la tecla P (modo pantallas) rompe arcade y copa

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** 25, 36 y 39
aplicadas (bug de la revisión post-fusión online, 2026-10-04)

## Objetivo

Dentro del arcade o la copa, pulsar **P** activa el modo pantallas en medio
del bracket: `set_sections` resetea el marcador, `match_over` y rearranca la
ronda, desincronizando la escalera/eliminatoria (las teclas V y C ya tienen
guard `and not arcade and not cup`; P no). Añadir el mismo guard y, al
entrar en arcade/copa, apagar el modo pantallas como ya se hace con 2v2 y
el caos.

## Contexto del proyecto (leer antes de tocar nada)

- El bloque de toggles vive en `_physics_process`, dentro de
  `if not Net.active():` (la fusión online lo agrupó). Líneas actuales:
  `toggle_2v2`, `toggle_arena` y `toggle_random` llevan
  `and not arcade and not cup`; `toggle_sections` NO.
- `set_arcade(on)` y `set_cup(on)` empiezan con el patrón
  `if on and X: set_X(false)` para 2v2 y caos (`set_cup` también apaga el
  arcade): el modo pantallas falta ahí igualmente.
- El smoke test activa el modo pantallas SIN arcade/copa: el guard nuevo no
  lo afecta.

## Instrucciones paso a paso

### 1. Guard en el toggle

En `_physics_process`, busca la línea (dentro del bloque `if not Net.active():`):

```gdscript
		if Input.is_action_just_pressed("toggle_sections"):
			set_sections(not sections_mode)
```

y sustitúyela por:

```gdscript
		if Input.is_action_just_pressed("toggle_sections") and not arcade and not cup:
			set_sections(not sections_mode)
```

### 2. Apagar pantallas al entrar en arcade

En `set_arcade`, tras el bloque `if on and chaos: set_chaos(false)`, añade:

```gdscript
	if on and sections_mode:
		set_sections(false)
```

### 3. Apagar pantallas al entrar en la copa

En `set_cup`, tras el bloque `if on and chaos: set_chaos(false)`, añade las
mismas dos líneas del paso 2.

## Qué NO hacer

- No toques `set_sections` (el smoke la usa directamente y está bien).
- No añadas el guard a `toggle_arcade`/`toggle_cup`: salir de los modos con
  su propia tecla debe seguir funcionando siempre.
- No metas los cambios fuera del bloque `if not Net.active():`.

## Criterios de aceptación

1. Arcade nivel 2 en marcha: pulsa P → no pasa nada (ni rejas ni reset).
2. Copa en semifinal: pulsa P → no pasa nada.
3. Con el modo pantallas activo, pulsar Y → el arcade arranca LIMPIO (sin
   rejas), igual que ya apagaba el 2v2.
4. Fuera de arcade/copa, P activa/desactiva el modo pantallas como siempre.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan` (los casos
de pantallas, arcade y copa del smoke siguen pasando).
