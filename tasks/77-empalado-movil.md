# Tarea 77 — Cadáver empalado móvil (sube y baja con la hoja)

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** 30 aplicada (cadáver/empalamiento)

## Objetivo

El detalle del logro "Memories" del original: con la víctima clavada en tu
hoja, cambiar de estancia **mueve el cadáver con la hoja** (arriba lo
izas, abajo lo apoyas). Hoy el cadáver empalado queda pegado a un punto fijo
del asesino.

## Contexto del proyecto (leer antes de tocar nada)

- Clase `Corpse` (game.gd): cuando `impaler != null`, cada frame fija
  `position = impaler.position + Vector2(impaler.facing * 44.0, -6.0)`.
- El asesino cambia estancia con up/down (su sprite dibuja la hoja en tres
  líneas: alta hacia arriba, media al frente, baja hacia abajo) — el offset
  del cadáver debe seguirla.
- `Player.H` es `LOW=0, MID=1, HIGH=2`.
- Reglas de estilo: GDScript tipado, tabs, español.

## Instrucciones paso a paso

### 1. Offset por estancia

En `Corpse._process`, sustituye la línea del empalamiento:

```gdscript
				position = impaler.position + Vector2(impaler.facing * 44.0, -6.0)
```

por:

```gdscript
				# el cadáver sigue la línea de la hoja según la estancia (tarea 77)
				match impaler.stance:
					Player.H.HIGH:
						position = impaler.position + Vector2(impaler.facing * 26.0, -34.0)
					Player.H.LOW:
						position = impaler.position + Vector2(impaler.facing * 40.0, 14.0)
					_:
						position = impaler.position + Vector2(impaler.facing * 44.0, -6.0)
```

## Qué NO hacer

- No lo sueltes del todo al bajar (LOW lo apoya rozando el suelo, no lo
  entierras: y +14 con el sprite tumbado queda a ras).
- No alteres la condición de soltarse (`attack_is_active()` o perder espada
  liberan el cadáver, como ya está).
- No lo hagas con el arco (el arco no empala: sigue excluido como hoy).

## Criterios de aceptación

1. Empala a un rival con florete/daga y mantén arriba/abajo: el cadáver
   sube y baja con la hoja, pegado a su línea.
2. Atacar o soltar el arma suelta el cadáver como antes.
3. `SMOKE OK` (el smoke tiene caso de empalamiento y no asserta el offset).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
