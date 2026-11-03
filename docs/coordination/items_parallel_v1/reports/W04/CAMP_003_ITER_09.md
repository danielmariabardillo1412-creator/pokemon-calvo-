# IA4 / W04 — CAMPAÑA_003 / Microbloque 09

**Rama exclusiva:** `codex/calvo-items-20261103-w04-camp003`  
**Estado:** `EN_CI_AUTOMATICA` — pruebas de bloque 09 publicadas, CI aún sin certificar.

## Cola autorizada
- `unremarkable_teacup`
- `sweet_apple`
- `tart_apple`

## Puerta previa (CI bloque 08)
Ejecución [#41571247167](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41571247167), `completed/success`, SHA `f0c33388cb7e6ef428c3b80142a6170b1be69b5f`: `CAMP003_W04_PY PASS blocks=8 checks=92` y `CAMP003_W04_GODOT PASS blocks=8 checks=180`.

El runner confirmó positivos sobre `chipped_pot`, `cracked_pot` y `masterpiece_teacup`, pero sus registros del catálogo mostraron `conditions={}`. La CI confirma su ruta de uso y persistencia en el motor actual, **no** la discriminación canónica entre formas auténticas y no auténticas. Se conserva la dependencia de forma para revisión de política/datos.

## Nuevas pruebas acumuladas (01–09)
- Runner Godot: `dbd8a504d0b8ac7c79c5bf3190be820f59caabf3`. Amplía la consulta de registros a bloque 09 y registra origen, destino y condiciones `base_form` reales. Conserva positivos, rechazo de destino equivocado, gasto único, identidad y SaveV2 cuando la ruta está clasificada `RUNTIME_SUPPORTED`.
- En los tres objetos se comprueba que Eevee, como especie incompatible, no tenga opciones ni evolución, ni pierda unidades ni atributos.
- Para `sweet_apple` / `tart_apple`, si el catálogo define alternativas con destino diferente para el mismo origen, se prueba explícitamente el destino de la **otra** manzana: el servicio debe rechazarlo sin consumir ni modificar el estado. No se asume que dichas rutas existan.
- Fixture: `2559b7dccc9796f9da0ec798e8614d227f01cc88`, añade únicamente 09, preserva 01–08.
- Validador Python: `06a2b94e379ff775f66829eca09bd3a3a1f40d80`, exige los IDs de 09, fixture, pertenencia al catálogo y nuevas aserciones sobre destino cruzado.
- Progreso: `b7a09e2ee4576f3fe84e6dd2c9e90ae5258cc3c2`; deja 08 `CI_PASS_VERIFICADO` y 09 `EN_CI_AUTOMATICA`.

## Contratos y límites
No se ha editado `main`, V28, producción, catálogos, políticas ni otra rama. Las condiciones de forma, si el catálogo no las define, se consignan como dependencia: **un PASS del arnés no certifica todas las formas**. No se inventan especies ni nuevos triggers.

**Pendiente:** comprobar nueva CI sobre el SHA que contiene runner + fixture + validador + progreso, y sus recibos `CAMP003_W04_PY PASS blocks=9 checks=M` y `CAMP003_W04_GODOT PASS blocks=9 checks=M`. Si falla, diagnosticar y reparar solo dentro de W04 conforme a `AUTONOMOUS_REPAIR_V5.md`.

**Próximo `p`:** bloque 10/10, `syrupy_apple`, `scroll_of_darkness`, `scroll_of_waters`, salvo fallo real anterior.
