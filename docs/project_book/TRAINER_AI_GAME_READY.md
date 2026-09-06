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

## 27.1 — Freeze final Game-Ready: Trainer AI hardening CLOSED / VALIDATED

Estado: **CLOSED / VALIDATED**.

Esta freeze cierra exclusivamente la fase Game-Ready abierta en 27.0. No reabre C3f, no crea una continuación C3f-at y no autoriza una nueva tranche de Trainer AI.

### Checkpoints canónicos

Commit de apertura 27.0:

`14bed5cfc3cc8a48714277baa481a350b47da4f4`

Checkpoint técnico:

`63850b0c738cb7f2c1dc740294b7289e4b9ef5db`

Checkpoint humano:

`17fd83aa38c901116f1d635ef4125d0c76e17d8e`

Los dos checkpoints son siblings directos del mismo parent:

`14bed5cfc3cc8a48714277baa481a350b47da4f4`

y comparten exactamente el mismo tree:

`92aa8ce7fbf0c4931c186003c4e328623836ba88`

### Certificación doble

Checkpoint técnico:

- **18/18 workflows SUCCESS**;
- Trainer Evaluation Corpus: **408 PASS / 0 FAIL**;
- Trainer Battle Session: **66 PASS / 0 FAIL**;
- Trainer Team Composition: **1258 PASS / 0 FAIL**;
- Godot 4.7 global: **472 PASS / 0 FAIL**.

Checkpoint humano:

- **18/18 workflows SUCCESS**;
- Trainer Evaluation Corpus: **408 PASS / 0 FAIL**;
- Trainer Battle Session: **66 PASS / 0 FAIL**;
- Trainer Team Composition: **1258 PASS / 0 FAIL**;
- Godot 4.7 global: **472 PASS / 0 FAIL**.

Los logs inspeccionados de Evaluation, Battle y Team no contienen `SCRIPT ERROR` ni `Traceback`. El `Parse JSON failed` observado en el corpus Godot pertenece al control negativo deliberado de savegame corrupto y termina en `PASS sg_corrupt_rejected`; no es un fallo de producto.

### Resolución del falso blocker 404/3

El candidato diagnóstico anterior produjo **404 PASS / 3 FAIL** y reportó:

`live_root_coverage_mismatch`

La causa no estaba en `TrainerGameReadyTieResolver` ni en Battle Core. El fixture runtime clonado omitía el inventario que había generado el proposal fuente de 10 raíces legales. El proposal original contenía:

- 2 raíces MOVE;
- 2 raíces SWITCH;
- 6 raíces ITEM.

El helper canónico instala 1 Potion + 1 Hyper Potion por lado; el clon no lo hacía. El resolver, por tanto, bloqueaba correctamente porque el espacio legal vivo no coincidía con la evidencia profunda que intentaba consumir.

La corrección final fue estrictamente de fixture:

- instalar en la sesión clonada el mismo inventario Potion + Hyper Potion;
- exigir explícitamente `game_ready_runtime_fixture_live_root_coverage` antes de resolver el empate.

La barrera `live_root_coverage_mismatch` **se conserva intacta**. No se debilitó el comportamiento fail-closed para hacer pasar el test.

### Resultado Game-Ready

Queda certificado que:

- un empate exacto, completo y vigente se resuelve de forma reproducible entre raíces deep-best equivalentes;
- el turno autoritativo avanza;
- la sustitución alcanza `SUBSTITUTION_READY`;
- no existe caller fallback;
- la telemetría del empate se conserva;
- invertir el orden de candidatos no altera el resultado;
- la selección no usa la acción actual del jugador;
- existe diversidad entre equivalentes y no una preferencia fija por el primer root;
- empate incompleto, stale o con cobertura legal viva distinta continúa bloqueado;
- la ruta unique-max anterior permanece sin cambios;
- las políticas adversariales `damage_greedy`, `switch_bait`, `sacrifice` e `item_heal` completan batalla sin deadlock;
- `item_heal` ejerce realmente la superficie ITEM;
- el benchmark reproducible ejecuta 5 muestras y todas permanecen muy por debajo del guard CI de 5000 ms.

Los tiempos del benchmark son únicamente referencia del runner CI y **no** constituyen una medición ni una promesa de rendimiento sobre el PC físico del usuario.

### Scope neto canónico 27.0 -> Game-Ready

Exactamente 4 archivos:

Producción:

1. `modules/gameplay/trainer_battle_session.gd`;
2. `modules/trainer_ai/trainer_game_ready_tie_resolver.gd`.

Tests:

3. `tests/trainer_ai/trainer_evaluation_corpus_test_runner.gd`;
4. `tests/trainer_ai/trainer_game_ready_hardening_test_suite.gd`.

No existe workflow/helper diagnóstico temporal en el tree canónico.

### Barreras preservadas

No se ha abierto ni integrado:

- Trainer Brain general;
- autonomía global por defecto;
- scheduler;
- shared budget / 660;
- FASE34;
- recovery/campaign/replacement policy como desempate oculto;
- forced replacement fuera de Battle Core.

### Invariantes externos y cierre

- PR #105 debe permanecer **OPEN / unmerged**;
- `main` debe permanecer exactamente en `641d4b1fb0bcf964205d616e96f198f05d702197`;
- esta freeze es docs-only sobre el checkpoint humano certificado;
- **Trainer AI Game-Ready hardening: CLOSED / VALIDATED**.

No hay una siguiente tranche Game-Ready de Trainer AI autorizada. Cualquier trabajo futuro requiere un regression reproducible concreto o una nueva feature/proyecto con scope separado.
