# Tareas del proyecto Nidhogg-like

Cada archivo de esta carpeta es una **tarea atómica e independiente**: está pensada
para lanzarse suelta a un LLM básico como único objetivo, sin conocimiento previo
del proyecto (cada tarea duplica el contexto necesario).

## Cómo lanzar una tarea a un LLM básico

Copia esta plantilla como prompt y sustituye el nombre del archivo:

```
Trabajas en el proyecto Godot 4.6 que está en la carpeta
C:\Users\tigreton\Documents\zcode\Nidhogg 2.1

1. Lee el archivo tasks/<nombre-de-la-tarea>.md completo.
2. Ejecuta la tarea EXACTAMENTE como está escrita, paso a paso, sin cambios creativos.
3. No modifiques archivos que la tarea no mencione.
4. Al terminar, ejecuta el comando de verificación que indica la tarea y comprueba
   que la última línea es: SMOKE OK - todas las mecánicas funcionan
5. Si el código real no encaja con lo que describe un paso, DETENTE y explica la
   discrepancia. No improvises.
```

Reglas de oro para ti (el humano que supervisa):

- **Una tarea = un commit.** Así si una sale mal, se revierte sola.
- Verifica siempre el test headless antes de aceptar el resultado.
- Las tareas son independientes, pero algunas **tocan el mismo código** (ver tabla
  de conflictos abajo): si aplicas dos que se pisan, revisa el diff con cuidado.

## Índice de tareas

| Archivo | Tarea | Dificultad | Archivos que toca |
|---|---|---|---|
| `01-ia-bot.md` | Bot jugable para P2 (combate + correr a la meta) | alta | `player.gd`, `game.gd` |
| `02-ia-bot-dificultad.md` | Tres niveles de dificultad del bot | baja | `game.gd` |
| `03-arena-hierba-alta.md` | Hierba alta que oculta la estancia | baja | `game.gd`, `player.gd` |
| `04-arena-plataformas.md` | Escalera de plataformas (verticalidad) | baja | `game.gd` |
| `05-arena-segundo-foso.md` | Segundo foso sin plataforma | media | `game.gd` |
| `06-feel-hitstop.md` | Hit-stop (congelar unos frames al matar) | baja | `game.gd` |
| `07-feel-camara-lenta.md` | Cámara lenta al matar y al anotar | baja | `game.gd`, `test` |
| `08-feel-indicador-meta.md` | Aviso "¡CORRE!" con dirección de meta | baja | `game.gd` |
| `09-feel-marcador-paso.md` | Halo bajo los pies de quien tiene el paso | baja | `player.gd` |
| `10-feel-polvo.md` | Polvo al aterrizar y al correr | baja | `player.gd` |
| `11-feel-musica.md` | Música procedural en bucle | media | nuevo `music.gd`, `game.gd` |
| `12-mov-rodar.md` | Rodar (esquiva rápida agachado + salto) | media | `player.gd` |
| `13-mov-punetazo.md` | Puñetazo cuando estás desarmado | media | `player.gd`, `game.gd` |
| `14-test-ampliar.md` | Ampliar el smoke test (5 casos nuevos) | media | `test/smoke_test.gd` |
| `15-rob-pausa.md` | Pausa con ESC | baja | `game.gd` |
| `16-rob-gamepad.md` | Soporte de mando (2 gamepads) | baja | `game.gd` |
| `17-fix-espada-foso.md` | La espada desviada sobre el foso cae en el borde | baja | `game.gd` |
| `18-mov-estocada.md` | Estocada al atacar corriendo | media | `player.gd` |
| `19-mov-desarme.md` | El choque desarma al que ataca en alto | media | `game.gd` |
| `20-mov-tajo-aereo.md` | Tajo de espada en el aire (elegir altura) | baja | `player.gd` |
| `21-ia-bot-vs-bot.md` | Modo bot vs bot con la tecla N | baja | `game.gd` |
| `22-stats-partido.md` | Estadísticas en la pantalla de victoria | baja | `game.gd` |

Las ideas que aún no son tareas formales viven en `secundarias.md`, junto con
la guía para convertirlas en tareas con este mismo formato.

## Orden recomendado

Aunque son independientes, si vas a hacer varias, este orden minimiza fricción:

1. Primero las que solo añaden (`06`, `07`, `08`, `09`, `10`, `15`, `16`, `17`).
2. Luego arena (`03`, `04`, `05`) y movilidad (`12`, `13`).
3. Después `14` (el test ampliado vigila que nada se rompa en lo sucesivo).
4. Al final `01` → `02` (bot) y `11` (música), que son las más grandes.
5. `18`–`20` (movilidad) van bien justo después de `12`/`13`; `21` después de
   `01`; `22` en cualquier momento.

## Conflictos conocidos (por tocar el mismo código)

| Tareas | Conflicto y qué hacer |
|---|---|
| `01` y `02` | `02` reescribe parte de lo que añade `01`. Aplica `01` antes que `02`. |
| `05` y `17` | Las dos modifican la gestión de fosos en `_drop_sword`. Si aplicas ambas, unifica el helper `_in_any_pit`. |
| `06` y `15` | Las dos usan `get_tree().paused`. Si aplicas ambas, acepta que pulsar ESC durante el hit-stop lo corta (o protege el toggle con una variable). |
| `06` y `07` | Las dos actúan en `_kill`. Son compatibles, pero revisa juntas el resultado. |
| `12` y `13` | Las dos tocan el bloque de ataque en `player.gd`. Aplica una, prueba, y luego la otra. |
| `03` y `09` | El halo del corredor de `09` sigue viéndose dentro de la hierba de `03` (aceptable, o envuélvelo también). |
| `12`, `13`, `18` y `20` | Las cuatro tocan el bloque de input de ataque en `player.gd`. Cada una está escrita para el código base: aplícalas de una en una y revisa el diff entre medias. |
| `01` y `21` | `21` necesita el bot de `01` (activar ambos con N). |
| `19` y `13` | Sinergia (no conflicto): el desarme de `19` crea los duelos a puñetazo que arma `13`. Aplicables en cualquier orden. |

## Comando de verificación (común a todas las tareas)

Desde la raíz del proyecto:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

La última línea debe ser `SMOKE OK - todas las mecánicas funcionan`.
