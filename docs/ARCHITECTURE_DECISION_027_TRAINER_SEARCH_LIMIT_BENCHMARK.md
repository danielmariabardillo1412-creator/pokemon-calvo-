# ADR-027 — Trainer Search Limit Benchmark V1

## Estado

VALIDADA / CERRADA.

## Contexto

FASE 26 demostró que el planner de profundidad 2 mejora el corpus V1 sin regresiones en
los cuatro controles. Eso no justificaba aumentar profundidad, branching ni introducir
MCTS por anticipación. FASE 27 se diseñó para buscar límites concretos del planner actual
y separar causalmente horizonte, ancho de acciones e información incompleta.

El contrato vigente de `TrainerSearchBudget` mantiene `depth_turns = 2` como máximo y el
planner usa un número configurable de acciones por lado y mundos plausibles construidos
solo desde información legítima.

## Decisión

### 1. Banco diagnóstico, no nueva IA

FASE 27 no cambia el algoritmo de búsqueda ni los pesos de producción. Introduce:

- `TrainerSearchLimitBenchmark`, harness segmentado, determinista y espejado;
- `TrainerSequenceProbeBrain`, cerebro diagnóstico de secuencia fija que solo puede escoger
  acciones ya legales en `TrainerDecisionContext`;
- cuatro escenarios finales: dos controles positivos de replanning, un límite de branching
  conocido y una sorpresa legítima de información oculta.

El probe no es un candidato de gameplay. Su función es comprobar que una línea legal existe
y separar “el planner no la encontró” de “el escenario no tenía solución”.

### 2. Hipótesis de horizonte: refutada en estos fixtures

La hipótesis inicial era que una línea de tres turnos quedaría fuera de una búsqueda con
profundidad nominal 2. El fixture exigía combinar preparaciones antes del golpe decisivo.

El resultado contradijo la hipótesis de forma reproducible. Con perfil `balanced`, en las
seis ejecuciones (tres semillas y espejo de lados), el planner hizo exactamente:

1. `focus`;
2. `speed+attack`;
3. `strike`.

Resultado: **6/6 victorias en tres turnos**, con `fully_completed_depth = 2` y
`budget_exhausted = false`.

Se intentó aislar una posible ayuda del evaluador táctico mediante un perfil diagnóstico con
`setup_weight_bp = 0`, sin modificar reglas de búsqueda, legalidad ni acceso a información.
El resultado volvió a ser exactamente el mismo: **6/6 victorias**, misma secuencia de tres
turnos y profundidad 2 completada sin agotar presupuesto.

La explicación es receding-horizon replanning: profundidad 2 no significa que el agente solo
pueda ejecutar estrategias de dos turnos. En cada turno vuelve a planificar, y una mejora
intermedia que ya tiene valor dentro del horizonte visible puede encadenarse hasta una línea
más larga.

Por tanto, FASE 27 **no demuestra que profundidad 2 sea un cuello de botella**. Los dos casos
se conservan como controles positivos para impedir que una fase futura degrade esta capacidad.
No se aumentará `depth_turns` solo por intuición; hará falta un contraejemplo real que el
planner actual no pueda resolver.

### 3. Límite de branching conocido: confirmado

`known_fourth_response` da al rival cuatro movimientos públicamente plausibles. Los cuatro
están en su learnset y, por tanto, pueden formar parte de las creencias sin hacer trampas.

El planner mantiene `max_actions_per_side = 3`. Los tres primeros movimientos son débiles;
el cuarto es una respuesta ofensiva letal y el cerebro rival real la selecciona.

El resultado final es:

- planner: **0/6**;
- probe con línea conservadora: **6/6**;
- el cuarto movimiento está en el prior público;
- aparece en los eventos reales;
- no aparece en la traza simulada del planner;
- la traza registra `max_actions_per_side = 3`;
- `budget_exhausted = false`.

Esto demuestra un límite real de cobertura de acciones, no un problema de CPU, horizonte ni
información ilegal. FASE 28 debe atacar primero este cuello de botella con branching adaptativo
o selección informada antes de considerar algoritmos de búsqueda más complejos.

### 4. Información oculta legítima: límite confirmado, no blunder

`unmodeled_hidden_coverage` contiene un movimiento real del rival que no está en su learnset
público y todavía no ha sido revelado.

El resultado final es planner **0/6**, pero el comportamiento es correcto desde el punto de
vista de anti-cheat:

- el movimiento está ausente del prior público;
- está ausente de la primera traza;
- el rival lo revela únicamente al usarlo en el combate real;
- `budget_exhausted = false`.

No existe un probe-oráculo de “juego justo” para este caso, porque conocer la cobertura antes
de que sea observable sería hacer trampas. El escenario queda clasificado como límite de
información incompleta, no como error táctico del agente.

Una mejora futura deberá ampliar priors o generar hipótesis de cobertura desconocida sin
inyectar el moveset real oculto.

### 5. RNG controlado sin simulador paralelo

Los combates siguen usando `BattleState + AuthoritativeBattleServer` y el RNG real. Para que
los fixtures no dependan de críticos, sus movimientos fijan una modificación de crítico
suficientemente negativa para que el umbral efectivo sea 0. El factor normal aleatorio de
daño permanece activo y los márgenes del fixture conservan el resultado en ese rango.

### 6. Presupuesto bajo prueba

FASE 27 mantiene:

- profundidad: 2;
- mundos: 2;
- simulaciones: 128;
- acciones máximas por lado: 3.

El presupuesto de simulaciones es deliberadamente holgado. Los límites confirmados no se
atribuyen a agotamiento accidental de nodos.

## Resultados finales del banco

Con tres semillas y espejo de lados:

- 4 escenarios;
- 24 partidas del planner;
- 12 partidas de probe-oráculo;
- 0 partidas inválidas;
- control de replanning `balanced`: planner 6/6;
- control de replanning con `setup_weight_bp = 0`: planner 6/6, probe 6/6;
- branching conocido: planner 0/6, probe 6/6;
- sorpresa oculta: planner 0/6, sin oráculo legítimo;
- ejecución determinista;
- gate FASE 27: **49 PASS / 0 FAIL**.

El resultado agregado del planner es 12 victorias y 12 derrotas, pero esa cifra no se usa
como métrica de fuerza global: el banco está segmentado para diagnosticar causas concretas.

## Invariantes conservados

- no se aumentó profundidad;
- no se introdujo MCTS;
- no se modificaron pesos de producción para fabricar resultados;
- no se filtró información oculta real hacia las creencias;
- las decisiones hipotéticas siguen usando el Battle Core autoritativo;
- los resultados se prueban en ambos lados y con semillas deterministas;
- las hipótesis refutadas se documentan en vez de reetiquetarlas como éxitos.

## No objetivos

- demostrar superioridad universal del planner;
- aumentar `depth_turns` a 3 sin un caso que lo justifique;
- implementar MCTS/UCT/PUCT;
- añadir omnisciencia;
- llamar “blunder” a una sorpresa que el agente no podía conocer legítimamente;
- usar wall-clock como sustituto de calidad de decisión.

## Siguiente decisión

La prioridad empíricamente justificada es **FASE 28 — Adaptive Branching / Action Coverage**.

Debe intentar corregir `known_fourth_response` sin simplemente elevar el ancho para todos los
nodos. El objetivo es conservar coste acotado y escoger mejor qué respuestas rivales merecen
entrar en la búsqueda. La corrección deberá:

1. hacer visible la cuarta respuesta peligrosa cuando sea públicamente plausible;
2. mantener el límite de información de FASE 27 intacto;
3. conservar los dos controles de replanning;
4. volver a superar el corpus de FASE 26 y todos los gates históricos;
5. compararse contra el planner actual antes de considerar MCTS.

MCTS solo entrará como candidato si las soluciones incrementales de cobertura no ofrecen una
relación suficiente entre calidad, coste y complejidad.
