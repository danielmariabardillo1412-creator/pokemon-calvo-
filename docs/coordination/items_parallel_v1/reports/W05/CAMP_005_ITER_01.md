> **CERTIFICACIÓN FUNCIONAL DEFINITIVA — BLOQUE 01/10 · CI PASS (2026-11-03):** [GitHub Actions #41715365400](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41715365400), SHA `c18760b7df5978a4bdcbb6395f2bcd85c113b7fb`, job `126193834698`, `completed/success`. Se leyeron recibos reales: `CAMP005_W05_MANIFEST_PASS reserved=10 completed=1 ids=60 kind=NEW_IDS`; `CAMP005_W05_PY PASS blocks=1 checks=58`; `CAMP005_GATE_PY_PASS worker=W05 blocks=1 checks=58`; `CAMP005_W05_GODOT PASS blocks=1 checks=231`; `CAMP005_GATE_GODOT_PASS worker=W05 blocks=1 checks=231`. **Las seis nuevas MT tienen cobertura funcional PASS en Godot headless y catálogo Python; no se atribuye certificación visual/GPU.** Regresiones CAMP004/003 no ejecutadas en bloque 01: están previstas explícitamente para hitos 05/10 y cambios de producción propios. Este párrafo prevalece sobre notas históricas inferiores de CI pendiente. No hubo parches en producción.

# IA5/W05 — CAMPAÑA_005 · BLOQUE 01/10 · MT142–147

**Estado inicial al publicar:** EN_CI_AUTOMATICA (no confundir bootstrap 0/10 con PASS funcional).

## Autorización y contrato
- Rama exclusiva `codex/calvo-items-20261103-w05-camp005`; fuente IA6 `CAMPAIGN_005_W05_GATE.md`, `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W05.md`, `AUTONOMOUS_REPAIR_V5.md` en rama árbitra.
- Fila autorizada 01: `tm142;tm143;tm144;tm145;tm146;tm147` con movimientos activos de `modules/inventory/item_connections_v1.json`:

| MT | Movimiento SV |
| --- | --- |
| `tm142` | `hydro_pump` |
| `tm143` | `blizzard` |
| `tm144` | `fire_pledge` |
| `tm145` | `water_pledge` |
| `tm146` | `grass_pledge` |
| `tm147` | `wild_charge` |

## Cambios publicados
1. `tests/tools/test_parallel_items_w05_campaign_005.py`, commit `1a7832904a18d2adb0c57130999a3ae5dcfcef35`. Hereda las validaciones verificadas de CAMP004 y se adapta a cola/fixture CAMP005. Prueba identidad, versión, unicidad, exclusión de MT históricas, metadatos de movimiento, PP positivo, política y al menos una especie con learnset de máquina SV real. No afirma que el cotejo estático equivalga a enseñar en el motor.
2. `tests/gameplay/parallel_items_w05_campaign_005.gd`, commit `da5b10d32a8478db725d03bb438d8eb84d5d3524`. Prueba el `FieldItemService.teach` real con especie compatible e incompatible derivadas del catálogo, existencia/propiedad, rechazo de falta de stock, consumo exacto de una MT, PP, rechazo de enseñanza repetida, identidad de instancia y SaveV2 (escritura, lectura, equipo e inventario). Reutiliza arquitectura y contratos ya demostrados en CAMP004, sin crear servicios paralelos.
3. `tests/fixtures/parallel_items/w05_campaign_005.json`: añadido solo bloque 01, commit `095942fcaf1de2b3cb2a07efc14ec5a85be6cafa`.
4. `reports/W05/CAMP_005_PROGRESO.csv`: única fila nueva 01, commit `c18760b7df5978a4bdcbb6395f2bcd85c113b7fb`, que dispara CI CAMP005.
5. Validación estática tras publicar: 1 bloque, 1 fila de progreso, 6 IDs únicos, asignación exacta de IA6 y los seis movimientos de versión SV del perfil; cero discrepancias. **Esto no equivale a PASS funcional.**

## CI, continuidad y reglas
- Workflow de IA6 `.github/workflows/parallel-camp005-w05-autoci.yml`: Godot 4.7 headless, Python CAMP005, Godot CAMP005, validación de manifiesto y recibos positivos. **CI bootstrap 0/10 `success` no es validación funcional**.
- Run funcional bloque 01: [GitHub Actions #41715365400](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41715365400), SHA `c18760b7df5978a4bdcbb6395f2bcd85c113b7fb`, inicialmente `in_progress`. Se exigirá `completed/success`, `CAMP005_W05_PY PASS blocks=1 checks=N`, `CAMP005_W05_GODOT PASS blocks=1 checks=N` y ambos gates antes de certificar seis enseñanzas.
- El gate exige regresiones completas CAMP004 (60 MT) y CAMP003 (60 MT) al menos en hitos 05/10 y cambios propios de producción; workflow las incorpora expresamente para dichos hitos. No alegar ejecución en bloque 01 si no se ejecutaron.
- No modificar `main`, V28, PR118, rama árbitra, otras W, catálogo, política, las 19 MT legacy inactivas ni workflows; sin merge. Solo reparación propia V5 con fallo reproducido y regresión.
- **Próxima `p`**: comprobar primero run 01, después ejecutar solamente bloque 02 `tm148`–`tm153`, nunca saltar bloques. Al 10/10 `CAMPAÑA_005_FINALIZADA` y STOP.
