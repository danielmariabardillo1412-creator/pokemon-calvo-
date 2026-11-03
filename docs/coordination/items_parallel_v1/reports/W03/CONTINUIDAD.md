**CI bloque05 VERIFICADA:** [Actions #41559647462](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559647462) terminó SUCCESS en SHA `d3a9ce8bee76564a18cc5e997cdcd0bef5dd5c74`. Logs del job `125667075993`: `CAMP003_W03_PY PASS blocks=5 checks=148`, `CAMP003_W03_GODOT PASS blocks=5 checks=619`, puertas de IA6 PASS. No atribuir este resultado a cambios de producción: solo auditoría y pruebas de Fast/Dream. Siguiente `p` = 06 `friend_ball;heal_ball`. CSV conserva estado de publicación EN_CI_AUTOMATICA para evitar activar otra CI con una mera edición documental.

# IA3/W03 — CONTINUIDAD VIGENTE CAMPAÑA_003: 05/10

**Rama exclusiva:** `codex/calvo-items-20261103-w03-camp003`. **Fila 05 ejecutada:** `fast_ball;dream_ball`. **Siguiente `p`: fila oficial 06 `friend_ball;heal_ball`**, después de revisar CI de 05. Prohibido saltar a 07 sin otra `p`.

- **01–04 PASS real:** [Actions #41558471582](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41558471582), SHA de tests `34d963e5...`, Python 122 / Godot 490, 0 errores. El último HEAD previo a 05 era documental `fc1558e2...`.
- **05 Fast/Dream son mecánicas EXISTENTES**; histórico `item_capture_v11.gd` prueba 10.760 casos, por lo que no se duplica. Nueva cobertura complementaria: especies Pikachu base_speed90/×1, Mew100/×4 y Raichu110/rate75/×3,4 cap255; sueño persistente ×4 además del bono de estado ×2, Bostezo volátil no activa Ensueño; dos especies y dos modos PS; inventario/RNG, identidad y negativos con ambas.
- **Rutas propias de pruebas:** `tests/fixtures/parallel_items/w03_campaign_003.json` blob `0aa75d9f67bdc6d7c04693db58675628604819f7`; `tests/gameplay/parallel_items_w03_campaign_003.gd` blob `66bba61156102ddc7f3d668b683f5881cd49db55`; `tests/tools/test_parallel_items_w03_campaign_003.py` blob `bb6460ee07c63b496a6d85fa57f2b273b0b3af49`.
- **CSV 05 publicado:** `CAMP_003_PROGRESO.csv` blob `922ccad449b1c845f6fd04b2caa0f425e501bc22`, commit de pruebas/progreso `d3a9ce8bee76564a18cc5e997cdcd0bef5dd5c74`. **CI [#41559647462](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559647462) EN EJECUCIÓN** al redactar; consultar run y logs `CAMP003_W03_PY PASS blocks=5 checks=M` / `CAMP003_W03_GODOT PASS blocks=5 checks=M` antes de certificar.
- **Informe:** [CAMP_003_ITER_05.md](./CAMP_003_ITER_05.md), publicado. La revisión estructural de 5 bloques pasó; no equivale a ejecución. Solo IA6 consolida CI; W03 no cambia workflows, producción, `main`, V28, catálogo, otras ramas.
- **Al siguiente `p`:** verificar CI de 05 sobre SHA `d3a9ce8...`; si PASS, 06 `friend_ball;heal_ball`. Si falla test propio, corregir SIN quitar aserciones; fallo real motor/contrato compartido → STOP y solicitar IA6.

---

## Histórico previo conservado (01–04)

# IA3/W03 — CONTINUIDAD ACTUAL CAMPAÑA_003: 04/10

**Rama exclusiva:** `codex/calvo-items-20261103-w03-camp003`. **Progreso acumulativo:** cuatro bloques publicados (01 Poké/Gran, 02 Ultra/Master, 03 Quick/Timer, 04 Level/Nest). **Siguiente tecla `p`: exactamente 05 `fast_ball;dream_ball`, tras leer último run.** No ejecutar 06 sin nueva `p`.

## Estado verificado al publicar 04
- **Bloques 01–03 con CI real PASS:** [#41556927911](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556927911), SHA de pruebas `5ec49e9290a3eba5230c7eb9b96e69a4b16ff4d9`: Python `blocks=3 checks=88`, Godot `blocks=3 checks=317`.
- **Bloque 04 de Level/Nest:** Nivel Ball factor ×1/×2/×4/×8 según nivel activo vs objetivo, cap 255/tasa de especie; Nest factor max((41−nivel objetivo)/10,1), sin necesitar nivel del capturador. Se reutiliza producción existente: ningún multiplicador nuevo. Probadas por GDScript propuesto 2 especies (Mew/Caterpie) × 2 modos PS y umbrales. Nivel activo inválido `-1,0,101` debe rechazar `capture_active_level_context_missing` sin RNG/consumo.
- **Fuente fiable:** `WildAdventureSession.capture_current` y `ShowdownAdventureSession.capture` pasan `catcher.level` al contexto real. No crear reloj/contador ficticio ni modificar `CaptureBattleContext`.
- **Suite acumulativa y blobs de pruebas:** fixture `1dc12e0190c848c0f25079df81d208ac875bd56d`, runner Godot `3e7180db53076ebe0cb26e9d8bd9279ea05d58cd`, Python `6fce102ddf72cbc4da61e8e1a63894892a16be93`. Se preservaron funciones y entradas 01–03; `CAMP_003_PROGRESO.csv` contiene exactamente 04 filas. `CAMP_003_ITER_04.md` describe pruebas y límites.
- **Commit de activación CI:** `34d963e5c0cab2c840189b24a6c447353a4dd5db`, run [#41558471582](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41558471582) **CI SUCCESS VERIFICADA**. Esta rama puede tener commits documentales posteriores sin reejecución de tests. **Resultado comprobado del job 125663365696:** `CAMP003_W03_PY PASS blocks=4 checks=122`, `CAMP003_W03_GODOT PASS blocks=4 checks=490`, ambas puertas IA6 PASS. Commit de pruebas `34d963e5c0cab2c840189b24a6c447353a4dd5db`. Para dictaminar PASS, buscar el run cuyo SHA sea el de CSV/test indicado, con logs `CAMP003_W03_PY PASS blocks=4 checks=M` y `CAMP003_W03_GODOT PASS blocks=4 checks=M`.
- **Estado de validación:** revisión estructural en GitHub OK; **nueva CI con PASS verificado sobre SHA de pruebas**. Si falla un assert propio, corregir únicamente test/fixture/cuaderno sin eliminar cobertura; si el motor compartido falla, STOP y solicitud a IA6.
- **Seguridad:** sólo escrituras de W03 en runner/fixture/Python/progreso/reports de esta rama. `main`, V28, producción, `.github`, catálogo canónico, otras W y árbitra intocables. IA4 opera por adenda independiente.

---

## Histórico anterior conservado

# IA3/W03 — CAMPAÑA_003: estado actual 03/10

**Rama de trabajo exclusiva:** `codex/calvo-items-20261103-w03-camp003`. **Progreso:** 03/10 publicados, solo auditoría/contratos/tests. **Siguiente `p`: exactamente bloque 04 `level_ball;nest_ball`**, no ejecutar 05 sin orden posterior.

## Resultados verificables
- **01 Poké/Gran:** CI corregida [#41555095544](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555095544) `success`, Python 31, Godot 56.
- **02 Ultra/Master:** CI [#41555590257](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555590257) `success`, Python 56, Godot 108. La primera CI 01 había fallado por un literal de `quit` en el validador Python, corregido sin reducir cobertura en `70fb7f7a...`. Los informes anteriores contienen el histórico; no confundirlo con fallo del motor.
- **03 Quick/Timer:** IDs exactos de fila 03 `quick_ball;timer_ball`. Factores canónicos de `capture_context_ball_effects.gd`: Quick ×5 solo al turno 0, ×1 después; Timer `min(1+0.3*turnos,4)`, tope a 10. Fuente de turnos: `WildAdventureSession.capture_current` y `ShowdownAdventureSession.capture` desde estado de batalla real; el contexto default -1 debe rechazar, nunca bonificar. No se tocó ningún módulo ni catálogo.
- **Suite acumulativa 03**: `tests/fixtures/parallel_items/w03_campaign_003.json` blob `71fe990cbe8fb9a77c72c035439e19df79272b2f` (turnos 0,1,3,9,10,11, valores inválidos -1,-2); `tests/gameplay/parallel_items_w03_campaign_003.gd` blob `0dadec944cde62080431cc386c3b1926d0765d16` (captura RNG/coste/propiedad y negativos); `tests/tools/test_parallel_items_w03_campaign_003.py` blob `d46f87697164237442eef999cc5ab08b00cf3e86` (fuentes de contexto + contratos; 01/02 preservados).
- **Commit CSV de 03:** `5ec49e9290a3eba5230c7eb9b96e69a4b16ff4d9`, nueva ejecución automática [#41556927911](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556927911) **CI SUCCESS CONFIRMADA en SHA de pruebas `5ec49e9290a3eba5230c7eb9b96e69a4b16ff4d9`: Python 88 checks PASS y Godot 4.7 317 checks PASS (0 errores)**. El contrato original exigía `CAMP003_W03_PY PASS blocks=3 checks=M` y `CAMP003_W03_GODOT PASS blocks=3 checks=M`. Los logs del job #125658043378 confirman `CAMP003_W03_PY PASS blocks=3 checks=88`, `CAMP003_W03_GODOT PASS blocks=3 checks=317` y ambas puertas IA6 PASS. El estado `EN_CI_AUTOMATICA` del CSV es histórico al publicar la prueba; no se modifica CSV para evitar lanzar CI redundante.
- **Informe** [ITER03](./CAMP_003_ITER_03.md); CSV de progreso `CAMP_003_PROGRESO.csv` con exactamente 3 filas. Los estados anteriores `EN_CI_AUTOMATICA` son estados de publicación, no veredictos definitivos.
- **Siguiente `p`:** comprobar gate/CSV/última CI. Si PASS, ejecutar únicamente 04 `level_ball;nest_ball`; si fallo de test propio, reparación sin reducir pruebas; si motor compartido, detenerse y solicitar IA6. 10/10 STOP.
- **Prohibiciones:** `main`, V28, `.github/`, `modules/`, `data/`, `config/`, catálogo, guardados, árbitra y ramas ajenas; IA4 adenda independiente y fuera de este trabajo.

---

## Historial anterior conservado

ACTUALIZACION CI BLOQUE 02: #41555590257 SUCCESS, SHA c48c62f5fb662dba9480327faa432afe56860adf. Recibos: Python blocks=2 checks=56 PASS y Godot blocks=2 checks=108 PASS. No hubo cambio de produccion. El CSV refleja el estado EN_CI_AUTOMATICA al publicar; el veredicto posterior real es PASS.

# IA3/W03 — CAMPAÑA_003: continuidad actualizada a 02/10

**Rama única:** `codex/calvo-items-20261103-w03-camp003`. **Progreso:** dos bloques publicados: `01 poke_ball;great_ball`, `02 ultra_ball;master_ball`. Solo auditoría/contratos/test; prohibido producción, otros IDs o ramas. **Próximo `p`: exactamente 03 quick_ball;timer_ball.**

**01 — CI verificada tras reparación de propio test:**
- `6e5db746...` publicó primer test; [#41553752377](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41553752377) FAIL en validador Python (literal de `quit` incorrecto; Godot no corrió).
- Commit de reparación exclusiva `70fb7f7a2746abbdbd7fd70b3b95e65fef07d704`: exige `if errors.is_empty()`, `quit(0)` y `quit(1)` sin falsos negativos de sintaxis; no quita casos.
- [#41555095544](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555095544), SHA `70fb7f7a...`: **completed/success**, `CAMP003_W03_PY PASS blocks=1 checks=31`, `CAMP003_W03_GODOT PASS blocks=1 checks=56`. Es evidencia funcional acotada a casos testados de Poké/Gran.

**02 — pruebas publicadas, CI automática por verificar:**
- Fixture `tests/fixtures/parallel_items/w03_campaign_003.json`, commit `479e90c43e8bea3225ea68a7a947454ef6627320`: 01 preservado + 02 `ultra_ball;master_ball`, tres especies, dos estados de PS y negativos.
- Godot `tests/gameplay/parallel_items_w03_campaign_003.gd`, commit `248b62289d5c90f0e115ccc7e78ff55f9f98ce96`: Ultra ×2 (un coste y una tirada), Master garantizada (un coste, RNG sin cambiar), propiedad de equipo/PC, intentos inválidos sin gasto. Bloque 01 inalterado.
- Python `tests/tools/test_parallel_items_w03_campaign_003.py`, commit `cf266efa94bcfe7080d0efcb12d27ddf67207beb`: mantiene contratos 01 y añade reglas 02 de tabla canónica y motor.
- Progreso `CAMP_003_PROGRESO.csv`, commit `c48c62f5fb662dba9480327faa432afe56860adf`: dos filas, 02 `EN_CI_AUTOMATICA`, SHA de blob runner.
- Informe técnico [ITER02](./CAMP_003_ITER_02.md). Última CI nueva al escribir: [#41555590257](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555590257) sobre `c48c62f5...` **SIN PASS CONFIRMADO**. No atribuirle éxito sin consultar run y salida estricta `blocks=2` en Python/Godot. Cancels de commits intermedios no son fallos funcionales.

**Orden al recibir `p`:** leer primero Gate003, orden `CAMP_003_W03.md`, rama HEAD y CSV real, último run CI; si FAILED por test propio reparar sin reducir cobertura, si falla producción/guardado STOP a IA6. Si CI completed/success o pending y bloque independiente, crear solo 03 `quick_ball;timer_ball`, sin borrar 01/02. Nunca ejecutar 04 sin otro `p`; 10/10 STOP.

**No tocar:** main, V28, `.github/workflows`, `modules/`, `data/`, catálogo, árbitra, W01/W02/W04/W05, ramas antiguas. IA4 ha sido reincorporada únicamente bajo su adenda separada, no cambia esta cola.

---

## Archivo histórico preservado: estado tras bloque 01

# IA3/W03 — Cuaderno actual CAMPAÑA_003 (solo esta rama)

**IDENTIDAD:** IA3/W03. **RAMa exclusiva:** `codex/calvo-items-20261103-w03-camp003`. **ESTADO:** 01/10 publicado; `EN_CI_AUTOMATICA` al publicar. **Puntero oficial:** `CAMPAIGN_GATE_003.md`, manifiesto, cola aprobada, `campaigns/CAMP_003_W03.md` en árbitra. **Nunca leer el cuaderno heredado CAMP001 como orden vigente.**

- Bloque 01: `poke_ball;great_ball`, ya implementadas. No reescribir multiplicadores ni duplicar matriz V11. Cobertura nueva = paridad con mismo objetivo/semilla/PS en tres especies, dos niveles de PS, coste y RNG, dos negativas.
- Archivos propios: `tests/gameplay/parallel_items_w03_campaign_003.gd` blob `a6f777a43d2a813df59e86788d3f30d52a593875`, `tests/tools/test_parallel_items_w03_campaign_003.py` blob `15ac200cdfdb13aa31e0494399ca9ee0647ff93d`, `tests/fixtures/parallel_items/w03_campaign_003.json` blob `59d16be0559b956ead0d6f18d9c3729ad0815287`, informe `CAMP_003_ITER_01.md` y CSV `CAMP_003_PROGRESO.csv`.
- Contrato CI: `CAMP003_W03_PY PASS blocks=N checks=M` y `CAMP003_W03_GODOT PASS blocks=N checks=M`; ambos requieren N igual a número de filas CSV. El workflow `.github/workflows/parallel-camp003-worker-autoci.yml` ya es propiedad de IA6. Primer run de bootstrap 0 bloques [#41551961372](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41551961372) SUCCESS **NO cuenta como verificación funcional**.
- **Verificación presente:** código existente inspeccionado en GitHub. **Nuevo Python y Godot SIN_EJECUTAR hasta CI propia del commit 01**; consultar resultado al siguiente `p`. Si CI FAIL, arreglar solo test propio sin eliminar controles o STOP ante producción/contrato compartido.
- **Siguiente bloque ya asignado:** 02 `ultra_ball;master_ball`. Se añade una fila, fixture/script/test acumulativos, sin borrar 01. Nunca más de un bloque por `p`. Límite 10/10 STOP, no cuarta campaña automática.
- **Escritura autorizada:** solo `tests/gameplay/parallel_items_w03_campaign_003.gd`, `tests/tools/test_parallel_items_w03_campaign_003.py`, `tests/fixtures/parallel_items/w03_campaign_003.json`, `reports/W03/CAMP_003_ITER_XX.md`, `CAMP_003_PROGRESO.csv`, `CAMP_003_FINAL.md` y este cuaderno. **No tocar** producción, `modules/`, `data/`, `main`, V28, PR #118, workflows, manifest, árbitra, otras W, IA4 ni ramas anteriores.
