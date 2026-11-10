# IA5/W05 — AUTORUN V1 TANDA 01 · CHECKPOINT ANTES DE CI

**Rama exclusiva:** codex/calvo-items-20261109-w05-books-ui. **Autorización:** rama árbitra AUTONOMY_V1/README.md + copia vinculante IA6_AUTORUN.md, 10 filas / 49 MT SV de CAMP006.

## Estado al publicar

Se creó un único runner Godot parametrizado `tests/gameplay/parallel_items_w05_book_ui_autorun_v1.gd` que recorre los 10 grupos exactos desde el fixture histórico CAMP006 y ejercita un PanelContainer real para cada libro, compartiendo `FieldItemService.teach`. Por cada ID: presentación ES desde FieldMachineBookProfile, tipo, compatibilidad y especie permitidas, cuatro slots y reemplazo, ausencia de stock, guard field_locked, movimiento ya conocido, exactamente un libro consumido, identidad, PP, SaveV2 y caso incompatible. Si el dato real no existe, emite BLOQUEADO sin inventar efectos. `test_parallel_items_w05_book_ui_autorun_v1.py` valida la reserva original y la cola oficial, la matriz de permisos y los diez grupos.

**CI pendiente:** workflow existente ampliado para probar estos runners nuevos, manteniendo su piloto histórico L3 01/02 y todas las CAMP006/005/004/003. Los diez registros del CSV son `EN_CI_AUTOMATICA` históricos del push inicial: no constituyen PASS funcional aún. Las filas solo pasan a `CERTIFICADO` si un run ejecutado sobre este código acredita 10 recibos por grupo y positivos reales. En fallos reparar solo tests/panel/CI propios sin relajar regresiones. Fecha 2026-11-10.

**Archivos propios:** test Godot, test Python, workflow W05, progreso e informe de checkpoint. Sin cambios a FieldItemBag, FieldItemService, SaveV2, catálogo, datos, localización, main, V28, PR118 o ramas externas. Sin merge. Pruebas UI headless, no revisión humana/GPU.
