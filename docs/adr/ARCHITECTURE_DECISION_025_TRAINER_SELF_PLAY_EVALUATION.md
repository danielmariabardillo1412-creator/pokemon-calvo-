# ADR-025 — Trainer Self-Play Evaluation V1

## Estado

VALIDADA / CERRADA.

FASE 25 quedó validada sobre `3eee9f1036a46ff365082c1a884a959cf440f9bb` con:

- suite FASE 25: **48 PASS / 0 FAIL**;
- baseline profundidad 1: **0 victorias / 6 derrotas** en el fixture pareado;
- planner profundidad 2: **6 victorias / 0 derrotas**;
- **6 mejoras pareadas / 0 regresiones**;
- resultado conservado al invertir `side_a` / `side_b`;
- FASE 24, 23, 22, 21, 20 y 19: SUCCESS;
- regresión global Godot 4.7: SUCCESS.

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

Profundidad 1 prefiere el daño inmediato. Al llegar el segundo turno, el rival sigue siendo
más rápido y remata antes de la segunda acción.

Profundidad 2 prepara el setup en el primer turno. Sobrevive al primer golpe, pasa a ser más
rápido y su Ataque aumentado permite KO antes del segundo golpe rival.

El cerebro de referencia es táctico y solo dispone del ataque pesado, eliminando ambigüedad
de política rival en este fixture.

## Incidente de validación resuelto

La primera ejecución de FASE 25 obtuvo **42 PASS / 6 FAIL**. La infraestructura de self-play,
el aislamiento, el determinismo y el baseline funcionaban, pero el planificador también
escogía el ataque codicioso.

La investigación mostró que el fixture había declarado al rival con `base_speed = 60` pero
le había asignado un `speed` real de 90. El sistema anti-cheat no conoce ese 90 oculto:
`TrainerBeliefInference` construye su rango plausible a partir de especie y nivel públicos.
Con `base_speed = 60`, varios mundos legítimos hacían defendible la acción codiciosa.

No se modificaron los pesos del cerebro, la búsqueda ni las reglas para aprobar el test.
Se corrigió únicamente la incoherencia pública del fixture, elevando la especie rival a
`base_speed = 100` y manteniendo el `speed` real en 90. Así el valor real queda dentro del
rango públicamente plausible, pero **el entrenador continúa sin recibir el stat exacto**.

Tras esa corrección, sin cambios en el algoritmo, el planner pasó a elegir el setup temprano
y la suite quedó en 48 PASS / 0 FAIL. El incidente valida además que la frontera anti-cheat
está influyendo realmente en las decisiones y no es solo una abstracción documental.

## Resultado empírico V1

Con tres semillas deterministas y espejo de lados, cada candidato juega seis partidas contra
el mismo rival de referencia:

- `SearchTrainerBrain` profundidad 1: 0-6;
- `DepthSearchTrainerBrain` profundidad 2: 6-0;
- mejoras pareadas: 6;
- regresiones pareadas: 0;
- partidas inválidas: 0;
- acciones rechazadas en partidas normales: 0.

Este resultado demuestra el valor del laboratorio y una ventaja real en este escenario de
horizonte. **No se interpreta como significancia estadística general ni como prueba de que
profundidad 2 sea universalmente superior.**

## No objetivos

- MCTS/DUCT;
- entrenamiento neuronal;
- wall-clock performance ranking;
- afirmar significancia estadística con una suite CI pequeña;
- etiquetar como blunder cualquier derrota;
- modificar `TrainerBattleSession` para benchmarking.

## Invariantes validados

1. La suite FASE 25 queda en 0 FAIL y supera el mínimo de 45 PASS.
2. Las partidas son deterministas a igualdad de semilla.
3. Los rosters de entrada permanecen intactos.
4. No aparecen acciones rechazadas en los combates normales.
5. El espejo conserva la mejora del planificador.
6. Baseline pierde el fixture de horizonte y planner lo gana en las semillas pareadas.
7. No aparecen regresiones pareadas en el fixture validado.
8. FASE 24, 23, 22, 21, 20, 19 y la regresión global Godot 4.7 siguen verdes.
9. La mejora se consigue sin revelar al cerebro el stat oculto exacto del rival.

## Siguiente decisión

FASE 26 debe ampliar el corpus de escenarios y ejecutar una evaluación estadística mayor,
con resultados segmentados y un intervalo de confianza apropiado, antes de decidir si MCTS
aporta una mejora suficiente para justificar su complejidad y coste.
