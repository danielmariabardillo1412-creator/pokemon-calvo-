# ADR-015 — Battle Capture Presentation V1

Fecha: 2026-08-30  
Rama: `feature/battle-capture-presentation-v1`  
Base: `feature/battle-commands-v1`  
Estado: **ACCEPTED / VALIDATED**

## Contexto

FASE 14 formalizó Capture como comando de turno seguro en la aventura salvaje: una captura inválida no gasta turno, una captura fallida consume exactamente un turno y provoca una respuesta rival, y una captura exitosa completa la sesión sin represalia.

El siguiente límite debía hacer visible ese contrato sin duplicar reglas de Capture, Inventory, ownership o Battle dentro de la UI.

## Decisión

`BattlePresentationController` pasa a usar un único límite de aplicación para las interacciones del jugador:

`WildAdventureSession.submit_player_command(...)`

Tanto MOVE como CAPTURE atraviesan esa frontera. La presentación no llama a `capture_current()` y no contiene fórmulas de captura, routing de ownership, consumo de inventario ni resolución de turnos.

### Controles de captura

La UI técnica muestra únicamente balls que existen con cantidad positiva en `PlayerInventory`, en un orden de presentación estable V1:

1. `poke_ball`
2. `great_ball`
3. `ultra_ball`
4. `master_ball`

Otros objetos del inventario no aparecen como controles de captura. Las cantidades visibles se leen del inventario vivo y se actualizan tras cada intento.

Este orden es una decisión de presentación técnica, no una regla de economía ni un catálogo definitivo de Bag.

### RNG de captura

El `RandomNumberGenerator` de Capture se inyecta en `BattlePresentationController.configure(...)`.

La UI no crea un seed oculto. Si no se inyecta RNG, Battle sigue siendo jugable mediante movimientos pero los controles de captura quedan deshabilitados y un intento directo devuelve `capture_rng_unavailable` sin mutar turno ni inventario.

En la escena técnica local, `technical_overworld.gd` posee e inyecta un RNG determinista para QA. En una futura arquitectura multiplayer, ese RNG deberá vivir en autoridad server-side; esta fase no afirma seguridad de red.

## Flujos visibles

### Captura inválida

La presentación construye un `WildBattleCommand.CAPTURE` y delega. Si el comando es inválido —por ejemplo, ball no poseída— se muestra el rechazo; no se consume turno, no hay respuesta rival y los invariantes de RNG/inventario permanecen en la capa de dominio.

### Captura fallida

La ball desaparece o reduce su cantidad según el inventario real. El rival ejecuta exactamente una respuesta mediante el contrato de FASE 14. La UI representa los `BattleEvent` resultantes y refresca HP, PP, turno y balls disponibles.

Si esa represalia causa KO y finaliza Battle, la presentación ejecuta el settlement existente, mantiene visible el resultado y espera confirmación antes de volver al Overworld.

### Captura exitosa

La misma `CreatureInstance` capturada queda en party o storage según el routing existente. No hay respuesta rival. La sesión queda `COMPLETED / CAPTURED`, los controles de comandos quedan deshabilitados y las filas de balls se ocultan para no dejar cantidades obsoletas después de que la Battle viva haya sido retirada.

El Overworld permanece congelado hasta que el jugador confirma `Return to overworld`; entonces la sesión vuelve a `READY` y el movimiento se reanuda.

## Escena técnica

`res://scenes/overworld/technical_overworld.tscn` sigue siendo una escena asset-free de integración.

Para demostrar Capture de forma reproducible, su bootstrap añade un inventario mínimo de QA:

- 3 × `poke_ball`
- 1 × `great_ball`
- 1 × `master_ball`

También inyecta un RNG de captura con seed fijo.

Estas cantidades no son balance, economía ni inventario inicial definitivo del juego.

## Auditoría post-green

El primer CI dedicado de FASE 15 pasó con **51 PASS / 0 FAIL**, pero la fase no se cerró ahí. La auditoría posterior detectó un defecto visual real: tras una captura exitosa, el comando había consumido correctamente la ball pero la fila visual podía conservar una etiqueta obsoleta porque la sesión ya había eliminado la Battle activa y `_refresh_view()` no podía reconstruirla.

Se corrigió el controlador para eliminar explícitamente esos controles tras éxito y se añadieron 17 checks adversariales adicionales.

La suite ampliada verificó **68 PASS / 0 FAIL** y el gate CI quedó elevado a 68 para evitar perder esa cobertura silenciosamente.

## Invariantes demostrados

- la UI de Capture no implementa la fórmula de captura;
- la UI no llama al API histórico `capture_current()`;
- MOVE y CAPTURE usan el mismo límite de comando de aplicación;
- solo aparecen balls realmente poseídas;
- objetos no-capture no aparecen;
- sin RNG de Capture los controles son inoperables y no hay mutación;
- una ball inexistente no consume turno, respuesta rival ni RNG;
- fallo válido: una ball consumida, un turno y exactamente una respuesta rival;
- capturar no consume PP del movimiento del jugador;
- la respuesta rival sí consume su PP y puede causar daño/KO;
- la UI refleja HP y cantidades de inventario actualizadas;
- cuando se consume la última ball de un tipo, su control desaparece;
- éxito con espacio conserva la misma instancia en party;
- éxito con party llena conserva la misma instancia en storage;
- una captura exitosa no provoca represalia;
- después del éxito no quedan controles de captura obsoletos;
- derrota causada por la represalia se liquida y se presenta antes de volver al mapa;
- el Overworld permanece congelado hasta confirmación y luego se reanuda.

## Límites aceptados

- UI técnica, no diseño final;
- no animación de lanzamiento/sacudidas/captura;
- no Bag completo ni categorías de items;
- no economía/tiendas;
- no Run;
- no selector visual de Switch/reemplazo;
- no IA rival estratégica;
- no networking/multiplayer;
- no assets finales Pokémon/Roma;
- el orden de balls es de presentación V1 y puede evolucionar sin cambiar reglas de dominio.

## Evidencia

Sobre el HEAD de código auditado previo a documentación:

- Historical regression: **470 PASS / 0 FAIL**
- Inventory: **47 PASS / 0 FAIL**
- Savegame V2: **40 PASS / 0 FAIL**
- Savegame V2 adversarial: **8 PASS / 0 FAIL**
- Wild Encounters: **54 PASS / 0 FAIL**
- Logical Vertical Slice: **62 PASS / 0 FAIL**
- Overworld: **59 PASS / 0 FAIL**
- Battle Presentation: **43 PASS / 0 FAIL**
- Battle Commands: **53 PASS / 0 FAIL**
- Battle Capture Presentation + audit: **68 PASS / 0 FAIL**
- Godot: `4.7.stable.official.5b4e0cb0f`
- import headless: PASS

El HEAD documental final debe conservar estos gates; el cierre operativo del PR depende de ese workflow final.
