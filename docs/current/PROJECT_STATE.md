# ESTADO ACTUAL DEL PROYECTO

## Baseline funcional certificado

Último freeze funcional anterior al workstream actual:

`f43dc6b158c35fe25139de5524b83f6fe2d3426f`

Estado acumulado:

- Trainer AI runtime system 26.67: **CLOSED / COMPLETED**;
- Trainer AI Game-Ready 27.1: **CLOSED / VALIDATED**;
- Trainer AI Expertise V1: **CLOSED / CERTIFIED / FROZEN**;
- Expertise final: **18/18 workflows SUCCESS**;
- Trainer Evaluation Corpus antes de Campaign Persistence: **498 PASS / 0 FAIL**;
- PR #106: **CLOSED / NOT MERGED**.

## DATA V3

Estado: **CERRADO / CERTIFICADO**.

Contrato canónico preservado:

- 1.025 especies;
- 326 formas;
- 18 tipos runtime;
- 919 movimientos;
- 373 habilidades;
- 2.222 objetos;
- 61.102 entradas de learnset;
- 554 evoluciones.

No reabrir DATA V3 para subir contadores ni alterar fuentes inmutables.

## Trainer AI de combate — sistema cerrado

El entrenador de combate ya dispone de:

- memoria bilateral sanitizada;
- beliefs sin información oculta;
- búsqueda acotada;
- MOVE / SWITCH / ITEM donde el modo lo permita;
- switching estratégico;
- loadouts y composición;
- proposal profundo sobre todas las raíces legales;
- sustitución autónoma side_b;
- resolución game-ready de empates exactos;
- integración real Overworld -> TrainerBattleSession -> presentación -> Battle Core;
- victoria, derrota, reset y segunda batalla certificados;
- adversarial full-battle sin deadlock;
- estilos `balanced`, `aggressive`, `cautious`, `technical`;
- expertise `limited` (inner cap 1) y `full` (inner cap 3), con default `balanced + full`.

No reabrir C3f, Game-Ready 27.x ni Expertise V1 salvo regresión reproducible.

## Workstream activo — Trainer AI Campaign Persistence V1

Rama:

`feature/trainer-ai-campaign-persistence-v1`

Parent exacto:

`f43dc6b158c35fe25139de5524b83f6fe2d3426f`

PR #107: **OPEN / DRAFT / NOT MERGED**.

Objetivo: definir e integrar el ownership persistente de un entrenador rival entre combates, separando claramente:

- estado de batalla;
- roster owned por caller;
- persistencia de campaña;
- recovery policy;
- replacement policy.

### P1-A — CLOSED / CERTIFIED

Scope: **TEST/AUDIT-ONLY**.

Checkpoint técnico exacto:

`26c11caa635cecb851b95cd636580cb250683a32`

Resultado:

- `TrainerCampaignPersistenceBoundaryAuditTestSuite`: **23/23 PASS**;
- aggregate: `CAMPAIGN_PERSISTENCE_OWNERSHIP_SEAM_LOCALIZED`;
- Trainer Evaluation Corpus: **521 PASS / 0 FAIL**;
- Team Composition workflow: **SUCCESS**;
- full CI técnico: **18/18 workflows SUCCESS**;
- **0 cambios de producción / 0 Battle Core**.

El conector no expuso el conteo agregado literal del job Team Composition para este checkpoint; no se infiere desde ejecuciones anteriores.

P1-A certifica que `TrainerBattleSession` consume temporalmente referencias externas de `CreatureInstance`, BattleState comparte esas identidades y settlement reconcilia antes de liberar el roster interno. `technical_overworld.gd` ya posee el roster externamente, pero la vertical slice es one-shot y no ejerce rematch.

También queda fijado que el `campaign_snapshot` histórico de `TrainerIntelligenceController`/`TrainerDecisionContext` es transporte DTO deep-detached, **no** ownership persistente. El proposal Game-Ready actual no conecta ese snapshot.

### P1-B — NEXT / CONTRACT-FIRST

La siguiente tranche debe fijar por tests/audit, todavía sin owner productivo:

- owner autoritativo estable fuera de `BattleState`/`TrainerBattleSession`;
- misma identidad de `CreatureInstance`;
- post-battle por defecto = `reconcile_post_battle()`, sin auto-heal;
- HP/PP/persistent status sobreviven; volatile battle state se limpia;
- recovery explícito entre combates;
- campaign replacement separado de forced replacement;
- duplicados/double ownership fail-closed;
- no persistir `BattleState` completo;
- `campaign_snapshot` como máximo DTO sanitizado, nunca source of truth.

P1-B no toca Save V2, proposal/search/tie resolver, FASE34, scheduler/shared-budget/660 ni Battle Core. Producción queda reservada a P1-C.

## Invariantes externos

- PR #105: **OPEN / unmerged**; no mergear casualmente.
- `main`: permanece exactamente en `641d4b1fb0bcf964205d616e96f198f05d702197`.
- PR #106: **CLOSED / not merged**.
- PR #107: **OPEN / DRAFT / unmerged**.
- Campaign Persistence parte del freeze Expertise V1, no de `main`.
- Campaign/recovery/replacement no puede convertirse en fallback oculto de search, proposal o tie resolution.
