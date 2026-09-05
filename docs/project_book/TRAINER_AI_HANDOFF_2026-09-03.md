# TRAINER AI — relevo de conversación 2026-09-03

Este archivo es un checkpoint de relevo. No sustituye a `docs/project_book/TRAINER_AI.md`, que sigue siendo el cuaderno canónico. Su función es permitir que una conversación nueva retome el trabajo sin depender del contexto del chat anterior.

## Estado seguro de entrada

Repositorio: `danielmariabardillo1412-creator/pokemon-calvo-`

Rama de trabajo: `audit/trainer-ai-v3-random-cup-redesign-v1`

PR temporal: `#105`

REGLA CRÍTICA: PR #105 NO SE MERGEA. `main` no se toca salvo autorización expresa del usuario.

`main` certificado/observado: `f8452a1625ccb8389c9e52ff4416a96a24e00efd`.

Último freeze documental canónico antes de este relevo:

`5b8031b4b15c7cf39287583828b593c556005f9b`

Commit: `docs(trainer-ai): freeze C3f-u as 26.42`

La sección canónica de continuidad es:

`TRAINER_AI.md` → `26.42 C3f-u — la validación adversarial ampliada conserva 72/72 y el scheduler compartido solo completa 32/32 con 660 en la muestra`.

En ese freeze C3f-u está CERRADA y certificada. No debe reabrirse ni reinterpretarse desde recuerdos del chat.

## Checkpoints C3f-u

Baseline documental 26.41:
`f63665420facd3b001695cc340a7a004efb85e32`

Checkpoint técnico limpio:
`fb3b7ac5e04520cfcab1c807dd77db2e4ad3a75d`

Checkpoint humano tree-identical:
`259a0bf6fac0f29c640b45f05612487a2038a07d`

Tree común técnico/humano:
`c0afe5b9a28235e8644391fc12a4181e23e8fc09`

Diff técnico limpio frente a 26.41:
- `tests/trainer_ai/trainer_roster_search_broader_adversarial_shared_budget_audit_test_suite.gd`: +807
- `tests/trainer_ai/trainer_team_composition_test_runner.gd`: +1/-1
- cero producción.

Certificación técnica y humana:
- 18/18 GitHub Actions SUCCESS;
- FASE33: 832 PASS / 0 FAIL;
- Godot 4.7 SUCCESS;
- DATA V3 SUCCESS;
- Search Foundation SUCCESS;
- Search Depth Budget SUCCESS;
- Search Limit Benchmark SUCCESS;
- Strategic Switching V2 SUCCESS;
- resto de workflows Trainer SUCCESS.

El freeze documental `5b8031b4...` también mostró 18/18 workflows SUCCESS.

## Resultado congelado de C3f-u

Suite:
`TrainerRosterSearchBroaderAdversarialSharedBudgetAuditTestSuite`

Audit ID:
`c3f_u_broader_adversarial_shared_budget_audit_v1`

Scheduler TEST-ONLY:
`equal_upfront_root_reservation_no_redistribution_v1`

Modelos productivos observados, SIN modificación:
- search: `simultaneous_depth_budget_v1`;
- sampler: `kind_stratified_round_robin_v1`;
- inner depth: 2;
- `max_actions_per_side`: 3;
- `max_worlds`: 4;
- `max_simulations` por root: 220.

Muestra expandida:
- 48 casos legacy C3f-t;
- 24 nuevos adversariales;
- 72 totales;
- 72 semánticamente completos;
- 0 inconclusos;
- 258 candidatos adversariales no-legacy screened;
- 0 screen failures;
- 1021 species elegibles;
- 306 tie contexts poblacionales de referencia.

Rank del ganador depth2 frente al screen depth1 en los 72 casos:
- rank 1: 54;
- rank 2: 11;
- rank 3: 5;
- rank 4: 2;
- gap max: 1665.

Candidatos TEST-ONLY sobre 72 casos:
- `depth1_margin_3000_all_legal`: 72/72 conserva deep optimum, 0 pérdidas, total simulations 13323;
- `depth1_topk_4_tie_preserving`: 72/72, 0 pérdidas, total 16641;
- `depth1_margin_6000_all_legal`: 72/72, 0 pérdidas, total 17217.

Interpretación obligatoria: `margin3000` fue el menos costoso de esos tres EN ESTA MUESTRA, pero no está probado seguro globalmente y NO está seleccionado para producción.

Scheduler ejecutado sobre 32 contextos con shared budgets `[220, 440, 660]`:
- budget 220: 14 truncados/no-decision; preserva oracle best 18/32;
- budget 440: 8 truncados/no-decision; preserva 24/32;
- budget 660: 0 truncados, 0 no-decision; preserva 32/32;
- budget violations globales: 0;
- forward/reverse allocation mismatches: 0.

Interpretación obligatoria: 660 funciona 32/32 bajo ESTE scheduler y ESTA muestra. No es una cota global ni un budget productivo autorizado.

## Barreras semánticas que siguen congeladas

NO usar Pareto como hard pruning/preselector.
NO usar roster value como preselector.
NO usar `TrainerProfile` como tiebreak pre-search.
NO introducir hidden beliefs.
NO introducir live RNG.
NO introducir recovery/replacement/campaign policy.
NO modificar production sampler, production budgets, phase logic o brains sin autorización explícita posterior.
NO inferir seguridad global de resultados 72/72 o 32/32.
NO seleccionar todavía `margin3000`, budget 660 ni el scheduler auditado como política productiva.

Estado explícito al cerrar C3f-u:
- `selected_shared_budget = null`;
- `selected_strategy_id = null`;
- `production_strategy_selected = false`;
- `search_sampling_redesign_authorized = false`;
- `behavior_integration_authorized = false`.

## Siguiente microtranche autorizada

La siguiente microtranche autorizada por 26.42 es únicamente:

**C3f-v — TEST/AUDIT-ONLY held-out validation of the 0-loss screen candidates and shared-budget scheduler robustness before any production port.**

Antes de implementar C3f-v, leer literalmente el final de la sección 26.42 de `TRAINER_AI.md` y tomar de allí sus requisitos exactos. Este handoff resume el objetivo, pero el texto canónico manda si hay cualquier diferencia.

Objetivo de C3f-v:
- validar fuera de la muestra usada para seleccionar/fortalecer los candidatos C3f-t/C3f-u;
- comprobar si `margin3000` y los otros candidatos 0-loss siguen preservando el oracle deep optimum;
- someter el scheduler de shared budget a held-out contexts y medir truncation/no-decision/oracle-best preservation;
- mantener controles de permutation/order;
- medir coste real, no solo accounting teórico;
- reportar cualquier pérdida o counterexample sin parchear la muestra para hacerlo desaparecer;
- seguir siendo TEST/AUDIT-ONLY y no elegir todavía política productiva salvo que una autorización documental posterior lo permita.

## Modo de trabajo obligatorio

1. Al entrar en una nueva conversación, verificar LIVE el head de PR #105 y el SHA de `main`; no asumir que este archivo sigue siendo HEAD.
2. Leer `docs/project_book/TRAINER_AI.md`, al menos la sección 26.42 y su final, antes de tocar código.
3. Si el head ya avanzó por encima de este relevo, seguir el cuaderno canónico más reciente, no retroceder a C3f-v por inercia.
4. Trabajar por microtranches. Cada tranche debe quedar importable y verificable.
5. No afirmar certificación hasta comprobar CI exacta.
6. Para una tranche técnica: crear checkpoint técnico limpio, ejecutar la matriz completa de CI y registrar resultado exacto de FASE33.
7. Si procede, crear checkpoint humano tree-identical con el mismo tree y el mismo parent del baseline; volver a certificar CI.
8. Congelar después el resultado en `TRAINER_AI.md` mediante commit documental limpio y volver a comprobar CI del freeze.
9. Mantener PR #105 OPEN y UNMERGED; comprobar que `main` no cambió.
10. Si aparece un staging defectuoso, no maquillar resultados ni reducir cobertura. Corregir causa demostrada o descartar el sibling de staging y reconstruir un checkpoint limpio desde el baseline.
11. No convertir orden lexical en preferencia semántica.
12. No convertir resultados de muestra en garantías globales.
13. Distinguir siempre root fan-out del cap interno `max_actions_per_side`.
14. Si la arquitectura no permite auditar correctamente algo sin modificar producción cuando la tranche es audit-only, PARAR y documentar el blocker en vez de entrar en un ciclo de parches productivos.
15. No inventar SHAs, CI, métricas ni causas raíz. Verificar todo en GitHub.

## Herramientas / patrón GitHub

Usar el conector GitHub para estado privado/real del repositorio. Acciones útiles: fetch PR, fetch file, fetch commit, compare commits, workflow runs/jobs/logs, create/update file, Git data commits/trees/refs cuando sea necesario.

Para freezes documentales grandes, el patrón ya probado es payload temporal + workflow temporal de append + limpieza + commit documental limpio. Verificar siempre que payload/workflow temporales desaparecieron antes de certificar el HEAD final.

## Regla de relevo

Cuando el usuario diga `sigue` en la conversación nueva, NO pedir que repita el contexto. Verificar HEAD/main, leer el final canónico de `TRAINER_AI.md` y ejecutar directamente la siguiente microtranche autorizada desde el último baseline certificado.
