# ESTADO ACTUAL DEL PROYECTO

## Baseline canónico

`main = d2ad6796a93e6db56ef24c98431a3909e3874cdf`

Estado: **CERTIFICADO**.

La consolidación moderna terminó el 2026-09-08:

- antigua `main`: `641d4b1fb0bcf964205d616e96f198f05d702197`;
- freeze moderno previo: `8552f52158ffc21c27b4e8f1dbc7caa63ac1a467`;
- merge histórico: `2f63312e8dc3e61c8fadbd02e97972fff6d0eacc`;
- HEAD final/promovido: `d2ad6796a93e6db56ef24c98431a3909e3874cdf`;
- resultado: **18/18 workflows SUCCESS** sobre ese HEAD exacto;
- PR #108 quedó cerrado/merged con `merge_commit_sha = d2ad6796...`, sin crear SHA adicional.

`main` vuelve a ser el baseline normal de desarrollo. La antigua política de snapshots cerrados sin merge queda retirada.

## DATA V3

Estado: **CERRADO / CERTIFICADO**.

Contrato preservado:

- 1.025 especies;
- 326 formas;
- 18 tipos runtime;
- 919 movimientos;
- 373 habilidades;
- 2.222 objetos;
- 61.102 learnset entries;
- 554 evoluciones.

Frontera ejecutable relevante:

- Moves: 590 RUNTIME_SUPPORTED / 71 PARTIAL_RUNTIME / 246 DATA_ONLY / 12 UNSUPPORTED;
- Abilities: 21 RUNTIME_SUPPORTED / 14 PARTIAL_RUNTIME / 338 DATA_ONLY;
- Evolutions: 391 RUNTIME_SUPPORTED / 149 DATA_ONLY / 14 UNSUPPORTED.

No reabrir DATA V3 por cobertura estética.

## Trainer AI

Estado obligatorio completo:

- runtime 26.67 — CLOSED / COMPLETED;
- Game-Ready 27.1 — CLOSED / VALIDATED;
- Expertise V1 — CLOSED / CERTIFIED / FROZEN;
- Campaign Persistence V1 — CLOSED / CERTIFIED / FROZEN.

Checkpoint técnico P1-D:

`b314b8bb81db439e3063433644c691181ed39ef4`

Evidencia final:

- P1-D 46/46;
- Evaluation 628/0;
- 18/18 workflows SUCCESS.

No existe P1-E.

## Estado del videojuego visible

`project.godot` sigue arrancando en:

`res://scenes/overworld/technical_overworld.tscn`

Es una vertical slice técnica, no una campaña completa. Los cimientos ya incluyen Battle Core, progresión/captura, Party/Storage, inventario, Save V2, encuentros/overworld técnico, localización y Trainer AI.

## Game Foundation V1 — ACTIVE

Rama:

`feature/game-foundation-v1`

Baseline:

`d2ad6796a93e6db56ef24c98431a3909e3874cdf`

Cuaderno:

`docs/project_book/GAME_FOUNDATION.md`

Plan fijo: GF1-A..GF1-F.

### GF1-A — Game State + contrato de campaña — ACTIVE / PENDING CI

Producción nueva:

`modules/gameplay/game_campaign_state.gd`

`GameCampaignState` es autoridad pura y separada para:

- `campaign_id`;
- ubicación lógica `current_map_id + current_spawn_id` actualizada atómicamente;
- inicial write-once;
- story flags;
- entrenadores derrotados monotónicos;
- `campaign_stage` no negativo/monotónico;
- DTO `to_dict()` determinista y desacoplado para Save V3 posterior.

GF1-A no modifica Save V2, Battle Core, Trainer AI, PlayerCollection ni CreatureInstance.

Tests focales:

- `GameCampaignStateTestSuite`;
- `GameCampaignStateBoundaryTestSuite`;
- `game_foundation_test_runner.gd`.

Workflow nuevo:

`Game Foundation Tests`

Por tanto la matriz normal de GF1 pasa de 18 a **19 workflows**. Este número es contrato nuevo, pero GF1-A todavía no se declara certificado hasta ejecutar los 19 sobre el HEAD final exacto.

## Próximos tramos GF1

- GF1-B mapas/transiciones;
- GF1-C NPC/diálogo/eventos;
- GF1-D Save V3 mundo/campaña;
- GF1-E servicios/UI mínima;
- GF1-F vertical slice jugable E2E.

## Invariantes externas

- PR #105 OPEN / unmerged;
- PR #106 CLOSED / not merged;
- PR #107 CLOSED / not merged;
- Save V2 permanece congelado hasta GF1-D;
- no reabrir DATA V3 o Trainer AI salvo regresión real o feature explícita.
