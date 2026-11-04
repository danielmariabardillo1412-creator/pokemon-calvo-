# W05 — CAMPAÑA_006 · BLOQUE 02/10

**Estado:** BLOQUE_02_CI_PASS_VERIFICADO. **Fecha:** 2026-11-04. **Rama:** `codex/calvo-items-20261104-w05-camp006`.

## Alcance autorizado y mapeo canónico

IA6 reserva exclusivamente `tm207;tm208;tm209;tm210;tm211` para el segundo microbloque, cinco MT de `scarlet-violet`. Cotejado con `modules/inventory/item_connections_v1.json`, sin modificar catálogo, learnsets ni política.

| MT | Movimiento canónico |
| --- | --- |
| `tm207` | `temper_flare` |
| `tm208` | `whirlpool` |
| `tm209` | `muddy_water` |
| `tm210` | `supercell_slam` |
| `tm211` | `electroweb` |

## Implementación y alcance de pruebas

- Fixture acumulativo `tests/fixtures/parallel_items/w05_campaign_006.json`: dos bloques, **10 IDs únicos**. Commit de pruebas `5862ac6efbb9560efdcdea1d5e3606c65c6c1d6b`.
- Python `tests/tools/test_parallel_items_w05_campaign_006.py --ci`: cola, fuente SV, learnset, PP, políticas, ausencia de duplicados, controles de identidad de reserva.
- Godot `tests/gameplay/parallel_items_w05_campaign_006.gd`: cada MT se enseña con `FieldItemService.teach` a especie realmente compatible; comprobar PP, exactitud del movimiento, consumo de una unidad, propiedad, identidad, stock y SaveV2, más rechazos sin mutación por incompatibilidad, falta de stock y enseñanza repetida.
- Se preservan los cinco casos del bloque 01; no se modifican ejecutores, producción, fuentes ni otras ramas. Regresiones CAMP005/004/003 se ejecutaron en hito 01 y volverán en 05/10 según gate.

## CI funcional — PASS verificado

[GitHub Actions #41767616709](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41767616709), `completed/success`, SHA de pruebas y progreso `1ea865c48184b723874868322f467a3dc263c6ab`, job `126369600349`. Recibos **extraídos de logs reales del mismo run**:

- `CAMP006_W05_MANIFEST_PASS reserved=10 completed=2 ids=49 kind=NEW_IDS`
- `CAMP006_W05_PY PASS blocks=2 checks=98`
- `CAMP006_GATE_PY_PASS worker=W05 blocks=2 checks=98`
- `CAMP006_W05_GODOT PASS blocks=2 checks=376`
- `CAMP006_GATE_GODOT_PASS worker=W05 blocks=2 checks=376`

**Regresiones CAMP005/004/003 en este run:** step `skipped`, conforme a hitos obligatorios 01/05/10 y detección de parches `modules/`; se ejecutaron y aprobaron en el bloque 01. La CI del bloque 02 acredita los contratos acumulativos del bloque 01+02 en motor headless, no UI/GPU ni merge global. La fila CSV conserva el estado histórico `EN_CI_AUTOMATICA` de su publicación, no el veredicto de la CI.

**Siguiente bloque solo tras siguiente `p` y control de CI:** 03 `tm212..tm216`. Sin merge, sin `main`, V28, otras trabajadoras ni 19 MT históricas.
