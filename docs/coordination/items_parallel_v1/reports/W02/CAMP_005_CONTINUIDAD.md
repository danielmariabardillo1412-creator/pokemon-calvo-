# IA2/W02 — CONTINUIDAD VIGENTE CAMPAÑA_005 BLOQUE 07/10

**Trabajadora W02**, bayas, medicinas y entrenamiento. **Única rama con escritura:** `codex/calvo-items-20261103-w02-camp005`. Autoridad: IA6 `CAMPAIGN_005_W02_GATE.md`, `CAMPAIGN_005_W02_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W02.md` y `AUTONOMOUS_REPAIR_V5.md`. Cada `p` significa una sola fila. No tocar `main`, V28, PR118, árbitra, otras trabajadoras, workflow ni API global.

**Estado actual de publicación (NO certificación):** 7 de 10 microbloques; **28 IDs, 196 escenarios únicos, 588 variantes programadas** en `active` (PARTY con ítem), `none` (sin ítem) y `reserve` (STORAGE con ítem). Los siete golden del verificador Python se cotejaron contra la fixture acumulativa y fueron iguales; el runner Godot está conectado a `FieldItemService`, pero no se han obtenido logs concluyentes de ejecución de CAMP005 en esta sesión. No atribuir CI PASS por archivos subidos.

**Fila07 completada:** `resist_mochi;genius_mochi;clever_mochi;swift_mochi`, 32 escenarios nuevos × 3 modos. Los cuatro suben hasta **+10 EV** en Defensa, Ataque Especial, Defensa Especial y Velocidad respectivamente, limitados a 252 por estadística y 510 totales. Mochi V13/RHH **no cambia amistad**, a diferencia de vitaminas o plumas; discrepancia con referencias Gen9 documentada en `docs/current/ITEM_MOCHI_V13.md`. Se comprueban EV 0/248/252, total global 508/509/510, ranura inesperada, amistad 254, consumo y no consumo, copia/propiedad, estadísticas y HP, PP, IV, naturaleza, SaveV2 y SHA256. Oráculo Godot `MOCHI_STATS_005` mapea los seis mochis de mejora sin basarse en la fixture.

**Commits:**
- Fixture `tests/fixtures/parallel_items/w02_campaign_005.json`: `3ef494afaa0ae37e8adb90f12385bd4a27905bb7`.
- Godot `tests/gameplay/parallel_items_w02_campaign_005.gd`: `6cbc6211ab876a00b6be3c5c2d730879d6f2ff04`.
- Python `tests/tools/test_parallel_items_w02_campaign_005.py`: `04ab6baeb92dce7cbeb04af214d7a6c2000f9f4c`, `a83f601f7ac44c99bed9cec69c5e6eeb2ee1695c`, `44413f741a9dd963d53589e7b8bd89f57b4cfb76`, `7a60642ab83d500c78a60c3f0e976501d838ac54`.
- Progreso `docs/coordination/items_parallel_v1/reports/W02/CAMP_005_PROGRESO.csv`: `981b7f4a6e60db6777a8b98e298be2fcc02458e8`, fila 07 `EN_CI_AUTOMATICA`.
- Informe `docs/coordination/items_parallel_v1/reports/W02/CAMP_005_ITER_07.md`: `f9e8c5278cab2b42812129be0b0643a5d9115942`.

**CI y regresiones:** workflow `.github/workflows/parallel-camp005-w02-autoci.yml` configura Python+Godot CAMP005 para N=7, con regresiones CAMP004 y CAMP003 en hitos 05 y 10. Revisar RUN, SHA y logs de seis recibos cuando corresponda; `fetch_commit_workflow_runs` y `get_commit_combined_status` sobre HEAD06 devolvieron `[]`, que NO certifica éxito ni fracaso. La CI histórica CAMP004 no sustituye la de CAMP005. GPU/UI/integración global no verificadas. Reparar únicamente fallos propios V5 sin borrar pruebas; APIs compartidas requieren IA6.

**Siguiente `p`:** revisar CI y ejecutar **solo bloque 08** `fresh_start_mochi;adamant_mint;modest_mint;jolly_mint`. Mochi Reinicio limpia EV sin incrementar amistad, mientras las mentas son otro contrato; inspeccionar funcionalidad real antes de escribir expectativas, registrar dependencias si falta. No ejecutar bloque 09 sin otra orden.

---

# IA2/W02 — CONTINUIDAD VIGENTE CAMPAÑA_005 BLOQUE 06/10

**Trabajadora:** W02 (bayas, medicinas, entrenamiento). **Rama única de escritura:** `codex/calvo-items-20261103-w02-camp005`. Encargo IA6 en `CAMPAIGN_005_W02_GATE.md`, `CAMPAIGN_005_W02_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W02.md` y `AUTONOMOUS_REPAIR_V5.md`. Una tecla `p` = una sola fila siguiente. Nunca tocar `main`, V28, PR118, rama árbitra, otras trabajadoras, producción común o workflows.

**Progreso actual:** bloques **01–06** publicados, 24 IDs únicos, 164 escenarios, 492 variantes programadas (PARTY con ítem, PARTY sin ítem y STORAGE con ítem). Todos los golden Python de 01–06 coinciden estructuralmente con las fixtures y se contrastaron fuentes; **no equivale a Godot/Python ejecutados o CI aprobada**. El workflow `.github/workflows/parallel-camp005-w02-autoci.yml` requiere `CAMP005_W02_PY/GODOT PASS blocks=6`. El hito 05 además requiere regresión de CAMP004 y CAMP003 Python/Godot (10 bloques cada una). Logs y SHA finales **no recuperados**: conectores de runs/status por commit dan listas vacías para pushes; no inferir PASS ni FAIL.

**Bloque06 completo en rama W02:** `clever_wing;swift_wing;health_mochi;muscle_mochi`, 32 casos nuevos y 96 variantes. Clever/Swift Wing +1 EV de Defensa Especial/Velocidad, amistad 3/2/1 según tramo. Health/Muscle Mochi hasta +10 EV de PS/Ataque, **amistad intacta** según motor real Mochi V13 (referencia RHH). La discrepancia con otras implementaciones/contratos de amistad está documentada en `docs/current/ITEM_MOCHI_V13.md`: no afirmar paridad oficial. Comprobar EV inicial 0, atributo próximo al tope 252, bloqueo en 252, total de EV en 509 o 510, slot no permitido, amistad 254. Se preservan HP, PP, IV, naturaleza, XP, identidad, consumo, rechazo atómico, SaveV2 y recibos.

**Commits W02 bloque06:**
- Fixture `tests/fixtures/parallel_items/w02_campaign_005.json`: `d8bba42bcf99f89a22b51d0ea22ee59ed333ae25`.
- Runner `tests/gameplay/parallel_items_w02_campaign_005.gd`: `ab22963ab96d9bcef169788b60bb0493fcec2605`.
- Python `tests/tools/test_parallel_items_w02_campaign_005.py`: `d66ef9c09a12f77d95db7e7995b93d4b28d25dd6`, `bb0fb83c6ed5b618d743a9811081a45dd0e2a00b`, `6fa7e167d2764c48b0988e0afa6d6ab1bbf5caf3`, `a41ac8303e1b92a1e11debd99328f3a82b95937a`, `3d582173bb0dde77c2ad0d31811631eb49c4fffc`, `628ba038521f4b7a3c2ea5d3470c9d6b75d7fbbc`.
- Progreso `docs/coordination/items_parallel_v1/reports/W02/CAMP_005_PROGRESO.csv`: `7a6610469ae891fd38897f3d83d72534e20c3aba`; fila06 `EN_CI_AUTOMATICA`.
- Informe `docs/coordination/items_parallel_v1/reports/W02/CAMP_005_ITER_06.md`: `bb2aca2131d346e644f7464e38035df0bcb04f8f`.

**Regresiones y seguridad:** CAMP004/CAMP003 permanecen intactas y deben comprobarse con logs de los runs del hito05 y 10, sin rehacerlas ni borrar tests. El runner W02 005 hereda utilidades de 004 pero ejecuta fixture 005 independiente. Reparar defectos propios V5, nunca alterar API compartida sin IA6. No se ha probado visual/GPU ni integrado en producción.

**Próxima `p`:** revisar CI real de 06, y especialmente los seis recibos de hito05, corregir fallos propios con autorización V5; ejecutar **solamente fila07** `resist_mochi;genius_mochi;clever_mochi;swift_mochi`. No adelantar fila08 ni abrir campañas nuevas.

---

# IA2/W02 — CONTINUIDAD VIGENTE CAMPAÑA_005 BLOQUE 05/10

**Identidad y autoridad:** W02 (bayas, medicinas, entrenamiento). Rama **exclusiva de escritura** `codex/calvo-items-20261103-w02-camp005`. Encargo oficial IA6: `CAMPAIGN_005_W02_GATE.md`, `CAMPAIGN_005_W02_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W02.md`, `AUTONOMOUS_REPAIR_V5.md`. **Una `p` = una sola fila de la cola**, nunca más. No tocar `main`, V28, PR118, árbitra IA6, otras ramas, producción, API global ni workflow.

**Progreso publicado:** bloques **01–05 de 10**, 20 objetos distintos, 132 escenarios únicos y 396 variantes preparadas (active PARTY, none PARTY sin ítem, reserve STORAGE). 5 bloques con goldens Python separados, comprobados estructuralmente, sin afirmar ejecutados. **CI CAMP005 bloque05 y regresiones CAMP004/CAMP003 aún PENDIENTES de resultados verificados**; el conector de runs por commit no garantiza acceso a ejecuciones de `push`. La aprobación pasada de CAMP004 no demuestra regresión en CAMP005.

**Bloque 05 publicado:** `health_wing;muscle_wing;resist_wing;genius_wing`, 32 escenarios nuevos (8 por objeto), cada uno +1 EV de PS/Ataque/Defensa/Ataque Especial (no +10 como vitaminas), tope 252 por stat y 510 globales; rechazo por stat completa, total completo o ranura incompatible, y verificación de amistad por tramos [3,2,1] con acercamiento a 255. Propiedad/stock, consumo único, rechazo atómico, estadísticas recalc, EV/IV/PP intactos fuera del objetivo, SaveV2 y recibos SHA256 de Godot. Fuente: `modules/inventory/field_training_effects.gd` y `field_friendship_effects.gd`. Runner ahora admite `kind=wing` sin eliminar `kind=vitamin`. No se modificó producción.

**Commits del bloque 05:**
- Fixture `tests/fixtures/parallel_items/w02_campaign_005.json`: `7c57a4ceb82b45b3529ba6884f449d414958dca5`.
- Godot `tests/gameplay/parallel_items_w02_campaign_005.gd`: `ce45833dacd8d78fce7ea96dbd60f6ab26f610fc`.
- Python `tests/tools/test_parallel_items_w02_campaign_005.py`: `57368d5ef9d192cc67ced3627d2d8afe949023f0`, `138c4a142b86df8481227900cffd32a236a5d41c`, `aa14eb74df373f31f5f88808d75e0e464ea8f458`, `6aef3a4a105d40272586c26308df95666be57133`, `67a13f731cb757c49f5adc0df1cea03352d6ccd1`, `ea5b08c0e2db18d6557b0729e7f4a5b2183dfd20`. Incluye golden05 exacto de 32 y 16 mutaciones adversariales.
- Progreso `docs/coordination/items_parallel_v1/reports/W02/CAMP_005_PROGRESO.csv`: `ed0867facaf1410abc840b28f2d7c9ac9775eb44`, fila05 `EN_CI_AUTOMATICA`.
- Informe `docs/coordination/items_parallel_v1/reports/W02/CAMP_005_ITER_05.md`: `e1e438577b9a83f7af46e7b8b5e013532ded14f4`.

**Hito 05, crítico:** workflow IA6 `.github/workflows/parallel-camp005-w02-autoci.yml` exige `CAMP005_W02_PY/GODOT PASS blocks=5`, más `CAMP004_W02_PY/GODOT PASS blocks=10` y `CAMP003_W02_PY/GODOT PASS blocks=10`. No confundir publicación del CSV con aprobación; recuperar **SHA exacto y logs reales**. Si hay fallo de test W02, reparar bajo V5 sin debilitar los controles; si API compartida, consultar IA6. No hay verificación visual/GPU.

**Siguiente `p`:** revisar seis recibos del hito 05 y resolver defectos propios comprobados; después ejecutar **solo bloque 06/10**: `clever_wing;swift_wing;health_mochi;muscle_mochi` de la cola. No ejecutar bloque07 sin nueva `p`.

---

# IA2/W02 — CONTINUIDAD VIGENTE CAMPAÑA_005 BLOQUE 04/10

**Identidad:** IA2/W02, bayas, medicinas y entrenamiento. **Escritura exclusiva:** `codex/calvo-items-20261103-w02-camp005`. Encargo oficial IA6: `CAMPAIGN_005_W02_GATE.md`, `CAMPAIGN_005_W02_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W02.md` y V5. Tecla `p` = una sola fila autorizada por turno. No tocar `main`, V28, PR118, árbitra, otras trabajadoras, producción, APIs compartidas ni workflows.

**Estado publicado acumulado:** 04/10 bloques, **16 IDs**, 100 escenarios únicos, **300 variantes planificadas** (3 situaciones de dueño por caso). CI CAMP005 W02 **sin ejecución Python/Godot recuperada con PASS SHA+logs en esta sesión**; no afirmar certificación con solo revisión estática. CI anterior CAMP004 10/10 aprobada según gate IA6 [#41589286005](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41589286005), no extrapolable a CAMP005. Los bloques 01–03 se conservan íntegros y se verifican sus golden; regresión histórica CAMP004/CAMP003 no se ha modificado.

**Bloque 04 publicado:** `exp_candy_s;exp_candy_m;exp_candy_l;exp_candy_xl`. 32 escenarios nuevos: cuatro caramelos S 800, M 3000, L 10000, XL 30000 XP; para cada uno niveles 50/90/99, lvl99 con solo 50 XP restantes, lvl50 con 80 XP hasta próximo nivel, nivel 100 rechazo, ranura inesperada rechazo, amistad 200. `FieldGrowthEffects` fija techo XP del nivel100; nivel final se deriva mediante `ProgressionRuleset.level_for_experience`, manteniendo IV/EV/naturaleza, PP, déficit HP, ubicación/consumo y `SaveV2`. No asumir incremento fijo de nivel; se usan Mew y no se generalizan decisiones `NEEDS_CONTEXT` de otras especies. Runner Godot genera recibos SHA256 y `CAMP005_W02_GODOT PASS blocks=4` solo al ejecutarse; Python `CAMP005_W02_PY PASS blocks=4` igualmente precisa ejecución real.

**Commits bloque04:**
- Fixture `tests/fixtures/parallel_items/w02_campaign_005.json` `8ea4575de1ef5cb95a26e5ddbe735ea9342d4b9c`.
- Godot `tests/gameplay/parallel_items_w02_campaign_005.gd` `fd3ee2148a8d212fadbfc36924b88181276243a6`.
- Python `tests/tools/test_parallel_items_w02_campaign_005.py`: `8979e0e13415cde375b6147643fb5f79da4e5cd5`, `c5ea35ed91423b48e0152cdef92eabfe2b2ea2e6`, `8d1952aa84d06b7df7b860025d12b786df4dbf14`, `613402863a376d19ff17cab506ad6fac0cb71b2d`, `f188b8b3a05c28303b293fb2c295d615371d7673` (golden 32, 16 mutaciones y fuentes).
- CSV `docs/coordination/items_parallel_v1/reports/W02/CAMP_005_PROGRESO.csv`, fila04 `EN_CI_AUTOMATICA`, `9fcffee3aa161c7123c2c36206ac27cce0e20915`.
- Informe `docs/coordination/items_parallel_v1/reports/W02/CAMP_005_ITER_04.md`, `847f88b51f77422b6988f7c9ef25a0a807e8dee2`.

**Pendiente:** consultar CI sobre HEAD y registrar `CAMP005_W02_PY/GODOT PASS blocks=4` con SHA/logs si accesibles; reparar solo fallos propios V5. Si requiere API compartida, coordinar IA6. UI/GPU no verificados.

**Siguiente `p`:** bloque 05/10 **`health_wing;muscle_wing;resist_wing;genius_wing`** de la cola IA6. El workflow CAMP005 ejecuta además regresiones CAMP004/CAMP003 en el hito 05; verificar esos logs, no dar por exitosas las regresiones sin ejecución. No adelantar bloque 06.

---

# IA2/W02 — CONTINUIDAD VIGENTE CAMPAÑA_005 BLOQUE 03/10

**Identidad:** IA2/W02, bayas/medicinas/entrenamiento. **Rama única editable:** `codex/calvo-items-20261103-w02-camp005`. Cola/autoridad IA6: `CAMPAIGN_005_W02_GATE.md`, `CAMPAIGN_005_W02_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W02.md` y V5. **Cada `p` autoriza un solo microbloque**, nunca un adelanto sin orden. No tocar main, V28, PR118, rama árbitra, ramas ajenas, catálogos, políticas ni workflows.

**Acumulado publicado (NO certificado):** bloques 01, 02, **03** completos en documentos y código de tests, 12 IDs, 68 escenarios y 204 variantes de tres modos (`active`, `none`, `reserve`). CAMP005 Python y Godot **aún sin CI PASS/FAIL con log y SHA verificables** desde esta conversación. El workflow W02 `.github/workflows/parallel-camp005-w02-autoci.yml` debería dispararse por cambios en fixture/tests/progreso, pero GitHub connector para commit workflow runs no retorna los pushes y la URL pública de Actions dio `DisabledError`. Éxito de CAMP004 [#41589286005](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41589286005) es histórico, NO resultado de CAMP005. No inventar recibos ni run IDs.

**Bloque 03:** `calcium;zinc;carbos;exp_candy_xs` (26 casos nuevos). Calcio/Zinc/Carbos aumentan +10 EV de Ataque Especial/Defensa Especial/Velocidad, con límite 252 por estadística y 510 globales: condiciones 0/248/252 EV y 508/510 EV totales, además de rechazo por ranura de PP no permitida. Caramelo Exp XS aporta 100 XP con límite nivel100: pruebas de Mew niveles 20/50/99, XP 40 antes de lvl51, XP 50 antes del nivel100, amistad 200 y rechazos nivel100/slot inesperado. **El XP y nivel esperado se calculan desde `ProgressionRuleset` y el motor `FieldGrowthEffects`; no se inventan aumentos fijos de nivel.** Todos los casos verifican aceptación/rechazo, consumo único, propietario PARTY/STORAGE, HP, PP, EV, amistad, SaveV2 y SHA256.

**Commits bloque 03:**
- Fixture `tests/fixtures/parallel_items/w02_campaign_005.json`: `c4311e4dd0fc53710049fce2e1a43d1e75492ded`.
- Godot `tests/gameplay/parallel_items_w02_campaign_005.gd`: `27a4c6d3fb0884044bec71e4caedbd1dc1e11ed7`.
- Python `tests/tools/test_parallel_items_w02_campaign_005.py`: golden 26 y fuentes `a4479b04d4091ff11c7b512ad36b8f2d1919ad0e`; 15 mutaciones `fb409a9e92e0b84a6df93a9a4ac116164afb1faf`.
- CSV `docs/coordination/items_parallel_v1/reports/W02/CAMP_005_PROGRESO.csv`: `6ccd56b0b5ad0c94a17d5f0d16451bad7f5aef1a`, fila 03 `EN_CI_AUTOMATICA`.
- Informe `docs/coordination/items_parallel_v1/reports/W02/CAMP_005_ITER_03.md`: `428a588e8e1acc13736a99bf133a60efd419d41c`.

**Regresiones:** bloques 01/02 siguen íntegros y CAMP004/CAMP003 sin modificar; según gate, deben ejecutarse en hito 05/10 y parches de producción. No se modificaron funciones de producción, APIs compartidas, motor común o workflows. Prueba visual/GPU e integración final fuera de alcance.

**Siguiente `p`:** revisar CI real SHA+logs si accesibles, reparar solo defectos propios bajo V5 sin reducir contratos; si CI aún pendiente, se permite preparar trabajo independiente. Ejecutar únicamente bloque **04/10** `exp_candy_s;exp_candy_m;exp_candy_l;exp_candy_xl`. No ejecutar 05 antes de nueva `p`; no tocar ramas ajenas.

---

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
