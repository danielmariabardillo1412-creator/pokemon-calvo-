# Pokémon Calvo

Juego en Godot 4.7. Copia activa: `D:/Proyectos/Pokemon Calvo - Arquitectura Kilo`.
Original protegido: `D:/Proyectos/Pokemon Calvo`. Rama local:
de origen `codex/kilo-architecture-v1`. Actualización organizada V27 en
`codex/organized-update-v27` del [repositorio del juego](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-).

Para descargar esta versión, **seleccionar esa rama**. El código se conserva en
Git y los recursos visuales grandes se adjuntan a la release de desarrollo.
No basta con descargar el ZIP de código para tener todas las imágenes.
Preparación reproducible y pruebas: [entorno V27](docs/current/GITHUB_ENVIRONMENT_V27.md).
Alcance de la actualización: [entrega V27](docs/current/GITHUB_UPDATE_V27.md).

Ejecutar `JUGAR_DEMO.cmd`. La escena principal es
`scenes/visual/field_demo.tscn`: movimiento, encuentros, captura, combate nativo,
mochila y guardado. B abre mochila; F3 abre la galería; F12 ensaya dobles.
Sigue siendo una demo técnica, no una campaña terminada.

Leer [el inicio vigente](docs/current/START_HERE.md), el
[estado](docs/current/PROJECT_STATE.md) y el
[trabajo pendiente](docs/current/NEXT_STEPS.md).
Los controles detallados están en [el cuaderno visual](docs/project_book/VISUAL_FIELD.md).

T001–T006B están aceptadas. OpenCode no tiene tareas pendientes autorizadas.
Los contratos de `docs/kilo/` son históricos. Las instrucciones actuales para
agentes están en `AGENTS.md`.

El comparador general V1 terminó 135 casos con hallazgos compartidos y pruebas
obsoletas. La [limpieza posterior](docs/current/CLEANUP.md) registra su resolución,
retiradas explícitas y límites. V1 corresponde al código anterior a la limpieza;
no certifica cambios posteriores. Véanse
[el contrato y los resultados](docs/current/COMPARATOR_GENERAL_V1.md).

Datos, políticas y arte permanecen separados de esta limpieza. No ejecutar
regeneradores de datasets para arreglar pruebas. El catálogo de objetos y su
arte no equivalen a tener todas sus mecánicas implementadas.

Prueba básica (no sustituye las pruebas de cada cambio):

```text
godot --headless --path . --script res://tests/test_runner.gd
python tools/regression_comparator/test_results.py
```

Índice de arquitectura, cuadernos, créditos e historial: [docs/README.md](docs/README.md).
