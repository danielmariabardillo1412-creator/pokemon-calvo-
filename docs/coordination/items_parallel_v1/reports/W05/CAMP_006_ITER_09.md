# IA5/W05 — CAMPAÑA_006 · BLOQUE 09/10

**Fecha:** 2026-11-06. **Rama exclusiva:** `codex/calvo-items-20261104-w05-camp006`. **Estado inicial de publicación:** EN_CI_AUTOMATICA. **Estado final:** CI PASS VERIFICADA. **Commit del fixture:** `ea2b4a0788e7b35ecc0c6949abf773a23f077c38`.

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

## Resultado CI bloque 09 — PASS verificado

[GitHub Actions #42252558475](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42252558475) ha concluido `completed/success` sobre el SHA de publicación `c982120718a12f117741301160491e41f191b2d1` (job `128011208264`). Recibos literales verificados en su log:

- `CAMP006_W05_MANIFEST_PASS reserved=10 completed=9 ids=49 kind=NEW_IDS`
- `CAMP006_W05_PY PASS blocks=9 checks=441`
- `CAMP006_GATE_PY_PASS worker=W05 blocks=9 checks=441`
- `CAMP006_W05_GODOT PASS blocks=9 checks=1636`
- `CAMP006_GATE_GODOT_PASS worker=W05 blocks=9 checks=1636`

Regresiones CAMP003/004/005: paso `skipped` en este run al ser bloque 09, sin parche de producción; en hito 05 habían pasado [#41785064826](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41785064826). En el bloque 10 (hito obligatorio) hay que exigir seis recibos completos CAMP003/004/005 en Python y Godot. El CSV conserva `EN_CI_AUTOMATICA` histórico del push y el PASS se certifica aquí. El éxito headless no equivale a UI/GPU ni integración en main.

**Próxima `p` tras certificar CI:** último bloque 10 `tm31;tm36;tm44;tm77` y regresiones completas de CAMP003/004/005. No hacer merge.
