# W02 / CAMPAÑA_002 — ITER_02: Zanama (Leppa) e Higog (Figy)

**Estado de ITER_02:** `PREPARADO_PENDIENTE_CI` (02/03). **Sin PASS funcional para los casos nuevos.** Rama exclusiva `codex/calvo-items-20261102-w02-camp002`.
**Orden IA6:** `CAMPAIGN_002_ITER01_CI_GATE.md` blob `12e9c3021e80f9e03e0f9b0e900853b9a7e6a513` y `campaigns/CAMP_002_W02.md` blob `8e52a9f9e740eaee6210494ffaa764ce1ad9c644`.
**CI de ITER_01 verificada:** [Actions #41484879741](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41484879741), staging `967002fcbf26a1159d3a14a020e8921b34cfab8f`: Sitrus/Lum **350 checks Godot, 4 casos, 13 Python tests PASS** y verificador de recibos. **No cubre Leppa/Figy.**
**Corrección IA6 obligatoria sincronizada:** runner `tests/gameplay/parallel_items_w02_campaign_002.gd` blob `2e0ac1d2142dad96f110254e7eb4f2a3c5f04c47` reproducido exactamente desde árbitra en W02, commit `3fba13ac0b17d5e01b082ab498450465d3eef8d5`; evita comparación JSON `[1.0] != [1]` sin eliminar controles.

## Triaje acreditado y casos añadidos
- `leppa_berry` (Zanama): `tools/item_audit/held_effect_sweep_v3.cjs` contiene `empty_pp` (primer movimiento 0 PP → +10 PP cuando se utiliza el segundo) y `nonempty_pp` (primer movimiento 1 PP → no consume). Usamos `tackle`/`reflect`, comando `move 2`. Perfil de campo sí existente: `imported_recovery_v19.json` restaura 10 PP, `scope=one`; **no se ensaya campo**.
- `figy_berry` (Higog): `tools/item_audit/held_pilot.cjs` tiene caso `mew_modest` a PS bajos que cura `floor(max_hp/3)`, gasta la baya y provoca confusión. Naturaleza **modest** baja Ataque y rechaza picante; `hardy` actúa como control neutro. `data/api/v2/item/136/index.json` confirma rechazo del sabor por naturaleza que disminuye Ataque (su texto histórico de 1/8 HP no prevalece sobre prueba del simulador moderno). Figy no aparece en `imported_recovery_v19.json`: ausencia en campo documentada, **sin modificación de producción**.
- Nuevos 5 casos: `leppa_zero_pp_c002`, `leppa_one_pp_c002`, `figy_modest_low_c002`, `figy_hardy_low_c002`, `figy_modest_high_c002` (superior a umbral, no consume). Tres modos cada caso, 15 nuevas variantes; junto a 4 de ITER_01: **9 escenarios, 27 variantes nativas previstas**.
- Comprobaciones: portador activo/sin objeto/reserva, solo un consumo físico, PP del primer slot sin tocar el segundo, PS y naturaleza tras SaveV2, confusión obtenida del **log del motor nativo** (no del espejo que omite volátiles), hash SHA256 de evidencia por variante y cierre FLED.

## Evidencia y límites
- Fixture exclusivo `tests/fixtures/parallel_items/w02_campaign_002.json`, blob `fbce41f9bbda5f920bd0d9135fc3eefe2eeb49dc`, commit `ac3f49f53b26a67924605210c5e948ee63972f7b`.
- Runner exclusivo `tests/gameplay/parallel_items_w02_campaign_002.gd`, blob `540d93c0f29a027dca8f9b94254e7c008366a0b4`, commit `fbc45d9327b7842f9dbf2c6a3f4092f0651cd016`.
- Validador exclusivo `tests/tools/test_parallel_items_w02_campaign_002.py`, blob `77e5016003eca3a7bfce63261aba265dfda7abdc`, commit `52640aca09e5f187baa1671d832ba1a112917b96`; 17 tests unitarios definidos.
- **Revisión estática REAL:** 31/31 comprobaciones leyendo blobs GitHub: preservación de 4 casos antiguos, 5 nuevos, contratos exactos, 4 IDs, corrección IA6, control PP/naturaleza/consumo, cobertura, ausencia de falsas certificaciones.
- **SIN_EJECUTAR en ITER_02:** 17 tests Python, Godot 4.7, postvalidador, visual/GPU. El PASS de ITER_01 no es un PASS de estos 5 casos. La CI de IA6 es la siguiente puerta.
- Comandos IA6: `python tests/tools/test_parallel_items_w02_campaign_002.py --unittest`; `godot --headless --path . --script res://tests/gameplay/parallel_items_w02_campaign_002.gd`; `python tests/tools/test_parallel_items_w02_campaign_002.py --result .godot/parallel_items/w02_campaign_002/godot.json`.
- **Permisos:** 3 tests exclusivos, docs W02 y nada más. `main`, V28, PR #118, CAMPAÑA_001, otras ramas, W04 congelada, producción, simulador, guardados y workflow intactos.
- **Siguiente `p`:** ITER_03 (matriz de cuatro y regresión), solo si IA6 no registra FAIL/STOP; no anticipar cierre 03.
