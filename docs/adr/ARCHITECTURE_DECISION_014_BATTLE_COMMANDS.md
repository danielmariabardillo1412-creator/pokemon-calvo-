# ADR-014 — Battle Commands V1

Fecha: 2026-08-30  
Rama: `feature/battle-commands-v1`  
Base: `feature/battle-presentation-v1`  
Estado: **ACCEPTED / VALIDATED PENDING FINAL DOC-HEAD CI**

## Contexto

FASE 13 hizo jugable la Battle real desde el Overworld, pero Capture todavía quedaba fuera del contrato de turno. El método histórico `WildAdventureSession.capture_current()` podía resolver una captura y, si fallaba, dejar la Battle activa sin ejecutar automáticamente la respuesta rival. Exponer ese método directamente desde UI habría permitido repetir intentos de captura sin represalia.

La solución no debe trasladar reglas de Capture o Inventory al Battle Core: `CaptureSystem`, `CaptureInventoryService`, party/storage y sus invariantes siguen siendo dominios separados.

## Decisión

Se introduce un límite de aplicación explícito en `WildAdventureSession`:

`submit_player_command(command, capture_rng, opponent_action)`

con un envelope `WildBattleCommand` que admite:

- `ACTION`: contiene un `BattleAction` canónico; MOVE/SWITCH siguen usando exactamente el contrato de Battle existente.
- `CAPTURE`: contiene la intención mínima de captura (`turn`, `side_id`, `ball_id`). La sesión deriva target, ownership y contexto de Battle desde su estado vivo y trusted; no acepta esos hechos desde el payload.

### ACTION

La sesión empareja la acción del jugador con una acción rival legal y las envía al `AuthoritativeBattleServer.submit_turn()` normal. El Battle Core conserva su autoridad sobre turn, actor, side, target, PP, switch y fase.

### CAPTURE inválida

Una captura que no supera validación —por ejemplo, item no poseído, ball inválida, turno/side incorrectos o RNG ausente— no consume turno ni ejecuta respuesta rival. Los contratos existentes de Capture/Inventory conservan además sus garantías de no consumir RNG cuando la entrada es inválida.

### CAPTURE exitosa

Una captura válida exitosa consume la ball según `CaptureInventoryService`, enruta la misma `CreatureInstance` a party o storage mediante `CaptureOwnershipRouter`, reconcilia estado post-Battle y completa la sesión con `CAPTURED`. No se ejecuta respuesta rival porque la Battle deja de existir como conflicto activo.

### CAPTURE fallida

Una captura válida fallida consume la ball y el intento de captura. Después se ejecuta exactamente una respuesta rival legal y el turno avanza exactamente una vez.

Para esto, `AuthoritativeBattleServer` expone un camino interno de reacción:

- `validate_reaction_action(action, skipped_side_id)`;
- `submit_reaction_turn(action, skipped_side_id)`.

`TurnExecutor.execute_reaction()` ejecuta la acción del lado que responde y reutiliza el mismo pipeline de Battle para:

- consumo de PP;
- accuracy/status/daño/efectos;
- KO y reemplazos forzados;
- status de fin de turno;
- triggers END_TURN;
- persistencia del RNG de Battle;
- avance de `state.turn` una sola vez.

No se introduce un `SKIP`/`NO_OP` público en `BattleAction`: el lado que gastó su comando en Capture se representa en la capa de aplicación, no como una acción libre falsificable dentro del Battle Core.

## Orden de validación

La acción de respuesta rival se valida **antes** de que Capture pueda tocar inventario o consumir RNG de captura. Así, un responder malformado no convierte una captura fallida en un turno gratis después de haber gastado el objeto.

Los tests adversariales demuestran además que una supuesta respuesta del mismo side del jugador se rechaza antes de mutar item, turn o RNG.

## Fronteras de autoridad

`submit_reaction_turn()` es infraestructura trusted de aplicación/servidor, no un comando pensado para exposición directa a clientes.

En esta fase, `opponent_action` se recibe ya seleccionado por la capa de aplicación/presentación y el servidor comprueba que sea **legal**. Esto NO demuestra todavía que un cliente de red no pueda influir en la estrategia rival. En una arquitectura multiplayer real, la selección de la acción del oponente deberá vivir en autoridad server-side.

El método histórico `capture_current()` se mantiene por compatibilidad con tests/vertical slices anteriores. La UI nueva de captura debe usar `submit_player_command()`; `capture_current()` no debe exponerse como endpoint de interacción de jugador.

## Invariantes demostrados

- un ACTION normal conserva el pipeline autoritativo previo;
- una captura fallida válida consume exactamente un turno;
- el jugador no consume PP de movimiento al capturar;
- el rival ejecuta exactamente una respuesta y consume exactamente un PP de ese movimiento;
- el RNG de captura no se toca en entradas inválidas;
- el intento válido no garantizado usa una sola tirada de probabilidad en el contrato actual;
- una respuesta rival inválida se rechaza antes de consumir ball/RNG/turn;
- una captura exitosa no provoca ataque posterior;
- con party llena, la captura exitosa conserva la misma instancia en storage;
- poison/status END_TURN sigue procesándose tras captura fallida;
- la respuesta rival puede causar KO, FINISHED y posterior settlement de derrota;
- los 470 checks históricos siguen verdes tras refactorizar `TurnExecutor`.

## Límites aceptados

- no hay botón Bag/Capture todavía;
- no hay animación de ball;
- no hay selección visual de balls;
- no se formalizan aún Run ni UI de Switch;
- no se resuelve IA estratégica;
- no se afirma seguridad de red para la elección de acción rival;
- no se elimina todavía el API histórico `capture_current()`.

## Evidencia de auditoría de código

Sobre el HEAD de auditoría previo a documentación:

- Historical regression: **470 PASS / 0 FAIL**
- Inventory: **47 PASS / 0 FAIL**
- Savegame V2: **40 PASS / 0 FAIL**
- Savegame V2 adversarial: **8 PASS / 0 FAIL**
- Wild Encounters: **54 PASS / 0 FAIL**
- Logical Vertical Slice: **62 PASS / 0 FAIL**
- Overworld: **59 PASS / 0 FAIL**
- Battle Presentation: **43 PASS / 0 FAIL**
- Battle Commands: **53 PASS / 0 FAIL**
- Godot: `4.7.stable.official.5b4e0cb0f`
- import headless: PASS

El gate CI de Battle Commands queda fijado a un mínimo de **53** checks para impedir regresión silenciosa de cobertura.
