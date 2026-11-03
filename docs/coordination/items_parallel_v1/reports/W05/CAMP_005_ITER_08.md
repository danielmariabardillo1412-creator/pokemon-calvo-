> **CI DEFINITIVA VERIFICADA — BLOQUE 08/10 (2026-11-03):** [GitHub Actions #41733471535](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41733471535), SHA funcional `e455c80adb322fff21866e914e2538f6586e8706`, job `126256918456`, `completed/success`. Recibos exactos observados en el log: `CAMP005_W05_MANIFEST_PASS reserved=10 completed=8 ids=60 kind=NEW_IDS`; `CAMP005_W05_PY PASS blocks=8 checks=464`; `CAMP005_GATE_PY_PASS worker=W05 blocks=8 checks=464`; `CAMP005_W05_GODOT PASS blocks=8 checks=1736`; `CAMP005_GATE_GODOT_PASS worker=W05 blocks=8 checks=1736`. **48/48 MT de CAMP005 verificadas por pruebas automatizadas Python/Godot headless.** Las regresiones completas CAMP004 y CAMP003 no se ejecutaron en el bloque 08 por diseño; pasaron en hito 05 y se repetirán en 10. Esta certificación prevalece sobre las referencias históricas inferiores a CI pendiente. Sin modificación de producción ni degradación de pruebas; no se acredita UI/GPU.

# IA5/W05 — CAMPAÑA_005 · ITER_08/10

**Estado de publicación: EN_CI_AUTOMATICA.** El cotejo del catálogo no sustituye la enseñanza funcional; CI de este SHA pendiente de verificación al redactar.

## Reserva oficial y mapeo
- Rama única: `codex/calvo-items-20261103-w05-camp005`; autoridad IA6 en `CAMPAIGN_005_W05_GATE.md`, `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W05.md` y `AUTONOMOUS_REPAIR_V5.md`, rama árbitra `codex/calvo-items-20261101-arbitro`.
- Bloque 08 exacto `tm184;tm185;tm186;tm187;tm188;tm189`, movimientos de `modules/inventory/item_connections_v1.json`, `scarlet-violet`:

| MT | Movimiento SV |
| --- | --- |
| `tm184` | `vacuum_wave` |
| `tm185` | `lunge` |
| `tm186` | `high_horsepower` |
| `tm187` | `icicle_spear` |
| `tm188` | `scald` |
| `tm189` | `heat_crash` |

## Cambios y control
1. `tests/fixtures/parallel_items/w05_campaign_005.json`: añadido exclusivamente bloque 08, intactos bloques 01–07, commit `a1c2d55b7d652e6c01829542a5216c8abbfa0327`.
2. `docs/coordination/items_parallel_v1/reports/W05/CAMP_005_PROGRESO.csv`: una sola fila nueva de bloque 08 con estado `EN_CI_AUTOMATICA`, commit `e455c80adb322fff21866e914e2538f6586e8706`, que dispara CI.
3. Cotejo estático post-commit: **8 bloques, 8 filas, 48 MT únicas**, seis por bloque, todos los IDs y movimientos en idéntico orden entre fixture, progreso, cola aprobada de IA6 y perfil SV; cero discrepancias.
4. Sin modificaciones en runners ni producción. Los runners acumulativos Python y Godot de CAMP005 prueban mapeos reales SV, learnset compatible, PP, servicio `FieldItemService.teach`, rechazos de especie incompatible, propietario inexistente, falta de stock, consumo exacto de una MT, duplicado ya conocido, identidad/party y persistencia SaveV2. Ninguna aserción fue rebajada.

## CI y regresiones
- Bloques 01–07 certificados en [Actions #41727197381](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41727197381), SHA `fba3e31a39ed4416745541742004dd16ca5d51fc`, `completed/success`; `CAMP005_W05_PY PASS blocks=7 checks=406` y `CAMP005_W05_GODOT PASS blocks=7 checks=1521`, ambos gates PASS.
- Bloque 08: [Actions #41733471535](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41733471535), SHA de progreso `e455c80adb322fff21866e914e2538f6586e8706`, inicialmente `pending`. La CI intermedia de fixture #41733442793 podría cancelarse por concurrencia, sin que ello implique fallo funcional.
- Para certificar 48 MT exigir último run `completed/success`, y `CAMP005_W05_PY PASS blocks=8 checks=N`, `CAMP005_GATE_PY_PASS worker=W05 blocks=8 checks=N`, `CAMP005_W05_GODOT PASS blocks=8 checks=N`, `CAMP005_GATE_GODOT_PASS worker=W05 blocks=8 checks=N`, con N positivo y logs reales.
- Las 60 MT de CAMP004 y las 60 de CAMP003 superaron las regresiones en hito 05 [Actions #41721306449](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41721306449); la siguiente regresión integral obligatoria es en hito 10, o ante parche de producción. No atribuir regresiones a bloque 08 sin logs.

## Próxima orden y límites
- Siguiente `p`: comprobar CI bloque 08; ejecutar **solo bloque 09** `tm190;tm191;tm192;tm193;tm194;tm195` según fila y mapeo SV oficiales. Ante fallo real, diagnosticar y autorreparar dentro de W05 bajo V5 sin relajar aserciones; escalar solo conflicto compartido o permisos denegados.
- Prohibido modificar `main`, V28, PR118, árbitra, otras ramas, catálogos, learnsets, políticas, 19 MT históricas inactivas, guardados, workflows o hacer merge. Godot headless no acredita UI/GPU. Al 10/10 `CAMPAÑA_005_FINALIZADA` y STOP.

**BLOQUE 08 ENTREGADO; CI FUNCIONAL AÚN PENDIENTE EN ESTA VERSIÓN DEL INFORME.**
