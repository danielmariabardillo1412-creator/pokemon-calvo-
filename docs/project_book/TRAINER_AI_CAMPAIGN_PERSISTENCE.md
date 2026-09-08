# Trainer AI — Campaign Persistence V1

## P1.0 — workstream activo

Estado: **OPEN / P1-A CERTIFIED / P1-B CERTIFIED / P1-C CLOSED-CERTIFIED / P1-D NEXT**.

Parent original certificado de entrada:

`f43dc6b158c35fe25139de5524b83f6fe2d3426f`

Ese parent corresponde al freeze final de **Trainer AI Expertise V1 — CLOSED / CERTIFIED / FROZEN**.

Rama:

`feature/trainer-ai-campaign-persistence-v1`

PR:

`#107 — OPEN / DRAFT / NOT MERGED`

Esta feature no reabre C3f, Game-Ready 27.x ni Expertise V1. El sistema de combate Trainer AI continúa cerrado y certificado. Campaign Persistence define qué estado de un entrenador rival sobrevive entre combates y quién lo posee.

## Distinción canónica

No confundir:

- **estado de batalla**: HP/PP/status/active/turn y forced replacement mientras Battle Core está activo;
- **roster owned por campaign**: `CreatureInstance` que existe fuera de `TrainerBattleSession` y se reutiliza por identidad;
- **persistencia de campaña**: identidad/roster/configuración y consecuencias persistentes que sobreviven deliberadamente entre encuentros;
- **recovery policy**: operación explícita para curar/restaurar entre encuentros;
- **replacement policy**: operación explícita para sustituir miembros fuera de una batalla terminada;
- **forced replacement de Battle Core**: cambio obligatorio durante batalla; no es campaign replacement.

Campaign/recovery/replacement nunca puede convertirse en fallback oculto para decidir una acción de combate.

### `campaign_snapshot` histórico

Existe transporte histórico de `campaign_snapshot` en `TrainerIntelligenceController`/`TrainerDecisionContext`, con copia profunda del DTO. Ese transporte **no es el owner persistente de campaña** y no puede convertirse en source of truth.

El path autónomo Game-Ready de `TrainerItemAwareActionProposal` continúa creando su contexto sin conectar ese snapshot. Campaign Persistence mantiene deliberadamente separadas ambas responsabilidades.

## Plan fijo — 4 tramos

1. **P1-A — ownership/persistence boundary audit** — **CLOSED / CERTIFIED / TEST-AUDIT-ONLY**.
2. **P1-B — contrato de estado persistente + recovery/replacement** — **CLOSED / CERTIFIED / CONTRACT-FIRST**.
3. **P1-C — integración productiva mínima del owner persistente** — **CLOSED / CERTIFIED**.
4. **P1-D — rematch/cross-battle E2E + regresión + freeze** — **NEXT**.

No añadir una quinta tranche por inercia. Si aparece un blocker real que invalide este plan, debe documentarse antes de ampliar scope.

## P1-A — CLOSED / CERTIFIED

Scope original: **TEST/AUDIT-ONLY**.

Suite:

`TrainerCampaignPersistenceBoundaryAuditTestSuite`

Audit ID:

`p1_a_campaign_persistence_ownership_boundary_audit_v1`

Resultado:

`CAMPAIGN_PERSISTENCE_OWNERSHIP_SEAM_LOCALIZED`

Checkpoint técnico original:

`26c11caa635cecb851b95cd636580cb250683a32`

### Evidencia P1-A original

- P1-A: **23/23 PASS**.
- Trainer Evaluation Corpus: **521 PASS / 0 FAIL**.
- Team Composition: **SUCCESS**.
- Full CI: **18/18 workflows SUCCESS**.
- Diff original: solo docs/tests; **0 producción / 0 Battle Core**.

P1-A localizó que `TrainerBattleSession` consume referencias externas de `CreatureInstance`, BattleState comparte esas identidades, settlement reconcilia y la sesión libera después su roster interno. También fijó que la vertical slice era one-shot y que `campaign_snapshot` histórico era DTO detached, no authority.

Durante P1-C, cuatro asserts P1-A que congelaban literalmente la forma histórica (`_trainer_roster` ad-hoc y ausencia de owner) se volvieron falsos por el cambio autorizado. La auditoría fue hecha **forward-compatible** sin reducir sus 23 checks: ahora acepta únicamente la forma histórica o el sucesor explícitamente autorizado `TrainerCampaignRosterOwner`, y sigue exigiendo aislamiento respecto de combat AI. Esto fue una corrección de test histórico, no un fallo del owner productivo.

## P1-B — CLOSED / CERTIFIED / CONTRACT-FIRST

Suite:

`TrainerCampaignPersistenceContractAuditTestSuite`

Checkpoint técnico exacto:

`f900fb79fb324c6e05d218eb741352e4d3a5db1f`

- P1-B: **27/27 PASS**.
- Trainer Evaluation Corpus: **548 PASS / 0 FAIL**.
- Full CI técnico: **18/18 workflows SUCCESS**.
- Team Composition: **SUCCESS**.
- **0 producción / 0 Battle Core**.

### Contrato runtime fijado

Sobre la misma `CreatureInstance`:

- HP `118 -> 115` persiste tras `reconcile_post_battle()`;
- PP `20 -> 19` persiste;
- `burn` persistente sobrevive;
- volatile status se elimina;
- Attack stage `+2 -> 0`;
- identidad del objeto conservada.

Contrato canónico:

1. Owner autoritativo fuera de `BattleState`/`TrainerBattleSession`.
2. Mismas `CreatureInstance`, sin clones de identidad.
3. Post-battle base = `reconcile_post_battle()`, sin auto-heal.
4. HP, PP y persistent status sobreviven; volatile/transient battle state se limpia.
5. Recovery inter-battle explícito.
6. Campaign replacement fuera de batalla y separado de forced replacement.
7. IDs duplicados/ownership ambiguo fallan cerrado.
8. No persistir `BattleState` completo.
9. `campaign_snapshot` como máximo DTO sanitizado/detached, nunca authority.
10. Campaign/recovery/replacement aislado de proposal/search/tie resolution.

El HEAD documental P1-B `4e96c999818916e90c6f8e9bfbc381f516e347dc` pasó **18/18 workflows SUCCESS** y fue el parent exacto certificado de P1-C.

## P1-C — CLOSED / CERTIFIED / MINIMAL PRODUCTION INTEGRATION

Checkpoint técnico exacto:

`311349938af6c57f4507e2160e157cffbc124afb`

Suite:

`TrainerCampaignPersistenceOwnerIntegrationTestSuite`

Resultado certificado:

`CAMPAIGN_PERSISTENCE_OWNER_INTEGRATED`

### Evidencia ejecutable P1-C

- P1-C: **34/34 PASS**.
- P1-A forward-compatible: **23/23 PASS**.
- P1-B: **27/27 PASS**.
- Trainer Evaluation Corpus: **582 PASS / 0 FAIL**.
- Godot 4.7 regression: **SUCCESS**.
- Team Composition: **SUCCESS**.
- Full CI del checkpoint técnico: **18/18 workflows SUCCESS**.

### Integración productiva

Nuevo owner:

`modules/gameplay/trainer_campaign_roster_owner.gd`

`TrainerCampaignRosterOwner`:

- posee un `trainer_id` estable y un roster de `CreatureInstance`;
- valida roster/IDs antes de mutar;
- rechaza trainer id vacío, roster vacío, nulls, instance ids vacíos y duplicados;
- conserva exactamente las mismas referencias de `CreatureInstance`;
- `roster_for_battle()` desacopla solo el contenedor `Array`, no los objetos;
- `owned_creature(...)` falla cerrado si la identidad fuese ambigua;
- `recover_creature_full(...)` es una operación explícita, nunca automática;
- recovery ejecuta reconciliación, restaura HP/PP y limpia persistent status sobre la misma instancia;
- `replace_member(...)` es campaign replacement explícito y atómico;
- prohíbe rebind silencioso de un mismo `instance_id` a otro objeto;
- rechaza replacement con identidad duplicada antes de mutar.

Integración Overworld:

- `technical_overworld.gd` dejó de poseer `_trainer_roster` ad-hoc;
- ahora posee `_trainer_campaign_owner`;
- bootstrap configura el owner una vez;
- cada `begin_battle(...)` recibe un array nuevo con las mismas referencias persistentes;
- P1-C mantuvo deliberadamente el bloqueo one-shot `_trainer_demo_completed`; rematch quedó reservado para P1-D.

### Incidente de regresión P1-C

Primer HEAD productivo/runner:

`d3238725e564f0ab8cf11ab592c5fcb3c715a096`

Evaluation produjo **578 PASS / 4 FAIL**, pero los **34/34 checks P1-C estaban verdes**. Los cuatro fallos eran asserts P1-A que exigían que el owner nuevo aún no existiera. Se corrigió únicamente la auditoría histórica para reconocer el sucesor autorizado sin perder checks ni barreras. El HEAD corregido `311349...` produjo **582/0** y 18/18 CI.

Conclusión: el incidente fortaleció la regresión histórica; no se ocultó ni se rebajó ninguna condición productiva.

### Scope exacto P1-C

Diff desde el parent certificado P1-B documental `4e96c999...` hasta `311349...`:

1. owner productivo nuevo;
2. wiring mínimo de `technical_overworld.gd`;
3. suite P1-C;
4. una entrada en el runner;
5. adaptación forward-compatible de la auditoría P1-A.

P1-C no modificó Save V2, Battle Core, proposal/search/brain/tie resolver, FASE34 ni scheduler/shared-budget/660.

## P1-D — NEXT / FINAL CLOSURE

P1-D es **el único tramo restante** de Campaign Persistence V1.

Debe probar en E2E real:

1. primer combate usa exactamente la criatura owned por campaign;
2. settlement conserva consecuencias persistentes sobre esa misma instancia;
3. tras una victoria del jugador, el rival KO **no reaparece curado automáticamente**;
4. un intento de revancha sin recovery falla cerrado por no haber rival vivo;
5. recovery explícito restaura la misma instancia;
6. segundo combate puede abrirse después de recovery y vuelve a usar exactamente esa misma instancia;
7. el segundo encuentro ejecuta y cierra por la ruta real Overworld -> Presentation -> TrainerBattleSession -> Battle Core;
8. no se introduce persistencia de `BattleState`, Save V2 ni policy oculta en combat AI;
9. regresión global final verde;
10. freeze documental y cierre de PR #107 **sin merge** siguiendo el protocolo de snapshots.

P1-D puede retirar el bloqueo one-shot del demo para permitir rematch, pero **no** puede introducir auto-recovery en `_on_trainer_battle_closed`. La recuperación debe seguir siendo una acción inter-battle explícita.

## Invariantes externas

- `main` permanece exactamente en `641d4b1fb0bcf964205d616e96f198f05d702197`.
- PR #105 permanece OPEN / unmerged.
- PR #106 permanece CLOSED / not merged.
- PR #107 permanece OPEN / DRAFT / unmerged hasta el freeze P1-D.
- El parent original de Campaign Persistence sigue siendo Expertise V1 `f43dc6b...`, no `main`.
