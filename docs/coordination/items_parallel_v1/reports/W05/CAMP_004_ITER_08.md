# IA5/W05 — CAMPAÑA_004 · ITER_08/10 — MT Scarlet/Violet

**Estado al publicar: EN_CI_AUTOMATICA.** No declarar PASS de las seis MT del bloque 08 hasta confirmar GitHub Actions y sus logs.

## Autorización y selección
- Rama exclusiva: `codex/calvo-items-20261103-w05-camp004`.
- Fuente IA6: `CAMPAIGN_004_W05_GATE.md`, `CAMPAIGN_004_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_004_W05.md`, `AUTONOMOUS_REPAIR_V5.md`.
- Fila `08,W05,MACHINE` cotejada contra `modules/inventory/item_connections_v1.json` (`scarlet-violet`):

| ID | Movimiento SV |
| --- | --- |
| `tm124` | `ice_spinner` |
| `tm125` | `flamethrower` |
| `tm126` | `thunderbolt` |
| `tm127` | `play_rough` |
| `tm128` | `amnesia` |
| `tm129` | `calm_mind` |

## Publicaciones
1. `tests/fixtures/parallel_items/w05_campaign_004.json`: añadido únicamente bloque 08 con seis pares; conservados bloques 01–07, commit `dae8a132e33574e87d04676154648a7229fc73ac`.
2. `docs/coordination/items_parallel_v1/reports/W05/CAMP_004_PROGRESO.csv`: una única fila nueva 08, `EN_CI_AUTOMATICA`, commit `2d62f9efda8f47c1c434fe5a9b5b8dbd166b9f43`, disparador de CI.
3. Runners `tests/tools/test_parallel_items_w05_campaign_004.py` y `tests/gameplay/parallel_items_w05_campaign_004.gd` no modificados. Contratos existentes de learnsets reales SV, PP, propiedad, disponibilidad, consumo único, incompatibilidad, repetición y SaveV2 con `FieldItemService.teach`; no se tocaron producción ni aserciones.
4. Cotejo estático post-commit: **8 bloques, 8 filas, 48 MT únicas**, seis por bloque, sin discrepancias entre cola IA6, fixture, progreso y perfil SV. Este control no equivale a una prueba funcional de las seis MT recién añadidas.

## Recibos CI
- Bloques 01–07 verificados por [Actions #41579505939](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41579505939) SHA `c6d5c738d2a3a68ced8d3388da370f5abcfc37e4`, `completed/success`. Logs `CAMP004_W05_PY PASS blocks=7 checks=406`, `CAMP004_W05_GODOT PASS blocks=7 checks=1521`, ambos gates PASS.
- Mismo run: CAMP003 Python `PASS blocks=10 checks=580` / Godot `PASS blocks=10 checks=2166` sobre las 60 MT anteriores, y CAMP002 11 tests `OK`.
- Nuevo bloque 08: [Actions #41584156568](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41584156568), SHA exacto `2d62f9efda8f47c1c434fe5a9b5b8dbd166b9f43`, observado inicialmente como `pending`. El run de fixture #41584143411 puede cancelarse por `concurrency.cancel-in-progress` al arrancar el último run; cancelación no es fallo funcional.
- Para certificar 48 MT: run de progreso `completed/success` y recibos `CAMP004_W05_PY PASS blocks=8 checks=N`, `CAMP004_W05_GODOT PASS blocks=8 checks=N`, ambos gates, regresiones CAMP003 y CAMP002, N positivo. No inventar PASS.

## Continuación V5 y restricciones
- **Siguiente `p`:** revisar CI del bloque 08 y ejecutar **únicamente bloque 09** `tm130;tm131;tm132;tm133;tm134;tm135` si procede. Con CI ejecutándose se autoriza como máximo un bloque independiente sin certificar PASS; con fallo, diagnosticar logs y reparar dentro de la especialidad W05 según V5, sin rebajar pruebas ni tocar código ajeno.
- Escalar conflictos de función compartida, arquitectura o reglas globales y denegación real de permisos a IA6. No editar `main`, V28, PR118, árbitra, otras ramas, catálogos, políticas, 19 máquinas legacy, guardados reales ni workflows; sin merge ni validación UI/GPU por headless.
- Al 10/10 comunicar `CAMPAÑA_004_FINALIZADA` y STOP.

**ITER_08/10 entregada. 48 MT en suite acumulativa; CI del último bloque pendiente al redactar.**
