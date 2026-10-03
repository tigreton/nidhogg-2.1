# Tarea 67 — Muerte súbita antidesgaste (45 s sin sangre)

**Dificultad:** baja/media · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** 47 aplicada (usa su `parry`)

## Objetivo

Romper los duelos cautelosos como el original: si pasan **45 s sin muertes**,
anuncio de **¡MUERTE SÚBITA!** y a partir de ahí **todo choque mata a ambos**
(paradas y rebotes incluidos). Se desactiva sola al morir alguien.

## Contexto del proyecto (leer antes de tocar nada)

- `_kill(def, atk)` centraliza las muertes: ahí se resetea el contador.
- `_resolve_attacks()` calcula `var outcome := "kill"` y un `match outcome`
  con las ramas `"kill"`, `"trade"`, `"clash"`, `"parry"`, `"miss"` (en ese
  orden). `"trade"` ya ejecuta `_melee_hit(atk, def)` + `_kill(atk, null)`
  (mueren los dos).
- El rebote de guardia a la misma estancia vive en `_resolve_guard_impale`
  (rama `if f.stance == g.stance:` con `parry_cd`); la parada blanda en
  `_parry(atk, def)` llamada desde el `match`.
- `show_msg(texto, dur)` y `sfx(pos, "alert", db)` para el anuncio.
- `_physics_process(delta)` descuenta `shake_time`/`parry_cd` al principio:
  sitio para el contador.
- `match_over` y `round_lock` gestionan el fin de punto; el contador NO debe
  correr con el partido acabado ni durante el round_lock (entre puntos hay
  pausa natural).
- Reglas de estilo: GDScript tipado, tabs, español.

## Instrucciones paso a paso

### 1. Estado

Junto a `var parry_cd := 0.0`:

```gdscript
var calm_time := 0.0            # segundos sin muertes
var sudden_death := false
const SUDDEN_DEATH_AFTER := 45.0
```

### 2. Contador en `_physics_process`

Junto a `parry_cd = maxf(0.0, parry_cd - delta)`:

```gdscript
	if not match_over and round_lock <= 0.0:
		calm_time += delta
		if not sudden_death and calm_time >= SUDDEN_DEATH_AFTER:
			sudden_death = true
			show_msg("¡MUERTE SÚBITA!", 1.4)
			sfx(camera.position, "alert", -4.0)
			shake_time = maxf(shake_time, 0.2)
```

### 3. Choques mortales

En `_resolve_attacks`, justo antes de `atk.attack_resolved = true`:

```gdscript
		if sudden_death and outcome in ["clash", "parry", "miss"]:
			outcome = "trade"   # muerte súbita: todo contacto mata a ambos
```

Y en `_resolve_guard_impale`, rama de misma estancia, sustituye el
`if parry_cd > 0.0: continue` por:

```gdscript
				if sudden_death:
					_kill(f, g)   # en muerte súbita el rebote también mata
					return
				if parry_cd > 0.0:
					continue
```

### 4. Reset al morir alguien

En `_kill(def, atk)`, primera línea tras el guard `if def.state == DEAD`:

```gdscript
	calm_time = 0.0
	sudden_death = false
```

Y en `_start_round()`, junto a `right_of_way = null`:

```gdscript
	calm_time = 0.0
	sudden_death = false
```

## Qué NO hacer

- No matrices el respawn entre puntos de la misma ronda: solo cuenta el
  tiempo entre MUERTES, y una muerte apaga la muerte súbita.
- No toques flechas ni armas lanzadas: siguen con sus reglas (la súbita
  afecta al cuerpo a cuerpo y al rebote, que es donde se esconde el rival).
- No lo apliques con `match_over` (el juego ya ha terminado).

## Criterios de aceptación

1. Dejar pasar 45 s sin matar muestra el aviso y suena; a partir de ahí
   cualquier parada, rebote o choque mata a ambos.
2. La primera muerte devuelve el juego a la normalidad (contador a 0).
3. R de revancha limpia el estado.
4. `SMOKE OK` y `ALL PASSED` sin cambios (los tests matan mucho y rápido:
   nunca llegan a 45 s).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/test_runner.tscn
```

Últimas líneas esperadas: `SMOKE OK - todas las mecánicas funcionan` y
`RESULT: ALL PASSED (12)`. Comprobación a mano: poner
`SUDDEN_DEATH_AFTER := 5.0` temporalmente y dejar pasar 5 s.
