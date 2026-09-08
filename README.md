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

En el aire, el botón de ataque hace una **patada voladora** que derriba al rival.

## Mecánicas

- **Estancias**: alta (W), media (neutral), baja (S). El ataque golpea a la altura de tu estancia.
- **Choque (clash)**: si atacas a la misma altura que defiende el rival, las espadas chocan y ambos salen despedidos.
- **Doble muerte**: si ambos atacáis a alturas distintas a la vez, los dos caéis.
- **Esquiva**: agachado te esquivas los ataques altos; en el aire esquivas los bajos.
- **Lanzar espada**: vuela recta a altura media; el rival la desvía si está en guardia media o atacando. La espada cae al suelo y se recoge pasando por encima.
- **Foso central**: caer dentro es muerte. Hay una plataforma para cruzar.
- **Reaparición**: el muerto reaparece cayendo del cielo, delante del corredor y hacia su meta, con 1,3 s de invulnerabilidad.

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
reinicio de ronda y lanzamiento de espada.

## Estructura

- `scenes/main.tscn` + `scripts/game.gd` — nivel, combate, cámara, rondas y HUD.
- `scenes/player.tscn` + `scripts/player.gd` — control y dibujo procedural del duelistas.
- `scripts/sfx.gd` — efectos de sonido generados por código (sin assets).
- `scripts/sword_projectile.gd`, `scripts/pickup.gd` — espada lanzada y espada caída.
