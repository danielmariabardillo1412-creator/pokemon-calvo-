# Pokémon Calvo

Proyecto de fangame de criaturas en **Godot 4.7**. El repositorio contiene Battle Core determinista, progresión/captura/overworld, persistencia, inventario y una IA de entrenadores no neuronal con inferencia de información, búsqueda acotada, switching estratégico, objetos, loadouts, composición de equipos, estilos/expertise y persistencia de roster entre combates.

## Baseline moderno

La línea moderna certificada culmina en el freeze documental:

`8552f52158ffc21c27b4e8f1dbc7caa63ac1a467`

Ese SHA pasó la matriz normal de **18/18 workflows SUCCESS** y cierra Trainer AI Campaign Persistence V1.

La sustitución de la antigua `main` se ejecuta como una operación separada en `chore/main-baseline-consolidation-v1`. El merge histórico inicial `2f63312e8dc3e61c8fadbd02e97972fff6d0eacc` conserva como padres tanto la antigua `main` (`641d4b1f...`) como el freeze moderno (`8552f521...`) y usa exactamente el árbol certificado moderno. La referencia de GitHub sobre el HEAD final certificado de esa operación es la autoridad para la promoción de `main`.

## Estado del producto

Los cimientos técnicos están avanzados, pero el ejecutable visible sigue siendo una **vertical slice técnica**, no una campaña Pokémon completa. La siguiente línea de producto debe convertir los sistemas ya certificados en un juego real: game state global, mapas/transiciones, NPC/eventos, persistencia de mundo y una primera vertical slice de campaña.

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
