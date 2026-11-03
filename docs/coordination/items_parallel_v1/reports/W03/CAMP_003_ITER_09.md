# IA3/W03 — CAMPAÑA_003, microbloque 09/10

**Reserva exacta:** `love_ball;moon_ball`. **Alcance real:** pruebas de rechazo seguro y dependencia contextual; NO se declara implementado el efecto especial.

## Evidencia de código

- `CaptureRuleset` registra bolas básicas y las declaradas en `CaptureBallEffects` y `CaptureContextBallEffects`. Ni `love_ball` ni `moon_ball` figuran en dichas listas.
- `CaptureSystem.validate_attempt` rechaza `unknown_ball` cuando el estado del encuentro es capturable, antes de que `CaptureInventoryService` descuente una unidad.
- Amor Ball requiere comparar especie y sexo del Pokémon activo con el objetivo. `CaptureBattleContext` no transporta sexo ni especie del capturador.
- Luna Ball exige consultar una fuente de elegibilidad canónica de evolución por Piedra Lunar de la especie del objetivo. No se ha verificado dicho contrato dentro del adaptador de captura. La existencia de un motor de evolución no equivale a que la señal esté disponible para esta mecánica.

## Cobertura añadida

Suite acumulativa de 9 bloques: dos especies reales (Mew/Caterpie), PS completos o 1, contexto ausente o con turno/nivel reales (sin simular sexo o Piedra Lunar), ambas bolas. Godot realiza lanzamientos mediante `CaptureInventoryService.resolve` para validar `INVALID/unknown_ball`, objeto sin gastar, RNG sin tirada, objetivo y equipo inalterados. Además, tres rechazos prioritarios por bola (`trainer_battle_not_capturable`, `target_knocked_out`, `battle_finished`) y sus invariantes. Python verifica fuentes de producción, contratos y conexión de la suite.

El éxito de CI **solo** acredita el rechazo seguro actual; no concede bonus por sexo ni por evolución lunar.

## Dependencia para IA6

Establecer contrato de sexo (incluyendo desconocido/sin sexo), identidad de especie del capturador, fuentes del catálogo/evolución por Piedra Lunar (incluidas formas), propagación desde ambas sesiones y reconstrucción tras carga. La autonomía V5 no autoriza inventar reglas ni rehacer arquitectura compartida.

**Sin cambios de producción**, catálogo, workflow, `main`, V28 ni ramas ajenas. CI nueva: pendiente de verificación en el último SHA que contenga las 9 filas de progreso.
