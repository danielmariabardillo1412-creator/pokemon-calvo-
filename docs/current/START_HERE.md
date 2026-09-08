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

Freeze funcional anterior al workstream actual:

`f43dc6b158c35fe25139de5524b83f6fe2d3426f`

Corresponde a:

`Trainer AI Expertise V1 — CLOSED / CERTIFIED / FROZEN`

Además permanecen cerrados:

- Trainer AI runtime system 26.67 — CLOSED / COMPLETED;
- Trainer AI Game-Ready 27.1 — CLOSED / VALIDATED.

Rama activa:

`feature/trainer-ai-campaign-persistence-v1`

PR #107: **OPEN / DRAFT / NOT MERGED**.

## Campaign Persistence — punto real

- **P1-A — CLOSED / CERTIFIED / TEST-AUDIT-ONLY**.
  - technical checkpoint `26c11caa635cecb851b95cd636580cb250683a32`;
  - 23/23;
  - Evaluation 521/0;
  - 18/18 workflows SUCCESS.
- **P1-B — CLOSED / CERTIFIED / CONTRACT-FIRST**.
  - technical checkpoint `f900fb79fb324c6e05d218eb741352e4d3a5db1f`;
  - 27/27;
  - Evaluation 548/0;
  - 18/18 workflows SUCCESS;
  - 0 producción / 0 Battle Core.
- **P1-C — NEXT**, después de que el HEAD documental actual pase su gate 18/18.
- **P1-D — PENDING**, reservado para rematch/cross-session E2E + freeze final.

Contrato P1-B que no debe reinterpretarse:

- misma identidad de `CreatureInstance`;
- `reconcile_post_battle()` como transición base;
- HP/PP/persistent status sobreviven;
- volatile/transient state se limpia;
- no auto-heal;
- recovery inter-battle explícito;
- campaign replacement separado de forced replacement;
- ownership/IDs fail-closed;
- no persistir BattleState;
- `campaign_snapshot` histórico no es source of truth.

P1-C puede introducir el owner persistente mínimo e integrarlo en el punto de ownership existente, pero no puede tocar Save V2, Battle Core, proposal/search/tie resolver, FASE34 ni scheduler/shared-budget/660. El E2E de dos encuentros queda para P1-D.

## Invariantes externos

- `main` debe permanecer exactamente en `641d4b1fb0bcf964205d616e96f198f05d702197` mientras este workstream no autorice otra cosa.
- PR #105 permanece OPEN / unmerged y no debe mergearse casualmente.
- PR #106 permanece CLOSED / not merged.
- PR #107 permanece OPEN / DRAFT / unmerged.
- El siguiente tramo parte del último SHA certificado exacto, no de `main` por nombre.

## Regla de memoria

Las decisiones materiales no deben vivir solo en el chat:

- estado y continuación: `docs/current/`;
- conocimiento de workstream: `docs/project_book/`;
- decisión arquitectónica duradera: ADR;
- evidencia histórica cerrada: `docs/history/worklogs/`.
