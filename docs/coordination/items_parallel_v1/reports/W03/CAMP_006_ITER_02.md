# IA3/W03 — CAMPAÑA_006 · BLOQUE 02 · Cuerda Huida / Cola Esponjosa

**Rama exclusiva:** `codex/calvo-items-20261104-w03-camp006`. **Reserva:** `escape_rope;fluffy_tail`, cero objetos nuevos.

**Autorización específica IA6:** `CAMPAIGN_006_W03_BLOCK02_SHARED_SEAM_AUTHORIZATION.md` (árbitra). Permite cambiar únicamente la rama de habilitación `_refresh_choices` y el caso `escape_rope` de `_apply` en `scenes/visual/field_item_bag.gd`, crear `modules/overworld/field_world_item_transaction.gd` y modificar los tests/CI propios. No se ha modificado `field_demo.gd`, `field_native_bridge.gd`, `field_item_service.gd`, controlador de travesía, módulos SaveV2, `PlayerInventory`, `PlayerCollection`, sesión ni reglas compartidas.

## Implementación L3

`FieldItemBag._refresh_choices`: solo `escape_rope` se habilita sin Pokémon objetivo y presenta descripción de retorno seguro, manteniendo los otros usos intactos. `_apply("use")` intercepta exclusivamente esa ID y ejecuta `_apply_escape_rope`. La operación obtiene un token de inventario/propietario y posición inicial con `FieldWorldItemTransaction.prepare` mientras la mochila sigue visible; cierra la mochila para restaurar movimiento mediante señal existente; ejecuta `await FieldWorldItemTransaction.execute`, que revalida colección, inventario, región/posición y ancla, y reserva reentrada por `busy`. `EscapeRopeDemoPilot.return_to_demo_anchor` recorre de verdad `OverworldTraversalController.traverse_portal` y comprueba el retorno a `SurfaceCaveReturn`. **Solo después** se descuenta 1 `escape_rope`.

La implementación **no hace autosave**. `FieldNativeBridge.save_game/load_game` existente guarda/carga manualmente el mundo y el inventario en pruebas. `fluffy_tail` no se intercepta y conserva su huida en combate salvaje.

## Evidencias ejecutables

- Godot CAMP006 `_block_01` (sin cambios) y nuevo `_block_02`, desde `field_demo.tscn`. La bolsa real se abre en cueva, se selecciona Cuerda Huida y se dispara `bag._use.pressed.emit()`. Se verifica destino, región, consumo unitario, misma colección, ausencia de guardado automático, guardado manual y recarga/restauración de posición y cantidad.
- Rechazos de `execute`: superficie sin ancla, no disponer de cuerda, reentrada `busy`, revisión del inventario caducada y colisión física sobre el marcador de retorno; no deben consumir ni desplazar.
- Python CAMP006 comprueba la ruta exclusiva en `FieldItemBag`, la ejecución real del adaptador, la reserva de colección y la ausencia de autosave. La regresión CAMP005 W03 (incluida Cola Esponjosa) se ejecuta íntegramente.

**Límite de garantía:** los casos probados establecen rechazo seguro y gasto posterior al traslado. El adaptador detecta estado cambiante durante el `await` y revierte la posición solo si el controlador queda inactivo; un fallo extremo con travesía permanentemente ocupada o mutaciones concurrentes ajenas requeriría una primitiva adicional de cancelación/rollback propiedad de IA6. No debe proclamarse atomicidad general bajo concurrencia arbitraria, solo la transacción demostrada en el piloto de la demo.

**Verificación CI:** comprobar `CAMP006_W03_PY PASS blocks=2`, `CAMP006_W03_GODOT PASS blocks=2` y CAMP005 regresión Python/Godot sobre último SHA de código. No confundir prueba de guardado manual con guardado automático, ni L3 headless con GUI/GPU validada.

**Fusión:** requiere revisión del diff compartido `FieldItemBag` por IA6 antes de merge. No tocar `main`, V28 ni ramas ajenas. Una vez CI validada, siguiente `p` = bloque03 de repelentes.
