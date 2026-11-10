# IA2/W02 → IA6 · TANDA 03: redundancia Growth.plan después de repararse EvolutionSystem

**Rama exclusiva W02:** `codex/calvo-items-20261109-w02-mints-integration`. Fecha: 2026-11-10.

## Causa exacta
La TANDA 02, en `modules/inventory/field_growth_effects.gd::plan`, añadió la recuperación temporal de naturaleza efectiva después de `EvolutionSystem.apply_evolution` porque este último perdía `effective_nature_id`. En TANDA 03, IA6 autorizó reparar **solo** `modules/creatures/progression/evolution_system.gd::apply_evolution`; el motor general ya copia `new_creature.effective_nature_id = creature.effective_nature_id` antes de `StatCalculator.compute` con la naturaleza efectiva.

En el código actual `FieldGrowthEffects.plan` todavía ejecuta lo siguiente después de que el motor general haya calculado las stats:
```gdscript
var effective_before_evolution: StringName = c.effective_nature_id
c = EvolutionSystem.apply_evolution(c, StringName(choice), catalogs, ProgressionRuleset.new())
if c == null: return deny("evolution_failed")
if effective_before_evolution != &"":
    c.effective_nature_id = effective_before_evolution
    c.recalculate_stats(catalogs.species(c.species_id), ProgressionRuleset.new())
```
Esto es **redundante** para los Pokémon con menta. Las pruebas TANDA 03 demuestran que el resultado actual no queda incoherente, pero no eliminan la segunda evaluación ni prueban coste cero.

## Límite de permiso y acción IA6 requerida
La orden TANDA 03 **prohíbe editar FieldGrowthEffects**. No se ha modificado ese archivo. Para quitar el doble cálculo, IA6 debe autorizar un cambio mínimo en `FieldGrowthEffects.plan`, o realizarlo directamente en su rama, eliminando exclusivamente el recálculo de reserva y conservando la elección evolutiva, el ajuste de PS y las pruebas históricas.

**Contrato esperado:** para Eevee→Vaporeon por piedra y Bulbasaur→Ivysaur por nivel tras menta, naturaleza original intacta, naturaleza efectiva idéntica a la previa, estadísticas según la especie y naturaleza efectiva, PP, IV/EV, identidad, propiedad, SaveV2, rechazo y rollback. No modificar `CreatureInstance`, `StatCalculator`, W04 `form_id`, factoría, ni SaveV2.

### Contrato de futuras formas W04
La instancia `CreatureInstance` de esta revisión no expone `form_id` en su esquema mostrado; esta reparación **no implementa ni garantiza la persistencia de formas futuras**. IA6/W04 debe definir ese contrato antes de incorporar datos de forma. No se tocó ningún archivo de W04.

**Estado de hito 09:** interoperabilidad funcional probada (camino `Growth.plan` con evolución real y SaveV2), **eliminación del cálculo duplicado BLOQUEADA por archivo protegido**. La CI global de TANDA03 se registra aparte al concluir, sin atribuirle la desaparición de este coste redundante.
