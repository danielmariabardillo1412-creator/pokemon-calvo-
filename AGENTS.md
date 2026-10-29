# Pokemon Calvo — desarrollo tras la arquitectura

Raiz de trabajo: `D:/Proyectos/Pokemon Calvo - Arquitectura Kilo`.
Original protegido: `D:/Proyectos/Pokemon Calvo`; no editarlo ni probarlo.
T001–T006 estan aceptadas en 208c06c0. Los contratos en docs/kilo son historicos;
OpenCode esta detenido. Limpieza cerrada en 941dd297. Autorizacion vigente:
continuar objetos disponibles manteniendo la arquitectura y comprobar cada bloque.
V9 validado: seis caramelos (raro y EXP XS/S/M/L/XL), candidato separado,
decisiones explicitas en mochila, consumo al finalizar, guardado y combate nativo.
67 efectos de campo conectados; docs/current/ITEM_FIELD_V9.md conserva alcance y
dependencias. V8 de PP y V7 de EV siguen cubiertos por regresiones.
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

Un escritor; sin agentes paralelos. Mantener el servicio de objetos como autoridad,
la UI como vista y el motor nativo para combate. Preparar copia, validar, publicar
y consumir una unidad solo ante efecto real. No usar clases UI como servicios.
Conservar los guards de identidad y actividad. No duplicar reglas en otro motor.
Toda ampliacion debe conservar esta separacion: reglas en su modulo, coordinacion
en servicios y presentacion en vistas; no acumular mecanicas en field_demo o UI.
Compartir comportamientos repetidos y verificar conexiones antes de cerrar el lote.

No modificar el original, F:, datos brutos/normalizados, politicas, arte, packs,
Node/Showdown, algoritmos de combate, RNG o schema de guardado. No regenerar
fixtures de datasets ni descargar dependencias para resolver el encargo.
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
