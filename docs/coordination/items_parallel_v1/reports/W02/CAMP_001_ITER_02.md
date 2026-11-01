# W02 — CAMPAÑA_001 ITER_02 / 3

**Estado:** PREPARADO_PENDIENTE_CI. Identidad IA2/W02. Rama exclusiva `codex/calvo-items-20261101-w02`.
**Orden:** `campaigns/CAMP_001_W02.md` blob `f6f8f08b13f9e4f84d18970643ebd4aeab5a75b7`; puerta `CAMPAIGN_GATE_001.md` ACTIVADA.
**Base:** árbitra `1b52fdd0b7b89e468811a17ad83a917ec7107735` es antecesor de nuestra rama. No rebase ni force.
**CI anterior:** run #41341842320 PASS para código anterior, no prueba esta iteración.

## Casos nuevos (8, más los 8 inmutables de ITER_01)
- `persim_confuse_ray`: Gengar provoca confusión; solo el titular equipado debe consumir y curarse. Controles sin objeto/en reserva mantienen confusión.
- `persim_no_confusion`: no se provoca confusión, no debe gastarse Persim.
- `chesto_spore`: Gengar usa Spore, Chesto elimina el sueño. Campo con sueño inicial.
- `chesto_burn` y `chesto_healthy`: rechazo de cura improcedente.
- `rawst_burn`: cura quemadura y gasta una unidad; comparar PS tras daño residual.
- `rawst_poison` y `rawst_healthy`: no consumen ni curan veneno.
- **Hueco de campo:** `persim_berry` no tiene perfil en `imported_recovery_v19.json`; se espera rechazo atómico incluso ante confusión. NO se programó un efecto nuevo.

## Entrega y pruebas
- Fixture `tests/fixtures/parallel_items/w02_campaign_001.json`: 16 filas; blob `a482aae62a14363463cbfc9e388b4e6c8a971556`; commit `19b6e0be842992d0317b84e9bb5d7569a077cf75`.
- Godot `tests/gameplay/parallel_items_w02_campaign_001.gd`: proyecta confusión volátil, propietario, uso campo, estado y SaveV2; blob `ebdf39d994c1762b3f59c235364684fbb5d54cde`; commit `816c6c211fceba3f73864919de04e0d797d64c9f`.
- Python `tests/tools/test_parallel_items_w02_campaign_001.py`: valida casos, raw SHA256 y 15 tests adversariales; blob `ff39182a725766477763322403afb516155a6e1b`; commit `55bdbbbaa3168a89c438541004fb30aba900a336`.
- Cobertura nueva prevista: 8 casos × 3 variantes equipadas y 2 de campo = 24 + 16; acumulada 16 × 5 = 80. No son casos ejecutados.
- **PASS ESTÁTICO REAL: 20/20 comprobaciones de integridad por GitHub.** Python y Godot **SIN_EJECUTAR** para esta iteración; sin prueba visual/GPU.
- Reproducir: `python tests/tools/test_parallel_items_w02_campaign_001.py --unittest`, `godot --headless --path . --script res://tests/gameplay/parallel_items_w02_campaign_001.gd`, después Python con `--result .godot/parallel_items/w02_campaign_001/godot.json`.
- Ningún archivo de producción, política, workflow, rama ajena, informe antiguo ni prueba W02 antigua alterado.
- Siguiente microbloque al recibir `p`: ITER_03, regresión y matriz de seis IDs; parar ante error y publicar cierre después.
