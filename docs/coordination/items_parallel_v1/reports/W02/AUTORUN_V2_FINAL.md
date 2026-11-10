# IA2/W02 — AUTORUN V2 · TANDA 02 FINALIZADA

**Rama exclusiva:** `codex/calvo-items-20261109-w02-mints-integration`. **Autorización:** `docs/coordination/items_parallel_v1/IA6_AUTORUN.md` (TANDA 02) y `AUTONOMY_V1/QUEUE_W02_TANDA_02.md` en rama árbitra.

**Balance: 10/10 hitos examinados y cerrados, 9 hitos con funcionalidad real L3 comprobada, 0 bloqueados, 1 hito final de CI/documentación (no es un objeto nuevo).**

**CI funcional final:** [#42869765262](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42869765262) **completed / SUCCESS** sobre SHA exacto `ba2af91278a6e79df30532b66855f7ccdb4278d8`. Los commits posteriores de ticket y acta son solo documentales `[skip ci]`; no se les atribuye esa CI.

## Manifiesto de 10 hitos

| Fila | Hito | Estado | Funcional L3 |
|---|---|---|---|
| 01 | `mint_rare_candy_red` — Rojo nativo y verde posterior; rechazo antes del arreglo sin gasto | CERTIFICADO | Sí |
| 02 | `growth_nature_validation` — Growth.validation_error usa naturaleza efectiva cuando existe | CERTIFICADO | Sí |
| 03 | `exp_candies_after_mint` — XP XS y XL; nivel100 PS PP SaveV2 | CERTIFICADO | Sí |
| 04 | `growth_move_evolution` — Razor Leaf reemplazo y Bulbasaur→Ivysaur tras menta; corrección Growth.plan | CERTIFICADO | Sí |
| 05 | `mint_mochi_red` — Rojo Muscle Mochi; Swift Mochi positivo desde mochila tras corrección | CERTIFICADO | Sí |
| 06 | `mochi_nature_validation` — Mochi.validation_error reconoce naturaleza efectiva | CERTIFICADO | Sí |
| 07 | `fresh_start_mochi` — Fresh Start reinicia EV reales y persiste SaveV2 | CERTIFICADO | Sí |
| 08 | `protein_carbos` — Protein y Carbos recalculan EV estadística y amistad | CERTIFICADO | Sí |
| 09 | `five_step_sequence` — Menta crecimiento mochi vitamina menta, PARTY/STORAGE, rollback y SaveV2 | CERTIFICADO | Sí |
| 10 | `final_regressions` — CI completa, pruebas archivadas y regresiones, informe único | CERTIFICADO | No; CI/cierre |

## Evidencia de integración

- **Reproducción roja real:** CI [42867971285](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42867971285), SHA `7b21c0de66f7b27fad943ebd75f3ce3dad489685`, falló como era esperado en PARTY y STORAGE al usar menta seguida de `rare_candy` o `muscle_mochi`; ambos fueron rechazados y no gastaron la unidad. Swift Mochi utiliza el mismo validador, pero **no se obtuvo una reproducción roja nativa independiente para Swift**; su caso positivo se comprobó después.
- **Corrección acotada** `modules/inventory/field_growth_effects.gd::validation_error` y `modules/inventory/field_mochi_effects.gd::validation_error`: validan `nature_id` original y `effective_nature_id` opcional; el oráculo de stats usa la efectiva cuando existe. Commit `e8801e857fa6c1050b0a57413e9fa0259b1c8237`.
- **Evolución por crecimiento**: prueba roja en CI [42868990430](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42868990430) localizó pérdida de naturaleza efectiva en `EvolutionSystem.apply_evolution` para Bulbasaur→Ivysaur. Reparación estrictamente local `FieldGrowthEffects.plan` en commit `6f6ed9552e34b5bfead70d33a4638603e4c323db`: restaura naturaleza efectiva y recalcula el candidato sin modificar el motor general; prueba de movimiento Razor Leaf y evolución a nivel16, estado, PP, PS y SaveV2 en PARTY/STORAGE.
- **Mochi y vitaminas:** `muscle_mochi`, `swift_mochi`, `fresh_start_mochi`, `protein` y `carbos` prueban efectos positivos reales tras menta, consumo, stats según naturaleza efectiva, EV, amistad, rechazo y persistencia. No se modificó `FieldTrainingEffects.apply` porque el contrato real pasó.
- **Secuencia acumulada L3:** menta → `rare_candy` → `muscle_mochi` → `carbos` → segunda menta, PARTY y STORAGE, validación de identidad, naturaleza original, PS, IV, EV, PP, bolsa, SaveV2, rechazo de objetivo incorrecto y repetición sin gasto.

**Recibos nuevos exactos de la CI final**: `W02_AUTORUN_V2_PY PASS rows=10 checks=23` y `W02_AUTORUN_V2_GODOT PASS checks=316`. Suite `tests/tools/test_parallel_items_w02_autorun_v2.py`; runner `tests/gameplay/parallel_items_w02_autorun_v2.gd`; fixture `tests/fixtures/parallel_items/w02_autorun_v2.json`.

## Regresiones preservadas

La misma CI final certifica MINT-L3 piloto01 y 02, TANDA01, CAMP006 bloques 01–10, CAMP005 archivado y vigente, CAMP004 y CAMP003. En particular:

- `W02_MINT_PILOT02_20261109_GODOT PASS checks=223`.
- `W02_AUTORUN_V1_GODOT PASS rows=10 positive=20 negative=10 level100=10 sequential=10 checks=822`.
- `W02_CAMP005_FROZEN PASS sha=9e2797a4972f22dbf14d5bc5f2d24bb212d29456 scenarios=288` y `CAMP005_W02_GODOT PASS blocks=10 checks=16735` en congelada.
- `CAMP005_W02_GODOT PASS blocks=10 checks=16878` en revisión actual con whitelist.
- `CAMP004_W02_GODOT PASS blocks=10 checks=12282`.
- `CAMP003_W02_GODOT PASS blocks=10 checks=7306`.

## Dependencia compartida detectada para IA6

**Ticket:** `docs/coordination/items_parallel_v1/reports/W02/AUTORUN_V2_EVOLUTION_SHARED_SEAM_TICKET.md`. La función general `modules/creatures/progression/evolution_system.gd::apply_evolution` no traslada `effective_nature_id` al nuevo Pokémon; la reparación de W02 solo cubre la evolución dentro de `FieldGrowthEffects.plan`. IA6 debe auditar las demás rutas de evolución, especialmente ítems evolutivos y W04. No contabilizar este comportamiento global como arreglado.

**Integridad de permisos:** no se ha editado `main`, V28, PR #118 ni ramas ajenas; no se han cambiado `CreatureInstance`, `StatCalculator`, `ProgressionSystem`, SaveV2 central, `FieldNativeSave`, `FieldItemService`, `FieldItemBag`, `EvolutionSystem`, EXP Share o motor compartido.

**Estado final:** `TANDA 02 FINALIZADA`; STOP hasta que IA6 publique nueva tanda. La TANDA01 se conserva con su CI original sin repetición ni recuento duplicado.
