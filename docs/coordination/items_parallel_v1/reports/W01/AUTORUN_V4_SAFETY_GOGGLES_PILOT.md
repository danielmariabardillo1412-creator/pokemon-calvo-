# W01 · TANDA04/08 — Gafas Protectoras (piloto no certificado)

Mecánica nativa ya presente en CAMP001 (`goggles_spore`, `goggles_sandstorm`, `goggles_normal`). No contar como objeto nuevo.

- Prueba nativa: 3 modos de Espora, 3 de tormenta de arena y 2 neutros; confirma movimiento rival en log de snapshot, persistencia del estado `slp` sin goggles y daño climático solo para activo sin equipar; Save restore en los 8 escenarios.
- Prueba Godot L3: 8 rutas con `FieldItemService.equip`, battle nativo real, cambio a reserva tras dormir, victoria real, `settle_finished_battle`, SaveV2 antes/después.
- Si el bloqueo de Espora impide una victoria natural en el piloto, conservar la prueba roja y corregir únicamente setup/driver; nunca forzar una victoria ni editar motor protegido.
- **Pendiente CI propia** y posteriormente CI acumulativa V4. Estado oficial TANDA04 al publicar: 3/10 certificados, 0 implementaciones de producción, IA6 integración NO.
