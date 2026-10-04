# Cambios de código que harían falta — rediseño de sprites

**Estado: NINGUNO aplicado ni necesario.** Los 55 PNG sobrescriben ficheros
existentes con los mismos nombres y respetan el contrato de `player.gd`
(pies al borde inferior, eje del cuerpo centrado, canvas de ancho impar).
Godot reimporta solo al detectar contenido nuevo.

Lista de cambios **opcionales** para sacar más partido al rediseño, por si
quieres aplicarlos tú más adelante:

1. **Poses por arma** (el rediseño hornea el florete en todas las poses).
   - `scripts/player.gd`: en `pose_texture()` añadir sufijo por `weapon_id`
     (p. ej. `player_attack_mid_daga_p1.png`) con fallback al actual.
   - `tools/redesign_sprites.py`: variante `sword()` con longitud/guarda por
     arma (daga corta, espadón con gola). Es trabajo del pipeline, no del juego.

2. **Borrar el apaño de alineación de la tarea 62.** El INDICE-MULTIMEDIA
   menciona `POSE_Y_FIX` en `player.gd` como posible mapa de corrección por
   pose: ya no haría falta (P1 y P2 comparten geometría exacta y pies anclados).

3. **Actualizar `INDICE-MULTIMEDIA.md` §1/§2**: las tablas de tamaños de los
   sprites antiguos (p. ej. `attack_mid` 84×56) quedaron desfasadas con los
   nuevos (117×56). Es documentación, no código.

4. **Estela del tajo (tarea 80)**: los arcos de `player.gd` `_draw()` van de
   `(6,-8)` a `(86,-8)` px locales fijos. Con la hoja de `attack_mid` ahora a
   33 px del puño la estela sigue cuadrando; si algún día quieres que la
   estela naciese de la punta de la hoja, habría que parametrizarlo con
   `weapon_reach()`.

5. **`player_slide`**: sigue usándose solo para `State.ROLL` (la tarea 45 del
   slide tackle del original no está portea da). El sprite ya está rediseñado
   para cuando llegue.

6. **Título (`title.gd`)**: previsualiza con `player_idle_p1/p2`; hereda el
   nuevo look sin cambios.

Si aplicas el cambio 1 (poses por arma) avísame y lo diseño igual que este.
