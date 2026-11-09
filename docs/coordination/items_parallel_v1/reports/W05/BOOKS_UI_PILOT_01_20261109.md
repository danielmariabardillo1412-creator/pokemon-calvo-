# IA5/W05 — PILOTO LIBROS-UI-L3 01 · 9 noviembre 2026

## Alcance y estado

Nueva rama exclusiva codex/calvo-items-20261109-w05-books-ui. CAMPAÑA_006 sigue FINALIZADA: 10/10, 49/49 MT SV. Este piloto no crea MT ni campaña adicional.

Estado de publicación inicial: PILOTO_EN_CI. Estado final certificado: PILOTO_01_CI_PASS_CON_SEAM_PENDIENTE.

## Entregables

1. scenes/visual/field_machine_book_panel.gd: PanelContainer montable y separado de la mochila. Enlace al FieldItemService ya configurado por FieldItemBag mediante bind_existing_service(service). Lee directamente owner.inventory y owner.party; llama FieldMachineBookProfile.presentacion; muestra tipo y nombre español, compatibilidad basada en learnset SV real, opciones de sustitución, botón de enseñar y resultado. Solo service.teach aplica movimientos, consumo y validaciones; no hay segundo motor ni SaveV2 nuevo.
2. tests/gameplay/parallel_items_w05_book_ui_pilot_20261109.gd: Godot SceneTree con panel real, selecciones, pulsación de botón, tm202/pain_split y tm31/metal_claw, stock agotado, full moves + reemplazo, incompatible, PP, consumo, identidad, SaveV2 al guardar y cargar.
3. tests/tools/test_parallel_items_w05_book_ui_pilot_20261109.py: manifest estático de mapeo SV, límites, y conservación de las 49 MT.
4. Todos los runners CAMP006 y regresiones CAMP005, CAMP004, CAMP003 quedan bajo el workflow existente de esta rama y no se han relajado.

Los nombres de los dos movimientos se localizan en este panel como Divide Dolor / Garra Metal. Su move_id, type_id, versión, PP y autorización siguen viniendo del perfil y del catálogo existentes. Se deja la localización general para IA6.

## Contrato pendiente de unión con la mochila real (permiso IA6)

No se ha editado scenes/visual/field_item_bag.gd. Ese archivo ya usa un FieldItemService ligado con field.field_bind_item_service(service), tiene selección de MT y ejecución por service.use_item. Para presentar el nuevo panel desde esa bolsa, IA6 deberá autorizar la inserción del componente y dos llamadas:
- panel.bind_existing_service(field_item_bag.service)
- panel.select_book(item_id)
Cuando panel.teaching_finished(result) indique un resultado, reusar field_item_bag.refresh y field.field_refresh_hud, sin repetir service.use_item. El servicio ya es la fuente de autoridad, sin escrituras nuevas en SaveV2 ni motores duplicados.

Alcance demostrado a verificar en CI: integración local del panel con servicio y SaveV2. No hay todavía entrada montada en FieldItemBag (L3 global pendiente) ni revisión humana visual/GPU.

## CI

CI bootstrap 42690009491: completed/success en 09ce28c5fcc9e9764603e1489fcb321e567654fd, antes de agregar el piloto; no es el recibo del trabajo nuevo.

Se exigen nueva CI SUCCESS, recibos PY/GODOT propios, CAMP006 49/49, y regresiones CAMPAÑA_003/004/005 completas. Documentar SHA de prueba y job, y si falla corregir solo esta rama.

STOP tras piloto 01. No cambiar FieldItemBag, main, V28, PR118, árbitra, ramas W01-W04 ni catálogos/learnsets compartidos, ni realizar merges.

## Recibos CI reales y veredicto L2/L3

GitHub Actions #42697722250: https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42697722250
SHA funcional probado: 75883f53edbd977810b9234b3014f0c5ecf69096. Job 129433913836. Estado: completed/success.

- W05_BOOK_UI_PILOT_20261109_PY PASS checks=17
- W05_BOOK_UI_PILOT_20261109_GODOT PASS checks=88
- CAMP006_W05_MANIFEST_PASS reserved=10 completed=10 ids=49 kind=NEW_IDS
- CAMP006_W05_PY PASS blocks=10 checks=481
- CAMP006_GATE_PY_PASS worker=W05 blocks=10 checks=481
- CAMP006_W05_GODOT PASS blocks=10 checks=1781
- CAMP006_GATE_GODOT_PASS worker=W05 blocks=10 checks=1781
- CAMP005_W05_PY PASS blocks=10 checks=580
- CAMP005_W05_GODOT PASS blocks=10 checks=2166
- CAMP004_W05_PY PASS blocks=10 checks=580
- CAMP004_W05_GODOT PASS blocks=10 checks=2166
- CAMP003_W05_PY PASS blocks=10 checks=580
- CAMP003_W05_GODOT PASS blocks=10 checks=2166

Los recibos demuestran instancia real de PanelContainer headless, selectores y botón, casos tm202/pain_split y tm31/metal_claw, incompatibilidad, ausencia de stock, selección y sustitución de movimiento con cuatro slots, PP, un consumo unitario y no consumo por rechazos, identidad del Pokémon y guardado/carga SaveV2. La prueba Python es estática y no debe contabilizarse como 17 ejecuciones Godot adicionales.

Clasificación: L2 previamente certificado mediante FieldItemService.teach; piloto de presentación e integración L3 **aislada** panel → FieldItemService → SaveV2 certificado en headless; L3 **de la mochila FieldItemBag real sin montar** y revisión de aspecto/GPU **NO CERTIFICADAS**. Es una dependencia de integración con permiso IA6, no un PASS global. No se cambió FieldItemBag, SaveV2 central, FieldItemService, catálogos/learnsets ni ramas ajenas.

Diff de código y pruebas propio: scenes/visual/field_machine_book_panel.gd, tests/gameplay/parallel_items_w05_book_ui_pilot_20261109.gd, tests/tools/test_parallel_items_w05_book_ui_pilot_20261109.py, informe y continuidad. El panel de presentación local conserva interfaz para IA6: bind_existing_service(servicio_actual_de_bag), select_book(item_id), teaching_finished(result). No conectar un segundo uso a service.use_item o gastar dos veces. STOP: esperar orden expresa de IA6.
