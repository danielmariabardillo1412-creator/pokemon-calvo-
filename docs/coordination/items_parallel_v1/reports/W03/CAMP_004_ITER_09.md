# IA3/W03 — CAMPAÑA_004 / MICROBloque 09

**Reserva autorizada:** `ground_tera_shard;ice_tera_shard;normal_tera_shard;poison_tera_shard`. Rama propia `codex/calvo-items-20261103-w03-camp004`.

## Diagnóstico

Los cuatro materiales Tera Tierra, Hielo, Normal y Veneno constan como `TERA_MATERIAL`, `SELECCIONADO` en `docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`. Las rutas de `PlayerInventory` soportan almacenamiento genérico, incrementos, extracción y serialización de sus cantidades. `FieldItemService.use_item` no posee mecánica de teracristalización para esos IDs, por lo que el uso directo actual devuelve `DEPENDENCY_MISSING/field_effect_not_connected`. Esto impide su consumo indebido; **no representa teracristalización funcional**.

## Evidencia de pruebas propias

La función `_block_09` ejecuta contratos Godot reales para cada uno de los cuatro IDs. Cubre existencias 0, 1, 25 y 999; selección en catálogo, `add/has/quantity/remove`, reposición, desbordamiento, serialización `PlayerInventory.to_dict/from_dict`, rechazo del servicio de campo sin consumo ni cambio de estado, bloqueo y mochila corrupta. El auditor Python coteja cola oficial, selección, ruta de inventario, ausencia de ejecutor y prueba Godot.

**Resultado funcional a registrar:** `DEPENDENCIA_COMPARTIDA` para los cuatro fragmentos. Un PASS de CI demostraría los contratos actuales de mochila y de rechazo, **no** SaveV2 completo, transformación Tera, cambio de tipo ni uso o consumo en combate.

## Regresiones y permisos

La CI acumulativa debe ejecutar bloques 01–09 CAMP004 más suites CAMP003 W03. El bloque anterior 08 está validado en [#41578378122](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41578378122), Python 151/Godot 1012 PASS y regresiones Python 279/Godot 986 PASS. La CI de 09 requiere confirmación en el commit final, no se afirma antes.

**Para IA6:** determinar política de materiales Tera, posible cambio de tipo, consumo, batalla y persistencia cuando autorice implementar esa mecánica. No se han editado `main`, V28, producción, workflows, catálogo, PR #118 ni ramas de otras trabajadoras.
