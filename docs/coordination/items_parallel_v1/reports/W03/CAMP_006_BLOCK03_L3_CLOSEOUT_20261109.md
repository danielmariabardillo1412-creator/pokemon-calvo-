# W03 — CAMPAÑA_006 BLOQUE 03 · REPelENTES L3 CERRADO

**Fecha:** 2026-11-09. **Rama:** `codex/calvo-items-20261104-w03-camp006`.
**Autorización:** `CAMPAIGN_006_W03_BLOCK03_REPEL_L3_WORLD_SEAM_AUTH_20261109.md`.
**Código + tests certificados:** SHA `6376d6f2833923edfd247dc72bf687eb282efdc7`, CI [#42716742131](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42716742131) **completed/success**.

## Integración realizada

- Un único efecto `FieldRepelStepEffect` ligado a `OverworldPlayer.step_completed`; 100/200/250 pasos físicos, sin consumir en movimiento bloqueado.
- `FieldItemBag` activa `repel`, `super_repel`, `max_repel` sin elegir Pokémon, consume exactamente 1 después de iniciar el efecto; niega activación durante un repelente vigente, sin stock o con bloqueo; si la retirada del objeto falla, restaura snapshot del efecto. **Sin autoguardado**.
- `field_demo.field_prepare_native_encounter` resuelve primero el encuentro en RNG clonado, obtiene el primer Pokémon vivo del equipo y suprime solo encuentros de nivel inferior. `field_native_bridge.on_step` evita `_open` y llama `field_commit_repelled_encounter_rng`; el RNG consumido avanza, pero la semilla de batalla no aumenta. Se admiten estados RNG `int64` negativos válidos.
- `world.repel` se incluye en el snapshot nativo existente; validador rechaza tipos, versiones, IDs y límites incorrectos. JSON puede representar enteros como float integral; se prohíben strings y valores fraccionarios. Un guardado anterior sin `repel` restaura estado inactivo. Carga corrupta se rechaza antes de publicar mundo/colección. Sin cambios a `modules/save/**`.
- Test nuevo `tests/gameplay/parallel_items_w03_repel_l3.gd`: botón UI real, inventario, bridge real pre-batalla, RNG, nivel inferior/igual, guardado/carga manual, carga de partida anterior, carga malformada, tres duraciones y pasos reales. Los tests L2 acumulativos permanecen.

## Recibos de CI real — 42716742131

- `CAMP006_W03_PY PASS`: bloques=3; deferred=1; last_executed_id=03.
- `CAMP006_W03_GODOT PASS`: bloques=3, comprobaciones acumulativas históricas.
- `CAMP006_W03_REPEL_L3 PASS`: 65 comprobaciones de la suite especializada.
- `CAMP005_W03_PY PASS` y `CAMP005_W03_GODOT PASS`: regresiones completas.
- El contrato rojo del bloque05 sigue evidenciando ausencia de procedencia autenticada pesca/surf/buceo; su paso controlado **no certifica el 05**.

**Contabilidad:** tres bloques completados; 04 APLAZADO_IA6; 05 BLOQUEADO_PRODUCTOR. B03 es el mismo bloque 03, remediado de L2 a L3, no suma bloque adicional.

**Revisión IA6 antes de integración:** modificaciones en `scenes/visual/field_item_bag.gd`, `scenes/visual/field_demo.gd`, `scenes/visual/field_native_bridge.gd`; no merge automático. `main`, V28, PR118, ramas ajenas, sesión y SaveV2 central siguen intactos. La inspección visual/GPU manual no está certificada.
