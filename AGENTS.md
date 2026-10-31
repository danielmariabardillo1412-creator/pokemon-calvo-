# Pokemon Calvo — desarrollo tras la arquitectura

Estado vigente V26: tras revisión solicitada por el usuario, se excluyen los
diez objetos ligados únicamente a evoluciones de intercambio en el diseño elegido:
dragon_scale, dubious_disc, electirizer, magmarizer, prism_scale, protector,
reaper_cloth, sachet, up_grade y whipped_dream. Linking Cord sigue excluido.
Su función genérica con Fling no justifica conservarlos aquí. Datos canónicos,
SDK y cantidades de partidas antiguas no se borran. Metal Coat, King's Rock,
Deep Sea Tooth y Deep Sea Scale siguen permitidos por sus otros efectos.

PRIORIDAD HUMANA: terminar objetos antes de adaptar evoluciones. La conversión
intercambio -> nivel está APLAZADA. No fijar niveles, no asumir 37, no modificar
EvolutionSystem ni registros canónicos por un simple «sigue». Para retomarlo se
contrastarán otros juegos/randomizadores y la tabla que aporte el amigo.
Ver TRADE_EVOLUTIONS_FUTURE.md y ITEM_TRADE_EXCLUSIONS_V26.md/.json.

54 exclusiones; 614 equipables permitidos / 611 con descriptor. Quedan
amulet_coin, exp_share y luck_incense como dependencias de economía/perfil XP,
no como neutros para rellenar cobertura. Otras familias (EV equipados, IV/mentas,
formas, mapa) mantienen sus dependencias; no confundir estos tres con todo lo
que falta del sistema de objetos. Mantener arquitectura y límites del proyecto.

Guarda nueva: tools/verification/run_trade_item_exclusions_v26.py contra e9a4812.
Su sello ya existe: no resellar. Guardas/matrices V2–V25 históricas; no editarlas
para aparentar aceptación actual. Codex es único escritor; OpenCode no trabaja.
Checkpoint funcional: 9cda56431025abe0f5f6dbaeb30041800d74e902.

ENCARGO EXTERNO HISTORICO (cerrado en 2fee506; no reanudar): el usuario autoriza de nuevo OpenCode para cierre de
objetos por familias completas. Leer docs/opencode/ITEM_CLOSURE_V2/START_HERE.md,
WORK_ORDER y CONTRACT de ese paquete. O100/O110/O120/O190 pueden continuar sin
revision de Codex entre objetos ni familias autorizadas. O001/O002 son historicos.
Los planos se preparan sobre V21 (da00bd4c); no se cambia aqui la jugabilidad.
Cuando el usuario lo arranque, OpenCode sera el unico escritor; Codex revisara
despues el rango. No hay un segundo ejecutor paralelo ni aceptacion automatica.
El paquete autoriza un helper de mochila y cambios SOLO en applyMedicine y
checkpoint de nuestro native_engine.cjs, usando APIs del simulador fijado y el
canal transaccional existente. Es excepcion expresa a la prohibicion anterior
de tocar ese adaptador; no autoriza callbacks/Dex, dano, RNG, dispatch, protocolo,
paquetes o schema. field_demo solo puede delegar en un helper dentro de
field_prepare_native_encounter. El guard V2 protege el resto, incluidos estos
planos y AGENTS. OpenCode actualiza sus STATE/PROGRESS y los cuadernos permitidos.

Raiz de trabajo: `D:/Proyectos/Pokemon Calvo - Arquitectura Kilo`.
Original protegido: `D:/Proyectos/Pokemon Calvo`; no editarlo ni probarlo.
T001–T006 estan aceptadas en 208c06c0. Los contratos en docs/kilo son historicos;
la arquitectura no se reabre. Limpieza cerrada en 941dd297. Autorizacion vigente:
continuar objetos disponibles manteniendo la arquitectura y comprobar cada bloque.
V9 validado: seis caramelos (raro y EXP XS/S/M/L/XL), candidato separado,
decisiones explicitas en mochila, consumo al finalizar, guardado y combate nativo.
V10 conecta Capsula/Parche Habilidad, con cambio moderno normal/oculta y regreso
al primer slot normal, vistas obsoletas rechazadas y guardado/combate verificados.
76 efectos de campo conectados tras V13; docs/current/ITEM_FIELD_V10.md conserva alcance y
dependencias (Modo Daruma pendiente sin consumo, herencia evolutiva separada).
V9 de caramelos, V8 de PP y V7 de EV siguen cubiertos por regresiones.
V11 conecta Nido/Rapid/Ensueno/Sana/Honor Ball: nueve IDs de captura admitidos,
selector nativo, curacion y relojes finales, guardado/restauracion verificados.
Ver docs/current/ITEM_CAPTURE_V11.md: se conserva la formula simplificada de
calvo_capture_v1, sin certificar fidelidad completa a Gen IX. Captura se cuenta
aparte de los efectos de campo. Las mentas siguen pendientes de una
representacion persistente distinta de la naturaleza original; no falsearla.
V12 conecta Veloz/Turno/Nivel Ball con contexto vivo de turnos y nivel activo:
doce bolas admitidas. Cargar reconstruye el contexto; no hay contadores nuevos
en el guardado. docs/current/ITEM_CAPTURE_V12.md registra las pruebas y limites.
V15 conecta Amigo/Safari/Competi/Gloria Ball, dieciseis IDs admitidos. Amigo fija
amistad 200 solo al capturar; Safari/Competi multiplican por 1,5 y Gloria por 1.
Mismo perfil aproximado de captura, sin regalos/concursos ni nuevos campos de
origen de bola. Ver docs/current/ITEM_CAPTURE_V15.md; Lujo sigue pendiente.
V13 conecta siete rutas EV de mochis, con perfil RHH que conserva amistad;
paridad de amistad con SV pendiente de contraste, sin afirmar equivalencia total.
Ver docs/current/ITEM_MOCHI_V13.md. V14 corrige la entrada nativa con Campana
Alivio mediante metadatos revisados del adaptador propio; probados guardar/cargar,
Lanzamiento, Desarme, Truco, captura y ausencia de duplicacion. Ver
docs/current/ITEM_FIELD_HELD_V14.md. V16 conecta 24 medicinas equipadas mediante
metadatos revisados, sin curacion automatica ni nuevos usos de medicina en combate.
Ver docs/current/ITEM_FIELD_HELD_V16.md. V17 conecta otros 17 consumibles de
entrenamiento/potenciadores equipados y comparte el contrato nativo de pruebas.
Ver docs/current/ITEM_FIELD_HELD_V17.md. En V17 quedaron 21 equipables permitidos sin
definicion nativa. Los ocho potenciadores de combate mantienen pendiente su uso
desde mochila; registro equipado no equivale a efecto de uso implementado.
V18 conecta Huevo Suerte (XP de combate actual/inicial, sin bonus a caramelos) y
unifica Piedra Eterna para evolucion por nivel. Ver docs/current/ITEM_PROGRESSION_V18.md.
Quedan 19 equipables sin definicion; el reparto base calvo_progression_v1 se conserva.
V19 prueba importacion automatica de recuperacion desde RHH fijado: 42 IDs en
manifiesto generado, 41 rutas anteriores preservadas y Flauta Azul nueva sin
consumo. Son 77 efectos de campo; los 19 equipables pendientes no cambian.
Ver docs/current/ITEM_IMPORT_V19.md. No inferir cobertura de otras familias por
el barrido de 2.222 IDs. El importador no ejecuta C/Ruby y falla ante conflictos.
La autorizacion humana de V19 permite este importador, su manifiesto propio,
la consulta de recuperacion y consumo en servicio/vista; no regenerar datasets,
politicas ni baselines anteriores. Mundo/combate/IV/mentas siguen separados.
V20 importa doce metadatos equipados revisados sin efecto pasivo: cinco panuelos,
cinco flautas, Poke Muneco y Cola Skitty. Ver docs/current/ITEM_FIELD_HELD_V20.md.
Son 618/625 definiciones nativas; quedan siete, sin admitirlos como neutros.
Los 77 efectos de campo no aumentan; los usos de mundo, huida, concurso y
mochila de combate de estos objetos siguen pendientes excepto Azul de V19.
Este bloque solo amplia el registro propio mediante manifiesto y pruebas; no
modifica NativeEngine, algoritmos, paquetes, datos, politicas ni callback alguno.
V21 conecta tres consumibles de huida desde mochila nativa: poke_doll, fluffy_tail
y poke_toy. Ver docs/current/ITEM_ESCAPE_V21.md. Terminan FLED, consumen una unidad
solo al publicar, sin RNG/turno extra y con rechazo ante entrenador/frontera invalida.
Se reutiliza el cierre sincronico; la UI solo consulta/ofrece/pide. Checkpoints
activos no pueden inventar gasto de estos objetos terminales. Schema sin cambios.
Son 18 usos directos de mochila nativa (15 medicinas + 3 huida), aparte de bolas;
77 efectos de campo y 618/625 definiciones equipadas no cambian. Bola Humo,
ocho potenciadores y las dependencias de mundo/formas/IV/mentas siguen pendientes.
Antes de caramelos se corrigieron alias/divisor de las curvas XP; ver
docs/current/PROGRESSION_GROWTH_CURVES_FIX.md. Reutilizar la progresion existente
y su tabla contrastada; resolver decisiones de aprender/evolucionar antes de consumir.
Auditoria PokéAPI y correcciones cerradas: docs/current/POKEAPI_DATA_REPAIRS_V1.md.
El usuario autorizo la reparacion puntual de la condicion cero de Tyrogue y dos
hashes de procedencia/binding. No ampliar eso a regenerar datasets. Se conservan
los textos correctos por generacion y el objeto unico Baya Hibis.
Region corregida en 0e2cd3a;
objetos V5-V7 cerrados hasta eb18a5da. Comparador V1 terminado con hallazgos,
conservado en 021a9c5. Leer docs/current/START_HERE.md y docs/current/CLEANUP.md.

Un escritor; sin agentes paralelos. Historial: cuando OpenCode no estaba
disponible el usuario devolvio a Codex O001 (Capsula/Parche), cerrado como V10.
No se atribuye ninguna revision independiente a OpenCode. El piloto anterior
quedo cerrado; el nuevo encargo autorizado es ITEM_CLOSURE_V2 al inicio de este archivo.
Los planos y el guard O001 son historicos: no resellarlos; V10 tiene scope propio.
No reabrir la arquitectura T001–T006 ni iniciar otro ejecutor simultaneo.
Mantener el servicio de objetos como autoridad, la UI como vista y el motor nativo
para combate. Preparar copia, validar, publicar
y consumir una unidad solo ante efecto real. No usar clases UI como servicios.
Conservar los guards de identidad y actividad. No duplicar reglas en otro motor.
Toda ampliacion debe conservar esta separacion: reglas en su modulo, coordinacion
en servicios y presentacion en vistas; no acumular mecanicas en field_demo o UI.
Compartir comportamientos repetidos y verificar conexiones antes de cerrar el lote.

No modificar el original, F:, datos brutos/normalizados, politicas, arte, packs,
paquetes instalados Node/Showdown, algoritmos de combate, RNG o schema de guardado. No regenerar
fixtures de datasets ni descargar dependencias para resolver el encargo.
La orden humana de corregir Campana Alivio autoriza el adaptador propio
native_engine.cjs y un modulo revisado de metadatos para ese objeto (V14).
La continuacion de objetos V16 amplia solo ese modulo a 24 medicinas revisadas;
no modifica native_engine.cjs ni instala callbacks para sus usos de campo.
V17 revisa otros 17 descriptores en ese modulo y extrae pruebas comunes, con
los mismos limites de metadatos y sin habilitar usos no implementados.
V18 amplia progresion y sus tres sesiones para esos dos efectos, reutilizando
origin del combate nativo y cache transitoria en legado. No cambia native_engine,
algoritmos de combate, datos ni schema. El helper puro es la autoridad de esos efectos.
No agregar callbacks de mecanicas, admitir objetos desconocidos en bloque ni
editar node_modules para ocultar fallos; el resto queda protegido por hash.
No borrar motores anteriores ni archivos ausentes con skip-worktree. Antes de
retirar material obsoleto, comprobar consumidores y conservar su historia en Git.
No duplicar archivos retirados en nuevas carpetas de archivo. Conservar contratos,
creditos, evidencia y verificadores historicos que todavia tengan consumidores.
No reset --hard, clean, rebase, merge, push ni remotos. Commits locales pequenos
tras pruebas pertinentes; conservar todo trabajo ajeno inesperado.

Desarrollar objetos por familias con contrato de referencia fijado, escenarios
positivos/negativos, mochila real y guardado/carga. Registrar como pendientes los
usos cuyo mundo, formas u otros sistemas aun falten. No certificar todo el catalogo
por pasar un lote ni cambiar los vetos acordados. Creditos y limites documentados.
Los verificadores historicos T006B conservan su alcance y baselines: no resellar ni
presentarlos como validadores de cambios nuevos. Cada fase nueva declara sus
archivos permitidos y verifica el resto contra el checkpoint anterior.
