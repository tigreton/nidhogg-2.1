# Tarea 04 — Escalera de plataformas (verticalidad)

**Dificultad:** baja · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** ninguno

## Objetivo

Añadir una escalera de tres plataformas en la zona x=1480–1900 para dar
verticalidad: se puede subir saltando y desde lo alto atacar o tirarse en
patada voladora sobre el rival que pasa por debajo.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Duelo de esgrima 2D estilo Nidhogg. Todo el arte
  es procedural y los sonidos se generan por código: **sin assets externos**.
- `scripts/game.gd` construye el nivel en `_build_level()` y ya tiene un helper:
  `_platform(x0: float, x1: float, y: float)` que crea la caja de colisión
  (`StaticBody2D` de 16 px de alto) y el dibujo de una plataforma.
- Física de salto (para que veas por qué estas alturas funcionan): velocidad de
  salto `-700`, gravedidad `1700` → el salto sube ~144 px. El suelo está a
  `GROUND_Y=560`; los "pies" del duelist quedan ~29 px por encima de su centro.
- Prohibido colocar plataformas con parte de su rango x en [1550, 2050] POR DEBAJO
  de y=520... en realidad al revés: el smoke test coloca jugadores en el suelo de
  x≈1600–1800 y solo comprueba `is_on_floor` tras un salto puntual, así que las
  plataformas deben quedar ALTAS (y ≥ 448) para no bloquear el paso por el suelo.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Plataformas

En `scripts/game.gd`, dentro de `_build_level()`, después de la línea
`_platform(PLAT_X0, PLAT_X1, PLAT_Y)`, añade exactamente:

```gdscript
	# escalera de plataformas (verticalidad en el tramo izquierdo-centro)
	_platform(1480.0, 1660.0, 448.0)
	_platform(1660.0, 1800.0, 368.0)
	_platform(1800.0, 1900.0, 288.0)
```

Alturas elegidas para que cada salto suba 80–112 px (factible con salto de 144 px).

### 2. Comprobación de alcance (no requiere código, solo entenderlo)

- Suelo (560) → plataforma 1 (448): sube 112 px. OK.
- Plataforma 1 (448) → plataforma 2 (368): sube 80 px. OK.
- Plataforma 2 (368) → plataforma 3 (288): sube 80 px. OK.

## Qué NO hacer

- No toques `_platform()` ni `_static_box()`: úsalos tal cual.
- No pongas plataformas por debajo de y=448 en la franja 1480–2050 (el test y el
  paso por el suelo deben quedar libres).
- No añadas rampas ni otras físicas nuevas.

## Criterios de aceptación

1. Se ven tres plataformas escalonadas y se puede subir de suelo a la más alta
   con tres saltos.
2. Se puede caminar por debajo de la escalera sin chocar (el suelo sigue libre).
3. Desde la plataforma más alta, un salto + ataque en el aire hace patada
   voladora sobre un rival que pase por el suelo.
4. El smoke test sigue pasando.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`
(la escalera se comprueba a mano con F5).
