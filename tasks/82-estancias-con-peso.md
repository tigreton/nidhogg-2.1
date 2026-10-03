# Tarea 82 — Estancias con peso (cambiar de altura cuesta según el arma)

**Dificultad:** media · **Archivos:** `scripts/game_config.gd`, `scripts/player.gd`, `test/smoke_test.gd` (contingencia) · **Prerrequisitos:** 23 aplicada (GameConfig.WEAPONS)

## Objetivo

Divergencia de feel nº 3: en el original, cambiar de postura tiene duración
y depende del arma (la daga es "la más rápida en ataque, cambio de postura y
lanzamiento"; el espadón es un tronco). Aquí W/S es un interruptor
instantáneo. Esta tarea añade `stance_time` por arma: la hoja **viaja** —
apuntar arriba/abajo pasa de flick a decisión con coste, y el juego se
vuelve deliberado como el original.

## Contexto del proyecto (leer antes de tocar nada)

- El input de estancia vive en `player.gd::_physics_process`, bloque
  `if can_act:`:

```gdscript
		if held("up"):
			stance = H.HIGH
		elif held("down"):
			stance = H.LOW
		else:
			stance = H.MID
		if weapon_id == "espada" and stance == H.MID:
			stance = H.LOW
```

- `stance` es la estancia EFECTIVA (la leen guardias, flechas, impalamientos
  y el ataque al pulsarse: `attack_height = stance`): debe seguir siéndolo —
  el cambio se aplica SOLO al completarse el desplazamiento.
- `GameConfig.WEAPONS` (game_config.gd) tiene una entrada por arma con
  `dur/from/to/reach/run_mult/thrown_speed/thrown_kills/blade_*` — añadir
  `stance_time` a cada una.
- El bot cambia de estancia en `_bot_think` cada 0,13–0,26 s: con
  `stance_time ≤ 0,18` sus cambios llegan a completarse entre decisiones.
- Riesgo de tests: cualquier caso que pulse up/down y ataque EN EL MISMO
  frame espera la estancia instantánea. Repasa el smoke (tajos aéreos,
  guardias del arco) — la contingencia del paso 4 lo cubre.
- Reglas de estilo: GDScript tipado, tabs, español.

## Instrucciones paso a paso

### 1. `stance_time` en las armas

En `game_config.gd`, añade la clave a cada arma (daga ágil, florete ágil,
espadón pesado, arco irrelevante):

```gdscript
	"florete": { ... "stance_time": 0.08, ... }
	"espada":  { ... "stance_time": 0.18, ... }
	"daga":    { ... "stance_time": 0.0,  ... }
	"arco":    { ... "stance_time": 0.08, ... }
```

### 2. Desplazamiento con retardo en `player.gd`

Variables junto a `var stance: int = H.MID`:

```gdscript
var stance_target: int = H.MID   # a dónde va la hoja
var stance_shift := 0.0          # > 0 mientras la hoja viaja
```

Sustituye el bloque de input de estancia por:

```gdscript
		if can_act:
			var want: int = H.MID
			if held("up"):
				want = H.HIGH
			elif held("down"):
				want = H.LOW
			if weapon_id == "espada" and want == H.MID:
				want = H.LOW
			if want != stance and want != stance_target:
				stance_target = want
				stance_shift = float(weapon()["stance_time"])
			if stance_shift > 0.0:
				stance_shift -= delta
			elif stance_target != stance:
				stance = stance_target
```

### 3. Estados que fijan estancia la fijan también como objetivo

La rodada (`stance = H.LOW`), el dive (`stance = H.MID`) y el divekick la
asignan directo: añade junto a cada una `stance_target = stance` para que al
recuperar el control la hoja no "salte" sola. (Tres líneas, junto a las
existentes.)

### 4. Contingencia de tests

Ejecuta smoke y runner. Si un caso falla por atacar antes de completar el
cambio (esperaba HIGH y salió MID), NO toques `stance_time`: añade al caso
un `await get_tree().create_timer(0.12).timeout` (o los frames equivalentes)
entre empezar a mantener up/down y pulsar ataque. Los casos del arco (guardia
alta 30+ frames) ya tienen margen de sobra.

## Qué NO hacer

- No hagas el cambio instantáneo para el ataque: `attack_height = stance` es
  la estancia EFECTIVA — que el timing del jugador importe es el objetivo.
- No subas de 0,2 s: el espadón ya es el más lento atacando; más sería
  injugable.
- No guardes `stance_target` en el bot ni en el juego: vive solo en el
  jugador.

## Criterios de aceptación

1. Con florete, subir la hoja tarda ~0,08 s (apenas se nota); con espadón
   ~0,18 s (se planea); con daga, instantáneo.
2. Soltar up/down durante el viaje re-dirige la hoja al nuevo objetivo sin
   saltos.
3. Atacar a mitad de cambio golpea con la estancia VIEJA (la efectiva).
4. `SMOKE OK`, `ALL PASSED` y `SIM PASS` (con la contingencia si hace
   falta).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/test_runner.tscn
```

Últimas líneas esperadas: `SMOKE OK - todas las mecánicas funcionan` y
`RESULT: ALL PASSED (12)`.

## Nota de aplicación (2026-10-03)

Aplicada con la contingencia del paso 4 usada DOS veces en el caso 22 del
smoke: el stomp del caso 21 deja la hoja en LOW, y el puñetazo de pie se
distingue de la patada baja por `atk.stance != H.LOW` en `_melee_hit` — sin
esperas, el puñetazo salía como patada (hoja aún viajando) y la patada como
puñetazo. Añadidos +0,12 s antes del primer ataque y 0,15→0,35 s en el
segundo (que además pisaba la animación del primero). `SMOKE OK`,
`ALL PASSED (12)` y `SIM PASS` (kills=10, puntos=3).
