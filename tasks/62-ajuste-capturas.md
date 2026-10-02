# Tarea 62 — Ajuste fino visual con capturas y cierre del track arte

**Dificultad:** media · **Archivos:** `scripts/player.gd`, `scripts/game.gd`, `test/screenshots.gd`, `INDICE-MULTIMEDIA.md` · **Prerrequisitos:** tareas 53–60 aplicadas (61 opcional)

## Objetivo

Pase de calidad visual de todo el arte integrado usando capturas reales del
juego: alinear los pies de cada pose, cuadrar proporciones (gusano, bordes de
foso), resolver costuras del parallax, y actualizar la documentación del
índice multimedia con lo que queda integrado y lo que sigue sin usar.

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). Las capturas se sacan con
  `test/screenshots.tscn` (CON render, no headless):

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --path . res://test/screenshots.tscn
```

  deja PNG en `screens/` (el test imprime `CAPTURAS OK`).
- El renderer de personajes (tarea 60) dibuja cada pose anclada por los pies
  con dos constantes: `POSE_SCALE` (58/56) y `POSE_FEET_Y` (32). Si una pose
  concreta flota o se hunde, se corrige con un mapa de offsets por pose.
- `INDICE-MULTIMEDIA.md` §8 ("Cómo usarlo en Nidhogg 2.1") describe el estado
  de llegada del arte: hay que actualizarlo al estado real tras integrar.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en
  español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Ampliar las capturas

En `test/screenshots.gd`, añade al repertorio (siguiendo el patrón de las
existentes: teletransportar jugadores con `position`, forzar `state`/`stance`,
esperar unos frames y llamar a `_snap("nombre")`):

- `accion_alta` / `accion_media` / `accion_baja`: los dos jugadores en
  `State.ATTACK` con `attack_height` 2/1/0.
- `carrera`: ambos en `State.RUN` con `run_phase` 0, π/2, π y 3π/2 (4
  capturas, una por fase del ciclo).
- `derribado_muerte`: uno en `State.KNOCKDOWN` y un `Corpse` recién creado.
- `desarmado` (si la 61 está aplicada): `has_sword = false` en idle y
  carrera.

### 2. Alineación de pies por pose

Abre las capturas y revisa una a una: los pies deben tocar el suelo en idle,
carrera, salto/aterrizaje, agachado y ataques; las poses tumbadas (`dead`,
`downed`) deben reposar en el suelo sin flotar. Si una pose concreta desentona,
añade en `player.gd` un mapa de corrección y aplícalo en `_draw()`:

```gdscript
# corrección vertical por pose (px, + baja el sprite)
const POSE_Y_FIX := {
	"downed": 2.0,
}
```

y en `_draw()`, al calcular el rectángulo (las claves del mapa son nombres de
pose sin sufijo; funciona igual con o sin la tarea 61):

```gdscript
	var feet := POSE_FEET_Y + float(POSE_Y_FIX.get(_pose_name(), 0.0))
	draw_texture_rect(tex, Rect2(-w * 0.5, feet - h, w, h), false, tint)
```

Ajusta también si hace falta el factor de ciclo de carrera
(`run_phase * 2.0 / PI`) si el ritmo de 4 frames se ve a tirones — sobre todo
si las tareas 43/44 del porteo recalibraron la física después de la 60.

### 3. Escenario

Con capturas de las tres arenas (tecla C):

- **Parallax** (tarea 58): busca costuras verticales; si aparecen, prueba
  `motion_mirroring` de 2304 con `s.position.x = -576.0`, o baja un 10% el
  `modulate` de `bg_layer1` para diferenciar planos.
- **Bordes de foso** (tarea 57): comprueba que `pit_edge` no tape los pies al
  caminar por el borde (si lo hace, baja su `z_index` a -6 o súbelo 4 px).
- **Gusano** (tarea 59): proporción respecto al ganador (debe envolverlo);
  ajusta la escala de las regiones si domina la pantalla o queda fino.
- **Título** (tarea 54): contraste del texto sobre la ilustración.

### 4. Cerrar documentación

- Actualiza `INDICE-MULTIMEDIA.md` §8: marca qué assets están ya integrados
  (con la tarea que lo hizo) y cuáles siguen sin usar
  (`player_throw`/`slide` hasta sus tareas, resto según `PLAN-ARTE.md`).
- Si surgió algún ajuste relevante (offsets, costuras), añádelo como nota en
  la sección de conflictos de `PLAN-ARTE.md`.

## Qué NO hacer

- No cambies gameplay, física ni colisiones para "arreglar" un problema
  visual: el humo es siempre del dibujo (offsets, escalas, z_index).
- No regeneres sprites en esta tarea: si una pose es insalvable, anótala en
  `PLAN-ARTE.md` como candidata a regeneración y sigue.
- No borres capturas antiguas de `screens/`: son el histórico de comparación.

## Criterios de aceptación

1. Las capturas nuevas existen y en ninguna pose el personaje flota, se
   hunde o queda desencajado del suelo.
2. Las tres arenas se ven correctas en captura: parallax sin costuras
   evidentes, bordes de foso integrados, tintes diferenciados.
3. `INDICE-MULTIMEDIA.md` refleja el estado real de integración.
4. `CAPTURAS OK` en el test de capturas y `SMOKE OK` en el headless.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --path . res://test/screenshots.tscn
```

Últimas líneas esperadas: `SMOKE OK - todas las mecánicas funcionan` y
`CAPTURAS OK`.
