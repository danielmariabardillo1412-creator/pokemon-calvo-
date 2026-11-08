# IA2/W02 — CAMPAÑA_006 | Bloque 10/10 | Entrenamiento E2E

**Rama exclusiva:** `codex/calvo-items-20261104-w02-camp006`. Puerta de entrada: [CI 42418112808](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42418112808), `completed/success` en `7ac50f4fce12ee19fe9862538ca0ccd6a30939e0`.

## Contratos reales por objeto

| ID | Estado de publicación | Evidencia y límites |
| --- | --- | --- |
| `lucky_egg` | Efecto positivo por certificar en CI10 | Mochila → equipado → SaveV2 → salida segura STORAGE/participación en combate → XP 106 frente a 71 sin objeto → SaveV2 y persistencia de propiedad |
| `soothe_bell` | Efecto positivo por certificar en CI10 | Mochila → equipado → SaveV2 → entrenamiento real con proteína desde PARTY → amistad +7 vs +5 sin objeto, EV +10 Ataque, consume proteína, nunca cascabel → SaveV2. No se atribuye efecto a caminar o subir nivel |
| `exp_share` | **L1 dependencia IA6**, no L2 | Equipamiento y SaveV2 funcionan, pero `ProgressionSystem.reconcile_battle_result` reparte XP solamente a `participants`. Una criatura elegible no participante, con `exp_share` equipada, no gana experiencia; no inventar XP ni contar ese caso como positivo |

Prueba Godot: `tests/gameplay/parallel_items_w02_campaign_006_block10.gd`, 3 IDs × 3 estados (`active`, `reserve`, `none`): **4 efectos positivos**, **2 pruebas de dependencia**, **3 controles negativos** (sin inventario). Conserva tests de equipamiento repetido, rollback, identidad, propiedad, consumo, XP, amistad y SaveV2. Prueba de contrato Python adicional: `tests/tools/test_parallel_items_w02_campaign_006_block10.py`.

**No modificar** IA6, `ProgressionSystem`, contratos del motor de batalla, `modules/save/**`, `StatCalculator`, `main`, V28 o ramas de otras trabajadoras. Las mentas 02/03 salvo `gentle_mint` no se declaran positivas retroactivamente.

**CI pendiente**: el trabajo solo pasa a `CAMPAÑA_006_FINALIZADA` cuando GitHub confirma `completed/success` para el SHA final, incluidos CAMP005 10/10, CAMPAÑA_006 01–10, CAMP004/003. Un `SUCCESS` no implica que `exp_share` funcione. Tras éxito, reportar las dependencias concretas a IA6 para integración, sin fusionar nada automáticamente.
