# Pokemon Calvo — desarrollo tras la arquitectura

Raiz de trabajo: `D:/Proyectos/Pokemon Calvo - Arquitectura Kilo`.
Original protegido: `D:/Proyectos/Pokemon Calvo`; no editarlo ni probarlo.
T001–T006 estan aceptadas en 208c06c0. Los contratos en docs/kilo son historicos;
OpenCode esta detenido. Limpieza cerrada en 941dd297. Autorizacion vigente:
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
Ver docs/current/ITEM_FIELD_HELD_V17.md. Quedan 21 equipables permitidos sin
definicion nativa. Los ocho potenciadores de combate mantienen pendiente su uso
desde mochila; registro equipado no equivale a efecto de uso implementado.
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

Un escritor; sin agentes paralelos. El usuario indica que OpenCode no esta
disponible y devolvio a Codex el bloque O001 (Capsula/Parche Habilidad), cerrado como V10.
No hay encargo externo activo ni revision independiente atribuible a OpenCode.
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
