# Trainer AI — Campaign Persistence V1

## P1.0 — workstream activo

Estado: **OPEN / P1-A CERTIFIED / P1-B CLOSED-CERTIFIED / P1-C NEXT**.

Parent exacto certificado de entrada:

`f43dc6b158c35fe25139de5524b83f6fe2d3426f`

Ese parent corresponde al freeze final de **Trainer AI Expertise V1 — CLOSED / CERTIFIED / FROZEN**.

Rama:

`feature/trainer-ai-campaign-persistence-v1`

PR:

`#107 — OPEN / DRAFT / NOT MERGED`

Esta feature no reabre C3f, Game-Ready 27.x ni Expertise V1. El sistema de combate Trainer AI continúa cerrado y certificado. El objetivo de este workstream es definir y después integrar qué estado de un entrenador rival sobrevive entre combates y quién lo posee.

## Distinción canónica

No confundir:

- **estado de batalla**: HP/PP/status/active/turn y forced replacement mientras Battle Core está activo;
- **roster owned por el caller**: `CreatureInstance` que existe fuera de `TrainerBattleSession` y puede reutilizarse;
- **persistencia de campaña**: identidad/roster/configuración y consecuencias persistentes que sobreviven deliberadamente entre encuentros;
- **recovery policy**: reglas explícitas para curar/restaurar entre encuentros;
- **replacement policy**: reglas explícitas para sustituir miembros fuera de una batalla terminada;
- **forced replacement de Battle Core**: cambio obligatorio durante una batalla; no es campaign replacement.

Campaign/recovery/replacement nunca puede convertirse en un fallback oculto para decidir una acción de combate.

### `campaign_snapshot` histórico

Existe transporte histórico de `campaign_snapshot` en `TrainerIntelligenceController`/`TrainerDecisionContext`, con copia profunda del DTO. Ese transporte **no es el owner persistente de campaña** y no puede convertirse en source of truth.

El path autónomo Game-Ready actual de `TrainerItemAwareActionProposal` crea su `TrainerDecisionContext` sin conectar ese snapshot. Campaign Persistence mantiene deliberadamente separadas ambas responsabilidades.

## Plan fijo — 4 tramos

1. **P1-A — ownership/persistence boundary audit** — **CLOSED / CERTIFIED / TEST-AUDIT-ONLY**.
2. **P1-B — contrato de estado persistente + recovery/replacement** — **CLOSED / CERTIFIED / CONTRACT-FIRST**.
3. **P1-C — integración productiva mínima del owner persistente** — **NEXT**.
4. **P1-D — rematch/cross-session E2E + regresión + freeze** — PENDIENTE.

No añadir una quinta tranche por inercia. Si aparece un blocker real que invalide este plan, debe documentarse antes de ampliar scope.

## P1-A — CLOSED / CERTIFIED

Scope: **TEST/AUDIT-ONLY**.

Suite:

`TrainerCampaignPersistenceBoundaryAuditTestSuite`

Audit ID:

`p1_a_campaign_persistence_ownership_boundary_audit_v1`

Resultado certificado:

`CAMPAIGN_PERSISTENCE_OWNERSHIP_SEAM_LOCALIZED`

Checkpoint técnico exacto:

`26c11caa635cecb851b95cd636580cb250683a32`

### Evidencia ejecutable P1-A

- P1-A: **23/23 PASS**.
- Trainer Evaluation Corpus: **521 PASS / 0 FAIL**.
- Workflow Team Composition: **SUCCESS**.
- Full CI del checkpoint técnico: **18/18 workflows SUCCESS**.
- El conteo agregado literal interno de Team Composition no fue expuesto por el conector para ese job; no se infiere desde checkpoints anteriores.
- Diff contra el freeze Expertise V1: solo docs/tests; **0 producción / 0 Battle Core**.

### Ownership seam certificado

P1-A demuestra que:

- `TrainerBattleSession` recibe roster rival owned externamente;
- BattleState y roster de sesión comparten la misma identidad de `CreatureInstance`;
- mutaciones runtime sobre esas criaturas son visibles desde el roster owned por el caller;
- `_roster_with_living_active(...)` conserva referencias y solo reordena;
- settlement reconcilia las criaturas y luego la sesión libera su roster interno;
- reset elimina identidad/configuración runtime del oponente;
- `technical_overworld.gd` ya actúa como owner externo de `_trainer_roster`;
- la vertical slice actual sigue siendo one-shot y no ejerce rematch;
- existe transporte histórico deep-detached de `campaign_snapshot`, pero el proposal Game-Ready actual no lo usa;
- no existe aún un owner productivo dedicado de campaign/recovery/replacement;
- campaign/recovery/replacement permanecen fuera de proposal/search/tie resolution.

Conclusión: **Battle Core/TrainerBattleSession consumen temporalmente las mismas `CreatureInstance`, pero el lifecycle persistente pertenece a un owner exterior estable**. No hay justificación para persistir `BattleState`, clonar el roster o introducir curación implícita.

## P1-B — CLOSED / CERTIFIED / CONTRACT-FIRST

Scope: **TEST/AUDIT-ONLY / CONTRACT-FIRST**. P1-B no introduce todavía el owner productivo.

Suite:

`TrainerCampaignPersistenceContractAuditTestSuite`

Checkpoint técnico exacto:

`f900fb79fb324c6e05d218eb741352e4d3a5db1f`

### Evidencia ejecutable P1-B

- P1-B: **27/27 PASS**.
- Trainer Evaluation Corpus: **548 PASS / 0 FAIL**.
- Full CI del checkpoint técnico: **18/18 workflows SUCCESS**.
- Team Composition del mismo SHA: **SUCCESS**.
- El conteo agregado literal interno de Team Composition no se reutiliza ni se infiere si el conector no lo expone de forma verificable.
- Cambios P1-B técnicos: suite nueva + registro en runner; **0 producción / 0 Battle Core**.

### Contrato runtime fijado

El probe ejecutable demuestra la transición post-battle sobre la **misma** `CreatureInstance`:

- HP: `118 -> 115` y el daño persiste tras `reconcile_post_battle()`;
- PP: `20 -> 19` y el consumo persiste;
- persistent status `burn` persiste;
- volatile status se elimina;
- stat stage de Attack `+2 -> 0`;
- la identidad del objeto no cambia.

Por tanto, el contrato canónico para P1-C queda fijado:

1. El owner autoritativo vive fuera de `BattleState` y `TrainerBattleSession`.
2. Conserva exactamente las mismas `CreatureInstance`; no crea copias de identidad.
3. La transición post-battle base es `reconcile_post_battle()`; **no hay auto-heal**.
4. HP, PP y persistent status sobreviven conforme al contrato actual; volatile/transient battle state se limpia.
5. Recovery es una operación/policy inter-battle explícita.
6. Campaign replacement es una operación fuera de batalla y distinta del forced replacement de Battle Core.
7. IDs duplicados/double ownership fallan cerrado; no se corrigen silenciosamente.
8. No se persiste el `BattleState` completo.
9. `campaign_snapshot` histórico, si se proyecta, solo puede ser DTO sanitizado/detached; nunca owner autoritativo.
10. Campaign/recovery/replacement permanece aislado de proposal/search/tie resolution.

P1-B utilizó como precedentes arquitectónicos `CreatureInstance.reconcile_post_battle()`, ownership fail-closed de `PlayerCollection`, unicidad por instance ID de `SaveGameData`, settlement sin policy de recovery/replacement y reconciliación sin auto-heal de `WildAdventureSession`. **Save V2 no fue modificado.**

## P1-C — NEXT / MINIMAL PRODUCTION INTEGRATION

P1-C está autorizado a introducir el **owner persistente mínimo** y conectarlo en la superficie de integración existente, con estas barreras:

- mantener identidad exacta de `CreatureInstance`;
- ownership/IDs fail-closed;
- no auto-heal;
- recovery y campaign replacement explícitos y fuera de Battle Core;
- no persistir `BattleState`;
- no tocar Save V2;
- no conectar `campaign_snapshot` al proposal Game-Ready;
- no modificar search, proposal, brain, tie resolver, FASE34 ni scheduler/shared-budget/660;
- no convertir P1-C todavía en la prueba de revancha: el rematch/cross-session E2E queda reservado para P1-D.

La integración debe ser mínima: sustituir ownership ad-hoc por un owner dedicado sin reabrir el comportamiento de combate ya certificado.

## Gate documental P1-B

Este commit documental debe pasar **18/18 workflows SUCCESS** antes de utilizarse como parent certificado de P1-C. La evidencia técnica P1-B anterior ya está cerrada; este gate certifica únicamente que la sincronización documental no introduce regresión.

## Invariantes externas

- `main` permanece exactamente en `641d4b1fb0bcf964205d616e96f198f05d702197`.
- PR #105 permanece OPEN / unmerged.
- PR #106 permanece CLOSED / not merged.
- PR #107 permanece OPEN / DRAFT / unmerged durante el workstream.
- El parent original de esta feature es el freeze Expertise V1 `f43dc6b...`, no `main`.
- El PR de esta feature deberá cerrarse sin merge tras P1-D/freeze, siguiendo la cadena de snapshots certificados.
