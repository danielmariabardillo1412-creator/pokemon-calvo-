# IA2/W02 — AUTORUN V1 · TANDA 01 FINALIZADA

**Fecha de registro:** 2026-11-10. **Autoridad:** IA6 AUTONOMY_V1 (orden permanente en la rama propia `docs/coordination/items_parallel_v1/IA6_AUTORUN.md`, protocolo `AUTONOMY_V1/README.md` en la rama árbitra).

**Resultado:** **10/10 filas examinadas · 10/10 efectos L3 reales certificados · 0 bloqueadas · 0 diferidas**. La tanda cierra exclusivamente estos diez IDs. **CI final [#42730263746](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42730263746) `completed/success` sobre `f8168c2b5cdb2dc74bc2820d94cc59e7bc7be19c`**. Esta acta y el CSV se publican posteriormente como commit documental `[skip ci]`; no se atribuye su SHA documental a la ejecución funcional.

## Manifiesto de las diez mentas
| Fila | ID | Naturaleza efectiva | Cambios estadísticos | Resultado |
| --- | --- | --- | --- | --- |
| 01 | `hasty_mint` | `hasty` | +speed / −defense | **L3 CERTIFICADO** |
| 02 | `lax_mint` | `lax` | +defense / −special_defense | **L3 CERTIFICADO** |
| 03 | `relaxed_mint` | `relaxed` | +defense / −speed | **L3 CERTIFICADO** |
| 04 | `jolly_mint` | `jolly` | +speed / −special_attack | **L3 CERTIFICADO** |
| 05 | `bold_mint` | `bold` | +defense / −attack | **L3 CERTIFICADO** |
| 06 | `calm_mint` | `calm` | +special_defense / −attack | **L3 CERTIFICADO** |
| 07 | `careful_mint` | `careful` | +special_defense / −special_attack | **L3 CERTIFICADO** |
| 08 | `brave_mint` | `brave` | +attack / −speed | **L3 CERTIFICADO** |
| 09 | `quiet_mint` | `quiet` | +special_attack / −speed | **L3 CERTIFICADO** |
| 10 | `impish_mint` | `impish` | +defense / −special_attack | **L3 CERTIFICADO** |

**Cadena auténtica de producción y guardado:** `FieldItemService.use_item` → `FieldMintEffects.apply` → `CreatureInstance.effective_nature_id` → `StatCalculator.compute` → actualización transaccional de inventario/propiedad → SaveV2. Todas las naturalezas existen en `ProgressionRuleset.NATURE_MODIFIERS` y sus IDs no están excluidos en `config/item_selection_v1.json`.

**Pruebas nativas de esta tanda:** `tests/gameplay/parallel_items_w02_autorun_v1.gd`, fixture independiente `tests/fixtures/parallel_items/w02_autorun_v1.json`, contrato `tests/tools/test_parallel_items_w02_autorun_v1.py`. Recibos exactos en #42730263746:
- `W02_AUTORUN_V1_PY PASS rows=10 historical=288 promoted=82 checks=95`.
- `W02_AUTORUN_V1_GODOT PASS rows=10 positive=20 negative=10 level100=10 sequential=10 checks=822`.

**Cobertura funcional:** diez naturalezas con incrementos/disminuciones estadísticos exactos e independientes, veinte aplicaciones PARTY/STORAGE, diez rechazos sin stock, diez casos nivel 100 y diez sustituciones de una menta anterior; naturaleza original inmutable, naturaleza efectiva recalculada, misma identidad y propiedad, HP/PS, IV, EV, PP, experiencia, consumo una unidad, no-effect repetido, rechazo de estado KO o batalla temporal o stats incoherentes, rollback, persistencia SaveV2 vigente/legacy y carga corrupta denegada. Los tests del piloto 02 también siguen `PASS checks=39` Python y `PASS checks=223` Godot.

## Migración versionada, sin reescribir la historia
El fixture original CAMPAÑA_005 de **288 casos** se conserva exactamente con blob Git SHA `020a147f67294a139c4ff404cccfefe1c38702ac` (igual en SHA congelado y HEAD actual). La puerta archivada ejecuta los 288 casos en `9e2797a4972f22dbf14d5bc5f2d24bb212d29456`: `W02_CAMP005_FROZEN PASS ... scenarios=288`; `CAMP005_W02_GODOT PASS blocks=10 checks=16735`.

La puerta actual ejecuta los 288 casos **sin excluir escenarios** y migra 82 casos de `mint_dependency` por una whitelist exacta de las 3 mentas del piloto02 y las 8 de esta tanda con negativos históricos; `hasty_mint` y `lax_mint` no figuraban entre esas dependencias CAMPAÑA_005. Se prueba resultado positivo o rechazo actual específico de slot/stock/naturaleza idéntica. `CAMP005_W02_GODOT PASS blocks=10 checks=16878`. El script actual adapta además `relaxed_mint` y un rechazo por objetivo inválido en recuperación CAMP006, mientras las pruebas antiguas y recibos históricos permanecen archivados.

## Recuperación acumulativa y regresiones
La CI final comprueba **SUCCESS en todas las etapas**: MINT-L3 piloto01 y piloto02, CAMP005 Python/Godot archivada y actual, CAMP006 recuperación 01–05, bloques 06–10, CAMPAÑA_004 y CAMPAÑA_003. Recibos finales: `CAMP004_W02_GODOT PASS blocks=10 checks=12282` y `CAMP003_W02_GODOT PASS blocks=10 checks=7306`. No se han introducido `continue-on-error`, `|| true`, pruebas silenciadas o exclusión general de tests.

**Commits funcionales/técnicos destacables:** `a4cd4102` (migración inicial CAMP005), `36c1705b` (diez mentas y checkpoint), `72acfd5a` (validadores históricos versionados), `668f6648` (runner nativo/fixtures/contrato propios), `04abd188` (dos puertas CI congelada/actual), `f8168c2b` (recuperación CAMPAÑA_006 y SHA global certificado).

**Protecciones:** ningún cambio a `main`, V28, PR #118, ramas de otras IA, `StatCalculator`, `ProgressionSystem`, `CreatureInstance`, SaveV2 central, `FieldNativeSave`, `FieldItemBag`, `FieldGrowthEffects`, `FieldMochiEffects` ni motor compartido.

## Dependencias fuera de esta tanda
`exp_share` permanece pendiente de IA6 para reparto de XP a no participantes; no se cuenta como objeto funcional de esta tanda. Otros consumidores de naturaleza efectiva en Growth/Mochi y validación nativa de mundo siguen siendo propiedad de IA6. **Estos pendientes no bloquean el cierre de las diez mentas autorizadas**.

**Estado final W02: `TANDA 01 FINALIZADA`. STOP hasta que IA6 publique la siguiente tanda en `IA6_AUTORUN.md`.**
