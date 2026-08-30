# ADR-027 — Trainer Search Limit Benchmark V1

## Estado

IMPLEMENTADA / PENDIENTE DE VALIDACIÓN.

## Contexto

FASE 26 demostró que el planner de profundidad 2 mejora el corpus V1 sin regresiones en
los cuatro controles. Eso no justifica aumentar profundidad, branching ni introducir MCTS
por anticipación. Antes hay que demostrar límites concretos del planner actual y separar
sus causas.

El contrato vigente de `TrainerSearchBudget` limita explícitamente `depth_turns` a 2 y el
planner usa un máximo configurable de acciones por lado y mundos plausibles construidos
solo desde información legítima.

## Decisión

### 1. Banco de límites, no nueva IA

FASE 27 no cambia el algoritmo de búsqueda ni sus pesos. Introduce:

- `TrainerSearchLimitBenchmark`, harness segmentado y espejado;
- `TrainerSequenceProbeBrain`, cerebro diagnóstico de secuencia fija que solo puede escoger
  acciones ya presentes en el `TrainerDecisionContext` legal;
- tres escenarios diseñados para aislar límites diferentes.

El probe no es un candidato de gameplay. Su única función es demostrar que una línea legal
existe cuando el planner no la encuentra.

### 2. Límite de horizonte

`three_turn_horizon` exige combinar dos preparaciones distintas antes del golpe decisivo:

1. subir Velocidad y +1 Ataque;
2. añadir +3 Ataque;
3. atacar.

La combinación llega a +4 Ataque y permite KO garantizado. Una sola preparación no basta.
El rival derrota al candidato si este intenta resolver el combate solo con daño inmediato.

El planner se ejecuta con profundidad 2 y presupuesto holgado. El gate exige comprobar que
la traza alcanzó profundidad 2 completa y no agotó simulaciones. Si aun así pierde mientras
el probe de tres pasos gana, el fallo queda atribuido a horizonte y no a falta accidental
de presupuesto.

### 3. Límite de branching conocido

`known_fourth_response` da al rival cuatro movimientos públicamente plausibles. Los cuatro
están en su learnset de nivel y, por tanto, son información que puede formar parte de las
creencias sin hacer trampas.

El planner mantiene `max_actions_per_side = 3`. Los tres primeros movimientos son débiles;
el cuarto es una respuesta ofensiva letal. El cerebro rival real la selecciona por su valor
táctico.

El gate exige demostrar simultáneamente:

- el cuarto movimiento está en el prior público;
- aparece en los eventos reales;
- no aparece en la traza simulada del planner;
- la traza registra cap 3;
- el presupuesto de simulaciones no se agotó;
- una línea legal conservadora (debuff de Ataque seguido de ataques) gana con el probe.

Así se separa un límite de muestreo/branching de un límite de horizonte o de CPU.

### 4. Límite de información legítima

`unmodeled_hidden_coverage` contiene un movimiento real del rival que no está en su learnset
público y todavía no ha sido revelado.

El planner no debe conocerlo antes del primer turno. El gate exige que:

- el movimiento esté ausente del prior público;
- esté ausente de la primera traza;
- el rival lo revele al usarlo en el combate real.

Este escenario se clasifica como sorpresa legítima de información incompleta. No se usa un
probe-oráculo para declarar que el planner hizo una mala jugada, porque un oráculo que
conociese de antemano el movimiento oculto estaría haciendo trampas.

### 5. RNG controlado sin simulador paralelo

Los combates siguen usando `BattleState + AuthoritativeBattleServer` y el RNG real. Para
que los fixtures no dependan de críticos, sus movimientos fijan una modificación de ratio
de crítico suficientemente negativa para que el umbral efectivo sea 0. El factor aleatorio
de daño permanece activo, y los márgenes de HP/daño están construidos para conservar el
resultado en todo el rango normal.

### 6. Presupuesto del planner bajo prueba

FASE 27 usa:

- profundidad: 2;
- mundos: 2;
- simulaciones: 128;
- acciones máximas por lado: 3.

El presupuesto de simulaciones es deliberadamente amplio para que los fixtures de horizonte
y branching no confundan un cap estructural con agotamiento accidental de nodos.

## Gate de aceptación esperado

Con tres semillas y espejo de lados:

- 18 partidas del planner;
- 12 partidas de probe-oráculo en los dos escenarios solucionables;
- 0 partidas inválidas;
- horizonte: planner 0/6, probe 6/6;
- branching conocido: planner 0/6, probe 6/6;
- sorpresa oculta: planner 0/6, sin oráculo de juego justo;
- trazas coherentes con cada causa declarada;
- ejecución determinista.

Estas cifras son expectativas de fixtures diagnósticos y no resultados hasta que CI las
confirme.

## No objetivos

- aumentar `depth_turns` a 3;
- implementar MCTS/UCT/PUCT;
- cambiar pesos tácticos;
- añadir omnisciencia al rival;
- usar wall-clock como métrica de inteligencia;
- llamar “blunder” a una sorpresa que el agente no podía conocer legítimamente.

## Siguiente decisión si se valida

Comparar primero correcciones incrementales contra cada límite por separado:

1. horizonte: profundidad 3 o extensión selectiva;
2. branching: selección/adaptación del ancho o poda informada;
3. información: priors más amplios o muestreo de cobertura desconocida sin revelar datos reales.

MCTS solo deberá entrar como candidato si una de esas soluciones incrementales no ofrece
una relación suficiente entre calidad, coste y complejidad, y siempre deberá revalidar el
corpus de FASE 26 para demostrar que no introduce regresiones.
