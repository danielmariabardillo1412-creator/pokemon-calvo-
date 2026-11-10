# W01 TANDA03 — mapa de seam L3, límites y puntos de validación

**Objeto de la auditoría:** 18 gemas históricas, **0 objetos nuevos**. Orden IA6: `docs/coordination/items_parallel_v1/IA6_AUTORUN.md`, TANDA 03.

## Camino real, no pruebas de simple catálogo

1. `modules/inventory/player_inventory.gd`: `add`, `remove`, `quantity`, `to_dict`; contador de unidades físicas.
2. `modules/creatures/storage/player_collection.gd`: `party`, `inventory`, `owned_creature(instance_id)`; identidad exclusiva entre equipo y caja.
3. `modules/inventory/field_item_service.gd`: `configure(collection, definitions, may_mutate)`, `holdable(id)`, `equip(item_id, creature_id)`, `unequip(creature_id)`. Equipar se hace mediante **el servicio real**, con una bolsa con 2 copias, nunca asignando `held_item_id` desde una prueba. Sustitución de otro equipo por staging y rollback de bolsa.
4. `modules/creatures/domain/creature_instance.gd`: `held_item_id` y `held_item_consumed`; ambos son datos de guardado V2.
5. `modules/gameplay/field_native_session.gd`: subclase real de `showdown_adventure_session.gd` usada por `scenes/visual/field_native_bridge.gd`. Inicia el encuentro con el propietario equipado, consulta `battle_state().creature`, acepta `submit`.
6. `modules/battle/backends/showdown/field_held_items.cjs`: hook preexistente `onSourceTryPrimaryHit` de gemas; el presente lote no altera daños ni porcentajes.
7. `modules/gameplay/showdown_adventure_session.gd`: `settle_finished_battle()` y `_finish(reason,bag)` publican únicamente al terminar el combate la proyección de consumo en `player.party` y sus cantidades. El estado anterior a settle debe permanecer intacto para evitar doble gasto.
8. `modules/save/save_game_repository.gd`: `save_collection(path,player)` y `load(path)` de disco antes y después de la liquidación. No equivale a solo decodificar un diccionario.
9. `modules/save/save_game_migration.gd`: al cargar legacy V1, se construye **bolsa vacía**; se conserva el flag `held_item_consumed` de criatura, pero no se infiere una gema fantasma.

## Cobertura planeada y advertencias

- Fixture `tests/fixtures/parallel_items/w01_autorun_v3.json`: 3 CAMP005 + 10 TANDA01 + 5 TANDA02, 18 IDs únicos.
- Runner `tests/gameplay/parallel_items_w01_autorun_v3.gd`: equipar, persistir, iniciar batalla con adaptador real FieldNativeSession, comprobar consumo, liquidar victoria, persistir y recargar; desequipar la gema consumida sin devolverla, reequipar una copia de inventario sin duplicación.
- Negativos transaccionales: equipo ajeno, bolsa vacía, equipar ya equipado, sustitución con devolución.
- Legacy V1: preservar flag consumido, bolso vacío y conversión a SaveV2; prohibido añadir objetos desde el estado antiguo.
- **No se declara** cobertura de captura, derrota, Transformación y presentación UI salvo que el runner realmente las ejecute. Son hitos de auditoría restantes y cualquier ausencia debe documentarse en un ticket, no convertirse en PASS.
- **No se modifica** `FieldItemService`, `PlayerCollection`, `CreatureInstance`, `SaveGameRepository`, `SaveV2`, motor o escena. La integración con rama IA6 sigue pendiente.

## Checkpoint

Rama exclusiva `codex/calvo-items-20261110-w01-gems-autobatch01`. TANDA02 finalizada: SHA funcional `0871aa6751faecb7342376134ddbcaa5acf1ce5a` y CI `42869207766` SUCCESS. El código de pruebas TANDA03 necesita SU PROPIA CI sobre SU SHA; sin recibo `completed/success` los hitos permanecen pendientes.
