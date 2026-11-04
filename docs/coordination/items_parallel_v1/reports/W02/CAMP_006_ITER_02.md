# IA2/W02 — CAMPAÑA_006 · BLOQUE 02/10: tres mentas, dependencia de naturaleza efectiva

**Rama exclusiva:** `codex/calvo-items-20261104-w02-camp006`. **Orden IA6:** `CAMPAIGN_006_W02_QUEUE_APPROVED.csv` fila02 (`gentle_mint;hasty_mint;lax_mint`), gate `CAMPAIGN_006_W02_GATE.md`, encargo `CAMP_006_W02.md` y `AUTONOMOUS_REPAIR_V5.md`. Ningún cambio en main/V28/PR118/árbitra/ramas de otras trabajadoras/producción/APIs compartidas.

## Recuperación previa: gate desbloqueado con recibo real

El run [41763921080](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41763921080) finalizó `completed/success` en commit `2abcc2ae9644b8821d9dae6f26214b1a8fa347fc`. Ejecutó `CAMP005_W02_PY/GODOT PASS blocks=10`, `CAMP006_W02_PY/GODOT PASS blocks=1` y regresiones Python/Godot CAMP004 y CAMP003. Es un recibo HISTÓRICO de bloque01; no sustituye la nueva CI del código bloque02. Se mantienen todos los 288 casos previos.

## Diagnóstico real bloque02: no existe efecto L2

| ID nuevo | Naturaleza definida en reglas nativas | Efecto estadístico de esa naturaleza | Estado de menta |
|---|---|---|---|
| `gentle_mint` | `gentle` | +Defensa Especial / −Defensa | `DEPENDENCIA_DOCUMENTADA` |
| `hasty_mint` | `hasty` | +Velocidad / −Defensa | `DEPENDENCIA_DOCUMENTADA` |
| `lax_mint` | `lax` | +Defensa / −Defensa Especial | `DEPENDENCIA_DOCUMENTADA` |

**Constatado en fuente:** `ProgressionRuleset.NATURE_MODIFIERS` registra los modificadores anteriores; `CreatureInstance` contiene `nature_id`, pero no `effective_nature_id` ni estado persistente equivalente. `CreatureInstance.recalculate_stats` llama a `StatCalculator.compute(..., nature_id, level)` y el cálculo usa esa naturaleza original. `FieldItemService.use_item` no tiene handler de menta y termina con `DEPENDENCY_MISSING`/`field_effect_not_connected`. `FieldItemEffects` tampoco gestiona los IDs. La configuración de selección no excluye ninguno. `SaveGameData.build` serializa `CreatureInstance.to_dict()`, que no guarda un modificador de naturaleza por menta. No se ha encontrado un contrato que garantice el efecto positivo y SaveV2.

**Por tanto, una menta del bloque02 NO puede darse como funcional solo por existir su naturaleza en la tabla.** Ni cambiar `nature_id` ni alterar stats manualmente constituye una implementación correcta. No se ha efectuado ninguna de esas operaciones.

## Una dependencia compartida para IA6 (no 24 rechazos equivalentes)

**Clave:** `MINT_EFFECTIVE_NATURE_STATE_SAVEV2_006_W02`. **Propietaria de decisión:** IA6 y el responsable que asigne del contrato de criatura/SaveV2. **Productor pendiente:** naturaleza estadística efectiva independiente de la original, handler transaccional de las mentas y persistencia válida.

**Consumidores que deben quedar coherentes:** `CreatureInstance.recalculate_stats`, `StatCalculator.compute`, cálculos de combate, `CreatureInstance.to_dict/from_dict`, `SaveGameData.validate/build`, `SaveGameRepository.decode_snapshot`, `FieldItemService.use_item`.

**Contrato positivo a aprobar/probar:** para cada una de las tres mentas, demostrar recálculo real de la estadística aumentada y reducida, conservación de la naturaleza original y de PS/IV/EV/PP/identidad/amistad, descuento exactamente de una unidad de la bolsa, rollback sin consumo ante objetivo no aplicable, paridad PARTY/STORAGE, carga SaveV2 sin perder el estado efectivo y aplicación idéntica durante batalla. Preservar compatibilidad con guardados preexistentes. Sin esa decisión de interfaz compartida, no abrir cambios de producción.

**Comprobación negativa representativa, sin falsos positivos:** `gentle_mint_missing_effect_route`, un solo caso ejecutado por el runner existente a través de `_probe_training`/servicio nativo en `active`, `none` y `reserve`. Debe devolver `DEPENDENCY_MISSING`, no consumir stock, no mutar criatura, conservar propietario y SaveV2. Para `hasty_mint` y `lax_mint` los checks de Python constatan ausencia de ejecutor y presencia en la tabla, sin duplicar el mismo negativo numerosas veces. Este bloque es **L1 dependencia**, no L2 ni L3.

## Publicaciones y validación

- Fixture propia `tests/fixtures/parallel_items/w02_campaign_006.json`: bloque02 con tres IDs, mapa de naturalezas, una prueba nativa representativa, dependencia singular con origen/consumidores/propietario/prueba positiva pendiente y gate histórico `41763921080`. Commit `a77f951cb64d8f810aca5953a5a38edc744a9e79`.
- Progreso `reports/W02/CAMP_006_PROGRESO.csv`: fila01 `CI_RECUPERADA_VERIFICADA`, fila02 `DEPENDENCIA_DOCUMENTADA`; commit `52438969592f85edc3901d41c43767b2e2ed2c78`.
- Validador `tests/tools/test_parallel_items_w02_campaign_006.py`: verifica ambas filas, 288 escenarios CAMP005 intactos, gate 01, mapa independiente, ausencia de handler y estado efectivo, productor/consumidores, test único y contrato SaveV2; marca por separado `CAMP006_W02_PY PASS blocks=1` y `CAMP006_W02_DEPENDENCY BLOCKED block=02 ids=3`. Commit `a9cf6592826c8d1f590f07fe58ac282fd534a70a`.
- Runner Godot `tests/gameplay/parallel_items_w02_campaign_006.gd`: comprueba la tabla de naturalezas y ejecuta una negativa real sobre 3 modos, manteniendo recibo `PASS blocks=1` exclusivo de recuperación y marcador `BLOCKED block=02` separado. Commits `2cff2eb92c9e66233b3d709637c01c8fa96c7776`, `171cd5abde97a0634bd25b6f0bc99f1786db9366`.
- CI `.github/workflows/parallel-camp006-w02-autoci.yml`: ampliada para exigir la prueba de dependencia en Python y Godot, sin reducir CAMP005, CAMP004 ni CAMP003. Una modificación del workflow produjo accidentalmente duplicación de contenido (runs fallidos antes de jobs); se reparó reconstruyéndolo desde la versión válida y añadiendo solo los dos `grep` nuevos. Commit de reparación `2da2e54dc1657f140fd2c12724595404176197af`. Este tipo de incidencia **no es un fallo de implementación de menta**.

**CI de bloque02:** debe comprobarse el run del último SHA en la rama tras terminar. Hasta entonces, no afirmar `CAMP006_W02_GODOT/PY PASS blocks=2`: sería incorrecto por ausencia de L2. Exigir únicamente recuperación PASS de bloque01, marcador `DEPENDENCY BLOCKED block=02`, las regresiones previas y `completed/success` del workflow sin convertir el bloque02 en funcional.

## Siguiente paso

**Bloque02 entrega diagnóstico y tests; no cierra integración funcional.** IA6 debe resolver primero la interfaz compartida. El siguiente `p` solo podrá tratar la fila03 de la cola sin inventar pruebas positivas ni reabrir docenas de rechazos similares; si persiste esta dependencia, registrar que comparten la clave `MINT_EFFECTIVE_NATURE_STATE_SAVEV2_006_W02`. No empezar bloque03 en esta orden.
