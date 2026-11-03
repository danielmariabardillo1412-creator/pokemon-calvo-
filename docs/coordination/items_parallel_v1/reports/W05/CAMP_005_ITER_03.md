# IA5/W05 — CAMPAÑA_005 · ITER_03/10

**Estado inicial:** EN_CI_AUTOMATICA. La comprobación estática no sustituye a las pruebas funcionales.

**Rama exclusiva:** `codex/calvo-items-20261103-w05-camp005`. Fuente de autorización IA6: `CAMPAIGN_005_W05_GATE.md`, `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W05.md` y `AUTONOMOUS_REPAIR_V5.md`.

## Asignación autorizada — Scarlet/Violet

| MT | Movimiento SV |
| --- | --- |
| `tm154` | `hydro_cannon` |
| `tm155` | `frenzy_plant` |
| `tm156` | `outrage` |
| `tm157` | `overheat` |
| `tm158` | `focus_blast` |
| `tm159` | `leaf_storm` |

Cada movimiento se cotejó con `modules/inventory/item_connections_v1.json` y la fila 03 de la cola oficial, sin inferir compatibilidad de especies de otras generaciones.

## Cambios publicados y pruebas
- Fixture `tests/fixtures/parallel_items/w05_campaign_005.json`: solo se añadió bloque 03, preservando 01–02; commit `6787fc68b75cc996ba868370655dc3a881e2fbbd`.
- CSV `docs/coordination/items_parallel_v1/reports/W05/CAMP_005_PROGRESO.csv`: una sola fila nueva 03 con `EN_CI_AUTOMATICA`; commit `245b77936642d59990cde21471c86c2c5491dd7f`, que activa CI.
- Suites acumulativas `tests/tools/test_parallel_items_w05_campaign_005.py` y `tests/gameplay/parallel_items_w05_campaign_005.gd`, sin cambios de arnés ni producción. Python comprueba perfil SV, política, metadatos, PP y learnsets positivos reales. Godot ejecuta `FieldItemService.teach`, rechazos sin stock, propietario ajeno, especie incompatible, consumo unitario, PP, identidad/party, repetición sin coste y SaveV2.
- Cotejo estático posterior a publicación: **3 bloques, 3 filas y 18 IDs distintos**; todos idénticos en orden y movimiento al perfil SV y cola IA6, sin desviaciones.

## Evidencia de CI
- Bloques 01–02: [run #41718416082](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41718416082), SHA `83d89ccc862e2035181e7a0136c6256d73e9d063`, `completed/success`: Python `CAMP005_W05_PY PASS blocks=2 checks=116`, Godot `CAMP005_W05_GODOT PASS blocks=2 checks=446` y ambos gates PASS.
- Bloque 03: [run #41719102271](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41719102271) sobre SHA `245b77936642d59990cde21471c86c2c5491dd7f`, `pending` en primera observación. El run anterior del fixture #41719079083 podría cancelarse por concurrencia; su cancelación no indica fallo funcional.
- Antes de acreditar las 18 MT, exigir `completed/success` del SHA de progreso, recibos `CAMP005_W05_PY PASS blocks=3 checks=N`, `CAMP005_W05_GODOT PASS blocks=3 checks=N`, gates y N positivo.
- Regresiones CAMP004 y CAMP003 previstas por workflow para hitos 05/10 o parches de producción: sin parche de producción en bloque 03, no atribuir su ejecución aquí.

## Continuidad
Siguiente `p`: comprobar CI bloque 03 y ejecutar **solo bloque 04** `tm160;tm161;tm162;tm163;tm164;tm165` si procede. Si la CI falla, diagnosticar logs y corregir autónomamente el defecto W05 según V5 conservando negativos; elevar solo conflicto funcional compartido o acceso real denegado. Prohibido tocar `main`, V28, PR118, árbitra, otras ramas, catálogo/learnsets, políticas, 19 MT legacy, workflows o saves; sin merge. Al 10/10 declarar `CAMPAÑA_005_FINALIZADA` y STOP.

**Bloque 03 publicado, certificación pendiente al redactar.**
