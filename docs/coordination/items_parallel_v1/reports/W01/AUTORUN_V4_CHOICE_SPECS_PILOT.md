# W01 TANDA 04 fila 04 — Gafas Elegidas (piloto, no certificado)

- Política: `choice_specs` SELECCIONADO; `ITEM_INVENTORY.csv` marca `onModifySpA|onModifyMove|onStart` y perfil de mochila permite equipar.
- Prueba Node: daño especial `water_gun`, control sin equipar, objeto en reserva, bloqueo de `shadow_ball`, rechazo de orden ilegal, cambio y reset con checkpoint/restore nativo.
- Prueba Godot: `FieldItemService.equip` → `FieldNativeSession` → cambio y combate → `settle_finished_battle` → SaveV2 antes/después. Tres modos.
- **Estado:** preparado para ejecutar CI piloto. Un PASS del piloto no reemplaza CI acumulativa; no modificar código de producción ni contar nuevo objeto antes de comprobar si ya existe mecánica.
- Hito anterior `choice_band`: piloto SUCCESS #42927457230; CI acumulativa nueve jobs SHA `0d11b41549b713c68433fa6b1d11d18b7d7e670c` pendiente.
