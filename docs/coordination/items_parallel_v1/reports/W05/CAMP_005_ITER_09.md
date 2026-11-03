> **CI DEFINITIVA VERIFICADA — BLOQUE 09/10 (2026-11-04):** [GitHub Actions #41737890652](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41737890652), SHA funcional `0a69eaf51999f7a26cd69e34cf52f43f7a2ff5ff`, job `126272071488`, `completed/success`. Recibos de logs reales: `CAMP005_W05_MANIFEST_PASS reserved=10 completed=9 ids=60 kind=NEW_IDS`; `CAMP005_W05_PY PASS blocks=9 checks=522`; `CAMP005_GATE_PY_PASS worker=W05 blocks=9 checks=522`; `CAMP005_W05_GODOT PASS blocks=9 checks=1951`; `CAMP005_GATE_GODOT_PASS worker=W05 blocks=9 checks=1951`. **54/54 MT de CAMP005 verificadas por pruebas Python y Godot headless.** Regresiones CAMP004 y CAMP003 no ejecutadas en bloque 09; fueron verificadas en el hito 05 y deberán repetirse en el hito final 10. Este veredicto prevalece sobre estados históricos de CI pendiente que aparecen debajo. Sin cambios de producción ni rebaja de pruebas; UI/GPU no acreditadas.

# IA5/W05 — CAMPAÑA_005 · ITER_09/10

**Estado de publicación: EN_CI_AUTOMATICA.** La concordancia estática no se considera PASS de enseñanza real hasta verificar la CI sobre el SHA de progreso.

## Asignación IA6 y mapeo SV

- Rama exclusiva `codex/calvo-items-20261103-w05-camp005`; autoridad IA6 `CAMPAIGN_005_W05_GATE.md`, `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W05.md` y `AUTONOMOUS_REPAIR_V5.md` en rama árbitra.
- Bloque 09 aprobado: `tm190;tm191;tm192;tm193;tm194;tm195`. Mapeo `scarlet-violet` verificado en `modules/inventory/item_connections_v1.json`:

| MT | Movimiento SV |
| --- | --- |
| `tm190` | `solar_blade` |
| `tm191` | `uproar` |
| `tm192` | `focus_punch` |
| `tm193` | `weather_ball` |
| `tm194` | `grassy_glide` |
| `tm195` | `burning_jealousy` |

## Archivos, contratos y trazabilidad

1. Fixture `tests/fixtures/parallel_items/w05_campaign_005.json`: añadido exclusivamente bloque 09 con seis casos, sin alterar 01–08. Commit `c521dfeb8cf04ca45f224d0690d9e9d600052ca6`.
2. Progreso `docs/coordination/items_parallel_v1/reports/W05/CAMP_005_PROGRESO.csv`: una fila nueva 09 `EN_CI_AUTOMATICA`, commit `0a69eaf51999f7a26cd69e34cf52f43f7a2ff5ff`. Este commit activa CI.
3. Control estático post-commit en GitHub: **9 bloques, 9 filas, 54 MT únicas**, seis por bloque; posiciones, IDs y movimientos exactos respecto a la cola IA6 y perfil Scarlet/Violet, cero errores.
4. Runners acumulativos Python `tests/tools/test_parallel_items_w05_campaign_005.py` y Godot `tests/gameplay/parallel_items_w05_campaign_005.gd` preservados. Python valida catálogo, política, PP y al menos una especie compatible por learnset SV. Godot comprueba `FieldItemService.teach` real, especies compatibles e incompatibles, rechazo de falta de stock o propietario, consumo único, PP, repetición, identidad y SaveV2.
5. Sin cambios de producción ni relajación de aserciones; no confundir fixture añadido con integración global ni pruebas visuales.

## CI real y regresiones

- Bloques 01–08 certificados por [Actions #41733471535](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41733471535), SHA `e455c80adb322fff21866e914e2538f6586e8706`, `completed/success`; Python `CAMP005_W05_PY PASS blocks=8 checks=464` y Godot `CAMP005_W05_GODOT PASS blocks=8 checks=1736`, gates PASS.
- CI bloque 09 [Actions #41737890652](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41737890652), SHA de progreso `0a69eaf51999f7a26cd69e34cf52f43f7a2ff5ff`, inicialmente `pending`. CI intermedia del fixture #41737864787 puede ser `cancelled` por concurrencia, no por defecto funcional.
- Para certificar 54 MT, exigir run de progreso `completed/success` y recibos `CAMP005_W05_PY PASS blocks=9 checks=N`, `CAMP005_GATE_PY_PASS worker=W05 blocks=9 checks=N`, `CAMP005_W05_GODOT PASS blocks=9 checks=N`, `CAMP005_GATE_GODOT_PASS worker=W05 blocks=9 checks=N`, N positivo y logs reales.
- Las regresiones de CAMP004 (60 MT) y CAMP003 (60 MT) pasaron en el hito 05 [Actions #41721306449](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41721306449), Python 580/Godot 2166 comprobaciones por campaña. Deben repetirse obligatoriamente en el siguiente hito 10 o si se cambia producción; no atribuirlas a bloque 09 si el workflow no las ejecutó.

## Continuidad y límites

- Siguiente `p`: comprobar primero CI bloque 09; con PASS ejecutar **solo último bloque 10** `tm196;tm197;tm198;tm199;tm200;tm201` y comprobar también regresiones CAMP004/CAMP003. Si la CI falla, diagnosticar logs y reparar autónomamente según V5 solo W05, sin reducir pruebas ni modificar catálogos.
- Prohibido tocar `main`, V28, PR118, rama árbitra, otras ramas, datasets/learnsets canónicos, políticas, las 19 MT históricas inactivas, partidas reales, workflows o realizar merge. Godot headless no certifica UI/GPU.
- Al terminar el décimo bloque y su CI, publicar informe consolidado y declarar `CAMPAÑA_005_FINALIZADA` y STOP.

**ITER_09 ENTREGADA; CI FUNCIONAL PENDIENTE AL REDACTAR.**
