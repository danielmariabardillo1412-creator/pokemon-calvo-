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
