# ADR-026 — Trainer Evaluation Corpus & Statistical Benchmark V1

## Estado

VALIDADA / CERRADA.

## Contexto

FASE 25 validó el laboratorio de self-play y un escenario completo donde profundidad 2
mejora una trampa de horizonte. Un único escenario, incluso repetido con varias semillas,
no justifica una arquitectura más compleja ni permite generalizar la superioridad del
planner.

Antes de considerar MCTS necesitábamos un corpus segmentado que mezclase casos donde la
profundidad adicional debía ayudar con controles donde no debía alterar una decisión obvia.

## Decisión

### 1. Corpus segmentado

FASE 26 introduce `TrainerEvaluationCorpus`. Cada escenario declara:

- identificador y familia;
- roster candidato;
- roster de referencia;
- cerebro de referencia;
- semillas deterministas;
- límite de turnos.

Cada escenario reutiliza `TrainerSelfPlayEvaluation`, por lo que conserva comparación
pareada y espejo `side_a` / `side_b`.

### 2. Tamaño V1

El gate CI usa cinco familias, seis semillas y espejo de lados:

`5 escenarios x 6 semillas x 2 lados = 60 partidas por candidato`.

Baseline y planner se enfrentan por separado a exactamente las mismas condiciones.

### 3. Familias V1

1. `two_turn_setup_horizon`: preparación temprana de Velocidad/Ataque necesaria para ganar.
2. `obvious_terminal_attack`: KO inmediato; mirar más profundo no debe estropearlo.
3. `priority_speed_control`: un movimiento de prioridad resuelve una desventaja de Velocidad.
4. `guarded_type_coverage`: una opción conocida como inmune 0x debe descartarse y usarse cobertura.
5. `setup_restraint_control`: existe setup atractivo, pero un ataque ya termina el combate; el planner no debe preparar innecesariamente.

El primer escenario mide ganancia de horizonte. Los cuatro restantes son controles de
regresión con mecanismos distintos.

### 4. Intervalo Wilson del 95 %

`TrainerWilsonInterval` calcula el intervalo Wilson score bilateral convencional con z=1.96
y serializa los resultados en basis points.

Se informa por separado:

- win rate decisivo del baseline;
- win rate decisivo del planner;
- proporción de mejoras entre pares cuyo resultado cambia;
- proporción de regresiones entre pares cuyo resultado cambia.

Los pares iguales no se convierten artificialmente en evidencia de mejora: sirven como
señal de estabilidad.

### 5. No wall-clock scoring

El benchmark sigue siendo determinista y basado en resultados. El tiempo de CPU no forma
parte del criterio de inteligencia ni del pass/fail de esta fase.

### 6. Criterio de interpretación

Aunque los intervalos se separan en este corpus sintético, eso solo demuestra una ventaja
estadísticamente consistente **dentro del corpus V1**. No equivale a demostrar que
profundidad 2 sea universalmente superior en todas las batallas Pokémon.

## Resultado validado

HEAD técnico validado antes de este cierre documental:
`871f740d90ab331827bea330cd7e042101b1dc0d`.

FASE 26 obtuvo:

- 36 PASS / 0 FAIL;
- 60 partidas por candidato;
- baseline: 48 victorias / 12 derrotas;
- planner profundidad 2: 60 victorias / 0 derrotas;
- 12 mejoras pareadas;
- 0 regresiones pareadas;
- 48 pares iguales;
- 0 empates;
- 0 partidas inválidas;
- los cuatro escenarios de control permanecen iguales y ganadores para el planner;
- determinismo confirmado ejecutando el corpus completo dos veces.

El win rate observado es 80 % para baseline y 100 % para planner. Con Wilson bilateral
95 %, los intervalos aproximados son:

- baseline 48/60: 68.2 % — 88.2 %;
- planner 60/60: 94.0 % — 100 %.

Los intervalos no se solapan en este corpus. Entre los 12 pares cuyo resultado cambia,
los 12 cambios favorecen al planner; los otros 48 pares son estabilidad y no se cuentan
como evidencia adicional de mejora.

## Validación de regresión

Sobre el mismo SHA `871f740d90ab331827bea330cd7e042101b1dc0d` quedaron en SUCCESS:

- FASE 26 corpus estadístico;
- FASE 25 self-play;
- FASE 24 profundidad/presupuesto;
- FASE 23 búsqueda;
- FASE 22 creencias;
- FASE 21 inteligencia táctica;
- FASE 20 foundation;
- FASE 19 trainer battle session;
- regresión global Godot 4.7.

Total: 9/9 gates verdes.

## No objetivos

- MCTS/DUCT;
- redes neuronales;
- afirmar superioridad general a partir de 60 partidas sintéticas;
- optimización de rendimiento por tiempo real;
- reemplazar el self-play autoritativo de FASE 25;
- ocultar o promediar regresiones por familia.

## Siguiente decisión

No introducir MCTS solo porque profundidad 2 haya ganado el corpus actual. La siguiente
fase debe construir casos que expongan límites reales del planner actual —mayor horizonte,
branching y/o incertidumbre— y medirlos con el mismo laboratorio. Después se compararán
alternativas incrementales (más profundidad/presupuesto, poda u otra búsqueda) antes de
aceptar el coste de MCTS.
