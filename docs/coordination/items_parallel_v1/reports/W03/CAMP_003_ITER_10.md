# IA3/W03 — CAMPAÑA_003, microbloque 10/10

**IDs oficiales:** `beast_ball;heavy_ball`. **Alcance:** pruebas acumulativas y diagnóstico contextual. **No afirmar implementación funcional.**

## Diagnóstico

- `CaptureRuleset` todavía no incluye `beast_ball` ni `heavy_ball` (ni en las listas de `CaptureBallEffects` o `CaptureContextBallEffects`).
- Ente Ball requiere un atributo canónico que permita identificar Ultraentes en el objetivo; no bastaría inferirlo a partir de un nombre o tipo.
- Peso Ball exige una medida de peso fiable de especie y forma, más una decisión documentada de la versión de la fórmula y su tratamiento de la tasa modificada.
- Como ambas son desconocidas para el motor, `CaptureSystem.validate_attempt` devuelve `unknown_ball` antes de cualquier descuento. Ni el contexto de combate ni las reglas actuales acreditan los efectos especiales.

## Pruebas del bloque 10

El fixture añade dos especies reales, PS completos o 1, contextos con/sin turno y nivel, dos bolas. Godot ejecuta `CaptureInventoryService.resolve` y exige `INVALID/unknown_ball`, conservación de inventario, objetivo, equipo y estado RNG. Además, cuatro casos inválidos por bola: batalla entrenador, objetivo KO, batalla finalizada y ausencia de bola; este último sigue resolviendo `unknown_ball` por la prioridad de validación. Python audita fuentes, la presencia de pruebas Godot reales y la integridad de reservas.

**Alcance de cualquier PASS:** el rechazo seguro actual, nunca el multiplicador de Ultraentes ni el efecto por peso. Se conservaron bloques 01–09; no se han tocado `main`, V28, ramas ajenas, catálogo, workflows ni producción.

## Frontera de integración para IA6

Definir clasificación Ultraente canónica por especie/forma y peso fiable con regla versionada para Peso Ball (incluido tope/suelo del capture rate). Una vez fijado ese contrato, conectar sin duplicar motor y crear positivos/negativos funcionales en una campaña posterior, no ampliar CAMP003.

**CI 10:** pendiente de confirmación sobre SHA final de pruebas/fixture/progreso.
