# Game Foundation V1

Estado: **ACTIVE — GF1-A**.

Este cuaderno es la memoria temática única de Game Foundation V1. No crear un cuaderno por cada tramo GF1-A..GF1-F.

## Baseline

Game Foundation V1 parte de la `main` moderna consolidada y certificada:

`d2ad6796a93e6db56ef24c98431a3909e3874cdf`

Ese SHA pasó **18/18 workflows SUCCESS** antes de abrir GF1. La política antigua de snapshots cerrados sin merge queda retirada: desde este punto `main` vuelve a ser baseline canónico.

Rama de trabajo:

`feature/game-foundation-v1`

## Objetivo de producto

Convertir los cimientos técnicos existentes en una primera mini-campaña jugable real, aun con arte provisional:

`nueva partida -> inicial -> pueblo/mapa -> ruta -> encuentro/captura -> entrenador -> servicio -> guardar -> cargar -> continuar`

El objetivo no es producir todavía una región completa ni perseguir 100% de PokéAPI.

## Plan fijo

1. **GF1-A — Game State + contrato de campaña** — ACTIVE.
2. **GF1-B — mapas y transiciones** — PENDING.
3. **GF1-C — NPC, diálogo y eventos data-driven** — PENDING.
4. **GF1-D — Save V3 de mundo/campaña** — PENDING.
5. **GF1-E — servicios y UI mínima** — PENDING.
6. **GF1-F — vertical slice de campaña E2E** — PENDING.

No existe un GF1-G implícito. Cualquier ampliación tras la vertical slice debe definirse como trabajo separado o una nueva versión explícita.

## GF1-A — contrato

### Autoridad nueva

`GameCampaignState` es un `RefCounted` puro y separado. Es dueño únicamente del progreso de campaña/mundo que no pertenece a Party/Storage/Inventory/Battle Core/Trainer AI.

Archivo de producción:

`modules/gameplay/game_campaign_state.gd`

Contrato actual:

- `campaign_id` estable y no vacío;
- `current_map_id + current_spawn_id` forman una pareja de ubicación que se actualiza atómicamente;
- `starter_species_id` es write-once: repetir la misma elección es idempotente, intentar cambiarla falla cerrado;
- story flags son hechos booleanos identificados por ID;
- entrenadores derrotados son hechos monotónicos e idempotentes;
- `campaign_stage` es entero no negativo y monotónico;
- `to_dict()` produce DTO JSON-safe, ordenado y desacoplado para que GF1-D pueda persistirlo sin compartir colecciones mutables;
- `validate()` protege invariantes del estado vivo.

### Lo que GF1-A NO hace

- no modifica Save V2;
- no persiste posición física ni fichero de campaña;
- no crea mapas, warps ni spawn nodes;
- no crea sistema de quests;
- no toca Battle Core;
- no toca Trainer AI;
- no mete Party/Storage/Inventory dentro de `GameCampaignState`;
- no valida existencia de especies contra PokéAPI dentro del objeto puro: esa validación pertenece a la capa de aplicación/catálogos.

## Tests GF1-A

Suites:

- `GameCampaignStateTestSuite`
- `GameCampaignStateBoundaryTestSuite`

Runner:

`tests/gameplay/game_foundation_test_runner.gd`

Nuevo workflow:

`.github/workflows/game-foundation-tests.yml`

La matriz normal pasa de 18 a **19 workflows**. El gate de Game Foundation exige al menos 45 checks y 0 FAIL; el conteo real debe registrarse después de ejecutar CI, no predecirse como resultado.

## Fronteras heredadas

- DATA V3 permanece CLOSED / CERTIFIED.
- Trainer AI permanece CLOSED / CERTIFIED / FROZEN.
- Campaign Persistence V1 no se reabre.
- Save V2 sigue siendo autoridad de criaturas + party + storage + inventory hasta GF1-D.
- `PlayerCollection` conserva Party + Storage + Inventory y no absorbe campaña.
- `CreatureInstance` conserva la identidad persistente de criatura.

## Invariantes externos

- PR #105 permanece OPEN / unmerged.
- PR #106 CLOSED / not merged.
- PR #107 CLOSED / not merged.
- PR #108 cerró la consolidación de `main`; su `merge_commit_sha` coincide con `d2ad6796...`, sin SHA adicional.

## Próximo gate

GF1-A no se considera cerrado hasta que:

1. el proyecto importe en Godot 4.7;
2. `Game Foundation Tests` esté verde sobre el HEAD exacto;
3. la matriz normal completa de 19 workflows esté verde sobre ese mismo HEAD;
4. el cuaderno y `docs/current/` registren el SHA certificado real;
5. `main` no se mueva hasta esa certificación.
