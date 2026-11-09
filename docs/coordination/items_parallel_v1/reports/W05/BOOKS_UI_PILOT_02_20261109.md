# IA5/W05 — LIBROS-UI-L3 02 · QA de estados y consumo

**Rama:** `codex/calvo-items-20261109-w05-books-ui`. **Autoridad:** `IA6_ORDERS_W03_W04_W05_20261109.md` en rama árbitra. **Estado inicial:** EN_CI_PENDIENTE, no declarar PASS antes de recibos reales.

## Alcance y diffs

- `scenes/visual/field_machine_book_panel.gd`: el botón `Enseñar movimiento` queda **deshabilitado** cuando no hay libro o Pokémon seleccionado, no queda stock, hay un bloqueo del servicio `field_locked`, la especie no ofrece learnset SV, la especie es incompatible, ya conoce el movimiento, el movimiento no está permitido o hay cuatro ataques sin decidir cuál sustituir. La vista usa `FieldMachineBookProfile.presentacion`, el guard existente `FieldItemService._boundary`, el inventario/colección reales y el learnset SV original; no establece reglas de consumo.
- `teach_selected()` vuelve a consultar el estado vivo antes del único `service.teach`. Ni la señal de botón emitida en un estado bloqueado ni una UI desactualizada pueden gastar libros; el servicio continúa siendo la única autoridad de enseñanza y consumo.
- `tests/gameplay/parallel_items_w05_book_ui_pilot_20261109.gd`: amplía el piloto real con botones deshabilitados, clic forzado en estado prohibido sin mutación, ausencia temporal de existencias, elección obligatoria de reemplazo, comprobación del movimiento anterior retirado, movimiento ya conocido, sin selección, guard bloqueado, última copia consumida, ausencia temporal de learnset únicamente en memoria del test con restauración, PP y SaveV2. Mantiene `tm202`, `tm31` y un incompatible real.
- `tests/tools/test_parallel_items_w05_book_ui_pilot_20261109.py`: amplía las verificaciones estructurales conservando el recibo y la distinción entre pruebas estáticas y prueba Godot real.

## Fronteras

IA6 ya integró la conexión de libros con `FieldItemBag` en `codex/calvo-ia6-integration-20261109`, CI conjunta `42701239557` SUCCESS. **W05 no cambia ni copia `FieldItemBag`** ni esa rama, ni SaveV2 central, `FieldItemService`, catálogo, mapas o textos compartidos. Mantiene los dos nombres españoles previamente verificados y no añade traducciones ni IDs.

Estas pruebas son headless: acreditan el panel aislado con servicio y SaveV2, no revisión visual/GPU ni certifican que la nueva revisión del panel se haya incorporado ya a la rama integrada de IA6. IA6 debe incorporar selectivamente solo el nuevo panel y revalidar su conexión.

## Puerta CI

Exigir GitHub Actions `completed/success` del SHA publicado, recibos `W05_BOOK_UI_PILOT_20261109_PY PASS checks=N` y `W05_BOOK_UI_PILOT_20261109_GODOT PASS checks=N`, además de regresiones CAMP006/005/004/003 completas. No usar `42701239557` como resultado de esta nueva mejora. Una vez aprobado, registrar SHA, run, job, recibos y STOP hasta nueva orden IA6.
