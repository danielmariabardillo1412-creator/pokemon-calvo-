# IA2/W02 — TANDA 04 FINALIZADA

**Asignación vigente:** `docs/coordination/items_parallel_v1/IA6_AUTORUN.md` — TANDA 04, rama exclusiva `codex/calvo-items-20261109-w02-mints-integration`; cola maestra `docs/coordination/items_parallel_v1/AUTONOMY_V1/QUEUE_W02_TANDA_04.md` en la rama árbitra.

**Resultado:** **10/10 hitos examinados y certificados · 0 bloqueados · 0 objetos nuevos · 1 reparación localizada de una doble evaluación · 9 hitos técnicos/QA y 1 de certificación/cierre.** **Integración en la rama árbitra IA6: NO realizada ni certificada.**

**CI final:** [#42922087890](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42922087890) — **completed/SUCCESS** sobre SHA funcional exacto **`7765c4bb6982662ae00695c8329c970e10931b4c`**. Esta acta y el CSV posterior son un commit documental con `[skip ci]`; no se atribuye esta CI al SHA de cierre documental.

## Manifestación de los diez hitos

| Hito | Entrega y evidencia | Estado |
| --- | --- | --- |
| 01 | `diagnose_old_duplicate` — Diagnóstico estructural y CI roja de duplicación explícita 42921793520 | **CERTIFICADO** |
| 02 | `compare_semantic_equivalence` — Godot compara payload completo de candidato con y sin fallback legacy en PARTY/STORAGE | **CERTIFICADO** |
| 03 | `remove_growth_recalc` — Growth.plan elimina solo fallback effective y recalculate_stats redundante; conserva HP delta | **CERTIFICADO** |
| 04 | `bulbasaur_ivysaur_minted` — Evolución real Bulbasaur a Ivysaur tras menta por nivel y SaveV2 | **CERTIFICADO** |
| 05 | `eevee_vaporeon_item` — Eevee a Vaporeon mediante Piedra Agua; rechazos sin consumo y persistencia | **CERTIFICADO** |
| 06 | `multi_level_context_rollback` — Caramelo Exp XL: varios niveles, decisiones de evolución, rechazo y rollback atómico | **CERTIFICADO** |
| 07 | `owner_party_storage_invariants` — PARTY/STORAGE: identidad propietario IV EV HP PP y sin duplicación | **CERTIFICADO** |
| 08 | `save_v2_normal_legacy_corrupt` — Snapshot SaveV2 actual legacy y alterado; carga corrupta denegada | **CERTIFICADO** |
| 09 | `w04_form_guard_not_integration` — Contrato estructural W04 sin form_id agregado ni escrito; integración futura no demostrada | **CERTIFICADO** |
| 10 | `regression_certification` — CI global verde 42922087890, T01-T03 y CAMP003-CAMP006 completas | **CERTIFICADO** |

## Prueba roja, reparación mínima y equivalencia

1. **Roja reproducida:** [CI #42921793520](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42921793520), SHA `4991f19905bac236ee1f49114bbacbbfd3b21da2`. El contrato Python rechazó el sitio `effective_before_evolution` y la segunda llamada a `recalculate_stats` en `modules/inventory/field_growth_effects.gd::plan` con `AssertionError: Growth.plan still repeats effective nature and recalculates`. Era una prueba estructural roja del cálculo duplicado, **no un fallo funcional demostrado en los datos del Pokémon**.
2. **Equivalencia de comportamiento:** runner nativo `tests/gameplay/parallel_items_w02_autorun_v4.gd`, fixture `tests/fixtures/parallel_items/w02_autorun_v4.json`. Compara candidatos serializados con y sin reproducción de la antigua recuperación en Pokémon con naturaleza original distinta de la efectiva y original coincidente con efectiva; ejecuta las evoluciones reales por nivel y por piedra, los rechazos, experiencia multinivel y SaveV2 en PARTY/STORAGE. El estado esperado original está fundamentado por la [CI previa de TANDA 03 #42890511612](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42890511612), SUCCESS sobre `17df457b1320eec379ef78059cd14c4f6e5576e1`.
3. **Reparación estricta:** commit `7765c4bb6982662ae00695c8329c970e10931b4c` cambia únicamente `modules/inventory/field_growth_effects.gd::plan`, quitando `effective_before_evolution`, la reasignación de `effective_nature_id` y la segunda llamada `c.recalculate_stats(...)`. Mantiene `EvolutionSystem.apply_evolution` (ya reparado en T03), la guarda nula, la elección de evolución y el cálculo `clampi(old_hp + c.stats.max_hp - old_max, 1, c.stats.max_hp)`. El diff de producción es **3 inserciones documentales y 7 eliminaciones**, sin editar otra función de Growth ni sistemas protegidos.
4. **Medición:** la ausencia del segundo sitio de recálculo queda comprobada por el contrato Python y equivalencia nativa. No se instrumentó `StatCalculator` ni se midió la ganancia de rendimiento; **no se afirma un porcentaje de aceleración**.

## Recibos exactos: TANDA 04 y regresiones

- `W02_AUTORUN_V4_PY PASS checks=23`.
- `W02_AUTORUN_V4_GODOT PASS checks=245`.
- `W02_AUTORUN_V3_GODOT PASS checks=193`.
- `W02_AUTORUN_V2_GODOT PASS checks=316`.
- `W02_AUTORUN_V1_GODOT PASS rows=10 positive=20 negative=10 level100=10 sequential=10 checks=822`.
- La puerta archivada CAMP005 conserva los 288 escenarios originales en SHA `9e2797a4972f22dbf14d5bc5f2d24bb212d29456`: `CAMP005_W02_GODOT PASS blocks=10 checks=16735` en revisión congelada y `CAMP005_W02_GODOT PASS blocks=10 checks=16878` en la actual.
- `CAMP004_W02_GODOT PASS blocks=10 checks=12282` y `CAMP003_W02_GODOT PASS blocks=10 checks=7306`. Las etapas CAMP006 también terminaron en SUCCESS dentro de la misma CI. No se han quitado regresiones ni convertido fallos en avisos.

## Contrato con W04 y límites de autorización

La fuente de `CreatureInstance` en esta rama no declaraba `form_id` al preparar la tanda. El test de T04 documenta ese límite y confirma que **no se han añadido/copiadο campos de forma regional**. No certifica integración futura de `form_id` ni sustituye las pruebas de IA6/W04.

**No editados:** `EvolutionSystem`, `CreatureInstance`, `StatCalculator`, `FieldItemService`, SaveV2 central, `FieldNativeSave`, factoría, W04 y su rama, `main`, V28 ni PR #118. No se hizo merge ni integración en la rama IA6. Solo cambian `Growth.plan` dentro del permiso, pruebas/fixtures, workflow y documentación W02.

**Cierre oficial W02:** `TANDA 04 FINALIZADA`. Parar hasta que IA6 publique una nueva tanda en la misma nota fija.
