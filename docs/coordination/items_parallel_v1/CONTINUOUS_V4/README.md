# IA6 — CONTINUOUS_V4 · CINCO RAMAS STAGING DE INTEGRACIÓN POR ESPECIALIDAD

Fecha: 2026-11-11. Plan firmado por IA6 tras auditar HEAD, STATE, informe y CI W01–W05. Los cinco staging se crearon **desde el mismo HEAD controlado** de `codex/calvo-ia6-integration-20261109`: `e63b2e6c7e175fba318cc2f562bebd1769589092`. Contienen el veto activo `dynamax_candy`. Su creación **NO integra** todavía ningún código nuevo.

## Problema que resuelve
La mayoría de trabajadoras agotaron sus misiones V3 y quedaron READY_FOR_IA6. Repetir otras 10 auditorías en sus ramas históricas no añade funcionalidad a la versión conjunta. V4 es **trabajo real de trasplante selectivo de módulos/funciones con pruebas**, en cinco ramas de *ensayo* separadas. Ninguna W puede modificar la rama integradora oficial, `main`, V28, PR #118 u otra staging. IA6 es la única que decidirá la integración final tras comparar las cinco entregas y repetir una CI cruzada.

## Staging exclusivo y estado
| Worker | Staging | Activación |
|---|---|---|
| W01 | `codex/calvo-ia6-staging-20261111-w01-held` | **EN ESPERA** del cierre real READY_FOR_IA6 de V2 y gate 38/38 |
| W02 | `codex/calvo-ia6-staging-20261111-w02-growth` | **EN ESPERA** del cierre real READY_FOR_IA6 de V3 |
| W03 | `codex/calvo-ia6-staging-20261111-w03-capture` | ACTIVA V4 tras V3 #42958535816 SUCCESS |
| W04 | `codex/calvo-ia6-staging-20261111-w04-evolution` | ACTIVA V4 tras V3 #42959076143 SUCCESS |
| W05 | `codex/calvo-ia6-staging-20261111-w05-books` | ACTIVA V4 tras V3 #42957930359 SUCCESS |

Cada staging tiene una copia del plan en `docs/coordination/items_parallel_v1/IA6_AUTORUN.md` y un `CONTINUOUS_V4/STATE_W0X.md`. La rama histórica propia de cada W recibe enlace/redirect. Si la ventana está vinculada a un workspace local con cambios sin publicar, primero hacer checkpoint y comprobar HEAD/working tree; **no perder trabajo por checkout**. Una `p` retoma la siguiente fase autorizada; el usuario no debe transportar informes ni pedir una tanda al terminar cada 10.

## Fases comunes, continuas
1. **A — Diff selectivo:** comparar source code SHA exacto de la W certificada contra el staging basado en IA6; inventariar los hunks por función y conservar arreglos y políticas ya presentes en IA6. Prohibido copiar clases compartidas enteras, hacer merge completo o introducir código no incluido en el plan. Añadir pruebas rojas que fallen en baseline y pasen con la corrección. No modificar históricos inmutables para maquillar FAIL; usar waiver de IDs promocionados de V1 con evidencia previa y aserción positiva nueva.
2. **B — Puerta local funcional:** ejecutar casos L3 de producción, propiedad, consumos, rollback, SaveV2, contexto y regresiones pertinentes en **la staging**, no citar únicamente CI de la rama W histórica. Preparar runtime Godot headless, Python, nativo cuando aplique. Un staging green no es integración conjunta.
3. **C — Entrega a IA6:** CI `completed/success` sobre SHA exacto del staging con workflow propio; report `reports/W0X/CONTINUOUS_V4_STAGING_FINAL.md`, file-hunks, dependencias frente a otras W, pruebas y limitaciones. Publicar `READY_FOR_IA6_MERGE`, no generar más rondas de QA o inventar objetos.

**Stop válido:** misión V4 agotada; todos los siguientes archivos fuera de permiso; daño a baseline que exige decisión IA6; turno/contexto agotado (checkpoint y p). No detener por 10/10 si quedan fases. No ejecución en segundo plano.

## Dependencias cruzadas y orden IA6, NO automático
- W02 naturaleza efectiva vs W04 `CreatureInstance` / `EvolutionSystem`: IA6 integrará por función, preservará ambos.
- W03 ledger/repelentes y W05 `FieldItemBag`: la staging W05 ya tiene Rope del baseline IA6; no acreditar Repel conjunto hasta que IA6 incorpore W03.
- W01 held backend + W03 captura: no reescribir `native_engine.cjs` genérico.
- W04 origen/destino `form_id` vs SaveV2 de W03 ledger: validaciones aditivas, no reemplazo de documento.
- La política Dinamax Candy permanece excluida en todos los estadios y debe comprobarse en CI.
- `main`, V28, PR118 protegidos: las staging no publican producción conjunta por sí solas.

Métricas: `Fases A/B/C | hunks reales | L3 de integración local | regresiones PASS | conflictos no resueltos | CI SHA | integración central: NO`. Cero objetos nuevos es normal en una campaña de integración.
