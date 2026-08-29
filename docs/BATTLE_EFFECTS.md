# Battle effects contract

## Runtime contract

Cada `BattleEffectSpec` serializable usa:

```json
{
  "kind": "inflict_status",
  "target": "opponent",
  "value": 0,
  "ratio_basis_points": 0,
  "chance_basis_points": 10000,
  "status_id": "paralysis",
  "stat_id": "",
  "children": []
}
```

IDs de `kind`: `damage`, `heal`, `recoil`, `drain`, `inflict_status`,
`cure_status`, `modify_stat_stage`, `chance`, `flinch`, `fixed_damage`.
Targets V2: `self`, `opponent`. Ratios y probabilidades son basis points para evitar
floats ambiguos. `Chance` ejecuta `children` en orden.

## Future data-pipeline metadata

El pipeline futuro puede añadir, tras incrementar su schema:

- moves: `effect_specs: Array[BattleEffectSpec dictionary]`;
- abilities/items: `trigger_specs`, cada uno con `trigger`, `priority`, `conditions`,
  `consume_source` y un `effect` con el contrato anterior;
- campos estructurados adicionales como `contact`, `multi_hit_distribution` o
  flags de target cuando una mecánica los necesite.

El importador deberá validar kinds, targets, IDs referenciados, rangos y estructura
de hijos. Un spec inválido se rechaza; nunca se infiere desde descripciones.
`effect_summary` se conserva exclusivamente para documentación/localización y
Battle Core no lo lee.

## Explicit V2 mappings

- Daño simple: `tackle`, `water_gun`, `quick_attack`.
- Daño + status: `ember`, `thunder`, `thunder_punch`.
- Stage: `growl`, `swords_dance`.
- Heal: `recover`.
- Recoil: `double_edge`.
- Drain: `mega_drain`.
- Status puro: `thunder_wave`, `will_o_wisp`, `toxic`, `sleep_powder`.

Mappings de ability: `intimidate`, `levitate`, `blaze`, `torrent`, `overgrow`,
`static`. Held items: `leftovers`, `sitrus_berry`.

Cada ID anterior tiene ejecución y tests. Cualquier otro move de daño aún recibe la
fórmula base, pero no se considera completamente soportado si su secundario no tiene
spec. Los casos exóticos permanecen parciales o unsupported.

## Events

Los handlers emiten IDs semánticos: move miss/use, PP, damage, critical, type
effectiveness, status apply/fail/cure/tick, stage, heal, recoil, switch, ability,
item, KO y turn/battle end. No contienen frases localizadas ni campo `text`.
