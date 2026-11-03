# IA4/W04 — CAMPAÑA_005 / Bloque 03: condiciones de evolución

**Rama exclusiva:** `codex/calvo-items-20261103-w04-camp005`  
**Bloque 03/10 — objetos ya auditados, NO nuevos:** `oval_stone;dawn_stone;peat_block`.  
**Estado inicial:** `EN_CI_AUTOMATICA` hasta verificar logs reales de Python/Godot.

## Rutas canónicas y condiciones

| Objeto | Ruta | Fuente cruda PokeAPI | Condición que no puede omitirse |
| --- | --- | --- | --- |
| `oval_stone` | Happiny → Chansey | `data/api/v2/evolution-chain/51/index.json` | `level-up`, Piedra Oval **equipada** y `time_of_day=day`, **sin mínimo numérico suministrado** |
| `dawn_stone` | Kirlia → Gallade | `data/api/v2/evolution-chain/140/index.json` | `use-item` y `gender=2` (**macho**, en PokéAPI) |
| `dawn_stone` | Snorunt → Froslass | `data/api/v2/evolution-chain/186/index.json` | `use-item` y `gender=1` (**hembra**, en PokéAPI) |
| `peat_block` | Ursaring → Ursaluna | `data/api/v2/evolution-chain/110/index.json` | `use-item` y `time_of_day=full-moon` |

Los niveles 20/30 de las etapas anteriores de Kirlia/Ursaring y 42 de la ruta Snorunt→Glalie **no sirven como umbrales de las rutas anteriores**. `full-moon` y `day` son contratos de contexto, no horas o fases inferidas arbitrariamente.

## Dependencias de integración identificadas

1. `modules/creatures/progression/evolution_system.gd::_conditions_are_runtime_compatible` solo acepta `base_form` y `relative_physical_stats`; clasifica las rutas de `gender`, `held_item` y `time_of_day` como `DATA_ONLY`. Debe verificarse que no degrada requisitos a evolución genérica.
2. `EvolutionSystem.level_up_context(creature)` contiene nivel/bloqueo por Everstone/ataque/defensa, no transmite el objeto equipado ni `time_of_day`. El productor `ProgressionSystem` necesita contexto de hora si IA6 adopta tal integración.
3. `modules/creatures/domain/creature_instance.gd` no guarda `gender`. Sin identidad de sexo persistente y un contrato de generación/migración/SaveV2, **no es seguro habilitar Dawn Stone**. Kirlia y Snorunt necesitan comprobar especies, sexo y destino; no basta con tener piedra.
4. El motor de campo actual no recibe una fase lunar aprobada para `peat_block`. Tampoco debe confundirse un literal PokeAPI `full-moon` con una implementación de calendario/reloj.
5. `oval_stone` y `dawn_stone` están entre los equipables del perfil actual; `peat_block` no. Esta autorización de equipamiento **no certifica** que las evoluciones sean ejecutables.

**Decisiones/contratos para IA6:** fuente y ciclo día/noche, fuente de fase lunar (o requisito equivalente decidido para el juego), almacenamiento de sexo e integración en SaveV2, y semántica de consumo del objeto equipado y del objeto de uso directo. No editar APIs compartidas sin coordinación ni simular evolución sin condición.

## Nuevo trabajo verificable publicado

- Fixture acumulativo `tests/fixtures/parallel_items/w04_campaign_005.json`, commit `b97b1d83f2d0e310fbf00d6fb1b0b486c2064faf`: los cuatro registros de las tres piedras y sus fuentes PokeAPI sin inventar niveles.
- Runner `tests/gameplay/parallel_items_w04_campaign_005.gd`, commit `28d5f533425cd3b2678cf8fe572e96a1e09da346`: añade bloque 03, clasifica condiciones runtime y verifica ruta específica, uso/evolución rechazados, equipamiento conforme al perfil, identidad, cantidad, propietario ajeno y SaveV2 en Happiny, Kirlia, Snorunt y Ursaring; conserva bloques 01–02.
- Validador Python `tests/tools/test_parallel_items_w04_campaign_005.py`, commits `0a08776da7618a538000f2e214db64d9a4b6019a` y `2876c4556064a6da65c354d8b9c06b764c8ace0d`: cuatro cadenas PokeAPI, sexo/hora/luna, catálogo seleccionado, falta de género persistente y aserciones de runtime, acumulando los 9 objetos anteriores.
- CSV `docs/coordination/items_parallel_v1/reports/W04/CAMP_005_PROGRESO.csv`, commit `4f3b07a8c391bee07b6d510eb335fb915cc064e9`: fila 03 `EN_CI_AUTOMATICA`, hasta la verificación del log.

**Puerta de CI:** exigir `CAMP005_W04_MANIFEST_PASS reserved=10 completed=3 ids=46`, `CAMP005_W04_PY PASS blocks=3 checks=N` y `CAMP005_W04_GODOT PASS blocks=3 checks=N`. Corregir errores reales dentro de la rama W04 y repetir antes de reconciliar.

**Aislamiento:** ninguna modificación en `main`, V28, rama árbitra, ramas W01/W02/W03/W05, scripts de producción, datos canónicos ni workflows. Regresiones anteriores conservadas; workflow solo las ejecuta en hitos 05/10 o con parche en `modules/`.

**Próximo `p` autorizado tras aprobar CI03:** exclusivamente bloque 04 `galarica_cuff;galarica_wreath;scroll_of_darkness;scroll_of_waters`.
