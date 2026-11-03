# IA2/W02 — CAMPAÑA_003 / BLOQUE 01 DE 10

**Estado:** `EN_CI_AUTOMATICA` hasta leer resultado de GitHub Actions para el primer commit con progreso publicado (`a278495a20345e86458d13e536198140d78ae5f9`). **No dar PASS funcional antes de ese run.**

**Identidad/rama:** IA2/W02, `codex/calvo-items-20261103-w02-camp003` (rama nueva de IA6, checkpoint inicial `41c1efeba0346349490f863131179ed7a8fc274c`). Cero merges de ramas antiguas.

**Autoridad:** `CAMPAIGN_GATE_003.md` blob `390f7ce6897462e1ae8e3cc7e3cd5f799b6c2213`, `CAMPAIGN_003_BRANCH_MANIFEST.md` blob `9b797b4d32fbab022e12d580e46b10f063f5690f`, cola oficial blob `ea06a0a000fc4f3b8bab48e45e21fb549d753559`, `campaigns/CAMP_003_W02.md` blob `62498ebd44288a86e59986379dbc1b70e111ef1f`.

## Cuatro IDs autorizados

| ID | Disparo positivo | Negativo de control | Fuente previa |
|---|---|---|---|
| `aguav_berry` | PS 1/5, naturaleza Naughty rechaza sabor amargo: cura 1/3 y confunde | naturaleza Hardy cura sin confusión; PS altos retienen | `held_effect_sweep_v3.cjs` (perfil sabor/naturaleza) |
| `apicot_berry` | PS 1/5 y defensa especial +1, consumo | PS casi máximos, sin subida ni consumo | `held_effect_sweep_v2.cjs` (`pinch_stat_berry`) |
| `aspear_berry` | `freeze` cura y consume | Pokémon sano conserva objeto | `held_effect_sweep_v2.cjs` (`status_berry`) |
| `babiri_berry` | Clefable recibe `flash_cannon` de Acero supereficaz, reduce daño | `tackle` no Acero, daño igual y sin gasto | `held_effect_sweep_v2.cjs` (`resist_berry`) |

**Matriz nueva:** 9 escenarios, 3 variantes por escenario (`active`, `none`, `reserve`), **27 ejecuciones nativas previstas**, consumo de una única unidad, posición de objeto, captura de eventos `|-start|confusion` / `|-boost|spd`, `battle.snapshot`, restauración SaveV2, cierre FLED, recibos JSON con SHA256.

**Reutilización, no duplicación de funcionalidad:** ejecuta el motor nativo existente `@pkmn/sim` mediante `item_automation_opponent_v28.gd`, `FieldItemService.equip` y helper SaveV2 de V28; no crea callbacks ni toca producción. Los scripts históricos fueron leídos **solo como contratos** y no se sobrescribieron.

**Entregables W02 exclusivos:**
- `tests/fixtures/parallel_items/w02_campaign_003.json`, commit `da00c3ab3565d46d42000e1a9f21c399bbc9270d`.
- `tests/gameplay/parallel_items_w02_campaign_003.gd`, commit `a580fb13d27e074f5d847ce491bac04bd0128d76`.
- `tests/tools/test_parallel_items_w02_campaign_003.py`, commit `3c8f2808a2011803b0450fd3d3a10726a4be0374`.
- `reports/W02/CAMP_003_PROGRESO.csv`, bloque `01` añadido commit `a278495a20345e86458d13e536198140d78ae5f9`.

**Prueba CI actual:** [GitHub Actions #41553745691](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41553745691), inicialmente `queued` sobre commit con 1 fila. Recibos esperados `CAMP003_W02_PY PASS blocks=1 checks=M` y `CAMP003_W02_GODOT PASS blocks=1 checks=M`; Godot 4.7/Node22. **No confundir los SUCCESS previos de bootstrap 0 bloques con funcionalidad.**

**Límites:** solo objetos equipados, no uso de campo, sin GPU/visual ni doble combate. Campo sin contrato = no activar. Las reservas de CAMP001/CAMP002 permanecen excluidas. `main`, V28, PR #118, ramas W, catálogo y guardados reales intactos.

**Siguiente `p`:** únicamente bloque 02, `charti_berry`, `chilan_berry`, `chople_berry`, `coba_berry`, si la CI reciente es success o continúa con pruebas independientes; FAIL funcional exige STOP/ticket a IA6. Límite absoluto 10/10.
