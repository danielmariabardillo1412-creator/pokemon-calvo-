# IA2/W02 — CAMPAÑA_006 | BLOQUE 08/10: Macho Brace y Soothe Bell

Rama exclusiva: `codex/calvo-items-20261104-w02-camp006`. Puerta de entrada: [run 42232974438](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42232974438) `completed/success` en `2c727c47c057eeb4cebb02c51b33ebe873a8d55c`.

- `macho_brace`: `BattleEvRewards.award` ya duplica EV por enemigo. Se prueba ruta real desde `FieldItemService.equip`, combate `ProgressionSystem.reconcile_battle_result`, Magikarp (1→2 EV velocidad), XP inalterada, caps 252/510, guardado/carga SaveV2, propiedad PARTY/STORAGE y rechazo atómico sin stock.
- `soothe_bell`: `FieldFriendshipEffects.increase` ya añade multiplicador 1,5 a la amistad generada por `FieldTrainingEffects`. Se prueba equipar y consumir proteína real (+7 amistad desde 99, frente a +5 sin objeto), consumo de proteína y NO del cascabel, límite 255, desactivación si objeto consumido y SaveV2. No se afirma bonificación por caminar o por subir de nivel: esas rutas no están acreditadas.
- Se reutilizan los 288 escenarios históricos de CAMP005 y las regresiones previas; sin cambios a producción.
- Fixture: `tests/fixtures/parallel_items/w02_campaign_006_block08.json`. Runner Godot: `tests/gameplay/parallel_items_w02_campaign_006_block08.gd`. Validador Python: `tests/tools/test_parallel_items_w02_campaign_006_block08.py`.

**Estado de publicación:** pendiente de CI propia y regresiones. No declarar PASS funcional por haber publicado pruebas. `exp_share` continúa dependencia IA6; mentas de bloques 02/03 siguen L1. Tras CI exitosa, siguiente fila: 09 `ability_capsule;ability_patch;gentle_mint`. No modificar `main`, V28, rama árbitra ni ramas ajenas.
