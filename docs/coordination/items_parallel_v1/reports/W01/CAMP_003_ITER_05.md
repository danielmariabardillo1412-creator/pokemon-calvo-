# IA1/W01 — CAMPAÑA_003, microbloque 05/10

**Rama exclusiva:** `codex/calvo-items-20261103-w01-camp003`. **Entrega:** bloque 05 publicado, `EN_CI_AUTOMATICA` al redactar; **sin PASS de las pruebas nuevas**. Autoridad: cola oficial IA6 W01/05, IDs exactos `flame_orb;focus_sash;grassy_seed`. Prohibido modificar producción, catálogo, V28, `main` u otras ramas.

## Auditoría y matriz de cobertura

| Objeto | Referencia histórica | Casos nuevos | Efecto y control esperado de la integración |
|---|---|---|---|
| `flame_orb` (Llamasfera) | `held_effect_sweep_v2.cjs`: `end_turn_status`, quemadura residual | `flame_burn_end_turn` (19,23), `flame_fire_type_immune` (19) | Mew portador queda quemado al final del turno y **no consume**; sin objeto o reserva, no. Charizard tipo Fuego no debe quemarse aunque lo lleve |
| `focus_sash` (Banda Aguante) | `tests/gameplay/parallel_items_w01_held_v1.gd`: `lethal_full`, `lethal_partial`, `nonlethal_control`; inventario `HELD_PILOT_VERIFIED` | `sash_full_hp_lethal` (1,19), `sash_partial_hp_lethal` (19), `sash_nonlethal` (23) | Pikachu nivel 1 a PS máximos sobrevive a `seismic_toss` de Mew nivel 100 con **1 PS**, gastando una unidad; control y reserva caen. Con PS por debajo del máximo cae incluso con el objeto, que se retiene. Golpe no letal no lo consume |
| `grassy_seed` (Semilla Hierba) | `held_effect_sweep_v3.cjs`: pareja `grassy_seed/grassy_terrain/def` y `wrong_terrain` | `grassy_seed_field` (19,23), `grassy_seed_wrong_field` (19), `grassy_seed_no_field` (19) | Campo Hierba lanzado por rival concede **Defensa +1 y consumo** solo al portador; Campo Eléctrico o ausencia de campo no activa; reserva no consume |

**Cobertura nueva:** 8 escenarios, 11 pares caso-semilla y 33 variantes (portador/ausencia/reserva). **Acumulada 01..05:** 36 escenarios, 80 pares caso-semilla, **240 variantes**. Los 28 casos de 01..04 permanecen en el fixture sin alterar sus operaciones, IDs ni semillas.

Las pruebas no simulan efectos: el runner llama al existente `_fixture` → `FieldItemService`, `Native.begin_wild/submit` y `_restore_probe` SaveV2 (guarda, cierra, reabre, compara snapshot, estado nativo, portador y stock). Se amplió el runner para admitir niveles distintos actor/rival y PS al máximo/parciales, sin modificar producción. La fixture registra estos requisitos para que no se confundan con una activación arbitraria.

## Publicación y control del estado de CI

- `tests/fixtures/parallel_items/w01_campaign_003.json`: commit `8cc182ec9b6128f8eaac67a914ecfbf2f51820a6`, blob `a63f1fe9e7baec515fc1a69f4042791e6c649981`.
- `tests/gameplay/parallel_items_w01_campaign_003.gd`: commits `dfe3db8326ee0a8a013f5f73f9211a310cbe6c03` y `c23179a1da1038581c18f70c24cf8de9b269e103`; blob final `b37ba674a8b1c4990af5dafedb7c3795f63ea13a`. La condición positiva de Banda Aguante exige **PS iniciales exactamente al máximo** y la negativa **PS menores al máximo**.
- `tests/tools/test_parallel_items_w01_campaign_003.py`: commits `f416703ec8af7259e72e42e26307d7a8abaf9de3` y `8e174547429bba10c9bf3d62988d283931e15dd1`; blob `0f9de8a409c69853aa091e4c6f3cc5da28f4f35c`. Contratos exactos de ocho casos, especie, niveles, PS, semillas, fuentes V2/V3, inventario y número total 36/80.
- `reports/W01/CAMP_003_PROGRESO.csv`: cinco filas, commit `adc29afe506a79b50af643eba475765c09aaef98`. Bloques 01/02/03 PASS real; 04 figura `ENTREGADO_PENDIENTE_CI` porque la ejecución [#41558549785](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41558549785) **se canceló al ser sustituida por nuevos pushes**, no se declara aprobado ni fallido funcionalmente. Bloque 05 `EN_CI_AUTOMATICA`. **La CI nueva del bloque 05 debe revalidar simultáneamente 04 y 05**.
- La CI de 03 [#41556859548](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556859548) fue `completed/success`, Godot 3217 checks/3 bloques, Python PASS; no acredita bloques 04/05.
- El workflow existente requiere recibos exactos `CAMP003_W01_PY PASS blocks=5 checks=M` y `CAMP003_W01_GODOT PASS blocks=5 checks=M`, M positivo y exit code 0. La ejecución actual aún no está verificada; consultar rama/runs tras commit de progreso.

**Riesgos pendientes:** duración del conjunto acumulativo por Focus Band con 24 semillas; si expira tiempo, registrar fallo de infraestructura y elevar a IA6 (workflow inmutable W01), no falsear pruebas. Headless no certifica GPU/UI, liquidación en mapa ni RNG exhaustivo. Si hay defecto en simulador/SaveV2 compartidos, STOP y pedir intervención IA6. Si hay error exclusivo de test, corregir en rutas W01 sin eliminar comparaciones causales.

**Siguiente `p`:** revisar último run antes de pasar a W01/06. No adelantar ningún otro bloque ahora.
