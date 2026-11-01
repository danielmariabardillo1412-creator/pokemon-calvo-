# IA5/W05 — CAMPAÑA_001 / ITER_02: metadatos textuales de libros

**Estado:** `PREPARADO_PENDIENTE_CI`; microbloque **02/03** entregado, sin certificación Godot del cambio nuevo.

- **Orden:** `campaigns/CAMP_001_W05.md` blob `ce0e5763accadecc9c4ee971b13dae7dba23a2ef`; puerta vigente `CAMPAIGN_GATE_UPDATE_003.md` blob `59c553bd7a931ebe4ac10bf4b2b3ce43815220dc`.
- **Gate previo resuelto por IA6:** adaptador consulta ITER_01 integrado `39df72c1`, 18 comprobaciones Godot PASS y CI árbitra [#41350909378](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41350909378) `success`. No confundir con CI de ITER_02.
- **Sincronización:** merge de dos padres en rama exclusiva W05 `9d01b3c985915d2070d5d41aa77429df44fc4d01`; incorpora árbitra `8e170550881861daa3a3aefe8aa91909decf84af` conservando informe 01, CSV y cuaderno propios, sin force.
- **Código:** [`modules/inventory/field_machine_book_profile.gd`](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/modules/inventory/field_machine_book_profile.gd), commit `74e68e55d5d5abbdaf49e2afc6a956f828eeebe2`.
- **Cambio autorizado:** nueva función `presentacion(item_id, perfil, catalogos)` que reutiliza `consultar()` y `SpanishGameText.move_name/type_name`, sin mapa paralelo. Devuelve `item_id`, `move_id`, `type_id`, `etiqueta`, `categoria_presentacion` y `clasificacion_tipo`, preservando el rechazo heredado.
- **Test preparado:** [`tests/gameplay/parallel_items_w05_machine_books_v1.gd`](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/tests/gameplay/parallel_items_w05_machine_books_v1.gd), commit `6d15aba76b8f69874012cd28aa0a2c06c096adc1`, ampliado para leer el CSV real y verificar 229 MT activas: movimiento canónico, etiqueta textual, tipo original/traducción; 19 heredadas con rechazo explícito y sin etiqueta.
- **Evidencia estática EJECUTADA** leyendo blobs reales de GitHub: 248 seleccionadas, 229 SV, 19 heredadas, 0 sin mapa, 0 ID repetido; `tm01=take_down`, `tm02=charm`, `tm03=fake_tears`, `tm04=agility`. Nuevo adaptador sin operaciones de escritura detectadas.
- **Godot 4.7 sobre este SHA:** `SIN_EJECUTAR`; script ampliado y etiquetas no certificados. En este entorno no hay binario Godot ni checkout completo.
- **Reproducción tras integración/CI de IA6:** `godot --headless --path . --script res://tests/gameplay/parallel_items_w05_machine_books_v1.gd`. Si falla, no manipular fixture ni certificar PASS.
- **Sin diseño gráfico:** cero texturas, paletas y seis modelos de libro creados. Se mantiene la denominación libro en español, sin CD/USB ni reglas de imagen inventadas.
- **Producción compartida intacta:** ni `FieldItemService.teach`, inventario, fuentes canónicas, learnsets, selección, saves ni las 19 máquinas históricas modificados.
- **Próximo paso si no hay FAIL:** ITER_03, pruebas integradas de enseñanza/PP/consumo por servicio existente; IA6 gestionará CI de ITER_02 por paquete. No ejecutar sin nuevo `p`.
