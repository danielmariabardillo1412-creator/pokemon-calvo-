# IA1/W01 — CAMPAÑA_003, microbloque 03/10

**Estado al publicar:** `EN_CI_AUTOMATICA`. Rama exclusiva `codex/calvo-items-20261103-w01-camp003`. Fila exacta IA6/W01/03 de `CAMPAIGN_003_QUEUE_APPROVED.csv`: **`clear_amulet;covert_cloak;eject_button`**. No se modificó producción.

## Evidencia anterior e integración nueva

| Objeto | Referencia histórica de verdad | Casos bloque 03 | Aserciones causales en Godot |
|---|---|---|---|
| `clear_amulet` / Amuleto Puro | `held_effect_sweep_v2.cjs`, `opponent_drop_protection` con `charm` | `amulet_charm_block` (19,23), `amulet_no_drop` (19) | El portador mantiene `boosts.atk=0` frente a descenso en control y reserva; control con Amnesia y retención |
| `covert_cloak` / Capa Furtiva | `held_effect_sweep_v2.cjs`, `secondary_protection` con `nuzzle` | `cloak_nuzzle_secondary` (19,23), `cloak_plain_hit` (19) | Con Nuzzle conserva daño, pero solo el portador evita la parálisis secundaria; golpe Normal no introduce protección o consumo espurio |
| `eject_button` / Botón Escape | `ITEM_INVENTORY.csv`, estado `HELD_PILOT_VERIFIED` y callback `onAfterMoveSecondary` | `eject_on_hit` (19,23), `eject_without_hit` (19) | Daño Normal solicita `forceSwitch` solo al portador, con consumo de una unidad y reserva intacta; Amnesia no solicita cambio ni consume |

Los tres están `SELECCIONADO` en `RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`. Esa selección no se usa como prueba de funcionamiento. No se han duplicado los hooks; la ejecución usa `FieldItemService`, `Native`, motor `@pkmn/sim`, SaveV2 y los controles `active/none/reserve`.

## Archivos de pruebas acumulativas

- `tests/fixtures/parallel_items/w01_campaign_003.json`: seis casos nuevos, nueve pares caso-semilla, 27 variantes. Se añade fuente `held_effect_sweep_v2.cjs` con Git blob `c9ba4d7bcddad6ae69f085f4b69983461ad05219`. Commits de fixture `07cf8c0e2dc47e08421d3de703bcf6b643f4b70c` y fuente `030640e6e7ccd885ae53cd225e18d936361bdd56`. Blob final `ed56adf7dc77bf01699e4690cec490b2def1b227`.
- `tests/gameplay/parallel_items_w01_campaign_003.gd`: reutiliza todos los casos 01/02, observa `boosts.atk`, estado persistente, daño y `request.forceSwitch` del checkpoint; gestiona solicitud de cambio sin asumir presencia de `request.active[0]`; mantiene _restore_probe y comprobación de propietario/stock. Commit `5b74e242d718365205a6e9d980cf475d18b8637d`, blob `01a0a37409a072066e0d5aa58a4d39aebe490ff0`.
- `tests/tools/test_parallel_items_w01_campaign_003.py`: `SCENARIOS_03` fija los seis casos, las semillas exactas, especie rival, movimiento y operación; consulta fuentes V2 y piloto existentes y exige conteos acumulativos. Commit `8bc3a2dc4941013c604a410e6cea6e7c78c62fb0`, blob `e167965856f062fa149fd1d6ce368d8b62eb3e9e`.
- `CAMP_003_PROGRESO.csv`: fila 03 `EN_CI_AUTOMATICA`, fila 02 `CI_PASS_VERIFICADO` por [#41555559263](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555559263). Commit disparador `4bacfd05b82296eadd5767f871082e2cc8692b14`.

**Acumulado:** 21 escenarios (7+8+6), 37 pares caso-semilla (10+18+9), 111 variantes (30+54+27). Auditoría estructural de los blobs GitHub: **18/18 PASS**, pero NO confirma la ejecución Godot del bloque 03.

## CI y límites

- Bloque 02: [#41555559263](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555559263) `completed/success` tras corregir tope de semillas. Runs intermedios cancelados por `concurrency.cancel-in-progress` no son fallos funcionales.
- CI del nuevo bloque: [#41556859548](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556859548), SHA `4bacfd05b82296eadd5767f871082e2cc8692b14` en estado `pending` al redactar. La salida aceptable exige `CAMP003_W01_PY PASS blocks=3 checks=M` y `CAMP003_W01_GODOT PASS blocks=3 checks=M`, con M positivo y exit code 0. No atribuir PASS al run en cola.
- Si hay FAIL de script: corregir solamente tests W01 sin quitar la aserción causal. Si hay defecto del simulador, SaveV2 o dependencia compartida, STOP y ticket IA6. No tocar producción o workflow.
- Headless no certifica UI/GPU, regreso a mapa, liquidación de resultado, todas las combinaciones RNG ni todos los eventos secundarios.

**Próxima `p`:** verificar este último run; solo entonces el microbloque 04/10, IDs `eject_pack;electric_seed;focus_band`, si no hay fallo real. No adelantar tareas ni crear iteración 11.
