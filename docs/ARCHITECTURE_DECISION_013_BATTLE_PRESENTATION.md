# ADR-013 — Battle Presentation V1

Fecha: 2026-08-29  
Rama: `feature/battle-presentation-v1`  
Base: `feature/overworld-core-v1`  
Estado: **ACCEPTED / VALIDATED**

## Contexto

FASE 12 dejó validado el handoff físico `Overworld -> Battle`: una zona de encuentro puede iniciar una Battle lógica real y congelar el movimiento del jugador. Sin embargo, la escena técnica solo mostraba un label; el usuario todavía no podía observar HP/turnos ni enviar acciones de combate desde una superficie visual.

El siguiente límite debía hacer la Battle jugable sin trasladar reglas de dominio a la UI y sin crear una segunda implementación paralela del combate.

## Decisión

Se añade una capa de presentación técnica, asset-free, compuesta por dos responsabilidades explícitas.

### `BattlePresentationController`

`modules/battle/presentation/battle_presentation_controller.gd` es un `Control` que:

- recibe por inyección la `WildAdventureSession` activa y el `DefinitionCatalog`;
- lee el `BattleState` y las `CreatureInstance` vivas existentes;
- muestra turno, especie, nivel y HP de ambos participantes;
- expone hasta cuatro movimientos con PP;
- convierte una pulsación de UI en un `BattleAction` normal;
- envía el turno mediante `WildAdventureSession.submit_turn()` al servidor autoritativo existente;
- renderiza los `BattleEvent` semánticos devueltos por el Core;
- al terminar la Battle delega el settlement a `WildAdventureSession.settle_finished_battle()`;
- mantiene visible el resultado hasta que el usuario confirma el retorno;
- el retorno ejecuta `COMPLETED -> READY`, oculta la presentación y reanuda el Overworld.

La presentación no calcula daño, accuracy, prioridad, estados, KO, XP ni evolución. Tampoco muta directamente HP o PP.

### `SimpleBattleOpponentPolicy`

`modules/battle/presentation/simple_battle_opponent_policy.gd` es una política técnica determinista para el rival. Selecciona el primer movimiento actualmente usable y construye un `BattleAction` ordinario.

No resuelve resultados, no consume PP por su cuenta, no toca RNG y no muta el estado. La autoridad sigue siendo `AuthoritativeBattleServer` / `TurnExecutor`.

No se considera IA estratégica final; es únicamente una fuente mínima de acciones legales para poder recorrer el ciclo visual completo.

## Frontera de autoridad

La UI deriva los IDs de participante desde la propiedad real del `BattleState` mediante `side_for_creature(...)`. No conoce ni depende de nombres convencionales como `side_a`/`side_b`.

Esta corrección salió de la auditoría posterior al primer CI verde: la primera versión del controlador sí horneaba esos IDs. Se eliminó ese acoplamiento antes de aceptar la fase.

Los botones de movimiento solo permanecen activos en `WAITING_FOR_ACTIONS`; el estado `FINISHED` se representa explícitamente como Battle terminada.

## Integración con Overworld

`technical_overworld.tscn` conserva el Overworld físico de FASE 12 y añade `CanvasLayer/BattlePresentation`.

Flujo validado:

`movimiento físico -> step -> encounter zone -> WildAdventureSession -> Battle real -> BattlePresentationController -> BattleAction -> servidor autoritativo -> BattleEvent -> settlement -> COMPLETED -> READY -> Overworld reanudado`

Al iniciar Battle, `OverworldPlayer.movement_enabled = false`. La presentación se abre sobre la misma sesión. Tras confirmar el resultado, la señal `battle_closed(reason)` reactiva el movimiento.

## Captura deliberadamente NO expuesta todavía

La captura lógica existente funciona correctamente en la vertical slice, pero `WildAdventureSession.capture_current()` todavía no está modelada como una acción de turno del Battle Core.

Si la UI expusiera ahora un botón de captura, un intento fallido podría dejar la Battle activa sin que el rival recibiera automáticamente su turno. Eso permitiría encadenar intentos de captura sin represalia y sería una semántica de juego incorrecta.

Por ello FASE 13 **no añade un botón de captura falso**. Antes de presentarlo visualmente, Capture/Item debe entrar en un contrato explícito de comandos de Battle donde quede definido consumo de turno, validación, consumo de inventario y respuesta rival.

## Invariantes

- la UI no decide resultados de combate;
- las acciones se validan por la autoridad existente;
- un movimiento inválido desde presentación no avanza turno ni consume PP;
- la política rival no muta estado al elegir;
- HP mostrado refleja las mismas `CreatureInstance` que usa Battle;
- no puede volver al Overworld mientras la sesión siga en Battle activa;
- tras settlement y confirmación, la sesión queda `READY` y el Overworld vuelve a moverse;
- los IDs de side se derivan del estado vivo, no de literales de UI;
- la presentación no depende de sprites finales ni de la librería gráfica local masiva.

## Evidencia

CI posterior a la auditoría de código:

- Historical regression: **470 PASS / 0 FAIL**
- Inventory: **47 PASS / 0 FAIL**
- Savegame V2: **40 PASS / 0 FAIL**
- Savegame V2 adversarial: **8 PASS / 0 FAIL**
- Wild Encounters: **54 PASS / 0 FAIL**
- Logical Vertical Slice: **62 PASS / 0 FAIL**
- Overworld: **59 PASS / 0 FAIL**
- Battle Presentation: **43 PASS / 0 FAIL**
- Godot: `4.7.stable.official.5b4e0cb0f`
- import headless: **PASS**
- workflow: **SUCCESS**

El único error impreso durante la regresión histórica es el diagnóstico intencionado del test de JSON corrupto, que termina en PASS. Los avisos de Node.js de GitHub Actions pertenecen al runner/actions y no son defectos del producto.

## Consecuencias

### Positivas

- primer combate técnicamente jugable desde el Overworld;
- UI y dominio siguen desacoplados;
- la futura presentación con sprites/animaciones puede reemplazar la superficie técnica sin reescribir Battle;
- el ciclo visual ya atraviesa el servidor autoritativo y settlement reales;
- se ha identificado explícitamente la próxima frontera necesaria para captura/items como acciones de Battle.

### Límites aceptados

- presentación técnica sin arte final;
- rival determinista mínimo, no IA estratégica;
- solo movimientos en la UI V1;
- sin switch, bag/capture visual, run, animaciones ni audio;
- sin multiplayer;
- sin mapa romano final.
