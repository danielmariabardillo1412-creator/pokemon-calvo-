# IA3/W03 — CAMPAÑA_003 / ITER_03: Quick Ball y Timer Ball

**Identidad/rama exclusiva:** IA3/W03, `codex/calvo-items-20261103-w03-camp003`. **Fila autorizada:** `03,W03,CAPTURE_BALL,quick_ball;timer_ball`, cola `CAMPAIGN_003_QUEUE_APPROVED.csv` blob `ea06a0a000fc4f3b8bab48e45e21fb549d753559`. No se ha tocado la rama de CAMPAÑA_002 ni se han duplicado IDs previos.

## Evidencia ya existente (no reimplementar)
- `modules/capture/capture_context_ball_effects.gd` blob `2eb24d7de69d60b0ac3a31ec28055dd8c5eea00b`: ambos IDs registrados; **Quick ×5** solamente si `completed_turns == 0`, en turnos posteriores ×1. **Timer = min(1 + 0,3 × completed_turns, 4)**: turnos 0→×1; 1→×1,3; 3→×1,9; 9→×3,7; 10 y 11→×4.
- `modules/capture/capture_battle_context.gd` blob `0a1ac1e2710e3a1f370fd8443ba0efde6dba4533`: `completed_turns = -1` por defecto; el adaptador rechaza negativos mediante `capture_turn_context_missing`, no permite un bonus gratuito de primer turno.
- Productores de contexto inspeccionados: `WildAdventureSession.capture_current()` (`wild_adventure_session.gd` blob `42b03a0435fd07915955fe9ecf7b8b7468c8c714`) usa `_battle_server.state.turn`; `ShowdownAdventureSession.capture()` (blob `1542086a8c44c58eb41c7ca8c592a40b61d5abf1`) usa `battle_state().turn`. La fuente es el combate real, no reloj del SO ni UI.
- `CaptureInventoryService.resolve()` conserva el mismo gasto de una bola por intento válido y el RNG del motor. **Las dos bolas ya están implementadas**; el trabajo nuevo es auditoría y regresión, sin escribir producción.

## Pruebas incrementales del bloque 03
- Fixture acumulativo `tests/fixtures/parallel_items/w03_campaign_003.json`, blob `71fe990cbe8fb9a77c72c035439e19df79272b2f`: bloques 01 y 02 intactos, bloque 03 de Quick/Timer, 2 especies (Mew y Caterpie), PS completos o 1 PS, turnos `0,1,3,9,10,11`, negativos `-1,-2`, entrenador e inventario sin bola.
- Godot `tests/gameplay/parallel_items_w03_campaign_003.gd`, blob `0dadec944cde62080431cc386c3b1926d0765d16`: `_block_03()` contrasta factor adaptador frente a tabla independiente, probabilidad real `calvo_capture_v1`, resultado con la misma semilla, una unidad, un RNG, identidad de capturado o ausencia de mutaciones tras fallo, y todos los rechazos sin consumo ni RNG. Mantiene `_block_01` y `_block_02`.
- Python `tests/tools/test_parallel_items_w03_campaign_003.py`, blob `d46f87697164237442eef999cc5ab08b00cf3e86`: verifica IDs exactos, tabla de factores, ausencia de contextos falsos, API real y dos productores de turnos; mantiene las validaciones 01/02.
- Progreso CSV: únicamente **tercera fila** `03,quick_ball;timer_ball`, estado `EN_CI_AUTOMATICA`, SHA del blob de Godot. Commit de activación del workflow `5ec49e9290a3eba5230c7eb9b96e69a4b16ff4d9`.

## Validación y siguiente acto
- La última CI de bloque 02 fue [#41555590257](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555590257): **PASS**, Python 56 comprobaciones y Godot 108 comprobaciones.
- Para bloque 03 se inició automáticamente [#41556927911](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556927911) en el SHA de pruebas/CSV `5ec49e9290a3eba5230c7eb9b96e69a4b16ff4d9`. **Pendiente de veredicto al redactar.** Los runs de commits intermedios cancelados no cuentan como evidencia; el workflow exige `CAMP003_W03_PY PASS blocks=3 checks=M` y `CAMP003_W03_GODOT PASS blocks=3 checks=M`, con M positivo.
- Inspección de estructura de los tres blobs `PASS_CONTRACT_STRUCTURE_ONLY`; **no equivale a ejecución en Godot**. No se certifican pruebas GPU ni tipos dinámicos.
- **Próximo `p`: bloque 04 exacto `level_ball;nest_ball`**, después de comprobar el último run de la CI. Si falla test propio: corregir sin disminuir aserciones; si falla contrato compartido: STOP, IA6.
- **No tocar:** `main`, V28, `.github`, `modules/`, `data/`, catálogo canónico, árbitra, PR #118, ramas antiguas/ajenas ni W04.
