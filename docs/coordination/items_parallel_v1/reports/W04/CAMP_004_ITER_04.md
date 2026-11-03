# IA4/W04 — CAMPAÑA_004, bloque 04

**Rama exclusiva:** `codex/calvo-items-20261103-w04-camp004`. **Estado:** `EN_CI_AUTOMATICA`, sujeto al resultado real de GitHub Actions.

## Cola autorizada y contratos
- `adamant_crystal` (Gran Diamansfera): objeto equipado relacionado con forma de Dialga; **no** sustituir un contrato de formas por evolución de mochila. `item_connections_v1.json` lo declara `holdable` y `ITEM_FIELD_V8.csv.txt` marca transferencia de equipamiento verificada, pero no funcionalidad de forma.
- `blue_orb` (Prisma Azul): objeto equipable de Kyogre, relacionado con reversión primigenia; no introducir transformación ni activación de batalla sin contrato. Equipamiento aparece verificado, efecto pendiente.
- `catching_charm` (Amuleto Captura): en selección como `STORY_KEY_OR_FORM_REVIEW`; el perfil de equipamiento no lo incluye y `ITEM_FIELD_V8.csv.txt` no certifica su efecto. **Captura es competencia de W03**: esta auditoría solo verifica no fingir un efecto de evolución/bolsa, no la tasa de captura.

## Pruebas
- Godot `tests/gameplay/parallel_items_w04_campaign_004.gd`, commit `74beda72dda2f2fccec9f723a1303680f12ada63`: conserva bloques 01–03. Añade para Dialga, Kyogre y control Eevee pruebas sobre definición, propiedad de inventario, rechazo de `use_item` y `evolve` como transformaciones no soportadas, ausencia de gasto o alteración de SaveGameData, equipamiento únicamente cuando el perfil autoriza y vuelta a estado intacto. Si se equipa un orbe/cristal, persiste objeto/identidad en SaveV2 y comprueba que no cambie especie por ese solo acto. Para el amuleto verifica rechazo de equipamiento de criatura, **sin atribuir resultados del subsistema de captura**.
- Fixture `tests/fixtures/parallel_items/w04_campaign_004.json`, commit `cb9151868d67350cd6e1dcffd5fa0a69822a62b2`: agrega IDs y alcance 04.
- Python `tests/tools/test_parallel_items_w04_campaign_004.py`, commit `8010967ed4761213bd19ab06df60baf6eb99ac76`: comprueba exactamente 4 filas, 12 IDs nuevos acumulados, categoría `STORY_KEY_OR_FORM_REVIEW`, registros `ITEM_FIELD_V8`, presencia de dos `holdable_ids` y no inclusión del Amuleto, más los contratos del runner.
- Progreso `reports/W04/CAMP_004_PROGRESO.csv`, commit `f3cb82b986443123a0a56336b0e76d09a8e446f3`: añade una única fila 04. La cola y manifiesto de IA6 no se han modificado.

**Pendiente:** consultar GitHub Actions y verificar recibos `CAMP004_W04_PY PASS blocks=4 checks=M`, `CAMP004_W04_GODOT PASS blocks=4 checks=M`, y regresiones CAMPAÑA_003. Un PASS negativo solo acredita invariantes actuales de inventario y forma, nunca reversión primigenia ni bonificación de captura.

**Límites:** sin edición en módulos de producción, `main`, V28, ramas W01/W02/W03/W05, rama árbitra, workflow o catálogo canónico. Las 16 dependencias de CAMP003 y nueve dependencias previas de CAMP004 se conservan.

**Próximo `p` autorizado:** bloque 05 (`dna_splicers;exp_charm;gracidea`), previa verificación de esta CI.


## CI04 verificada

La ejecución [#41578460848](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41578460848) sobre SHA `f3cb82b986443123a0a56336b0e76d09a8e446f3` terminó `completed/success`, con recibos del log:

- `CAMP004_W04_MANIFEST_PASS reserved=10 completed=4 ids=36`.
- `CAMP004_W04_PY PASS blocks=4 checks=114`.
- `CAMP004_W04_GODOT PASS blocks=4 checks=382`.
- Regresión CAMP003: Python 120 y Godot 270 comprobaciones PASS.

Los mensajes individuales de Godot fueron:
- `adamant_crystal`: `DEPENDENCIA`, equipable pero **sin transformación de forma ejecutable mediante FieldItemService**.
- `blue_orb`: `DEPENDENCIA`, equipable pero **sin reversión primigenia ejecutable mediante FieldItemService**.
- `catching_charm`: `AUDITORIA_DE_DATOS`, no se certifican efectos de captura; W03 es propietaria de captura.

La fila 04 del CSV queda `DEPENDENCIA_DOCUMENTADA` (incluye la auditoría de datos del amuleto porque la puerta admite esos estados), run `41578460848`, commit `4b93b0af42bebc2c5298fe26f384e191a84bdafa`. La CI de ese CSV consolidado se comprueba aparte. Ninguna afirmación de funcionalidad de combate o captura procede de este PASS.


## Segunda CI del progreso consolidado

La ejecución [#41578687219](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41578687219), SHA `4b93b0af42bebc2c5298fe26f384e191a84bdafa`, terminó **completed/success** tras actualizar la fila 04 a `DEPENDENCIA_DOCUMENTADA`. Confirmó nuevamente `CAMP004_W04_MANIFEST_PASS reserved=10 completed=4 ids=36`, Python **114 PASS**, Godot **382 PASS** y regresiones CAMP003 Python **120 PASS**, Godot **270 PASS**. `adamant_crystal` y `blue_orb` continúan como `DEPENDENCIA`; `catching_charm` como `AUDITORIA_DE_DATOS` fuera de captura W04.

**Estado del bloque 04:** pruebas aprobadas y documentación publicada, no implementación funcional de formas ni captura. Siguiente `p` autorizado: bloque 05.
