# ESTADO ACTUAL DEL PROYECTO

## Baseline Trainer AI certificado

Trainer AI queda cerrado en sus sistemas obligatorios actuales:

- Trainer AI runtime system 26.67 — **CLOSED / COMPLETED**;
- Trainer AI Game-Ready 27.1 — **CLOSED / VALIDATED**;
- Trainer AI Expertise V1 — **CLOSED / CERTIFIED / FROZEN**;
- Trainer AI Campaign Persistence V1 — **CLOSED / CERTIFIED / FROZEN**.

No hay una tranche Trainer AI obligatoria activa después de P1-D.

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

## Trainer AI de combate — cerrado

El entrenador de combate dispone de memoria bilateral sanitizada, beliefs sin información oculta, búsqueda acotada, MOVE/SWITCH/ITEM donde corresponda, switching estratégico, loadouts/composición, proposal sobre todas las raíces legales, sustitución autónoma side_b, tie resolution game-ready, integración real Overworld/Battle Core, victoria/derrota/reset, full-battle adversarial, estilos y expertise certificados.

No reabrir C3f, Game-Ready 27.x ni Expertise V1 salvo regresión reproducible.

## Trainer AI Campaign Persistence V1 — CLOSED / CERTIFIED / FROZEN

Rama snapshot:

`feature/trainer-ai-campaign-persistence-v1`

Parent original:

`f43dc6b158c35fe25139de5524b83f6fe2d3426f`

Parent documental P1-D:

`bf604176a66abde8ad475dd54f7375420c21c06b`

Checkpoint técnico final P1-D:

`b314b8bb81db439e3063433644c691181ed39ef4`

### P1-A — CLOSED / CERTIFIED

Checkpoint:

`26c11caa635cecb851b95cd636580cb250683a32`

- 23/23 PASS;
- Evaluation 521/0;
- 18/18 workflows SUCCESS;
- 0 producción / 0 Battle Core.

Localizó el ownership seam entre caller, `TrainerBattleSession` y las mismas `CreatureInstance`.

### P1-B — CLOSED / CERTIFIED / CONTRACT-FIRST

Checkpoint:

`f900fb79fb324c6e05d218eb741352e4d3a5db1f`

- 27/27 PASS;
- Evaluation 548/0;
- 18/18 workflows SUCCESS;
- 0 producción / 0 Battle Core.

Contrato: misma `CreatureInstance`; HP/PP/persistent status sobreviven a `reconcile_post_battle()`; volatile/stages se limpian; no auto-heal; recovery/replacement explícitos; IDs/ownership fail-closed; no BattleState persistido; `campaign_snapshot` no es authority.

HEAD documental P1-B:

`4e96c999818916e90c6f8e9bfbc381f516e347dc` — 18/18 SUCCESS.

### P1-C — CLOSED / CERTIFIED

Checkpoint:

`311349938af6c57f4507e2160e157cffbc124afb`

- P1-C 34/34 PASS;
- Evaluation 582/0;
- Godot SUCCESS;
- Team Composition SUCCESS;
- 18/18 workflows SUCCESS.

Producción:

- `TrainerCampaignRosterOwner` como owner estable fuera de BattleState/TrainerBattleSession;
- misma identidad exacta de `CreatureInstance`;
- handoff desacopla solo el Array;
- configuración/replacement atómicos y fail-closed;
- recovery explícito;
- Overworld usa `_trainer_campaign_owner`.

P1-C no modificó Save V2, Battle Core ni combat AI.

HEAD documental P1-C / parent P1-D:

`bf604176a66abde8ad475dd54f7375420c21c06b` — 18/18 SUCCESS.

### P1-D — CLOSED / CERTIFIED / FINAL

Checkpoint técnico final:

`b314b8bb81db439e3063433644c691181ed39ef4`

Resultado:

- P1-D: **46/46 PASS**;
- Evaluation: **628 PASS / 0 FAIL**;
- Godot 4.7: **SUCCESS**;
- Team Composition: **SUCCESS**;
- full technical CI: **18/18 workflows SUCCESS**.

Ciclo E2E certificado:

`primer combate -> settlement -> rival KO persiste -> revancha inmediata bloqueada -> recovery explícito -> misma CreatureInstance -> segundo combate real`

La revancha sin recovery falla con `no_available_opponent_creature`. No existe auto-heal oculto. Tras recovery explícito se conserva la misma referencia, se restauran HP/PP y el segundo combate vuelve a usar esa misma instancia con memoria fresca y respuesta autónoma side_b.

Combat AI sigue reportando `campaign_policy_used = false`, `recovery_policy_used = false` y `replacement_policy_used = false`.

### Incidente P1-D registrado

Primer intento:

`c0375c70fe15f76e0a75e51726ec9b083824b166`

Evaluation: **626 PASS / 2 FAIL**.

Los dos fallos eran una falsa alarma de auditoría estática: se buscaba la palabra `BattleState` en el source del owner y apareció en un comentario que describía que el owner vive fuera de BattleState. El runtime P1-D estaba verde.

La corrección fue test-only y sustituyó esa búsqueda textual por comprobaciones de dependencias operativas prohibidas. Checkpoint corregido `b314b8bb...`: **46/46, 628/0, 18/18 CI**.

## Scope congelado

Campaign Persistence V1 no modifica:

- Save V2;
- Battle Core;
- persistencia completa de BattleState;
- search/proposal/brain/tie resolver;
- FASE34;
- scheduler/shared-budget/660;
- conexión de `campaign_snapshot` al proposal Game-Ready.

No introduce auto-recovery ni replacement silencioso.

## Continuación

No hay P1-E ni trabajo Trainer AI obligatorio pendiente. Cualquier ampliación futura —estrategia de campaña avanzada, MCTS, aprendizaje continuo, memoria estratégica extendida o persistencia en disco— debe abrirse como feature separada y opcional, no como continuación automática de este workstream.

## Invariantes externos

- `main` = `641d4b1fb0bcf964205d616e96f198f05d702197`;
- PR #105 permanece OPEN / unmerged;
- PR #106 permanece CLOSED / not merged;
- PR #107 debe cerrarse sin merge después de que el HEAD documental final pase 18/18 CI.
