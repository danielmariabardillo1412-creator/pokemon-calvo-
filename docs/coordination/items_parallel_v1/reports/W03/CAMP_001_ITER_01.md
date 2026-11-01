# CAMP_001_W03 / ITER_01 — Contrato Net Ball

**Estado: PREPARADO_PENDIENTE_CI; microbloque 01 cerrado, sin producción.**
- Autoridad: `CAMPAIGN_GATE_001.md` (blob `3ef0b39f7eb74f3ebcb688f279c254daec981f8e`, ACTIVADA); encargo `CAMP_001_W03.md` (blob `ecb7d9915c936bf5c43f4854584c0f5873f71101`).
- Identidad: IA3/W03; ID exclusivo `net_ball`. `luxury_ball`, `dusk_ball`, `beast_ball` fuera del trabajo.
- Sincronización: W03 avanzó sin fuerza de `37f32d946220d9de3597c0869fad4e5c0070ff0f` a HEAD de árbitra `1b52fdd0b7b89e468811a17ad83a917ec7107735`; era ancestro, comparación tras actualizar `identical`. LOTE_001 y LOTE_002 conservan blobs `2ef030e9...` y `f45a6cd...`.
- CI base **PASS REAL HISTÓRICO DE SHA `ac34fabbe1a27e69614f0239abee21c29d6fe65e`**: [Actions 41341842320](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41341842320), W03 caracterización PASS **sin Malla operativa**. De ese SHA al HEAD árbitra solo cambiaron documentos (comparado).
- Contrato Agua: `magikarp`, especie `water`, factor esperado 3,5. Bicho: `caterpie`, `bug`, factor 3,5. Control Normal: `pidgey`, factor 1,0. Tipo doble Agua+Bicho recibe factor 3,5 **una sola vez**; no suma ni multiplica duplicado. No se añade RNG independiente.
- Fuente de tipos: `CreatureSpecies.has_type()` y `type_ids_resolved()` (blob `590b963a...`); `CaptureSystem.resolve()` recupera la especie mediante `base_species_id()` y llama a `BallEffects.multiplier()` (blob `59d0149...`).
- Fuente de registro: `CaptureRuleset._init()` y `ordered_ball_ids()` incorporan `BallEffects.IDS` (blob `aaa848d...`); el adaptador actual `capture_ball_effects.gd` aún **NO** tiene `net_ball` (blob `6846456...`).
- Semántica acordada del encargo: consultar tipos **canónicos de especie**, no inventar tipo mutable en `CaptureBattleContext`. Limitación no cubierta: cambios temporales de tipo en combate; no ampliar arquitectura sin permiso.
- Frontera de captura: `CaptureInventoryService.resolve()` valida primero; intenta gastar exactamente 1 por lanzamiento válido, repone en rollback; `SaveGameRepository.save_collection()/load()` transaccional. No se duplicó ninguna capa.
- Pruebas existentes reutilizadas: `tests/gameplay/parallel_items_w03_capture_net_v1.gd` (blob `e2b6a77...`) contiene Agua/Bicho/Normal, Net desconocida sin RNG/gasto, Poké Ball fallida con consumo, rechazos, Master Ball/PC y SaveV2; **sin modificar**.
- Históricas que deben cambiar en iteración 02: `item_capture_v11.gd` bucle `unsupported` incluye Net; `item_capture_v15.gd` otro bucle `unsupported` incluye Net. Reemplazar ambos negativos por controles positivos/negativos equivalentes; Lujo y demás desconocidas siguen negativas.
- Nuevo archivo propio `tests/tools/test_parallel_items_w03_net_campaign_001.py` (commit `bbde5ef67d181092c24c671228f51eb5e0134fd4`) ofrece `--phase baseline` y `--phase implemented`: exige contrato, tres casos, propiedad/consumo/guardado y corrección de las dos regresiones al implementar.
- **Comprobación realizada**: lectura de blobs GitHub y cotejos estáticos directos en código; sin discrepancias en contrato, con `net_ball` ausente por diseño. No son pruebas de ejecución.
- **Nuevo validador Python:** `SIN_EJECUTAR`; **nuevo Godot:** `SIN_EJECUTAR`; CI del nuevo commit: `SIN_EJECUTAR`; GPU: `SIN_EJECUTAR`. No hay checkout de GitHub ni Godot en el contenedor (`git ls-remote`: DNS error).
- Comando de réplica: `python tests/tools/test_parallel_items_w03_net_campaign_001.py --phase baseline`. Esperable PASS estático, no atribuirlo sin ejecutar.
- **Siguiente microbloque autorizado 02**, solo ante nuevo `p`: añadir Malla al adaptador permitido con 3,5/1 desde `CreatureSpecies.has_type` y sustituir negativos obsoletos en V11/V15, sin tocar `CaptureSystem`, `CaptureRuleset`, fórmula ni guardados. Exigir CI posterior para cualquier funcionalidad.
- No se modificó `main`, V28, árbitra ni ramas ajenas. No hay PASS funcional de Net Ball.
