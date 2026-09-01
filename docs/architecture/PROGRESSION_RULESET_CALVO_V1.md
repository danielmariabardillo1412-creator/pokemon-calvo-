# PROGRESSION RULESET — `calvo_progression_v1`

Single source of tuning for FASE 6 progression. Lives in `ProgressionRuleset` (`ID = &"calvo_progression_v1"`).

## Limits

| Constant | Value | Meaning |
|---|---|---|
| `MAX_LEVEL` | 100 | Level cap |
| `MOVE_SLOTS_MAX` | 4 | Moves per creature |
| `MAX_PARTY` | 6 | Party size |
| `MAX_EV_TOTAL` | 508 | Total EVs across stats |
| `MAX_EV_PER_STAT` | 252 | Per-stat EV cap |
| `MAX_IV` | 31 | Per-stat IV cap |

## Experience curves

`E(level)` = total XP required to reach `level`. `E(1) = 0`. For `n >= 2`:

```
fast         = floor( 4·n³ / 5 )
medium       = n³
medium_slow  = floor( 6/5·n³ − 15·n² + 100·n − 140 )
slow         = floor( 5·n³ / 4 )
erratic      = piecewise (n ≤ 50, 51–68, 69–98, ≥99)
fluctuating  = piecewise (n ≤ 15, 16–36, 37–100)
```

Monotonic and verified at checkpoints: medium L2=8, L100=1'000'000; medium-slow L2=9;
fast L100=800'000; slow L100=1'250'000; erratic/fluctuating L100=1'640'000 / 1'640'000.

- `experience_for_level(species_id, level)` — cached per `(species_id, level)`.
- `level_for_experience(species_id, xp)` — monotone search (handles sparse curves).
- `experience_for_defeats(defeats, participant_count)` — sum of `experience_for_defeat` shared across
  participants; `experience_for_defeat(base_xp, foe_level, participants) = base_xp·foe_level·100/700 / participants`.

## Nature table

25 canonical natures. Multipliers: raised stat ×1.1, lowered stat ×0.9, neutral ×1.0. Neutral =
`&"hardy"`. Mapping stored in `NATURE_MODIFIERS` (stat_key → [up, down]).

| Raised ↓ \ Lowered → | attack | defense | speed | special_attack | special_defense |
|---|---|---|---|---|---|
| (neutral) hardy | — | — | — | — | — |
| lonely | attack | defense | | | |
| adamant | attack | special_attack | | | |
| naughty | attack | special_defense | | | |
| brave | attack | speed | | | |
| bold | defense | attack | | | |
| impish | defense | special_attack | | | |
| lax | defense | special_defense | | | |
| relaxed | defense | speed | | | |
| modest | special_attack | attack | | | |
| mild | special_attack | defense | | | |
| rash | special_attack | special_defense | | | |
| quiet | special_attack | speed | | | |
| calm | special_defense | attack | | | |
| gentle | special_defense | defense | | | |
| careful | special_defense | speed | | | |
| sassy | special_defense | special_attack | | | |
| timid | speed | attack | | | |
| hasty | speed | defense | | | |
| jolly | speed | special_attack | | | |
| naive | speed | special_defense | | | |
| (others) | | | | | |

## Stat formula (`StatCalculator.compute`)

```
HP : (2·base + iv + ev/4)·level/100 + level + 10
OTH: ((2·base + iv + ev/4)·level/100 + 5) · nature_mult
```

`nature_mult` applies only to the raised/lowered stat (1.1 / 0.9); all other stats use 1.0.
Verified: bulbasaur L5 neutral HP=19 atk=9; L50 adamant atk=59 vs neutral 54.
