# INFORME FINAL — FASE 13: Battle Presentation V1

Fecha: 2026-08-29  
Rama: `feature/battle-presentation-v1`  
Base: `feature/overworld-core-v1`  
PR: #7  
Motor CI: `4.7.stable.official.5b4e0cb0f`

## Estado

**FASE_13_STATUS = CLOSED / VALIDATED**

Este cierre queda condicionado al workflow del HEAD final de documentación/código. El informe registra los gates ya repetidos en verde tras la auditoría de código; el HEAD documental debe conservarlos antes de considerar definitivo el cierre operativo del PR.

## Qué demuestra esta fase

El proyecto ya puede pasar desde exploración física a una Battle visual técnica y jugar turnos reales utilizando el mismo Battle Core autoritativo construido en fases anteriores.

Flujo:

`input -> movimiento físico -> encounter -> Battle real -> presentación -> selección de movimiento -> BattleAction -> servidor autoritativo -> eventos/HP -> fin -> settlement -> retorno al Overworld`

La presentación no es una simulación separada: observa y controla la misma `WildAdventureSession`, las mismas `CreatureInstance` y el mismo `BattleState` que usa la vertical slice.

## Runtime añadido

### Battle Presentation

`modules/battle/presentation/battle_presentation_controller.gd`

Superficie técnica que muestra:

- turno actual;
- Pokémon del jugador y salvaje;
- niveles;
- HP actual/máximo y barras;
- hasta cuatro movimientos con PP;
- log de `BattleEvent` semánticos;
- resultado de victoria/derrota;
- confirmación para volver al Overworld.

Un click de movimiento no aplica daño desde UI: construye un `BattleAction` y llama a `WildAdventureSession.submit_turn()`. La autoridad existente valida y resuelve el turno.

### Rival técnico

`modules/battle/presentation/simple_battle_opponent_policy.gd`

Elige de manera determinista el primer movimiento usable del rival y devuelve una acción normal. No altera PP/HP/RNG ni contiene reglas de daño.

Sirve para hacer jugable el slice técnico, no pretende ser IA final.

### Overworld <-> Battle

La escena técnica de FASE 12 incorpora la presentación dentro de `CanvasLayer`.

Al comenzar un encuentro:

- la Battle real ya existe;
- el jugador del Overworld se congela;
- se abre la UI de Battle;
- las acciones pasan por la sesión/servidor;
- al terminar se ejecuta settlement real;
- el resultado queda visible;
- al confirmar, `WildAdventureSession` pasa de `COMPLETED` a `READY`;
- la UI se oculta y el movimiento vuelve a estar habilitado.

## Auditoría antes del cierre

El primer CI de FASE 13 ya estaba completamente verde, pero se hizo una revisión adicional antes de cerrar.

Se corrigieron dos acoplamientos/defectos de presentación:

1. **IDs de side hardcodeados.** La primera versión construía acciones usando `side_a` / `side_b`. Aunque coincidía con la sesión actual, hacía que UI dependiera de una convención interna. Ahora los sides se derivan con `BattleState.side_for_creature(...)` a partir de la propiedad real del actor/objetivo.
2. **Estado visual tras FINISHED.** La UI mostraba siempre el número del siguiente turno. Ahora representa explícitamente `Battle finished` y los botones solo son interactivos durante `WAITING_FOR_ACTIONS`.

El workflow completo volvió a verde después de estas correcciones.

## Cobertura Battle Presentation

La suite dedicada demuestra, entre otros:

- carga del catálogo runtime normalizado;
- Battle real activa antes de presentar;
- política rival crea actor/target/side/turn/move válidos;
- política rival no consume PP ni muta estado al seleccionar;
- política rival rechaza Battle terminada/side desconocido;
- controlador inicialmente oculto;
- apertura únicamente sobre Battle activa;
- movimientos disponibles y botones sincronizados;
- HP de jugador/rival sincronizado con las instancias vivas;
- movimiento inválido no emite eventos, no avanza turno y no consume PP;
- no se puede volver al Overworld a mitad de Battle;
- movimiento válido produce eventos y pasa por autoridad sin `ACTION_REJECTED`;
- turno avanza y HP visual permanece sincronizado;
- victoria determinista real;
- settlement deja sesión `COMPLETED` con motivo VICTORY;
- overlay permanece hasta confirmación;
- confirmación ejecuta `COMPLETED -> READY`;
- señal de cierre conserva el motivo de finalización;
- escena técnica arranca Battle desde grass real;
- overlay Battle se hace visible;
- Overworld queda congelado;
- controles de movimiento aparecen.

## Gates verificados tras auditoría

- Historical regression: **470 PASS / 0 FAIL**
- Inventory: **47 PASS / 0 FAIL**
- Savegame V2: **40 PASS / 0 FAIL**
- Savegame V2 adversarial: **8 PASS / 0 FAIL**
- Wild Encounters: **54 PASS / 0 FAIL**
- Logical Vertical Slice: **62 PASS / 0 FAIL**
- Overworld: **59 PASS / 0 FAIL**
- Battle Presentation: **43 PASS / 0 FAIL**
- Import headless: **PASS**
- Godot exacto: `4.7.stable.official.5b4e0cb0f`
- Workflow post-auditoría: **SUCCESS**
- Merge a `main`: **NO**

El diagnóstico `Parse JSON failed` del test histórico de save corrupto es intencionado y el test termina en PASS. Los warnings Node.js/punycode/url.parse observados proceden de GitHub Actions y no de Godot ni del código del juego.

## Captura visual diferida por diseño

FASE 13 no añade botón de captura aunque el sistema lógico de captura ya existe.

Motivo: actualmente `WildAdventureSession.capture_current()` no forma parte del contrato de acciones por turno del Battle Core. En un fallo de captura la Battle sigue activa, pero no existe todavía el contrato que obligue a ejecutar la respuesta del rival como parte de ese turno.

Poner un botón ahora permitiría potencialmente repetir intentos sin represalia. En vez de ocultar ese defecto bajo UI, se deja explícitamente como frontera del siguiente diseño.

## Fuera de alcance

- sprites/animaciones Pokémon finales;
- UI gráfica final de Roma;
- captura como comando de turno;
- bolsa/items de Battle;
- switch visual y selección de reemplazo;
- huida;
- IA estratégica;
- audio;
- multiplayer/networking;
- mapa romano final.

## Próximo bloque recomendado

Antes de añadir botones de Bag/Capture/Switch a la interfaz, conviene formalizar **Battle Commands V1**: acciones no-movimiento que tengan semántica de turno explícita y autoritativa.

La prioridad técnica es Capture/Item como comando de Battle: validar ownership/inventario, consumir el objeto solo cuando corresponda, determinar si consume turno, ejecutar respuesta rival tras fallo y terminar correctamente la Battle tras éxito. Después la UI puede exponerlo sin duplicar reglas ni introducir exploits de flujo.
