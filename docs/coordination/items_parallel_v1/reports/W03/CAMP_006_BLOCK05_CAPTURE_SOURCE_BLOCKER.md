# IA3/W03 — CAMP006 bloque 05: captura ambiental sin productor autenticado

**Fecha:** 2026-11-09. **Rama exclusiva:** `codex/calvo-items-20261104-w03-camp006`.
**IDs:** `dive_ball;lure_ball`. **Estado:** BLOQUEADO_PRODUCTOR (no PASS, no fila de progreso funcional, no objeto nuevo).
**Puerta IA6:** `CAMPAIGN_006_W03_BLOCK04_DEFER_CAPTURE_GATE_20261109.md`. El 04 está aplazado, no completado.

## Evidencia de código (HEAD de partida `4a7fef50c5d3ef2af3e97c296605f52076afae22`)

- `modules/capture/capture_battle_context.gd` solo lleva `is_wild`, estado de combate, propietarios, turnos y nivel del lanzador; no contiene procedencia de pesca/surf/buceo.
- `modules/gameplay/wild_adventure_session.gd::capture_current()` construye ese contexto desde batalla; no recibe ni valida origen acuático, herramienta de pesca o modo de movimiento.
- `modules/capture/capture_ruleset.gd` no registra `dive_ball` ni `lure_ball` como bolas resolubles; `CaptureSystem.validate_attempt` rechaza `unknown_ball`.
- `scenes/visual/field_demo.gd::field_prepare_native_encounter` y `modules/overworld/overworld_encounter_director.gd::on_step` generan encuentros por zona, sin distinguir pesca, surf ni buceo.
- No se encontró en el árbol de fuentes un productor explícito de pesca/surf/buceo. Un Pokémon de tipo Agua o una zona bautizada `water` no prueban el medio por el que empezó el encuentro.

## Prueba roja necesaria

**Escenario:** desde la demo real iniciar un encuentro mediante un productor de pesca o surf/buceo y solicitar el contexto de captura de `WildAdventureSession`. Afirmar que el contexto identifica un origen autenticado y estable, reconstruido por el propietario de la sesión, y que `CaptureSystem` aplica la regla canónica de cada bola sin usar flags de UI/test.

**Resultado actual:** el productor no existe y `CaptureBattleContext` no expone ninguna procedencia. La prueba no puede ser positiva sin añadir una interfaz compartida, que W03 no tiene permiso para modificar. No fabricar `is_fishing=true` ni dar PASS con un contexto inventado.

## Contrato mínimo solicitado a IA6

1. **Origen inmutable** emitido por el productor de encuentro: `EncounterOrigin` con `kind` (walk/fish/surf/dive), `zone_id` y, cuando corresponda, identificador de caña; establecer origen antes de consumir RNG y de iniciar batalla. Prohibir alteración por UI.
2. **Propagación de solo lectura**: `WildAdventureSession.begin_encounter(..., origin)` valida y retiene el origen asociado al encuentro activo; `capture_current()` transmite copia fiable a `CaptureBattleContext`. Se limpia tras batalla/retorno/carga. Sin inventar persistencia si el combate no se guarda.
3. **Regla canónica**: IA6 debe aprobar versión exacta para `dive_ball` (pesca/surf/buceo según generación) y `lure_ball` (captura con caña), multiplicadores y comportamiento sin origen acreditado.
4. **Entrega W03**: una vez aprobado lo anterior, implementar solo cálculo y validación local en `modules/capture/` y pruebas reales desde productor → batalla → lanzamiento → resultado, con no-consumo si falta contexto, RNG y regresiones intactas.

**No se modifica** `field_demo.gd`, `WildAdventureSession`, `CaptureBattleContext` compartido, `SaveV2`, director de encuentros, RNG ni inventario. El progreso sigue **3 completados / 1 aplazado (04) / 1 bloqueado (05)**, y `last_executed_id=03`. No convertir una prueba negativa en una integración.
