# Nidhogg-like (Godot 4.6)

Duelo de esgrima 2D estilo Nidhogg 2 para 2 jugadores en el mismo teclado.
Un golpe mata: quien mata gana el "paso" y debe correr hasta su meta; el rival
reaparece delante para frenarlo. Primero en llegar 3 veces (configurable) gana
el partido.

## Controles

| Acción | P1 (naranja) | P2 (cian) |
|---|---|---|
| Moverse | A / D | ← / → |
| Saltar / espada en alto | W | ↑ |
| Agacharse / espada baja | S | ↓ |
| Atacar (estancia actual) | F | K |
| Lanzar espada / tensar arco | G | L |
| Revancha (al terminar) | R | R |

| Extras | Tecla |
|---|---|
| Bot P2 (OFF → fácil → normal → difícil) | B |
| Aliado P3 en 2v2 (OFF → fácil → normal → difícil) | H |
| Bot vs bot (todos los duelistas) | N |
| Modo 2v2 por equipos | V |
| Lluvia de rocas (modo caos) | T |
| Cambiar de arena | C |
| Modo pantallas (secciones con rejas) | P |
| Modo arcade (escalera de bots) | Y |
| Modo copa (semifinales + final) | O |
| Música / pausa | M / ESC |
| **Menú ONLINE (1v1 por red)** | O (en el título) |

En el aire, el botón de ataque hace una **patada voladora** que derriba al rival.

## Online (1v1 por red)

Desde el título, **O** abre el menú online: `1` crea la partida (eres P1,
anfitrión; se muestran tus IPs LAN) y `2` se une a una IP (eres P2). El
anfitrión es la autoridad: su simulación manda, el cliente predice su propio
jugador y el marcador, bajas y rondas viajan por ENet (puerto 24565). Detalles
y decisiones en `docs/online-netcode.md`. En partida online se juega el 1v1
puro (sin bots ni modos extra, sin pausa ESC).

## Mecánicas

- **Estancias**: alta (W), media (neutral), baja (S). El ataque golpea a la altura de tu estancia.
- **Choque (clash)**: si atacas a la misma altura que defiende el rival, las espadas chocan y ambos salen despedidos (el que ataca en alto pierde el arma).
- **Doble muerte**: si ambos atacáis a alturas distintas a la vez, los dos caéis.
- **Esquiva**: agachado te esquivas los ataques altos; en el aire esquivas los bajos.
- **Rodar y estocada**: con S+W ruedas (cuenta como guarda baja); atacar corriendo hace una estocada con embestida.
- **Dive horizontal**: corriendo, S+W lanza un vuelo rasante letal que cruza fosos; al acabar caes derribado.
- **Sidekick**: corriendo con espada, S+F lanza una patada lateral que derriba y desarma; tú rebotas hacia atrás.
- **Stomp**: ponte encima de un rival derribado y mantén abajo para rematarlo.
- **Juego desarmado**: el puñetazo de pie DESARMA (y el rival ya no tiene guarda media que le frene), la patada baja derriba y corres un 15 % más rápido. La patada voladora también suelta el arma de la víctima.
- **Guardia pasiva**: parado con el arma en guardia, quien corre contra ti a otra altura se empala y muere (correr no guarda: el arma solo mata por sí sola si estás parado).
- **Lanzar espada**: vuela recta; el rival la desvía si está en guardia media o atacando. La espada cae y se recoge pasando por encima.
- **Foso central**: caer dentro es muerte. Hay una plataforma para cruzar… y un **puente alto** de madera.
- **Reaparición**: el muerto reaparece cayendo del cielo, delante del corredor y hacia su meta, con 1,3 s de invulnerabilidad.

## Armas con ciclo de muerte

Al morir reapareces con la SIGUIENTE arma del ciclo **florete → espadón → daga →
arco** (y la que llevabas cae al suelo, donde cualquiera puede recogerla):

| Arma | Rasgos |
|---|---|
| **Florete** | Equilibrado, como la espada clásica. |
| **Espadón** | Lento y largo, sin guarda media (neutro = baja) y sus golpes DESARMAN en vez de clavar. |
| **Daga** | Rapidísima y corta; corres un 15 % más con ella y su lanzamiento solo mata en alto. |
| **Arco** | Mantén atacar para tensar (máx 1 s) y suelta una flecha a tu altura: mata a otra altura, rebota en la guardia igual y tras un rebote mata a cualquiera. |

## Gore y presentación

- **Sangre**: cada muerte deja un charco persistente que gotea (máx 200, FIFO).
- **Cadáveres**: el cuerpo sale despedido girando y queda tumbado; con armas de
  hoja queda **empalado** en la espada del asesino hasta que da un tajo o muere.
- **Gusano de victoria**: al cerrar el partido, el gusano gigante baja y envuelve
  al ganador antes de las estadísticas.
- **Estela**: la espada lanzada deja un rastro de su trayectoria.
- **HUD**: cartel **¡FIGHT!** al empezar la ronda, halo del portador del paso,
  aviso "¡CORRE!", barra de reaparición y (en pantallas) fila de pips.

## Los mapas: alturas por zonas (tecla C para cambiar)

**Ruinas de Medianoche** — noche azulada con luna:

- **Aldea (izquierda)**: una casa con tejado subible en dos faldones, chimenea
  con humo, ventana cálida, valla y antorchas. El muro es decorativo: se pasa
  por la puerta y el tejado se usa como atajo en alto.
- **Hierba alta**: te esconde (el rival no ve tu estancia) con flores.
- **Escalera y puente alto**: tres plataformas suben hasta un puente de madera
  que cruza el foso central por arriba. Ruta arriesgada pero rápida.
- **Zona rocosa (derecha)**: peldaños de piedra, un gran peñasco y una torre
  con gallardete. Tres alturas para emboscar con patadas voladoras.

**Templo del Alba** — amanecer cálido con sol:

- **Torre y peñasco a la izquierda**: la zona alta está junto a la meta de P2.
- **Casa junto a la meta derecha** y un foso pequeño que cruzar de un salto.
- Mismo puente alto sobre el foso central: domina la carrera por arriba.

**Cripta del Ocaso** — atardecer púrpura con luna naranja baja:

- **Torre a la izquierda y casa a la derecha**, foso pequeño junto a la meta de P1.
- Velas fantasmales con llama verde y lápidas decorativas.

## Modos de juego

- **Duelo (1v1)**: el clásico. Bot disponible en el P2 con tres dificultades.
- **2v2 (tecla V)**: P1·P3 (naranjas) contra P2·P4 (azules). Los aliados son
  bots (P3 se ajusta con H, P4 sigue la dificultad del bot P2). Sin fuego
  amigo: los ataques, espadas lanzadas y patadas solo afectan al equipo rival.
  Si el portador del paso muere, su compañero vivo hereda la carrera.
- **Lluvia de rocas (tecla T)**: modo caos. Rocas con aviso (diana roja y haz)
  caen del cielo: el impacto directo mata y el golpecito cercano derriba.
  Cuidado también en el puente y los tejados: las rocas caen donde hay suelo.
- **Pantallas (tecla P)**: el nivel se trocea en 7 secciones con rejas. Solo se
  abre la reja que el portador del paso va a cruzar; al cruzar, la sección
  queda conquistada (fila de pips arriba) y los rivales vivos pasan al fondo.
- **Arcade (tecla Y)**: escalera infinita contra bots. Cada partido ganado sube
  el nivel, la dificultad (fácil → normal → difícil) y rota la arena; perder
  termina la escalera.
- **Copa (tecla O)**: semifinal P1 vs BOT, semifinal P2 vs BOT y final entre
  los supervivientes (bot en nivel normal).

## Pantalla de título

Al arrancar se ve el título con los controles y las reglas configurables:

- **1 / 3 / 5**: puntos para ganar el partido.
- **T**: activar/desactivar lanzar el arma. **R**: activar/desactivar rodar.
- **Z / X**: aspecto de P1 (peinado y piel). **N / M**: aspecto de P2.
- **ENTER o ESPACIO**: empezar a jugar.

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
puente), la lluvia de rocas, el modo 2v2, el cambio de arena, el ciclo de
armas, el arco, el modo pantallas y su HUD, stomp, desarmado, dive, sidekick,
sangre, cadáveres, gusano de victoria, estela, la tercera arena, la guardia
pasiva, el arcade y la copa.

## Capturas de las zonas

```
godot --path . res://test/screenshots.tscn
```

Guarda PNGs de cada zona en `screens/` (carpeta fuera del repositorio).

## Estructura

- `scenes/title.tscn` + `scripts/title.gd` — pantalla de título y reglas.
- `scripts/match_rules.gd` — reglas configurables del partido (estáticas).
- `scenes/main.tscn` + `scripts/game.gd` — nivel, combate, cámara, modos y HUD.
- `scenes/player.tscn` + `scripts/player.gd` — control y dibujo procedural del duelistas.
- `scripts/game_config.gd` — stats de las armas y orden del ciclo de muerte.
- `scripts/arrow.gd` — flecha del arco (rebotes y clavado).
- `scripts/falling_rock.gd` — roca del modo caos (aviso + caída).
- `scripts/sfx.gd` — efectos de sonido generados por código (sin assets).
- `scripts/sword_projectile.gd`, `scripts/pickup.gd` — espada lanzada (con estela) y espada caída.
