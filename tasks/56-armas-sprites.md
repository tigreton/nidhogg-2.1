# Tarea 56 — Armas sueltas con sprites: caída, lanzada, flecha y arco

**Dificultad:** baja · **Archivos:** `scripts/pickup.gd`, `scripts/sword_projectile.gd`, `scripts/arrow.gd`, `scripts/player.gd` · **Prerrequisitos:** que existan `weapon_*.png` (ya importados)

## Objetivo

Todas las armas "fuera de la mano" pasan a sprite: el arma caída que se
recoge (`pickup.gd`), el arma lanzada volando (`sword_projectile.gd`), la
flecha del arco (`arrow.gd`) y el arco que sostiene el jugador
(`_draw_bow()` en `player.gd`). El arma **en mano** no se toca en esta tarea:
la espada va horneada en las poses del personaje (ver `PLAN-ARTE.md`).

## Contexto del proyecto (leer antes de tocar nada)

- Juego **Godot 4.6** (GDScript). El ciclo de armas es `florete → espada →
  daga → arco` (`GameConfig.WEAPON_ORDER` en `game_config.gd`), con
  `weapon_id` como clave en todos los scripts.
- Sprites disponibles (miran a la derecha, filo horizontal):
  `weapon_rapier.png` (90×9, florete), `weapon_longsword.png` (120×9,
  espadón), `weapon_dagger.png` (55×8, daga), `weapon_bow.png` (38×70,
  vertical), `weapon_arrow.png` (28×6).
- `scripts/pickup.gd` — `SwordPickup._draw()`: aura pulsante con `draw_arc`
  (se conserva) + la espada con 4 `draw_line` y un `draw_set_transform` de
  rotación -0.25.
- `scripts/sword_projectile.gd` — `_draw()`: espada con líneas; el nodo
  entero ya rota con `rotation += spin * delta` y arrastra una estela
  `Line2D` con gradiente (se conserva). `z_index = 15`.
- `scripts/arrow.gd` — `_draw()`: flecha con líneas; `tint()` oscurece con
  cada rebote (`bounces`); la dirección la da `vel.x`.
- `scripts/player.gd` — `_draw_bow()` (~línea 479): dibuja el arco con
  `draw_arc` más la cuerda y la flecha enganchada según `bow_time` (0..1).
  La cuerda y la flecha nocked **se conservan**: solo se sustituye el arco.
- Reglas de estilo: GDScript tipado, indentación con **tabs**, comentarios en
  español.
- Al terminar SIEMPRE ejecutar desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea tiene que ser `SMOKE OK - todas las mecánicas funcionan`.

## Instrucciones paso a paso

### 1. Tabla de texturas (una por script que la necesite)

Añade esta constante al inicio de `pickup.gd`, `sword_projectile.gd` y
`arrow.gd` (solo esta última usará `weapon_arrow`):

```gdscript
const WEAPON_TEX := {
	"florete": preload("res://art/sprites/weapon_rapier.png"),
	"espada": preload("res://art/sprites/weapon_longsword.png"),
	"daga": preload("res://art/sprites/weapon_dagger.png"),
	"arco": preload("res://art/sprites/weapon_bow.png"),
}
```

### 2. Arma caída (`pickup.gd`)

En `_draw()` de `SwordPickup`, conserva el aura y sustituye las cuatro líneas
de la espada (y su transform) por la textura centrada y ligeramente rotada:

```gdscript
func _draw() -> void:
	var a := 0.22 + 0.1 * sin(t * 5.0)
	draw_arc(Vector2.ZERO, 17.0 + 1.5 * sin(t * 5.0), 0.0, TAU, 24, Color(1, 1, 1, a), 2.0)
	draw_set_transform(Vector2.ZERO, -0.25, Vector2(0.8, 0.8))
	var tex: Texture2D = WEAPON_TEX.get(weapon_id, WEAPON_TEX["florete"])
	draw_texture(tex, -tex.get_size() * 0.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
```

(El arco caído se dibuja igual: la textura vertical rota -0.25 queda
"tumbada" en el suelo.)

### 3. Arma lanzada (`sword_projectile.gd`)

En `_draw()` de `SwordProjectile`, sustituye las líneas por la textura
centrada (la rotación del nodo ya la hace girar; la estela no se toca):

```gdscript
func _draw() -> void:
	var tex: Texture2D = WEAPON_TEX.get(weapon_id, WEAPON_TEX["florete"])
	var w := tex.get_width() * 0.8
	var h := tex.get_height() * 0.8
	draw_texture_rect(tex, Rect2(-w * 0.5, -h * 0.5, w, h), false)
```

### 4. Flecha (`arrow.gd`)

Sustituye `_draw()` completo; el volteo se hace con escala X negativa y el
tinte por rebotes pasa a ser el `modulate` del `draw_texture_rect`:

```gdscript
const ARROW_TEX := preload("res://art/sprites/weapon_arrow.png")

func _draw() -> void:
	var dir := 1.0 if vel.x >= 0.0 else -1.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1.0))
	draw_texture_rect(ARROW_TEX, Rect2(-14.0, -3.0, 28.0, 6.0), false, tint())
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
```

(`tint()` se conserva tal cual.)

### 5. Arco en mano (`player.gd`)

En `_draw_bow()`, sustituye el `draw_arc` del arco por la textura (la cuerda
y la flecha nocked de después se quedan igual):

```gdscript
const TEX_BOW := preload("res://art/sprites/weapon_bow.png")

func _draw_bow() -> void:
	var c := color if flash_time <= 0.0 else Color.WHITE
	var dark := Color(0.05, 0.04, 0.08)
	var pull := 0.0 if bow_time <= 0.0 else clampf(bow_time, 0.0, 1.0)
	draw_set_transform(Vector2(8, -8), 0.0, Vector2(0.55, 0.55))
	draw_texture(TEX_BOW, -TEX_BOW.get_size() * 0.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var py := -8.0
	var px := 8.0 - pull * 12.0
	... (la cuerda y la flecha enganchada, sin cambios)
```

Ajusta las X de la cuerda (8.0 ± 14.0) si al verla en juego la cuerda no
toca los extremos del sprite: el arco texturizado mide ~21×38 px a escala
0.55 centrado en (8, -8).

## Qué NO hacer

- No toques la lógica de rebotes/impactos ni las velocidades: solo cambia el
  dibujo.
- No borres la estela del proyectil ni el aura del pickup.
- No modifiques `_draw()` del personaje (la espada en mano se trata en la
  tarea 60) ni `GameConfig`.

## Criterios de aceptación

1. Al desarmar o lanzar, el arma caída del suelo es el sprite correcto de su
   `weapon_id` (florete/espadón/daga/arco se distinguen a simple vista).
2. El arma lanzada vuela girando con su sprite y conserva la estela.
3. La flecha del arco usa `weapon_arrow.png`, se voltea según dirección y se
   oscurece un poco con cada rebote.
4. Con el arco equipado, el personaje sostiene el sprite del arco y al tensar
   la cuerda sigue arrastrando la flecha.
5. El smoke test termina en `SMOKE OK`.

## Verificación

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

Última línea esperada: `SMOKE OK - todas las mecánicas funcionan`.
Y una pasada con render: lanzar cada arma del ciclo (matar avanza el ciclo)
y tensar el arco.
