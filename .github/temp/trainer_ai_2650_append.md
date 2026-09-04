

### 26.50) Freeze C3f-ac — el margin SWITCH es portable solo con score ItemAware recalculado por contexto role-local; scores base históricos no son reutilizables

#### Baseline, incidente de parser y checkpoints canónicos

C3f-ac parte exclusivamente del freeze 26.49 certificado:

- freeze 26.49: `27b9b1294439166bc575083304933cc6480ea014`;
- primer técnico C3f-ac descartado: `4af64cd1b6e4ab3d6a61f4b2b899f1d2538ad959`;
- técnico C3f-ac corregido/canónico: `f3f4111b14688393afb3742f6aaa206e18142cad`;
- humano C3f-ac: `b6d93434d05eec339664bf8c0fcf5e5c67d29f61`;
- parent común de técnico corregido y humano: `27b9b1294439166bc575083304933cc6480ea014`;
- tree común: `4610dfee5c635f408da6e58798ac274513ba6dd5`.

El primer técnico `4af64cd1...` falló únicamente en Trainer Team Composition por un error de parser/harness: la suite TEST/AUDIT contenía el operador `!==`, no aceptado por GDScript 4.7. No hubo fallo semántico de la política, ni cambio productivo, ni evidencia válida que pudiera extenderse desde ese staging.

La corrección se hizo fuera de la línea canónica, sustituyendo exclusivamente `!==` por `!=`, y el técnico corregido fue reconstruido **directamente desde 26.49**. No se apiló ningún fix sobre el técnico fallido.

El técnico corregido y el humano son siblings reales: comparten exactamente parent y tree y ninguno desciende del otro.

Diff C3f-ac frente a 26.49:

- `tests/trainer_ai/trainer_roster_search_item_aware_depth1_switch_score_portability_audit_test_suite.gd`: +948;
- `tests/trainer_ai/trainer_team_composition_test_runner.gd`: +1/-1;
- producción: 0 cambios;
- brains: 0 cambios;
- `TrainerMultiTurnSearch`: 0 cambios;
- `TrainerItemAwareSearch`: 0 cambios;
- adapter productivo: 0 cambios.

#### Resultado ejecutivo C3f-ac

Suite:

`TrainerRosterSearchItemAwareDepth1SwitchScorePortabilityAuditTestSuite`

Audit ID:

`c3f_ac_item_aware_depth1_switch_score_portability_role_local_audit_v1`

Boundary ID:

`validate_item_aware_depth1_switch_score_portability_on_role_local_sanitized_context_before_any_production_adapter`

Resultado:

`PORTABLE_TEST_CONTRACT`

Estado exacto de procedencia del score:

`PORTABLE_ONLY_IF_RECOMPUTED_WITH_ITEM_AWARE_SEARCH_IN_ROLE_LOCAL_CONTEXT`

La conclusión NO significa que el score depth-1 base y el score ItemAware sean equivalentes. C3f-ac demuestra lo contrario en el fixture ejecutable: existen deltas observables entre ambos en los tres roles. Por tanto, la portabilidad del contrato SWITCH solo existe si cada candidato se vuelve a evaluar con **`TrainerItemAwareSearch` real** dentro del contexto role-local sanitizado correspondiente.

Queda fijado explícitamente:

`historical_base_score_reuse_authorized = false`

No se autoriza reutilizar scores C3f-t/u/v ni scores base depth-1 históricos como sustituto del score ItemAware.

#### Tres roles role-local ejecutados

C3f-ac cubre exactamente:

1. `root_opponent_response` — side rival desde su propia memoria histórica válida;
2. `own_depth2_continuation` — side observer sobre el estado branch-local posterior al root turn;
3. `opponent_depth2_continuation` — side rival sobre ese mismo estado branch-local, pero con su propia memoria/perspectiva.

El harness mantiene dos `TrainerBattleMemory` side-specific desde battle start. Para continuaciones:

- clona ambas memorias;
- ejecuta un turno no letal en un fork;
- proyecta únicamente los eventos de esa rama sobre cada clone;
- construye después observación, belief y `TrainerDecisionContext` role-local;
- no muta las memorias live;
- no comparte memoria privada del observer con el rival.

La observación conserva el inventario propio exacto del side evaluado y mantiene oculto el bag privado del oponente.

#### Semántica ItemAware realmente atravesada

Cada candidato SWITCH se evalúa con:

- `TrainerMultiTurnSearch` depth-1 como telemetría comparativa;
- `TrainerItemAwareSearch` depth-1 como fuente válida del contrato C3f-ac.

La ejecución confirma metadata ItemAware real, incluyendo:

- `finite_item_depth_search_v1`;
- sampler `move_switch_item_stratified_round_robin_v1`;
- resource model `own_exact_opponent_unmodeled_battle_items_v1`.

Los tres roles contienen legalmente MOVE, SWITCH e ITEM y al menos dos SWITCH candidatos. La diferencia base↔ItemAware es observada, no inferida.

En el fixture certificado:

- `root_opponent_response`: score ItemAware distinto del base y margin SWITCH ItemAware ~6917;
- `own_depth2_continuation`: score ItemAware distinto del base y margin SWITCH ItemAware ~2938;
- `opponent_depth2_continuation`: score ItemAware distinto del base y margin SWITCH ItemAware ~6691.

Los valores son evidencia del fixture, no thresholds globales ni calibración productiva.

#### Contrato margin que sí queda portable en TEST/AUDIT

Sigue vigente:

- candidate policy: `depth1_margin_3000_all_legal`;
- scope: SWITCH-only;
- score source: `TrainerItemAwareSearch` recalculado role-local;
- root fanout inicial: all-legal;
- inner cap: 3;
- `candidate_strategy_proven_safe_globally = false`.

El margin no gana autorización para mezclar MOVE/SWITCH/ITEM con un score común ni para reutilizar orden lexical. Los kind siguen separados. Tampoco se reabre la política cross-kind ya cerrada por contratos anteriores.

El cambio de estado branch-local produce cambio de score, por lo que el resultado refuerza otra restricción: un score precalculado fuera del estado/role actual tampoco es portable.

#### Límites que continúan cerrados

C3f-ac no selecciona ni reabre:

- scheduler;
- shared 660;
- strategy productiva;
- shared budget productivo;
- lexical fallback;
- frontier fallback;
- roster/Profile fallback;
- campaign/recovery/replacement fallback.

Se conserva:

- `selected_strategy_id = null`;
- `selected_scheduler_id = null`;
- `selected_shared_budget = null`;
- `shared_660_reopened = false`;
- `production_adapter_authorized = false`;
- `behavior_integration_authorized = false`;
- `production_files_modified = false`;
- `fase34_open = false`.

`PORTABLE_TEST_CONTRACT` es únicamente una conclusión de contrato TEST/AUDIT bajo estas precondiciones. No demuestra seguridad global y no autoriza ningún adapter productivo.

#### Certificación C3f-ac

Checkpoint técnico corregido:

`f3f4111b14688393afb3742f6aaa206e18142cad`

- 18/18 workflows `SUCCESS`;
- FASE33: `1079 PASS / 0 FAIL`;
- 40 checks nuevos C3f-ac;
- JSON: `tranche_status = PORTABLE_TEST_CONTRACT`;
- producción: 0 cambios.

Checkpoint humano:

`b6d93434d05eec339664bf8c0fcf5e5c67d29f61`

- 18/18 workflows `SUCCESS`;
- FASE33: `1079 PASS / 0 FAIL`;
- mismos 40 checks C3f-ac;
- mismo JSON `PORTABLE_TEST_CONTRACT`;
- mismo parent y mismo tree que el técnico corregido;
- producción: 0 cambios.

Invariantes después de certificar el humano:

- PR #105: OPEN;
- `merged = false`;
- head: `b6d93434d05eec339664bf8c0fcf5e5c67d29f61`;
- base: `main`;
- `main`: `f8452a1625ccb8389c9e52ff4416a96a24e00efd`;
- FASE34: CLOSED.

#### Decisión documental y siguiente frontera

C3f-ac queda cerrado como `PORTABLE_TEST_CONTRACT`: el contrato SWITCH margin-3000 puede trasladarse al dominio ItemAware **solo** cuando los scores son recalculados con la semántica ItemAware real y con la perspectiva role-local sanitizada correspondiente.

Antes de diseñar cualquier adapter productivo debe comprobarse que ese comportamiento no es una peculiaridad del fixture C3f-ac. La siguiente frontera debe ser un corpus nuevo, disjunto y role-local.

Se autoriza exclusivamente:

**C3f-ad — TEST/AUDIT-ONLY disjoint role-local corpus validation for the ItemAware SWITCH margin policy before any production adapter.**

Boundary exacto:

`validate_item_aware_margin_policy_on_disjoint_role_local_corpus_before_any_production_adapter`

C3f-ad deberá:

1. ser estrictamente TEST/AUDIT-only;
2. usar un corpus nuevo y disjunto del fixture C3f-ac y de los corpus históricos usados para seleccionar inicialmente `depth1_margin_3000_all_legal`;
3. cubrir los tres roles: `root_opponent_response`, `own_depth2_continuation`, `opponent_depth2_continuation`;
4. construir cada caso desde memoria side-specific válida, observación sanitizada, belief y context role-local;
5. para continuaciones, usar clones de memoria y eventos exclusivamente branch-local;
6. recalcular siempre cada score SWITCH mediante `TrainerItemAwareSearch`; queda prohibido reutilizar scores base/históricos;
7. evaluar `depth1_margin_3000_all_legal` únicamente en su dominio SWITCH;
8. registrar por caso margin, conjunto seleccionado, divergencia y cualquier pérdida/peor resultado observable frente al all-legal de referencia del propio caso;
9. distinguir resultados del corpus de cualquier afirmación global: incluso un corpus completamente verde mantendrá `candidate_strategy_proven_safe_globally = false`;
10. mantener MOVE/SWITCH/ITEM separados y no inventar un score cross-kind común;
11. mantener root fanout all-legal separado del inner cap3;
12. no usar lexical/frontier/roster/Profile/campaign/recovery/replacement como fallback semántico;
13. no reabrir ni seleccionar scheduler/660;
14. mantener `selected_strategy_id = null`, `selected_scheduler_id = null`, `selected_shared_budget = null`;
15. mantener producción, brains, search productivo y adapter productivo sin cambios;
16. mantener FASE34 CLOSED;
17. producir JSON determinista y serializable.

C3f-ad deberá terminar con una conclusión inequívoca, sin predeterminarla, entre:

- `SAFE_DISJOINT_TEST_CORPUS` — el corpus disjunto ejecutado no observa pérdida bajo el contrato auditado, sin convertirlo en prueba global;
- `NEEDS_POLICY_CHANGE` — aparecen pérdidas/divergencias que invalidan el margin actual dentro del corpus;
- `NEEDS_MORE_VALIDATION` — la evidencia ejecutable sigue siendo insuficiente para cerrar la siguiente frontera;
- `BLOCKED` — la validación exigiría información o comportamiento no autorizado.

Ninguno de esos resultados autoriza por sí solo un adapter productivo. Cualquier adapter o cambio de comportamiento productivo requerirá un freeze documental posterior y separado.
