# IA5/W05 — TANDA 04 · checkpoint de preparación (2026-11-10)

**Rama exclusiva:** `codex/calvo-items-20261109-w05-books-ui`. **Autoridad:** `IA6_AUTORUN.md` de esta rama y `AUTONOMY_V1/QUEUE_W05_TANDA_04.md` en árbitra. La última CI verde de T03 es #42870869700 en SHA 048a1427 (documental).

## Datos y alcance

Se localizaron los 229 movimientos SV por `machine_rows` y por el índice PokeAPI copiado al repositorio. Se inspeccionaron **229 JSON fuente individuales** y sus objetos `names` con `language.name="es"`; todos tienen un nombre es explícito, ninguno falta. Los 229 movimientos son distintos y corresponden a 229 MT originales, sin añadir ningún ID. El resultado se consolidó en un nuevo JSON versionado `data/localization/machine_moves_es_sv_v1.json` con `move_id → nombre_es/source_api_id/source_blob_sha/item_id`. Las fuentes `es-419` o inglés no se usarán como ES.

Se compararon los CORE globales: conflicto **uno**, `light_screen`: antiguo `Pantalla Luz` frente a fuente PokeAPI `es` `Pantalla de Luz`. Se selecciona fuente ES **solo en el panel/perfil de libros**. `SpanishGameText` permanece intacto.

En `modules/localization/machine_moves_es_sv_w05.gd` se añadió helper exclusivamente de lectura; el único método modificado de `modules/inventory/field_machine_book_profile.gd` es `presentacion`. El panel propio usa resultados del perfil para lista, título, sustitución y confirmación. Si faltase fuente válida, muestra el aviso honesto de fallback, sin enseñanza alternativa.

Para migrar V3 (11 nombres previamente acreditados y 218 fallback, prueba histórica certificada en SHA 93b13e63), el runner nuevo de HEAD verifica explícitamente los **218 promovidos** mediante el conjunto exacto de claves PokeAPI; se conserva historia y se añade prueba V4 positiva por **cada uno de los 229**. No se silencia V1/V2/V3 ni CAMP003–006. La revisión de rendimiento sigue siendo headless, no GPU.

**Estado:** artefactos preparados, CI nueva pendiente. No marcar grupos funcionales hasta obtener recibos del SHA nuevo. Cualquier error dentro de archivos W05 propios se repara con CI; si hay dependencia protegida se documenta BLOQUEADO.

**Archivos protegidos sin cambio:** FieldItemBag, FieldItemService, SpanishGameText global, SaveV2 central, catálogos, PokeAPI original, learnsets, main, V28, PR118, otras ramas. Sin merge.
