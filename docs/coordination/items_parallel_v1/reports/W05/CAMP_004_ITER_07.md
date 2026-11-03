# IA5/W05 — CAMP004 · ITER_07/10

**Estado de entrega: EN_CI_AUTOMATICA; aún no confirmado PASS del bloque 07.**
Rama propia: `codex/calvo-items-20261103-w05-camp004`. Autorización: `CAMPAIGN_004_W05_GATE.md`, `CAMPAIGN_004_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_004_W05.md` y reparación V5 de IA6.

## IDs y movimientos Scarlet/Violet autorizados

| ID | Movimiento SV |
| --- | --- |
| tm118 | heat_wave |
| tm119 | energy_ball |
| tm120 | psychic |
| tm121 | heavy_slam |
| tm122 | encore |
| tm123 | surf |

Perfil `modules/inventory/item_connections_v1.json` cotejado con la fila 07 de la cola IA6.

## Cambios y validación

- Fixture `tests/fixtures/parallel_items/w05_campaign_004.json`: añadido solo bloque 07, commit `42020d197ea704486fb2415c43989793ca0c1deb`.
- Progreso `reports/W05/CAMP_004_PROGRESO.csv`: nueva fila 07 `EN_CI_AUTOMATICA`, commit `c6d5c738d2a3a68ced8d3388da370f5abcfc37e4`.
- Cotejo estático: siete bloques, siete filas de progreso, 42 IDs únicos y todas las parejas de movimientos coincidentes con el perfil SV y la cola IA6. Sin discrepancias.
- Runners Python/Godot CAMP004 no modificados. Estos comprueban learnset real SV, PP, positivos y negativos de stock, propietario y compatibilidad, consumo y SaveV2 con `FieldItemService.teach`. No se modificó producción ni se rebajaron comprobaciones.

## Evidencia CI

**Bloques 01–06 certificados:** [run #41579048410](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41579048410), `completed/success`, SHA `e3ef241634ad013d20907272ca319cfdd51fba6c`, Python `CAMP004_W05_PY PASS blocks=6 checks=348` y Godot `CAMP004_W05_GODOT PASS blocks=6 checks=1306`, ambos gates PASS. Regresiones CAMP003 60 MT: Python 580 checks y Godot 2166 checks; CAMP002: 11 tests OK.

**Bloque 07 pendiente al redactar:** [run #41579505939](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41579505939), SHA `c6d5c738d2a3a68ced8d3388da370f5abcfc37e4`, primero `pending`. El run sustituido #41579488183 puede cancelarse por concurrencia. PASS requiere run `completed/success`, `CAMP004_W05_PY PASS blocks=7`, `CAMP004_W05_GODOT PASS blocks=7`, gates y regresiones anteriores.

## Continuación
Siguiente `p`: comprobar CI del bloque 07; ejecutar exclusivamente bloque 08 `tm124;tm125;tm126;tm127;tm128;tm129` si procede. Fallos locales: investigar/reparar bajo V5 con regresiones, sin alterar datos canónicos ni otras familias. Escalar únicamente conflicto de arquitectura/función compartida, diseño o permisos. No tocar `main`, V28, árbitra, otras ramas, PR118 ni legacy. Detenerse al 10/10.
