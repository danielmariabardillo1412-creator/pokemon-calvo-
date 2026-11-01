# W03 / LOTE_001 — informe de entrega (auditoría de captura)

**Estado: LISTA_PARA_REVISION** · **IA3/W03** · **Solo diagnóstico: ningún objeto implementado ni prueba modificada.**

- **Encargo original:** [LOTE_001_W03.md](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-arbitro/docs/coordination/items_parallel_v1/assignments/LOTE_001_W03.md).
- **Rama exclusiva:** `codex/calvo-items-20261101-w03`; base inicial `d6d6d5f9285d71b97db3ac18c6bbb70274ab19af`.
- **Marca de ocupación previa y comprobación de sitio libre:** commit [`0014f82cddf90e39af77dfb882e8596e57d30570`](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/commit/0014f82cddf90e39af77dfb882e8596e57d30570), `RESERVADO_POR_IA3_W03`, mismo archivo; antes no existía `reports/W03/` en esta rama. **No se escribe ninguna otra rama.**
- **Referencia V28 de solo lectura:** `codex/items-v28-from-main` HEAD `7d49a23d15432b9e7845f2c8cd6b0ee5a88e286e`, PR #118 sin integrar. La rama de catálogo/V27 y V28 son divergentes; **no se realizó merge/rebase**.
- **Commit de la entrega:** consultar el historial de [este informe en W03](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/commits/codex/calvo-items-20261101-w03/docs/coordination/items_parallel_v1/reports/W03/LOTE_001.md) y el HEAD de la rama; el SHA definitivo lo acompaña en el mensaje de entrega al usuario. No se puede incrustar el propio hash final dentro de su contenido sin un commit adicional.

## 1. Resultado resumido por ID (no confundir selección con funcionalidad)

| ID / nombre | Fuente de catálogo | Ruta de captura en V27 y V28 | Clasificación principal | Qué falta |
|---|---|---|---|---|
| `luxury_ball` — Lujo Ball | `SELECCIONADO` / entrada nativa e icono | **No reconocida** por `CaptureRuleset`; test V15 afirma explícitamente su exclusión temporal | **DEPENDENCIA** + `CONEXION_PARCIAL` de datos | Persistir origen de captura por criatura y aplicar bonificación de amistad futura desde su dueño; contrato de evolución/amistad y pruebas |
| `net_ball` — Malla Ball | `SELECCIONADO` / entrada nativa e icono | **No reconocida**; test V15 afirma explícitamente su exclusión temporal | **CONEXION_PARCIAL** + dependencia de tipos efectivos | Regla de tipo Agua/Bicho y datos de tipos efectivos confiables del objetivo en la sesión real; pruebas diferenciales |
| `dusk_ball` — Ocaso Ball | `SELECCIONADO` / entrada nativa e icono | **No reconocida** por `CaptureRuleset`; **sin negativo específico** encontrado en V15 | **DEPENDENCIA** + `SIN_EVIDENCIA` de prueba específica | Contexto confiable noche/cueva de la batalla, regla de multiplicador y pruebas de los límites |

`FUNCION_Y_PRUEBA`: **0/3** para estas tres bolas. El inventario/catálogo nativo o una marca `VERIFIED` de la matriz de campo **no certifica su lanzamiento, multiplicador, efectos secundarios ni guardado**. Tampoco implica que falte recrear el sistema de captura completo.

## 2. Evidencia concreta de código y rama

1. `docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv` blob `8b9b723bf5944bbbde39aa2d49dfbb2f2a64e11b`: los tres seleccionados, familia `CAPTURE_BALL`. `docs/current/ITEM_INVENTORY.csv` blob `2aaf18643bb2b071226118a1ad556cffca4707dd`: las tres entradas son `NATIVE_ENTRY_REQUIRES_EFFECT_CASE`, no certificación de efecto. `docs/current/ITEM_FIELD_V8.csv.txt` blob `9509d537622039b2f1919067561631449b8ddc47`: las tres son `BATTLE_CAPTURE_ITEM_NOT_DIRECT_FIELD_USE` y `SCENARIO_OR_SPECIAL_ACTION_CONTEXT_PENDING`; su `VERIFIED` se refiere a la clasificación/alcance de campo, **no** a captura conectada.
2. `modules/capture/capture_ruleset.gd` blob `aaa848d77ff31349dae9720be001ff31658f55a9`: solo cuatro bolas base + nueve `BallEffects.IDS` + tres `ContextBallEffects.IDS` = **16**. `ordered_ball_ids()` alimenta al selector; **ninguno** de los tres IDs del lote figura allí.
3. `modules/capture/capture_ball_effects.gd` blob `684645648c654030b482d6b945055c5ed42bda7e`: multiplicadores, validaciones y postcaptura para las nueve bolas anteriores, sin Lujo/Malla/Ocaso. `modules/capture/capture_context_ball_effects.gd` blob `2eb24d7de69d60b0ac3a31ec28055dd8c5eea00b`: solo Veloz/Turno/Nivel.
4. `modules/capture/capture_system.gd` blob `59d0149f27dd8f6bcdf8334b89c07cc1f88917cf`: `validate_attempt()` devuelve `unknown_ball` para cualquier ID ausente antes de resolver; `resolve()` usa los dos adaptadores de multiplicadores y `BallEffects.on_catch()` en éxito. No inventar efectos en la UI.
5. `modules/inventory/capture_inventory_service.gd` blob `5898e23f3d935bd48df4a5f9e13c5b2cab7c852d`: validación previa, comprobación de propiedad y **una unidad reservada/consumida por intento válido**, con rollback defensivo. No hay que reconstruir este servicio para tres bolas nuevas.
6. `scenes/visual/capture_ball_picker.gd` blob `9e09fdbcd79f6f45ecbd411b4beb48477576c9a3`: consulta `CaptureRuleset.ordered_ball_ids()`, nombre/cantidad y habilitación; no gestiona multiplicadores. Después de registrar correctamente una bola, debe poder mostrarla sin lógica de interfaz por ID.
7. `modules/capture/capture_battle_context.gd` blob `0a1ac1e2710e3a1f370fd8443ba0efde6dba4533`: contexto incluye `is_wild`, `battle_finished`, dueño, bando, `completed_turns` y `catcher_level`; **no contiene tipos efectivos del objetivo, hora de batalla ni localización/cueva**.
8. `modules/creatures/domain/creature_instance.gd` blob `882f630845549700cacaa710b742bab986887e5c`: `friendship` sí se guarda en `to_dict()`/`from_dict()`, pero **no** el ID de bola de origen. `modules/inventory/field_friendship_effects.gd` blob `da010fd3baad787cd30249e39f767085bf556599`: `increase()` aplica la base y Campana Alivio, declara expresamente pendiente el origen/bonus de captura. `modules/inventory/battle_support_profile.json` blob `8137722e25bc9b087e5ff485b1e636766e7e5c3b` confirma ausencia de metadatos de origen y Lujo.
9. `modules/gameplay/wild_adventure_session.gd` blob `42b03a0435fd07915955fe9ecf7b8b7468c8c714`: `capture_current()` forma contexto real (turnos/activo), llama al servicio y deriva al dueño/PC mediante `CaptureOwnershipRouter`. `modules/gameplay/showdown_adventure_session.gd` blob `1542086a8c44c58eb41c7ca8c592a40b61d5abf1`: `capture()` prepara copia transaccional, comprueba revisión, devuelve inventario/RNG y publica al concluir; `snapshot()/restore_saved()` recupera el contexto de combate. Ambos necesitan datos fiables si se autoriza añadir Malla/Ocaso; la UI no es fuente de verdad.
10. `tests/gameplay/item_capture_v15.gd` blob `0d209e00ef2abc6ed998753c24847363420af7f9`: líneas 104–105 incluyen `net_ball` y `luxury_ball` en el conjunto de bolas **que deben permanecer deshabilitadas** durante V15. `dusk_ball` no figura en ese negativo concreto. Una futura habilitación requerirá actualizar la expectativa y crear escenarios nuevos, no simplemente eliminar la aserción.

**Comparación acotada con V28:** se consultaron de forma independiente en `codex/items-v28-from-main` los blobs de `capture_ruleset.gd`, `capture_system.gd`, `capture_ball_effects.gd`, `capture_context_ball_effects.gd`, `capture_ball_picker.gd` y `item_capture_v15.gd`: **todos conservan el mismo SHA de blob que W03**. Esto prueba identidad byte a byte de **esos archivos**, no equivalencia completa de los dos árboles ni verificación operativa de su combinación. `docs/current/ITEM_CAPTURE_V15.json` también coincide en blob (`0dd6aa2b3a6520412a33814935fe30876c1ee86c`).

## 3. Contrato funcional a cerrar ANTES de codificar

**Malla Ball / `net_ball`:** la [referencia Essentials fijada en el proyecto](https://github.com/Maruno17/pokemon-essentials/blob/8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b/Data/Scripts/011_Battle/007_Other%20battle%20code/010_Battle_PokeBallEffects.rb) usa ×3,5 si el objetivo es Agua **o** Bicho con `NEW_POKE_BALL_CATCH_RATES` (perfil moderno), y ×3 con perfil antiguo; si no, ×1. La comprobación de `pbHasType?` es del combatiente vivo; determinar y fijar si el motor puede exponer esos **tipos efectivos**, incluyendo alteraciones en combate, sin confiar en datos de la UI. Si tiene ambos tipos el bonus **no** se acumula dos veces. Efecto de captura exclusivamente; sin bonus de amistad posterior.

**Ocaso Ball / `dusk_ball`:** la misma referencia usa ×3 moderno / ×3,5 antiguo si `battle.time == 2` (noche **o** cueva), ×1 fuera. Determinar quién establece noche/cueva (mapa/encuentro, batalla y restauración) y qué significa «noche» en el juego; **no inventar hora real del dispositivo, clima o bioma** como sustitutos. Contexto ausente o incoherente: rechazar antes de consumir, en vez de conceder bonus arbitrario. No hay test histórico V15 de Ocaso por ID.

**Lujo Ball / `luxury_ball`:** captura normal ×1, sin efecto instantáneo equiparable a Amigo Ball; su función distintiva es modificar **ganancias futuras positivas de amistad del individuo capturado**. Su valor exacto/orden de aplicación según generación, Campana Alivio y límites de amistad requiere contrato aprobado. `friend_ball` fija amistad a 200 en éxito; **no reutilizar esa semántica** para Lujo. Guardar la bola de origen con integridad, migración explícita de partidas antiguas, no pérdida al mover equipo↔PC y aplicación en los caminos existentes de aumento de amistad. **Bloqueo de esquema/propiedad:** cambiar `CreatureInstance`, serialización/validadores y servicio de amistad sin permiso implicaría riesgo de regresiones compartidas con W02. No hacer todavía.

Las tres: permitir sólo combate salvaje válido contra objetivo capturable, no KO/no entrenador, propiedad de la bolsa, rechazo sin RNG/coste, lanzamiento válido fallido gasta una unidad y avanza la lógica del turno, éxito conserva identidad/IV/EV/PS/PP y enruta a equipo o PC, edición de estado solo tras publicación transaccional, revisiones obsoletas no duplican gastos, guardado/restauración y comprobación visual independientes. Ni catálogo ni datos comerciales garantizan disponibilidad inmediata.

## 4. Pruebas y su alcance REAL

### Inspección realizada AHORA (sin ejecutar Godot)

- **Chequeos estáticos sobre blobs leídos del W03:** (1) ninguno de los tres IDs en `CaptureRuleset`; (2) prueba negativa específica V15 de Malla y Lujo presente; (3) prueba negativa V15 de Ocaso **ausente**; (4) `CaptureBattleContext` sin hora/cueva/tipos efectivos; (5) `CreatureInstance` sin campo serializado de bola origen; (6) `field_friendship_effects.gd` sin rama de Lujo. Resultado de las seis inspecciones **coherente con el código leído**. Son comprobaciones **estáticas**, NO prueba de Godot.
- **Entorno de esta auditoría:** `command -v godot || command -v godot4 || command -v Godot` no devolvió binario; no hay checkout ejecutable ni assets importados bajo `/mnt/data`. **Sin ejecución local de Godot, tests de juego, GPU o CI en W03.** Clasificación: `SIN_EJECUTAR`. No se invocó workflow para un lote documental.
- **Evidencia HISTÓRICA V15 (NO reejecutada):** `docs/current/ITEM_CAPTURE_V15.md` y `ITEM_CAPTURE_V15.json` registran `python tools/verification/run_capture_v15.py`, grupo `new_balls` `PASS checks=51895 cases=17216 GPU=false`, y grupo `balls_gpu` `PASS checks=68 GPU=true` con Godot 4.7 en la máquina Windows original. Los 17.216 casos y cuatro rutas son para **Amigo, Safari, Competi, Gloria**, NO para las tres bolas de este encargo. Los negativos de Malla/Lujo forman parte del test histórico. Los logs locales `.godot/item_capture_v15/` no se han reproducido/descargado aquí. **Ningún PASS histórico puede citarse como PASS nuevo en W03 o V28 integrada.**
- **Identidad técnica**: `project.godot` blob `fb2e492f1333e495aedee6a4e2c3b23e6f862e26`, `config/features=PackedStringArray("4.7", "GL Compatibility")`.
- **Comandos existentes sugeridos para una fase posterior autorizada** (NO ejecutados): `python tools/verification/run_capture_v15.py` y, para el test acotado sin GPU desde la raíz con Godot 4.7 disponible, `godot --headless --path . --script tests/gameplay/item_capture_v15.gd`. El segundo sigue sin cubrir estos IDs hasta crear las expectativas nuevas. La coordinadora debe decidir el runner/gate consolidado y conservar el V15 original como regresión.

### Matriz mínima de pruebas nuevas propuesta (no implementada)

| ID | Positivos | Negativos críticos |
|---|---|---|
| `net_ball` | Agua, Bicho, ambos; cambio de tipos según contrato; captura real y PC | Ni Agua ni Bicho ×1; no doble bonus; tipo obsoleto, datos ausentes y entrenador no gastan |
| `dusk_ball` | Noche exterior y cueva de día, restauradas desde dueño del combate | Día exterior ×1; reloj/bioma ausente; contexto manipulado, turno/coste no alterados |
| `luxury_ball` | Captura ×1, guardar/cargar bola de origen, ganar amistad, equipo y PC, límites 255 | No bonus inmediato ni sobre criaturas capturadas con otra bola; fallo no marca origen; carga anterior no inventa Lujo |

Añadir para cada ID: RNG determinista, inventario 0/1/2, éxito/fallo, KO, PS/PP/estado, revisión obsoleta, entrenador, rival/otro dueño, repetición, almacenamiento lleno, guardado/carga pre y postcaptura, prueba de UI/GPU separada. No afirmar cobertura hasta ejecutar.

## 5. Duplicación, colisiones y propuesta para la árbitra IA6

- **Reutilizar**, sin clonar: `CaptureRuleset` → `CaptureSystem` → `CaptureInventoryService` → sesiones legado/nativa → `CaptureOwnershipRouter` → selector. Los adaptadores `capture_ball_effects.gd` / `capture_context_ball_effects.gd` contienen ya el patrón para reglas declarativas y postcaptura. Proponer registro/descriptor por ID y tabla de casos compartida; no nuevos scripts de lanzamiento independientes, ni fórmulas repetidas por escena.
- **Archivo compartido conflictivo con W02:** `modules/inventory/field_friendship_effects.gd` es empleado por bayas, vitaminas y entrenamientos; el tratamiento de Lujo no puede imponerse desde W03 sin asignar a un propietario único y resolver combinación con Campana Alivio. `modules/creatures/domain/creature_instance.gd` y save/restore son transversales a todas W. Reservar coordinación IA6 si procede alterar la serialización.
- **Otros puntos de titularidad exclusiva a asignar:** `modules/capture/capture_battle_context.gd`, ambas sesiones `wild_adventure_session.gd`/`showdown_adventure_session.gd`, `capture_ruleset.gd`, `capture_system.gd`, adaptadores, `tests/gameplay/item_capture_v15.gd` y nuevo test selectivo. V28 tiene cambios propios en subsistemas compartidos de batalla/progresión; rebasar sobre base certificada antes del primer código.
- **Conflicto de política AJENO al lote:** `beast_ball` aparece `SELECCIONADO` en catálogo nuevo, pero `docs/handoff/ITEMS_V28/START_HERE.md` (V28, líneas 22–25) documenta cancelación expresa y captura normal de Ultraentes. **CONFLICTO_POLITICA_ENTE_BALL** para IA6/usuario; aquí no se evaluó ni programó.
- **Prioridad recomendada al asignar siguiente lote, tras gate V28:** primero Malla (si tipos del objetivo están accesibles/contrastados); Ocaso solo tras fijar contexto de noche/cueva; Lujo después de una decisión expresa sobre origen persistente/compatibilidad de guardados y propiedad del subsistema amistad. El orden es propuesta, **no autorización de desarrollo**.

## 6. Inventario de cambios y autocontrol

- **Archivo editado:** exclusivamente `docs/coordination/items_parallel_v1/reports/W03/LOTE_001.md` de `codex/calvo-items-20261101-w03` (marca inicial reemplazada por este informe).
- **Archivos que habría que modificar para conectar efectos, pero NO modificados:** todos los módulos de captura, `CreatureInstance`, amistad, sesiones, tests, scripts, datos, configuración y UI enumerados arriba.
- **Modificaciones reales en producción / tests / selección / datasets / guardados:** **0**.
- **Pruebas ejecutadas de Godot, GitHub Actions, GPU:** **0 — SIN_EJECUTAR**. Inspección estática **sí realizada** con hashes y símbolos anteriores.
- **Alcance:** exactamente tres IDs `luxury_ball`, `net_ball`, `dusk_ball`; `beast_ball` solo se cita como dependencia política, fuera del trabajo.
- **Autocontrol:** no modifiqué `main`, V28, árbitra, otras trabajadoras, `config/item_selection_v1.json`, CSV maestro, cola, código de producción, tests, arte ni partidas; no ejecuté `merge` ni `rebase`. Esta rama conserva su base original más el informe.
- **Entrega:** `LISTA_PARA_REVISION`. **No iniciar LOTE_002 sin nuevo documento de IA6**.
