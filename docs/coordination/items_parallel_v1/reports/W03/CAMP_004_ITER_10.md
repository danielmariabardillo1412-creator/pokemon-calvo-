# IA3/W03 — CAMPAÑA_004 / MICROBloque 10

**Reserva autorizada:** `psychic_tera_shard;rock_tera_shard;steel_tera_shard;water_tera_shard`. **Rama exclusiva:** `codex/calvo-items-20261103-w03-camp004`.

## Auditoría del estado

Los cuatro Teralitos —Psíquico, Roca, Acero y Agua— constan como `TERA_MATERIAL` y `SELECCIONADO` en el scope oficial. Las reglas actuales de `PlayerInventory` permiten almacenar hasta 999 unidades, consultar, retirar, reponer y reconstruir cantidades desde `to_dict/from_dict`. La política de selección no los excluye.

No se ha encontrado una ruta de ejecución de teracristalización para ellos en `FieldItemService.use_item`, el perfil importado de recuperación ni los modificadores de encuentros. El uso directo devuelve `DEPENDENCY_MISSING / field_effect_not_connected`. **El rechazo sin consumo no significa que exista una mecánica Tera funcional.**

## Pruebas incorporadas

El runner Godot `_block_10` comprueba los cuatro IDs con cantidades 0, 1, 25 y 999: `add`, `has`, `quantity`, `remove`, restauración, desbordamiento de pila y roundtrip `PlayerInventory`. Invoca el servicio real de campo para demostrar rechazo sin gasto ni cambios de criatura, bolsa o relojes; cubre campo bloqueado e inventario corrupto. El auditor Python coteja la reserva 10, los registros seleccionados, el contrato real, la ausencia de ejecutores y la cobertura Godot.

**Estado por ID:** `DEPENDENCIA_COMPARTIDA` respecto a uso Tera. Una CI verde valida las pruebas de almacenamiento y rechazo, pero no cambio de tipo, consumo para teracristalizar, condiciones de batalla ni SaveV2 integral.

## Cierre condicionado de CAMPAÑA_004

Con las diez filas oficiales publicadas se habrá cubierto la cola W03: tres bolas contextuales, quince objetos de campo y dieciocho fragmentos Tera. Esta finalización de auditoría **no equivale a 36 objetos funcionalmente implementados**. La Flauta Azul dispone de efecto de curación existente con cobertura positiva; quedan dependencias funcionales anotadas en cada informe.

**CI anterior confirmada:** [#41579091544](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41579091544) CAMP004 Python 169/Godot 1178 PASS y regresiones CAMP003 Python 279/Godot 986 PASS.

**CI final CAMP004 bloque 10:** comprobar recibos `CAMP004_W03_PY PASS blocks=10` y `CAMP004_W03_GODOT PASS blocks=10`, más manifiesto, regresiones y SHA del CSV. No afirmar `CAMPAÑA_004_FINALIZADA` hasta ese éxito.

Dependencias para IA6: APIs de encuentro/captura/mundo, efectos de campo restantes y decisión e integración de teracristalización. No tocar `main`, V28, producción, datos globales, workflows ni ramas ajenas; al terminar 10/10, STOP sin inventar CAMPAÑA_005.
