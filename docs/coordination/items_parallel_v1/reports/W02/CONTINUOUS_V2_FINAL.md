# IA2/W02 — CAMPAÑA CONTINUA V2 FINALIZADA · 42 BAYAS

**Fecha:** 2026-11-11. **Trabajadora:** IA2/W02. **Rama exclusiva:** `codex/calvo-items-20261109-w02-mints-integration`.

**Resultado:** 42/42 IDs examinados, cinco bloques de la cola V2 agotados, **36 con contratos positivos y negativos heredados de CAMP003**, **5 con QA nativa nueva de uso desde mochila y de activación equipada**, **1 Persim equipada con QA nativa nueva**. Además Aspear, ya incluida en las 36, obtuvo prueba adicional de campo. **0 objetos nuevos añadidos al código de producción, 0 cambios en mecánicas de producción, 0 bloqueados para el alcance comprobado.**

**Certificación final:** [CI #42937706214](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42937706214) **completed/SUCCESS** sobre SHA exacto del workflow y pruebas:
`bd2a525858a5b08ff85fc2121a23ddf6a10d7c5d`.

## Evidencia cuantitativa real

| Puerta | Recibo obtenido en CI final | Alcance |
| --- | --- | --- |
| Inventario de cobertura | `W02_CONTINUOUS_V2_AUDIT_PY PASS ids=42 historical=36 field=6 persim=1 held=5 checks=42` | Cuenta 42 IDs únicos y distingue pruebas nuevas, antiguas y superpuestas |
| Mochila/servicio de campo | `W02_CONTINUOUS_V2_B01_GODOT PASS positive=6 negative=6 checks=795` | Cheri, Chesto, Pecha, Rawst, Aspear, Oran; cada escenario PARTY, sin stock y STORAGE; consumo atómico, SaveV2 |
| Persim equipada | `W02_CONTINUOUS_V2_PERSIM_GODOT PASS cases=2 checks=165` | Confuse Ray real; cura confusión, consumo, propietario, control sin baya/reserva, restore y SaveV2 |
| Cinco bayas equipadas | `W02_CONTINUOUS_V2_HELD05_GODOT PASS positive=5 negative=5 checks=833` | Cheri, Chesto, Pecha, Rawst y Oran, disparador real y ausencia de disparador, PARTY/ausente/reserva, stock, restore y SaveV2 |
| TANDA04 W02 | `W02_AUTORUN_V4_GODOT PASS checks=245` | Mantiene eliminación de recálculo duplicado en Growth |
| CAMP005 congelada | `CAMP005_W02_GODOT PASS blocks=10 checks=16735` | Fixture histórico íntegro del SHA congelado |
| CAMP005 actual | `CAMP005_W02_GODOT PASS blocks=10 checks=16878` | Regresión actual con migraciones explícitas |
| CAMP004 actual | `CAMP004_W02_GODOT PASS blocks=10 checks=12282` | Medicinas y bayas anteriores |
| CAMP003 actual | `CAMP003_W02_GODOT PASS blocks=10 checks=7306` | Bayas y contratos heredados, incluidas las 36 cubiertas en esta auditoría |

También superadas todas las demás etapas de TANDAS 01–03 y CAMP006 del workflow. La CI es propia de la rama W02; **no equivale a prueba de integración IA6**.

## Cobertura de la cola en bloques continuos

- **Bloque 01, 10 IDs:** 4 históricamente certificados en CAMP003 (`aspear_berry`, `aguav_berry`, `iapapa_berry`, `mago_berry`); cinco con nuevas pruebas nativas de campo **y** de objeto equipado (`cheri_berry`, `chesto_berry`, `pecha_berry`, `rawst_berry`, `oran_berry`); `persim_berry` con prueba nativa equipada. Aspear obtiene una comprobación de campo adicional sin contarse de nuevo.
- **Bloque 02, 10 IDs:** historial CAMP003 con positivos/negativos y regresión verde, sin duplicar mecánicas.
- **Bloque 03, 10 IDs:** historial CAMP003 con positivos/negativos y regresión verde, sin duplicar mecánicas.
- **Bloque 04, 10 IDs:** historial CAMP003 con positivos/negativos y regresión verde, sin duplicar mecánicas.
- **Bloque 05, 2 IDs:** historial CAMP003 con positivos/negativos y regresión verde, sin duplicar mecánicas.

**Lista individual auditada:** `docs/coordination/items_parallel_v1/reports/W02/CONTINUOUS_V2_BERRIES_AUDIT.csv` (42 filas, evidencia por ID y SHA de la CI final). `sitrus_berry` queda fuera de esta campaña deliberadamente, por cobertura anterior; no se cuenta como objeto nuevo.

## Incidencia roja y reparación verificable de QA

1. CI #42937080819 **FAILED** en el nuevo HELD05 porque el fixture de Chesto inyectaba `sleep` desde el estado inicial de la sesión sin un estado nativo válido. El test se reescribió para hacer que **Amoonguss utilice Spore** durante combate; no se tocó el motor.
2. El log de esa CI reveló `SCRIPT ERROR: Invalid access to property or key 'confused'` al ejecutar el comparador heredado de CAMP004 desde la nueva fixture de campo. La suite podía imprimir un PASS aunque GDScript hubiese emitido esos errores. Se corrigió el fixture con el atributo de confusión explícito.
3. Las etapas nuevas de CI incorporan guardas que **fallan** si sus logs contienen `SCRIPT ERROR` o `Parse Error`. La CI final pasó con esas guardas activas; no hay prueba silenciada ni conversión artificial de FAIL a PASS.
4. La CI #42931293868 también fue SUCCESS, pero **no** se usa como certificación final: la nueva prueba HELD05 y los guardas estrictos están en el SHA de #42937706214.

## Límites y propiedad

- Comparación de GitHub desde el cierre T04 `5d8c77b34d` hasta el SHA funcional de esta campaña: cambios exclusivamente de **tests, fixtures, workflow y documentación**. No se modificaron `modules/`, productores de combate, SaveV2 central, contenido normalizado, `main`, V28 ni PR #118.
- La certificación L3 es la **cobertura de contextos probados**; no acredita todos los formatos competitivos, dobles, todos los ciclos de campo, UI visual, GPU ni puesta en producción.
- **Integración IA6: NO REALIZADA.** Se detectaron tres diferencias de producción entre la rama W02 y la integrada: `field_growth_effects.gd`, `field_mochi_effects.gd`, `evolution_system.gd`. Consultar `docs/coordination/items_parallel_v1/reports/W02/CONTINUOUS_V2_IA6_HANDOFF.md`. Se requiere integración selectiva y CI cruzada propia de IA6; nunca merge automático.
- Los commits documentales posteriores al SHA funcional usan `[skip ci]` y **no se atribuyen a la CI de código**.

## Estado y próxima acción

**`READY_FOR_IA6` — PLAN_W02 V2 AGOTADO.** No quedan IDs pendientes de esta lista de 42. W02 no crea un backlog ilimitado ni inicia una nueva campaña sin un plan oficial. IA6 debe revisar este paquete, integrar selectivamente lo que corresponda y certificar en su rama aislada, conservando las regresiones y los límites protegidos.

**Cierre:** `W02 CONTINUOUS_V2 — 42/42 examinadas — 36 históricas — 5 con QA nativa campo+equipada nueva — 1 Persim nativa nueva — 0 objetos nuevos — 0 bloqueadas — CI #42937706214 SUCCESS — SHA bd2a525858 — INTEGRACIÓN IA6 NO`.
