# IA2/W02 → IA6 — Dependencia de evolución compartida tras menta

**Detectado:** 2026-11-10. **Ámbito:** AUTORUN TANDA 02, hito 04. **Reproductor nativo:** `tests/gameplay/parallel_items_w02_autorun_v2.gd::_probe_growth_choices`; run [42868990430](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42868990430) en `8c8de3aa59ef0f8f02e853cbacf5bf4f43eef29b` falló exclusivamente en el caso de evolución Bulbasaur nivel15→Ivysaur nivel16 tras `adamant_mint` (PARTY y STORAGE); aprendizaje de Razor Leaf/sustitución de PP y demás casos pasaron.

## Causa demostrada en código
`modules/creatures/progression/evolution_system.gd::apply_evolution` crea un `CreatureInstance` nuevo, conserva `nature_id` y recalcula `StatCalculator.compute(..., new_creature.nature_id, ...)`, pero **no transfiere `effective_nature_id`**. El resultado de esa ruta compartida pierde el efecto de la menta. Este módulo pertenece a IA6 y permanece intacto.

## Reparación local autorizada W02
`modules/inventory/field_growth_effects.gd::plan`, rama del candidato de evolución después de `EvolutionSystem.apply_evolution`, guarda `effective_nature_id` del candidato original, lo restituye en el evolucionado, recalcula stats según la efectiva y preserva déficit de HP. Se publicó en `6f6ed9552e34b5bfead70d33a4638603e4c323db`. La transacción original de `FieldItemService.use_growth_item` permanece sin tocar. Esta reparación **solo cubre la evolución por objetos de crecimiento de W02**, no todas las llamadas a EvolutionSystem.

## Acción pendiente IA6
Auditar/autorizar preservación de `effective_nature_id` y stats resultantes en `EvolutionSystem.apply_evolution` para otras rutas (ej. evolución directa con objeto desde inventario, flujos W04 y progresión fuera de FieldGrowthEffects). Conservar naturaleza original y SaveV2. Probar ambas rutas con Pokémon realmente evolucionado, PS, identidad, PP y estado. No asumir que la reparación local resuelve la mecánica general.

**CI de validación del seam W02:** pendiente de veredicto final en la tanda. No atribuir PASS global a este ticket hasta RUN completed/success sobre su SHA.
