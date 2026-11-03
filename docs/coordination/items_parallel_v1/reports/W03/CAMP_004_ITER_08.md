# IA3/W03 — CAMPAÑA_004 / MICROBloque 08

**Reserva exacta:** `fighting_tera_shard;fire_tera_shard;flying_tera_shard;ghost_tera_shard;grass_tera_shard`. Rama exclusiva: `codex/calvo-items-20261103-w03-camp004`.

## Auditoría de fragmentos Tera

Los cinco Teralitos —Lucha, Fuego, Volador, Fantasma y Planta— aparecen como `TERA_MATERIAL` y `SELECCIONADO` en `docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`. La política de selección no los excluye. Su almacenamiento depende del sistema `PlayerInventory`, que permite añadir, consultar, extraer, reponer y serializar cantidades conforme al máximo de 999 por pila.

La consulta de rutas actuales (`FieldItemService.use_item`, `FieldEffects`, `EncounterModifiers` y `imported_recovery_v19.json`) no acredita un ejecutor que aplique teracristalización. El uso directo actual retorna `DEPENDENCY_MISSING/field_effect_not_connected`. **Estado por ID: `DEPENDENCIA_COMPARTIDA`**, no `FUNCIONAL_VERIFICADO`.

## Pruebas reales y regresión

La suite Godot propia `_block_08` cubre cada ID con 0, 1, 25 y 999 unidades, `add/has/quantity/remove`, reposición, límite de pila, roundtrip de `PlayerInventory.from_dict(to_dict())`, rechazo de `FieldItemService.use_item` sin mutación y controles de campo bloqueado y mochila corrupta. Python valida la cola oficial, selección, contrato existente, exclusión, ausencia de ejecutor y cobertura Godot.

La CI acumulativa debe ejecutar bloques 01–08 y las regresiones CAMP003 W03. El éxito de la mochila **no supone** SaveV2 integral, cambio de tipo Tera, uso en combate ni consumo de materiales para transformar.

**Dependencia compartida para IA6:** decisión normativa sobre material y coste, productor del cambio de tipo Tera, condiciones de combate, estado persistente y contrato de guardado. No se implementó ni simuló ninguna de esas piezas; no se han modificado módulos funcionales.

## Estado de entrega

**Bloque 07 validado:** [GitHub Actions #41576607990](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41576607990), `CAMP004_W03_PY PASS blocks=7 checks=133`, `CAMP004_W03_GODOT PASS blocks=7 checks=805`; regresión CAMP003 Python 279/Godot 986 PASS.

**Bloque 08:** pendiente de la CI propia del SHA definitivo con ocho filas; no registrar PASS antes de ver los recibos. Sin cambios en `main`, V28, PR #118, catálogo, workflows o ramas ajenas.
