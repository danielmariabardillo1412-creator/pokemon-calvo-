# IA2/W02 — CAMPAÑA_005 — BLOQUE 01/10

**Encargo IA6:** `CAMPAIGN_005_W02_GATE.md`, cola oficial `CAMPAIGN_005_W02_QUEUE_APPROVED.csv` fila 01 y `campaigns/CAMP_005_W02.md`. **Única rama:** `codex/calvo-items-20261103-w02-camp005`. Arranque autorizado: solo bloque 01, `ability_capsule;ability_patch;rare_candy;pp_up`. No se han modificado `main`, V28, PR #118, CAMP004, otros workers, motores ni workflows.

## 18 escenarios × 3 estados de propiedad = 54 variantes funcionales programadas

| ID | Casos | Ruta nativa y oráculo independiente |
| --- | ---: | --- |
| `ability_capsule` | 4 | Growlithe `intimidate → flash_fire`, `flash_fire → intimidate`; rechazos desde habilidad oculta y con slot inesperado |
| `ability_patch` | 4 | `intimidate/flash_fire → justified`, `justified → intimidate`; slot inesperado se rechaza |
| `rare_candy` | 4 | Mew `nivel 50 → 51`, `99 → 100`, comprobación de XP exacta según curva, PS faltantes, amistad y PP intactos; nivel 100 sin evolución se rechaza y slot inesperado también |
| `pp_up` | 6 | Un boost de 20% de PP base en `growl` y `protect`, manteniendo PP usados (aumento actual y máximo del mismo delta), amistad; rechaza tres boosts previos, ausencia de slot y slot inválido |

**Pruebas reales conectadas:** `tests/gameplay/parallel_items_w02_campaign_005.gd` hereda solamente utilidades y métodos de los runners existentes CAMP004/CAMP003, pero ejecuta su propia fixture CAMP005. Por cada escenario llama `FieldItemService.use_item` con un Pokémon real creado mediante `CreatureFactory`, y para habilidad verifica `ability_preview` y el sello. Ejecuta `PARTY con dos unidades`, `PARTY sin objeto`, `STORAGE con dos unidades`. Inspecciona aceptación/rechazo, mutación atómica, origen no alterado, consumo único, transición de habilidad, crecimiento XP/level, máximo y PP actuales, estado, EV/IV/naturaleza, amistad, persistencia SaveV2 y recibos JSON SHA256. Registra `CAMP005_W02_GODOT PASS blocks=1 checks=M` solo si las aserciones ejecutadas pasan.

`tests/tools/test_parallel_items_w02_campaign_005.py` implementa golden independiente con los 18 casos, controles estrictos de cola, modos, orden, duplicados, rutas reales de `field_ability_effects.gd`, `field_growth_effects.gd` y `field_pp_boost_effects.gd`, además de **15 mutaciones negativas**. Compara la conexión transaccional con `field_item_service.gd` y referencias de regresión `item_field_ability_v10.gd`, `item_field_growth_v9.gd` e `item_field_pp_v8.gd`. Recibo `CAMP005_W02_PY PASS blocks=1 checks=M` exige que las aserciones pasen en ejecución real.

## Commits y estado

- Fixture `tests/fixtures/parallel_items/w02_campaign_005.json`: `a9b847c3dc9800fdba3fb3ec332835396b7c36c2`.
- Runner Godot `tests/gameplay/parallel_items_w02_campaign_005.gd`: `35eda1841902611c6dd5fd178bec95aab258dc98`.
- Python `tests/tools/test_parallel_items_w02_campaign_005.py`: `b40efaa6b026e79a8d2e7b513bae607d65be6692`.
- Progreso `docs/coordination/items_parallel_v1/reports/W02/CAMP_005_PROGRESO.csv`, fila 01: `67448949dd933e01f907fe30023dba000dc50b9c`, estado `EN_CI_AUTOMATICA`.

**Comprobación ya realizada:** 14 controles de **coherencia estática** de identidad, 18 escenarios, igualdad golden, 4 ID únicos, ruta Python, ruta Godot, perfil/semántica y manifiesto oficial, todos correctos. **No equivalen a CI Godot/Python aprobada**. El workflow existente `.github/workflows/parallel-camp005-w02-autoci.yml` se dispara en push sobre esta rama y espera recibos con blocks=1; la ejecución no está confirmada en esta sesión. `fetch_commit_workflow_runs` y `get_commit_combined_status` devolvieron listas vacías en el SHA de progreso; el acceso externo web dio `DisabledError` y el contenedor no dispone de Godot ni resolución DNS de github.com. No afirmar PASS/FAIL ni inventar run.

**Regresiones:** las campañas CAMP004 10/10 y CAMP003 10/10 permanecen intactas. Su comprobación nueva en CAMP005 se exige al menos en hitos 05 y 10 y para parches propios de producción, según la CI autorizada por IA6. No se ha modificado producción.

**Siguiente `p`:** revisar CI y reparar fallos en archivos propios bajo V5 sin relajar aserciones; después ejecutar solamente bloque 02 `pp_max;hp_up;protein;iron` en esta rama. Si emerge necesidad de cambiar `field_item_service.gd` o API común, coordinar con IA6. No avanzar directamente a 03.
