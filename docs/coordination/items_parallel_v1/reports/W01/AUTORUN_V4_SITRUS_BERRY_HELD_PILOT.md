# W01 TANDA04/10 · Baya Zidra held — QA exclusivamente, no nuevo desarrollo

**Propiedad:** Sitrus Berry pertenece también al campo de bayas/medicinas de W02. La orden explícita de TANDA04 W01 autoriza comprobar **la modalidad de objeto equipado en combate** pero NO editar campo/medicina, consumo de bolsa general, ni código de W02.

- Efecto nativo preexistente (HELD_PILOT_VERIFIED) en `tools/item_audit/held_pilot.cjs`; no contar implementación nueva ni alterar NativeEngine.
- Node prueba 6 modos (HP bajo, umbral exacto de 50%, justo por encima, completos, sin equipar, objeto en reserva), recuperación 1/4 del máximo, consumo único y Save/Restore, sin doble curación tras segundo turno.
- Godot prueba seis recorridos reales desde mochila/equipamiento, `FieldNativeSession`, `settle_finished_battle`, SaveV2 y `unequip` del objeto gastado sin devolución fantasma.
- Cualquier fallo de la ruta protegida `FieldItemService`/SaveV2 requiere ticket y asignación IA6, jamás parche sin permiso.
- **Estado:** piloto publicado, sin PASS ni certificación antes de CI y posterior puerta acumulativa. Integración IA6 NO.
