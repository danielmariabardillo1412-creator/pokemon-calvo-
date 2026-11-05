# IA2/W02 — CAMPAÑA_006 | BLOQUE 05/10: equipables de progresión

**Orden IA6:** fila05 de `CAMPAIGN_006_W02_QUEUE_APPROVED.csv` = `everstone;exp_share;lucky_egg`. **Rama exclusiva:** `codex/calvo-items-20261104-w02-camp006`. Sin cambiar producción, API de progresión, `StatCalculator`, `EvolutionSystem`, batalla, SaveV2, `main`, V28, árbitra ni las ramas de otras trabajadoras.

## Evidencia de origen y diagnóstico funcional

| ID | Conexión comprobable en motor actual | Certificación exigida en el piloto |
| --- | --- | --- |
| `everstone` — Piedra Eterna | `ProgressionHeldItems.blocks_level_evolution` invocado por `EvolutionSystem.level_up_context` | Equipar desde mochila real, Bulbasaur sube 15→16 sin evento de evolución, quitar piedra habilita candidato Ivysaur; conservar propietario, bolsa, SaveV2 |
| `lucky_egg` — Huevo Suerte | `ProgressionHeldItems.battle_reward_amount` invocado por `ProgressionSystem.reconcile_battle_result` | Recompensa de combate 71→106 XP con objeto activo, evento XP exacto, no consumido, quitar objeto devuelve 71 XP; PARTY/STORAGE, SaveV2 |
| `exp_share` — Repartir Exp. | **El descriptor permite equipar, pero no existe una ruta de reparto** en `ProgressionSystem` ni `ProgressionHeldItems` | No declarar efecto; controlar que un no participante no recibe XP, y emitir dependencia única para IA6 sobre política/distribución |

Los dos efectos positivos de Piedra Eterna/Huevo Suerte ya tenían implementación en código de progresión V18 (documentación `docs/current/ITEM_PROGRESSION_V18.md` y `tests/gameplay/progression_items_v18.gd`). El bloque 05 **no reimplementa ni cambia su lógica**: añade pruebas acumulativas conectando `FieldItemService.equip/unequip`, el cálculo de progresión real, propietario PARTY/STORAGE, ausencia de stock y SaveV2. Son pruebas nuevas de integración en la rama W02; no se presentan como nuevos handlers de producción.

**Exp Share es una dependencia, no un efecto positivo.** Puede figurar en `item_connections_v1.json` y equiparse sin que `ProgressionSystem.reconcile_battle_result` distribuya experiencia a los Pokémon de reserva/no participantes. Ese método calcula `survivors` desde `participants` y reparte solo a esa colección. No hay una ruta ni la política de destinatarios de `exp_share`.

## Dependencia IA6 concreta

**Clave:** `EXP_SHARE_PROGRESSION_DISTRIBUTION_POLICY_006_W02`; **responsable de decisión:** IA6. Para implementar el efecto real debe fijar: semántica de generación (objeto equipado frente a reparto global), destinatarios y elegibilidad (participantes/no participantes, desmayados y nivel 100), fórmula, redondeo, multiplicación con Huevo Suerte y guardado de propiedad. Después autorizar intervención mínima en `ProgressionSystem.reconcile_battle_result`, su helper/contexto de propietarios y pruebas de nivel/SaveV2. Ninguna modificación de esos módulos se ha hecho en esta fila. El estado registrado es **L1/DEPENDENCIA_DOCUMENTADA** para ese ID, no L2.

Hay otra dependencia previa distinta: después de aplicar una menta de bloque04, `FieldGrowthEffects.validation_error` y `FieldMochiEffects.validation_error` todavía usan `nature_id` original en lugar de la naturaleza efectiva. Su modificación requiere autorización IA6. **No se ha intentado alterar esos consumidores para completar bloque05.**

## Matriz de pruebas nuevas y puerta de CI

- `tests/fixtures/parallel_items/w02_campaign_006.json`: quinto bloque, tres IDs y exactamente tres oráculos independientes; dos `held_positive` y uno `held_dependency`. Se conserva el piloto de mentas bloque04 con su run [41788596358](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41788596358) `completed/success`.
- `tests/gameplay/parallel_items_w02_campaign_006.gd`: por cada ítem y modo `active`, `reserve`, `none`, se comprueba equipar desde mochila (−1), rechazo por falta de stock, rechazo de equipar dos veces, SaveV2 antes/después. Piedra Eterna: progresión/evolución reales y retirada. Huevo Suerte: conciliación de recompensa de combate real y reversión al retirarlo. Repartir Exp.: ausencia de experiencia para Pokémon no participante y stock inalterado tras combate. Recibo `CAMP006_W02_HELD05 PASS block=05 positive=2 dependency=1` **solo si Godot ejecuta todas las aserciones**.
- `tests/tools/test_parallel_items_w02_campaign_006.py`: golden exacto, fuente/IDs/naturaleza del bloqueo, seis mutaciones adversariales, guarda de 288 escenarios históricos. Recibo `CAMP006_W02_HELD05_CONTRACT READY positives=2 dependency=1` indica contrato estructural, no sustituye Godot.
- `.github/workflows/parallel-camp006-w02-autoci.yml`: mantiene CAMP005 Python/Godot, bloque01 recuperación, filas02/03 dependencias, mentas04 positivas, y regresiones CAMP004/003. Añade los dos recibos de bloque05 sin suavizar los anteriores.

**Estado de este informe previo al run:** dos rutas positivas ya conectadas y una dependencia; **CI nueva pendiente**. No declarar `CI_PASS_VERIFICADO` sin `completed/success` y logs del SHA correspondiente.

**Siguiente `p`:** ejecutar únicamente fila06 `power_anklet;power_band;power_belt`, siempre comprobando la CI del quinto bloque. No abrir trabajo compartido sin permiso IA6.
