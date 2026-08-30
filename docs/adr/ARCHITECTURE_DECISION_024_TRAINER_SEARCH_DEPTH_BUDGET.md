# ADR-024 — Trainer Search Depth & Budget V1

## Estado

VALIDADA / CERRADA.

FASE 24 quedó validada sobre `e48fdcbfac6c5f81dda552b0ee934d2328bee0a6` con:

- suite FASE 24: **47 PASS / 0 FAIL**;
- FASE 23: SUCCESS;
- FASE 22: SUCCESS;
- FASE 21: SUCCESS;
- FASE 20: SUCCESS;
- FASE 19: SUCCESS;
- regresión global Godot 4.7: SUCCESS.

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
raíz del mundo. No se suman dos evaluaciones turno-a-turno, evitando contar dos veces daño,
KO o estados persistentes.

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

### 9. Benchmark y trampa de horizonte

`TrainerPlanningBenchmark` compara decisiones de dos cerebros sin medir wall-clock.
Registra:

- coincidencias con resultado esperado;
- decisiones cambiadas;
- mejoras de horizonte;
- regresiones;
- firmas deterministas.

El fixture final de horizonte evita imponer una retirada artificial. El Pokémon propio
dispone de un ataque fuerte y de `depth_defense_setup`, que aumenta Defensa en dos niveles.
Ante un rival con golpe fuerte de prioridad, profundidad 1 prefiere el daño inmediato,
pero profundidad 2 detecta que preparar Defensa en el primer turno permite sobrevivir al
segundo; intentar preparar la defensa después del ataque llega demasiado tarde.

Existe además un control de presión ligera donde profundidad 1 y 2 coinciden en atacar.
Así la mejora de horizonte no se obtiene convirtiendo al planificador en excesivamente
conservador.

## Invariantes validados

1. Cualquier fallo detiene la fase hasta corregirse y revalidarse.
2. Nunca se consulta RNG vivo en planificación.
3. Nunca se materializan secretos no observados/no inferidos.
4. La legalidad profunda pertenece al Battle Core sintético.
5. El presupuesto es determinista y explícito en la traza.
6. Ninguna matriz parcial puede presentarse como profundidad 2 completa.
7. Profundidad 2 demuestra una mejora real de horizonte sin regresión en el control.
8. MCTS queda explícitamente fuera de FASE 24.

## Incidente de validación resuelto

El primer fixture esperaba que profundidad 2 cambiara inmediatamente a un tanque. El gate
mostró que el planificador encontraba una línea válida superior: atacar primero y retirarse
en el turno siguiente. No se modificó el algoritmo para satisfacer una expectativa peor;
se corrigió el fixture para representar una trampa de horizonte genuina mediante setup
defensivo temprano.

## Siguiente decisión

FASE 25 debe ampliar la evidencia empírica mediante benchmark/self-play, registro de
resultados y clasificación de blunders antes de decidir si una búsqueda tipo MCTS/DUCT
aporta valor suficiente frente al planificador determinista de profundidad 2.
