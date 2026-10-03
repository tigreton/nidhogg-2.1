# Diseño de personajes — Nacho y Rodrigo

> Diseños de los dos duelistas del juego, basados en los niños de las fotos de
> referencia (sesión 2026-09-06). Estilo: **pixel art grotesco-colorido tipo
> Nidhogg 2** (esgrimistas esbeltos, caras expresivas, paletas limitadas).
> Generado con `bl image edit` (modelo `wan2.7-image`) usando 2-3 fotos de cada
> niño como referencia de parecido.

## Fichas de personaje

### Nacho — P1 (azul eléctrico)

| Campo | Valor |
|---|---|
| Referencia | El niño moreno de las fotos (pelo oscuro + gafas). |
| Edad / cuerpo | 10 años, esbelto, proporciones estiradas estilo Nidhogg. |
| Pelo | Corte casquete/mop-top castaño oscuro. |
| Señal de identidad | **Gafas rectangulares con lentes transparentes** y montura oscura, ojos visibles a través del cristal. |
| Expresión | Seria, concentrada; en victoria, rapier en alto. |
| Vestuario | Túnica azul eléctrico sobre camisa blanca de manga larga, pantalón corto beige, zapatillas azules, guante de esgrima marrón. |
| Arma característica | **Florete** (fino, estocada profunda). |
| Paleta | Azul eléctrico + blanco + beige. |
| Color de jugador | Azul eléctrico → sangre, pips del HUD, flecha y tinte del sprite. |

### Rodrigo — P2 (rojo/naranja)

| Campo | Valor |
|---|---|
| Referencia | El niño rubio de las fotos. |
| Edad / cuerpo | 8 años, mejillas redondas, complexión un poco más compacta. |
| Pelo | Rubio con flequillo recto. |
| Expresión | Sonrisa grande y alegre incluso combatiendo. |
| Vestuario | Túnica roja y naranja con cinturón de cuero marrón, pantalones cargo caqui, zapatillas azul oscuro, hombrera pequeña. |
| Arma característica | **Espada larga a dos manos** (descansada al hombro, golpes amplios). |
| Paleta | Rojo + naranja + caqui. |
| Color de jugador | Rojo → sangre, pips del HUD, flecha y tinte del sprite. |

## Archivos generados (`media/personajes/`)

| Archivo | Qué es |
|---|---|
| `nacho_hoja.png` | **Definitiva.** Hoja de Nacho: 3 poses (idle en guardia, estocada, victoria) + caption "NACHO". |
| `nacho_hoja_v1_descartada.png` | Primera versión descartada: las gafas se leían como visor/banda azul sin ojos visibles. Conservada en el historial de git como `media/personajes/nacho_hoja.png` del commit `9d42f23` ("hoja basica de personajes"). |
| `rodrigo_hoja.png` | Hoja de Rodrigo: 3 poses (guardia con espada al hombro, espadazo horizontal, victoria) + caption "RODRIGO". |
| `duelo_versus.png` | Key art 16:9 del duelo (salón gótico, cartel "¡FIGHT!", HUD de 5 cuadros azul/huecos rojos) usando ambas hojas como referencia. |

Parámetros de generación (reproducibles): modelo `wan2.7-image`, `--size 3:4`
(hojas) / `16:9` (duelo), `--watermark false`, 2-3 imágenes de referencia por
personaje. Sin semilla fija — regenerar implica nueva variación.

## Relación con el plan (`PLAN.md` §4)

- Estas hojas son **arte conceptual**: definen silueta, paleta y señal de
  identidad de cada niño para validar parecido y estilo.
- La hoja de **poses de juego** (idle, correr ×4, salto, caída, agachado,
  slide, dive kick, estocadas alta/media/baja, lanzar, derribado, muerto) se
  generará en la **fase 8** partiendo de estas fichas como referencia.
- Ambos personajes usan las **4 armas** del ciclo (florete → espada → daga →
  arco); el arma "característica" de cada hoja es solo su firma visual.
- El color de jugador (azul Nacho / rojo Rodrigo) alimenta el sistema ya
  planeado: sangre por color, pips rellenos/huecos y flecha del HUD.
