# W01 Fase B / Bloque 01 · Hito 01 Ability Shield — piloto no certificado

Orden CONTINUOUS_V2. IDs seleccionados + entrada nativa comprobados: `ability_shield`, hook `onSetAbility`; evidencia preexistente en `tools/item_audit/held_effect_sweep_v3.cjs` (Gastro Acid vs Synchronize), **sin acreditación L3 antigua ni implementación nueva**.

- Node nativo verifica en cuatro modos `active`, `none`, `reserve`, `neutral`: efecto `gastro_acid`, `ignoringAbility()` con/sin escudo, `|-block|` del objeto correcto, propietario, preparación sin mutación, snapshots Restore.
- Godot verifica 4 rutas `FieldItemService.equip`, `FieldNativeSession`, evento traducido `item_triggered` con `metadata.reason=ability_protected`, combate y settlement natural, SaveV2 con propiedad estable.
- **No certificación con CI piloto solamente**: una CI acumulativa Fase B deberá repetir esta prueba junto con las 16 jobs de TANDA04 y regresiones históricas. Si el piloto falla, registrar prueba roja, diagnosticar y corregir solo tests propios W01. No tocar política ni reglas globales.
- Fase A cerrada 10/10; Fase B 0/26 certificados; dependencias fuera W01: cuatro. Integración IA6 NO.
