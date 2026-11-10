# IA3/W03 — TANDA 04 FINALIZADA: Repeat Ball nativa, QA adversarial y Transformación

**Fecha:** 2026-11-10. **Rama exclusiva:** `codex/calvo-items-20261104-w03-camp006`.

## Contabilidad sin ambigüedad

- **Hitos examinados: 10/10.**
- **QA/harness certificados: 8/9** (filas 01, 03, 04, 05, 06, 07, 08, 09).
- **Bloqueado por contrato de arquitectura: 1/9** (fila 02, STORAGE no tiene límite global).
- **Cierre de CI/documentación: fila 10, SUCCESS**.
- **Objetos nuevos implementados: 0.** Repeat Ball ya era L3 en TANDA 03; esta tanda sólo amplía su QA.
- **Integración en rama IA6: NO**. No se realizó merge ni se modificaron `main`, V28, PR #118 o ramas ajenas.

**Código de cierre sometido a CI:** `b131fb008ac9e06ba06c63808e00d33ecd3e1178`.
**GitHub Actions:** [#42891930750](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42891930750), `completed/success`, mismo SHA de código.

El HEAD posterior puede contener sólo commits documentales de cierre `[skip ci]`, que **no tienen una CI nueva atribuible a su SHA**. La evidencia certificada corresponde exactamente al commit de código indicado, no a un SHA documental distinto.

## Matriz de aceptación y resultado

| Fila | Estado | Evidencia |
|---|---|---|
| 01 Dos batallas nativas, ledger y seed | **QA PASS** | `parallel_items_w03_repeat_native_v4.gd`: Master captura Pidgey con dueño real, se registra ledger, guardado y recarga, segundo encuentro usa Repeat. La semilla de captura se fija y se restaura. |
| 02 Party + STORAGE totalmente llena | **BLOQUEADO_CONTRATO** | `StorageRuleset.BOX_CAPACITY=30`, pero NO hay `MAX_BOXES`; `CreatureStorage.ensure_capacity_for` crea nuevas cajas. No se puede forzar una respuesta de almacenamiento globalmente lleno sin introducir una limitación que no existe en el juego. Ver `AUTORUN_V4_STORAGE_CONTRACT.md`. |
| 03 Captura fallida por RNG | **QA PASS** | `parallel_items_w03_repeat_native_v4_negatives.gd`: Mewtwo salvaje nivel 5, Poké Ball, semilla 6413. El fallo es la resolución real de la probabilidad, no un resultado fabricado. Descuenta exactamente una Ball en inventario staged, consume RNG y no añade ledger ni criatura. Se comprueba recuperación del estado staged. |
| 04 Inventario sin bola | **QA PASS** | Intento de Repeat sin stock en captura nativa: rechazo antes de RNG; snapshot nativo (incluye estado de batalla/PP), inventario real y ledger inalterados. Las pruebas independientes de SaveV2 continúan verdes. **No se añade prueba byte-a-byte del guardado por ese rechazo concreto.** |
| 05 Transformación antes de Repeat | **QA PASS** | `parallel_items_w03_repeat_native_v4_transform.gd`: un Mew usa Transform en el motor Showdown; el estado proyectado registra transformación real; Repeat captura Pidgey bonificada y la identidad persistente de Mew se conserva tras captura y recarga. |
| 06 Checkpoint durante combate | **QA PASS** | Guardado manual de batalla nativa activa antes de Repeat, recarga de snapshot idéntico, `_capture_rng.state`, ledger y cantidad exacta de Repeat conservados. |
| 07 Party llena, PC disponible | **QA PASS** | Seis criaturas en Party; Master y después Repeat enrutan una sola identidad por captura al almacenamiento. Se mantiene tamaño de Party=6; SaveV2 conserva propiedad única. |
| 08 Corrupción y legacy ledger | **QA PASS** | Guardado nativo con checksum recalculado y ledger duplicado es rechazado antes de publicar; identidad de collection, snapshot y RNG vivos persisten. El archivo original vuelve a cargar y el formato legado sin campo de ledger crea historial vacío. |
| 09 Repeat tras otra Ball, otra especie x1 | **QA PASS** | Captura Master de Pidgey crea ledger, Repeat posterior tras Transform aplica bonus ×3.5; nuevo encuentro Caterpie desde la tabla real del mapa (sin reiniciar colección), resolución Repeat nativa coincide con probabilidad neutra ×1. Se conserva gasto de una Ball. |
| 10 CI y regresiones | **CI PASS** | Ejecución #42891930750 valida el código actual, QA nueva, tests previos y SaveV2. Este documento y `AUTORUN_V4_PROGRESS.csv` completan la entrega. |

## Resultados medidos en los logs de la CI final

| Suite | Resultado |
|---|---|
| **V4 nativa: full-party/no-stock/continuidad** | PASS — 26 checks |
| **V4 nativa: fallo probabilístico y guardados hostiles** | PASS — 18 checks |
| **V4 nativa: Transform y especie distinta** | PASS — 20 checks |
| **Total V4 nuevo** | **64 checks PASS** |
| V3 nativa Repeat (conservada) | PASS — 26 checks |
| Native field/SaveV2/captura | PASS — 118 checks |
| CAMP006 W03 Python | PASS — 54 checks (1 dependencia diferida heredada) |
| CAMP006 W03 Godot | PASS — 78 checks |
| CAMP006 repelentes L3 | PASS — 65 checks |
| CAMP005 W03 Python | PASS — 169 checks |
| CAMP005 W03 Godot | PASS — 208 checks |
| Otros runners V1/V2 y SaveV2 adversarial | PASS en workflow |

La primera propuesta de workflow falló por YAML mal compuesto (#42889955290), reparado. El siguiente intento (#42891278307) evidenció que el test de especie distinta reiniciaba la campaña al cambiar la configuración, **no un fallo de Repeat**. El harness se corrigió para cambiar sólo la tabla de encuentros nativos sin destruir el ledger. La ejecución final #42891930750 pasó íntegra.

## Contrato pendiente de IA6

No se marca la fila 02 como funcional ni como prueba positiva de almacenamiento lleno. El producto define cajas autoexpandibles, no almacenamiento globalmente lleno. IA6 debe decidir si redefine este hito como «primera caja con 30 slots llenos, nueva caja creada al capturar» o si requiere primero una política global de capacidad distinta. W03 no modifica los módulos protegidos para simular esa condición.

**Siguientes pasos de IA6:** auditar y seleccionar cherry-picks de pruebas y workflow W03, mantener las regresiones de V3 y el código `showdown_adventure_session.gd::capture` previamente propuesto para integración. No hacer merge ciego. Publicar nueva `IA6_AUTORUN.md` sólo cuando IA6 revise esta entrega.

**TANDA 04 FINALIZADA — 10/10 examinados — 8 hitos QA PASS — 1 bloqueo de contrato — 1 cierre CI PASS — 0 objetos nuevos — integración IA6 NO. STOP.**
