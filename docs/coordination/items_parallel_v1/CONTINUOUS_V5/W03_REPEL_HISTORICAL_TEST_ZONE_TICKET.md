# IA3/W03 V5 — ticket: test histórico Repel usa zona equivocada

## Evidencia reproducible

- Test histórico **inalterado** `tests/gameplay/parallel_items_w03_repel_l3.gd`, blob `318ee45f60d9ee046bcb048019337524acfb4844`. Línea de fixture: `var zone: StringName = scene._director.registered_zone_ids()[0]`.
- `modules/overworld/overworld_encounter_director.gd::registered_zone_ids` convierte las claves a Array y hace **`out.sort()`**.
- Los IDs reales de `scenes/overworld/technical_overworld.tscn` son `technical_cave_floor` (cueva) y `technical_grass` (hierba); el índice 0 ordenado selecciona la **cueva**.
- El mismo test llama `scene.get_node("EncounterZone").global_position`, que corresponde a la **hierba**, y exige `scene.zone_at_position(grass_position) == zone`. Por construcción la comparación falla.
- Run V5 [#43073388744](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43073388744) FAIL real con `CAMP006_W03_REPEL_L3 FAIL checks=49`: las dos aserciones `real demo grass position belongs to registered encounter zone`, dos `native bridge suppression commits RNG only` y fallos encadenados de pasos/tercer ítem tras una batalla incorrectamente iniciada.
- Baseline con el test antes del trasplante: [#43072852369](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43072852369), cancelado por commits posteriores, pero logs muestran `Invalid access ... _repel_effect` por falta de enlace.

## Qué se ha hecho (sin esconder regresiones)

Se conserva el fichero histórico **byte-for-byte**. Una nueva prueba **independiente** `tests/gameplay/parallel_items_w03_v5_repel_grass.gd` usa `scene.TECHNICAL_ZONE_ID` en lugar del primer ID del array ordenado, mantiene el mismo flujo real y prueba los tres repeles. Su CI está en `.github/workflows/ia6-w03-v5-repel-grass-qa.yml`. Los cambios de producción V5 no alteran `registered_zone_ids()`, los identificadores de zonas, los colliders, la ruta de encuentros genérica ni la RNG general; modificar ese motor solo para pasar el test sería un arreglo incorrecto.

## Decisión pendiente IA6

IA6 debe decidir si **autoriza corregir únicamente la selección de zona del test histórico** manteniendo todas sus demás aserciones y lanzar su CI estricta, o si mantiene ese test como artefacto histórico inválido y designa formalmente la nueva prueba V5 de zona real como oráculo vigente. **La W03 V5 no reescribe ni silencia pruebas históricas sin autorización.**

**No llamar PASS histórico** al test `parallel_items_w03_repel_l3.gd` hasta que se resuelva esa decisión. Un PASS de la prueba V5 corregida solo valida el comportamiento frente a la zona real.
