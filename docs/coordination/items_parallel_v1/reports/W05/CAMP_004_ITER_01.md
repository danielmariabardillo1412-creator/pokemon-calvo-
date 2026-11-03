# IA5/W05 — CAMPAÑA_004 · ITER_01/10 — MT Scarlet/Violet

**Estado inicial: EN_CI_AUTOMATICA.** El arranque anterior en verde, con cero bloques, **no** acredita enseñanza funcional.

## Autorización y asignación
- Rama exclusiva `codex/calvo-items-20261103-w05-camp004`; gate IA6 `CAMPAIGN_004_W05_GATE.md`, cola `CAMPAIGN_004_W05_QUEUE_APPROVED.csv`, encargo `campaigns/CAMP_004_W05.md`, protocolo `AUTONOMOUS_REPAIR_V5.md`.
- La orden inicial activa exclusivamente **bloque 01** y seis MT de `scarlet-violet`, sin repetir CAMP003 ni alterar la familia W05 fuera de su reserva.

| MT | Movimiento canónico SV |
| --- | --- |
| `tm82` | `thunder_wave` |
| `tm83` | `poison_jab` |
| `tm84` | `stomping_tantrum` |
| `tm85` | `rest` |
| `tm86` | `rock_slide` |
| `tm87` | `taunt` |

Los seis pares se leyeron y cotejaron con la fila de la cola IA6 y `modules/inventory/item_connections_v1.json[machine_rows][id][scarlet-violet]` del árbol de CAMP004.

## Cambios publicados
1. Fixture nuevo `tests/fixtures/parallel_items/w05_campaign_004.json`: se añadió únicamente `block: 01` con los seis pares exactos. Commit `b467ae2f219627c5e227ed830ea976435bd432a5`.
2. CSV nuevo `docs/coordination/items_parallel_v1/reports/W05/CAMP_004_PROGRESO.csv`: se añadió una sola fila `01`, estado `EN_CI_AUTOMATICA`, commit de activación `7d1b5b65da4135dc197a198ab08aa78e1646c84f`.
3. La suite **ya preparada en la nueva rama por IA6** `tests/tools/test_parallel_items_w05_campaign_004.py` y `tests/gameplay/parallel_items_w05_campaign_004.gd` recorre dinámicamente el fixture. No fue necesario duplicar CAMP003 ni reescribir `FieldItemService.teach` sin un error demostrado.
4. Inspección documental de GitHub después de los commits: 1 bloque / 6 IDs sin duplicados, movimiento SV idéntico a la cola aprobada y perfil, progreso y fixture coherentes. **Comprobación estática, no certificación funcional.**

## Pruebas y puertas
- Nueva CI funcional de este bloque: [GitHub Actions #41571216304](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41571216304), SHA `7d1b5b65da4135dc197a198ab08aa78e1646c84f`, inicialmente `in_progress`.
- Los recibos exigidos para **PASS del bloque 01** son `CAMP004_W05_PY PASS blocks=1 checks=M` y `CAMP004_W05_GODOT PASS blocks=1 checks=M`, M positivo, más `CAMP004_GATE_PY_PASS` y `CAMP004_GATE_GODOT_PASS`, en el mismo SHA completado `success`.
- Según el workflow `.github/workflows/parallel-camp004-w05-autoci.yml`, **también debe pasar regresión de CAMP003, 60 MT anteriores** (Python `PASS blocks=10` y Godot `PASS blocks=10`) y regresión histórica CAMP002. No se eliminan aserciones ni datos negativos; el runner Godot CAMP004 exige especies con learnset real SV, propiedad, consumo de una unidad, stock, incompatibilidad, repetición, PP y SaveV2.
- El PASS de bootstrap [#41570901863](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41570901863) verificó **0/10** y no es evidencia de enseñanza. El run intermedio de fixture [#41571203410](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41571203410) fue cancelado por `concurrency.cancel-in-progress`, no por un defecto.

## Continuación
- La **próxima `p`** debe comprobar el último run del commit de progreso; si `success`, ejecutar **solamente bloque 02** `tm88;tm89;tm90;tm91;tm92;tm93`. `queued/in_progress` permite como máximo avanzar otro bloque independiente de pruebas y sin PASS; `failure` exige investigar y reparar primero siguiendo AUTONOMOUS_REPAIR_V5, sin reducir controles.
- V5 permite W05 modificar el perfil de máquinas y exclusivamente la función `teach` de su familia en su propia rama, si existe fallo reproducible, prueba rojo/verde y CI final; no inventar compatibilidad.
- Prohibido cambiar `main`, V28, PR118, árbitra, ramas ajenas, políticas, datos canónicos, 19 máquinas legacy, scripts compartidos de CI o partidas reales. No hacer merge. Visual/GPU no comprobadas por headless.

**BLOQUE 01/10 ENTREGADO. Nueva CI todavía pendiente de veredicto.**
