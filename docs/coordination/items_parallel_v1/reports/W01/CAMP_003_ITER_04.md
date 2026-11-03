# IA1/W01 — CAMPAÑA_003, microbloque 04/10

**Rama exclusiva:** `codex/calvo-items-20261103-w01-camp003`. **Estado al publicar:** `EN_CI_AUTOMATICA`, sin PASS del bloque nuevo. **Asignación exacta IA6:** W01/04 = `eject_pack;electric_seed;focus_band` (objetivo `evento_y_propietario`), `CAMPAIGN_003_QUEUE_APPROVED.csv`. Las tres entradas del catálogo de selección son `SELECCIONADO` y tienen `native_entry=True`, sin que esto signifique funcionalidad nueva.

## Cobertura histórica y nuevas pruebas causales

| Objeto | Referencia de motor ya existente | Positivo | Negativos / SaveV2 |
|---|---|---|---|
| Mochila Escape, `eject_pack` | `held_effect_sweep_v3.cjs`: `self_drop` con `close_combat` y `no_drop`; evento nativo `onAfterBoost` y relacionados | Descenso de Defensa por A Bocajarro y `request.forceSwitch` solo en portador, gasto de una unidad | Movimiento `tackle` sin descenso no fuerza cambio ni consume; ausencia y reserva no activan; restauración de checkpoint y stock |
| Semilla Electro, `electric_seed` | `held_effect_sweep_v3.cjs`: `terrain_mew` con `electric_terrain`, `boosts.def=1` y `wrong_terrain` | Campo Eléctrico lanzado por rival activa +1 Defensa y consume, solo en portador activo | `misty_terrain` o Amnesia no activan; ausencia/reserva y SaveV2 |
| Cinta Aguante, `focus_band` | `held_effect_sweep_v3.cjs`: `survival_rng` con `seismic_toss`, objeto **no consumible** | Actor a 1 PS antes de golpe letal de daño fijo; 24 semillas distintas. Exigir al menos **una** supervivencia efectiva a 1 PS y evento `item: Focus Band` en log, controles sin objeto/reserva a 0 PS | Golpe no letal nunca activa; el objeto se conserva en todos los modos, incluso al salvar 1 PS; checkpoint SaveV2 comparado con estado nativo |

**Casos añadidos:** 7 (2 Mochila, 3 Semilla, 2 Cinta); **32 pares caso-semilla**, de los cuales 24 corresponden a intento letal con Cinta Aguante. **96 variantes** del bloque en modos `active`, `none`, `reserve`. **Acumulado:** 28 casos, 69 pares caso-semilla, 207 variantes. Los 21 casos de bloques 01..03 permanecen intactos.

## Blobs, commits y límites

- Fixture `tests/fixtures/parallel_items/w01_campaign_003.json`, commit `4e6564228190cb6e58e44dbacd49bcc3a2ef8d04`, blob `7a5823b7708362b0baadb37b10bfe4a5361a89ca`.
- Runner `tests/gameplay/parallel_items_w01_campaign_003.gd`, commit `b7a8c7387b7cbcc5108ba709a473d0f47e00de9b`, blob `e725f365d510ec8ba7e056eb7399a99ba8c9b7c0`. Observa boosts, `forceSwitch`, HP, activación nativa de Cinta, consumo/stock y SaveV2; **no contiene callbacks implementados**.
- Contrato Python `tests/tools/test_parallel_items_w01_campaign_003.py`, commit `68eaa186650adac748a0b37404aa0f8a427bb195`, blob `6529a2eaa045abd702bda30eb38049e9e36fea85`. Revisa fuentes nativas V3, orden de la cola y listas exactas de semillas, sin extrapolar resultados nativos.
- CSV `reports/W01/CAMP_003_PROGRESO.csv` actualizado a 04/10, disparador CI commit `ead4ab776703028c6289cebf182465d3a5306efc`. El bloque 03 se cambió a `CI_PASS_VERIFICADO` tras [Actions #41556859548](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556859548), SUCCESS: Godot `3217` checks en 3 bloques y Python PASS.
- Auditoría estructural de blobs GitHub: **18/18 invariantes PASS**; NO equivale a nueva ejecución Godot 04 ni garantiza supervivencia aleatoria.
- CI nueva: [Actions #41558549785](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41558549785), SHA `ead4ab776703028c6289cebf182465d3a5306efc`: `in_progress` al redactar. El workflow IA6 requiere `CAMP003_W01_PY PASS blocks=4 checks=M` y `CAMP003_W01_GODOT PASS blocks=4 checks=M`; no declarar PASS sin ambos. Los runs intermedios se cancelaron por `concurrency.cancel-in-progress`.

**Limitaciones:** RNG medido en 24 semillas fijadas, no demostrado 10% estadístico; no sustituye totalidad de los estados de combate, limpieza al mapa, otros climas, Trick, UI/GPU ni pruebas manuales. Si hay FAIL de test, corregir solo test propio sin reducir sus controles; si es defecto/dependencia compartida, STOP y pedir IA6. No tocar `main`, V28, `modules/`, `data/`, catálogo o ramas ajenas.

**Siguiente `p`:** comprobar primero CI del último SHA; si no hay fallo real, ejecutar **solo bloque 05/10**, `flame_orb;focus_sash;grassy_seed` según cola. No iniciarlo en el bloque actual.
