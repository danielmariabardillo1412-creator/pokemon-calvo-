# Investigación: arquitecto, ejecutor y revisión para Pokémon Calvo

Fecha de consulta: 2026-10-28.
Estado: investigación y propuesta de método. No es un encargo activo para Kilo,
no modifica el juego y no inicia una copia o reorganización.

## Conclusión

El reparto que propone el usuario tiene precedentes documentados. Aider separa
razonamiento y edición mediante dos modelos. Anthropic describe planificación,
implementación y evaluación, con entregas verificables. OpenAI documenta planes
autosuficientes para trabajos prolongados. Estas fuentes respaldan el patrón,
pero no prueban que cualquier modelo pequeño pueda reorganizar correctamente
este proyecto ni que el ahorro esté garantizado.

Propuesta para nuestro caso: Codex analiza y diseña; Kilo ejecuta una tarea
delimitada en una copia; las pruebas producen evidencia; Codex revisa cada
entrega importante. Son tres funciones, no una obligación de contratar o lanzar
tres agentes simultáneos. No hace falta instalar Aider ni crear otro framework.

## Qué está documentado

### 1. Aider: Architect/Editor

La documentación describe un modelo que propone la solución y un segundo que
la convierte en ediciones concretas. Permite elegir el editor por separado.
También advierte que utilizar dos solicitudes puede aumentar tiempo y coste.
[Modos oficiales de Aider](https://aider.chat/docs/usage/modes.html).

Su artículo de 2024 presenta el razonamiento detrás de esta separación y
resultados de aquel benchmark. Es un antecedente del método; sus modelos y
porcentajes históricos no sirven para elegir hoy el ejecutor de Godot.
[Artículo original](https://aider.chat/2024/09/26/architect.html).

### 2. Anthropic: planificador, generador y evaluador

El artículo de marzo de 2026 presenta esas tres funciones y acuerdos de entrega
con comportamiento comprobable antes de implementar. El evaluador ejecuta la
aplicación y contrasta los criterios. La comunicación puede conservarse en
archivos. También muestra que la utilidad del evaluador depende de las
capacidades del modelo y del trabajo, por lo que no prescribe añadir agentes
indefinidamente.
[Diseño del proceso para trabajos largos](https://www.anthropic.com/research/harness-design-long-running-apps).

### 3. Anthropic: continuidad entre sesiones

Su guía de noviembre de 2025 usa un preparador inicial, un ejecutor incremental,
una lista de comportamientos pendientes y notas de progreso. Identifica dos
fallos: intentar demasiado de una vez y declarar terminado algo sin comprobarlo
de extremo a extremo. Propone trabajar sobre una función cada vez, dejar
evidencia y conservar las comprobaciones.
[Continuidad de agentes de larga duración](https://www.anthropic.com/research/effective-harnesses-for-long-running-agents).

### 4. OpenAI Docs: planes autosuficientes

La receta de ExecPlans pide contexto suficiente para retomar el trabajo sin
recordar conversaciones, rutas y pasos concretos, progreso, decisiones y
validación observable. Es un documento vivo. La página está marcada como
archivada: aprovechamos su estructura de planificación, no sus recomendaciones
antiguas de modelos ni promesas de autonomía.
[Using PLANS.md for multi-hour problem solving](https://developers.openai.com/cookbook/articles/codex_exec_plans).

### 5. Kilo: capacidades actuales y compatibilidad

La documentación actual distingue agentes de trabajo y permite delegación.
El antiguo modo Orchestrator figura como obsoleto. Sus subagentes tienen
conversaciones separadas, pero comparten la carpeta de trabajo: una conversación
aislada no constituye una copia aislada de archivos.
[Orchestrator y su sustitución](https://kilo.ai/docs/code-with-ai/agents/orchestrator-mode).

Los agentes personalizados permiten definir instrucciones, modelo y permisos.
Las reglas del proyecto se pueden cargar desde archivos. Debemos comprobar su
compatibilidad con la extensión que realmente esté activa antes de generar la
configuración; instrucciones en texto y permisos efectivos son mecanismos
distintos.
[Subagentes personalizados](https://kilo.ai/docs/customize/custom-subagents),
[reglas del proyecto](https://kilo.ai/docs/customize/custom-rules),
[agentes disponibles](https://kilo.ai/docs/code-with-ai/agents/using-agents).

Inspección local de solo lectura: hay directorios de extensión de Kilo Code
7.8.17 y 7.8.18 en `.vscode/extensions`. Esto no confirma cuál está cargado en
Visual Studio Code, el proveedor ni el modelo seleccionado. No se han leído
credenciales ni cambiado ajustes. Kilo es la herramienta; la capacidad del
ejecutor dependerá también del modelo que tenga configurado.

## Adaptación propuesta a Pokémon Calvo

Esta sección es nuestra recomendación, no un procedimiento que las fuentes
hayan validado específicamente para Godot, Pokémon o nuestro repositorio.

### Orden y punto de partida

Se mantiene la decisión del usuario: cerrar primero la fase de objetos que puede
verificarse y registrar las dependencias que requieren otros sistemas. Después
se fija el estado completo del proyecto y se prepara la copia de trabajo.

La copia debe incluir el trabajo local válido, también los archivos que todavía
no estén en Git. Un worktree creado únicamente desde un commit no lo incluye por
sí solo. Hay que inventariar también los recursos y las dependencias necesarias
para ejecutar la demo; no descargar o regenerar datasets para hacer la copia.

El juego original conserva una única línea de desarrollo. Mientras el ejecutor
reorganiza una zona, evitaremos desarrollar en paralelo nuevas funciones que
cambien sus mismos contratos. Arte, textos u otros trabajos independientes
pueden avanzar con límites explícitos y un registro de cambios para integrarlos.

### Paquete de instrucciones futuro

Los siguientes son nombres propuestos; estos archivos no se han creado ni
activado con esta investigación:

| Documento | Contenido |
| --- | --- |
| START_HERE.md | Raíz de la copia, versión base, orden de lectura, primera tarea y comprobación de arranque. |
| ARCHITECTURE_TARGET.md | Mapa actual y destino, responsabilidades, propietarios del estado y operaciones públicas previstas. |
| TASKS.json | Tareas, dependencias, prioridad, estado y ubicación de su evidencia. |
| tasks/T001.md, etc. | Encargo autosuficiente del bloque actual, con rutas, límites y resultados verificables. |
| TEST_MATRIX.md | Qué prueba protege cada conexión y cuándo ejecutar regresiones más amplias. |
| PROGRESS.md | Último bloque cerrado, problemas reproducidos, decisiones y siguiente paso. |

Prepararemos el mapa general y detallaremos primero el piloto y los bloques
inmediatos. Las siguientes tareas se concretarán con lo aprendido. Esto evita
mantener veinte planos detallados que dejan de coincidir con el código.

El ejecutor recibe reglas estables, el índice y su tarea; consulta los demás
documentos y archivos cuando lo necesita. No le enviaremos todo el historial o
todos los datos en cada solicitud. Los detalles necesarios para una tarea sí
deben estar en su encargo o en archivos locales inequívocos.

### Contenido obligatorio de cada encargo

1. Problema concreto y comportamiento que debe conservarse.
2. Archivos y conexiones actuales relevantes, comprobados contra la copia.
3. Responsabilidad que se extrae y contrato de entrada/salida resultante.
4. Archivos autorizados y superficies que no se pueden alterar.
5. Pasos pequeños, cada uno con una comprobación local apropiada.
6. Pruebas de conexión y regresiones que corresponden al bloque.
7. Resultado esperado, evidencia exigida y criterios de aceptación.
8. Qué puede resolver solo y qué descubrimiento obliga a detener esa tarea.
9. Cómo recuperar el último estado aceptado sin perder otros trabajos válidos.

Un contrato no tiene que escribir por adelantado todas las líneas de código.
Debe resolver las decisiones arquitectónicas y permitir decisiones locales que
conserven sus límites. Una dependencia nueva se documenta; no autoriza ampliar
la reforma ni modificar las reglas del juego.

### Autonomía y puntos de revisión

El ejecutor prepara una pieza, la prueba y documenta, prepara su conexión,
comprueba esa conexión y solo entonces la activa. Es el método identificado en
`D:/NOVA_LAB/recovered_v7_repo/docs/CODEX_WORKING_NOTEBOOK.md`.

Puede continuar con pequeños pasos aprobados si sus comprobaciones pasan. Una
conexión nueva requiere una comprobación específica; la suite completa no tiene
que ejecutarse después de cada edición. Al completar un grupo relacionado se
ejecutan las regresiones de ese grupo. Cambios de autoridad del estado, guardado,
publicación del combate o formato serializado exigen revisión antes de seguir.

Como límite inicial propuesto para el piloto, después de dos intentos de corregir
el mismo fallo sin resolverlo se entrega un informe reproducible. Es una regla
nuestra para evitar bucles de trabajo, no un límite recomendado universalmente
por las fuentes. Se puede ajustar después de medir el piloto.

### Evidencia y revisión

Cada entrega identifica el estado de partida, archivos cambiados, conexiones
afectadas, comandos ejecutados, resultados y pendientes. Debe distinguir pruebas
ejecutadas, omitidas y fallidas. Una dependencia ausente no se convierte en PASS.

La revisión usa el cambio real y vuelve a ejecutar las comprobaciones críticas.
El resumen del ejecutor orienta, pero no sustituye esa evidencia. Las pruebas
existentes no se eliminan, desactivan ni debilitan para aceptar un cambio. Cualquier
cambio justificado en una prueba se presenta por separado para revisión.

Para nuestra primera ronda, las reglas de combate y su perfil vigente, los IDs
canónicos, datos, vetos, recursos y compatibilidad de guardado son límites que
deben conservarse. Tampoco se borra la ruta anterior hasta demostrar qué piezas
todavía utiliza la nueva. Las mejoras de comportamiento y de arquitectura se
registran como trabajos distintos.

### Elección del ejecutor

Antes de entregar una reforma larga, se elige un bloque pequeño representativo
de GDScript y se prueba el modelo configurado en Kilo. Mediremos correcciones
necesarias, respeto del alcance, pruebas y esfuerzo de revisión, además del
consumo si la herramienta lo ofrece. Más tiempo de ejecución o menos coste por
token no garantizan menos coste total si hay que rehacer el trabajo.

El primer piloto debería afectar a una responsabilidad acotada de presentación
o diagnóstico, conservando las reglas y el dueño de la partida. Su encargo exacto
se decidirá contra el estado congelado del proyecto, no contra rutas supuestas.

## Lo que queda preparado por esta investigación

Hay una propuesta de reparto, documentos, autonomía y aceptación contrastada
con fuentes primarias. Queda pendiente cerrar la fase de objetos, fijar el
estado base, confirmar el Kilo activo/modelo y generar los planos específicos.
No se ha delegado ningún trabajo, lanzado Kilo ni reactivado Nova.
