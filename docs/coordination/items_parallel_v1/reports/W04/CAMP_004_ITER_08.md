# IA4/W04 — CAMPAÑA_004 / Microbloque 08

**Rama exclusiva:** `codex/calvo-items-20261103-w04-camp004`.
**IDs oficiales:** `reveal_glass`, `rotom_catalog`, `zygarde_cube`.
**Estado:** `EN_CI_AUTOMATICA` — no se declara PASS hasta consultar Godot y Python reales.

## Contratos auditados

Los tres IDs constan como `SELECCIONADO`, familia `STORY_KEY_OR_FORM_REVIEW`, en `docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`. En `modules/inventory/item_connections_v1.json` ninguno es equipable y `docs/current/ITEM_INVENTORY.csv` los clasifica `DATA_ONLY`, sin entrada nativa. `ITEM_FIELD_V8.csv.txt` exige `STORY_FORM_OR_SIDE_SYSTEM_CONTEXT_NEEDED` y equipamiento `NOT_CERTIFIED` para los tres.

- `reveal_glass`: el cambio de forma de Tornadus y otros genios requiere un contrato de forma explícito. No equivale a una evolución normal ni a equiparlo.
- `rotom_catalog`: la selección de forma/aparato de Rotom exige elección contextual y, en su caso, coherencia con movimientos. En el inventario está la marca **`missing_description`**, dependencia documental adicional que se comunica a IA6. No se inventan aparatos ni formas.
- `zygarde_cube`: células, ensamblaje y formas de Zygarde necesitan un modelo de colección/forma; no se inventa acumulación de células ni una evolución por objeto de mochila.

## Entregables en rama W04

- `tests/gameplay/parallel_items_w04_campaign_004.gd`, commit `df7d9e952b7848a0d9d266c481c640fd9d610eb4`: añade `BLOQUE_08` preservando 01–07. Consulta cada registro de evolución real y lo clasifica; si no hay una ruta ejecutable de uso de objeto, verifica en Tornadus, Rotom, Zygarde y Eevee: definición, rechazo de equipamiento, `use_item`, `evolve`, opciones vacías, propietario ajeno, cantidad intacta, identidad/especie sin cambio y guardado/carga SaveV2. Si apareciera una ruta positiva `TRIGGER_USE_ITEM + RUNTIME_SUPPORTED`, activa solo entonces el contrato positivo existente, sin asumir formas.
- `tests/fixtures/parallel_items/w04_campaign_004.json`, commit `115bb57ebb738eea0c8325eb99e858bf04f09925`: añade únicamente los tres IDs nuevos, clasificando dependencias de formas y ausencia de descripción.
- `tests/tools/test_parallel_items_w04_campaign_004.py`, commit `5b45e535e6f7ac3d5e9171974199ea96ca440893`: comprueba reserva 08, IDs acumulados, perfil, `DATA_ONLY`, `missing_description`, runner y aserciones reales.
- `reports/W04/CAMP_004_PROGRESO.csv`, commit `2ac9b2cef1486e074f57ecf01232333bbaf793e7`, fila 08 `EN_CI_AUTOMATICA`.

## Puerta y fronteras

Exigir GitHub Actions `CAMP004_W04_PY PASS blocks=8 checks=N`, `CAMP004_W04_GODOT PASS blocks=8 checks=N` y regresiones Python/Godot CAMPAÑA_003. CAMPAÑA_001 se mantiene para las puertas 05 y 10 según workflow. La CI negativa confirma invariantes de inventario/SaveV2, **no** disponibilidad de las formas.

No se han modificado producción, `main`, V28, rama árbitra, W01/W02/W03/W05, catálogos ni workflows. Las 16 dependencias heredadas de CAMP003 permanecen abiertas.

**Próximo `p`:** bloque 09/10, con `n_lunarizer_merge;n_solarizer_merge;roto_catch;roto_exp_points;roto_friendship`, después de comprobar y reparar si procede esta CI08. No ejecutar la cola 09 antes de ese mensaje.

## CI08 inicial verificada

La ejecución [#41591880287](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41591880287) en SHA `2ac9b2cef1486e074f57ecf01232333bbaf793e7` terminó **completed/success**. Logs reales:
- `CAMP004_W04_MANIFEST_PASS reserved=10 completed=8 ids=36`.
- `CAMP004_W04_PY PASS blocks=8 checks=245`.
- `CAMP004_W04_GODOT PASS blocks=8 checks=746`.
- Regresiones CAMPAÑA_003: Python **120**, Godot **270** PASS.

Resultados individuales: `reveal_glass`, `rotom_catalog` y `zygarde_cube`: `status=DEPENDENCIA records=0 conditioned=0` cada uno, sin ruta de forma. Los tres casos de control rechazan el uso directo/equipamiento sin gasto y persisten en SaveV2. No se certifican formas alternativas. `rotom_catalog` tiene además una marca documental `missing_description`.

El progreso se ha reconciliado en el commit `4e328bdba11bad06bc8d5b7e1f5e8390d5192ae1`, fila 08 `DEPENDENCIA_DOCUMENTADA` con CI `41591880287`. Esa actualización del CSV genera otra CI que debe verificarse por separado.


## Segunda CI08: progreso consolidado

GitHub Actions [#41592113216](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41592113216), SHA `4e328bdba11bad06bc8d5b7e1f5e8390d5192ae1`, terminó **completed/success** tras reconciliar el CSV. Recibos: `CAMP004_W04_MANIFEST_PASS reserved=10 completed=8 ids=36`, Python **245 PASS**, Godot **746 PASS**, regresión CAMP003 Python **120 PASS**, Godot **270 PASS**. Los tres objetos vuelven a mostrar `DEPENDENCIA records=0`; no se ha implementado ningún cambio de forma.

**Estado final del microbloque:** 08/10 entregado, probado y documentado; 24 IDs auditados en CAMP004. Siguiente `p` exclusivamente bloque 09.
