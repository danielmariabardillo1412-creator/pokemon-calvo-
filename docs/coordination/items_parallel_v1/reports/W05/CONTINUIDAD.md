# IA5/W05 — CAMPAÑA_006 · BLOQUE 02/10 PUBLICADO · CI PENDIENTE (2026-11-04)

**Rama única:** `codex/calvo-items-20261104-w05-camp006`. La cola IA6 autoriza bloque 02 `tm207;tm208;tm209;tm210;tm211`; mapeos SV comprobados `tm207=temper_flare, tm208=whirlpool, tm209=muddy_water, tm210=supercell_slam, tm211=electroweb`. **Commit de pruebas:** `5862ac6efbb9560efdcdea1d5e3606c65c6c1d6b`. Fixture acumulativo 2/10, diez MT; progreso y `CAMP_006_ITER_02.md` preparados. El runner Python y Godot anteriores permanecen sin cambios y deben probar ambas filas, incluido `FieldItemService.teach`, PP, stock, propiedad, compatibilidad, consumo y SaveV2. **NO DECLARAR PASS** hasta que CI del HEAD que incluya el CSV termine satisfactoriamente. Workflow W05 se dispara al escribir CSV/fixture; comprobar recibos reales CAMP006 PY y GODOT con `blocks=2` y checks positivos, más sus gates. Hitos de regresión completa 01/05/10; bloque 01 PASS ya comprobado en [Actions #41764725393](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41764725393).

**Próxima `p`:** si CI 02 PASS, ejecutar exactamente bloque 03 `tm212;tm213;tm214;tm215;tm216`; ante error, autorreparar solo en dominio W05. No tocar `main`, V28, PR #118, árbitra, otras ramas, datos/políticas, saves reales o máquinas históricas; no hacer merge. Godot headless no acredita UI/GPU.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_006 · BLOQUE 01/10 CI PASS VERIFICADA (2026-11-04)

**Identidad y control:** IA5/W05, MT/libros. **Rama exclusiva activa:** `codex/calvo-items-20261104-w05-camp006`, creada por IA6 a partir del cierre CAMP005 en SHA `f74b8d33c6d4e7853dcc4fdadfe3a62bf2050d0b`. Autoridad IA6 en `codex/calvo-items-20261101-arbitro`: `CAMPAIGN_006_W05_GATE.md`, `CAMPAIGN_006_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_006_W05.md`, `AUTONOMOUS_REPAIR_V5.md`. **Esta cabecera prevalece sobre el histórico posterior de CAMP005 FINALIZADA**: nueva campaña explícitamente autorizada. Cola oficial copiada idéntica a propia rama, blob `0f3f1af220dab2e2197b0f181a6f113a544828a6`.

**CAMP006 AUTORIZADA:** 49 MT activas en Scarlet/Violet, 10 microbloques (01..09 de 5 y 10 de 4); 28 `tm202`–`tm229` y 21 MT de numeración anterior aún pendientes. Las 19 históricas sin mapeo SV están excluidas. No inventar IDs ni cambiar fuentes. CAMP003, CAMP004, CAMP005 (60 MT cada una) conservadas como regresión.

**BLOQUE 01 EJECUTADO Y CERTIFICADO:** `tm202;tm203;tm204;tm205;tm206` → `pain_split;psych_up;double_edge;endeavor;petal_blizzard` desde perfil SV. Fixture `tests/fixtures/parallel_items/w05_campaign_006.json` con **1 bloque/5 MT** publicado en commit `450b10b189585977a3f30f044c95d38d1ab9062b`; progreso `reports/W05/CAMP_006_PROGRESO.csv` con fila 01 `EN_CI_AUTOMATICA` (histórica), commit `6eee6ccf80d41bae36063d1653babf085293426e`. Ejecutores específicos `tests/tools/test_parallel_items_w05_campaign_006.py` y `tests/gameplay/parallel_items_w05_campaign_006.gd` hacen pruebas efectivas, no solo metadatos: learnset SV compatible/incompatible, propietario, ausencia stock, consumo de una unidad, PP, movimiento conocido/rechazado sin mutación e identidad/SaveV2. Manifest `tests/tools/test_parallel_items_w05_campaign_006_manifest.py`, workflow `.github/workflows/parallel-camp006-w05-autoci.yml`. Todo reside únicamente en rama W05.

**CI FINAL DEL BLOQUE 01 PASS:** [Actions #41764725393](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41764725393), SHA de pruebas `cfb95bd64db841bdc8500129ffa781be34bdc99a`, job `126360311722`, `completed/success`. Recibos reales:
- `CAMP006_W05_MANIFEST_PASS reserved=10 completed=1 ids=49 kind=NEW_IDS`
- `CAMP006_W05_PY PASS blocks=1 checks=49`
- `CAMP006_GATE_PY_PASS worker=W05 blocks=1 checks=49`
- `CAMP006_W05_GODOT PASS blocks=1 checks=196`
- `CAMP006_GATE_GODOT_PASS worker=W05 blocks=1 checks=196`
- REGRESIÓN CAMP005 (60 MT): `CAMP005_W05_PY PASS blocks=10 checks=580`, `CAMP005_W05_GODOT PASS blocks=10 checks=2166`
- REGRESIÓN CAMP004 (60 MT): `CAMP004_W05_PY PASS blocks=10 checks=580`, `CAMP004_W05_GODOT PASS blocks=10 checks=2166`
- REGRESIÓN CAMP003 (60 MT): `CAMP003_W05_PY PASS blocks=10 checks=580`, `CAMP003_W05_GODOT PASS blocks=10 checks=2166`.

**Incidencias y soluciones propias W05:** CI inicial YAML inválida corregida `76196545511d694052d2eea9a56bdc7d70f2d2f0` y bootstrap estructural PASS [#41763897134](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41763897134). Rutas de cola equivocadas de Python/Godot corregidas `d464cdafc0bbb97379f48887c6ef4cbd3170509d`/`22032718dc7984373df505c664ff5ddd79aa9043`. Exclusión histórica incorrectamente aplicada a cola 006 corregida `7343c5367947de810f8c1f62b0a83733b0771ab9`. Godot `all_blocks` fuera de alcance corregido `cfb95bd64db841bdc8500129ffa781be34bdc99a`. Informe de auditoría detallado `reports/W05/CAMP_006_ITER_01.md`, última certificación commit `fd94264ea03c3dd7fc6f762337c2b5f86bf56da9`. Ninguna incidencia exigió parchear producción ni relajar pruebas.

**PRÓXIMA `p`:** ejecutar exactamente bloque **02** `tm207;tm208;tm209;tm210;tm211`, cotejar de nuevo cola IA6 y mapeo SV, añadir cinco casos a fixture y una fila CSV, validar Python/Godot y esperar los cuatro recibos reales CAMP006. Preservar positivos/negativos previos. Regresiones completas CAMP005/004/003 volverán a ejecutarse en hitos 05/10 o parche de producción, y ya se han ejecutado en 01. Si falla, diagnosticar/autorreparar en W05 bajo V5, sin tocar políticas/datos ni API compartida no asignada.

**LÍMITES:** prohibido modificar `main`, V28, PR118, árbitra, W01–W04, ramas ajenas, catálogo y learnsets canónicos, 19 máquinas inactivas, saves reales o hacer merge. La CI Godot headless acredita pruebas funcionales y SaveV2, **no UI/GPU ni integración global**. Al cerrar 10/10 declarar `CAMPAÑA_006_FINALIZADA` y STOP, sin bloque 11.

---

# ESTADO DEFINITIVO IA5/W05 — CAMPAÑA_005_FINALIZADA · CI PASS (2026-11-04)

**IDENTIDAD Y RAMA EXCLUSIVA:** IA5/W05, MT y libros, `codex/calvo-items-20261103-w05-camp005`. Autoridad IA6 `CAMPAIGN_005_W05_GATE.md`, `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W05.md` y `AUTONOMOUS_REPAIR_V5.md`. **Esta cabecera prevalece sobre todas las anteriores** y contiene el cierre definitivo.

**CAMPAÑA_005 COMPLETADA:** **10/10 bloques, 60/60 MT `tm142`–`tm201`** en Scarlet/Violet. Último bloque `tm196;tm197;tm198;tm199;tm200;tm201` → `flip_turn;dual_wingbeat;poltergeist;lash_out;scale_shot;misty_explosion`. Fixture `tests/fixtures/parallel_items/w05_campaign_005.json`, commit `d351a80cff579fc951e534580ab7fa26114b4868`. Progreso `reports/W05/CAMP_005_PROGRESO.csv`, última fila 10 `EN_CI_AUTOMATICA`, commit `b886c10756ad843d5f92834f29a42d31e63cf262`. Cotejo de todos los bloques contra cola IA6 y perfil canónico SV: 60 IDs únicos, 10 filas/10 bloques, sin duplicados ni divergencias. Informe final `CAMP_005_FINAL.md` certificado con commit `16726b624d03080eaa3783151398c02dc2549044`; `CAMP_005_ITER_10.md` actualizado con commit `bc024c777f5c663a17e96121eb5a97021673b859`.

**CI FINAL FUNCIONAL PASS:** [GitHub Actions #41742499805](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41742499805), SHA de pruebas `b886c10756ad843d5f92834f29a42d31e63cf262`, job `126287538668`, `completed/success`. Recibos exactos comprobados:
- `CAMP005_W05_MANIFEST_PASS reserved=10 completed=10 ids=60 kind=NEW_IDS`
- `CAMP005_W05_PY PASS blocks=10 checks=580`
- `CAMP005_GATE_PY_PASS worker=W05 blocks=10 checks=580`
- `CAMP005_W05_GODOT PASS blocks=10 checks=2166`
- `CAMP005_GATE_GODOT_PASS worker=W05 blocks=10 checks=2166`
- Regresión CAMP004 60 MT: `CAMP004_W05_PY PASS blocks=10 checks=580` y `CAMP004_W05_GODOT PASS blocks=10 checks=2166`
- Regresión CAMP003 60 MT: `CAMP003_W05_PY PASS blocks=10 checks=580` y `CAMP003_W05_GODOT PASS blocks=10 checks=2166`.

**LÍMITES E INTEGRACIÓN:** sin parches de producción; no se tocaron `main`, V28, PR118, árbitra, W01–W04, catálogos, learnsets, políticas, 19 MT legacy, guardados reales, workflows ni se realizó merge. Las etiquetas CSV `EN_CI_AUTOMATICA` documentan el estado al publicar, no el veredicto posterior; no reescribir para evitar otro run. CI Godot headless acredita lógica/SaveV2, **no UI ni GPU**. El resultado de CI W05 no significa integración global en el juego: **IA6 deberá auditar el diff y coordinar la integración**.

**STOP OFICIAL:** `CAMPAÑA_005_FINALIZADA`. No ejecutar bloque 11 ni iniciar campaña nueva por una simple `p`. IA5/W05 queda detenida hasta nueva autorización explícita de IA6. Todo el histórico del cuaderno se conserva a continuación.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_005 · 10/10 ENTREGADO · CI FINAL POR VERIFICAR (2026-11-04)

**Identidad:** IA5/W05, MT/libros. **Rama exclusiva** `codex/calvo-items-20261103-w05-camp005`. Gate de IA6 `CAMPAIGN_005_W05_GATE.md`, cola `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, encargo `campaigns/CAMP_005_W05.md`, protocolo `AUTONOMOUS_REPAIR_V5.md`. Esta cabecera prevalece sobre estados inferiores. CAMP004 y CAMP003 siguen cerradas, 60 MT cada una, preservadas como regresiones.

**BLOQUE 10 ENTREGADO:** `tm196;tm197;tm198;tm199;tm200;tm201` → `flip_turn;dual_wingbeat;poltergeist;lash_out;scale_shot;misty_explosion` en mapeo Scarlet/Violet. Fixture `tests/fixtures/parallel_items/w05_campaign_005.json`, ahora **10 bloques/60 IDs**, commit `d351a80cff579fc951e534580ab7fa26114b4868`. CSV `reports/W05/CAMP_005_PROGRESO.csv`, nueva fila 10 `EN_CI_AUTOMATICA`, commit `b886c10756ad843d5f92834f29a42d31e63cf262`. Informes `CAMP_005_ITER_10.md` y `CAMP_005_FINAL.md`, commits `f944ec742a99ece8320e3f7319d1fcda96bb7cfa` y `3e88590f798e099ba3c10f2e873fb8e843ee08cb`. Cotejo estático: 60 IDs únicos, 10 bloques/10 filas, seis por bloque, parejas exactas a cola de IA6 y perfil canónico SV, cero discrepancias; esta comprobación no equivale a CI funcional.

**CI 01–09 PASS VERIFICADA:** [Actions #41737890652](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41737890652), SHA `0a69eaf51999f7a26cd69e34cf52f43f7a2ff5ff`, `completed/success`, Python `CAMP005_W05_PY PASS blocks=9 checks=522`, Godot `CAMP005_W05_GODOT PASS blocks=9 checks=1951`, gates PASS. Regresiones CAMP004 y CAMP003, cada una 60 MT, Python 580 y Godot 2166 checks, pasaron en hito 05 [#41721306449](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41721306449).

**CI FINAL EN CURSO:** [Actions #41742499805](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41742499805) sobre SHA `b886c10756ad843d5f92834f29a42d31e63cf262`, observado `in_progress` preparando Godot 4.7. Para certificar cierre: `completed/success`, `CAMP005_W05_PY PASS blocks=10`, `CAMP005_W05_GODOT PASS blocks=10`, ambos gates, **más regresiones CAMP004 y CAMP003 completas Python y Godot en este mismo run**, no solo registros antiguos. El run intermedio del fixture #41742478253 puede cancelarse por concurrencia. Etiqueta del CSV `EN_CI_AUTOMATICA` es estado histórico, no reescribir solo por PASS para no relanzar CI.

**SIGUIENTE ACCIÓN:** verificar y anotar los recibos exactos del run final en `CAMP_005_ITER_10.md`, `CAMP_005_FINAL.md` y aquí. Si verde: `CAMPAÑA_005_FINALIZADA` y **STOP** (no hay bloque 11); IA6 recibe la entrega para auditar e integrar según gate, sin merge desde W05. Si fallo: diagnosticar/reparar únicamente ámbito W05 bajo V5 sin rebajar aserciones y repetir CI. No tocar `main`, V28, PR118, árbitra, otras W, catálogo/learnsets/políticas, 19 MT legacy inactivas, partidas reales, workflows. Godot headless no valida UI/GPU.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_005 · 09/10 CI PASS VERIFICADA (2026-11-04)

**Identidad:** IA5/W05, dominio MT/libros. **Rama exclusiva activa:** `codex/calvo-items-20261103-w05-camp005`. Autorización IA6 `CAMPAIGN_005_W05_GATE.md`, `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W05.md` y `AUTONOMOUS_REPAIR_V5.md`, de la rama árbitra. Esta cabecera prevalece sobre estados históricos de CI pendiente de más abajo. CAMP004 y CAMP003 están cerradas: 60 MT anteriores cada una, preservar como regresión.

**BLOQUE 09 CERTIFICADO:** `tm190;tm191;tm192;tm193;tm194;tm195` → `solar_blade;uproar;focus_punch;weather_ball;grassy_glide;burning_jealousy` en perfil SV. Fixture `tests/fixtures/parallel_items/w05_campaign_005.json`: **9 bloques/54 MT únicas**, commit `c521dfeb8cf04ca45f224d0690d9e9d600052ca6`. CSV `reports/W05/CAMP_005_PROGRESO.csv`: fila 09 `EN_CI_AUTOMATICA`, commit `0a69eaf51999f7a26cd69e34cf52f43f7a2ff5ff`. Informe `CAMP_005_ITER_09.md` certificado con commit `87b899d4bf7a256850744a07a23241b815249b96`. Validación estática en GitHub: nueve bloques y filas, 54 IDs sin repetidos y seis por bloque; posiciones, movimiento y orden idénticos a cola IA6 y mapeo SV, sin diferencias. No se modificaron runners ni producción.

**CI FUNCIONAL REAL SUCCESS:** [Actions #41737890652](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41737890652), SHA funcional `0a69eaf51999f7a26cd69e34cf52f43f7a2ff5ff`, job `126272071488`, `completed/success`. Logs:
- `CAMP005_W05_MANIFEST_PASS reserved=10 completed=9 ids=60 kind=NEW_IDS`
- `CAMP005_W05_PY PASS blocks=9 checks=522`
- `CAMP005_GATE_PY_PASS worker=W05 blocks=9 checks=522`
- `CAMP005_W05_GODOT PASS blocks=9 checks=1951`
- `CAMP005_GATE_GODOT_PASS worker=W05 blocks=9 checks=1951`.
**54/54 MT CAMP005 verificadas funcionalmente mediante Python y Godot headless**, con casos reales de compatibilidad, propietario, stock, PP, consumo, rechazo y SaveV2.

**REGRESIONES:** CAMP004 y CAMP003 (60 MT cada una) pasaron Python 580 / Godot 2166 checks por campaña en el hito 05 [#41721306449](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41721306449). No se ejecutaron en bloque 09 por no ser hito ni haber parche de producción. Su ejecución es obligatoria en 10/10. Las filas CSV `EN_CI_AUTOMATICA` son registros históricos y no se reescriben solo por PASS para no relanzar CI. La CI headless no valida UI/GPU.

**SIGUIENTE `p`:** comprobar la rama, fila IA6 y mapeo SV; ejecutar exclusivamente bloque **10/10** `tm196;tm197;tm198;tm199;tm200;tm201`, actualizar un bloque fixture/una fila CSV, correr CI Python/Godot CAMP005 y todas las regresiones CAMP004 y CAMP003, verificar recibos `completed/success`; publicar `CAMP_005_ITER_10.md`, `CAMP_005_FINAL.md`, actualizar continuidad y declarar `CAMPAÑA_005_FINALIZADA` y STOP. No ejecutar bloque 11. Ante fallo investigar/autorreparar en W05 con autonomía V5 sin bajar aserciones. No tocar `main`, V28, PR118, árbitra, ramas de otras trabajadoras, catálogo/learnsets/políticas, 19 máquinas históricas, partidas reales, workflows o hacer merge.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_005 · 09/10 ENTREGADO, CI PENDIENTE (2026-11-04)

**Identidad:** IA5/W05, MT/libros. **Rama exclusiva:** `codex/calvo-items-20261103-w05-camp005`. Autoridad IA6: `CAMPAIGN_005_W05_GATE.md`, `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W05.md`, `AUTONOMOUS_REPAIR_V5.md` de la rama árbitra. Esta cabecera prevalece sobre estados inferiores. CAMP004 y CAMP003, 60 MT cada una, cerradas y conservadas como regresiones.

**BLOQUE 09 ENTREGADO:** `tm190;tm191;tm192;tm193;tm194;tm195` → `solar_blade;uproar;focus_punch;weather_ball;grassy_glide;burning_jealousy` en SV. Fixture `tests/fixtures/parallel_items/w05_campaign_005.json` con **9 bloques/54 MT**, commit `c521dfeb8cf04ca45f224d0690d9e9d600052ca6`. Progreso `reports/W05/CAMP_005_PROGRESO.csv`, fila 09 `EN_CI_AUTOMATICA`, commit `0a69eaf51999f7a26cd69e34cf52f43f7a2ff5ff`. Informe `CAMP_005_ITER_09.md`, commit `da88eeab3420014d86afd5ed287c17cd71d4fa9a`. Cotejo estático: 9 bloques y filas, 54 IDs únicos sin duplicados y movimiento/orden idéntico a cola IA6 y mapeo canónico SV; sin cambios de runners ni producción. Este cotejo no sustituye a CI funcional.

**CI ANTERIOR 01–08 VERIFICADA:** [Actions #41733471535](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41733471535), SHA `e455c80adb322fff21866e914e2538f6586e8706`, `completed/success`; `CAMP005_W05_PY PASS blocks=8 checks=464`, `CAMP005_W05_GODOT PASS blocks=8 checks=1736`, gates PASS. En hito 05 [#41721306449](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41721306449), CAMP004 60 MT y CAMP003 60 MT pasaron Python 580 y Godot 2166 comprobaciones por campaña.

**CI BLOQUE 09 POR VERIFICAR:** [Actions #41737890652](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41737890652), SHA `0a69eaf51999f7a26cd69e34cf52f43f7a2ff5ff`, inicialmente `pending`; run fixture intermedio #41737864787 puede cancelarse por concurrencia. Exigir `completed/success`, recibos `CAMP005_W05_PY PASS blocks=9`, `CAMP005_W05_GODOT PASS blocks=9`, ambos gates. Regresiones CAMP004/003 programadas en hito 10 o cambios de producción, no en bloque 09.

**SIGUIENTE `p`:** comprobar primero CI 09; después ejecutar exclusivamente **bloque 10/10** `tm196;tm197;tm198;tm199;tm200;tm201`, con nueva prueba funcional y regresión completa de CAMP004 y CAMP003 en el mismo run. Si falla cualquier prueba, diagnosticar y autorreparar dentro de W05 según V5, sin rebajar aserciones. Prohibido tocar `main`, V28, PR118, árbitra, otras W, catálogo/learnsets/políticas, 19 MT legacy inactivas, saves, workflows o merge. Una vez acabado 10/10 y CI PASS, publicar consolidado `CAMP_005_FINAL.md`, declarar `CAMPAÑA_005_FINALIZADA` y STOP; sin bloque 11. CI Godot headless no verifica GPU/UI.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_005 · 08/10 CI PASS VERIFICADA (2026-11-03)

**Identidad:** IA5/W05, MT/libros; **rama exclusiva** `codex/calvo-items-20261103-w05-camp005`. Autoridad IA6: `CAMPAIGN_005_W05_GATE.md`, `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W05.md` y `AUTONOMOUS_REPAIR_V5.md`, de la rama árbitra. Este encabezado prevalece sobre notas antiguas. CAMP004 y CAMP003 son campañas previas de 60 MT cada una, conservadas y solo regresionadas.

**BLOQUE 08 CERTIFICADO:** `tm184;tm185;tm186;tm187;tm188;tm189` → `vacuum_wave;lunge;high_horsepower;icicle_spear;scald;heat_crash` según perfil `scarlet-violet`. Fixture `tests/fixtures/parallel_items/w05_campaign_005.json`, **8 bloques/48 MT**, commit `a1c2d55b7d652e6c01829542a5216c8abbfa0327`. Progreso `reports/W05/CAMP_005_PROGRESO.csv`, fila 08 `EN_CI_AUTOMATICA`, commit `e455c80adb322fff21866e914e2538f6586e8706`. Informe `CAMP_005_ITER_08.md` certificado commit `2f0cd3eb780168a143f5baba904301b9e76809e4`. Cotejo estático: 8 bloques y filas, 48 IDs distintos, seis por bloque, movimientos exactos a cola IA6 y perfil SV; cero discrepancias. Runners/producción sin cambios.

**CI FUNCIONAL VERIFICADA SUCCESS:** [Actions #41733471535](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41733471535), SHA `e455c80adb322fff21866e914e2538f6586e8706`, job `126256918456`, `completed/success`. Logs:
- `CAMP005_W05_PY PASS blocks=8 checks=464`
- `CAMP005_GATE_PY_PASS worker=W05 blocks=8 checks=464`
- `CAMP005_W05_GODOT PASS blocks=8 checks=1736`
- `CAMP005_GATE_GODOT_PASS worker=W05 blocks=8 checks=1736`
- `CAMP005_W05_MANIFEST_PASS reserved=10 completed=8 ids=60 kind=NEW_IDS`.

**REGRESIONES:** CAMP004 60 MT y CAMP003 60 MT pasaron Python 580/Godot 2166 comprobaciones por campaña en hito 05 [#41721306449](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41721306449). No se ejecutaron en bloque 08, sin cambios de producción. Nuevamente obligatorias en hito 10. La etiqueta CSV `EN_CI_AUTOMATICA` es histórica y no se altera solo para registrar PASS, evitando relanzar CI. Godot headless no prueba visuales/GPU.

**SIGUIENTE `p`:** ejecutar exclusivamente bloque **09** `tm190;tm191;tm192;tm193;tm194;tm195`, verificando cola de IA6 y mapeo SV antes de añadir una fila de progreso y bloque fixture; probar CI. En caso de fallo, diagnosticar y autorreparar bajo V5 solo dentro de W05 sin reducir aserciones; escalar conflictos de función compartida/política o permisos realmente denegados. No tocar `main`, V28, PR118, árbitra, W01–W04, otras ramas W05, catálogo/learnsets/políticas, 19 MT legacy, partidas reales, workflows ni hacer merge. Al completar 10/10 declarar `CAMPAÑA_005_FINALIZADA` y STOP.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_005 · 08/10 ENTREGADO · CI PENDIENTE (2026-11-03)

**Identidad:** IA5/W05, dominio MT/libros. **Rama única activa:** `codex/calvo-items-20261103-w05-camp005`. Autoridad IA6 `CAMPAIGN_005_W05_GATE.md`, `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W05.md`, protocolo `AUTONOMOUS_REPAIR_V5.md` de la rama árbitra. Esta cabecera prevalece sobre los estados históricos inferiores; no retomar CAMP004 ni CAMP003 como trabajo nuevo: ambas son regresiones de 60 MT anteriores cada una.

**BLOQUE 08 ENTREGADO:** `tm184;tm185;tm186;tm187;tm188;tm189` → `vacuum_wave;lunge;high_horsepower;icicle_spear;scald;heat_crash` en versión `scarlet-violet`. Fixture `tests/fixtures/parallel_items/w05_campaign_005.json` con **8 bloques/48 MT** commit `a1c2d55b7d652e6c01829542a5216c8abbfa0327`. Progreso `reports/W05/CAMP_005_PROGRESO.csv` fila 08 `EN_CI_AUTOMATICA`, commit `e455c80adb322fff21866e914e2538f6586e8706`. Informe `CAMP_005_ITER_08.md` commit `b5aa4b9e96aee864890dcf3b9520d0be077badc2`. Comparación estática real: ocho bloques/filas, seis IDs por bloque, 48 únicos, orden y movimientos idénticos a cola IA6 y perfil canónico SV. Sin cambios de runners ni producción; esta comprobación documental no prueba por sí sola enseñanza.

**CI ANTERIOR 01–07 VERIFICADA:** [Actions #41727197381](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41727197381), SHA `fba3e31a39ed4416745541742004dd16ca5d51fc`, `completed/success`; Python `CAMP005_W05_PY PASS blocks=7 checks=406`, Godot `CAMP005_W05_GODOT PASS blocks=7 checks=1521`, ambos gates. Regresiones CAMP004 60 MT y CAMP003 60 MT pasaron en hito 05 [#41721306449](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41721306449) con Python 580/Godot 2166 checks por campaña.

**CI BLOQUE 08 PENDIENTE AL PUBLICAR:** [Actions #41733471535](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41733471535), SHA de progreso `e455c80adb322fff21866e914e2538f6586e8706`, inicialmente `pending`; el run intermedio #41733442793 podría cancelarse por concurrencia. Para certificar 48 MT exigir `completed/success` y recibos `CAMP005_W05_PY PASS blocks=8`, `CAMP005_W05_GODOT PASS blocks=8`, ambos gates. Regresiones completas CAMP004/CAMP003 se repiten en hito 10 o parche de producción; no estaban programadas para 08.

**PRÓXIMA `p`:** comprobar CI 08; ejecutar exclusivamente bloque **09** `tm190;tm191;tm192;tm193;tm194;tm195` tras confirmar fila y perfil SV; añadir un bloque fixture y una fila CSV, informe y continuidad, verificar CI. Si falla, investigar/autorreparar bajo V5 en dominio W05 sin rebajar aserciones; conflictos de API compartida, política o ACL denegada real a IA6. Prohibido `main`, V28, PR118, árbitra, otras W, catálogos/learnsets/políticas, 19 máquinas legacy, partidas, workflows o merge. Al 10/10 comunicar `CAMPAÑA_005_FINALIZADA` y STOP; Godot headless no valida UI/GPU.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_005 · 07/10 CI PASS VERIFICADA (2026-11-03)

**Identidad:** IA5/W05, MT/libros. **Rama única activa:** `codex/calvo-items-20261103-w05-camp005`. Autoridad IA6 `CAMPAIGN_005_W05_GATE.md`, `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W05.md` y `AUTONOMOUS_REPAIR_V5.md`. Este estado prevalece sobre el historial inferior. CAMP004 y CAMP003 son dos campañas previas de 60 MT cada una, conservadas y regresionadas, no sumadas de nuevo al trabajo propio CAMP005.

**BLOQUE 07 CERTIFICADO:** `tm178;tm179;tm180;tm181;tm182;tm183` → `gravity;smack_down;gyro_ball;knock_off;bug_bite;super_fang` según versión Scarlet/Violet. Fixture `tests/fixtures/parallel_items/w05_campaign_005.json`, 7 bloques/42 MT únicas, commit `e68be042d3e4a5d6bd71686852658e05068683d3`. Progreso `reports/W05/CAMP_005_PROGRESO.csv`, fila 07 `EN_CI_AUTOMATICA`, commit `fba3e31a39ed4416745541742004dd16ca5d51fc`. Informe `CAMP_005_ITER_07.md` certificado con commit `5dc68fcb75ef8d37b6bb6d2c4b10c6be04ca4ae5`. Cotejo estático: 42 IDs distintos, siete bloques y filas, parejas y orden iguales a cola IA6 y mapeo SV. Sin modificación de runners ni producción.

**CI FUNCIONAL PASS:** [GitHub Actions #41727197381](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41727197381), SHA funcional `fba3e31a39ed4416745541742004dd16ca5d51fc`, job `126235426472`, `completed/success`. Recibos reales:
- `CAMP005_W05_MANIFEST_PASS reserved=10 completed=7 ids=60 kind=NEW_IDS`
- `CAMP005_W05_PY PASS blocks=7 checks=406`
- `CAMP005_GATE_PY_PASS worker=W05 blocks=7 checks=406`
- `CAMP005_W05_GODOT PASS blocks=7 checks=1521`
- `CAMP005_GATE_GODOT_PASS worker=W05 blocks=7 checks=1521`.

**REGRESIONES:** CAMP004 60 MT y CAMP003 60 MT, pruebas Python 580/Godot 2166 por campaña, pasaron en el hito 05 [#41721306449](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41721306449); no se ejecutaron otra vez en bloque 07 al no haber parche de producción. Se repiten en hito 10. Los estados CSV `EN_CI_AUTOMATICA` son históricos y no se reescriben solo para anotar PASS, pues relanzarían CI. Godot headless no acredita visuales/GPU.

**SIGUIENTE `p`:** ejecutar exclusivamente bloque **08** `tm184;tm185;tm186;tm187;tm188;tm189`, previa lectura de cola IA6 y mapeo activo SV, añadir solo un bloque fixture y una fila CSV; ejecutar CI Python/Godot. Ante fallo reparar dentro de W05 con autonomía V5, sin reducir pruebas; escalar un conflicto compartido o permisos efectivamente denegados a IA6. No tocar `main`, V28, PR118, árbitra, W01–W04, otras ramas W05, catálogo/learnsets/políticas, 19 MT históricas, partidas reales, workflows ni hacer merge. Al completar 10/10 declarar `CAMPAÑA_005_FINALIZADA` y STOP.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_005 · 07/10 ENTREGADO · CI PENDIENTE (2026-11-03)

**Identidad:** IA5/W05, responsable de MT/libros. **Rama exclusiva activa:** `codex/calvo-items-20261103-w05-camp005`. Gate de IA6 `CAMPAIGN_005_W05_GATE.md`, cola `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, encargo `campaigns/CAMP_005_W05.md`, autorreparación `AUTONOMOUS_REPAIR_V5.md`. Esta cabecera prevalece sobre notas históricas inferiores. CAMP004 (60 MT) y CAMP003 (60 MT) conservadas como regresión, no recalcular como nuevas.

**BLOQUE 07 ENTREGADO:** `tm178;tm179;tm180;tm181;tm182;tm183` → `gravity;smack_down;gyro_ball;knock_off;bug_bite;super_fang` con mapeos canónicos SV. Fixture `tests/fixtures/parallel_items/w05_campaign_005.json` **7 bloques/42 MT**, commit `e68be042d3e4a5d6bd71686852658e05068683d3`; CSV `reports/W05/CAMP_005_PROGRESO.csv` con única fila 07 `EN_CI_AUTOMATICA`, commit `fba3e31a39ed4416745541742004dd16ca5d51fc`; informe `CAMP_005_ITER_07.md`, commit `74520f175b85e80d8d87aa4a07a9b5b0384ab8ab`. Cotejo estático: siete bloques, siete filas, 42 IDs únicos, seis por bloque, coincidencia exacta de IDs/orden/movimientos con cola IA6 y perfil SV, cero errores. Ni runners ni producción modificados.

**CI ANTERIOR 01–06 VERIFICADA:** [Actions #41722664035](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41722664035), SHA `bbb4e1f3ec3da2b6473bc0dc5d572680e67f1463`, `completed/success`; `CAMP005_W05_PY PASS blocks=6 checks=348`, `CAMP005_W05_GODOT PASS blocks=6 checks=1306`, ambos gates PASS. Regresiones históricas CAMP004 60 MT y CAMP003 60 MT verificadas PASS en el hito 05 [#41721306449](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41721306449), Python 580/Godot 2166 checks en cada campaña.

**CI BLOQUE 07 POR VERIFICAR:** [Actions #41727197381](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41727197381), SHA de progreso `fba3e31a39ed4416745541742004dd16ca5d51fc`, inicialmente `pending`. La ejecución intermedia de fixture #41727170257 puede cancelarse por concurrencia. Requerir `completed/success`, `CAMP005_W05_PY PASS blocks=7`, `CAMP005_W05_GODOT PASS blocks=7`, ambos gates, N checks positivo. CAMP004/003 regresionadas en hito 05 y otra vez previstas en hito 10/parche de producción; no atribuir nuevas regresiones a 07 sin evidencia.

**SIGUIENTE `p`:** comprobar CI 07; ejecutar solo **bloque 08** `tm184;tm185;tm186;tm187;tm188;tm189` según cola/mapeo SV y publicar fixture/CSV/informe/cuaderno. Si CI falla, diagnosticar logs y autorreparar bajo V5 arnés W05 o defecto comprobado en `teach`, sin rebajar aserciones. Escalar solo conflicto de funciones compartidas, política o permiso realmente denegado a IA6. Prohibido `main`, V28, PR118, árbitra, otras W, catálogo/learnsets/políticas, 19 MT históricas, partidas reales, workflows y merge. Al 10/10 `CAMPAÑA_005_FINALIZADA` y STOP. CI Godot headless no valida UI/GPU.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_005 · 06/10 CI PASS VERIFICADA (2026-11-03)

**Identidad:** IA5/W05, responsable de MT y libros. **Rama exclusiva activa:** `codex/calvo-items-20261103-w05-camp005`. Gate IA6 `CAMPAIGN_005_W05_GATE.md`, cola `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, encargo `campaigns/CAMP_005_W05.md` y autonomía `AUTONOMOUS_REPAIR_V5.md`. Esta cabecera prevalece sobre los estados históricos inferiores; las 60 MT de CAMP004 y 60 MT de CAMP003 siguen cerradas y protegidas como regresión.

**BLOQUE 06 CERTIFICADO:** `tm172;tm173;tm174;tm175;tm176;tm177` → `roar;charge;haze;toxic;sand_tomb;spite` en perfil SV. Fixture `tests/fixtures/parallel_items/w05_campaign_005.json`, 6 bloques/36 MT, commit `7be70541c7879b2856cef432a2a1eb001939ca53`; CSV `reports/W05/CAMP_005_PROGRESO.csv`, fila 06 `EN_CI_AUTOMATICA`, commit `bbb4e1f3ec3da2b6473bc0dc5d572680e67f1463`. Informe `CAMP_005_ITER_06.md` certificado con commit `8bfe68c1fd4ce531c709f2d73cf32182204dbfff`. Cotejo estático: 36 MT únicas, 6 bloques y filas de seis IDs, movimientos idénticos a cola IA6 y catálogo SV, cero desviaciones. Runners y producción sin cambios.

**CI REAL PASS:** [Actions #41722664035](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41722664035), SHA funcional `bbb4e1f3ec3da2b6473bc0dc5d572680e67f1463`, job `126219771697`, `completed/success`, recibos reales:
- `CAMP005_W05_PY PASS blocks=6 checks=348`
- `CAMP005_GATE_PY_PASS worker=W05 blocks=6 checks=348`
- `CAMP005_W05_GODOT PASS blocks=6 checks=1306`
- `CAMP005_GATE_GODOT_PASS worker=W05 blocks=6 checks=1306`
- Manifiesto `CAMP005_W05_MANIFEST_PASS reserved=10 completed=6 ids=60 kind=NEW_IDS`.

**REGRESIONES:** CAMP004 60 MT y CAMP003 60 MT Python/Godot fueron verificadas PASS en el hito anterior [#41721306449](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41721306449): CAMP004 Python 580 / Godot 2166 y CAMP003 Python 580 / Godot 2166; no se ejecutaron nuevamente en el bloque 06 al no haber cambios de producción. La fila CSV `EN_CI_AUTOMATICA` es histórica: no reescribir para reflejar PASS porque relanzaría CI. Godot headless no valida UI/GPU.

**SIGUIENTE `p`:** ejecutar exclusivamente bloque **07** `tm178;tm179;tm180;tm181;tm182;tm183`. Comprobar rama, cola IA6 y mapeo SV antes de añadir un bloque/una fila, y verificar CI real. Ante error autorreparar bajo V5 solo arnés o función W05 probada, sin rebajar aserciones; conflicto de arquitectura, regla global o ACL realmente denegada → IA6. No tocar `main`, V28, PR118, árbitra, W01–W04, otras ramas W05, catálogo/learnsets, políticas, 19 legacy, partidas reales, workflows ni merge. Al 10/10 `CAMPAÑA_005_FINALIZADA` y STOP.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_005 · 06/10 ENTREGADO · CI PENDIENTE (2026-11-03)

**Identidad y control:** IA5/W05, MT/libros, rama exclusiva `codex/calvo-items-20261103-w05-camp005`. Autoridad IA6 `CAMPAIGN_005_W05_GATE.md`, `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W05.md`, `AUTONOMOUS_REPAIR_V5.md`. Esta cabecera prevalece sobre estados anteriores. CAMP004 y CAMP003 cerradas, 60 MT cada una, conservadas como regresión.

**BLOQUE 06 ENTREGADO:** `tm172;tm173;tm174;tm175;tm176;tm177` → `roar;charge;haze;toxic;sand_tomb;spite` en SV. Fixture `tests/fixtures/parallel_items/w05_campaign_005.json` de 6 bloques/36 MT, commit `7be70541c7879b2856cef432a2a1eb001939ca53`; progreso `reports/W05/CAMP_005_PROGRESO.csv`, fila nueva 06 `EN_CI_AUTOMATICA`, commit `bbb4e1f3ec3da2b6473bc0dc5d572680e67f1463`; informe `CAMP_005_ITER_06.md` commit `2094afa6aa1de51fdf13baa1f5fa9cb9753da56d`. Control estático verificado: 36 IDs únicos, seis bloques/filas, pareja y orden exactos respecto a cola IA6 y perfil SV, cero discrepancias. Sin cambios de arnés ni producción. El cotejo no equivale a funcionamiento positivo de las seis nuevas MT.

**CI BLOQUES 01–05 Y REGRESIONES VERIFICADAS:** [#41721306449](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41721306449), SHA `b47e6ecc45d96b0b6d3bb901a5aed66a9370c85a`, `completed/success`; CAMP005 Python 290 y Godot 1091 checks PASS, gates PASS. Regresión CAMP004 60 MT: Python 580/Godot 2166 checks PASS; regresión CAMP003 60 MT: Python 580/Godot 2166 checks PASS.

**CI BLOQUE 06 POR VERIFICAR:** [#41722664035](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41722664035), SHA de progreso `bbb4e1f3ec3da2b6473bc0dc5d572680e67f1463`, inicial `pending`. El run del fixture #41722635151 podría cancelarse por concurrencia. Para certificar las 36 MT comprobar run `completed/success` y recibos `CAMP005_W05_PY PASS blocks=6`, `CAMP005_W05_GODOT PASS blocks=6`, y gates. Regresiones CAMP004/003 se repiten por workflow en hito 10 o con parche de producción, no en bloque 06.

**SIGUIENTE `p`:** verificar la CI 06 y ejecutar solo bloque 07 `tm178;tm179;tm180;tm181;tm182;tm183`, siguiendo mapeo SV y cola IA6. Ante fallo, diagnosticar/autorreparar bajo V5 en arnés W05 o función propia de enseñanza con pruebas reales, sin relajar aserciones. Si hay conflicto con API compartida, reglas globales o ACL denegada real, escalar IA6. No tocar `main`, V28, PR118, árbitra, otras W, catálogos/learnsets/políticas, 19 máquinas históricas, saves, workflows o merge. Al 10/10 `CAMPAÑA_005_FINALIZADA` y STOP; Godot headless no valida UI/GPU.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_005 · 05/10 CI Y REGRESIONES PASS (2026-11-03)

**Identidad:** IA5/W05 responsable de MT/libros. **Rama exclusiva:** `codex/calvo-items-20261103-w05-camp005`. Fuente IA6 `CAMPAIGN_005_W05_GATE.md`, `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W05.md`, `AUTONOMOUS_REPAIR_V5.md`. Esta cabecera prevalece sobre estados históricos de CI pendiente que aparecen más abajo. CAMP004 y CAMP003 son 60 MT anteriores cada una, conservadas y verificadas como regresión.

**BLOQUE 05 CERTIFICADO:** `tm166;tm167;tm168;tm169;tm170;tm171` → `thunder;close_combat;solar_beam;draco_meteor;steel_beam;tera_blast` en SV. Fixture `tests/fixtures/parallel_items/w05_campaign_005.json` **5 bloques / 30 MT únicas**, commit `c58a37bfd5f06550d0097ab58405680188622a0a`; CSV `reports/W05/CAMP_005_PROGRESO.csv`, fila 05 `EN_CI_AUTOMATICA`, commit `b47e6ecc45d96b0b6d3bb901a5aed66a9370c85a`; informe `CAMP_005_ITER_05.md` certificado, commit `3d29ffc74f80ade859c2e642c3011dd952c7a070`. Revisión estática real: cinco bloques y filas, 30 IDs distintos sin duplicados, movimientos idénticos a cola IA6 y perfil SV. Tests y producción intactos.

**CI HITO 05 COMPLETED/SUCCESS VERIFICADA:** [Actions #41721306449](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41721306449), SHA `b47e6ecc45d96b0b6d3bb901a5aed66a9370c85a`, job `126215005633`, logs:
- `CAMP005_W05_PY PASS blocks=5 checks=290`
- `CAMP005_GATE_PY_PASS worker=W05 blocks=5 checks=290`
- `CAMP005_W05_GODOT PASS blocks=5 checks=1091`
- `CAMP005_GATE_GODOT_PASS worker=W05 blocks=5 checks=1091`
- CAMP004, 60 MT: `CAMP004_W05_PY PASS blocks=10 checks=580`, `CAMP004_W05_GODOT PASS blocks=10 checks=2166`
- CAMP003, 60 MT: `CAMP003_W05_PY PASS blocks=10 checks=580`, `CAMP003_W05_GODOT PASS blocks=10 checks=2166`.
**30/30 MT de CAMP005 certificadas en CI real y 120 MT anteriores regresionadas con PASS.** El CSV mantiene la etiqueta histórica de publicación `EN_CI_AUTOMATICA`: no reescribir para evitar CI redundante. Sin cambios de producción ni merge. Godot headless no valida UI/GPU.

**PRÓXIMA `p`:** ejecutar exclusivamente bloque **06** `tm172;tm173;tm174;tm175;tm176;tm177` previa comprobación de la rama y asignación/mapeos SV de IA6; ampliar sólo fixture, CSV e informe/cuaderno W05. Regresiones completas nuevamente obligatorias en hito 10 o si se modifica producción propia; no atribuirlas a runs intermedios sin logs. Ante fallo investigar y autorreparar en W05 bajo V5 sin rebajar casos. No tocar `main`, V28, PR118, rama árbitra, otras W, catálogos/learnsets/políticas, 19 MT legacy inactivas, partidas o workflows. Al 10/10 decir `CAMPAÑA_005_FINALIZADA` y STOP, sin merge automático.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_005 · 05/10 ENTREGADO · CI Y REGRESIONES PENDIENTES (2026-11-03)

**Identidad:** IA5/W05 responsable de MT y libros. **Rama exclusiva** `codex/calvo-items-20261103-w05-camp005`. Gate IA6 `CAMPAIGN_005_W05_GATE.md`, cola `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, encargo `campaigns/CAMP_005_W05.md`, protocolo `AUTONOMOUS_REPAIR_V5.md`. Esta cabecera prevalece sobre las anteriores; CAMP004 y CAMP003 son las dos familias de regresión de 60 MT cada una, no se repiten como nuevos trabajos.

**HITO BLOQUE 05 ENTREGADO:** `tm166;tm167;tm168;tm169;tm170;tm171` → `thunder;close_combat;solar_beam;draco_meteor;steel_beam;tera_blast` mapeo Scarlet/Violet. Fixture `tests/fixtures/parallel_items/w05_campaign_005.json` ahora **5 bloques/30 MT** commit `c58a37bfd5f06550d0097ab58405680188622a0a`. Progreso `reports/W05/CAMP_005_PROGRESO.csv` con una fila `05` `EN_CI_AUTOMATICA` commit `b47e6ecc45d96b0b6d3bb901a5aed66a9370c85a`. Informe `CAMP_005_ITER_05.md` commit `d66c13b655dff629273ae152cda17d741adcccf6`. Validación estática tras ambos commits: 5 bloques, 5 filas, 30 IDs únicos, parejas exactas a cola IA6 y perfil SV, cero discrepancias. Runners y producción sin cambios.

**CI ANTERIOR 01–04 VERIFICADA:** [Actions #41720191745](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41720191745), SHA `fc87f105b9f5b979d7f5dc6f0f73f5b026dbca48`, `completed/success`, Python `CAMP005_W05_PY PASS blocks=4 checks=232`, Godot `CAMP005_W05_GODOT PASS blocks=4 checks=876`, gates PASS.

**CI HITO 05 POR VERIFICAR:** [Actions #41721306449](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41721306449), SHA de progreso `b47e6ecc45d96b0b6d3bb901a5aed66a9370c85a`, `pending` inicialmente. La ejecución de fixture #41721275333 puede aparecer cancelada por concurrencia. Antes de acreditar 30 MT exigir run `completed/success`, recibos `CAMP005_W05_PY PASS blocks=5`, `CAMP005_W05_GODOT PASS blocks=5`, ambos gates. Además **hito obligatorio**: comprobar en ese run regresiones Python y Godot de CAMP004 60 MT y CAMP003 60 MT, recibos respectivos `CAMP004_W05_PY/GODOT PASS blocks=10` y `CAMP003_W05_PY/GODOT PASS blocks=10`. No confundir comprobación documental con CI.

**SIGUIENTE `p`:** verificar esta CI de hito y regresiones; con PASS, ejecutar exclusivamente **bloque 06** `tm172;tm173;tm174;tm175;tm176;tm177`. Ante fallo, diagnosticar y reparar arnés o función W05 según V5 con pruebas reales, sin reducir negativos ni modificar catálogo/learnsets. No tocar `main`, V28, PR118, árbitra, otras ramas, catálogo/learnsets/políticas, 19 MT históricas, partidas reales, workflows o APIs ajenas. Sin merge. Al 10/10 declarar `CAMPAÑA_005_FINALIZADA` y STOP. CI headless no valida UI/GPU.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_005 · 04/10 CI PASS VERIFICADA (2026-11-03)

**Identidad:** IA5/W05 responsable de MT/libros. **Rama exclusiva:** `codex/calvo-items-20261103-w05-camp005`. Autoridad IA6: `CAMPAIGN_005_W05_GATE.md`, `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W05.md`, `AUTONOMOUS_REPAIR_V5.md`. Este estado prevalece sobre cabeceras antiguas. CAMP004 (60 MT) y CAMP003 (60 MT) cerradas: mantener regresión, sin repetir trabajo.

**BLOQUE 04 CERTIFICADO:** `tm160;tm161;tm162;tm163;tm164;tm165` → `hurricane;trick_room;bug_buzz;hyper_beam;brave_bird;flare_blitz` en Scarlet/Violet. Fixture `tests/fixtures/parallel_items/w05_campaign_005.json` de cuatro bloques/24 MT, commit `f01eb2223d6b5e44a8f55b58c049bf7a9d08e05b`. CSV `reports/W05/CAMP_005_PROGRESO.csv` con única fila 04, commit `fc87f105b9f5b979d7f5dc6f0f73f5b026dbca48`. Informe `CAMP_005_ITER_04.md` certificado con commit `08510860f070aa82dc43b5354f6898e956be4664`. Control estático: 24 IDs distintos, cuatro bloques y filas idénticos a cola IA6/mapeo SV. Runners Python/Godot y producción sin cambios.

**CI FUNCIONAL PASS:** [Actions #41720191745](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41720191745), SHA `fc87f105b9f5b979d7f5dc6f0f73f5b026dbca48`, job `126210891293`, `completed/success`. Logs reales: `CAMP005_W05_PY PASS blocks=4 checks=232`, `CAMP005_GATE_PY_PASS worker=W05 blocks=4 checks=232`, `CAMP005_W05_GODOT PASS blocks=4 checks=876`, `CAMP005_GATE_GODOT_PASS worker=W05 blocks=4 checks=876`. Los contratos acumulativos ejercitan enseñanza real mediante `FieldItemService.teach`, compatibles/incompatibles, stock, propietario, PP, consumo y SaveV2. CI headless no prueba interfaz/GPU. Regresiones CAMP004/CAMP003 **no ejecutadas en bloque 04**, al no ser hito ni haberse modificado producción; están programadas en 05/10 y 10/10. CSV sigue con estado histórico `EN_CI_AUTOMATICA` para no relanzar CI solo por cambiar etiquetas.

**SIGUIENTE `p`:** ejecutar **únicamente bloque 05** `tm166;tm167;tm168;tm169;tm170;tm171` tras cotejo de cola IA6/perfil SV. Además de CI funcional CAMP005, verificar en los logs regresiones CAMP004 de 60 MT y CAMP003 de 60 MT (Python/Godot), dado que 05 es hito obligatorio; si fallan, diagnosticar y reparar bajo V5 sin relajar pruebas. Prohibido tocar `main`, V28, PR118, rama árbitra, otras W, catálogos/learnsets/políticas, 19 MT legacy inactivas, saves, workflows o merge. Al 10/10 declarar `CAMPAÑA_005_FINALIZADA` y STOP.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_005 · 04/10 ENTREGADO, CI PENDIENTE (2026-11-03)

**Identidad fija:** IA5/W05, MT y libros. **Rama exclusiva** `codex/calvo-items-20261103-w05-camp005`. Autoridad IA6: `CAMPAIGN_005_W05_GATE.md`, `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W05.md` y `AUTONOMOUS_REPAIR_V5.md`. Esta cabecera prevalece sobre el historial inferior. CAMP004 (60 MT) y CAMP003 (60 MT) están cerradas y se conservan como regresión.

**BLOQUE 04 PUBLICADO:** `tm160;tm161;tm162;tm163;tm164;tm165` → `hurricane;trick_room;bug_buzz;hyper_beam;brave_bird;flare_blitz` según SV. Fixture `tests/fixtures/parallel_items/w05_campaign_005.json`, 4 bloques/24 MT, commit `f01eb2223d6b5e44a8f55b58c049bf7a9d08e05b`. Progreso `reports/W05/CAMP_005_PROGRESO.csv`, una fila 04, commit `fc87f105b9f5b979d7f5dc6f0f73f5b026dbca48`. Informe `CAMP_005_ITER_04.md`, commit `7830f6a0065be2d05413d3a65490ce2f922a04b2`. Validación estática de los cuatro bloques frente a cola IA6 y catálogo SV: **24 IDs únicos y cero discrepancias**; no equivale a CI funcional.

**CI ANTERIOR BLOQUES 01–03 VERIFICADA:** [#41719102271](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41719102271), SHA `245b77936642d59990cde21471c86c2c5491dd7f`, `completed/success`; `CAMP005_W05_PY PASS blocks=3 checks=174`, `CAMP005_W05_GODOT PASS blocks=3 checks=661`, gates PASS.

**CI BLOQUE 04 PENDIENTE:** [#41720191745](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41720191745), SHA de progreso `fc87f105b9f5b979d7f5dc6f0f73f5b026dbca48`, inicialmente `pending`; run intermedio de fixture #41720124312 puede cancelarse por concurrencia. Exigir `completed/success`, Python `CAMP005_W05_PY PASS blocks=4`, Godot `CAMP005_W05_GODOT PASS blocks=4` y ambos gates antes de certificar 24 MT. Regresiones CAMP004/003 previstas en hitos 05 y 10 y parches propios, no en 04.

**SIGUIENTE `p`:** comprobar primero CI 04. Con PASS, ejecutar exactamente bloque 05 `tm166;tm167;tm168;tm169;tm170;tm171` y exigir regresiones completas CAMP004/003 por ser hito. Ante fallo, diagnosticar y reparar bajo V5 solo arnés W05 o defecto probado en enseñanza, sin rebajar pruebas. Conflictos de arquitectura compartida/reglas o ACL real denegada → IA6. No tocar `main`, V28, PR118, árbitra, otras W, catálogos y learnsets canónicos, políticas, 19 MT históricas inactivas, saves reales, workflows o merge. Al 10/10 `CAMPAÑA_005_FINALIZADA` y STOP; CI headless no valida GPU/UI.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_005 · 03/10 CI PASS VERIFICADA (2026-11-03)

**Rama propia:** `codex/calvo-items-20261103-w05-camp005`. Identidad IA5/W05, dominio MT/libros. Gate y cola IA6: `CAMPAIGN_005_W05_GATE.md`, `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W05.md`, protocolo `AUTONOMOUS_REPAIR_V5.md`. Esta cabecera prevalece sobre estados históricos inferiores; CAMP004 y CAMP003 se conservan cerradas como regresión.

**BLOQUE 03 CERTIFICADO:** `tm154;tm155;tm156;tm157;tm158;tm159` → `hydro_cannon;frenzy_plant;outrage;overheat;focus_blast;leaf_storm` en SV. Fixture `tests/fixtures/parallel_items/w05_campaign_005.json`, 3 bloques/18 MT, commit `6787fc68b75cc996ba868370655dc3a881e2fbbd`; progreso `reports/W05/CAMP_005_PROGRESO.csv` con tercera fila `EN_CI_AUTOMATICA`, commit `245b77936642d59990cde21471c86c2c5491dd7f`. Informe `CAMP_005_ITER_03.md` actualizado con recibos reales, commit `9941439e5851dd51e506f8ba294d4cb327162b13`. Validación estática de 18 IDs únicos, tres filas y movimientos iguales a cola IA6/perfil SV. Sin cambios de producción ni de arnés.

**CI FUNCIONAL PASS:** [#41719102271](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41719102271), SHA funcional `245b77936642d59990cde21471c86c2c5491dd7f`, job `126207313857`, `completed/success`: `CAMP005_W05_PY PASS blocks=3 checks=174`, `CAMP005_GATE_PY_PASS worker=W05 blocks=3 checks=174`, `CAMP005_W05_GODOT PASS blocks=3 checks=661`, `CAMP005_GATE_GODOT_PASS worker=W05 blocks=3 checks=661`. Tests de enseñanza real con compatible/incompatible, stock, propietario, consumo exacto, PP, repetición, identidad y SaveV2; no se certifica UI/GPU. Regresiones CAMP004 y CAMP003 se ejecutan por workflow en hitos 05 y 10 o al modificar producción, **no en este bloque 03**. Las etiquetas `EN_CI_AUTOMATICA` del CSV son históricas y no se editan solo para declarar PASS.

**SIGUIENTE `p`:** ejecutar exclusivamente bloque **04** `tm160;tm161;tm162;tm163;tm164;tm165`; antes cotejar con cola y perfil SV y estado de rama, agregar un solo bloque a fixture y una fila CSV, ejecutar CI. Ante fallo, investigar y autorreparar defecto W05 según V5 sin relajar pruebas; escalar solo conflicto compartido o permisos reales denegados. No tocar `main`, V28, PR118, árbitra, otras W, catálogos/learnsets canónicos, políticas, 19 MT históricas inactivas, guardados ni workflows. Sin merge; al 10/10 `CAMPAÑA_005_FINALIZADA` y STOP.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_005 · 03/10 PUBLICADOS · CI PENDIENTE (2026-11-03)

**Identidad fija:** IA5/W05, MT/libros. **Rama exclusiva activa:** `codex/calvo-items-20261103-w05-camp005`. Gate IA6 `CAMPAIGN_005_W05_GATE.md`, cola `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, encargo `campaigns/CAMP_005_W05.md` y `AUTONOMOUS_REPAIR_V5.md`. Este estado prevalece sobre el histórico posterior. CAMPAÑAS_004 y 003 preservadas como regresiones, sin repeticiones.

**BLOQUE 03 PUBLICADO:** `tm154;tm155;tm156;tm157;tm158;tm159` → `hydro_cannon;frenzy_plant;outrage;overheat;focus_blast;leaf_storm` según perfil Scarlet/Violet. Fixture acumulado 3 bloques/18 MT, commit `6787fc68b75cc996ba868370655dc3a881e2fbbd`. CSV `reports/W05/CAMP_005_PROGRESO.csv` con fila 03 `EN_CI_AUTOMATICA`, commit `245b77936642d59990cde21471c86c2c5491dd7f`. Informe `CAMP_005_ITER_03.md`, commit `7f400f8cacf5b4b68e18da402607b51c5de107f6`. Comparación estática: 18 IDs únicos, 3 bloques y filas, todos en cola IA6 y mapeo SV exactos; no equivale a prueba funcional. No se ha modificado código de producción ni runners.

**CI BLOQUES 01–02 VALIDADA:** [Actions #41718416082](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41718416082), `completed/success`, SHA `83d89ccc862e2035181e7a0136c6256d73e9d063`; Python `CAMP005_W05_PY PASS blocks=2 checks=116`, Godot `CAMP005_W05_GODOT PASS blocks=2 checks=446`, ambos gates PASS.

**CI BLOQUE 03 INICIALMENTE PENDIENTE:** [Actions #41719102271](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41719102271) sobre SHA de progreso `245b77936642d59990cde21471c86c2c5491dd7f`, en primera consulta `pending`. Run del fixture #41719079083 puede cancelarse por política de concurrencia; no confundir con fallo. Acreditar 18 MT solo con `completed/success`, recibos `CAMP005_W05_PY PASS blocks=3`, `CAMP005_W05_GODOT PASS blocks=3` y ambos gates. Workflow ejecuta CAMP004/CAMP003 como regresiones en hitos 05/10 o al cambiar producción, no en este bloque.

**SIGUIENTE `p`:** comprobar CI bloque 03; si success, ejecutar únicamente bloque **04** `tm160;tm161;tm162;tm163;tm164;tm165`. Si failure, leer logs, reparar defectos W05 con V5 y CI real sin relajar pruebas; elevar conflicto compartido, política global o ACL denegada real. No tocar `main`, V28, PR118, árbitra, otras ramas, catálogo/learnsets canónicos, políticas, 19 legacy, saves o workflows; sin merge. Al 10/10 declarar `CAMPAÑA_005_FINALIZADA` y STOP. CI headless no verifica UI/GPU.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_005 · 02/10 CI PASS VERIFICADA (2026-11-03)

**Rama exclusiva:** `codex/calvo-items-20261103-w05-camp005`, trabajadora IA5/W05, dominio MT/libros. Autoridad de IA6 `CAMPAIGN_005_W05_GATE.md`, `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W05.md` y `AUTONOMOUS_REPAIR_V5.md`. Esta cabecera sustituye las anteriores sobre CI pendiente; CAMPAÑAS_004/003 siguen cerradas y preservadas como regresión.

**BLOQUE 02 CERTIFICADO:** `tm148;tm149;tm150;tm151;tm152;tm153` → `sludge_bomb;earthquake;stone_edge;phantom_force;giga_impact;blast_burn` en mapeo `scarlet-violet`. Fixture `tests/fixtures/parallel_items/w05_campaign_005.json`, dos bloques/12 IDs, commit `ae06a0a83e5ae35011077ae465030fcda745cf74`. CSV `reports/W05/CAMP_005_PROGRESO.csv` segunda fila, commit `83d89ccc862e2035181e7a0136c6256d73e9d063`. Informe `CAMP_005_ITER_02.md` certificación commit `cec145b54b302b2ea30403d414c684a5d0cf0d13`. Cotejo estático: 12 IDs distintos, 2 filas y dos bloques, movimientos y orden idénticos a cola IA6/perfil SV. Runners y producción sin cambios.

**CI REAL PASS EN SHA DE PROGRESO:** [Actions #41718416082](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41718416082), SHA `83d89ccc862e2035181e7a0136c6256d73e9d063`, job `126205002195`, `completed/success`. Logs: `CAMP005_W05_PY PASS blocks=2 checks=116`, `CAMP005_GATE_PY_PASS worker=W05 blocks=2 checks=116`, `CAMP005_W05_GODOT PASS blocks=2 checks=446`, `CAMP005_GATE_GODOT_PASS worker=W05 blocks=2 checks=446`; el manifiesto W05 también PASS con dos bloques de diez y 60 IDs reservados. CI Godot headless prueba enseñanza real, stock/propietario, compatibles/incompatibles, consumo, PP y SaveV2, no UI/GPU. Regresiones CAMP004/003 se ejecutarán según workflow en hitos 05, 10 y parches propios, **no se ejecutaron en 02**, por tanto no afirmar que pasaron en este run. La etiqueta histórica `EN_CI_AUTOMATICA` en CSV no se reescribe solo para reflejar PASS y evitar un nuevo run.

**SIGUIENTE `p`:** ejecutar exclusivamente bloque 03 `tm154;tm155;tm156;tm157;tm158;tm159`, consultar cola IA6 y mapeo SV, ampliar fixture y CSV una vez y ejecutar CI. Si un nuevo run falla, reparar autónomamente según V5 sólo tests o producción W05 de enseñanza con defecto probado, nunca rebajar aserciones. Prohibido tocar `main`, V28, PR118, rama árbitra, otras W, datasets/learnsets canónicos, políticas, 19 MT legacy, guardados o workflows; sin merge. Al 10/10 `CAMPAÑA_005_FINALIZADA` y STOP.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_005 · 02/10 PUBLICADOS (2026-11-03)

**Identidad:** IA5/W05, MT/libros. **Rama exclusiva activa:** `codex/calvo-items-20261103-w05-camp005`. Gate IA6 `CAMPAIGN_005_W05_GATE.md`, cola `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, encargo `campaigns/CAMP_005_W05.md` y `AUTONOMOUS_REPAIR_V5.md` de la rama árbitra. Esta cabecera prevalece sobre los estados históricos inferiores. CAMP004 y CAMP003 se conservan íntegros como regresión.

**BLOQUE 02 PUBLICADO:** `tm148;tm149;tm150;tm151;tm152;tm153` → `sludge_bomb;earthquake;stone_edge;phantom_force;giga_impact;blast_burn` (`scarlet-violet`). Fixture acumulativo `tests/fixtures/parallel_items/w05_campaign_005.json` 2 bloques/12 MT commit `ae06a0a83e5ae35011077ae465030fcda745cf74`. CSV `reports/W05/CAMP_005_PROGRESO.csv` única fila 02 `EN_CI_AUTOMATICA`, commit `83d89ccc862e2035181e7a0136c6256d73e9d063`. Informe `CAMP_005_ITER_02.md` commit `dc3d6960828f35e4a952bf885a4b621d2c2c9d93`. Verificación estática de 12 IDs únicos, 2 bloques y orden/parejas idénticos a cola IA6 y mapeo SV canónico **PASS**, no sustituye pruebas funcionales. Los runners CAMP005 Python y Godot y producción quedaron intactos respecto al bloque 01.

**CI bloque 01 VALIDADA:** [#41715365400](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41715365400), SHA `c18760b7df5978a4bdcbb6395f2bcd85c113b7fb`, `completed/success`; Python `CAMP005_W05_PY PASS blocks=1 checks=58`, Godot `CAMP005_W05_GODOT PASS blocks=1 checks=231`, gates PASS.

**CI bloque 02 PENDIENTE EN EL MOMENTO DEL INFORME:** [#41718416082](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41718416082), SHA `83d89ccc862e2035181e7a0136c6256d73e9d063`, inicialmente `pending`. Run anterior fixture #41718391206 puede cancelarse por concurrencia. Para declarar PASS 02 exigir `completed/success` y recibos `CAMP005_W05_PY PASS blocks=2`, `CAMP005_W05_GODOT PASS blocks=2` y ambos gates. Regresiones CAMP004/003 solo programadas para hitos 05/10 o parche funcional propio; no se ejecutaron en 01, no atribuir PASS de regresión 02 salvo evidencia.

**PRÓXIMA `p`:** verificar CI 02; si verde, ejecutar exclusivamente bloque **03** `tm154;tm155;tm156;tm157;tm158;tm159`, con cotejo de perfil SV y la cola oficial. Si falla, diagnosticar y autorreparar bajo V5 sin reducir aserciones ni tocar familia ajena; si es problema global, conflicto compartido o acceso realmente denegado, escalar IA6. Prohibido `main`, V28, PR118, rama árbitra, otras W, catálogos canónicos, políticas, 19 MT legacy, saves reales, workflows y merge. Al 10/10 `CAMPAÑA_005_FINALIZADA` y STOP. CI Godot headless no valida GPU/UI.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_005 · 01/10 CI PASS VERIFICADA (2026-11-03)

**Rama activa exclusiva:** `codex/calvo-items-20261103-w05-camp005`, identidad W05/MT-libros. Autoridad IA6 `CAMPAIGN_005_W05_GATE.md`, `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W05.md` y autorreparación V5. Nueva campaña autorizada explícitamente; CAMP004 y CAMP003 permanecen cerradas como regresiones. Esta cabecera prevalece sobre estados antiguos.

**BLOQUE 01 FUNCIONALMENTE CERTIFICADO:** `tm142;tm143;tm144;tm145;tm146;tm147` → `hydro_pump;blizzard;fire_pledge;water_pledge;grass_pledge;wild_charge` en Scarlet/Violet. Runner Python `tests/tools/test_parallel_items_w05_campaign_005.py`, commit `1a7832904a18d2adb0c57130999a3ae5dcfcef35`; runner Godot `tests/gameplay/parallel_items_w05_campaign_005.gd`, commit `da5b10d32a8478db725d03bb438d8eb84d5d3524`; fixture 1 bloque/6 MT commit `095942fcaf1de2b3cb2a07efc14ec5a85be6cafa`; CSV `reports/W05/CAMP_005_PROGRESO.csv`, una fila `EN_CI_AUTOMATICA`, commit `c18760b7df5978a4bdcbb6395f2bcd85c113b7fb`. Informe `CAMP_005_ITER_01.md` certificado por commit `f2d63736727e106932d434a524f477eec73dcdc9`. Cotejo estático con cola IA6 y perfil SV sin discrepancias.

**RECIBOS CI REALES:** [GitHub Actions #41715365400](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41715365400) sobre SHA `c18760b7df5978a4bdcbb6395f2bcd85c113b7fb`, job `126193834698`, `completed/success`: `CAMP005_W05_PY PASS blocks=1 checks=58`, `CAMP005_GATE_PY_PASS worker=W05 blocks=1 checks=58`, `CAMP005_W05_GODOT PASS blocks=1 checks=231`, `CAMP005_GATE_GODOT_PASS worker=W05 blocks=1 checks=231`. Aprendizaje probado con el servicio real, negativos de propiedad/stock/compatibilidad, consumo, PP e identidad y SaveV2. No se modificó producción. Las regresiones CAMP004 y CAMP003 están programadas en el workflow de IA6 para hitos 05/10 o parches de producción y **no se ejecutaron en bloque 01**.

**SIGUIENTE `p`:** ejecutar exclusivamente bloque 02 `tm148;tm149;tm150;tm151;tm152;tm153`, cotejando mapeos SV y la cola oficial antes de publicar. No repetir bloque 01 ni volver a CAMP004. Cada `p` un bloque y su CI. Autonomía V5: reparar solo defecto demostrable en W05/enseñanza, sin tocar catálogo, learnsets o 19 máquinas históricas. Prohibido `main`, V28, PR118, árbitra, ramas W01–W04, otras W05, políticas, saves, workflows y merge. Al 10/10 `CAMPAÑA_005_FINALIZADA` y STOP. CI headless no certifica UI/GPU.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_005 · 01/10 PUBLICADO · CI EN CURSO (2026-11-03)

**Identidad fija** IA5/W05, MT/libros. **Rama exclusiva nueva:** `codex/calvo-items-20261103-w05-camp005`. Nueva autorización formal de IA6: `CAMPAIGN_005_W05_GATE.md`, `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W05.md`; `AUTONOMOUS_REPAIR_V5.md`. **Esta cabecera prevalece sobre las anteriores**: CAMP004 10/10 CI PASS es histórica y ahora es regresión, no un STOP contra la nueva campaña explícita.

**BLOQUE 01 ENTREGADO:** `tm142;tm143;tm144;tm145;tm146;tm147` con movimientos SV `hydro_pump;blizzard;fire_pledge;water_pledge;grass_pledge;wild_charge`. Los seis pares coinciden con el perfil canónico y la cola aprobada IA6. Bootstrap inicial carecía de runners funcionales (0 bloques, éxito solo estructural). Se publicaron `tests/tools/test_parallel_items_w05_campaign_005.py` (commit `1a7832904a18d2adb0c57130999a3ae5dcfcef35`) y `tests/gameplay/parallel_items_w05_campaign_005.gd` (commit `da5b10d32a8478db725d03bb438d8eb84d5d3524`) adaptando los contratos reales CAMP004 a CAMP005, sin tocar producción. Fixture `tests/fixtures/parallel_items/w05_campaign_005.json` 1 bloque/6 MT (commit `095942fcaf1de2b3cb2a07efc14ec5a85be6cafa`), CSV `reports/W05/CAMP_005_PROGRESO.csv` nueva fila 01 `EN_CI_AUTOMATICA` (commit `c18760b7df5978a4bdcbb6395f2bcd85c113b7fb`). Informe `CAMP_005_ITER_01.md` commit `3622610d74be646bf2007b2a70917be82fe3ba15`.

**CI bloque 01 AÚN NO CERTIFICADA:** [GitHub Actions #41715365400](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41715365400), SHA de progreso `c18760b7df5978a4bdcbb6395f2bcd85c113b7fb`, estado `in_progress` en primera comprobación. No afirmar PASS funcional hasta `completed/success` y recibos `CAMP005_W05_PY PASS blocks=1 checks=N`, `CAMP005_W05_GODOT PASS blocks=1 checks=N`, gates PASS, con N positivo. CI bootstrap #41711755340 `success` con 0/10 **NO** prueba enseñanza. Gate IA6 exige regresiones CAMP004 y CAMP003 al menos en hitos 05 y 10, y cambios propios de producción; workflow ya lo hace.

**SIGUIENTE `p`:** comprobar CI 01 y ejecutar exclusivamente bloque **02** `tm148;tm149;tm150;tm151;tm152;tm153`. Si CI falla, diagnosticar logs y reparar autónomamente arnés o perfil/función `teach` propia W05 con V5, conservando positivos, negativos, PP, propietario, consumo y SaveV2. Si problema compartido de API/arquitectura, permiso 403 real o regla ambigua, elevar IA6. Prohibido `main`, V28, PR118, rama árbitra, otras W, catálogo/learnsets, políticas, 19 MT legacy, workflows o merge. Tras 10/10 declarar `CAMPAÑA_005_FINALIZADA` y STOP.

---

# ESTADO DEFINITIVO — CAMPAÑA_004_FINALIZADA · IA5/W05 10/10 · CI PASS (2026-11-03)

**IA5/W05 (MT/libros)** ha terminado oficialmente CAMPAÑA_004: diez microbloques, **60 MT distintas (`tm82` a `tm141`)**, 60/60 validadas funcionalmente. Rama exclusiva `codex/calvo-items-20261103-w05-camp004`. Autoridad de asignación IA6 `CAMPAIGN_004_W05_GATE.md`, `CAMPAIGN_004_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_004_W05.md`, protocolo `AUTONOMOUS_REPAIR_V5.md`. **Esta cabecera prevalece sobre todas las anotaciones de CI pendiente/STOP antiguas de debajo.**

**CI FINAL VERIFICADA EN LOGS GITHUB:** [Actions #41591821717](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41591821717), SHA `5c9051ca2a0a186d31705372d2f0c350e2dd62db` (commit último progreso y fixture de 60 MT), `completed/success`, job `125770313243`. Recibos exactos:
- `CAMP004_W05_PY PASS blocks=10 checks=580`
- `CAMP004_GATE_PY_PASS worker=W05 blocks=10 checks=580`
- `CAMP004_W05_GODOT PASS blocks=10 checks=2166`
- `CAMP004_GATE_GODOT_PASS worker=W05 blocks=10 checks=2166`
- CAMP003, 60 MT anteriores regresionadas: `CAMP003_W05_PY PASS blocks=10 checks=580` y `CAMP003_W05_GODOT PASS blocks=10 checks=2166`.
- CAMP002: `Ran 11 tests`, `OK`.

**TRAZABILIDAD:** última ampliación de `tests/fixtures/parallel_items/w05_campaign_004.json`, commit `6f1ae6afe42051e9e58b8a5a6e99e83bb343e701`, con bloque `10` y `tm136;tm137;tm138;tm139;tm140;tm141` mapeadas en SV a `electric_terrain;grassy_terrain;psychic_terrain;misty_terrain;nasty_plot;fire_blast`. Última fila de `reports/W05/CAMP_004_PROGRESO.csv` commit `5c9051ca2a0a186d31705372d2f0c350e2dd62db`. Diez bloques de seis IDs, 60 sin duplicados, movimientos exactos respecto a cola aprobada IA6 y perfil canónico. Informes `CAMP_004_ITER_01.md` … `CAMP_004_ITER_10.md` y `CAMP_004_FINAL.md` (certificación commit `2d0b9c07e7aca59965f0e95beb6cc31a637ba212`) publicados. Las etiquetas `EN_CI_AUTOMATICA` del CSV son históricas y no se reescriben para evitar CI innecesaria; prevalece el PASS final comprobado en logs.

**SIN REPARACIONES DE PRODUCCIÓN:** no se encontró fallo funcional en la familia W05 que requiriese parche V5. Los únicos cambios en esta campaña afectan a fixture, progreso e informes/cuaderno propios. No se tocaron `main`, V28, PR118, rama árbitra, otras W, catálogos, políticas, 19 legacy, partidas, workflows o sistemas ajenos. No hay merge. La CI headless prueba lógica y SaveV2 pero **no valida interfaz visual o GPU**.

**SIGUIENTE ACCIÓN Y STOP:** no ejecutar más bloques en CAMP004 ni iniciar campaña nueva solo por una `p`. No hay bloque 11 autorizado. **IA6** debe revisar la entrega, diff y compatibilidad e integrar según sus gates; W05 queda detenido hasta un encargo nuevo explícito. **CAMPAÑA_004_FINALIZADA.**

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_004 · 10/10 ENTREGADOS · CI FINAL POR VERIFICAR (2026-11-03)

**Identidad:** IA5/W05, dominio MT/libros; rama exclusiva `codex/calvo-items-20261103-w05-camp004`. El gate `CAMPAIGN_004_W05_GATE.md`, cola `CAMPAIGN_004_W05_QUEUE_APPROVED.csv`, encargo `campaigns/CAMP_004_W05.md` y protocolo `AUTONOMOUS_REPAIR_V5.md` de IA6 son autoridad. Esta cabecera prevalece sobre las anteriores. CAMP003 cerró 10/10, 60 MT; solo se prueba como regresión.

**BLOQUE 10 ENTREGADO:** `tm136;tm137;tm138;tm139;tm140;tm141` → `electric_terrain;grassy_terrain;psychic_terrain;misty_terrain;nasty_plot;fire_blast` canónicos SV. Fixture `tests/fixtures/parallel_items/w05_campaign_004.json` con **10/10 y 60 IDs distintos**, commit `6f1ae6afe42051e9e58b8a5a6e99e83bb343e701`. CSV `reports/W05/CAMP_004_PROGRESO.csv` con la décima fila `EN_CI_AUTOMATICA`, commit `5c9051ca2a0a186d31705372d2f0c350e2dd62db`. Informe `CAMP_004_ITER_10.md`, commit `570e88935b4f79fcbbe67fa7dfda38159774ae34`. **Control estático:** diez bloques/seis IDs cada uno, diez filas exactas y 60 mapeos idénticos a cola aprobada IA6 y perfil SV; ningún repetido ni discrepancia. Runners y producción sin cambios.

**CI ANTERIOR VERIFICADA:** [#41589081119](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41589081119), `completed/success` sobre SHA `cc092d4935036be18503965af3519852ecc9b39f`; CAMP004 Python `PASS blocks=9 checks=522`, Godot `PASS blocks=9 checks=1951`, gates PASS, regresiones CAMP003 Python 580 / Godot 2166 checks y CAMP002 11 tests PASS.

**CI FINAL 10/10 inicialmente PENDIENTE:** [#41591821717](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41591821717), SHA de progreso `5c9051ca2a0a186d31705372d2f0c350e2dd62db`, primera consulta `pending`. La CI intermedia de fixture #41591801564 puede aparecer cancelada por concurrencia. Antes de afirmar fin FUNCIONAL comprobar último run `completed/success`, recibos `CAMP004_W05_PY PASS blocks=10` y `CAMP004_W05_GODOT PASS blocks=10`, gates y regresiones completas CAMP003/CAMP002. Si falla, reparar bajo V5 sin disminuir aserciones, con CI del SHA con cambios.

**SIGUIENTE ACCIÓN:** terminar validación del run 10, publicar `CAMP_004_FINAL.md`, anotar la evidencia final aquí y comunicar `CAMPAÑA_004_FINALIZADA`. **STOP**: no existe bloque 11 ni otra campaña autorizada; no seguir solo con `p`. IA6 audita e integra por lote. No tocar `main`, V28, PR118, árbitra, otras W, catálogos/políticas, 19 legacy, saves, workflows, producción ajena ni hacer merge. La CI headless no valida visual/GPU.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_004 · 09/10 ENTREGADOS (2026-11-03)

**Identidad:** IA5/W05 (MT/libros), rama exclusiva `codex/calvo-items-20261103-w05-camp004`. Gate IA6 `CAMPAIGN_004_W05_GATE.md`, cola `CAMPAIGN_004_W05_QUEUE_APPROVED.csv`, encargo `campaigns/CAMP_004_W05.md` y protocolo de reparación V5. Esta cabecera prevalece sobre notas antiguas. CAMP003 queda cerrada 10/10 y sus 60 MT solo se regresionan.

**BLOQUE 09 ENTREGADO:** `tm130;tm131;tm132;tm133;tm134;tm135` → `helping_hand;pollen_puff;baton_pass;earth_power;reversal;ice_beam` en SV. Fixture `tests/fixtures/parallel_items/w05_campaign_004.json` acumulado 9 bloques/54 MT, commit `c89ed525a7355a36484bc8aaa6d3e9a084fef4f1`; CSV `reports/W05/CAMP_004_PROGRESO.csv` con nueva fila 09 `EN_CI_AUTOMATICA`, commit `cc092d4935036be18503965af3519852ecc9b39f`; informe `CAMP_004_ITER_09.md` commit `5379a621473ee2507ffaac841ca49a0ef0d6d268`. Verificación estática en GitHub: **54 IDs únicos, nueve bloques y filas CSV, seis por bloque, correspondencia exacta cola IA6 y mapeo SV; cero diferencias.** Scripts y producción sin modificar; esta prueba no acredita enseñanza de las seis MT nuevas.

**CI BLOQUES 01–08 VERIFICADA:** [#41584156568](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41584156568), SHA `2d62f9efda8f47c1c434fe5a9b5b8dbd166b9f43`, `completed/success`. Logs `CAMP004_W05_PY PASS blocks=8 checks=464` y `CAMP004_W05_GODOT PASS blocks=8 checks=1736`, gates PASS. Regresión CAMP003 de 60 MT Python 580/Godot 2166 comprobaciones PASS y CAMP002 11 tests OK. Estados de CSV `EN_CI_AUTOMATICA` históricos: no actualizar únicamente etiquetas para evitar CI redundante; prevalece resultado del run real.

**CI BLOQUE 09 PENDIENTE AL PUBLICAR:** [#41589081119](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41589081119), SHA exacto `cc092d4935036be18503965af3519852ecc9b39f`, inicialmente `pending`; run intermedio de fixture #41589064444 puede cancelarse por concurrencia. Para certificar 54 MT verificar `completed/success` y recibos `CAMP004_W05_PY PASS blocks=9`, `CAMP004_W05_GODOT PASS blocks=9`, gates y regresiones.

**SIGUIENTE `p`:** comprobar primero CI 09. Si es success, ejecutar únicamente el **bloque 10/10** `tm136;tm137;tm138;tm139;tm140;tm141`, con mapa canónico SV y seis casos nuevos. Si en curso, como máximo un bloque independiente autorizado sin inventar PASS; si failure, diagnosticar/autorrepasar pruebas o componente W05 según V5 con regresión. Conflicto funcional compartido, cambios de API global o permisos realmente denegados → IA6. Al 10/10 comunicar `CAMPAÑA_004_FINALIZADA` y STOP; sin bloque 11. Prohibido tocar `main`, V28, árbitra, PR118, otras ramas, catálogos, políticas, 19 máquinas legacy, partidas reales, workflows o producción ajena. Sin merge; Godot headless no valida UI/GPU.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_004 · 08/10 ENTREGADOS (2026-11-03)

**Identidad:** IA5/W05, especialista en MT y libros. **Rama exclusiva:** `codex/calvo-items-20261103-w05-camp004`. Puerta IA6 `CAMPAIGN_004_W05_GATE.md`, cola `CAMPAIGN_004_W05_QUEUE_APPROVED.csv`, encargo `campaigns/CAMP_004_W05.md` y autorreparación V5. Este encabezado es el estado vigente; las notas de abajo preservan el historial. CAMP003 está finalizada 10/10 y sus 60 MT sólo se comprueban como regresión.

**BLOQUE 08 ENTREGADO:** `tm124;tm125;tm126;tm127;tm128;tm129` → `ice_spinner;flamethrower;thunderbolt;play_rough;amnesia;calm_mind` para Scarlet/Violet. Fixture `tests/fixtures/parallel_items/w05_campaign_004.json` suma **8 bloques/48 MT**, commit `dae8a132e33574e87d04676154648a7229fc73ac`. CSV `reports/W05/CAMP_004_PROGRESO.csv` con una nueva fila 08, commit `2d62f9efda8f47c1c434fe5a9b5b8dbd166b9f43`. Informe `CAMP_004_ITER_08.md` commit `3206d1bebf1a8b13d616fb82bb878885df55224f`. Comparación directa de 8 filas, 48 IDs únicos, asignación, orden y mapeo SV frente a IA6/catálogo: **sin discrepancias**. Runners de Python/Godot y producción sin cambios; no usar cotejo estático como PASS funcional.

**CI bloques 01–07 VERIFICADA:** [#41579505939](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41579505939), SHA `c6d5c738d2a3a68ced8d3388da370f5abcfc37e4`, `completed/success`. Logs `CAMP004_W05_PY PASS blocks=7 checks=406`, `CAMP004_W05_GODOT PASS blocks=7 checks=1521`, gates PASS. Regresión CAMP003 60 MT Python 580/Godot 2166 comprobaciones PASS y CAMP002 11 tests OK. Las filas viejas `EN_CI_AUTOMATICA` del CSV son históricas y no se reescriben para evitar ejecuciones redundantes; prevalece evidencia del run real.

**CI bloque 08 inicialmente PENDIENTE:** [#41584156568](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41584156568), SHA de progreso `2d62f9efda8f47c1c434fe5a9b5b8dbd166b9f43`, primera consulta `pending`. El run anterior de fixture #41584143411 puede ser cancelado por concurrencia. Exigir run `completed/success` y logs `CAMP004_W05_PY PASS blocks=8`, `CAMP004_W05_GODOT PASS blocks=8`, ambos gates y regresiones para certificar las 48 MT.

**SIGUIENTE `p`:** comprobar CI 08. Si `success`, ejecutar **solamente bloque 09** `tm130;tm131;tm132;tm133;tm134;tm135`, un fixture/CSV/informe/cuaderno W05 CAMP004. Si la CI aún corre, permitir sólo un bloque independiente sin declarar PASS; si falla, diagnosticar logs y corregir pruebas propias o defecto probado de perfil/función `teach` bajo V5, con regresión y nuevo SHA CI. Conflicto de función/API con otra trabajadora, diseño general o acceso efectivamente denegado → IA6. No modificar `main`, V28, PR118, árbitra, ramas ajenas, catálogo, políticas, 19 máquinas históricas, guardados, workflows ni otras familias; sin merge. Límite 10/10, `CAMPAÑA_004_FINALIZADA`, STOP. CI headless no valida GPU/visuales.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_004 · 07/10 ENTREGADOS (2026-11-03)

**Identidad:** IA5/W05, MT/libros. **Rama exclusiva:** `codex/calvo-items-20261103-w05-camp004`. Puerta y cola IA6 `CAMPAIGN_004_W05_GATE.md`, `CAMPAIGN_004_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_004_W05.md`, autonomía V5. Esta cabecera prevalece sobre estados antiguos. CAMP003 10/10, 60 MT, sólo se comprueban como regresión, sin repetir trabajo.

**BLOQUE 07 entregado:** `tm118;tm119;tm120;tm121;tm122;tm123` con movimientos SV `heat_wave;energy_ball;psychic;heavy_slam;encore;surf`. Fixture CAMP004 acumulativo 7 bloques/42 MT, commit `42020d197ea704486fb2415c43989793ca0c1deb`; CSV progreso fila 07 `EN_CI_AUTOMATICA`, commit `c6d5c738d2a3a68ced8d3388da370f5abcfc37e4`. Informe `CAMP_004_ITER_07.md`, commit `b74f30b5d4a8eb71623d2b7e07d2a83b560b8d00`. Comprobación documental: 42 IDs únicos, siete filas y mapeos SV completos exactamente iguales a cola y perfil. Scripts Python/Godot y producción sin cambios; cotejo estático no acredita las seis nuevas enseñanzas.

**CI BLOQUES 01–06 VERIFICADA:** [#41579048410](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41579048410), SHA `e3ef241634ad013d20907272ca319cfdd51fba6c`, `completed/success`, Python `CAMP004_W05_PY PASS blocks=6 checks=348` y Godot 4.7 `CAMP004_W05_GODOT PASS blocks=6 checks=1306`, ambos gates PASS. Regresiones CAMP003 60 MT Python 580 y Godot 2166 checks PASS, CAMP002 11 tests OK.

**CI BLOQUE 07 PENDIENTE EN EL MOMENTO DE PUBLICACIÓN:** [#41579505939](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41579505939), SHA `c6d5c738d2a3a68ced8d3388da370f5abcfc37e4`, inicialmente `pending`. Run intermedio de fixture #41579488183 puede cancelarse por concurrencia. Para certificar 42 MT exigir `completed/success`, Python `CAMP004_W05_PY PASS blocks=7`, Godot `CAMP004_W05_GODOT PASS blocks=7`, gates y regresiones. No reescribir filas históricas CSV solo para acreditar CI porque eso relanza el workflow; dejar evidencia aquí.

**SIGUIENTE `p`:** comprobar primero el run 07. Si `success`, ejecutar exclusivamente **bloque 08** `tm124;tm125;tm126;tm127;tm128;tm129`, seis MT autorizadas. Si pending, solo bloque independiente sin atribuir PASS; si failure, diagnosticar/reparar pruebas y componentes W05 según V5 con CI, sin reducir aserciones. Conflictos compartidos, diseño o ACL real denegada → IA6. Límite 10/10, entonces `CAMPAÑA_004_FINALIZADA` y STOP. Protegidos: `main`, V28, PR118, árbitra, otras W, catálogo, políticas, 19 legacy, saves reales, workflows e integración; no certificar GUI/GPU con headless.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_004 · 06/10 ENTREGADOS (2026-11-03)

**Identidad fija:** IA5/W05, MT y libros. **Rama exclusiva:** `codex/calvo-items-20261103-w05-camp004`. Autoridad IA6 `CAMPAIGN_004_W05_GATE.md`, `CAMPAIGN_004_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_004_W05.md` y protocolo `AUTONOMOUS_REPAIR_V5.md`. Esta cabecera sustituye el estado histórico inferior. CAMP003 está finalizada (10/10, 60 MT) y solo se usa como regresión; no duplicar su trabajo.

**BLOQUE 06 ENTREGADO:** `tm112;tm113;tm114;tm115;tm116;tm117` → `aura_sphere;tailwind;shadow_ball;dragon_pulse;stealth_rock;hyper_voice` en Scarlet/Violet. Fixture `tests/fixtures/parallel_items/w05_campaign_004.json` ampliado a **6 bloques / 36 MT**, commit `d1b7ce62395cedf340db44dc4aff1fbcef0c630a`. CSV `reports/W05/CAMP_004_PROGRESO.csv` con única fila nueva 06 `EN_CI_AUTOMATICA`, commit `e3ef241634ad013d20907272ca319cfdd51fba6c`; informe `CAMP_004_ITER_06.md`, commit `d89531d84568bdcc3ea9331e6148c933d80982f4`. Runners de Python/Godot y código de producción sin cambios. Cotejo estático frente a cola IA6, CSV y perfil SV: **36 IDs distintos y seis pares exactos por bloque, ninguna discrepancia**. Este cotejo no certifica ejecución de las seis MT nuevas.

**CI BLOQUES 01–05 VERIFICADA:** [#41576524159](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41576524159), SHA `0ab410a15fa47b301b76f68c402a2e8e8d3d9fd7`, `completed/success`; logs `CAMP004_W05_PY PASS blocks=5 checks=290`, `CAMP004_W05_GODOT PASS blocks=5 checks=1091`, ambos gates PASS. Regresión CAMP003 60 MT Python 580 comprobaciones y Godot 2166 PASS, CAMP002 11 tests OK. Las filas históricas `EN_CI_AUTOMATICA` del CSV no se reescriben solo para reflejar CI, evitando relanzar runs; prevalece este resultado real.

**CI BLOQUE 06 PENDIENTE:** [#41579048410](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41579048410), SHA de progreso `e3ef241634ad013d20907272ca319cfdd51fba6c`, inicialmente `pending`. Run previo de fixture #41579033578 puede cancelarse por `concurrency.cancel-in-progress`. Para certificar las 36 MT, comprobar `completed/success`, `CAMP004_W05_PY PASS blocks=6`, `CAMP004_W05_GODOT PASS blocks=6`, ambos gates y regresiones CAMP003/CAMP002 del SHA exacto.

**SIGUIENTE `p`:** verificar la CI 06. Con `success`, ejecutar exclusivamente bloque **07** `tm118;tm119;tm120;tm121;tm122;tm123`. Si aún en curso, un bloque independiente de pruebas como máximo, sin PASS. Si falla, diagnosticar y corregir autonomía V5 en el dominio W05 (arnés o perfil/función `teach`) con regresión y CI real, sin reducir tests; conflictos compartidos, arquitectura, reglas globales o ACL real denegada → IA6. Prohibido `main`, V28, PR118, rama árbitra, otras trabajadoras, catálogo, política, 19 máquinas legacy, guardados reales, workflow o merge. Máximo 10 bloques, `CAMPAÑA_004_FINALIZADA` y STOP. CI headless no equivale a prueba visual/GPU.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_004 · 05/10 ENTREGADOS (2026-11-03)

**Identidad fija:** IA5/W05, familia de MT/libros. **Rama exclusiva:** `codex/calvo-items-20261103-w05-camp004`. Autoridad IA6 `CAMPAIGN_004_W05_GATE.md`, `CAMPAIGN_004_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_004_W05.md` y autorreparación V5; prevalece este estado sobre notas antiguas. CAMPAÑA_003 permanece 10/10 terminada, sus 60 MT solo se vuelven a probar como regresión, no se repiten encargos.

**BLOQUE 05 ENTREGADO:** `tm106;tm107;tm108;tm109;tm110;tm111` → `drill_run;will_o_wisp;crunch;trick;liquidation;giga_drain` en perfil SV. Fixture CAMP004 `tests/fixtures/parallel_items/w05_campaign_004.json` ampliado a **5 bloques / 30 MT**, commit `ed2b61dddbb2f923aaa90cdf7299ba32d63a2012`; progreso `reports/W05/CAMP_004_PROGRESO.csv` con una sola nueva fila `05`, commit `0ab410a15fa47b301b76f68c402a2e8e8d3d9fd7`. Informe `CAMP_004_ITER_05.md` commit `aec86dded917df164b16529d9186e44ed74c47ea`. Scripts Python/Godot CAMP004 y producción sin cambios. Cotejo estático real: **30 IDs distintos**, cinco bloques y filas CSV, todos exactamente alineados con cola IA6 y mapeos SV; cero discrepancias. Esto no equivale a haber ejecutado los seis casos nuevos.

**CI bloques 01–04 VERIFICADA:** [#41575917016](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41575917016), SHA `64d7f53bba17dbba7403721bb8c89831d47b1844`, `completed/success`. Logs `CAMP004_W05_PY PASS blocks=4 checks=232`, `CAMP004_W05_GODOT PASS blocks=4 checks=876`, ambos gates PASS. Regresiones CAMP003 60 MT: Python 580 y Godot 2166 comprobaciones PASS; CAMP002 11 tests OK. Los registros `EN_CI_AUTOMATICA` de filas antiguas en CSV son históricos y no se reescriben, para no relanzar CI innecesariamente; prevalece el log real del run.

**CI bloque 05 PENDIENTE:** [#41576524159](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41576524159), SHA de progreso `0ab410a15fa47b301b76f68c402a2e8e8d3d9fd7`, originalmente `pending`. El run anterior de fixture #41576483399 puede quedar cancelado por concurrencia. Antes de certificar **30 MT**, exigir `completed/success`, logs `CAMP004_W05_PY PASS blocks=5` y `CAMP004_W05_GODOT PASS blocks=5`, gates y regresiones CAMP003/CAMP002 sobre ese SHA.

**PRÓXIMA `p`:** verificar CI del SHA de progreso 05. Si `success`, ejecutar exclusivamente **bloque 06** `tm112;tm113;tm114;tm115;tm116;tm117`, ampliar fixture y una fila CSV, informe y continuidad de CAMP004. Si sigue en curso, únicamente bloque independiente sin certificar PASS; si falla, investigar logs y corregir autónomamente pruebas o el defecto W05 del perfil/función `teach` con V5, sin reducir aserciones; conflicto de arquitectura/API compartida, norma general o ACL realmente denegada → IA6. `main`, V28, PR118, árbitra, otras W, catálogo, 19 legacy, política, saves y CI compartidos intocados; sin merge. Tras 10/10 declarar `CAMPAÑA_004_FINALIZADA` y STOP. No confundir pruebas Godot headless con validación UI/GPU.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_004 · 04/10 ENTREGADOS (2026-11-03)

**Identidad:** IA5/W05, familia de MT/libros. **Rama exclusiva activa:** `codex/calvo-items-20261103-w05-camp004`. Autorización IA6: `CAMPAIGN_004_W05_GATE.md`, cola `CAMPAIGN_004_W05_QUEUE_APPROVED.csv`, encargo `campaigns/CAMP_004_W05.md`, autorreparación V5. Esta cabecera prevalece sobre los estados históricos inferiores; CAMP003 conserva 10/10 (60 MT) y se ejecuta solo como regresión, nunca se repite su trabajo.

**BLOQUE 04 ENTREGADO:** `tm100;tm101;tm102;tm103;tm104;tm105` asignados en Scarlet/Violet a `dragon_dance;power_gem;gunk_shot;substitute;iron_defense;x_scissor`. Fixture `tests/fixtures/parallel_items/w05_campaign_004.json` de **4 bloques/24 MT**, commit `936bb0d60578b3edd7ca7fec091fc026651cb16c`; nueva fila 04 `EN_CI_AUTOMATICA` en progreso `reports/W05/CAMP_004_PROGRESO.csv`, commit `64d7f53bba17dbba7403721bb8c89831d47b1844`; informe `CAMP_004_ITER_04.md` commit `3e777b153ac0beffc6d95eb94f7a5a51124b87c0`. No se modificaron los runners Python/Godot ni el motor: el protocolo V5 exige defecto demostrado para reparar. Cotejo estático de los 24 IDs únicos, cuatro filas y movimientos SV frente a cola IA6 y catálogo: **PASS sin discrepancias**; no implica función comprobada de las seis nuevas MT.

**CI BLOQUES 01–03 VERIFICADA:** [Actions #41573686036](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41573686036), SHA `e902ea2e8df76d3273fcdd6020186fcedc2f8ef4`, `completed/success`. Logs `CAMP004_W05_PY PASS blocks=3 checks=174`, `CAMP004_W05_GODOT PASS blocks=3 checks=661`; ambos gates PASS. Regresión CAMP003 60 MT Python 580 checks, Godot 2166 checks PASS; CAMP002 11 tests OK. CSV de bloques previos mantiene estado `EN_CI_AUTOMATICA` histórico para no relanzar CI; prevalece el run real.

**CI BLOQUE 04 AÚN PENDIENTE:** [Actions #41575917016](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41575917016), SHA de progreso `64d7f53bba17dbba7403721bb8c89831d47b1844`, inicialmente `pending`. El run intermedio de fixture #41575899234 puede ser `cancelled` por concurrencia. Para certificar las 24 MT exigir `completed/success`, `CAMP004_W05_PY PASS blocks=4` y `CAMP004_W05_GODOT PASS blocks=4`, gates y regresiones.

**SIGUIENTE `p`:** comprobar CI del SHA de progreso 04. Si verde, ejecutar exclusivamente **bloque 05** `tm106;tm107;tm108;tm109;tm110;tm111` (seis pares SV, un registro CSV, informe y cuaderno propios). Si CI continúa, solo bloque independiente sin PASS; si falla, reparar autónomamente fallos propios en test/arnés o perfil/función `teach` bajo V5 sin cambiar reglas ni reducir aserciones. Conflicto compartido, diseño global o permisos denegados reales: elevar IA6. `main`, V28, PR118, árbitra, ramas otras W, catálogos, 19 máquinas legacy, política, partidas y workflows intocados; sin merge. Al 10/10 `CAMPAÑA_004_FINALIZADA` y STOP.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_004 · 03/10 ENTREGADOS (2026-11-03)

**Identidad fija:** IA5/W05 (familia MT/libros). **Única rama CAMP004 autorizada:** `codex/calvo-items-20261103-w05-camp004`. Puerta/cola IA6 de CAMPAÑA_004: `CAMPAIGN_004_W05_GATE.md`, `CAMPAIGN_004_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_004_W05.md`; reparación autónoma V5. Esta cabecera sustituye las instrucciones históricas inferiores. CAMP003 10/10 (60 MT) sigue cerrada y es regresión inmutable de esta campaña.

**BLOQUE 03 ENTREGADO:** `tm94;tm95;tm96;tm97;tm98;tm99`, perfil Scarlet/Violet `dark_pulse;leech_life;eerie_impulse;fly;skill_swap;iron_head`. Fixture acumulativo nuevo `tests/fixtures/parallel_items/w05_campaign_004.json`: 3 bloques/18 MT, commit `2b3b1237edd4695599e9a0f4cbb4caf694fed27f`; progreso `reports/W05/CAMP_004_PROGRESO.csv` añadió una sola fila 03, commit `e902ea2e8df76d3273fcdd6020186fcedc2f8ef4`. Informe `CAMP_004_ITER_03.md`, commit `8d9c6c6fd7a141317c0d8e25f32a85f6fe3f3552`. Runners Python/Godot CAMP004 no reescritos, sin parches en producción. Comprobación estática realizada: **18 IDs únicos, tres filas, todos los mapeos SV y orden coinciden exactamente con la cola IA6 y catálogo**. No equivale a PASS funcional del bloque nuevo.

**CI BLOQUES 01–02 VERIFICADA:** GitHub Actions [#41572800181](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41572800181), SHA `fb5cb0433e17d805feb04755eed63b764005e797`, `completed/success`. Logs Python `CAMP004_W05_PY PASS blocks=2 checks=116`; Godot 4.7 `CAMP004_W05_GODOT PASS blocks=2 checks=446`; ambos gates PASS. Regresión CAMP003 60 MT, Python 580 checks y Godot 2166 checks, PASS; CAMP002 11 tests OK. La fila histórica 02 del CSV dice `EN_CI_AUTOMATICA` al momento de escribirla, pero la CI real quedó confirmada, no reescribir CSV solo por ello.

**CI BLOQUE 03 PENDIENTE HASTA RUN FINAL:** [#41573686036](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41573686036), SHA de progreso `e902ea2e8df76d3273fcdd6020186fcedc2f8ef4`; primer estado `pending`. Run anterior de fixture #41573673543 puede cancelarse por `concurrency.cancel-in-progress`. Exigir `completed/success`, recibos `CAMP004_W05_PY PASS blocks=3` y `CAMP004_W05_GODOT PASS blocks=3`, gates, regresiones CAMP003 y CAMP002, antes de certificar las 18 MT.

**SIGUIENTE `p`:** comprobar la CI del SHA de progreso 03. Si success, ejecutar exclusivamente bloque **04** `tm100;tm101;tm102;tm103;tm104;tm105`, ampliar solo fixture+CSV+informe+continuidad de CAMP004. Si CI en curso, solo un bloque independiente sin PASS; si falla, diagnosticar y reparar autónomamente fallo propio bajo V5 sin relajar aserciones. Escalar a IA6 solo conflicto concurrente, cambio general de arquitectura, norma ambigua o permisos reales denegados. Límite 10/10, STOP, `CAMPAÑA_004_FINALIZADA`; nunca inventar nuevos IDs. `main`, V28, PR118, árbitra, otras W, catálogo/políticas, 19 legacy, saves, workflows y producción ajena protegidos; UI/GPU fuera de CI.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_004 · 02/10 PUBLICADOS (2026-11-03)

**Identidad:** IA5/W05, familia MT/libros. **Rama exclusiva actual:** `codex/calvo-items-20261103-w05-camp004`. Gate IA6 `CAMPAIGN_004_W05_GATE.md`, `CAMPAIGN_004_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_004_W05.md`; protocolo de autorreparación V5. Esta cabecera prevalece sobre las anteriores. La CAMP003 está cerrada 10/10 y sus 60 MT de regresión no se repiten ni se alteran.

**BLOQUE 02 entregado:** IDs `tm88;tm89;tm90;tm91;tm92;tm93` con movimientos SV `swords_dance;body_press;spikes;toxic_spikes;imprison;flash_cannon`. Fixture `tests/fixtures/parallel_items/w05_campaign_004.json` ampliado a **2 bloques/12 MT** commit `982c453964bec3c8baad6b12684d2cc78f6a8702`; CSV `reports/W05/CAMP_004_PROGRESO.csv` fila 02 `EN_CI_AUTOMATICA`, commit `fb5cb0433e17d805feb04755eed63b764005e797`; informe `CAMP_004_ITER_02.md` commit `424f2920bd61e9d3e2395398a808565a878b4fc7`.

**Cotejo estático efectuado:** 12 IDs únicos, dos filas de progreso, mismos IDs/orden y movimientos que cola IA6 y perfil Scarlet/Violet sin discrepancias. Los runners propios Python/Godot CAMP004 siguen acumulativos, sin cambios de código; ninguna modificación en producción. Este cotejo no acredita enseñanza de las seis nuevas MT.

**CI bloque 01 VERIFICADA:** [#41571216304](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41571216304) `completed/success` sobre SHA `7d1b5b65da4135dc197a198ab08aa78e1646c84f`; Python `CAMP004_W05_PY PASS blocks=1 checks=58`, Godot `CAMP004_W05_GODOT PASS blocks=1 checks=231`, ambos gates PASS, y regresiones CAMP003 (Python 580 / Godot 2166 comprobaciones para 60 MT) y CAMP002 (11 tests OK).

**CI bloque 02 inicialmente PENDIENTE:** [#41572800181](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41572800181), SHA de progreso `fb5cb0433e17d805feb04755eed63b764005e797`, inicialmente `pending`; run previo de fixture #41572746262 puede cancelarse por concurrencia. Para certificar: `completed/success` y logs `CAMP004_W05_PY PASS blocks=2`, `CAMP004_W05_GODOT PASS blocks=2` con gates y regresiones anteriores. No atribuir `CI_PASS_VERIFICADO` sin estos recibos.

**SIGUIENTE `p`:** primero comprobar CI exacta del bloque 02. Si verde, ejecutar solamente bloque **03** `tm94;tm95;tm96;tm97;tm98;tm99`. Si en curso, solo siguiente bloque independiente sin PASS. Si failure, reparar autónomamente el arnés o defecto propio del perfil/función `teach` con mínimo diff y CI real; conflictos, diseño global o ACL real denegada elevan IA6. Prohibido tocar `main`, V28, PR118, árbitra, otras W, catálogo, políticas, partidas, 19 legacy o workflows. Límite 10/10, entonces `CAMPAÑA_004_FINALIZADA` y STOP. Revisión visual/GPU no certificada.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_004 · 01/10 CI PASS VERIFICADA (2026-11-03)

**Identidad:** IA5/W05, dominio MT/libros. **Única rama activa:** `codex/calvo-items-20261103-w05-camp004`. La puerta `CAMPAIGN_004_W05_GATE.md` y la cola `CAMPAIGN_004_W05_QUEUE_APPROVED.csv` de IA6 habilitan diez bloques nuevos `tm82`–`tm141`, seis por `p`, sin repetir CAMP003; V5 permite reparación de fallos propios demostrados, nunca modificación de otras trabajadoras ni `main`/V28.

**BLOQUE 01/10 CON CI REAL PASS:** `tm82;tm83;tm84;tm85;tm86;tm87` con `thunder_wave;poison_jab;stomping_tantrum;rest;rock_slide;taunt` mapeadas canónicamente SV. Fixture `tests/fixtures/parallel_items/w05_campaign_004.json` commit `b467ae2f219627c5e227ed830ea976435bd432a5` y progreso `reports/W05/CAMP_004_PROGRESO.csv` commit `7d1b5b65da4135dc197a198ab08aa78e1646c84f`. Informe `CAMP_004_ITER_01.md`, commit inicial `ee9503519f3fcc72934c65c2e9bf4b74390e0559`. **[Actions #41571216304](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41571216304)** `completed/success`, SHA `7d1b5b65da4135dc197a198ab08aa78e1646c84f`, job `125704313130`; logs Python `CAMP004_W05_PY PASS blocks=1 checks=58`, Godot 4.7 `CAMP004_W05_GODOT PASS blocks=1 checks=231` y ambos gates OK. **Regresiones también verdes en el mismo run:** CAMP003 60 MT Python 580 checks / Godot 2166 checks; CAMP002 11 tests `OK`. No se modificó producción ni se necesitaron reparaciones V5. La fila del CSV mantiene estado histórico `EN_CI_AUTOMATICA` para no relanzar CI por un cambio administrativo; prevalece la comprobación directa de GitHub Actions.

**SIGUIENTE `p`: ejecutar EXCLUSIVAMENTE el bloque 02 CAMP004**, `tm88;tm89;tm90;tm91;tm92;tm93`, según la cola de IA6. Revisar los mapeos SV, anexar seis MT al fixture acumulativo CAMP004, una fila al progreso, reutilizar runners Python/Godot y verificar la CI real y regresiones. No repetir CAMP003, no ejecutar bloques futuros por anticipado, no inventar normas ni cambiar códigos compartidos sin causa. Al 10/10 comunicar `CAMPAÑA_004_FINALIZADA` y STOP. Los textos de CAMP003 inferiores son históricos: el STOP antiguo fue reemplazado para esta nueva campaña por la puerta IA6. `main`, V28, árbitra, ramas ajenas, catálogo, 19 legacy, guardados y GPU/visual intactos.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_004 · 01/10 ENTREGADO (2026-11-03)

**IDENTIDAD:** IA5/W05, MT/libros. **ÚNICA rama CAMP004:** `codex/calvo-items-20261103-w05-camp004`. Esta campaña nueva fue activada expresamente por IA6; sus reglas `CAMPAIGN_004_W05_GATE.md`, `CAMPAIGN_004_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_004_W05.md` y `AUTONOMOUS_REPAIR_V5.md` de la rama árbitra prevalecen sobre el antiguo STOP histórico de CAMP003 que aparece debajo. CAMP003 se conserva 10/10 / 60 MT con CI PASS [#41565822563](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41565822563). **No repetir, sobrescribir ni extender CAMP003.**

**BLOQUE 01 CAMP004 ENTREGADO:** `tm82;tm83;tm84;tm85;tm86;tm87` mapeadas por perfil SV a `thunder_wave;poison_jab;stomping_tantrum;rest;rock_slide;taunt`. `tests/fixtures/parallel_items/w05_campaign_004.json` actualizado con seis nuevos casos, commit `b467ae2f219627c5e227ed830ea976435bd432a5`. CSV `docs/coordination/items_parallel_v1/reports/W05/CAMP_004_PROGRESO.csv` con primera fila `EN_CI_AUTOMATICA`, commit `7d1b5b65da4135dc197a198ab08aa78e1646c84f`. Informe `CAMP_004_ITER_01.md`, commit `ee9503519f3fcc72934c65c2e9bf4b74390e0559`.

**Control documental de Github:** fixture y progreso exactamente 1/10; seis IDs únicos y sus movimientos coinciden con la fila autorizada 01 y `machine_rows[*]["scarlet-violet"]` del perfil canónico. No equivale a enseñanza aprobada. **CI funcional del bloque 01 pendiente:** [#41571216304](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41571216304), SHA `7d1b5b65da4135dc197a198ab08aa78e1646c84f`, inicialmente `in_progress`. La CI anterior [#41570901863](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41570901863) fue únicamente bootstrap 0/10, sin pruebas funcionales. Se exigen en el nuevo run ambos recibos `CAMP004_W05_PY PASS blocks=1` y `CAMP004_W05_GODOT PASS blocks=1`, validador, regresión CAMP003 de 60 MT y CAMP002. Runs intermedios cancelados no son fallo.

**Siguiente `p`:** comprobar CI del SHA de progreso del bloque 01. Si `completed/success`, ejecutar **solo bloque 02** `tm88;tm89;tm90;tm91;tm92;tm93`, verificando mapeo SV y añadiendo seis casos y una fila a las rutas CAMP004. Si `queued/in_progress`, gate solo permite un bloque independiente sin declarar PASS; si `failure`, investigar logs y reparar automáticamente fallos W05 bajo V5 (perfil propio o únicamente `teach`, sin cambios globales, con regresiones), STOP/escalado por conflicto compartido, diseño o ACL real. Diez bloques máximo, luego `CAMPAÑA_004_FINALIZADA` y STOP. No inventar otros IDs.

**Protegidos:** `main`, V28, PR118, rama árbitra, otras W, producción ajena, catálogos, reglas/política, workflows, guardados reales y 19 MT legacy. No certificar UI/GPU con CI headless.

---

# ESTADO FINAL VERIFICADO IA5/W05 — CAMPAÑA_003 10/10 · CI PASS (2026-11-03)

**CAMPAÑA_003_FINALIZADA** tanto en entrega documental como en validación funcional de CI de su rama. Diez microbloques W05 entregados, **60 MT diferentes** validadas cumulativamente. Último run [#41565822563](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41565822563), SHA pruebas/progreso `984a80a128f5c6847664325ae487956adb838f49`, `completed/success`, Python `CAMP003_W05_PY PASS blocks=10 checks=580`, Godot 4.7 `CAMP003_W05_GODOT PASS blocks=10 checks=2166`, ambos gates del manifiesto PASS (logs comprobados, job `125687201922`). **No se introdujo parche en producción**: no apareció defecto que activar bajo V5. Fixture, CSV y cola IA6 cotejados: 60 IDs únicos y mapeos SV sin diferencias. La última fila CSV conserva estado histórico `EN_CI_AUTOMATICA` para evitar relanzar CI por cambios administrativos; prevalece el resultado del run real. Informes `CAMP_003_ITER_10.md` y `CAMP_003_FINAL.md` documentan el cierre.

**SIGUIENTE ACCIÓN:** ninguna `p` nueva está autorizada para W05. **STOP en 10/10**; no se inventa bloque 11, no se inicia CAMPAÑA_004. IA6 se encargará de consolidación / revisión global e integración. No se hizo merge a árbitra, `main` o V28; ni se modificaron otras W, catálogo, saves, 19 legacy o reglas compartidas. Pruebas de GPU/visuales no cubiertas por headless. Las notas inferiores de CI pendiente son históricas y anteriores a este PASS.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_003 · 10/10 ENTREGADOS (2026-11-03)

**Identidad:** IA5/W05 (familia MT/libros). **Rama exclusiva:** `codex/calvo-items-20261103-w05-camp003`. Autoridad de IDs: cola IA6 `CAMPAIGN_003_QUEUE_APPROVED.csv`; alcance y reparación: `campaigns/CAMP_003_W05.md` y `AUTONOMOUS_REPAIR_V5.md` de `codex/calvo-items-20261101-arbitro`. **Los diez microbloques están entregados. Ninguna nueva `p` puede crear un bloque 11 ni una nueva campaña.**

**ÚLTIMO BLOQUE 10 publicado:** `tm75;tm76;tm78;tm79;tm80;tm81` mapeados a `light_screen;rock_blast;dragon_claw;dazzling_gleam;metronome;grass_knot` en perfil Scarlet/Violet. Fixture propio acumulativo `tests/fixtures/parallel_items/w05_campaign_003.json` commit `f6f41b505173d303bf0f03062d4034fc63f182b4`, progreso `reports/W05/CAMP_003_PROGRESO.csv` commit `984a80a128f5c6847664325ae487956adb838f49`. Informe `CAMP_003_ITER_10.md` commit `55985e3de43d6f2c24650afb24248924fc6182de`. Informe consolidado `CAMP_003_FINAL.md` commit `05a361d8237c13f25c2b7c7b0271c050c9902ff3`.

**Control estático:** cotejados los 10 bloques del fixture y las 10 filas de progreso contra las diez asignaciones W05 de cola IA6 y `machine_rows[*]["scarlet-violet"]`. **60 IDs únicos, seis por bloque, cero discrepancias**. Tests Python/Godot W05 acumulativos mantenidos, sin modificar producción. La autorización V5 solo se usa si hay fallo comprobado; no implica inventar parches.

**CI bloques 01–09 VERIFICADA:** [#41563688381](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41563688381), SHA `ad5b3164f3ac116b79deef8538b8f36aca93c8e4`, `completed/success`. Logs `CAMP003_W05_PY PASS blocks=9 checks=522` y `CAMP003_W05_GODOT PASS blocks=9 checks=1951`. 54 MT con CI PASS en ese SHA.

**CI bloque 10:** [#41565822563](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41565822563), SHA `984a80a128f5c6847664325ae487956adb838f49`, `in_progress` en consulta previa. El run anterior de fixture #41565804120 quedó cancelado por nueva ejecución. Solo declarar 60/60 MT CI PASS si se comprueba `completed/success` y logs `CAMP003_W05_PY PASS blocks=10` / `CAMP003_W05_GODOT PASS blocks=10`. Informes posteriores no alteran los tests ni disparan CI.

**Regla de cierre:** `CAMPAÑA_003_FINALIZADA` como **entrega de diez bloques**, sin declarar certificada la CI final aún. **STOP de nuevos microbloques**. Si falla el run final, diagnóstico y reparación autónoma permitida en dominio W05 según V5, sin rebajar aserciones, sin tocar otras funciones de fichero compartido y con CI real tras parche. IA6 integra/revisa en lote. No modificar `main`, V28, PR118, ramas ajenas, catálogos, `data/`, `config/`, saves ni 19 máquinas legacy; UI/arte/GPU fuera de alcance.

---

# ACTUALIZACIÓN PREVALENTE W05 — AUTONOMOUS_REPAIR_V5 (2026-11-03)

**Estado oficial:** leído `docs/coordination/items_parallel_v1/AUTONOMOUS_REPAIR_V5.md` de la rama IA6 `codex/calvo-items-20261101-arbitro`, blob `ebe71ace6949cc9311eb9831068799081bca8ba7`. **Prevalece sobre la prohibición antigua de tocar cualquier producción:** W05 puede diagnosticar y reparar autónomamente fallos de su familia de MT/libros **solo en su rama**, limitando los cambios a `modules/inventory/field_machine_book_profile.gd` y **solo la función `teach`** de `modules/inventory/field_item_service.gd`, si hay evidencia de fallo real, con diff mínimo, regresión que falle antes/pase después, casos positivos y negativos intactos, y CI de SHA que incluya tests y producción. No modificar otras funciones de ese archivo compartido, APIs ajenas, `main`, V28, ramas de otras trabajadoras, catálogos, políticas o 19 máquinas legacy; no inventar compatibilidad ni reglas de juego.

**Fallos locales:** diagnosticar error exacto de Godot/Python/API, corregir dentro de propiedad W05 sin permiso rutinario IA6, comprobar todas las regresiones y ejecutar GitHub Actions. Si hay conflicto concurrente en la misma función, cambio general de arquitectura/contrato, regla ambigua, migración de saves o permisos realmente denegados que no puedan repararse lícitamente, STOP solo para esa operación y elevar hallazgo concreto a IA6. No saltar seguridad ni hacer force push. La CI `queued/in_progress` permite avanzar un solo bloque independiente; `failure` obliga a diagnosticar y reparar antes de trabajo dependiente.

**CI bloque 09 VERIFICADA EN LOGS:** [#41563035302](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41563035302), SHA `d17bffb0134d80b03f762c8c5f650e4e07f5e34f`, `completed/success`, Python `CAMP003_W05_PY PASS blocks=9 checks=522`; Godot 4.7 `CAMP003_W05_GODOT PASS blocks=9 checks=1951`. Además IA6 editó **exclusivamente el workflow de W05**, commit `ad5b3164f3ac116b79deef8538b8f36aca93c8e4`, para activar CI ante modificaciones del módulo W05; run [#41563688381](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41563688381) `completed/success`, confirma otra vez Python 522, Godot 1951. **Ninguna reparación de producción ha sido necesaria ni realizada por W05 todavía.** Esta modificación de workflow la publicó IA6, no W05.

**Progreso actualmente:** CAMP003 **09/10 publicados y CI PASS**, 54 MT con comprobaciones funcionales acumuladas. **SIGUIENTE `p` ejecuta únicamente el bloque 10/10:** `tm75;tm76;tm78;tm79;tm80;tm81`, según la cola IA6. No ejecutar bloque 10 por este mensaje de actualización de protocolo, pues no contiene la tecla `p`. Tras entrega del 10 y revisión de CI final, `CAMPAÑA_003_FINALIZADA` y STOP; no crear bloque 11.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_003 · 09/10 PUBLICADOS (2026-11-03)

**Identidad:** IA5/W05, familia de MT/libros. **ÚNICA rama:** `codex/calvo-items-20261103-w05-camp003`. Encargo/cola IA6: `CAMPAIGN_GATE_003.md`, `CAMPAIGN_003_QUEUE_APPROVED.csv`, `campaigns/CAMP_003_W05.md` en rama `codex/calvo-items-20261101-arbitro`. Esta cabecera prevalece sobre los históricos inferiores.

**BLOQUE 09 ENTREGADO:** `tm69;tm70;tm71;tm72;tm73;tm74` mapeadas en Scarlet/Violet a `ice_punch;sleep_talk;seed_bomb;electro_ball;drain_punch;reflect`. Fixture acumulativo de **9 bloques / 54 MT distintas**, commit `cdcd2ed0ce02913c0508e5da297a4d54b37dddf2`, y fila `09` del progreso `reports/W05/CAMP_003_PROGRESO.csv`, commit `d17bffb0134d80b03f762c8c5f650e4e07f5e34f`. Informe `CAMP_003_ITER_09.md`, commit `b7670550c6765b6e93d5aed1d41f2a7de08f7134`. Scripts Python/Godot propios sin cambios; continúan leyendo fixture/progreso acumulativamente. **Cotejo estático verificado:** 54 IDs no repetidos, nueve filas y mapeos idénticos a cola IA6 y fuente SV. No equivale a PASS funcional de seis nuevas enseñanzas.

**CI BLOQUES 01–08 VERIFICADA:** [#41560433553](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41560433553), SHA `aeaa0ec2a4add2ab134ceb4b8d06c12afca6e40c`, `completed/success`, logs Python `CAMP003_W05_PY PASS blocks=8 checks=464`, Godot 4.7 `CAMP003_W05_GODOT PASS blocks=8 checks=1736`. Se conservaron estados históricos `EN_CI_AUTOMATICA` de los primeros ocho bloques en el CSV para evitar nuevos runs redundantes; el veredicto real queda aquí.

**CI BLOQUE 09 AÚN SIN PASS:** [#41563035302](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41563035302), SHA de progreso `d17bffb0134d80b03f762c8c5f650e4e07f5e34f`, inicialmente `pending`; el run intermedio de fixture #41563021095 puede cancelarse por concurrencia. Para certificar exigir `completed/success` y ambos recibos `PASS blocks=9`. El progreso, informe y HEAD posteriores no equivalen a CI exitosa.

**Próxima `p`:** consultar CI del SHA del progreso 09/10; si `success`, ejecutar solo el **último bloque 10** `tm75;tm76;tm78;tm79;tm80;tm81`. Si en curso, un único bloque independiente de tests sin PASS; si FAIL del arnés, corregir sin perder aserciones; si falla servicio, SaveV2, catálogo o lógica compartida STOP y comunicar IA6. Una vez publicado bloque 10, anunciar `CAMPAÑA_003_FINALIZADA` **como entrega**, verificar CI final aparte y STOP. Nunca bloque 11 ni nueva campaña.

**Protección:** `main`, V28, PR118, árbitra, W01–W04, producción, `modules/`, `data/`, `config/`, CI/manifest compartidos, partidas reales, 19 MT legacy y arte/GPU/UI intactos.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_003 · 08/10 PUBLICADOS (2026-11-03)

**Identidad:** IA5/W05, MT/libros. **Única rama autorizada:** `codex/calvo-items-20261103-w05-camp003`. Reglas: `CAMPAIGN_GATE_003.md`, `CAMPAIGN_003_QUEUE_APPROVED.csv`, `campaigns/CAMP_003_W05.md` en rama árbitra. Cada `p` = solo primer bloque pendiente de cola (máximo 10, después STOP). Esta cabecera prevalece sobre las históricas inferiores.

**BLOQUE 08 ENTREGADO:** `tm63;tm64;tm65;tm66;tm67;tm68`, mapeo real SV `psychic_fangs;bulk_up;air_slash;body_slam;fire_punch;thunder_punch`. Fixture acumulativo `tests/fixtures/parallel_items/w05_campaign_003.json` ampliado a **8 bloques/48 MT**, commit `75082f500b06d27c80de3b117c2ce8a25d67ec56`. CSV `reports/W05/CAMP_003_PROGRESO.csv` con una sola fila nueva `08`, commit `aeaa0ec2a4add2ab134ceb4b8d06c12afca6e40c`. Informe `CAMP_003_ITER_08.md`, commit `cab17daf4bfe7155e452192d4e084f7cd8ede16d`. Scripts Python/Godot acumulativos **sin cambios**, no reprogramar `FieldItemService.teach`. **Validación estática comprobada:** 48 IDs únicos y correspondencia exacta con cola IA6, orden de filas y perfil SV. Esto NO implica CI funcional del bloque 08.

**CI BLOQUES 01–07 CONFIRMADA:** GitHub Actions [#41560159198](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41560159198), SHA `fc41a3e6cd53ee85cfccd08ca6da3a3fac2521e0`, `completed/success`; Python `CAMP003_W05_PY PASS blocks=7 checks=406`, Godot 4.7 `CAMP003_W05_GODOT PASS blocks=7 checks=1521`, ambos leídos en los registros. 42 MT cubiertas en ese SHA. Los estados históricos `EN_CI_AUTOMATICA` del CSV se preservan para no disparar CI innecesaria; el resultado real está verificado aquí.

**CI BLOQUE 08 PENDIENTE:** [#41560433553](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41560433553), SHA de progreso `aeaa0ec2a4add2ab134ceb4b8d06c12afca6e40c`, inicialmente `pending`. La ejecución anterior #41560420588 puede quedar `cancelled` por `concurrency.cancel-in-progress`. Exigir ambos recibos Python/Godot `PASS blocks=8` en último SHA para certificar 48 MT. Informes no activan CI.

**SIGUIENTE `p`:** revisar último run del SHA de progreso. Con `success`, ejecutar solamente **bloque 09** (`tm69;tm70;tm71;tm72;tm73;tm74`) y anexar exactamente seis casos y una fila nuevos. Si el run continúa, solo bloque independiente de tests sin PASS; si falla arnés W05, corregir sin reducir aserciones; fallo de servicio, catálogo, SaveV2 o contrato compartido implica STOP y notificación a IA6. Límite 10/10, `CAMPAÑA_003_FINALIZADA` y STOP.

**PROTECCIÓN:** `main`, V28, PR118, rama árbitra, otras W, producción, `modules/`, `data/`, `config/`, workflows, guardados reales, 19 legacy y arte/GPU/UI intactos.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_003 · 07/10 PUBLICADOS (2026-11-03)

**Identidad:** IA5/W05, MT/libros. **Rama exclusiva:** `codex/calvo-items-20261103-w05-camp003`. Única autoridad para los diez bloques: gate y `CAMPAIGN_003_QUEUE_APPROVED.csv` / `campaigns/CAMP_003_W05.md` de IA6. Esta sección prevalece sobre los historiales inferiores.

**BLOQUE 07 ENTREGADO:** `tm57;tm58;tm59;tm60;tm61;tm62` → `false_swipe;brick_break;zen_headbutt;u_turn;shadow_claw;foul_play`, mapeos reales en perfil Scarlet/Violet. Fixture ampliado a 7 bloques/42 MT, commit `05bb0662f3a4089146d1968bf651e3280f9dac11`. Una única nueva fila de progreso `07`, commit `fc41a3e6cd53ee85cfccd08ca6da3a3fac2521e0`. Informe `CAMP_003_ITER_07.md`, commit `a3d615d99f322132789d30933384852322df7ff9`. Scripts Python/Godot propios no reescritos, acumulan las 42 muestras. **Consistencia documental** verificada: 42 IDs distintos, siete filas y correspondencia idéntica a la cola y los movimientos del perfil; no implica enseñanza ejecutada del bloque 07.

**CI BLOQUES 01–06 VERIFICADA:** GitHub Actions [#41559866278](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559866278) sobre `920a647db1bfa5f5ad9f34c13bab5d6b2fa48143`, `completed/success`; logs `CAMP003_W05_PY PASS blocks=6 checks=348` y `CAMP003_W05_GODOT PASS blocks=6 checks=1306` (Godot 4.7). 36 MT verificadas funcionalmente en ese commit.

**CI BLOQUE 07 PENDIENTE HASTA RESULTADO DEL SHA DE PROGRESO:** `fc41a3e6cd53ee85cfccd08ca6da3a3fac2521e0`, workflow `.github/workflows/parallel-camp003-worker-autoci.yml`. Exigir `completed/success` y ambos recibos `PASS blocks=7`; no atribuir PASS de 42 MT antes. Run del commit de fixture puede ser `cancelled` por `concurrency.cancel-in-progress`.

**Próxima `p`:** verificar run del SHA de progreso del bloque 07; con success ejecutar solamente el **bloque 08** `tm63;tm64;tm65;tm66;tm67;tm68` (una nueva fila CSV, seis entradas fixture, informe y continuidad propios). Si CI sigue en curso, solo bloque independiente de tests sin PASS; si falla test propio, corregir sin reducir aserciones; defectos reales en servicio, SaveV2, fuente canónica o dependencia compartida → STOP y elevar IA6. Al llegar a diez bloques declarar `CAMPAÑA_003_FINALIZADA` y STOP.

**Protección:** `main`, V28, PR118, árbitra, ramas otras W, producción, `modules/`, `data/`, `config/`, CI/manifest compartidos, partidas reales, 19 legacy y UI/GPU intocados.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_003 · 06/10 PUBLICADOS (2026-11-03)

**Identidad:** IA5/W05, MT/libros. **ÚNICA rama de escritura:** `codex/calvo-items-20261103-w05-camp003`. Gate/cola autorizados por IA6 en `codex/calvo-items-20261101-arbitro`, `CAMPAIGN_GATE_003.md`, `CAMPAIGN_003_QUEUE_APPROVED.csv`, `campaigns/CAMP_003_W05.md`. Historial más abajo es obsoleto para la siguiente autorización.

**BLOQUE 06 entregado (sin PASS CI aún):** `tm51;tm52;tm53;tm54;tm55;tm56` con mapeo SV `sandstorm;snowscape;smart_strike;psyshock;dig;bullet_seed`. Se añadió al fixture propio `tests/fixtures/parallel_items/w05_campaign_003.json` commit `856c08cce2ac3b6b6ff6894d20c7debf2cb8a583` y al progreso `reports/W05/CAMP_003_PROGRESO.csv` commit `920a647db1bfa5f5ad9f34c13bab5d6b2fa48143`. Informe `CAMP_003_ITER_06.md` commit `104b52ef08f6ceaa915e78c4b8a6d41ba6f2cd0e`. Las suites Python/Godot siguen **acumulativas, sin ediciones de script**, para 6 bloques y 36 MT. Consistencia documental exacta entre fixture, progreso, cola y perfil SV: **verificada, 36 IDs únicos**.

**CI BLOQUES 01–05 VERIFICADA:** GitHub Actions [#41559168692](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559168692) `completed/success`, SHA `7692702bb5969de282a28604a93c44d01a8b092a`. Logs leídos: Python `CAMP003_W05_PY PASS blocks=5 checks=290`, Godot 4.7 `CAMP003_W05_GODOT PASS blocks=5 checks=1091`. Los campos históricos de estado `EN_CI_AUTOMATICA` del CSV de bloques 01–05 no se han reescrito para no disparar ejecuciones repetidas.

**CI BLOQUE 06:** último run del SHA `920a647db1bfa5f5ad9f34c13bab5d6b2fa48143` [#41559866278](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559866278); observado inicialmente como `pending`. El run intermedio de fixture #41559852441 puede cancelarse por política de concurrencia. No declarar 36 MT PASS sin `completed/success` y los dos recibos `blocks=6` sobre último SHA de progreso.

**SIGUIENTE `p`:** verificar CI exacta 06/10, luego ejecutar **solo bloque 07** `tm57;tm58;tm59;tm60;tm61;tm62` de la cola autorizada. Si CI en curso, la puerta permite como máximo un bloque de tests independiente, sin PASS; si falla runner propio, corregir sin quitar aserciones; si se detecta problema real de motor, SaveV2, catálogo, permisos o dependencia compartida → STOP y comunicar IA6. Nunca inventar nuevas MT ni avanzar más de un bloque por tecla. Límite diez bloques, después `CAMPAÑA_003_FINALIZADA` y STOP.

**Seguridad:** ninguna modificación en `main`, V28, PR118, árbitra, otras ramas, producción, `modules/`, `data/`, `config/`, workflows, guardados reales o catálogo canónico. Las 19 legacy siguen inactivas; visual/GPU no comprobada.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_003 · 05/10 PUBLICADOS (2026-11-03)

**Identidad:** W05/IA5, libros MT. **Rama EXCLUSIVA:** `codex/calvo-items-20261103-w05-camp003`. Cola y gate IA6 de CAMPAÑA_003, 10 bloques autorizados, seis IDs SV por bloque, uno por `p`. Los estados históricos inferiores no sustituyen esta cabecera.

**BLOQUE 05 ENTREGADO:** `tm45;tm46;tm47;tm48;tm49;tm50` = `venoshock;avalanche;endure;volt_switch;sunny_day;rain_dance` de versión Scarlet/Violet. Fixture acumulativo de 30 IDs, commit `4c305e29a1b418ccd531593071355220692c8f4b`; fila 05 del progreso, commit `7692702bb5969de282a28604a93c44d01a8b092a`. Informe `CAMP_003_ITER_05.md` en commit `ff3c12276c1e15cf6eb0744474545dea64ec46b5`. **Consistencia documental comprobada:** 5 bloques/30 IDs sin duplicados, mapeos SV iguales a cola IA6 y perfil. No se han reescrito scripts acumulativos ni código compartido.

**CI BLOQUES 01–04 VERIFICADA:** [#41558194753](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41558194753), SHA `d9c38c6cb606bbe3081eebc16d4560944370a48a`, `completed/success`; `CAMP003_W05_PY PASS blocks=4 checks=232` y `CAMP003_W05_GODOT PASS blocks=4 checks=876` leídos de logs.

**CI BLOQUE 05:** estado del progreso `EN_CI_AUTOMATICA` hasta confirmar nueva ejecución del SHA `7692702bb5969de282a28604a93c44d01a8b092a`. Exigir `CAMP003_W05_PY PASS blocks=5` y `CAMP003_W05_GODOT PASS blocks=5`, sin atribuir éxito al bootstrap ni a ejecuciones canceladas de fixture. El informe y esta cabecera no disparan otra CI.

**Siguiente `p`:** primero revisar el último workflow por rama sobre el SHA del progreso. Si success, ejecutar exclusivamente bloque **06** (`tm51;tm52;tm53;tm54;tm55;tm56`) añadiendo seis casos a fixture y una fila de progreso. Si en curso, se admite solo bloque independiente de pruebas sin PASS; un fallo real de arnés propio se repara con aserciones intactas; fallo de motor, guardados o catálogo compartido implica STOP y arbitraje IA6. Al 10/10 declarar `CAMPAÑA_003_FINALIZADA` y detenerse.

**Protección:** `main`, V28, PR118, árbitra, otras ramas, producción, `modules/`, `data/`, `config/`, CI inmutable, 19 legacy, guardados reales y arte/GPU/UI intocados.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_003 · 04/10 PUBLICADOS (2026-11-03)

**Identidad:** IA5/W05 · MT/libros. **Única rama de escritura:** `codex/calvo-items-20261103-w05-camp003`. Activación IA6 de diez microbloques según `CAMPAIGN_GATE_003.md`, `campaigns/CAMP_003_W05.md` y `CAMPAIGN_003_QUEUE_APPROVED.csv`. Historias previas inferiores no tienen autoridad para bloques siguientes.

**BLOQUE 04 publicado, estado EN_CI_AUTOMATICA:** `tm38;tm39;tm40;tm41;tm42;tm43` mapeados en SV a `flame_charge;low_sweep;air_cutter;stored_power;night_shade;fling`. Fixture acumulativo ampliado a **4 bloques/24 MT** en commit `e74d3d4cbdb38bd71624cbb31516b335c121b1ed`. Una sola fila nueva del progreso en commit `d9c38c6cb606bbe3081eebc16d4560944370a48a`. Informe `CAMP_003_ITER_04.md` publicado commit `e68362958e8f2a019f3cc437a92d91f930ed8d66`. Scripts Python/Godot de W05 permanecen intactos; su contrato es acumulativo y no se ha vuelto a implementar `FieldItemService.teach`.

**CI bloques 01–03 VERIFICADA:** [#41556713903](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556713903) SUCCESS, SHA `c3c48e92ddf48708d7d941554e58420a994e55ed`, Python **174** checks, Godot 4.7 **661** checks, `blocks=3`, cero errores. Recibos leídos directamente de logs.

**CI bloque 04 pendiente al publicar:** [#41558194753](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41558194753), SHA `d9c38c6cb606bbe3081eebc16d4560944370a48a`, inicialmente `pending`. La CI intermedia [#41558142876](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41558142876) puede quedar `cancelled` por cancelación deliberada de runs anteriores. No declarar PASS de 24 MT sin verificar `completed/success` y logs Python/Godot `blocks=4`. El cotejo estático de **24 IDs únicos**, 4 filas y perfil SV sí fue coherente.

**Próxima `p`:** verificar último run SHA del progreso del bloque 04. Si success, ejecutar solo **bloque 05** de la cola (`tm45;tm46;tm47;tm48;tm49;tm50`). Si todavía corre, un único bloque siguiente independiente permitido, sin declararlo PASS; FAIL de arnés propio se corrige sin reducir aserciones, FAIL funcional compartido → STOP e intervención IA6. Al completar 10/10, `CAMPAÑA_003_FINALIZADA` y STOP.

**Intocables:** `main`, V28, árbitra, otras W, producción, `modules/`, `data/`, `config/`, catálogo canónico, PR118, workflow/validador de manifiesto, saves reales y 19 legacy. Arte/GPU/UI no verificados.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_003 · 03/10 PUBLICADOS (2026-11-03)

**Identidad:** IA5/W05, libros/MT. **Única rama de escritura:** `codex/calvo-items-20261103-w05-camp003`. Autorización de la cola IA6 `CAMPAIGN_003_QUEUE_APPROVED.csv`/encargo `campaigns/CAMP_003_W05.md`, no modificar otras ramas ni producción.

**BLOQUE 03 entregado:** `tm30;tm32;tm33;tm34;tm35;tm37` = `snarl;swift;magical_leaf;icy_wind;mud_shot;draining_kiss` según versión Scarlet/Violet del perfil original. Se añadió el bloque 03 al fixture propio `tests/fixtures/parallel_items/w05_campaign_003.json` commit `f4668498b84ca92dc114ed4cac7edff4b001e109`, y una única tercera fila a `reports/W05/CAMP_003_PROGRESO.csv` commit `c3c48e92ddf48708d7d941554e58420a994e55ed`. Informe `CAMP_003_ITER_03.md`, commit `f9c2e665365d3bf41a5ee99f7ff0ab4b966fa15d`. No se tocaron runners previos: acumulan exactamente 18 casos para 03/10.

**CI bloques 01 y 02 VERIFICADA:** GitHub Actions [#41555043090](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555043090) `completed/success`, SHA `131b4420e2d4878972199bec9aa6fb4ccf86ae4a`, Python `PASS blocks=2 checks=116`, Godot 4.7 `PASS blocks=2 checks=446`. Se leyó el registro real. Los dos primeros renglones del CSV conservan estado histórico `EN_CI_AUTOMATICA` para evitar otra CI redundante, **pero su resultado real es SUCCESS**.

**CI bloque 03:** [#41556713903](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556713903) sobre `c3c48e92ddf48708d7d941554e58420a994e55ed`; **`pending` al primer vistazo**, no declarar PASS sin revisar la nueva conclusión y logs Python/Godot. El run anterior del fixture #41556696614 podrá ser `cancelled` por `concurrency.cancel-in-progress`. Contrato estricto: `blocks=3`, 18 casos, positiva y negativas completas, SaveV2, cero errores. Consistencia estática entre los 18 IDs de cola, fixture, progreso y perfil SV: **comprobada**, no equivale a resultados de enseñanza.

**Próxima `p`:** leer estado actual del último run del SHA del progreso; si `success`, ejecutar sólo **bloque 04**: `tm38;tm39;tm40;tm41;tm42;tm43`. Si aún en curso, se permite preparar un bloque independiente de pruebas sin PASS. Ante FAIL real, analizar logs: arreglar solo arnés W05 o STOP y reportar IA6 por dependencia de código compartido. No duplicar ID, borrar aserciones, modificar motor, versiones, políticas, catálogo, CI, arte, guardados reales, `main`, V28 o ramas ajenas. Campaña límite 10/10.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_003 · 02/10 PUBLICADOS (2026-11-03)

**Identidad:** IA5/W05, MT/libros. **Rama exclusiva:** `codex/calvo-items-20261103-w05-camp003`. Activación IA6 de diez microbloques en la cola `CAMPAIGN_003_QUEUE_APPROVED.csv` y `campaigns/CAMP_003_W05.md` (rama árbitra).

**BLOQUE 02 publicado, estado EN_CI_AUTOMATICA, sin PASS confirmado:** `tm24;tm25;tm26;tm27;tm28;tm29` mapeadas a `fire_spin;facade;poison_tail;aerial_ace;bulldoze;hex` en Scarlet/Violet. Se añadieron al fixture acumulativo (commit `f006f83ab42290609c65ab159652a68dc9017d64`) y al progreso (commit `131b4420e2d4878972199bec9aa6fb4ccf86ae4a`). **Bloque 01 conservado completo**; son 12 MT repartidas en dos bloques, todavía no doce enseñanzas certificadas por CI. Informe `CAMP_003_ITER_02.md`, commit `0f76b80eb15c7a77ae97efcfa7e0247495a3a970`.

**Control real ejecutado:** lectura y cotejo de los 12 IDs y movimientos en fixture, cola IA6, CSV de progreso y perfil SV: **coherentes**. No equivale a ejecución de Godot ni a verificación de learnsets. Se intentó obtener el veredicto de la CI anterior, pero no se recibió resultado fiable de Actions; por ello se avanzó solo **un bloque independiente de tests** y NO se marcó `CI_PASS_VERIFICADO`. El workflow `.github/workflows/parallel-camp003-worker-autoci.yml` se dispara por los pushes de fixture/progreso; no se ha tocado.

**Siguiente `p`:** consultar el último run real de CI para el último SHA de pruebas/progreso de **02/10**. Con `success`, ejecutar solo **bloque 03** (`tm30;tm32;tm33;tm34;tm35;tm37`) y anexar al fixture y CSV sin borrar previos. Con `queued/in_progress`, aplicar el gate V4 de independencia y no inferir PASS. Con `failure` de contrato compartido, motor o SaveV2, STOP y elevar a IA6; reparar solo test propio si error aislado. No acumular indefinidamente trabajo si sigue inaccesible el estado de CI.

**Protección:** `main`, V28, PR118, árbitra, otras W, `modules/`, `data/`, `config/`, catálogo canónico, scripts de workflow y partida real intactos. 19 legacy siguen inactivas. GPU/arte/UI excluidos.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_003 · 01/10 PUBLICADO (2026-11-03)

**Identidad:** W05, MT/libros. **ÚNICA rama de escritura:** `codex/calvo-items-20261103-w05-camp003`. Activación IA6 en `CAMPAIGN_GATE_003.md`, `CAMPAIGN_003_BRANCH_MANIFEST.md` y `campaigns/CAMP_003_W05.md`. Diez bloques, seis MT cada uno; completar uno por `p` y STOP en 10/10. **El historial CAMP001/002 más abajo es obsoleto para permisos y rama.**

**BLOQUE 01 entregado, CI sin resultado comprobado:** `tm07;tm16;tm18;tm21;tm22;tm23`. Fixture `tests/fixtures/parallel_items/w05_campaign_003.json`, Python `tests/tools/test_parallel_items_w05_campaign_003.py`, Godot `tests/gameplay/parallel_items_w05_campaign_003.gd`, informe `CAMP_003_ITER_01.md`, progreso `CAMP_003_PROGRESO.csv`. Commit Python final `c622e29bd06c5a40c189ff780a4effc8755d0275`, Godot final `a43b182e532d9bc123d64acc9a89bdc602bad08d`, trigger del progreso `a2047a58a02760380b3a55f4620417051984dea7`. **No afirmar CI PASS** hasta comprobar resultado del SHA exacto. No se pudieron verificar especies/PP manualmente en JSON normalizado por límite del conector: la CI Python y el runner verifican learnsets, metadatos, consumo y SaveV2 reales.

**Siguiente `p`:** primero consultar resultado CI de `codex/calvo-items-20261103-w05-camp003`. Si success, ejecutar **bloque 02** reservado `tm24;tm25;tm26;tm27;tm28;tm29`, anexando al fixture, conservando y probando bloque01 en scripts acumulativos. Si CI queued/in_progress, puede preparar solo bloque independiente sin PASS. Si fallo funcional o dependencia compartida, STOP y comunicar a IA6. Nunca adelantar más de un bloque por mensaje ni editar scripts de otras W o motor.

**CI inmutable:** `.github/workflows/parallel-camp003-worker-autoci.yml`, validador de manifiesto compartido inmutable. Pruebas con recibo estricto `CAMP003_W05_PY/GODOT PASS blocks=N checks=M` y N igual a progreso. No tocar `main`, V28, PR118, otras ramas, producción, datos, config, catálogo, saves reales ni activar las 19 legacy. Arte/UI/GPU no validados.

---

# IA5 / W05 — CUADERNO DE CONTINUIDAD · MACHINE

## 1. Identidad, alcance y autoridad

- **Identidad:** IA5 / W05; familia MACHINE (máquinas/libros de movimientos).
- **Rama de trabajo exclusiva:** `codex/calvo-items-20261101-w05`.
- **Última orden oficial leída:** [`assignments/LOTE_002_W05.md`](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-arbitro/docs/coordination/items_parallel_v1/assignments/LOTE_002_W05.md), blob **`b8f8df20cc70ab9ca7004c7b692a59537fc3efd7`**.
- **Estado:** `LISTA_PARA_REVISION` de LOTE_002 (todavía NO integrado ni certificado en Godot). No hay LOTE_003 asignado.
- **Base inicial propia:** `d6d6d5f9285d71b97db3ac18c6bbb70274ab19af`. **Checkpoint autorizado IA6:** `38188cc208e67b19002437ac75160898ce332ec2`. **Fusión segura en W05:** `239edd8083a0980e556dfe04079e03f04b09e89e` (dos padres; sin `--force`, LOTE_001 intacto).
- **Último commit de informe previo a este cuaderno:** `9435b86350c11edd35b190e10acdae1edca8cf41`. Para recuperar el HEAD final leer la rama W05 en GitHub; el propio documento no puede contener su SHA futuro de forma autorreferencial.
- **Pruebas funcionales ejecutadas sobre la base combinada:** **NINGUNA**. Estado de verificación completo: `PENDIENTE_CI`.
- **Rutas permitidas para este lote:** solo `tools/item_audit/parallel_w05_machine_scope.py`, `tests/tools/test_parallel_w05_machine_scope.py`, `tests/fixtures/parallel_items/w05_machine_scope_v1.json` y `reports/W05/{LOTE_002.md,CONTINUIDAD.md}`. Prohibido producción.

## 2. Mapa de implementación existente (NO rehacer)

**Fuentes:** `docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv` (248 seleccionadas), `docs/current/ITEM_FIELD_V8.csv.txt`, `docs/current/ITEM_INVENTORY.csv`, `modules/inventory/item_connections_v1.json` (338 IDs con mapas por versión, solo SV activo), `tests/fixtures/item_connections_v1/primary/sources.json` (fuente PokéAPI fijada).

**Adaptador:** `tools/item_audit/prepare_connections_v1.py` regenera relaciones canónicas `ID→versión→move_id` y fixtures de máquinas activas, sin tocar datos fuente. La ruta nativa ya se implementó antes de W05: `modules/inventory/field_item_service.gd:machine_move(),teach(),use_item()` selecciona versión, valida movimientos, especie, propiedad, estado de mochila y ranura; prepara criatura/bolsa y consume una unidad al éxito, no al rechazo.

**UI/guardado:** `scenes/visual/field_item_bag.gd` presenta una acción de enseñar y previsualiza el movimiento correcto; `tests/gameplay/item_connections_test_runner.gd` incluye una ruta `tm01` de mochila, guardado/carga e integración, **no 229 pruebas por ID en PC/guardado ni libros visuales**. Existe `scenes/visual/item_art_catalog.gd` y manifest de arte; de las 248 solo `tm01` tenía entrada gráfica registrada en LOTE_001.

**Propiedad de archivos:** `field_item_service.gd`, `field_item_bag.gd`, `item_connections_v1.json`, `assets/local_item_catalog/manifest.json`, políticas, tests anteriores y configuración de CI son compartidos/reservados. IA6 debe serializar cualquier edición de producción futura. En LOTE_002 se dejaron intactos.

## 3. Estado comprobable por subfamilia

| Subfamilia | Cantidad seleccionada | Fuente de prueba/estado | Límite actual |
| --- | ---: | --- | --- |
| MT `tm01`–`tm229` | 229 | `ITEM_FIELD_V8.csv.txt` + `ITEM_CONNECTIONS_V1.json` y `item_connections_test_runner.gd:172–197`, **PASS histórico V27 (2026-10-28)** | Una especie/MT en evidencia anterior; no PASS funcional del checkpoint combinado |
| MT antigua `tm00` | 1 | Perfil mapeado en `sword-shield`, no `scarlet-violet` | `DEPENDENCIA`: norma de versión/aprendizaje y consumo |
| MO `hm01/hm04/hm05/hm06/hm08` | 5 | Mapa histórico existente; `hm05` enseña `waterfall` en ORAS y solapa `tm77` SV | No habilitar efecto de campo ni enseñar sin política. `hm08` usa fuente `ruby-sapphire` |
| DT `tr13/tr19/tr28/tr31/tr39/tr41/tr44/tr50/tr72/tr83/tr85/tr91/tr93` | 13 | Mapa `sword-shield`; metadatos nativos de DT existentes | No son jugables en el perfil SV; entrada nativa ≠ ruta de uso |
| 90 máquinas canónicas fuera de selección | 90 | Total 338 mapeadas − 248 seleccionadas | No asignadas: no activarlas por accidente |
| Presentación gráfica tipo libro | 0 certificadas | Solo propuesta; sin escena/art nuevo | Consulta a IA6/diseño, no implementación actual |

**Interpretación obligatoria:** 248 seleccionadas **no** son 248 mecánicas certificadas. 229 pruebas históricas de enseñanza acotadas; 19 requieren perfil/reglas. La ausencia de 247 entradas en manifest no prueba ausencia de imagen fallback.

## 4. Historial de trabajos y pruebas

| Lote | Cambios reales | Prueba y alcance | Informe / estado |
| --- | --- | --- | --- |
| LOTE_001 | Auditoría de 248 IDs, CSV con mapeo/risks y reservas | Cruce **estático**; sin Godot nuevo | [LOTE_001](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/docs/coordination/items_parallel_v1/reports/W05/LOTE_001.md), commit `d9fffd2da1c9e4f2c120557503503292a34844f6`; **ACEPTADO por IA6 como documental** |
| LOTE_002 | Fusión checkpoint y creación de validador Python de solo lectura + suite de negativos + fixture versionado | Python 3.13.5 local **13 PASS + 1 SKIP** (12 controles unitarios más CLI y test real pendiente); cruce independiente de **datos GitHub reales** PASS estático 248/229/19 y solape | [LOTE_002](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/docs/coordination/items_parallel_v1/reports/W05/LOTE_002.md); **LISTA_PARA_REVISION**, pendiente IA6 |

**Rutas de LOTE_002:**
- [`tools/item_audit/parallel_w05_machine_scope.py`](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/tools/item_audit/parallel_w05_machine_scope.py) · blob `e1d6015a125f7fe4b5d1d0f9e34b94079f68858f`.
- [`tests/tools/test_parallel_w05_machine_scope.py`](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/tests/tools/test_parallel_w05_machine_scope.py) · blob `e150dd766c976f1fccf7d9fa2d08f633acc95ed4`.
- [Contrato JSON de regresión](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/tests/fixtures/parallel_items/w05_machine_scope_v1.json) · blob `0dbd1f4d299569b63a7b0f0341bf2112e51c9319`.

**Comandos reproducibles, desde raíz del checkout completo:**
```sh
python tools/item_audit/parallel_w05_machine_scope.py
python -m unittest discover -s tests/tools -p 'test_parallel_w05_machine_scope.py' -v
```

**Ejecución exacta hasta ahora:** el módulo Python y su suite se ejecutaron en contenedor aislado con tests sintéticos; 14 casos, 13 PASS, 1 SKIP (`test_ruta_real_248_si_disponible`, por no estar montado el repo). El chequeo estático **independiente** en sesión leyó blobs reales de GitHub `8b9b723...` y `0525b370...`, confirmó 248/229/19, detectó 5 mutaciones negativas; **no sustituye ejecutar el Python publicado con los 248 del checkout**. Godot 4.7 y GPU **SIN_EJECUTAR**. No se lanzó ningún workflow nuevo, por economía de CI.

## 5. Interfaz futura de libros — PROPUESTA, NO AUTORIZACIÓN

Implementar solo tras decisión IA6 y encargo nuevo, como **capa de presentación** sobre máquina existente, nunca una función de enseñanza por libro:

1. Entrada: `item_id` canónico existente en mochila; leer `machine_rows[item_id][perfil_aprobado]`, `move_id` y tipo del movimiento desde `DefinitionCatalog`; si el perfil no lo autoriza, UI indica «No disponible» y no ofrece usarlo.
2. Modelo de vista sugerido `LibroMovimientoVista` (estructura de datos, **no clase escrita**): `item_id`, `move_id`, `tipo`, `estilo_base_libro`, `paleta_tipo`, `texto_localizado`, `habilitado`, `motivo_bloqueo`. Variantes visuales reutilizables: seis bases de libro y colores por tipo si se confirma el diseño; sin 248 texturas/escenas exclusivas como requisito.
3. Acción: botón de la mochila llama al servicio actual `teach()`, no realiza reglas/consumo en el widget. Persistir únicamente ID y estado de criatura ya existentes, sin schema de guardado nuevo.
4. Validación futura: vista para ID normal/inactivo, color y tipo correctos, rendimiento de 248 entradas, acceso a PC, cancelación/rechazo sin gasto, persistencia y visual/GPU. La regla de MO de campo se diseña separadamente, nunca inferida del libro.
5. Duplicidad `hm05`/`tm77`: IA6 decide contenido; el verificador la mantiene visible y no elimina ningún ID automáticamente. `scarlet_book` y `violet_book` son objetos de historia, no sustitutos de MT.

## 6. Bloqueos, riesgos, siguiente turno

- **BLOQUEO DE VERIFICACIÓN:** el checkpoint V27+V28 está combinado sin CI. Para validar el Python publicado con los 248, hace falta checkout completo en ejecutor; GitHub Actions consolidada de IA6 o entorno Windows del usuario. No afirmar PASS de Godot a partir de test Python.
- **BLOQUEO DE POLÍTICA:** activar 19 legadas exige perfil, compatibilidad learnset, consumo, posibles duplicados y decisión sobre MO/campo. Ningún movimiento antiguo se asigna por similitud de número.
- **Riesgo de colisión:** servicio de inventario, vistas, tests compartidos, arte y políticas; las otras W trabajan familias vecinas. No escribir allí sin contrato de propiedad.
- **Riesgo de snapshot:** si cambian catálogo o versión, el contrato espera 248/229/19 y solape revisado; un FAIL puede indicar evolución legítima, **no** arreglarlo cambiando cifras a ciegas.
- **No tocar:** `main`, `codex/items-v28-from-main`, la árbitra, ramas ajenas, guardados, `config/`, `data/`, `assets/`, `.github/`, reglas Mega y decisiones de selección; no crear 248 scripts ni regenerar bibliotecas.

### Retomar en la siguiente conversación

1. Leer `STATUS.md` y **nuevo encargo oficial** en la rama árbitra; verificar SHA y permisos. Si no hay LOTE_003 asignado, **no trabajar**.
2. Leer este cuaderno y el [último informe](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/docs/coordination/items_parallel_v1/reports/W05/LOTE_002.md), no volver a procesar todo el historial.
3. Confirmar HEAD W05 e identidad de checkpoint `38188cc...`; verificar que IA6 acepte el reporte/runner y confirme si realizó CI consolidada.
4. Ejecutar ambos comandos Python en checkout con datos reales; documentar resultado y logs por commit. Mantener separada evidencia de lógica Python, evidencia de Godot y prueba visual.
5. Solo bajo nueva autorización, preparar contrato funcional/aprendizaje de 19 legacy y diseño de libro por tipo, con propiedad exclusiva de archivos.

**Último paso reproducible:** ejecutar primero `python tools/item_audit/parallel_w05_machine_scope.py` y luego `python -m unittest discover -s tests/tools -p 'test_parallel_w05_machine_scope.py' -v` sobre el checkout completo de W05; entregar resultados a IA6 para integración. **PENDIENTE_CI; LISTA_PARA_REVISION.**
