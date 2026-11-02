# IA5/W05 — CIERRE DE ENTREGA CAMPAÑA_002 (3/3)

**Estado de entrega: `CAMPAÑA_002_FINALIZADA`**. Esto expresa cierre de tres microbloques autorizados, **no** certificación automática de la implementación.

| ITER | Entrega | Evidencia y límite |
| --- | --- | --- |
| 01 | Selector determinista de 12 MT nuevas (fixture + Python) | 11 tests Python y muestra real de 12 PASS en IA6 [#41484879741](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41484879741), sin enseñanza Godot |
| 02 | Runner parametrizado 6 MT por `FieldItemService.teach` | Godot 4.7 177 checks/6 casos PASS, [CI propia #41539925530](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41539925530) |
| 03 | Ampliación a 12 enseñanzas, SaveV2 y 19 legacy negativos; matriz 12/217/19 | Código publicado en `0af3e48aa60508601e494a81fd3bf52ee668465a`; **EN_CI_AUTOMATICA** hasta resultado de este SHA |

Todas las escrituras del bloque 03 se limitan a `tests/gameplay/parallel_items_w05_campaign_002.gd` y reportes `reports/W05`. Se preservan fixture y generador del bloque 01, y no se toca `FieldItemService`, 19 máquinas inactivas, selección canónica, `main`, V28, ramas ajenas, partidas reales ni PR #118.

**Cobertura prevista si CI ITER_03 da PASS:** exactamente 12 enseñanzas individuales nuevas; otras 217 MT activas solo con evidencias de metadatos/learnsets; 19 legacy negativas sin activar. Ni 229/229 enseñanzas ni la representación visual de los libros están certificadas.

**Acción de IA6:** verificar conclusión/sha del workflow automático y contraste del informe con el selector Python; si hay FAIL, diagnosticar antes de consolidar. No continuar a ITER_04 ni CAMPAÑA_003 por recibir `p`.
