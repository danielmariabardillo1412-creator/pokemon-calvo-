> **ESTADO HISTÓRICO SUPERADO:** esta propuesta de 10–12 bloques fue **aprobada y concretada** en [CAMPAIGN_GATE_003.md](CAMPAIGN_GATE_003.md) con **10 bloques por cada una de W01/W02/W03/W05**, cola de 40 filas y CI automática verificada. La frase original `NO ACTIVADO` que sigue más abajo describe solo el momento de redacción del borrador, no el estado actual. Para operar usar el GATE_003, nunca este borrador como encargo.

# PROPUESTA IA6 — CAMPAÑAS LARGAS V4 / «p» continua, sin STOP burocrático
**Estado: DISEÑO PREPARADO, NO ACTIVADO.** Elaborado 2026-11-03 tras validar que CAMPAÑA_002 4/4 ha completado ITER03 con CI automática. Ninguna IA puede usar este borrador como un nuevo encargo. Requiere autorización inicial única del usuario y publicación del manifiesto con IDs reales, no un `p` aislado.

## Diagnóstico y objetivo verificable
El sistema V3 sí ejecuta GitHub Actions tras cada cambio de tests; las cuatro ramas pasaron la última CI real. Sin embargo, el encargo dice `03/03 STOP`, de modo que **cualquier** tercer bloque termina la campaña. Los chats cumplen la regla, no se detienen «porque sí». Un sistema de trabajo continuo necesita un **presupuesto de tareas expresamente delegado**, no ejecutar `p` sin límites ni objeto asignado.

**Objetivo:** un solo mensaje de autorización por nueva campaña y luego `p` ejecuta el siguiente bloque de la cola (hasta 10–12 microbloques por IA, configurable por cantidad de objetos), con CI por rama que corre sola. IA6 solo revisa incidentes y puntos de consolidación; no hace de semáforo de cada iteración.

## Diseño propuesto
1. **Antes de activar**, IA6 construye `CAMPAIGN_003_QUEUE_APPROVED.csv` con **IDs exactos** seleccionados, familia W, contrato existente, condición de disparo, estado previo, dependencia, rutas de escritura exclusivas, prioridad y una prueba/recepción objetiva por bloque. Se cruza contra `CAMPAIGN_001_EVIDENCE_OVERLAY_V1.csv`, las cuatro actas CAMP002 y código actual. No suponer que `QUEUE_V1.csv` indica «sin implementar»: los estados son históricos.
2. **Reservas exclusivas por lote**, no «marcas» arbitrarias editadas por cinco IAs. Cada W solo toca pruebas/fixtures/reportes propios; cambios a `modules/`, `data/`, guardados, redes, arquitectura de combate o captura se bloquean y pasan a autorización separada IA6.
3. **Por cada `p`**: leer HEAD, cuaderno de progreso y fila siguiente autorizada; tomar 1 bloque; ejecutar contratos Python localmente si es posible; crear o ampliar test Godot sin falsear aserciones; publicar commit, actualizar CSV y un informe breve con IDs y SHA. La `p` siguiente lee la última CI:
   - `success`: seguir.
   - `queued/in_progress`: seguir **solo** con un bloque de pruebas independiente que no requiera resultados previos; etiquetar `EN_CI_AUTOMATICA` (sin PASS inventado).
   - `failure` / `timed_out`: diagnosticar y reparar solo en la ruta de pruebas propia; si hay defecto funcional/contrato/permiso/alcance, STOP y ticket a IA6. No pasar de largo para inflar progreso.
   - `cancelled` por commit posterior: consultar run vigente del **último SHA de tests**, nunca contar el cancelado como PASS.
4. **CI real por rama (ya existe)**: `.github/workflows/parallel-camp002-worker-autoci.yml` es una base que funciona. Preparar un workflow de CAMP003 adaptado a sus **nuevos tests** y solo en nuevas ramas de CAMP003, con rutas `on.push.paths` limitadas a código de pruebas/fixtures y no a documentos, `concurrency.cancel-in-progress`, timeout acotado, logs/artifacts 7 días, control del resultado por familia, Godot 4.7 + Node fijado cuando corresponda.
5. **Consolidación**: cada 4–5 microbloques **publicados y con CI PASS**, IA6 puede revisar el manifiesto compacto por excepción o a petición, sin detener las otras W por motivos administrativos. Un merge en árbitra requiere prueba de SHA y revisión de contratos, no se hace automáticamente a `main`.
6. **Contexto de chat**: cada 4–5 bloques, actualizar el cuaderno de continuidad y guardar registro de IDs y rutas. Al agotar contexto, abrir una conversación de **la misma identidad** que recupere HEAD/progreso; sin duplicar ni reempezar.
7. **Fin de campaña**: solo si se agota el rango de IDs autorizado, se cumple límite máximo de 10–12 microbloques, aparece un FAIL real/contrato compartido, o el usuario ordena STOP. Al acabar, decir `CAMPAÑA_003_FINALIZADA` y detenerse; no inventar CAMPAÑA_004.

## Restricciones específicas ya conocidas
- **W01 (equipables):** CAMP002 comprobó `ability_shield`, `absorb_bulb`, `adrenaline_orb`, **no volver a asignarlos como trabajo nuevo**. Elegir otros IDs tras cotejar pruebas nativas existentes.
- **W02 (bayas):** CAMP002 comprobó `sitrus_berry`, `lum_berry`, `leppa_berry`, `figy_berry`; no volver a implementar ni a modificar la naturaleza sin recálculo de estadísticas. El nuevo rango requiere inventario de disparos de campo/equipado.
- **W03 (captura):** CAMP002 **NO implementó** `dusk_ball`, `repeat_ball`, `dive_ball`: la suite únicamente prueba negativos y documenta que faltan contextos de noche/cueva, especie capturada o submarino. **No declarar terminadas esas tres bolas** ni pedir a W03 que invente contexto o fórmulas. Priorizar candidatos cuyo contexto actual exista o solicitar a IA6 un contrato de captura separado.
- **W05 (MT):** CAMP002 verificó **12 enseñanzas** con SaveV2 y controles negativos sobre 229 MT activas, **no las 229**; 19 históricas siguen deshabilitadas. Una campaña extensa debe trabajar muestras parametrizadas por tipo/learnset y ampliarlas con criterio de cobertura y coste, no duplicar 229 scripts o tocar `FieldItemService.teach`.
- **W04 (piedras):** CAMPAÑA_001 03/03 finalizada y CI 559 checks SaveV2 PASS. No reactivar como trabajadora permanente ni asignarle objetos sin decisión expresa del usuario.
- **main/V28/PR #118** siguen protegidos. No tocar las dos Megas universales, diseño/arte de libros ni características fuera de objetos. Las pruebas headless no sustituyen pruebas visuales/GPU.

## Precondiciones de activación
- IA6 debe publicar `CAMPAIGN_GATE_003.md` + `CAMPAIGN_003_BRANCH_MANIFEST.md` + `campaigns/CAMP_003_W0X.md` + **cola con filas reales ya auditadas**. Deben existir ramas nuevas base del último arbiter verificadas y CI con un smoke inicial; workers no deben mezclar su antigua rama CAMP002 por fuerza.
- La persona usuaria autoriza la nueva campaña UNA vez. Sin ello, cualquier `p` adicional a W01/W02/W03/W05 cerradas debe **solo explicar 03/03**.
- Este diseño no ofrece ejecución autónoma de las conversaciones ChatGPT sin mensajes: el usuario mantiene una `p` por bloque y GitHub CI funciona sin IA6.
