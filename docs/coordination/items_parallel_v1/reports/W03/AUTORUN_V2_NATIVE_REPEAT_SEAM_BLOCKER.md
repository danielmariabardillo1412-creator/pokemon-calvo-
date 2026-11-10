# W03 AUTORUN V2 — Contrato pendiente para Repeat Ball L3 en captura nativa

**Alcance:** una sola dependencia de sesión compartida, expresamente **NO autorizada** para edición W03 por la TANDA 02. No inferir que guardar un ledger equivale a producir el bonus en un combate Showdown.

## Evidencia de código

1. `modules/gameplay/wild_adventure_session.gd::capture_current` construye su propio `CaptureBattleContext`. W03 puede dar la bonificación verificando `PlayerCollection.caught_base_species_ids` **antes** del intento, y añadir al ledger **después** de `CaptureResult.SUCCESS` y `CaptureOwnershipRouter.route(...).routed`. Una captura fallida o un avistamiento no altera el ledger.
2. El combate nativo de `scenes/visual/field_native_bridge.gd` crea `FieldNativeSession` que utiliza `ShowdownAdventureSession`. En `modules/gameplay/showdown_adventure_session.gd::capture`, el contexto se crea localmente, actualmente asigna solo turno/nivel, usa `CaptureInventoryService.resolve` con copia temporal de bolsa/party/RNG y ejecuta `_finish("CAPTURED", ...)`. **No lee `player.caught_base_species_ids` ni registra al finalizar**. Este archivo queda protegido.
3. `modules/save/field_native_save.gd::write/decode` está autorizado exclusivamente para **persistir/restaurar** el ledger como colección normal SaveV2. Esta persistencia **no activa el multiplicador** por sí sola.

## Interfaz mínima para IA6

- Antes de `CaptureInventoryService.resolve` en el propietario nativo, establecer `context.previously_caught_base_species = player.has_previously_caught(target.base_species_id(), catalogs)` desde el agregado en vivo (nunca desde UI ni parámetro de cliente).
- Después de `_finish("CAPTURED", bag, resolution)` y **solo si `result.accepted` es verdad**, registrar `resolution.captured.base_species_id()` sobre la colección **publicada**, con rollback si cualquier etapa de commit falla. NO registrar tras `submit_reaction("capture_failed")`, no consumir RNG extra, no duplicar gasto de Ball.
- Confirmar que `_finish` conserva el agregado jugador que contiene el ledger. En caso de reconstrucción, copiar snapshot aprobado sin reconstruir desde Party/storage.
- Prueba L3 requerida: dos combates nativos reales sucesivos con la misma especie, primero con Ball de captura garantizada; SaveV2 manual y carga; segundo `repeat_ball` con probabilidad 3.5× contra control; probar otra especie (1×), fallo/rechazo, storage lleno, recuperación de batalla, RNG y double spend. La ruta de aventura ya tiene prueba separada.

**Regla canónica de la bonificación:** `repeat_ball` factor ×3.5 en Gen VII–IX frente a una especie previamente capturada; ×1 en caso contrario. Referencia: https://bulbapedia.bulbagarden.net/wiki/Catch_Rate (tabla de Repeat Ball); el perfil activo del juego es generación 9. No inventar ×3 de Gen III–VI.

**Estado:** productor de historial y guardado del ledger implementados en rama W03; **L3 nativa NO certificable sin este seam protegido**. No tocar Showdown en la rama trabajadora. Entregar a IA6 para integración selectiva; no hacer merge ciego de SaveV2.
