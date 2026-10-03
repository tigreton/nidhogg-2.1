# Investigación: mecánicas de Nidhogg 2 (base de diseño del clon)

> Consolidado a partir de: análisis visual de las 7 capturas oficiales de Steam
> (`media/screenshots/`), los 2 tráilers oficiales (`media/videos/`) y ~60 fuentes de
> texto (wiki Fandom, guías de Steam/GameFAQs, reviews de Ars Technica, Rock Paper
> Shotgun, PC Gamer, Eurogamer, Gaming Nexus, hilos de Steam Community y Reddit).
> Donde las fuentes se contradicen se indica explícitamente.

## 1. Reglas de partida (estructura tug-of-war)

- **Arena de pantallas encadenadas en horizontal**. Nidhogg 1 tenía **5 pantallas**;
  Nidhogg 2 tiene **7** (1 central + 3 por lado, confirmado por múltiples reviews y por el
  HUD de 7 cuadros visible en las capturas). Ambos jugadores **empiezan en la pantalla
  central**, armados, cara a cara, **sin cuenta atrás**.
- **Derecho de avance ("la flecha")**: al matar aparece una flecha grande en pantalla con
  tu color y dirección; **solo el portador puede cruzar el borde** de la sección hacia su
  meta. Matar no da puntos: es una táctica de retraso ("no points for killing… it's more a
  delaying tactic"). Con la flecha puedes pasarte de largo al rival vivo sin pelear.
- **Respawn**: la víctima reaparece a los **~2–3 s** (N1: ~5 s; la comunidad cita ~2,5 s
  para N2) **en la pantalla actual, por delante del corredor**, entre él y la salida que
  ataca, con la **siguiente arma del ciclo** y en **postura media**. El respawn es
  predecible: los jugadores cronometran flechas para que lleguen justo al reaparecer.
- **Sin progreso guardado**: si el defensor mata al corredor, la flecha cambia de dueño y
  el avance se recorre físicamente en la dirección contraria.
- **Victoria**: al cruzar el borde final de tu lado, el gusano Nidhogg baja y **devora al
  ganador** (ser comido ES ganar). La última pantalla suele tener público animándote.
- **Timer**: por defecto no hay; opcional (p. ej. 3:00). Al agotarse → **sudden death**:
  duelo de una sola pantalla, el próximo kill gana.
- **HUD**: fila de cuadros arriba-centro (uno por pantalla; se rellenan en el color del
  atacante hacia su meta, con cabecitas de gusano en los extremos en N2) + flecha grande
  dibujada a mano en el color del atacante.

## 2. Sistema de combate general

- **Un golpe = una muerte.** No hay barras de vida. Puños/patadas solo derriban, desarman
  y aturden (~0,5 s el neck-snap en N1).
- **Tres alturas** de golpe y guarda: alta (cabeza), media (torso), baja (piernas). Se
  cambian con Arriba/Abajo. La parada es automática por posición: mantener el arma a la
  altura de la estocada entrante la bloquea (ambos retroceden). No hay piedra-papel-tijera
  duro ("there's no hard-coded system of counters").
- **Empalamiento**: florete y daga dejan el cadáver clavado en la hoja; puedes mover la
  hoja arriba/abajo con el cuerpo puesto (logro "Memories"). La espada larga NO empala.
- **Blade pasivo**: quien corre/rueda/salta contra tu punta extendida muere sin que
  pulses nada. La guardia baja empala rodando; la alta bloquea armas lanzadas y destripa
  saltadores.
- **Correr guarda el arma** brevemente → ventana vulnerable (no puedes bloquear).
- **Giro automático**: si el rival te pasa corriendo, tu personaje se gira solo.
- **Desarme** (vías confirmadas): cruzar tu hoja sobre la del rival pasada la mitad
  (fácil contra estocadas), el peso de la espada larga, patada/puñetazo bien posicionado,
  dive kick (en N2 ambos caen y la víctima queda desarmada), slide-kick.
- **Stomp**: sobre un rival derribado, pisarle la cabeza lo mata (eres invulnerable
  mientras lo haces). Es el reemplazo N2 del neck-snap.

## 3. Las cuatro armas

Ciclo al morir (orden por defecto, editable en reglas): **florete → espada larga → daga →
arco**. "Kill your opponent and he or she will spawn with the next weapon in line" (RPS).
Suicidarse para cambiar de arma es táctica legítima (Ars Technica lo compara con
intencionar base por bolas).

| Propiedad | Florete (rapier) | Espada larga (broadsword) | Daga | Arco |
|---|---|---|---|---|
| Alturas | alta/media/baja | **solo alta/baja** (sin media) | alta/media/baja | apunta a 3 alturas |
| Velocidad | media | la más lenta | la más rápida (ataque, cambio de postura, lanzamiento) | tensado ~1 s |
| Alcance | medio (mayor alcance de estocada frontal según Ars) | el mayor (barridos amplios) | el más corto | ilimitado (flecha lenta) |
| Mata de un golpe | sí (empala) | sí (o desarma) | sí (empala) | sí |
| Lanzada | recta; golpea alto+medio | girando; golpea alto+medio | rapidísima; **solo golpea alto** (cabeza) — la más difícil de bloquear | derriba, NO mata |
| Peculiaridades | mejor arma defensiva; contrarresta la mayoría de ataques | sin postura media = débil a estocadas al estómago y flechas medias; el swing puede reflejar flechas | corres más rápido con ella; el arma híbrida melee/distancia; contrarresta flechas | no puede guardar/bloquear; si la flecha choca con un arma a su altura, **rebota hacia el tirador y puede matarlo** |

Detalles del **arco**:

- Munición ilimitada ("no limit to how many arrows you have"); un toque corto solo tensa,
  mantener ~1 s y soltar dispara. Se puede mantener tensada la flecha lista.
- 3 alturas de apuntado: agachado = baja; de pie = media (cuidado: **los rivales
  reaparecen en postura media**, así que las flechas medias rebotan con frecuencia);
  agachado + saltito = disparo a la cabeza.
- La flecha vuela recta y lenta (esquivable a larga distancia); se clava en terreno y
  puertas; **rebota** al chocar con un arma quieta a su altura y cada rebote la frena
  (tras ~6 ping-pongs se para en el aire, según la comunidad); puede matar al tirador
  (logro "Self Sacrifice"). Hasta desarmado puedes reflejar flechas con timing de patada.
- Se puede tensar en pleno dive-kick y disparar al levantarte (wiki Fandom).

Detalles de la **espada larga** (contradicción documentada): quieto parece deflectar
proyectiles pasivamente, pero al moverse lo pierde — la comunidad discute si es bug o
intencional ("no passive hitbox"). Para el clon: solo el swing activo refleja.

## 4. Desarmado (puños/patadas — "Foot")

- **Corres más rápido sin arma** (y también con la daga). Las patadas son más rápidas que
  cualquier arma.
- **Puñetazo/patada**: desarma y aturde ~0,5 s; arriesgado (te puedes ensartar en su
  arma). En N2 el puñetazo de N1 fue reemplazado por patada de pie (snap kick).
- **Patada baja** (agachado + ataque) y **slide-kick** (desde rodada): derriban.
- **Dive kick** (ataque en el aire, no con arco): baja a ~45°; en N2 **ambos caen** y la
  víctima queda desarmada (en N1 solo caía la víctima). Si el rival tiene la punta alta,
  te ensartas.
- **Stomp letal** sobre caído; invulnerable mientras lo ejecutas.
- Se puede **patear el arma** fuera de las manos del rival y **reflejar flechas** con la
  patada.

## 5. Movimiento

- **Correr**: mantener dirección; pivote prácticamente instantáneo; el arma se guarda
  brevemente (ventana vulnerable).
- **Salto**: altura fija (~1 personaje; con carrerilla ~2,5), más flotado tipo Mario en
  N2. Existe el roll-jump (saltar desde agachado, cuerpo encogido, pasa por túneles y
  sobre hojas bajas/medias).
- **Rodar/deslizarse**: Abajo mientras corres = roll; ataque durante el roll = slide
  tackle (derriba, pasa bajo armas lanzadas y guardias altas; **recoge armas del suelo a
  mitad de deslizamiento**). La guardia baja enemiga empala al que rueda.
- **Recoger armas**: Abajo sobre un arma caída, o rodar/pasar deslizándote sobre ella.
  Las armas caídas persisten y cualquiera puede cogerlas ("different weapons littering
  the floor").
- **Levantarse tras caída**: Arriba = in situ; lateral = rodando (te re-arma si ruedas
  sobre un arma). Mientras estás caído te pueden stompear.
- **Lanzar arma**: Arriba + Ataque; vuela recta sin gravedad hasta matar/ser parada/chocar
  muro; te deja desarmado. La guardia alta la bloquea; te puedes agachar para esquivarla.
- **Muros (N1, heredado en parte)**: wall-cling, wall-run y wall-jump estilo Prince of
  Persia. No crítico para el clon.
- **Sin agarres cuerpo a cuerpo** documentados: las "tomas" se hacen con patadas, dives y
  el impale.

## 6. Niveles y hazards (N2, 13 mapas)

Castle, Ocean/Pax Place, Beach, Office, Wilds, Airship, Winter, Swamp, Dungeon, Clouds,
Train, Volcano, Club. Filosofía de diseño de Messhof: **nada del entorno te mata
directamente** (los fosos son la excepción clásica) — los hazards ocultan información
(hierba alta, cascadas, muros divisorios), restringen movimientos (puertas, techos bajos
que anulan lanzamientos y dive kicks) o te empujan (cintas transportadoras del Volcano/
Airship). Ejemplos: plataformas de hielo que se hunden (Winter), picadoras de carne
(Airship), túneles en silueta (Swamp/Club), puentes donde las armas caídas se pierden para
siempre (Beach/Wilds).

## 7. Controles oficiales (referencia)

- Esquema de **dos botones** (salto + ataque) + direcciones para mover/cambiar postura.
- Teclado (heredado de N1, remapeable): **P1** = W/A/S/D + F ataque + G salto;
  **P2** = Flechas + Numpad0 ataque + NumpadDecimal salto.
- Gamepad: stick/cruceta mueve y cambia postura; dos botones frontales = salto/ataque;
  Arriba+ataque = lanzar. Soporte completo de mando, 2 jugadores con teclado+mando.

## 8. Contradicciones entre fuentes (sin resolver)

1. **Pantallas por arena**: 4 por dirección según el wiki (Castle/Beach/Train descritos en
   4) vs 7 totales según reviews ("seven screens") — reconciliación: 1 central + 3 por
   lado = 7 en total, cada jugador cruza 4. N1 tenía 5. **Nuestro juego usa 5 (petición
   del usuario).**
2. **Hitbox pasiva de la espada larga**: "quieto deflecta todo" vs "no tiene hitbox
   pasiva, es intencional". Decisión de diseño: solo swing activo.
3. **Arma al respawn**: ciclo fijo (RPS/Ars/AMA de Messhof) vs "aleatorio" (Xbox Tavern).
   Gana el ciclo (fuente primaria del propio dev).
4. **Puños vs patadas en N2**: "el puñetazo fue reemplazado por patada" (Steam) vs fuentes
   que siguen diciendo "fists". Implementamos ambos (puñetazo ràpido + patadas).
5. **Alturas del arco**: 3 (Gaming Nexus, verificado) vs 2. Gana 3.
6. **Atrapar flechas con la mano**: solo fuentes comunitarias, sin confirmación. Lo
   dejamos fuera; sí implementamos el reflejo con arma/patada.
7. **Respawn exacto en segundos**: no hay cifra pública; "un par de segundos" (N2).
   **Nuestro juego usa 2,0 s fijos (petición del usuario).**

## 9. Chuleta numérica para el clon

| Parámetro | Valor en N2 (documentado/estimado) | Valor en nuestro juego |
|---|---|---|
| Pantallas por partida | 7 (1 central + 3/lado) | **5** |
| Respawn | ~2–3 s | **2,0 s** |
| Postura al reaparecer | media | media |
| Arma al reaparecer | siguiente del ciclo (florete→espada→daga→arco) | igual |
| Alturas de golpe | 3 (espada larga: 2) | igual |
| Tensado del arco | ~1 s | 1,0 s |
| Aturdimiento de patada | ~0,5 s | 0,5 s |
| Dive kick | ~45°, ambos caen, víctima desarmada | igual |
| Velocidad de flecha | lenta (esquivable) | 600 px/s |
| Rebote de flecha | −velocidad por rebote, ~6 rebotes = parada | −15% por rebote |

## 10. Fuentes principales

- Wiki Fandom de Nidhogg: nidhogg.fandom.com (Dagger, Rapier, Sword, Bow, Foot, Weapons in
  Nidhogg 2, Maps in Nidhogg 2, achievements).
- Guía "Nidhogg Technique" (Steam Community, base N1) y Move List de GameFAQs.
- Reviews: Ars Technica, Rock Paper Shotgun (review + artículo de fighting games +
  entrevista a Messhof), PC Gamer (review + preview 2016), Eurogamer, Gaming Nexus,
  IGN, Nintendo World Report, WayTooManyGames, Lifeisxbox, TechRaptor, Videochums
  (guía de logros con descripciones mecánicas), XBLA Fans, A.V. Club, GameCritics.
- ClickBliss — "What's new in Nidhogg 2" (el desglose mecánico más fino).
- Hilos de Steam Community: "Weapon Experiments: What does the dagger even do?",
  "What I saw.", "Bow thoughts?", "minor bugs with the bow".
- Reddit: r/nidhogg "Tips and Tricks" (respawn ~2,5 s, slide recoge armas), AMA de
  Messhof en r/PS4.
- Página oficial: messhof.com/nidhogg2 · Steam: store.steampowered.com/app/535520.
- Análisis visual propio de las 7 capturas 1080p y 2 tráilers oficiales (ver README.md).
