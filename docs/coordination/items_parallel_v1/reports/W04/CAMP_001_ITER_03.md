# IA4/W04 — CAMPAÑA_001 — ITER_03 (SaveV2)

**Estado: PREPARADO_PENDIENTE_CI.** Único bloque ejecutado tras relevo del 2026-11-02; 01/02 intactos.

- Autoridad: `CAMPAIGN_HANDOFF_GATE_20261102.md`, rama árbitra; rama única W04.
- Scripts propios modificados: `tests/gameplay/parallel_items_w04_campaign_001.gd` (commit `028e0a8b5ce0bdc7b25e1629da1104a1b55b9919`) y `tests/tools/test_parallel_items_w04_campaign_001.py` (commit `e57b924f8b6cc547e7158b2f87cd626a7cf585d3`).
- Alcance: seis piedras autorizadas, cada una sobre especie elegible y tanto equipo como PC (**12 pruebas SaveV2**), sin alterar los casos 01/02.
- Flujo: stock 2; rechazos de criatura ajena y destino inválido con snapshot íntegro; evolución de destino descubierto en catálogo; stock 1; rechazo de segundo intento; guardado `SaveGameRepository.save_collection`; carga `load`; comprobación de V2, identidad, especie, IV/EV, movimientos, experiencia, amistad, ubicación, inventario y rechazo sin gasto tras cargar.
- Archivos de guardado de test: `user://w04_camp001_iter03_<piedra>_<party|pc>.json`; eliminación al acabar cada caso; **no son guardados reales del usuario**.
- Validador Python exige las 12 combinaciones y 12 resultados positivos de SaveV2, sin transformar una mera prueba estática en prueba funcional.
- **Ejecución de Python checkout:** SIN_EJECUTAR; **Godot 4.7 sobre nuevo HEAD:** SIN_EJECUTAR. Los 313 checks de IA6 corresponden a bloques anteriores en staging #41350981613, no a ITER_03.
- Comandos para IA6, tras importar Godot: `python -B tests/tools/test_parallel_items_w04_campaign_001.py`; `godot --headless --path . --import`; `python -B tests/tools/test_parallel_items_w04_campaign_001.py --godot godot`.
- Riesgos pendientes de runner: compatibilidad de SaveV2, serialización exacta de snapshots, parseo de GDScript y códigos de retorno. Si alguno falla, registrar evidencia y no tocar producción.
- Sin cambios en `main`, V28, ramas ajenas, producción, workflows, datos o partidas existentes.

**Siguiente propietario del gate funcional:** IA6. **W04 detenida al completar 03/03.**
