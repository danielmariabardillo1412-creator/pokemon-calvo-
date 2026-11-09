# IA6 — Inicio real de integración y frontera de experiencia (2026-11-09)

**Responsable IA6: esta conversación arbitral. No se espera a otra IA ni se traslada el trabajo a W02/W05 ya cerradas.**

## Rama aislada y cambios efectivamente preparados

Rama: `codex/calvo-ia6-integration-20261109`, creada desde árbitra `9b15e26d7fedfd701c5125acd5ab2172dc765b38`. **NO merge a `main`, V28, ni PR118.** Sin escrituras a las ramas de W01–W05.

Se han trasladado sin cambiar su lógica los siete archivos de producción siguientes:
- W02: `modules/creatures/domain/creature_instance.gd` (naturaleza efectiva opcional), `modules/inventory/field_item_service.gd` (ruteo transaccional menta), `modules/inventory/field_mint_effects.gd` (helper, solo un subconjunto de mentas).
- W03: `modules/overworld/escape_rope_demo_pilot.gd`, `modules/overworld/field_world_item_transaction.gd`, `modules/overworld/field_repel_step_effect.gd` (L2, NO L3), `scenes/visual/field_item_bag.gd` (solo seam de Cuerda Huida).

Prueba nueva real en `tests/gameplay/ia6_integration_mint_rope_20261109.gd`: efecto de `gentle_mint` (naturaleza original `hardy` intacta, aumentos/disminuciones y consumo; SaveGameData / serialización y compatibilidad legacy) + uso de `escape_rope` desde bolsa real, desplazamiento a superficie, gasto exactamente 1, guardado manual y carga SaveV2. **27 verificaciones Godot PASS** en la ejecución inicial [#42680021807](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42680021807), pero CI **global FAILED** en suite histórica V18.

Investigación IA6 del primer fallo: el workflow propio inicialmente no instalaba el runtime Node fijado para el motor nativo; en V18 varias pruebas fallaron al iniciar `ShowdownAdventureSession._begin`. Se ha añadido la preparación estándar del proyecto `python -B tools/battle_reference/run.py --install --limit 1` al workflow, commit `c6b442f921c4178561d347551ae4003681fa5241`; [run de recuperación #42680403069](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42680403069). **Pendiente de conclusión en el momento de esta anotación.** No se han silenciado las regresiones ni alterado los tests de juego.

## EXP SHARE: IA6 detecta una condición de integración distinta de W02

En `ProgressionSystem.reconcile_battle_result(participants,...)`, la progresión solo usa el array `participants` y divide experiencia entre sus supervivientes. Sin embargo, `ShowdownAdventureSession._finish` pasa `party.get_creatures()`, es decir, toda la party disponible, igual que rutas antiguas `WildAdventureSession`/`TrainerBattleSession`; V18 verifica que compañeros no titulares reciben actualmente una cuota ordinaria. Por tanto, **un parche que añadiera XP a portadores no participantes podría duplicar recompensas**. Requiere (1) productor fiable de participación/estado al cierre del combate, (2) política inequívoca de reparto y de portador equipable, (3) prueba con titular y no participante, (4) SaveV2, Lucky Egg y tope nivel100.

**No se ha modificado el sistema de XP ni se afirma `exp_share` funcional.** W02 sigue cerrada 10/10, pero la dependencia L1 es de IA6.

## Siguiente puerta

La rama de integración solo es candidata cuando la CI combinada y regresiones de progresión/bolsa sean `completed/success`; después auditoría de cambios de producción y validación de efecto en PC. Corregir cualquier fallo real de la combinación allí, no en ramas de las cinco trabajadoras. W01 motor Showdown/Transform, W03 encuentro/captura, W04 política V27, EXP Share y resto de mentas son decisiones/familias separadas. No contar `field_repel_step_effect` como L3 hasta conectar director, mochila y persistencia.
