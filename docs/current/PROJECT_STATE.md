# ESTADO ACTUAL DEL PROYECTO

## Baseline funcional certificado

Último HEAD certificado exacto antes del workstream actual:

`f43dc6b158c35fe25139de5524b83f6fe2d3426f`

Estado acumulado:

- Trainer AI runtime system 26.67: **CLOSED / COMPLETED**;
- Trainer AI Game-Ready 27.1: **CLOSED / VALIDATED**;
- Trainer AI Expertise V1: **CLOSED / CERTIFIED / FROZEN**;
- Expertise final: **18/18 workflows SUCCESS**;
- Trainer Evaluation Corpus: **498 PASS / 0 FAIL**;
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

## Nuevo workstream activo — Trainer AI Campaign Persistence V1

Rama:

`feature/trainer-ai-campaign-persistence-v1`

Parent exacto:

`f43dc6b158c35fe25139de5524b83f6fe2d3426f`

Objetivo: definir y luego integrar el ownership persistente de un entrenador rival entre combates, separando claramente:

- estado de batalla;
- roster owned por caller;
- persistencia de campaña;
- recovery policy;
- replacement policy.

### P1-A actual

Scope: **TEST/AUDIT-ONLY**.

Hallazgo de apertura:

- `TrainerBattleSession` recibe referencias externas de `CreatureInstance` y las reutiliza durante Battle Core;
- settlement reconcilia el roster rival y después libera la referencia interna;
- `technical_overworld.gd` ya posee `_trainer_roster` fuera de la sesión;
- la vertical slice es one-shot: tras completar el combate Trainer bloquea la revancha;
- no hay todavía contrato certificado de campaign/recovery/replacement;
- esos tres conceptos siguen explícitamente fuera de la decisión de combate.

La primera tranche solo localiza y certifica este seam. No implementa recuperación ni persistencia productiva.

## Invariantes externos

- PR #105: **OPEN / unmerged**; no mergear casualmente.
- `main`: debe permanecer exactamente en `641d4b1fb0bcf964205d616e96f198f05d702197`.
- PR #106 queda cerrado sin merge.
- El nuevo workstream parte del freeze Expertise V1, no de `main`.
- Campaign/recovery/replacement no puede convertirse en fallback oculto de search, proposal o tie resolution.
