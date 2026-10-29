# Pokémon Calvo

Juego en Godot 4.7. Copia activa: `D:/Proyectos/Pokemon Calvo - Arquitectura Kilo`.
Original protegido: `D:/Proyectos/Pokemon Calvo`. Rama local:
`codex/kilo-architecture-v1`, sin remoto configurado.

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
