# IA5/W05 — CAMPAÑA_006 · BLOQUE 10/10 · HITO FINAL

**Fecha:** 2026-11-07. **Rama:** `codex/calvo-items-20261104-w05-camp006`. **Estado inicial:** PUBLICADO_PENDIENTE_CI; el cierre exige recibos reales. **Commit del fixture:** `c929538eaff755c511273b9e82f955f8301fa35a`.

## Reserva final IA6 (únicamente 4 MT)

La fila 10 de `CAMPAIGN_006_W05_QUEUE_APPROVED.csv` de la rama árbitra especifica cuatro IDs activos; el mapeo se ha cotejado con el perfil `scarlet-violet` de `modules/inventory/item_connections_v1.json`:

| MT | Movimiento canónico en Scarlet/Violet |
|---|---|
| `tm31` | `metal_claw` |
| `tm36` | `rock_tomb` |
| `tm44` | `dragon_tail` |
| `tm77` | `waterfall` |

No utilizar las asociaciones históricas de estas MT. Fixture `tests/fixtures/parallel_items/w05_campaign_006.json` acumulativo: **10 bloques / 49 MT distintas**, 45 casos previos intactos, cero alteraciones al catálogo, learnsets, política, motor ni SaveV2.

## Puerta funcional de cierre

- Runner Python CAMP006 para toda la cola: IDs únicos y reservados, versión activa, metadatos del movimiento, PP, política, especie SV compatible y learnset real.
- Runner Godot CAMP006 para los 49 casos: `FieldItemService.teach` sobre especies reales compatibles, identidad y propiedad, PP, gasto de una unidad, stock, negativa por incompatibilidad/ausencia de stock/movimiento conocido y SaveV2. Conservar toda la cobertura de 01–09.
- **Obligatorio en este hito final:** ejecutar regresiones completas CAMP005, CAMP004 y CAMP003 **tanto Python como Godot**. Un PASS aislado de CAMP006 no permite cerrar 10/10.
- No confundir PASS headless con validación visual/GPU, integración de ramas o puesta en producción.

## Evidencia exigida

En el mismo run de Actions del commit de publicación, comprobar `completed/success`, `CAMP006_W05_MANIFEST_PASS reserved=10 completed=10 ids=49 kind=NEW_IDS`, `CAMP006_W05_PY PASS blocks=10 checks=N`, `CAMP006_GATE_PY_PASS worker=W05 blocks=10 checks=N`, `CAMP006_W05_GODOT PASS blocks=10 checks=N`, `CAMP006_GATE_GODOT_PASS worker=W05 blocks=10 checks=N`, todos N positivos. Además: `CAMP005_W05_PY/GODOT PASS blocks=10`, `CAMP004_W05_PY/GODOT PASS blocks=10` y `CAMP003_W05_PY/GODOT PASS blocks=10`, verificados literalmente en logs.

Al superar todo lo anterior: anotar el run, SHA, job, métricas y estado `CAMPAÑA_006_FINALIZADA` en este informe y en continuidad; **STOP**, no iniciar campaña nueva ni modificar otras ramas. El CSV `EN_CI_AUTOMATICA` es constancia histórica del momento de publicación; no actualizar solo para cambiar la etiqueta.
