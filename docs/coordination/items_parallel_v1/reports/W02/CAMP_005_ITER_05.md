# IA2/W02 — CAMPAÑA_005 | MICROBLOQUE 05/10

**Autorización IA6:** `CAMPAIGN_005_W02_GATE.md`, `CAMPAIGN_005_W02_QUEUE_APPROVED.csv` (fila 05), `campaigns/CAMP_005_W02.md` y `AUTONOMOUS_REPAIR_V5.md`. **Rama exclusiva:** `codex/calvo-items-20261103-w02-camp005`. No se ha modificado `main`, V28, PR118, rama árbitra, ramas ajenas, producción, API compartida ni workflow.

## 4 IDs y 32 escenarios nuevos — 96 variantes de pruebas programadas

| ID | Estadística | Casos nuevos |
| --- | --- | --- |
| `health_wing` | PS (`hp`) | 8: +1 EV inicial, EV 251→252, tope 252 (rechazo), EV global 509→510, tope global 510 (rechazo), slot no permitido, amistad 254→255, objetivo EV 250 y total 509 |
| `muscle_wing` | Ataque (`attack`) | Los mismos 8 contratos positivos y negativos |
| `resist_wing` | Defensa (`defense`) | Los mismos 8 contratos positivos y negativos |
| `genius_wing` | Ataque especial (`special_attack`) | Los mismos 8 contratos positivos y negativos |

**Fuente funcional:** `modules/inventory/field_training_effects.gd` define explícitamente `WINGS` y `gain = min(1, 252 - EV_stat, 510 - EV_total)` para estas plumas; `modules/inventory/field_friendship_effects.gd` aplica amistad **[3,2,1]**, no **[5,3,2]** como vitaminas. El motor recalcula estadísticas y preserva el déficit de PS. No se inventan habilidades, bonus de captura ni incrementos de +10 EV para plumas.

**Runner Godot:** `tests/gameplay/parallel_items_w02_campaign_005.gd` ahora acepta `kind=wing` sin cambiar el comportamiento de `kind=vitamin`: construye EV iniciales, distribuye EV de otras estadísticas dentro de límites y llama a `FieldItemService.use_item` sobre criatura y bolsa reales. En cada escenario comprueba variante `active` (PARTY con 2 unidades), `none` (PARTY sin objeto) y `reserve` (STORAGE con 2 unidades), aceptación y rechazo atómico, consumo, estadística recalc, amistad por tramo, PP/IV/EV restantes, experiencia, status, identidad y SaveV2. La salida programa recibos JSON con SHA256. No se ha alterado producción.

**Validador Python:** `tests/tools/test_parallel_items_w02_campaign_005.py` añade golden independiente `EXPECTED_05` con 32 escenarios exactos, respeta golden 01–04, coteja mapas `WINGS`, ganancias EV, amistad y soporte Godot, y suma 16 mutaciones adversariales sobre IDs, escenarios, límites, estadística objetivo, stock y amistad. La coherencia estructural de fixture y contratos **01–05** fue comprobada: 20 IDs únicos, 132 escenarios sin duplicados, todos los golden iguales a su bloque.

## Publicaciones GitHub

- Fixture `tests/fixtures/parallel_items/w02_campaign_005.json`: `7c57a4ceb82b45b3529ba6884f449d414958dca5`.
- Godot `tests/gameplay/parallel_items_w02_campaign_005.gd`: `ce45833dacd8d78fce7ea96dbd60f6ab26f610fc`.
- Python `tests/tools/test_parallel_items_w02_campaign_005.py`: `57368d5ef9d192cc67ced3627d2d8afe949023f0`, `138c4a142b86df8481227900cffd32a236a5d41c`, `aa14eb74df373f31f5f88808d75e0e464ea8f458`, `6aef3a4a105d40272586c26308df95666be57133`, `67a13f731cb757c49f5adc0df1cea03352d6ccd1`, `ea5b08c0e2db18d6557b0729e7f4a5b2183dfd20`.
- Progreso `docs/coordination/items_parallel_v1/reports/W02/CAMP_005_PROGRESO.csv`: fila 05 `EN_CI_AUTOMATICA`, `ed0867facaf1410abc840b28f2d7c9ac9775eb44`.

## Hito de regresiones y certificación pendiente

**Estado publicado CAMP005:** 5/10 bloques, 20 IDs, 132 escenarios y **396 variantes programadas** (tres modalidades). **No equivale a 20 objetos funcionalmente certificados.** El workflow `.github/workflows/parallel-camp005-w02-autoci.yml`, ya creado por IA6, tiene el hito explícito `steps.scope.outputs.blocks == '5'`: al comprobar la fila 05 debe intentar Python y Godot de CAMP005, más regresiones **CAMP004 y CAMP003**, ambas Python y Godot, y guardar logs por 7 días. Recibos exigibles: `CAMP005_W02_PY PASS blocks=5`, `CAMP005_W02_GODOT PASS blocks=5`, `CAMP004_W02_PY/GODOT PASS blocks=10` y `CAMP003_W02_PY/GODOT PASS blocks=10`, vinculados al **SHA exacto**. No se han obtenido aún los logs de ejecución de estos cambios. La consulta de runs por SHA del conector no enumera de forma fiable `push`; la ausencia de resultados no demuestra PASS, FAIL ni falta de ejecución. No sustituir estos logs por inspecciones estáticas. No se ha ejecutado Godot o Python del repositorio en este chat; GPU/UI no verificadas.

**Siguiente `p`:** buscar los seis recibos del hito 05 y reparar fallos propios bajo V5 sin reducir aserciones, escalando API compartida a IA6. Después, si lo autoriza la cola, ejecutar solo fila **06** `clever_wing;swift_wing;health_mochi;muscle_mochi`. No ejecutar 07 sin otra `p`. No tocar `main`, V28 ni ramas ajenas.
