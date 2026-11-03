# IA5/W05 — CAMPAÑA_004 · ITER_10/10 · último bloque

**ESTADO A LA PUBLICACIÓN: 10/10 ENTREGADOS, CI FINAL PENDIENTE.** La verificación funcional se certificará únicamente con el run exacto del último cambio de fixture y CSV.

## Autorización y asignación
Rama exclusiva `codex/calvo-items-20261103-w05-camp004`; autoridad IA6 `CAMPAIGN_004_W05_GATE.md`, `CAMPAIGN_004_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_004_W05.md` y `AUTONOMOUS_REPAIR_V5.md`. Fila final `10,W05,MACHINE`:

| MT | Movimiento Scarlet/Violet |
| --- | --- |
| `tm136` | `electric_terrain` |
| `tm137` | `grassy_terrain` |
| `tm138` | `psychic_terrain` |
| `tm139` | `misty_terrain` |
| `tm140` | `nasty_plot` |
| `tm141` | `fire_blast` |

Movimientos cotejados contra la fila 10 de la cola IA6 y el perfil canónico `modules/inventory/item_connections_v1.json` (`scarlet-violet`), sin sustituir versiones ni inventar compatibilidad.

## Entrega GitHub
- Fixture `tests/fixtures/parallel_items/w05_campaign_004.json`: añadido únicamente bloque 10, conservados bloques 01–09, commit `6f1ae6afe42051e9e58b8a5a6e99e83bb343e701`.
- Progreso `docs/coordination/items_parallel_v1/reports/W05/CAMP_004_PROGRESO.csv`: añadida una única fila 10 con estado histórico `EN_CI_AUTOMATICA`, commit `5c9051ca2a0a186d31705372d2f0c350e2dd62db`. Este commit disparó la nueva CI.
- **Control estático posterior:** 10 bloques y 10 filas de progreso, **60 IDs únicos**, exactamente 6 por bloque, IDs y movimientos en idéntico orden entre fixture, progreso, cola aprobada IA6 y `machine_rows[*]["scarlet-violet"]` del perfil canónico: **sin discrepancias**.
- Las suites acumulativas de CAMP004 `tests/tools/test_parallel_items_w05_campaign_004.py` y `tests/gameplay/parallel_items_w05_campaign_004.gd` quedan intactas. Python valida metadatos, política y learnsets reales; Godot prueba `FieldItemService.teach`, propiedad, stock, compatibilidad, rechazo, PP, consumo y SaveV2. Sin reparaciones de producción ni relajación de pruebas.

## Certificación
- **Bloques 01–09 CI real PASS:** [Actions #41589081119](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41589081119), SHA `cc092d4935036be18503965af3519852ecc9b39f`, `completed/success`. Logs `CAMP004_W05_PY PASS blocks=9 checks=522`, `CAMP004_W05_GODOT PASS blocks=9 checks=1951`, ambos gates PASS, CAMP003 Python 580 / Godot 2166 checks PASS, CAMP002 11 tests OK.
- **CI de cierre** [Actions #41591821717](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41591821717), SHA exacto del progreso `5c9051ca2a0a186d31705372d2f0c350e2dd62db`, observado inicialmente `pending`. Run intermedio del fixture #41591801564 puede cancelarse por concurrencia; una cancelación sustituida no es fallo funcional.
- Antes de declarar `CAMPAÑA_004_FINALIZADA`, comprobar que el run final termina `completed/success`, con `CAMP004_W05_PY PASS blocks=10 checks=N`, `CAMP004_W05_GODOT PASS blocks=10 checks=N`, ambos validadores, regresiones CAMP003 de 60 MT y CAMP002 de 11 tests. Si falla, diagnosticar/reparar automáticamente dentro de W05 bajo V5, con CI nueva.

## Fronteras y STOP
- No ejecutar bloque 11 ni reservar IDs posteriores; solo IA6 puede autorizar una campaña posterior.
- `main`, V28, PR118, rama árbitra, ramas de otras trabajadoras, política/catálogos, 19 máquinas legacy y partidas reales intocados; sin merge. CI headless no acredita UI ni GPU.
- Con los recibos finales PASS, publicar informe consolidado CAMP004 y marcar `CAMPAÑA_004_FINALIZADA` **sin reescribir el CSV histórico para evitar nuevas ejecuciones de CI**.

**ITER_10/10 entregada; CI final pendiente al redactar.**
