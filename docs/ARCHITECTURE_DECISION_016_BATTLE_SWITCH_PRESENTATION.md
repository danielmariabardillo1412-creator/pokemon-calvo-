# ADR-016 — Battle Switch Presentation V1

Fecha: 2026-08-30  
Rama: `feature/battle-switch-presentation-v1`  
Base: `feature/battle-capture-presentation-v1`  
Estado: **ACCEPTED / VALIDATION FINAL PENDIENTE DEL HEAD DOCUMENTAL**

## Contexto

FASE 15 dejó MOVE y CAPTURE atravesando el mismo límite de aplicación visible:

`BattlePresentationController -> WildAdventureSession.submit_player_command(...) -> AuthoritativeBattleServer / Battle Core`

Antes de abrir un comando nuevo como Run, se auditó el código canónico existente. No se encontró un roadmap explícito que asignara formalmente una FASE 16. La decisión de exponer Switch se deriva de una frontera ya implementada y probada en Battle Core:

- `BattleAction.SWITCH` ya existe;
- `WildBattleCommand.ACTION` ya transporta `BattleAction`;
- `AuthoritativeBattleServer` ya valida ownership, actor activo, target no activo y target vivo;
- `TurnResolver` ya ordena Switch antes de MOVE;
- `TurnExecutor` ya cambia `active_id`, limpia stages/volatile del saliente y emite `BattleEvent.SWITCHED`;
- el reemplazo tras KO ya existe como política automática del core.

Por tanto, FASE 16 no inventa reglas de cambio. Expone en la presentación técnica una capacidad canónica que ya existía.

## Decisión

`BattlePresentationController` incorpora un control técnico de Switch electivo compuesto por:

- un `OptionButton` con candidatos vivos, propios y no activos;
- un botón `Switch`;
- una ruta `submit_player_switch(instance_id)` que construye un `BattleAction.SWITCH`, lo envuelve en `WildBattleCommand.ACTION` y delega en `WildAdventureSession.submit_player_command()`.

La UI no modifica directamente `BattleSide.active_id`, `StatStages`, estados volátiles, prioridad, HP, PP ni turnos.

## Fuente de verdad de candidatos

La lista visible se deriva del `BattleState` vivo y de la `BattleSide` que posee al actor activo. Solo se ofrecen IDs que:

1. pertenecen al roster autoritativo del lado del jugador;
2. no son el `active_id` actual;
3. resuelven a una `CreatureInstance` real del estado;
4. no están KO.

El orden conserva `BattleSide.party_ids`.

La autoridad final sigue siendo `AuthoritativeBattleServer`: aunque se invoque `submit_player_switch()` directamente con un ID no poseído o KO, el comando se rechaza sin consumir turno ni provocar respuesta rival.

## Identidad estable del selector

La auditoría post-green detectó un riesgo de presentación: resolver el target únicamente mediante `selected index -> lista recalculada` podía convertir una selección obsoleta en otra criatura si la lista autoritativa cambiaba entre render y pulsación.

Se endureció el control almacenando el `instance_id` exacto como metadata de cada item del `OptionButton`. `_on_switch_pressed()` envía esa identidad estable en vez de reinterpretar el índice contra una lista nueva.

La autoridad server-side sigue validando el ID al ejecutar el comando; la metadata evita además que la propia UI cambie silenciosamente la intención del jugador.

## Semántica de Switch electivo

Un Switch válido consume un turno normal y usa la semántica ya existente de Battle Core:

- Switch se resuelve antes de MOVE por prioridad canónica;
- el Pokémon saliente deja de ser activo;
- sus stat stages se reinician;
- sus estados volátiles se limpian;
- se emite `BattleEvent.SWITCHED` con `forced=false`;
- la respuesta rival legal se ejecuta una vez y golpea al nuevo activo si corresponde;
- la UI refresca identidad, HP y nuevos candidatos desde el estado autoritativo resultante.

Switch no consume Capture RNG ni objetos de inventario.

## Reemplazo forzado tras KO

Esta fase **no** convierte el reemplazo tras KO en una elección manual del jugador.

El comportamiento canónico actual de `TurnExecutor` permanece intacto: cuando el activo cae y existe un reemplazo vivo, el core selecciona el primer reemplazo disponible según el roster y ejecuta un Switch forzado con metadata `forced=true`.

La responsabilidad de FASE 16 es representar correctamente el resultado. La auditoría añade un caso donde una captura fallida provoca represalia, KO del activo y reemplazo automático; la presentación debe:

- mostrar al nuevo activo y su HP;
- mantener la Battle activa;
- no volver a ofrecer al Pokémon KO como candidato.

Elegir manualmente el reemplazo forzado requeriría cambiar la máquina de estados/contrato de turnos y queda expresamente fuera de FASE 16.

## Escena técnica

`res://scenes/overworld/technical_overworld.tscn` sigue siendo la vertical slice asset-free.

Su bootstrap añade un segundo miembro de party:

- `technical_starter`: Bulbasaur Lv.5;
- `technical_bench`: Charmander Lv.5.

`technical_bench` existe exclusivamente como fixture QA para poder demostrar Switch en la escena ejecutable. No define el roster inicial, starter selection ni balance final del juego.

El flujo técnico validado queda:

`Overworld -> Encounter -> Battle visible -> Switch -> respuesta rival -> Capture -> confirmación -> Overworld`

## Auditoría y diagnóstico CI

El primer CI funcional de FASE 16 pasó con **35 PASS / 0 FAIL**. La fase no se cerró ahí.

La auditoría posterior añadió:

- selector con múltiples candidatos y orden estable;
- binding por metadata de identidad;
- target KO oculto/rechazado;
- target no poseído rechazado sin turno ni respuesta;
- inventario intacto tras Switch;
- Capture RNG intacto tras Switch;
- prioridad Switch-before-Move;
- limpieza de stages/volatile;
- daño de la respuesta sobre el nuevo activo;
- reemplazo forzado tras KO y refresco de presentación;
- integración de escena Switch -> Capture -> retorno al Overworld.

Durante esa auditoría, una constante de test inexistente (`WildAdventureSession.ACTIVE`) produjo un parse error y aparentó un runner colgado. Se verificó el contrato canónico y se corrigió a `WildAdventureSession.BATTLE_ACTIVE`.

Además, el runner dedicado quedó envuelto en `timeout 20s` y cada caso imprime un marcador `BSP_TEST`, de modo que un futuro parse error o cuelgue queda acotado y diagnosticable en CI en lugar de consumir el timeout global del job.

Tras la corrección, la suite ampliada pasó **49 PASS / 0 FAIL** y el gate CI quedó fijado en un mínimo de 49.

## Invariantes demostrados

- Switch electivo usa el command boundary canónico; no hay mutación directa desde UI;
- solo se muestran candidatos propios, vivos y no activos;
- el orden de candidatos sigue el roster autoritativo;
- la identidad seleccionada queda ligada al `instance_id`, no solo al índice visual;
- targets no poseídos y KO son rechazados sin avanzar turno;
- Switch válido consume exactamente un turno;
- Switch tiene prioridad sobre la respuesta MOVE según Battle Core;
- el saliente no recibe el golpe de la respuesta posterior;
- el entrante sí recibe la respuesta cuando corresponde;
- stages y volatile del saliente se limpian por el core;
- la respuesta rival consume su PP una sola vez;
- Switch no consume Capture RNG;
- Switch no consume inventario;
- el candidato anterior vuelve a aparecer tras cambiar, si sigue vivo;
- el reemplazo automático tras KO se refleja correctamente en UI;
- el Pokémon KO no se ofrece como siguiente candidato;
- la escena técnica completa Switch y después Capture sin descongelar prematuramente el Overworld.

## Límites aceptados

- UI técnica, no diseño gráfico final;
- no sprites, animaciones ni layout final de party;
- no validación pixel-perfect/manual a 640×360 en esta fase; la evidencia es funcional/headless;
- no elección manual de reemplazo forzado tras KO;
- no Run;
- no IA estratégica;
- no networking/multiplayer;
- no cambios de reglas de Battle Core;
- el segundo miembro de party de la escena es fixture QA, no balance definitivo.

## Evidencia de código antes del HEAD documental

GitHub Actions run `33279617197`, Godot `4.7.stable.official.5b4e0cb0f`, Ubuntu 24.04:

- Historical regression: **470 PASS / 0 FAIL**
- Inventory: **47 PASS / 0 FAIL**
- Savegame V2: **40 PASS / 0 FAIL**
- Savegame V2 adversarial: **8 PASS / 0 FAIL**
- Wild Encounters: **54 PASS / 0 FAIL**
- Logical Vertical Slice: **62 PASS / 0 FAIL**
- Overworld: **59 PASS / 0 FAIL**
- Battle Presentation: **43 PASS / 0 FAIL**
- Battle Commands: **53 PASS / 0 FAIL**
- Battle Capture Presentation: **68 PASS / 0 FAIL**
- Battle Switch Presentation: **49 PASS / 0 FAIL**
- import headless: **PASS**

El cierre definitivo depende de repetir estos gates sobre el HEAD que contiene la documentación final.