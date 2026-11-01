# IA5 / W05 — CAMPAÑA_001_FINALIZADA

**Estado:** tres microbloques entregados (03/03); el tercero está `PREPARADO_PENDIENTE_CI`. **STOP** hasta nueva asignación oficial IA6.

## Matriz comprobable

| Bloque | Alcance | Código / evidencia | Estado |
| --- | --- | --- | --- |
| 01 consulta | ID máquina → movimiento SV → tipo; rechazo de no activas | `field_machine_book_profile.gd` y prueba `parallel_items_w05_machine_books_v1.gd`; CI #41350909378, 18 checks | INTEGRADO_VERIFICADO_IA6 |
| 02 presentación | 229 etiquetas/tipos canónicos + 19 legadas rechazadas, de 248 MACHINE seleccionadas | `presentacion()` sobre `consultar()`; CI #41362733419, Godot 959 checks/0 errores, Python 14 PASS | INTEGRADO_VERIFICADO_IA6 |
| 03 integración | Subconjunto `tm01`, `tm02`, `tm77`; pruebas de enseñanza, PP, gasto, propiedad y guardado; 19 negativas exhaustivas | Suite Godot ampliada, commit `c48491a3e50f0386cec76d72402b1e5cdcd4d3e3` | PREPARADO_PENDIENTE_CI |

## Alcance exacto y límites

- **Inventario seleccionado:** 248 máquinas, 229 activas Scarlet/Violet, 19 heredadas sin versión activa. Cotejo estático sobre catálogo y `item_connections_v1.json`, 0 ausentes, 0 duplicadas.
- **Fuente funcional única:** `modules/inventory/field_item_service.gd:teach()` se reutiliza sin modificaciones. El perfil de libros solo lee metadatos; no enseña, consume, equipa ni persiste objetos.
- **Prueba ITER_03 preparada:** tres MT representativas; rechazos por falta de stock, identidad ajena, campo bloqueado o movimiento repetido; PP correctos; consumo unitario; guardado/carga de prueba para `tm01`; 19 heredadas no aplicadas. Son **escenarios escritos**, no PASS ejecutados.
- **Pendiente de IA6:** ejecutar Godot 4.7 en SHA integrado y verificar salida no nula ante cualquier error. Reproducir: `godot --headless --path . --script res://tests/gameplay/parallel_items_w05_machine_books_v1.gd`.
- **No certificado:** nuevas rutas de ITER_03, GPU/visual, sprites y seis modelos de libros, UI final, interacción de todas las máquinas con cada especie, migraciones, habilitación de heredadas.
- **Políticas preservadas:** no se activaron 19 máquinas históricas, ni se deduplicaron `hm05` y `tm77`, ni se crearon reglas de MO/DT nuevas o medios anacrónicos CD/USB.
- **Ramas preservadas:** trabajo exclusivo `codex/calvo-items-20261101-w05`; `main`, V28, PR #118, árbitra y otras trabajadoras sin escrituras. Documentos anteriores LOTE_001/LOTE_002 e ITER_01/02 conservados.
- **Continuación:** IA6 revisa diff permitido, ejecuta CI y certifica o devuelve diagnóstico preciso; **no ejecutar un cuarto `p`** ni empezar CAMPAÑA_002 sin autorización.
