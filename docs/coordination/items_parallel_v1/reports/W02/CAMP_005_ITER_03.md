# IA2/W02 — CAMPAÑA_005 · MICROBLOQUE 03/10

**Autorización:** IA6 `CAMPAIGN_005_W02_GATE.md`, `CAMPAIGN_005_W02_QUEUE_APPROVED.csv`, fila 03, `campaigns/CAMP_005_W02.md` y protocolo de reparación V5. **Rama única:** `codex/calvo-items-20261103-w02-camp005`. Se añade sólo bloque 03 y se conservan íntegros los 01 y 02, CAMP004/CAMP003, `main`, V28 y ramas ajenas. Sin modificaciones de producción ni workflows.

## 4 IDs / 26 escenarios nuevos / 78 variantes programadas

| ID | Casos | Contratos funcionales reales |
| --- | ---: | --- |
| `calcium` | 6 | +10 EV de **Ataque Especial**, limitado por 252 EV por atributo y 510 globales. Casos EV inicial 0, 248 (+4), 252 (rechazo), total de otros EV 508 (+2), 510 (rechazo), slot inesperado (rechazo) |
| `zinc` | 6 | +10 EV de **Defensa Especial** con idénticos límites, recálculo de estadísticas, amistad [5,3,2] y preservación de déficit HP |
| `carbos` | 6 | +10 EV de **Velocidad** con límites, transacción y no alteración de otros EV/IV/PP/experiencia |
| `exp_candy_xs` | 8 | Recuperación de **100 puntos de experiencia** (con tope de experiencia del nivel 100), incluyendo niveles 20/50/99, cruce 50→51 al partir 40 XP antes del siguiente nivel, cruce 99→100 con solo 50 XP disponibles, amistad alta, rechazo nivel 100 y rechazo si se pasa una ranura de movimiento |

**Origen de los contratos:** `modules/inventory/field_training_effects.gd` contiene el mapa `calcium→special_attack`, `zinc→special_defense`, `carbos→speed`, incrementos de 10 y límites `EV_PER_STAT_MAX`/`EV_TOTAL_MAX`. `modules/inventory/field_growth_effects.gd` asigna `exp_candy_xs=100` y usa `ProgressionRuleset`/`ProgressionSystem.gain_experience`, sin inventar XP/level ni omitir posibles decisiones de evolución. El arnés usa **Mew** en los ocho ensayos de Exp XS; no extrapolar el automatismo a especies que exigen `NEEDS_CONTEXT`.

**Godot:** `tests/gameplay/parallel_items_w02_campaign_005.gd` incorpora la experiencia inicial a 40/50 XP del nivel siguiente donde se especifica, y comprueba la curva real de XP, incremento exacto del efecto, nivel derivado, amistad, déficit de PS, naturaleza, IV/EV y PP de los movimientos anteriores. Mantiene caso especial de Caramelo Raro de bloque 01; solo se añadió la segunda rama de crecimiento y los escenarios de Exp XS. Las vitaminas reutilizan el verificador positivo y negativo de bloque 02, con EV repartidos en estadísticos distintos y recálculo real. Los tres modos por escenario son `active` (PARTY con objeto), `none` (PARTY sin objeto), `reserve` (STORAGE con objeto). Se inspecciona consumo único o rechazo atómico, propietario, `SaveV2` y recibos JSON/SHA256.

**Python:** `tests/tools/test_parallel_items_w02_campaign_005.py` mantiene los contratos independientes de los bloques 01/02 y añade un golden propio de 26 escenarios del bloque 03; 15 mutaciones adversariales adicionales sobre IDs, fuentes, valores EV, rechazos, XP y cruces de nivel. Confronta además las rutas nativas de Exp XS y de vitaminas con el repositorio. La CI exige que se ejecute y emita `CAMP005_W02_PY PASS blocks=3 checks=M` con M>0, y que Godot emita su equivalente `CAMP005_W02_GODOT PASS blocks=3 checks=M`.

## Evidencias publicadas en la rama W02

- Fixture acumulada, `tests/fixtures/parallel_items/w02_campaign_005.json`, commit `c4311e4dd0fc53710049fce2e1a43d1e75492ded`.
- Runner Godot actualizado, `tests/gameplay/parallel_items_w02_campaign_005.gd`, commit `27a4c6d3fb0884044bec71e4caedbd1dc1e11ed7`.
- Validador Python, `tests/tools/test_parallel_items_w02_campaign_005.py`, commits `a4479b04d4091ff11c7b512ad36b8f2d1919ad0e` y `fb409a9e92e0b84a6df93a9a4ac116164afb1faf`.
- Progreso, `docs/coordination/items_parallel_v1/reports/W02/CAMP_005_PROGRESO.csv`, fila 03 en `EN_CI_AUTOMATICA`, commit `6ccd56b0b5ad0c94a17d5f0d16451bad7f5aef1a`.

## Certificación, dependencias y continuación

**Acumulado publicado:** 3/10 bloques, **12 IDs**, 68 escenarios, 204 variantes preparadas. La coherencia entre fuentes y fixture se ha revisado; **no se han obtenido logs de ejecución que certifiquen Python y Godot para CAMP005 01–03**. La consulta pública al workflow GitHub Actions respondió `DisabledError`; el método de runs por commit del conector no enumera de forma fiable las ejecuciones `push` de esta rama. Ni PASS ni FAIL pueden presumirse. El anterior éxito de CAMP004 W02 [#41589286005](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41589286005), documentado en gate IA6, no demuestra la CI de CAMP005. No se han realizado pruebas visuales/GPU. No se afirma integración global.

**Siguiente `p`:** verificar CI y reparar solo defectos W02 conforme a V5; si hay dependencia de APIs/políticas comunes, elevar a IA6. Si está pendiente y se permite adelantar trabajo independiente, ejecutar únicamente bloque **04/10**: `exp_candy_s;exp_candy_m;exp_candy_l;exp_candy_xl`. No iniciar 05 sin nueva `p`. Regresiones CAMP004/CAMP003 preservadas para hitos 05/10 o parches de producción.
