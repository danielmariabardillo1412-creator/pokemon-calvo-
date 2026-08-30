# ADR-025 — Trainer Self-Play Evaluation V1

## Estado

IMPLEMENTADA / PENDIENTE DE VALIDACIÓN.

## Contexto

FASE 24 demostró en un caso controlado que una búsqueda determinista de dos turnos puede
resolver una trampa de horizonte que profundidad 1 no ve. Eso no basta para justificar un
salto a MCTS: antes necesitamos un laboratorio que ejecute combates completos, compare
cerebros bajo las mismas semillas y conserve evidencia por turno.

## Decisión

### 1. Self-play sobre Battle Core real

`TrainerSelfPlayMatch` usa directamente:

`BattleState -> AuthoritativeBattleServer -> TurnExecutor`

No existe un simulador de benchmark paralelo. `TrainerBattleSession` no se reutiliza porque
su contrato es deliberadamente asimétrico (`player`/`opponent`) e incluye settlement y
progresión del jugador. Forzarlo a representar dos agentes simétricos mezclaría gameplay
con evaluación.

### 2. Dos controladores independientes

Cada lado recibe su propio `TrainerIntelligenceController`, memoria, creencias y cerebro.
Ambos eligen su acción antes de que ninguna se envíe al servidor. Después Battle Core
resuelve simultáneamente y ambos observan el mismo conjunto autoritativo de eventos desde
su perspectiva.

### 3. Aislamiento entre partidas

Los rosters de entrada se clonan mediante el contrato serializable de `CreatureInstance`.
Una partida no puede dejar HP, PP, estado o stages contaminando la siguiente.

### 4. Límite determinista de turnos

Cada partida tiene un máximo explícito de turnos. No existe timeout de decisión ni scoring
por tiempo de CPU. Alcanzar el límite produce empate técnico y una firma diagnóstica.

### 5. Evidencia por turno

El resultado conserva:

- semilla;
- acción de ambos lados;
- `TrainerDecisionTrace` cuando el cerebro lo expone;
- eventos autoritativos;
- ganador por lado;
- condición de terminación;
- firmas diagnósticas.

### 6. Blunder signatures objetivas

`TrainerBlunderAnalyzer` V1 evita etiquetar una jugada como mala por intuición. Solo registra:

- decisión nula;
- acción rechazada por Battle Core;
- selección de un movimiento cuya propia traza táctica conocía como inmunidad 0x;
- ventana prolongada sin progreso material;
- límite de turnos.

Son señales de diagnóstico, no una prueba de juego subóptimo perfecto.

### 7. Comparación pareada y con espejo

`TrainerSelfPlayEvaluation.compare_against_reference()` compara baseline y planner contra el
mismo cerebro de referencia usando las mismas semillas. Cada semilla se juega dos veces:
una con el candidato en `side_a` y otra en `side_b`.

Se registran:

- victorias/derrotas/empates;
- partidas inválidas;
- mejoras pareadas;
- regresiones pareadas;
- firma determinista.

### 8. Fixture de horizonte completo

El escenario CI tiene un candidato más lento que recibe un golpe antes de actuar y muere
si recibe un segundo. Tiene dos opciones:

- ataque codicioso, que hace daño importante pero no mata;
- `selfplay_agility_focus`, setup de un solo PP que aumenta Velocidad +4 y Ataque +2.

Profundidad 1 debe preferir el daño inmediato. Al llegar el segundo turno, el rival sigue
siendo más rápido y remata antes de la segunda acción.

Profundidad 2 debe preparar el setup en el primer turno. Sobrevive al primer golpe, pasa a
ser más rápido y su Ataque aumentado permite KO antes del segundo golpe rival.

El cerebro de referencia es táctico y solo dispone del ataque pesado, eliminando ambigüedad
de política rival en este fixture.

## No objetivos

- MCTS/DUCT;
- entrenamiento neuronal;
- wall-clock performance ranking;
- afirmar significancia estadística con una suite CI pequeña;
- etiquetar como blunder cualquier derrota;
- modificar `TrainerBattleSession` para benchmarking.

## Gate de aceptación

La fase solo puede cerrarse si:

1. la suite FASE 25 queda en 0 FAIL y al menos 45 PASS;
2. las partidas son deterministas a igualdad de semilla;
3. los rosters de entrada permanecen intactos;
4. no aparecen acciones rechazadas en los combates normales;
5. el espejo conserva la mejora del planificador;
6. baseline pierde el fixture de horizonte y planner lo gana en las semillas pareadas;
7. no aparecen regresiones pareadas en el fixture de control;
8. FASE 24, 23, 22, 21, 20, 19 y la regresión global Godot 4.7 siguen verdes.

## Siguiente decisión si se valida

Ampliar el corpus de escenarios y ejecutar una evaluación estadística mayor antes de decidir
si MCTS aporta una mejora suficiente para justificar su complejidad y coste.
