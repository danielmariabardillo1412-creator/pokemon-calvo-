# IA4/W04 — CAMPAÑA_004 / Microbloque 07

**Rama exclusiva:** `codex/calvo-items-20261103-w04-camp004`.
**IDs oficiales:** `rage_candy_bar`, `red_orb`, `reins_of_unity`.
**Estado:** pruebas publicadas; `EN_CI_AUTOMATICA`, no declarar PASS hasta revisar logs reales.

## Auditoría de contratos

- `rage_candy_bar` (Caramelo Furia): `ITEM_FIELD_V8.csv.txt` registra recuperación de estado de campo verificada y `modules/inventory/imported_recovery_v19.json` la define como cura de estados y confusión con consumo. Aunque `ITEM_INVENTORY.csv` contiene `DATA_ONLY` para su *entrada nativa de combate*, **existe efecto ejecutable en `FieldItemService`**. No confundir los dos campos. Este bloque prueba la curación real y no duplica ni modifica W02.
- `red_orb` (Prisma Rojo): equipo permitido y transferencia `VERIFIED`; entrada nativa existente pero aún `NATIVE_ENTRY_REQUIRES_EFFECT_CASE`. Un objeto equipado en Groudon no demuestra automáticamente la reversión primigenia en batalla.
- `reins_of_unity` (Riendas Unión): no equipable en el perfil actual, `DATA_ONLY`, fusión de Calyrex con otra criatura sin contrato de dos propietarios ni tratamiento de formas establecido en el servicio de campo. No simular fusión con `evolve`.

## Cambios propios

- Runner Godot `tests/gameplay/parallel_items_w04_campaign_004.gd`: commits `ad08ab7318c4e932139e91c56ae8de69380af8de`, `0b3a67a6353d8ec2e879ef27f9655a43e9c41862`. Acumula los bloques 01–07. Prueba Caramelo Furia en Eevee sano (rechazo sin gasto), en Eevee con quemadura (cura positiva, una unidad gastada, especie e identidad intactas, persistencia SaveV2), sin doble consumo y con propietario ajeno. Usa la criatura publicada por el servicio al verificar el estado tras la transacción. Para Prisma Rojo prueba en Groudon y Eevee equipamiento y retirada sin transformación falsa, estado/inventario y SaveV2; para Riendas Unión prueba en Calyrex y Eevee uso y evolución rechazados, equipamiento no autorizado y SaveV2. No ejecuta ni certifica Primal Reversion o fusión.
- Fixture `tests/fixtures/parallel_items/w04_campaign_004.json`: commit `717e7a80529dbce3dd590092ced3efa8123ff8d6`.
- Python `tests/tools/test_parallel_items_w04_campaign_004.py`: commit `2b652dabad36d9148bc45193f808bd2ecfef6062`, reserva exacta, 7 filas, 21 IDs acumulados, perfil, recuperación y cobertura de escenarios.
- Progreso `reports/W04/CAMP_004_PROGRESO.csv`: commit `0c02e95ba2d13f726dfb4c02cb692946680bd990`, fila 07 esperando CI.

## Regresiones y límites

La CI debe exigir Python y Godot acumulativos de CAMP004 y regresiones Python/Godot de CAMP003; CAMP001 se conserva y ejecuta por workflow en puertas 05 y 10. **No** introducir efectos de captura, entrenamiento ajeno, fusiones o cambios de forma en producción. No se han alterado `main`, V28, rama árbitra, otras trabajadoras, scripts de producción, catálogo ni workflows.

**Siguiente `p`:** ejecutar exclusivamente bloque 08 `reveal_glass;rotom_catalog;zygarde_cube`, previa verificación de CI07 y corrección de cualquier fallo local.
