# SIGUIENTE TRABAJO

## Workstream activo — Trainer AI Campaign Persistence V1

Rama:

`feature/trainer-ai-campaign-persistence-v1`

Parent certificado de entrada:

`f43dc6b158c35fe25139de5524b83f6fe2d3426f`

Ese parent es el freeze final de **Trainer AI Expertise V1**.

PR #107: **OPEN / DRAFT / NOT MERGED**.

## Plan fijo — P1-A cerrado, P1-B actual

1. **P1-A — ownership/persistence boundary audit** — **CLOSED / CERTIFIED / TEST-AUDIT-ONLY**.
2. **P1-B — contrato persistente + recovery/replacement** — **ACTUAL / CONTRACT-FIRST**.
3. **P1-C — integración productiva mínima** — PENDIENTE.
4. **P1-D — rematch/cross-session E2E + freeze** — PENDIENTE.

No añadir una quinta tranche por inercia.

## P1-A — evidencia cerrada

Checkpoint técnico exacto:

`26c11caa635cecb851b95cd636580cb250683a32`

- suite P1-A: **23/23 PASS**;
- aggregate: `CAMPAIGN_PERSISTENCE_OWNERSHIP_SEAM_LOCALIZED`;
- Trainer Evaluation Corpus: **521 PASS / 0 FAIL**;
- Team Composition workflow: **SUCCESS**;
- full CI: **18/18 workflows SUCCESS**;
- **0 producción / 0 Battle Core**.

El conteo agregado literal de Team Composition no fue expuesto por el conector para ese job, por lo que no se infiere desde otro SHA.

P1-A fijó además la separación entre el `campaign_snapshot` histórico deep-detached y el futuro owner persistente: el snapshot es DTO/context transport, no source of truth, y el proposal Game-Ready actual no lo conecta.

## P1-B — contrato exacto a certificar

P1-B es **CONTRACT-FIRST**. Antes de escribir el owner productivo debe demostrar ejecutablemente:

1. **Ownership autoritativo** — existe un único owner conceptual fuera de `BattleState` y `TrainerBattleSession`.
2. **Identity preservation** — el roster persistente conserva exactamente las mismas `CreatureInstance`; no duplica identidades.
3. **Post-battle default** — `reconcile_post_battle()` es la transición base; no hay full-heal automático.
4. **Persistent combat consequences** — HP, PP y persistent status sobreviven según el contrato actual; volatile/transient battle state se limpia.
5. **Explicit recovery** — cualquier heal/restore entre encuentros requiere policy/action explícita.
6. **Campaign replacement** — sustitución del roster fuera de combate es distinta del forced replacement de Battle Core.
7. **Fail-closed ownership** — IDs duplicados/double ownership no se corrigen ni resuelven silenciosamente.
8. **No BattleState persistence** — no se serializa ni conserva todo el estado runtime de batalla.
9. **Snapshot boundary** — `campaign_snapshot`, si se proyecta en el futuro, solo puede ser un DTO sanitizado/detached; nunca owner autoritativo.
10. **Combat isolation** — campaign/recovery/replacement no altera proposal/search/tie resolution.

### Evidencia de arquitectura que debe aprovechar P1-B

- `CreatureInstance.reconcile_post_battle()` ya preserva consecuencias persistentes y limpia estado volátil.
- `PlayerCollection` ya modela ownership por identidad con transferencias fail-closed.
- `SaveGameData` ya exige almacenamiento único por instance ID; se usa como precedente arquitectónico, no como scope de edición.
- `TrainerBattleSettlement` transporta outcome/progression pero no posee recovery/replacement.
- `WildAdventureSession` reconcilia post-battle sin auto-heal.

## Barreras P1-B

P1-B no autoriza:

- modificar producción del owner todavía;
- tocar Save V2;
- conectar el `campaign_snapshot` histórico al proposal Game-Ready;
- curar automáticamente;
- resetear HP/PP por intuición;
- reemplazar Pokémon KO silenciosamente;
- permadeath;
- persistir `BattleState` completo;
- usar campaign/recovery/replacement para decidir una acción;
- modificar search/proposal/brain/tie resolver;
- tocar Battle Core;
- reabrir scheduler/shared budget/660;
- abrir FASE34;
- mergear PR #105 o PR #107.

## Gate de entrada a P1-B

El HEAD documental que cierra P1-A debe pasar **18/18 workflows SUCCESS** antes de considerar P1-A frozen y empezar a añadir la suite P1-B.

## Invariantes externas

- PR #105 permanece OPEN / unmerged.
- PR #106 permanece CLOSED / not merged.
- PR #107 permanece OPEN / DRAFT / unmerged.
- `main` permanece exactamente en `641d4b1fb0bcf964205d616e96f198f05d702197`.
- P1-B parte del HEAD documental certificado de P1-A, no de `main`.
