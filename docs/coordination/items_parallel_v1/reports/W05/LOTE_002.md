# IA5 / W05 — LOTE_002: validador de alcance MACHINE (solo lectura)

**Estado: LISTA_PARA_REVISION** · 2026-11-01 · Rama exclusiva `codex/calvo-items-20261101-w05`.

**Encargo oficial:** [LOTE_002_W05](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-arbitro/docs/coordination/items_parallel_v1/assignments/LOTE_002_W05.md) · blob SHA `b8f8df20cc70ab9ca7004c7b692a59537fc3efd7`.

**LOTE_001 aceptado por IA6:** [Informe W05 anterior](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/docs/coordination/items_parallel_v1/reports/W05/LOTE_001.md), commit `d9fffd2da1c9e4f2c120557503503292a34844f6`. Se conservó también el CSV de 248 IDs, sin cambios ni pérdidas.

## 1. Puerta de sincronización antes de escribir pruebas

- Checkpoint autorizado IA6: `38188cc208e67b19002437ac75160898ce332ec2`.
- HEAD propio anterior: `d9fffd2da1c9e4f2c120557503503292a34844f6`.
- Comparaciones Git en ambos sentidos: ambos descendían de `d6d6d5f9285d71b97db3ac18c6bbb70274ab19af`; **3 commits exclusivos de W05 vs 54 del checkpoint, sin rutas coincidentes en sus respectivos diffs**.
- Fusión **sin force, sin reset, sin rebase y exclusivamente sobre W05**, commit con dos padres `239edd8083a0980e556dfe04079e03f04b09e89e`, árbol `c487b6af2bf75819adc5b91d1f5d92ab677a95f1`. Padres: (1) W05 anterior, (2) checkpoint IA6. La actualización de rama se aceptó con precondición de HEAD esperado.
- Verificación posterior de presencia: `tools/item_audit/automation_v28.py` (blob `ae181662b315f033172a5cfef4a87961088fe8fd`), `docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv` (`8b9b723bf5944bbbde39aa2d49dfbb2f2a64e11b`), `NOTEBOOK_PROTOCOL_V1.md` (`4fac0eba28ea30dc6d3a3bd749699874cf446e66`). **LOTE_001.md** conserva blob `c8abed8810742505f2b1eee3c8e77994c8dcb13b`; **MACHINE_GAP_LOTE_001.csv** conserva `3dc33aaffaee469d239396fda7de684264618298`.
- Esta verificación acredita fusión de árbol y conservación de documentos, **NO CI/Godot de la base conjunta**.

## 2. Entregables y permisos

Se crearon/modificaron **solamente** cinco rutas autorizadas:

1. [Validador `parallel_w05_machine_scope.py`](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/tools/item_audit/parallel_w05_machine_scope.py) · commit creación `139dca1771609a01421fe95f1145707b0fdb2d2e` · blob `e1d6015a125f7fe4b5d1d0f9e34b94079f68858f`.
2. [Pruebas `test_parallel_w05_machine_scope.py`](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/tests/tools/test_parallel_w05_machine_scope.py) · commits `1a08f8439041204ce937f0476e75f4fdbfc4d7a6`, `3dc59071850326f863b41d9852076fde257bd38b` · blob `e150dd766c976f1fccf7d9fa2d08f633acc95ed4`.
3. [Fixture/contrato versionado](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/tests/fixtures/parallel_items/w05_machine_scope_v1.json) · commit `1c3c09f0018ca55218c24ed933c2bc867b1d997a` · blob `0dbd1f4d299569b63a7b0f0341bf2112e51c9319`.
4. Este `reports/W05/LOTE_002.md`.
5. Cuaderno mutable [`reports/W05/CONTINUIDAD.md`](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/docs/coordination/items_parallel_v1/reports/W05/CONTINUIDAD.md).

**No** se editaron `modules/`, `scenes/`, `assets/`, `config/`, `docs/current/`, `data/`, `.github/workflows/`, pruebas V27/V28, fuentes canónicas, guardados, cola, selección o ramas ajenas.

## 3. Qué valida y qué NO valida

El nuevo `validar(catalogo, perfil, contrato)` es **solo lectura**, con biblioteca estándar Python. Deriva todos los IDs a partir del CSV maestro filtrado por `familia=MACHINE`, no de una tabla escrita a mano ni de la antigua auditoría. Rechaza ID duplicado, formato ID MACHINE inválido, ID seleccionado ausente de `machine_rows`, versión/movimiento mal formado, descriptor de perfil/versión inadecuado y movimiento duplicado entre máquinas activas.

La versión activa viene del contrato JSON `active_machine_version` y debe coincidir con el perfil existente. Las preferencias históricas para `hm`, `tm`, `tr` son **versionadas y declarativas**: busca la primera versión de referencia disponible para cada máquina heredada sin inventar su movimiento. Cruza movimientos de máquinas heredadas con activas para **detectar solapes entre versiones**, sin activarlos ni modificar política. Compara recuentos y solapes calculados con la fotografía aprobada `expected_snapshot` del fixture; al cambiar el catálogo no altera silenciosamente sus expectativas: falla y pide revisión explícita.

**Salida positiva estática esperada:** 248 MACHINE seleccionadas, 229 mapeadas en `scarlet-violet`, 19 heredadas sin perfil SV (5 `hm`, 1 `tm` adicional, 13 `tr`), 229 movimientos activos distintos, un solape cross-version `hm05`/`tm77` → `waterfall`. `hm08` referencia `ruby-sapphire`, pues no tiene la preferida `omega-ruby-alpha-sapphire`. Los 90 IDs mapeados fuera de selección siguen sin alteración.

**No valida:** `FieldItemService.teach()` en Godot, compatibilidad de todas las especies, propietario real de equipo/PC, consumos reales, manejo de cuatro movimientos, lectura/escritura de partidas, GPU ni apariencia de libro. Su código no escribe ni un byte en las fuentes consultadas.

## 4. Pruebas realmente realizadas

| Evidencia | Comando o ejecución | Resultado | Alcance real |
|---|---|---|---|
| Sintaxis del validador | `python -m py_compile tools/item_audit/parallel_w05_machine_scope.py` | **PASS LOCAL** | Python 3.13.5; copia idéntica al blob publicado, sin Godot |
| Suite Python | `python -m unittest discover -s tests/tools -p 'test_parallel_w05_machine_scope.py' -v` | **13 PASS, 1 SKIP**, 14 casos, 0 FAIL, 0,030 s | Carpeta aislada local con fixtures **sintéticos** de 4 máquinas. Comprueba positivo, CLI JSON, lectura inmutable, duplicados, faltantes, versión inválida, malformados, solapes y conteos |
| Validación cruzada independiente del repositorio real | Lectura GitHub de `RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv` y `item_connections_v1.json`, verificador estático en sesión con 6 variantes | **PASS ESTÁTICO**: 248/229/19; prefijos 5/230/13; 0 entradas sin correspondencia o formato anómalo; 1 solape `hm05`/`tm77`. **5 negativas detectadas**: ID ausente, duplicado, perfil erróneo, movimiento duplicado y versión legacy imposible | Analiza datos reales de W05 tras merge; **no** ejecuta el script Python publicado en un checkout completo |
| Control de identidad del código publicado | `git hash-object` de copia local de validador y test vs blobs GitHub | **PASS**: `e1d6015...` y `e150dd7...` | Mismo código probado y publicado |
| Validación Python del árbol completo (248 filas) | El caso `test_ruta_real_248_si_disponible` | **SKIP / SIN_EJECUTAR** | Entorno local carece de checkout y DNS para GitHub; pendiente de CI consolidada IA6 |
| Godot 4.7/integración | `python tools/item_audit/run_connections.py --gpu --regressions` | **SIN_EJECUTAR** | No se dispone de Godot; orden histórica adicional **genera** archivos, y el lote prohíbe cambios de producción |
| Anteriores V27 | `docs/current/ITEM_CONNECTIONS_V1.json`, `tests/gameplay/item_connections_test_runner.gd` | **PASS HISTÓRICO (2026-10-28)** | 229 MT con una especie por ID + límites; no constituye PASS del árbol integrado |

**Comandos para IA6 en checkout de rama W05 o posterior integración** (un solo bloque de CI consolidado; no lanzado por W05):

```sh
python tools/item_audit/parallel_w05_machine_scope.py
python -m unittest discover -s tests/tools -p 'test_parallel_w05_machine_scope.py' -v
```

El primer comando debe terminar en `PASS_MAPA_ESTATICO_NO_FUNCIONAL`. El segundo debe tener 14 pruebas ejecutadas sin skips al estar el checkout íntegro, salvo que una fuente haya cambiado; entonces **investigar el fallo**, nunca actualizar fixture automáticamente para hacerlo pasar. Se recomienda añadir ambos al CI consolidado **solo por IA6**, tras revisar diff; no generar CI por cada commit documental.

## 5. Estado técnico, reutilizaciones y riesgos

- **Reutilización:** `tools/item_audit/prepare_connections_v1.py` y `modules/inventory/item_connections_v1.json` ya generan la relación estable `ID→versión→movimiento`. `modules/inventory/field_item_service.gd:teach` mantiene enseñanza, propiedad, guardas, consumo transaccional; `scenes/visual/field_item_bag.gd` visualiza y pide ranura. El validador **no duplica ninguna de esas reglas**.
- **Límite de test:** la nueva suite verifica **consistencia de mapa**, no funcionamiento en partida. Las 229 MT tienen evidencia histórica; las 19 dependen de política de versión/learnset y no se habilitan por ser seleccionadas.
- **Solape de diseño:** `hm05` ↔ `tm77` comparten `waterfall`. No se decidió eliminar uno: decidir de forma coordinada si existen dos libros que enseñen el mismo movimiento, o si se mantiene uno solo.
- **Formato libro:** **solicitud futura**, no se tocaron arte/UI. Definir `item_id→movimiento en perfil aprobado→tipo de movimiento→skin de libro` como capa de presentación, sin añadir 248 funciones ni transformar IDs persistidos. No usar el objeto histórico `scarlet_book` como libro MT; es otro ID.
- **Dependencias:** la base conjunta `38188cc` sigue **BASE_COMBINADA_SIN_CI**; falta prueba real completa sobre árbol W05. IA6 debe coordinar archivos compartidos (`field_item_service.gd`, `field_item_bag.gd`, `item_connections_v1.json`, `manifest.json`, tests existentes), reservados a otras familias o a integración central.
- **Solicitudes IA6 para ronda futura, NO ejecutadas:** aprobar perfil multiversión propio y reglas de MO/DT, decidir política de solapes, contrato de libro por tipo, andamiaje CI consolidado y pruebas de propietario/PC/guardado.

## 6. Autocontrol y estado final

El diff nuevo de W05 desde el checkpoint está restringido al LOTE_001 conservado más las cinco rutas expresamente permitidas de LOTE_002. Ningún PASS funcional nuevo de Godot, libro visual, consumo o persistencia se declara. No se realizó merge en árbitra, main ni V28; no se generó un workflow ni se ejecutó GitHub Actions. El LOTE_001 original permanece inmutable en contenido.

**ESTADO: LISTA_PARA_REVISION.** Próxima acción: revisión de IA6, validación Python en checkout y su CI consolidada; **no comenzar LOTE_003** sin encargo oficial nuevo.
