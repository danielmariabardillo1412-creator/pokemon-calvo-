# IA5/W05 — CAMPAÑA_004 · ITER_05/10 — MT Scarlet/Violet

**Estado al publicar: EN_CI_AUTOMATICA.** La consistencia estática de los IDs no equivale a PASS de enseñanza funcional.

## Mandato y selección autorizada

Rama única `codex/calvo-items-20261103-w05-camp004`. Autoridad IA6 `CAMPAIGN_004_W05_GATE.md`, `CAMPAIGN_004_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_004_W05.md`, `AUTONOMOUS_REPAIR_V5.md`. Bloque `05,W05,MACHINE` con seis MT exactas:

| MT | Movimiento Scarlet/Violet |
| --- | --- |
| `tm106` | `drill_run` |
| `tm107` | `will_o_wisp` |
| `tm108` | `crunch` |
| `tm109` | `trick` |
| `tm110` | `liquidation` |
| `tm111` | `giga_drain` |

Cada ID y su movimiento están cotejados contra la cola aprobada y `modules/inventory/item_connections_v1.json` en versión `scarlet-violet`, sin inferir compatibilidades de otros juegos.

## Publicación y controles

1. `tests/fixtures/parallel_items/w05_campaign_004.json`: añadido **solo bloque 05** con las seis MT, conservando los bloques 01–04. Commit `ed2b61dddbb2f923aaa90cdf7299ba32d63a2012`.
2. `docs/coordination/items_parallel_v1/reports/W05/CAMP_004_PROGRESO.csv`: una nueva fila `05`, `EN_CI_AUTOMATICA`, commit `0ab410a15fa47b301b76f68c402a2e8e8d3d9fd7` que activa la CI.
3. Se conservan los runners de CAMP004 `tests/tools/test_parallel_items_w05_campaign_004.py` y `tests/gameplay/parallel_items_w05_campaign_004.gd`. La suite Python comprueba metadatos, política, versión y learnsets reales SV. La suite Godot utiliza `FieldItemService.teach` auténtico y comprueba especies compatibles/incompatibles, propiedad, falta de stock, consumo único, PP, rechazo de repetición y SaveV2. No se alteraron aserciones ni se inventaron especies válidas.
4. Cotejo estático post-commit en repositorio: **5 bloques, 5 filas CSV, 30 MT únicas**, seis por bloque, correspondencia idéntica de IDs, orden y movimientos entre fixtures, progreso, cola IA6 y perfil SV. Sin discrepancias. Este control no sustituye a ejecutar Godot.

## Evidencia CI y regresión

- Bloques 01–04 **verificados**: [Actions #41575917016](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41575917016), SHA `64d7f53bba17dbba7403721bb8c89831d47b1844`, `completed/success`; leídos en log `CAMP004_W05_PY PASS blocks=4 checks=232` y `CAMP004_W05_GODOT PASS blocks=4 checks=876`, además de los dos gates.
- El mismo run conserva regresiones **CAMP003** de 60 MT: `CAMP003_W05_PY PASS blocks=10 checks=580` y `CAMP003_W05_GODOT PASS blocks=10 checks=2166`; y **CAMP002**, 11 tests `OK`.
- Bloque 05: [Actions #41576524159](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41576524159), SHA del progreso `0ab410a15fa47b301b76f68c402a2e8e8d3d9fd7`, estado inicialmente `pending`. La ejecución de fixture #41576483399 estaba `in_progress` y puede cancelarse por `concurrency.cancel-in-progress` sin implicar fallo de pruebas.
- Para acreditar las 30 MT, exigir `completed/success` del SHA de progreso, recibos `CAMP004_W05_PY PASS blocks=5 checks=N` y `CAMP004_W05_GODOT PASS blocks=5 checks=N` con N positivo, validadores de manifiesto y regresión CAMP003/CAMP002 en el mismo run.

## Siguiente `p`, autonomía V5 y fronteras

- Consultar primero CI 05. Si `success`, ejecutar **solo bloque 06** `tm112;tm113;tm114;tm115;tm116;tm117`, según la cola. Si sigue en curso, permite únicamente otro bloque de pruebas independiente sin inventar PASS. Si falla, diagnosticar y reparar bajo V5 el defecto propio con caso rojo/verde, regresiones completas y nuevo run, sin rebajar controles. Escalar a IA6 solo conflictos entre trabajadoras, arquitectura/API compartida, norma general o permisos realmente denegados.
- `main`, V28, PR118, árbitra, ramas ajenas, catálogos, política global, 19 MT legacy, workflows y saves reales permanecen protegidos. Sin merge, sin acreditación visual/GPU por CI headless. Límite 10/10 y `CAMPAÑA_004_FINALIZADA`.

**ITER_05/10 entregada. Estado del nuevo bloque: CI pendiente al redactar.**
