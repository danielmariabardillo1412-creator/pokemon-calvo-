# EMPEZAR AQUÍ

Este archivo es el punto de entrada para recuperar el proyecto en una conversación, agente o sesión nueva.

## Lectura mínima

1. `PROJECT_STATE.md` — baseline certificado y estado real.
2. `NEXT_STEPS.md` — trabajo autorizado ahora.
3. `WORK_PROTOCOL.md` — reglas de ejecución/certificación.
4. `../project_book/TRAINER_AI_CAMPAIGN_PERSISTENCE.md` — cuaderno temático activo.

## Autoridad

Si dos fuentes se contradicen:

1. commit/branch/PR/CI del SHA exacto en GitHub;
2. fuente canónica/inmutable del dominio;
3. `docs/current/`;
4. arquitectura/ADR vigentes;
5. cuadernos temáticos;
6. historial/worklogs;
7. memoria del chat.

## Baseline moderno

Freeze funcional anterior a Campaign Persistence:

`f43dc6b158c35fe25139de5524b83f6fe2d3426f`

Trainer AI Expertise V1: **CLOSED / CERTIFIED / FROZEN**.

Rama activa:

`feature/trainer-ai-campaign-persistence-v1`

PR #107: **OPEN / DRAFT / NOT MERGED**.

## Campaign Persistence — punto real

- P1-A — **CLOSED / CERTIFIED**
  - `26c11caa635cecb851b95cd636580cb250683a32`
  - 23/23; Evaluation 521/0; 18/18 CI.
- P1-B — **CLOSED / CERTIFIED**
  - `f900fb79fb324c6e05d218eb741352e4d3a5db1f`
  - 27/27; Evaluation 548/0; 18/18 CI.
- P1-B documentary parent — **CERTIFIED**
  - `4e96c999818916e90c6f8e9bfbc381f516e347dc`
  - 18/18 CI.
- P1-C — **CLOSED / CERTIFIED**
  - `311349938af6c57f4507e2160e157cffbc124afb`
  - 34/34; Evaluation **582/0**; Team Composition SUCCESS; 18/18 CI.
- **P1-D — NEXT / FINAL** después de certificar el HEAD documental P1-C.

## Contrato que no debe reinterpretarse

- `TrainerCampaignRosterOwner` es authority de roster dentro del runtime de campaña;
- conserva la misma `CreatureInstance`;
- handoff al battle session copia solo el Array;
- `reconcile_post_battle()` no auto-cura;
- HP/PP/persistent status son persistentes;
- volatile/stages son battle-only;
- recovery es explícito inter-battle;
- campaign replacement es externo a Battle Core;
- IDs/ownership inválidos fallan cerrado;
- `campaign_snapshot` histórico no es source of truth;
- no persistir BattleState;
- Save V2 sigue fuera de este V1.

## P1-D — secuencia canónica

El cierre E2E debe demostrar:

`primer combate -> settlement -> rival KO persiste -> revancha sin recovery bloqueada -> recovery explícito -> misma instancia restaurada -> segundo combate real`

P1-D puede retirar el one-shot técnico, pero no introducir auto-recovery. Después: regresión global, freeze final y cierre de PR #107 sin merge.

## Invariantes externas

- `main` = `641d4b1fb0bcf964205d616e96f198f05d702197`.
- PR #105 OPEN / unmerged.
- PR #106 CLOSED / not merged.
- PR #107 OPEN / DRAFT / unmerged hasta freeze.

## Regla de memoria

Las decisiones materiales deben quedar en `docs/current/`, cuaderno temático, ADR o worklog; nunca solo en chat.
