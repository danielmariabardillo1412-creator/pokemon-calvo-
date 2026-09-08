# EMPEZAR AQUÍ

Este archivo es el punto de entrada para recuperar el proyecto en una conversación, agente o sesión nueva.

## Lectura mínima

1. `PROJECT_STATE.md` — baseline certificado y estado real.
2. `NEXT_STEPS.md` — trabajo autorizado ahora.
3. `WORK_PROTOCOL.md` — reglas de ejecución/certificación.
4. `../project_book/TRAINER_AI_CAMPAIGN_PERSISTENCE.md` — cierre canónico del último workstream Trainer AI.

## Autoridad

Si dos fuentes se contradicen:

1. commit/branch/PR/CI del SHA exacto en GitHub;
2. fuente canónica/inmutable del dominio;
3. `docs/current/`;
4. arquitectura/ADR vigentes;
5. cuadernos temáticos;
6. historial/worklogs;
7. memoria del chat.

## Baseline Trainer AI moderno

Trainer AI está cerrado en sus sistemas obligatorios actuales:

- runtime system 26.67 — CLOSED / COMPLETED;
- Game-Ready 27.1 — CLOSED / VALIDATED;
- Expertise V1 — CLOSED / CERTIFIED / FROZEN;
- Campaign Persistence V1 — **CLOSED / CERTIFIED / FROZEN**.

No hay una tranche Trainer AI obligatoria activa.

## Campaign Persistence V1 — freeze final

Rama snapshot:

`feature/trainer-ai-campaign-persistence-v1`

Parent original:

`f43dc6b158c35fe25139de5524b83f6fe2d3426f`

Parent documental P1-D:

`bf604176a66abde8ad475dd54f7375420c21c06b`

Checkpoint técnico final:

`b314b8bb81db439e3063433644c691181ed39ef4`

Estado por tramos:

- P1-A — CLOSED / CERTIFIED — 23/23; Evaluation 521/0; 18/18 CI.
- P1-B — CLOSED / CERTIFIED — 27/27; Evaluation 548/0; 18/18 CI.
- P1-C — CLOSED / CERTIFIED — 34/34; Evaluation 582/0; 18/18 CI.
- P1-D — CLOSED / CERTIFIED — **46/46; Evaluation 628/0; 18/18 CI**.

## Contrato final que no debe reinterpretarse

- `TrainerCampaignRosterOwner` es authority del roster de campaña en runtime;
- conserva la misma `CreatureInstance`;
- handoff al battle session copia solo el Array;
- `reconcile_post_battle()` no auto-cura;
- HP/PP/persistent status son consecuencias persistentes;
- volatile/stages son battle-only;
- recovery es explícito inter-battle;
- campaign replacement es externo a Battle Core;
- IDs/ownership inválidos fallan cerrado;
- no se persiste BattleState completo;
- Save V2 queda fuera de Campaign Persistence V1;
- `campaign_snapshot` histórico no es source of truth;
- campaign/recovery/replacement no participa en la decisión de combate.

## E2E final certificado

Secuencia real:

`primer combate -> settlement -> rival KO persiste -> revancha inmediata bloqueada -> recovery explícito -> misma CreatureInstance -> segundo combate real`

El rechazo sin recovery usa el error `no_available_opponent_creature`. No existe auto-recovery oculto.

## Continuación

No existe P1-E. No abrir una quinta tranche ni otra feature Trainer AI automáticamente.

Cualquier ampliación futura —estrategia de campaña avanzada, MCTS, aprendizaje continuo, memoria estratégica extendida o persistencia en disco— es opcional y requiere un nuevo workstream explícito.

## Invariantes externas

- `main` debe permanecer en `641d4b1fb0bcf964205d616e96f198f05d702197`;
- PR #105 OPEN / unmerged;
- PR #106 CLOSED / not merged;
- PR #107 es snapshot de Campaign Persistence y debe cerrarse sin merge después del gate documental final.

## Regla de memoria

Las decisiones materiales deben quedar en `docs/current/`, cuaderno temático, ADR o worklog; nunca solo en chat.
