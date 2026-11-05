# IA2/W02 — CAMPAÑA_006 | BLOQUE 06/10: objetos Power y EV de combate

**Rama exclusiva:** `codex/calvo-items-20261104-w02-camp006`. **Fila oficial:** `power_anklet;power_band;power_belt`.

## Diagnóstico de producción
La implementación ya existe en `modules/creatures/progression/battle_ev_rewards.gd`, conectada desde `ProgressionSystem.reconcile_battle_result`. Cada objeto suma +8 EV por enemigo válido en su estadística: Tobillera Recia = velocidad; Banda Recia = defensa especial; Cinto Recio = defensa. Los límites son 252 por estadística y 510 totales; el objeto debe coincidir al inicio/final de combate para activarse. No se modificó producción.

## Contrato publicado, pendientes de confirmar por ejecución
- Fixture propia `tests/fixtures/parallel_items/w02_campaign_006_block06.json` con tres IDs, modos PARTY/STORAGE/sin stock y topes 252/510.
- Runner Godot `tests/gameplay/parallel_items_w02_campaign_006_block06.gd`: equipar desde `FieldItemService`, comprobar gasto de una unidad y rechazo atómico sin stock, SaveV2, combate con `ProgressionSystem.reconcile_battle_result`, EV inicial/final frente al yield real de Magikarp, XP y propiedad, objeto sin consumir, y topes de EV mediante `BattleEvRewards.award` real.
- Validador Python `tests/tools/test_parallel_items_w02_campaign_006_block06.py`: identidad de la cola y contrato del código real. No sustituye las aserciones nativas.
- Workflow `.github/workflows/parallel-camp006-w02-autoci.yml`: amplía la suite con la ejecución del bloque 06 y conserva la recuperación CAMP005, los bloques 01–05 y las regresiones CAMP004/003.

**Estado:** pruebas publicadas, pendiente leer conclusión del nuevo run completo. No declarar funcionalidad nueva ni `CI_PASS_VERIFICADO` sin run `completed/success`. Si Godot encuentra fallo, corregir la prueba/implementación únicamente dentro de la autorización W02, sin relajar aserciones.

**Antecedente:** bloque05 run 41955498590 terminado `completed/success`. Exp Share sigue dependencia IA6. Mentas 02/03 siguen dependencia. No tocar `main`, V28 ni ramas ajenas.

**Siguiente fila después del cierre CI:** bloque 07 `power_bracer;power_lens;power_weight`.
