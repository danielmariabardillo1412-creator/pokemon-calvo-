# IA6 — PROTOCOLO V2: CAMPAÑAS CONTINUAS, NO STOP CADA DIEZ
Emisión: 2026-11-11. Aplicable a IA1/W01–IA5/W05 **desde la nota activa de su propia rama**.

## Cambio vinculante
**REVOCA SOLO EL STOP al terminar cada bloque de 10** en AUTONOMY_V1/README.md, WORKER.md y colas históricas. NO revoca protecciones de archivos, políticas Randomlock, CI, SHA, integridad SaveV2, ni autorizaciones específicas. La unidad operativa ahora es una **CAMPAÑA COMPLETA**, con **varios bloques de hasta diez**. Cerrado un bloque con CI real, continuar **automáticamente** al siguiente bloque preautorizado del MISMO plan; no pedir a IA6 nueva tanda, no quedarse aguardando al usuario salvo límite de turno. Al alcanzar el final del plan, no inventar otro backlog.

## Instrucción de ejecución para cada `p` / `sigue`
1. Recuperar identidad W0X, rama propia y archivo `docs/coordination/items_parallel_v1/IA6_AUTORUN.md`; leer `CONTINUOUS_V2/PLAN_W0X.md` **copiado en la nota activa** y `CONTINUOUS_V2/STATE_W0X.md` o checkpoint equivalente de su propia rama.
2. Elegir **el primer ID/hito NO CERRADO de todos los bloques** de la campaña. No reiniciar el bloque 01 ni atribuir QA histórica a nuevos objetos. Si un bloque tiene 10/10, pasar inmediatamente al siguiente bloque de la misma campaña **SIN consultar IA6**.
3. Ejecutar en orden: ID y política real → prueba positiva de producción L2/L3 → negativos/propiedad/stock/rollback/SaveV2 → regresiones acumulativas → CI con SHA de código, `completed/success`. Si la suite CI dura más que el turno, publicar checkpoint, recuperar resultado en siguiente `p`.
4. Al completar cada bloque: escribir progreso y recibos en rama propia; **no hacer STOP ni exigir publicación IA6**. Continuar por el siguiente bloque; si el turno o contexto se agota, dejar checkpoint y terminar la respuesta. Un siguiente `p` retoma automáticamente.
5. Un ID `YA_CERTIFICADO` con evidencia SHA+test y no cambiado no suma objeto nuevo ni justifica repetir pruebas costosas; uno `BLOQUEADO` debe describir productor/API/archivo responsable y se salta hacia otra tarea independiente. No transformar diez negativos del mismo productor en diez funcionalidades.
6. Reparaciones autónomas SOLO en rutas/funciones aprobadas por el plan y antiguas autorizaciones. Si hace falta clase compartida nueva, IA6 integrará o emitirá permiso: **crear ticket y avanzar**. Prohibido fusionar ramas, tocar `main`, V28, PR118, bajar checks, saltar regresiones, inventar fuentes/curvas o afirmar CI de SHA diferente.
7. **Parada válida** solamente cuando: (a) se agotó toda la campaña y no quedan filas independientes útiles; (b) la totalidad del trabajo restante requiere una decisión/permiso compartido de IA6; (c) hay fallo crítico de seguridad/integridad que impide recuperar un HEAD verde; (d) el turno o la ventana llegó al límite de ejecución. En (d) no se necesita nueva tarea: solo `p`/relevo a ventana nueva.

## Estado persistente y cambio de ventana sin pérdida de contexto
Archivo estable por W: `docs/coordination/items_parallel_v1/CONTINUOUS_V2/STATE_W0X.md` en **su propia rama**. Crear si falta y actualizar en cada checkpoint. Mínimo: `branch`, `mission_version`, `phase`, `block`, `next_id`, `checked/functional/new/blocked`, `last_green_code_sha`, `last_green_run_id`, `ci_pending`, `owned_files_changed`, `protected_tickets`, `next_safe_action`. Al cambiar de conversación basta UNA instrucción de arranque para recuperar rama, nota y STATE; no copiar conversaciones largas ni confiar en memoria de ChatGPT.
**Límite honesto:** las ventanas no comparten ejecución/contexto vivo automáticamente, GitHub NO las despierta, y ChatGPT no sigue trabajando indefinidamente en segundo plano ni puede autoabrir otra ventana. Una `p` inicia el turno y el agente puede completar **varios bloques** mientras el turno lo permita; la próxima `p` continúa si hizo checkpoint. Ningún prompt evita límites físicos de contexto/turno.

## Contabilidad de resultados obligatoria
`CAMPAÑA: fase X/Y | BLOQUE n/total | HITOS revisados A | OBJETOS NUEVOS N | OBJETOS YA CERTIFICADOS C | QA Q | BLOQUEADOS B | L3 real L | INTEGRACIÓN IA6 NO/SÍ(con SHA)`.
El "10/10" se refiere exclusivamente al bloque. No se publican 100% de campaña hasta procesar el backlog completo y acreditar CI/reporte final.
CI de trabajador certifica **solo su rama**. La rama integrada `codex/calvo-ia6-integration-20261109` pertenece a IA6 y exige integración selectiva y pruebas cruzadas propias. No inventar su estado.

## Límites de autonomía y antitrabajo ficticio
Cada PLAN_W0X define dominio, orden, IDs verificables y archivos permitidos. No se autoriza recorrer ciegamente todos los `holdable_ids` (631 incluyen objetos de evolución, balls, berries, formas, excluidos). No se autoriza sustituir una familia bloqueada por otra sin relación ni inventar un plan ilimitado. Al agotar una lista o detectar que queda exclusivamente integración central, marcar `READY_FOR_IA6` y STOP; eso es preferible a llenar el contexto de pruebas redundantes.
