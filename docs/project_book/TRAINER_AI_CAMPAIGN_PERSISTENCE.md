# Trainer AI — Campaign Persistence V1

## Estado final

**CLOSED / CERTIFIED / FROZEN**.

Campaign Persistence V1 ha terminado. No existe P1-E ni una quinta tranche pendiente.

Rama de snapshot:

`feature/trainer-ai-campaign-persistence-v1`

Parent original del workstream:

`f43dc6b158c35fe25139de5524b83f6fe2d3426f`

Ese parent corresponde al freeze certificado de **Trainer AI Expertise V1**.

Parent documental certificado de entrada a P1-D:

`bf604176a66abde8ad475dd54f7375420c21c06b`

Checkpoint técnico final P1-D:

`b314b8bb81db439e3063433644c691181ed39ef4`

PR de snapshot:

`#107` — debe cerrarse **sin merge** después de que el HEAD documental final pase 18/18 CI.

Campaign Persistence no reabre C3f, Game-Ready 27.x, Expertise V1, FASE34, scheduler/shared-budget/660 ni Battle Core.

## Distinción canónica

No confundir:

- **estado de batalla**: HP/PP/status/active/turn y forced replacement mientras Battle Core está activo;
- **roster owned por campaign**: `CreatureInstance` que existe fuera de `TrainerBattleSession` y se reutiliza por identidad;
- **persistencia de campaña**: identidad/roster/configuración y consecuencias persistentes que sobreviven deliberadamente entre encuentros;
- **recovery policy**: operación explícita para restaurar entre encuentros;
- **replacement policy**: operación explícita para sustituir miembros fuera de batalla;
- **forced replacement de Battle Core**: cambio obligatorio durante batalla, no campaign replacement.

Campaign/recovery/replacement permanece fuera de la decisión de combate. Nunca es un fallback oculto para proposal, search, tie resolution o selección de acción.

### `campaign_snapshot` histórico

Existe transporte histórico de `campaign_snapshot` en `TrainerIntelligenceController`/`TrainerDecisionContext`, con copia profunda del DTO. Ese transporte **no es el owner persistente de campaña** ni source of truth.

El path Game-Ready de `TrainerItemAwareActionProposal` continúa sin conectar ese snapshot. Campaign Persistence V1 no altera esa frontera.

## Plan ejecutado — 4/4 tramos

1. **P1-A — ownership/persistence boundary audit** — CLOSED / CERTIFIED / TEST-AUDIT-ONLY.
2. **P1-B — persistent-state + recovery/replacement contract** — CLOSED / CERTIFIED / CONTRACT-FIRST.
3. **P1-C — minimal production integration** — CLOSED / CERTIFIED.
4. **P1-D — rematch/cross-battle E2E + regression + freeze** — CLOSED / CERTIFIED.

No añadir una quinta tranche por inercia. Cualquier ampliación futura es un workstream distinto y opcional.

## P1-A — CLOSED / CERTIFIED

Checkpoint técnico original:

`26c11caa635cecb851b95cd636580cb250683a32`

Suite:

`TrainerCampaignPersistenceBoundaryAuditTestSuite`

Resultado original:

`CAMPAIGN_PERSISTENCE_OWNERSHIP_SEAM_LOCALIZED`

Evidencia:

- P1-A: **23/23 PASS**;
- Trainer Evaluation Corpus: **521 PASS / 0 FAIL**;
- full CI: **18/18 workflows SUCCESS**;
- 0 producción / 0 Battle Core.

P1-A localizó que `TrainerBattleSession` consume referencias externas de `CreatureInstance`, BattleState/session comparte esas identidades, settlement reconcilia y la sesión libera después su roster interno.

Durante P1-C y P1-D la auditoría histórica se hizo forward-compatible sin reducir sus 23 checks: acepta la forma histórica o el sucesor explícitamente autorizado, y sigue exigiendo la misma separación respecto de combat AI.

## P1-B — CLOSED / CERTIFIED / CONTRACT-FIRST

Checkpoint técnico:

`f900fb79fb324c6e05d218eb741352e4d3a5db1f`

Suite:

`TrainerCampaignPersistenceContractAuditTestSuite`

Evidencia:

- P1-B: **27/27 PASS**;
- Evaluation: **548 PASS / 0 FAIL**;
- full CI: **18/18 workflows SUCCESS**;
- 0 producción / 0 Battle Core.

Contrato fijado sobre la misma `CreatureInstance`:

- HP reducido persiste tras `reconcile_post_battle()`;
- PP consumido persiste;
- persistent status persiste;
- volatile status se elimina;
- stat stages se restablecen;
- identidad del objeto se conserva;
- no existe auto-heal implícito.

Contrato canónico:

1. owner autoritativo fuera de `BattleState` y `TrainerBattleSession`;
2. mismas `CreatureInstance`, sin clones de identidad;
3. post-battle base = `reconcile_post_battle()`;
4. recovery inter-battle explícito;
5. campaign replacement fuera de batalla y distinto de forced replacement;
6. IDs duplicados/ownership ambiguo fallan cerrado;
7. no se persiste `BattleState`;
8. `campaign_snapshot` es como máximo DTO detached, nunca authority;
9. Campaign Persistence no entra en combat AI.

HEAD documental P1-B certificado:

`4e96c999818916e90c6f8e9bfbc381f516e347dc` — **18/18 SUCCESS**.

## P1-C — CLOSED / CERTIFIED / MINIMAL PRODUCTION INTEGRATION

Checkpoint técnico:

`311349938af6c57f4507e2160e157cffbc124afb`

Suite:

`TrainerCampaignPersistenceOwnerIntegrationTestSuite`

Resultado:

`CAMPAIGN_PERSISTENCE_OWNER_INTEGRATED`

Evidencia:

- P1-C: **34/34 PASS**;
- P1-A forward-compatible: **23/23 PASS**;
- P1-B: **27/27 PASS**;
- Evaluation: **582 PASS / 0 FAIL**;
- Godot 4.7: SUCCESS;
- Team Composition: SUCCESS;
- full CI: **18/18 workflows SUCCESS**.

Owner productivo:

`modules/gameplay/trainer_campaign_roster_owner.gd`

`TrainerCampaignRosterOwner`:

- posee `trainer_id` y roster estable;
- conserva exactamente las mismas referencias de `CreatureInstance`;
- `roster_for_battle()` desacopla solo el contenedor `Array`;
- configuración, ownership y replacement fallan cerrado y son atómicos;
- rechaza nulls, IDs vacíos, duplicados y rebind silencioso de identidad;
- `recover_creature_full(...)` es una operación explícita;
- `replace_member(...)` es campaign replacement explícito fuera de Battle Core.

Overworld sustituyó `_trainer_roster` ad-hoc por `_trainer_campaign_owner`. P1-C mantuvo temporalmente el one-shot para reservar rematch a P1-D.

### Incidente P1-C

Primer intento productivo `d3238725e564f0ab8cf11ab592c5fcb3c715a096` produjo **578 PASS / 4 FAIL** aunque P1-C estaba 34/34. Los cuatro fallos eran asserts P1-A que congelaban literalmente la forma anterior a la existencia del owner.

Se corrigió únicamente la auditoría histórica, sin reducir checks ni barreras. El checkpoint `311349...` quedó **582/0** y **18/18**.

HEAD documental P1-C certificado y parent exacto de P1-D:

`bf604176a66abde8ad475dd54f7375420c21c06b` — **18/18 SUCCESS**.

## P1-D — CLOSED / CERTIFIED / FINAL E2E

Checkpoint técnico final:

`b314b8bb81db439e3063433644c691181ed39ef4`

Suite:

`TrainerCampaignPersistenceRematchE2EClosureTestSuite`

Audit ID:

`p1_d_campaign_persistence_rematch_e2e_closure_v1`

Resultado:

`CAMPAIGN_PERSISTENCE_REMATCH_E2E_CLOSED`

### Evidencia final P1-D

- P1-D: **46/46 PASS**;
- P1-A: 23/23 PASS;
- P1-B: 27/27 PASS;
- P1-C: 34/34 PASS;
- Trainer Evaluation Corpus: **628 PASS / 0 FAIL**;
- Godot 4.7 regression: **SUCCESS**;
- Team Composition: **SUCCESS**;
- full CI del checkpoint técnico: **18/18 workflows SUCCESS**.

### Ciclo E2E certificado

P1-D demuestra por la ruta ejecutable real:

`primer combate -> settlement -> rival KO persiste -> revancha inmediata bloqueada -> recovery explícito -> misma CreatureInstance -> segundo combate real`

Concretamente:

1. el primer combate recibe exactamente la `CreatureInstance` owned por campaign;
2. el jugador vence y settlement deja al rival en 0 HP sobre esa misma instancia;
3. continue/reset de `TrainerBattleSession` no cura ni reemplaza esa instancia;
4. una revancha inmediata falla cerrado con el error exacto `no_available_opponent_creature`;
5. el intento fallido no crea combate ni auto-cura al rival;
6. `recover_demo_trainer_full()` ejecuta recovery explícito fuera de batalla;
7. recovery conserva la misma referencia, restaura HP/PP y limpia persistent status conforme al contrato;
8. el segundo combate vuelve a usar exactamente la misma `CreatureInstance`;
9. el segundo encuentro comienza en turn 0 con memoria fresca;
10. una acción real del jugador produce la respuesta autónoma side_b, avanza turno y mantiene `caller_fallback_used = false`;
11. `campaign_policy_used`, `recovery_policy_used` y `replacement_policy_used` permanecen `false` dentro del combat AI.

### Cambio productivo P1-D

P1-D modifica únicamente la integración técnica de Overworld para:

- retirar el candado artificial `_trainer_demo_completed`;
- permitir un nuevo intento de combate contra el mismo owner;
- añadir `recover_demo_trainer_full()` como acción explícita inter-battle.

El bloqueo por rival KO procede naturalmente de `TrainerBattleSession.begin_battle()`; no se añadió una segunda arquitectura de bloqueo.

No existe auto-recovery en `_on_trainer_battle_closed`.

### Incidente P1-D

Primer HEAD P1-D:

`c0375c70fe15f76e0a75e51726ec9b083824b166`

Resultado Evaluation:

**626 PASS / 2 FAIL**.

Los dos fallos fueron exclusivamente:

- `p1d_source_scope_isolated`;
- `p1d_status_closed`.

El runtime E2E estaba verde. La causa fue una auditoría estática que buscaba literalmente `BattleState` dentro del source del owner y encontró esa palabra en un comentario que documentaba precisamente que el owner vive fuera de BattleState.

Corrección test-only:

`b314b8bb81db439e3063433644c691181ed39ef4`

La auditoría pasó a comprobar dependencias operativas prohibidas (`SaveGameData`, `_battle_server`, proposal/search/tie resolver) en vez de una coincidencia textual de comentario. No cambió producción. El resultado final fue **46/46 P1-D, 628/0 Evaluation y 18/18 CI**.

## Scope final congelado

Campaign Persistence V1 **no** modifica:

- Save V2;
- Battle Core;
- persistencia del `BattleState` completo;
- Trainer search/proposal/brain/tie resolver;
- FASE34;
- scheduler/shared-budget/660;
- `campaign_snapshot` Game-Ready.

No introduce:

- auto-heal post-battle;
- replacement silencioso de rivales KO;
- permadeath;
- fallback de campaña en decisiones de combate.

## Cierre

**Trainer AI Campaign Persistence V1 queda CLOSED / CERTIFIED / FROZEN.**

No queda ninguna tranche obligatoria P1 pendiente. Cualquier sistema futuro de estrategia de campaña más profunda, aprendizaje continuo, MCTS, memoria estratégica extendida o persistencia en disco del rival deberá abrirse como feature separada y opcional; no es blocker de este sistema.

## Invariantes externas del freeze

- `main` debe permanecer exactamente en `641d4b1fb0bcf964205d616e96f198f05d702197`;
- PR #105 permanece OPEN / unmerged;
- PR #106 permanece CLOSED / not merged;
- PR #107 se cierra sin merge solo después de certificar el HEAD documental final;
- el snapshot Campaign Persistence deriva de Expertise V1 `f43dc6b...`, no de `main`.
