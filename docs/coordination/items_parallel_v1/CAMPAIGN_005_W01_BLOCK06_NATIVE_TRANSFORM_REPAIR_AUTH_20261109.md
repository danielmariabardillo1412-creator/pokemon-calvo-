# IA6 — W01 CAMP005 bloque 06 · reparación nativa Transformación (2026-11-09)

**Estado: PERMISO DIAGNÓSTICO Y REPARACIÓN LIMITADO.** La rama W01 actual es `codex/calvo-items-20261104-w01-camp005`. Los bloques 01–05 están CI PASS, **el 06 NO**. Las tres ejecuciones #42233251445, #42235777234 y #42252938911 fallaron; Python 06 pasa, Godot 06 da tres errores de Ditto transformado en modos active/none/reserve y uno agregado. La última traza devuelve literalmente `Cannot read properties of undefined (reading 'id')` desde backend nativo, no una regla de combate que prohíba `switch 2`. Ver `reports/W01/CAMP_005_BLOCK06_SHARED_DEPENDENCY.md` y `CAMP_005_ITER_06.md`.

## Autorización IA6 puntual

W01 puede, **solo en su rama**, añadir un **reproductor aislado** del backend que capture stack JS completo, estado de turnos, serialización `battle.toJSON()`, `Battle.fromJSON()`, `b.restart()` y elección `switch 2` después de Transformación. No imprimir información sensible; conservar los 54 escenarios y 3 modos. Comparar A (snapshot intermedio transformado y restauración), B (prepare/choose switch), C (batalla equivalente sin Transform) con misma semilla.

Una vez demostrado el origen exacto del `undefined.id`, IA6 concede **permiso condicionado** para un parche **mínimo y aislado** a `modules/battle/backends/showdown/native_engine.cjs` exclusivamente donde el reproductor pruebe que falla la reconstrucción del estado. **No tocar** balance/movimientos, `ShowdownBackend`, `ShowdownAdventureSession`, SaveV2, clases de criatura, `main`, V28 ni ramas ajenas. Si la reparación requiere otro archivo compartido, **STOP y ticket de IA6** con stack, diff propuesto y test rojo. Si es imposible restaurar un snapshot válido, no simular éxito ni cambiar expectativas para ocultarlo.

## Puertas de aceptación

1. Reproductor pasa en el bug corregido y sigue rechazando snapshots malformados (no `try/catch` que trague el error). Preservar invariantes de identidad, PP, PS, objetos, especies, forma, posición, elección y determinismo RNG/semilla.
2. Godot CAMP005 W01 **bloques 01–06 acumulativos** en los tres carriles pasa; test específico de Metal Powder sin Transformación positivo y DESPUÉS de Transformación sin bonus; DeepSeaScale y DeepSeaTooth positivos siguen pasando.
3. Pruebas de snapshot y SaveV2 del turno intermedio y cambio legal, no sustituir el caso por un checkpoint posterior si eso elude la avería. Regresión completa CAMP004 y tests nativos existentes de restauración/turnos tras modificación de `modules/`.
4. CI de la propia rama `completed/success` sobre SHA del arreglo + recibos reales. Solo entonces declarar 06 PASS y autorizar 07. Si requiere cambio amplio de motor o reglas de partida, dejar 06 pendiente y solicitar nueva autorización, sin `p` indefinidas.

Este permiso no supone revisión de integración ni aprobación de merge. El trabajo en producción de W01 queda pendiente de revisión de IA6 antes de incorporar a rama compartida.
