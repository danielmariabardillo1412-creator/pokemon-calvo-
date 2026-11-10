# IA6 · W05 — MODO CAMPAÑA CONTINUA V2 ACTIVADO

**ORDEN PERMANENTE: YA NO SE PARA POR 10/10.** Esta orden sustituye la obligación `STOP al cerrar TANDA X` de la versión anterior, sin derogar permisos técnicos ni pruebas. Identifícate como W05, utiliza SOLO la rama `codex/calvo-items-20261109-w05-books-ui`. El plan de trabajo completo se copia abajo y tiene varios bloques; **cuando uno termina con CI, pasa directamente al siguiente bloque del MISMO plan SIN PEDIR IA6**.

Con cada `p` o `sigue`: (1) consulta tu HEAD y esta nota; (2) lee o crea `docs/coordination/items_parallel_v1/CONTINUOUS_V2/STATE_W05.md` de TU RAMA; (3) continúa la primera tarea pendiente de toda la CAMPAÑA, no solo de la última tanda; (4) trabaja secuencialmente mientras el turno lo permita, registrando checkpoints cada 10. Si el contexto se agota, publica estado y una próxima `p` reanuda desde GitHub. **No te quedes diciendo «esperando tanda siguiente» si quedan fases preautorizadas en este plan.**

**Protocolo IA6 V2 (prioritario):** rama árbitra `codex/calvo-items-20261101-arbitro`, `docs/coordination/items_parallel_v1/CONTINUOUS_V2/README.md`. **Plan central y único:** `docs/coordination/items_parallel_v1/CONTINUOUS_V2/PLAN_W05.md` en árbitra (copia íntegra abajo). Si en el futuro IA6 actualiza este mismo archivo con una misión más reciente, leer siempre HEAD y respetar la última versión.

**Control de seguridad:** no autoautorizar módulos protegidos, no fusionar ramas, no editar main/V28/PR118, no mover trabajo de otra W. No atribuir a IA6 integración no realizada. Si toda la misión termina o el resto exige exclusivamente una seam compartida, publicar `READY_FOR_IA6` y detenerse; no crear bucles de QA vacíos. Si hay más tareas independientes, continuar sin esperar. **Una `p` no mantiene ejecución asíncrona ni abre otra conversación automáticamente.**

**Contabilidad en cada respuesta:** `CAMPAÑA fase | bloque n/total | objetos nuevos | ya certificados | L3 verdaderos | bloqueados | CI SHA | integración IA6 pendiente`. Un 10/10 de bloque no es 100% de campaña.

---

# W05 — CAMPAÑA CONTINUA V2 · LIBROS MT Y PREPARACIÓN DE INTEGRACIÓN
**Rama:** `codex/calvo-items-20261109-w05-books-ui`.
**Baseline:** 229/229 libros SV enseñables en panel propio, 229 ES verificadas fuente PokeAPI, PCK Windows con traducción real, CI TANDA05 #42923848244 / #42924399433 SUCCESS. **No quedan MT activas SV nuevas por implementar en esta cola**. Lo pendiente principal es montaje final dentro de `FieldItemBag` integrado por IA6.

## Tres etapas encadenadas SIN STOP cada diez
**B01 — Interfaz verificable:** pruebas de integración del panel propio con servicio real usando `bind_existing_service`, `select_book`, `select_creature`, `select_replacement_slot`, `teaching_finished`; 229 IDs, PP, propietario, Party/Storage, selección caducada, bloqueos, señales duplicadas, consumo/rollback y SaveV2. Reutilizar fixtures parametrizados para no generar 229 escenas o checks duplicados inútiles. Si ya están certificadas, registrar SHA sin repetir.
**B02 — Paquete/evidencias:** archivos incluidos en Windows PCK, helper `MachineMovesEsSvW05` y etiquetas ES/legacy fallback, rendimiento básico sin inventar FPS GPU, size budget para EXE 635 MB (recuento de recursos sin cambiar preset sin prueba). Una captura de PCK headless no es una prueba visual Windows. Android solo documento de dependencia porque NO hay preset certificado.
**B03 — Contrato de integración IA6:** generar **test de aceptación del montaje** que IA6 pueda ejecutar en su rama: panel dentro de mochila real, selección de libro desde inventario, un aprendizaje que descuente exactamente uno, cambio de propietario, SaveV2, coexistencia con Cuerda Huida y repelente W03. Puede ser prueba roja aislada o demostración con adaptador mock, pero **no editar ni incorporar `FieldItemBag`** desde W05. Enumerar diff mínimo, rutas exactas y prueba esperada; adjuntar SHA/test/CI. Publicar `READY_FOR_IA6` al terminar.

**No crear TANDAS 06,07... para repetir 229 enseñanzas sin cambios.** La campaña termina cuando se entregan estas tres etapas y el contrato IA6, aunque sea antes de agotar el turno. Queda explícitamente vedado tocar `FieldItemBag`, `FieldItemService`, `SaveV2`, catálogos/PokeAPI, `SpanishGameText` global, ramas de otras W, main/V28/PR118. Se permite trabajo en tests/helpers/CI propios y `field_machine_book_panel.gd` solo ante bug reproducido de UI aislada, con regresiones. No se permite integración compartida autónoma.


