# IA5/W05 — CAMPAÑA_003 · ITER_07/10 — MT Scarlet/Violet

**Estado al publicar: EN_CI_AUTOMATICA.** No se declara PASS funcional de las seis MT nuevas sin la CI de esta iteración.

## Alcance autorizado
- Rama exclusiva: `codex/calvo-items-20261103-w05-camp003`.
- Autoridad: `CAMPAIGN_GATE_003.md`, `CAMPAIGN_003_QUEUE_APPROVED.csv`, `campaigns/CAMP_003_W05.md` de IA6.
- Bloque `07` de `W05`, **seis IDs exactos**:

| MT | Movimiento activo Scarlet/Violet |
| --- | --- |
| `tm57` | `false_swipe` |
| `tm58` | `brick_break` |
| `tm59` | `zen_headbutt` |
| `tm60` | `u_turn` |
| `tm61` | `shadow_claw` |
| `tm62` | `foul_play` |

Se verificó cada relación directamente en `modules/inventory/item_connections_v1.json`, sin reutilizar correspondencias de generaciones anteriores ni suponer especies compatibles.

## Cambios en la rama propia
1. **Fixture:** se añadió exclusivamente `block: 07` con las seis MT a `tests/fixtures/parallel_items/w05_campaign_003.json`, preservando bloques 01–06. Commit `05bb0662f3a4089146d1968bf651e3280f9dac11`.
2. **Progreso:** una fila `07`, `EN_CI_AUTOMATICA` en `docs/coordination/items_parallel_v1/reports/W05/CAMP_003_PROGRESO.csv`. Commit `fc41a3e6cd53ee85cfccd08ca6da3a3fac2521e0`; activa ejecución del workflow inmutable.
3. Tests acumulativos W05 existentes `tests/tools/test_parallel_items_w05_campaign_003.py` y `tests/gameplay/parallel_items_w05_campaign_003.gd`, **sin modificaciones y sin duplicar la implementación de enseñar**. El protocolo requiere `blocks=7`, **42 casos**, con pareja aprendible real `machine/scarlet-violet`, PP, consumo, incompatibilidad, negativas por falta de stock/propietario/repetición y SaveV2.
4. Cotejo estático con repositorio real: **7 bloques, 42 IDs distintos, cero discrepancias** entre fixture, CSV de progreso, cola IA6 y correspondencia SV del perfil. Esto no equivale al PASS funcional del bloque 07.

## CI verificable
- **Bloques 01–06 verificados:** [#41559866278](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559866278), SHA `920a647db1bfa5f5ad9f34c13bab5d6b2fa48143`, `completed/success`, recibos Python `CAMP003_W05_PY PASS blocks=6 checks=348` y Godot 4.7 `CAMP003_W05_GODOT PASS blocks=6 checks=1306`, comprobados en logs de job.
- **Bloque 07:** seguimiento del workflow `.github/workflows/parallel-camp003-worker-autoci.yml` en esta rama para el SHA del progreso `fc41a3e6cd53ee85cfccd08ca6da3a3fac2521e0`. Sólo confirmar PASS cuando los logs de su ejecución incluyan `CAMP003_W05_PY PASS blocks=7` y `CAMP003_W05_GODOT PASS blocks=7` y el job complete `success`. La ejecución del commit de fixture puede aparecer cancelada por `concurrency.cancel-in-progress`.

## Siguiente «p»
Comprobar **primero** último run del SHA `fc41a3e6...`. Si `success`, ejecutar exclusivamente **bloque 08** `tm63;tm64;tm65;tm66;tm67;tm68`. Si sigue `queued/in_progress`, gate permite un único bloque independiente de tests sin PASS. Si hay `failure`, corregir sólo tests propios sin rebajar aserciones o STOP y solicitar IA6 ante problema funcional compartido.

**Intocables:** `main`, V28, PR118, ramas ajenas, árbitra, `modules/`, `data/`, `config/`, catálogo canónico, workflow y test de manifiesto, guardados reales, 19 MT legacy, arte/GPU/UI.

**BLOQUE 07/10 ENTREGADO. CI PROPIA TODAVÍA NO CERTIFICADA.**
