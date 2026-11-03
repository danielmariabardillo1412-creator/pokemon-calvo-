# IA6 — CAMPAÑA_004 EXCLUSIVA W02 | ACTIVADA
**Fecha:** 2026-11-03. **Autorización:** usuario pide continuar W02 tras CAMPAÑA_003, sin detenerla mientras las otras trabajan. **Rama nueva:** `codex/calvo-items-20261103-w02-camp004`. **Única trabajadora:** IA2/W02.

## Cierre verificado y alcance
CAMP003 W02 **10/10**; GitHub Actions [#41570972406](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41570972406) en SHA `291146f2efe617dbb7528050068e09e80a64022c` terminó `completed/success`: Godot `PASS blocks=10 checks=7306` y gates de Python/Godot correctos. Esto no certifica la integración global ni la UI.

Nueva cola [CAMPAIGN_004_W02_QUEUE_APPROVED.csv](CAMPAIGN_004_W02_QUEUE_APPROVED.csv): **10 bloques / 40 IDs**. Bloques 01–02: **8 bayas** BERRY no incluidas en las 40 bayas CAMP003 ni las 6 de CAMP001. Bloques 03–10: **32 medicinas** MEDICINE aún no reservadas en el equipo. Se verificó ausencia de colisión de IDs con campañas 003 y 004 de W03/W05. `hopo_berry` figura como MEDICINE en selección: revisar su contrato, no reinterpretar política.

## Protocolo
1. Crear la rama exclusiva W02 CAMP004 desde HEAD exacto de W02 CAMP003 y mantener intacta la anterior. Activación inicial ejecuta bloque 01; después cada `p` avanza exactamente una fila, hasta el bloque 10. No inventar bloque 11.
2. Conservar íntegra la regresión de CAMP003. Crear Python/Godot propios para CAMP004 en `tests/tools/test_parallel_items_w02_campaign_004.py` y `tests/gameplay/parallel_items_w02_campaign_004.gd`, fixture propio `tests/fixtures/parallel_items/w02_campaign_004.json`, CSV de progreso e informes W02; no usar un recibo anterior para declarar éxito nuevo.
3. Por cada objeto contrastar datos con operación real, efectos positivos/negativos, rechazo sin consumo, stock, propietario, límites de HP/PP/estado/EV/amistad según proceda, y SaveV2. No todas las medicinas tienen el mismo efecto; no inventar semántica. Si falta contrato/código, registrar dependencia concreta sin declararlo implementado.
4. **V5 vigente:** W02 puede reparar errores propios de bayas/medicinas, con test rojo-verde y CI del SHA. La reparación de medicina debe permanecer en funciones de su familia; `field_item_service.gd` es compartido con W03/W04/W05, por lo que cualquier edición de API o función común exige coordinación de IA6. Nunca modificar reglas ajenas o arquitectura general.
5. CI dedicada W02 CAMP004 valida manifest y corre Python+Godot en cada bloque, y regresión acumulada W02 CAMP003; un bootstrap 0/10 valida solo configuración, no funcionalidades. Si falla, diagnosticar y reparar sin reducir aserciones. CI en curso permite preparar bloque independiente, no declarar PASS.
6. Prohibido tocar `main`, V28, PR #118, ramas W01/W03/W04/W05, rama árbitra desde el chat W02, catálogos o políticas globales. IA6 integra secuencialmente y conserva trazabilidad; sin merge automático. La GPU/UI requiere verificación separada.
