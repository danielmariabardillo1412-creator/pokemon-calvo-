# IA2/W02 — CAMPAÑA_003 / BLOQUE 05 DE 10

**Entrega:** bloque 05 publicado, `EN_CI_AUTOMATICA` hasta resultado real de GitHub Actions. Rama única `codex/calvo-items-20261103-w02-camp003`. No se modificó producción, selección, ramas ajenas ni workflow.

**Autoridad:** `CAMPAIGN_GATE_003.md`, `CAMPAIGN_003_QUEUE_APPROVED.csv` (blob `ea06a0a000fc4f3b8bab48e45e21fb549d753559`), `campaigns/CAMP_003_W02.md` (blob `62498ebd44288a86e59986379dbc1b70e111ef1f`). La reincorporación de W04 no altera la cola W02.

## Cuatro objetos, ocho escenarios

| Baya | Positivo | Negativo | Contrato nativo previo |
|---|---|---|---|
| `kebia_berry` | Clefable recibe `sludge_bomb` Veneno supereficaz: reduce daño y consume | `tackle` Normal no consume ni modifica daño | `held_effect_sweep_v2.cjs`, tabla `resist.poison` |
| `kee_berry` | Ataque físico `tackle` desencadena `+1 Def` en el portador y consume | Ataque especial `confusion`, no dispara | `held_effect_sweep_v2.cjs`, `reactive_stat_berry` |
| `lansat_berry` | Al 20 % PS aparece `focusenergy` nativo y consume | PS casi máximos, sin volatile ni consumo | `held_effect_sweep_v3.cjs`, `critical_focus` |
| `liechi_berry` | Al 20 % PS aumenta Ataque (`|-boost|p1a:...|atk|`) y consume | PS casi máximos, ni boost ni consumo | `held_effect_sweep_v2.cjs`, `pinch_stat_berry` |

**Diseño del ensayo:** para los ocho casos se configura movimiento propio `amnesia` en lugar de `swords_dance`, evitando atribuir a Liechi una subida de Ataque causada por el movimiento. Los registros de subidas comprueban explícitamente `p1a` para no confundir al enemigo con el portador. Se distinguen categoría física/especial y estado crítico persistente. No se implementan efectos.

**Integración:** `active`, `none`, `reserve`, transacción real de Godot 4.7 + simulador nativo `@pkmn/sim`, propiedad de objeto, consumo exactamente de una unidad, persistencia SaveV2 y revisión de checkpoint, cierre FLED, no doble gasto, recibos JSON por escenario y SHA256. Se conservan los cuatro bloques anteriores.

**Cobertura esperada acumulada:** bloques 01–05: **42 escenarios** (9+8+8+9+8) de 20 bayas distintas; **126 variantes** (42×3). Son planes de test, no una afirmación de PASS del nuevo bloque hasta revisión CI.

**Contratos Python:** `EXPECTED_05` fijo con ocho escenarios y requisitos individuales (tipo, PS, ataque, consumo, volatile, movimiento del portador), comprobación de precedentes V2/V3 y diez mutaciones adversariales nuevas que deben ser rechazadas. Los controles anteriores no se reducen.

**Commits de contenido:**
- `tests/fixtures/parallel_items/w02_campaign_003.json` commit `4ef4dae9861d422c1d940a2e3dc67c90f2170db0`.
- `tests/gameplay/parallel_items_w02_campaign_003.gd` commit `829d52379bb90bb99ddc10631e400c9961aa1024`.
- `tests/tools/test_parallel_items_w02_campaign_003.py` commit `78edab9ff8df12ee202552ca55642ccb7503d9af`.
- `docs/coordination/items_parallel_v1/reports/W02/CAMP_003_PROGRESO.csv` quinta fila commit `fd6fd0b6a40b2e5a0780607d268c9eb60d51204f`.

**CI anterior verificable:** [#41558465659](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41558465659), `completed/success`, SHA `1e1e71d9c29bf00e764f5fe6039a8648feed1f46`. `CAMP003_W02_PY PASS blocks=4 checks=256`; `CAMP003_W02_GODOT PASS blocks=4 checks=2925`. **No certifica este bloque 05.**

**CI automática del bloque 05:** [#41559377763](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559377763), primer SHA con quinta fila `fd6fd0b6a40b2e5a0780607d268c9eb60d51204f`. Recibos exigidos `CAMP003_W02_PY PASS blocks=5 checks=M` y `CAMP003_W02_GODOT PASS blocks=5 checks=M`. Al redactar, `pending`; no inventar un PASS. Los runs de commits intermedios cancelados por concurrencia no equivalen a fallos.

**Límites:** objetos EQUIPADOS únicamente; campo sin contrato no probado, visual/GPU no certificados. Prohibido escribir `main`, V28, PR #118, catálogo, `modules/`, `data/`, `config/`, workflow, IA6 y ramas ajenas. Ante FAIL del test propio reparar sin bajar expectativas; fallo de motor/SaveV2 compartido → STOP y solicitar IA6.

**Próxima `p`:** únicamente bloque 06 `mago_berry;maranga_berry;micle_berry;occa_berry`, revisando previamente la CI actual. Ningún bloque 07 o superior por esta orden.
