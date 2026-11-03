# IA4/W04 — CAMPAÑA_004 / Bloque 05

**Rama exclusiva:** `codex/calvo-items-20261103-w04-camp004`. **IDs exactos:** `dna_splicers`, `exp_charm`, `gracidea`.

**Estado:** `EN_CI_AUTOMATICA`. No afirmar funcionalidad nueva ni PASS antes de comprobar los logs de GitHub Actions.

## Contratos reales del proyecto
- `dna_splicers`: objeto clave ligado a la fusión de Kyurem. La fusión de dos criaturas y sus identidades/forma no puede sustituirse por `FieldItemService.evolve` o `use_item` a una sola criatura. El catálogo de selección lo retiene como `STORY_KEY_OR_FORM_REVIEW`, pero `ITEM_INVENTORY.csv` lo clasifica `DATA_ONLY`.
- `exp_charm`: bonificación de experiencia, no piedra evolutiva ni equipable bajo `item_connections_v1.json`. No se modifica ni se certifica el cálculo de experiencia, fuera del dominio asignado.
- `gracidea`: objeto de cambio de forma de Shaymin. El proyecto requiere contrato explícito de forma/tiempo/estado para una transformación auténtica; no inventar `evolve` directo ni datos de forma ausentes. Figura `DATA_ONLY`.

Los tres están `SELECCIONADO` con `STORY_KEY_OR_FORM_REVIEW` en `docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`, y **ninguno figura en `holdable_ids`**. `docs/current/ITEM_FIELD_V8.csv.txt` marca `STORY_FORM_OR_SIDE_SYSTEM_CONTEXT_NEEDED` y equipamiento `NOT_CERTIFIED` para los tres. No se ha alterado ninguno de esos datos.

## Pruebas publicadas
- `tests/gameplay/parallel_items_w04_campaign_004.gd`: commit `515e9eccd44cf572adbe1c3cb95e40a74f1fb94f`. Conserva los cuatro bloques anteriores y añade auditoría con Kyurem, Shaymin y control Eevee: `use_item`, `evolve`, `evolution_options`, `equip` y propietario ajeno deben rechazar rutas sin soporte **sin consumo, cambio de especie, equipamiento ni alteración de SaveGameData**. Guarda y carga SaveV2 con inventario e identidad. Si surgiera una ruta directa de evolución genuinamente `RUNTIME_SUPPORTED` en el catálogo, la prueba la distingue y solo entonces prueba positivo; no se presupone su existencia.
- `tests/fixtures/parallel_items/w04_campaign_004.json`: commit `3d68eed7d11ca427ad142fda05cc983d8e4c463a`; añade la reserva 05 conservando 01–04.
- `tests/tools/test_parallel_items_w04_campaign_004.py`: commit `b2156cd52cd78dcdccbcc19e7d00a10f81498d5b`; valida reserva, fixture, selección y clasificación documentada, ausencia de equipamiento y presencia de escenarios de Godot.
- `reports/W04/CAMP_004_PROGRESO.csv`: commit `26da57ec3496f03b728cc60f4ffc9206ec71a485`; cinco filas, quinta `EN_CI_AUTOMATICA`.

## Puerta de regresión
En bloque 05 el workflow debe ejecutar **Python/Godot CAMP004**, **Python/Godot CAMP003** y también la prueba histórica de **CAMPAÑA_001 (seis piedras y SaveV2)**. Revisar recibos y último SHA. Ante fallo local, repararlo en W04 siguiendo `AUTONOMOUS_REPAIR_V5.md` sin eliminar aserciones ni simplificar reglas.

**Límites:** no se ha modificado producción, `main`, V28, rama árbitra, W01/W02/W03/W05, workflows, datasets ni reglas globales. La CI de negativos no certifica Kyurem fusionado, forma cielo de Shaymin ni aumento de experiencia.

**Próximo `p`:** bloque 06/10 `griseous_core;lustrous_globe;meteorite`, después de revisar CI05. 


## Recibos CI 05 ejecutados

[GitHub Actions #41579180249](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41579180249), SHA `26da57ec3496f03b728cc60f4ffc9206ec71a485`, terminó `completed/success`. Los logs verifican:
- `CAMP004_W04_MANIFEST_PASS reserved=10 completed=5 ids=36`.
- `CAMP004_W04_PY PASS blocks=5 checks=147`.
- `CAMP004_W04_GODOT PASS blocks=5 checks=455`.
- Regresión CAMPAÑA_003 Python `PASS blocks=10 checks=120` y Godot `PASS blocks=10 checks=270`.
- Regresión CAMPAÑA_001 `PARALLEL_ITEMS_W04_CAMP_001_GODOT PASS iteration=3 checks=559 cases=12`.

**Clasificación exacta de Godot:**
- `dna_splicers`: `DEPENDENCIA records=0`, `fusion_kyurem_no_implementada`.
- `exp_charm`: `DEPENDENCIA records=0`, `bono_experiencia_fuera_del_servicio_W04`.
- `gracidea`: `DEPENDENCIA records=0`, `forma_shaymin_necesita_contexto`.

La prueba demuestra invariantes de rechazo y SaveV2, **no** una fusión, ganancia real de experiencia o cambio de forma. Progreso consolidado en commit `ba870381e0a5b2215a925be44487e5613157b777` con estado `DEPENDENCIA_DOCUMENTADA` y recibo CI. Se comprueba aparte la nueva ejecución automática que dicho CSV produce.
