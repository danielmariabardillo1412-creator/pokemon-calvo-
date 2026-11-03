# IA2/W02 — CAMPAÑA_005 / MICRO BLOQUE 02/10

**Rama exclusiva:** `codex/calvo-items-20261103-w02-camp005`. Autoridad: IA6 `CAMPAIGN_005_W02_GATE.md`, cola oficial `CAMPAIGN_005_W02_QUEUE_APPROVED.csv` fila 02, `campaigns/CAMP_005_W02.md`, reparación V5. **Sólo se trabaja la fila 02**, conservando los 18 escenarios del bloque 01 y las campañas 004/003.

## Trabajo añadido: 4 IDs, 24 escenarios, 72 variantes de ejecución diseñadas

| ID | Escenarios | Contrato nativo contrastado |
| --- | ---: | --- |
| `pp_max` | 6 | Eleva el PP máximo del movimiento seleccionado al tercer incremento (60 % de base), aumentando el PP actual por la diferencia de máximos sin restaurar el PP gastado. Casos de 0, 1 y 2 boosts; rechazos con 3 boosts, sin ranura y ranura inexistente |
| `hp_up` | 6 | +10 EV en **PS**, con tope de 252 por estadística y 510 global. Ensayos 0 EV, 248 EV (+4), 252 EV (rechazo), 508 EV globales (+2), 510 globales (rechazo) y ranura inesperada (rechazo) |
| `protein` | 6 | Misma política de +10 EV para **Ataque**; se verifica que no modifica las otras estadísticas y preserva propiedad/SaveV2 |
| `iron` | 6 | Misma política de +10 EV para **Defensa**; cubre topes individuales/globales, rechazo y reconstrucción de estadísticas |

La afinidad por estadística y las cantidades no se han supuesto por analogía: proceden de `modules/inventory/field_training_effects.gd`, `field_pp_boost_effects.gd` y `field_friendship_effects.gd`. Para vitaminas la amistad sube 5/3/2 según la amistad previa; el motor respeta el déficit de HP cuando se recalculan estadísticas. PP Máximos conserva PP ya gastados y afecta exclusivamente la ranura seleccionada.

El runner `tests/gameplay/parallel_items_w02_campaign_005.gd` ahora construye EV de origen sin violar el estado inicial, distribuye hasta 510 EV en otros atributos de forma válida y comprueba EV/HP/amistad/PP/IV/naturaleza/experiencia, consumo, propietario y SaveV2. Los modos de cada caso son `active` (PARTY con 2 objetos), `none` (PARTY sin objeto) y `reserve` (STORAGE con 2 objetos). Rechazos comprobados por igualdad de la instantánea integral anterior y posterior. Los recibos JSON/SHA256 están programados y sólo acreditan ejecución cuando Godot realmente los emita.

El validador `tests/tools/test_parallel_items_w02_campaign_005.py` contiene un **golden independiente de los 24 escenarios nuevos** y conserva los 18 del bloque 01; contrasta IDs y fuentes oficiales, el código de límites EV/PP y la amistad, además de **15 mutaciones adversariales del bloque 02**. No se ha reescrito el motor de producción ni se han tocado APIs compartidas.

## Commits publicados

- Fixture: `tests/fixtures/parallel_items/w02_campaign_005.json`, `c740f5281d868fd8689f2f8a09955793653536c2`.
- Godot: `tests/gameplay/parallel_items_w02_campaign_005.gd`, `55fdcc416e1c6fc4a0191d686b834e3b4cb58d43`, ajuste local de suma EV `ca7ed514ff8eefff8aea77907b94d7931f39510b`.
- Python: `tests/tools/test_parallel_items_w02_campaign_005.py`, `c9e38e271f8e3681d83d88eb9e85116269ae86fe` y `3dabb4ed6aaab4e9b09f37913dc840143213502e`.
- Progreso: `docs/coordination/items_parallel_v1/reports/W02/CAMP_005_PROGRESO.csv`, fila 02 `EN_CI_AUTOMATICA`, commit `24e65b3a481802763b71a0ae16240385dfc9d71f`.

## Estado de validación — separar publicación y CI

**Acumulado CAMP005 publicado:** 2/10 bloques, 8 IDs, 42 escenarios, 126 variantes previstas (18 + 24 casos × tres modos). Se han realizado verificaciones de consistencia estática y cotejos textuales con los módulos reales, pero **no hay todavía recibos de ejecución Godot/Python confirmados para los bloques 01–02 en los SHAs publicados**. No afirmar que la funcionalidad esté certificada.

El workflow dedicado `.github/workflows/parallel-camp005-w02-autoci.yml` se configura para importar en Godot 4.7, ejecutar Python y Godot de CAMP005, emitir y validar `CAMP005_W02_PY/GODOT PASS blocks=2 checks=M` y conservar logs durante siete días. Las consultas del conector para `workflow_runs` asociadas a commits por `push` no siempre retornan esos runs; un resultado vacío **no demuestra** que no se ejecutaron ni que pasaron. La última CI CAMP004 previa es la indicada en el gate de IA6 [#41589286005](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41589286005), pero no sustituye pruebas de CAMP005.

**Regresiones:** los archivos CAMP004/CAMP003 quedan intactos y su CI se exige según gate en hitos 05/10 y cambios de producción propios. Integración global, GPU y UI no verificadas en este microbloque.

## Siguiente `p`

Revisar el resultado de CI de CAMP005 sobre SHA actual; corregir solo fallos propios según V5 sin debilitar aserciones. Ejecutar **sólo el bloque 03** de la cola autorizada: `calcium;zinc;carbos;exp_candy_xs`. Si una reparación afecta API global o políticas, elevar a IA6. No ejecutar 04 sin nueva orden.
