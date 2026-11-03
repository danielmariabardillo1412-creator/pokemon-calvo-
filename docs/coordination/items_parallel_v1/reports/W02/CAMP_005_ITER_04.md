# IA2/W02 — CAMPAÑA_005 · MICROBLOQUE 04/10

**Autorización:** IA6, `CAMPAIGN_005_W02_GATE.md`, fila 04 de `CAMPAIGN_005_W02_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W02.md` y autonomía `AUTONOMOUS_REPAIR_V5.md`. **Única rama propia** `codex/calvo-items-20261103-w02-camp005`. Ninguna modificación en `main`, V28, rama árbitra, ramas ajenas, producción, catálogo de movimientos ni workflows. No se repiten bloques 01–03.

## 4 objetos y 32 escenarios nuevos × 3 propietarios = 96 variantes previstas

| ID | Ganancia nominal de XP | Contratos añadidos (8 por objeto) |
| --- | ---: | --- |
| `exp_candy_s` | 800 | Lvl50, lvl90, lvl99, lvl99 a 50 XP del tope, lvl50 a 80 XP del siguiente nivel, lvl100 rechazo, slot incompatible rechazo y amistad 200 |
| `exp_candy_m` | 3.000 | Mismas ocho condiciones: evolución del nivel según curva, no un nivel fijo |
| `exp_candy_l` | 10.000 | Mismas condiciones, con ganancias acumuladas y tope lvl100 |
| `exp_candy_xl` | 30.000 | Mismas condiciones, incluyendo **corte real de XP** en lvl99 cuando faltan menos de 30.000 XP para 100 |

**Datos y motor:** `modules/inventory/field_growth_effects.gd` define `EXP` = S 800, M 3.000, L 10.000, XL 30.000; usa `ProgressionRuleset.experience_for_level(...,100)`, `ProgressionSystem.gain_experience`, preserva déficit HP y concede amistad por bandas 5/3/2 si la ganancia real de XP es positiva. Los escenarios usan Mew para evitar decisiones de evolución/elección de movimiento que otros Pokémon podrían requerir (`NEEDS_CONTEXT`). No se afirma cobertura de todos los Pokémon ni implementación nueva de producción.

**Pruebas Godot:** `tests/gameplay/parallel_items_w02_campaign_005.gd` ahora acepta `exp_amount` por caso y calcula `expected_exp = min(experiencia máxima nivel100, experiencia inicial + exp_amount)`; deriva el nivel con `ProgressionRuleset.level_for_experience`, comprueba `result.exp_gained`, nivel, topes, cruces, amistad, PP/EV/IV/PS y ausencia de alteraciones espurias. Preserva la vía anterior de Caramelo Raro y XS. Como en los bloques anteriores, recorre `active` (PARTY con objeto), `none` (PARTY sin objeto) y `reserve` (STORAGE con objeto), comprobando inventario, consumo único/rechazo atómico, propietario, `SaveV2` y recibos JSON SHA256.

**Pruebas Python:** `tests/tools/test_parallel_items_w02_campaign_005.py` mantiene los golden independientes de los bloques 01, 02, 03 y añade `EXPECTED_04` con 32 casos exactos, fuentes de crecimiento y límites, checks de runner nativo y 16 mutaciones adversariales para IDs, fuente, cantidades, umbrales, niveles, rechazos y amistad.

## Evidencias subidas

- Fixture acumulada `tests/fixtures/parallel_items/w02_campaign_005.json`, commit `8ea4575de1ef5cb95a26e5ddbe735ea9342d4b9c`.
- Godot `tests/gameplay/parallel_items_w02_campaign_005.gd`, commit `fd3ee2148a8d212fadbfc36924b88181276243a6`.
- Python `tests/tools/test_parallel_items_w02_campaign_005.py`, commits `8979e0e13415cde375b6147643fb5f79da4e5cd5`, `c5ea35ed91423b48e0152cdef92eabfe2b2ea2e6`, `8d1952aa84d06b7df7b860025d12b786df4dbf14`, `613402863a376d19ff17cab506ad6fac0cb71b2d` y `f188b8b3a05c28303b293fb2c295d615371d7673`.
- CSV `docs/coordination/items_parallel_v1/reports/W02/CAMP_005_PROGRESO.csv`, fila 04 `EN_CI_AUTOMATICA`, commit `9fcffee3aa161c7123c2c36206ac27cce0e20915`.

## Estado y siguiente paso

**Acumulado publicado:** bloques 01–04, **16 IDs**, 100 escenarios y **300 variantes de prueba preparadas**; todavía **no son 16 objetos certificados**. Se han comprobado estructuralmente los cuatro bloques y sus golden, pero **aún no existe un log de Python/Godot CAMP005 con `PASS blocks=4` verificado en esta sesión**. El conector de runs por commit no enumera necesariamente eventos `push`; resultados `[]` no certifican PASS, FAIL ni ausencia de ejecución. El historial exitoso de CAMP004 y sus regresiones permanece intacto, sin reutilizarlo como certificación CAMP005. No hay pruebas UI/GPU ni integración global verificadas aquí.

**Siguiente `p`:** intentar recuperar logs/estado real de CI, reparar fallos en pruebas propias según V5 sin reducir aserciones; después ejecutar **sólo fila 05** de la cola IA6. En el hito 05 el workflow ejecutará también las regresiones CAMP004 y CAMP003. No alterar APIs compartidas ni `main`/V28 sin autorización.
