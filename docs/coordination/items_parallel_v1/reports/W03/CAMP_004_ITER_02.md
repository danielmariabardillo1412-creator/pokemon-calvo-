# IA3/W03 — CAMPAÑA_004 — MICROBloque 02/10

**Reserva:** `black_flute;blue_flute;escape_rope`. **Rama exclusiva:** `codex/calvo-items-20261103-w03-camp004`.

## Auditoría de código funcional (corrección importante)

El perfil `modules/inventory/imported_recovery_v19.json` incluye la **Flauta Azul** con `effect.cure=["slp"]` y `consume=false`. `FieldItemService.use_item` usa `FieldEffects.supports`, prepara copia del Pokémon, aplica el efecto de recuperación y publica un cambio de identidad de criatura preservando el ID. Al curar sueño borra también el reloj correspondiente. Se actualizó la prueba para **verificar el caso positivo real, no rechazarlo**.

- **blue_flute:** curación real del sueño con objeto en mochila; reusable, cantidad intacta. Sin sueño y con objeto se rechaza por `item_has_no_effect`; sin objeto se rechaza por `item_not_owned`. Se verificará en CI.
- **black_flute:** no hay ruta de alteración autoritativa de encuentros; uso directo vuelve `field_effect_not_connected` sin gasto.
- **escape_rope:** no hay ruta autorizada de navegación/destino de mapa; uso directo vuelve `field_effect_not_connected` sin gasto.

## Pruebas reales

La suite Godot llama a `FieldItemService.use_item` con estado dormido/no dormido y existencias 0/2, comprueba el efecto positivo y persistencia de cantidad en Flauta Azul; para todas las pruebas negativas exige snapshot sin mutaciones, campo bloqueado, inventario corrupto y objetivo ajeno. Un roundtrip `PlayerInventory.from_dict(to_dict())` comprueba la persistencia básica de mochila, **no SaveV2 integral**.

Python verifica la existencia del perfil con cura de sueño no consumible, el enrutamiento funcional y los contratos de dependencias. Los bloques 01 y 02 son acumulativos y CAMP003 se regresiona en el workflow oficial.

**Estado:** Flauta Azul `FUNCIONAL_PENDIENTE_CI`; Flauta Negra y Cuerda Huida `DEPENDENCIA_COMPARTIDA`. **CI de bloque02 pendiente** en el último SHA de pruebas/fixture.

## Frontera con IA6

La conexión de Flauta Negra con encuentros y Cuerda Huida con mapa y guardado son cambios de subsistemas compartidos; no se ha modificado producción. No se ha inventado efecto pasivo o persistencia de posición. `main`, V28, workflows, política, datos y ramas ajenas intactos.
