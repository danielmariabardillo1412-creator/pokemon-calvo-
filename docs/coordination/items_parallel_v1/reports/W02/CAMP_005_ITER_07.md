# IA2/W02 — CAMPAÑA_005 · MICRO BLOQUE 07/10

**Autoridad:** IA6, `CAMPAIGN_005_W02_GATE.md`, `CAMPAIGN_005_W02_QUEUE_APPROVED.csv` fila 07, `campaigns/CAMP_005_W02.md` y `AUTONOMOUS_REPAIR_V5.md`. **Rama exclusiva:** `codex/calvo-items-20261103-w02-camp005`. Esta orden `p` ejecuta **sólo la fila 07**, sin tocar `main`, V28, PR118, ramas ajenas, workflows ni producción.

## 4 mochis, 32 escenarios nuevos, 96 variantes programadas

| ID | Contrato de entrenamiento real | Casos por objeto |
|---|---|---|
| `resist_mochi` | Hasta **+10 EV Defensa** | 8 |
| `genius_mochi` | Hasta **+10 EV Ataque Especial** | 8 |
| `clever_mochi` | Hasta **+10 EV Defensa Especial** | 8 |
| `swift_mochi` | Hasta **+10 EV Velocidad** | 8 |

Cada mochi cuenta con los casos: 0 EV (+10); estadística 248 (+4 hasta 252); estadística 252 (rechazo); total de otros EV 508 (+2 hasta 510); total 510 (rechazo); ranura inesperada (rechazo); amistad 254 (permanece intacta); total otros EV 509 (+1). Todos se aplican, cuando procede, con **consumo de una sola unidad**; los rechazos deben conservar criatura e inventario sin cambios.

**Fuente funcional observada:** `modules/inventory/field_mochi_effects.gd` registra la tabla exacta de cuatro destinos y `gain = min(10, 252-EV_stat, 510-EV_total)`. Mochi V13 **no incrementa amistad**, aunque otras referencias presentan una regla distinta: `docs/current/ITEM_MOCHI_V13.md` deja esa discrepancia explícita. No se inventan flags de amistad o paridad oficial. `modules/inventory/field_item_effects.gd` despacha al ejecutor `Mochi.apply`; `FieldItemService` posee inventario, transacciones y sustitución por identidad.

**Godot:** `tests/gameplay/parallel_items_w02_campaign_005.gd` ya soportaba `kind=mochi` desde el bloque 06 y ahora añade un **oráculo independiente** `MOCHI_STATS_005` para las seis especies de mochi de mejora, incluido el bloque 07. Compara el destino declarado y el aumento esperado con límites `ProgressionRuleset.EV_PER_STAT_MAX`/`EV_TOTAL_MAX`, contrastando la transición real de `FieldItemService.use_item`. Mantiene los tres modos por escenario `active` (PARTY con 2 objetos), `none` (PARTY sin objeto) y `reserve` (STORAGE con 2 objetos), rechazo atómico, EV y estadísticas derivadas, déficit de HP, amistad, naturaleza, IV, PP, nivel, identidad, consumos, SaveV2 y recibos JSON SHA256.

**Python:** `tests/tools/test_parallel_items_w02_campaign_005.py` incorpora `EXPECTED_07` de 32 escenarios exactos, comprueba fila oficial, fuente, valores y mapa de mochis, y añade **16 mutaciones adversariales** del bloque 07. Los golden anteriores 01–06 siguen intactos; se verificó estructuralmente que los siete golden coinciden con las siete fixtures, con 28 IDs distintos y 196 nombres de escenario únicos. Esto no equivale a ejecutar el runner.

## Commits y archivos propios publicados

- Fixture `tests/fixtures/parallel_items/w02_campaign_005.json`: `3ef494afaa0ae37e8adb90f12385bd4a27905bb7`.
- Godot `tests/gameplay/parallel_items_w02_campaign_005.gd`: `6cbc6211ab876a00b6be3c5c2d730879d6f2ff04`.
- Python `tests/tools/test_parallel_items_w02_campaign_005.py`: `04ab6baeb92dce7cbeb04af214d7a6c2000f9f4c`, `a83f601f7ac44c99bed9cec69c5e6eeb2ee1695c`, `44413f741a9dd963d53589e7b8bd89f57b4cfb76`, `7a60642ab83d500c78a60c3f0e976501d838ac54`.
- Progreso `docs/coordination/items_parallel_v1/reports/W02/CAMP_005_PROGRESO.csv`: `981b7f4a6e60db6777a8b98e298be2fcc02458e8`, fila 07 `EN_CI_AUTOMATICA`, nunca marcada `PASS` sin recibo.

**Total CAMP005 publicado:** **7/10 bloques, 28 objetos, 196 escenarios, 588 variantes previstas**.

## Límite de certificación y traspaso

**CI real aún por verificar:** la consulta de `fetch_commit_workflow_runs` y status combinado para el SHA de cierre del bloque 06 devolvió listas vacías. El workflow de IA6 se desencadena por cambios en fixture, Python, Godot y progreso, pero una lista vacía no acredita si se ejecutó, falló o pasó. No se han recuperado recibos verificables `CAMP005_W02_PY/GODOT PASS blocks=7`, ni los cuatro recibos de regresión CAMP004/CAMP003 (hito 05). La revisión estática de fuentes y casos **no certifica integración funcional**, GPU/UI ni pruebas de campo.

**Siguiente orden `p`:** revisar estado y logs de CI actuales, corregir errores propios conforme V5 sin relajar contratos y ejecutar **solamente el bloque 08** autorizado: `fresh_start_mochi;adamant_mint;modest_mint;jolly_mint`. El Mochi Reinicio y las mentas requieren contratos de efecto distintos y no pueden recibir el mismo oráculo de mochi +10 EV. No adelantar 09.
