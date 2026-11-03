# IA3/W03 — CAMPAÑA_004 / MICROBloque 07

**Reserva aprobada:** `bug_tera_shard;dark_tera_shard;dragon_tera_shard;electric_tera_shard;fairy_tera_shard`. **Rama exclusiva:** `codex/calvo-items-20261103-w03-camp004`.

## Auditoría de estado

Los cinco fragmentos Tera (Bicho, Siniestro, Dragón, Eléctrico y Hada) están seleccionados como `TERA_MATERIAL` en `docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`. La política `config/item_selection_v1.json` no excluye estos IDs. `PlayerInventory` dispone de operaciones reales y serialización determinista de cantidades; la mochila admite hasta 999 unidades por stack.

El servicio `FieldItemService.use_item`, los perfiles de recuperación y los modificadores actuales no tienen ejecución para teracristalizar mediante estos fragmentos. Se espera `DEPENDENCY_MISSING / field_effect_not_connected` al usarlos directamente, sin gastar unidades ni cambiar estados. **Los cinco están `DEPENDENCIA_COMPARTIDA` para uso funcional**, aun si la transacción genérica de inventario pasa.

## Pruebas añadidas

- Runner Godot `_block_07`: catálogos reales y política de selección; por ID prueba cantidades 0, 1, 25 y 999; `add`, `quantity`, `has`, `remove`, reposición de una unidad y límite máximo; roundtrip `PlayerInventory.to_dict/from_dict`; rechazo de `FieldItemService.use_item` con snapshot íntegro; campo bloqueado y bolsa corrupta.
- Auditor Python: cola/familia/selección, ausencia de ejecutor de Tera, contrato real de inventario y cobertura de las pruebas Godot, además de no atribuir mecanización.
- Regresión acumulativa: suite CAMP004 bloques 01–07 y regresiones oficiales CAMP003 W03 en GitHub Actions.

**Límite de certificación:** el roundtrip de `PlayerInventory` no certifica SaveV2 integral y una CI verde no certifica teracristalización, conversión de tipos o consumo en batalla. Tampoco se ha implementado sistema Tera ni se ha modificado el propietario de ninguna arquitectura compartida.

## Dependencia de integración para IA6

Definir, previa decisión de IA6/usuario, la política de uso del fragmento, el sistema que cambia el tipo Tera, condiciones y consumo, estado de combate y persistencia de dicho tipo. El presente lote **no implementa ni simula** esas funciones.

Sin cambios en producción, `main`, V28, workflows, catálogo, PR #118 ni ramas ajenas. La CI del bloque 07 debe verificarse sobre el SHA definitivo del CSV antes de comunicar PASS.
