# IA3/W03 — CAMPAÑA_004 / BLOQUE 01

**IDs oficiales:** `dive_ball;dusk_ball;repeat_ball`. Rama exclusiva: `codex/calvo-items-20261103-w03-camp004`.

## Diagnóstico de producción

`CaptureRuleset`, `CaptureBallEffects` y `CaptureContextBallEffects` no incluyen estas tres bolas. Por tanto, la ruta `CaptureInventoryService.resolve` llama primero a `CaptureSystem.validate_attempt`, que devuelve `unknown_ball` y **no consume** inventario, RNG ni modifica la criatura. La existencia de entradas en catálogo de objetos no equivale a funcionamiento de captura.

- Dive/Buceo: requiere origen autoritativo de captura mediante surf/buceo o el contexto exacto decidido por IA6.
- Dusk/Ocaso: requiere fuente de noche/cueva y su propagación verificable, no el reloj local inventado por pruebas.
- Repeat/Acopio: requiere comprobar si la especie ya estaba registrada como capturada en Pokédex antes del intento.

No se ha encontrado ninguna de esas tres señales en `CaptureBattleContext`. La instalación real exigiría productores de sesión y reglas compartidas; **dependencia para IA6**. No se han inventado factores, estados ni una Pokédex falsa.

## Pruebas nuevas

`tests/gameplay/parallel_items_w03_campaign_004.gd` llama a los servicios reales, usando dos especies catalogadas, PS completos o 1, dos configuraciones de turnos/nivel sin fingir contexto especial, y cuatro negativos por bola (combate entrenador, combate terminado, objetivo KO y ausencia en inventario). Comprueba motivo de rechazo, no consumo, no RNG, identidad/estado del objetivo y equipo intactos. Python valida reserva, fuentes reales, arnés estricto y contrato de rechazo.

**Interpretación de CI:** un PASS certifica exclusivamente rechazo seguro y ausencia de efectos secundarios **con las reglas actuales**. Estado por las tres: `NEGATIVO_VERIFICADO_NO_IMPLEMENTADO` si pasan ambos runners, y dependencia contextual para implementación.

**Regresiones anteriores:** el workflow W03 incluye expresamente CAMP002 y CAMP003 (20 bolas) en Python/Godot; no se replican en el runner CAMP004.

No se modificaron `main`, V28, producción, APIs, catálogo, workflows ni ramas ajenas. CI sobre el SHA de fixture/tests/progreso aún pendiente hasta inspeccionar el run.
