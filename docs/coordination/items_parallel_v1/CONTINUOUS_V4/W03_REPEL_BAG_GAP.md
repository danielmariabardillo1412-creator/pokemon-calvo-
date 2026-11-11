# W03 V4 — dependencia de repelentes frente a W05 / IA6

Rama staging: `codex/calvo-ia6-staging-20261111-w03-capture`, base oficial IA6 `e63b2e6c7e175fba318cc2f562bebd1769589092`. Fuente histórica W03 certificada `ef63e824069aa27ce957e99997df8e7a50c78524`.

## Diff comprobado (no trasplantado)

- En origen `scenes/visual/field_item_bag.gd` W03 añadía detección de `repel`, `super_repel`, `max_repel`, `_apply_repel()`, validación de stock y efecto, rollback si falla commit, 100/200/250 pasos de mundo y sin autoguardado. **La base IA6** tiene el panel W05 `_open_machine_books` / `_on_book_teaching_finished` y no incluye esa rama Repel. El blob IA6 `0d0497d661bc28785a76aed73b7e177854fe1a23` se preservó sin cambios.
- En origen W03 `scenes/visual/field_demo.gd` contiene `_repel_effect`, bloqueo de encuentro bajo líder, commit del RNG tras bloqueo, validación/restauración estricta de pasos en SaveV2 de campo. En staging IA6 esas piezas no están. Un efecto de inventario sin bloquear encuentros o sin persistir estado **no es** funcional L3.
- El origen W03 `scenes/visual/field_native_bridge.gd::on_step` reconoce `blocked_by_repel` y hace commit de su RNG; en staging IA6 falta ese hunk.

## Resolución requerida a IA6 (NO permiso W03)

La rama de integración final debe integrar conjuntamente el efecto de campo de W03 y el panel de libros W05 en las funciones relevantes, sin copiar `FieldItemBag` completo. Revisar `_refresh_choices`, `_apply`, `_apply_repel`, `_open_machine_books`, `_on_book_teaching_finished`, `field_demo` y `field_native_bridge`. Repetir las CI de Cuerda Huida, panel MT, pasos repelidos, consumo/rollback, RNG y SaveV2. No eliminar el botón `Abrir libro` ni sobreescribir naturaleza efectiva. La staging W03 **no** tiene autoridad de escritura sobre estos módulos; los deja inalterados.

**Estado:** `BLOCKED_SHARED_SEAM`, cero repeles integrados en V4 staging; la integración oficial sigue pendiente.
