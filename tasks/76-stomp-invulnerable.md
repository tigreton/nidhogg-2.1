# Tarea 76 — Invulnerabilidad breve al ejecutar el stomp

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** 27 aplicada (stomp letal)

## Objetivo

En el original, stompear a un caído te deja **invulnerable mientras lo
haces** (el rival no puede salvarte el stomp con un tajo de castigo). Aquí:
el stomp concede 0,4 s de invulnerabilidad al ejecutor.

## Contexto del proyecto (leer antes de tocar nada)

- `_resolve_stomps()` (game.gd): p en IDLE/RUN, en suelo, `held("down")`,
  con un `def` KNOCKDOWN a ≤34 px → `_burst` + `_kill(def, p)`.
- `p.invuln_time` ya existe (parpadeo del sprite incluido) y todas las
  resoluciones lo respetan (`if def.invuln_time > 0.0: continue`).
- Reglas de estilo: GDScript tipado, tabs, español.

## Instruccuciones paso a paso

### 1. La concesión

En `_resolve_stomps`, sustituye el bloque final del impacto:

```gdscript
			# pisotón letal: el derribado estalla
			_burst(def.position, def.color, 60, 560.0)
			_kill(def, p)
			shake_time = maxf(shake_time, 0.2)
			break
```

por:

```gdscript
			# pisotón letal: el derribado estalla; el ejecutor, invulnerable
			_burst(def.position, def.color, 60, 560.0)
			p.invuln_time = maxf(p.invuln_time, 0.4)
			_kill(def, p)
			shake_time = maxf(shake_time, 0.2)
			break
```

## Qué NO hacer

- No concedas la invulnerabilidad al pisar sin matar (solo al ejecutar el
  stomp real).
- No la extiendas más de 0,5 s: castigaría demasiado al rival.
- No la des al caído (él ya tiene la suya al reaparecer).

## Criterios de aceptación

1. Matar con stomp deja al ejecutor parpadeando 0,4 s: un tajo inmediato de
   un tercer jugador (2v2) o del portador no le mata en esa ventana.
2. El stomp sobre invulnerable sigue siendo letal como siempre.
3. `SMOKE OK` y `ALL PASSED` (el smoke tiene caso de stomp: sus asserts no
   miran invuln del ejecutor).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
