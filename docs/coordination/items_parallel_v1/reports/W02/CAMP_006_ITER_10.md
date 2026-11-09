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

**Estado al publicar el bloque:** CI todavía pendiente. El acta de cierre definitivo, confirmada posteriormente por IA6, figura a continuación. Ningún `SUCCESS` implica que `exp_share` reparta XP.

## ACTA DEFINITIVA DE CIERRE — CAMPAÑA_006_FINALIZADA

**Fecha del cierre registrado:** 2026-11-09. **Autoridad:** confirmación de IA6 y consulta directa de GitHub Actions.

- **Estado oficial de IA2/W02:** `CAMPAÑA_006_FINALIZADA`; diez microbloques ejecutados y certificados conforme a los contratos individuales, **no** diez bloques compuestos exclusivamente de objetos funcionales.
- **CI de validación final:** [42437567862](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42437567862), estado `completed`, conclusión **`success`**. SHA validado: `a571d33266bc445207ed9e8d03cd34e33ac8b071`. La rama W02 coincidía exactamente con ese SHA antes de la presente actualización **solo documental**.
- **Alcance:** bloques 01–10; recuperación y 288 casos de CAMPAÑA_005, pruebas nativas Godot/Python del bloque 10, y regresiones históricas CAMPAÑA_004/003 incluidas en la CI final. No se reclasifican por el mero hecho de pasar CI los efectos no implementados.
- **`lucky_egg`:** bonificación real ×1,5 de experiencia comprobada en combate, inventario y SaveV2.
- **`soothe_bell`:** bonificación real ×1,5 de amistad generada por proteína y otros productores de campo conectados; no se certifica un productor universal de amistad por caminar/subir nivel.
- **`exp_share`:** **DEPENDENCIA ABIERTA, L1, propietario IA6.** Equipamiento y persistencia SaveV2 comprobados; **NO existe distribución funcional acreditada a Pokémon no participantes**. Contrato y prueba pendiente en `CAMP_006_EXP_SHARE_IA6_DEPENDENCY.md`.
- **Resto de dependencias:** las mentas históricas de bloques 02/03 que no hayan recibido pruebas positivas posteriores mantienen su clasificación de dependencia; `gentle_mint` sí dispone de prueba funcional propia en el bloque 09.
- **Control de cambios:** este cierre se limita a documentación; no modifica producción, tests, fixtures, workflows, reglas globales, `main`, V28 o ramas ajenas. Sin nueva CI, sin merge y **sin comenzar CAMPAÑA_007**. IA6 es responsable de la siguiente asignación.

**Parada operativa:** W02 queda detenida hasta nueva autorización expresa de IA6.
