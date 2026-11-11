# W04 — CONTINUOUS V4 STAGING · ENTREGABLE PARA IA6 (con puertas pendientes)

**Rama de ensayo exclusiva:** `codex/calvo-ia6-staging-20261111-w04-evolution`.
**Base fija IA6:** `e63b2e6c7e175fba318cc2f562bebd1769589092`.
**Fuente W04 V3:** `db24e6f38943e5782b0d028b2d6553267adecd6f`; CI origen #42959076143 SUCCESS.
**CI propia staging definitiva:** [#42965322073](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42965322073), **COMPLETED/SUCCESS**, SHA funcional `cdd53fb1d61a3aeb8790818aa571e13f9afbaed8`. Los commits documentales posteriores no forman parte de esa certificación.

## Resultado de la rama staging
- **7/7 evoluciones regionales reales a través de `FieldItemService.evolve`** certificadas; 14 casos Party/Storage con SaveV2, stock unitario e `instance_id` estable.
- `W04_V3_L3 PASS checks=396 routes=7 ownership=14 rollback=2`: naturaleza natal `nature_id` **y naturaleza efectiva `effective_nature_id` W02** conservadas; recálculo de estadísticas con la efectiva, IV/EV/experiencia, `moveset`/PP y persistencia. Se probaron además sesión bloqueada, especie/ítem/target erróneos, repetición y dos fallos forzados después de sustituir propietario, restaurando stock+creatura+ubicación.
- `W04_V2_B02 PASS checks=59 L3=0`; `W04_V2_B03 PASS checks=179 L3=0`.
- `W04_AUTORUN_V3_ALL PASS checks=968 examined=56 native_functional=55 blocked=1` (Exeggutor Alola bloqueado: no conceder Harvest oculta).
- `W04_AUTORUN_V4 PASS checks=64 promoted=4 blocked=1`; selección normal canónica de habilidad solamente para Ponyta/Rapidash Galar y Voltorb/Electrode Hisui.
- `W04_AUTORUN_V5 PASS checks=64 routes=2 L3=0`; Galarica histórica mantiene sus pruebas; `W04_AUTORUN_V2_FORM PASS checks=37`.
- Política de objetos: `dynamax_candy` **excluido**, verificado en `config/item_selection_v1.json` mediante la CI. No se han añadido objetos nuevos ni cambiado el veto.

## HUNKS de producción trasladados selectivamente
1. `CreatureInstance`: **únicamente `form_id` opcional y su serialización/restauración tipada** sobre W02; nunca eliminar ni sustituir `effective_nature_id`.
2. `CreatureFactory.create`: productor de identidad regional desde especie seleccionada y catálogo canónico, más promoción estricta de habilidad normal en las cuatro especies ya autorizadas; jamás crear habilidad oculta.
3. `EvolutionSystem.apply_evolution`: forma canónica **DEL DESTINO** para siete rutas; conservar `effective_nature_id`; calcular estadísticas con naturaleza efectiva si existe, natal si no. No copiar `form_id` de origen.
4. `FieldItemService.evolution_options/evolve`: whitelist de las siete rutas, validación de ítem y procedencia, política de especie base+forma canónica, consumo preparado, reemplazo de propietario y rollback verificable.
5. `SaveGameData.validate`: guardia estructural de `form_id` opcional, sin cambio de versión SaveV2.
6. `FieldNativeSave._valid_creature`: guardia de identidad canónica, **manteniendo la validación de estadísticas y naturaleza efectiva W02**.
7. Helpers puros `canonical_form_identity_w04.gd`, `regional_item_evolution_contract_w04_v2.gd`, `regional_evolution_contract_w04.gd`, `regional_ability_selection_w04.gd` y tests/workflow W04 exclusivos de staging.

## Rutas L3 verificadas
- `darumaka_galar + ice_stone → darmanitan_galar_standard`
- `growlithe_hisui + fire_stone → arcanine_hisui`
- `sandshrew_alola + ice_stone → sandslash_alola`
- `slowpoke_galar + galarica_cuff → slowbro_galar`
- `slowpoke_galar + galarica_wreath → slowking_galar`
- `voltorb_hisui + leaf_stone → electrode_hisui`
- `vulpix_alola + ice_stone → ninetales_alola`

## Puertas que IA6 aún debe cerrar antes de integración definitiva
**No afirmar CI global ni merge completado.**
- **CAMP003–006 Python/Godot en rama staging: NO EJECUTADAS.** Existen con PASS histórico en fuente V3 (#42959076143), pero la base fija de staging no incluye las suites/fixtures históricas W04 y sus dependencias. Requieren la fase de CI conjunta de IA6; su ausencia no es un PASS.
- **Interfaz visual `FieldItemBag`: no probada de punta a punta** en staging para las siete rutas; únicamente consumo en servicio real, Party/Storage y SaveV2.
- **Integración con W03 y W05** y propia rama oficial `codex/calvo-ia6-integration-20261109`: no realizada. Esta staging no se debe fusionar a ciegas ni copiar sus archivos enteros sobre W02/W03.
- **Exeggutor Alola:** bloqueo de habilidad oculta intacto y no se autoautoriza cambio de política.
- La inyección de rollback cubre dos fallos de publicación, no todos los modos imaginables de fallo de UI/almacenamiento.
- **Conservación de main, V28, PR118 y otras ramas:** sin modificaciones en esta operación.

## Dictamen
**READY_FOR_IA6_MERGE_CANDIDATE**: la parte W04 de la staging ha pasado las pruebas disponibles y no tiene otras tareas independientes justificadas; **NO es una autorización de merge ni certificación de la rama oficial**. IA6 deberá ejecutar el set conjunto completo y resolver las puertas anteriores. No generar una V5 ficticia ni contabilizar estos siete L3 como objetos nuevos.
