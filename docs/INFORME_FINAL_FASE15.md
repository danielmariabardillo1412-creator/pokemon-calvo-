# INFORME FINAL — FASE 15: Battle Capture Presentation V1

Fecha: 2026-08-30  
Rama: `feature/battle-capture-presentation-v1`  
Base: `feature/battle-commands-v1`  
PR: #9  
Motor CI: `4.7.stable.official.5b4e0cb0f`

## Estado

**FASE_15_STATUS = CLOSED / VALIDATED**

Este informe forma parte del HEAD final que debe pasar el workflow completo. Si ese workflow no conserva todos los gates descritos abajo, este estado deja de ser válido y la fase debe reabrirse.

## Qué cambia

La Battle técnica ya permite intentar capturas desde la misma superficie visible en la que se juegan movimientos, usando exclusivamente el contrato seguro de FASE 14.

Flujo:

`Overworld -> encounter -> Battle visible -> MOVE o CAPTURE -> submit_player_command -> autoridad -> eventos/ownership -> resultado -> confirmación -> Overworld`

## Presentación de Capture

`BattlePresentationController` muestra las balls realmente poseídas y sus cantidades. La lista técnica usa un orden explícito `poke_ball`, `great_ball`, `ultra_ball`, `master_ball` y omite cualquier objeto no-capture.

La UI no implementa reglas de captura. Un botón genera `WildBattleCommand.CAPTURE` y delega en `WildAdventureSession.submit_player_command()`.

Además, los movimientos de la UI se migraron al mismo límite de aplicación; la presentación ya no necesita una vía separada de interacción para MOVE frente a CAPTURE.

## Semántica visible

### Entrada inválida

No se gasta turno ni se ejecuta respuesta rival. Una ball no poseída, por ejemplo, es rechazada sin consumir Capture RNG ni alterar el inventario.

### Fallo de captura

La ball se consume según el sistema existente. El turno avanza exactamente una vez y el rival ejecuta exactamente una respuesta legal por Battle Core. La presentación actualiza HP, PP, turno, eventos y cantidades de inventario. Si se consumió la última ball de ese tipo, su botón desaparece.

### Éxito de captura

No se ejecuta represalia. La misma instancia capturada queda en party o storage, la sesión termina con `CAPTURED` y el overlay espera confirmación. El Overworld continúa congelado hasta `Return to overworld`.

## RNG

Capture RNG se inyecta en el controlador; la UI no crea un seed oculto.

Sin RNG, los controles visibles quedan deshabilitados y un intento directo es rechazado sin mutación. La escena técnica inyecta un RNG determinista únicamente para QA local.

Esto no se presenta como autoridad de red. En multiplayer futuro, el RNG y la selección estratégica rival deberán residir en autoridad server-side.

## Escena técnica

La escena `technical_overworld` incorpora un inventario mínimo de prueba:

- 3 Poke Ball
- 1 Great Ball
- 1 Master Ball

No son valores de economía ni inventario inicial definitivo. Sirven para demostrar fallo probabilístico y éxito garantizado sin depender de assets externos.

## Auditoría posterior al primer CI verde

El primer gate dedicado quedó en **51 PASS / 0 FAIL**. Aun así se hizo revisión manual del diff y de la presentación.

La auditoría encontró un defecto visual: tras éxito de captura, el inventario real ya había consumido la ball pero una etiqueta de botón podía quedar visible con cantidad antigua, porque el éxito elimina la Battle activa antes de que `_refresh_view()` pueda reconstruir controles.

Se corrigió la presentación y se añadieron 17 checks adicionales para cubrir:

- capture visible pero deshabilitado cuando no hay RNG;
- desaparición del botón al consumir la última ball tras un fallo;
- represalia de captura fallida capaz de causar KO, settlement de derrota y confirmación visible;
- ausencia de botones obsoletos tras captura exitosa;
- todos los comandos deshabilitados después del éxito.

La suite ampliada terminó en **68 PASS / 0 FAIL**. El workflow se endureció para exigir un mínimo de 68.

## Auditoría de alcance

El diff de FASE 15 se limita a:

- presentación de Battle;
- bootstrap de la escena técnica;
- tests dedicados/auditoría;
- runner CI;
- workflow;
- documentación.

No se modifican `CaptureSystem`, `CaptureRuleset`, `CaptureInventoryService`, storage/party, probabilidades ni ownership core.

La presentación no llama a `capture_current()` y no contiene fórmula de catch probability. La ruta canónica nueva es `submit_player_command()`.

## Gates de código auditado antes del HEAD documental

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
- Import headless: **PASS**
- Godot exacto: `4.7.stable.official.5b4e0cb0f`
- Merge a `main`: **NO**

El workflow del HEAD final de este informe debe repetir estos resultados antes de considerar definitivo el cierre operativo.

## Fuera de alcance

- gráficos/animaciones de captura finales;
- Bag completo;
- tiendas/economía;
- Run;
- selector visual de Switch/reemplazo;
- IA estratégica;
- networking/multiplayer;
- mapa y assets finales de Roma/Pokémon.

## Próximo bloque

Antes de diseñar la siguiente fase se debe consultar el roadmap/documentación real del repositorio. Las fronteras todavía abiertas más evidentes son Switch/Run de presentación y semántica de comandos, pero no se deben asumir como FASE 16 sin revisar primero los documentos canónicos del proyecto.
