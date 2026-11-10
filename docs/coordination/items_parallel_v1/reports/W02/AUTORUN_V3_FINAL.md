# IA2/W02 — TANDA 03 FINALIZADA · Reparación efectiva de evolución

**Orden:** `docs/coordination/items_parallel_v1/IA6_AUTORUN.md` en la rama exclusiva `codex/calvo-items-20261109-w02-mints-integration`, con cola maestra `AUTONOMY_V1/QUEUE_W02_TANDA_03.md` en la árbitra.

**Balance auditado:** **10/10 hitos examinados · 9 certificados · 1 BLOQUEADO (optimización prohibida de Growth.plan)**. **0 objetos nuevos**, **1 defecto compartido corregido en W02**, pruebas/QA de las rutas nuevas positivas y negativas certificadas, **integración en la rama IA6: NO certificada**.

**CI funcional definitiva:** [#42890511612](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42890511612), `completed/success`, **SHA exacto `17df457b1320eec379ef78059cd14c4f6e5576e1`**. El ticket de IA6 y este cierre son commits documentales posteriores `[skip ci]`; no se atribuye la CI a sus SHA.

## Entregas en diez hitos

| Hito | Entrega | Resultado |
|---|---|---|
| 01 | `direct_red` — Red 42889749900: Eevee mintado Vaporeon pierde efectiva en PARTY y STORAGE | **CERTIFICADO** |
| 02 | `minimal_patch` — Unico arreglo compartido en EvolutionSystem.apply_evolution 51f6892f | **CERTIFICADO** |
| 03 | `level_evolution` — Bulbasaur Ivysaur nivel 16 Growth.plan, naturaleza, PP, PS, SaveV2 | **CERTIFICADO** |
| 04 | `field_item_evolution` — Fire Stone Eevee Flareon, destino falso rechaza, stock y rollback | **CERTIFICADO** |
| 05 | `unminted_baseline` — Eevee sin menta evolucionado conserva naturaleza original, IV, EV, PP, habilidad y SaveV2 | **CERTIFICADO** |
| 06 | `same_original_and_replacement` — Timid luego Adamant coincide con original, nueva menta, evolución | **CERTIFICADO** |
| 07 | `party_storage` — Identidad propia y ubicacion PARTY STORAGE sin duplicar ni perder | **CERTIFICADO** |
| 08 | `save_v2_legacy_invalid` — SaveV2 evolucionado, legacy sin naturaleza efectiva, corrupción rechazada sin publicar | **CERTIFICADO** |
| 09 | `growth_plan_interop` — Interoperabilidad funcional PASS; recálculo doble en Growth.plan protegido, ticket IA6 | **BLOQUEADO** |
| 10 | `ci_final` — CI 42890511612 SUCCESS sobre SHA 17df457b, campañas y pilotos preservados | **CERTIFICADO** |

## Evidencia roja y parche mínimo

- **CI roja de reproducción:** [42889749900](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42889749900), SHA `2deb011f5da8fd20bd385dbe5fdc60f1910de2bd`, `W02_AUTORUN_V3_GODOT FAIL checks=23`, con cuatro fallos específicos: naturaleza efectiva perdida y stats originales en evolución directa Eevee→Vaporeon tanto PARTY como STORAGE. Los demás contratos directos (identidad, IV/EV, PP, origen y no mutación de stock) continuaron en verde.
- **Parche mínimo funcional:** commit `51f6892f5086d81fa795278b6050b5bd1d3126e4` en `modules/creatures/progression/evolution_system.gd::apply_evolution`: 3 líneas añadidas / 1 sustituida en el diff, copiando `effective_nature_id` después de `nature_id` y escogiendo naturaleza efectiva para `StatCalculator.compute` cuando existe; si no, mantiene la original. No cambia ninguna otra función de EvolutionSystem.
- **Pruebas multirruta:** commit `17df457b1320eec379ef78059cd14c4f6e5576e1` mediante `tests/gameplay/parallel_items_w02_autorun_v3.gd`, `tests/tools/test_parallel_items_w02_autorun_v3.py` y fixture independiente e inmutable `tests/fixtures/parallel_items/w02_autorun_v3.json` (blob SHA `a769fbc5259b1a64025cf5b57f76a31d9b516ed4`). Veredictos finales exactos: `W02_AUTORUN_V3_PY PASS checks=26`, `W02_AUTORUN_V3_GODOT PASS checks=193`. Prueban evolución directa, piedra, nivel, sin menta, naturaleza original igual a efectiva, menta sustituida, propiedad PARTY/STORAGE, invalidación de objetivos, consumo, rollback, SaveV2 normal/legacy y corrupción rechazada.

## Conservación de regresiones y límites

En la misma CI final también quedan **SUCCESS** las etapas TANDA 02 (Godot 316), TANDA 01 (Godot 822), los pilotos MINT-L3, las 288 pruebas archivadas CAMPAÑA_005 sobre SHA histórico `9e2797a4972f22dbf14d5bc5f2d24bb212d29456` (Godot 16735), la revisión vigente CAMP005 (Godot 16878), CAMPAÑA_006 y las regresiones CAMPAÑA_004 (Godot 12282) y CAMPAÑA_003 (Godot 7306). Sin omisiones generales, `continue-on-error` ni cambios de fixture histórico para simular resultados pasados.

**No editados:** `CreatureInstance`, `StatCalculator`, SaveV2 central, `FieldNativeSave`, `FieldItemService`, `FieldGrowthEffects`, `Factory`, las reglas W04 `form_id`, otros archivos de evolución, `main`, V28, PR #118 o ramas ajenas.

## Hito 09: dependencia real fuera de permisos

El motor compartido ya conserva la naturaleza efectiva en todas las llamadas a `apply_evolution`. Pero `FieldGrowthEffects.plan` conserva una recuperación de la TANDA 02 que vuelve a ejecutar `c.recalculate_stats(...)` después de la evolución. La CI demuestra **interoperabilidad correcta**; no demuestra que el cálculo redundante se haya eliminado. La orden TANDA 03 prohíbe editar `FieldGrowthEffects`, por lo que ese subobjetivo queda **BLOQUEADO sin atribuir una reparación ficticia**.

Ticket escrito para IA6:
`docs/coordination/items_parallel_v1/reports/W02/AUTORUN_V3_IA6_GROWTH_DOUBLE_RECALC_TICKET.md`.

**Contrato W04/form_id futuro:** esta tanda no inventa ni copia un `form_id` no aprobado en `CreatureInstance`; los cambios futuros de forma requieren IA6/W04 y una validación integrada. No se afirma integración ya realizada.

**Cierre W02:** `TANDA 03 FINALIZADA`; 10/10 examinados, 9 certificados, 1 bloqueado, 0 objetos nuevos, integración IA6 NO. STOP hasta siguiente nota nueva.
