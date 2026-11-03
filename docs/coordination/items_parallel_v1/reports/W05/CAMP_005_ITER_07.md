> **CI DEFINITIVA VERIFICADA — BLOQUE 07/10 (2026-11-03).** [GitHub Actions #41727197381](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41727197381), SHA funcional `fba3e31a39ed4416745541742004dd16ca5d51fc`, job `126235426472`, `completed/success`. Recibos extraídos de logs reales: `CAMP005_W05_MANIFEST_PASS reserved=10 completed=7 ids=60 kind=NEW_IDS`; `CAMP005_W05_PY PASS blocks=7 checks=406`; `CAMP005_GATE_PY_PASS worker=W05 blocks=7 checks=406`; `CAMP005_W05_GODOT PASS blocks=7 checks=1521`; `CAMP005_GATE_GODOT_PASS worker=W05 blocks=7 checks=1521`. **42/42 MT de CAMP005 verificadas funcionalmente por Python/Godot headless.** Regresiones de CAMP004 y CAMP003 no se ejecutaron otra vez en este bloque, ya verificadas en el hito 05; se repetirán en el hito 10 y si hay parche propio de producción. Este veredicto prevalece sobre las menciones históricas inferiores a CI pendiente. Sin modificaciones de producción ni relajación de aserciones; CI headless no acredita GPU/UI.

# IA5/W05 — CAMPAÑA_005 · ITER_07/10

**Estado al publicar: EN_CI_AUTOMATICA.** No certificar la enseñanza de las seis nuevas MT sin CI funcional Python/Godot en el SHA correcto.

## Autorización y asignación

- Rama exclusiva `codex/calvo-items-20261103-w05-camp005`. Autoridad de IA6: `CAMPAIGN_005_W05_GATE.md`, `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W05.md`, `AUTONOMOUS_REPAIR_V5.md` en la rama árbitra.
- Bloque 07 autorizado `tm178;tm179;tm180;tm181;tm182;tm183` y movimientos SV verificados en `modules/inventory/item_connections_v1.json`:

| MT | Movimiento `scarlet-violet` |
| --- | --- |
| `tm178` | `gravity` |
| `tm179` | `smack_down` |
| `tm180` | `gyro_ball` |
| `tm181` | `knock_off` |
| `tm182` | `bug_bite` |
| `tm183` | `super_fang` |

## Cambios publicados y contratos

1. `tests/fixtures/parallel_items/w05_campaign_005.json`: agregado únicamente bloque 07 con sus seis pares, preservados 01–06; commit `e68be042d3e4a5d6bd71686852658e05068683d3`.
2. `docs/coordination/items_parallel_v1/reports/W05/CAMP_005_PROGRESO.csv`: una nueva fila `07` `EN_CI_AUTOMATICA`, commit `fba3e31a39ed4416745541742004dd16ca5d51fc`, dispara CI.
3. Verificación estática de todos los datos tras publicar: exactamente **7 bloques, 7 filas CSV, 42 IDs únicos**, seis por bloque y asignaciones/orden/movimientos idénticos a la cola de IA6 y al perfil SV, sin divergencias.
4. Los runners acumulativos de W05 CAMP005 Python y Godot no se modificaron. Python: perfil SV, política, metadatos y PP, especies elegibles por learnset máquina SV. Godot: servicio `FieldItemService.teach` real con compatible e incompatible, rechazos sin stock/propietario, consumo único, PP, identidad, movimiento ya conocido y persistencia SaveV2. La verificación estática no sustituye a esas pruebas.

## CI y regresiones

- Bloques 01–06 certificados: [Actions #41722664035](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41722664035), SHA `bbb4e1f3ec3da2b6473bc0dc5d572680e67f1463`, `completed/success`. `CAMP005_W05_PY PASS blocks=6 checks=348`, `CAMP005_W05_GODOT PASS blocks=6 checks=1306`, ambos gates PASS.
- Primer hito 05 de regresión aprobado: [Actions #41721306449](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41721306449), CAMP004 (60 MT) Python 580/Godot 2166 y CAMP003 (60 MT) Python 580/Godot 2166, todos PASS.
- Bloque 07: [Actions #41727197381](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41727197381), SHA de progreso `fba3e31a39ed4416745541742004dd16ca5d51fc`, primero `pending`. El run intermedio del fixture #41727170257 puede cancelarse por concurrencia; cancelación de ese run sustituido no prueba fallo.
- Para certificar 42 MT: `completed/success`, recibos `CAMP005_W05_PY PASS blocks=7 checks=N`, `CAMP005_GATE_PY_PASS worker=W05 blocks=7 checks=N`, `CAMP005_W05_GODOT PASS blocks=7 checks=N` y `CAMP005_GATE_GODOT_PASS worker=W05 blocks=7 checks=N`, con N positivo.
- Las regresiones CAMP004/CAMP003 se repetirán en el hito 10 y ante un cambio de producción W05; en 07 sin cambios de producción el workflow no las ejecuta.

## Continuidad y límites

- Próxima `p`: revisar la CI del bloque 07 y ejecutar **exclusivamente bloque 08** `tm184;tm185;tm186;tm187;tm188;tm189`. Si la CI falla, diagnosticar logs y reparar autónomamente dentro de W05 bajo V5 sin relajar aserciones. Escalar conflictos compartidos o ACL realmente denegada a IA6.
- Prohibido tocar `main`, V28, PR118, rama árbitra, otras ramas, catálogo/learnsets canónicos, políticas, 19 MT históricas inactivas, partidas, workflows o realizar merge. Godot headless no verifica UI/GPU.
- Al 10/10 declarar `CAMPAÑA_005_FINALIZADA` y STOP.

**Bloque 07/10 entregado; certificación de la nueva CI pendiente en el momento de publicación.**
