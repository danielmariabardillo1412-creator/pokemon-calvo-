# IA2/W02 — CAMPAÑA_003 / BLOQUE 06 DE 10

**Estado:** `EN_CI_AUTOMATICA` hasta los recibos reales del SHA de progreso `e1bd985da220fcff2578be97cd4de4f53167b1af`. **No atribuir PASS a bloque 06 basándose en pruebas previas.** Rama W02 exclusiva `codex/calvo-items-20261103-w02-camp003`.

**Fuente de autorización:** `CAMPAIGN_003_QUEUE_APPROVED.csv` blob `ea06a0a000fc4f3b8bab48e45e21fb549d753559`, asignación `campaigns/CAMP_003_W02.md` blob `62498ebd44288a86e59986379dbc1b70e111ef1f`. Solo cuatro bayas de fila 06, sin tocar producción.

## Cuatro IDs, nueve escenarios nuevos

| Baya | Disparo y prueba positiva | Negativo | Precedente nativo |
|---|---|---|---|
| `mago_berry` | PS al 20%, Brave rechaza el sabor y confunde; Hardy cura sin confusión. Recupera `floor(maxHP/3)` | PS casi máximos con Brave, no se gasta ni cura | `held_effect_sweep_v3.cjs` (Mago-Brave, rechazo de sabor) |
| `maranga_berry` | Mew recibe `confusion` especial, gana +1 Defensa Especial (`p1a`) y consume | Ataque físico `tackle`, sin aumento ni gasto | `held_effect_sweep_v2.cjs` (`reactive_stat_berry`) |
| `micle_berry` | PS al 20%: primer turno `reflect`, produce volatile nativa `micleberry`; restaurar checkpoint, siguiente turno `hydro_pump` utiliza y elimina la volatile | PS casi máximos, sin volatile ni consumo; segundo movimiento todavía ejecutado | `held_effect_sweep_v3.cjs` (`next_move_accuracy`, `full_hp`) |
| `occa_berry` | Scizor recibe `flamethrower` supereficaz y reduce daño con consumo | `tackle` Normal, sin activación ni reducción | `held_effect_sweep_v2.cjs` (`resist.fire`) |

**Micle es de efecto diferido:** no basta con observar `held_item_consumed`. Se inspecciona `session._checkpoint.roster[].pokemon[].volatiles` del **motor nativo** para el ID real `own`, antes y después de restaurar el checkpoint y después de ejecutar el segundo movimiento. Se exige presencia de `micleberry` únicamente en `active` y PS bajos, persistencia en el checkpoint restaurado y desaparición tras `hydro_pump`. Se registra el movimiento nativo `|move|p1a:...|Hydro Pump|`. **No se afirma tasa de acierto mejorada con un solo intento**; el sweep V3 histórico prueba el efecto de precisión sobre múltiples semillas.

**Se reutiliza** `@pkmn/sim`, las sesiones `item_automation_opponent_v28.gd`, servicio existente de equipamiento, checkpoints reales y SaveV2; no se añaden nuevas mecánicas de bayas. Se emplean controles de portador `active/none/reserve`, dos unidades físicas, gasto atómico, restauración real y FLED sin doble liquidación, comprobaciones SHA256 de recibos.

**Suite acumulativa:** 9 + 8 + 8 + 9 + 8 + 9 = **51 escenarios**, **153 variantes de combate previstas**, **24 IDs de bayas distintos**; los 42 casos de los cinco primeros bloques siguen íntegros. Python exige `EXPECTED_06` exacto y 11 mutaciones adversariales nuevas (naturaleza, umbral, tipo físico/especial, siguiente movimiento y objeto fuera de reserva).

**Commits del bloque 06:**
- Fixture `tests/fixtures/parallel_items/w02_campaign_003.json` — `66fbae22a05e84326fdbf9b6a21e9a886238f42e`.
- Runner `tests/gameplay/parallel_items_w02_campaign_003.gd` — `744057924c583f0e73e8900ce4d89b71f19cbd07`.
- Validador `tests/tools/test_parallel_items_w02_campaign_003.py` — `e0791b6d88b680b06bfc8fd5436532adf0e0bcc6`.
- CSV de progreso — `e1bd985da220fcff2578be97cd4de4f53167b1af`.

**CI bloque 05 anterior: REAL PASS.** [#41559377763](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559377763) `completed/success` sobre `fd6fd0b6a40b2e5a0780607d268c9eb60d51204f`; recibos `CAMP003_W02_PY PASS blocks=5 checks=327` y `CAMP003_W02_GODOT PASS blocks=5 checks=3612`. No cubre el bloque 06.

**CI bloque 06:** [#41560377509](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41560377509), SHA tests/progreso `e1bd985da220fcff2578be97cd4de4f53167b1af`; exige `CAMP003_W02_PY PASS blocks=6 checks=M` y `CAMP003_W02_GODOT PASS blocks=6 checks=M`. La primera observación fue `pending`, no `PASS`. El cancelado de commits intermedios por `concurrency` no significa fallo funcional.

**Protecciones:** ningún cambio en `main`, V28, PR #118, otros trabajadores, IA6, producción, catálogo o workflow. Campo, interfaz, GPU no probados. Si CI falla por falso test, reparar solo el arnés W02 sin disminuir expectativas; fallo nativo/SaveV2 compartido → STOP, ticket IA6.

**Siguiente `p`:** solo bloque 07 de la cola `passho_berry;payapa_berry;petaya_berry;rindo_berry`. Consultar CI anterior y progreso; no ejecutar bloque 08 ni posteriores con esta `p`.
