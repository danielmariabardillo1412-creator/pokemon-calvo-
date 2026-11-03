# IA3/W03 — CAMPAÑA_005 / BLOQUE 08 — Flautas Roja, Amarilla y Azul

**Cola oficial:** `red_flute;yellow_flute;blue_flute`. Estos IDs ya estaban auditados, no se cuentan como nuevos. Rama propia: `codex/calvo-items-20261103-w03-camp005`.

## Diagnóstico funcional real

**Flauta Azul:** `modules/inventory/imported_recovery_v19.json` incluye `blue_flute` con `consume: false` y `effect.cure: ["slp"]`. El servicio `FieldItemService.use_item` utiliza `FieldItemEffects.apply` sobre una copia del Pokémon y publica el resultado al propietario solamente tras validarlo; el perfil impide consumir la Flauta Azul y el servicio borra `sleep_clocks` al curar el sueño. Hay un **efecto de campo funcional existente**, no simplemente una dependencia.

**Flauta Amarilla y Flauta Roja:** el contrato de `battle_support_profile.json` indica `yellow_flute: cure_volatile(confusion)` y `red_flute: cure_volatile(attraction)`, con objetivo activo de combate y sin consumo. `modules/battle/backends/showdown/native_bag_effects.cjs` mantiene reglas para confusión y atracción; **no existe ejecución equivalente de campo** en `FieldItemEffects`. No debe añadirse un uso de campo que cure estados volátiles inexistentes o extrapolarlo de la curación persistente de sueño.

## Pruebas propias

Godot `_block_08` verifica catálogo y política de selección de tres flautas, transacción `FieldItemService.use_item` con sueño real, identidad del Pokémon, cantidad inalterada, eliminación del reloj y rechazo sin efecto sin cambios de Pokémon, bolsa ni relojes. Para Roja y Amarilla comprueba que el servicio de campo no afirma una curación que carece de ejecutor, sin consumo ni mutación. El auditor Python verifica los perfiles importados, rutas de transacción y estado persistente, origen de los efectos volátiles y presencia de cada test ejecutable.

**Clasificación:**
- `blue_flute`: **FIELD_FUNCTIONAL_SLEEP_CURE_REUSABLE**, pendiente de certificación CI de bloque08.
- `red_flute`, `yellow_flute`: **DEPENDENCIA_BATTLE_VOLATILE** para uso dirigido en batalla; el campo rechaza su uso. Definir si IA6 desea interoperabilidad de batalla/bolsa y dónde queda la autoridad de estados volátiles.

## Pendientes exactos para IA6

Acordar propiedad de la interfaz entre objetos de bolsa y estado activo Showdown de combate, restricciones, rechazo por no efecto y sincronización de ambos estados para Roja/Amarilla. No forzar `status_state` persistente a tener atracción/confusión si la batalla gestiona estas condiciones; tampoco consumir una flauta reutilizable en rechazados. No se modificaron `main`, V28, PR #118, producción, workflows, catálogos ni ramas ajenas.

**CI:** requiere comprobantes de `CAMP005_W03_PY PASS blocks=8` y `CAMP005_W03_GODOT PASS blocks=8`, gates IA6 y commit definitivo del CSV antes de validar.
