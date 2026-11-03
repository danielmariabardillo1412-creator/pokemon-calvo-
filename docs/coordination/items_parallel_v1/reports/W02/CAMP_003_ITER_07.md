# IA2/W02 — CAMPAÑA_003 / BLOQUE 07 DE 10

**Estado:** `EN_CI_AUTOMATICA`, sin PASS real de los bloques 06 y 07 hasta nueva CI cumulativa. Rama exclusiva `codex/calvo-items-20261103-w02-camp003`. Un único bloque 07 autorizado, no 08.

**Autoridad:** `CAMPAIGN_003_QUEUE_APPROVED.csv` blob `ea06a0a000fc4f3b8bab48e45e21fb549d753559`; asignación `campaigns/CAMP_003_W02.md` blob `62498ebd44288a86e59986379dbc1b70e111ef1f`. El objetivo de la fila 07 es `passho_berry;payapa_berry;petaya_berry;rindo_berry`.

## Cuatro IDs exactos y ocho escenarios nuevos

| ID | Test positivo nativo | Test negativo | Fuente |
|---|---|---|---|
| `passho_berry` | Charizard recibe `surf` (Agua supereficaz), reduce daño y consume | `tackle` Normal: mismo daño, conserva baya | `tools/item_audit/held_effect_sweep_v2.cjs`, `resist.water` |
| `payapa_berry` | Gengar recibe `psychic` (Psíquico supereficaz), reduce daño y consume | `tackle` Normal: no reduce ni consume | `held_effect_sweep_v2.cjs`, `resist.psychic` |
| `petaya_berry` | Mew al 20 % de PS gana +1 **Ataque Especial** (`|-boost|p1a:...|spa|`), consume | PS casi máximos, sin subida ni consumo | `held_effect_sweep_v2.cjs`, `pinch_stat_berry`, `petaya_berry:'spa'` |
| `rindo_berry` | Blastoise recibe `energy_ball` (Planta supereficaz), reduce daño y consume | `tackle` Normal, no consume ni reduce | `held_effect_sweep_v2.cjs`, `resist.grass` |

**Antifalsos positivos:** los casos de Petaya usan **`amnesia` propio** como movimiento neutro respecto de Ataque Especial, para no atribuir al objeto un efecto del movimiento. El runner incorpora una variable distinta `boost_spa`, inspecciona exclusivamente `|-boost|p1a:` con `|spa|` y exige ausencia del mismo efecto en `none` y `reserve`. Verifica el campo `native_boost_spa` en recibos con SHA256.

**Reutilización:** el motor `@pkmn/sim`, equipamiento, SaveV2, checkpoint/restore y cierre FLED se ejecutan con el mismo arnés acumulativo. No se implementan nuevas mecánicas. Tres modalidades de propiedad por caso: `active/none/reserve`; consumo de unidad única, no efecto desde reserva, recibos JSON con SHA256. Campo, UI, GPU y pruebas visuales siguen excluidos.

**Contabilización:** acumulados 7 bloques, **28 IDs** (4×7), 9+8+8+9+8+9+8 = **59 escenarios**, **177 variantes de combate previstas**. Ocho escenarios nuevos, 24 variantes. El validador Python exige exactamente ocho contratos `EXPECTED_07`, cuatro pares positivo/negativo y **11 mutaciones adversariales adicionales** que deben rechazarse. Se mantienen los 51 escenarios previos.

**Entregables publicados solo en W02:**
- Fixture `tests/fixtures/parallel_items/w02_campaign_003.json`: commit `18a84e704a43240b66fe0d0265fe563eaff85ba8`.
- Runner `tests/gameplay/parallel_items_w02_campaign_003.gd`: commit `76fbf729fa843772e8bf5ba53f7d27d58fc20f9b`.
- Contratos Python `tests/tools/test_parallel_items_w02_campaign_003.py`: commit `96f2a528b8a81e5e7dbb5a81e4f60e864726c711`.
- Progreso `docs/coordination/items_parallel_v1/reports/W02/CAMP_003_PROGRESO.csv`: 7.ª fila, commit `d7820e1b2aecc5cff13f13f1c289609a22c3a9ad`.

## CI: distinguir PASS reales de cancelaciones

**Último resultado funcional CERTIFICADO:** [Actions #41559377763](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559377763) `completed/success`, **5 bloques**: Python 327 checks PASS, Godot 3612 checks PASS.

**Bloque 06:** [Actions #41560377509](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41560377509) acabó **`cancelled` por concurrencia durante ejecución nativa**, no es SUCCESS ni FAIL funcional. Sí se observó `CAMP003_W02_PY PASS blocks=6 checks=398` y `CAMP003_GATE_PY_PASS`. Godot NO EMITIÓ recibo PASS del 06. Por tanto **no se da por verificado**.

**Actual run para 06+07:** [Actions #41560981081](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41560981081), SHA de progreso `d7820e1b2aecc5cff13f13f1c289609a22c3a9ad`, inicialmente pendiente. Debe emitir **`CAMP003_W02_PY PASS blocks=7 checks=M` y `CAMP003_W02_GODOT PASS blocks=7 checks=M`** para acreditar que todos los efectos, incluido Micle de 2 turnos, funcionan sin regresiones. Si se cancela, no declarar PASS. Error de arnés propio: reparar sin relajar prueba. Fallo funcional en motor/persistencia compartidos: STOP y pedir intervención IA6.

**Siguiente `p`:** exclusivamente bloque 08 `roseli_berry;rowap_berry;salac_berry;shuca_berry`, previa consulta del último run y de la cola oficial. No tocar producción, `main`, V28, catálogo, workflow, ramas ajenas ni W04.
