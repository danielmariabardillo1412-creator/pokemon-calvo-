# W05 — CONTINUOUS V2 / B03 — Contrato de integración para IA6

**Propiedad:** IA6 es la única autorizada a editar la mochila integrada. W05 entrega pruebas y requisitos, no monta nada en FieldItemBag.
**Rama W05:** codex/calvo-items-20261109-w05-books-ui.

## Archivos concretos
- Panel: scenes/visual/field_machine_book_panel.gd
- Servicio: modules/inventory/field_item_service.gd, su método teach
- Presentación: modules/inventory/field_machine_book_profile.gd
- Localización: modules/localization/machine_moves_es_sv_w05.gd y data/localization/machine_moves_es_sv_v1.json
- Mochila central (IA6 exclusivamente): scenes/visual/field_item_bag.gd
- Runner consumidor real sin mochila: tests/gameplay/parallel_items_w05_continuous_v2.gd
- Verificación de contrato y guarda de tamaño: tests/tools/test_parallel_items_w05_continuous_v2.py

## Diff mínimo propuesto en IA6
1. Montar una sola instancia de field_machine_book_panel.gd en el árbol real de FieldItemBag. Pasar exactamente el mismo FieldItemService de la mochila a bind_existing_service; no crear ni reconfigurar un segundo servicio al recibir señales tardías.
2. Desde la selección del inventario pasar el ID estable de libro a select_book. Desde Party pasar el instance_id real mediante select_creature, nunca el índice de fila. Para cuatro movimientos, seleccionar de forma explícita select_replacement_slot(0–3); -1 sólo si no hay reemplazo obligatorio.
3. Conectar teaching_finished una sola vez. Su callback sólo actualiza visualización/HUD; **no llama de nuevo a teach ni use_item**, pues el panel ya consumió el libro en FieldItemService.teach. Evitar doble evento desde el botón global Usar.
4. Cerrar o revalidar al cambiar sesión, inventario, propietario, Party/Storage o reapertura. No seleccionar automáticamente un Pokémon o libro distinto cuando desaparece la selección. Ningún autosave nuevo; utilizar SaveV2 manual existente.
5. Aplicar la integración sobre el FieldItemBag más reciente de la rama integrada IA6, **no copiar el FieldItemBag antiguo de W05**. Conservar Cuerda Huida (escape_rope), repelentes y demás modificaciones W03; no sustituir en bloque _apply ni _refresh_choices.

## Matriz de aceptación integrada que IA6 debe añadir a su CI
| Puerta | Comportamiento que se debe probar |
| --- | --- |
| A. Apertura | Mochila real, una instancia del panel, abrir/cerrar/reabrir sin señales duplicadas |
| B. Aprendizaje | tm31 x2, Pokémon compatible Party, 4 movimientos, slot 1; un click consume exactamente 1; metal_claw, PP reales, misma instance_id; segundo click no consume |
| C. Propietario | Depositar seleccionado en Storage antes del click; rechazo, estado anterior idéntico y sin seleccionar otro Pokémon |
| D. Mutaciones concurrentes | Quitar libro o bloquear sesión antes del click; rechazar sin alterar objeto/creatura/Storage |
| E. SaveV2 | Guardado manual posterior, recarga de movimiento, PP, x1, Party/Storage y misma identidad; sin autosave |
| F. Convivencia W03 | Tras los pasos anteriores, ejercer Cuerda Huida y repelente en flujos W03 certificados; conservar sus consumos y rollback propios; volver a libros sin regresiones |
| G. Windows visual | Abrir ejecutable en Windows con UI/GPU y ratón; revisar etiquetas, scroll y botones; no inferir FPS ni resultado a partir de headless |

## Ejecución reproducible
Desde raíz, restaurar recursos e importar proyecto con Godot 4.7. Las comprobaciones del panel consumidor son:

- python -B tests/tools/test_parallel_items_w05_continuous_v2.py
- godot --headless --path . --script res://tests/gameplay/parallel_items_w05_continuous_v2.gd

La puerta de montaje estática debe ser roja en W05 y podrá ser verde tras integrar en IA6:

- python -B tests/tools/test_parallel_items_w05_continuous_v2.py --require-integrated

**Importante:** esa puerta sólo comprueba referencias estructurales y NO sustituye la matriz dinámica A–G. IA6 debe ejecutar su propia CI integrada y publicar SHA. El runner W05 verifica el panel auténtico con FieldItemService auténtico pero no el FieldItemBag actual de IA6.

## Evidencia certificada anteriormente, no contada como objetos nuevos
- TANDA01 + TANDA02: 229 enseñanzas, stock, PP y SaveV2 en Godot headless.
- TANDA03: reapertura, guardas, Storage, selección caducada, señales, rechazo y guardado.
- TANDA04: 229 nombres exactos de PokeAPI names.es.
- TANDA05: PCK Windows real, 229 etiquetas, helper cargado del PCK, exportación EXE de 635.385.472 B.
- CONTINUOUS V2: prueba del consumidor y auditoría de distribución con guarda de regresión de tamaño: máximo +10% respecto al EXE anterior (NO es un presupuesto comercial aprobado). Conteo de archivos del workspace distinto del contenido exacto del PCK.

Sin prueba visual Windows/GPU, ni exportación Android; no alegar integración FieldItemBag. **READY_FOR_IA6** sólo cuando la nueva CI W05 sea completed/success.
