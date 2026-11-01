# PROTOCOLO OPERARIOS W01–W05 — trabajar de tres en tres sin pérdida de contexto

**Tu rol es uno solo, W01/W02/W03/W04/W05.** No eres la coordinadora. Tienes **una rama exclusiva**. No inicies una misión al abrir el chat sin que exista un `assignments/LOTE_NNN_W0X.md` **publicado en la rama de la árbitra** y entregado por el usuario. Tu trabajo no afecta a otras conversaciones automáticamente.

## Leer primero

1. `docs/coordination/items_parallel_v1/START_HERE.md`.
2. `docs/coordination/items_parallel_v1/WORKER.md` (este protocolo).
3. `AGENTS.md`, `docs/current/ITEM_SYSTEM_CURRENT_STATUS.json`, `docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`.
4. El **encargo exacto de tu lote** desde la rama `codex/calvo-items-20261101-arbitro`.
5. Código, pruebas y reportes actuales de los IDs concretos asignados. No cargar documentación histórica que no afecte al lote.

## Reglas absolutas

- Escribir exclusivamente en tu rama `codex/calvo-items-20261101-w0X`. Leer ramas ajenas solo para conocer estado; **no modificar** árbitra, otras W, `main`, V28, catálogos canónicos, guardados ni selección activa.
- La cola y las asignaciones son de la **árbitra**. No marcar en `QUEUE_V1.csv` un ID como asignado/completado; manda informe para que la árbitra lo actualice.
- **Solo los 1–3 IDs de tu encargo** o lote de familia excepcional expresamente autorizado. No añadir a escondidas objetos nuevos por detectar vecinos. Si ya están implementados, conservar, probar y notificar; **no rehacer**.
- No crear funciones objeto a objeto si una sola tabla o adaptador por familia resuelve el mismo problema. No parchear arquitectura central ni tocar las fuentes originales o módulos protegidos para salvar una prueba.
- La interfaz y documentación para usuario deben estar en español; preservar APIs y convenciones existentes, nombres de funciones públicas, compatibilidad con Godot 4.7 y paquetes congelados.
- Solo importar técnicas y datos de fuentes con licencia compatible y atribución documentada. No copiar recursos de juegos comerciales sin autorización.
- Un objeto `DESCARTAR` en el catálogo nuevo **puede seguir conectado en la versión actual** y no debes desconectarlo. No tocar Z de estado; Mega universal queda en fase posterior. Objetos evolutivos originales se conservan aunque se elimine el intercambio.
- No inventar tests que no existen, no alterar pruebas para hacer que pasen, no reetiquetar una verificación del 31 de octubre como comprobación de hoy.

## Método de trabajo dentro de tu lote

1. **Reconstruir la evidencia:** inspeccionar CSV, conexiones, importador, escena UI, pruebas de la versión exacta, confirmando estado de cada ID: implementado/cubierto, parcial, pendiente, bloqueado. Registrar cuál prueba demuestra cada punto.
2. **Contrato funcional mínimo:** especificar efecto, condiciones, propiedad del Pokémon, consumo/no consumo, persistencia, batalla vs campo, límites de balance, fuente normativa, casos negativos. Si existe en el repositorio y ya está probado, no reimplementarlo.
3. **Producir cambio mínimo:** familia compartida cuando sea posible. No modificar archivos fuera del encargo. Si el archivo que necesitas está reservado a otra W, no escribir: documentar bloqueo para la árbitra.
4. **Pruebas:** usar comando real reproducible, preferir pruebas selectivas de la familia; si es necesario ejecutar Godot, usar runtime disponible/Actions, capturar logs. Si no hay ejecución, estado `NO_PROBADO`; analizar de forma estática no equivale a prueba. Diferenciar PASS de lógica del PASS visual/GPU.
5. **Guardados/regresiones:** intentar uso normal, abuso, cantidad cero, KO, PS/PP/estados, efecto ajeno, rival, sincronización, carga y coste de un solo uso según aplique. Si no aplica, justificar.
6. **Commit y reporte:** guardar cambios aislados en tu rama. Informar al usuario de la URL, ID del lote, commit SHA, comprobaciones y pruebas que no pudiste ejecutar.
7. **Pedir revisión:** dejar la tarea `LISTA_PARA_REVISION` sin asumir integración. La árbitra hará review e integrará si corresponde. No tomar un nuevo lote por tu cuenta.

## Formato exacto de reporte

Ruta exclusiva `docs/coordination/items_parallel_v1/reports/W0X/LOTE_NNN.md`:

```md
# W0X / LOTE_NNN — informe de entrega
Encargo original: enlace a assignments/LOTE_NNN_W0X.md de rama árbitra
Branch de trabajo y commit SHA: ...
ID y nombre / categoría: ...
Estado PREVIO con pruebas y versión: ...
Qué efecto se mantiene/corrige/conecta (por ID): ...
Archivos tocados: ...
Archivos que solicitaste tocar pero NO tocaste por reserva: ...
Pruebas ejecutadas (comando real, versión, hash, resultado y resumen de logs): ...
Pruebas NO ejecutadas y por qué: ...
Resultados de negativos/propiedad/consumo/PC/guardado: ...
Verificación visual / GPU: PASS, FAIL o NO REALIZADA
Riesgos / regresiones / dependencias: ...
Autocontrol: no he modificado main/V28/otras ramas/descartes ni fuente canónica.
Estado: LISTA_PARA_REVISION / BLOQUEADO / RECHAZADO
```

## Si el repositorio o la rama no son accesibles

Detener los cambios, informar el error concreto y los IDs asignados sin alterar el estado. No afirmar que se ha guardado o probado nada. El usuario puede reabrir una conversación con el mismo ID de lote y branch; el reporte en GitHub es la fuente.

## Regla Mega literal para no volver a equivocarse

**DOS piedras universales físicas por partida; hasta DOS megaevoluciones por entrenador EN EL MISMO combate.** Los portadores se fijan antes del combate y no pueden cambiar ni traspasar su piedra durante él. Después se pueden asignar a otros Pokémon; especies sin megaforma autorizada no megaevolucionan. No implementar todavía; leer la especificación corregida V2.

## Complemento LOTE_001 — primera ronda de comprobación

Para el primer encargo exclusivo `LOTE_001_W0X` prevalece la **prohibición temporal de editar producción** de la puerta de compatibilidad. Una W puede leer cualquier rama, pero no introducir cambios de V28 en su propia rama antes de que la árbitra publique una base integrada certificada. Los 248 IDs de máquinas de W05 constituyen **una auditoría de tabla**, no permiso para programar 248 objetos. Un informe sin PASS operativo sigue siendo útil si clasifica las rutas y cita exactamente el código y las evidencias disponibles. Lee `BASELINE_GATE_2026-11-01.md`.

## Obligación de memoria técnica por rama (desde LOTE_002)

Consultar [NOTEBOOK_PROTOCOL_V1.md](NOTEBOOK_PROTOCOL_V1.md) y la [plantilla](NOTEBOOK_TEMPLATE_V1.md). Desde el siguiente lote, con autorización expresa en `assignments/LOTE_NNN_W0X.md`, mantener `reports/W0X/CONTINUIDAD.md` dentro de **tu propia rama**. Registrar estado por ID/familia, mapa del sistema, qué código existía, cambios reales, pruebas con SHA, cómo reproducirlas, límites, conflictos y próximo paso. Actualizarlo **al terminar cada lote y antes de pasar a otra conversación**, además del informe de lote.

El cuaderno NO es una nueva fuente de órdenes: si contradice el encargo de IA6, detén las escrituras y consulta la asignación oficial. **No añadir archivos nuevos a LOTE_001 ya iniciado**; el informe del primer lote sirve de memoria inicial y se enlazará en el primer cuaderno autorizado. Ni un `sigue` ni un cuaderno propio autorizan cambiar de familia, rama, archivo o lote.
