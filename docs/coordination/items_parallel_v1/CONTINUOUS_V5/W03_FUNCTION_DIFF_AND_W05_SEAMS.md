# IA3/W03 V5 — Diff verificable por función y seams W05 (2026-11-11)

## Comparación sobre la staging propia

- Base captura V4: `5a82da2a9dd1a868c3f8af9d73551fe16571adea`, rama derivada `codex/calvo-ia6-staging-20261111-w03-capture`.
- Destino Repel V5 W03: `codex/calvo-items-20261111-w03-repel-staging-v5`.
- Helper `modules/overworld/field_repel_step_effect.gd`: blob origen y V5 **idénticos** `7dbd62dd8238191e2101f25687d3e12d5d61a693`; conexión a `OverworldPlayer.step_completed`, duración 100/200/250, filtro nivel menor que el líder.
- `scenes/visual/field_item_bag.gd`: base blob `0d0497d661bc28785a76aed73b7e177854fe1a23` → V5 `a72be67c03b6548b348748d78d4b8efafd954fbc`. Cambios en `_refresh_choices` (5 líneas), `_apply` (2 líneas) y nueva `_apply_repel` (28 líneas). La comparación automática cuenta comentario adyacente bajo `_on_book_teaching_finished`, pero **su lógica no cambia**. Se conserva el panel W05 existente y `_apply_escape_rope`.
- `scenes/visual/field_demo.gd`: base `e71bd44b8d9819058e7cbe9eee0483e87e469c65` → V5 `9d1aaa0f620ad3c10bcbe30b3c1e5e01527be4c1`. Preamble: instancia `_repel_effect`; `_ready`: adjunta el movimiento real. `field_prepare_native_encounter`: bloqueo tras resolver Pokémon salvaje según nivel líder; `field_commit_repelled_encounter_rng`: nuevo commit acotado. `field_native_world_snapshot`, `field_validate_native_loaded_world` y `field_publish_native_loaded_world`: almacenamiento, validación y restauración opcional SaveV2.
- `scenes/visual/field_native_bridge.gd`: base `14571ab0dedf0f789064c2137baa49c279cbe44a` → V5 `6c40370575d0d07a68a49993cb5e9a594d60f6cb`. Solo `on_step` (+4 líneas) intercepta `blocked_by_repel` y confirma RNG antes de crear batalla.

Los blobs de siete módulos protegidos, la política que excluye `dynamax_candy` y el test histórico `parallel_items_w03_repel_l3.gd` quedan vigilados por `tests/tools/test_ia6_w03_v5_source_guard.py`. No se editan el motor JS, la lógica global RNG ni las reglas generales de captura.

## Compatibilidad con la staging W05 posterior — IMPORTANTE

Comparación real contra `codex/calvo-ia6-staging-20261111-w05-books`:

- W03 V5 mochila: `a72be67c03b6548b348748d78d4b8efafd954fbc`.
- W05 staging mochila: `12907d0dfdc040686dc3385c27bcef8ffda1e1d9`.
- **Hunks solapados:** `_ready`, `open_bag`, `_refresh_choices`, `_apply`. Diferencias adicionales en `_open_machine_books`, `_on_book_teaching_finished`; `_apply_repel` **solo existe en W03**.
- IA6 debe partir de un árbol controlado, fusionar manualmente las líneas W05 de panel/libros con el dispatch targetless y rollback W03, conservar apertura/cierre y refresco de mochila, y ejecutar las pruebas nativas tanto de libros y Cuerda Huida como de Repel.
- **No sustituir `FieldItemBag` por ningún archivo completo.** No afirmar que la staging W05 más reciente esté integrada en W03 ni viceversa.
- Después de integración, volver a certificar al menos `ia6_books_bag_20261109.gd`, `ia6_integration_mint_rope_20261109.gd`, Repel zona hierba real y adversariales de inventario y SaveV2, Repeat/Net/Moon.

## TEST HISTÓRICO ROJO — NO OCULTAR

`tests/gameplay/parallel_items_w03_repel_l3.gd` permanece idéntico, blob `318ee45f60d9ee046bcb048019337524acfb4844`, y conserva un fixture erróneo `registered_zone_ids()[0]` que selecciona `technical_cave_floor` antes de `technical_grass`. El ticket `CONTINUOUS_V5/W03_REPEL_HISTORICAL_TEST_ZONE_TICKET.md` documenta el fallo real de CI `43073388744`. La prueba nueva independiente usa `scene.TECHNICAL_ZONE_ID`, manteniendo toda la lógica de encuentro. IA6 decidirá si autoriza corregir solo la selección de zona histórica. **Un PASS de la nueva prueba no convierte en PASS el test histórico**.

## Limitaciones

La certificación scoped de W03 no sustituye a una CI de integración central. No afirmar haber ejecutado CAMP003–006 completos, las 7 rutas W04 ni la staging W05 posterior sin recibo separado.
