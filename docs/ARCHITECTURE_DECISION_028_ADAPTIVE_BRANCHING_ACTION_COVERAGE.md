# ADR-028 — Adaptive Branching / Action Coverage V1

## Estado

IMPLEMENTADA / PENDIENTE DE VALIDACIÓN.

## Contexto

FASE 27 confirmó un límite concreto: con cuatro respuestas rivales públicamente plausibles y
`max_actions_per_side = 3`, la búsqueda podía excluir la cuarta respuesta peligrosa aunque el
presupuesto de simulaciones no estuviese agotado. El mismo banco refutó que profundidad 2 sea,
por sí sola, un cuello de botella demostrado.

La inspección posterior mostró dos hechos:

1. `TrainerPlausibleWorldFactory` ya conserva hasta cuatro movimientos plausibles del rival;
2. `TrainerMultiTurnSearch._bounded_actions()` mantiene el orden recibido dentro de MOVE y
   recorta después al máximo permitido.

Por tanto, una amenaza puede existir correctamente en el mundo plausible y aun así quedar
fuera de la matriz únicamente por su posición en el moveset.

## Decisión

FASE 28 mantiene intactos el planner y el buscador de FASE 27 y crea un candidato A/B separado:

- `TrainerThreatOrderedWorldFactory`;
- `TrainerAdaptiveBranchingSearch`;
- `AdaptiveBranchingTrainerBrain`.

### Ordenación de movimientos plausibles

El nuevo factory llama primero al generador legítimo de movimientos plausibles de FASE 27.
No añade movimientos, no consulta el moveset real oculto y no modifica las creencias.

Solo reordena los movimientos ya presentes según una amenaza determinista para el Pokémon
activo propio observado:

- potencia;
- precisión declarada;
- STAB;
- efectividad de tipo;
- prioridad positiva;
- utilidad estructurada básica de estado, cambios de stages, curación/drenaje y flinch.

La confianza de la hipótesis solo desempata amenazas iguales; el ID estable desempata después.
Esto es deliberado: una vez que un movimiento forma parte de un mundo plausible, la búsqueda
debe protegerse primero contra las respuestas peligrosas de ese mundo, no contra el orden
alfabético del identificador.

### Preservación del branching

`TrainerAdaptiveBranchingSearch` hereda íntegramente `TrainerMultiTurnSearch` y únicamente
instala el factory ordenado por amenaza. `_bounded_actions()` sigue usando el mismo esquema
estratificado MOVE/SWITCH y el mismo límite de acciones.

No se eleva el ancho global.

### Candidato A/B

`AdaptiveBranchingTrainerBrain` hereda `DepthSearchTrainerBrain` y sustituye solo el objeto de
búsqueda por `TrainerAdaptiveBranchingSearch`.

El brain anterior queda intacto. Esto permite que el gate de FASE 27 siga funcionando como
baseline negativo del escenario de branching y que FASE 28 mida el candidato sin reescribir
el pasado.

## Presupuesto congelado

- profundidad: 2;
- mundos: 2;
- simulaciones: 128;
- acciones máximas por lado: 3.

## Gate esperado

El banco de FASE 28 debe reutilizar los cuatro escenarios de FASE 27 y exigir:

- replanning `balanced`: candidato 6/6;
- replanning con `setup_weight_bp = 0`: candidato 6/6;
- branching conocido: candidato 6/6 y probe 6/6;
- la respuesta peligrosa pública aparece ahora en la traza;
- el candidato abre con la línea defensiva esperada;
- cobertura oculta: candidato 0/6 y el movimiento oculto sigue ausente de la primera traza;
- 0 inválidas;
- determinismo;
- el cap sigue siendo 3 y el presupuesto no se agota.

Además, el gate histórico de FASE 27 debe continuar en 49 PASS / 0 FAIL con el brain antiguo.

## Criterio de decisión

Si FASE 28 corrige `known_fourth_response` sin regresiones, la evidencia favorece selección de
branching informada antes que aumentar profundidad o introducir MCTS.

Si falla, se inspeccionará la causa antes de ampliar el algoritmo. No se aumentará el cap como
parche automático.
