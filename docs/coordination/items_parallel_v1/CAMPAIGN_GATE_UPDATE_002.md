# CAMPAÑA_001 — puerta de verificación y continuación 002 (IA6, 2026-11-01)

**Orden oficial de IA6.** Prevalece sobre las notas históricas de CI pendiente en `STATUS.md` y los cuadernos escritos **antes** de las pruebas citadas. No amplía IDs, propiedad de archivos, número de microbloques ni autoriza nueva campaña.

## Evidencia técnica comprobada
- Integración de W03 en árbitra: commit `82f9eea26d10976e6eb2702adce911bd7e1ed173`, Net Ball factor ×3,5 para Agua/Bicho, pruebas V11/V15 y auditoría estática.
- Integración de W05 en árbitra: commit `39df72c1edda278108c74f29ed4b6053724528f6`, helper de consulta read-only MACHINE y probe Godot.
- CI de staging [#41350463036](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41350463036), SHA `c25f1616366a4c4432ee63fd49c001083d55647b`: `completed/success`. Net 34 checks/0 errores, V11 32406 PASS, V15 51901 PASS, W05 18/0 y contrato 248=229+19.
- **CI sobre árbol integrado en rama árbitra** [#41350909378](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41350909378), SHA `71332b256621e49e98676ef5f0af48c145d1e86f`: `completed/success`. Esto valida la integración existente, no los microbloques todavía no escritos ni la interfaz visual.
- Paquete de pruebas nuevo de cinco familias [#41350981613](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41350981613), SHA staging `6ea4cb1b9b68e0d1e33ef6a5228dcf57503a3456`: `completed/failure` **únicamente W02**. Pasan los pasos W01, W03, W04 y W05. W02 emite `CAMP_001_W02 FAIL checks=1544 cases=16` con fallo en semilla comprobada, escenario Persim (confusión) y propagación al resumen `per_item`. Un PASS estático no sustituye corrección ni rerun Godot.
- Para W02 se inició diagnosis aislada en staging `codex/calvo-items-20261101-ci-w02-diagnostico`, [Actions #41353549834](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41353549834); **no considerar resultado aún hasta revisar conclusión y logs**. Las aserciones originales se conservan en el diagnóstico.

## Dictamen y permisos
| W | Campaña entregada | Dictamen IA6 | Siguiente paso |
|---|---:|---|---|
| W01 | 02/03 | Nuevos tests 01–02 PASS Godot en paquete sobre SHA staging; no se ha integrado el test nuevo en árbitra | Puede recibir `p` para preparar ITER_03, respetando campaña |
| W02 | 03/03 | **CERRADA como entrega, RECHAZADA funcionalmente hasta reparar prueba/contrato** | No `p` ni cuarto bloque; IA6 documenta diagnóstico de test `persim_confuse_ray` y pide corrección acotada si procede |
| W03 | 02/03 | `INTEGRADO_VERIFICADO` para adaptador Net y regresiones sobre árbol arb | **DESBLOQUEADO para ITER_03** tras un `p`; solo regresiones adicionales autorizadas |
| W04 | 02/03 | Nuevos tests 01–02 PASS Godot sobre paquete staging; chat roto no implica pérdida en GitHub | ITER_03 en el mismo W04, usando relevo del cuaderno si necesita nueva conversación |
| W05 | 01/03 | `INTEGRADO_VERIFICADO` para adaptador read-only sobre árbol arb | **DESBLOQUEADO para ITER_02** tras un `p`; clasificación/libros, no activar 19 legadas |

## Reglas al reanudar W03 o W05
1. Leer esta puerta y `CAMPAIGN_GATE_001.md` en la rama árbitra, el encargo `campaigns/CAMP_001_W0X.md` y el cuaderno propio de la rama W. Recuperar el HEAD real y conservar los blobs ya preparados.
2. Registrar que el código existente de W03/W05 pasó CI del árbol IA6. **No repetir ITER_01/02**, no reimplementar Net y no borrar reports. Sincronizar de modo no destructivo; si hay conflicto, detener y comunicarlo.
3. **Un único `p` habilita solo la iteración pendiente**; ningún `p` abre CAMP_002 ni cambia los archivos autorizados. Mantener `PREPARADO_PENDIENTE_CI` en cualquier novedad sin prueba real sobre su commit.
4. IA6 conservará la responsabilidad de integrar/CI por paquetes. Godot headless no verifica visual/GPU; no declarar el juego completo terminado.

**Árbol canónico:** `codex/calvo-items-20261101-arbitro`. `main`, PR #118, V28 y ramas de las trabajadoras permanecen fuera del alcance de la integración.
