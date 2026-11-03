# IA1/W01 — CAMPAÑA_003 · Microbloque 07/10

**Estado:** entregado con `EN_CI_AUTOMATICA`; PASS funcional de 07 todavía no acreditado. **Rama exclusiva:** `codex/calvo-items-20261103-w01-camp003`. Fila oficial IA6 W01/07: **`iron_ball;lagging_tail;light_clay`**. Sin cambios a producción ni arquitectura.

## Referencias previas y pruebas nuevas

| ID | Fuente nativa ya existente | Cobertura nueva, controles negativos |
|---|---|---|
| `iron_ball` — Bola Férrea | `held_effect_sweep_v3.cjs`: `speed_halved` y `grounded_flying_holder` | Charizard portador recibe Terremoto de Garchomp frente a control y reserva inmunes; Gengar portador mueve después de Garchomp a igual prioridad, sin objeto/reserva primero. Objeto no consumible |
| `lagging_tail` — Cola Plúmbea | `held_effect_sweep_v3.cjs`: `last_same_priority` y `priority_preserved` | Gengar con Cola Plúmbea actúa después de Snorlax usando Tackle, pero Ataque Rápido (+1 prioridad) sigue ocurriendo primero. Contraste activo/ausente/reserva y no consumo |
| `light_clay` — Refleluz | `held_pilot.cjs`: `reflect.duration` incrementado en tres turnos | Reflejo dura +3 turnos únicamente con portador; sin usar pantalla no se crea duración artificial. No se consume y el objeto en reserva no afecta |

Los tres están `SELECCIONADO` en el alcance canónico; esto solo autoriza probarlos, no implica implementación. Los escenarios leen **logs de orden de movimiento**, **PS de entrada ante Tierra** y **duración de `sideConditions.reflect`** desde el checkpoint real del motor, comparando los tres modos de propiedad. Cada caso mantiene SaveV2 y equivalencia de instantánea/stock al reabrir.

**Bloque 07:** 6 escenarios / 10 pares caso-semilla / 30 variantes. **Acumulado 01..07:** 48 escenarios / 99 pares / 297 variantes. Se preservaron los 42 escenarios anteriores.

## Commits y pruebas

- Fixture `tests/fixtures/parallel_items/w01_campaign_003.json`: commit `5c0b51ccebe9c8283294e8cb6792969b3ed888df`, blob `dde1e88b165fa1da854633ccb29e5fbf12f2f297`.
- Runner `tests/gameplay/parallel_items_w01_campaign_003.gd`: commits `1686d40c769dd6d4b1a8194a9b635fae5568c1af` y `d0a724aa3a4aad81e6c4c6288bd348b13857df97`; blob `823722d5eaf44e8b18cd67897b174dd34077713d`. Llama a `Native.begin_wild`, `submit`, `_restore_probe`, sin callbacks simulados.
- Validador Python `tests/tools/test_parallel_items_w01_campaign_003.py`: commit `c68f4eb8ceef9e8ee00cc7a5a127bc77dfe495d8`, blob `197c2c786fd042a5c3395305bff991c5e189bafd`. Fija exactamente las seis pruebas, semillas, fuentes históricas, IDs y total acumulado 48/99.
- CSV `reports/W01/CAMP_003_PROGRESO.csv`: 7 filas, commit disparador `edcb31040c68c429539eed4a8e523f83208bca57`. 04–06 **ENTREGADO_PENDIENTE_CI**; 07 **EN_CI_AUTOMATICA**. Auditoría estática de blobs: **23/23** (no certifica ejecución funcional).

## CI y límites

Las CI 01–03 están confirmadas, última [#41556859548](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556859548) SUCCESS, 3217 checks Godot en 3 bloques. Los runs 04 [#41558549785](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41558549785), 05 [#41559578486](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559578486) y 06 [#41560388772](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41560388772) finalizaron **cancelled** por pushes posteriores, no PASS ni FAIL de mecánica. Nueva CI de 07 [#41561052781](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41561052781) estaba `pending` al redactar; debe validar acumulativamente los 7 bloques mediante `CAMP003_W01_PY PASS blocks=7` y `CAMP003_W01_GODOT PASS blocks=7`, conclusión `success`.

Si hay FAIL de un script W01, corregirlo sin reducir aserciones; si la dependencia está en producción o el workflow compartido, **STOP y escalar a IA6**. No se cubren UI/GPU, retorno al mapa ni todas las combinaciones.

**Siguiente `p` autoriza exclusivamente bloque W01/08:** `luminous_moss;mental_herb;metronome`, previa lectura del último run. No iniciar antes ni modificar `main`, V28, otras ramas, producción o catálogo.
