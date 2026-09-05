

## 26.58 — Freeze C3f-aj: propuesta productiva cross-kind certificada sin sustitución; se abre solo sustitución autoritativa opt-in fail-closed

Estado: **FREEZE DOCUMENTAL / C3f-aj DOBLEMENTE CERTIFICADA / PROPOSAL PRODUCTIVA VALIDADA / SUSTITUCIÓN AUTORITATIVA TODAVÍA CERRADA**.

C3f-aj materializa en producción el contrato ya validado por C3f-ai: el lifecycle trainer puede calcular una propuesta side-specific sobre el action space legal completo MOVE/SWITCH/ITEM, usando contexto sanitizado y memoria detached, sin que esa propuesta controle todavía la acción enviada a Battle Core.

### 26.58.1 Genealogía limpia

Baseline exclusivo — freeze 26.57 certificado:

`4a8bed2310cd1fd90b0a07b5082d6330991e33d3`

Checkpoint técnico C3f-aj certificado:

`5f5cfe0b4df076d03229bfdc6af8c58c66d41600`

Checkpoint humano C3f-aj certificado:

`0fffe154d3a321d462ff5b38b9a9cefa7047c3fc`

Los dos checkpoints son siblings reales:

- parent común: `4a8bed2310cd1fd90b0a07b5082d6330991e33d3`;
- tree común: `cffe2dfd986f27aecb2966d1e5be1f27d2a19d71`;
- GitHub los reporta divergentes 1/1 con ese merge-base;
- ninguno desciende del otro.

Diff neto exacto contra 26.57:

- `modules/gameplay/trainer_battle_session.gd`: **+46 / -0**;
- `modules/trainer_ai/trainer_item_aware_action_proposal.gd`: **+384 / -0**;
- `tests/trainer_ai/trainer_battle_session_action_proposal_audit_test_suite.gd`: **+275 / -0**;
- `tests/trainer_ai/trainer_evaluation_corpus_test_runner.gd`: **+1 / -0**;
- workflows/YAML: **0 cambios**;
- brains: **0 cambios**;
- sampler/budgets/phase logic: **0 cambios**;
- Battle Core: **0 cambios**.

Existió un intento temporal de staging que pretendía ampliar el timeout de `trainer-battle-tests.yml`; GitHub lo rechazó por falta de permiso `workflows`. Ese intento nunca entró en la rama de trabajo. La solución final no modifica ningún workflow y ejecuta la auditoría pesada C3f-aj dentro del gate ya existente Evaluation Corpus, con margen suficiente.

### 26.58.2 Certificación técnica y humana

Checkpoint técnico:

- **18/18 workflows SUCCESS**;
- Trainer Team Composition run: `33944316165`;
- FASE33 literal: **`1258 PASS / 0 FAIL`**;
- 28/28 checks C3f-ai preservados;
- Trainer Evaluation Corpus run: `33944316137`;
- literal: **`72 PASS / 0 FAIL`**;
- **36 checks C3f-aj**;
- Trainer Battle Session run: `33944316211`;
- literal: **`66 PASS / 0 FAIL`**;
- **0 `SCRIPT ERROR`**, **0 traceback**, **0 líneas FAIL**, **0 `ERROR:`** en las superficies auditadas.

Checkpoint humano:

- **18/18 workflows SUCCESS**;
- Trainer Team Composition run: `33944807269`;
- FASE33 literal: **`1258 PASS / 0 FAIL`**;
- 28/28 checks C3f-ai preservados;
- Trainer Evaluation Corpus run: `33944807262`;
- literal: **`72 PASS / 0 FAIL`**;
- mismos **36 checks C3f-aj**;
- Trainer Battle Session run: `33944807288`;
- literal: **`66 PASS / 0 FAIL`**;
- **0 `SCRIPT ERROR`**, **0 traceback**, **0 líneas FAIL**, **0 `ERROR:`** en las superficies auditadas.

Los logs Team Composition técnico y humano son byte-idénticos:

`sha256:996d7590c9a6c6ffbe33463d4c3469e6186d8724c4f4716d3ff39efecb766312`

Los logs Evaluation Corpus técnico y humano también son byte-idénticos:

`sha256:ba83db5ce93edd35ac22de9143025817827122ce2e27ea2e33ca9f0050952d54`

Resultado canónico C3f-aj:

`PRODUCTION_ACTION_PROPOSAL_VALIDATED_NO_SUBSTITUTION`

No se observa nondeterminismo técnico↔humano.

### 26.58.3 Qué hace ya producción

`TrainerItemAwareActionProposal`:

1. valida BattleState, side, memoria y catálogo;
2. clona estado y memoria;
3. construye observación side-specific sanitizada;
4. construye belief únicamente desde la memoria detached permitida;
5. crea action space legal completo;
6. enumera **todos** los roots MOVE/SWITCH/ITEM;
7. evalúa cada root con `TrainerItemAwareSearch`, `TrainerProfile.balanced()` y budget depth2 común;
8. exige cobertura completa, mismos modelos y `fully_completed_depth = 2` para todos los roots;
9. compara el scalar profundo cross-kind ya certificado por C3f-ai;
10. devuelve propuesta solo si existe un máximo exacto único;
11. devuelve una `BattleAction` reconstruida/detached, no una referencia mutable del action space;
12. ante empate exacto devuelve `TIE_UNRESOLVED` y ninguna acción;
13. ante contexto, identidad, cobertura o profundidad inválidos falla cerrado y no devuelve acción.

No existe tiebreak por lexical, input order, prioridad MOVE/SWITCH/ITEM, sampler, Pareto/frontier, roster value, `TrainerProfile`, campaign/recovery/replacement ni RNG.

### 26.58.4 Evidencia lifecycle productiva

En el fixture certificado side_b:

`current_side_b`:

- roots legales: **10**;
- MOVE: 2;
- SWITCH: 2;
- ITEM: 6;
- roots evaluados: **10/10**;
- profundidad común: **2**;
- simulaciones: **56 por root**;
- ganador único: `move:c3fad_chip_b`;
- score ganador: `1292`.

`branch_side_b`:

- roots legales: **10**;
- roots evaluados: **10/10**;
- profundidad común: **2**;
- simulaciones: **56 por root**;
- ganador único: `move:c3fad_chip_b`;
- score ganador: `1257`.

Estos scores y roots coinciden con la evidencia C3f-ai. La materialización productiva no altera el contrato previo.

### 26.58.5 Barrera autoritativa demostrada

`TrainerBattleSession` expone proposal current/branch y un toggle independiente, **OFF por defecto**.

Con proposal ON, la sesión calcula y guarda telemetría antes del submit, pero la línea autoritativa continúa literalmente:

`_battle_server.submit_turn([player_action, opponent_action])`

Por tanto:

- `opponent_action` del caller sigue siendo obligatorio;
- la proposal no reemplaza `opponent_action`;
- proposal ON/OFF con mismos inputs produce el mismo action/event/state autoritativo;
- el estado live y las memorias live no son mutados por calcular la propuesta;
- settlement/reset desactivan y limpian proposal;
- no existe fallback silencioso desde proposal hacia otra política.

Campos canónicos continúan cerrados en C3f-aj:

- `behavior_integration_authorized = false`;
- `action_substitution_authorized = false`;
- `selected_strategy_id = null`;
- `selected_scheduler_id = null`;
- `selected_shared_budget = null`;
- `fase34_open = false`.

### 26.58.6 Siguiente microtranche autorizada: C3f-ak primera sustitución autoritativa controlada

Tras certificar este freeze, se autoriza exclusivamente:

**C3f-ak — introducir una sustitución autoritativa opt-in y OFF por defecto para side_b trainer lifecycle que, cuando la proposal C3f-aj sea `PROPOSAL_READY`, única, completa, side-matching, legal y detached, envíe exactamente esa proposal a Battle Core en lugar del `opponent_action` aportado por el caller; ante cualquier empate, incompletitud o bloqueo debe fallar cerrado sin ejecutar turno y sin usar el action del caller como fallback silencioso.**

C3f-ak deberá:

1. añadir un toggle de sustitución separado, OFF por defecto;
2. mantener inicialmente la firma `submit_player_action(player_action, opponent_action)` sin hacer opcional `opponent_action`;
3. con sustitución OFF, conservar comportamiento exactamente idéntico a C3f-aj;
4. con sustitución ON, calcular proposal actual side_b mediante la superficie C3f-aj ya certificada;
5. aceptar sustitución solo si el reporte está listo, tiene máximo único, profundidad común 2, cobertura completa y acción detached válida/legal para side_b;
6. enviar a Battle Core **exactamente** la propuesta validada, no una reconstrucción semánticamente distinta;
7. usar en test un `opponent_action` caller deliberadamente distinto para demostrar que la sustitución ocurrió;
8. verificar por eventos/estado que la acción ejecutada es la proposal y no la del caller;
9. mantener la memoria autoritativa coherente con la acción realmente ejecutada;
10. ante `TIE_UNRESOLVED`, contexto inválido, memoria inválida, cobertura/profundidad incompleta o acción propuesta no legal: **fail closed / no turn**;
11. NO caer silenciosamente al `opponent_action` caller cuando sustitución ON falla;
12. NO usar lexical, input order, kind priority, sampler, RNG, Pareto/frontier, roster value, Profile, campaign/recovery/replacement ni hidden beliefs como fallback;
13. conservar root fan-out all-legal separado del inner cap3;
14. no modificar brains, sampler, search budget, phase logic ni Battle Core;
15. no reabrir scheduler/shared budget/660;
16. mantener `selected_strategy_id = null`, `selected_scheduler_id = null`, `selected_shared_budget = null`;
17. limitar `behavior_integration_authorized` estrictamente a esta sustitución side_b opt-in, sin convertirla en autorización general de Trainer Brain;
18. mantener FASE34 CLOSED;
19. no mergear PR #105.

Resultados admisibles C3f-ak:

- `AUTHORITATIVE_SIDE_B_SUBSTITUTION_VALIDATED`;
- `AUTHORITATIVE_SIDE_B_SUBSTITUTION_VALIDATED_WITH_FAIL_CLOSED_BLOCKERS`;
- `NEEDS_MORE_VALIDATION`;
- `BLOCKED`.

Incluso un resultado validado no autoriza retirar todavía el `opponent_action` caller, conectar un brain general, abrir scheduler/shared budget ni abrir FASE34. Un freeze posterior deberá decidir cualquier ampliación.

### 26.58.7 Invariantes externas

PR #105 debe permanecer **OPEN / unmerged**.

`main` permanece bajo ownership externo y, al certificar C3f-aj, continúa en:

`641d4b1fb0bcf964205d616e96f198f05d702197`

C3f-aj queda por tanto **DOBLEMENTE CERTIFICADA** como `PRODUCTION_ACTION_PROPOSAL_VALIDATED_NO_SUBSTITUTION`; el único siguiente paso autorizado tras CI-clean freeze es C3f-ak bajo las barreras anteriores.
