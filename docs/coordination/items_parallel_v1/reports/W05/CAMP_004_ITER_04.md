# IA5/W05 — CAMPAÑA_004 · ITER_04/10 — MT Scarlet/Violet

**Estado al publicar: EN_CI_AUTOMATICA.** La coherencia documental de seis MT nuevas no acredita que su enseñanza funcione; exigir resultados de CI real.

## Autorización y datos verificados
- Rama exclusiva `codex/calvo-items-20261103-w05-camp004`. Autoridad IA6: `CAMPAIGN_004_W05_GATE.md`, `CAMPAIGN_004_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_004_W05.md` y reparación V5.
- Fila aprobada `04,W05,MACHINE` con seis máquinas nuevas y sus movimientos `scarlet-violet`, cotejados directamente contra `modules/inventory/item_connections_v1.json`:

| MT | Movimiento SV |
| --- | --- |
| `tm100` | `dragon_dance` |
| `tm101` | `power_gem` |
| `tm102` | `gunk_shot` |
| `tm103` | `substitute` |
| `tm104` | `iron_defense` |
| `tm105` | `x_scissor` |

## Trabajo publicado
1. Fixture `tests/fixtures/parallel_items/w05_campaign_004.json`: añadido solo bloque `04` con seis pares; bloques `01`–`03` íntegros. Commit `936bb0d60578b3edd7ca7fec091fc026651cb16c`.
2. CSV `docs/coordination/items_parallel_v1/reports/W05/CAMP_004_PROGRESO.csv`: única fila nueva `04`, estado `EN_CI_AUTOMATICA`. Commit `64d7f53bba17dbba7403721bb8c89831d47b1844`, disparador de la CI.
3. Scripts W05 `tests/tools/test_parallel_items_w05_campaign_004.py` y `tests/gameplay/parallel_items_w05_campaign_004.gd` **sin modificaciones**. Son acumulativos; comprueban learnsets reales SV, metadatos y PP, compatibilidad, propiedad, stock, consumo de una unidad, rechazos de incompatibles y repetidos, y SaveV2 con `FieldItemService.teach` real. No se inventaron especies ni se reprogramó la producción.
4. **Cotejo estático realizado:** fixture de cuatro bloques, 24 IDs diferentes, exactamente cuatro filas CSV y correspondencia sin discrepancias entre IDs, orden y movimientos de cola IA6 y catálogo SV. No sustituye a la CI funcional.

## Evidencias de CI
- **Bloques 01–03 con PASS real:** [Actions #41573686036](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41573686036), SHA `e902ea2e8df76d3273fcdd6020186fcedc2f8ef4`, `completed/success`. Logs: `CAMP004_W05_PY PASS blocks=3 checks=174`, `CAMP004_W05_GODOT PASS blocks=3 checks=661`, y los dos gates del manifiesto PASS.
- En esa misma ejecución se superaron regresiones CAMP003 (60 MT; Python `PASS blocks=10 checks=580`; Godot `PASS blocks=10 checks=2166`) y CAMPAÑA_002 (11 tests OK).
- **Bloque 04 aún no acreditado al publicar:** [Actions #41575917016](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41575917016), SHA de progreso `64d7f53bba17dbba7403721bb8c89831d47b1844`, observado `pending` inicialmente. El run del fixture [#41575899234](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41575899234) estaba `in_progress` y puede cancelarse por `concurrency.cancel-in-progress`; ello no implica fallo de tests.
- Exigir `completed/success` y logs `CAMP004_W05_PY PASS blocks=4 checks=N` / `CAMP004_W05_GODOT PASS blocks=4 checks=N`, ambos gates, regresiones anteriores y N positivo, sobre SHA del progreso, antes de acreditar 24/24 funcionalmente.

## Siguiente `p` y protocolos
- Verificar primero CI 04. Si `success`, ejecutar exclusivamente **bloque 05**: `tm106;tm107;tm108;tm109;tm110;tm111`. Si está en curso, como máximo un bloque independiente autorizado sin atribuir PASS. Si `failure`, investigar logs, reproducir y reparar autónomamente dentro de W05 bajo AUTONOMOUS_REPAIR_V5 sin suavizar pruebas. Conflicto de arquitectura/API compartida, diseño global o ACL real denegada requiere IA6.
- Mantener ramas `main`, V28, árbitra y otras W intactas, sin merge, sin modificar catálogos, política, 19 legacy ni partidas reales. No certificar UI/GPU por CI headless. Máximo 10 bloques, después `CAMPAÑA_004_FINALIZADA` y STOP.

**Bloque 04/10 entregado. 24 MT de CAMP004 en suite; CI del bloque 04 pendiente al redactar.**
