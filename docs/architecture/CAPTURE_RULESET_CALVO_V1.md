# CAPTURE_RULESET — calvo_capture_v1

Regla determinista de captura. Fuente de verdad para la probabilidad y la tabla de balls.
Implementada en `modules/capture/capture_ruleset.gd`.

## Fórmula de probabilidad

```
p = (capture_rate / 255) * ball_mult * status_mult * hp_factor
hp_factor = (3 * max_hp - 2 * current_hp) / (3 * max_hp)   # 1.0 a 0 HP, 1/3 a HP lleno
```

- `p` se clampa a `[0, 1]`.
- Éxito = `guaranteed` (master) OR `rng.randf() < p`.
- Sacudidas en fallo = `clamp(int(p * 3), 0, 2)` (flavor determinista).

## Tabla de balls (canónica)

PokéAPI `items` no trae multiplicadores de ball estructurados, así que esta tabla es la fuente de
verdad (ver `CAPTURE_DATA_AUDIT.md`).

| ball_id      | base_multiplier | guaranteed |
|---|---|---|
| `poke_ball`  | 1.0             | false     |
| `great_ball` | 1.5             | false     |
| `ultra_ball` | 2.0             | false     |
| `master_ball`| 1.0             | true      |

Master Ball => SUCCESS siempre, sin consumir RNG.

## Bonus de status (solo persistentes)

| persistent_status_id | status_mult |
|---|---|
| `sleep`              | 2.0         |
| `freeze`             | 2.0         |
| `poison`             | 1.5         |
| `badly_poisoned`     | 1.5         |
| `burn`               | 1.5         |
| `paralysis`          | 1.5         |
| (ninguno / `&""`)    | 1.0         |
| volátil (flinch/confusión) | 1.0 (no afecta) |

`status_bonus` lee `CreatureInstance.status_state.persistent_id`.

## Rango de captura

- `is_valid_capture_rate(capture_rate)` => `1 <= capture_rate <= 255`.
- `0`/ausente => no capturable (`invalid_capture_rate`).
- Fuente: `pokemon-species` (`capture_rate`). Ejemplos: bulbasaur 45, pikachu 190, mewtwo 3.

## Restricciones (en `CaptureSystem._validate`)

- `invalid_target` (target nulo)
- `invalid_context` (contexto nulo)
- `battle_finished` (batalla terminada)
- `trainer_battle_not_capturable` (no es salvaje)
- `target_owned_by_trainer` (el target pertenece a un entrenador)
- `target_knocked_out` (KO, salvo `ALLOW_CAPTURE_KO`)
- `unknown_ball` (ball no en tabla)
- `unknown_species` / `invalid_capture_rate`

## Ejemplo numérico (golden)

Pikachu (`capture_rate = 190`), poke_ball, full HP, sin status:
`p = (190/255) * 1.0 * 1.0 * (1/3) = 0.2483...` => ~24.8%.
Bajar HP a 1 ó aplicar sleep duplica/mejora la probabilidad; great/ultra multiplican por 1.5/2.0.

## `schema_version`

`CaptureRuleset.SCHEMA_VERSION = 2` (sin bump respecto a Progression; campos aditivos).
