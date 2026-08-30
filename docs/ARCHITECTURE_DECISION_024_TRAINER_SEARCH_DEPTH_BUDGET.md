# ADR-024 — Trainer Search Depth & Budget V1

## Estado

IMPLEMENTADA / PENDIENTE DE VALIDACIÓN CI.

## Contexto

FASE 23 validó búsqueda simultánea de un turno sobre mundos plausibles. Saltar directamente
a MCTS añadiría selección de árbol, rollouts y presupuestos sin haber demostrado primero
que mirar un turno adicional mejora decisiones reales del entrenador.

## Decisión

### 1. Profundidad máxima V1: dos turnos

FASE 24 introduce `TrainerMultiTurnSearch` con profundidad configurable 1..2. No existe
recursión sin límite y MCTS permanece fuera de alcance.

### 2. Presupuesto determinista

`TrainerSearchBudget` limita:

- mundos plausibles;
- simulaciones `submit_turn`;
- acciones por lado en nodos de continuación;
- profundidad máxima.

No existe límite por milisegundos en V1. El mismo contexto y presupuesto deben producir
el mismo árbol y la misma decisión independientemente de la máquina.

Cada acción raíz que evalúa `DepthSearchTrainerBrain` recibe un presupuesto nuevo e
idéntico, evitando que las primeras acciones consuman el presupuesto de las últimas.

### 3. Expansión simultánea

En cada nodo sintético las acciones legales se generan mediante
`TrainerActionSpace.from_server()` sobre el `AuthoritativeBattleServer` sintético.

Por tanto:

- Battle Core continúa siendo la autoridad de legalidad;
- no se consulta el BattleState vivo después de materializar el mundo;
- ambas acciones del siguiente turno se generan desde el mismo estado previo;
- el rival no obtiene conocimiento de la acción propia antes de elegir.

### 4. Muestreo de acciones acotado

Cuando un nodo tiene más acciones de las permitidas por el presupuesto, MOVE y SWITCH se
intercalan mediante `kind_stratified_round_robin_v1`. Así un límite pequeño no elimina
sistemáticamente todos los cambios solo porque los movimientos se enumeren primero.

### 5. Hojas acumulativas, no suma por turno

El valor de una hoja de profundidad 2 se calcula comparando el estado final con el estado
raíz del mundo. No se suman dos evaluaciones turno-a-turno, lo que evitaría contar dos
veces daño, KO o estados persistentes.

### 6. Matrices parciales no influyen

Si el presupuesto se agota en mitad de la matriz de respuestas de una rama, esa expansión
no adopta valor de profundidad 2. Conserva el valor completo de profundidad 1.

Esto sacrifica trabajo parcial antes que introducir optimismo/pesimismo dependiente del
orden de iteración.

Las expansiones de continuación se ejecutan round-robin entre ramas raíz para repartir el
presupuesto antes de profundizar repetidamente en una sola rama.

### 7. Reemplazo forzado

Battle Core ya realiza automáticamente el primer reemplazo disponible tras un KO. La
búsqueda no implementa una segunda regla de reemplazo: continúa desde el estado sintético
que devuelve `TurnExecutor` siempre que la fase siga `WAITING_FOR_ACTIONS`.

### 8. Cerebro separado

`DepthSearchTrainerBrain` es una clase nueva. `SearchTrainerBrain` de FASE 23 queda intacto
y sirve como baseline directo en benchmarks.

El cerebro de profundidad mantiene la composición validada:

`score de búsqueda + 25 % baseline táctico/estratégico`.

### 9. Benchmark

`TrainerPlanningBenchmark` compara decisiones de dos cerebros sin medir wall-clock.
Registra:

- coincidencias con resultado esperado;
- decisiones cambiadas;
- mejoras de horizonte;
- regresiones;
- firmas deterministas.

Los fixtures de FASE 24 incluyen un caso donde el golpe inmediato parece favorable tras
un turno, pero el rival con prioridad puede rematar al atacante en el segundo. La
profundidad 2 debe preservar al atacante y cambiar al tanque. También existe un control
de presión ligera donde profundidad 1 y 2 deben coincidir en atacar.

## Invariantes

1. Cualquier fallo detiene la fase hasta corregirse y revalidarse.
2. Nunca se consulta RNG vivo en planificación.
3. Nunca se materializan secretos no observados/no inferidos.
4. La legalidad profunda pertenece al Battle Core sintético.
5. El presupuesto es determinista y explícito en la traza.
6. Ninguna matriz parcial puede presentarse como profundidad 2 completa.
7. Profundidad 2 debe demostrar al menos un caso de horizonte sin introducir regresión en
   el caso de control antes de considerar FASE 24 validada.
8. MCTS queda explícitamente fuera de FASE 24.

## Gate de cierre esperado

- suite FASE 24: 0 FAIL;
- FASE 23: SUCCESS;
- FASE 22: SUCCESS;
- FASE 21: SUCCESS;
- FASE 20: SUCCESS;
- FASE 19: SUCCESS;
- regresión global Godot 4.7: SUCCESS.

Solo después de ese cierre se decidirá si FASE 25 debe ampliar benchmarks/self-play o si
ya existe evidencia suficiente para introducir una búsqueda tipo MCTS/DUCT.
