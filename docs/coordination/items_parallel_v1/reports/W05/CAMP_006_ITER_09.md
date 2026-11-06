# IA5/W05 — CAMPAÑA_006 · BLOQUE 09/10

**Fecha:** 2026-11-06. **Rama exclusiva:** `codex/calvo-items-20261104-w05-camp006`. **Estado inicial:** EN_CI_AUTOMATICA, pendiente de pruebas GitHub Actions. **Commit del fixture:** `ea2b4a0788e7b35ecc0c6949abf773a23f077c38`.

## Reserva de IA6 y mapeo Scarlet/Violet

Los cinco IDs proceden exclusivamente de la fila 09 de `CAMPAIGN_006_W05_QUEUE_APPROVED.csv` de la rama árbitra. Los `move_id` se han cotejado con la versión activa `scarlet-violet` de `modules/inventory/item_connections_v1.json`:

| MT | Movimiento SV |
| --- | --- |
| `tm14` | `acrobatics` |
| `tm15` | `struggle_bug` |
| `tm17` | `confuse_ray` |
| `tm19` | `disarming_voice` |
| `tm20` | `trailblaze` |

En ediciones históricas esta numeración tiene otros movimientos; el bloque no los reactiva ni modifica datos canónicos.

## Evidencia funcional programada

- El fixture `tests/fixtures/parallel_items/w05_campaign_006.json` pasa a **9 bloques y 45 MT**, conservando los 40 registros ya certificados en 01–08 sin cambios ni duplicados.
- Runner Python `tests/tools/test_parallel_items_w05_campaign_006.py --ci`: orden de la reserva, catálogo y mapeo SV, política, datos de movimiento, PP y especie/learnset compatible.
- Runner Godot `tests/gameplay/parallel_items_w05_campaign_006.gd`: enseñanza efectiva con `FieldItemService.teach` a especie real compatible, PP, gasto exactamente una MT, propiedad/identidad, rechazos sin mutación por stock ausente, portador ajeno, incompatibilidad o movimiento conocido, más persistencia SaveV2.
- Las pruebas acumulativas no se han reescrito ni relajado. Sin cambios en motor, catálogos, learnsets, políticas, saves reales, workflows, `main`, V28, ramas de otras trabajadoras o 19 máquinas históricas fuera de reserva.
- Regresiones completas CAMP003/004/005 certificadas en hito 05 [#41785064826](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41785064826). Siguiente hito obligatorio: bloque 10, con las seis regresiones completas.

## Criterio de cierre

El workflow `.github/workflows/parallel-camp006-w05-autoci.yml` debe terminar `completed/success` sobre el SHA que incluye fixture y CSV. Verificar en logs `CAMP006_W05_PY PASS blocks=9 checks=N`, `CAMP006_W05_GODOT PASS blocks=9 checks=N`, `CAMP006_GATE_PY_PASS worker=W05 blocks=9 checks=N` y `CAMP006_GATE_GODOT_PASS worker=W05 blocks=9 checks=N` con N positivo. No atribuir PASS sin run y recibos exactos.

**Próxima `p` tras certificar CI:** último bloque 10 `tm31;tm36;tm44;tm77` y regresiones completas de CAMP003/004/005. No hacer merge.
