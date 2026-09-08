# SIGUIENTE TRABAJO

## Trainer AI — ningún tramo obligatorio activo

**Trainer AI Campaign Persistence V1 está CLOSED / CERTIFIED / FROZEN.**

No existe P1-E y no debe abrirse una quinta tranche por inercia.

Los cuatro tramos previstos están terminados:

1. P1-A ownership/persistence boundary audit — CLOSED / CERTIFIED.
2. P1-B persistent-state + recovery/replacement contract — CLOSED / CERTIFIED.
3. P1-C minimal production integration — CLOSED / CERTIFIED.
4. P1-D rematch/cross-battle E2E + regression — CLOSED / CERTIFIED.

## Checkpoint técnico final

`b314b8bb81db439e3063433644c691181ed39ef4`

Parent documental certificado de P1-D:

`bf604176a66abde8ad475dd54f7375420c21c06b`

Evidencia final:

- P1-D: **46/46 PASS**;
- Trainer Evaluation Corpus: **628 PASS / 0 FAIL**;
- Godot 4.7: SUCCESS;
- Team Composition: SUCCESS;
- full technical CI: **18/18 workflows SUCCESS**.

Secuencia certificada:

`KO persistente -> rematch bloqueado -> recovery explícito -> misma CreatureInstance -> segundo combate real`

La revancha inmediata sin recovery falla con `no_available_opponent_creature`. Recovery no es automático y combat AI permanece aislado de campaign/recovery/replacement.

## Scope congelado

No reabrir como parte de Campaign Persistence V1:

- Save V2;
- persistencia completa de BattleState;
- Battle Core;
- search/proposal/brain/tie resolver;
- FASE34;
- scheduler/shared-budget/660;
- `campaign_snapshot` Game-Ready;
- auto-heal post-battle;
- replacement silencioso de Pokémon KO.

## Qué puede venir después

No hay una tarea Trainer AI obligatoria preseleccionada.

Si más adelante se desea ampliar al rival, debe abrirse un **workstream separado** con objetivo y contrato propios. Ejemplos opcionales, no blockers:

- estrategia de campaña a largo plazo;
- memoria estratégica extendida entre encuentros;
- MCTS u otra planificación más profunda;
- aprendizaje continuo o adaptación persistente;
- persistencia en disco de rivales/campaña;
- progresión autónoma del rival fuera de combate.

Ninguna de esas features forma parte del cierre actual ni debe iniciarse automáticamente.

## Cierre de snapshot pendiente únicamente de protocolo

El PR #107 es un PR de snapshot y debe cerrarse **sin merge** cuando el HEAD documental final de este freeze haya pasado 18/18 workflows SUCCESS.

Después de ese cierre no queda trabajo funcional pendiente en Campaign Persistence V1.

## Invariantes

- `main` = `641d4b1fb0bcf964205d616e96f198f05d702197`;
- PR #105 OPEN / unmerged;
- PR #106 CLOSED / not merged;
- PR #107 se cierra sin merge tras el gate documental final.
