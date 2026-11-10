# IA5/W05 — AUTORUN TANDA 02 FINALIZADA · 180 MT scarlet-violet

**Fecha:** 2026-11-10. **Propietaria:** IA5/W05. **Rama exclusiva:** `codex/calvo-items-20261109-w05-books-ui`.
**Estado final:** `TANDA_02_FINALIZADA`, **10/10 grupos examinados, 10/10 grupos funcionales, 180/180 MT nuevas con positivo de enseñanza, 0 bloqueados**.
**SHA funcional comprobado:** `98fe396988b841705df1d01ac64dcfd0882d80bb`.
**GitHub Actions:** [#42733955354](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42733955354), `completed/success`, job `129558530826`.

## Integridad de la selección

Fuente canónica: `modules/inventory/item_connections_v1.json`, clave `machine_rows[id]["scarlet-violet"]`, y orden oficial `AUTONOMY_V1/QUEUE_W05_TANDA_02.md` de IA6. Contrato estático `tests/tools/test_parallel_items_w05_book_ui_autorun_v2.py` certifica:
- **229** MT activas exactas con mapeo SV real.
- **49** IDs de TANDA01 preservados en `w05_campaign_006.json`.
- **180** IDs adicionales y distintos, distribuidos **10 × 18**.
- `49 + 180 = 229` sin duplicados ni sustitución de mapeos; fixture nuevo de solo pruebas `w05_book_ui_autorun_v2.json`.

| Grupo | IDs exactos de la cola | Enseñanza positiva | Bloqueados | Comprobaciones Godot |
|---|---|---:|---:|---:|
| 01 | `tm07`, `tm16`, `tm18`, `tm21`, `tm22`, `tm23`, `tm24`, `tm25`, `tm26`, `tm27`, `tm28`, `tm29`, `tm30`, `tm32`, `tm33`, `tm34`, `tm35`, `tm37` | **18/18** | 0 | 1044 |
| 02 | `tm38`, `tm39`, `tm40`, `tm41`, `tm42`, `tm43`, `tm45`, `tm46`, `tm47`, `tm48`, `tm49`, `tm50`, `tm51`, `tm52`, `tm53`, `tm54`, `tm55`, `tm56` | **18/18** | 0 | 1044 |
| 03 | `tm57`, `tm58`, `tm59`, `tm60`, `tm61`, `tm62`, `tm63`, `tm64`, `tm65`, `tm66`, `tm67`, `tm68`, `tm69`, `tm70`, `tm71`, `tm72`, `tm73`, `tm74` | **18/18** | 0 | 1044 |
| 04 | `tm75`, `tm76`, `tm78`, `tm79`, `tm80`, `tm81`, `tm82`, `tm83`, `tm84`, `tm85`, `tm86`, `tm87`, `tm88`, `tm89`, `tm90`, `tm91`, `tm92`, `tm93` | **18/18** | 0 | 1044 |
| 05 | `tm94`, `tm95`, `tm96`, `tm97`, `tm98`, `tm99`, `tm100`, `tm101`, `tm102`, `tm103`, `tm104`, `tm105`, `tm106`, `tm107`, `tm108`, `tm109`, `tm110`, `tm111` | **18/18** | 0 | 1044 |
| 06 | `tm112`, `tm113`, `tm114`, `tm115`, `tm116`, `tm117`, `tm118`, `tm119`, `tm120`, `tm121`, `tm122`, `tm123`, `tm124`, `tm125`, `tm126`, `tm127`, `tm128`, `tm129` | **18/18** | 0 | 1044 |
| 07 | `tm130`, `tm131`, `tm132`, `tm133`, `tm134`, `tm135`, `tm136`, `tm137`, `tm138`, `tm139`, `tm140`, `tm141`, `tm142`, `tm143`, `tm144`, `tm145`, `tm146`, `tm147` | **18/18** | 0 | 1044 |
| 08 | `tm148`, `tm149`, `tm150`, `tm151`, `tm152`, `tm153`, `tm154`, `tm155`, `tm156`, `tm157`, `tm158`, `tm159`, `tm160`, `tm161`, `tm162`, `tm163`, `tm164`, `tm165` | **18/18** | 0 | 1044 |
| 09 | `tm166`, `tm167`, `tm168`, `tm169`, `tm170`, `tm171`, `tm172`, `tm173`, `tm174`, `tm175`, `tm176`, `tm177`, `tm178`, `tm179`, `tm180`, `tm181`, `tm182`, `tm183` | **18/18** | 0 | 1044 |
| 10 | `tm184`, `tm185`, `tm186`, `tm187`, `tm188`, `tm189`, `tm190`, `tm191`, `tm192`, `tm193`, `tm194`, `tm195`, `tm196`, `tm197`, `tm198`, `tm199`, `tm200`, `tm201` | **18/18** | 0 | 1044 |

## Pruebas funcionales del panel aislado

Runner `tests/gameplay/parallel_items_w05_book_ui_autorun_v2.gd` reutiliza la secuencia parametrizada de TANDA01, monta **un panel Godot real**, comparte `FieldItemService` previamente configurado y solo invoca `FieldItemService.teach` como fuente autoritativa. En cada uno de los 180 casos: perfil SV y presentación textual española real, especie permitida y compatibilidad de learnset auténtica, Pokémon poseído y seleccionado, necesidad de sustituir un movimiento cuando hay 4 slots, rechazo sin movimiento elegido, stock agotado, bloqueo de sesión, elección positiva de reemplazo, consumo de exactamente uno, PP correcto, propietario e identidad sin alteraciones, movimiento anterior retirado, rechazo de repetir conocido sin gastar, recarga SaveV2 y un Pokémon incompatible real sin mutación ni gasto.

**Recibos verificados en logs del job `129558530826`:**
- `W05_BOOKS_AUTORUN_V2_PY PASS blocks=10 ids=180 total_active=229 previous=49 checks=225`.
- Para cada grupo del 01 al 10: `W05_BOOKS_AUTORUN_V2_GROUP block=NN status=CERTIFICABLE ids=18 functional=18 blocked=0 checks=1044`.
- `W05_BOOKS_AUTORUN_V2_GODOT PASS blocks=10 ids=180 functional=180 blocked=0 checks=10467`.
- Todos corresponden al SHA funcional `98fe396988b841705df1d01ac64dcfd0882d80bb` con GitHub Actions `completed/success`.

## Preservación histórica y regresiones del mismo run

- TANDA01: `W05_BOOKS_AUTORUN_PY PASS blocks=10 ids=49 checks=114` y `W05_BOOKS_AUTORUN_GODOT PASS blocks=10 ids=49 functional=49 blocked=0 checks=2869`.
- Pilotos LIBROS-UI L3 01/02: Python **23** PASS y Godot headless **143** PASS.
- CAMPAÑA_006: Python **481** PASS y Godot **1781** PASS, más manifesto 10/10, 49 IDs.
- CAMPAÑA_005: Python **580** y Godot **2166** PASS.
- CAMPAÑA_004: Python **580** y Godot **2166** PASS.
- CAMPAÑA_003: Python **580** y Godot **2166** PASS.

**Incidencias reparadas sin rebajar cobertura:**
1. La CI [#42733397422](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42733397422) detectó un verificador histórico de TANDA01 que todavía leía la nota móvil `IA6_AUTORUN.md`, reemplazada correctamente por IA6 al activar TANDA02. El validador pasó a leer el **informe congelado TANDA01**, manteniendo el fixture y todas sus aserciones.
2. La CI [#42733686050](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42733686050) mostró diez recibos V2 con 18 positivos cada uno, pero falló en el agregado porque el runner reutilizado aún exigía `seen.size()==49`. Se corrigió exclusivamente la aserción del nuevo runner a 180 y el recibo de salida; sin editar `FieldItemService`, el panel o los positivos. CI [#42733955354](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42733955354) certifica el cierre completo.

## Límites y relevo IA6

- **L3 acreditado:** panel independiente, seleccionadores y botón reales sobre Godot headless, `FieldItemService.teach` y SaveV2.
- **No acreditado:** revisión visual/GPU humana, pruebas de todas las combinaciones Pokémon–MT, ni que este panel mejorado esté ya portado a la rama integrada `codex/calvo-ia6-integration-20261109`. Integración selectiva `FieldItemBag` y regresión conjunta pertenecen a IA6.
- **No tocados:** `scenes/visual/field_item_bag.gd`, `FieldItemService`, módulos SaveV2 centrales, catálogos, learnsets, política, datos de referencia, `main`, V28, PR #118, ramas de IA1–IA4, árbitra. Sin merge.
- **Archivos escritos:** fixture V2 W05, runner Godot V2, validador Python V2, adaptación del validador histórico V1 para fuente documental inmutable, workflow W05, checkpoint, CSV y este informe final.

**ENTREGA:** `W05 TANDA 02 FINALIZADA — 10/10 examinados — 180/180 funcionales — 0 bloqueados — SHA 98fe396988b841705df1d01ac64dcfd0882d80bb — CI #42733955354 SUCCESS — AUTORUN_V2_FINAL.md`.

**STOP:** no comenzar TANDA03 ni inventar nuevos IDs. IA6 publicará próxima cola si procede en la nota fija `IA6_AUTORUN.md`.
