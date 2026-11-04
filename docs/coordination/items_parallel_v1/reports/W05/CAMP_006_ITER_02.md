# W05 — CAMPAÑA_006 · BLOQUE 02/10

**Estado:** PUBLICADO_PENDIENTE_CI. **Fecha:** 2026-11-04. **Rama:** `codex/calvo-items-20261104-w05-camp006`.

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

## CI — evidencia pendiente

La publicación de la nueva fila de progreso activa `.github/workflows/parallel-camp006-w05-autoci.yml`. **No consta PASS en el momento de este commit.** La aceptación exige `completed/success` y recibos `CAMP006_W05_PY PASS blocks=2 checks=N`, `CAMP006_W05_GODOT PASS blocks=2 checks=N` y ambos `CAMP006_GATE_*_PASS` con N > 0, vinculados al SHA que contiene los dos bloques. Los recibos no se inventan; si falla, diagnosticar y reparar en W05.

**Siguiente bloque solo tras siguiente `p` y control de CI:** 03 `tm212..tm216`. Sin merge, sin `main`, V28, otras trabajadoras ni 19 MT históricas.
