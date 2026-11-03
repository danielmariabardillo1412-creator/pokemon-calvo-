# IA2/W02 — CAMPAÑA_003 / BLOQUE 02 DE 10

**Estado:** `EN_CI_AUTOMATICA`, bloque 02 publicado; sin PASS de este nuevo SHA. **Rama exclusiva:** `codex/calvo-items-20261103-w02-camp003`.

## Verdad CI anterior y reparación

La CI previa [#41553745691](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41553745691) fue `failure`: Godot 749 comprobaciones, fallo en el test de `apicot_berry` (`boost_spd`). El test inicial leía `|-boost|spd` sin diferenciar lados, confundiendo la **Amnesia del rival** con la subida del portador. Se corrigió **únicamente el filtro del test W02** a `line.begins_with("|-boost|p1a:")`, sin cambiar expectación ni producción. Commit `2449baf285ef9eaffdb4fa030f78dfe3ee8c551c`. **Reejecución #41554998986 `completed/success` del SHA corregido**: se desbloquea la siguiente `p`.

## IDs del bloque 02, contratos existentes y nuevas pruebas

| ID | Ataque positivo | Pokémon | Ataque negativo |
|---|---|---|---|
| `charti_berry` | `smack_down` (Roca) | `charizard` | `tackle` |
| `chilan_berry` | `tackle` (Normal) | `mew` | `surf` |
| `chople_berry` | `brick_break` (Lucha) | `snorlax` | `tackle` |
| `coba_berry` | `aerial_ace` (Volador) | `venusaur` | `tackle` |

**Precedente real:** `tools/item_audit/held_effect_sweep_v2.cjs` define exactamente los cuatro tipos, portadores y controles `resist_berry`/`resist_nonmatching`. Son efectos equipados existentes, no implementación nueva. **Chilan protege de Normal sin necesitar supereficacia**.

**Prueba adicional justificable:** cada uno de los ocho escenarios se ejecuta en tres modos, verificando que solo el portador activo reduce el daño, que un ataque no coincidente no la consume, que la reserva conserva su objeto y que inventario/SaveV2 no pierden ni duplican unidades. Los nueve escenarios del bloque 01 se mantienen sin cambios: **17 escenarios acumulados y 51 ejecuciones nativas previstas**.

**Archivos de código exclusivos:**
- `tests/fixtures/parallel_items/w02_campaign_003.json`: bloque 02 añadido, commit `919f36e444a572b973852b3ef4f114c83d6f6707`.
- `tests/gameplay/parallel_items_w02_campaign_003.gd`: reutiliza mismo comparador de resistencias con familia `resist_type`, commit `ed5c2f2dd1ca8620f6fcb0d066942dd721734fcd`.
- `tests/tools/test_parallel_items_w02_campaign_003.py`: nueve contratos previos preservados y ocho nuevos con tipo, especie, ataque, consumo estrictamente fijados; seis tests adversariales nuevos contra manipulación/ausencia, commit `feddccce4d23571d989784e89919305dceede825`.
- `docs/coordination/items_parallel_v1/reports/W02/CAMP_003_PROGRESO.csv`: bloque `02` añadido, commit `926ad81488c1e83d777177bfa5a2eff35b028eca`.

**CI actual automática:** [run #41555493832](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555493832), primer commit con ambos bloques declarados. Exige `CAMP003_W02_PY PASS blocks=2 checks=M` y `CAMP003_W02_GODOT PASS blocks=2 checks=M`, Godot 4.7 + Node22. `pending` al escribir este informe; no atribuir PASS hasta consultar resultado y SHA.

**Límites:** no tocar `main`, V28, IA6 ni otras ramas, producción, motores ni catálogos. No activar campo; GPU y doble combate no incluidos. **Próxima `p`: bloque 03 de la cola (`colbur_berry;custap_berry;enigma_berry;ganlon_berry`) solo según semáforo CI.** Límite total 10/10.
