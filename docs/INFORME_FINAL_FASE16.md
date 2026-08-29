# INFORME FINAL — FASE 16: Battle Switch Presentation V1

Fecha: 2026-08-30  
Rama: `feature/battle-switch-presentation-v1`  
Base: `feature/battle-capture-presentation-v1`  
PR: #10  
Motor CI: `4.7.stable.official.5b4e0cb0f`

## Estado

**FASE_16_STATUS = CLOSED / VALIDATED, condicionado al workflow verde del HEAD documental final**

Este informe forma parte del HEAD que debe ejecutar el workflow completo. Si dicho HEAD no conserva todos los gates indicados abajo, el cierre deja de ser válido y FASE 16 debe reabrirse.

## Por qué Switch fue el siguiente bloque

No se encontró un roadmap explícito que denominara formalmente una FASE 16. Se auditó primero la arquitectura real.

Battle Core ya poseía `BattleAction.SWITCH`, validación autoritativa, prioridad, limpieza de stages/volatile, eventos semánticos y reemplazo automático tras KO. En cambio, Run todavía no tiene un contrato canónico formalizado.

Por eso el siguiente paso de menor riesgo fue exponer Switch en la presentación sin inventar una segunda implementación de reglas.

## Qué cambia

La Battle técnica ya permite elegir un Pokémon vivo de la party y ejecutar un cambio electivo desde la misma superficie visible que MOVE y CAPTURE.

Flujo:

`Overworld -> Encounter -> Battle visible -> MOVE / SWITCH / CAPTURE -> submit_player_command -> autoridad -> eventos/estado -> presentación`

`BattlePresentationController` añade:

- selector técnico de candidatos de Switch;
- botón `Switch`;
- `submit_player_switch(instance_id)`;
- renderizado semántico de `BattleEvent.SWITCHED`;
- refresco del nuevo activo, HP y candidatos tras resolver el turno.

## Autoridad y reglas

La UI no cambia `active_id` directamente y no limpia estados por su cuenta.

Un Switch construye `BattleAction.SWITCH`, se transporta como `WildBattleCommand.ACTION` y entra en `WildAdventureSession.submit_player_command()`.

`AuthoritativeBattleServer` sigue siendo quien decide si el target es válido. `TurnResolver` mantiene la prioridad y `TurnExecutor` aplica el cambio y sus efectos canónicos.

## Selector seguro

Solo se muestran criaturas que pertenecen al lado del jugador, no son la activa y siguen vivas. Se conserva el orden del roster autoritativo.

La auditoría post-green endureció además la identidad del selector: cada opción almacena su `instance_id` como metadata y el botón envía ese ID exacto. La intención del jugador ya no depende de reinterpretar un índice contra una lista potencialmente modificada.

## Semántica validada

Un Switch válido:

- consume un turno;
- ocurre antes del MOVE rival;
- cambia el activo mediante Battle Core;
- limpia stages y volatile del Pokémon saliente;
- deja intactos inventario y Capture RNG;
- provoca exactamente una respuesta rival legal;
- hace que esa respuesta afecte al nuevo activo cuando corresponde;
- vuelve a ofrecer al antiguo activo como candidato si sigue vivo.

Targets no poseídos o KO son rechazados sin consumir turno ni respuesta rival.

## Reemplazo tras KO

El reemplazo forzado sigue siendo automático en Battle Core. FASE 16 no cambia la máquina de estados para pedir una elección manual.

Se añadió una prueba adversarial completa:

`captura fallida -> represalia -> activo a 0 HP -> forced SWITCHED -> nuevo activo -> Battle continúa`

La UI refresca correctamente al nuevo activo y no ofrece al Pokémon KO como candidato.

Una futura elección manual de reemplazo forzado debe tratarse como un cambio de contrato/máquina de estados independiente, no como un detalle cosmético de este selector.

## Escena técnica

`technical_overworld` incorpora un segundo Pokémon de QA (`technical_bench`, Charmander Lv.5) para que Switch sea ejecutable dentro de la vertical slice.

Ese segundo miembro no define el roster inicial ni el balance final.

La integración headless demuestra:

`Overworld -> Battle -> Switch -> Battle sigue congelando Overworld -> Capture -> confirmación -> Overworld reanudado`

## Auditoría posterior al primer verde

El primer CI de FASE 16 terminó en **35 PASS / 0 FAIL**, pero no se aceptó como cierre suficiente.

La auditoría posterior amplió la cobertura a identidad estable del selector, múltiples candidatos, target KO/no poseído, invariantes de RNG/inventario, prioridad, limpieza de estado y reemplazo forzado tras KO.

Durante esa ampliación apareció un fallo de test real: se escribió `WildAdventureSession.ACTIVE`, constante inexistente. El runner parecía quedar esperando porque el script no podía instanciarse tras el parse error.

Se corrigió usando el contrato real `WildAdventureSession.BATTLE_ACTIVE` y se mantuvo una protección adicional en CI: la suite dedicada se ejecuta bajo `timeout 20s` y emite marcadores por caso. Así un futuro fallo de parseo/cuelgue queda visible y acotado.

Resultado auditado previo a documentación: **49 PASS / 0 FAIL**.

## Gates auditados antes del HEAD documental

GitHub Actions run `33279617197`:

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
- Import headless: **PASS**
- Godot exacto: `4.7.stable.official.5b4e0cb0f`
- Merge a `main`: **NO**

El workflow del HEAD documental final debe repetir estos gates antes de cerrar PR #10.

## Fuera de alcance

- Run;
- elección manual de reemplazo forzado tras KO;
- UI final con sprites/animaciones;
- pixel-perfect/manual visual QA;
- IA estratégica;
- networking/multiplayer;
- reglas nuevas de Battle Core;
- mapa/assets definitivos de Roma/Pokémon.

## Próximo bloque

No se debe iniciar una FASE 17 hasta que el HEAD documental de FASE 16 haya pasado CI y PR #10 haya quedado cerrado sin merge.

Después del cierre, la siguiente decisión debe volver a partir de una auditoría del contrato canónico. Run es una frontera pendiente evidente, pero a diferencia de Switch todavía requiere formalizar semántica de dominio/aplicación antes de añadir un botón visible.