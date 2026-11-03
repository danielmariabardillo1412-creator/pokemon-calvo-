# IA2/W02 — CAMPAÑA_003 / BLOQUE 04/10

**Estado de entrega:** `EN_CI_AUTOMATICA` hasta verificar el resultado del último SHA de pruebas/progreso. Se ha entregado **exactamente el bloque 04**, sin iniciar 05.

**Rama exclusiva:** `codex/calvo-items-20261103-w02-camp003`. Fuente autorizada: `CAMPAIGN_003_QUEUE_APPROVED.csv` blob `ea06a0a000fc4f3b8bab48e45e21fb549d753559`, encargo `campaigns/CAMP_003_W02.md` blob `62498ebd44288a86e59986379dbc1b70e111ef1f`.

## Nueve escenarios nuevos; cuatro bayas exactas

| Baya | Control positivo | Control negativo | Contrato histórico |
|---|---|---|---|
| `haban_berry` | Dragonite ante `dragon_pulse` supereficaz: menor daño y consume | `tackle` Normal, sin reducción ni consumo | `held_effect_sweep_v2.cjs` (resistencia Dragón) |
| `iapapa_berry` | Mew con 1/5 PS, naturaleza `lonely` rechaza sabor: cura 1/3 y confunde; `hardy` cura sin confusión | PS altos con `lonely`, sin cura/consumo/confusión | `held_effect_sweep_v3.cjs` (perfiles de sabor) |
| `jaboca_berry` | `tackle` físico al portador: devuelve `floor(maxHP del rival/8)` y consume | `confusion` especial: no devuelve PS ni consume | `held_effect_sweep_v3.cjs` (`category_retaliation`) |
| `kasib_berry` | Mew ante `shadow_ball` Fantasma supereficaz: menor daño y consume | `tackle` Normal: conserva baya, daño idéntico | `held_effect_sweep_v2.cjs` (resistencia Fantasma) |

**Integración real prevista:** portador `active`, testigo `none` y objeto `reserve`; motor nativo `@pkmn/sim` con revisión de transacción, guardado/restore del checkpoint, `SaveGameRepository.decode_snapshot` SaveV2, `FLED` y prueba de no doble consumo. El efecto de Jaboca **no se infiere de consumo**: se contrastan PS y PS máximos de `foe` recogidos del estado de batalla, incluyendo su restauración. Se conserva filtro de `p1a` para los boosts y naturaleza `lonely` con recálculo de stats.

**Cobertura total acumulada:** bloques 01–04: 9 + 8 + 8 + 9 = **34 escenarios** de 16 bayas y **102 variantes nativas** de propiedad. Las 25 escenas anteriores permanecen en fixture/runner/validador.

**Pruebas adversariales Python:** nuevo contrato completo `EXPECTED_04`; diez mutaciones que deben ser rechazadas (ataque, consumo, naturaleza, rechazo, umbral, daño de Jaboca 1/8 frente a 1/4, tipo especial/físico, ataque Fantasma, caso omitido, ID no autorizado). Referencias de herramientas de auditoría V2/V3 verificadas por texto.

**Commits en la rama W02:**
- Fixture `tests/fixtures/parallel_items/w02_campaign_003.json` commit `35e019737ff554ee784870df113ffd7a100be78d`.
- Runner `tests/gameplay/parallel_items_w02_campaign_003.gd` commit `8e4b99d66025b43cb5cdbcb641465adf64e9d374`.
- Contratos `tests/tools/test_parallel_items_w02_campaign_003.py` commit `d4af169883004f0929371738b66b2eb48585f8fb`.
- CSV de progreso `reports/W02/CAMP_003_PROGRESO.csv` commit `1e1e71d9c29bf00e764f5fe6039a8648feed1f46`.

**CI anterior confirmada:** [Actions #41556875512](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556875512), `completed/success`, SHA `44482761ab0217323335d9a1bc63f060cbcad513`: `CAMP003_W02_PY PASS blocks=3 checks=187` y `CAMP003_W02_GODOT PASS blocks=3 checks=2071`. **No certifica nuevas cuatro bayas**.

**CI actual del bloque 04:** [Actions #41558465659](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41558465659), SHA de pruebas/progreso `1e1e71d9c29bf00e764f5fe6039a8648feed1f46`, pendiente al redactar. Exige recibos `CAMP003_W02_PY PASS blocks=4 checks=M` y `CAMP003_W02_GODOT PASS blocks=4 checks=M`. Los runs anteriores cancelados por `concurrency.cancel-in-progress` no equivalen a un FAIL.

**Limitaciones y reglas:** solo bayas equipadas; no activar campo, no alterar catálogo, motor/SaveV2, archivos compartidos, workflows, `main`, V28, ramas ajenas, W04 ni PR #118. Sin visual/GPU ni extrapolación a todos los formatos. Si falla el runner propio, diagnosticar y reparar sin rebajar expectativas; fallo de motor compartido exige STOP y aviso IA6.

**Siguiente `p`:** únicamente bloque 05 `kebia_berry;kee_berry;lansat_berry;liechi_berry`, previa consulta de CI y autorización de cola. No anticipar ese bloque en esta entrega.
