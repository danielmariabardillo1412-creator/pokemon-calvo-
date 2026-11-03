# IA4/W04 — CAMPAÑA_005 / Bloque 08 — Fusiones de dos criaturas

**Rama exclusiva:** `codex/calvo-items-20261103-w04-camp005`  
**Cola autorizada:** `dna_splicers;reins_of_unity;n_lunarizer_merge;n_solarizer_merge`  
**Estado inicial:** `EN_CI_AUTOMATICA`. Estos cuatro IDs ya figuraban en el backlog; **no son objetos nuevos ni evoluciones directas**.

## Seis combinaciones, cuatro objetos

| Objeto | Titular | Compañero | Forma de referencia |
|---|---|---|---|
| `dna_splicers` | Kyurem | Zekrom | `kyurem-black` |
| `dna_splicers` | Kyurem | Reshiram | `kyurem-white` |
| `reins_of_unity` | Calyrex | Glastrier | `calyrex-ice` |
| `reins_of_unity` | Calyrex | Spectrier | `calyrex-shadow` |
| `n_lunarizer_merge` | Necrozma | Lunala | `necrozma-dawn` |
| `n_solarizer_merge` | Necrozma | Solgaleo | `necrozma-dusk` |

Las variedades alternativas se contrastan con `data/api/v2/pokemon-species/{646,898,800}/index.json`; los compañeros con species `{644,643,896,897,792,791}`. Las cadenas `{333,476,421}` tienen **cero evoluciones**, por lo que ninguna pareja ha de convertirse en `EvolutionSystem.evolution_candidates`.

**Límite de procedencia:** PokeAPI aquí acredita los nombres de variantes y especies, pero **no describe el contrato completo de fusión entre dos CreatureInstance** en esas cadenas. Las combinaciones estándar requieren una regla de diseño explícita del juego y transacción reversible; no presentarlas como evoluciones de mochila ni como rutas `use-item` importadas de PokeAPI. Los IDs `n_lunarizer_merge` y `n_solarizer_merge` son entradas legacy seleccionadas, distintas de una evolución convencional.

## Diagnóstico nuevo y dependencia concreta

- `docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`: cuatro IDs `SELECCIONADO`. `dna_splicers` y `reins_of_unity` pertenecen a `STORY_KEY_OR_FORM_REVIEW`; ambos IDs de Necrozma a `LEGACY_OR_CATEGORY_REVIEW`.
- `docs/current/ITEM_INVENTORY.csv`: los cuatro `DATA_ONLY`; `ITEM_FIELD_V8.csv.txt` marca equipamiento `NOT_CERTIFIED` y cero rutas de evolución.
- `modules/inventory/item_connections_v1.json`: ninguno de los cuatro pertenece a `holdable_ids`; no equiparlos artificialmente para simular fusión.
- `modules/creatures/storage/player_collection.gd`: `owned_creature`, `deposit` y `location_of` permiten **verificar** dos propietarios legítimos, en PARTY o STORAGE, pero no existe transacción `fuse/unfuse` en `FieldItemService`.
- `modules/save/save_game_data.gd`: SaveV2 almacena criaturas una vez por ID e impide `duplicate_creature_id` y `double_ownership`; **no define** qué ocurre con la segunda criatura mientras está fusionada ni cómo separarla preservando el mismo ID, IV, EV, nivel, experiencia, movimientos, estado e inventario.

**Contrato que necesita IA6:**

```text
PlayerCollection: principal y socio con dos instance_id legítimos
          ↓
Seleccionar objeto de fusión + ambos propietarios + variante destino
          ↓
FUSION_TXN: validar disponibilidad, exclusividad y estado/batalla
          ↓
Conservar identidad y datos del socio (retirado lógicamente, no borrado)
          ↓
Persistir ambos IDs, vínculo, forma, estado y política objeto en SaveV2
          ↓
UNFUSE_TXN: restaurar las DOS criaturas originales sin duplicar ni perder
```

Sin contratos de `FUSION_TXN`, `UNFUSE_TXN`, política de posesión/consumo del objeto y serialización reversible, **queda bloqueada la integración positiva**. No se cambia esquema de SaveV2 ni productores compartidos por esta trabajadora.

## Evidencia publicada

1. `tests/fixtures/parallel_items/w04_campaign_005.json`: bloque 08, seis combinaciones, cuatro IDs, tres cadenas sin evolución, segundo propietario en equipo/PC y dependencia explícita.
2. `tests/gameplay/parallel_items_w04_campaign_005.gd`: crea las dos criaturas con IDs distintos; verifica propiedad PARTY/STORAGE y registro SaveV2 único; prueba `use_item`, `evolve`, `equip` y tercero ajeno, todos rechazados sin consumo/mutación; guarda y carga ambas identidades/estadísticas/inventario y no confunde fusión con evolución.
3. `tests/tools/test_parallel_items_w04_campaign_005.py`: valida cuatro reservas, seis variedades, seis compañeros y cadena cruda; prueba límites de `PlayerCollection`, SaveV2 y ausencia de API `fuse/unfuse`; conserva los bloques 01–07.
4. `docs/coordination/items_parallel_v1/reports/W04/CAMP_005_PROGRESO.csv`: fila 08 `EN_CI_AUTOMATICA`, sin alterar la fila 04 (incidencia de conciliación previa).

**Aceptación del hito:** `CAMP005_W04_MANIFEST_PASS reserved=10 completed=8 ids=46 kind=FUNCTIONAL_BACKLOG`; `CAMP005_W04_PY PASS blocks=8 checks=N`; `CAMP005_W04_GODOT PASS blocks=8 checks=N` con N>0. La CI valida **contratos de propiedad y rechazos**, NO fusiones jugables.

**Aislamiento:** solo pruebas, fixture, progreso e informe W04; `main`, V28, PR118, otras ramas, código de producción, catálogos, workflows y SaveV2 compartido intactos.

**Siguiente `p` autorizada tras cierre:** 09/10 `gracidea;meteorite;reveal_glass;rotom_catalog;zygarde_cube`.
