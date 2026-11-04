# IA5/W05 — CAMPAÑA_006 · BLOQUE 04/10

**Estado:** PUBLICADO_PENDIENTE_CI (no se presupone PASS). **Fecha:** 2026-11-04. **Rama exclusiva:** `codex/calvo-items-20261104-w05-camp006`. **Commit de fixture:** `26f5dff704ff4e15a1bb2b339ea863719e9ed038`.

## MT reservadas y mapeo canónico Scarlet/Violet

Cola oficial de IA6 comprobada en `codex/calvo-items-20261101-arbitro`, fila `04`, perfil de movimiento `modules/inventory/item_connections_v1.json`. No se modifican catálogos ni learnsets.

| MT | Movimiento canónico |
| --- | --- |
| `tm217` | `future_sight` |
| `tm218` | `expanding_force` |
| `tm219` | `skitter_smack` |
| `tm220` | `meteor_beam` |
| `tm221` | `throat_chop` |

## Cobertura programada

- Fixture `tests/fixtures/parallel_items/w05_campaign_006.json`: 4 bloques acumulativos, **20 MT**, preservando exactamente las 15 MT de los bloques 01, 02 y 03.
- Python `tests/tools/test_parallel_items_w05_campaign_006.py --ci`: reserva IA6, mapeo SV, learnset compatible, política, PP, metadatos y no duplicados.
- Godot `tests/gameplay/parallel_items_w05_campaign_006.gd`: para cada registro del fixture, ejecución de `FieldItemService.teach` con especie compatible real, comprobación de PP, consumo de una unidad, propiedad e identidad, falta de stock, incompatibilidad, rechazo sin mutación, movimiento repetido, SaveV2 y restauración de inventario.
- Los ejecutores no se han reescrito ni relajado. No hay cambio de producción, APIs compartidas, políticas, catálogo, archivos de IA6/otras trabajadoras ni partidas reales.
- Las regresiones CAMP005/004/003 completas se ejecutan en hitos 01/05/10 o parches de producción; los tres bloques previos mantienen sus pruebas acumulativas.

## CI pendiente

La fila 04 de `CAMP_006_PROGRESO.csv` dispara el workflow `.github/workflows/parallel-camp006-w05-autoci.yml`. Para declarar PASS es obligatorio verificar `completed/success` sobre el SHA que incluye CSV+fixture, `CAMP006_W05_PY PASS blocks=4 checks=N`, `CAMP006_GATE_PY_PASS worker=W05 blocks=4 checks=N`, `CAMP006_W05_GODOT PASS blocks=4 checks=N`, `CAMP006_GATE_GODOT_PASS worker=W05 blocks=4 checks=N`, con N positivo. El PASS previo de bloque 03 no certifica el bloque 04.

**Próxima `p` tras verificar resultado de CI:** bloque 05 `tm222;tm223;tm224;tm225;tm226`. En ese hito regresiones completas CAMP005/004/003. Sin merges.
