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

Parent original:

`f43dc6b158c35fe25139de5524b83f6fe2d3426f`

PR #107: **OPEN / DRAFT / NOT MERGED**.

Objetivo: ownership persistente de un entrenador rival entre combates, separando estado de batalla, roster owned por caller, persistencia de campaña, recovery policy y replacement policy.

### P1-A — CLOSED / CERTIFIED

Checkpoint técnico exacto:

`26c11caa635cecb851b95cd636580cb250683a32`

Resultado:

- suite P1-A: **23/23 PASS**;
- aggregate: `CAMPAIGN_PERSISTENCE_OWNERSHIP_SEAM_LOCALIZED`;
- Trainer Evaluation Corpus: **521 PASS / 0 FAIL**;
- Team Composition: **SUCCESS**;
- full CI técnico: **18/18 workflows SUCCESS**;
- **0 producción / 0 Battle Core**.

P1-A localizó el ownership seam: `TrainerBattleSession` consume temporalmente referencias externas de `CreatureInstance`, BattleState comparte esas identidades y settlement reconcilia antes de liberar el roster interno. `technical_overworld.gd` poseía el roster externamente, pero la vertical slice seguía siendo one-shot.

El `campaign_snapshot` histórico de `TrainerIntelligenceController`/`TrainerDecisionContext` es transporte DTO deep-detached, **no** ownership persistente. El proposal Game-Ready actual no conecta ese snapshot.

### P1-B — CLOSED / CERTIFIED / CONTRACT-FIRST

Checkpoint técnico exacto:

`f900fb79fb324c6e05d218eb741352e4d3a5db1f`

Resultado:

- suite P1-B: **27/27 PASS**;
- Trainer Evaluation Corpus: **548 PASS / 0 FAIL**;
- Team Composition: **SUCCESS**;
- full CI técnico: **18/18 workflows SUCCESS**;
- cambios técnicos exclusivamente tests/runner;
- **0 producción / 0 Battle Core**.

Contrato runtime ejecutable fijado sobre la misma `CreatureInstance`:

- HP `118 -> 115` persiste tras reconciliación;
- PP `20 -> 19` persiste;
- persistent status `burn` persiste;
- volatile status se elimina;
- Attack stage `+2 -> 0`;
- la identidad del objeto se conserva.

Contrato canónico:

- owner autoritativo fuera de `BattleState`/`TrainerBattleSession`;
- mismas `CreatureInstance`, sin clones de identidad;
- post-battle base = `reconcile_post_battle()`, sin auto-heal;
- recovery explícito inter-battle;
- campaign replacement fuera de batalla y separado de forced replacement;
- IDs duplicados/double ownership fail-closed;
- no persistir BattleState completo;
- `campaign_snapshot` como máximo DTO sanitizado/detached, nunca source of truth;
- Save V2 y Battle Core fuera de scope.

### P1-C — NEXT / MINIMAL PRODUCTION INTEGRATION

P1-C debe introducir y conectar el owner persistente mínimo sin reabrir combate:

- ownership estable por identidad;
- validación fail-closed;
- conservación de consecuencias persistentes;
- recovery/replacement explícitos fuera de Battle Core;
- sin Save V2, proposal/search/tie resolver, FASE34 ni scheduler/shared-budget/660;
- el rematch/cross-session E2E completo queda reservado para P1-D.

El HEAD documental que registra el cierre de P1-B debe pasar **18/18 workflows SUCCESS** antes de ser parent certificado de P1-C.

## Invariantes externos

- PR #105: **OPEN / unmerged**; no mergear casualmente.
- `main`: permanece exactamente en `641d4b1fb0bcf964205d616e96f198f05d702197`.
- PR #106: **CLOSED / not merged**.
- PR #107: **OPEN / DRAFT / unmerged**.
- Campaign Persistence parte del freeze Expertise V1, no de `main`.
- Campaign/recovery/replacement no puede convertirse en fallback oculto de search, proposal o tie resolution.
