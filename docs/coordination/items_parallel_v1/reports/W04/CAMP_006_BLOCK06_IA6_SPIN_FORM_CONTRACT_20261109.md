# IA4/W04 — CAMPAÑA_006 bloque 06 — Resolver aislado de Milcery y puerta IA6

**Orden oficial:** `docs/coordination/items_parallel_v1/IA6_ORDERS_W03_W04_W05_20261109.md` de rama árbitra, blob `ea8deae329e377ba132f7bc4461fd773e7083043`. **Trabajo exclusivamente en** `codex/calvo-items-20261104-w04-camp006`.

## Estado inequívoco

- `completed=3`; funcionales previos: 01, 02, 03 con las reservas históricas ya documentadas.
- `04=DEFERRED_POR_POLITICA` (V27, sin niveles aprobados). No implementado ni completado.
- `05=BLOCKED_PRODUCER_VERIFIED` (faltan sexo individual, día del mundo y luna). Resolver de condiciones L2 aislado, no L3.
- `06=BLOCKED_SPIN_FORM_PRODUCERS_VERIFIED` (falta giro y selección/persistencia de forma). Resolver nuevo aislado, no L3.
- `last_executed_id=06`, `evaluated_ids=[01,02,03,05,06]`, `blocked_ids=[05,06]`, `deferred=[04]`.
- **Cero objetos nuevos, cero evoluciones Milcery→Alcremie funcionales y cero cambios al esquema de guardado.** No seguir al bloque07 sin otra orden IA6.

## Investigación de fuentes canónicas del repositorio

`data/api/v2/evolution-chain/452/index.json` define una sola ruta `milcery→alcremie`, `trigger=spin`, generación Sword/Shield, `item=null`, `held_item=null`, `min_level=null` y **sin regla de elección de crema ni siete evoluciones use_item**.

`data/api/v2/pokemon/869/index.json` lista **63 formas canónicas**: nueve cremas asociadas a cada uno de los siete confites `berry_sweet`, `clover_sweet`, `flower_sweet`, `love_sweet`, `ribbon_sweet`, `star_sweet`, `strawberry_sweet`. Todas son nombres PokeAPI reales; no se han inventado nombres/variantes.

Los siete confites pertenecen a `holdable_ids` del `modules/inventory/item_connections_v1.json`. No son `use_item` que evolucione Milcery. `EvolutionSystem.classify_record` continúa clasificando `spin` como `UNSUPPORTED`. La inspección de los productores de campo, sesión, progresión y `CreatureInstance` no encontró un evento de **giro del personaje con duración/dirección/hora** ni un `form_id` de criatura que se guarde/cargue en SaveV2. La existencia de 63 entradas fuente no prueba que haya una selección jugable de crema.

## Entrega aislada comprobable

Nuevo módulo puro `modules/creatures/progression/milcery_spin_resolver_w04.gd`:

```gdscript
const MilceryResolver = preload("res://modules/creatures/progression/milcery_spin_resolver_w04.gd")
var result := MilceryResolver.inspect(
    canonical_milcery_spin_record,
    &"milcery", creature.held_item_id, creature.held_item_consumed,
    spin_event, canonical_form_names)
# {preconditions_valid: bool, evolution_ready: false,
#  candidate_forms: Array, reason: String,
#  scope: "PURE_SPIN_PRECONDITIONS_ONLY", mutates: false}
```

- `canonical_form_names` debe provenir del catálogo de formas original. El resolver lista únicamente los nueve nombres canónicos de Alcremie compatibles con el dulce equipado y valida un nombre propuesto mediante `validate_candidate(form_id, held_item_id, canonical_form_names)`.
- `spin_event` tiene el contrato estructural futuro `{trigger:"spin", completed:true, direction:"clockwise"|"counterclockwise", duration_ms:int positivo, world_daypart:"day"|"night"}`. **Este módulo no autentica la fuente del evento ni fija umbrales de duración/horarios.** Las pruebas inyectan valores para ejercitar el predicado; **NO representan giros producidos en el juego**.
- Si el ítem equipado es incorrecto, el confite ya se consumió, falta giro completo, dirección/duración/hora o la lista canónica de formas está incompleta/duplicada, el resultado falla cerrado. Nunca consume un confite ni cambia estado de Pokémon.
- Incluso con precondiciones válidas y nueve candidatos reales por dulce, `evolution_ready=false` siempre. El resolver **no puede elegir una crema sin la regla oficial implementada en un productor auténtico**. No se inventa elección por orden, primera forma, semilla, duración arbitraria ni por reloj del SO.

Nuevo test `tests/gameplay/parallel_items_w04_milcery_resolver.gd` revisa las 63 formas, los siete confites, 7 casos positivos de **precondición aislada**, nombres candidatas y negativos de ausencia de giro, mal disparador, dirección/duración/hora omitidas o inválidas, dulce erróneo, consumido, duplicados y formas fabricadas. Prueba que `EvolutionSystem.evolution_candidates` todavía no evoluciona Milcery. No usa ni altera servicios compartidos.

La regresión anterior de `evolution_condition_resolver_w04.gd` está conservada. Se extendieron fixture, Python, Godot y workflow acumulativos para `rows=5` con `completed=3`. B04 permanece solo en `deferred_blocks`, fuera de la lista de filas funcionales.

## Contrato mínimo para desbloqueo por IA6

**Productor A — evento del mundo:**
- Emitir desde controlador de jugador/overworld un `SpinCompleted` real tras gesto válido del jugador; evento vinculado a criatura elegida por ID y al mundo/sesión actual, con dirección, duración y hora del mundo. No convertir el equipamiento, `use_item` de mochila o un giro visual sin evento en evolución.
- IA6 define una política/versionamiento autorizado para interpretar el evento: umbrales de duración, dirección y reloj del mundo que determinan **crema**, sin inferirla de PokeAPI (que solo lista nombres y no presenta esa fórmula). De ser necesario, tests contra reglas canónicas de Sword/Shield elegidas para el juego.

**Productor B — identidad de forma canónica:**
- Fuente determinista para la crema final (una de las nueve), derivada de la regla oficial, y decoración derivada del confite **realmente equipado**. Combinar ambas y validar nombre exacto contra `pokemon/869/forms`; si falta cualquiera, no evolucionar.
- `CreatureInstance` y SaveV2 deben tener representación persistente de forma/decoración, migación/retrocompatibilidad de partidas antiguas y capacidad de reconstruir el Pokémon evolucionado sin perder identidad, PP, IV/EV, naturaleza ni demás datos persistentes.

**Productor C — transacción:**
- `FieldItemService` / propietario del agregado deben comprobar criatura Milcery, confite actual y no consumido, procedencia auténtica del evento de giro y forma determinada de la versión. Solo entonces realizar evolución, cambio de forma y consumo/retención correcto, con commit/rollback atómico y persistencia SaveV2. IA6 debe aprobar la semántica exacta de consumo del confite durante confirmación, cancelación y fallo; no se ha impuesto ninguna.
- Tests positivos L3 de giro real → Alcremie con forma esperada y dulce correcto, y negativos sin giro/ítem/forma, cancelación, cambio concurrente de equipo, guardado/carga y restauración de identidad. Ninguna de estas pruebas L3 está certificada ahora.

**Seams prohibidos respetados:** sin cambios a `CreatureInstance`, Factory, `EvolutionSystem` compartido, `ProgressionSystem`, `FieldItemService`, mundo/escena, SaveV2 central, `main`, V28, PR#118, árbitra ni otras trabajadoras.

## CI real y evidencia

[Run #42715096500](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42715096500), SHA `a51c99305cf0d3e16bad7ad65b3feff11af5c680`, **completed SUCCESS**:
- `CAMP006_W04_SCOPE PASS completed=3 last_executed=06 deferred=04 rows=5`
- `CAMP006_W04_PY PASS completed=3 last_executed=06 deferred=04 checks=211`
- `CAMP006_W04_GODOT PASS completed=3 last_executed=06 deferred=04 checks=326`
- `CAMP006_W04_RESOLVER_L2 PASS completed=3 last_executed=06 deferred=04 checks=91`
- `CAMP006_W04_MILCERY_RESOLVER sweets=7 canonical_forms=63 pure_precondition_positives=7 status=NOT_L3 completed=3 deferred=04 blocked=05,06`
- `CAMP006_W04_MILCERY_L2 PASS completed=3 last_executed=06 deferred=04 blocked=05,06 checks=150`
- `CAMP005_W04_PY PASS blocks=10 checks=673` y `CAMP005_W04_GODOT PASS blocks=10 checks=1423`.

**Significado:** CI exitosa certifica **resolver puro, catálogo y regresiones**, NO giro jugable ni evolución Alcremie L3.

**Recibo definitivo de CSV consolidado:** [run #42715401401](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42715401401), SHA probado `889f50b4a44e8e5c4a0ac474b8d869098dfee0ab`, **completed SUCCESS**. Se repitieron y aprobaron todos los pasos: alcance `completed=3 last_executed=06 deferred=04 rows=5`, Python CAMP006 211, Godot CAMP006 326, resolver previo 91, resolver Milcery 150, regresiones CAMP005 Python 673 y Godot 1423. La quinta fila está `BLOCKED_SPIN_FORM_PRODUCERS_VERIFIED`, no `PASS_L3`. El presente añadido documental no altera código ni workflow ni exige nueva CI.

**Difusión a IA6:** punto de integración preciso pendiente: productor Overworld de giro completado, reglas canónicas de selección de crema + calendario y campo persistente de forma/SaveV2, y transacción equipamiento/evolución/consumo con rollback. La ventana W04 se detiene, sin pasar al 07.

**Para IA6:** resolver, test y ticket listos. Es necesaria asignación explícita de productor A+B+C o nuevo gate de tarea independiente. No continuar bloque07 ni sumar 04/05/06 a `completed`.
