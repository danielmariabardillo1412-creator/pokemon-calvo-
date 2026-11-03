# IA4/W04 — CAMPAÑA_005 — Bloque 07/10 — Objetos asociados a formas

**Rama exclusiva:** `codex/calvo-items-20261103-w04-camp005`  
**Cola autorizada:** `adamant_crystal;blue_orb;griseous_core;lustrous_globe;red_orb`  
**Clasificación:** `DEPENDENCIA_FORMA_EQUIPABLE`, cinco IDs de backlog, **NO cinco objetos nuevos ni cinco evoluciones**.  
**Estado inicial:** `EN_CI_AUTOMATICA`, recibos reales pendientes.

## Fuente canónica, sin confundir equipamiento con transformación

| Objeto | Especie titular | Forma default PokeAPI | Forma alternativa | Contexto pendiente |
| --- | --- | --- | --- | --- |
| `adamant_crystal` | Dialga | `dialga` | `dialga-origin` | equipamiento y forma origen |
| `blue_orb` | Kyogre | `kyogre` | `kyogre-primal` | regresión primigenia en combate |
| `griseous_core` | Giratina | `giratina-altered` | `giratina-origin` | equipamiento y forma origen |
| `lustrous_globe` | Palkia | `palkia` | `palkia-origin` | equipamiento y forma origen |
| `red_orb` | Groudon | `groudon` | `groudon-primal` | regresión primigenia en combate |

Los archivos `data/api/v2/pokemon-species/{382,383,483,484,487}/index.json` contienen estas cinco parejas variedad base/alternativa; las respectivas cadenas `data/api/v2/evolution-chain/{198,199,244,245,248}/index.json` tienen **cero aristas evolutivas**. Giratina, Kyogre y Groudon declaran `forms_switchable=true`; Dialga y Palkia `false` en el snapshot: no inferir por ello que una nueva especie sea necesaria.

Los cinco IDs constan `SELECCIONADO` en `docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`, familia `STORY_KEY_OR_FORM_REVIEW`; los cinco están en `modules/inventory/item_connections_v1.json::holdable_ids`. `ITEM_INVENTORY.csv` conserva `NATIVE_ENTRY_REQUIRES_EFFECT_CASE` y `ITEM_FIELD_V8.csv.txt` no certifica rutas de evolución positivas. Un efecto `onBasePower` en la procedencia legacy de ciertas esferas no demuestra una forma implementada; `onSwitchIn` tampoco autoriza una transformación fuera de combate.

## Frontera de integración concreta

```text
Inventario → FieldItemService.equip/unequip → CreatureInstance.held_item_id
                                               |
                                               +-- existe, se guarda en SaveV2
                                               |
                                               v
                             resolver de forma origen o primaria: PENDIENTE
                                               |
                                               v
                          ciclo de combate switch-in / revert: PENDIENTE
                                               |
                                               v
                         estado/identidad forma y política SaveV2: PENDIENTE
```

**Pendientes IA6:** definir o conectar productor de evento de forma (los 3 objetos de origen vs los 2 Prismas al entrar en combate), mapeo inequívoco de objeto/especie/variedad y modo de retorno (retirar objeto / salir de combate), persistencia de forma permanente vs transformación temporal, y política de interacción con estadísticas/efectos de objeto equipable. `CreatureInstance.battle_transform_original` existe para restaurar transformaciones temporales, pero no prueba un puente de estos cinco objetos. Ninguna de estas cinco rutas debe tocar `EvolutionSystem.evolution_candidates` como si fueran evoluciones.

**Anticruce:** `blue_orb` en Groudon y `red_orb` en Kyogre pueden equiparse como objetos genéricos con el perfil actual; jamás deben activar su variante primigenia incorrecta ni mutar la especie por hacerlo. La validación ensaya ambos casos sin asumir una restricción de equipamiento que el juego no tiene.

## Pruebas y observaciones

- `tests/fixtures/parallel_items/w04_campaign_005.json`: bloque 07 con cinco parejas de especie/variedad, cadena, forma y contrato; bloques 01–06 intactos.
- `tests/tools/test_parallel_items_w04_campaign_005.py`: cadenas sin evoluciones, variedades reales, distinción `forms_switchable`, cinco IDs, familia y selección, equipamiento, ausencia de contrato de forma persistente, escenarios Godot.
- `tests/gameplay/parallel_items_w04_campaign_005.gd`: por cada objeto, catálogo y fuente, uso/evolución por mochila rechazados sin gasto, equipamiento positivo, no cambio falso de especie, identidad y atributos, persistencia SaveV2 y retirada que devuelve inventario. Cruce de Prismas sobre especie contraria sin mutación.
- `docs/coordination/items_parallel_v1/reports/W04/CAMP_005_PROGRESO.csv`: nueva fila 07 `EN_CI_AUTOMATICA`, fila 04 conservada sin modificación.

**Gate CI07:** `CAMP005_W04_MANIFEST_PASS reserved=10 completed=7 ids=46 kind=FUNCTIONAL_BACKLOG`; `CAMP005_W04_PY PASS blocks=7 checks=N`; `CAMP005_W04_GODOT PASS blocks=7 checks=N`, N>0. No afirmar PASS mientras la CI esté pendiente. Las regresiones históricas se esperan en hitos 05/10 o si se modifica producción; este bloque no cambia producción.

**Conclusión correcta si pasa la CI:** equipamiento y SaveV2 verificados, **formas de origen y primigenias no certificadas como funcionales**. El alcance de integración es responsabilidad IA6 / módulo de formas y ciclo de combate, no reescritura de evolución.

**Aislamiento:** únicamente archivos de prueba, fixture y reporte W04; no `main`, V28, otras ramas, producción, catálogo, workflows, guardados, PR #118.

**Próxima `p`:** bloque 08/10 `dna_splicers;reins_of_unity;n_lunarizer_merge;n_solarizer_merge` exclusivamente tras cerrar este bloque.

## CI07 real — validada la dependencia, NO la transformación

[GitHub Actions #41738161812](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41738161812), SHA `97d01a5738420c40382bfa99c3b5fff0bb882afa` (fixture+tests+progreso), terminó **completed/success**.

Recibos extraídos de los logs de GitHub:
- `CAMP005_W04_MANIFEST_PASS reserved=10 completed=7 ids=46 kind=FUNCTIONAL_BACKLOG`.
- `CAMP005_W04_PY PASS blocks=7 checks=426`.
- `CAMP005_W04_GODOT PASS blocks=7 checks=754`.
- Los cinco `CAMP005_W04_ITEM id=...` muestran `status=DEPENDENCIA_FORMA`; apuntan a los cinco pares correctos de especie y variedad de origen/primigenia, con `need=form_resolver_and_lifecycle`.
- `CAMP005_W04_ORB_CROSS blue_orb=>groudon red_orb=>kyogre status=NO_FALSE_FORM`.
- El workflow no ejecutó regresiones históricas CAMP004/003/001 en el bloque 07 (pasos `skipped`); **sí** ejecutó completo el arnés acumulativo de CAMP005 bloques 01–07.

Después se dejó en CSV la fila 07 `DEPENDENCIA_DOCUMENTADA`, `ci_run=41738161812`, commit `df5d656b29f7f147505398c5e7a947aec2e8aa7d`. Este cambio administrativo activa una segunda CI, por lo que no debe declararse aprobado ese commit sin comprobar el nuevo run. La fila 04 sigue sin alterar por su incidencia de permisos.

**Resultado técnico:** cinco equipamientos, rechazados seguros, preservación SaveV2 y ninguna falsa forma; **no** cinco transformaciones implementadas. La decisión de integración del subsistema de formas y primigenias sigue pendiente.

**Próximo bloque autorizado:** 08/10, cuatro fusiones, únicamente al recibir la siguiente `p`.
