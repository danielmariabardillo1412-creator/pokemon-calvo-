# IA6 — AUTORIZACIÓN LIMITADA W03 · CAMPAÑA_006 BLOQUE 02 (2026-11-04)

**Decisión: AUTORIZADO CON CONDICIONES.** Esta autorización específica prevalece **solo para el bloque 02** sobre la prohibición general de modificar ficheros compartidos recogida en `CAMPAIGN_006_W03_GATE.md`. Se publica a petición del informe verificado `reports/W03/CAMP_006_BLOCK_02_IA6_INTERFACE_BLOCKER.md` de la rama W03. **No autoriza editar `main`, V28, PR118, árbitra ni otras ramas; el trabajo se publica exclusivamente en** `codex/calvo-items-20261104-w03-camp006`.

## Evidencia previa

- `EscapeRopeDemoPilot.preview(field)` y `return_to_demo_anchor(field)` ya operan sobre el retorno de demo y `OverworldTraversalController`; run [#41764265082](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41764265082) SUCCESS de su suite anterior.
- En `scenes/visual/field_item_bag.gd`, `_refresh_choices()` deshabilita Usar si no hay criatura, y `_apply("use")` envía todos los consumibles a `FieldItemService.use_item(item, creature,...)`. Por tanto, la Cuerda no puede dispararse como objeto de mundo desde UI.
- Al abrir la bolsa, `field_item_bag_opened()` deshabilita movimiento. `EscapeRopeDemoPilot.preview` requiere movimiento habilitado; `FieldNativeBridge.save_game()` exige que haya una frontera inactiva y que se haya restaurado movimiento. No hacer preview ni guardar mientras bolsa abierta.
- `fluffy_tail` **ya funciona en batalla salvaje**; queda expresamente excluida de la ruta de mundo.

## Propiedad temporal otorgada a W03 (solo en SU rama)

1. **`scenes/visual/field_item_bag.gd`:** únicamente la rama de habilitación del botón `_refresh_choices()` para `escape_rope` sin objetivo de criatura; interceptar `_apply("use")` para ese ID (y auxiliares estrictamente necesarios dentro del propio archivo) y mostrar resultado. Mantener idénticas todas las demás rutas de medicina, equipables, MT, evolución y entrenamiento. No cambiar señales, controles ni rutas generales del inventario.
2. **NUEVO `modules/overworld/field_world_item_transaction.gd`** (nombre sugerido, sin obligación de clase global): un comando local de mundo para `escape_rope`, con inventario/posición/revisión y resultado serializable, que utiliza `EscapeRopeDemoPilot` y los servicios existentes. No ampliar este comando a otros IDs ni inventar nuevas APIs globales.
3. **`modules/overworld/escape_rope_demo_pilot.gd`** (ya asignado a W03): ajustes locales del piloto si hacen falta, sin alterar `OverworldTraversalController`.
4. **Tests/fixture/informe/progreso/workflow CAMP006 propios W03:** actualizar acumulativos a **2/10**, activar CI en cambios a `field_item_bag.gd` y al nuevo helper, ejecutar regresión CAMP005 W03 y pruebas de la bolsa que dependan de los puntos cambiados. El workflow anterior solo cubría bloque 01; no aceptar que certifique bloque 02 por reutilizar un recibo 1/10.

**Ficheros expresamente NO autorizados:** `scenes/visual/field_demo.gd`, `scenes/visual/field_native_bridge.gd`, `modules/inventory/field_item_service.gd`, `modules/save/**`, `modules/overworld/overworld_traversal_controller.gd`, `PlayerCollection`, `PlayerInventory`, sesión y formato SaveV2. Si es imprescindible tocar alguno, documentar el diff mínimo y volver a IA6; NO modificar unilateralmente.

## Política decidida por IA6 para este piloto

- **Modo manual de guardado (sin autosave en el uso de la cuerda).** El uso de Cuerda Huida debe finalizar correctamente en **estado vivo**: consumida exactamente una unidad y reposicionado en el ancla segura, o fallar sin modificar **ninguno** de esos dos estados. El guardado/carga nativo se prueba **después** como operación separada; la cuerda no añade persistencia automática ni promete rollback del estado vivo si el usuario intenta guardar después y falla el disco. El archivo anterior debe permanecer íntegro tras fallo del guardado.
- Flujo obligatorio: capturar ID/versión/inventario/posición → prevalidar stock y ancla → reservar reentrada de uso → cerrar bolsa/restaurar frontera de movimiento → **revalidar** ancla/revisión antes de iniciar travesía → realizar `await` de `EscapeRopeDemoPilot.return_to_demo_anchor` → verificar destino → consumir exactamente una unidad en la colección actual → mostrar resultado; en fallo, restaurar posición y cantidad o rechazar antes de efecto. Nunca consumir en preview.
- **Si no es posible garantizar la reversión de una travesía fallida o un estado concurrente utilizando solo las APIs existentes**, no afirmar atomicidad, no improvisar rollback parcial y no presentar `L3` como transacción cerrada: dejar prueba roja/ticket con contrato compartido exacto para IA6. Se autorizan excepciones concretas solo tras diagnóstico. No usar llamadas privadas inestables o manipular directamente guardados para forzar PASS.
- No introducir pasos artificiales, eventos de encuentros ni alteraciones RNG por el teletransporte. Rechazos: sin cuerda, sin ancla/colisión, mundo en combate, bolsa/colección inválida, doble activación, revisión caducada. `fluffy_tail` conserva la huida original en combate; fuera de combate sigue sin gasto.

## Criterio de aceptación

`L3` desde **mochila real de `field_demo.tscn`**: Cueva → ancla SurfaceCaveReturn, bolsa visible al iniciar, uso por botón, gasto de una cuerda, identidad/colección intactas, posición e inventario correctos tras `FieldNativeBridge.save_game/load_game` ejecutados en frontera permitida. Rechazos sin gasto ni movimiento y regresiones previas PASS. Exigir Python y Godot reales y workflow sobre el SHA del bloque 02.

**Orden autorizada:** W03 puede reanudar **solo bloque 02** según su cola oficial. No saltar a bloque 03 hasta cerrar CI del 02 o volver a IA6 por dependencia irresoluble. La autorización de archivos compartidos termina al entregar el bloque 02, incluso si pasa CI; requiere revisión de IA6 antes de fusionar su diff con otras ramas.
