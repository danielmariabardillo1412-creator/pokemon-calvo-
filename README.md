# Pokémon Calvo

Proyecto de fangame de criaturas en **Godot 4.7**, con Battle Core determinista, progresión/captura/overworld y una IA de entrenadores no neuronal con búsqueda, belief inference, self-play, objetos, switching estratégico y composición de equipos.

## Baseline certificado

La base de datos canónica actual es **DATA FOUNDATION V3**, conservada en `feature/data-foundation-v3` (HEAD certificado `304035e2e7b39a628c4fece89cf0f3db6caa8664`). Ese HEAD pasó los 18 workflows normales del proyecto.

La fuente PokéAPI es un snapshot versionado en `data/api/v2` + `data/schema/v2`; `tools/pokeapi_adapter_v3.py` genera el raw/manifiesto y Godot normaliza mediante `tools/run_import.gd`.

## Ejecutar tests

```bash
godot --headless --path . --import
godot --headless --path . --script res://tests/test_runner.gd
```

No se fija aquí un número de PASS: el total crece con el proyecto y la fuente de verdad son los workflows de `.github/workflows/`.

## Documentación

- Estado actual: [docs/STATUS.md](docs/STATUS.md)
- Índice documental: [docs/README.md](docs/README.md)
- DATA FOUNDATION V3: [docs/DATA_FOUNDATION_V3.md](docs/DATA_FOUNDATION_V3.md)
- Arquitectura general: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- ADR: [`docs/adr/`](docs/adr/)
- Historial de fases: [`docs/history/`](docs/history/)
