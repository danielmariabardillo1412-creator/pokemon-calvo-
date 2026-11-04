# IA3/W03 · CAMP006 BLOQUE 02 · BLOQUEADO_IA6 — transacción de Cuerda Huida
**Fecha:** 2026-11-04. **Rama exclusiva:** `codex/calvo-items-20261104-w03-camp006`.
**IDs reservados:** `escape_rope;fluffy_tail`. **Familia:** WORLD_RETURN.
**Progreso verificado:** bloque 01/10, piloto L2/L3 de navegación, CI [#41764265082](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41764265082) SUCCESS. **Bloque 02 NO entregado ni añadido al CSV/fixture.**

## Comprobación de autorización
Se releen en la rama árbitra `CAMPAIGN_006_W03_GATE.md` (blob `0e956f16`), `campaigns/CAMP_006_W03.md` (blob `ce37e56b`) y la cola (blob `1a29d08f`): siguen concediendo a W03 **solo el nuevo adaptador de mundo/captura**; inventario, `FieldItemService`, `FieldItemBag`, sesión, movimiento y SaveV2 corresponden a IA6. No consta ampliación explícita de ownership para el bloque02 ni un productor compartido entregado. La cola autoriza investigar el bloque, no la modificación unilateral de esas APIs.

Se verifican productores existentes:
- `EscapeRopeDemoPilot.preview(field)` y `return_to_demo_anchor(field)` son **positivos reales**; el segundo mueve al jugador por el controlador, pero deliberadamente **no gasta el objeto**.
- `PlayerInventory` tiene `to_dict/from_dict`, `has/remove` y `validate` para preparar un inventario candidato sin mutar la sesión.
- `FieldItemService.use_item` termina en `field_effect_not_connected` para `escape_rope` y `fluffy_tail` en campo. `FieldItemBag._apply("use")` siempre envía un objetivo de criatura a `service.use_item`: no existe una acción de objeto que reciba un mundo/mapa.
- `FieldNativeBridge.save_game()` rechaza cuando `_idle_boundary` no se cumple y exige movimiento habilitado fuera de batalla; abrir la mochila bloquea movimiento. Un comando de la bolsa debe gestionar explícitamente **cerrar/transferir el control de UI**, la revisión y el ciclo asíncrono de la travesía antes de intentar `save_game()`.
- `FieldNativeSave.write` usa `SaveGameSerializer.write_atomic_dictionary` para el archivo, pero esa atomicidad del archivo **no equivale** a transacción de *dos estados vivos* (posición + inventario) ni permite un rollback automático si falla la escritura.
- `fluffy_tail` ya tiene uso positivo en batalla salvaje mediante `ShowdownAdventureSession._use_escape_item` (huida garantizada y gasto de 1); **no procede conectar su huida a una posición del mundo ni alterar ese resultado**.

## Contrato compartido mínimo propuesto a IA6
**Propietario:** IA6 debe autorizar un comando de mundo/bolsa y su punto de llamada en `FieldItemBag` o `FieldItemService`. W03 solo facilitará `EscapeRopeDemoPilot.preview/return_to_demo_anchor` y pruebas.

```text
use_world_item(
  field: FieldDemo,
  item_id: StringName,                       # escape_rope
  expected_inventory_stamp: String,
  expected_world_revision: String,
  requested_save_policy: String              # explicit/manual vs auto-save
) -> await {
  accepted: bool, reason: String,
  item_id: String, spent_quantity: 0|1,
  from_position: [float,float],
  to_position: [float,float],
  from_region: String, to_region: String,
  save_committed: bool, revision: String
}
```

1. **Preflight síncrono** en propiedad IA6: colección/bolsa no corruptas, bola/objeto presente con cantidad ≥1, sesión sin batalla, sin UI/battle locks no resueltos, revisión de inventario+posición actual coincide, región fuente admite salir, `Pilot.preview(field)` devuelve un ancla validada.
2. **Preparar** copia `PlayerInventory.from_dict(original.to_dict())`, verificar `validate()` y `candidate.remove(&"escape_rope",1)`, pero **no publicar cantidad ni posición todavía**.
3. **Reservar operación exclusiva**: bloquear reentradas y cambios simultáneos de inventario, región, revisión y SaveV2, cerrar bolsa antes de travesía sin habilitar un segundo comando. Si el ancla se vuelve ocupada o la revisión cambia, rechazar sin mover/gastar.
4. **Travesía real** por `await Pilot.return_to_demo_anchor(field)` (o seam mejorado de IA6), verificar resultado y posición con `OverworldTraversalController`; si falla, mantener bolsa intacta y retornar fallo.
5. **Commit + persistencia**: IA6 decide el orden exacto de publicación de inventario candidato, instantánea de mundo y llamada a `save_game()`. En caso de error de disco, debe quedar restaurado estado vivo (bolsa, posición, región, RNG, relojes) y no existir un archivo de guardado parcialmente publicado. Debido al `await`, **revalidar stamps inmediatamente antes de publicar**. El adaptador W03 no asume ni garantiza esta atomicidad.
6. **Poscondiciones**: una sola cuerda gastada, retorno al marcador `SurfaceCaveReturn`, guardar y cargar mantiene destino y cantidad; no altera identidad ni especie, y ningún paso artificial dispara encuentro/RNG.

## Criterios de aceptación y pruebas nuevas que faltan
- **L3 positivo obligatorio:** abrir mochila real en `field_demo`, usar cuerda desde cueva, comprobar `inventory.quantity -1`, `technical_region_id()=="surface"`, guardar/cargar nativo y verificar que ambos sobreviven.
- **Rechazos transaccionales:** no existe ancla, choque en destino, mundo en batalla, inventario corrupto, cero cuerda, revisión desactualizada, doble click/uso durante `await`, fallo de escritura/SaveV2. Rechazo siempre implica **mismo snapshot de mundo + inventario**, sin RNG alterado.
- **Fluffy Tail:** preservar positivo de batalla salvaje y el rechazo de uso en mundo; ni consumo ni RNG en rechazo.

## Dictamen W03
**BLOQUE_02_BLOQUEADO_IA6; WORLD_RETURN en PAUSA.** El bloqueo es sobre el **mismo productor compartido** que se describió tras bloque01. Según regla CAMP006 no se inventa otra serie de negativos ni se marca 02/10 como completado. La suite CAMP006 verificada sigue en **1/10**. W03 no modifica módulos compartidos, no altera `main`, V28, PR118 ni otras ramas.

**Acción precisa para IA6:** asignar propiedad/autorización explícita de la interfaz `use_world_item` y sus reglas de persistencia/rollback, o implementar ese productor en rama coordinadora y publicar el contrato para W03. Solo entonces reanudar BLOQUE02. Si IA6 prefiere que W03 pase a familia ENCOUNTER_STEPS, debe confirmarlo explícitamente para no quebrantar la secuencia autorizada.
