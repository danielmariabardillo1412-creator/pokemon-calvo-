# IA2/W02 — CAMPAÑA_006 | BLOQUE 07/10: Power Bracer, Lens y Weight

**Rama:** `codex/calvo-items-20261104-w02-camp006`. **Autorización:** fila07 de `CAMPAIGN_006_W02_QUEUE_APPROVED.csv`.

## Puerta de continuidad
El run [41972015003](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41972015003) terminó **completed/success** en `58dc8103c8dd85275d477d4f563ca7ef279d9f86`; incluye CAMP005 10/10, bloques W02 01-06 y regresiones CAMP004/CAMP003.

## Motor existente e integración
`BattleEvRewards.award` ya implementa +8 EV por KO de objeto Power, aplicando topes de 252 por estadística/510 total, sin modificación de producción. La ruta real viene de `ProgressionSystem.reconcile_battle_result`.

| ID | EV adicional | Estadística |
| --- | --- | --- |
| `power_bracer` | +8 | Ataque |
| `power_lens` | +8 | Ataque Especial |
| `power_weight` | +8 | PS |

## Pruebas del bloque 07 (publicadas, CI pendiente)
- Fixture propia `tests/fixtures/parallel_items/w02_campaign_006_block07.json` y validador Python propio que comprueba IDs exactos, el mapeo productivo y los 288 escenarios heredados CAMP005.
- Runner Godot `tests/gameplay/parallel_items_w02_campaign_006_block07.gd`: 3 objetos × 3 modos (PARTY, STORAGE, sin stock); uso real `FieldItemService.equip`, persistencia SaveV2 antes/después, combate real con Magikarp (yield Velocidad), bonus de +8 por objeto, test negativo de divergencia entre held item al inicio/final, y límites 252/510 con consideración del orden de stats (para Lente Recia, el +1 de Velocidad del rival precede al bonus de Ataque Especial).
- Workflow CI actualizado con etapa Python y Godot bloque07 manteniendo recuperación CAMP005, bloque06 y regresiones.
- Progreso CSV actualizado: bloque05 41955498590 CI success, bloque06 41972015003 CI success; bloque07 queda explícitamente **pendiente**.

## Criterio de cierre
**No declarar funcionalidad L2 acreditada ni 7/10 cerrados** hasta comprobar que la nueva ejecución sobre el commit de este bloque termina `completed/success`. Si falla, corregir primero las pruebas sin suavizar las aserciones. No tocar `main`, V28, la rama árbitra o ramas de otras trabajadoras.

**Siguiente fila cuando esté aprobada:** bloque08 `macho_brace;soothe_bell`. `exp_share` sigue en dependencia IA6; mints de bloques 02/03 siguen dependencia, no se recalifican como L2.
