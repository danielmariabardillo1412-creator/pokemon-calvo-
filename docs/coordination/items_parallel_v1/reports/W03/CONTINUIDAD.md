# W03 / IA3 — CUADERNO DE CONTINUIDAD (captura)

## Estado vigente — CAMPAÑA_001_FINALIZADA, ITER_03/03 publicada

- **Identidad:** IA3/W03; rama única `codex/calvo-items-20261101-w03`; ID único `net_ball`. **Estado:** `CAMPAÑA_001_FINALIZADA` por tres entregas, con ITER_03 `PREPARADO_PENDIENTE_CI`. Ningún cuarto bloque autorizado.
- **Órdenes:** `CAMPAIGN_GATE_UPDATE_003.md` árbitra, blob `59c553bd7a931ebe4ac10bf4b2b3ce43815220dc`; campaña `CAMP_001_W03.md` blob `ecb7d9915c936bf5c43f4854584c0f5873f71101`; protocolo de CI/traspaso V2, blob `89087d3729b80290ebd50c226570dc529453547e`. Actualización 003 autoriza explícitamente ITER_03.
- **Sincronización segura:** commit Git de dos padres `d29ab409245189621b1469423230aff4e1bdc40f` (primero W03 `428ca1f7...`, segundo árbitra `8e170550...`), no force. Conservó `LOTE_001.md` blob `2ef030e9...`, `LOTE_002.md` blob `f45a6cd...`, cuaderno previo e informes de ITER_01/02, sin modificar árbitra, main ni W ajenas.
- **Evidencia real de iteración 02, NO de la 03:** IA6 integró Net Ball en `82f9eea26d10976e6eb2702adce911bd7e1ed173` y confirmó PASS en [Actions #41350909378](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41350909378), SHA probado `71332b256621e49e98676ef5f0af48c145d1e86f` (Godot 4.7; V11 32.406, V15 51.901, W03 34 en staging). El PASS no abarca el nuevo test de ITER_03.
- **ITER_03 real:** creada `tests/gameplay/parallel_items_w03_net_campaign_001.gd` commit `3d17512ad442c282a78bf4a6cf8d84c7aa506fa9`, blob `d22bcdabf30c0d85833c20e9d273bedb37f8f3ab`; actualizada `tests/tools/test_parallel_items_w03_net_campaign_001.py` commit `609e0f2ac6cb386ebdc2e46e797d4a6699393c2d` blob `8efa079c6d5c2b6da38eb1d83ce624a681e74285`. Ambos exclusivos de W03.
- **Cobertura añadida:** Magikarp/Agua ×3,5 (equipo), Caterpie/Bicho ×3,5 (PC), Pidgey/Normal ×1, Surskit Agua+Bicho ×3,5 no acumulativo, Mew/otros ×1 con fallo RNG elegido; entrenador, combate acabado, KO, ausencia de bola sin consumo ni RNG; SaveV2/PC/propietario; descriptores `ItemDefinition`, `SpanishGameText` y selector `CaptureBallPicker`. Los tres tipos base reutilizan `_probe_live_types()`/ `_probe_net_boundary()` del test W03 anterior.
- **Verificación en este chat:** comprobación estática de los blobs GitHub de nueva suite + prueba Python, adaptador, V11, V15, APIs de captura/inventario/especie y selector: sin faltantes. **Python ejecutado: NO; Godot ejecutado sobre ITER_03: NO; CI de los nuevos commits: NO; visual/GPU: NO.** No declarar `FUNCIONAL_PASS_COMMIT` para ITER_03.
- **Entregas de campaña:** [ITER_01](./CAMP_001_ITER_01.md), [ITER_02](./CAMP_001_ITER_02.md), [ITER_03](./CAMP_001_ITER_03.md), [matriz final](./CAMP_001_FINAL.md), [CSV de progreso](./CAMP_001_PROGRESO.csv). Cada archivo en rama W03. Consultar HEAD real para SHA final.
- **Acción siguiente corresponde SOLO a IA6:** integrar en staging el nuevo test Godot y validador Python, ejecutar Godot 4.7 con Node 22/simulador nativo fijado y controles V11/V15, conservar SHA y reporte de exit codes. Si falla, diagnóstico y nueva orden limitada. **No continuar por `p`; no abrir CAMPAÑA_002 por cuenta propia.**
- **No tocar:** `CaptureSystem`, `CaptureRuleset`, RNG global, contextos, partidas y migraciones, selección canónica, `luxury_ball`, `dusk_ball`, `beast_ball`, MT/MO legacy, main, V28, PR #118, árbitra u otras ramas. Limitación tipos dinámicos y UI visual queda abierta.
- **Último commit:** no escribir su propio hash dentro del cuaderno; consultar HEAD e historial para recuperarlo.

---

## Registro histórico hasta ITER_02

### Estado previo a ITER_03 — ITER_02/03 publicada, entonces pendiente de CI

- **IA3/W03:** campaña activa `CAMP_001_W03.md` blob `ecb7d9915c936bf5c43f4854584c0f5873f71101`; puerta `CAMPAIGN_GATE_001.md` blob `3ef0b39f7eb74f3ebcb688f279c254daec981f8e`. **ID único: `net_ball`**.
- **Rama exclusiva:** `codex/calvo-items-20261101-w03` incorpora checkpoint árbitra `1b52fdd0b7b89e468811a17ad83a917ec7107735` sin fuerza; LOTE_001 y LOTE_002 intactos. No sincronizar copiando sobre otros documentos. PASS base Actions `41341842320` en commit `ac34fabbe...`, **anterior a la implementación**.
- **Microbloque 01:** análisis de contrato y validador por fases `tests/tools/test_parallel_items_w03_net_campaign_001.py`, commit `bbde5ef67d181092c24c671228f51eb5e0134fd4`, informe [ITER_01](./CAMP_001_ITER_01.md). Solo estático.
- **Microbloque 02:** código **solo en adaptador** `modules/capture/capture_ball_effects.gd` (commit `a87d0b4d0addd1409b2560ab670e6cc89c40d521`) registra `net_ball`. Multiplicador ×3,5 para especie Agua **o** Bicho; ×1 para otras. No duplica ×3,5 con doble tipo. Usa `CreatureSpecies.has_type` de especie basal, NO tipos dinámicos.
- **Regresiones modificadas:** `tests/gameplay/item_capture_v11.gd` (commit `534b22c4ed4481b71573b936396f8472ec0a8af0`) y `tests/gameplay/item_capture_v15.gd` (`625d276143fdacd55756081d109c4b0d126ae4de`); se han eliminado solo las expectativas negativas anticuadas de Net, sustituyéndolas por contrato positivo de registro/probabilidades, consumo, propietario y control de entrenador. Permanecen negativos Lujo y demás bolas pendientes.
- **Evidencia del bloque 02:** 21 comprobaciones **estáticas de contenido GitHub PASS**, con blobs SHA. Informe [ITER_02](./CAMP_001_ITER_02.md), progreso [CSV](./CAMP_001_PROGRESO.csv). **Python real: SIN_EJECUTAR; Godot 4.7: SIN_EJECUTAR; CI del nuevo commit: SIN_EJECUTAR; GPU: SIN_EJECUTAR.** No declarar `net_ball` certificada ni lista para juego. En el entorno no hay Godot ni checkout; la CI pertenece a IA6.
- **Bloqueo siguiente `p`:** como **ITER_02 cambia producción sin prueba Godot nueva**, no preparar ITER_03 hasta que IA6 confirme ejecución real PASS sobre commit integrado o autorice expresamente seguir tras diagnosticar. Si hay FAIL, reportar y detener; no avanzar automáticamente.
- **Comandos de validación pendientes, desde checkout en CI:** `python tests/tools/test_parallel_items_w03_net_campaign_001.py --phase implemented`, `python tests/tools/test_parallel_items_w03_capture_v1.py`, `godot --headless --path . --script tests/gameplay/parallel_items_w03_capture_net_v1.gd -- --require-net`, ejecutar V11 y V15 con Godot según sus runners. Registrar SHA probado y resultados.
- **Contratos intactos:** `CaptureRuleset` incorpora `BallEffects.IDS` automáticamente; `CaptureSystem.resolve()` usa especies y cálculo `calvo_capture_v1`; `CaptureInventoryService` descuenta/rollback; `SaveGameRepository` y `CaptureOwnershipRouter` mantienen partidas/PC. No duplicar ni editar módulos compartidos.
- **Permisos y exclusiones:** mantener fuera `CaptureSystem`, `CaptureRuleset`, sesiones, esquema/guardados, workflows, `main`, V28, árbitra, W01/W02/W04/W05. `luxury_ball`, `dusk_ball`, `beast_ball` no pertenecen a esta campaña. Tres microbloques como máximo.
- **Último commit propio:** leer HEAD/historial de [este cuaderno](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/commits/codex/calvo-items-20261101-w03/docs/coordination/items_parallel_v1/reports/W03/CONTINUIDAD.md); por diseño el propio SHA no puede insertarse dentro de su commit.

---

## Registro histórico — microbloque 01

### ITER_01 — contrato y validador (histórico)

- **Identidad:** IA3/W03; ID exclusivo `net_ball`. **Estado:** `PREPARADO_PENDIENTE_CI` (microbloque 01 terminado), sin Net implementada. Los bloques 02 y 03 no se han iniciado; cada uno necesita nuevo `p`.
- **Autoridad vigente:** `CAMPAIGN_GATE_001.md` blob `3ef0b39f7eb74f3ebcb688f279c254daec981f8e` (`ACTIVADA`); `campaigns/CAMP_001_W03.md` blob `ecb7d9915c936bf5c43f4854584c0f5873f71101`; `STATUS.md` blob `cb651d4cc3a684d80f5b99752fba87ca8c4adb4d`.
- **Sincronización:** se hizo fast-forward **sin fuerza** de la rama exclusiva W03 (`37f32d9`) al HEAD árbitra `1b52fdd0b7b89e468811a17ad83a917ec7107735`. W03 y árbitra quedaron idénticas antes de crear archivos propios; `LOTE_001.md` (blob `2ef030e9...`) y `LOTE_002.md` (blob `f45a6cd...`) se conservaron. El checkpoint autorizado `8a74b938...` y SHA de CI `ac34fab...` son ancestros de la rama árbitra.
- **PASS real de base (histórico, NO nuevo W03):** Actions [41341842320](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41341842320), commit `ac34fabbe1a27e69614f0239abee21c29d6fe65e`, conclusión `success`, Godot 4.7. W03 caracterización PASS con `net_ball` **no implementada**. Del SHA probado hasta la campaña solo hubo archivos de documentación.
- **ITER_01:** [informe](./CAMP_001_ITER_01.md), [progreso](./CAMP_001_PROGRESO.csv); validador Python de fases [`tests/tools/test_parallel_items_w03_net_campaign_001.py`](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w03/tests/tools/test_parallel_items_w03_net_campaign_001.py) creado en `bbde5ef67d181092c24c671228f51eb5e0134fd4`. No hay cambios de producción ni de tests históricos.
- **Contrato:** Magikarp/Agua ×3,5; Caterpie/Bicho ×3,5; Pidgey/Normal ×1. Dos tipos elegibles no duplican factor. `CaptureSystem.resolve()` ya consulta `CreatureSpecies` y llama a `BallEffects.multiplier()`, mientras `CaptureRuleset` incorpora automáticamente `BallEffects.IDS`. Los tipos usados son los canónicos de especie, no los alterados dinámicamente durante combate; no alterar contexto ni fórmula de RNG.
- **Reutilización:** `parallel_items_w03_capture_net_v1.gd` ya cubre tres especies, Net desconocida sin consumo/RNG, fallo válido que consume, entrenador rechazado, equipo/PC y SaveV2. **Dos negativos obsoletos al conectar Malla:** bucles `unsupported` de `item_capture_v11.gd` y `item_capture_v15.gd`; reemplazarlos con expectativas positivas, preservando negativos de Lujo y resto.
- **Pruebas de ITER_01:** revisión estática de blobs GitHub hecha. El **nuevo** Python `--phase baseline`: `SIN_EJECUTAR` sobre checkout; nuevo Godot `SIN_EJECUTAR`; CI sobre commit de este bloque `SIN_EJECUTAR`; GPU `SIN_EJECUTAR`. Contenedor sin Godot, `git ls-remote` falló DNS. No inventar PASS.
- **Límites de escritura vigentes:** solamente `modules/capture/capture_ball_effects.gd`, tests W03 expresamente listados en `CAMP_001_W03.md`, `reports/W03/CAMP_001_ITER_0N.md`, `CAMP_001_PROGRESO.csv` y este cuaderno. `CaptureRuleset`, `CaptureSystem`, save/schema, sesiones, `.github/`, V28, `main`, árbitra y otras ramas solo lectura.
- **Próximo `p` (ITER_02):** comprobar primero estado oficial IA6 y rama W03; añadir SOLO `net_ball` a `BallEffects.IDS` y multiplicador puro desde `CreatureSpecies.has_type(&"water")` o `has_type(&"bug")`; cambiar negativos históricos V11/V15 por contratos correctos. Ejecutar `python tests/tools/test_parallel_items_w03_net_campaign_001.py --phase implemented` y Godot cuando exista runner; si no se prueba nueva producción, **PREPARADO_PENDIENTE_CI**, no certificado.
- **Parada:** cualquier FAIL, choque de rutas, cambio a tipos temporales o necesidad de editar otro módulo requiere IA6. `luxury_ball`, `dusk_ball`, `beast_ball` fuera de campaña. Detener tras ITER_03 y emitir `CAMPAÑA_001_FINALIZADA`.

---

## Registro histórico anterior (LOTE_001 y LOTE_002)


**Estado: LISTA_PARA_REVISION / PENDIENTE_CI**. Documento de memoria técnica en la rama **`codex/calvo-items-20261101-w03`**. **No otorga permisos nuevos**. Fecha: 2026-11-01.

## 1. Identidad, orden oficial y versión base

- Trabajadora IA3 / W03. Familia asignada: `CAPTURE_BALL`. En `LOTE_001`: `luxury_ball`, `net_ball`, `dusk_ball`. En `LOTE_002`: **solo caracterización de `net_ball`**, sin producción.
- Última asignación oficial IA6: `docs/coordination/items_parallel_v1/assignments/LOTE_002_W03.md` en rama árbitra; blob **`27cf744ac6a8cf15ca9c1c5413c197dedc11ad12`**, leído en rama árbitra `9fc2a303ce17c91a48b2c6189cbcfc281b3d92c3`.
- Protocolo oficial de cuadernos `NOTEBOOK_PROTOCOL_V1.md` blob `4fac0eba28ea30dc6d3a3bd749699874cf446e66`.
- Checkpoint común de IA6 `38188cc208e67b19002437ac75160898ce332ec2`, base combinada **SIN CI**. W03 incorporó historia de árbitra `9fc2a303...` en merge propio **`84247bdee5b70a445f163b6b6a1c870a05672661`** con padres W03 `c84a0f9...` + árbitra; avance sin fuerza y LOTE_001 preservado exactamente (blob `2ef030e9a70bf0102849dc7e65e700e07b195c53`).
- Último commit propio que contiene este cuaderno: consultar [historial de este archivo](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/commits/codex/calvo-items-20261101-w03/docs/coordination/items_parallel_v1/reports/W03/CONTINUIDAD.md) o HEAD. Es imposible escribir dentro del mismo commit su propio SHA sin generarlo de nuevo.
- Último commit **funcional probado** para los tres IDs: **ninguno**. Última evidencia de captura histórica relacionada: V15, fuera de estos tres IDs.
- Rutas autorizadas exclusivamente en LOTE_002: `tests/gameplay/parallel_items_w03_capture_net_v1.gd`, `tests/tools/test_parallel_items_w03_capture_v1.py`, este cuaderno y `reports/W03/LOTE_002.md`; no escribir en ninguna otra ruta.

## 2. Mapa exacto del flujo existente

`docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv` (selección) + `docs/current/ITEM_INVENTORY.csv` (entrada nativa) → `CaptureRuleset` (solo bolas admitidas y orden) → `capture_ball_picker.gd` (vista y cantidad, nunca fórmula) → sesión `WildAdventureSession` o `ShowdownAdventureSession` construye contexto desde batalla → `CaptureInventoryService.resolve` (propiedad, gasto de una unidad y rollback) → `CaptureSystem.validate_attempt/resolve` (especie por `base_species_id`, RNG, probabilidad `calvo_capture_v1`) → `BallEffects`/`ContextBallEffects` (reglas puras y efectos postcaptura) → `CaptureOwnershipRouter` (equipo/PC) → `SaveGameRepository` y snapshot/restore de sesión.

**Blobs clave inspeccionados en W03 sobre base fusionada:**
- `capture_ruleset.gd` `aaa848d77ff31349dae9720be001ff31658f55a9`; `capture_system.gd` `59d0149f27dd8f6bcdf8334b89c07cc1f88917cf`.
- `capture_ball_effects.gd` `684645648c654030b482d6b945055c5ed42bda7e`; `capture_context_ball_effects.gd` `2eb24d7de69d60b0ac3a31ec28055dd8c5eea00b`.
- `capture_battle_context.gd` `0a1ac1e2710e3a1f370fd8443ba0efde6dba4533` (sin campo de tipo efectivo).
- `creature_species.gd` `590b963a85929ff9d8c82a3590d05e28fe178cd7` (`has_type` y `type_ids_resolved` disponibles); `creature_instance.gd` `882f630845549700cacaa710b742bab986887e5c` (sin bola de origen).
- `capture_inventory_service.gd` `5898e23f3d935bd48df4a5f9e13c5b2cab7c852d`; `field_friendship_effects.gd` `da010fd3baad787cd30249e39f767085bf556599`.
- `item_capture_v15.gd` `0d209e00ef2abc6ed998753c24847363420af7f9` mantiene negativo `net_ball` y `luxury_ball` fuera de catálogo admitido.

**Qué está probado históricamente:** 16 bolas conectadas en V27/V28. V15 registró `ITEM_CAPTURE_V15 PASS checks=51895 cases=17216 GPU=false` y `checks=68 GPU=true` para Amigo/Safari/Competi/Gloria, no para W03. Evidencia en `docs/current/ITEM_CAPTURE_V15.json` blob `0dd6aa2b3a6520412a33814935fe30876c1ee86c`. No trasplantar esos PASS al árbol combinado.

## 3. Estado por ID

| ID | Estado real | Evidencia | Siguiente trabajo |
|---|---|---|---|
| `net_ball` | **CONEXION_PARCIAL / BLOQUEO_DE_CONTRATO**; especie/tipos basales consultables, bola no reconocida | LOTE_001 y LOTE_002 + código `CaptureRuleset` y `CaptureSystem`; Godot nuevo **SIN_EJECUTAR** | IA6 decide tipos canónicos vs dinámicos; correr test W03; autorizar implementación solo después |
| `luxury_ball` | **DEPENDENCIA**: no registra bola origen, ganancia futura de amistad incompleta | `CreatureInstance`, `field_friendship_effects.gd`, `battle_support_profile.json` | Definir serialización/migración y compartir autoría con W02; no desarrollar en LOTE_002 |
| `dusk_ball` | **DEPENDENCIA**: no hay noche/cueva confiable en contexto de captura | `CaptureBattleContext`, `CaptureRuleset` | IA6 define contrato de tiempo/entorno antes de implementar |
| `beast_ball` | **CONFLICTO_POLITICA**, FUERA DEL LOTE | V28 cancela; catálogo nuevo selecciona | Resolver solo en IA6/usuario, nunca por W03 |

**No hay PASS nuevo ni certificación de efecto para ninguno de estos tres.** El hecho de disponer de imagen/entrada en inventario no habilita captura.

## 4. Historial de trabajo propio

| Lote | Entrega real | Commits | Validación | Estado de IA6 |
|---|---|---|---|---|
| LOTE_001 | Auditoría documental de tres bolas, sin producción | Reserva `0014f82`; informe `c84a0f9` | lectura de código y evidencia histórica, Godot **SIN_EJECUTAR** | **ACEPTADO documentalmente** |
| Sincronización LOTE_002 | Merge sin fuerza, conserva LOTE_001 | `84247bdee5b70a445f163b6b6a1c870a05672661` | HEAD y tres rutas obligatorias verificados por GitHub | base combinada **SIN CI** |
| LOTE_002 | [Prueba Godot](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w03/tests/gameplay/parallel_items_w03_capture_net_v1.gd), [validador Python](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w03/tests/tools/test_parallel_items_w03_capture_v1.py), [informe](./LOTE_002.md), este cuaderno | `af07415` + `6060994` + `0c72624` + commit de cuaderno por historial | Godot **SIN_EJECUTAR**, Python completo **SIN_EJECUTAR**; test estático preparado | **LISTA_PARA_REVISION** |

**Qué contienen las pruebas:** Godot caracteriza tres especies con encuentros vivos (Agua/Bicho/Normal), Net desconocida sin gasto/RNG, control Poké Ball con fallo determinista y coste real, rechazos por entrenador, Master Ball con PC, guardado/carga del inventario y propietario. Si se habilita Net, exige multiplicadores externos 3,5/3,5/1 y coste; `--require-net` ofrece un rojo explícito para esa fase. El validador Python cuenta seis pruebas de estructura/contrato y declara por texto `NO_ES_PASS_FUNCIONAL` incluso al pasar.

**No ejecutado por entorno:** sin Godot 4.7, sin checkout completo; `git ls-remote` falló por DNS. No hay CI W03 lanzado. Inspección de rutas, contenido y hashes hecha en GitHub. Ninguna afirmación de PASS operativo.

## 5. Riesgos, decisiones, conflictos

1. **Tipos efectivos:** `CaptureSystem` puede leer `CreatureSpecies` del objetivo y esa clase tiene `has_type`, pero eso no demuestra tipos actuales si hubo transformaciones o cambios por combate. No falsear `CaptureBattleContext`. **SOLICITUD_IA6** decidir fuente y semántica.
2. **Test histórico incompatible con futura activación:** V15 exige expresamente Net/Lujo ausentes. La próxima implementación deberá actualizar esa expectativa de forma controlada, preservando regresiones.
3. **Persistencia/propiedad:** no duplicar `CaptureInventoryService` ni `SaveGameRepository`. Mantener guardados transaccionales, publicación una vez, contexto desde servidor/sesión.
4. **Intersección W02:** `field_friendship_effects.gd` y `CreatureInstance` son compartidos; Lujo no se toca en este lote.
5. **Base combinada:** V27 + V28 fusionadas estructuralmente, pero jamás declarar PASS sin CI del conjunto. La árbitra controla el único CI consolidado y archivos compartidos.
6. **Otros vetos:** no abrir gestión Mega, Ultraentes/Ente Ball, política activa, economía ni reprogramar captura entera.

## 6. Cómo retomar sin repetir trabajo

1. Abrir `STATUS.md` y el **último** `assignments/LOTE_NNN_W03.md` de árbitra; comparar SHA y permisos. No interpretar «sigue» como lote nuevo.
2. Verificar HEAD W03 y ancestro de checkpoint/árbitra; nunca sobrescribir este cuaderno ni `LOTE_001.md` mediante rebase forzado.
3. Leer [informe LOTE_002](./LOTE_002.md) y los **dos** scripts nuevos, no recargar documentación de 2.222 objetos.
4. Si la coordinadora autoriza CI, desde checkout Godot 4.7:
   - `python tests/tools/test_parallel_items_w03_capture_v1.py`
   - `godot --headless --path . --script tests/gameplay/parallel_items_w03_capture_net_v1.gd`
   - Solo para exigir Net en fase implementada: `godot --headless --path . --script tests/gameplay/parallel_items_w03_capture_net_v1.gd -- --require-net`.
5. Registrar SHA probado, logs, códigos de salida y si el test queda en `BLOQUEADO_NET_BALL_NO_REGISTRADA`; **CARACTERIZACION_PASS no equivale a Net funcional**.
6. Si IA6 emite lote de implementación tras base certificada, resolver contrato de tipos dinámicos y propiedad exclusiva de archivos primero. No tocar más de lo autorizado.

**Último siguiente paso reproducible:** revisión IA6 del diff de LOTE_002; ejecutar Python/Godot en CI **una sola vez y coordinadamente** tras combinar lotes. Resolver la política de tipos antes de implementar Net.

**GPU/visual:** NO REALIZADA en LOTE_002.

**NO TOCAR:** `main`, V28, árbitra, otras W, `modules/`, `scenes/`, `config/`, `data/`, `assets/`, `.github/workflows/`, datos/selección/guardados, tests existentes sin nueva asignación. No iniciar LOTE_003.
