# ADR-023 — Trainer Search Foundation V1

## Estado

ACEPTADA / IMPLEMENTADA / VALIDADA en `feature/trainer-search-foundation-v1`.

Validación final de la fase:

- FASE 23 Trainer Search Foundation: 45 PASS / 0 FAIL;
- FASE 22 Trainer Belief Inference: SUCCESS;
- FASE 21 Trainer Tactical Intelligence: SUCCESS;
- FASE 20 Trainer Intelligence Foundation: SUCCESS;
- FASE 19 Trainer Battle Session: SUCCESS;
- regresión global Godot 4.7: SUCCESS.

## Contexto

FASE 22 dejó una representación auditable de incertidumbre. El siguiente paso necesita
lookahead sin romper la frontera anti-cheat ni asumir que el rival conoce nuestra acción
antes de elegir la suya.

La frontera permanece:

`Observation -> Memory -> Beliefs -> DecisionContext -> TrainerBrain -> Battle Core`

## Decisión

### 1. No se clona el BattleState vivo

`BattleSimulationFork` es seguro como motor contrafactual, pero clonar el estado vivo
para planificar copiaría también secretos rivales legítimamente ocultos. FASE 23 construye
primero un `BattleState` sintético desde `TrainerDecisionContext` y solo entonces crea el
fork.

La party propia se reconstruye completa porque es información del entrenador. La party
rival contiene únicamente criaturas observadas.

### 2. Mundos plausibles

`TrainerPlausibleWorldFactory` materializa un conjunto pequeño y determinista de mundos.

Variaciones V1:

- hasta dos hipótesis de habilidad del activo rival;
- muestras min/medio/max del rango público de Speed;
- una rejilla de semillas RNG sintéticas.

Nunca se usa `BattleState.rng_state` del combate real.

Los stats rivales no-Speed usan el proxy público de especie+nivel. El Speed se toma del
rango de creencias. Un objeto desconocido no se inventa: queda sin modelar y el mundo lo
registra como supuesto.

El límite de mundos es un presupuesto, no un sesgo de conocimiento. Las combinaciones se
seleccionan mediante `ability_stratified_round_robin_v1`: las hipótesis de habilidad se
intercalan antes de aplicar el límite, y la masa de peso de cada habilidad se deriva de su
confianza en `TrainerBeliefState` y se reparte entre los mundos seleccionados de esa
hipótesis. Así, truncar a 12 mundos no favorece a la primera habilidad por orden de bucle.

### 3. Movesets rivales

Los movimientos revelados tienen prioridad. Los huecos restantes se completan con los
candidatos de mayor confianza de `TrainerBeliefState`, hasta cuatro movimientos. Si no
hay hipótesis disponibles, se usa el learnset público como fallback.

Un movimiento real no revelado que no pertenece a las creencias no entra en el mundo.

PP rival desconocido se aproxima como completo y se registra explícitamente como supuesto.

### 4. Banca rival

Solo las criaturas rivales ya observadas se materializan. Por tanto una banca no vista
no puede aparecer como candidato de cambio en la búsqueda.

### 5. Matriz de acciones simultáneas

Para cada acción propia candidata, `TrainerSimultaneousSearch` la cruza con todas las
acciones rivales plausibles desde el mismo estado inicial del mundo.

No existe la secuencia incorrecta:

`elegimos -> rival ve nuestra elección -> rival responde`

La semántica es:

`acción propia candidata x acción rival plausible -> Battle Core resuelve ambas`.

### 6. Evaluación V1

`TrainerSearchStateEvaluator` puntúa tras un turno:

- daño proporcional infligido y recibido;
- KOs ganados/perdidos;
- nuevos estados persistentes;
- victoria/derrota terminal.

No pretende ser todavía una función de valor profunda.

### 7. Incertidumbre de política rival

FASE 23 no inventa una distribución de probabilidades sobre acciones rivales. Para cada
mundo se combina media y peor caso. El perfil controla aversión al riesgo:

- aggressive: 25 % peor caso;
- balanced: 40 %;
- technical: 50 %;
- cautious: 65 %.

### 8. SearchTrainerBrain

El cerebro de búsqueda usa el score robusto de simulación y conserva el 25 % del baseline
táctico/estratégico de FASE 21. Si no existen escenarios válidos, cae al baseline.

`TrainerDecisionTrace` conserva resultados agregados y escenarios públicos, pero nunca
serializa el `BattleState` sintético ni `rng_state`.

## Correcciones durante validación

La validación descubrió dos defectos que se resolvieron antes de cerrar la fase:

1. El fixture sintético no registraba el tipo `normal`, aunque `DamageCalculator` exige que
   todo `move.type_id` exista en `DefinitionCatalog`. Se corrigió el fixture para respetar
   el contrato real de Battle Core y se añadió una comprobación explícita.
2. El orden inicial `habilidad -> velocidad -> RNG` combinado con `max_worlds = 12`
   representaba 9 mundos de la primera habilidad y 3 de la segunda cuando existían 18
   combinaciones. Se sustituyó por muestreo estratificado determinista y pesos basados en
   confianza. Las pruebas verifican tanto estratificación como masa probabilística.

Tras estas correcciones, el escenario adversarial de cañón de cristal demuestra que el
cerebro de búsqueda abandona el ataque tácticamente atractivo y cambia al tanque cuando
la represalia plausible hace perder al activo frágil.

## Invariantes

1. El Battle Core sigue resolviendo todas las reglas de combate.
2. La búsqueda no recibe ni clona secretos del BattleState vivo.
3. Un rival no visto no existe en los mundos plausibles.
4. Un movimiento oculto no inferido no existe en los mundos plausibles.
5. RNG de búsqueda es sintético y reproducible.
6. Cada respuesta rival se evalúa desde el mismo estado previo a la acción propia.
7. Toda selección es determinista para un mismo `DecisionContext`.
8. El presupuesto de mundos no puede favorecer una hipótesis por el orden de iteración.
9. FASE 23 no incluye MCTS, profundidad recursiva ni modelo aprendido de política rival.

## Siguiente frontera

FASE 24 debe ampliar planificación de forma controlada y medible. Antes de introducir un
MCTS completo, conviene añadir presupuesto explícito de simulación, búsqueda multi-turno
acotada y benchmarks que permitan demostrar que mirar más lejos mejora decisiones en vez
de simplemente consumir más CPU. MCTS queda como evolución posterior si ese escalón
mantiene determinismo, anti-cheat y regresiones verdes.
