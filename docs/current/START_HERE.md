# Empezar aquí — 2026-10-31

Estado actual: **diez objetos de evolución por intercambio revisados y excluidos.**
No tienen otro efecto específico de combate en el simulador fijado; su uso genérico
con Lanzamiento queda reconocido. Se mantienen Revestimiento Metálico, Roca del Rey,
Diente Marino y Escama Marina por sus efectos de combate. Cordón Unión sigue excluido.

[Revisión y lista](ITEM_TRADE_EXCLUSIONS_V26.md) · [Resultados](ITEM_TRADE_EXCLUSIONS_V26.json).
La política bloquea generación, equipamiento y uso; los datos originales, el SDK
y las cantidades de inventarios antiguos se conservan. No se han cambiado las
evoluciones ni se han fijado niveles. La adaptación de intercambios sigue aplazada:
primero se termina lo aplicable de objetos, después se contrastarán otras bases.

5 grupos PASS / 6.931 comprobaciones, incluidas regresiones. Son 54 exclusiones,
614 equipables permitidos y 611 reconocidos por el backend. Es una reducción de
alcance, no más efectos implementados. Los pendientes de descriptor son Amulet
Coin, Exp. Share y Luck Incense. Otras familias conservan dependencias de sistemas;
no se certifica todo el catálogo por pasar este lote.
Checkpoint funcional: `9cda56431025abe0f5f6dbaeb30041800d74e902`.

[Trabajo de evoluciones aplazado](TRADE_EVOLUTIONS_FUTURE.md). Los informes
V2–V25 son históricos; no se resellan ni sus recuentos describen el estado actual.
Los apartados siguientes describen V1–V21.

V21: [consumibles de huida](ITEM_ESCAPE_V21.md). Poké Muñeco, Cola Skitty y
Poké Señuelo ya se usan desde mochila nativa para terminar un encuentro salvaje,
con consumo único y sin RNG/ataque extra. Son 18 usos directos de mochila con las
medicinas. Siguen 77 efectos de campo y siete huecos de definición equipada.

V20: [doce equipables revisados en bloque](ITEM_FIELD_HELD_V20.md). El registro
nativo pasa a 618/625; quedan siete definiciones pendientes. Los usos especiales
de mundo/mochila/concurso se mantienen separados; siguen 77 efectos de campo.
Poké Muñeco conserva su ID mediante un nombre nativo compatible.

V19: [importación automática por familias](ITEM_IMPORT_V19.md). Se compilan 42
objetos de recuperación en bloque: 41 rutas anteriores conservadas y Flauta Azul
nueva, reutilizable. V19 dejó 77 efectos de campo; ver V20 para el registro
nativo actual. Clasificar 2.222 IDs no certifica todas sus mecánicas.

1. Leer `AGENTS.md` en la raíz: copia activa, original protegido y límites.
2. Leer [PROJECT_STATE.md](PROJECT_STATE.md): estado vigente y cobertura.
3. Leer [NEXT_STEPS.md](NEXT_STEPS.md): familias pendientes y límites.
4. Seguir [WORK_PROTOCOL.md](WORK_PROTOCOL.md) y consultar solo el cuaderno
   temático necesario.

La limpieza y las correcciones declaradas están cerradas; resultados y límites
en [CLEANUP.md](CLEANUP.md). No hay una tarea T00 pendiente para OpenCode.
La arquitectura se aceptó en `208c06c0`; los objetos V7 se cerraron en `eb18a5da`.
El comparador V1 quedó conservado en `021a9c5`, antes de esta limpieza.
Después se conectaron y verificaron Más PP/PP Máximos (V8); consultar
[ITEM_SYSTEM_CURRENT_STATUS.json](ITEM_SYSTEM_CURRENT_STATUS.json) y su informe.
V9 conecta los seis caramelos con decisiones de aprendizaje/evolución y consumo
transaccional: [ITEM_FIELD_V9.md](ITEM_FIELD_V9.md).
V10 conecta Cápsula/Parche Habilidad:
[ITEM_FIELD_V10.md](ITEM_FIELD_V10.md). 5.092 casos de catálogo y mochila/guardado/
combate nativo verificados; Modo Daruma queda pendiente sin consumo del Parche.
OpenCode no llegó a iniciar O001; Codex lo terminó por instrucción del usuario.
V11: [ITEM_CAPTURE_V11.md](ITEM_CAPTURE_V11.md).
Cinco bolas adicionales, nueve admitidas; 10.760 casos, guardado/restauración,
selector del campo y cura de Sana verificados. Se conserva la fórmula aproximada
calvo_capture_v1; no confundir ese perfil con una reproducción completa de Gen IX.
V12: [ITEM_CAPTURE_V12.md](ITEM_CAPTURE_V12.md). Veloz/Turno/Nivel
conectadas con turnos/nivel activo reales y restauración; doce bolas admitidas.
19.368 casos y nueve grupos PASS. La fidelidad completa de captura sigue pendiente.
V13: [ITEM_MOCHI_V13.md](ITEM_MOCHI_V13.md). Siete rutas EV de mochis,
30.128 casos y nueve grupos PASS; 76 efectos de campo conectados. Se conserva
amistad según RHH, sin certificar paridad SV.
V14: [ITEM_FIELD_HELD_V14.md](ITEM_FIELD_HELD_V14.md). Campana Alivio
ya entra en nativo y conserva su identidad, transferencias, consumo y guardado.
Once casos nativos y diez grupos PASS. Ese inventario señaló 62 equipables
permitidos sin definición; V16 reduce el pendiente sin inferir efectos neutros.
V15: [ITEM_CAPTURE_V15.md](ITEM_CAPTURE_V15.md). Amigo/Safari/Competi/
Gloria Ball, dieciséis bolas conectadas. 17.216 casos y cuatro rutas del mapa con
guardar/cargar; resultados completos en su JSON. La fórmula aproximada de captura
y los sistemas de obtención/eventos se mantienen separados.
V16: [ITEM_FIELD_HELD_V16.md](ITEM_FIELD_HELD_V16.md). Se conectan
24 medicinas equipadas al registro nativo, sin curacion automatica ni nuevas
medicinas de combate. Quedan 38 equipables permitidos sin definicion. Pruebas
por objeto, mochila real y guardado/carga; resultados completos en su JSON.
V17: [ITEM_FIELD_HELD_V17.md](ITEM_FIELD_HELD_V17.md). Otros 17
consumibles equipados revisados; contrato nativo compartido con V16 y usos de
campo existentes conservados. Quedan 21 equipables sin definición. Los ocho
potenciadores no ganan todavía una acción de uso desde mochila de combate.
V18: [ITEM_PROGRESSION_V18.md](ITEM_PROGRESSION_V18.md). Huevo
Suerte aplica XP de combate x1,5 con el objeto actual/inicial; Piedra Eterna usa
la misma puerta de evolucion por nivel en combate y caramelos. Rutas reales,
guardado/carga y referencias fijadas en el JSON. V18 dejó 19 definiciones pendientes;
V20 reduce el pendiente actual a siete.
La revisión previa a caramelos corrigió las curvas de experiencia; resultado y
compatibilidad en [PROGRESSION_GROWTH_CURVES_FIX.md](PROGRESSION_GROWTH_CURVES_FIX.md).
Auditoría de datos original/API y correcciones cerradas:
[POKEAPI_DATA_REPAIRS_V1.md](POKEAPI_DATA_REPAIRS_V1.md). Conserva las diferencias
de versión válidas; la auditoría inicial sigue en POKEAPI_DATA_AUDIT_V1.md.

Autoridad operativa: instrucciones humanas vigentes, código y pruebas sobre los
bytes reales de esta copia, estado actual y contratos del dominio. Los informes
de CI remotos y diarios antiguos solo describen sus versiones exactas; no mandan
hacer merges, recrear la copia ni repetir tareas cerradas.

No editar el original, regenerar datos o cambiar recursos gráficos como parte de
esta tarea. Las decisiones de contenido siguen documentadas en los perfiles.
