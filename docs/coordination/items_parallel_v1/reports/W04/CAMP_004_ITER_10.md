# IA4/W04 — CAMPAÑA_004 / Bloque 10: tesoros y coleccionables

**Rama única de trabajo:** `codex/calvo-items-20261103-w04-camp004`.  
**Cola oficial:** `big_nugget;bottle_cap;gold_bottle_cap;heart_scale;nugget;pretty_wing;rare_bone`.  
**Estado inicial:** 10/10 filas publicadas, **CI final pendiente de verificación**, no afirmar funcionamiento sin logs.

## Diagnóstico a partir del catálogo real

Los siete están `SELECCIONADO`, `TREASURE_OR_COLLECTIBLE` y no aparecen en `imported_recovery_v19.json` como medicinas ni tienen enlaces evolutivos según `docs/current/ITEM_INVENTORY.csv`.

- **Equipables / transferencia documentada**: `big_nugget`, `bottle_cap`, `gold_bottle_cap`, `rare_bone`. El perfil `modules/inventory/item_connections_v1.json` los incluye en `holdable_ids`, `ITEM_FIELD_V8.csv.txt` marca transferencia `VERIFIED` y el inventario documenta entrada nativa `NATIVE_ENTRY_REQUIRES_EFFECT_CASE`. **Esto no prueba venta, economía, entrenamiento extremo/IV ni efectos de batalla.**
- **No equipables en el perfil / `DATA_ONLY`**: `heart_scale`, `nugget`, `pretty_wing`, sin entrada nativa ni contrato de uso de campo. **No se atribuye venta, reaprendizaje de movimientos ni ningún efecto especial.**

El campo `SELL_TRADE_OR_TRAINING_CONTEXT_NEEDED` aparece en los siete. Una etiqueta de selección no equivale a funcionalidad de tienda, comercio o entrenamiento.

## Pruebas y datos publicados

- Godot `tests/gameplay/parallel_items_w04_campaign_004.gd`, commit `46d349296bc670e9cb1c282d8758608dacce4fa6`, añade `BLOQUE_10`, descubre reglas reales de evolución por objeto y solo prueba una ruta positiva si `TRIGGER_USE_ITEM + RUNTIME_SUPPORTED`. Si no hay ruta soportada, en **Eevee y Magikarp** comprueba cantidad, rechazo de uso directo, ausencia de evolución falsa, especie/identidad conservadas, equipar y retirar cuando el perfil lo permite y persistencia `SaveV2`, tanto equipado como restaurado. No modifica moneda, IV, tienda, movimientos ni producción.
- Fixture `tests/fixtures/parallel_items/w04_campaign_004.json`, commit `d78be4863e9df8fa6813b4f6f54d50418d49d65b`, añade la décima y última fila sin reordenar ninguna anterior.
- Python `tests/tools/test_parallel_items_w04_campaign_004.py`, commit `b71884094b5e52f5a2a8f3f6a70c18ef3cfd84a4`, comprueba **36 IDs únicos en diez bloques**, coincidencia íntegra fixture–cola oficial, siete selecciones de tesoro, cuatro equipables/entradas nativas pendientes y tres `DATA_ONLY`, no recuperación y aserciones del runner.
- Progreso `reports/W04/CAMP_004_PROGRESO.csv`, commit `eb7f9046cb1a0cc04e0ea15764dbf32646925033`: diez filas con la 10 en `EN_CI_AUTOMATICA`.

## Puerta de cierre

Exigir CI real sobre el SHA de pruebas y progreso: `CAMP004_W04_MANIFEST_PASS reserved=10 completed=10 ids=36`, `CAMP004_W04_PY PASS blocks=10 checks=N`, `CAMP004_W04_GODOT PASS blocks=10 checks=N`, regresión CAMP003 Python/Godot 10/10 y regresión CAMP001 `PARALLEL_ITEMS_W04_CAMP_001_GODOT PASS iteration=3 checks=559 cases=12`. Resolver cualquier fallo antes de marcar cierre; **PASS de inventario no significa efectos de venta, entrenamiento o formas certificados**.

Sin cambios en producción, catálogos, `main`, V28, rama árbitra o ramas W01/W02/W03/W05. **Las 16 dependencias funcionales de CAMPAÑA_003 siguen pendientes**. El cierre solo certificará el trabajo de auditoría/contratos autorizado y mantendrá un listado de dependencias por dominio para IA6.

**Al alcanzar CI final aprobada:** reconciliar CSV con recibo, actualizar este informe, crear `CAMP_004_FINAL.md`, actualizar `CONTINUIDAD.md`, comprobar nueva CI de CSV consolidado y declarar `CAMPAÑA_004_FINALIZADA`. Después STOP; no inventar CAMPAÑA_005.


## Primera CI final ejecutada

[GitHub Actions #41610829772](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41610829772), SHA `eb7f9046cb1a0cc04e0ea15764dbf32646925033`, terminó **completed/success**, con recibos de logs:

- `CAMP004_W04_MANIFEST_PASS reserved=10 completed=10 ids=36`.
- `CAMP004_W04_PY PASS blocks=10 checks=387`.
- `CAMP004_W04_GODOT PASS blocks=10 checks=1090`.
- Regresión CAMP003: Python `PASS blocks=10 checks=120` y Godot `PASS blocks=10 checks=270`.
- Regresión CAMP001: `PARALLEL_ITEMS_W04_CAMP_001_GODOT PASS iteration=3 checks=559 cases=12`.

Resultados individuales en Godot: `big_nugget`, `bottle_cap`, `gold_bottle_cap`, `rare_bone` figuran `status=DEPENDENCIA records=0` con equipamiento y SaveV2 verificados, pero venta, economía y entrenamiento sin efecto certificado; `heart_scale`, `nugget` y `pretty_wing` figuran `status=DEPENDENCIA records=0` y `DATA_ONLY`, con rechazos seguros, identidad y SaveV2 correctos. Los siete carecen de rutas evolutivas asociadas.

El log acumulado contiene exactamente 36 IDs únicos: **31 `DEPENDENCIA`**, **1 `AUDITORIA_DE_DATOS`** (`catching_charm`), **3 `AUDITORIA_LEGACY`** (`roto_*`) y **1 `RECUPERACION_VERIFICADA`** (`rage_candy_bar`); este último sí prueba curación real, gasto unitario y SaveV2. La regresión CAMP003 sigue con 16 dependencias funcionales propias.

La fila 10 del CSV está reconciliada como `DEPENDENCIA_DOCUMENTADA`, run `41610829772`, commit `1f4021c4ec00f26a4df3e24428e53b0989caabe8`. **Queda pendiente de confirmar la CI disparada por ese cambio documental antes de declarar cierre total.** Ningún dato funcional del juego ha sido modificado.


## CI del progreso final y STOP

La segunda ejecución [#41611102944](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41611102944) terminó `completed/success` en SHA `1f4021c4ec00f26a4df3e24428e53b0989caabe8`, **después** de registrar el bloque 10 como `DEPENDENCIA_DOCUMENTADA`. Se verificaron otra vez los recibos `CAMP004_W04_MANIFEST_PASS reserved=10 completed=10 ids=36`, Python **387**, Godot **1.090**, CAMP003 Python **120** / Godot **270** y CAMP001 Godot **559** / **12** casos. Los siete tesoros mantienen `status=DEPENDENCIA records=0`.

Informe consolidado para IA6: `reports/W04/CAMP_004_FINAL.md`. La clasificación individual de 36 IDs fue comprobada en el log completo: **31 dependencias**, **1 auditoría de datos**, **3 auditorías legacy**, **1 recuperación positiva**. La campaña está completada como **auditoría, pruebas, documentación y delimitación de las funciones faltantes**, no como implementación de 36 mecánicas. El cierre no requiere modificar producción ni repetir trabajo.

**Estado: `CAMPAÑA_004_FINALIZADA` — STOP IA4/W04** hasta nuevo encargo oficial.
