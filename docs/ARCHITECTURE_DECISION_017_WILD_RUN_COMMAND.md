# ADR-017 — Wild Run Command V1

Fecha: 2026-08-30  
Rama: `feature/wild-run-command-v1`  
Base: `feature/battle-switch-presentation-v1`  
Estado: **ACCEPTED / VALIDACIÓN FINAL PENDIENTE DEL HEAD DOCUMENTAL**

## Contexto

FASE 16 dejó MOVE, CAPTURE y SWITCH utilizables en la vertical slice técnica y cerró la frontera de presentación de Switch. La revisión del repositorio no encontró un roadmap canónico que asignara formalmente una FASE 17.

La siguiente frontera se eligió por dependencia arquitectónica: antes de añadir un botón **Run** a la UI, debía existir y probarse una semántica de huida independiente de la presentación, del mismo modo que FASE 14 formalizó Capture como comando antes de que FASE 15 lo expusiera en pantalla.

`BattleAction` representa acciones genéricas del Battle Core y actualmente cubre MOVE/SWITCH. Huir no es una operación genérica de una batalla cualquiera: depende de que la sesión sea un encuentro salvaje y afecta al ciclo de aventura. Por ello no se amplía `BattleAction` con una semántica que el core genérico no necesita.

## Decisión

Se incorpora `WildBattleCommand.RUN` en el límite de aplicación existente:

`BattlePresentation/Application caller -> WildBattleCommand.RUN -> WildAdventureSession.submit_player_command()`

RUN no transporta Speed, probabilidades, identidad del rival ni ningún otro hecho confiable. `WildAdventureSession` deriva actor, rival y estado desde la batalla viva autoritativa.

El resultado expone un `WildEscapeResolution` con:

- `escaped`;
- número de `attempt`;
- `odds`;
- `roll` cuando hubo RNG;
- `rng_consumed`;
- `reason` semántico en rechazo.

## Ruleset V1

La política se encapsula en `WildEscapeRuleset`, ID estable:

`calvo_escape_v1`

Reglas:

1. Speed inválida (`<= 0`) o intento inválido se rechazan sin RNG.
2. Si `player_speed >= wild_speed`, la huida es automática y no consume RNG.
3. En otro caso:

   `odds = floor(player_speed * 128 / wild_speed) + 30 * attempt`

4. Si `odds > 255`, la huida es automática y no consume RNG.
5. Si no es automática, se consume exactamente una tirada inyectada uniforme `0..255`; hay éxito cuando `roll < odds`.
6. Cada intento de RUN válido incrementa el contador del encuentro. Comandos inválidos no lo incrementan.

Esta fórmula conserva una forma reconocible de los juegos principales —velocidad relativa, mejora por intentos y tirada acotada— pero **no reclama paridad bit-perfect con una generación concreta de Pokémon**. Las fórmulas oficiales han variado entre generaciones; `calvo_escape_v1` es una política explícita del proyecto y puede evolucionar mediante otro ID de ruleset.

## Speed persistente

V1 usa `CreatureInstance.stats.speed`, es decir, Speed persistente derivada del Pokémon.

No usa `StatStages.SPEED` ni modificaciones transitorias de Battle, y no interpreta parálisis como modificador de esta fórmula de aplicación. Esta separación se prueba explícitamente: alterar el stage de Speed no cambia `odds`.

Si en el futuro se decide que la huida debe usar una Speed efectiva de combate, será un cambio consciente del ruleset y no una consecuencia accidental del TurnExecutor.

## Orden de validación y RNG

La frontera valida primero:

- batalla activa y fase correcta;
- turno;
- actor/lado del jugador;
- participante del comando;
- existencia de rival y stats;
- Speed estructural válida.

Una Speed corrupta se rechaza como `invalid_escape_speed` **antes** de exigir reacción rival y antes de consumir RNG.

Para una huida no garantizada, la reacción rival se valida antes de la tirada de escape. Así una reacción malformada no puede consumir intento, turno ni RNG. La reacción se vuelve a ejecutar mediante `AuthoritativeBattleServer.submit_reaction_turn()` solo después de un fallo válido de huida.

La prevalidación y la ejecución usan la misma validación autoritativa de reacción y no existe mutación de Battle entre ambas. Por tanto, una reacción previamente aceptada no debería poder ser rechazada en el submit salvo que ese contrato cambie en una fase futura.

## Semántica de éxito

Una huida exitosa:

- consume el intento/turno semántico de RUN;
- no ejecuta respuesta rival;
- no consume PP del jugador;
- no consume inventario ni Capture RNG;
- no captura ni transfiere ownership del Pokémon salvaje;
- no concede XP;
- no cura HP;
- conserva estado persistente;
- reconcilia y limpia modificadores exclusivamente transitorios de Battle;
- completa la sesión con `COMPLETED / FLED`;
- elimina la batalla/encuentro transitorio activo.

El contador del intento que produjo la huida permanece observable mientras la sesión está COMPLETED y se reinicia al confirmar `reset_after_completion()`.

## Semántica de fallo

Una huida válida fallida:

- consume exactamente una tirada de Escape RNG;
- incrementa el contador de intentos;
- consume un turno;
- ejecuta exactamente una reacción rival legal mediante el pipeline autoritativo existente;
- ejecuta también el pipeline de fin de turno del core, incluidos estados persistentes como poison;
- puede producir KO y finalizar Battle;
- si Battle termina, el settlement existente decide victoria/derrota; RUN no crea una vía paralela de settlement.

## Ciclo del contador

`_escape_attempts` se reinicia en los límites de ciclo que invalidan el encuentro anterior:

- inicio/no inicio de un nuevo encounter;
- Capture exitosa;
- settlement de Battle;
- load exitoso;
- `reset_after_completion()`.

Después de FLED queda temporalmente visible hasta `reset_after_completion()` para preservar la evidencia semántica del último resultado.

## Auditoría post-green

La primera suite dedicada pasó **43 PASS / 0 FAIL**. No se cerró la fase con ese resultado.

Se añadió una auditoría adversarial separada que cubre, entre otros:

- igualdad de Speed como escape garantizado;
- `odds > 255` como escape garantizado;
- frontera exacta `roll == odds` y comparación estricta `<`;
- inputs inválidos sin RNG;
- participante incorrecto sin efectos laterales;
- independencia entre Escape RNG y Capture RNG;
- inventario intacto;
- independencia de stat stages;
- poison/end-turn tras fallo;
- FLED sin XP, curación ni ownership;
- conservación del estado persistente;
- reinicio del contador entre encuentros.

La auditoría detectó además una sutileza defensiva: una Speed públicamente corrompida a cero podía exigir primero una reacción rival porque `odds()` devolvía cero. Se endureció la sesión para rechazar `invalid_escape_speed` antes de la validación de reacción y se añadió una prueba que demuestra turno/intento/RNG intactos.

Tras ese hardening, la suite dedicada queda en **71 PASS / 0 FAIL**.

## Límites aceptados

- no botón Run ni presentación visual en esta fase;
- no animación/transición final de huida;
- no habilidades como Run Away;
- no objetos como Smoke Ball/Poké Doll;
- no reglas de huida de trainer battles;
- no trapping/Mean Look u otros bloqueos especiales;
- no networking/multiplayer;
- no afirmación de paridad exacta con una generación oficial;
- no cambios al Battle Core genérico salvo reutilizar su pipeline de reacción/fin de turno.

## Evidencia de código antes del HEAD documental

GitHub Actions run `33299334123`, Godot `4.7.stable.official.5b4e0cb0f`, Ubuntu 24.04:

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
- Wild Run Command + audit: **71 PASS / 0 FAIL**
- import headless: **PASS**

El workflow se endurece para exigir `>=71 PASS / 0 FAIL` en la suite RUN. El cierre definitivo depende de repetir todos estos gates sobre el HEAD documental final.
