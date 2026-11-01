# W01 — CAMP_001 / microbloque 01 — Curación y daño residual

**Estado:** PREPARADO_PENDIENTE_CI. **No afirmar PASS de Godot para estos IDs.**
**Rama exclusiva:** `codex/calvo-items-20261101-w01`. **Checkpoint árbitra incorporado:** `1b52fdd0b7b89e468811a17ad83a917ec7107735`.
**Asignación oficial (blob):** `4faaae234c3021944d7f4724789c3b2c5d0652fd`; puerta `3ef0b39f7eb74f3ebcb688f279c254daec981f8e`.
**Tests/fixture publicados:** commits `19db170d5aadf29d0b158dc5c3bbbd04c19b1b21`, `320e985db63d1afa86ffadbcccfe30441eb775f4`, `cb81acaabf6b7d5f1d347ecad9bc6f825ee69919`.

## IDs y evidencia existente
- `black_sludge`: seleccionado; `blacksludge/onResidual`. Casos de curación tipo Veneno herido, tipo Veneno a PS completos y daño residual a no Veneno.
- `shell_bell`: seleccionado; `shellbell/onAfterMoveSecondarySelf`. Casos ataque con daño, movimiento de estado y ataque inmune (Normal contra Gengar).
- `big_root`: seleccionado; `bigroot/onTryHeal`. Casos Absorber con drenaje y movimiento sin drenaje. Histórico V27 `tools/item_audit/held_effect_sweep_v2.cjs` ya contiene una comprobación parcial de Campana y Raíz; **no se ha rehecho el efecto**.

## Entregables comprobados
- Fixture `tests/fixtures/parallel_items/w01_campaign_001.json`: 8 escenarios, 12 pares caso-semilla, 36 variantes (`active`, `none`, `reserve`).
- Runner `tests/gameplay/parallel_items_w01_campaign_001.gd`: sesión `@pkmn/sim@0.10.11` con `Native`, `FieldItemService`, propietario, comprobación de revisión obsoleta, snapshots antes/después, restauración `SaveV2` y comprobación de no consumo.
- Validador `tests/tools/test_parallel_items_w01_campaign_001.py`: rechaza escenario alterado, variantes faltantes, resultado que no sea PASS, aserciones causales falsas y evidencias ausentes/con hash divergente.
- Comprobación estructural **PASS estático** (ejecutada mediante lectura GitHub + JavaScript): 12 invariantes de contenido, operaciones, rutas, número de ejecuciones, propietario y verificación de hash. **No equivale a ejecutar Python ni Godot.**

## Ejecución y límites
- **PASS histórico ajeno a este commit:** CI base `ac34fabbe1a27e69614f0239abee21c29d6fe65e`, [Actions #41341842320](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41341842320), validó LOTE_002 con W01 1.332 checks; **no incluye estos ocho escenarios nuevos**.
- **Godot 4.7 de esta iteración:** SIN_EJECUTAR / PENDIENTE_CI. **Python nuevo:** SIN_EJECUTAR (validación de texto/JSON solamente). **GPU/visual:** SIN_EJECUTAR.
- Comandos de CI, tras preparar recursos y `POKEMON_CALVO_NODE` como en `.github/workflows/parallel-items-gate.yml`:
  ```bash
  python -B tests/tools/test_parallel_items_w01_campaign_001.py --contracts
  python -B tests/tools/test_parallel_items_w01_campaign_001.py --self-test
  godot --headless --path . --script res://tests/gameplay/parallel_items_w01_campaign_001.gd
  python -B tests/tools/test_parallel_items_w01_campaign_001.py
  ```
- Riesgos: semilla y perfil nativos requieren CI, no se ha comprobado cierre real de batalla/UI, ni supresión/cambio de portador. Un FAIL obliga a parar y reportar a IA6, no corregir producción.

**Próximo paso permitido por una nueva `p` si IA6 no bloquea:** microbloque 02 (`eviolite`, `expert_belt`, `safety_goggles`). No se ha empezado.
