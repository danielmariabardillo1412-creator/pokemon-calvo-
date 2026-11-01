# IA4/W04 — CAMPAÑA_001, microbloque 01

**Estado:** PREPARADO_PENDIENTE_CI. **Fecha:** 2026-11-01. Solo piedras clásicas; 02/03 aún no iniciados.

- Autoridad: `campaigns/CAMP_001_W04.md` en árbitra (blob `42a8cb9db9bdbe34c607d745da6b97e107b621bf`), `CAMPAIGN_GATE_001.md` ACTIVADA (blob `3ef0b39f7eb74f3ebcb688f279c254daec981f8e`).
- Base: rama W04 y árbitra idénticas en `1b52fdd0b7b89e468811a17ad83a917ec7107735` al iniciar. Sin merge forzado ni sobrescritura.
- IDs exactos: `fire_stone`, `water_stone`, `thunder_stone`. Los tres `SELECCIONADO` en catálogo de diseño, no efectos nuevos.
- Fuente primaria: `data/api/v2/evolution-chain/67/index.json` (Eevee → Flareon/Vaporeon/Jolteon según piedra); el corredor usa el **destino obtenido del catálogo activo**, no una constante asumida. Contrasta `EvolutionSystem.classify_record`.
- Ya existía: `FieldItemService.evolution_options/evolve`, `EvolutionSystem.apply_evolution` y corredor V27 `tests/gameplay/item_connections_test_runner.gd`. V1 documenta 5, 6 y 7 rutas compatibles respectivamente; NO duplicamos el motor.
- Base CI real **histórica respecto a esta iteración**: [Actions #41341842320](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41341842320) PASS en `ac34fabbe1a27e69614f0239abee21c29d6fe65e`; W04 anterior 100 checks/3 armaduras y mineral. No cubre los dos nuevos scripts.
- Test nuevo: `tests/gameplay/parallel_items_w04_campaign_001.gd` (blob `37d3b47e9cfadfa7179d32227e653d9aa98e1b28`), 6 combinaciones: Eevee/Growlithe con Fuego; Eevee/Shellder con Agua; Eevee/Pikachu con Trueno.
- Validador nuevo: `tests/tools/test_parallel_items_w04_campaign_001.py` (blob `80309e781739b08270b918ca91b61d3c42f27da0`): comprueba fuente Eevee y selección; opcional `--godot` ejecuta la prueba funcional con JSON único, sin aceptar falsas omisiones.
- Cada caso prueba opción real única, registro respaldado y permitido; falta de stock, criatura ajena, destino falsificado, piedra equivocada, bloqueo de campo, especie incompatible y **rechazo sin consumo**.
- Después verifica evolución, propietario, identidad, IV/EV, experiencia, amistad y movimientos; gasto exacto de 1 y segundo uso no aceptado. No prueba aún guardado/carga (reservado a microbloque 03).
- **Ejecución realizada en este microbloque:** cotejo independiente de GitHub **40/40 PASS estructurales** sobre CSV, cadena canónica, historial y presencia de seis escenarios en los scripts.
- **SIN_EJECUTAR:** ejecución física del validador Python en checkout y del Godot 4.7 para los scripts nuevos. **NO** declarar `FUNCIONAL_PASS_COMMIT`. GPU/visual también pendiente.
- Ejecución futura (único CI consolidado IA6): `python -B tests/tools/test_parallel_items_w04_campaign_001.py`; `godot --headless --path . --import`; `python -B tests/tools/test_parallel_items_w04_campaign_001.py --godot godot`.
- **Rutas escritas:** solo 2 tests nuevos, este informe, `CAMP_001_PROGRESO.csv` y `CONTINUIDAD.md`. Producción, selección, saves, V28, main, otras W y árbitra: sin modificaciones.
- **Próximo paso con otro «p»:** microbloque 02 (Hoja/Hielo/Lunar), si no surge bloqueo/FAIL. No adelantarlo.
