# W01 B01/02 · Absorb Bulb pilot (no certificado)

`absorb_bulb` SELECCIONADO, native_entry True, native hook `onDamagingHit` y `holdable_ids` comprobados. **Sin implementación nueva**, salvo demostración posterior de seam local defectuoso.

- Node 4 modos: portador recibe Water Gun → +1 SpA y consumo; sin objeto, en reserva y ataque físico no Agua → sin activación. Daño real, preparación pura, instantánea restaurada.
- Godot 4 rutas mochila → `FieldItemService.equip` → combate `FieldNativeSession` → `settle_finished_battle` → SaveV2; comprueba consumo persistente y eliminación de boost temporal en campaña.
- Piloto independiente. No marcar B `CERTIFICADO` hasta su incorporación al workflow acumulativo con 16 jobs originales y regresiones históricas. Si fallo, reparar solo archivos propios W01.
