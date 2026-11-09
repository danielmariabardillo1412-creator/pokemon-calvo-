# IA5/W05 — LIBROS-UI-L3 02 · QA de estados y consumo

**Rama:** `codex/calvo-items-20261109-w05-books-ui`. **Autoridad:** `IA6_ORDERS_W03_W04_W05_20261109.md` en rama árbitra. **Estado de publicación inicial:** EN_CI_PENDIENTE. **Estado certificado:** `LIBROS_UI_L3_02_PASS_HEADLESS` tras revisión de CI y recibos.

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

## Resultado final certificado — 9 noviembre 2026

La primera ejecución [#42714448965](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42714448965) terminó FAILURE solo por una expectativa incorrecta del test para cuatro movimientos: el botón debía permanecer deshabilitado mientras no se escogiese un slot de sustitución. Las pruebas CAMP006/005/004/003 habían pasado. Se corrigió solo el runner Godot, **sin alterar el panel** ni relajar la norma de sustitución, en `42397483f99a54d6234a3afae94e239b79b99f63`.

La segunda ejecución [#42714738745](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42714738745) sobre ese SHA funcional concluyó `completed/success`, job `129493213945`. Recibos literales verificados en los logs del job:

- `W05_BOOK_UI_PILOT_20261109_PY PASS checks=23`
- `W05_BOOK_UI_PILOT_20261109_GODOT PASS checks=143`
- `CAMP006_W05_MANIFEST_PASS reserved=10 completed=10 ids=49 kind=NEW_IDS`
- `CAMP006_W05_PY PASS blocks=10 checks=481`
- `CAMP006_GATE_PY_PASS worker=W05 blocks=10 checks=481`
- `CAMP006_W05_GODOT PASS blocks=10 checks=1781`
- `CAMP006_GATE_GODOT_PASS worker=W05 blocks=10 checks=1781`
- `CAMP005_W05_PY PASS blocks=10 checks=580`
- `CAMP005_W05_GODOT PASS blocks=10 checks=2166`
- `CAMP004_W05_PY PASS blocks=10 checks=580`
- `CAMP004_W05_GODOT PASS blocks=10 checks=2166`
- `CAMP003_W05_PY PASS blocks=10 checks=580`
- `CAMP003_W05_GODOT PASS blocks=10 checks=2166`

El piloto de 143 comprobaciones Godot cubre los positivos reales `tm202`, `tm31` y su incompatibilidad, UI de botón activo/inactivo, cuatro movimientos sin slot, sustitución, PP y retirada del movimiento anterior, último libro consumido, inventario vacío, selector no definido, `field_locked`, ausencia inyectada de contexto SV en memoria de test (restaurada), rechazo sin doble consumo y persistencia SaveV2. El test Python de 23 comprobaciones es estático; no confundirlo con 23 ejecuciones funcionales adicionales.

**Frontera de integración:** IA6 mantiene en `codex/calvo-ia6-integration-20261109` su conexión previa a la mochila real (CI #42701239557 SUCCESS). **La versión actualizada del panel todavía no se ha trasladado a esa rama ni se ha certificado allí de nuevo.** Este resultado valida el panel aislado en Godot headless, no una revisión visual/GPU. El portado selectivo y la prueba conjunta quedan bajo IA6. `FieldItemBag` y demás áreas compartidas siguen sin cambios en W05.

**LIBROS-UI-L3 02 CERRADO. STOP hasta nueva autorización IA6.** No se inicia piloto 03, no se añade ninguna MT o traducción y no se hace merge.
