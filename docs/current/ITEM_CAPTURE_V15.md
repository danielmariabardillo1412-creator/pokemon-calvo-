# Objetos V15 — Amigo, Safari, Competi y Gloria Ball

Base: `b467470`, continuación en la copia organizada. No se cambia el original,
datos, arte, vetos, paquetes instalados, mecánicas de combate ni esquema de guardado.

## Alcance y referencia

Cuatro IDs adicionales se conectan al perfil existente **calvo_capture_v1**:

| ID | Efecto de captura conectado |
| --- | --- |
| `friend_ball` — Amigo Ball | Multiplicador 1. Tras capturar, fija amistad en 200. No suma 200, no cura y no actúa tras un intento fallido. |
| `safari_ball` — Safari Ball | Multiplicador 1,5. Sin efecto posterior sobre el Pokémon. |
| `sport_ball` — Competi Ball | Multiplicador 1,5. Sin efecto posterior sobre el Pokémon. |
| `cherish_ball` — Gloria Ball | Multiplicador 1. Sin efecto posterior sobre el Pokémon. |

Fuente reutilizada: Pokémon Essentials de Maruno17 y colaboradores, commit
`8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b`. Archivo
`Data/Scripts/011_Battle/007_Other battle code/010_Battle_PokeBallEffects.rb`,
SHA-256 `5cf7a70d736d92c56427755100dee768106807eb6e65c807514eb4b89a6fdf65`.
Amigo utiliza la rama sin límite blando de felicidad de esa referencia (200);
no se añade la alternativa 150. Safari y Competi reutilizan sus modificadores
1,5. Gloria usa el comportamiento base sin manejador especial. PBS/items.txt
confirma los cuatro IDs como Poké Balls. Solo se leen estas fuentes, sin ejecutar Ruby.

Las cuatro funcionan cuando el jugador ya posee el objeto. No se crean regalos,
eventos, concursos, una Zona Safari, comercios ni entregas automáticas a partidas.
Tampoco se inventa historial de captura, género o metadatos del mapa. El permiso
de contenido se conserva según la política actual, sin añadir vetos por intuición.

## Conexión

La ampliación reside en `capture_ball_effects.gd`; los servicios de captura,
coste de inventario, publicación nativa y vista existentes la consumen sin
ramas específicas en el mapa o la UI. Amigo utiliza el campo persistente de
amistad existente. El efecto se aplica solo al capturado y antes de enrutarlo
al equipo o PC. El objeto se gasta una vez en cada lanzamiento válido.

El selector existente obtiene los IDs de CaptureRuleset, conserva nombre/arte
del catálogo y permite lanzar cualquiera de las cuatro desde el combate del mapa.
No se añaden campos de origen de Poké Ball: Lujo y sus bonos futuros continúan pendientes.

## Verificación

Ejecutar `python tools/verification/run_capture_v15.py`. La evidencia y los
resultados reales se registran en [ITEM_CAPTURE_V15.json](ITEM_CAPTURE_V15.json).

- Matriz de 1.076 especies/formas permitidas, cuatro bolas, dos estados de PS y
  despierto/dormido: 17.216 casos. Probabilidad, éxito/fallo, tirada RNG, unidad
  gastada y mutación exacta del individuo se comparan contra expectativas separadas.
- Amistad previa 0/149/199/200/255; Amigo fija 200 incluso si antes era 255.
  Valores fuera de 0–255 se rechazan antes de gastar inventario o RNG.
- Rechazos por entrenador, captura terminada, objetivo KO, estado inválido,
  mochila corrupta/sin unidad y contexto ausente; bolas pendientes siguen rechazadas.
- Captura hacia PC con equipo lleno, conexiones legado/nativo, rechazo de revisión
  obsoleta, publicación única y conservación de identidad, IV/EV, naturaleza,
  shiny, PS, PP y reloj de sueño real. No se usa un objeto equivocado como sustituto.
- Fallo seguido de guardado/restauración y Master Ball: el coste previo se publica
  una vez y una Amigo fallida no aplica amistad al capturar después con otra bola.
- Cuatro rutas en el mapa real: mochila guardada, Falsotortazo y Espora reales,
  guardar/cargar combate, seleccionar/lanzar, volver al mapa y guardar/cargar el
  resultado. La prueba con GPU repite estas rutas visuales, sin duplicar la matriz.
- Regresiones de núcleo, bolas V11/V12, inventario, UI legado, entrada nativa y
  restauración. Guard propio congelado antes de editar; no se resellan fases anteriores.

La ejecución inicial quedó con timeout tras el parón y no se contó como PASS.
Una ejecución posterior aisló ocho fallos de comparación de diccionarios IV/EV:
las claves/números internos cambian de tipo al pasar por JSON. Se comparan todos
los valores serializados canónicos, como hace el guardado, y se conservan ambos
lados en el informe. No se cambia el motor ni se elimina la comprobación. Los
intentos fallidos y sus logs permanecen separados de la ejecución final.

## Límites

Con este lote hay 16 IDs de bolas conectados; los 76 efectos de campo se cuentan
aparte. **No se certifica todo el catálogo ni fidelidad completa a Gen IX**:
la probabilidad continúa siendo la aproximación calvo_capture_v1. Capturas
críticas, tratamiento de Ultraentes, bolas de contexto y demás pendientes se
mantienen explícitos. No se atribuye a este lote resolver las 62 definiciones
de equipados ausentes del motor nativo ni las mentas/Entrenamiento Extremo.
