# ADR-026 — Trainer Evaluation Corpus & Statistical Benchmark V1

## Estado

IMPLEMENTADA / PENDIENTE DE VALIDACIÓN.

## Contexto

FASE 25 validó el laboratorio de self-play y un escenario completo donde profundidad 2
mejora una trampa de horizonte. Un único escenario, incluso repetido con varias semillas,
no justifica una arquitectura más compleja ni permite generalizar la superioridad del
planner.

Antes de considerar MCTS necesitamos un corpus segmentado que mezcle casos donde la
profundidad adicional debe ayudar con controles donde no debe alterar una decisión obvia.

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

### 2. Tamaño mínimo V1

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

Incluso si los intervalos se separan en este corpus sintético, eso solo demuestra una
ventaja estadísticamente consistente **dentro del corpus V1**. No equivale a demostrar que
profundidad 2 sea universalmente superior en todas las batallas Pokémon.

## Gate de aceptación esperado

El corpus V1 está construido para producir, si la arquitectura se comporta como en FASE 25:

- 60 partidas por candidato;
- baseline: 48 victorias / 12 derrotas;
- planner: 60 victorias / 0 derrotas;
- 12 mejoras pareadas;
- 0 regresiones pareadas;
- 48 pares iguales;
- 0 partidas inválidas;
- intervalo Wilson del planner separado del baseline;
- controles sin regresión.

Estas cifras son expectativas de un fixture deliberadamente diseñado, no resultados hasta
que CI las valide.

## No objetivos

- MCTS/DUCT;
- redes neuronales;
- afirmar superioridad general a partir de 60 partidas sintéticas;
- optimización de rendimiento por tiempo real;
- reemplazar el self-play autoritativo de FASE 25;
- ocultar o promediar regresiones por familia.

## Siguiente decisión si se valida

Si el corpus confirma mejora sin regresiones, la siguiente fase debe atacar un límite que
profundidad 2 no resuelva —mayor branching, incertidumbre o horizonte— y usar ese caso para
comparar una técnica de búsqueda más avanzada contra el planner actual. MCTS solo se
justifica si aporta una mejora medible en esos casos difíciles sin degradar el corpus ya
validado.
