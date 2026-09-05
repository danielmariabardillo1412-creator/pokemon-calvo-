

## 26.57 — Freeze C3f-ai: score profundo cross-kind MOVE/SWITCH/ITEM comparable; se autoriza solo propuesta productiva read-only antes de cualquier sustitución

Estado: **FREEZE DOCUMENTAL / C3f-ai DOBLEMENTE CERTIFICADA / COMPARABILIDAD CROSS-KIND VALIDADA / COMPORTAMIENTO AUTORITATIVO TODAVÍA CERRADO**.

C3f-ai cierra la barrera abierta por 26.56: el scalar final de `TrainerItemAwareSearch.evaluate(context, root_action)` puede compararse entre roots MOVE, SWITCH e ITEM cuando todos se evalúan bajo el mismo contexto sanitizado, mismo perfil, mismo modelo, mismo budget y una profundidad completamente terminada común.

### 26.57.1 Genealogía limpia

Baseline exclusivo — freeze 26.56 certificado:

`de505cfaa157ac88f0d927332efe81c5654f4379`

Checkpoint técnico C3f-ai certificado:

`a96d5a766cc73a8fcbaaf4304ce0388811d40501`

Checkpoint humano C3f-ai certificado:

`aab800003db1cb5f7a8a14b3c866ed6aa0c50bda`

Los dos checkpoints son siblings reales:

- parent común: `de505cfaa157ac88f0d927332efe81c5654f4379`;
- tree común: `e6ba11b8b18aa2f76c083fd25ce23b3cab947bd4`;
- ninguno desciende del otro.

Diff exacto contra 26.56:

- `tests/trainer_ai/trainer_roster_search_cross_kind_deep_score_comparability_audit_test_suite.gd`: **+343 / -0**;
- `tests/trainer_ai/trainer_team_composition_test_runner.gd`: **+1 / -1**;
- producción: **0 cambios**;
- brains: **0 cambios**;
- sampler/budgets/phase logic: **0 cambios**.

Existió un precursor técnico rechazado, `501a3c5cc8a4f89ba06060d9b26c0499ce165600`, que no llegó a ejecutar la auditoría por una colisión de nombre de constante en el test (`BLOCKED` heredado). Ese precursor no pertenece a la línea certificada. La reparación reconstruyó el checkpoint técnico limpio directamente sobre 26.56 y no cambió la lógica auditada.

### 26.57.2 Certificación técnica y humana

Checkpoint técnico:

- **18/18 workflows SUCCESS**;
- Trainer Team Composition run: `33943026259`;
- FASE33 literal: **`1258 PASS / 0 FAIL`**;
- **28 checks C3f-ai nuevos** sobre los 1230 anteriores;
- **0 `SCRIPT ERROR`**;
- **0 traceback**;
- **0 líneas FAIL**;
- **0 líneas `ERROR:`**.

Checkpoint humano:

- **18/18 workflows SUCCESS**;
- Trainer Team Composition run: `33943288001`;
- FASE33 literal: **`1258 PASS / 0 FAIL`**;
- mismos 28 checks C3f-ai;
- **0 `SCRIPT ERROR`**;
- **0 traceback**;
- **0 líneas FAIL**;
- **0 líneas `ERROR:`**.

Los logs `trainer-team-composition-test.log` son byte-idénticos:

`sha256:996d7590c9a6c6ffbe33463d4c3469e6186d8724c4f4716d3ff39efecb766312`

Resultado canónico:

`CROSS_KIND_DEEP_SCORE_COMPARABILITY_VALIDATED`

No se observa nondeterminismo entre técnico y humano.

### 26.57.3 Qué demuestra exactamente C3f-ai

La auditoría ejecuta cuatro contextos lifecycle side-specific y detached:

- `current_side_a`;
- `current_side_b`;
- `branch_side_a`;
- `branch_side_b`.

En cada contexto el action space completo contiene exactamente:

- MOVE: **2**;
- SWITCH: **2**;
- ITEM: **6**;
- total roots legales: **10**.

Los 10 roots son enumerados en root fan-out all-legal. El inner `max_actions_per_side = 3` sigue siendo únicamente el límite interno de respuestas/continuaciones del search y no poda roots.

Todos los roots comparados cumplen:

- `fully_completed_depth = 2`;
- mismo `TrainerItemAwareSearch`;
- mismo `TrainerProfile.balanced()`;
- mismo world model;
- mismo budget auditado;
- misma agregación robusta;
- **56 simulaciones por root**;
- invariancia frente al orden del conjunto de roots.

El pipeline de score auditado no contiene normalización por action kind:

- `TrainerItemAwareSearch` delega el score a la cadena de search base;
- `TrainerSearchStateEvaluator` no depende de `BattleAction.action_type`;
- MOVE, SWITCH e ITEM desembocan en la misma escala de estado HP/KO/status/terminal;
- la agregación robusta final es común a los tres kinds.

Por tanto no existe una prioridad implícita `MOVE > SWITCH > ITEM` ni ninguna conversión específica por kind dentro del scalar comparado.

### 26.57.4 Resultado lifecycle: ganador MOVE por score, no por prioridad fija

Resultados observados:

- `current_side_a`: `move:c3fad_chip_a = 882` → ganador MOVE;
- `current_side_b`: `move:c3fad_chip_b = 1292` → ganador MOVE;
- `branch_side_a`: `move:c3fad_chip_a = 865` → ganador MOVE;
- `branch_side_b`: `move:c3fad_chip_b = 1257` → ganador MOVE.

Los cuatro resultados son `SINGLE_ROOT_CONTRACT` con máximo cross-kind único.

Este patrón no autoriza una preferencia fija por MOVE. Los MOVE ganan únicamente porque su score profundo es superior en estos cuatro fixtures.

El subconjunto SWITCH coincide exactamente con C3f-ah en los cuatro contextos (`switch_coherent = true`), demostrando que la comparación cross-kind no altera retrospectivamente el contrato SWITCH ya certificado.

### 26.57.5 Empates e incompletitud siguen fail-closed

Probe sintético cross-kind de empate:

- MOVE = `100`;
- ITEM = `100`;
- profundidad común = 2;
- outcome: `TIE_UNRESOLVED`;
- `selected_root_id = ""`.

No se usa prioridad por kind, lexical, input order, sampler ni RNG para romper el empate.

Probe sintético de profundidad desigual:

- un root a depth2;
- otro root a depth1;
- outcome: `INCOMPLETE_COMMON_DEPTH`;
- ninguna acción seleccionada.

Por tanto la comparabilidad validada no introduce descenso silencioso de calidad ni un fallback oculto.

### 26.57.6 Qué NO cambia todavía

C3f-ai continúa siendo estrictamente **TEST/AUDIT/CONTRACT-ONLY**.

No modifica:

- `TrainerBattleSession`;
- `TrainerItemAwareShadowProbe`;
- production search;
- brains;
- sampler;
- budgets;
- phase logic;
- Battle Core.

Siguen cerrados:

- `behavior_integration_authorized = false`;
- `action_substitution_authorized = false`;
- `selected_strategy_id = null`;
- `selected_scheduler_id = null`;
- `selected_shared_budget = null`;
- `fase34_open = false`.

PR #105 debe permanecer **OPEN / unmerged**.

`main` permanece bajo ownership externo y continúa en:

`641d4b1fb0bcf964205d616e96f198f05d702197`

### 26.57.7 Siguiente microtranche autorizada: C3f-aj propuesta productiva all-legal, todavía read-only

Se autoriza exclusivamente:

**C3f-aj — materializar en producción un selector/proposal seam read-only que reproduzca el contrato C3f-ai sobre el lifecycle side_b, devuelva una acción propuesta detached/canónica cuando exista un máximo profundo cross-kind único y falle cerrado ante empate/incompletitud, sin sustituir todavía la acción autoritativa enviada a Battle Core.**

Objetivo: mover el contrato ya validado desde una suite audit-only a una superficie productiva observable, pero mantener separadas dos fronteras:

1. `puedo calcular una acción propuesta en producción`;
2. `esa propuesta controla realmente el combate`.

C3f-aj deberá:

1. reutilizar memoria side-specific detached y contexto sanitizado;
2. enumerar todos los roots legales MOVE/SWITCH/ITEM;
3. mantener root fan-out all-legal separado del inner cap3;
4. evaluar todos los roots con el mismo search/profile/budget/profundidad 2;
5. aceptar propuesta solo con cobertura/profundidad completa común;
6. devolver una copia detached/canónica del root ganador, no una referencia mutable del action space;
7. devolver `TIE_UNRESOLVED` sin acción ante máximo exacto múltiple;
8. devolver estado fail-closed sin acción ante contexto, memoria, cobertura o profundidad inválidos;
9. conservar metadata suficiente para auditar root ids, kinds, scores, depths y simulaciones;
10. comprobar paridad exacta con la evidencia C3f-ai en current side_b y branch side_b;
11. no usar lexical/input order/prioridad de kind/sampler como tiebreak;
12. no usar Pareto/frontier/roster/Profile/campaign/recovery/replacement/hidden belief/live RNG como fallback;
13. no cambiar brains, sampler, budgets ni phase logic;
14. no tocar Battle Core;
15. no cambiar todavía `submit_player_action(player_action, opponent_action)` ni hacer opcional `opponent_action`;
16. no sustituir `opponent_action` aunque exista una propuesta válida;
17. probar que proposal OFF/ON deja idénticos action/event/state autoritativos cuando el caller entrega el mismo `opponent_action`;
18. mantener FASE34 CLOSED.

Resultados admisibles:

- `PRODUCTION_ACTION_PROPOSAL_VALIDATED_NO_SUBSTITUTION`;
- `PRODUCTION_ACTION_PROPOSAL_VALIDATED_WITH_UNRESOLVED_TIES`;
- `NEEDS_MORE_VALIDATION`;
- `BLOCKED`.

Incluso el resultado validado **no autoriza todavía comportamiento real**. Solo el freeze posterior a C3f-aj podrá decidir si existe evidencia suficiente para abrir la primera sustitución autoritativa controlada.

C3f-ai queda por tanto **DOBLEMENTE CERTIFICADA** como `CROSS_KIND_DEEP_SCORE_COMPARABILITY_VALIDATED`; la siguiente frontera autorizada es únicamente C3f-aj proposal/read-only.