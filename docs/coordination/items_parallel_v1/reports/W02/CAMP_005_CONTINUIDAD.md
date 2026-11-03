# IA2/W02 — CONTINUIDAD VIGENTE CAMPAÑA_005 BLOQUE 02/10

**Identidad:** IA2/W02, bayas/medicinas/entrenamiento. **Única rama editable:** `codex/calvo-items-20261103-w02-camp005`. Autoridad IA6: `CAMPAIGN_005_W02_GATE.md`, `CAMPAIGN_005_W02_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W02.md` y V5. `p` = **sólo una** fila siguiente por mensaje. No modificar main, V28, PR118, árbitra IA6, otras trabajadoras, datasets canónicos ni workflows.

**Estado:** bloques 01 y 02 publicados, 8 IDs, 42 escenarios y 126 variantes programadas sobre `FieldItemService` real con tres situaciones de propietario y SaveV2. **No equivale a CI PASS**: CAMP005 W02 Python/Godot 01–02 aún sin run/log verificable en esta ventana; GitHub commit-workflow runs sólo expone PR y no garantiza listado de pushes. El gate de IA6 acredita CAMP004 previo con CI [#41589286005](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41589286005), no reutilizarlo como CAMP005.

**Bloque 02 publicado:** `pp_max;hp_up;protein;iron` (6 pruebas por ID, 24 escenarios nuevos × 3 modos = 72 variantes). `pp_max` aplica tercer boost +60% de PP base en el movimiento seleccionado, sin restaurar puntos gastados; negativos con boost ya máximo, sin slot y slot inválido. Vitaminas HP Up (hp), Protein (attack), Iron (defense) aumentan hasta 10 EV, con límite de 252 por atributo/510 global; casos con 0, 248, 252 EV, total previo 508/510 y slot incorrecto. Amistad [5,3,2] por tramo y preservación del déficit de HP se cotejan con las funciones reales. No se ha modificado producción.

**Commits:**
- Fixture `tests/fixtures/parallel_items/w02_campaign_005.json`: `c740f5281d868fd8689f2f8a09955793653536c2`.
- Runner Godot `tests/gameplay/parallel_items_w02_campaign_005.gd`: `55fdcc416e1c6fc4a0191d686b834e3b4cb58d43` y `ca7ed514ff8eefff8aea77907b94d7931f39510b`.
- Validador Python `tests/tools/test_parallel_items_w02_campaign_005.py`: `c9e38e271f8e3681d83d88eb9e85116269ae86fe`, `3dabb4ed6aaab4e9b09f37913dc840143213502e` (golden exacto, 15 mutaciones del 02).
- Progreso `docs/coordination/items_parallel_v1/reports/W02/CAMP_005_PROGRESO.csv`: `24e65b3a481802763b71a0ae16240385dfc9d71f`; fila 02 `EN_CI_AUTOMATICA`.
- Informe `docs/coordination/items_parallel_v1/reports/W02/CAMP_005_ITER_02.md`: `64923e44ac25370fca677fb24c26da75bf091614`.

**Pruebas heredadas:** los 18 escenarios de bloque 01, CAMP004 y CAMP003 permanecen intactos. El runner acumula bloque 01/02 y registra `CAMP005_W02_GODOT PASS blocks=N checks=M` solo cuando todas las aserciones Godot se ejecuten; Python igualmente requiere ejecutar su validador. Un commit o chequeo de estructura no constituye ejecución.

**Siguiente `p`:** comprobar resultados/logs reales de CI para HEAD y reparar fallos propios bajo V5 sin quitar pruebas. Ejecutar **sólo fila 03**, `calcium;zinc;carbos;exp_candy_xs`, sin adelantar 04. Los cambios de API compartida requieren coordinación IA6. GPU/UI y merge en main/V28 siguen fuera de alcance.

---

# IA2/W02 — CONTINUIDAD VIGENTE CAMPAÑA_005 BLOQUE 01/10

**Identidad y función:** W02, bayas/medicinas/entrenamiento. **Rama exclusiva:** `codex/calvo-items-20261103-w02-camp005`. La autoridad es IA6 en `CAMPAIGN_005_W02_GATE.md`, `CAMPAIGN_005_W02_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W02.md` y V5. Primera orden resuelta: bloque 01 `ability_capsule;ability_patch;rare_candy;pp_up`. Cada `p` posterior permite exactamente un bloque, no otra campaña. No modificar `main`, V28, PR118, rama árbitra, otras trabajadoras, datos canónicos o workflows.

**Estado verificado:** fixture CAMP005: 1/10 bloques y 18 casos distintos; 4 IDs nuevos, 54 ejecuciones previstas en tres modos de propiedad (PARTY con ítem, PARTY sin ítem, STORAGE con ítem). Archivos propios nuevos:
- `tests/fixtures/parallel_items/w02_campaign_005.json` commit `a9b847c3dc9800fdba3fb3ec332835396b7c36c2`.
- `tests/gameplay/parallel_items_w02_campaign_005.gd` commit `35eda1841902611c6dd5fd178bec95aab258dc98`; hereda utilidades de CAMP004/CAMP003, pero no ejecuta campañas antiguas por su `_initialize` independiente.
- `tests/tools/test_parallel_items_w02_campaign_005.py` commit `b40efaa6b026e79a8d2e7b513bae607d65be6692`: golden exacto 18 casos, 15 mutaciones adversariales, fuente nativa y rutas de servicio.
- `docs/coordination/items_parallel_v1/reports/W02/CAMP_005_PROGRESO.csv`: fila 01 `EN_CI_AUTOMATICA`, commit `67448949dd933e01f907fe30023dba000dc50b9c`.
- `docs/coordination/items_parallel_v1/reports/W02/CAMP_005_ITER_01.md` informe, commit `9f98657d95c2c94d95a4fa08cc8b15ee5e272a87`.

**Funcionalidad contrastada en código nativo:** Cápsula Habilidad alterna Growlithe `intimidate↔flash_fire` y no debe aplicar desde habilidad oculta; Parche Habilidad `intimidate/flash_fire→justified` y reversión `justified→intimidate`; Caramelo Raro sube Mew 50→51 y 99→100, nivel 100 no hace efecto; Más PP aumenta en 20% del PP base un solo movimiento, hasta 3 boosts, manteniendo PP gastados y elevando amistad. Para los cuatro casos, negativos por slot incompatible o falta de item, consumo y propietario, identidad, SaveV2, SHA256. Los contratos están conectados a `field_ability_effects.gd`, `field_growth_effects.gd`, `field_pp_boost_effects.gd`, `field_item_service.gd`. Precedentes `item_field_ability_v10.gd`, `item_field_growth_v9.gd`, `item_field_pp_v8.gd`.

**CI no verificada:** el workflow de IA6 `.github/workflows/parallel-camp005-w02-autoci.yml` dispara con pushes que incluyen scripts/fixture/progreso. Sin embargo `fetch_commit_workflow_runs` y `get_commit_combined_status` en SHA de progreso devolvieron listas vacías; consulta pública a Actions falló con `DisabledError`, contenedor carece de Godot y DNS GitHub. Hasta tener run y logs vinculados al SHA, marcar **EN_CI_AUTOMATICA, sin PASS ni FAIL afirmados**. 14 comprobaciones estructurales y 22 verificaciones textuales de código fuente se realizaron, sin sustituir la ejecución. La CAMP004 anterior figura CI PASS en gate IA6 run [#41589286005](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41589286005). No confundirla con la nueva CAMP005.

**Siguiente `p`:** revisar resultado/errores de CI de 01 y, si es posible, reparar propios bajo V5; **solo entonces ejecutar siguiente bloque 02** `pp_max;hp_up;protein;iron`. En ausencia de CI accesible pero en progreso, el gate permite preparar un siguiente bloque independiente sin afirmar PASS. Preservar CAMP004 y CAMP003 y sus regresiones. No usar producción ajena ni inventar cambios de naturaleza, habilidad o XP que no estén implementados.
