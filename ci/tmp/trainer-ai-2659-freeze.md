## 26.59 — Freeze C3f-ak: primera sustitución autoritativa side_b certificada; caller y autonomía general permanecen cerrados

Estado: **FREEZE DOCUMENTAL / C3f-ak DOBLEMENTE CERTIFICADA / SUSTITUCIÓN AUTORITATIVA SIDE_B VALIDADA / AUTONOMÍA GENERAL TODAVÍA CERRADA**.

C3f-ak cruza por primera vez la frontera entre «la IA propone» y «la acción propuesta llega realmente a Battle Core». La integración está deliberadamente limitada a un toggle explícito, OFF por defecto, sobre side_b y con fail-closed estricto.

### 26.59.1 Genealogía limpia

Baseline exclusivo — freeze 26.58 certificado:

`0e073fcc68b137b104075f7af68676489b78151f`

Checkpoint técnico C3f-ak certificado:

`5f4adc7fc5dd069b5aa5c52dd8519c3a7fefd5d4`

Checkpoint humano C3f-ak certificado:

`0ee23b1a56438bb42d18ddbeaef8faa2974ead7c`

Los dos checkpoints son siblings reales:

- parent común: `0e073fcc68b137b104075f7af68676489b78151f`;
- tree común: `63a123402ea38888ade733fdf746fe90959d08e4`;
- GitHub los reporta divergentes 1/1 con ese merge-base;
- ninguno desciende del otro.

Diff neto exacto contra 26.58:

- `modules/gameplay/trainer_battle_session.gd`: **+217 / -2**;
- `tests/trainer_ai/trainer_battle_session_authoritative_substitution_audit_test_suite.gd`: **+238 / -0**;
- `tests/trainer_ai/trainer_evaluation_corpus_test_runner.gd`: **+1 / -0**;
- workflows/YAML finales: **0 cambios**;
- brains: **0 cambios**;
- sampler: **0 cambios**;
- search budgets: **0 cambios**;
- phase logic: **0 cambios**;
- Battle Core: **0 cambios**.

La preparación temporal de C3f-ak tuvo fallos mecánicos de staging —YAML no parseable, payload base64 truncado y correcciones de tipado/harness—. Ninguno de esos intentos entró en la rama certificada. El checkpoint técnico final fue reconstruido directamente sobre 26.58 con el tree neto anterior.

### 26.59.2 Certificación técnica

Checkpoint técnico `5f4adc7fc5dd069b5aa5c52dd8519c3a7fefd5d4`:

- **18/18 workflows SUCCESS**;
- Trainer Evaluation Corpus run: `33961701026`;
- job: `101294581819`;
- literal: **`106 PASS / 0 FAIL`**;
- **34/34 checks C3f-ak PASS**;
- aggregate C3f-ak: `AUTHORITATIVE_SIDE_B_SUBSTITUTION_VALIDATED_WITH_FAIL_CLOSED_BLOCKERS`;
- artifact id: `9968141670`;
- Trainer Team Composition run: `33961701035`;
- job: `101294581764`;
- literal FASE33: **`1258 PASS / 0 FAIL`**;
- **28/28 checks C3f-ai** preservados;
- test-log Team SHA256: `996d7590c9a6c6ffbe33463d4c3469e6186d8724c4f4716d3ff39efecb766312`;
- Trainer Battle Session run: `33961701034`;
- job: `101294581671`;
- literal: **`66 PASS / 0 FAIL`**;
- **0 `SCRIPT ERROR`**, **0 traceback**, **0 líneas FAIL**, **0 `ERROR:`** en las superficies auditadas.

### 26.59.3 Certificación humana sibling

Checkpoint humano `0ee23b1a56438bb42d18ddbeaef8faa2974ead7c`:

- **18/18 workflows SUCCESS**;
- Trainer Evaluation Corpus run: `33964079118`;
- job: `101300935725`;
- literal: **`106 PASS / 0 FAIL`**;
- **34/34 checks C3f-ak PASS**;
- mismo aggregate: `AUTHORITATIVE_SIDE_B_SUBSTITUTION_VALIDATED_WITH_FAIL_CLOSED_BLOCKERS`;
- artifact id: `9968860808`;
- Trainer Team Composition run: `33964079073`;
- job: `101300935655`;
- literal FASE33: **`1258 PASS / 0 FAIL`**;
- **28/28 checks C3f-ai** preservados;
- test-log Team SHA256: `996d7590c9a6c6ffbe33463d4c3469e6186d8724c4f4716d3ff39efecb766312`;
- Trainer Battle Session run: `33964079089`;
- job: `101300935642`;
- literal: **`66 PASS / 0 FAIL`**;
- **0 `SCRIPT ERROR`**, **0 traceback**, **0 líneas FAIL**, **0 `ERROR:`** en las superficies auditadas.

Los logs Evaluation Corpus técnico y humano son byte-idénticos:

`sha256:adf3c2b0c4af7100e07d6dbb7bb9d94fae6fe47aad64d98be70e5596776a0c5d`

Los logs Battle Session técnico y humano son byte-idénticos:

`sha256:123f2fd6ae75bf9907d3eb5364f9d43cc2e3916788ade19063ca32ae48c06f75`

No se observa nondeterminismo técnico↔humano.

### 26.59.4 Qué cambia realmente en comportamiento

C3f-ak añade a `TrainerBattleSession` un toggle independiente:

`set_trainer_action_substitution_enabled(enabled)`

Contrato:

- OFF por defecto;
- limitado a side_b;
- `opponent_action` del caller continúa siendo obligatorio;
- con sustitución OFF, el camino histórico sigue enviando exactamente el action del caller;
- con sustitución ON, la sesión recalcula una proposal C3f-aj actual y side-specific;
- solo una proposal `PROPOSAL_READY`, única, completa, depth2, detached y legal puede sustituir;
- antes de submit se revalida la acción propuesta contra el action space legal del servidor autoritativo actual;
- si la validación pasa, Battle Core recibe exactamente la acción propuesta;
- si falla cualquier requisito, no se ejecuta turno;
- cuando ON falla, **no existe fallback al `opponent_action` caller**.

La igualdad legal no depende de JSON ni de orden textual. Se valida sobre los campos canónicos de `BattleAction`:

- `turn`;
- `action_type`;
- `side_id`;
- `actor_id`;
- `move_id`;
- `target_id`;
- `switch_instance_id`;
- `item_id`.

### 26.59.5 Evidencia inequívoca de sustitución real

El fixture C3f-ak entrega deliberadamente desde el caller:

`move:c3fad_setup_b`

La proposal C3f-aj certificada elige:

`move:c3fad_chip_b`

Con sustitución OFF:

- el turno ejecuta `setup_b`;
- memoria autoritativa revela `setup_b`;
- no existe substitution report.

Con sustitución ON:

- proposal status: `PROPOSAL_READY`;
- roots legales/evaluados: **10/10**;
- profundidad común: **2**;
- simulaciones: **56 por root**;
- selected root: `move:c3fad_chip_b`;
- substitution status: `SUBSTITUTION_READY`;
- submitted root: `move:c3fad_chip_b`;
- memoria autoritativa revela `chip_b` y no `setup_b`;
- el objeto `opponent_action` del caller permanece sin mutación;
- `caller_fallback_used = false`.

Esto demuestra una sustitución autoritativa real y observable, no una inferencia basada únicamente en telemetría.

### 26.59.6 Fail-closed certificado

C3f-ak prueba explícitamente que no hay turno ni fallback silencioso ante:

- `TIE_UNRESOLVED`;
- profundidad común incompleta;
- proposal no legal en el estado actual;
- proposal de turno stale;
- lifecycle/memoria rota;
- caller `opponent_action` ausente.

También permanecen cerrados todos los tiebreak/fallback no autorizados:

- lexical;
- input order;
- prioridad fija por kind;
- sampler;
- live RNG;
- Pareto/frontier;
- roster value;
- TrainerProfile;
- campaign;
- recovery;
- replacement;
- hidden beliefs.

Y siguen cerrados:

- `trainer_brain_integration_authorized = false`;
- `selected_strategy_id = null`;
- `selected_scheduler_id = null`;
- `selected_shared_budget = null`;
- `shared_660_reopened = false`;
- `fase34_open = false`.

### 26.59.7 Invariantes externas

PR #105 continúa **OPEN / unmerged**.

`main` continúa exactamente en:

`641d4b1fb0bcf964205d616e96f198f05d702197`

La sustitución C3f-ak no autoriza merge, cambio de main ni apertura de FASE34.

### 26.59.8 Qué NO queda autorizado todavía

C3f-ak **NO** autoriza todavía:

- hacer opcional o eliminar `opponent_action` del caller;
- activar sustitución por defecto;
- declarar que todos los entrenadores del juego usan ya esta IA;
- integrar un Trainer Brain general;
- inventar política para forced replacement;
- inventar recuperación/campaign/scheduler;
- usar propuestas stale/cached entre turnos;
- relajar los bloqueos de empate/incompletitud.

La primera sustitución de un turno está certificada; todavía falta demostrar que el lifecycle permanece correcto cuando la IA decide repetidamente sobre un estado que ella misma acaba de modificar.

### 26.59.9 Siguiente microtranche autorizada: C3f-al auditoría multi-turn de sustitución fresca

Se autoriza exclusivamente:

**C3f-al — auditar, sin ampliar todavía la superficie productiva, que la sustitución side_b C3f-ak funciona de forma coherente durante varios turnos ordinarios consecutivos, recalculando una proposal fresca después de cada batch autoritativo y consumiendo la memoria/estado actualizados, sin reutilizar una proposal stale y manteniendo el caller todavía obligatorio.**

C3f-al será **TEST/AUDIT-ONLY** salvo que la auditoría demuestre un blocker imposible de observar sin una corrección mínima explícitamente documentada.

Deberá comprobar al menos:

1. sustitución sigue OFF por defecto;
2. al activar ON, cada turno obtiene una proposal nueva para el `state.turn` actual;
3. el turno N+1 no reutiliza el `proposal_action` ni el report del turno N;
4. memoria side_b incorpora los eventos autoritativos del turno anterior antes del siguiente cálculo;
5. `last_observed_turn` permanece coherente con el estado;
6. la proposal del turno N+1 usa la identidad/actor/target vigentes;
7. cada proposal vuelve a pasar legalidad exacta contra el action space live;
8. el caller action continúa siendo obligatorio en cada turno;
9. el caller no se usa como fallback cuando ON falla;
10. OFF conserva el comportamiento histórico;
11. un report/proposal stale del turno anterior sería rechazado por contrato;
12. no hay cache/reuse oculto de scores, roots o acciones entre turnos;
13. root fan-out all-legal permanece separado del inner cap3;
14. no se modifica search budget, sampler, brains, phase logic ni Battle Core;
15. no se introduce forced-replacement policy;
16. no se inventan campaign/recovery/replacement semantics;
17. no se abre scheduler/shared budget/660;
18. `selected_strategy_id`, `selected_scheduler_id` y `selected_shared_budget` permanecen `null`;
19. FASE34 permanece CLOSED;
20. PR #105 permanece OPEN/unmerged.

Resultados admisibles C3f-al:

- `MULTI_TURN_AUTHORITATIVE_SUBSTITUTION_VALIDATED`;
- `MULTI_TURN_AUTHORITATIVE_SUBSTITUTION_VALIDATED_WITH_FAIL_CLOSED_BOUNDARY`;
- `NEEDS_MORE_VALIDATION`;
- `BLOCKED`.

Incluso un resultado validado **no autoriza por sí solo** retirar el `opponent_action` caller ni activar la IA por defecto. Esa decisión solo podrá abrirse en el freeze posterior si la evidencia multi-turn queda limpia.

C3f-ak queda por tanto **DOBLEMENTE CERTIFICADA** como `AUTHORITATIVE_SIDE_B_SUBSTITUTION_VALIDATED_WITH_FAIL_CLOSED_BLOCKERS`; la siguiente frontera autorizada es únicamente C3f-al multi-turn audit-only.