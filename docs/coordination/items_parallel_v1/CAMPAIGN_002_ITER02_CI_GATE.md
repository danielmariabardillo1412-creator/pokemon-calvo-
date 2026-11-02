# IA6 — GATE de CI CAMP_002 / ITER_02 para W01, W02, W03 (2026-11-02)

**Resultado real:** [Actions #41493879869](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41493879869) `completed/success`, SHA staging exacto `6a5562dd97225d86fd9b2fb994b247aadc33f98e` sobre `codex/calvo-items-20261102-ci-camp002-iter02`. Godot 4.7, simulador nativo Node, recibos Python; tres pasos W01/W02/W03 y veredicto general SUCCESS. No hay certificación de ITER_03, visual/GPU ni de bolas nuevas implementadas.

- **W01, 02/03:** 7 escenarios, 10 ejecuciones y 30 variantes; `W01_CAMP002_GODOT PASS checks=687 runs=10 errors=0`, `W01_CAMP002_NATIVE_EVIDENCE_PASS runs=10 variants=30`. Corrección exclusivamente del runner: `OUT` renombrado a `W01_C002_OUTPUT` por conflicto de nombre heredado de `item_field_effects_v4.gd`. No cambiar expectativas ni efectos, y ningún código de producción se ha alterado.
- **W02, 02/03:** 4 bayas (Sitrus, Lum, Leppa, Figy), 9 escenarios y 3 variantes; `PARALLEL_ITEMS_W02_CAMP002 PASS checks=800 cases=9`, fixture/unittest/recibo Python PASS. Tras cambiar `nature_id` en los casos Figy, el test debe llamar al método ya existente `own.recalculate_stats(catalogs.species(own.species_id), ProgressionRuleset.new())` **antes de abrir batalla**: la prueba anterior fallaba al importar stats `game=236 native=212` porque las estadísticas no se recalcularon tras asignar naturaleza Modesta. Se mantienen todas las aserciones; la lógica de Baya Higog no se cambió.
- **W03, 02/03:** estática `tests=11` PASS y Godot `CAMP_002_W03_NEGATIVE` 37 comprobaciones, 0 errores, `scope=NEGATIVE_CURRENT_BEHAVIOR_ONLY`. Dusk/Repeat/Dive **todavía no implementadas**; contextos de oscuridad, Pokédex y submarino no autorizados. No confundir PASS de negativos con multiplicadores jugables.

**Integración:** IA6 copia al árbol árbitra estos 8 archivos exactos del staging verificado. Ramas W01/W02/W03 originales **no modificadas** ni rebasadas. Los archivos de pruebas de las W quedan obsoletos respecto a **dos** correcciones:
- W01 sincronizar `tests/gameplay/parallel_items_w01_campaign_002.gd` desde árbitra, blob `cc9fb835e5e999e991e1aa5ac58056ec5855da97`.
- W02 sincronizar `tests/gameplay/parallel_items_w02_campaign_002.gd` desde árbitra, blob `73171d57101dab742bb9a27ce8a3027198b639de`, que incorpora tanto ajuste numérico ITER_01 como recálculo de stats de naturaleza ITER_02.

**Continuación:** W01/W02 pueden recibir **un único `p` para ITER_03** siempre que empiecen leyendo este gate, sincronizando solo el blob indicado en su rama exclusiva, y comprueben que no existe conflicto con sus reportes. W03 también puede recibir `p` para su auditoría de contrato ITER_03, nunca para implementar producción. Si una sincronización falla, STOP, bloquear y avisar IA6.

W04 CAMP_001 03/03 entregada desde relevo, pendiente de CI de SaveV2. W05 CAMP_002 02/03 preparada, pendiente de CI de 6 MT nuevas. Su CI independiente [#41537680311](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41537680311) estaba en marcha cuando se redacta esta acta. **No enviar `p` a W04 (ya cerrada) ni a W05 (esperando CI).**

**Protección:** `main`, V28, PR #118, guardados reales, ramas de trabajadoras y producción intocables. El PASS es acotado a pruebas y SHA indicados.
