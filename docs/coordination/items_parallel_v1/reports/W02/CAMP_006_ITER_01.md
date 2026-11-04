# IA2/W02 — CAMPAÑA_006 | BLOQUE 01 — RECUPERACIÓN OBLIGATORIA DE CI005

**Rama de trabajo:** `codex/calvo-items-20261104-w02-camp006`. **Origen:** `codex/calvo-items-20261103-w02-camp005`. **Autorización:** IA6 en `CAMPAIGN_006_W02_GATE.md`, `CAMPAIGN_006_W02_QUEUE_APPROVED.csv`, `campaigns/CAMP_006_W02.md` y V5.

## Reproducción con evidencia real, no deducción de un estado vacío

Run original: [GitHub Actions #41742682811](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41742682811), job `verify` ID `126287947552`.

- `CAMP005_W02_PY PASS blocks=10 checks=1267`.
- `CAMP005_W02_GODOT FAIL blocks=9 checks=16735`.
- Únicas aserciones concretas fallidas en Godot: `exp_candy_xl_level99_gain: active Caramelo Exp llega exactamente al máximo nivel100` y `...reserve...`.
- `relaxed_mint_level100: bloque íntegro` **NO significa que la menta haya modificado datos**: es la comprobación agregada de los diez bloques. `_run_camp005` conserva `current_case` de la última iteración al ejecutar `check("bloque íntegro", ok)`; el bloque04 ya estaba fallado por la expectativa XL. En Godot no hubo otra aserción individual `relaxed_mint_level100` fallida. No modificar, relajar ni eliminar sus contratos negativos.

## Causa y corrección mínima

El problema es **expectativa de fixture errónea**, NO defecto del motor de crecimiento ni del rechazo de menta. El Pokémon de prueba es Mew, curva `medium-slow`. La fuente independiente `tests/fixtures/progression_growth_curves/reference_contract.json` fija:

- Nivel99: **1.027.103 XP**.
- Nivel100: **1.059.860 XP**.
- Brecha: **32.757 XP**.
- `exp_candy_xl`: **30.000 XP**; destino esperado **1.057.103 XP**, aún nivel99, a **2.757 XP** del 100.

Corrección en propia rama CAMP006:
- `tests/fixtures/parallel_items/w02_campaign_005.json`, caso `exp_candy_xl_level99_gain`: sustituir `expect_cap=true` incorrecto por `expect_no_cap=true` explícito, manteniendo exactamente 288 escenarios, sus nombres y la prueba `exp_candy_xl_level99_cap_50xp` que SÍ verifica el tope100.
- `tests/tools/test_parallel_items_w02_campaign_005.py`: actualizar golden independiente del caso, mutación adversarial de `expect_no_cap` y comprobación externa de la brecha 32757; no rebajar pruebas.
- `tests/gameplay/parallel_items_w02_campaign_005.gd`: nuevo oráculo **positivo estricto** `expected_exp < cap_exp`, `gain_expected == nominal_exp`, nivel de salida igual a 99 y recibo `exp_gained==30000`; en paralelo, mantener `expect_cap` para el otro caso.

**Commits de reparación:** fixture `09a55fd0d966b2e36ee3884e97b47732e9fe90cf`; Python `f29548d515c98212e3b15c673b0e746e9b6e2a6e`; Godot `c0f86eb8f16ba0e75ee6e0f4d7da8bc2cc6feec2`. Ningún cambio de producción, `main`, V28, árbitra ni ramas ajenas.

## Evidencia propia CAMP006 y puerta de CI

- Fixture recuperación `tests/fixtures/parallel_items/w02_campaign_006.json`: tres casos seleccionados del antiguo lote (XL99 sin tope; XL a 50 XP del tope; relaxed_mint nivel100 sin handler), commit `f9f6e401aaacf83042525bcf16dd4e41d3884141`.
- Python `tests/tools/test_parallel_items_w02_campaign_006.py`: valores independientes de curva, mutaciones adversariales, preservación de los 288 casos y contratos reales, commit `5e3cc0c4b241f7f4688371383289a05bdeb46975`.
- Godot `tests/gameplay/parallel_items_w02_campaign_006.gd`: tres casos ejecutados mediante `_probe_training` real, tres modos de propiedad y SaveV2, commit `841a0b98ef219f19333e9a752cdd9ea90122faf8`.
- Workflow dedicado de rama `.github/workflows/parallel-camp006-w02-autoci.yml`, commit `2abcc2ae9644b8821d9dae6f26214b1a8fa347fc`. Exige Python+Godot CAMP005 completo, recuperación nueva en Python+Godot y regresiones Python/Godot CAMP004 y CAMP003, con logs como artefactos. No altera workflows ajenos.
- Run de comprobación: [#41763921080](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41763921080), commit `2abcc2ae9644b8821d9dae6f26214b1a8fa347fc`.

**Estado de este informe, previo al cierre del run:** verificación real de steps `Puerta 01`, `Recuperación integral Python CAMP005 10/10`, `Recuperación integral Godot CAMP005 10/10` y `Godot CAMP006 01/10` en `completed/success`; regresiones CAMP004/CAMP003 aún `in_progress` cuando se consultaron. No declarar **CI global PASS** ni desbloquear bloque02 hasta tener conclusión, logs y SHA.

## STOP de seguridad

**No ejecutar bloque02 hasta que la CI completa de CAMP005 aparezca PASS en la nueva rama** y se documente de forma verificable el run. Aun con ejecución correcta, la reparación de un oracle erróneo no implementa las mentas del backlog. La integración funcional, APIs compartidas o modificación de naturaleza efectiva quedan fuera de bloque01.
