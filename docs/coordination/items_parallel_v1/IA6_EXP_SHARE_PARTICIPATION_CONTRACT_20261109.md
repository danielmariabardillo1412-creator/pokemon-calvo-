# IA6 — Dictamen técnico para EXP Share y participación real
**Fecha:** 2026-11-09 · **Estado:** dependencia compartida P0, aún NO implementada · **Propiedad:** IA6

## Evidencia concreta de código y CI

- `modules/creatures/progression/progression_system.gd::reconcile_battle_result(participants, outcome, catalogs, ruleset, starting_items={})` utiliza **todos los supervivientes del array recibido**, comparte experiencia entre ellos y aplica el modificador individual del objeto equipado con `HeldItems.battle_reward_amount`. Ese array NO contiene una marca verificable de participación.
- Los tres productores de resultado `modules/gameplay/showdown_adventure_session.gd::_finish`, `wild_adventure_session.gd` y `trainer_battle_session.gd` pasan actualmente `party.get_creatures()` (todos los miembros, no los participantes efectivamente desplegados).
- `tests/gameplay/progression_items_v18.gd` exige expresamente que un compañero de la party sin el objeto conserve su cuota normal de XP (`map teammate keeps ordinary share`), con y sin Lucky Egg del titular. Este es comportamiento existente a preservar, no un defecto que debamos «corregir» precipitadamente.
- W02 CAMP006 10/10 #42437567862 registra `exp_share` como **L1**: transferencia/equipamiento/SaveV2, **sin bono diferenciado acreditado para no participantes**.

**Conclusión:** añadir XP por el mero hecho de llevar `exp_share` actualmente duplicaría o alteraría la experiencia normal que reciben todos los compañeros. Una CI verde del equipamiento no demuestra el efecto.

## Decisión de IA6 (vinculante por ahora)

1. **No alterar todavía** `ProgressionSystem.reconcile_battle_result`, `ShowdownAdventureSession._finish`, `WildAdventureSession` ni `TrainerBattleSession` para sumar XP de `exp_share`. Conservar V18 y las tres rutas de cierre.
2. **Prohibido** contar `exp_share` como L2/L3 o modificar la lógica de Lucky Egg como atajo. W02 CAMP006 permanece cerrada.
3. Desarrollar como primer seam común un registro de participación originado por **eventos/acciones del motor autoritativo**, no por la UI ni por el hecho de estar en la party. La sesión conservará IDs de criatura desplegada, presencia al resolver el combate y equipo inicial, validando que todos pertenecen a la party original; será de solo lectura para progresión.
4. La política de experiencia queda versionada: mantener el comportamiento actual como **perfil legado compatible**. Un nuevo reparto por participación/EXP Share no podrá activarse por defecto ni distribuir dos veces experiencia a un mismo individuo. Se requiere especificar y probar el perfil propuesto antes de tocar producción; no inventar multiplicadores ni reglas a partir del nombre del objeto.
5. No se autoriza a W02/W03/W04/W05 modificar esta frontera compartida. IA6 será responsable de su implementación/CI en rama aislada y posterior integración selectiva.

## Contrato propuesto para la siguiente implementación

Productor compartido: `BattleParticipationReceipt`, DTO inmutable/detached con:
`battle_id`, `side_id`, `roster_ids`, `deployed_ids` (por al menos una entrada real en combate), `eligible_alive_ids`, `starting_held_items`, `outcome_ref` o hash del resultado.

Criterios:
- Referencias de ID únicas, propietario correcto, sin storage añadido al combatir, sin enemigos.
- Rechazar un recibo incompleto, incoherente o de batalla distinta; no degradar silenciosamente a todos los miembros.
- El consumidor de progresión requiere una política explícita con XP normal, reparto y equipables; `exp_share` solo puede dar un resultado diferente cuando existe una prueba comparativa base/portador desde eventos reales.
- Preservar guardados antiguos; ningún cambio a esquema SaveV2 sin puerta propia. El recibo de participación de sesión no se inventa al recargar a mitad del combate: si se permite guardar batallas activas, su serialización necesitará un contrato específico.
- Sin modificación de RNG, inventario o objetos mientras se prepara un recibo.

## Pruebas rojas y positivas necesarias

1. Party con A titular, B reserva equipada con `exp_share` y C reserva sin equipar; entrada real de B en otra variante; XP por individuo, base y bonificación exactas conforme a la política elegida, sin doble reparto.
2. Distinguir no participante, participante, debilitado y nivel 100; crecimiento y XP con y sin Lucky Egg; no exceder límite ni alterar EV/amistad por accidente.
3. Movimiento de objeto durante la batalla y validación de held inicial/final; ninguna duplicación ni consumo espurio.
4. Mismas expectativas en sesión nativa, salvaje legacy y entrenador; partido vivo/restaurado si está autorizado. Ningún test con `deployed_ids` forjado cuenta como L3.
5. Regresión completa V18 y W02 CAMP006, prueba de no duplicidad, SaveV2, identidad/propiedad, y CI por SHA.
6. Si la política final mantiene el reparto global por party, registrar `exp_share` como **redundante para XP** y decidir su tratamiento en el catálogo, no atribuirle un efecto inexistente.

## Orden operativo inmediata IA6

Primero cerrar la CI de integración `codex/calvo-ia6-integration-20261109` (menta/Cuerda Huida, regresiones). Después obtener evidencia de participación autoritativa por escenario y elegir un contrato de política compatible con V18. Hasta entonces, `exp_share` continúa PENDIENTE; no fusionar ningún experimento de XP en main/V28.
