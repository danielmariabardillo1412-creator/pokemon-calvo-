# IA6 — CAMPAÑA_005 W02 / AUTORIZACIÓN OFICIAL

**Fecha:** 2026-11-03. **Orden del usuario:** todas han terminado CAMP004 salvo W01; autorizar nueva carga independiente sin esperar. **Identidad:** IA2/W02. **Rama exclusiva:** `codex/calvo-items-20261103-w02-camp005`.

## Evidencia y objetivo
CAMP004 W02 finalizó 10/10; GitHub Actions [#41589286005](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41589286005) `completed/success` con contratos Python/Godot. Esta prueba de rama NO significa integración a `main`.
**Nueva reserva:** [CAMPAIGN_005_W02_QUEUE_APPROVED.csv](CAMPAIGN_005_W02_QUEUE_APPROVED.csv), 10 bloques de 4: cápsulas de habilidad, caramelos, PP, vitaminas, plumas, mochi y mentas. Todos los IDs cotejados con `RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv` y las colas 003/004; sin solapes conocidos. Ningún ID equivale a funcionalidad nueva hasta pruebas reales.

## Trabajo autorizado
- Primera orden: bloque **01** `ability_capsule;ability_patch;rare_candy;pp_up`; cada `p` posterior exactamente 02..10, un bloque por mensaje. Al 10/10 STOP con `CAMPAÑA_005_FINALIZADA`. No empezar 006.
- Nuevos archivos propios CAMP005: `tests/tools/test_parallel_items_w02_campaign_005.py`, `tests/gameplay/parallel_items_w02_campaign_005.gd`, `tests/fixtures/parallel_items/w02_campaign_005.json`, `reports/W02/CAMP_005_PROGRESO.csv` e informes. Mantener CAMP004/CAMP003 intactos; usar CI Godot 4.7 y Python con recibos CAMP005 de bloque y checks reales.
- Para cada objeto: contrastar código y referencia, caso compatible, incompatible, stock/consumo, propietario, PP/HP/EV/amistad/naturaleza según aplique, identidad, persistencia SaveV2. Negativos no equivalen a funcionalidad positiva.
- **Autonomía de reparación V5 por función propia:** `modules/inventory/field_growth_effects.gd` y helpers de entrenamiento, únicamente por función y sin tocar medicina/captura/evolución/MT ajenas. Los cambios en APIs de sesión/SaveV2 o FieldItemService compartido se elevan a IA6.
- **Restricción especial:** No aplicar cambios en IV, naturaleza, habilidad ni experiencia si no existe contrato real; documentar dependencia y rechazos. `dynamax_candy` queda EXCLUIDO de esta tanda por decisión de Randomlock; no inferir autorización aunque el catálogo lo liste.
- CI bootstrap 0/10 solo valida estructura. Desde bloque 01 exige PASS Python+Godot real en el SHA correspondiente. Regresión de CAMP004/003 al menos en hitos 05 y 10 y en cambios de producción propios; si hay regresión, reparar antes de continuar bloque dependiente, sin rebajar aserciones ni falsificar recibos.
- Prohibido tocar `main`, V28, PR118, ramas W01–W04 o W05 ajenas, datasets canónicos y políticas globales; ningún merge automático.

**Nota:** la campaña no autoriza reemplazar la política de Randomlock por reglas inventadas. Ante un conflicto compartido real, documentarlo y elevarlo a IA6; continuar otros bloques independientes, no quedarse parada por cuestiones administrativas.
