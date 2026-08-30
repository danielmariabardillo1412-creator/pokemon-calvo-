# INFORME FINAL — FASE 17: Wild Run Command V1

Fecha: 2026-08-30  
Rama: `feature/wild-run-command-v1`  
Base: `feature/battle-switch-presentation-v1`  
PR: #11  
Motor CI: `4.7.stable.official.5b4e0cb0f`

## Estado

**FASE_17_STATUS = CLOSED / VALIDATED**

El código, la auditoría adversarial y el HEAD documental de cierre han conservado todos los gates definidos para la fase. No se ha hecho merge a `main`; el bloque permanece stacked sobre FASE 16.

## Qué cambia

FASE 17 formaliza la huida de un encuentro salvaje como comando de aplicación, sin introducir todavía ningún botón nuevo en la UI.

Flujo lógico:

`Wild Battle activa -> WildBattleCommand.RUN -> WildAdventureSession -> WildEscapeRuleset -> éxito FLED o fallo -> reacción rival autoritativa`

La decisión mantiene a Battle Core genérico centrado en MOVE/SWITCH. RUN pertenece a la sesión de aventura salvaje y por eso vive en `WildBattleCommand`, junto a CAPTURE.

## Ruleset de huida

Se introduce `calvo_escape_v1`:

- Speed jugador >= Speed salvaje: huida garantizada, sin RNG;
- si no: `floor(player_speed * 128 / wild_speed) + 30 * attempt`;
- `odds > 255`: huida garantizada;
- en otro caso, una única tirada inyectada `0..255` y éxito cuando `roll < odds`;
- los intentos válidos posteriores aumentan las odds;
- comandos inválidos no aumentan el contador.

La fórmula es una política explícita del proyecto inspirada en la estructura clásica de Pokémon. **No se declara bit-perfect respecto a una generación oficial concreta.**

## Estado usado para Speed

La huida usa `CreatureInstance.stats.speed`, no stages temporales de Battle. Un `+6 Speed` de `StatStages` no altera las odds de FASE 17.

Esto evita mezclar accidentalmente una política de aventura con transformaciones internas del resolver de turnos. Si más adelante se desea usar Speed efectiva, debe definirse como cambio deliberado del ruleset.

## Éxito

Una huida exitosa:

- devuelve un `WildEscapeResolution` exitoso;
- consume el intento/turno de RUN;
- completa la sesión como `COMPLETED / FLED`;
- no provoca respuesta rival;
- no consume inventario ni Capture RNG;
- no concede XP;
- no captura ni transfiere ownership;
- no cura HP;
- conserva PP/HP/estado persistente;
- limpia estado exclusivamente transitorio de Battle mediante la reconciliación existente.

Después, `reset_after_completion()` devuelve la sesión a READY y reinicia el contador de intentos.

## Fallo

Una huida probabilística fallida:

- consume exactamente una tirada de Escape RNG;
- incrementa el intento;
- consume un turno;
- ejecuta exactamente una reacción rival legal mediante `AuthoritativeBattleServer`;
- atraviesa el mismo fin de turno que el core usa para el resto de acciones, incluidos ticks de poison;
- puede causar KO y terminar Battle;
- si termina Battle, se reutiliza `settle_finished_battle()` para derrota/victoria.

No existe un settlement paralelo inventado para RUN.

## Validación defensiva

Se preserva el principio de "entrada inválida = cero efectos laterales":

- turno incorrecto;
- participante incorrecto;
- reacción rival inválida cuando es necesaria;
- ausencia de Escape RNG cuando la huida es probabilística;
- Speed inválida/corrupta.

Esos casos no deben avanzar turno, incrementar intento ni consumir Escape RNG.

La auditoría encontró una mejora concreta: con Speed corrupta a cero, la sesión podía llegar a validar primero la reacción rival. Aunque una criatura normal no debería tener Speed <= 0, los campos son mutables y el límite público debe ser defensivo. Se añadió el rechazo temprano `invalid_escape_speed`, probado sin reacción y con RNG intacto.

## Serialización

`WildBattleCommand.RUN` serializa únicamente:

- `turn`;
- `command_type`;
- `side_id`.

No transporta `BattleAction`, ball, Speed, odds ni resultado supuesto. La autoridad deriva esos hechos del estado vivo.

## Evolución de la QA

La primera implementación funcional produjo **43 PASS / 0 FAIL** en la suite dedicada.

No se cerró la fase con ese verde inicial. Se añadió una suite adversarial independiente con fronteras probabilísticas, corrupción de Speed, separación de RNG, efectos de estado, recompensas, ownership y ciclo del contador.

Resultado después de auditoría y hardening:

**WILD RUN COMMAND = 71 PASS / 0 FAIL**

El workflow queda configurado para exigir **mínimo 71 PASS y 0 FAIL**, permitiendo que futuras fases añadan más tests sin romper una igualdad exacta artificial.

## Alcance de cambios

La fase modifica únicamente la frontera de gameplay salvaje, el contrato de comando/resultado, el ruleset/resolution de escape, tests, CI y documentación.

No se añaden sprites, assets, economía, mapa, lógica de trainer battle ni red.

## Gates de cierre validados

GitHub Actions run `33299465947`:

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
- Import headless: **PASS**
- Godot exacto: `4.7.stable.official.5b4e0cb0f`
- Merge a `main`: **NO**

## Fuera de alcance

- botón Run y feedback visual;
- transición/animación final de huida;
- Run Away, Smoke Ball, Poké Doll y equivalentes;
- trapping/Mean Look y mecánicas especiales;
- huida de combates de entrenador;
- multiplayer/network authority;
- paridad exacta con una generación oficial.

## Próximo bloque recomendado

La siguiente dependencia natural es una fase de **Run Presentation V1** que exponga el comando ya validado en `BattlePresentationController` y en la escena técnica, sin reimplementar la fórmula ni tocar Battle Core.

Antes de abrirla se debe auditar el controlador y la escena actuales para definir exactamente el flujo de botón, estado deshabilitado, feedback de fallo y retorno al Overworld.
