# Fixtures de regresión

Este directorio contiene **datos de prueba**, no el dataset canónico del juego.

- `starter_dataset.json` + `../manifests/starter_manifest.json`: fixture del Data Pipeline V1.
- `regression_resources/`: Resources `.tres` sintéticos/estables usados por regresiones históricas (Foundation, tipos españoles y Battle V2).

Los datos Pokémon canónicos proceden del snapshot `data/api/v2` + `data/schema/v2`, se generan en `data/raw/pokemon_api.json` y se normalizan en `data/normalized/pokemon_api.json`.
