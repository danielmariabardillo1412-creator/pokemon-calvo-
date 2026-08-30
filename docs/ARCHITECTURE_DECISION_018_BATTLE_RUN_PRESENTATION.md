# ADR-018 — Battle Run Presentation V1

Fecha: 2026-08-30  
Rama: `feature/battle-run-presentation-v1`  
Base: `feature/wild-run-command-v1`  
Estado: **ACCEPTED / VALIDACIÓN FINAL PENDIENTE DEL HEAD DOCUMENTAL**

## Contexto

FASE 17 cerró y validó la semántica de huida salvaje en `WildBattleCommand.RUN` y `WildAdventureSession`, incluida la política `calvo_escape_v1`. Esa fase dejó deliberadamente fuera el botón Run y cualquier presentación visual.

FASE 18 cubre únicamente esa frontera de presentación: hacer utilizable RUN desde `BattlePresentationController` y desde la vertical slice técnica sin mover autoridad de gameplay a la UI.

## Alternativas evaluadas

### A. Integrar Run en `BattlePresentationController`

Elegida.

Es el mismo límite de presentación que ya expone Move, Capture y Switch. Permite construir una intención canónica y delegar toda la resolución a `WildAdventureSession`.

### B. Añadir `BattleAction.RUN`

Rechazada.

Contradiría ADR-017: huir no es una acción genérica del Battle Core, sino una operación específica de una sesión de encuentro salvaje.

### C. Hacer que `technical_overworld.gd` invoque RUN directamente

Rechazada.

Duplicaría lógica de presentación en la escena y rompería el patrón ya establecido: la escena orquesta transición/freeze/resume y el controlador presenta los comandos de Battle.

## Decisión

`BattlePresentationController` incorpora un botón **Run** y el método:

`submit_player_run() -> WildBattleCommandResult`

El controlador construye:

`WildBattleCommand.run(state.turn + 1, player_side.side_id)`

y lo envía a:

`WildAdventureSession.submit_player_command(command, null, opponent_action, escape_rng)`

La UI no implementa ni replica `WildEscapeRuleset`.

## Frontera de autoridad

La presentación **NO** calcula ni decide:

- Speed usada para huir;
- `odds`;
- bonus por intento;
- si la huida es garantizada;
- si se requiere RNG;
- si se requiere represalia rival;
- si la huida tuvo éxito.

Todos esos hechos salen del estado autoritativo y de `calvo_escape_v1` dentro de la capa de aplicación/dominio.

La presentación solo:

- ofrece el intent Run mientras Battle espera acción;
- proporciona una reacción rival candidata cuando existe;
- inyecta Escape RNG cuando está configurado;
- representa el `WildBattleCommandResult` recibido.

## Escape RNG y estado del botón

`configure()` recibe un cuarto parámetro opcional `p_escape_rng`, conservando compatibilidad con llamadas anteriores.

El botón Run **no se deshabilita solo porque Escape RNG sea null**. Esto es intencionado: una huida garantizada puede resolverse correctamente sin RNG. La presentación no debe duplicar la fórmula para adivinar si el RNG será necesario.

Consecuencia V1:

- huida garantizada + RNG null: puede tener éxito;
- huida probabilística + RNG null: el dominio rechaza `escape_rng_required` sin turno, intento, represalia ni mutación.

La escena técnica siempre inyecta un Escape RNG determinista; el caso null existe para preservar un contrato correcto y auditable, no como UX final recomendada.

## Reacción rival candidata

El controlador consulta `SimpleBattleOpponentPolicy` para obtener una acción rival legal cuando existe, pero no rechaza RUN si la política devuelve null.

Motivo: una huida garantizada no necesita reacción rival. Solo `WildAdventureSession` sabe, después de aplicar la política de escape, si una reacción es obligatoria.

La auditoría adversarial demuestra ambos bordes:

- rival sin acción + huida garantizada -> FLED válido, sin RNG ni eventos de respuesta;
- rival sin acción + huida probabilística -> rechazo `invalid_opponent_response:*`, sin turno, intento ni consumo de Escape RNG.

## Semántica visual de éxito

Cuando el resultado es `COMPLETED / FLED`:

- se registra `Got away safely.`;
- se bloquean los comandos;
- se limpian controles contextuales stale de Capture/Switch;
- Run queda no utilizable;
- se muestra `Return to overworld`;
- el overlay permanece visible;
- el Overworld sigue congelado hasta confirmación explícita.

`continue_after_completion()` hace el reset de sesión y emite exactamente una vez `battle_closed(FLED)`, tras lo cual la escena reanuda movimiento.

## Semántica visual de fallo

Cuando RUN es válido pero falla:

- se registra `Couldn't get away.`;
- se representan los eventos de la represalia;
- HP/estado visible se refresca desde el estado vivo;
- Run vuelve a quedar utilizable si Battle continúa;
- el contador de intentos permanece en `WildAdventureSession` y aumenta según el dominio;
- si la represalia termina Battle, se reutiliza `_settle_finished_battle()` y se presenta la derrota/victoria normal.

No existe un settlement paralelo de presentación para RUN.

## Interacciones auditadas

La suite base produjo **43 PASS / 0 FAIL**. No se cerró la fase con ese primer verde.

Se añadió `BattleRunPresentationAuditTestSuite`, que verifica además:

- huida garantizada sin acción rival;
- huida probabilística sin acción rival y RNG intacto;
- Speed corrupta con cero efectos laterales;
- dos fallos consecutivos con intento 1 -> 2 y odds crecientes;
- coherencia de HP/control tras fallos repetidos;
- Run fallido -> Capture exitosa;
- Capture fallida -> Run exitoso;
- Switch -> Run usando el nuevo activo autoritativo;
- independencia entre Escape y Capture RNG/inventario;
- señal `battle_closed(FLED)` exactamente tras Continue;
- reapertura del mismo controlador para un encounter nuevo;
- reset del contador entre encounters;
- llamada pública a Run después de COMPLETED rechazada sin mutación.

Resultado post-auditoría: **94 PASS / 0 FAIL**.

## Vertical slice técnica

`technical_overworld.gd` crea un Escape RNG determinista con seed `12006` y lo inyecta en `BattlePresentationController`.

Esa seed es un fixture de QA, no una decisión de balance. La escena prueba:

`movimiento -> encounter -> Battle -> Run -> FLED -> confirmación -> movimiento reanudado`

No se añadieron assets ni dependencias sobre la biblioteca pesada local.

## Compatibilidad

- Battle Core genérico no cambia.
- `WildEscapeRuleset` no cambia.
- `WildAdventureSession` no cambia en FASE 18.
- Capture conserva su propio RNG y sus semantics.
- llamadas previas a `BattlePresentationController.configure()` siguen siendo válidas porque el nuevo argumento es opcional.

## Límites aceptados

- UI técnica, no arte final;
- sin animación de huida;
- sin sonido/VFX/transiciones de producción;
- sin Run Away, Smoke Ball, Poké Doll, trapping o Mean Look;
- sin trainer-battle escape;
- sin networking/multiplayer;
- sin recalcular en UI la fórmula de huida;
- sin cambios de balance en `calvo_escape_v1`.

## Evidencia pre-cierre

GitHub Actions run `33300297082`, job `99227059631`, sobre merge sintético del PR #12 contra FASE 17:

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
- Wild Run Command: **71 PASS / 0 FAIL**
- Battle Run Presentation + adversarial audit: **94 PASS / 0 FAIL**
- Godot: `4.7.stable.official.5b4e0cb0f`
- import headless: **PASS**

Artifact: `godot-ci-logs-33300297082`, ID `9728716602`, SHA-256 `80143261d7dcc46242003d0e8a71573e17556daa48dd4496daa539daef6d9bff`.

El workflow se endureció posteriormente para exigir `>=94 PASS / 0 FAIL`. El cierre definitivo requiere repetir todos los gates sobre el HEAD documental con ese mínimo activo.
