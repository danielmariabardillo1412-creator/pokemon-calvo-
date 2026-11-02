# W02 / CAMPAÑA_002 — ITER_03/03: regresión y SaveV2

**Estado de entrega:** `PREPARADO_EN_CI_AUTOMATICA`; publicación terminada, falta acreditar CI del SHA nuevo. **No es un PASS funcional.**
**Identidad:** IA2/W02. Rama exclusiva `codex/calvo-items-20261102-w02-camp002`; base `67959eb8f19abfd2ae391872747a14f603fcab01`.
**Autoridad:** `campaigns/CAMP_002_W02.md` blob `8e52a9f9e740eaee6210494ffaa764ce1ad9c644` y `CI_AUTOPILOT_V3.md` (CI autónoma por rama); ningún bloque 04 autorizado.
**Estado CI anterior real:** [W02 #41539808520](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41539808520), `completed/success` sobre SHA `6373ea47cac3069b120e9e2102f49d100ea14698`. Godot/Python sobre runner Figy corregido; **NO acredita el nuevo SHA**.
**Regresión final:** sin inventar nuevas bayas ni alterar los nueve escenarios: `sitrus_berry` 2, `lum_berry` 2, `leppa_berry` 2, `figy_berry` 3; 9 escenarios/27 variantes nativas activas, ausentes y en reserva.
**Matriz explícita:** `regression_contract` en fixture declara 9 escenarios, 27 variantes, 4 contadores por ID, SaveV2 obligatorio, consumo físico de exactamente una unidad cuando corresponde, cero pruebas de campo y protección de Persim histórico.
**Godot:** `_regresion_cuatro_bayas(rows)` revisa por cada escenario las tres posiciones, estado del titular, stock final y bolsa, recarga SaveV2, cierre FLED y ausencia de duplicados. Exige 27/27 variantes válidas antes de anunciar PASS. Incluye `fixture_sha256` del JSON efectivo y recuentos por modo.
**Python:** comprueba schema y matriz declarativa exacta, compara `fixture_sha256` contra bytes del fichero usado, exige `regression.status=PASS`, nueve casos, 27 variantes con SaveV2 y nueve casos por modo; además conserva SHA256 por recibo y evidencias de PP/naturaleza/confusión nativas.
**Protección IA6 preservada:** runner partía del blob verificado `73171d57101dab742bb9a27ce8a3027198b639de`, incluye recálculo de stats Figy; no se copiaron runners antiguos ni se modificó Persim de CAMP_001.
**Robustez numérica:** `per_item_cases` se compara por claves exactas y `float()` de recuentos para evitar diferencias `2.0`/`2` producidas por `JSON.parse_string`. No se omiten IDs ni se rebajan aserciones.
**Nueva suite Python:** 22 unit tests definidos, incluidos cinco negativos nuevos contra atribución de bayas, omisión SaveV2, falso campo, alteración Persim y reducción del número de variantes.
**Archivos:** fixture blob `767b5998483e9710c1e9c6d1aacb0b2375f35e6c`; Godot blob `67d2d0b79568e31eca24fb2d70aab3de5f156106`; Python blob `a3fe65ae70eeeb201a58c7918de30e4db8414346`.
**Inspección realizada:** 24/24 controles estáticos en GitHub, 0 discrepancias; **no equivale a ejecución nueva de Godot/Python**.
**CI automática:** el workflow propio `.github/workflows/parallel-camp002-worker-autoci.yml`, instalado previamente por IA6, se activa tras modificar pruebas/fixtures. Comprobar resultado para el SHA actual antes de usar `PASS`.
**Comandos verificación:** `python -B tests/tools/test_parallel_items_w02_campaign_002.py --unittest`; `godot --headless --path . --script res://tests/gameplay/parallel_items_w02_campaign_002.gd`; `python -B tests/tools/test_parallel_items_w02_campaign_002.py --result .godot/parallel_items/w02_campaign_002/godot.json`.
**Límites:** Sitrus, Lum y Leppa poseen perfil de recuperación de campo, Figy no registrado; esta campaña **no probó campo**. GPU, UI, formatos de batalla distintos y certificación exhaustiva del juego permanecen fuera de alcance.
**Permisos:** solo fixture/runner/validador propios y reportes W02. No alterar `main`, V28, PR #118, producción, árbitra, ramas ajenas, `tests/*campaign_001*`, selección, partidas ni workflows.
**Siguiente:** publicar `CAMP_002_FINAL.md`, CSV/cuaderno y **STOP**. Sin ITER_04 ni CAMP_003 aunque se envíe otra `p`.
