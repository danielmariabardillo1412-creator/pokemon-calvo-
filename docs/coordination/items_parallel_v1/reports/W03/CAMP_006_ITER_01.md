## Última verificación tras actualizar el CSV

[GitHub Actions #41764265082](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41764265082), HEAD `eead52006beb011f9a4c994cc4a7e9ced0a1c43a`, **completed/success**. La CI volvió a comprobar el mismo código funcional y el estado final del progreso: `CAMP006_W03_PY PASS blocks=1 checks=17`, `CAMP006_W03_GODOT PASS blocks=1 checks=20`, regresión `CAMP005_W03_PY PASS blocks=10 checks=169` y `CAMP005_W03_GODOT PASS blocks=10 checks=208`. El bloque 01 se considera **piloto de navegación L2/L3 validado**, no una Cuerda Huida conectada al botón de mochila. El contrato transaccional de IA6 sigue pendiente.

---

## Resultado CI real y correcciones del piloto

La ejecución final del código [#41764044349](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41764044349), commit `425885a7182db2a7c9962f0a396fd22bf70b858e`, terminó **completed/success**. Recibos: `CAMP006_W03_PY PASS blocks=1 checks=17`, `CAMP006_W03_GODOT PASS blocks=1 checks=20`, y regresión `CAMP005_W03_PY PASS blocks=10 checks=169`, `CAMP005_W03_GODOT PASS blocks=10 checks=208`.

Dos ejecuciones anteriores fallaron por causas propias corregidas sin relajar ninguna prueba: [#41763655888](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41763655888), inferencia estática de tipo GDScript en el runner, y [#41763891650](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41763891650), ausencia de guarda temprana del movimiento bloqueado en el adaptador. La tercera CI acreditó el retorno desde la cueva, guardado y recarga nativa, bloqueo seguro, conservación de cantidad y regresión.

**Criterio alcanzado:** retorno del piloto de demo y serialización/restauración a través de SaveV2 existente, no transacción completa del objeto. **CI no acredita UI ni GPU**, y no debe anunciarse Cuerda Huida plenamente jugable. Solicitud puntual IA6: integrar `WorldItemCommand` con propiedad de mochila y commit transaccional (siguiente bloque del mismo grupo) antes de conectar el botón de bolsa.

---

# IA3/W03 · CAMPAÑA_006 · BLOQUE 01 · Cuerda Huida

**Rama exclusiva:** `codex/calvo-items-20261104-w03-camp006`. **ID:** `escape_rope`, del backlog anterior, **no nuevo**. Baseline CAMP005 10/10 previo intacto. La rama inicialmente NO contenía fixture/progreso/runner CAMP006 ni workflow, y no había runs de CI CAMP006. Se crearon en W03, sin alterar ninguna rama ajena.

## Nuevo efecto positivo (piloto navegación L2 / sesión demo L3 parcial)

Se creó `modules/overworld/escape_rope_demo_pilot.gd`, función propia de W03 que **no cambia APIs globales**. Produce un `return_anchor` autoritativo desde nodos reales `CaveExit → SurfaceCaveReturn` o `BuildingExit → SurfaceBuildingReturn` del mapa `technical_overworld.tscn`. El adaptador valida región actual, identidad del portal, región de destino, identidad del marcador, ocupación de destino, bloqueo de movimiento y estado de actividad. La ejecución `return_to_demo_anchor` llama **realmente** a `OverworldTraversalController.traverse_portal` y comprueba posición y región resultantes.

La prueba Godot `tests/gameplay/parallel_items_w03_campaign_006.gd` crea la escena auténtica `field_demo.tscn`, entra físicamente en la cueva con `CaveEntrance`, regresa por el adaptador vía `CaveExit`, contrasta el ancla y las guardas (superficie sin destino, movimiento bloqueado), y comprueba que la mochila no se modifica unilateralmente. Se guarda la sesión demo **mediante el puente real** `FieldNativeBridge.save_game` y se carga `load_game`, contrastando la posición retornada y cantidad de objeto. Esto prueba recorrido/SaveV2 de un *piloto de navegación* y no una ejecución conectada al botón Usar.

## Estado honesto y contrato exacto requerido a IA6

**Estado:** `L2_L3_NAVIGATION_PILOT_ONLY`, **NO `escape_rope` jugable desde la mochila**. El adaptador no consume `escape_rope` ni modifica `FieldItemService`, `FieldItemBag`, mundo/sesión o SaveV2 globales. Antes de avanzar al bloque02 (transacción) IA6 debe autorizar o proporcionar un único punto de integración compartido:

```text
FieldItemBag.use(escape_rope) [IA6, UI]
  -> FieldItemService / WorldItemCommand [IA6, token y ownership]
  -> EscapeRopeDemoPilot.preview(field) [W03, anchor validado]
  -> staged(PlayerInventory) - 1 [IA6, copia transaccional]
  -> await OverworldTraversalController.traverse_portal(portal) [existente]
  -> commit inventario + mundo + SaveV2, atómicamente [IA6]
  -> si cualquier paso falla: rollback posición, inventario, reloj y RNG
  -> éxito: 1 unidad gastada, posición en SurfaceCaveReturn, SaveV2 reload igual
```

**Contrato mínimo:** `use_world_item(item_id, expected_world_revision, expected_inventory_stamp) -> {accepted,reason,old_position,new_position,spent_quantity,save_revision}`. Rechazar si batalla, mapa sin retorno, movimiento bloqueado, mochila corrupta, falta de objeto, fallo de colisión o traslado. El *commit* de inventario debe ocurrir después de resultado válido, sin introducir gasto irreversible si guardar/trasladar falla. Es decisión de IA6 asignar y especificar la atomicidad ante fallo de escritura SaveV2. No crear botones de UI ni saltarse su autorización.

## Criterio de cierre

CI propia: `CAMP006_W03_PY PASS blocks=1 checks=N` y `CAMP006_W03_GODOT PASS blocks=1 checks=M`, más regresión CAMP005 W03 10/10; comprobar SHA concreto del run y conservar logs. **CI PASS no es L4, ni prueba visual GPU.** Si el guardado y carga falla, diagnosticar y corregir pruebas o adaptador dentro de la rama, sin relajar casos. No tocar `main`, V28, PR118 ni ramas ajenas.
