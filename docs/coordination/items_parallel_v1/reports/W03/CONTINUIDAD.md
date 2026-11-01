# W03 / IA3 — CUADERNO DE CONTINUIDAD (captura)

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
