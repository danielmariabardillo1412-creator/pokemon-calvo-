# ADR-022 — Trainer Belief Inference V1

## Estado

ACEPTADA / IMPLEMENTADA / VALIDADA en `feature/trainer-belief-inference-v1`.

Validación final del commit de código `7597dd15db93c3f196682f6e809657e795c7356f`:

- Trainer Belief Inference (FASE 22): **48 PASS / 0 FAIL**.
- Trainer Tactical Intelligence (FASE 21): **SUCCESS**.
- Trainer Intelligence Foundation (FASE 20): **SUCCESS**.
- Trainer Battle Session (FASE 19): **SUCCESS**.
- Godot 4.7 headless regression completa: **SUCCESS**.

## Contexto

FASE 20 separó información revelada e inferida. FASE 21 añadió un baseline táctico
explicable que evita leer estadísticas ocultas. Antes de introducir búsqueda en FASE 23,
el entrenador necesita representar incertidumbre de forma útil, determinista y auditable.

La frontera sigue siendo:

`Observation -> Memory -> Beliefs -> DecisionContext -> TrainerBrain -> Battle Core`

## Decisión

### 1. BeliefState V2

`TrainerBeliefState` conserva candidatos discretos y añade:

- `provenance` por hipótesis;
- evidencia `prior / inferred / revealed`;
- rangos numéricos públicos para dominios como velocidad;
- actualización pseudo-bayesiana determinista para dominios mutuamente excluyentes;
- migración compatible desde schema V1.

Una revelación pública tiene prioridad sobre cualquier inferencia posterior.

### 2. Inferencia separada del almacenamiento

`TrainerBeliefInference` calcula priors/actualizaciones. No recibe `BattleState`, RNG,
`CreatureInstance` rivales ni metadata cruda de `BattleEvent`.

Consume únicamente:

- `TrainerObservation`;
- `TrainerBattleMemory.event_log`, que ya contiene el envelope público saneado;
- `DefinitionCatalog` como conocimiento público de reglas/especies.

### 3. Movimientos

El learnset de nivel de la especie genera priors, no una lista cerrada de legalidad.

- movimientos recientes: prior mayor;
- movimientos antiguos aprendibles: prior menor pero no cero;
- movimientos por encima del nivel observado: no se incluyen en ese prior;
- una revelación de un movimiento fuera del prior se acepta inmediatamente al 100%.

Esto evita asumir que futuros sistemas de MT/tutores no existen.

### 4. Habilidades

Las habilidades compatibles con la especie reciben inicialmente un prior uniforme.
FASE 22 no inventa tasas de uso competitivas que el dataset actual no justifica.

Una habilidad revelada poda el dominio y queda al 100%.

### 5. Objetos

No se crea una distribución artificial entre miles de objetos. Mientras no exista
evidencia pública, el dominio de objeto permanece sin candidatos concretos.

`desconocido` no se transforma en `sin objeto`.

### 6. Velocidad

A partir de especie+nivel y de los límites públicos de IV/EV/naturaleza se calcula un
intervalo posible de stat Speed, nunca el valor exacto oculto.

El intervalo puede estrecharse por orden observado solo cuando:

- ambos activos previos ejecutaron un MOVE;
- ambos movimientos tienen la misma prioridad;
- existen ambos `ACTION_USED` públicos;
- los modificadores públicos de Speed del turno anterior están disponibles.

El límite es inclusivo para conservar la posibilidad de empate resuelto por RNG.
Switches, acciones impedidas, KO antes de actuar o prioridades distintas no generan
evidencia de velocidad.

### 7. Actualización pseudo-bayesiana

Para dominios mutuamente excluyentes:

`posterior(c) ∝ prior(c) * likelihood(c)`

Los pesos se normalizan a 10000 basis points con reparto determinista del residuo.
No se aplica automáticamente a movimientos, porque un moveset contiene varios candidatos
simultáneamente.

## Invariantes validadas

1. Battle Core sigue siendo la única autoridad de legalidad y ejecución.
2. Inferencia nunca puede reemplazar una revelación pública.
3. Ausencia de evidencia no equivale a evidencia de ausencia.
4. Los snapshots de creencias no contienen IV, EV, naturaleza, RNG ni stats rivales exactos.
5. Todo resultado probabilístico usa enteros/basis points.
6. Toda inferencia importante deja provenance auditable.
7. Prioridad distinta no se interpreta falsamente como evidencia de velocidad.
8. El valor oculto real de Speed permanece dentro del intervalo inferido en el fixture adversarial.
9. FASE 23 puede construir mundos plausibles desde estas creencias sin abrir la frontera anti-cheat.

## Fuera de alcance

- estadísticas competitivas externas de uso de sets;
- inferencia neuronal;
- MCTS/minimax/lookahead;
- self-play de producción;
- inferencia de objetos por ausencia de activación;
- deducciones desde metadata privada de Battle Core.

## Handoff a FASE 23

La siguiente fase debe introducir una capa separada de `plausible worlds` y búsqueda corta.
La primera versión no debe saltar directamente a MCTS: conviene demostrar primero que
podemos materializar estados hipotéticos compatibles con `TrainerBeliefState`, evaluar
acciones simultáneas sin que un lado vea la elección privada del otro, y reutilizar
`BattleSimulationFork` sin mutar el combate real.
