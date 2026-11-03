# IA3/W03 — CAMPAÑA_004, ITERACIÓN 02

**IDs autorizados:** `black_flute;blue_flute;escape_rope`. Exclusivamente rama `codex/calvo-items-20261103-w03-camp004`.

## Inspección de soporte real

Los tres IDs están seleccionados como `FIELD_USE` en `RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`. `FieldItemService.use_item` no encuentra un ejecutor funcional para ellos en las rutas actuales (`FieldEffects`, `Growth`, `EncounterModifiers`, máquinas/evoluciones) y retorna `DEPENDENCY_MISSING / field_effect_not_connected`.

La Flauta Azul debería necesitar una acción de curar el sueño; Flauta Negra, conexión al sistema de encuentros; Cuerda Huida, posición y transición de mapa. **No existen contratos autorizados en esta campaña para introducir esos efectos**. La mera presencia de las flautas en el listado de metadatos equipables no prueba que tengan un efecto pasivo/usable. La ausencia de inventario para un objeto sin ejecutor actualmente también termina en `field_effect_not_connected`: registrar como limitación de precedencia, no interpretar como un uso exitoso.

## Pruebas Godot y Python

La función `_block_02` usa `service_for()` del entorno real y `FieldItemService.use_item`. Recorre 3 objetos, estado normal y dormido, inventario 0/2; exige rechazo y mismo snapshot de criatura, mochila y relojes. Comprueba además roundtrip `PlayerInventory.to_dict/from_dict`, bloqueo de campo, inventario corrupto y objetivo ajeno, todos sin consumo ni efecto. La condición dormida protege contra una falsa curación por Flauta Azul.

El auditor Python exige los IDs y fuentes reales, comprobaciones de integridad, rechazos, serialización y fuente de selección. **La prueba de roundtrip de mochila es únicamente evidencia del inventario, no de un efecto de campo ni del guardado integral SaveV2**.

## Dependencias para IA6

- **Flauta Negra:** fuente de modificaciones de encuentros y duración/persistencia, no un equipable ficticio.
- **Flauta Azul:** servicio de curación de sueño, elegibilidad y consumo según referencia escogida.
- **Cuerda Huida:** destino seguro, mapa y transición persistente.
- En los tres casos, decidir responsabilidades y API de sesión antes de editar producción compartida.

**Estado previsto si CI pasa:** `DEPENDENCIA_COMPARTIDA` con rechazo seguro y preservación de inventario comprobados; **no** `FUNCIONAL_VERIFICADO`.

**Regresión:** el workflow mantiene CAMP003 y las pruebas del bloque 01 de CAMP004. No se han modificado módulos de producción, main, V28, workflows, catálogo ni ramas ajenas.
