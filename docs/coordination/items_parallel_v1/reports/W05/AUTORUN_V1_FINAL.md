# IA5/W05 — TANDA 01 FINALIZADA · AUTORUN V1

**Fecha de ejecución:** 2026-11-10. **Rama exclusiva:** `codex/calvo-items-20261109-w05-books-ui`.
**Resultado:** `TANDA_01_FINALIZADA` — **10/10 filas examinadas; 10/10 grupos funcionales; 49/49 MT con positivo real, 0 bloqueados.**
**HEAD de código y pruebas ejecutado:** `fd6a04317b21d8afa15af43a25cbe777ae64c4f6`.
**CI final sobre ese código:** [GitHub Actions #42729735437](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42729735437), `completed/success`, job `129544427910`.

## Manifiesto de grupos y recibos positivos

Cada grupo se sometió al mismo runner Godot parametrizado `tests/gameplay/parallel_items_w05_book_ui_autorun_v1.gd`, con panel `PanelContainer` realmente instanciado y servicio `FieldItemService.teach`, no solo lectura de metadatos. Las 49 MT son las **exactas** de `CAMPAIGN_006_W05_QUEUE_APPROVED.csv` y el fixture histórico inalterado; perfil activo `scarlet-violet`.

| Fila | IDs autorizados | Enseñanza positiva | Bloqueados | Comprobaciones Godot |
|---|---|---:|---:|---:|
| 01 | `tm202`, `tm203`, `tm204`, `tm205`, `tm206` | 5/5 | 0 | 290 |
| 02 | `tm207`, `tm208`, `tm209`, `tm210`, `tm211` | 5/5 | 0 | 290 |
| 03 | `tm212`, `tm213`, `tm214`, `tm215`, `tm216` | 5/5 | 0 | 290 |
| 04 | `tm217`, `tm218`, `tm219`, `tm220`, `tm221` | 5/5 | 0 | 290 |
| 05 | `tm222`, `tm223`, `tm224`, `tm225`, `tm226` | 5/5 | 0 | 290 |
| 06 | `tm227`, `tm228`, `tm229`, `tm01`, `tm02` | 5/5 | 0 | 290 |
| 07 | `tm03`, `tm04`, `tm05`, `tm06`, `tm08` | 5/5 | 0 | 290 |
| 08 | `tm09`, `tm10`, `tm11`, `tm12`, `tm13` | 5/5 | 0 | 290 |
| 09 | `tm14`, `tm15`, `tm17`, `tm19`, `tm20` | 5/5 | 0 | 290 |
| 10 | `tm31`, `tm36`, `tm44`, `tm77` | 4/4 | 0 | 232 |

**Recibos literales del job:**
- `W05_BOOKS_AUTORUN_PY PASS blocks=10 ids=49 checks=114`.
- `W05_BOOKS_AUTORUN_GROUP block=01..09 status=CERTIFICABLE ids=5 functional=5 blocked=0 checks=290` — recibos individuales 01–09.
- `W05_BOOKS_AUTORUN_GROUP block=10 status=CERTIFICABLE ids=4 functional=4 blocked=0 checks=232`.
- `W05_BOOKS_AUTORUN_GODOT PASS blocks=10 ids=49 functional=49 blocked=0 checks=2869`.

El runner eligió especies **permitidas y con learnset SV real**, y comprobó por cada MT: nombre y tipo textual desde `FieldMachineBookProfile.presentacion`, selección de libro/Pokémon de la mochila y party reales, negativa incompatible, falta de stock, `field_locked`, cuatro movimientos y selección de reemplazo obligatoria, nuevo movimiento con PP correctos, antiguo movimiento sustituido, identidad y propietario, consumo de exactamente una unidad, prohibición de repetición y escritura/lectura SaveV2. Un escenario sin especie válida se habría registrado `BLOQUEADO` sin falsificar datos; en el run final no apareció ninguno.

## Regresiones y límites técnicos

En el **mismo run** se preservaron los recibos:
- `W05_BOOK_UI_PILOT_20261109_PY PASS checks=23`; `W05_BOOK_UI_PILOT_20261109_GODOT PASS checks=143` — pilotos L3 01/02.
- `CAMP006_W05_MANIFEST_PASS reserved=10 completed=10 ids=49 kind=NEW_IDS`.
- `CAMP006_W05_PY PASS blocks=10 checks=481`; `CAMP006_W05_GODOT PASS blocks=10 checks=1781` y ambos `CAMP006_GATE_*_PASS`.
- CAMPAÑA_005: Python **580** y Godot **2166** PASS, diez bloques.
- CAMPAÑA_004: Python **580** y Godot **2166** PASS, diez bloques.
- CAMPAÑA_003: Python **580** y Godot **2166** PASS, diez bloques.

Los intentos precedentes se conservaron sin borrar su historia: [#42729395369](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42729395369) falló sin jobs por error YAML en el paso nuevo, reparado; [#42729549686](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42729549686) pasó las regresiones, pero falló un control Python estático que esperaba el nombre local `BookPanel` en lugar del `PanelClass` efectivamente instanciado, reparado sin disminuir cobertura funcional. [#42729735437](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42729735437) certifica la solución completa.

**Alcance exacto:** L3 del **panel aislado** probado en Godot `--headless`, servicio real y persistencia SaveV2. **No es revisión visual/GPU ni prueba de todas las especies existentes**, ni certifica que esta versión del panel se haya integrado ya en la rama de IA6. IA6 conserva su conexión `FieldItemBag` previamente probada y debe incorporar **selectivamente** la versión W05 con regresión conjunta; no mezclar cambios W03 automáticamente.

## Protección, diff y próximos pasos

Cambios de esta tanda: `tests/gameplay/parallel_items_w05_book_ui_autorun_v1.gd`, `tests/tools/test_parallel_items_w05_book_ui_autorun_v1.py`, su workflow propio `.github/workflows/parallel-w05-books-ui-20261109.yml`, checkpoint, CSV y este informe final. No se editaron `FieldItemBag`, `FieldItemService`, SaveV2 central, fichas o catálogo, traducciones, `main`, V28, PR118, árbitra ni otras ramas. **No se hizo merge**.

**Regla de cierre:** tanda cerrada tras diez filas; sin tarea 11 ni próxima tanda inventada. **STOP hasta que IA6 publique nueva cola en `IA6_AUTORUN.md`.** El CSV final registra `CERTIFICADO` sobre la SHA comprobada en Actions; las modificaciones documentales posteriores no alteran los archivos de producción ni de pruebas.

**Relevo compacto a IA6:** `W05 TANDA 01 FINALIZADA — 10/10 examinados — 10/10 grupos funcionales — 49/49 MT — 0 bloqueados — fd6a04317b21d8afa15af43a25cbe777ae64c4f6 — CI #42729735437 SUCCESS — AUTORUN_V1_FINAL.md`.
