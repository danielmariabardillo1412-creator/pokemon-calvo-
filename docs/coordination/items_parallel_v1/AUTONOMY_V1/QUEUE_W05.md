# IA6 — ORDEN PERMANENTE AUTORUN V1 — W05
**Rama exclusiva:** `codex/calvo-items-20261109-w05-books-ui`
**Estado desde el que se reanuda:** LIBROS UI L3 02 cerrado en CI #42714738745 SUCCESS; panel independiente mejorado, IA6 montó versión anterior en FieldItemBag y aún debe incorporar cambios recientes.
**Activador:** `p`, `sigue` o `continúa` inicia o reanuda los **diez bloques de esta tanda**, sin pedir nuevo permiso por cada fila. Se trabaja hasta donde permita el turno/herramientas; si se interrumpe, checkpoint y siguiente `p` retoma la siguiente fila no cerrada.
**Reglas vinculantes:** leer `docs/coordination/items_parallel_v1/AUTONOMY_V1/README.md` de la rama árbitra `codex/calvo-items-20261101-arbitro`. Se autoriza la reparación autónoma en archivos propios, la migración versionada de pruebas históricas y seguir con filas independientes pese a bloqueos. **Nunca saltar pruebas ni inventar L3.**
**Resumen al usuario:** barra de filas revisadas `[████░░░░░░] 4/10` y **funcionales N/10** diferenciadas; solo al final enviar cierre a IA6.
**Informe final único:** `docs/coordination/items_parallel_v1/reports/W05/AUTORUN_V1_FINAL.md`; estado por fila en `AUTORUN_V1_PROGRESS.csv`. No tocar main, V28, PR118 ni otras ramas.

## Tanda 01 — cobertura real de la interfaz para los 49 libros de CAMP006
Son los **49 IDs exactos de la cola canónica aprobada**, divididos en 10 grupos. **No** usar `tm230..tm250`, que no pertenecen a esa cola. No re-implementar enseñanza: reutilizar `FieldItemService.teach`.

| Fila | IDs de la cola | Grupo |
|---|---|---|
| 01 | `tm202;tm203;tm204;tm205;tm206` | L01 CAMP006 |
| 02 | `tm207;tm208;tm209;tm210;tm211` | L02 |
| 03 | `tm212;tm213;tm214;tm215;tm216` | L03 |
| 04 | `tm217;tm218;tm219;tm220;tm221` | L04 |
| 05 | `tm222;tm223;tm224;tm225;tm226` | L05 |
| 06 | `tm227;tm228;tm229;tm01;tm02` | L06 |
| 07 | `tm03;tm04;tm05;tm06;tm08` | L07 |
| 08 | `tm09;tm10;tm11;tm12;tm13` | L08 |
| 09 | `tm14;tm15;tm17;tm19;tm20` | L09 |
| 10 | `tm31;tm36;tm44;tm77` | L10 |

Para cada ID: portada/libro textual ES desde `FieldMachineBookProfile.presentacion`, tipo y etiqueta real, learnset SV y species permitidas, Pokémon compatible e incompatible, falta de stock, bloqueo de sesión, cuatro movimientos con reemplazo obligatorio, intento repetir un movimiento conocido, PP, consumo exactamente uno/rollback, SaveV2 y owner intacto. Al menos una prueba **real** de enseñanza por ID cuando haya especie compatible; si no se halla, registrar fuente y motivo, nunca inventar learnset. Tests parametrizados, **no** generar 49 escenas idénticas ni retocar 49 metadatos de movimientos.

Edición autorizada del panel `scenes/visual/field_machine_book_panel.gd`, fixtures y runners W05, y CI de su rama; no modificar `scenes/visual/field_item_bag.gd`, `FieldItemService`, catálogos, `SaveV2`, políticas, ni fichas canónicas. IA6 unirá los cambios del panel mejorado con la mochila y los repelentes en rama integrada.

CI de fin de tanda debe preservar pruebas originales L3 01/02 y CAMPAÑAS 006/005/004/003, y emitir recibos por grupo, total de IDs con positivos y bloqueados. No atribuir cobertura visual GPU humana; `headless` solo. El usuario recibe un cierre único tras diez filas, no diez solicitudes de autorización.
