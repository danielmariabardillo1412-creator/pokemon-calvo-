# IA6 — RELEVO W02: PILOTO MINT-L3 01 · 2026-11-09

**Nueva rama exclusiva:** `codex/calvo-items-20261109-w02-mints-integration`, nacida del cierre documental `7842438f` de CAMPAÑA_006. **CAMPAÑA_006 permanece FINALIZADA** (#42437567862 SUCCESS). No iniciar CAMPAÑA_007.

**Trabajo autorizado 01:** conectar `lonely_mint`, `mild_mint`, `naive_mint` a `field_mint_effects.gd` y su ruta de `FieldItemService`, con efecto estadístico positivo real desde mochila, naturaleza original inmutable, naturaleza efectiva y SaveV2 legacy, identidad, HP y gasto transaccional. Conservar `gentle_mint` y efectos previos; no toques StatCalculator, ProgressionSystem, SaveV2 central ni backend de batalla.

**CI:** bootstrap propio de esta rama y nuevos tests Python/Godot; mantener regresiones CAMP006. Una CI PASS del bloque 01 valida solo los tres efectos que ejecuta, no `exp_share` ni las otras mentas. Consulta la orden central `IA6_REACTIVATION_W02_W05_W03_W04_20261109.md` en árbitra. En la siguiente `p`, ejecutar exclusivamente piloto 01, entregar SHA, CI y resultados y detenerse ante dependencia compartida.
