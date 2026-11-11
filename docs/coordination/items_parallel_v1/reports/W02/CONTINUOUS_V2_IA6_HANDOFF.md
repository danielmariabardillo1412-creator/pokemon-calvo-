# IA2/W02 → IA6 — Relevo de integración selectiva y QA de campaña V2

**Emisión:** 2026-11-11. **Fuente:** rama W02 `codex/calvo-items-20261109-w02-mints-integration`. **Destino de revisión, no editado:** `codex/calvo-ia6-integration-20261109`.

## Estado W02 y límites

- Campaña V2: revisión de 42 IDs de bayas, con 36 con pruebas históricas CAMP003, cinco IDs sin cobertura CAMP003 de uso/cura en campo y Persim mediante prueba de combate. Aspear combina historial equipado y ensayo adicional de campo; ninguna cifra representa 42 objetos nuevos.
- Evidencia global ya verde: CI `42931293868` sobre SHA `0e59679abc91c353a5d58b33e0a4bf4ea2c51fc6` (auditor 42, seis usos campo, Persim, regresiones completas).
- Puerta más estricta de cierre: CI `42937706214` sobre `bd2a525858a5b08ff85fc2121a23ddf6a10d7c5d` (añade cinco ensayos equipados, tres runners blindados contra `SCRIPT ERROR` y regresiones). **Verificada completed/SUCCESS en GitHub #42937706214**; V2 campo 795 checks, Persim 165 checks, HELD05 833 checks y regresiones completas.
- QA roja previa `42937080819`: Chesto fallaba por fixture de sleep preinyectado inválido; además se detectó `SCRIPT ERROR` silencioso por `confused` no inicializado en fixture de campo. Los errores se corrigieron exclusivamente en pruebas/fixtures y workflow; no se degradaron aserciones ni se modificó producción.
- `main`, V28, PR #118 y rama IA6 no han sido modificadas por W02.

## Dependencia real de integración — no hacer merge ciego

Comparación leída directamente de los blobs de ambas ramas (IA6 integrado vs W02):

| Archivo de producción | Blob rama IA6 integrada | Blob rama W02 | Prioridad |
| --- | --- | --- | --- |
| `modules/inventory/field_growth_effects.gd` | `23070bd2226beff088a94143bbf19e0ea8669c32` | `38a914221702d2f95fb28aa9e888a18ed79308e9` | TANDA02 y TANDA04: validar estado de naturaleza efectiva y eliminar segundo recálculo tras evolución |
| `modules/inventory/field_mochi_effects.gd` | `f6cc8d5db38b50db0e3e246413385b1c405d66d1` | `9239cc70e5f4e99828c166737ecc49a2b645d834` | TANDA02: aceptar estadísticas calculadas con naturaleza efectiva |
| `modules/creatures/progression/evolution_system.gd` | `2f684ae11f36c6c2183a7100b9015c3f6c906f49` | `4a95284855f91506fd143df7aff466854180fff4` | TANDA03: preservar `effective_nature_id` al evolucionar |

Los blobs difieren: **no se afirma que los cambios estén integrados**. La diferencia se observó en GitHub después de la CI V2. La rama de integración IA6 aún mantiene HEAD `f4a5687bff1aaf0fb443c36ca4c2873f5d0ac54e` al consultar este relevo.

Commits funcionales W02 de referencia:
- `e8801e857fa6c1050b0a57413e9fa0259b1c8237`: ajustes localizados Growth/Mochi.
- `51f6892f5086d81fa795278b6050b5bd1d3126e4`: reparación `EvolutionSystem.apply_evolution`.
- `7765c4bb6982662ae00695c8329c970e10931b4c`: elimina recálculo redundante en Growth.plan, conserva el ajuste de PS.
- CI previas: TANDA04 `42922087890` SUCCESS; TANDA03 `42890511612` SUCCESS; TANDA02 `42869765262` SUCCESS.

## Instrucciones para IA6 — acciones autorizadas solo en su propia rama

1. Revisar diffs funcionales mínimos de las tres rutas, no mezclar documentación/fixtures ni introducir regresiones al modelo de naturaleza original/efectiva.
2. Hacer integración selectiva en rama aislada propiedad IA6, conservando semántica de evolución y de PS; comprobar compatibilidad con W04 y SaveV2 central.
3. Ejecutar las suites nativas/CI de W02 y los escenarios cruzados con W01–W05, usando el SHA integrado, sin reciclar como si fueran propias las CI de la rama W02.
4. Si un conflicto requiere interfaces compartidas, registrar ticket; no tocar `main`, V28 o PR #118.
5. Mantener la campaña V2 de bayas como contrato de QA; su certificado W02 no implica instalación en el juego integrado ni verificación visual/GPU.

**Autoría:** informe W02. **Estado final:** `READY_FOR_IA6`; campaña V2 de 42 bayas certificada en rama W02 con CI `42937706214` SUCCESS y SHA `bd2a525858a5b08ff85fc2121a23ddf6a10d7c5d`. **Integración IA6 NO realizada aquí.**
