# INFORME FINAL — FASE 14: Battle Commands V1

Fecha: 2026-08-30  
Rama: `feature/battle-commands-v1`  
Base: `feature/battle-presentation-v1`  
PR: #8  
Motor CI: `4.7.stable.official.5b4e0cb0f`

## Estado

**FASE_14_STATUS = VALIDATED / FINAL DOC-HEAD CI REQUIRED**

El código y la auditoría adversarial están verdes. El cierre definitivo de la fase requiere que el workflow vuelva a pasar sobre el HEAD final que contiene documentación y el gate CI fijado en 53 checks.

## Problema resuelto

Antes de esta fase, Capture podía resolverse lógicamente desde `WildAdventureSession.capture_current()`, pero un intento fallido no representaba un turno completo de Battle. Era correcto para pruebas aisladas de captura, pero no era un contrato seguro para una interfaz jugable: una UI podría repetir balls sin respuesta rival.

FASE 14 añade un límite de comando de jugador que conserva los dominios separados y define explícitamente qué ocurre con el turno.

## Contrato nuevo

`WildBattleCommand` representa intención de aplicación:

- `ACTION` envuelve un `BattleAction` existente;
- `CAPTURE` transporta `turn`, `side_id` y `ball_id`.

`WildAdventureSession.submit_player_command()` es el punto canónico para la futura UI de Battle salvaje.

### Acción normal

MOVE/SWITCH no se reinventan. El comando contiene un `BattleAction`, se empareja con la respuesta rival y pasa por `AuthoritativeBattleServer.submit_turn()`.

### Captura inválida

No consume turno ni provoca respuesta rival. Las validaciones previas evitan además tocar inventario/RNG cuando el intento no es válido según los contratos existentes.

### Captura exitosa

La ball se consume según el sistema existente, la misma instancia capturada se enruta a party o storage y la sesión termina como `CAPTURED`. No hay respuesta del rival.

### Captura fallida

La ball se consume y el rival obtiene exactamente una respuesta legal. Esa respuesta pasa por `TurnExecutor`, por lo que no existe un mini-combate paralelo para Capture: PP, daño, status, KO, forced switch, END_TURN y RNG siguen usando el Battle Core existente.

## Cambios principales

- `modules/gameplay/wild_battle_command.gd`
- `modules/gameplay/wild_battle_command_result.gd`
- `modules/gameplay/wild_adventure_session.gd`
- `modules/battle/server/authoritative_battle_server.gd`
- `modules/battle/application/turn_executor.gd`
- `tests/battle_commands_test_suite.gd`
- `tests/battle_commands_audit_test_suite.gd`
- `tests/battle_commands_test_runner.gd`
- `.github/workflows/godot-tests.yml`
- ADR-014

## Auditoría adicional después del primer CI verde

El primer bloque de 42 checks pasó, pero no se cerró la fase con ese resultado. Se añadieron 11 checks adversariales extra para verificar explícitamente:

1. Capturar no consume PP del movimiento del jugador.
2. Tras fallo hay exactamente un `ACTION_USED` rival y exactamente un PP rival consumido.
3. El RNG de captura del intento válido no garantizado avanza exactamente una tirada de probabilidad en el contrato actual.
4. Una reacción forjada desde el mismo side se rechaza antes de ball, turn o RNG.
5. Con party de seis, Master Ball enruta la misma `CreatureInstance` a storage y no ejecuta respuesta rival.

Resultado dedicado tras esa auditoría: **53 PASS / 0 FAIL**.

## Gates verificados sobre el HEAD de auditoría

- Historical regression: **470 PASS / 0 FAIL**
- Inventory: **47 PASS / 0 FAIL**
- Savegame V2: **40 PASS / 0 FAIL**
- Savegame V2 adversarial: **8 PASS / 0 FAIL**
- Wild Encounters: **54 PASS / 0 FAIL**
- Logical Vertical Slice: **62 PASS / 0 FAIL**
- Overworld: **59 PASS / 0 FAIL**
- Battle Presentation: **43 PASS / 0 FAIL**
- Battle Commands: **53 PASS / 0 FAIL**
- Import headless: **PASS**
- Godot exacto: `4.7.stable.official.5b4e0cb0f`
- Workflow: **SUCCESS**

El gate de Battle Commands se elevó de 42 a **53** después de ampliar la auditoría.

## Límites y claims que NO hacemos

### Elección de acción rival

La fase valida que `opponent_action` sea una acción legal del lado contrario antes de mutar Capture. Sin embargo, la política que elige esa acción todavía vive en la capa de aplicación/presentación. Esto no equivale a autoridad de estrategia frente a un cliente hostil de red. Para multiplayer futuro, la selección rival deberá ser server-owned.

### API histórico de captura

`capture_current()` permanece para compatibilidad y regresión histórica. No tiene por sí solo la semántica completa de turno introducida aquí. La futura UI Bag/Capture debe llamar a `submit_player_command()`, no al método histórico directamente.

### Routing de captura

Los escenarios válidos actuales de party/storage están cubiertos, incluida party llena → storage. No se afirma que cualquier fallo interno imaginable de routing posterior a un `CaptureResult.SUCCESS` sea transaccionalmente imposible; si se introduce storage con límites/fallos externos en el futuro, esa frontera deberá revisarse.

## Fuera de alcance

- UI Bag/Capture;
- animaciones/sprites/audio de captura;
- Run;
- selector visual de Switch/reemplazo;
- IA rival estratégica;
- networking/multiplayer;
- assets finales de Roma/Pokémon.

## Próximo bloque recomendado

**FASE 15 — Battle Capture Presentation V1**.

Ahora sí existe el contrato necesario para exponer captura visualmente sin el exploit de balls gratis: la presentación puede listar balls poseídas, construir `WildBattleCommand.CAPTURE`, seleccionar una respuesta rival desde la política técnica actual y llamar exclusivamente a `submit_player_command()`.

La UI deberá demostrar tres caminos visibles: captura inválida sin gastar turno, captura fallida con represalia rival y captura exitosa con ownership real + retorno al Overworld.
