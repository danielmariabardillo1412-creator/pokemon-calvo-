# W05 · CONTINUOUS V3 — Auditoría estructural de colisiones para IA6

Fecha de lectura: 2026-11-11. **Solo lectura** de ramas ajenas; ningún cambio a IA6 ni W03.

## Tres versiones de FieldItemBag en conflicto

| Fuente leída | Git blob SHA de field_item_bag.gd | Sistemas observados |
| --- | --- | --- |
| W05 V3 | `0f9461cd7cc7e8e79adae53b3424d94f01c1b2df` | Panel MT `_machine_panel`, libro estable `_machine_requested_book`, callback de solo refresco, botón global `Usar` bloqueado en MT, vínculo del mismo servicio y slot |
| IA6 integrada | `0d0497d661bc28785a76aed73b7e177854fe1a23` | Panel propio `_books_panel`, botón `Abrir libro`, callback `_on_book_teaching_finished`, Cuerda Huida `_apply_escape_rope` |
| W03 | `b09970f8e9802a51538a40050ff3cebc3e6fab6e` | Cuerda Huida con `_world_item_tx`, y repelentes `repel/super_repel/max_repel` mediante `_apply_repel` |

**Hallazgo principal:** la rama IA6 YA contiene una interfaz de libros, pero no está acreditado en este informe que haya superado la matriz V3 en la CI integrada. **NO añadir una segunda instancia sobre ella.** El código W05 es evidencia y referencia de implementación, no un archivo para copiar sobre IA6.

**Hallazgo W03:** en la instantánea observada de IA6, aparecen `_world_item_tx` y `_apply_escape_rope`, pero NO aparece el tratamiento `repel`/ `_apply_repel` localizado en W03. IA6 debe resolver esta diferencia sobre su HEAD actual antes de declarar convivencia completa.

## Trasplante selectivo propuesto, NO automático

1. **Conservar UNA sola variante del panel MT.** Preferir la estructura que IA6 ya tiene (`_books_panel` y botón explícito), e incorporar desde W05 solamente las garantías validadas que falten: seleccionar por IDs persistentes de libro/Pokémon, retransmitir slot de sustitución 0–3, invalidar selección caducada y bloquear la doble ruta de consumo por `Usar`. Se necesita ejecutar el runner nativo adaptado a nombres de la rama IA6.
2. **Fusión de _ready:** no duplicar `BookPanel.new()` ni `teaching_finished.connect`; mantener `WorldItemTx` y `_books_button`, no añadir `_machine_panel` si `_books_panel` ya existe.
3. **Fusión de _refresh_choices:** preservar la excepción Cuerda Huida, que no requiere objetivo Pokémon y retorna pronto. Si IA6 incorpora repelentes W03, preserva sus controles `_repel_effect` y stock. Separar bloqueo `Usar` de MT y permisos de `Usar` de Rope/Repel. No devolver prematuramente antes de actualizar el botón/libro.
4. **Fusión de _apply:** mantener `await _apply_escape_rope()` y la futura `_apply_repel()`. La rama W05 bloquea `service.use_item` para MT porque el panel enseña; hacerlo específico a `machine_rows`, no a cualquier objeto. El callback no repite ninguna operación de servicio.
5. **Propiedad/SaveV2:** transacción autoritativa sigue en `FieldItemService.teach`, sin autosave. Guardar manual, cargar, restaurar mismo Pokémon y PP; revalidar en cada evento del panel.
6. **No utilizar cherry-pick del archivo entero.** Extraer cambios lógicos por función y contrastarlos con el HEAD IA6 del momento; estos SHA son solo una instantánea.

## Matriz de CI integrada imprescindible

- [ ] UN panel montado, sin señales duplicadas al abrir/cerrar/reabrir
- [ ] 229 IDs visibles, nombres ES de PokeAPI y stock correctos
- [ ] Slot 0, 1, 2, 3, cancelación (-1), PP y exactamente 1 libro descontado
- [ ] Bloqueo de `Usar` global durante la enseñanza, sin doble consumo
- [ ] Cambio de propietario Party → Storage y eliminación de stock durante selección: NO consume y no salta a otro libro/creatura
- [ ] Guardado manual SaveV2, recarga correcta y ninguna operación de autoguardado
- [ ] Cuerda Huida: retorno mundo, gasto único, rollback cuando falla
- [ ] Repelente normal/súper/máximo: efecto, duración, rechazo y stock/rollback según runner W03
- [ ] Regresiones históricas W01–W05 pertinentes y CI IA6 completed/success sobre el SHA integrado exacto

## Evidencia W05, diferente de CI IA6
Runner actual W05: `tests/gameplay/parallel_items_w05_continuous_v3.gd`, con el `FieldItemBag` auténtico de W05, no con la versión IA6. La nueva prueba cubre cuatro slots, cancelación, doble click, stock, dueño, lock y SaveV2; no puede acreditar W03 en otra rama. Documento de APIs previo: `docs/coordination/items_parallel_v1/CONTINUOUS_V2/W05_IA6_ACCEPTANCE.md`.

**No se ha modificado IA6/W03, main, V28 ni PR118.** Windows GPU y Android siguen sin prueba integrada.
