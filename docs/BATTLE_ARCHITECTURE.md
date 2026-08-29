# Battle architecture V2

## Authority boundary

```text
Client -> BattleAction(MOVE|SWITCH)
              |
              v
AuthoritativeBattleServer -- validate --> TurnExecutor
                                              |
                         BattleState <--------+--------> SeededRandomSource
                                              |
                  EffectRegistry -> EffectExecutor -> BattleEvent[]
                                     |       |
                                StatusSystem TriggerSystem
```

`BattleState` es la única verdad mutable. Presentation recibe eventos semánticos;
no recibe acceso de escritura al estado. Todo es RefCounted y no depende de Node,
SceneTree, UI ni assets.

## Phases

El orden contractual es:

1. `VALIDATE_ACTIONS` — servidor, antes de mutar estado.
2. `SELECT_ORDER` — switch priority, move priority, speed stage/paralysis, RNG tie.
3. `BEFORE_ACTION` — sleep, paralysis, freeze, flinch.
4. `ACCURACY` — accuracy de move + accuracy/evasion stages + RNG.
5. `EXECUTE_EFFECTS` — specs en orden declarado.
6. `AFTER_DAMAGE` — ability/item del receptor.
7. `FAINT_CHECK` — KO, reemplazo o fin.
8. `AFTER_ACTION` — punto reservado para triggers posteriores.
9. `END_TURN_STATUS` — poison, badly poison y burn por orden de lado.
10. `END_TURN_TRIGGERS` — held items/abilities por orden estable.
11. `TURN_END` — evento final y commit del estado RNG.

Los puntos reservados son contratos, no hooks globales: un trigger nuevo debe
registrarse en una phase concreta y tener tests de orden.

## Runtime state

`CreatureInstance` posee:

- `BattleMoveSlot[]`: `move_id`, `current_pp`, `max_pp`;
- `StatStages`: siete stages temporales -6..+6;
- `BattleStatusState`: un status persistente, contador/duración y volátiles;
- `ability_id`, `held_item_id`, flag de consumo;
- stats base separados, incluidos Special Attack/Defense.

`BattleState` posee participantes ordenados y `BattleSide[]` con party y active.
Switch limpia stages y volátiles del saliente, conserva status persistente y PP.
Al KO, V2 promueve determinísticamente el primer bench vivo.

## Snapshots

Schema actual: **2**. Incluye schema/ruleset/RNG, turn/phase/winner, orden de
participantes, sides/party/active, PP, stages, status persistente/volátil, ability e
item runtime. V1 se considera preproducción y no se migra; cualquier schema o RNG
desconocido se rechaza.

## Deterministic ordering

Sides y party son arrays persistidos. Specs son arrays. Abilities se evalúan antes
que items. Dictionaries solo se usan para lookup; cuando se serializa un mapa de
volátiles sus claves se ordenan. El estado RNG se actualiza también al terminar
anticipadamente por KO.
