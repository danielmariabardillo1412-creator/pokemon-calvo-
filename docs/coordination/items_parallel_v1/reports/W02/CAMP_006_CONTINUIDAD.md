# IA2/W02 — CONTINUIDAD VIGENTE CAMPAÑA_006 BLOQUE 05/10

**Identidad:** IA2/W02. Rama exclusiva `codex/calvo-items-20261104-w02-camp006`. Fila05 oficial ejecutada: `everstone;exp_share;lucky_egg`. No iniciar fila06 sin otro `p`. Sin cambios a motor compartido, main, V28, PR118, árbitra u otras ramas.

**Puerta anterior:** [41788596358](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41788596358) `completed/success`, SHA `ebb575ef078eab926a49e111bd99108f2dc86c1a`. Aprobó 288 casos históricos CAMP005, piloto positivo de 4 mentas del bloque04, dependencias 02/03 y regresiones CAMP004/CAMP003. Se actualizan fixture/CSV de bloque04 para registrar su aprobación REAL, sin declarar funcionales las mentas antiguas.

**Bloque05: dos positivos ya conectados y una dependencia real.** `everstone` bloquea evolución al nivel 16 con objeto activo; al quitarlo reaparecen candidatos. `lucky_egg` concede +50 % XP de combate (71→106, nivel/cap intactos), al retirarlo vuelve XP normal. `exp_share` está permitido/equipable pero `ProgressionSystem` no reparte XP a no participantes, por tanto **NO es funcional**. Un ticket para IA6: `EXP_SHARE_PROGRESSION_DISTRIBUTION_POLICY_006_W02`, decidir distribución/gen/partícipes, política de objetos y modificación futura de ProgressionSystem fuera del permiso de W02. Sin tocar producción de progresión.

**Cobertura W02:** 3 oráculos, 3 modos (PARTY con stock, STORAGE con stock, PARTY sin stock), equip/unequip real, inventario −1, sin stock rollback, SaveV2 y evolución/XP por `ProgressionSystem`. Python golden+fuentes y 6 mutaciones; Godot prueba positivos reales y un negativo de efecto no conectado. Recibos nuevos `CAMP006_W02_HELD05_CONTRACT READY positives=2 dependency=1` y `CAMP006_W02_HELD05 PASS block=05 positive=2 dependency=1`. **No es CI PASS hasta run de este SHA**. Fixture CAMP005 10 bloques/288 casos intacta, sin relajar tests anteriores.

**Archivos de bloque05 en un commit atómico:** `tests/fixtures/parallel_items/w02_campaign_006.json`, `tests/tools/test_parallel_items_w02_campaign_006.py`, `tests/gameplay/parallel_items_w02_campaign_006.gd`, `.github/workflows/parallel-camp006-w02-autoci.yml`, `docs/coordination/items_parallel_v1/reports/W02/CAMP_006_PROGRESO.csv`, `docs/coordination/items_parallel_v1/reports/W02/CAMP_006_ITER_05.md` y este cuaderno. Run05 debe certificarse aparte. Bloque05 contiene dos efectos originales de V18 conectados; no crear nuevo handler ni compartir PR ajeno.

**Pendiente IA6 adicional:** `FieldGrowthEffects` y `FieldMochiEffects` aún comparan stats con naturaleza original tras menta04; SaveV2 central pre-save valida poco. Sin autorización, no tocar. Decisión futura para Exp Share. **Siguiente fila al próximo `p`:** bloque06 `power_anklet;power_band;power_belt`, verificar primero run05 y fuente; no inventar efectos EV sin implementar.

---

# IA2/W02 — CONTINUIDAD VIGENTE CAMPAÑA_006 BLOQUE 04/10 (PILOTO MENTAS)

**Identidad/rama:** IA2/W02, `codex/calvo-items-20261104-w02-camp006`. **IA6 autorizó** el piloto mediante `docs/coordination/items_parallel_v1/CAMPAIGN_006_W02_EFFECTIVE_NATURE_ARCHITECTURE_GATE.md`. Bloque04 `naughty_mint;rash_mint;sassy_mint;serious_mint`. No avanzar al bloque05 sin otro `p` ni editar main, V28, ramas ajenas o APIs compartidas no autorizadas.

**Cambio propuesto para el mismo commit atómico:** helper `modules/inventory/field_mint_effects.gd` de solo 4 IDs; `CreatureInstance.effective_nature_id` opcional y su uso por recálculo, dict y reconstrucción; despacho/transacción sin gasto previo en `FieldItemService`. `nature_id` original se conserva, `serious_mint` neutra se persiste con `serious`, vacío solo significa ninguna menta. Se prueban 4 escenarios positivos en PARTY/STORAGE y sin stock, rechazos atómicos, SaveV2 válido/retrocompatible/valor inválido. Los demás IDs de mentas en CAMP005 y bloques02/03 no se habilitan y deben seguir pasando rechazos históricos.

**CI correcta y sin sobreafirmación:** estado `PILOTO_L2_EN_CI` hasta obtener recibo Godot `CAMP006_W02_MINT04 PASS block=04 ids=4`, Python `CAMP006_W02_MINT04_CONTRACT READY ids=4`, CAMP005 completos (288 escenarios), dependencias anteriores y CAMP004/CAMP003. Runs 41763921080, 41778869360 y 41784043391 SUCCESS correspondientes a código anterior: no sirven como certificado de este commit. Registrar nuevo SHA/run solo tras consultar GitHub.

**Dependencias fuera del permiso IA6:** `FieldGrowthEffects.validation_error` y `FieldMochiEffects.validation_error` comparan estadísticas con `nature_id` y bloquearían caramelos EXP/mochis tras menta. `SaveGameData.validate` no valida campos efectivos antes de escribir (la carga puede rechazarlos en CreatureInstance). Revisar `BattleState`/evoluciones consumidores. No editar esos sistemas sin nueva autorización. Informe para IA6 `docs/coordination/items_parallel_v1/reports/W02/CAMP_006_ITER_04.md` con interfaz mínima y pruebas propuestas.

**Próxima fila al escribir `p`:** bloque05 `everstone;exp_share;lucky_egg`. Revisar primero IA6 y CI piloto; no declarar efectos positivos si la regresión real falla.

---

# IA2/W02 — CONTINUIDAD CAMP006 BLOQUE 03/10

**Rama:** `codex/calvo-items-20261104-w02-camp006`. Solo fila03 `lonely_mint;mild_mint;naive_mint`; próximo `p` fila04 `naughty_mint;rash_mint;sassy_mint;serious_mint`, aún no ejecutada.

**Estado:** tres naturalezas válidas en ProgressionRuleset, sin handler menta ni naturaleza efectiva persistente, dependencia única `MINT_EFFECTIVE_NATURE_STATE_SAVEV2_006_W02` de IA6, misma de fila02. Fixture bloque03 tiene 0 negativos nuevos; Python/Godot validan fuentes reales y reutilizan rechazo nativo SaveV2 de fila02. **No L2 ni L3**; no tocar APIs compartidas sin IA6.

**Recibos anteriores:** run 41763921080 recuperación SUCCESS, run 41778869360 bloque02 CI SUCCESS con marcadores BLOCKED (no efectos positivos). Bloque03 requiere run nuevo de su SHA. Conservar 288 casos CAMP005. Archivos actualizados en un commit atómico: fixture CAMP006, progreso, tests Python/Godot, workflow W02 e informe `CAMP_006_ITER_03.md`.

---

# IA2/W02 — CAMPAÑA_006 · CONTINUIDAD VIGENTE BLOQUE 02/10 — DEPENDENCIA DE MENTAS

**Identidad:** IA2/W02. **Rama única de escritura:** `codex/calvo-items-20261104-w02-camp006`. **Cola oficial:** `CAMPAIGN_006_W02_QUEUE_APPROVED.csv`. Se ha ejecutado únicamente la fila **02** `gentle_mint;hasty_mint;lax_mint`; no se ha iniciado fila03. No escribir en `main`, V28, PR118, árbitra, ramas ajenas o producción compartida sin contrato IA6.

**Gate de recuperación ya acreditado:** run [41763921080](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41763921080), `completed/success`, SHA `2abcc2ae9644b8821d9dae6f26214b1a8fa347fc`. CAMP005 10 bloques/288 escenarios, CI Godot+Python y regresiones CAMP004/CAMP003 correctas. Su recibo es de bloque01, no debe reutilizarse como CI nueva de bloque02.

**Diagnóstico de fila02:** las tres naturalezas están en `ProgressionRuleset.NATURE_MODIFIERS`: gentle (+Defensa Especial, −Defensa), hasty (+Velocidad, −Defensa), lax (+Defensa, −Defensa Especial). **Ninguna menta tiene handler de campo o naturaleza efectiva persistente.** `CreatureInstance.recalculate_stats` y `StatCalculator.compute` operan con `nature_id` original, que SaveV2 persiste; no existe un dato independiente. Retocar `nature_id` directamente sería una mecánica falsa. Identificador compartido `MINT_EFFECTIVE_NATURE_STATE_SAVEV2_006_W02`, titular IA6, consumidores: criatura, stats, combate, serialización SaveV2 y FieldItemService. **Estado bloque02: `DEPENDENCIA_DOCUMENTADA`, NO L2 ni L3.**

**Prueba mínima con contrato real:** fixture `tests/fixtures/parallel_items/w02_campaign_006.json` registra **tres IDs, un caso negativo representativo**, tabla de naturalezas y una dependencia compartida con productor, consumidores, propietario y prueba positiva pendiente. Godot `_probe_training` verifica `gentle_mint_missing_effect_route` en active/none/reserve: `DEPENDENCY_MISSING`, no consumo, instantánea sin cambios y SaveV2. Python comprueba las tres naturalezas, la falta de handlers y persistencia de naturaleza efectiva. Recibos separados `CAMP006_W02_PY/GODOT PASS blocks=1` de recuperación, `CAMP006_W02_DEPENDENCY BLOCKED block=02 ids=3` de dependencia. **Nunca reportar PASS blocks=2 como efecto positivo.**

**Commits relevantes:** fixture `a77f951cb64d8f810aca5953a5a38edc744a9e79`; progreso `52438969592f85edc3901d41c43767b2e2ed2c78` (fila01 recuperada, fila02 dependencia); validador Python `a9cf6592826c8d1f590f07fe58ac282fd534a70a`; runner Godot `2cff2eb92c9e66233b3d709637c01c8fa96c7776`, corrección sintáctica `171cd5abde97a0634bd25b6f0bc99f1786db9366`; workflow CI reparado desde versión válida `2da2e54dc1657f140fd2c12724595404176197af`. Hubo runs con error de workflow por duplicación accidental al insertar grep: ya resuelto, no equivale a defecto de motor. Informe propio `docs/coordination/items_parallel_v1/reports/W02/CAMP_006_ITER_02.md`.

**Nueva CI bloque02:** [run 41778869360](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41778869360), SHA `2da2e54dc1657f140fd2c12724595404176197af`. En última lectura: pasos puerta01, Python/Godot CAMP005, runner Godot CAMP006 completados `success`; regresiones CAMP004/CAMP003 `in_progress`. Solo declarar éxito global cuando `completed/success`, con logs de ese SHA. Si falla, reparar únicamente defecto propio. No usar CI verde como implementación positiva de mentas.

**Próximo `p`:** fila03 `lonely_mint;mild_mint;naive_mint`, previa verificación de gate/CI en la rama. Si IA6 no ha definido el contrato compartido, **reutilizar la dependencia única** sin crear 24 rechazos redundantes ni implementar naturaleza ficticia. No avanzar a fila04 sin otro `p`; nunca cambiar producción común sin coordinación de IA6.

---

# IA2/W02 — CAMPAÑA_006 · CONTINUIDAD BLOQUE 01 / CI005 RECOVERY GATE

**Identidad:** IA2/W02. **Rama exclusiva:** `codex/calvo-items-20261104-w02-camp006`. **Base:** `codex/calvo-items-20261103-w02-camp005`. Autoridad: `CAMPAIGN_006_W02_GATE.md`, `CAMPAIGN_006_W02_QUEUE_APPROVED.csv`, `campaigns/CAMP_006_W02.md`, `AUTONOMOUS_REPAIR_V5.md`. No tocar main, V28, PR118, árbitra, otras ramas ni APIs compartidas. No ejecutar fila02 antes de acreditación del gate de CAMP005 completa.

**Run fallido investigado:** [41742682811](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41742682811), job 126287947552, `CAMP005_W02_PY PASS blocks=10 checks=1267`, `CAMP005_W02_GODOT FAIL blocks=9 checks=16735`. Dos aserciones falsas: `exp_candy_xl_level99_gain` (active/reserve) exigía tope100 injustificadamente; el rótulo `relaxed_mint_level100: bloque íntegro` es error agregado de estado del bloque04, no error específico de menta.

**Causa matemática (fuente independiente):** Mew medium-slow, E(99)=1027103, E(100)=1059860, delta=32757. XL+30000 termina E=1057103, lvl99, a 2757 XP del máximo. En la fixture anterior `expect_cap=true` era incorrecto. Fix CAMP005 en propia rama: `expect_no_cap=true`, verificación estricta de XP total, nivel99 y exp_gained=30000; case `exp_candy_xl_level99_cap_50xp` permanece `expect_cap=true`. **Los 288 casos CAMP005 se preservaron.** Commits: fixture `09a55fd0d966b2e36ee3884e97b47732e9fe90cf`, Python `f29548d515c98212e3b15c673b0e746e9b6e2a6e`, Godot `c0f86eb8f16ba0e75ee6e0f4d7da8bc2cc6feec2`. Ningún código de producción cambiado.

**Nuevo bloque01:** Fixture `tests/fixtures/parallel_items/w02_campaign_006.json` (3 regresiones), Python `tests/tools/test_parallel_items_w02_campaign_006.py`, runner Godot `tests/gameplay/parallel_items_w02_campaign_006.gd` que invoca servicio original `_probe_training` y SaveV2, `docs/coordination/items_parallel_v1/reports/W02/CAMP_006_PROGRESO.csv` con fila01 `EN_CI_AUTOMATICA` y `ci_run=PENDIENTE_REEJECUCION`. No se contabilizan como IDs nuevos de entrenamiento.

**Workflow específico de esta rama:** `.github/workflows/parallel-camp006-w02-autoci.yml`; run [41763921080](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41763921080), SHA de código probado `2abcc2ae9644b8821d9dae6f26214b1a8fa347fc`. Durante seguimiento, los pasos `Puerta 01`, `Recuperación integral Python CAMP005`, `Recuperación integral Godot CAMP005` y `Godot CAMP006 bloque01` constaban como `completed/success`, regresiones CAMP004/CAMP003 `in_progress`. **No afirmar éxito global hasta que la ejecución finalice, los logs se recuperen y la conclusión se verifique.**

**Informe fuente:** `docs/coordination/items_parallel_v1/reports/W02/CAMP_006_ITER_01.md`. Debe actualizarse con conclusión real y recibos de 006/005/004/003. Solo después de gate PASS documentado se puede considerar fila02 en el próximo turno `p`; no ejecutarla en este turno.

**IMPORTANTE:** No solicitar autorización IA6 para reparar una expectativa propia, pero no implementar motor de naturaleza efectiva o mutar API compartida sin contrato y coordinación. Nunca retroceder pruebas ni atribuir éxito por cero casos.
