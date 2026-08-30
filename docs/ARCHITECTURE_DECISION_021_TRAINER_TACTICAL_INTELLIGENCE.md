# ADR-021 — Trainer Tactical Intelligence Foundation

## Estado

ACEPTADA / IMPLEMENTADA / VALIDADA en `feature/trainer-tactical-intelligence-v1`.

Validación final:

- Trainer Tactical Intelligence: **34 PASS / 0 FAIL**.
- Trainer Intelligence Foundation (FASE 20): **SUCCESS**.
- Trainer Battle Session (FASE 19): **SUCCESS**.
- Godot 4.7 headless regression completa: **SUCCESS**.
- Commit validado: `45356d3efef8147608949fb9be6d8d6bb4e5d2b8`.

## Contexto

FASE 20 dejó una frontera anti-cheat explícita:

`Observation -> Memory -> Beliefs -> DecisionContext -> TrainerBrain -> Battle Core`

El siguiente paso necesita un entrenador que tome decisiones útiles antes de introducir
predicción profunda, MCTS o redes neuronales.

## Decisión

### 1. Legalidad

`TrainerActionSpace` es un adaptador privilegiado. Puede enumerar candidatos desde el
estado autoritativo, pero cada candidato debe pasar por la validación del
`AuthoritativeBattleServer`. El cerebro recibe copias desacopladas.

No se crea una segunda implementación de las reglas MOVE/SWITCH.

### 2. Evaluación táctica

`TrainerTacticalEvaluator` puntúa de forma interpretable:

- daño esperado aproximado;
- KO estimado;
- prioridad;
- precisión/riesgo;
- STAB y efectividad;
- estados;
- cambios de stages;
- curación, drenaje y recoil;
- multi-hit;
- presión ofensiva/defensiva de cambios;
- conservación básica de HP y PP.

Las estadísticas numéricas ocultas del rival no se consultan. Se usa
`public_species_proxy_v1`, basado en especie/nivel observados, cuando se necesita una
aproximación numérica.

### 3. Estrategia de equipo

`TrainerTeamStrategicEvaluator` puede detectar un caso conservador pero importante:
arriesgar al único Pokémon propio conocido que responde con fuerza a una amenaza rival
ya observada. Esta capa no hace búsqueda; añade valor estratégico de plantilla.

### 4. Guardas

`TrainerBlunderGuard` solo bloquea errores ciertos, por ejemplo:

- movimiento sin PP;
- inmunidad de tipo conocida para un ataque de daño;
- cambio a un Pokémon propio KO;
- cambio al activo actual.

No sustituye al evaluador ni obtiene información oculta.

### 5. Personalidad

`TrainerProfile` modifica pesos de una misma inteligencia. FASE 21 define perfiles
balanced/aggressive/cautious/technical. Ninguno obtiene privilegios de información.

### 6. Observabilidad

`TacticalTrainerBrain` produce `TrainerDecisionTrace` por candidato con puntuación,
confianza, razones, guardas y metadata. `TrainerTacticalBenchmark` ofrece una firma
determinista para casos de decisión reproducibles.

`TrainerDecisionTrace` queda además con round-trip JSON canónico para que las trazas
puedan persistirse y compararse de forma reproducible.

## Consecuencias

- Se obtiene un baseline táctico útil y testeable.
- El Battle Core no se duplica.
- La IA difícil no necesita hacer trampas.
- FASE 22 puede ampliar BeliefState sin romper el cerebro.
- FASE 23 puede usar BattleSimulationFork para lookahead/MCTS sobre este evaluador.
- La red neuronal queda fuera del camino crítico del juego.
