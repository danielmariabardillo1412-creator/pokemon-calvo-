# W03 — CAMPAÑA_001_FINAL

**Estado de entrega: CAMPAÑA_001_FINALIZADA (03/03); última suite `PREPARADO_PENDIENTE_CI`.** No implica PASS funcional global.
**Identidad:** IA3/W03, rama `codex/calvo-items-20261101-w03`, ID único `net_ball`. Gate vigente IA6 [003](../../CAMPAIGN_GATE_UPDATE_003.md).

| Bloque | Entrega | Código/archivo | Evidencia | Estado |
|---|---|---|---|---|
| 01 contrato | Agua, Bicho, Normal; consumo y SaveV2; negativos históricos | [ITER_01](./CAMP_001_ITER_01.md), [validador por fases](../../../../tests/tools/test_parallel_items_w03_net_campaign_001.py) | Revisión estática; CI base #41341842320 anterior a implementación | PREPARADO |
| 02 implementación | `BallEffects.IDS` registra solo Malla, ×3,5 Agua/Bicho y ×1 resto; negativos V11/V15 sustituidos | [ITER_02](./CAMP_001_ITER_02.md), `capture_ball_effects.gd`, V11, V15 | IA6 integró `82f9eea26d10976e6eb2702adce911bd7e1ed173`. [CI #41350909378](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41350909378) PASS sobre `71332b256621e49e98676ef5f0af48c145d1e86f`; V11/V15 y W03 también PASS staging | INTEGRADO_VERIFICADO para ese alcance |
| 03 regresión adicional | Agua/Bicho/Normal, Surskit doble tipo, fallo/control de RNG, entrenador/KO/batalla terminada/sin bola, equipo/PC, SaveV2, descriptor/UI | [ITER_03](./CAMP_001_ITER_03.md), `parallel_items_w03_net_campaign_001.gd`; validador Python ampliado | Inspección estática de blobs PASS. Python real **SIN_EJECUTAR**, Godot 4.7 nuevo **SIN_EJECUTAR**, CI del nuevo commit **SIN_EJECUTAR** | PREPARADO_PENDIENTE_CI |

**Cobertura conocida:** `magikarp` Agua ×3,5, `caterpie` Bicho ×3,5, `pidgey` Normal ×1; `surskit` Agua/Bicho ×3,5 sin acumulación (nuevo test pendiente de ejecutar). Caso no aplicable `mew` ×1 con fallo semilla controlada. La garantía de success en Magikarp/Caterpie procede del cálculo canónico de probabilidad con 1 HP, no de Master Ball ni de inyección de resultado.

**Garantías NO reclamadas:** pruebas GPU/visuales, tipos mutables de combate, certificación de nueva suite por CI, juego completo, políticas de `luxury_ball`, `dusk_ball`, `beast_ball`. Malla se implementó en adaptador sin modificar `CaptureSystem`, `CaptureRuleset`, RNG ni esquema de guardado.

**Próxima acción exclusiva de IA6:** integrar solamente nueva prueba Godot y validador Python en staging de rama árbitra, ejecutar suite W03 nueva y controles V11/V15 sobre SHA resultante, verificar salida/errores y decidir aceptación. Si fallan, diagnosticar y emitir encargo acotado; **no iniciar un cuarto bloque automáticamente**.

**STOP formal W03:** trabajo entregado. Ningún nuevo `p` autoriza CAMPAÑA_002.
