# Pokemon Calvo — desarrollo tras la arquitectura

Raiz de trabajo: `D:/Proyectos/Pokemon Calvo - Arquitectura Kilo`.
Original protegido: `D:/Proyectos/Pokemon Calvo`; no editarlo ni probarlo.
T001–T006 estan aceptadas en 208c06c0. Los contratos en docs/kilo son historicos;
OpenCode esta detenido. La nueva autorizacion del usuario es corregir
ARCH_SAVE_REGION_TYPE y continuar los objetos que tengan sistemas disponibles.
Correccion aceptada por pruebas: 0e2cd3a. Leer docs/current/DEVELOPMENT_CURRENT.md.

Un escritor; sin agentes paralelos. Mantener el servicio de objetos como autoridad,
la UI como vista y el motor nativo para combate. Preparar copia, validar, publicar
y consumir una unidad solo ante efecto real. No usar clases UI como servicios.
Conservar los guards de identidad y actividad. No duplicar reglas en otro motor.

No modificar el original, F:, datos brutos/normalizados, politicas, arte, packs,
Node/Showdown, algoritmos de combate, RNG o schema de guardado. No regenerar
fixtures de datasets ni descargar dependencias para resolver el encargo.
No borrar motores anteriores ni archivos ausentes con skip-worktree.
No reset --hard, clean, rebase, merge, push ni remotos. Commits locales pequenos
tras pruebas pertinentes; conservar todo trabajo ajeno inesperado.

Desarrollar objetos por familias con contrato de referencia fijado, escenarios
positivos/negativos, mochila real y guardado/carga. Registrar como pendientes los
usos cuyo mundo, formas u otros sistemas aun falten. No certificar todo el catalogo
por pasar un lote ni cambiar los vetos acordados. Creditos y limites documentados.
Los verificadores historicos T006B conservan su alcance y baselines: no resellar ni
presentarlos como validadores de cambios nuevos. Cada fase nueva declara sus
archivos permitidos y verifica el resto contra el checkpoint anterior.
