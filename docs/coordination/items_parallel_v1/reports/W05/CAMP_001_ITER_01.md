# W05 — CAMPAÑA_001, microbloque 01 (recuperación de publicación por IA6)

**Estado:** PREPARADO_PENDIENTE_CI. **Ningún PASS funcional nuevo afirmado.**

- Incidencia: W05 publicó correctamente el adaptador en `318e6b96d92db49c9c4125d3ad67c008ac5e9371`, pero sus escrituras posteriores fueron rechazadas; no llegó a publicar test ni informe.
- Intervención excepcional de IA6 solicitada por la persona usuaria: se verificó el HEAD, se preservó el commit previo y se restauró la publicación **solo** en las rutas exclusivas de W05; no se modificó otra rama.
- Nuevo probe Godot: `tests/gameplay/parallel_items_w05_machine_books_v1.gd`, creación `d2474b9914b3a311670513c469b7b639c8bc5b16`, ajuste de aserción `62741e4d7ae8be8797cea27569ebb50906b8be13`.
- El probe verifica lectura de `tm01`/`tm02` según mapeo `scarlet-violet`, tipo real en `DefinitionCatalog`, rechazo de `hm01` histórica, ID inexistente, versión histórica y catálogo nulo.
- Contrastado **estáticamente** por IA6 con el catálogo de selección y `item_connections_v1.json`: 248 IDs MACHINE, 229 activos, 19 heredados sin SV, 0 IDs sin mapa, 0 IDs repetidos. El mapeo activo `tm01=take_down`, `tm02=charm`; `hm01` sin SV.
- **SIN_EJECUTAR:** el nuevo script Godot, regresión por SHA, tests Python nuevos, CI integrada y visual/GPU. Se ha confirmado una publicación GitHub exitosa desde la conexión IA6, no que el problema de la sesión W05 esté definitivamente resuelto.
- El adaptador es solo de consulta y no modifica `FieldItemService.teach`, inventario, estado, guardados, políticas ni las 19 máquinas heredadas.
- Recuperación de documentación: este informe, `CAMP_001_PROGRESO.csv` y `CONTINUIDAD.md`. La prueba del cambio funcional de adaptador debe ejecutarse en CI Godot 4.7 antes de certificarlo.
- **Siguiente paso de W05:** leer esta recuperación, comprobar la rama y la puerta, no repetir el microbloque 01, y no avanzar si la verificación pendiente constituye bloqueo según el protocolo; elevar a IA6 el gate para integrar/prueba de este paquete. Si CI falla, STOP y diagnóstico.

**Comando de prueba cuando se integre en un checkout ejecutable:** 
`godot --headless --path . --script res://tests/gameplay/parallel_items_w05_machine_books_v1.gd`
