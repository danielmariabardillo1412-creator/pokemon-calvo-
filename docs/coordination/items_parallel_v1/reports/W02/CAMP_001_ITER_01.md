# W02 / CAMPAÑA_001 — ITER_01 (Aranja, Meloc, Zreza)

**Estado:** `PREPARADO_PENDIENTE_CI` — microbloque **01/03** entregado. **No hay PASS Godot nuevo** para los 3 IDs.
**Identidad:** IA2/W02, rama exclusiva `codex/calvo-items-20261101-w02`.
**Encargo oficial:** `campaigns/CAMP_001_W02.md` en árbitra, blob `f6f8f08b13f9e4f84d18970643ebd4aeab5a75b7`.
**Puerta:** `CAMPAIGN_GATE_001.md` ACTIVADA, blob `3ef0b39f7eb74f3ebcb688f279c254daec981f8e`; sincronización de rama mediante fast-forward seguro a HEAD árbitra `1b52fdd0b7b89e468811a17ad83a917ec7107735`.
**PASS anterior NO atribuible a este microbloque:** Actions [#41341842320](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41341842320), SHA probado `ac34fabbe1a27e69614f0239abee21c29d6fe65e`; en W02 validó 7 casos antiguos/21 variantes/503 checks (Zidra, Ziuela, Dillo). No ejecutó Aranja/Meloc/Zreza.

**IDs exactos:** `oran_berry` (Aranja), `pecha_berry` (Meloc), `cheri_berry` (Zreza).
**Previo reutilizado:** `tools/item_audit/held_pilot.cjs` prueba nativa Oran (2 seeds), `tools/item_audit/held_effect_sweep_v2.cjs` prueba casos básicos de bayas de estado, `tests/gameplay/item_field_recovery_v5.gd` valida campo (PARTY/STORAGE, efecto, cura específica y negativos). **Son PASS históricos; no reejecutados.**
**Nuevo alcance de test:** 8 contratos = Oran PS bajos/llenos (2), Meloc envenenado/quemado/sano (3), Zreza paralizado/envenenado/sano (3). Cada contrato tiene 3 variantes combate (activo/sin objeto/reserva) y 2 ubicaciones campo (equipo/caja): **24 variantes nativas + 16 usos en campo previstos**, NO ejecutados.
**Flujo probado por diseño, pendiente ejecución:** `PlayerCollection` → `FieldItemService.equip` y `use_item` → `showdown_adventure_session` controlado con `@pkmn/sim@0.10.11` → `SaveGameRepository`/SaveV2 → stock físico y portador. Usar 2 bayas de entrada; gasto exactamente de una cuando aplica; segundo cierre FLED no duplica gasto; control negativo no gasta.
**Rutas exclusivas creadas:**
- `tests/fixtures/parallel_items/w02_campaign_001.json` blob `6a72c1cb043b82cfa79c0a415f3ecfc6668e80e7`: matriz declarativa; fase `[1]`.
- `tests/gameplay/parallel_items_w02_campaign_001.gd` blob `40a9266e2b633ca9cddd9b49766c739acc0c9d69`: ejecución nativa + campo + persistencia, sin callbacks.
- `tests/tools/test_parallel_items_w02_campaign_001.py` blob `30babaf9b3a5d7e042f69a2523868b7b52992f02`: aserciones independientes, raw SHA-256 y 12 tests unitarios sintéticos/negativos.
**Commits código:** `3bde944a072a3e4b64bed4150216e37c20a0ed1f`, `545f3a618d2b8f56799fe3b19c56f52318e9822c`, `e6873734830914fdc50fb715b5204ef2814fd677`.
**PASS REAL ESTÁTICO:** 15/15 inspecciones independientes de GitHub: IDs, casos, modos, dueños, negativos, importación del motor original, persistencia, SHA-256, tests del validador y conservación exacta de LOTE_001/002.
**SIN_EJECUTAR:** `python ... --unittest`, Godot 4.7, postvalidador con recibos `.godot/parallel_items/w02_campaign_001/godot.json`; no se modificó un workflow ni se lanzó CI independiente. No hay cobertura visual/GPU.
**Comandos reproducibles desde checkout preparado:**
```sh
python tests/tools/test_parallel_items_w02_campaign_001.py --fixture-only
python tests/tools/test_parallel_items_w02_campaign_001.py --unittest
godot --headless --path . --script res://tests/gameplay/parallel_items_w02_campaign_001.gd
python tests/tools/test_parallel_items_w02_campaign_001.py --result .godot/parallel_items/w02_campaign_001/godot.json
```
**Límites:** no certifica combate dobles, todos los estados, relleno de PS contra impactos, visual, ni resultado de producción tras nuevos cambios. Contratos de combate/campo pueden fallar al ejecutar; no declarar PASS hasta ver logs/exit codes y hashes.
**Permisos:** ningún archivo de producción, datos canónicos, `main`, V28 original, árbitra, otras ramas, CI compartida, o pruebas W02 antiguas modificados.
**Próximo microbloque:** **02**, Persim/Chesto/Rawst (confusión, sueño, quemadura). Ejecutar **solo tras recibir siguiente `p` y verificar que IA6 no publicó STOP**. Si hay FAIL de la fase 01, detener y pedir intervención; no falsear fixtures.
