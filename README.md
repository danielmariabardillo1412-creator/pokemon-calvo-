# Pokémon Calvo

Foundation V1 de un fangame de criaturas construido para Godot 4.7. La rama
`foundation/core-v1` contiene un vertical slice lógico, sin gráficos ni assets
propietarios: dos criaturas, prioridad, velocidad, daño, STAB, efectividad, KO,
Poison, eventos, RNG determinista y snapshots serializables.

## Ejecutar

```powershell
& "C:\Godot\4.7\Godot_v4.7-stable_win64_console.exe" --headless --editor --import --path "F:\pokemon roma el calvo\pokemon-calvo"
& "C:\Godot\4.7\Godot_v4.7-stable_win64_console.exe" --headless --path "F:\pokemon roma el calvo\pokemon-calvo"
```

La segunda orden debe terminar con `13 PASS / 0 FAIL` y código de salida 0.

Consulta [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) para las reglas de
dependencia y [docs/ARCHITECTURE_DECISION_001.md](docs/ARCHITECTURE_DECISION_001.md)
para la auditoría y decisión.
