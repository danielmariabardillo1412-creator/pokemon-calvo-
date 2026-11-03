# IA3/W03 — CAMPAÑA_004, bloque 06 (BLOQUEO TÉCNICO)

**Rama exclusiva:** `codex/calvo-items-20261103-w03-camp004`.
**Reserva autorizada:** `super_repel;white_flute;yellow_flute`.

## Auditoría del comportamiento actual

Los tres IDs están seleccionados como `FIELD_USE` en `RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`, pero no aparecen en las rutas actuales de `FieldEffects`, `EncounterModifiers` ni el perfil de recuperación `imported_recovery_v19.json`.

- `super_repel`: pendiente conectar pasos, nivel del Pokémon líder y generación de encuentros.
- `white_flute`: pendiente fuente/contexto de modificación de frecuencia de encuentros.
- `yellow_flute`: pendiente conexión de curación de confusión, elegibilidad y política de consumo.

El comportamiento de `FieldItemService.use_item` actualmente observado en código es rechazo `field_effect_not_connected`. Un rechazo seguro no constituye implementación funcional.

## Publicado y pendiente

- Fixture acumulativo extendido a seis bloques: commit `101164d5be3727c5e62eefe401a1b67d882e6ec3`.
- Runner Godot con `_block_06`: commit `ff00ad656b1a270d1e83614ddf21a0ce22dc7da0`. Pruebas de rechazo, no mutación/consumo, guardas, estado confundido y roundtrip de inventario.
- **Bloqueado:** la modificación de `tests/tools/test_parallel_items_w03_campaign_004.py` para integrar el bloque 06 fue rechazada por un control de seguridad de la herramienta GitHub. No se ha intentado eludir el control.
- **No se ha añadido fila 06 al CSV de progreso:** la prueba Python requerida falta, de modo que no se puede activar/validar correctamente la puerta de seis bloques.
- **No existe CI PASS del bloque 06.** La última CI verificable es CAMP004 05 [#41574450751](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41574450751), Python 100, Godot 479 y regresiones CAMP003 Python 279/Godot 986 aprobadas.

## Acción requerida

Restablecer la operación de escritura autorizada sobre el auditor Python y completar su bloque 06; solo después publicar la sexta fila y verificar la CI en el SHA final. No modificar `main`, V28, producción, otros workers o APIs compartidas. **No iniciar bloque 07 mientras 06 siga incompleto**.
