# IA1/W01 — CAMPAÑA_002 · ITER_02 — Contraste nativo en Godot

**Estado: PREPARADO_PENDIENTE_CI.** Runner y validador publicados; ninguna nueva ejecución Godot 4.7 para estos blobs. **No proclamar PASS funcional.**
**Rama propia:** `codex/calvo-items-20261102-w01-camp002`. **Gate superior:** `CAMPAIGN_002_ITER01_CI_GATE.md`, blob `12e9c3021e80f9e03e0f9b0e900853b9a7e6a513`; asignación W01 `6ef97f3c0569c96138cb8c322069384e124e5c79`.

## Evidencia existente / alcance
- ITER_01: [Actions #41484879741](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41484879741), SHA staging `967002fcbf26a1159d3a14a020e8921b34cfab8f`, PASS de **contrato W01** 7 casos/10 semillas/30 variantes, seis mutantes negativos rechazados. No ejecutó un runner W01 nuevo.
- `ability_shield`: actor `synchronize`, rival `gastro_acid`, observar volátil nativo `gastroacid` con escudo frente a control y reserva; control sin supresión.
- `absorb_bulb`: impacto real `water_gun` vs `tackle` / `amnesia`; comparar PS nativos, `boosts.spa=1`, consumo/retención y propiedad.
- `adrenaline_orb`: Gyarados con `intimidate`; observar `boosts.spe=1` **ya en entrada** y después del primer turno, con control sin Intimidate; consumo/retención.
- Cada caso se ensaya en `active`, `none`, `reserve`; semilla alternativa **19 y 23** en los tres disparadores positivos. Total planificado **7 escenarios / 10 pares caso-semilla / 30 variantes**.

## Archivos de pruebas nuevos o ampliados
- `tests/gameplay/parallel_items_w01_campaign_002.gd`: hereda runner V28 para `FieldItemService` y `Native`, toma estados directamente de `session._checkpoint.roster`, ejecuta turno real, rechaza revisiones obsoletas, registra log nativo/snapshot y crea recibo por modo con SHA-256. Sin implementar efectos.
- `tests/tools/test_parallel_items_w01_campaign_002.py`: conserva contratos de ITER_01 y añade `--native` para exigir informe PASS de Godot, 10 pares y 30 modos, efecto causal/consumo, propietario, snapshots y coincidencia de cada hash SHA-256. Sin informe real debe fallar (`SIN_EJECUTAR`).
- Fixture ITER_01 `tests/fixtures/parallel_items/w01_campaign_002.json` **sin modificar**. SHA de blobs: runner `68b73dd62b0250b5bdbdebdf44c97cd4649a2487`, validador `a6492e1f9f8fa6928af5601a0633f6e830b0238e`, fixture `74c91b2cfb69d7525ee4d42cc1e57f442c4a808d`.
- Commits de tests: runner `b34e954a7e9a601432d23c470b50607920afec5e`, validador `b22ff7136b368171c003ef6d0571de964b8e529c`. Auditoría por lectura de GitHub **20/20 invariantes estructurales PASS**; no sustituye parser Godot ni Python ejecutado tras estos cambios.

## CI reproducible por IA6
```bash
python -B tests/tools/test_parallel_items_w01_campaign_002.py --contracts
python -B tests/tools/test_parallel_items_w01_campaign_002.py --self-test
godot --headless --path . --script res://tests/gameplay/parallel_items_w01_campaign_002.gd
python -B tests/tools/test_parallel_items_w01_campaign_002.py --native
```
Preparar import Godot 4.7, Node 22 y `@pkmn/sim@0.10.11` mediante protocolo común antes del runner; la salida esperada es `.godot/parallel_items/w01_campaign_002/report.json` y 30 recibos. **Ninguna de estas órdenes nuevas se ejecutó en esta conversación.**
**Limitaciones:** Godot parser/API, volátil Gastro Acid y proyección de consumo requieren CI; aún no se verifica SaveV2/restauración de ITER_03, ni UI/GPU, Trick, combate completo o juego integral.
**Siguiente bloque:** ITER_03 (SaveV2, contratos y matriz final) solo tras nuevo `p` y ausencia de FAIL/bloqueo de IA6. No tocar motor, producción, ramas ajenas o W04.
