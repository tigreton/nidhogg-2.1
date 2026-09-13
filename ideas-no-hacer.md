# Ideas que NO hacer (avisos pendientes)

Notas para el futuro del proyecto: cosas que NO están prohibidas para siempre,
pero que tienen un aviso importante antes de tocarlas. Si algún día se quiere
intentar alguna, leer primero el aviso completo.

---

## 1. Guardia pasiva (tarea 31, era D9 del apéndice)

La tarea `tasks/31-guardia-pasiva.md` es aplicable tal cual y ya incluye el
ajuste del bot, pero **cambia el equilibrio del duelo entero**: correr o
caminar hacia un rival parado con la espada en guardia pasa a ser muerte
(empalamiento), como en el Nidhogg original. Riesgos concretos:

- Puede dejar al bot (tareas 01/02) muriéndose de paseo contra guardias; la
  tarea ya añade una rama al `_bot_think` para evitarlo, pero hay que probarlo
  en partida real con las tres dificultades.
- Cambia el valor de las aproximaciones frontales: el dive horizontal (34) y
  el sidekick (35) ganan peso como aperturas, el puñetazo desarmado (28) pasa
  a ser más arriesgado de acercar.

**Regla acordada:** aplicarla, probarla y, si no convence, revertir con un
solo commit (una tarea = un commit, como siempre). No mezclarla con otros
cambios de equilibrio en la misma sesión.

---

## 2. Modo online

El Nidhogg 2 comercial tiene multijugador online. Este proyecto **lo deja
fuera a propósito**, igual que lo excluyó por diseño el proyecto hermano
"Nidhogg 2" (docs/PLAN.md §6 de aquel proyecto). Motivos:

- Requiere infraestructura que el proyecto no tiene y no quiere: servidor o
  matchmaking, gestión de salas, y una capa de red sincronizada (idealmente
  rollback) para un juego de esgrima a un golpe donde cada frame importa.
- Choca con las reglas del proyecto: arte y sonido 100 % procedurales,
  tareas atómicas ejecutables por un LLM básico, sin servicios externos.
- El juego ya cubre el hueco social con 2 humanos en local, bots con tres
  dificultades, bot vs bot, 2v2 y el modo Copa.

Si algún día se quiere intentar, primero habría que decidirlo como proyecto
(nueva decisión de alcance), no como una tarea más de la carpeta `tasks/`.
