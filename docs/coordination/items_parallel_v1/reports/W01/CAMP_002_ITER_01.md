# IA1/W01 — CAMPAÑA_002 · ITER_01 — Triaje y matriz de paridad

**Estado:** PREPARADO_PENDIENTE_CI. **Rama nueva exclusiva:** `codex/calvo-items-20261102-w01-camp002`.
**Base inicial verificada:** `67959eb8f19abfd2ae391872747a14f603fcab01`. **Gate IA6:** `CAMPAIGN_GATE_002.md` blob `ebc787803599e2b13cbd24c169b69112d18f7a42`; encargo `CAMP_002_W01.md` blob `6ef97f3c0569c96138cb8c322069384e124e5c79`.
**IDs únicos autorizados:** `ability_shield`, `absorb_bulb`, `adrenaline_orb`. Los tres están seleccionados, pero la selección NO demuestra el efecto.

## Hallazgos del código nativo existente
- `ability_shield`: `abilityshield/onSetAbility`; `held_effect_sweep_v3.cjs` demuestra escenario histórico `ability_suppression`, `gastro_acid` contra `synchronize`. Proyectado: protección sin consumo y control sin supresión.
- `absorb_bulb`: `absorbbulb/onDamagingHit`; `held_effect_sweep_v2.cjs` incluye `water_gun` y `boosts.spa == 1` con consumo. Controles: ataque no Agua y movimiento de estado.
- `adrenaline_orb`: `adrenalineorb/onAfterBoost`; `held_effect_sweep_v3.cjs` incluye `intimidate_trigger` (+1 velocidad y consumo) y `no_intimidate` (conserva objeto).
- **Dictamen:** `YA_EXISTE_TEST_NATIVO_HISTORICO_REVALIDAR_PARIDAD_GODOT`. Ningún cambio al simulador, catálogo, mochila ni producción.

## Entrega específica de ITER_01
- `tests/fixtures/parallel_items/w01_campaign_002.json`: siete escenarios (2+3+2), 10 combinaciones caso-semilla (19/23 según escenario), 30 variantes `active/none/reserve`; activación, consumo y efecto esperados descritos **como expectativa, no medición**.
- `tests/tools/test_parallel_items_w01_campaign_002.py`: Python de contrato estricto que compara cuatro blobs Git de referencias reales, hooks y selección, matriz/semillas, y seis mutaciones deliberadas negativas (`--self-test`). No ejecuta Godot ni informa PASS de combate.
- **Commits de pruebas:** fixture `16cd0d253c17d454e578cced864948e30b69e023`; validador `c2451f93a839c9e6e9b6058e3765da0a68f400b3`.
- **Auditoría estática realizada:** 16/16 invariantes PASS por lectura de GitHub y comparación de SHA (fuentes históricas, límites de ID, matriz positiva/negativa, portador/reserva, semillas, rutas y garantías del validador).
- **Python nuevo SIN_EJECUTAR; Godot 4.7 nuevo SIN_EJECUTAR; visual/GPU SIN_EJECUTAR.** CI base de IA6 #41364601482/#41364601486 es anterior a estos archivos y no los valida.

## Ejecución diferida y siguiente paso
- Reproducible en checkout de la nueva rama: `python -B tests/tools/test_parallel_items_w01_campaign_002.py --contracts` y `python -B tests/tools/test_parallel_items_w01_campaign_002.py --self-test`.
- **ITER_02 aún no ejecutada:** runner Godot autorizado `tests/gameplay/parallel_items_w01_campaign_002.gd`; contrastar realmente con `@pkmn/sim@0.10.11`, segundo seed y SaveV2/propiedad de reserva. IA6 gestiona CI por paquete.
- Si la integración exige cambiar producción o hay FAIL funcional, STOP y notificar a IA6. No reutilizar/editar archivos CAMP_001, ramas anteriores, W04, `main` ni V28.
