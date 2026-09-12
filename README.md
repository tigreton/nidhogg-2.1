# Nidhogg-like (Godot 4.6)

Duelo de esgrima 2D estilo Nidhogg para 2 jugadores en el mismo teclado.
Un golpe mata: quien mata gana el "paso" y debe correr hasta su meta; el rival
reaparece delante para frenarlo. Primero en llegar 3 veces gana el partido.

## Controles

| Acción | P1 (naranja) | P2 (cian) |
|---|---|---|
| Moverse | A / D | ← / → |
| Saltar / espada en alto | W | ↑ |
| Agacharse / espada baja | S | ↓ |
| Atacar (estancia actual) | F | K |
| Lanzar espada | G | L |
| Revancha (al terminar) | R | R |

| Extras | Tecla |
|---|---|
| Bot P2 (OFF → fácil → normal → difícil) | B |
| Aliado P3 en 2v2 (OFF → fácil → normal → difícil) | H |
| Bot vs bot (todos los duelistas) | N |
| Modo 2v2 por equipos | V |
| Lluvia de rocas (modo caos) | T |
| Música / pausa | M / ESC |

En el aire, el botón de ataque hace una **patada voladora** que derriba al rival.

## Mecánicas

- **Estancias**: alta (W), media (neutral), baja (S). El ataque golpea a la altura de tu estancia.
- **Choque (clash)**: si atacas a la misma altura que defiende el rival, las espadas chocan y ambos salen despedidos.
- **Doble muerte**: si ambos atacáis a alturas distintas a la vez, los dos caéis.
- **Esquiva**: agachado te esquivas los ataques altos; en el aire esquivas los bajos.
- **Rodar y estocada**: con S+W ruedas (cuenta como guarda baja); atacar corriendo hace una estocada con embestida.
- **Lanzar espada**: vuela recta a altura media; el rival la desvía si está en guardia media o atacando. La espada cae y se recoge pasando por encima.
- **Foso central**: caer dentro es muerte. Hay una plataforma para cruzar… y un **puente alto** de madera.
- **Reaparición**: el muerto reaparece cayendo del cielo, delante del corredor y hacia su meta, con 1,3 s de invulnerabilidad.

## El mapa: alturas por zonas

- **Aldea (izquierda)**: una casa con tejado subible en dos faldones, chimenea
  con humo, ventana cálida, valla y antorchas. El muro es decorativo: se pasa
  por la puerta y el tejado se usa como atajo en alto.
- **Hierba alta**: te esconde (el rival no ve tu estancia) con flores.
- **Escalera y puente alto**: tres plataformas suben hasta un puente de madera
  que cruza el foso central por arriba. Ruta arriesgada pero rápida.
- **Zona rocosa (derecha)**: peldaños de piedra, un gran peñasco y una torre
  con gallardete. Tres alturas para emboscar con patadas voladoras.

## Modos de juego

- **Duelo (1v1)**: el clásico. Bot disponible en el P2 con tres dificultades.
- **2v2 (tecla V)**: P1·P3 (naranjas) contra P2·P4 (azules). Los aliados son
  bots (P3 se ajusta con H, P4 sigue la dificultad del bot P2). Sin fuego
  amigo: los ataques, espadas lanzadas y patadas solo afectan al equipo rival.
  Si el portador del paso muere, su compañero vivo hereda la carrera.
- **Lluvia de rocas (tecla T)**: modo caos. Rocas con aviso (diana roja y haz)
  caen del cielo: el impacto directo mata y el golpecito cercano derriba.
  Cuidado también en el puente y los tejados: las rocas caen donde hay suelo.

## Ejecución

Abrir el proyecto con Godot 4.6 y pulsar F5, o desde consola:

```
godot --path . 
```

## Prueba automática (headless)

```
godot --headless --path . res://test/smoke_test.tscn
```

Verifica movimiento, salto, choque de espadas, muerte, paso, meta, marcador,
reinicio de ronda, lanzamiento de espada, las alturas nuevas (peldaño, tejado,
puente), la lluvia de rocas y el modo 2v2.

## Capturas de las zonas

```
godot --path . res://test/screenshots.tscn
```

Guarda PNGs de cada zona en `screens/` (carpeta fuera del repositorio).

## Estructura

- `scenes/main.tscn` + `scripts/game.gd` — nivel, combate, cámara, modos y HUD.
- `scenes/player.tscn` + `scripts/player.gd` — control y dibujo procedural del duelistas.
- `scripts/falling_rock.gd` — roca del modo caos (aviso + caída).
- `scripts/sfx.gd` — efectos de sonido generados por código (sin assets).
- `scripts/sword_projectile.gd`, `scripts/pickup.gd` — espada lanzada y espada caída.
