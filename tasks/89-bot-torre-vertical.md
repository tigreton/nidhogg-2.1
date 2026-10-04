# Tarea 89 — El bot usa los dos pisos de la Torre del Centinela

**Dificultad:** alta · **Archivos:** `scripts/game.gd` · **Prerrequisitos:** 85 aplicada
(la torre ya existe; limitación de la revisión post-fusión, 2026-10-04)

## Objetivo

`_bot_think` solo razona en el plano del suelo: en la TORRE DEL CENTINELA
(arena 4, tecla C tres veces) un corredor humano subido al piso superior
(y=320) es inalcanzable para el bot interceptor, que corre por el pasillo
inferior sin usar nunca las escaleras flotantes. Enseñarle el cambio de
piso: **subir por la escalera más cercana** cuando el rival juega arriba y
**bajar andando hasta el hueco más cercano** cuando juega abajo.

## Contexto del proyecto (leer antes de tocar nada)

- Geometría de la torre (`_tower_floor` en game.gd): piso superior a y=320
  en los tramos [620–1170], [1340–2130], [2460–3240], [3410–4120], con dos
  **huecos** (1170–1340 y 3240–3410) y el foso central a cielo abierto
  (2130–2460). **Escaleras flotantes** (se pasa por debajo): izquierda
  (450–560, y=448) y (520–610, y=384); derecha (4230–4340, y=448) y
  (4180–4270, y=384).
- Alturas de pies (`position.y` = superficie − 29): suelo 531, peldaños
  419/355, piso superior 291. Umbral "está arriba": y < 450 para el RIVAL
  (vale piso o peldaños); para uno mismo se usa y < 330 ("llegué de verdad
  al piso 320"), para seguir subiendo mientras se pisan los peldaños.
- Física de salto (player.gd): ~66 px parado, ~144 px corriendo de ápice.
  Para SUBIR una escalera hay que entrar por su pie con salto corriendo:
  la izquierda se embarca desde **x < 450 yendo a la derecha** (el arco
  cae sobre 450–560@448) y la derecha desde **x > 4340 yendo a la
  izquierda** (cae sobre 4230–4340@448). Empezar el salto desde debajo de
  la escalera hace pasarse de largo: por eso la aproximación camina hasta
  el pie y SOLO ENTONCES gira y salta.
- `_bot_think(p, delta)` decide cada `cfg["react"]` s y termina aplicando
  `p.bot_held = want` + un `tap` opcional. El corredor (con el paso) corre
  al suelo: NO se toca (la ruta suelo es válida y llega a meta).
- El bot solo cambia de piso en la arena 3 (`arena_id == 3`) y en estados
  de control (IDLE/RUN/JUMP): derribado usa la cola normal de levantarse.

## Instrucciones paso a paso

### 1. Insertar la rama de verticalidad al inicio de `_bot_think`

Busca la línea `var row_team := -1 if right_of_way == null else _team(right_of_way)`
(está justo antes del `if right_of_way != null and row_team == _team(p):`)
e inserta DESPUÉS de ella:

```gdscript
	# torre (85): si el rival juega en el otro piso, cambiar de piso —
	# subir por la escalera flotante más cercana (izq: se entra desde x<450
	# yendo a la derecha; dcha: desde x>4340 yendo a la izquierda) o bajar
	# andando hasta el hueco más cercano y caer por él
	var foe_up := foe.position.y < 450.0
	var me_up := p.position.y < 330.0
	if arena_id == 3 and foe_up != me_up and p.state in [Player.State.IDLE, Player.State.RUN, Player.State.JUMP]:
		if foe_up:
			var use_left := absf(p.position.x - 500.0) < absf(p.position.x - 4290.0)
			if use_left:
				if p.position.y > 450.0 and p.position.x > 450.0:
					want["left"] = true
				else:
					want["right"] = true
					if on_floor:
						tap = "jump"
			else:
				if p.position.y > 450.0 and p.position.x < 4340.0:
					want["right"] = true
				else:
					want["left"] = true
					if on_floor:
						tap = "jump"
		else:
			# bajar: andar hasta el centro del hueco más cercano y seguir:
			# la gravedad hace el resto (no saltar dentro del hueco)
			var hx := 1255.0 if absf(p.position.x - 1255.0) < absf(p.position.x - 3325.0) else 3325.0
			want["right"] = hx > p.position.x
			want["left"] = hx <= p.position.x
		p.bot_held = want
		if tap != "" and p.state in [Player.State.IDLE, Player.State.RUN, Player.State.JUMP]:
			p.bot_held[tap] = true
		return
```

## Qué NO hacer

- No toques las ramas de corredor/interceptor/duelo existentes: en las
  arenas 0–2 y en el sim el bot no debe cambiar NI UNA decisión (la rama
  vive entera bajo `arena_id == 3`).
- No cambies la física de salto ni la geometría de la torre.
- No hagas que el CORREDOR bot suba: su ruta válida es el pasillo inferior.
- Si al aplicar el bot se pasa de largo al primer peldaño, ajusta SOLO los
  umbrales (450/4340 de embarque o los puntos de referencia 500/4290) o
  añade `want["jump"] = true` mantenido: no reescribas la rama entera.

## Criterios de aceptación

1. Arena torre (C×3), tú arriba del todo con el paso: el bot interceptor
   camina hasta una escalera, sube los peldaños con saltos y llega al piso
   superior en < 8 s.
2. Con el rival abajo y el bot arriba, el bot camina hasta el hueco más
   cercano y cae al pasillo inferior.
3. En las arenas 0–2 el bot se comporta exactamente igual que antes.
4. Batería completa en verde (smoke, suites y sim no tocan la arena 3).

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/test_runner.tscn
```

Últimas líneas esperadas: `SMOKE OK - todas las mecánicas funcionan` y
`RESULT: ALL PASSED (16)`. Los puntos 1–3 se miran a mano en ventana (no
hay harness de la arena 3; el sim corre en la 0) — es la parte importante
de esta tarea.
