# W03 / LOTE_002 — caracterización de Net Ball, sin producción

**Estado: LISTA_PARA_REVISION** · **IA3/W03** · 2026-11-01. **Importante:** no hay PASS funcional nuevo ni prueba Godot ejecutada.

## 1. Autoridad y sincronización

- Asignación: [LOTE_002_W03.md](../../assignments/LOTE_002_W03.md) de la rama árbitra, blob **`27cf744ac6a8cf15ca9c1c5413c197dedc11ad12`**.
- Protocolo: `NOTEBOOK_PROTOCOL_V1.md`, blob `4fac0eba28ea30dc6d3a3bd749699874cf446e66`.
- Rama exclusiva: `codex/calvo-items-20261101-w03`; LOTE_001 original [aceptado](./LOTE_001.md), commit `c84a0f9cd5e1890038eb2e085fa2304e2e001cd2`, blob **`2ef030e9a70bf0102849dc7e65e700e07b195c53`**.
- Checkpoint autorizado `38188cc208e67b19002437ac75160898ce332ec2`, presente en la rama árbitra `9fc2a303ce17c91a48b2c6189cbcfc281b3d92c3` como ancestro directo (comparación: 1 commit delante/0 detrás).
- **Merge no destructivo publicado solo en W03:** commit **`84247bdee5b70a445f163b6b6a1c870a05672661`**, padres `c84a0f9...` (W03) y `9fc2a303...` (árbitra). Árbol base árbitra + **el mismo blob LOTE_001**; avance de rama sin `force` y con SHA esperado. No hubo colisiones de rutas (el diff propio frente árbitra consistía únicamente en el informe W03).
- Comprobación posterior en W03: presentes `tools/item_audit/automation_v28.py` (blob `ae181662b315f033172a5cfef4a87961088fe8fd`), `docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv` (blob `8b9b723bf5944bbbde39aa2d49dfbb2f2a64e11b`) y `NOTEBOOK_PROTOCOL_V1.md`; informe LOTE_001 idéntico. **La base combinada sigue SIN CI verificada**.

## 2. Alcance y entregables autorizados

| Ruta propia | Tipo | Commit de creación | Blob inspeccionado |
|---|---|---|---|
| `tests/gameplay/parallel_items_w03_capture_net_v1.gd` | Caracterización Godot 4.7 | `af07415f9e5ea826e29b2c635937ca7c0de82c82` | `a65f67964b11c830e035cb981ad252716ec53b9b` |
| `tests/tools/test_parallel_items_w03_capture_v1.py` | Validador estático, biblioteca estándar | `6060994523160fc2436e77ecedbd3a80fa50739a` | `39ba90337ba24c9dba9fc5f397aba7fe477f636c` |
| `docs/coordination/items_parallel_v1/reports/W03/LOTE_002.md` | Informe (este archivo) | Ver historial de GitHub | — |
| `docs/coordination/items_parallel_v1/reports/W03/CONTINUIDAD.md` | Cuaderno mutable del relevo | Ver historial de GitHub | — |

**Cambios de producción/configuración/CI/guardados/datasets/tests ajenos: 0.** No se ejecutaron workflows. Lujo y Ocaso siguen exclusivamente como dependencias documentadas. Ente Ball, fuera del lote.

## 3. Hallazgos técnicos con fuente concreta

- `modules/creatures/domain/creature_species.gd` (`590b963a85929ff9d8c82a3590d05e28fe178cd7`) **expone** `type_ids_resolved()` y `has_type()`: los tipos canónicos de especie están disponibles. El test caracteriza la ruta de encuentros reales con Magikarp (Agua), Caterpie (Bicho) y Pidgey (control Normal), usando `WildAdventureSession.begin_encounter()` y `current_wild()`.
- `modules/capture/capture_system.gd` (`59d0149f27dd8f6bcdf8334b89c07cc1f88917cf`) **recupera** `species` con `catalogs.species_catalog.get_by_id(target.base_species_id())` y aplica `BallEffects.multiplier()` y `ContextBallEffects.multiplier()`. Por tanto **la especie sí está disponible en la función de captura**, pero en el código inspeccionado no se usa `has_type()` para `net_ball`.
- `modules/capture/capture_battle_context.gd` (`0a1ac1e2710e3a1f370fd8443ba0efde6dba4533`) tiene turnos/nivel/propiedad, **no datos expresos de tipo efectivo en combate**. La especie basal disponible puede ser insuficiente para transformaciones y alteraciones temporales de tipo. **SOLICITUD_IA6:** decidir si el contrato admite tipos de especie o exige los tipos del objetivo tras cambios en combate; asignar fuente confiable antes de habilitar Net.
- `modules/capture/capture_ruleset.gd` (`aaa848d77ff31349dae9720be001ff31658f55a9`) y `capture_ball_effects.gd` (`684645648c654030b482d6b945055c5ed42bda7e`) **no registran** `net_ball`. `tests/gameplay/item_capture_v15.gd` (`0d209e00ef2abc6ed998753c24847363420af7f9`) contiene un negativo histórico que exige que Net/Lujo no estén habilitadas. **Este lote no cambia esas pruebas.**
- `modules/inventory/capture_inventory_service.gd` (`5898e23f3d935bd48df4a5f9e13c5b2cab7c852d`) ya implementa validación/propiedad/reserva/consumo/rollback; no introducir otro puente.
- Regla externa de referencia ya fijada por el proyecto (Pokémon Essentials `8c5911e4...`, `010_Battle_PokeBallEffects.rb`): Malla usa **×3,5** moderno si el objetivo es Agua **o** Bicho, en otro caso ×1; doble tipo no significa ×7. El test compara la probabilidad del **CaptureInventoryService real** frente al contrato externo **solo si** un cambio futuro hace conocida a Malla; nunca inyecta un multiplicador en producción.

## 4. Qué contienen las pruebas nuevas (no confundir escrito con ejecutado)

### Godot — `parallel_items_w03_capture_net_v1.gd`

Reutiliza `item_capture_v11.gd` y `GameData` (catálogo real), sin nuevo motor ni fixtures alteradas.

1. **Tipos:** encuentros vivos de Magikarp, Caterpie y Pidgey; verifica catálogo por `has_type()` y posibilidad de captura estándar con el objetivo real.
2. **Estado bloqueado controlado:** para cada especie, si Net sigue fuera del registro, se comprueba `unknown_ball`, ningún consumo, ninguna tirada RNG ni mutación del objetivo. Resultado semántico `BLOQUEADO_NET_BALL_NO_REGISTRADA`; **no se etiqueta como implementación PASS**.
3. **Preparado para activación futura:** cuando `CaptureRuleset` reconozca Net, compara las probabilidades reales de tres tipos con factores esperados 3,5/3,5/1 y exige una unidad por intento válido. Invocación opcional `--require-net` ofrece un **rojo explícito** mientras no esté conectada.
4. **Control positivo existente:** Poké Ball normal con semilla elegida de forma determinista para un fallo válido, RNG de una tirada, consumo de una unidad y conservación del equipo.
5. **Controles negativos:** captura de entrenador y Net desconocida no consumen ni alteran RNG/inventario; propietario y cantidad se verifican mediante `CaptureInventoryService`.
6. **Persistencia:** `SaveGameRepository.save_collection()/load()` después del gasto del control; captura exitosa con Master Ball y equipo lleno, enrutamiento al PC mediante `CaptureOwnershipRouter`, guardar/cargar conserva identidad, cantidades y destino. Los ficheros temporales son `user://` y se eliminan al finalizar.

**Límite deliberado:** esto es una *caracterización* del camino actual, no una prueba que ya active Net. No se certifican alteraciones dinámicas de tipos ni UI/GPU. No modifica `calvo_capture_v1`.

### Python — `test_parallel_items_w03_capture_v1.py`

Seis pruebas unitarias de **contrato estático**: `CreatureSpecies.has_type`, recuperación de especie y adaptadores, frontera de consumo/rollback, selección de catálogo separada de integración, escenarios requeridos en el test Godot y ausencia actual de tipos efectivos en `CaptureBattleContext`. Informa `STATIC_CONTRACT_PASS ... NO_ES_PASS_FUNCIONAL` solo si se ejecuta y supera el test. No instala módulos externos, no ejecuta Godot ni cambia archivos.

## 5. Ejecución y evidencia honesta

| Comprobación | Comando reproducible desde raíz | Estado en W03 |
|---|---|---|
| Validador Python | `python tests/tools/test_parallel_items_w03_capture_v1.py` | **SIN_EJECUTAR** en checkout completo; source revisado, falta checkout accesible en runtime |
| Godot headless | `godot --headless --path . --script tests/gameplay/parallel_items_w03_capture_net_v1.gd` | **SIN_EJECUTAR / PENDIENTE_CI** |
| Rojo exigente de Net (solo cuando IA6 lo decida) | `godot --headless --path . --script tests/gameplay/parallel_items_w03_capture_net_v1.gd -- --require-net` | **SIN_EJECUTAR**, esperado FAIL mientras Net no esté registrada |
| GPU/visual y prueba de entorno de noche | Godot 4.7 en Windows/juego | **NO REALIZADA / no corresponde a Net** |

**Limitación real del entorno:** comprobado que no hay ejecutable `godot`/`godot4` ni checkout completo en el contenedor; `git ls-remote` del repositorio falló por resolución DNS. La consulta GitHub conectada sí permitió leer/crear/confirmar blobs y commits. **NO se afirman PASS locales de Python/Godot**, ni CI de la base `38188cc`.

**PASS HISTÓRICO ÚNICAMENTE:** `docs/current/ITEM_CAPTURE_V15.json` (blob `0dd6aa2b3a6520412a33814935fe30876c1ee86c`) registra `python tools/verification/run_capture_v15.py`, `ITEM_CAPTURE_V15 PASS checks=51895 cases=17216 GPU=false` y 68 checks GPU para cuatro bolas **distintas** (Amigo/Safari/Competi/Gloria). **No verifica Malla ni la fusión nueva**. Registros V28 de otros objetos no sustituyen este PASS pendiente.

## 6. Dependencias y propuestas a IA6

- **SOLICITUD_IA6 — contrato Net:** escoger y documentar si tipos de especie `CreatureSpecies.has_type()` son suficientes o si deben obtenerse tipos efectivos del objetivo en el estado nativo/legado. Si es lo segundo, asignar propietario exclusivo a la frontera de contexto de captura y sesiones; nunca copiar datos de la vista.
- **SOLICITUD_IA6 — test V15 histórico:** una futura conexión de Net requerirá alterar su negativo `unknown_ball` de forma controlada y preservar una regresión de las demás bolas. No modificarlo sin permiso.
- **SOLICITUD_IA6 — validación:** incorporar **un solo pase** de Python + test Godot W03 al CI consolidado tras revisar los cinco lotes y la base combinada. En el informe de CI registrar SHA, exit code, logs, estado bloqueado y rutas de tipo. Una salida exitosa `CARACTERIZACION_PASS` no debe computarse como `FUNCION_Y_PRUEBA` de Net.
- `luxury_ball`: continúa dependiente del origen de captura persistente/amistad y coordinación W02; `dusk_ball`: contexto noche/cueva no fijado; `beast_ball`: conflicto de política V28/catálogo. **No se tocaron**.

## 7. Autocontrol y entrega

- Escrituras exclusivamente dentro de las **cuatro rutas** autorizadas por `LOTE_002_W03`.
- LOTE_001 conservado como archivo/commit/blobs históricos; `main`, V28, árbitra y otras W no modificadas.
- Sin cambios `modules/`, `scenes/`, `config/`, `data/`, `assets/`, `docs/current/`, `docs/handoff/`, `.github/` ni tests V27/V28 existentes.
- No hay implementación de nuevas bolas, migraciones ni modificación de balance.
- **Estado final: LISTA_PARA_REVISION, PENDIENTE_CI.** No iniciar LOTE_003 hasta orden expresa de IA6.
