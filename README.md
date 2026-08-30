# Pokémon Calvo

Fangame técnico de criaturas construido en **Godot 4.7** con arquitectura determinista, datos versionados y desarrollo por ramas stacked. El repositorio prioriza primero contratos de dominio/aplicación verificables y después presentación/assets.

## Baseline funcional actual

El HEAD validado más reciente demuestra el ciclo:

`Overworld físico -> encounter -> Battle visible -> MOVE / CAPTURE / SWITCH / RUN -> settlement -> confirmación -> Overworld`

Sistemas ya presentes:

- dataset PokéAPI normalizado con IDs/provenance estables;
- Battle Core autoritativo y determinista;
- progresión, captura, party, storage e inventory;
- Savegame V2 con migración real V1 -> V2 y carga transaccional;
- encuentros salvajes deterministas;
- Overworld técnico con movimiento, colisión y encounter zones;
- Battle Presentation técnica sobre la misma `WildAdventureSession` real;
- comandos visibles MOVE, CAPTURE, SWITCH y RUN.

La rama funcional más reciente es `feature/battle-run-presentation-v1`. PR #12 está cerrado **sin merge**; `main` no representa todavía este baseline stacked.

## Validación

Motor CI exacto:

`4.7.stable.official.5b4e0cb0f`

El workflow final de FASE 18 conserva:

- historical regression: **470 PASS / 0 FAIL**;
- Inventory: **47 / 0**;
- Savegame V2: **40 / 0**;
- Savegame V2 adversarial: **8 / 0**;
- Wild Encounters: **54 / 0**;
- Logical Vertical Slice: **62 / 0**;
- Overworld: **59 / 0**;
- Battle Presentation: **43 / 0**;
- Battle Commands: **53 / 0**;
- Capture Presentation: **68 / 0**;
- Switch Presentation: **49 / 0**;
- Wild RUN Command: **71 / 0**;
- Run Presentation + audit: **94 / 0**.

La regresión histórica puede ejecutarse con:

```powershell
& "C:\Godot\4.7\Godot_v4.7-stable_win64_console.exe" --headless --path "F:\pokemon roma el calvo\pokemon-calvo" --script res://tests/test_runner.gd
```

Debe terminar con al menos `470 PASS / 0 FAIL`. Las suites de fase adicionales y sus gates viven en `.github/workflows/godot-tests.yml`.

## Documentación canónica

- [`docs/STATUS.md`](docs/STATUS.md): estado agregado actual y evidencia del baseline.
- [`docs/ROADMAP.md`](docs/ROADMAP.md): próximas fronteras ordenadas por dependencias.
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md): arquitectura vigente y límites de autoridad.
- `docs/ARCHITECTURE_DECISION_*.md`: ADRs históricos.
- `docs/INFORME_FINAL_FASE*.md`: evidencia de cierre de cada fase.
- [`docs/MECHANICS_COVERAGE.md`](docs/MECHANICS_COVERAGE.md): cobertura honesta de moves/abilities/items/evoluciones.

## Siguiente frontera recomendada

No hay una FASE 19 abierta. La siguiente frontera recomendada por dependencia es **Post-Battle Progression Flow**: conservar y resolver correctamente las decisiones `MOVE_LEARN_CHOICE_REQUIRED` y `EVOLUTION_AVAILABLE` antes de volver al Overworld, y solo después exponerlas en presentación.

Ver `docs/ROADMAP.md` para el razonamiento y los gates propuestos.

## Assets pesados

La biblioteca local grande de sprites/referencias no forma parte del repositorio ni del CI. GitHub conserva código, datos canónicos necesarios y fixtures pequeños; la integración de assets finales se hará sobre interfaces estables sin convertir varios GB locales en dependencia de los tests remotos.