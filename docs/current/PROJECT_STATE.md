# Estado del proyecto — 2026-10-31

Estado actual: **V23 verificado — Amuleto e Incienso Puro ya entran equipados
al combate nativo.** Se conservan sus efectos de tasa de encuentros y el estado
real del objeto tras Lanzamiento, Truco, Desarme y guardar/cargar.

[Informe V23](ITEM_ENCOUNTER_HELD_V23.md) · [Resultados](ITEM_ENCOUNTER_HELD_V23.json).
9 grupos PASS, 1.559 comprobaciones (incluidas regresiones), dos capturas GPU
vistas y nueva guarda completa contra el checkpoint anterior. Código funcional:
`b9ca439c52ac10aea2da3f1f37c6f1de3090f34f`. Seguimos en la versión organizada, sin publicar ni mergear.

Ahora se reconocen 621/625 equipables permitidos. Quedan cuatro descriptores:
Amulet Coin, Exp. Share, Linking Cord y Luck Incense, ligados a sistemas pendientes.
La tasa 2/3 sigue siendo parcial: faltan las condiciones de pasos mínimos y la
crianza de Incienso Puro. El botón «Usar» no es su activación; funcionan equipados.
El mensaje genérico tras rechazar uso directo queda como deuda de texto de UI.

Los informes ITEM_CLOSURE_V2 son snapshots cerrados de su checkpoint, no se
regeneran para certificar V23. Su antigua falta de los dos descriptores queda
superada por V23. No hay un ejecutor OpenCode trabajando en paralelo.
Los apartados V1–V21 siguientes describen checkpoints históricos.

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

Copia activa: `D:/Proyectos/Pokemon Calvo - Arquitectura Kilo`.
Original separado e intacto: `D:/Proyectos/Pokemon Calvo`.
Rama local: `codex/kilo-architecture-v1`; no hay remoto configurado.

## Arquitectura y ejecución

T001–T006B aceptadas en `208c06c0`: HUD, diagnóstico, API del campo, mochila,
puente nativo y publicación validada de partidas. El motor nativo es la
autoridad del combate. El servicio de objetos conserva las transacciones.
El motor anterior sigue teniendo consumidores; no es código descartable.

La demo principal visual hereda del mundo técnico. Tiene movimiento, encuentros,
captura, combates, mochila, PC, progresión y guardado. No es una campaña completa.
Detalles de controles y arte: `docs/project_book/VISUAL_FIELD.md`.
Perfil de combate: [BATTLE_PROFILE.md](BATTLE_PROFILE.md).

## Ataques, objetos y arte

El barrido del perfil conjunto cubre positivamente 900 movimientos permitidos
de 919 IDs: 820 ordinarios, 50 Z de daño, 19 Maxi y 11 de dobles; 19 exclusiones.
No prueba todas las combinaciones posibles. Evidencia: `UNIFIED_MOVE_SWEEP.json`.
El barrido fresco del comparador V1 pasó en ambos juegos.

Objetos: 2.222 IDs inventariados. Estado mecánico vigente:
[ITEM_SYSTEM_CURRENT_STATUS.json](ITEM_SYSTEM_CURRENT_STATUS.json).
Hay 76 efectos de campo conectados y con rutas verificadas (41 de recuperación y
35 de entrenamiento: 18 EV/amistad base, 2 de mejoras de PP, 6 caramelos, 2 de habilidades y 7 mochis EV),
además de las conexiones y límites de equipados, evolución y máquinas registrados
allí. No están certificados todos los efectos de todos los objetos.
V9: 6.456 combinaciones especie/objeto y 252 contextos de propiedad/amistad;
33.633 checks headless y 33.635 GPU. Mochila con decisiones explícitas, consumo
al finalizar, guardado/restauración y uso posterior en combate nativo verificados:
[ITEM_FIELD_V9.md](ITEM_FIELD_V9.md). Cancelar descarta la candidata sin consumir.

V10 conecta Cápsula/Parche Habilidad: 5.092 casos de catálogo, 15.376 checks
headless y 15.378 GPU; nueve grupos de verificación PASS. Prueba funcional nativa
de Absorbe Fuego, mochila real, guardado/restauración y captura. El Parche permite
revertir a la primera normal; los vetos se conservan. Modo Daruma permanece como
dependencia de formas, sin consumo; herencia de slots al evolucionar sigue
separada: [ITEM_FIELD_V10.md](ITEM_FIELD_V10.md).

V11 añade cinco bolas (Nido, Rapid, Ensueño, Sana y Honor), para nueve IDs de
captura admitidos. 10.760 casos, 32.405 checks headless y 32.407 GPU; nueve grupos
PASS. Selector nativo, consumo/RNG, fallos con restauración y cura/relojes de
Sana verificados. Se cuentan aparte de los 69 efectos de campo. La probabilidad
sigue siendo la aproximación del perfil calvo_capture_v1, sin certificar fórmula
oficial completa, capturas críticas o penalización de Ultraentes:
[ITEM_CAPTURE_V11.md](ITEM_CAPTURE_V11.md).

V12 añade Veloz/Turno/Nivel Ball: doce IDs de captura admitidos. 19.368 casos,
58.185 checks headless y 58.187 GPU; nueve grupos PASS. Turnos completados y
nivel del activo se obtienen del dueño de combate y se reconstruyen al cargar.
La reserva no concede bonus de Nivel sin entrar al campo. Las nueve bolas
anteriores mantienen sus regresiones. Siguen siendo 69 los efectos de campo;
misma aproximación de probabilidad: [ITEM_CAPTURE_V12.md](ITEM_CAPTURE_V12.md).

V13: siete rutas de mochis (+10 EV o reinicio), 30.128 casos de catálogo y 756
contextos de propiedad, 91.991 checks headless y 91.993 GPU; nueve grupos PASS.
Mochila, guardado, restauración y combate posterior verificados. Amistad intacta
según la referencia RHH; equivalencia de amistad con SV no certificada.
V13 detectó que Campana Alivio impedía iniciar nativo; su prueba de mochis usa
Restos. Detalle histórico: [ITEM_MOCHI_V13.md](ITEM_MOCHI_V13.md).

V14 corrige Campana Alivio en el adaptador propio, sin modificar los paquetes
instalados ni los manejadores de combate. Once casos nativos, 127 comprobaciones
Godot y 129 GPU; diez grupos PASS. Inicio, guardado/restauración, Desarme,
Lanzamiento, Truco y captura del receptor conservan cantidades físicas correctas.
La traza ordinaria coincide con el adaptador previo. El barrido de registro
identifica 62 otros equipables permitidos sin definición nativa; no certifica
que todos sean neutros o que todos sus sistemas existan:
[ITEM_FIELD_HELD_V14.md](ITEM_FIELD_HELD_V14.md).

V15 conecta Amigo/Safari/Competi/Gloria Ball: dieciséis IDs de captura admitidos.
17.216 casos sobre las 1.076 especies/formas permitidas; Amigo fija amistad 200
solo tras éxito, Safari/Competi usan 1,5 y Gloria 1. Se verifican costes, fallos,
RNG, equipo lleno/PC, entrada nativa y cuatro rutas reales del selector del mapa
con guardado/carga. No se agregan concursos ni regalos. Los 76 efectos de campo
se cuentan aparte; captura conserva su fórmula aproximada. Evidencia:
[ITEM_CAPTURE_V15.md](ITEM_CAPTURE_V15.md).

V16 conecta 24 medicinas equipadas mediante descriptores revisados: nombre,
generación y Lanzamiento de potencia 30, sin callbacks ni curación automática.
Las 24 se comprueban en tres perfiles nativos, y con Lanzamiento, Desarme,
Truco, Espacio Mágico y transacciones; también guardado/carga, cantidades físicas
y uso posterior desde la mochila. El registro pasa a 587/625 equipables permitidos
con definición; quedan 38 ausentes. Los usos de campo y el menú de medicina de
combate conservan sus perfiles: [ITEM_FIELD_HELD_V16.md](ITEM_FIELD_HELD_V16.md).

V17 conecta otros 17 consumibles equipados: seis vitaminas, dos mejoras de PP,
Caramelo Raro y ocho potenciadores. Contrato nativo compartido y expectativas
separadas del código productivo; regresiones de V16 y Campana conservadas.
El registro llega a 604/625, con 21 ausentes. Los usos de campo de entrenamiento
siguen funcionando; los ocho potenciadores mantienen pendiente su acción de uso
desde mochila de combate: [ITEM_FIELD_HELD_V17.md](ITEM_FIELD_HELD_V17.md).

V18 conecta Huevo Suerte a las recompensas de combate y unifica Piedra Eterna
en la elegibilidad por nivel. Componente puro, contexto inicial por identidad
reconstruido desde origin en nativo y transitorio en legado; sin nuevo schema.
4.304 casos de XP y victorias/restauraciones reales. Se conserva el reparto base
de calvo_progression_v1 y se limita el evento a XP realmente otorgada. El registro
alcanzó 606/625; V20 lleva el registro actual a 618/625, con siete pendientes: [ITEM_PROGRESSION_V18.md](ITEM_PROGRESSION_V18.md).

Arte beta de objetos: [ITEM_ART_CURRENT_STATUS.json](ITEM_ART_CURRENT_STATUS.json).
La presencia de una imagen no certifica su mecánica. Las revisiones artísticas y
los cambios de aspecto anacrónico quedan separados de esta limpieza.

## Correcciones y validación

El fallo de tipo de región en guardado se corrigió en `0e2cd3a2`, con rechazo
seguro de valores mal formados. Objetos V5–V7 cerrados hasta `eb18a5da`.
V8 añade Más PP/PP Máximos con helper puro y amistad positiva compartida;
19.872 casos de catálogo, 336 contextos y recorrido nativo de mochila/guardado/
combate/captura/restauración PASS. Detalle: [ITEM_FIELD_V8.md](ITEM_FIELD_V8.md).
Antes de caramelos se corrigió la interpretación de dos nombres de curva XP y el
divisor del tramo 69–98 de erratic. Las seis tablas completas coinciden con dos
referencias independientes; 4.209 checks y regresiones PASS. No incorpora aún
caramelos ni migra partidas antiguas: [PROGRESSION_GROWTH_CURVES_FIX.md](PROGRESSION_GROWTH_CURVES_FIX.md).
La auditoría de fidelidad a PokéAPI revisó especies, regionales, aprendizaje,
evoluciones y fichas de movimientos/habilidades/objetos. Se restauró la condición
Ataque=Defensa de Tyrogue y se conectaron sus tres comparaciones al contexto real
de progresión/validación del dueño. Procedencia de Lilligant de Hisui corregida;
textos válidos por generación y duplicado API de Baya Hibis conservados.
Alcance y pruebas: [POKEAPI_DATA_REPAIRS_V1.md](POKEAPI_DATA_REPAIRS_V1.md).
Evidencia y límites por fase en los informes de objetos; no duplicar sus matrices.

El comparador V1 terminó 135/135 casos: 86 puertas comunes PASS, 17 adicionales
de la organizada PASS, 30 intentos con fallo compartido y 2 inconclusos iniciales.
Varias repeticiones corregidas ya pasaron; esos números no son 32 fallos nuevos.
No hubo fallo unilateral de la organizada. Coinciden los 18 estados de la traza,
con 38 asserts independientes. Integridad de las fuentes verificada.
Resultado global: FINDINGS_REVIEW_REQUIRED. Informe:
[COMPARATOR_GENERAL_V1.md](COMPARATOR_GENERAL_V1.md).

Limpieza y corrección declaradas cerradas; [CLEANUP.md](CLEANUP.md) registra lo
retirado, sus límites y las pruebas posteriores. Código y recursos del juego
siguen idénticos por hash. [NEXT_STEPS.md](NEXT_STEPS.md) indica lo pendiente.
Los resultados V1 son históricos y no certifican los bytes modificados después.

Las versiones extensas anteriores de este estado y de los próximos pasos están
en Git hasta `021a9c5`. Contratos de arquitectura aceptados en `docs/kilo/`;
ADR, créditos y procedencia permanecen en sus carpetas.
