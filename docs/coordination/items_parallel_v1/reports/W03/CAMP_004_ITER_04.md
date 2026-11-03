# IA3/W03 — CAMPAÑA_004 / MICROBloque 04

**IDs autorizados:** `max_lure;max_repel;red_flute`. **Rama de trabajo:** `codex/calvo-items-20261103-w03-camp004`.

## Diagnóstico del motor actual

Los tres objetos están `SELECCIONADO` y pertenecen a `FIELD_USE` según el scope de Randomlock. El servicio `FieldItemService.use_item` carece de un ejecutor reconocido para ellos en las rutas actuales de recuperación, crecimiento, encuentro y evolución/máquinas. La ruta observada de uso directo es `DEPENDENCY_MISSING / field_effect_not_connected`: rechazo seguro, no implementación funcional.

- `max_lure` (Colonia Máxima): requiere conexión confiable con generación/frecuencia de encuentros de mundo y definición de duración.
- `max_repel` (Repelente Máximo): requiere gestión de pasos/encuentros, nivel del líder y transiciones reales.
- `red_flute` (Flauta Roja): requiere acción fiable de curación de confusión, con reglas de elegibilidad y consumo, sin confundirse con el soporte ya verificado de Flauta Azul.

Ninguno aparece en `modules/inventory/imported_recovery_v19.json` ni está referido como ID operativo en `field_item_effects.gd` o `encounter_item_modifiers.gd`. No se ha inferido que su presencia en el catálogo active un efecto.

## Tests

Runner acumulativo Godot `_block_04` ejecuta el servicio de campo real en sus tres IDs, con existencias 0 y 2, criatura normal, dormida o confundida. Para los rechazos, verifica motivo exacto, estado completo de criatura/bolsa/relojes inalterado y cantidad sin consumo; la confusión permanece activa. Incluye guardas de bloqueo, inventario corrupto y objetivo ajeno y un roundtrip estricto `PlayerInventory.to_dict/from_dict`. Auditor Python exige selección, contrato real, conexiones y cobertura del runner. Las suites 01–03 siguen ejecutándose en CAMP004; la regresión de CAMP003 permanece en el workflow oficial.

**No atribuir efecto o SaveV2 integral a un PASS de rechazo.** El roundtrip de inventario no certifica guardado de ubicación, duración de repelentes ni estado de mundo.

## Dependencia compartida a elevar a IA6

Los productores de sesiones, navegación/encuentros y condiciones de estado comparten APIs; implementar cualquiera sin propiedad explícita y definición normativa podría romper sistemas de otras trabajadoras. La campaña autoriza auditoría/pruebas pero no reescribir esos productores.

**Estado previsto tras CI:** `DEPENDENCIA_COMPARTIDA` para los tres; solo `NEGATIVO_VERIFICADO` sobre el servicio presente. No se han modificado `main`, V28, módulos funcionales, workflows, catálogos, PR #118 ni ramas ajenas.

**CI 04:** pendiente de inspección sobre el último SHA de pruebas y progreso.
