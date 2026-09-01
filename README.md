# Pokémon Calvo

Proyecto de fangame de criaturas en **Godot 4.7**. El repositorio contiene Battle Core determinista, progresión/captura/overworld y una IA de entrenadores no neuronal con inferencia de información, búsqueda acotada, self-play/evaluación, objetos finitos, switching estratégico, loadouts y composición de equipos.

## Autoridad de desarrollo

El último baseline funcional certificado antes de la reorganización documental es:

- PR #95: `DATA V3 — final end-to-end certification`
- HEAD: `b4f6adc200bef18f8ac51b9144f2f9a838f464fd`
- estado: cerrado **sin merge**
- validación: **18/18 workflows SUCCESS** sobre el HEAD final.

La rama `main` es una referencia histórica antigua y **no representa el estado actual del proyecto**. No debe usarse como baseline de trabajo. Su sustitución por el baseline nuevo se hará en una operación separada cuando la reorganización esté terminada y certificada.

## Por dónde empezar

Para recuperar el proyecto sin leer todo el historial:

1. [`docs/current/START_HERE.md`](docs/current/START_HERE.md)
2. [`docs/current/PROJECT_STATE.md`](docs/current/PROJECT_STATE.md)
3. [`docs/current/NEXT_STEPS.md`](docs/current/NEXT_STEPS.md)
4. el cuaderno temático relevante en [`docs/project_book/`](docs/project_book/)

Índice completo: [`docs/README.md`](docs/README.md).

## Datos canónicos

DATA FOUNDATION V3 parte de un snapshot inmutable de PokéAPI en `data/api/v2` + `data/schema/v2`. `tools/pokeapi_adapter_v3.py` genera el raw/manifiesto y Godot normaliza mediante `tools/run_import.gd`.

El contrato consolidado y el cierre operativo están en:

- [`docs/architecture/DATA_FOUNDATION_V3.md`](docs/architecture/DATA_FOUNDATION_V3.md)
- [`docs/project_book/DATA_V3.md`](docs/project_book/DATA_V3.md)

## Ejecutar tests

```bash
godot --headless --path . --import
godot --headless --path . --script res://tests/test_runner.gd
```

No se fija aquí un número global de PASS: el total crece con el proyecto y la autoridad son los workflows de `.github/workflows/` ejecutados sobre el SHA exacto que se pretende certificar.
