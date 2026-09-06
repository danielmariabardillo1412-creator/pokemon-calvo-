# Trainer AI — Game-Ready Hardening

## 27.0 — Apertura explícita post-cierre

Estado: **AUTORIZADO POR EL USUARIO / NUEVA FASE DE HARDENING / NO REABRE C3f**.

Baseline cerrado de entrada:

`432d80e4ce32a0ad6f5110bc9c6f55e40322db64`

Freeze previo:

`26.67 — Trainer AI runtime system CLOSED / COMPLETED`

Esta fase existe porque, después del cierre funcional, el usuario pidió convertir el entrenador certificado en un rival de juego robusto frente a personas. No invalida 26.67 y no crea una continuación artificial C3f-at; es una frontera nueva de producto.

### Objetivos únicos

1. **Empates game-ready**: conservar `TrainerItemAwareActionProposal.TIE_UNRESOLVED` como evidencia auditable, pero permitir que la API autónoma resuelva exclusivamente empates exactos, completos y order-invariant entre raíces deep-best equivalentes mediante una selección reproducible y sin prioridad lexical/kind oculta.
2. **Adversarial full-battle**: ejecutar batallas completas contra políticas de jugador deliberadamente explotadoras (damage-greedy, switch-loop/bait, sacrifice y item/heal cuando exista acción legal), verificando que el entrenador no se bloquea, no lee la elección secreta del jugador y siempre produce una acción legal cuando la evaluación es completa.
3. **Benchmark reproducible**: medir tiempo de decisión autónoma en CI sobre escenarios representativos, registrar mediana/p95/máximo y dejar un harness reutilizable. Los tiempos CI son una referencia, no una afirmación sobre el PC físico del usuario.

### Contrato de desempate

El proposal profundo de producción **no cambia de significado**:

- máximo único -> `PROPOSAL_READY`;
- empate exacto -> `TIE_UNRESOLVED`;
- profundidad/cobertura incompleta -> `BLOCKED`.

La nueva capa game-ready solo puede resolver un `TIE_UNRESOLVED` si además se cumplen todas estas barreras:

- `evaluations_complete = true`;
- `metadata_models_match = true`;
- `same_budget = true`;
- `root_all_legal = true`;
- `common_depth == REQUIRED_DEPTH`;
- `order_invariant = true`;
- todos los `best_root_ids` siguen siendo acciones legales actuales de `side_b`;
- todos comparten exactamente el máximo score profundo;
- ningún root fuera del best-set comparte un score superior;
- battle id, turn y side siguen coincidiendo con el estado autoritativo.

Selección entre equivalentes:

`uniform_seeded_equal_deep_best_v1`

La semilla se deriva únicamente de información ya pública para el entrenador antes de resolver el turno:

- battle id;
- turn;
- side id;
- candidate root ids canónicamente ordenados;
- policy id.

No usa:

- acción actual elegida por el jugador;
- live Battle RNG;
- input order;
- prioridad MOVE/SWITCH/ITEM;
- lexical como preferencia semántica;
- profile fallback;
- campaign/recovery/replacement;
- scheduler/shared budget/660;
- FASE34.

El orden lexical solo puede emplearse para canonicalizar el conjunto antes de aplicar la selección seeded, nunca para escoger siempre el primer candidato.

### Scope productivo previsto

Máximo esperado:

1. nueva clase `TrainerGameReadyTieResolver`;
2. modificación estrecha de `TrainerBattleSession.submit_player_action_with_autonomous_trainer(...)` para consumir el resolver únicamente cuando el proposal sea `TIE_UNRESOLVED`;
3. limpieza del nuevo report durante begin/settle/reset.

`TrainerItemAwareActionProposal` debe conservar su contrato fail-closed original salvo blocker real.

### Gate de cierre

La fase se considerará game-ready solo si:

- el empate completo avanza turno con una acción legal y reproducible;
- invertir el orden de candidatos no cambia el resultado;
- variar battle/turn permite diversidad entre equivalentes sin sesgo fijo al primer root;
- empate stale/incompleto/ilegal sigue bloqueado;
- unique-max conserva exactamente la ruta anterior;
- no existe caller fallback;
- adversarial full-battle termina sin deadlock;
- benchmark no muestra una explosión patológica y registra métricas explícitas;
- 18/18 workflows SUCCESS en checkpoint técnico y humano tree-identical;
- PR #105 permanece OPEN/unmerged;
- `main` permanece exactamente en `641d4b1fb0bcf964205d616e96f198f05d702197`.
