# INFORME FINAL — FASE 18: Battle Run Presentation V1

Fecha: 2026-08-30  
Rama: `feature/battle-run-presentation-v1`  
Base: `feature/wild-run-command-v1`  
PR: #12  
Motor CI: `4.7.stable.official.5b4e0cb0f`

## Estado

**FASE_18_STATUS = VALIDATION_PENDING_FINAL_DOCUMENT_HEAD**

La implementación y la auditoría adversarial están verdes. Falta únicamente repetir GitHub Actions sobre el HEAD documental con el gate reforzado a **>=94 PASS / 0 FAIL** antes de marcar la fase CLOSED/VALIDATED.

No se ha hecho merge a `main`.

## Objetivo cumplido

RUN ya es utilizable desde la presentación técnica sin reimplementar la lógica de huida.

Flujo:

`Run button -> BattlePresentationController.submit_player_run() -> WildBattleCommand.RUN -> WildAdventureSession -> calvo_escape_v1 -> resultado -> presentación`

## Autoridad

`BattlePresentationController` no decide Speed, odds, RNG requerido, represalia requerida ni éxito/fracaso.

Esos hechos siguen bajo `WildAdventureSession` y `WildEscapeRuleset`. El controlador solo construye el intent, inyecta dependencias y representa el resultado autoritativo.

## Comportamiento presentado

### Run exitoso

- puede resolverse sin Escape RNG cuando el dominio lo considera garantizado;
- completa la sesión como `FLED`;
- no ejecuta represalia;
- bloquea comandos;
- mantiene el overlay y el Overworld congelado;
- muestra confirmación de retorno;
- `continue_after_completion()` emite `battle_closed(FLED)` y reanuda exploración.

### Run fallido

- consume el turno/intento según el dominio;
- representa exactamente la reacción rival producida por el pipeline autoritativo;
- refresca HP/estado;
- mantiene Run disponible si Battle sigue activa;
- si la reacción causa KO final, reutiliza el settlement normal y presenta DEFEAT/VICTORY.

### Run inválido

Casos como RNG requerido ausente, Speed corrupta o respuesta rival necesaria ausente se rechazan sin inventar fallback de UI ni mutar Battle.

## Integración técnica

`BattlePresentationController.configure()` añade un cuarto argumento opcional `escape_rng`, manteniendo compatibilidad con las llamadas existentes.

La escena `technical_overworld.gd` inyecta:

- Capture RNG separado;
- Escape RNG separado, seed técnica `12006`.

No se añaden assets. La seed es un fixture de QA, no balance de juego.

## QA base

La primera suite de presentación cubrió:

- control Run visible/habilitado;
- probabilístico sin RNG seguro;
- garantizado sin RNG/reacción;
- fallo con refresco de HP y continuidad;
- fallo que termina en derrota;
- independencia de Capture RNG/inventario;
- wiring real del botón;
- vertical slice completa Run -> FLED -> Continue -> Overworld.

Resultado inicial: **43 PASS / 0 FAIL**.

## Auditoría adversarial post-green

No se aceptó el primer verde como cierre.

Se añadió una suite adversarial independiente para probar:

- rival sin acción usable en escape garantizado;
- rival sin acción usable en escape probabilístico;
- Escape RNG intacto ante rechazo previo;
- Speed <= 0 desde presentación;
- fallos consecutivos y acumulación 1 -> 2;
- crecimiento exacto del bonus de intento;
- sincronización de HP/control;
- Run fallido seguido de Capture;
- Capture fallida seguida de Run;
- Switch seguido de Run con el nuevo activo;
- señal FLED solo después de Continue;
- reapertura del mismo controlador en encounter nuevo;
- reset de intentos;
- segunda llamada pública a Run tras COMPLETED sin mutación.

No aparecieron defectos funcionales que requirieran cambiar el dominio ni el Battle Core.

Resultado ampliado: **94 PASS / 0 FAIL**.

## Evidencia pre-cierre

Run `33300297082`, job `99227059631`:

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
- Battle Run Presentation + audit: **94 PASS / 0 FAIL**
- import headless: **PASS**

Artifact: `godot-ci-logs-33300297082`, ID `9728716602`, SHA-256 `80143261d7dcc46242003d0e8a71573e17556daa48dd4496daa539daef6d9bff`.

## Gate permanente de fase

El workflow queda configurado para exigir:

**Battle Run Presentation >=94 PASS / 0 FAIL**

Se usa mínimo y no igualdad exacta para permitir que fases posteriores añadan checks.

## Fuera de alcance

- UI/arte final;
- animación o transición audiovisual de huida;
- habilidades/objetos especiales de escape;
- trapping/Mean Look;
- trainer battle escape;
- networking;
- cambios de fórmula/balance de `calvo_escape_v1`;
- assets de la biblioteca local pesada.

## Próximo bloque recomendado

Después del cierre documental, revisar el roadmap real del repositorio y elegir la siguiente frontera por dependencia, no por numeración improvisada.

No debe abrirse FASE 19 hasta que el HEAD documental de FASE 18 pase todos los gates y PR #12 quede cerrado sin merge.
