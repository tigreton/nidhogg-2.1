# Tareas secundarias (backlog)

> **2026-10-04: BACKLOG AGOTADO.** Las dos últimas ideas grandes ya son tareas
> formales aplicadas: la torre de dos pisos (`85`, cuarta arena TORRE DEL
> CENTINELA) y la arena aleatoria por puntos (`86`, tecla X). Todo lo que
> pasó por este fichero está promocionado o aplicado; cuando entre una idea
> nueva, sigue la guía del final para convertirla en tarea con este formato.

---

## Cómo promocionar una idea a tarea (formato obligatorio)

Las tareas de esta carpeta están pensadas para lanzarse sueltas a un LLM
básico, así que cada una debe cumplir SIETE reglas:

1. **Atómica**: una sola característica cerrada, aplicable en una sesión. Si
   necesitas dos sesiones, son dos tareas.
2. **Independiente**: debe funcionar sobre el código ACTUAL del proyecto sin
   ninguna otra tarea aplicada. Si hereda de otra (como la dificultad del
   bot), decláralo en la cabecera como `Prerrequisitos:` y dilo en el
   contexto.
3. **Autocontenida**: duplica el bloque "Contexto del proyecto" con los
   archivos, constantes y funciones QUE ESA TAREA TOCA — no confíes en que
   el lector conoció el proyecto ni las demás tareas.
4. **Código literal**: pasos numerados con el código exacto a pegar. Di QUÉ
   línea existente buscar (cítala) y si el paso añade o sustituye. Un LLM
   básico no debe improvisar nada.
5. **Límites explícitos**: sección "Qué NO hacer" con las formas fáciles de
   estropear algo (tocar enums, romper el test, cambiar física global...).
6. **Aceptación verificable**: criterios que se comprueban a mano en 2
   minutos de partida, más el comando headless del test.
7. **Verificación común**: toda tarea termina con:

```
"C:/Users/tigreton/Desktop/Godot_v4.6.2-stable_win64.exe" --headless --path . res://test/smoke_test.tscn
```

y la última línea debe ser `SMOKE OK - todas las mecánicas funcionan`.

Plantilla exacta (copia esto y rellena):

```markdown
# Tarea NN — Título corto

**Dificultad:** baja|media|alta · **Archivos:** `ruta/a/tocar.gd` · **Prerrequisitos:** ninguno

## Objetivo
Qué se añade y para qué (2–4 frases, con el "por qué" del diseño).

## Contexto del proyecto (leer antes de tocar nada)
- Juego Godot 4.6 (GDScript)... — describe SOLO lo que esta tarea necesita:
  archivos, constantes, funciones, patrones existentes (con nombres exactos).
- Reglas de estilo: GDScript tipado, indentación con tabs, comentarios en español.

## Instrucciones paso a paso
### 1. Lo primero que hay que crear/cambiar
"En `archivo.gd`, busca la línea `código existente exacto` y ..."
```gdscript
	código nuevo literal (con tabs de indentación reales)
```
### 2. Lo siguiente...
(repite por cada paso, numerado, sin saltos)

## Qué NO hacer
- ...

## Criterios de aceptación
1. ... (comprobables a mano)

## Verificación
(comando headless + "última línea esperada: SMOKE OK...")
```

Checklist final antes de publicar la tarea:

- [ ] ¿Funciona sobre el código base sin ninguna otra tarea? (o prerrequisito declarado)
- [ ] ¿El código pegado usa TABS y compila tal cual (nombres exactos de variables)?
- [ ] ¿Cada línea que cito como "busca esto" existe realmente en el código actual?
- [ ] ¿Deja el smoke test en verde sin tocarlo (o ajusta sus esperas explicándolo)?
- [ ] ¿Toca el mínimo de archivos posible?
- [ ] ¿Actualicé `README.md` (tabla, conflictos, orden) con la nueva tarea?
- [ ] ¿Un LLM básico podría seguirla sin preguntar nada?
