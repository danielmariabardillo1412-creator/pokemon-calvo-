## ACTUALIZACIÓN VIGENTE — CAMPAÑA_003 09/10 (2026-11-03)

**Identidad IA1/W01; rama exclusiva `codex/calvo-items-20261103-w01-camp003`.** La nueva orden `p` ya ejecutó exactamente bloque **09/10** de la cola de IA6 (`mirror_herb;muscle_band;protective_pads`). No iniciar el bloque 10 hasta una nueva `p`. Está autorizado `AUTONOMOUS_REPAIR_V5.md` para corregir cualquier fallo de propia especialidad en tests o efectos funcionales locales, sin tocar `main`, V28, ramas ajenas ni arquitectura compartida.

- **CI confirmada para 01–08:** [#41569533376](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41569533376) `completed/success`, SHA exacto `8fe7e3e9d51462aeb6dcf18d01c2274d6835a831`. `CAMP003_W01_PY PASS blocks=8 checks=649`; `CAMP003_W01_GODOT PASS blocks=8 checks=9780`. Los 16 fallos históricos de Botas Gruesas/Bola Férrea/Cola Plúmbea fueron reparados sin rebajar controles, SaveV2 sigue completo. El CSV progreso 04–08 ya tiene `CI_PASS_VERIFICADO` y run `41569533376`, junto con la fila nueva 09, en commit `dc636ff178d5d46a381b24407dcbde0ae3795732`.
- **Bloque 09:** Hierba Copia clona +2 Ataque del rival cuando usa Danza Espada (consumible), pero no copia bajada de Gruñido. Cinta Fuerte aumenta daño físico de Placaje, sin modificar especial Agua Pistola ni consumirse. Paracontacto evita daño de Casco Dentado cuando el portador usa Placaje, pero no inventa un daño en movimientos sin contacto o ante rival sin Casco Dentado; tampoco se consume. Para prueba de rival con Casco Dentado se admite `foe_item` en fixture y se equipa realmente a la criatura rival, sin modificar motor. Tres variantes activo/ausente/reserva y restauración SaveV2 para todo.
- **Cobertura 09:** 7 casos, 10 pares caso-semilla, 30 variantes. **Acumulado 01..09: 61 escenarios, 118 pares, 354 variantes**, sin alterar los 54 casos anteriores. Auditoría estática de tests/fixture/CSV **26/26 PASS**; no sustituye resultado funcional.
- **Commits/blobs:** fixture `8b6b94e579b013833ae004fdec9871556ebf3acb`, blob `57e195bb7924bc2b19217ba9d538c13b02d05034`; runner `e678f1a453ae3f3a994ea88b604d33fcfea9e443`, etiqueta corrección de nombre `facb84a47bbe3e1df1a8096bf78a2a8d5636107c`, blob `4ba47ddd5df3c42976387f7326ed3be6612a8080`; validador Python `aba72c8dddf98160810a1cf55d46dc4977b7b194`, blob `ec300498f622a51939166a5966b30dbf460804e7`; CSV disparador CI `dc636ff178d5d46a381b24407dcbde0ae3795732`; informe `CAMP_003_ITER_09.md`.
- **CI nueva:** [#41571425044](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41571425044), `in_progress` al publicar; es la única autoridad para afirmar PASS 09, debe emitir `CAMP003_W01_PY PASS blocks=9` y `CAMP003_W01_GODOT PASS blocks=9`, exit code 0. Si FAIL, examinar logs y corregir W01 con V5 **antes de trabajo dependiente**. Los runs cancelados por commits incrementales no implican fallo de función.
- **Próxima `p`:** revisar primero CI 09; si no hay error no resuelto, ejecutar **solo bloque 10/10 `quick_claw;red_card;rocky_helmet`** según cola. Tras completar 10, STOP: `CAMPAÑA_003_FINALIZADA`. No producir fila 11. No modificar `main`, V28, otra trabajadora ni catálogo canónico.

---

## V5 — REPARACIÓN COMPLETADA / 08 DE 10 CI PASS (2026-11-03)

**Máxima prioridad para la siguiente IA o la siguiente `p`: CAMPAÑA_003 W01 está en 08/10, con los 16 errores históricos reparados y CI ACUMULATIVA SUCCESS.** No repetir bloque 08. **Próxima `p` solo bloque 09: `mirror_herb;muscle_band;protective_pads`**. 10 será último. La campaña sigue en rama `codex/calvo-items-20261103-w01-camp003`.

- **CI definitiva**, [GitHub Actions #41569533376](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41569533376), `completed/success`, SHA de pruebas `8fe7e3e9d51462aeb6dcf18d01c2274d6835a831`; recibos auténticos `CAMP003_W01_PY PASS blocks=8 checks=649` y `CAMP003_W01_GODOT PASS blocks=8 checks=9780`. La puerta de manifiesto IA6 también PASS en ambas. **0 errores**, regresiones de 01..08 superadas, sin timeout.
- **Diagnóstico detallado:** 12 de los 16 errores de Botas Gruesas se corrigieron reintroduciendo el original con `switch 2` tras la reordenación de plazas (`switch 2` / `switch 2`); quedó acreditado en CI #41567242610 (12 errores desaparecen). Los cuatro restantes (Bola Férrea, Cola Plúmbea, dos semillas por objeto) eran falsos fallos: el lector de `|move|` buscaba `entry.contains("|p1a:")` e identificaba el **objetivo** como atacante. Commit V5 `8fe7e3e9d51462aeb6dcf18d01c2274d6835a831` corrigió a `entry.begins_with("|move|p1a:")`. La CI final muestra `active=foe none=own reserve=own` para ambos casos y Godot PASS. No se rebajó ninguna aserción ni se modificaron reglas ni motor compartido.
- **Alcance de pruebas:** 54 escenarios, 108 pares caso-semilla, 324 variantes (activo/ausente/reserva), propietario, consumo, reglas nativas, SaveV2 y controles negativos. Python 649 checks; Godot 9780. Los bloques **01..08** están certificados funcionalmente en la única CI final, además de los recibos históricos de 01..03.
- **Estado documental:** `CAMP_003_ITER_08.md` contiene el cierre y enlace a la prueba. `CAMP_003_PROGRESO.csv` tiene todavía los estados pre-veredicto de 04–08 porque editar CSV por sí solo desencadenaría otra CI de Godot innecesaria. En la **próxima `p` (bloque 09)** actualizar conjuntamente esas cinco filas a `CI_PASS_VERIFICADO` con run `41569533376` y publicar fila nueva 09 para hacer **una sola** ejecución automática. No corregir ficticiamente esos estados sin referenciar este run.
- **Límites:** ninguna comprobación de GPU/UI o final de combate; no hay cambios en `main`, V28, producción ajena ni ramas de otras trabajadoras. V5 sigue autorizando reparar autónomamente defectos propios ante futuras CI fallidas, conservando regresiones.

---

## REPARACIÓN V5 CRÍTICA — ERRORES 16 → 4, RUN 08 EN REGRESIÓN (2026-11-03)

**NO CONSUME BLOQUE.** W01/08 ya está entregado; no iniciar W01/09 hasta otra `p`. El usuario pidió corregir íntegramente los 16 errores antiguos. Se han revisado logs Godot reales de [#41565500695](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41565500695) y [#41567242610](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41567242610).

- El primer run completó 8.793 checks, 16 fallos: 12 por orden de cambio a reserva/regreso `heavy_duty_boots`, cuatro por lectura de orden `iron_ball`/`lagging_tail`. Con `switch 2` dos veces, Godot volvió a ejecutar los cambios con éxito y el segundo run solo falló en **4** comparaciones de orden (9.780 checks). Las otras 12 incidencias han desaparecido, veredicto real de CI.
- Trazas auténticas en #41567242610 prueban que el equipable hace mover al rival primero: `|move|p2a: ...|Tackle|p1a: ...`. El lector propio erraba porque buscaba `entry.contains("|p1a:")` y capturaba tanto al atacante como al **objetivo**. Se corrigió para comparar únicamente el prefijo `entry.begins_with("|move|p1a:")`, commit **`8fe7e3e9d51462aeb6dcf18d01c2274d6835a831`**. No se elimina ni relaja ninguna aserción, no cambia fixture, Python, SaveV2 ni producción.
- **CI nueva:** [#41569533376](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41569533376), SHA de prueba `8fe7e3e9d51462aeb6dcf18d01c2274d6835a831`. Pendiente veredicto al redactar; para declarar reparada CAMP003 W01 01..08 debe terminar `success` con `CAMP003_W01_PY PASS blocks=8` y `CAMP003_W01_GODOT PASS blocks=8`. Mientras tanto 01–03 PASS reales y 04–08 SIN PASS definitivo. Estado sin alterar en CSV.
- **Informe:** `CAMP_003_ITER_08.md` se amplió con análisis detallado de 16→4, logs y el parche. V5 autoriza estas reparaciones de W01; trabajo fuera de rama, motor compartido, `main`, V28 y demás IAs intocables.

---

## ACTUALIZACIÓN VIGENTE — CAMPAÑA_003 08/10 (2026-11-03)

**W01 IA1**, rama de escritura exclusiva `codex/calvo-items-20261103-w01-camp003`. El usuario ha escrito **una `p`** y autoriza **solo microbloque 08** (`luminous_moss;mental_herb;metronome`) de la cola IA6. Bloque **08/10 publicado**; no iniciar 09 hasta nueva `p`. Protocolo [`AUTONOMOUS_REPAIR_V5.md`](../../AUTONOMOUS_REPAIR_V5.md) permite arreglar autónomamente fallos propios de tests o producción de W01, pero no otras ramas, `main`, V28, reglas compartidas sin consenso ni reescrituras ajenas.

- **Incidencia prioritaria:** CI anterior [#41565500695](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41565500695) **FAIL** al ejecutar Godot completo (8.793 checks, 16 errores), Python PASS 7/582. El timeout previo de 600 s quedó resuelto con modos independientes en paralelo. 12 errores están en el segundo comando del ciclo Trampa Rocas/Botas Gruesas, 4 en el orden de movimiento de Bola Férrea/Cola Plúmbea. El parche propio de Botas y trazas del orden es commit `2da7f3c5156d608abc5f35545ba3b5cb13f2fe43`. La CI de parche se canceló al añadir W01/08, no demuestra corrección definitiva.
- **Bloque 08:** Musgo Brillante `luminous_moss` +1 Defensa Especial/consumo al recibir Agua, negativo Tackle; Hierba Mental `mental_herb` cura Mofa y se consume, negativo Amnesia; Metrónomo `metronome` aumenta daño por tres Agua Pistola y reinicia al interrumpir con Reflejo. Motor nativo, tres modos y SaveV2. **6 casos nuevos / 9 pares-semilla / 27 variantes**. Acumulado **54 casos / 108 pares / 324 variantes**; pruebas 01..07 preservadas.
- **Rutas/blobs nuevas:** fixture `tests/fixtures/parallel_items/w01_campaign_003.json` blob `0728bb40640c9519f61cdb2568fac289bf77a266`, commit `d44f112b9422f14d4ef3646b5e068539e6c242ce`; Godot `tests/gameplay/parallel_items_w01_campaign_003.gd` blob `28730756df0633c9440479e9e6100d4c71e4718c`, commit `4b48d98b0432ebd6f4b4845cafe2ee72fb655fe0`; Python `tests/tools/test_parallel_items_w01_campaign_003.py` blob `c1da6380a988f14ca55d2de51041ec2359dace2d`, commit `efe1abb568ec0fb52ee22709c67b99df8c30f3a8`; CSV 8 filas, commit `d68ca59bc61459e2295d467f67c765bb3a59bc69`; informe `CAMP_003_ITER_08.md`. Auditoría estructural **24/24** no significa PASS funcional.
- **Última CI acumulativa:** [#41567242610](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41567242610) para 08/10, inicialmente `pending`. Debe confirmar `CAMP003_W01_PY PASS blocks=8 checks=M` y `CAMP003_W01_GODOT PASS blocks=8 checks=M` en SHA correcto. 01..03 sí están CI_PASS; 04..07 **sin PASS**, 08 `EN_CI_AUTOMATICA`. Si Godot sigue fallando, utilizar las trazas reales y reparar en W01 conforme V5, sin rebajar aserciones ni inventar activaciones.
- **Siguiente `p`:** revisar/reparar primero CI. Solo cuando no quede fallo que impida trabajo dependiente, ejecutar el bloque 09 `mirror_herb;muscle_band;protective_pads`; 10 es máximo, 11 no existe. No modificar `main`, V28, árbitra, workflows ajenos, otra trabajadora, catálogo canónico ni arquitectura global.

---

## V5 ACTIVADO — AUTORREPARACIÓN W01, CI BLOQUE 07 (2026-11-03)

**Norma prevalente leída:** `docs/coordination/items_parallel_v1/AUTONOMOUS_REPAIR_V5.md` de árbitra IA6, blob `ebe71ace6949cc9311eb9831068799081bca8ba7`. W01 puede reparar pruebas y **efectos estrictamente propios de sus equipables** en su única rama, con diff mínimo, test de regresión y CI del SHA completo. Sin permiso para `main`, V28, otros IDs, otras ramas, arquitectura global o modificar workflows ajenos. La actualización NO consume bloque y el siguiente `p` sigue siendo **W01/08: `luminous_moss;mental_herb;metronome`**.

**Diagnóstico CI actual:** [run #41563668757](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41563668757) `completed/failure` por `timeout 600s` del paso Godot, **exit code 124**, tras `CAMP003_W01_PY PASS blocks=7 checks=582`. No existe resultado Godot PASS de los bloques 04–07. La actualización del workflow por IA6 fue un commit separado `96627e6e17796699c004af31f680f49193cb196d`, no una alteración W01. El timeout NO prueba por sí mismo fallo de mecánica.

**Reparación local de W01:** commit `fdc2e8623376de6f0981d2cd4a91d467dc4951e3`, archivo único `tests/gameplay/parallel_items_w01_campaign_003.gd`, blob `225600b833f94d65df9dbca4452e234d1d5c79ac`. Paraleliza solo `active/none/reserve` del **mismo caso y semilla**, con tres propietarios y sesiones nativas independientes, espera tres respuestas y compara TODO lo anterior (48 casos, 99 pares-semilla, 297 variantes; mismos controles, consumos, SaveV2, log y testigo Focus Band). No se tocó producción ni motor compartido. Inspección estructural 10/10 PASS; no supone veredicto funcional.

**Nueva CI:** [run #41565500695](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41565500695) sobre SHA de **código de prueba** `fdc2e8623376de6f0981d2cd4a91d467dc4951e3`; `in_progress` al publicar. Si falla por concurrencia, depurar y reparar exclusivamente W01 según V5, sin rebajar aserciones. Si vuelve a agotar el límite compartido de 600 s incluso con las optimizaciones, identificar duración y escalar a IA6 la dependencia **workflow** sin alterar este por cuenta propia.

**CSV:** 01..03 CI_PASS_VERIFICADO; 04..06 ENTREGADO_PENDIENTE_CI; 07 EN_CI_AUTOMATICA (todavía sin PASS). La CI del nuevo SHA, no las canceladas ni el timeout anterior, es la autoridad para actualizarlos. El siguiente bloque 08 solo con nueva `p` y sin fallo dependiente pendiente.

---

## ACTUALIZACIÓN VIGENTE — CAMPAÑA_003 07/10 (2026-11-03)

**Identidad IA1/W01**; escritura exclusiva `codex/calvo-items-20261103-w01-camp003`. La `p` presente autoriza **solo W01/07**, asignación oficial `iron_ball;lagging_tail;light_clay`. **07/10 entregado, CI funcional pendiente**. No adelantar 08 hasta siguiente `p`. El siguiente bloque será `luminous_moss;mental_herb;metronome`.

- **Pruebas de W01/07:** Bola Férrea pierde inmunidad voladora de Charizard a Terremoto y retrasa a Gengar respecto a Garchomp; Cola Plúmbea mueve después de Snorlax a igual prioridad pero no anula Ataque Rápido; Refleluz aumenta tres turnos Reflejo y no afecta a controles sin pantalla. Todas conservan los tres modos activo/ausente/reserva, control de consumo y SaveV2. **6 escenarios, 10 pares-semilla, 30 variantes** nuevos; matriz 01..07 **48 casos / 99 pares / 297 variantes**. Sin reprogramar motor.
- **Fuentes anteriores leídas:** `held_effect_sweep_v3.cjs` (`iron_ball` y `lagging_tail`) y `held_pilot.cjs` (`light_clay`), ambos con hashes ya fijados en descriptor. Inventario y selección consultados en solo lectura.
- **Git commits:** fixture `5c0b51ccebe9c8283294e8cb6792969b3ed888df` (blob `dde1e88b165fa1da854633ccb29e5fbf12f2f297`); Godot `1686d40c769dd6d4b1a8194a9b635fae5568c1af` y `d0a724aa3a4aad81e6c4c6288bd348b13857df97` (blob `823722d5eaf44e8b18cd67897b174dd34077713d`); validador `c68f4eb8ceef9e8ee00cc7a5a127bc77dfe495d8` (blob `197c2c786fd042a5c3395305bff991c5e189bafd`); CSV de 7 filas `edcb31040c68c429539eed4a8e523f83208bca57`; informe `CAMP_003_ITER_07.md`. Auditoría estática 23/23; NO equivale a prueba funcional.
- **CI verificada solo para 01..03:** 01 [#41553771307](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41553771307), 02 [#41555559263](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555559263), 03 [#41556859548](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556859548) SUCCESS. 04 [#41558549785](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41558549785), 05 [#41559578486](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559578486), 06 [#41560388772](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41560388772) CANCELLED tras nuevos pushes, siguen `ENTREGADO_PENDIENTE_CI`. 07 [#41561052781](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41561052781) `EN_CI_AUTOMATICA` al emitir; solo `CAMP003_W01_PY` y `CAMP003_W01_GODOT PASS blocks=7`, SHA y `success` revalidan 04..07.
- **Próxima `p`:** primero revisar CI final de 07; si hay fallo del test propio, corregir sin retirar causalidad; ante fallo del simulador/SaveV2/workflow compartidos, STOP e intervención IA6. Si CI sigue en curso sin fallo, se autorizan tests independientes W01/08 sin declarar PASS. Solo ese bloque.
- **No tocar:** `main`, V28, PR #118, `modules/`, `data/`, producción, catálogo, workflows, árbitra u otras ramas. No afirmar verificación GPU/UI o fin de combate.

---

## ACTUALIZACIÓN VIGENTE — CAMPAÑA_003 06/10 (2026-11-03)

**Identidad IA1/W01, rama exclusiva** `codex/calvo-items-20261103-w01-camp003`. `p` actual autoriza exactamente W01/06, ya publicado. **NO ejecutar W01/07 hasta siguiente `p`.** La cola oficial IA6 `CAMPAIGN_003_QUEUE_APPROVED.csv` asigna 06: `grip_claw;heat_rock;heavy_duty_boots`; 07: `iron_ball;lagging_tail;light_clay`.

- Nuevos casos 06: **6 escenarios / 9 pares caso-semilla / 27 variantes**; acumulado 01..06 **42 escenarios / 89 pares / 267 variantes**, 18 IDs. Se conservan todos los tests 01..05. Los casos de Garra Garfio ejecutan **siete turnos auténticos** para comparar duración de Infestación; Roca Calor lee `weatherState.duration` y exige +3 turnos de Día Soleado; Botas Gruesas ejecuta `switch 2` y `switch 1` para observar el daño de Trampa Rocas en actor y reserva según tenencia. Controles negativos y SaveV2 intrabatalla.
- Fuentes históricas leídas, no modificadas: `held_effect_sweep_v3.cjs` (`grip_claw`, `heat_rock`), `held_pilot.cjs` (`heavy_duty_boots`, `HELD_PILOT_VERIFIED`). Se añadió referencia de hash `c8a59a18f546d772ff34e4f8640a4246a00a822b` de `held_pilot.cjs` al descriptor W01.
- **Blobs al cierre:** fixture `fdad6ee5d646f470e8050c034a3edd023a5116fd` (último commit `4378ee810e86bf6635a4b8ca916764f86b7d912a`); runner `76546c05325c8ad09834c034c98d523fd9deedd7` (commit `7c1f662b144629b600d933dd2231f22de9988050`); validador Python `4ec0f71a1b39c4dba986d10eeb352c6a865eed30` (commit `99bbfa8117f8b30a2c4d0f0d05caee7a70696c5b`). CSV progreso 6 filas, commit `d76dfb5fc3ed0621b5c171a5a02da0046731803c`, informe `CAMP_003_ITER_06.md`.
- **CI honesta:** 01 [#41553771307](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41553771307) PASS, 02 [#41555559263](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555559263) PASS, 03 [#41556859548](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556859548) PASS (3.217 Godot checks). 04 [#41558549785](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41558549785) `cancelled`, 05 [#41559578486](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559578486) `cancelled` por pushes posteriores, **ninguna acredita PASS funcional 04/05**. 06 [#41560388772](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41560388772) se disparó con SHA de CSV y está pendiente de veredicto; debe validar acumuladamente 04/05/06 y emitir `CAMP003_W01_PY PASS blocks=6` más `CAMP003_W01_GODOT PASS blocks=6`. Auditoría estática propia 24/24 PASS, no equivalente a ejecución real.
- Siguiente `p`: comprobar última CI. Si se detecta fallo de script W01, corregir sin reducir aserciones; ante defecto compartido o bloqueo CI no resoluble por W01, STOP y solicitar IA6. Solo si no hay fallo pendiente, avanzar **W01/07**. El resto de tareas no está autorizado en este turno.
- Garantías: únicamente archivos W01 de campaña; `main`, V28, PR #118, `modules/`, `data/`, producción, catálogo, workflows, otras ramas y árbitra son intocables.

---

## ACTUALIZACIÓN VIGENTE — CAMPAÑA_003 05/10 (2026-11-03)

**IA1/W01; rama exclusiva `codex/calvo-items-20261103-w01-camp003`.** El `p` actual autorizó **únicamente bloque W01/05** según `CAMPAIGN_003_QUEUE_APPROVED.csv`: `flame_orb;focus_sash;grassy_seed`. Entrega **05/10 publicada**, CI del nuevo bloque `EN_CI_AUTOMATICA` y sin PASS funcional todavía. La próxima `p` autoriza SOLO bloque 06, con control previo de CI; no adelantarlo ahora.

- **Estado fiable 01..03:** CI [#41553771307](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41553771307) W01/01 PASS, 872 checks; CI [#41555559263](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555559263) W01/02 PASS; CI [#41556859548](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556859548) W01/03 PASS, 3217 checks. No usar estas como prueba de 04/05.
- **Incidencia de continuidad CI04:** run [#41558549785](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41558549785) estuvo `in_progress` en Godot mientras se iniciaba el bloque 05 y fue **cancelado por los commits posteriores** antes de emitir veredicto. No es PASS, no demuestra FAIL funcional; el CSV deja 04 `ENTREGADO_PENDIENTE_CI`. El run 05 deberá volver a ejecutar todos los casos de 04 y 05.
- **Bloque W01/05 publicado:** Llamasfera `flame_orb` quemadura al final del turno sin consumo vs control sin objeto/reserva y Charizard tipo Fuego inmune; Banda Aguante `focus_sash` YA VERIFICADA históricamente en `parallel_items_w01_held_v1.gd` (PS máximos vs inferiores, letal/no letal) pero con nuevos tests de integración y restauración SaveV2; Semilla Hierba `grassy_seed` Campo Hierba +1 Defensa/consumo vs Campo Eléctrico/ausencia, con controles. No se reimplementó ningún efecto. **8 escenarios / 11 pares-semilla / 33 variantes**.
- **Acumulado W01 CAMP003:** 36 escenarios, 80 pares caso-semilla, 240 variantes, 15 IDs de cinco bloques. Reusa `FieldItemService` / `Native` / `SaveGameRepository` de V28 y simulador `@pkmn/sim`, sin tocar módulos.
- **GitHub pruebas W01:** fixture `tests/fixtures/parallel_items/w01_campaign_003.json` blob `a63f1fe9e7baec515fc1a69f4042791e6c649981`, commit `8cc182ec9b6128f8eaac67a914ecfbf2f51820a6`; runner `tests/gameplay/parallel_items_w01_campaign_003.gd` blob `b37ba674a8b1c4990af5dafedb7c3795f63ea13a`, último commit `c23179a1da1038581c18f70c24cf8de9b269e103`; contrato `tests/tools/test_parallel_items_w01_campaign_003.py` blob `0f9de8a409c69853aa091e4c6f3cc5da28f4f35c`, último commit `8e174547429bba10c9bf3d62988d283931e15dd1`.
- **CSV:** `reports/W01/CAMP_003_PROGRESO.csv` 5 filas, commit disparador `adc29afe506a79b50af643eba475765c09aaef98`; 04 pendiente, 05 `EN_CI_AUTOMATICA`. **CI nueva:** [#41559578486](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559578486), `in_progress` al escribir. Solo `CAMP003_W01_PY PASS blocks=5 checks=M` y `CAMP003_W01_GODOT PASS blocks=5 checks=M` más `success` acreditan ambos. Puede cancelarse por un nuevo push, en cuyo caso consultar su sustituto.
- **Fuentes verificadas en GitHub:** inventario canónico y selección (solo lectura); `held_effect_sweep_v2.cjs` (`flame_orb`), `held_effect_sweep_v3.cjs` (`grassy_seed`) y W01 histórico `parallel_items_w01_held_v1.gd` (`focus_sash`). Python los ata a blobs y contratos exactos. CI pendiente de ejecutar pruebas 05; no proclamar PASS basándose en comprobación estática.
- **Siguiente `p`:** revisar el último run 05 y la cola antes de empezar bloque **06/10 = `grip_claw;heat_rock;heavy_duty_boots`**. Ante fallos de test, corregir SOLO pruebas propias sin eliminar comprobaciones; ante defecto de producción/SaveV2 o límite compartido del workflow, STOP y elevar a IA6. No iniciar 07..10 por adelantado.
- **Límites:** no cubre GPU/UI, vuelta al mapa, todas las combinaciones RNG, cambios de portador, implementación de engine. `main`, V28, PR #118, `modules/`, `data/`, workflow IA6, catálogo canónico, árbitra y todas las otras ramas (W02/W03/W04/W05) protegidas.

---

## ACTUALIZACIÓN VIGENTE — CAMPAÑA_003 04/10 (2026-11-03)

**Identidad IA1/W01, rama exclusiva `codex/calvo-items-20261103-w01-camp003`.** El usuario ha enviado la `p` correspondiente a **bloque 04**. Cola IA6 `CAMPAIGN_003_QUEUE_APPROVED.csv` W01/04: `eject_pack;electric_seed;focus_band`. **04/10 publicado, CI de nuevas pruebas EN_CI_AUTOMATICA, sin PASS funcional certificado aún.** Próxima `p` requiere primero leer CI, luego autoriza únicamente bloque W01/05.

- **CI cerradas anteriormente:** W01/01 [#41553771307](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41553771307) SUCCESS (872 Godot); W01/02 [#41555559263](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555559263) SUCCESS tras resolver límite de semillas Python; W01/03 [#41556859548](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556859548) SUCCESS (3.217 Godot / 3 bloques, Python PASS). CSV 03 pasa a `CI_PASS_VERIFICADO`.
- **Bloque 04 sin reimplementaciones:** Mochila Escape `eject_pack` se basa en `held_effect_sweep_v3.cjs` (`Close Combat`, bajada estadística, `forceSwitch`, consumo y negativo con `Tackle`). Semilla Electro `electric_seed` V3 (Campo Eléctrico, +1 Defensa, consumo, controles Campo Bruma y sin campo). Cinta Aguante `focus_band` V3 (`Seismic Toss` letal, item NO consumible, supervivencia probabilística en 24 semillas con obligación de al menos una activación real en log). Cada variante activo/ninguno/reserva comprueba propietario, existencias, instantánea nativa y restauración SaveV2.
- **Nuevas coberturas:** 7 casos / 32 pares-semilla / 96 variantes; acumulado W01 CAMP003 28 casos / 69 pares-semilla / 207 variantes. Los primeros 21 casos no se modificaron. Auditoría estructural con blobs GitHub 18/18 PASS, no sustituye Godot/CI.
- **Hashes/commits:** fixture `tests/fixtures/parallel_items/w01_campaign_003.json` blob `7a5823b7708362b0baadb37b10bfe4a5361a89ca`, commit `4e6564228190cb6e58e44dbacd49bcc3a2ef8d04`; runner `tests/gameplay/parallel_items_w01_campaign_003.gd` blob `e725f365d510ec8ba7e056eb7399a99ba8c9b7c0`, commit `b7a8c7387b7cbcc5108ba709a473d0f47e00de9b`; Python `tests/tools/test_parallel_items_w01_campaign_003.py` blob `6529a2eaa045abd702bda30eb38049e9e36fea85`, commit `68eaa186650adac748a0b37404aa0f8a427bb195`. CSV commit `ead4ab776703028c6289cebf182465d3a5306efc`, 4 filas; informe `CAMP_003_ITER_04.md`.
- **CI nueva:** [#41558549785](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41558549785) `in_progress` al redactar, SHA disparador `ead4ab776703028c6289cebf182465d3a5306efc`. El run final válido debe emitir `CAMP003_W01_PY PASS blocks=4 checks=M` y `CAMP003_W01_GODOT PASS blocks=4 checks=M`, M positivo. No adjudicar éxito de CI vieja a pruebas nuevas.
- **Próximo paso exacto con otra `p`:** consultar el run más reciente y logs; si `success`, ejecutar solo bloque 05 `flame_orb;focus_sash;grassy_seed`. Si `in_progress`, se permite preparar tests independientes sin dar PASS, salvo dependencia real; si `failure`, corregir exclusivamente test propio sin suprimir aserciones causales o detener y pedir IA6 ante defecto compartido. No inventar encargo 11.
- **Protecciones absolutas:** `main`, V28, PR #118, `modules/`, `data/`, workflow IA6, catálogo canónico, otras ramas (incluida W04 reincorporada por addendum) y producción intocables. GPU/UI, mapa y RNG exhaustivo siguen fuera del alcance.

---

## ACTUALIZACIÓN VIGENTE — CAMPAÑA_003 03/10 (2026-11-03)

**W01 / IA1, rama exclusiva `codex/calvo-items-20261103-w01-camp003`.** El usuario ha enviado la tercera orden de la campaña, `p`, y se ha ejecutado SOLO fila `W01/03` de `CAMPAIGN_003_QUEUE_APPROVED.csv`. Estado **03/10 publicado, CI nueva aún pendiente**, sin autorización de microbloque 04 antes de otra `p`. El gate IA6 admite continuar con `p` solo tras verificar último run y que no haya fallo funcional.

- **01/10:** `air_balloon;assault_vest;binding_band`. CI [#41553771307](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41553771307) SUCCESS, Godot 872 checks, Python y manifiesto PASS.
- **02/10:** `blunder_policy;booster_energy;cell_battery`. CI previa #41555265598 FAIL de contrato Python por tope de semillas; corregido exclusivamente para Seguro Fallo. CI final [#41555559263](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555559263) `completed/success` para tests del bloque 02. CSV 02 `CI_PASS_VERIFICADO`.
- **03/10 nuevo:** `clear_amulet;covert_cloak;eject_button`. No implementar hooks: Amuleto/Capa usan pruebas históricas nativas en `tools/item_audit/held_effect_sweep_v2.cjs` (`Charm`, `Nuzzle`); Botón Escape marcado `HELD_PILOT_VERIFIED` con `onAfterMoveSecondary`. Tests nuevos verifican caída de ataque, parálisis secundaria y `forceSwitch`, además de controles sin efecto, propiedad activo/ninguno/reserva, consumo y SaveV2. **6 escenarios nuevos, 9 pares-semilla, 27 variantes**.
- **Total acumulado:** **21 escenarios / 37 pares-semilla / 111 variantes**, 9 IDs de tres bloques. No se eliminaron escenarios anteriores. Auditoría estructural 18/18 PASS, sin atribuir PASS funcional todavía.
- **Scripts exclusivos:** `tests/fixtures/parallel_items/w01_campaign_003.json` blob `ed56adf7dc77bf01699e4690cec490b2def1b227`; `tests/gameplay/parallel_items_w01_campaign_003.gd` blob `01a0a37409a072066e0d5aa58a4d39aebe490ff0`; `tests/tools/test_parallel_items_w01_campaign_003.py` blob `e167965856f062fa149fd1d6ce368d8b62eb3e9e`. CSV tres filas, commit disparador `4bacfd05b82296eadd5767f871082e2cc8692b14`.
- **CI nueva:** [#41556859548](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556859548) `pending` al publicar; se considera `EN_CI_AUTOMATICA` y no PASS hasta revisar conclusión, SHA, Python, Godot. CI debe emitir ambas líneas estrictas `CAMP003_W01_PY/GODOT PASS blocks=3 checks=M`. Runs previos cancelados tras push son supersedidos.
- **Documentos rápidos:** `CAMP_003_ITER_01.md`, `CAMP_003_ITER_02.md`, `CAMP_003_ITER_03.md`, `CAMP_003_PROGRESO.csv` y este cuaderno. Las anteriores campañas en otras ramas no se reabren ni mezclan.
- **Siguiente `p`:** primero consultar CI último commit; si éxito, solamente `W01/04: eject_pack;electric_seed;focus_band`. Si fallo del motor/SaveV2 compartidos STOP y escalar IA6; si solo test, reparar sin rebajar controles. No tocar `main`, V28, W04 (su campaña propia por addendum), otras W, `.github/workflows`, `data/`, `modules/`, catálogo canónico ni producción. Después de 10/10 `CAMPAÑA_003_FINALIZADA` y STOP.

---

## CORRECCIÓN CI DE BLOQUE 02 — CONTRATO DE SEMILLAS

**Fallo real de contrato Python, no de mecánica:** [CI #41555265598](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555265598) `failure`, porque el validador W01 exigía máximo 4 semillas en todos los casos y `blunder_accuracy_event` reserva exactamente 8. La CI se detuvo antes de Godot. Corrección solo de test, sin bajar controles: commit `95de5b7581b54183a7fd108ccf6066a1ddb32154`; límite 8 para ese caso, pero lista exacta inmutable en `SCENARIOS_02`. Resto sigue tope 4. CSV actualizado `45e06d1b14f1969a0ee178caf42543a69139cdbb`. **Nueva CI de último SHA debe pasar antes de atribuir PASS de 02**; si falla motor/contrato ajeno, detenerse.

---

## ACTUALIZACIÓN MÁS RECIENTE — CAMPAÑA_003 02/10 (2026-11-03)

**Identidad:** IA1/W01. Única rama de escritura `codex/calvo-items-20261103-w01-camp003`. Cola aprobada IA6 `CAMPAIGN_003_QUEUE_APPROVED.csv`, fila W01/02; ID exactos `blunder_policy;booster_energy;cell_battery`. Se ejecutó UNA iteración nueva tras recibir la `p`. **No iniciar 03 hasta próxima `p`.**

- **CI del bloque 01 confirmada:** [Actions #41553771307](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41553771307) SUCCESS en SHA de tests/progreso `f9316279e97564f7b12ff71ad0692f572881afa2`; Godot 4.7 `CAMP003_W01_GODOT PASS blocks=1 checks=872`. CSV de 01 corregido a `CI_PASS_VERIFICADO`.
- **Bloque 02 publicado:** fixture 8 casos nuevos / 18 pares-semilla, 54 variantes; total acumulativo con bloque 01: **15 casos / 28 pares-semilla / 84 variantes**. No se modifican los 7 anteriores. Informes `CAMP_003_ITER_01.md` y `CAMP_003_ITER_02.md` son la entrada más rápida para otra IA.
- **Mecánicas existentes:** Seguro Fallo `held_effect_sweep_v3.cjs` cambia `spe +2` y consume únicamente al fallar `zap_cannon`; test contrastado contra log `|-miss|` con ocho semillas, y sin objeto/reserva. Energía Potenciadora tiene pruebas V3 con Great Tusk/Protosíntesis, Iron Hands/Carga Cuark, control sin habilidad; ahora se exige activación al entrar, volátil y consumo real. Pila tiene prueba V2 con `thunder_shock` y `atk +1`; controles Normal/estado. No se implementaron hooks nuevos.
- **Pruebas nuevas autorizadas (acumulativas):** `tests/fixtures/parallel_items/w01_campaign_003.json` blob `07ea3df454b4e83e0e71aac8887dc341c822ca53` (commit `6d5c6f2aa...`); `tests/gameplay/parallel_items_w01_campaign_003.gd` blob `12f59a4997e8f5aebf5659af9c554e0689bb1386` (commit `0c29554638...`); `tests/tools/test_parallel_items_w01_campaign_003.py` blob `c3b5621bc757aa01839e2a2714a74ac955d19f80` (commit `963c8c772e...`). CSV 2 filas, actualización de progreso SHA `594c6772f3b64c9cabc2b31d23d435634bc53bee`.
- **CI de bloque 02:** último run [#41555265598](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555265598) sobre último commit de progreso; **EN_CI_AUTOMATICA** al crear cuaderno. Las ejecuciones intermedias canceladas por `concurrency.cancel-in-progress` no son fallos funcionales. Auditoría estructural 12/12 PASS; **no afirmar PASS nativo de bloque 02 antes de resultado real**.
- **Próxima `p`:** consultar gate y último run. Si `success`, ejecutar exclusivamente W01/03 `clear_amulet;covert_cloak;eject_button`; si `queued/in_progress` se puede preparar un bloque de tests independientes sin declarar PASS; si `failure`, revisar la causa y reparar únicamente propio TEST o STOP por dependencia compartida. Sin cambios en `main`, V28, otras ramas, producción, `modules/`, `data/`, CSV canónicos ni workflow; W04 reincorporada por IA6 mediante addendum, fuera de nuestras asignaciones.
- **Regla límite:** 10 bloques totales; una `p` autoriza solo el siguiente. Tras 10/10 `CAMPAÑA_003_FINALIZADA` y STOP. No crear nuevas tareas de forma autónoma.

---

# CUADERNO VIGENTE — IA1/W01 · CAMPAÑA_003 (2026-11-03)

## ACTUALIZACIÓN VIGENTE — IA1 W01 / CAMPAÑA_003 BLOQUE 01

**Identidad:** IA1/W01; rama exclusiva `codex/calvo-items-20261103-w01-camp003`, nacida del SHA `41c1efeba0346349490f863131179ed7a8fc274c`. **Campaña ACTIVADA 10 bloques** por IA6 y usuario. Autoridad: `CAMPAIGN_GATE_003.md` blob `390f7ce6897462e1ae8e3cc7e3cd5f799b6c2213`; `CAMPAIGN_003_BRANCH_MANIFEST.md` blob `9b797b4d32fbab022e12d580e46b10f063f5690f`; encargo `campaigns/CAMP_003_W01.md` blob `b638d5525b0aec87dd730b5573a99cca53c0522e`; cola aprobada `CAMPAIGN_003_QUEUE_APPROVED.csv` blob `ea06a0a000fc4f3b8bab48e45e21fb549d753559`. No mezclar ramas CAMP001/002; el texto histórico que sigue NO es asignación vigente.

**Avance:** `01/10` bloque 01 publicado; siguiente bloque autorizado con otra `p` es **02**, IDs `blunder_policy;booster_energy;cell_battery`. Si CI FAIL, corregir solo test propio o STOP por problema compartido, nunca pasar a 02 bajo fallo real.
- **Bloque 01:** `air_balloon`, `assault_vest`, `binding_band`. Globo y Chaleco ya tienen CI histórica: registrar `YA_VERIFICADO_NO_DUPLICAR`; Banda tiene evidencia de residual `held_effect_sweep_v3.cjs`. No han sido reprogramados; hay **nuevas pruebas nativas** de integración y SaveV2 de los tres.
- **Archivos de prueba de esta campaña:** `tests/fixtures/parallel_items/w01_campaign_003.json` (7 escenarios, 10 pares-semilla, 30 variantes), `tests/gameplay/parallel_items_w01_campaign_003.gd`, `tests/tools/test_parallel_items_w01_campaign_003.py`. El CSV `reports/W01/CAMP_003_PROGRESO.csv` tiene una fila. Informe `reports/W01/CAMP_003_ITER_01.md`. Commits respectivos `36baab52`, `3ab97738`, `c374c1ed`, `f9316279`, informe `4e5900c0`.
- **Test del bloque:** `Native` usa motor `@pkmn/sim`; _fixture equipa con `FieldItemService`; controles activo/ausente/reserva, restricción Chaleco/PS Globo/trampa Banda, lectura y restauración SaveV2 con `_restore_probe`. Python fija cola, campos, hashes y contratos de la fixture. CI workflow por rama es propiedad de IA6.
- **Pruebas:** auditoría estática de blobs 16/16 PASS. Última CI al escribir [#41553771307](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41553771307), SHA `f9316279e97564f7b12ff71ad0692f572881afa2`: `EN_CI_AUTOMATICA`, sin PASS confirmado hasta revisar conclusión. Los runs intermedios sin progreso 01 solo certifican bootstrap. Godot headless no prueba interfaz/GPU, mapa, otros eventos.
- **Reglas siguientes:** cada `p` uno de los bloques 02..10 siguiendo fila exacta de cola/progreso. No inventar nuevos IDs, no modificar V28, main, PR #118, producción (`modules/`, `data/`, `config/`) ni otras W, ni tocar workflow/manifest. Después de 10/10 `CAMPAÑA_003_FINALIZADA` y STOP. IA4 no participa.

---

# W01 — CUADERNO DE CONTINUIDAD

## Identidad y autoridad

- **IA1/W01**, rama exclusiva `codex/calvo-items-20261101-w01`.
- Familia: `HELD_COMBAT_CANDIDATE`, objetos `assault_vest`, `loaded_dice`, `focus_sash`.
- Última orden oficial: `docs/coordination/items_parallel_v1/assignments/LOTE_002_W01.md` en rama árbitra, **blob de asignación `660203ce96aeff2f6bb42b88962b7b46f5e2eca4`**.
- Estado **LISTA_PARA_REVISION (tests escritos, Godot PENDIENTE_CI)**; IA6 aceptó únicamente LOTE_001 como auditoría documental. No autodeclarar LOTE_002 integrado.
- Base integrada IA6: `38188cc208e67b19002437ac75160898ce332ec2`; merge seguro propio `e40b82303aa5c12b2ec1faaa8bcea2554e9319a6` con los dos padres. Antiguo W01 preservado: `aa224efeb261a05a63e5d3cae928748ec195aeb1`; informe LOTE_001 blob `df56277c045c05e28499cfea71e99ddaaf18ce48`.
- Commit de tests nuevos: `5f306faa1a375bf4094d493c40e20341a006460c` (tres archivos autorizados). El commit documental del cierre será posterior; consultar HEAD actual.

## Mapa técnico — qué existe y cómo funciona

`docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv` (selección de contenido) → 
`modules/inventory/field_item_service.gd` (`holdable/equip/unequip`, propietario equipo/PC, consumo físico) → 
`modules/gameplay/showdown_adventure_session.gd` / backend `modules/battle/backends/showdown/showdown_backend.gd` (sesión) → 
`native_engine.cjs` / **@pkmn/sim 0.10.11** (hooks de efecto nativos) → 
`CreatureInstance` / `SaveGameRepository` (snapshot/propietario) → UI/escena mapa (fuera del lote).

**No duplicar** lógica del motor en GDScript. `field_held_items.cjs` registra metadatos de otros ítems, no contiene los tres efectos; los hooks nativos conocidos son:
- Chaleco: `assaultvest`, `onDisableMove|onModifySpD`.
- Dado: `loadeddice`, `onModifyMove`.
- Banda: `focussash`, `onDamage`.

Los inventarios `ITEM_INVENTORY.csv` y matriz `ITEM_FIELD_V8.csv.txt` certifican presencia/transferencia y ciertos escenarios antiguos, no funcionamiento exhaustivo. V28 añade harness común, pero su lista de cierre ampliado deja fuera estos tres IDs. V28 y el catálogo convivieron inicialmente en ramas divergentes, ahora comparten checkpoint Git; CI conjunta **sin verificar**.

### Adaptadores y pruebas reutilizables

- V27: `tools/item_audit/held_pilot.cjs`, `held_effect_sweep_v2.cjs`, `tests/gameplay/item_held_pilot_test_runner.gd`, `item_effect_projection_v2.gd`; PASS históricos acotados, **no repetirlos sin motivo**.
- V28: `tests/gameplay/item_automation_v28.gd`, `_fixture`, `_restore_probe`, `_write_evidence`, `FieldItemService`, `SaveGameRepository`, `Native`; `tools/item_audit/automation_v28.py` conserva contratos cerrados ajenos y no se ha editado.
- W01 nuevos: `tests/fixtures/parallel_items/w01_held_v1.json` (9 casos / 16 semillas combinadas / 3 variantes por ejecución), `tests/gameplay/parallel_items_w01_held_v1.gd` (runner que hereda los helpers), `tests/tools/test_parallel_items_w01_held_v1.py` (contratos/evidencia SHA). **No** nuevos handlers de objeto.

## Estado por ID

| ID | Ya existía (histórico) | Test W01 añadido (no ejecutado en Godot) | Pendiente |
|---|---|---|---|
| `assault_vest` | Bloqueo de estado/turno rechazado (V1); callback nativo de Defensa Especial | bloqueo/ataque permitido, reducción de daño especial comparativa, daño físico control, reserva, restore | CI + asentamiento en campaña, supresión/Truco y efectos complejos |
| `loaded_dice` | 4–5 golpes Semilladora (V2) | seis semillas, control sin objeto/reserva, dos golpes fijos, golpe simple, restore y retención | CI + distribución estadística, otros ataques/habilidades |
| `focus_sash` | 1 PS y gasto al evitar KO (V1) | PS máximos/reducidos, golpe no letal, guardado de consumo y unidades activas/reserva | CI + cierre real del combate y gasto único persistido en campaña |

## Historial y evidencia

| Lote | Entrega | Evidencia actual | Autoridad IA6 |
|---|---|---|---|
| 001 | Informe `reports/W01/LOTE_001.md`, commit `aa224efe...`; solo lectura del código | PASS antiguos identificados, sin runtime nuevo | ACEPTADO **documental**, no funcional |
| 002 | Pruebas y fixture nuevos en `5f306faa...`; `reports/W01/LOTE_002.md` y este cuaderno | `python -m py_compile` PASS; `python tests/tools/test_parallel_items_w01_held_v1.py --contracts` PASS 9/16; 4 manipulaciones negativas rechazadas; comando sin reporte termina con error por ausencia de evidencia; **Godot SIN_EJECUTAR** | PENDIENTE_REVISION |

**Comandos futuros reproducibles** desde checkout combinado:

```bash
python -B tests/tools/test_parallel_items_w01_held_v1.py --contracts
godot --headless --path . --import
godot --headless --path . --script res://tests/gameplay/parallel_items_w01_held_v1.gd
python -B tests/tools/test_parallel_items_w01_held_v1.py
```

Se necesita Godot 4.7, `@pkmn/sim@0.10.11` fijado y `POKEMON_CALVO_NODE` correctamente configurado. Reutilizar staging/restauración del workflow V28, sin descargar/alterar datasets originales. La salida de Godot debe producir `.godot/parallel_items/w01_held_v1/report.json` y evidencias; Python sin `--contracts` debe revalidar los hashes. Ningún RUN de Godot nuevo disponible; prueba visual/GPU **NO REALIZADA**.

## Riesgos, dependencias y siguiente paso

1. IA6 debe validar la base fusionada mediante **una CI consolidada** y registrar commit, run, log y posibles fallos de parser/GDScript (no ejecutado aquí).
2. Si un test falla por fixture o regla del motor, conservar su salida y diagnosticar: **no** alterar callback, RNG, selección, ni cambiar el criterio para forzar PASS. Solicitar propietario de motor a IA6 si fuera necesario.
3. El harness W01 hereda de V28. Si se modifica V28/una API compartida, revisar compatibilidad antes de integrar.
4. Falta confirmar liquidación de combate y guardado de campaña después de consumo de Banda. El test actual verifica snapshots/restauración y ausencia de publicación prematura, no el ciclo completo de mapa.
5. La prueba de seis semillas de Dado no certifica porcentaje exacto de distribución; faltan casos de habilidades, movimientos especiales y dobles.
6. El próximo trabajo es **revisar informe 002 + diff y ejecutar CI**; solo después IA6 puede autorizar LOTE_003.

**NO HACER EN OTRO CHAT:** no tocar `main`, V28, árbitra, otras W, `modules/`, `scenes/`, `data/`, `assets/`, `config/`, docs actuales, políticas ni guardados sin nuevo encargo. No reprogramar efectos nativos que ya existen; no asumir LOTE_003 por un simple «sigue».

**Último siguiente paso reproducible:** IA6 revisa `LOTE_002.md`, el fixture y el validador del commit `5f306faa...`, y ejecuta una única CI para obtener el primer PASS/FAIL funcional nuevo. Hasta entonces, estado **LISTA_PARA_REVISION / PENDIENTE_CI**.
