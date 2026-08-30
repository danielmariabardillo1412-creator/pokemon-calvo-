# INFORME FINAL — FASE 19: TRAINER BATTLE SESSION V1

Fecha: 2026-08-30  
Rama: `feature/trainer-battle-session-v1`  
Base: `feature/battle-run-presentation-v1`  
PR: #13  
Estado: **CLOSED / VALIDATED**

## 1. Motivo de apertura

FASE 18 quedó técnicamente validada pero su cierre exigía dos acciones antes de continuar:

1. cerrar PR #12 sin merge;
2. revisar la siguiente frontera por dependencias reales y no asumir una fase por numeración.

Ambas condiciones se cumplieron.

No se encontró un roadmap prospectivo único que fijara una FASE 19 previamente acordada. La elección de Trainer Battle Session fue, por tanto, una decisión nueva derivada de la auditoría del repositorio, no una reconstrucción fingida de contexto perdido.

## 2. Decisión de dependencia

Se compararon dos fronteras principales:

- Bag/ITEM general en combate;
- combate contra entrenadores.

Bag se pospuso por su superficie semántica mucho mayor respecto al runtime actualmente soportado.

Trainer Battle se eligió porque reutiliza directamente:

- Battle Core;
- Party/CreatureInstance;
- Progression;
- contratos MOVE/SWITCH;
- settlement post-battle.

Además crea la frontera necesaria para futura IA/política de entrenadores sin mezclarla todavía con NPC o UI.

## 3. Implementación entregada

### `modules/gameplay/trainer_battle_session.gd`

Añade una sesión headless con:

- `READY -> BATTLE_ACTIVE -> COMPLETED`;
- trainer id obligatorio;
- roster jugador y rival con identidad estable;
- creación de `BattleState` real;
- `AuthoritativeBattleServer` como resolver;
- envío de acciones de jugador/rival a Battle Core;
- settlement VICTORY/DEFEAT;
- progresión del jugador en victoria;
- reconciliación post-battle;
- reset para siguiente combate.

No contiene reglas paralelas de daño, prioridad, PP, KO o switch.

### `modules/gameplay/trainer_battle_settlement.gd`

Resultado explícito de settlement con:

- ok/reason;
- player_won;
- session_completed;
- BattleOutcome;
- progression_events.

### Validación de roster

Se rechazan antes de crear BattleState:

- trainer id vacío;
- roster sin criatura viva;
- `instance_id` vacío;
- ids duplicados dentro del roster;
- identidad compartida entre jugador y rival.

### API deliberadamente ausente

Trainer Battle Session no expone:

- Capture;
- Run.

Esto mantiene las decisiones de las fases salvajes: captura y huida no se convierten por accidente en comandos genéricos de trainer battle.

## 4. Tests

Se añadieron:

- `tests/trainer_battle_session_test_suite.gd`;
- `tests/trainer_battle_session_audit_test_suite.gd`;
- `tests/trainer_battle_session_test_runner.gd`.

La suite base cubre contratos nominales y errores de ciclo de vida.

La auditoría adversarial cubre identidad corrupta, lados falsificados, actor falsificado, stale turns, no-mutación en rechazo, múltiples criaturas rivales, settlement duplicado y llamadas posteriores a cierre.

Resultado final del gate: **66 PASS / 0 FAIL**.

## 5. CI

Se añadió un workflow aislado:

`.github/workflows/trainer-battle-tests.yml`

Gate:

- Godot 4.7;
- fixtures PokeAPI fijados;
- import headless;
- `trainer_battle_session_test_runner.gd`;
- mínimo `>=66 PASS / 0 FAIL`;
- logs como artifact.

En el HEAD auditado previo al commit documental:

- Trainer Battle Session Tests: **completed / success**;
- Godot 4.7 Tests histórico: **completed / success**.

El workflow histórico conserva verdes las fases previas.

## 6. Correcciones encontradas durante la auditoría

La revisión en frío evitó dos errores de suposición antes de cierre:

1. `StatStages` no expone `is_neutral()`; el test se corrigió contra su API real.
2. `BattleEvent.ACTION_REJECTED` almacena el motivo en `metadata`, no en `data`; `TrainerBattleSession` se corrigió para leer el contrato existente.

Después se reforzó la frontera con rechazo explícito de ids vacíos/duplicados.

Estos cambios se hicieron antes de declarar la fase validada.

## 7. Lo que NO está terminado

FASE 19 no debe interpretarse como "combates de entrenadores terminados para el jugador".

Todavía faltan, por separado:

- presentación/UI específica o adaptación de la actual;
- NPC y trigger de combate en Overworld;
- diálogo pre/post batalla;
- trainer definitions/datos de equipos de producción;
- política/IA de decisión rival;
- recompensas y economía;
- multiplicador o reglas específicas de XP de trainer battle, si se deciden;
- Bag/ITEM general;
- networking;
- save/resume de trainer battle activo;
- arte final.

La fase entrega el **contrato lógico headless**, no el producto visual completo.

## 8. Riesgos que permanecen

### Acción rival suministrada externamente

La sesión recibe una acción rival candidata y Battle Core valida su legalidad. Esto es suficiente para la frontera local V1, pero no es una arquitectura segura de networking ni una IA rival.

### Semántica de rewards

Se reutiliza la progresión existente. No se ha definido todavía un bonus de XP, dinero o recompensa propia de entrenador.

### Datos de trainer roster

FASE 19 recibe `trainer_id + roster` confiables a nivel de aplicación. Aún no existe un catálogo/loader de entrenadores de producción.

## 9. Estado de ramas

La fase está apilada sobre FASE 18.

No se hace merge a `main`.

La estrategia del proyecto continúa siendo conservar la cadena validada en ramas feature y cerrar PRs sin merge cuando el bloque queda certificado.

## 10. Siguiente frontera recomendada

No debe abrirse automáticamente "FASE 20" por numeración.

La dependencia inmediata más razonable después de este bloque es decidir entre:

1. **Trainer Battle Presentation/Overworld seam**: hacer ejecutable el combate contra entrenador desde una vertical slice técnica; o
2. **Trainer Opponent Policy V1**: mover la selección de acción rival a una política explícita antes de conectar NPC/UI.

Recomendación técnica: **Trainer Opponent Policy V1 primero**, porque reduce el acoplamiento de presentación y deja una frontera reutilizable tanto para NPC local como para futuros bots/entrenamiento. Después, conectar la presentación/Overworld.

Antes de abrir ese bloque se debe verificar el HEAD documental final de FASE 19 y cerrar PR #13 sin merge.
