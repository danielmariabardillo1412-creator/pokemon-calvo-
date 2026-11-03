# IA2/W02 — CAMPAÑA_005 / MICROBLOQUE 06/10

**Autorización:** IA6, `CAMPAIGN_005_W02_GATE.md`, `CAMPAIGN_005_W02_QUEUE_APPROVED.csv` (fila 06), `campaigns/CAMP_005_W02.md`, `AUTONOMOUS_REPAIR_V5.md`. **Rama exclusiva:** `codex/calvo-items-20261103-w02-camp005`. No se modificaron producción, `main`, V28, PR118, árbitra ni ramas ajenas.

## Cuatro IDs nuevos: 32 casos y 96 variantes preparadas

| ID | Tipo y función real | Ocho escenarios por ID |
| --- | --- | --- |
| `clever_wing` | Pluma: **+1 EV Defensa especial**, amistad +3/+2/+1 por tramo | 0 EV; 251→252; 252 rechazo; total 509→510; total 510 rechazo; slot incorrecto; amistad 254→255; tope global 509 con 1 EV disponible |
| `swift_wing` | Pluma: **+1 EV Velocidad**, amistad +3/+2/+1 | Mismas ocho condiciones positivas y negativas |
| `health_mochi` | Mochi: **hasta +10 EV PS, sin modificar amistad** | 0 EV; 248→252 (+4); 252 rechazo; 508→510 (+2); 510 rechazo; slot incorrecto; amistad 254 permanece en 254; total 509 añade solo 1 EV |
| `muscle_mochi` | Mochi: **hasta +10 EV Ataque, sin modificar amistad** | Mismas ocho condiciones, sin bonus de amistad |

**Contratos nativos:** `modules/inventory/field_training_effects.gd` tiene el mapa `clever_wing → special_defense` y `swift_wing → speed`, +1 EV y amistad `[3,2,1]`. `modules/inventory/field_mochi_effects.gd` define los dos mochis (+10 EV máximo y topes 252/510) y no llama al sistema de amistad; `field_item_effects.gd` despacha `Mochi.apply` y `FieldItemService` gestiona la transacción y consumo. Historial técnico `tests/gameplay/item_mochi_v13.gd` y `docs/current/ITEM_MOCHI_V13.md` confirma **la discrepancia de referencias sobre amistad**: se preserva el contrato RHH V13 implementado; no se inventa equivalencia con otras referencias de Pokémon.

**Godot:** `tests/gameplay/parallel_items_w02_campaign_005.gd` amplía `kind=wing/vitamin` a `kind=mochi`, reutilizando la comparación exacta EV/estadísticas, PP/IV/naturaleza/experiencia, déficit de HP, consumos y SaveV2. El valor esperado de amistad es **0 para mochi**, `[3,2,1]` para pluma y `[5,3,2]` para vitamina. Mantiene pruebas 01–05. Las modalidades por escenario son `active` (PARTY con dos unidades), `none` (PARTY sin objeto) y `reserve` (STORAGE con dos unidades), incluidos rechazo atómico, identidad y recibos JSON SHA256.

**Python:** `tests/tools/test_parallel_items_w02_campaign_005.py` añade `EXPECTED_06` independiente de fixture, 32 casos exactos con fuentes, 16 mutaciones adversariales, verificaciones de los mapas nativos, envío por `FieldItemEffects` y antecedente Mochi V13. Conserva los cinco golden previos. Se han realizado **13 verificaciones estructurales** del acumulado: 24 IDs únicos, 164 escenarios sin duplicar, seis golden coincidentes y los contratos de fuente/runner presentes. Esto **no constituye ejecución Godot/Python**.

## Commits publicados

- Fixture: `tests/fixtures/parallel_items/w02_campaign_005.json` — `d8bba42bcf99f89a22b51d0ea22ee59ed333ae25`.
- Godot: `tests/gameplay/parallel_items_w02_campaign_005.gd` — `ab22963ab96d9bcef169788b60bb0493fcec2605`.
- Python: `tests/tools/test_parallel_items_w02_campaign_005.py` — `d66ef9c09a12f77d95db7e7995b93d4b28d25dd6`, `bb0fb83c6ed5b618d743a9811081a45dd0e2a00b`, `6fa7e167d2764c48b0988e0afa6d6ab1bbf5caf3`, `a41ac8303e1b92a1e11debd99328f3a82b95937a`, `3d582173bb0dde77c2ad0d31811631eb49c4fffc`, `628ba038521f4b7a3c2ea5d3470c9d6b75d7fbbc`.
- Progreso `docs/coordination/items_parallel_v1/reports/W02/CAMP_005_PROGRESO.csv` — `7a6610469ae891fd38897f3d83d72534e20c3aba`, fila 06 `EN_CI_AUTOMATICA`.

**Total publicado:** **6/10**, 24 IDs, 164 escenarios y **492 variantes preparadas**, sin afirmar que estén certificadas.

## Certificación y próximo bloque

**CI todavía pendiente:** el workflow dedicado debe comprobar `CAMP005_W02_PY/GODOT PASS blocks=6` (y en el hito 05 ejecutó o debía ejecutar las regresiones Python/Godot de CAMP004/CAMP003). No se dispone en este chat de logs de ejecución asociados al commit; `fetch_commit_workflow_runs` y status combinado del SHA 05 devolvieron listas vacías, que **no acreditan PASS ni FAIL**. Las ejecuciones reales y los artefactos deben verificarse antes de integrar. GPU/UI, integración en main/V28 y comparación de paridad externa de amistad Mochi siguen fuera de alcance.

**Siguiente `p`:** primero revisar logs CI y, si hay fallos W02, reparar bajo V5 sin rebajar pruebas. Después ejecutar **únicamente el bloque 07** `resist_mochi;genius_mochi;clever_mochi;swift_mochi`, como autoriza la cola. No avanzar a 08 sin otra `p`, ni tocar APIs compartidas sin coordinación IA6.
