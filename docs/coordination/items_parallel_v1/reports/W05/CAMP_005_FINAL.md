# IA5/W05 — CAMPAÑA_005 · INFORME CONSOLIDADO 10/10

**ESTADO DE ENTREGA:** 10 bloques entregados, **60 MT nuevas `tm142`–`tm201`** en versión Scarlet/Violet. **CI FUNCIONAL FINAL PENDIENTE** en la fecha de creación: no afirmar `CAMPAÑA_005_FINALIZADA` sin leer recibos de las tres campañas.

## Mandato y alcance

- IA5/W05 — MT y libros, rama exclusiva `codex/calvo-items-20261103-w05-camp005`.
- Autoridad IA6 de la rama árbitra: `CAMPAIGN_005_W05_GATE.md`, `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W05.md`, protocolo `AUTONOMOUS_REPAIR_V5.md`.
- 10 microbloques de seis MT cada uno: `01 tm142–tm147`, `02 tm148–tm153`, `03 tm154–tm159`, `04 tm160–tm165`, `05 tm166–tm171`, `06 tm172–tm177`, `07 tm178–tm183`, `08 tm184–tm189`, `09 tm190–tm195`, `10 tm196–tm201`.
- CAMP004 (60 MT `tm82`–`tm141`) y CAMP003 (60 MT anteriores) preservadas y usadas como **regresión**, no contadas como nuevos objetos. Las 19 MT históricas inactivas permanecen intactas.

## Bloque 10 autorizado

| MT | Movimiento canónico SV |
| --- | --- |
| `tm196` | `flip_turn` |
| `tm197` | `dual_wingbeat` |
| `tm198` | `poltergeist` |
| `tm199` | `lash_out` |
| `tm200` | `scale_shot` |
| `tm201` | `misty_explosion` |

## Archivos y contratos

- Fixture `tests/fixtures/parallel_items/w05_campaign_005.json`, último incremento 10/10 commit `d351a80cff579fc951e534580ab7fa26114b4868`.
- Progreso `docs/coordination/items_parallel_v1/reports/W05/CAMP_005_PROGRESO.csv`, 10 filas, última fila commit `b886c10756ad843d5f92834f29a42d31e63cf262`, que desencadena CI. La etiqueta `EN_CI_AUTOMATICA` es histórica; no modificar solo por registrar CI PASS y relanzar el workflow.
- Informes individuales `reports/W05/CAMP_005_ITER_01.md` … `CAMP_005_ITER_10.md` y `reports/W05/CONTINUIDAD.md`.
- Control estático después de registrar último bloque: 10 bloques x 6 casos, 10 filas de progreso, 60 IDs distintos, correspondencia exacta con 10 filas de cola IA6 y con `modules/inventory/item_connections_v1.json` (`scarlet-violet`); cero divergencias/duplicados.
- Runners `tests/tools/test_parallel_items_w05_campaign_005.py` y `tests/gameplay/parallel_items_w05_campaign_005.gd` creados en bloque 01 a partir de los contratos aprobados CAMP004, sin modificarse después. Python contrasta metadatos del ataque, PP, política y al menos un learnset real de MT/SV. Godot 4.7 headless llama a `FieldItemService.teach` con especie compatible/incompatible, dueño, stock, consumo de una MT, PP, rechazo de duplicado y SaveV2 (persistencia de especie/ataque/inventario).
- Sin cambios de producción, APIs compartidas, catálogos, políticas, learnsets, 19 MT históricas, partidas reales ni workflows. No se han bajado aserciones.

## CI y regresiones

- **Bloques 01–09 PASS real:** [Actions #41737890652](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41737890652), SHA `0a69eaf51999f7a26cd69e34cf52f43f7a2ff5ff`, `completed/success`. Python `CAMP005_W05_PY PASS blocks=9 checks=522`, Godot `CAMP005_W05_GODOT PASS blocks=9 checks=1951`, ambos gates PASS.
- **Hito 05 PASS con regresiones:** [Actions #41721306449](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41721306449), CAMP005 30 MT Python 290 / Godot 1091 PASS, CAMP004 60 MT Python 580 / Godot 2166 PASS, CAMP003 60 MT Python 580 / Godot 2166 PASS.
- **Run final:** [Actions #41742499805](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41742499805), SHA de progreso `b886c10756ad843d5f92834f29a42d31e63cf262`, inicialmente `pending`. Una ejecución intermedia del fixture #41742478253 puede cancelarse por concurrencia y ello no representa un fallo funcional.
- **Puerta obligatoria para certificar campaña:** run final `completed/success`, recibos `CAMP005_W05_PY PASS blocks=10`, `CAMP005_W05_GODOT PASS blocks=10`, gates respectivos y **regresiones completas CAMP004 Python/Godot blocks=10, CAMP003 Python/Godot blocks=10 en ese mismo run**, con N checks positivo. Si un recibo falla, diagnosticar y corregir bajo V5 antes de cierre. El resultado funcional no debe inferirse de ausencia de errores en datos estáticos.

## Handoff a IA6 y STOP

- IA6 debe auditar el diff y coordinar integración según gates: pruebas en rama W05 **no equivalen a merge ni a aceptación en producción global**. Godot headless no valida UI ni GPU; esas revisiones quedan pendientes.
- Prohibido modificar `main`, V28, PR118, rama árbitra, otras trabajadoras, catálogo/learnsets, políticas, 19 máquinas legacy, guardados reales, workflows. No hubo merge.
- Tras CI verde final, certificar el cierre en la parte superior de este informe y en continuidad, comunicar **`CAMPAÑA_005_FINALIZADA`** y **STOP**. No existe microbloque 11 autorizado.

**ENTREGA 10/10 PUBLICADA · CERTIFICACIÓN FINAL EN CURSO AL CREAR EL INFORME.**
