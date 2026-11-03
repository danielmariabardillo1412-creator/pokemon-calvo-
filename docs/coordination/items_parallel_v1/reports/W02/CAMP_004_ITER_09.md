# IA2/W02 — CAMPAÑA_004 / MICROBLOQUE 09/10

**Rama exclusiva de escritura:** `codex/calvo-items-20261103-w02-camp004`. **Autorización:** IA6 `CAMPAIGN_004_W02_GATE.md`, `CAMPAIGN_004_W02_QUEUE_APPROVED.csv` (fila 09), `campaigns/CAMP_004_W02.md`, reparación autónoma V5. Se ejecutó **únicamente fila 09**, sin modificar `main`, V28, PR #118, rama árbitra, ramas ajenas, producción, catálogos ni workflows.

## Cuatro IDs / 22 escenarios × tres modos = 66 variantes preparadas

| Ítem | Escenarios | Contrato nativo y negativos |
| --- | ---: | --- |
| `old_gateau` | 7 | Cura estados persistentes y confusión; casos veneno, tóxico, sueño y limpieza de reloj, congelación, confusión aislada, veneno+confusión y rechazo del sano |
| `paralyze_heal` | 5 | Cura **únicamente parálisis** `paralysis`; preserva confusión simultánea. Rechaza veneno, sueño y estado sano sin consumo |
| `pewter_crunchies` | 6 | Cura quemadura, tóxico, sueño+reloj, confusión, combinación veneno+confusión y rechaza objetivo sano |
| `potion` | 4 | Recupera **20 PS** desde media vida, limita recuperación a 7 PS ausentes, rechaza PS completos y conserva veneno al recuperar PS |

**Fuente de verdad:** `modules/inventory/imported_recovery_v19.json` contiene `old_gateau: {cure:"all",confusion:true}`, `paralyze_heal: {cure:["par"]}`, `pewter_crunchies: {cure:"all",confusion:true}` y `potion: {heal:20}`, con `consume:true` en los cuatro. La ruta `FieldItemEffects.apply` mapea `par → paralysis`, recupera PS y separa cura persistente de confusión. `tests/gameplay/item_field_effects_v4.gd` registra regresiones de `paralyze_heal` y `potion`; no se inventan regresiones antiguas para pasteles locales.

**Verificador Godot:** `tests/gameplay/parallel_items_w02_campaign_004.gd` ya soporta `kind=field_medicine`, curación selectiva de `status`, `cures_confusion`, `heal_amount` y `expect_sleep_clock_clear`; por tanto **no se modifica este archivo** ni el motor. Cada escenario se ejecutará en `active` (PARTY con ítem), `none` (PARTY sin ítem), `reserve` (STORAGE con ítem) mediante `FieldItemService.use_item`. Valida aceptación/rechazo, transacción y consumo único, estado/confusión, sueño, PP/HP/amistad, identidad, bolsa y guardado SaveV2, así como recibos JSON/SHA256.

**Validador Python:** `tests/tools/test_parallel_items_w02_campaign_004.py` incluye `EXPECTED_09` independiente de la fixture, 22 contratos exactos, perfiles canónicos y **14 mutaciones adversariales** de IDs, fuentes, rechazo, estados, confusión, PS y reloj. Se preservan íntegros los bloques 01–08 y regresión CAMP003.

## Commits

- `tests/fixtures/parallel_items/w02_campaign_004.json`: bloque09 22 casos, `e628d8eaa0e74d84f747414f9b1a326429394c3a`.
- `tests/tools/test_parallel_items_w02_campaign_004.py`: golden, fuentes y negativos, `360cda96c11b8e31cfb8525fb18ec9d5397b6977`.
- `docs/coordination/items_parallel_v1/reports/W02/CAMP_004_PROGRESO.csv`: fila09 `EN_CI_AUTOMATICA`, `b31059cf736fa175358763ca0aab93b71fb1c213`.
- Este informe `CAMP_004_ITER_09.md` y `CONTINUIDAD.md` (commit posterior).

**Acumulado:** 9 bloques **publicados**, 36 IDs, 165 escenarios y 495 variantes **preparadas**. No son 36 objetos certificados. Mantener dependencias reconocidas `razz_berry` (02) y `hopo_berry` (06): rechazo atómico no equivale a función útil.

## CI, riesgos y siguiente tecla

**Última CI verificable del historial de esta conversación:** bloque 01 de CAMP004 con PASS en [GitHub Actions #41573481223](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41573481223), Python `blocks=1 checks=83`, Godot `blocks=1 checks=1022`, regresión CAMP003 `blocks=10` (Python 680/Godot 7306). **02–09 continúan sin CI real certificada**: `fetch_commit_workflow_runs` sobre SHA HEAD de 08 dio `[]` al enumerar solo runs disparados por PR, no los de `push`; `get_commit_combined_status` dio `statuses:[]`. No presupone ni éxito ni fallo. No se ha ejecutado Godot ni Python directamente en este chat. UI/GPU y revisión visual PC siguen pendientes.

**Siguiente `p`:** primero revisar resultados y logs de CI del HEAD (objetivo `CAMP004_W02_PY/GODOT PASS blocks=9` más regresión `CAMP003_W02_PY/GODOT PASS blocks=10`), corregir fallos propios bajo V5 sin reducir aserciones ni tocar APIs compartidas. Después ejecutar **únicamente la fila 10/10** `shalour_sable;soda_pop;super_potion;sweet_heart`. Al cerrar 10, detenerse y comunicar `CAMPAÑA_004_FINALIZADA` solo como entrega documental si sigue pendiente la CI, sin afirmar certificación global.
