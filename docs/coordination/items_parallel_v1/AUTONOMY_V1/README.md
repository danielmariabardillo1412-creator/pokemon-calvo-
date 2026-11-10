# IA6 — PROTOCOLO PERMANENTE DE TANDAS AUTÓNOMAS V1
Fecha de emisión: 2026-11-10. Autoridad: IA6, árbitra de Pokémon Calvo.

## Propósito y disparador
Sustituye los permisos nuevos por cada objeto, piloto o `p`. Las cinco trabajadoras operan con una **orden de lote de hasta 10 microbloques** y entregan **un solo paquete de cierre a IA6**. Un mensaje del usuario `p`, `sigue` o `continúa` significa: leer la orden estable `docs/coordination/items_parallel_v1/IA6_AUTORUN.md` en **tu propia rama**, y avanzar por la tanda autorizada hasta agotarla **dentro de lo que permitan las herramientas y el turno actual**. No hace falta permiso nuevo para el siguiente subbloque de la MISMA tanda.

No existe ejecución en segundo plano garantizada entre mensajes: si el turno o herramienta se corta, publicar checkpoint en GitHub y reanudar con el siguiente `p`, sin pedir otra autorización. Las notas de GitHub no envían mensajes automáticamente a otras ventanas; cada trabajadora debe conocer una vez esta ruta estable.

## Fuente de verdad y propiedad
1. Este protocolo V1 y `QUEUE_W01.md` ... `QUEUE_W05.md` en la rama `codex/calvo-items-20261101-arbitro` son **órdenes emitidas**. Una copia actualizada de la cola aplicable vive en `docs/coordination/items_parallel_v1/IA6_AUTORUN.md` de cada rama de trabajadora.
2. La trabajadora escribe código solo en **su rama exclusiva**, registra progresos en `docs/coordination/items_parallel_v1/reports/W0X/AUTORUN_V1_PROGRESS.csv`, y al terminar `AUTORUN_V1_FINAL.md`, con commit + CI + permisos respetados. IA6 actualiza la cola en GitHub **solo tras recibir aviso de lote cerrado**. Nunca inventar aprobación de la IA6 futura.
3. Prioridad del contrato: sistema/usuario > restricciones de seguridad y archivos protegidos > este protocolo V1 y cola de trabajador > instrucciones históricas de STOP/piloto individual. Este protocolo **revoca solo la obligación de pedir permiso por cada siguiente bloque ya incluido**, no las protecciones de main, los datos ni los permisos de edición.
4. Cada tanda incluye 10 filas. `CERTIFICADO` exige efectos positivos reales y CI correspondiente; `BLOQUEADO`, `DIFERIDO` y `NO_APLICA` son salidas válidas, pero **no suman mecánicas/objetos funcionales**. No convertir “10 filas examinadas” en “10 objetos implementados”.
5. Una tanda no implica merge, despliegue ni obligación de reparar globalmente todas las dependencias.

## Motor de autonomía — obligatorio
A. Al recibir `p/sigue`: leer nota actual de su rama y estado CI/HEAD de GitHub. No volver a repetir una fila ya certificada. Empezar en la primera fila `PENDIENTE`. Correr subbloques consecutivos **sin parar a preguntar a IA6** si todos respetan sus límites.
B. Cada subbloque: verificar IDs reales en catálogo y política, trazar efecto de producción, probar positivo, negativo, propietario/consumo/rollback, SaveV2 cuando proceda. Documentar nivel L1 (dato), L2 (motor), L3 (mochila/mundo/guardado). Mantener tests anteriores y usar CI real con SHA. Después registrar en CSV un estado por fila. En respuesta breve incluir barra `[████░░░░░░] 4/10` de filas examinadas y **`funcionales X/10`** por separado.
C. Si una fila depende de productor compartido ausente, política no decidida, ID excluido, otra rama o recurso visual/GPU: documentar **un único ticket claro** con interfaz esperada y prueba roja o reproducción; marcar `BLOQUEADO` sin crédito; **pasar a la siguiente fila independiente**. Si tres filas consecutivas son variantes del mismo bloqueo, saltar esa familia y concentrarse en otra independencia prevista, sin fabricar casos negativos equivalentes.
D. Si CI falla por un bug reparable en los archivos **propios autorizados**, investigar y reparar autónomamente, sin pedir permiso, hasta 3 iteraciones razonables. Si requiere tocar archivo protegido o quitar una aserción histórica, usar la política de migración de tests versionados (más abajo) o marcar `BLOQUEADO` y seguir. Para seguir con base verde, revertir/aislar el experimento fallido, conservar diff/ticket y usar el último estado válido. Nunca falsificar un PASS, saltar job con `continue-on-error`, ni presentar la ejecución de otra SHA como actual.
E. Al alcanzar las 10 filas: ejecutar CI **final** desde el HEAD propio, generar manifiesto de 10 filas y resumen de PASS/BLOQUEADO, hashes, logs y archivos editados. Publicar `AUTORUN_V1_FINAL.md`. **STOP y entregar solo entonces el aviso a IA6**. Antes de tener otra cola publicada, no inventar filas 11+.
F. No escribir a otra IA ni en su rama; no interactuar automáticamente con sus ventanas. El usuario solo actúa como activador y transmite aviso de cierre, no como intermediario técnico bloque a bloque.

## Política permanente: promoción de dependencias históricas
Al activar un objeto antes marcado `DEPENDENCY_MISSING`/sin efecto, es NORMAL que un runner histórico negativo se vuelva incompatible. **No significa que el efecto nuevo sea incorrecto**, pero tampoco se puede declarar CI verde artificialmente:
1. Mantener **intacto** el fixture histórico y su SHA de cierre; comprobarlo en revisión congelada para trazabilidad. Prohibido reescribir la historia como si siempre hubiera sido funcional.
2. En el HEAD actual probar **todos los casos históricamente no afectados** con la misma exigencia y los objetos ahora promovidos con pruebas positivas nuevas de estado/consumo/SaveV2. Se puede introducir un modo de migración **con whitelist explícita de IDs promovidos** en el runner, registrar exactamente cada caso sustituido y su aserción positiva equivalente. Sin skips genéricos, no `|| true`, no tests silenciados.
3. La CI actual solo queda certificada cuando ambas puertas —archivo congelado y pruebas de HEAD, incluidos casos convertidos— pasan. Si no, estado `PARCIAL` y continuar otras tareas independientes. Esta regla queda preautorizada para todas las cinco trabajadoras; no pedir puerta específica cada vez.

## Matriz de edición / controles cruzados
- W01: objetos equipados y pruebas del backend de combate SOLO en seam local asociado al objeto y CI propia. Cambios al motor nativo fuera de esa ruta o reglamento global son protegidos IA6.
- W02: `field_mint_effects.gd`, tests/fixtures/W02 y workflow propio; se permite adaptar validadores históricos exclusivamente por whitelist de promoción según regla anterior. `CreatureInstance`, StatCalculator, FieldGrowth/Mochi y SaveV2 central protegidos IA6.
- W03: módulos/adaptadores propios del campo/captura y **seams específicos previamente autorizados** de `field_demo.gd`, `field_native_bridge.gd`, `FieldItemBag` para repelentes ya certificados. Otros cambios compartidos requieren ticket, pero esto **no detiene** el resto de su cola.
- W04: resolvers y tests propios de evolución, metadata canónica de solo lectura; no modificar sexo/forma persistentes de `CreatureInstance`, SaveV2, productor de reloj/luna/giro, política V27 o reglas globales sin autorización IA6. Seguir familias independientes tras bloqueos.
- W05: `field_machine_book_panel.gd`, tests/fixtures/W05 y workflow propio, uso de `FieldItemService.teach`; `FieldItemBag` es integración final de IA6, no la edita W05.
- IA6 es propietaria de la versión **integrada** de `FieldItemBag`, `field_native_save.gd`, la política EXP Share/participación real, calendario/sexo/forma y merges selectivos. **Prohibido tocar `main`, V28 y PR #118**.
- Si IA6 publica una orden nueva en README o cola específica, esa nueva versión gobierna desde el próximo `p`, manteniendo progreso ya validado.

## Protocolo de cierre (reducir contexto)
Un único texto breve para usuario/IA6 con: `W0X TANDA 01 TERMINADA — 10/10 examinados — N funcionales — N bloqueados — SHA — CI final resultado — informe GitHub`. IA6 recupera evidencias directamente de GitHub, no requiere pegar logs kilométricos. Un `FAIL` real debe figurar como `FAIL` y tampoco fuerza parón por un bloqueo ajeno mientras quedan filas independientes.
