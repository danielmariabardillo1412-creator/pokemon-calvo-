# EMPEZAR AQUÍ

Este archivo es el punto de entrada para recuperar el proyecto en una conversación, agente o sesión nueva.

## Lectura mínima

1. `PROJECT_STATE.md` — baseline certificado y estado real.
2. `NEXT_STEPS.md` — trabajo autorizado ahora.
3. `WORK_PROTOCOL.md` — reglas de ejecución/certificación.
4. El cuaderno temático activo en `../project_book/TRAINER_AI_CAMPAIGN_PERSISTENCE.md`.

## Autoridad

Si dos fuentes se contradicen:

1. commit/branch/PR/CI/artefactos del SHA exacto en GitHub;
2. fuente canónica o inmutable del dominio;
3. `docs/current/`;
4. arquitectura y ADR vigentes;
5. cuadernos temáticos;
6. historial/worklogs;
7. memoria del chat.

## Baseline moderno de continuidad

Último HEAD certificado exacto antes del workstream actual:

`f43dc6b158c35fe25139de5524b83f6fe2d3426f`

Corresponde al freeze final de:

`Trainer AI Expertise V1 — CLOSED / CERTIFIED / FROZEN`

Además permanecen cerrados:

- Trainer AI runtime system 26.67 — CLOSED / COMPLETED;
- Trainer AI Game-Ready 27.1 — CLOSED / VALIDATED.

Rama del workstream actual:

`feature/trainer-ai-campaign-persistence-v1`

El nuevo trabajo es una feature separada: **Trainer AI Campaign Persistence V1**. No reabre C3f, Game-Ready 27.x ni Expertise V1.

P1-A actual es estrictamente **TEST/AUDIT-ONLY** y localiza el ownership seam entre roster owned por caller, `TrainerBattleSession`, settlement y el lifecycle one-shot del Overworld antes de diseñar recovery/replacement.

## Invariantes externos

- `main` sigue siendo histórica y debe permanecer exactamente en `641d4b1fb0bcf964205d616e96f198f05d702197` mientras este workstream no autorice otra cosa.
- PR #105 permanece OPEN / unmerged y no debe mergearse casualmente.
- PR #106 permanece CLOSED / not merged.
- El siguiente tramo parte del último SHA certificado exacto, no de `main` por nombre.

## Regla de memoria

Las decisiones materiales no deben vivir solo en el chat:

- estado y continuación: `docs/current/`;
- conocimiento de workstream: `docs/project_book/`;
- decisión arquitectónica duradera: ADR;
- evidencia histórica cerrada: `docs/history/worklogs/`.
