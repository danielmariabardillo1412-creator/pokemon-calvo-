# CUADERNO DE RELEVO — Pokémon Calvo / sistema de objetos / cinco operarios y una árbitra

**Edición:** 2026-11-01. **Modo:** seis conversaciones separadas de ChatGPT con GitHub compartido. **Empieza aquí**, no desde el historial de 2.222 objetos. Este documento es para conservar el contexto cuando se abra otra ventana.

## 0. Objetivo y estado verificado

El objetivo NO es recrear Pokémon desde cero ni conectar 2.222 objetos uno a uno. Es **completar y verificar las funciones de los objetos seleccionados para Pokémon Calvo**, un randomlocke competitivo ambientado en romanos, vikingos y posiblemente mayas, usando Godot **4.7** según `project.godot`. Preferir automatización por familias con importadores, perfiles y pruebas.

**Selección vigente, no implementación:**
- 2.222 entradas canónicas: **743 PERMITIR, 1.375 DESCARTAR, 104 APARCADO_MEGA, 0 CONDICIONAL**. Archivo: `docs/current/RANDOMLOCK_ITEMS_SCOPE_V1.csv`.
- Lista de diseño: **744 tipos = 743 canónicos seleccionados + 1 tipo nuevo `mega_stone_universal`**: `docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`.
- Mega para **fase posterior**: **DOS piedras universales físicas por partida**, intercambiables **entre combates**, **DOS megaevoluciones permitidas por entrenador y combate**. **PROHIBIDO reasignar una piedra o cambiar el portador/variante durante un combate**. No reintroducir la idea falsa de «una Mega por combate». Especificación **vigente**: `docs/current/RANDOMLOCK_MEGA_UNIVERSAL_SPEC_V1.md` (contenido corregido V2). Los 104 IDs Mega históricos se conservan para referencia, fuera del backlog normal.
- **No tocar `main` ni la rama/PR V28 `codex/items-v28-from-main` / #118.** La rama catalogadora `codex/item-catalog-randomlock-v1-20261101` contiene la selección/documentación. Las seis ramas del equipo se derivan de ese punto, no de main.

**Evidencia de código preexistente, no dar por hecha toda la lista**: `docs/current/ITEM_SYSTEM_CURRENT_STATUS.json` (V27) informa 624 transferencias de equipo, 57 rutas de evolución por objeto, 229 máquinas activas, 77 efectos de campo y 16 bolas conectadas en fases específicas; muchos efectos de combate equipados/condicionales todavía no están certificados. El estado puede haber cambiado en V28: **leer rama objetivo y pruebas antes de afirmar PASA**. `docs/current/ITEM_INVENTORY.csv` distingue dato, entrada nativa y conexión, NO certifica por sí solo que el efecto funcione. `docs/current/ITEM_ART_CURRENT_STATUS.json` informa 1.011 entradas con arte (algunas no son objetos seleccionados). **Primero inventariar qué está realmente hecho, después crear.**

## 1. Documentos fuente, por orden de lectura

1. `docs/coordination/items_parallel_v1/START_HERE.md` (este documento).
2. `docs/coordination/items_parallel_v1/COORDINATOR.md` o `WORKER.md` según rol.
3. `docs/coordination/items_parallel_v1/QUEUE_V1.csv` (744 filas, familia, pista de estado y responsable previsto; la asignación real la hace solo la coordinadora).
4. `docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`, `docs/current/RANDOMLOCK_ITEMS_SCOPE_V1.csv` y `docs/current/RANDOMLOCK_MEGA_UNIVERSAL_SPEC_V1.md`.
5. `AGENTS.md` y `docs/current/ITEM_SYSTEM_CURRENT_STATUS.json` para reglas técnicas y evidencias; `docs/current/ITEM_CONNECTIONS_V1.md`, `docs/current/ITEM_ESCAPE_V21.md`, `docs/current/ITEM_CAPTURE_V15.md` según la familia.
6. `docs/current/RANDOMLOCK_ITEMS_AUDIT_PASS13_2026-11-01.md` y anteriores para justificación de descartes. **No revertir por intuición**; proponer en informe, dejar la política activa intacta.

Las palabras `PERMITIR`, `DESCARTAR`, `APARCADO_MEGA` son decisiones de *contenido futuro*, no garantías de integración. El ID provisional Mega no pertenece al catálogo canónico de 2.222.

## 2. Roles y ramas — ninguna conversación escribe en la rama de otra

Repositorio: `danielmariabardillo1412-creator/pokemon-calvo-`.

- **Árbitra / coordinadora**: `codex/calvo-items-20261101-arbitro`. **Única** autorizada a asignar IDs, actualizar tablero/cola, comprobar evidencias, integrar trabajos aprobados **en su rama** y pedir nuevas tandas. No modifica main.
- **Trabajadora 1 / W01:** `codex/calvo-items-20261101-w01`. Equipables de combate y consumibles de mejoras durante batalla: familias `HELD_COMBAT_CANDIDATE` (177) y `BATTLE_STAT_USE` (9). **186 IDs por triar**, no por programar.
- **Trabajadora 2 / W02:** `codex/calvo-items-20261101-w02`. Entrenamiento `TRAINING` (62), bayas `BERRY` (54) y curas `MEDICINE` (32). **148 IDs**.
- **Trabajadora 3 / W03:** `codex/calvo-items-20261101-w03`. Captura `CAPTURE_BALL` (24), campo `FIELD_USE` (15), ofensiva Z `Z_CRYSTAL` (32), Tera `TERA_MATERIAL` (18). **89 IDs**.
- **Trabajadora 4 / W04:** `codex/calvo-items-20261101-w04`. Evoluciones `EVOLUTION` (44), forma/clave `STORY_KEY_OR_FORM_REVIEW` (15), legacy útil (5), tesoros (7) y `FOOD_OR_PICNIC_ACTIVITY` (1). **72 IDs**.
- **Trabajadora 5 / W05:** `codex/calvo-items-20261101-w05`. Libros de movimientos / máquinas `MACHINE` (248). **248 IDs**. Los libros sustituyen CDs por coherencia romana/vikinga; aprovechar generación automática existente, no hacer un script por libro.
- **Objeto especial Mega:** `mega_stone_universal` (1 tipo; 2 unidades). **PENDIENTE FASE MEGA**, sin tarea para W01-W05 ahora.

Las cantidades **son listas iniciales de clasificación, no número real de implementaciones pendientes**. El volumen de trabajo varía por familia; no repartir la misma base de código a dos trabajadores solo por equilibrar números. Si una familia requiere cambios compartidos, la árbitra asigna **propiedad exclusiva por archivo/subsistema** o serializa las integraciones.

## 3. Protocolo de comunicación entre conversaciones

**No existe comunicación automática entre chats**. La persona usuaria abre cada conversación con su prompt, y puede pasar el mensaje «revisa GitHub y continúa el lote asignado». La coordinadora consulta las ramas, CSV y reportes en GitHub; las trabajadoras **NO envían órdenes directamente a las otras conversaciones**.

**Asignación centralizada:**
1. La árbitra lee `QUEUE_V1.csv` y el estado técnico por ID. Antes de asignar, identifica los IDs ya funcionales y la prueba que lo demuestra. Si existe PASS, marca **YA_HECHO_VERIFICADO** y NO pide reprogramarlos.
2. La árbitra crea un lote de hasta **3 IDs por trabajadora** (o lote de familia, cuando una automatización cubra más con pruebas). Le comunica los IDs, los criterios de aceptación, archivos que puede tocar, dependencias y la base exacta. **Solo ella actualiza las asignaciones.**
3. La trabajadora trabaja **únicamente en su rama** y **solo** el lote entregado. Crea reporte en `docs/coordination/items_parallel_v1/reports/W0X/LOTE_NNN.md` con commits, efecto por ID, pruebas reproducibles, resultados reales y límites. Si encuentra un conflicto, propone solución; **no modifica otros objetos por sorpresa**.
4. La trabajadora comunica que terminó. La árbitra lee el reporte y su diff, vuelve a ejecutar/comprobar las pruebas disponibles, revisa que no haya cambios externos y acepta/rechaza. **PASS solo con evidencia real**; si falta Godot local, registrar `NO_VERIFICADO`, no «funciona».
5. La árbitra integra **un lote cada vez** en su rama de integración, resuelve conflictos, actualiza el tablero y envía el siguiente lote. Jamás merge automático a main. **La rama de una trabajadora no es autoridad sobre el estado global**.
6. Cualquier tarea bloqueada se libera mediante registro explícito antes de reasignarla; no dar el mismo ID a dos conversaciones a la vez.

**Límite de contexto:** cada lote deja un reporte autosuficiente y un commit. No cargar entero el historial ni pegar miles de líneas en el chat. El próximo turno puede leer solo el cuaderno, cola y el último lote. Cada respuesta debe decir qué se cambió realmente, qué se verificó y qué queda bloqueado.

## 4. Peligros que deben evitar

- **Colisiones de código:** ramas separadas evitan sobrescrituras inmediatas, pero **NO evitan conflictos al integrar**. Los archivos compartidos de motor, inventario, políticas, tests y generadores son **zona de propietario exclusivo por lote**. La coordinadora resuelve integración y guarda registro.
- **No implementar contenido solo por estar PERMITIR:** usar `config/item_selection_v1.json` tal como está hasta autorización expresa. La selección nueva sigue siendo una propuesta/documentación; no cambiar la distribución ni partidas para simular progreso.
- **No desconectar implementaciones actuales por descartes:** Cola Skitty PERMITIR como representante; Poké Muñeco y Pokéseñuelo DESCARTAR en **futuro catálogo**, pero sus efectos V21 están conectados y **deben quedar funcionando** durante este trabajo. Lo mismo con bolas y demás rutas preexistentes.
- **No reabrir decisiones cerradas:** fósiles fuera, revivires excluidos, libros (no CDs), caramelos AV de Let's Go fuera, Z ofensivos sí y Z de estado no, 104 Mega fuera de la fase ordinaria. Mantener objetos originales necesarios para evoluciones por intercambio; `linking_cord` excluido, niveles futuros no elegidos.
- **Protección del juego:** no tocar datasets originales ni eliminar objetos/arte canónico; no reescribir arquitectura central por una familia, no reprogramar efectos ya probados; conservar compatibilidad de guardados y regresiones.
- **Pruebas:** usar checks/importadores existentes, Godot 4.7 en PC o GitHub Actions si hay workflow verificable; registrar salida, commit y versión. Una prueba documentada en V27 **no demuestra** que un commit nuevo V28 o paralelo pase sin ejecutarla.
- **Uso de GitHub:** evitar ejecutar CI por cada commit trivial. Agrupar pruebas por lote y subsistema; los costes de cinco CI simultáneos pueden aumentar. La coordinadora decide cuándo hacer una ejecución consolidada.

## 5. Escala real

Cinco trabajadoras por tres objetos implican hasta **15 IDs por ronda coordinada**. Si las 744 entradas requirieran trabajo individual, serían **unas 50 rondas**, no 20 (744 ÷ 15 ≈ 49,6). En la práctica, muchos objetos **ya están parcial o totalmente conectados** y otros pueden resolverse **por un generador común**, reduciendo las rondas de programación; sin diagnóstico no se puede prometer cifra.

**No iniciar masivamente 5 rondas de código sin comprobar la línea base y sus conflictos.** Primero un lote piloto pequeño por trabajadora y una integración completa en rama de la árbitra. Después se amplía el tamaño si las pruebas y los archivos compartidos lo permiten.

## 6. Qué debe entregar el equipo

A. Auditoría ID-por-ID de **lo ya implementado** vs **lo pendiente de contrato, código o prueba** (no confundir con 743 seleccionados). B. Importadores/perfiles reutilizables por familia. C. Pruebas de lógica, integración, consumo, propietarios/PC, guardado/carga y UI donde corresponda. D. Informe de cobertura por ID y evidencias reproducibles. E. Lista de bloqueos reales, no propuestas vagas. F. Integración secuencial **en rama árbitra**, lista para PR a main **solo si el usuario la autoriza**.

**Estado inicial del cuaderno:** ramas y protocolo preparados; nadie está trabajando automáticamente; ningún lote fue probado/implementado por crear estos documentos.

## Aviso de arranque: LOTE_001 audit-only

Ya existe `BASELINE_GATE_2026-11-01.md` y encargos `assignments/LOTE_001_W01.md` a `LOTE_001_W05.md` en la rama árbitra. No iniciar desarrollo hasta unificar las referencias V27/V28. Las trabajadoras escriben solo informes en ramas exclusivas; lectura de V28 no es importación de V28. Prioridad: no generar código espagueti, comprobar adaptadores reutilizables antes de nuevas implementaciones.
