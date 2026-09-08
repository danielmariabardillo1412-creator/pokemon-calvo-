# ESTADO ACTUAL DEL PROYECTO

## Baseline funcional certificado

Último freeze funcional anterior a Campaign Persistence:

`f43dc6b158c35fe25139de5524b83f6fe2d3426f`

Estado acumulado:

- Trainer AI runtime system 26.67: **CLOSED / COMPLETED**;
- Trainer AI Game-Ready 27.1: **CLOSED / VALIDATED**;
- Trainer AI Expertise V1: **CLOSED / CERTIFIED / FROZEN**;
- Trainer AI Campaign Persistence P1-A: **CLOSED / CERTIFIED**;
- Trainer AI Campaign Persistence P1-B: **CLOSED / CERTIFIED**;
- Trainer AI Campaign Persistence P1-C: **CLOSED / CERTIFIED**;
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

El entrenador de combate ya dispone de memoria bilateral sanitizada, beliefs sin información oculta, búsqueda acotada, MOVE/SWITCH/ITEM donde corresponda, switching estratégico, loadouts/composición, proposal sobre todas las raíces legales, sustitución autónoma side_b, tie resolution game-ready, integración real con Overworld/Battle Core, cierre/reset de batalla, full-battle adversarial, estilos y expertise certificados.

No reabrir C3f, Game-Ready 27.x ni Expertise V1 salvo regresión reproducible.

## Workstream activo — Trainer AI Campaign Persistence V1

Rama:

`feature/trainer-ai-campaign-persistence-v1`

Parent original:

`f43dc6b158c35fe25139de5524b83f6fe2d3426f`

PR #107: **OPEN / DRAFT / NOT MERGED**.

### P1-A — CLOSED / CERTIFIED

Checkpoint original:

`26c11caa635cecb851b95cd636580cb250683a32`

- 23/23 PASS;
- Evaluation 521/0;
- 18/18 workflows SUCCESS;
- 0 producción / 0 Battle Core.

La auditoría P1-A fue posteriormente hecha forward-compatible para aceptar únicamente el owner P1-C autorizado sin perder sus 23 checks ni el aislamiento respecto de combat AI.

### P1-B — CLOSED / CERTIFIED / CONTRACT-FIRST

Checkpoint técnico:

`f900fb79fb324c6e05d218eb741352e4d3a5db1f`

- 27/27 PASS;
- Evaluation 548/0;
- 18/18 workflows SUCCESS;
- Team Composition SUCCESS;
- 0 producción / 0 Battle Core.

Contrato: misma `CreatureInstance`; HP/PP/persistent status sobreviven a `reconcile_post_battle()`; volatile/stages se limpian; no auto-heal; recovery/replacement explícitos; IDs/ownership fail-closed; no BattleState persistido; `campaign_snapshot` no es authority.

HEAD documental P1-B certificado:

`4e96c999818916e90c6f8e9bfbc381f516e347dc` — **18/18 SUCCESS**.

### P1-C — CLOSED / CERTIFIED / PRODUCTION INTEGRATION

Checkpoint técnico exacto:

`311349938af6c57f4507e2160e157cffbc124afb`

Resultado:

- suite P1-C: **34/34 PASS**;
- P1-A forward-compatible: **23/23 PASS**;
- P1-B: **27/27 PASS**;
- Trainer Evaluation Corpus: **582 PASS / 0 FAIL**;
- Godot 4.7: **SUCCESS**;
- Team Composition: **SUCCESS**;
- full CI técnico: **18/18 workflows SUCCESS**.

Producción P1-C:

- nuevo `TrainerCampaignRosterOwner` fuera de BattleState/TrainerBattleSession;
- ownership por identidad exacta de `CreatureInstance`;
- array de handoff detached, objetos compartidos por referencia;
- configuración/replacement atómicos y fail-closed;
- recovery full explícito, nunca automático;
- Overworld reemplaza `_trainer_roster` ad-hoc por `_trainer_campaign_owner`;
- one-shot del demo preservado expresamente para dejar rematch a P1-D;
- Save V2, Battle Core, search/proposal/brain/tie resolver, FASE34 y scheduler/shared-budget/660 intactos.

Primer intento P1-C (`d3238725...`) dio **578/4**, aunque P1-C estaba 34/34: los cuatro fallos eran asserts P1-A que congelaban la forma pre-owner. Se corrigió la auditoría histórica sin reducir cobertura; `311349...` quedó 582/0 y 18/18.

### P1-D — NEXT / ÚLTIMO TRAMO

P1-D debe cerrar rematch/cross-battle E2E y freeze:

- primer combate usa la instancia owned por campaign;
- KO/HP/PP/status post-settlement no se curan solos;
- revancha inmediata con rival KO falla cerrado;
- recovery explícito restaura la misma instancia;
- segundo combate se abre con esa misma instancia y ejecuta por la ruta real;
- retirar el bloqueo one-shot sin introducir auto-recovery;
- full regression verde;
- freeze final de Campaign Persistence V1;
- cerrar PR #107 sin merge según protocolo.

No abre Save V2 ni persistencia de BattleState.

## Invariantes externos

- PR #105: **OPEN / unmerged**.
- `main`: `641d4b1fb0bcf964205d616e96f198f05d702197`.
- PR #106: **CLOSED / not merged**.
- PR #107: **OPEN / DRAFT / unmerged** hasta el freeze P1-D.
