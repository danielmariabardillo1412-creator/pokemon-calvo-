# CAPTURE — Data Audit (FASE 7)

## Pregunta

¿Tiene PokéAPI el dato necesario para `capture_rate`? ¿Y los multiplicadores de ball?

## Hallazgo 1 — capture_rate: SÍ (presente)

Fuente: endpoint **`pokemon-species`**, campo `capture_rate`.

| Especie   | capture_rate |
|---|---|
| bulbasaur | 45          |
| pikachu   | 190         |
| charmander| 45          |
| squirtle  | 45          |
| mewtwo    | 3           |

- Rango observado: `3..255`. `0` solo aparece en especies especiales/legendarias sin capture_rate.
- Validación: `1 <= capture_rate <= 255` (`CaptureRuleset.is_valid_capture_rate`).
- Adapter: `tools/pokeapi_adapter.py` añade `capture_rate` desde `pokemon-species`.
- `DataImporter.SPECIES_KEYS` incluye `"capture_rate"`.
- `CreatureSpecies.capture_rate: int = 0` + `to_dict`/`from_dict` + `is_valid_capture_rate()`.
- Re-importado: 986 especies · 0 referencias rotas · 0 rechazadas.

## Hallazgo 2 — multiplicadores de ball: NO (no estructurado)

PokéAPI `items` (pokeball family) trae `name`, `cost`, `category` y efectos de texto, pero **no**
un multiplicador numérico de captura estructurado. Por tanto:

- La tabla `CaptureRuleset.BALLS` (poke 1.0 / great 1.5 / ultra 2.0 / master garantizada) es la
  **fuente de verdad** por diseño de `calvo_capture_v1`.
- Esto está documentado en `CAPTURE_RULESET_CALVO_V1.md` y `ARCHITECTURE_DECISION_006_CAPTURE_PARTY.md`.
- No se inventan datos de PokéAPI; se declara explícitamente que la tabla es canónica del juego.

## Hallazgo 3 — status para bonus: SÍ (derivable)

`CreatureInstance.status_state.persistent_id` (Battle Core) cubre sleep/freeze/poison/
badly_poisoned/burn/paralysis. El bonus de captura usa solo los persistentes; los volátiles
(flinch/confusión) no afectan. Cubierto por `CaptureRuleset.status_bonus`.

## Conclusión

Datos suficientes para FASE 7. `capture_rate` importado y validado; balls definidas por regla de
juego; status derivado del Battle Core existente. Sin referencias rotas.
