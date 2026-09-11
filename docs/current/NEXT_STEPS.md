# SIGUIENTE TRABAJO

## Baseline canónico

`main = d2ad6796a93e6db56ef24c98431a3909e3874cdf`

Estado: **CERTIFICADO — 18/18 workflows SUCCESS** antes de abrir Game Foundation V1.

La consolidación de `main` está terminada. No volver a tratar `main` como histórica.

## Workstream activo — Game Foundation V1

Rama:

`feature/game-foundation-v1`

Cuaderno:

`docs/project_book/GAME_FOUNDATION.md`

### GF1-A — Game State + contrato de campaña — ACTIVE

Objetivo actual:

- autoridad `GameCampaignState` separada de `PlayerCollection` y Battle Core;
- identidad estable de campaña;
- mapa + spawn como transición atómica;
- inicial write-once;
- story flags;
- entrenadores derrotados;
- etapa de campaña monotónica;
- DTO determinista/desacoplado preparado para Save V3 posterior.

Archivos focales:

- `modules/gameplay/game_campaign_state.gd`
- `tests/gameplay/game_campaign_state_test_suite.gd`
- `tests/gameplay/game_campaign_state_boundary_test_suite.gd`
- `tests/gameplay/game_foundation_test_runner.gd`
- `.github/workflows/game-foundation-tests.yml`

### Gate de cierre GF1-A

1. `Game Foundation Tests` PASS / 0 FAIL;
2. import Godot 4.7 limpio;
3. matriz normal completa ahora de **19 workflows** en SUCCESS sobre el mismo HEAD exacto;
4. registrar SHA real certificado en `GAME_FOUNDATION.md` y `PROJECT_STATE.md`;
5. solo entonces promover a `main` y abrir GF1-B.

Save V2 no se modifica en GF1-A.

## Plan fijo restante

2. **GF1-B — mapas y transiciones**
   - mapas configurables;
   - puertas/warps;
   - spawn points;
   - zonas de encuentro;
   - triggers de entrenador/NPC.

3. **GF1-C — NPC, diálogo y eventos data-driven**
   - diálogo;
   - condiciones por flags;
   - acciones/eventos;
   - entrenador una vez / diálogo posterior;
   - objetos o desbloqueos simples.

4. **GF1-D — Save V3 de mundo/campaña**
   - persistir `GameCampaignState` junto al agregado de jugador;
   - mapa/posición/flags/entrenadores/progreso;
   - carga transaccional;
   - migración explícita V2 -> V3.

5. **GF1-E — servicios y UI mínima**
   - curación;
   - tienda;
   - PC/storage;
   - party/bolsa básicas.

6. **GF1-F — vertical slice jugable E2E**
   - nueva partida;
   - elección de inicial;
   - pueblo + ruta;
   - encuentro/captura;
   - entrenador real con Trainer AI;
   - servicio;
   - save/load y continuación.

Después de GF1-F se decidirá por separado rival autónomo de overworld, contenido, arte/audio, ampliaciones mecánicas concretas y distribución.

No reabrir DATA V3 ni Trainer AI por inercia.
