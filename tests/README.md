# Tests

`test_runner.gd` permanece en la raíz como regresión global. El resto se organiza por dominio:

- `battle/`: Battle Core/presentación/comandos/captura/switch/run.
- `data/`: DATA FOUNDATION V3 y tipos españoles.
- `gameplay/`: progresión, captura/party, inventario, savegame, encuentros, overworld y vertical slice.
- `trainer_ai/`: FASE19+ de IA de entrenadores, benchmarks y corpus.

Los archivos `*.gd.uid` son metadata persistente de Godot 4.4+ y se versionan junto a su script.
Los workflows de `.github/workflows/` son los gates autoritativos; no se borran suites históricas mientras sigan formando parte de esos gates.
