# IA4/W04 — CAMPAÑA_004 / Bloque 06

**Rama:** `codex/calvo-items-20261103-w04-camp004`  
**Estado inicial:** `EN_CI_AUTOMATICA`, pendiente de comprobar logs de Godot 4.7 y Python.  
**IDs exactos:** `griseous_core`, `lustrous_globe`, `meteorite`.

## Contratos existentes

- `griseous_core`: seleccionado en `RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`; `item_connections_v1.json` lo marca equipable y `ITEM_FIELD_V8.csv.txt` confirma transferencia de equipamiento, **no** la forma Origen de Giratina. `ITEM_INVENTORY.csv` tiene `NATIVE_ENTRY_REQUIRES_EFFECT_CASE`, una dependencia funcional del efecto/forma.
- `lustrous_globe`: condiciones equivalentes para Palkia: equipamiento verificado, forma especial aún sin prueba positiva.
- `meteorite`: seleccionado para revisión, no equipable en el perfil actual, `DATA_ONLY` en `ITEM_INVENTORY.csv`. El cambio de forma de Deoxys requiere contrato no implementado; no habilitarlo mediante uso de mochila sin datos.

No se han inventado reglas de forma, consumo, combate ni activación del objeto.

## Pruebas publicadas

- Runner Godot `tests/gameplay/parallel_items_w04_campaign_004.gd`, commit `4940c32e47488bc24d606876f3f5c127344b6433`: acumula bloques 01–06. Para cada objeto inspecciona registros de evolución reales. Si no existe ruta `TRIGGER_USE_ITEM + RUNTIME_SUPPORTED`, controla `use_item` y `evolve` rechazados, inventario sin gasto, identidad intacta, propietario ajeno rechazado, equipar/quitar solo cuando permitido y SaveV2; para Giratina, Palkia, Deoxys y Eevee como control negativo. Cualquier ruta positiva auténtica se comprueba solo si está catalogada y soportada.
- Fixture `tests/fixtures/parallel_items/w04_campaign_004.json`, commit `9c70187536dd3b7e8af1d1d27d25404b3774dcf4`: preserva 01–05 y añade IDs/casos de forma y equipamiento 06.
- Validador Python `tests/tools/test_parallel_items_w04_campaign_004.py`, commit `00960c1e2574452d2b97da52ed343109ede15270`: verifica exactamente 6 filas, 18 IDs, selección, diferencias `holdable`, entradas nativas, estado `DATA_ONLY` del Meteorito y presencia de aserciones del runner.
- CSV progreso `docs/coordination/items_parallel_v1/reports/W04/CAMP_004_PROGRESO.csv`, commit `ccbcb310580ae1b34f44d318ba9454eea9c44e91`, fila 06 `EN_CI_AUTOMATICA`.

## Incidencia de escritura previa

Un intento de publicación en la conversación anterior fue rechazado por un control de seguridad de OpenAI, sin modificar el archivo. Con nuevo mensaje `p` del usuario se reintentó **la misma operación autorizada y normal** de GitHub y se aceptó, sin cambio de permisos ni uso de interfaces alternas. La rama, los cinco bloques anteriores y la CI previa [#41579352482](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41579352482) se comprobaron intactos antes de editar.

## Puerta de aceptación

Consultar última CI de la rama y exigir `CAMP004_W04_PY PASS blocks=6 checks=N`, `CAMP004_W04_GODOT PASS blocks=6 checks=N`, regresión CAMPAÑA_003 Python/Godot. El workflow ejecuta además la regresión CAMPAÑA_001 en los bloques **05 y 10**, no en el bloque 06. CI local aprobada **no certifica** formas de Giratina/Palkia/Deoxys.

Sin cambios en producción, `main`, V28, datasets, workflow, rama árbitra ni ramas ajenas. Las 16 dependencias de CAMPAÑA_003 siguen intactas.

**Siguiente `p`:** bloque 07/10 (`rage_candy_bar;red_orb;reins_of_unity`), solamente después de revisar la CI06 y reparar cualquier fallo propio.


## Corrección V5 de validación Python

La primera CI [#41584213703](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41584213703) falló en el validador Python por un literal de salida **obsoleto**: el contrato de bloque 05 buscaba `CAMP004_W04_GODOT PASS blocks=5 checks=` aunque el runner acumulativo pasó correctamente a seis bloques. No se ejecutó Godot funcional en esa CI por el fallo anterior de Python.

Corrección mínima en `tests/tools/test_parallel_items_w04_campaign_004.py`, commit `64f688735428722fb0f5970a0be0f9ebb11a42e1`: retirar únicamente esa referencia específica al antiguo número de bloques. Se conservan los tests de comportamiento del bloque 05 y el recibo final exacto de seis bloques, que se verifica dentro de los contratos del bloque 06.

**Nueva CI:** [#41584355240](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41584355240), pendiente de comprobación final. No afirmar PASS hasta registros reales.


## CI06 corregida y verificada

Después del fallo inicial de Python por el marcador antiguo `blocks=5`, se publicó la reparación mínima `64f688735428722fb0f5970a0be0f9ebb11a42e1`. La nueva [GitHub Actions #41584355240](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41584355240) terminó `completed/success` sobre ese SHA. Recibos extraídos de logs:
- `CAMP004_W04_MANIFEST_PASS reserved=10 completed=6 ids=36`.
- `CAMP004_W04_PY PASS blocks=6 checks=181`.
- `CAMP004_W04_GODOT PASS blocks=6 checks=565`.
- Regresiones CAMP003: Python `PASS blocks=10 checks=120`; Godot `PASS blocks=10 checks=270`.

Salidas individuales: `griseous_core` y `lustrous_globe`, `DEPENDENCIA records=0`, equipamiento verificado pero sin ruta de forma certificada; `meteorite`, `DEPENDENCIA records=0`, cambio de Deoxys no conectado. Las aserciones de no consumo, identidad y SaveV2 pasaron, **no** la forma real de esos Pokémon.

CSV de progreso reconciliado a `DEPENDENCIA_DOCUMENTADA` con run `41584355240`, commit `ce99a4a70514b3d952a59ee863f07f770af71f6a`. La propia actualización del CSV activa CI adicional; no se debe atribuir su resultado hasta verificarlo.

**Resumen:** bloque 06 entregado con 18 IDs acumulados auditados. Próximo `p`: bloque 07, si esta última CI no revela fallo.
