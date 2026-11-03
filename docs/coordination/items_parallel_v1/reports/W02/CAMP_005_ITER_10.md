# IA2/W02 — CAMPAÑA_005 · BLOQUE 10/10 Y CIERRE DE ENTREGA

**Autorización:** IA6, `CAMPAIGN_005_W02_GATE.md`, `CAMPAIGN_005_W02_QUEUE_APPROVED.csv` (fila10), `campaigns/CAMP_005_W02.md`, `AUTONOMOUS_REPAIR_V5.md`. **Rama exclusiva:** `codex/calvo-items-20261103-w02-camp005`. Se preservaron `main`, V28, PR118, rama árbitra, ramas W01/W03/W04/W05, APIs compartidas, producción, CAMP004 y CAMP003. No se ha hecho merge.

## Bloque 10: cuatro mentas todavía sin ejecutor

| ID | Naturaleza prevista | Modificadores de reglas base | Estado |
|---|---|---|---|
| `brave_mint` | Audaz | +Ataque, −Velocidad | `DEPENDENCIA_DOCUMENTADA` |
| `quiet_mint` | Mansa | +Ataque Especial, −Velocidad | `DEPENDENCIA_DOCUMENTADA` |
| `impish_mint` | Agitada | +Defensa, −Ataque Especial | `DEPENDENCIA_DOCUMENTADA` |
| `relaxed_mint` | Plácida | +Defensa, −Velocidad | `DEPENDENCIA_DOCUMENTADA` |

**32 escenarios nuevos**, ocho por menta, ejecutables en tres modos de propiedad (**96 variantes programadas**):
1. Pokémon con naturaleza original `hardy`.
2. Pokémon con la misma naturaleza que la solicitada.
3. Pokémon con naturaleza original distinta.
4. Amistad 0.
5. Amistad 254.
6. Ranura de movimiento 0 no solicitada.
7. Ranura de movimiento 1 no solicitada.
8. Nivel 100.

**Resultado contractual del motor actual, no una aprobación runtime:** `accepted=false`, `status=DEPENDENCY_MISSING`, `reason=field_effect_not_connected`. El runner existente `tests/gameplay/parallel_items_w02_campaign_005.gd` instancia efectivamente la naturaleza inicial indicada por `spec.nature`, llama a `FieldItemService.use_item` y exige rechazo sin alterar la identidad, naturaleza, IV, EV, PP, estadísticas, amistad, experiencia, inventario, ubicación PARTY/STORAGE y SaveV2. Las tres variantes por caso son `active`, `none` y `reserve`.

## Evidencia de la dependencia

- Las mentas del bloque 10 no están excluidas en `config/item_selection_v1.json`.
- Ninguno de los IDs está respaldado por `modules/inventory/field_item_service.gd`, `field_item_effects.gd`, `field_growth_effects.gd` ni `field_mochi_effects.gd`. Sin ruta, `FieldItemService.use_item` devuelve expresamente `DEPENDENCY_MISSING` / `field_effect_not_connected`.
- `ProgressionRuleset.NATURE_MODIFIERS` sí registra las cuatro naturalezas, pero `CreatureInstance` conserva solo `nature_id` y calcula estadísticas desde ella. No tiene `effective_nature_id` persistente. La tabla de naturalezas **no implementa una menta**.
- Cambiar `nature_id` directamente falsificaría la mecánica de menta de generaciones modernas, que altera la distribución estadística sin reescribir la naturaleza original. W02 no modifica ese dominio sin coordinación IA6.

La misma dependencia afecta a las siete mentas de bloques 08–09. **Total de mentas pendientes de implementar: 11**.

## Contratos publicados en GitHub

- Fixture acumulada `tests/fixtures/parallel_items/w02_campaign_005.json`: commit `f5517796764ffad0ec11b579b29bdd5369f640f7`. Se añadió únicamente bloque10 con 32 casos, conservando 01–09.
- Validador `tests/tools/test_parallel_items_w02_campaign_005.py`: golden independiente `EXPECTED_10` (commit `e3f3f855894c524c463611b57aba020f62fe44c0`); comprobación contra cola/fuentes (commit `5be713faac297825dd1065f1470e4ba077a6aca1`); verificaciones nativas del estado de mentas, tabla de naturaleza, rechazo atómico y SaveV2 (commit `1026678370774d896d6559cb6c549f79d5b76065`); **16 mutaciones adversariales adicionales** (commit `ddf6fd8cab3c055e756b51a2ecbd8444b2631e47`).
- Progreso `docs/coordination/items_parallel_v1/reports/W02/CAMP_005_PROGRESO.csv`: fila10 `DEPENDENCIA_DOCUMENTADA`, `ci_run=AUTOMATICA_PENDIENTE`; commit `82f797ff8d704f77fadea1dd11b5ff85466deb18`.
- Runner Godot propio no requirió cambio en fila10: reutiliza el contrato positivo/negativo de bloques previos, `mint_dependency`, con naturaleza original explícita, ausencia de mutación y SaveV2. No se tocó producción.

## Cierre de campaña y límites de certificación

**CAMPAÑA_005_FINALIZADA — entrega documental y pruebas publicadas en la rama W02, no certificación funcional.**

| Indicador | Resultado |
|---|---:|
| Bloques de cola publicados | **10/10** |
| Objetos asignados únicos | **40** |
| Escenarios acumulados | **288** |
| Variantes programadas en tres modos | **864** |
| Objetos con rutas positivas de motor identificadas | **29** |
| Mentas sin ruta funcional ni naturaleza efectiva persistente | **11** |
| Regresiones CAMP003/CAMP004 verificadas con logs del hito 10 | **0 evidencias recuperadas** |

Los diez golden independientes coinciden con los diez bloques de fixture. Se revisaron estáticamente unicidad, cola, códigos fuente y oráculos. **No equivale a ejecutar realmente Python/Godot** y no debe escribirse `CI_PASS_VERIFICADO` sin un run verificable asociado al SHA del cierre. El workflow existente `.github/workflows/parallel-camp005-w02-autoci.yml` requiere ejecutar Python/Godot de CAMP005 y, en hito10, Python/Godot de CAMP004 y CAMP003; emitir recibos `CAMP005_W02_PY/GODOT PASS blocks=10` y regresiones `CAMP004_W02_PY/GODOT PASS blocks=10`, `CAMP003_W02_PY/GODOT PASS blocks=10` sobre el HEAD correcto. El conector de runs por commit ha devuelto listas vacías en esta campaña, lo que no prueba PASS, FAIL ni ausencia de ejecución. No se dispone de test GPU/UI, prueba integral del juego o integración a `main`.

**Traspaso IA6:** verificar los seis recibos del hito10 y sus SHA/logs; reparar fallos propios bajo V5 sin debilitar las pruebas; coordinar con responsable de dominio el diseño de `effective_nature_id`, consumo y transacción de mentas, recálculo estadístico, combate y persistencia SaveV2. Tras implementar la ruta, rehacer los contratos *positivos* de las once mentas y ejecutar regresiones acumulativas. No confundir sus actuales rechazos seguros con funcionalidad completada.

**STOP:** la cola IA2/W02 CAMPAÑA_005 está agotada. No empezar CAMPAÑA_006, no hacer merges y no tocar otras ramas sin una orden/autorización nueva.
