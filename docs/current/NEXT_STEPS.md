# SIGUIENTE TRABAJO

## Vigente: base de objetos inventariada — 2026-10-28

`ITEM_FOUNDATION.md`, `ITEM_FOUNDATION_V1.json` e `ITEM_INVENTORY.json/CSV`
documentan 2.222 IDs cruzados con runtime y conexiones existentes. Hay 565
entradas nativas (no se certifican todas), 15 medicinas y cuatro bolas básicas
ya conectadas. El primer lote de 21 equipados pasa 42 casos nativos y 461 checks
Godot, incluida persistencia/consumo real después de captura. Solo se añade el
mensaje nativo `-clearnegativeboost` al adaptador para Hierba Blanca.

La política nueva de selección excluye 43 IDs: cinco revivificadores (incluido
Maxipanal), Lupa/Polvo Brillo por decisión nominal delegada y las 36 cartas.
No se borra el catálogo ni se añaden vetos generales. El guardia exige soporte
explícito para generar objetos; no se han creado pools nuevos de botín/tiendas.

Siguiente: comparar arte con las 24 referencias de `ITEM_ART_PILOT.json`, luego
equipar/quitar/intercambiar con mochila y ampliar familias verificadas. MT/MO/DT
(338 entradas) requieren relación estructurada de versión/movimiento; elegibilidad
evolutiva no significa consumo desde mochila conectado. Objetos de campo y bolas
especiales siguen después. No afirmar que los 2.222 estén jugables. Gate actual
`tools/item_audit/run.py`; verificador `tools/item_audit/verify.py`.

## Antecedente: catálogo de ataques conectado y barrido cerrado — 2026-10-28

La demo normal usa `gen9calvounifiedv1` (Gen9 + entrada nativa de Dinamax); F12
usa su variante de dobles. Se conservan los efectos/fórmulas nativos y las
exclusiones existentes. Los formatos históricos y sus guardados siguen siendo
explícitos. No se aplica el presupuesto común Mega/Z/Max propuesto.

El barrido cubre los **900 permitidos**: 820 ordinarios, 50 Z de daño, 19 Maxi y
11 de dobles; 19 excluidos de un catálogo de 919. 3.358 casos generales, 72 con
prerrequisitos, 200 Z y 44 de dobles, con proyección Godot positiva y sin bloqueos.
Contratos y escenas reales comprueban PP, HP, tiempo de Dinamax, Z posterior,
segundo activo, rollback y guardado/repetición. Capturar durante Dinamax vuelve
a la colección canónica. Se corrige únicamente el rótulo visual de sol intenso.

Informe vigente: `UNIFIED_MOVE_SWEEP.json/CSV`. Contrato: `BATTLE_PROFILE.md`.
Gate: `run_unified_sweep.py`; revisión y verificación: `verify_unified_sweep.py`.
No declarar pendientes otra vez los 900 movimientos conectados. Los informes
anteriores documentan fases históricas, con sus perfiles y hashes de entonces.

Siguiente fase: objetos restantes (catálogo/política, recursos y reutilización
de su funcionamiento), seguida de las tareas pendientes de sistemas. Mega,
Ultra, teracristalización, IA profesional, randomización por niveles, muerte
definitiva/cuatro vidas, multijugador y mapas finales son trabajos separados.
Las pruebas de ataques no certifican todas las interacciones posibles; si
aparece una incidencia concreta se añade una regresión y se corrige.

## Antecedente: los 11 movimientos de dobles ya conectados — 2026-10-27

F12 del mapa habitual abre ahora un combate nativo de dos activos por equipo,
con selección de cuatro movimientos/objetivos, reservas y sustituciones. Incluye
los 11 casos pendientes desde ambos lados. Son clones de ensayo: no altera la
colección ni concede consecuencias a la campaña. El checkpoint atómico del
ensayo es independiente (`user://pokemon_calvo_doubles.json`). El modo histórico
de Cambio de Banda se conserva bajo `--legacy-field`.

44 casos nativos positivos, 454 comprobaciones Godot, 130 de interfaz sin GPU
y 196 con GPU, más 66 capturas temporales revisadas por lotes. Se comprueba
redirección, orden, mejoras del aliado, ayuda al daño, posiciones, PP, KO dobles,
reservas distintas, rollback y restauración. Se reutilizan clips y curvas de
desvanecimiento existentes, incluyendo sus movimientos/tintes de cuerpo. Los
OppMove nativos conservan sus slots canónicos; no se invierten usuario/objetivo.
No se modifica ningún PNG, export de animación, dataset ni política de contenido.

Gate actual: `python tools/showdown_engine_probe/run_doubles_integration.py`.
Capturas agrupadas con `doubles_contact_sheets.py`; evidencia comprobable con
`verify_doubles_integration.py`. Informe: `NATIVE_DOUBLES_INTEGRATION.json`.
Las regresiones del mapa, combate y guardado también pasan en esta fase.

Pendiente para cerrar ataques: acordar el perfil conjunto de generaciones y
mecánicas especiales y ejecutar el barrido final de esa configuración. Gen9,
Gen8/Max y dobles siguen explícitos; no se activa un híbrido ni un presupuesto
común Mega/Z/Max por inferencia. No se habilitan todavía encuentros dobles de
campaña ni sus recompensas. Las fixtures positivas no certifican todas las
interacciones de los 900 movimientos permitidos.

## Antecedente: combate nativo en el mapa y guardado — 2026-10-27

`JUGAR_DEMO.cmd` y la escena principal del proyecto abren el MISMO mapa existente
`field_demo.tscn`, ahora con encuentros y entrenadores por la conexión nativa.
Se conserva equipo/PC/inventario, movimiento/colisiones/travesía y arte existente.
No hay fallback automático al motor histórico si falla el trabajador. El mapa
technical y `--legacy-field` quedan como compatibilidad explícita de diagnóstico.

Ctrl+S / Ctrl+L y botones de partida guardan/cargan
`user://pokemon_calvo_field.json`: una envoltura atómica con SaveGame V2 canónico,
posición/configuración/RNG de encuentros, entrenador persistente y, si procede,
combate nativo/RNG/mochila provisional/diario de gastos. La carga valida todo y
recupera un trabajador candidato antes de publicar la nueva campaña. Se prueban
fallo de publicación y destino inválido conservando la partida anterior.

118 comprobaciones del mapa sin GPU; 123 con GPU y cinco capturas revisadas.
Incluye captura a equipo/PC, medicina, fuga, KO/cambio, victoria/derrota, XP único,
regreso al mapa, KO persistente del entrenador, recuperación de trabajador,
bloqueo durante carga, Z y checkpoint Dinamax en perfil Gen8 explícito. Ocho
checks nativos de sueño: solo se importan contadores observados; no se adivina
el contador de un guardado histórico. El diario de gastos vuelve a enteros al
restaurar para que el checkpoint sea idéntico tras JSON.

Gate vigente: `python tools/showdown_engine_probe/run_field_integration.py`;
verificar evidencia con `verify_field_integration.py`. Informe actual
`FIELD_NATIVE_INTEGRATION.json`. Regresiones PASS: SaveV2 40+8, núcleo 472,
compatibilidad visual/mapa 45+103, conexión 99, aventura 86, medicinas 120,
Node 21/10/7. Los informes anteriores conservan evidencia histórica de sus fases.

Pendiente para cerrar ataques: perfil final conjunto (Gen9 default y Gen8 con
Dinamax siguen separados y declarados), camino nativo de dobles para 11 acciones
y barrido final de esa configuración. Catálogo: 889 acciones de individuales
ensayadas + 11 de contexto doble + 19 excluidas = 919. Las tres firmas de formas
no incluidas están EXCLUIDAS; no reabrirlas como pendientes de importar formas.
La IA rival nativa sigue básica; la profesional histórica se conserva. No se
implementan todavía learnsets aleatorios, cuatro vidas/muerte definitiva,
multijugador ni el resto de objetos.

## Antecedente: bloqueos corregidos y escenarios preparados — 2026-10-27

La conversación aportada por el usuario confirma que **los 19 Maxi sí se incluyen**.
Los 53 Z continúan pendientes: no hay lista inequívoca del grupo completo y el
usuario pide consultarlo con su amigo si no queda claro. El ataque de 10 millones
de voltios se mencionó entre los ignorados/no finales; sigue sin habilitarse.
No ampliar descartes ni interpretar la antigua exclusión visual provisional de
Maxi como decisión final. Política JSON intacta; 15 descartes vigentes conservados.

Se corrigen los **12 bloqueos generales** por grupos: mensajes OHKO/cambio de
condiciones/animación, PS de Divide Dolor, alias Vice/Vise, Mimético/Transformación
y Sustituto/Relevo. Se observan PS exactos del sustituto después de los efectos
nativos, sin recrear daño; creación/daño/rotura en un turno, relevo y limpieza.
Los movimientos virtuales usan PP nativos; la persistencia usa baseMoveSlots para
recuperar forma/movimientos originales con el coste real. Esquema de captura y
salida no guarda la transformación ni PS duplicados. Revivificación deliberada
con Plegaria Vital en el propio combate se prueba en la base normal; las reglas
personalizadas de muerte/vidas permanecen aplazadas.

Barrido actualizado: **919 IDs, 3.362 casos y 13.448 decisiones**, sin bloqueos de
adaptador en las fixtures generales. Escenarios adicionales de los 48: 74 casos
nativos/72 proyecciones Godot positivas, más 11 positivos nativos de dobles.
Resultado combinado en `MOVE_CONNECTION_REPAIR.json` y CSV:

- **820** ordinarios ensayados en individuales (784 generales + 36 preparados).
- **19 Maxi** conectados en perfil explícito Gen8, con Dinamax/PP/PS, clips
  existentes, selector UI, tres turnos, guardado y vuelta a PS originales.
- **11** requieren dobles: positivos en simulador, no hay interfaz Godot de dobles.
- **1**, hyperspace_fury/Cerco Dimensión, necesita Hoopa Desatado. La lógica nativa
  pasa, pero esa forma falta del catálogo/arte actual; no usar imagen de Hoopa
  Confinado para fingirla ni inventar datos. Mantenerlo pendiente, no excluido.
- **53 Z pendientes**, **15 descartados**.

Abrir `JUGAR_COMBATE_MAXI.cmd` para la misma escena de aventura con perfil Gen8;
activar Dinamax antes del movimiento. Gen9 continúa separado: no se ha creado
un híbrido ni activado el backend en el mapa habitual. El aumento visual 1,35
es presentación provisional; ninguna imagen se redibuja ni sustituye.

Gate `python tools/showdown_engine_probe/verify_move_connections.py`: **99** checks
dedicados, **51 GPU/8 capturas revisadas**, regresiones **100 backend, 86 aventura,
120 medicinas, 23 GPU mochila, 20.809 playback**, Node 21/10/7 PASS.
Los consumidores compartidos aceptan PS/maxPS nativos y una marca Dinamax; no se
cambian fórmulas del servidor histórico. Solo cambian módulos/escenas de conexión
y esas extensiones de presentación; datos, política, arte y F: intactos.

Siguiente: resolver Hoopa Desatado y decidir alcance de dobles/perfil conjunto
antes de declarar todo cerrado. Z esperar respuesta del amigo. Después integrar
mapa/guardado y continuar objetos. No volver a implementar fórmulas por ataque;
IA profesional y reglas nuevas siguen aplazadas. Los informes anteriores son
históricos para sus hashes; evidencia vigente es MOVE_CONNECTION_REPAIR.

## Antecedente: barrido completo de movimientos; objetos en pausa — 2026-10-27

El usuario pide comprobar movimientos antes de continuar objetos. **No están
todos cerrados.** Auditoría de solo lectura `audit_moves.py` +
`verify_move_audit.py`, guía `tools/showdown_engine_probe/MOVE_AUDIT.md`.
Resumen `MOVE_FUNCTIONAL_AUDIT.json` y lista de los 919 IDs en el CSV homónimo.

3.343 casos (832 ordinarios × dos contextos × dos semillas + 15 contratos
independientes), 13.372 decisiones nativas y round trips, 3.338 continuaciones
guardadas. Todos atraviesan la proyección real de Godot por lotes. Cero errores
de ejecución nativa y 15/15 contratos esperados PASS. Esto no certifica todas las
semánticas: **772** pasan los contextos de integración, **48** requieren contextos
específicos, **12** presentan bloqueos de conexión. Además, **19 Maxi** solo
ensayados Gen8/perfil pendiente, **53 Z** pendientes y **15 excluidos**.

Bloqueos por causa compartida: `-ohko` (fissure/guillotine/horn_drill/sheer_cold),
`-swapsideconditions` (court_change), `-anim` (dragon_darts), PS simultáneos
(pain_split), alias Vice/Vise (vice_grip), movimientos/formas temporales
(mimic/transform) y Sustituto (substitute/shed_tail).

Siguiente: corregir esas causas por grupos y probar escenarios de los 48 sin
confundir requisitos legítimos (incluidos dobles) con errores. Aún no se decide
incluir/excluir más movimientos ni se ajusta política automáticamente. No volver
a objetos como si movimientos estuvieran certificados. Este barrido no modifica
código de juego, datos, imágenes, perfil ni el servidor habitual; dicho camino
histórico sigue con 620 admitidos y 230 pendientes. La IA continúa básica y las
reglas nuevas de randomlock aplazadas.

## Antecedente: mochila básica conectada — 2026-10-27

Prioridad del usuario: cerrar primero los sistemas básicos de Pokémon. Mantener
la IA básica actual; aplazar su revisión profesional y las novedades propias.
Para la fase randomlock posterior quedan apuntadas **cuatro vidas** y que los
Pokémon muertos desaparezcan del equipo en lugar de quedar debilitados. No se
implementan ni se deducen aquí otras reglas de vidas, PC, zonas o multijugador.

`JUGAR_AVENTURA_SHOWDOWN.cmd` incorpora Mochila con selección de objeto, Pokémon
activo/reserva y movimiento para Éter. Perfil compartido de **15 medicinas**:
cinco pociones, seis remedios de estados y cuatro recuperadores de PP. Mantiene
20/60/120 PS y curación total del registro previo del proyecto. Las descripciones
históricas PokeAPI de Super/Hiperpoción dicen 50/200; no se usan para ejecutar
efectos ni se modifica el dataset. Los remedios también contemplan confusión
en Cura Total/Restaurar Todo. Revivir, vitaminas y otros objetos siguen pendientes.

Showdown mantiene el estado autoritativo: medicina antes de la acción rival y
un fin de turno nativo. Objeto sin efecto/objetivo rival/KO/slot inválido no
gasta bolsa ni turno. Reserva no revela datos en el protocolo rival. Embargo
impide medicinas; Bloqueo Cura no impide una poción. Confirmación transaccional
y publicación final de bolsa/PS/PP/estados sobre los mismos objetos de colección.

Checkpoint de aventura **schema 2**: perfil de medicinas y diario de cantidades
gastadas; se rechazan inconsistencias y versiones previas sin convertirlas.
Se ha corregido una fuente de falsa divergencia de replay: los marcadores
horarios `t:` de Showdown se normalizan al serializar; no afectan reglas ni RNG.
Hay una prueba con relojes distintos, además de guardar/restaurar continuaciones.

Gate vigente: `SHOWDOWN_MEDICINE_INTEGRATION.json`, generado por
`python tools/showdown_engine_probe/verify_medicines.py`: **120 checks Godot,
21 Node, 23 GPU/5 capturas**, regresiones de aventura **86** y backend **100**.
Datos, imágenes, servidor histórico, IA y arranque habitual intactos. Referencias
locales consultadas para contrastar reglas, sin copiar su implementación Ruby.

Siguiente: completar inventario/objetos básicos que faltan, uso fuera de combate
y propietario de mapa/SaveV2; resolver fronteras de combate todavía explícitas
(sueño persistente, sustitutos/formas, perfil Dinamax/Gen9). No volver por inercia
a la IA profesional ni a reglas nuevas antes de esta base. El laboratorio sigue
siendo optativo, con colección en memoria; no certifica todo Pokémon ni activa
la campaña normal. GitHub continúa aplazado.

## Antecedente: conexión de colecciones y encuentros Showdown — 2026-10-27

`modules/gameplay/showdown_adventure_session.gd` conecta el backend optativo a
un `PlayerCollection` real. Reutiliza CaptureInventoryService, CaptureSystem,
CaptureOwnershipRouter, WildEscapeRuleset, BattleOutcome y ProgressionSystem.
No importa nuevos sistemas de otros juegos ni ejecuta fórmulas del servidor viejo.

`JUGAR_AVENTURA_SHOWDOWN.cmd` permite capturar/huir/combatir y encadenar encuentros
con el mismo equipo, PC, inventario, PS y PP. Las animaciones de captura/huida son
las existentes. Colección de prueba en memoria, sin escribir partidas de campaña.
La API también prueba entrenadores; el NPC sigue siendo la primera opción legal.

Gate: **86 checks de sesión**, **28 checks GPU / 5 capturas revisadas**, **7 checks
Node de reacciones**, y regresión Showdown **100 checks / 13 capturas** PASS.
Core **472**, playback **20.809** y corpus IA **628** PASS. Evidencia vigente:
`SHOWDOWN_ADVENTURE_INTEGRATION.json`, reproducible con
`python tools/showdown_engine_probe/verify_adventure.py`.

Se publican captura/PC, bolas gastadas, PS/PP/estados y experiencia una sola vez
al terminar. Un fallo de captura/huida usa un pass INTERNO validado de singles:
solo actúa el rival, con residuales/RNG nativos una vez. No es una acción libre
del jugador. Preparar/abortar conserva bola/RNG/turno ante errores, efectos no
representados o cambios concurrentes de la colección. Derrota no se convierte
en victoria por el fallback del constructor histórico de resultados. Los KO
previos se excluyen del equipo nativo, permanecen en colección y no reviven.
Checkpoint de sesión añade bolsa/RNG/huida y exige la misma campaña base.

Siguiente: medicinas de mochila y su conexión nativa; después observaciones,
acciones y mundos plausibles de la IA profesional. Conectar el propietario de
mapa/guardado SaveV2 y los checkpoints activos de esta sesión antes de activar
la aventura normal. No convertir LCG/sueño heredado ni mezclar perfiles Gen9 y
Dinamax por defecto. Cuotas de zona/vidas y demás reglas de campaña deben seguir
en su propietario; esta prueba no inventa ni certifica esas reglas.

El arranque habitual, sesiones históricas, datos, arte/manifiestos y F: siguen
intactos. Tres fuentes del piloto optativo cambian y se añaden sesión/escena.
No GitHub, commit, publicación ni exportado. Los informes anteriores de backend
y viabilidad describen sus versiones anteriores; este informe los sucede para
los hashes del código actual. No presentar esta fase como toda la campaña cerrada.

## Antecedente: combate jugable Showdown optativo cerrado — 2026-10-27

Ya existe `JUGAR_COMBATE_SHOWDOWN.cmd` y la escena
`scenes/visual/showdown_battle_lab.tscn`, dentro del proyecto y con los recursos
actuales. Equipo de prueba: Charizard/Blastoise frente a Snorlax/Gengar. Ataques,
curas, cambios, relevo pendiente, KO, sustituciones y victoria funcionan con el
simulador nativo. Guardado propio de la prueba, separado de campaña.

La fachada `modules/battle/backends/showdown/` usa un núcleo compartido con el
laboratorio anterior: preparar candidato → validar eventos/mirror → confirmar.
Errores, protocolos no representados y revisiones antiguas no aplican medio
turno. El guardado incluye backend, versión de simulador, perfil, datos/política,
revisión y estado/RNG nativos; se prueba cargar durante Ida y Vuelta. Al perder
el trabajador puede recuperarse el último estado confirmado. El mirror es para
presentación; no debe ejecutarse como BattleState histórico ni alimentar con
secretos a la IA profesional.

Gate: **100 checks GPU / 13 capturas revisadas**, 10 checks Node de transacciones,
472 core, 20.809 playback y 628 corpus de IA PASS. La prueba anterior también
pasa usando el núcleo compartido: 39 aserciones Node, 27 Godot y 2.496 ejecuciones/
serializaciones. Incluye regionales/shiny y reanudación después de morir el proceso.
Evidencia `SHOWDOWN_BACKEND_INTEGRATION.json`; documentación y límites en
`modules/battle/backends/showdown/README.md`.

Los **233 archivos de producción anteriores conservan sus hashes**; se añaden
cinco fuentes GDScript optativas y archivos auxiliares. El arranque habitual,
servidor histórico, datos, arte y renderer permanecen intactos. Las cifras del
juego normal siguen en 620 admitidos y 230 pendientes de mecánica. No se ha
activado Showdown para toda la aventura ni convertido guardados antiguos.

Siguiente: conectar las sesiones reales con la fachada, especialmente captura/
mochila/huida y conciliación de criaturas/resultados. Después adaptar espacio de
acciones, observaciones y mundos plausibles de nuestra IA profesional. El rival
de esta prueba solo usa su propia primera opción legal; no representa esa IA.
Mantener rollback y pruebas de ciclo de vida antes de cambiar el backend normal.
Formas/movimientos temporales, sustitutos, relojes heredados, perfil Dinamax/Gen9,
objetos externos y empaquetado siguen siendo fronteras explícitas. No avanzar
por nuevas fórmulas de ataques propias por inercia. GitHub continúa aplazado.

## Antecedente: viabilidad de Showdown — 2026-10-26

El usuario pide aprovechar sistemas estándar existentes, no continuar por
inercia implementando efectos por familias. La prueba aislada de reutilización
es positiva: `SHOWDOWN_BACKEND_FEASIBILITY.json` y
`tools/showdown_engine_probe/README.md`. **No se ha sustituido el servidor live.**
Los 233 archivos protegidos de código/configuración/datos/manifiestos permanecen
intactos; el juego sigue con 620 admitidos y 230 pendientes de mecánica.

Godot 4.7 se comunica con un proceso Node/@pkmn/sim 0.10.11 persistente. Se han
importado DTO reales de CreatureFactory con PS/PP/estadísticas/identidad,
restaurado snapshots con continuación RNG, emitido solicitudes/cambios y
proyectado un turno nativo a nuestra BattleTimelinePlan. 39 comprobaciones Node,
27 Godot y 2.496 ejecuciones/serializaciones nativas PASS. El barrido de 832
movimientos es de robustez, no certificación independiente de todos sus efectos.

Siguiente trabajo recomendado: fachada opcional/versionada para combates nuevos,
traducción genérica de solicitudes/eventos/estados y un combate visible completo.
Después conectar captura/mochila/reacciones y los mundos plausibles/espacio de
acciones de la IA existente. Conservar memoria/política profesionales y aislar
secretos del rival; el fork técnico del estado real no debe alimentar su búsqueda.
Mantener backend histórico para sesiones antiguas; no migrar relojes por aproximación.

Fronteras antes de producción: perfil moderno con Dinamax (Gen9 nativo lo
rechaza; los 19 Maxi pasan en Gen8), 60 diferencias de campos de movimientos
(mayoría Z; seis filas adicionales), alias contextual de Evocarrecuerdos,
objetos externos como Bola Humo, persistencia de formas/PS temporales y empaquetado
del trabajador/licencias. Showdown no proporciona mochila, captura, experiencia,
PC, mapa ni las normas randomlock. Sus datos/pesos pueden aprovecharse también.
No reabrir esas piezas ya trabajadas sin una razón concreta. GitHub aplazado.

Evitar añadir muchas fórmulas propias nuevas hasta cerrar esta comparación de
integración. Las implementaciones y comprobador actuales permanecen como
alternativa. Adoptar el simulador cambia el papel del comparador: confrontar el
mismo motor consigo mismo no certifica sus reglas; mantener expectativas
independientes y pruebas de conexión/persistencia/política.

## Último lote live cerrado: ocho curaciones — 2026-10-26

Integrados Aromaterapia, Cascabel Cura, Alivio, Gota Vital, Cura Selvática,
Plegaria Lunar, Purificación y Descanso. **620 admitidos / 299 no disponibles;
230 pendientes de mecánica** (162 DATA_ONLY, 57 parciales y 11 sin soporte).
No repetirlos como huecos. Informes `HEALING_MOVES.json` e informe/CSV live.

Focal: 2.546 PASS, 192 casos y 16 capturas GPU revisadas; PS del HUD iguales al
servidor. General: 9.890 PASS, 620 movimientos y 1.822 clips. Motor/playback/IA:
472/20.809/628 PASS. DATA V3 conserva 624 PASS y los nueve fallos anteriores.

El comparador ya incluye `--family healing`: **7.284/7.284 MATCH**, con 1.374 casos
nuevos de PS/estados/PP/reservas. Sus diferencias iniciales detectaron y ayudaron
a corregir las habilidades inactivas de las reservas y el redondeo de Gota Vital.
42 controles unitarios y tres negativos con motores reales PASS. Descanso tiene
además pruebas del ciclo completo en el servidor: dos acciones dormido, una con
Madrugar, despertar, cambio/guardado/repetición y cura desde la reserva.

Continuar por otra familia del CSV actual, reutilizando la investigación y
ampliando las comprobaciones durante la integración. No esperar al último
movimiento para detectar errores compartidos. Pesos, protecciones, terrenos,
move-calling y Maxi siguen con sus fronteras. El perfil permanece individual;
no ampliar dobles/IA estratégica ni modificar datos, arte o política por inercia.
Los relojes generales de sueño rival de la IA y supresión/habilidades/objetos
adicionales conservan su alcance previo. GitHub sigue aplazado.

## Fuentes descargadas para aprovechar familias — 2026-10-26

Investigación terminada, sin importar mecánicas. Tres fuentes fijadas fuera del
juego en `D:\Proyectos\Pokemon Calvo Referencias`: port Godot de Essentials,
pokerecomp (Godot Gen 1/2, MIT) y Essentials original (Ruby, CC BY-NC-SA 4.0).
Inventario/créditos/cruce en su README y `EXTERNAL_SOURCE_AUDIT.json`.
208/238 pendientes tienen entrada en ambos Essentials; esto no demuestra que
estén completos o correctos. Los 19 Maxi no están en esas tablas.

Continuar con una familia del CSV vigente aprovechando las referencias y la
comparación Showdown. Antes de copiar código, resolver condiciones del port sin
licencia explícita y compatibilidad de la fuente elegida. Conservar servidor,
RNG, save/replay e IA propios. No ejecutar importadores ni convertir tablas en
movimientos admitidos. Hallazgos: nueve rutas rotas del port y Protección con
probabilidades distintas a las modernas. Datos/código/arte del juego intactos;
seguimos en 612 admitidos, 307 no disponibles y 238 pendientes de mecánica.

## Decisión vigente: subida completa después del cierre visual — 2026-10-26

El usuario aplaza la limpieza y subida completa a GitHub hasta terminar la parte
visual del alcance acordado. Se continúa trabajando en local. El hito de subida
será tener los recursos visuales preparados y revisados, aunque todavía quede
programación; no exige terminar antes todas las mecánicas pendientes.

Antes de ese hito: cerrar los huecos visuales incluidos en el juego, revisar
procedencia/condiciones/créditos y reunir imágenes y animaciones actualmente
repartidas entre packs locales y cachés en un paquete reproducible. Comprobar que
una copia independiente encuentra todos los recursos sin las rutas de D: o F:.
Conservar los criterios confirmados: shiny solo de fuentes disponibles, sin
fabricar los 14 ausentes; regionales ya integradas no vuelven a contarse como huecos.

La futura subida debe dejar una versión actual ordenada, preservar los datos
grandes existentes y evitar copias antiguas mezcladas con los archivos activos.
No borrar repositorio, ramas, datos ni archivos históricos en esta fase. La
limpieza y publicación propuestas todavía no se han ejecutado.

## Bloque anterior: atrapamiento cerrado — 2026-10-26

Diez incorporaciones: Atadura, Constricción, Giro Fuego, Torbellino, Tenaza, Bucle
Arena, Lluvia Ígnea, Acoso, Cepo y Electrojaula. Perfil: **612 admitidos / 307 no
disponibles; 238 pendientes de mecánica** (168 DATA_ONLY, 59 parciales, 11 sin
soporte). Exclusiones/Z/dobles sin cambios. No volver a contarlos como pendientes.

Focal 1.883 PASS / 240 casos / 20 capturas revisadas y HUD exacto. General 9.858
PASS, 612 movimientos y 1.822 clips; motor/playback/IA 472/20.809/628 PASS. DATA V3
mantiene 624 PASS y sus nueve fallos. `BINDING_MOVES.json` documenta duración,
daño, contacto, salida/KO del origen, objetos/excepciones, Relevo, RUN, captura y
privacidad del reloj en la IA. Datos y arte intactos.

`python tools/battle_reference/run.py --batch-size 500`: **5.910/5.910 MATCH**
(600 etapas, 1.332 daño fijo, 3.018 potencia variable y 960 atrapamiento).
`--family binding` acota este bloque. Duración aleatoria en rango; 60 ciclos con
Garra Garfio comparan ocho turnos exactos. 36 controles unitarios + tres con
motores reales PASS. No forzar azar equivalente ni equiparar daño ordinario.

Siguiente: otra familia de la lista actual, cerrando contratos/tests antes de
habilitar. Pesos siguen sin exponer; estados/protecciones y demás mecánicas
mantienen su frontera. G-Max/Buceo, supresión y orden global de residuales
requieren trabajo separado. No reabrir IA/heurísticas por inercia: aquí solo se
comparte legalidad y se restauran estimaciones públicas. Seguir sin delegar ni
dejar tramos a medias, con GitHub aplazado.

## Bloque anterior: potencia variable cerrada — 2026-10-26

Bloque de **once incorporaciones** cerrado: Bola Voltio, Giro Bola, Azote,
Inversión, Agarrón, Estrujón, Prensa Metálica, Retribución, Frustración, As Oculto
y Castigo. Perfil actual **602 admitidos / 317 no disponibles**, de los cuales
**248** requieren mecánicas (168 DATA_ONLY, 69 parciales, 11 sin soporte).

Gate focal GPU 1.854 PASS / 264 casos / 22 capturas revisadas; general 9.818 PASS,
602 movimientos ejecutados y 1.822 clips. Core 472, playback 20.809 e IA 628 PASS.
DATA V3 conserva sus nueve fallos conocidos, sin regeneración para ocultarlos.
Informes `VARIABLE_POWER_MOVES.json`, `LIVE_MOVE_INTEGRATION.json` y CSV actual.

El barrido recomendado sigue siendo `python tools/battle_reference/run.py --batch-size 500`:
**4.950/4.950 MATCH**, 600 de etapas + 1.332 de daño fijo + 3.018 de potencia
variable. `--family variable_power` acota la nueva. 30 controles unitarios y
tres con motores reales PASS. Potencia variable compara potencia real/contacto/
impacto/PP; no confundirla con paridad de HP ordinario o de azar.

Se conserva el criterio del usuario: aprovechar mecánicas comunes y separar
excepciones, trabajar aquí sin delegar ni entregar tramos a medias. Seleccionar
la siguiente familia de la lista vigente y cerrar contratos, pruebas y clips
juntos. El grupo de atrapamiento de diez sigue como candidato sin habilitar.
Patada Baja, Hierba Lazo, Cuerpo Pesado y Golpe Calor necesitan pesos con
procedencia; continúan pendientes. Autosugestión/valores temporales, protecciones,
estados persistentes y demás grupos mantienen sus fronteras. GitHub aplazado.

## Bloque anterior: daño fijo/proporcional cerrado — 2026-10-26

Integrados Furia Dragón, Bomba Sónica, Sísmico, Tinieblas, Superdiente y Furia
Natural; corregido Calamidad ya admitido y contacto de Superdiente, sin cambiar
el dataset. **591 admitidos / 328 no disponibles; 259 pendientes de mecánica**
(179 DATA_ONLY, 69 parciales, 11 sin soporte). Las decisiones/exclusiones/dobles
conservan sus cantidades y reglas.

Gate focal GPU: 1.364 PASS, 168 casos, 14 capturas revisadas. Gate general: 9.774
PASS, 591 movimientos ejecutados y 1.822 clips comprobados. Motor/playback/IA
472/20.809/628 PASS. DATA V3 conserva sus nueve fallos conocidos (624 PASS).
Informes: `FIXED_DAMAGE_MOVES.json`, `LIVE_MOVE_INTEGRATION.json` y CSV de 328.

La herramienta externa ya compara ambas familias: **1.932/1.932 MATCH**, incluidos
1.332 casos con PS exactos de daño fijo. Sus controles pasan 24 pruebas unitarias
y tres con adaptadores reales. Comando predeterminado: `python tools/battle_reference/run.py`;
`--family fixed_damage` o `--family stat_stages` acotan el lote. No volver a
contar los 600 de etapas como movimientos nuevos ni extender paridad de daño
fijo a la fórmula de daño ordinario.

Optimización medida después: para el barrido amplio de estas familias, usar
`--batch-size 500`. Los mismos 1.932 casos pasan en cuatro lotes, 13,597 s frente
a 37,491 s del anterior de 150; entradas, observaciones y veredictos idénticos,
fuentes intactas. Evidencia: `.godot/battle_reference/batch_size_500/comparison.json`.
Medición orientativa de dos ejecuciones locales, sin cambiar el default del
script ni eliminar comprobaciones. Para incorporar más movimientos por tanda,
agrupar por infraestructura compartida y separar excepciones: hay candidatos de
10 movimientos de atrapamiento y 15 de potencia variable, todavía sin investigar
sus contratos completos ni habilitar. Los dependientes de peso necesitan exponer
ese dato con procedencia; no está en el registro normalizado actual. La amistad
sí existe en CreatureInstance. No confundir candidatos agrupados con soporte.

Siguiente: elegir una familia de mecánicas de la lista actual y extender fixtures,
normalización, tests propios y clips del juego a la vez. Daño variable, estados
persistentes, protecciones y otras familias siguen pendientes; no activarlas
por tener ya recursos visuales. Autosugestión/intercambios de valores necesitan
sus contratos de estado crítico/estadísticas temporales y siguen diferidos.
Se mantiene el aplazamiento de GitHub y el trabajo local descrito arriba.

## Bloque anterior: lote de modificadores de estadísticas — 2026-10-26

Ya existe la herramienta reutilizable de comparación por familias, autorizada
por el usuario: `tools/battle_reference/run.py`. Primer alcance: **600/600 MATCH**
para los ocho movimientos de etapas; 18 pruebas del gate y dos controles con los
adaptadores reales PASS. Compara etapas/PP/acción/sustitutos/reservas; no daño/HP
exactos ni animaciones. No aumenta el contador de movimientos admitidos.

Para los siguientes lotes mecánicos, ampliar esa familia de fixtures/adaptadores
con su contrato de equivalencia y ejecutar el barrido en grupos (por defecto 100).
Consultar `tools/battle_reference/README.md` y `BATTLE_REFERENCE_VALIDATION.json`.
Interpretar cada diferencia antes de cambiar juego o referencia: puede proceder
de una regla propia, un adaptador incompleto o una mecánica incorrecta. No
igualar semillas entre RNG distintos ni contar lo no comparable como aprobado.

Showdown permanece fuera del juego, versión 0.10.11 e integridad transitiva
fijadas, instalación local en `.godot/battle_reference/runtime/` con scripts npm
desactivados. Créditos/licencias guardados con la herramienta. La prueba inicial
de 13 casos en `.godot/showdown_research/` es histórica. No es una comparación
universal de los 585 movimientos ni importa automáticamente los 265 pendientes.

Retomada la integración de movimientos después del bloque regional/shiny. Se
habilitan seis DATA_ONLY mediante reglas live separadas: Niebla (`haze`),
Reversión (`topsy_turvy`), Cambiaalmas (`heart_swap`), Cambiafuerza (`power_swap`),
Cambiadefensa (`guard_swap`) y Acupresión (`acupressure`). También se corrigen
Niebla Clara (`clear_smog`) y Robasombra (`spectral_thief`), que estaban admitidos
pero solo hacían daño. No se cambian clasificaciones canónicas ni dibujos.

**Estado actual: 585 admitidos / 334 no disponibles**: 185 DATA_ONLY con lógica
pendiente, 69 parciales, 11 sin soporte, 15 excluidos, 53 Z pendientes y uno solo
de dobles. **265** pendientes de mecánica, sin sumar exclusiones/decisiones.
CSV e informe `LIVE_MOVE_INTEGRATION.json` regenerados desde el gate actual.

Gate del lote: **2.005 comprobaciones PASS, 192 casos, 16 capturas GPU**; ocho
movimientos, dos lados y doce semillas. Revisión de las capturas y límites en
`STAT_STAGE_MOVES.json`. Gate general: **9.750 PASS**, ejecución de los 585 y
validación de 1.822 clips. Motor 472, playback 20.809 e IA 628 PASS. DATA V3
conserva 624 PASS / los mismos nueve fallos previos.

Continuar por familias de mecánicas. Autosugestión y los intercambios de valores
base aún requieren sus contratos de estados críticos/estadísticas temporales;
no se habilitan a partir de este lote. Protecciones, otras habilidades y dobles
siguen con sus límites. Se conserva el aplazamiento de GitHub descrito arriba.

## Bloque anterior: regionales y shiny existentes integrados — 2026-10-26

Petición intercalada completada localmente: 57 regionales con sus datos reales,
1.011 parejas shiny base y 57 regionales shiny existentes. No se recrean los 14
shiny ausentes. F3 permite verlos; F1 admite IDs regionales y sufijo `__shiny`
para probar equipo, entrenador y salvaje fijo. Captura, PC, guardado, evolución y
Transformación conservan forma/color. Evidencia y límites:
`POKEMON_VARIANTS_INTEGRATION.json`; 13.807 comprobaciones GPU PASS.

No volver a contar estas 57 regionales como imágenes faltantes o sin integrar.
Otras formas especiales/cosméticas y sus mecánicas no quedan completadas por este
tramo. Las condiciones evolutivas aún no soportadas siguen bloqueadas.

En este cierre anterior quedaban las mecánicas de los movimientos permitidos, por
familias y pruebas compartidas: 579 admitidos / 271 con mecánicas
pendientes, la decisión Z pendiente y el resto de límites descritos abajo.
No se ha preparado distribución/GitHub del pack local.

## Bloque anterior: catálogo y perfil de movimientos integrados en el juego local — 2026-10-26

La petición es integrar todos los movimientos preparados en el juego habitual.
Se conecta la biblioteca visual completa y se habilitan automáticamente las
mecánicas individuales implementadas al crear las sesiones normales, sin pasar
por F7–F11. El alcance real se recoge en `LIVE_MOVE_INTEGRATION.json` y la lista
`LIVE_MOVE_UNAVAILABLE.csv`: **terminar los 19 pilotos no equivalía a tener la
lógica completa de los 919 movimientos canónicos**. No afirmar lo contrario.

Estado real del catálogo:

| Grupo | Movimientos |
|---|---:|
| Admitidos por el perfil de individuales | 579 |
| Datos sin mecánica ejecutable suficiente | 191 |
| Mecánica parcial aún no admitida | 69 |
| Sin soporte, salvo las excepciones implementadas | 11 |
| Excluidos por reglas de contenido ya acordadas | 15 |
| Decisión de contenido pendiente (Z) | 53 |
| Ally Switch: solo dobles | 1 |
| Total canónico | 919 |

Los 340 no disponibles en individuales están enumerados con ID, nombre, clase,
motivo y disponibilidad de sprites en el CSV. No se borran del dataset. Los Max
conservan su prioridad/arte: su etiqueta parcial no se convierte silenciosamente
en soporte completo de Dynamax. La decisión Z permanece pendiente; no se cambian
las reglas confirmadas ni se randomizan learnsets o niveles de aprendizaje.

`live_move_profile.gd` aplica el límite común a servidor, botones y candidatos de
IA. Las 18 mecánicas individuales de los pilotos quedan habilitadas en las
sesiones de juego creadas por `technical_overworld.gd` (también la demo visual).
Los constructores bajos de sesión/BattleState conservan la compatibilidad con
flags apagados para pruebas y consumidores anteriores; no confundirla con la
configuración actual del juego. Los presets F4–F11 siguen aislados para comparar.
Ally Switch permanece en F12; no se finge un relevo de reserva en individuales.

Jugador y NPC pueden usar pivotes/transferencias en encuentros reales. El jugador
elige reserva mediante el botón Enviar durante la pausa. El NPC continúa el mismo
turno con una selección determinista basada en sus PS/movimientos y los tipos
visibles del rival; no consulta estadísticas/PS ocultos ni consume RNG de combate
al elegir. Se mantiene el pipeline profesional de decisión principal del entrenador.
Las simulaciones de IA resuelven sus elecciones de relevo en forks aislados y
heredan el perfil y el clima público estimado, sin copiar RNG ni duración oculta
por rocas. Los snapshots conservan el contexto de perfil de forma aditiva.

Si no quedan movimientos permitidos con PP, se ofrece Esfuerzo virtual: no se
inventa un movimiento permanente en el learnset, no falla por precisión/evasión,
no usa STAB/tabla de tipos y aplica el coste de un cuarto de PS máximos redondeado
al entero próximo. Probado frente a Fantasma y con máximos impares. Las partidas
no quedan bloqueadas por tener cuatro movimientos fuera del perfil o agotados.

Visuales: **900 IDs / 1.822 clips registrados**, cargados bajo demanda desde los
shards existentes, verificando SHA. Se admiten desde eventos auténticos de daño,
estado, etapas o curación; no se reproduce un ataque como si hubiera funcionado
cuando falla su mecánica. Se usa la coreografía de cuerpos/partículas existente,
sin duplicar sprites; los movimientos propios dejan al rival visible. Las rutas
ya auditadas de impacto fino tienen prioridad. En el registro general los PS se
actualizan al finalizar el clip, conservando eventos y RNG del servidor. El renderer
congelado no cambia. Sustitutos mantienen su ruta visual específica.

Cinco admitidos carecen del par nativo por defecto (blazing_torque, combat_torque,
magical_torque, noxious_torque, wicked_torque) y usan la receta genérica de su tipo.
No se confunde registrar 900 IDs con certificar cada combinación de movimiento y
las 1.025 especies; el barrido estructural carga todos los clips y sus frames
inicial/intermedio/final, y las nuevas capturas son muestras de juego reales.

Validación nueva: **9.726 comprobaciones, ejecución determinista de los
579 admitidos en una fixture, todos los 1.822 clips y 10 capturas GPU**. Pruebas de
sesión de entrenador, NPC automático, elección humana, forks, privacidad de IA,
Esfuerzo y juego normal sin presets. Capturas: Absorber, Danza Espada, Recuperación,
Doble Equipo y selección/entrada de reserva de entrenador. Regresiones anteriores
sin fallos nuevos, incluidos 19.726 checks de playback y 628 de evaluación IA.
DATA V3 conserva **624 PASS / los mismos 9 FAIL previos**, comprobados contra la
referencia aislada. Raw, normalized, planes/reviews, catálogo y renderer mantienen SHA.

Ajustes de pruebas explícitos: el test de playback admite la actualización de PS
al final de un clip del catálogo, conservando la prueba anterior para la ruta
genérica. La comparación histórica `BATTLE_EXTERNAL_INTEGRATION.json` desactiva
el perfil en sus fixtures; sus no-ops de flags apagados no describen el juego actual.
`SWITCH_MOVE_PILOT.json` apunta al informe live, manteniendo evidencia por etapa.

Pendiente real: implementar/certificar las 271 mecánicas parciales o ausentes,
resolver las 53 decisiones de contenido, compatibilidad competitiva completa y
empaquetado/exportación de recursos locales. Los recursos nativos siguen en
caché local; no se ha preparado un ejecutable distribuible ni cambiado GitHub/CI.
No reabrir los datasets o rehacer sprites para resolver estas reglas de combate.

Evidencia: `docs/current/LIVE_MOVE_INTEGRATION.json`, `LIVE_MOVE_UNAVAILABLE.csv`,
`.godot/live_integration_checks/gpu.json` y `contact_sheet.png`. Constructor
`tools/visual/build_live_battle_catalog.py`; resumen reproducible
`tools/visual/summarize_live_integration.py`. Referencia de Esfuerzo:
<https://github.com/smogon/pokemon-showdown/blob/master/sim/battle-actions.ts>.


## Bloque anterior: Cambio de Banda en el ensayo de dobles F12 — 2026-10-26

Ally Switch (`ally_switch`, Cambio de Banda) tiene una mecánica base real en
un adaptador explícito 2 contra 2 dentro de la demo existente. F12 abre cuatro
Pokémon activos, selección de las cuatro acciones y replay; Esc devuelve al mapa.
El equipo principal, inventario, encuentros y partidas guardadas no se modifican.
No se convierte el modo habitual del juego a dobles.

El adaptador `modules/battle/server/doubles_position_battle.gd` reutiliza entidades,
reglas de daño, efectos, estados y RNG existentes, con su propio formato/versionado
de snapshot. Cada objetivo se valida y se liga a la POSICIÓN seleccionada antes
de ordenar el turno. Cambio de Banda tiene prioridad +2 e intercambia dos aliados
vivos: un golpe posterior alcanza al ocupante actual de ese puesto. No se cambia
una reserva ni se emite SWITCHED; identidad, PS, PP, estados, etapas y orden de
party permanecen en la criatura. Sin aliado vivo falla; un actor caído no actúa.

Orden de cuatro acciones por prioridad/velocidad y desempates reproducibles,
independientes del orden del paquete. Repeticiones conforme a la referencia
moderna: 1/3, 1/9… hasta 1/729; fallo elimina el contador y un turno intermedio
sin intento lo hace expirar. Se conserva al guardar/restaurar. KO, cambio de
ocupante y redirección desde un puesto caído se resuelven antes del siguiente
golpe. Tras un KO, la interfaz deja de ofrecer ese objetivo y envía las acciones
de los tres supervivientes. Fin de combate solo cuando cae un equipo activo.

Alcance cerrado de este adaptador: exactamente dos criaturas por equipo, sin
reservas, habilidades/objetos, movimientos de área, captura, progresión, IA ni
red. Solo Cambio de Banda y cuatro ataques de diagnóstico: Placaje, Pistola Agua,
Ataque Rápido y Velocidad Extrema. Rechaza atómicamente acciones/contextos no
soportados, sin gastar PP/turno/RNG. La API individual rechaza paquetes de cuatro
actores; se conserva su contrato histórico de dos acciones y su formato.
Los otros 18 pilotos individuales NO se declaran disponibles en dobles.

Presentación de cuatro sprites y posiciones desde eventos confirmados; PS y
replay no alteran el servidor. Fuentes originales ALLYSWITCH: dos líneas de
15 frames a 20 fps, solo cuerpos, sin partículas. Se reutiliza su curva de
opacidad y se refleja alrededor del intercambio, con cámara/movimiento adaptados
a cuatro actores. Los impactos de diagnóstico usan recetas genéricas existentes
por tipo. No se anuncian como VFX nativos completos ni se generan dibujos.
El renderer congelado, PNGs, catálogo y datasets mantienen sus SHA.

Evidencia de este bloque: **1.044 comprobaciones, 48 casos base servidor,
16 capturas GPU**, más pruebas de repetición, empates a cuatro, KO, dos aliados
usando el movimiento, ambos lados, snapshots, rechazos y separación de APIs.
Matriz base: ambos equipos, ambos puestos y doce semillas. Cuatro casos de UI
capturados antes/intercambio/impacto redirigido/después; el snapshot autoritativo
es idéntico durante todo el replay y la party principal permanece intacta.

Acumulado F7–F12: **7.411 comprobaciones, 528 casos base y 77 capturas**.
Los **19 casos originales tienen ya pilotos de mecánica base delimitados**:
18 individuales en F7–F11 y Ally Switch en este ensayo de dobles independiente.
Esto NO cierra los 19 handoffs de producción ni certifica un motor competitivo
completo. Permanecen pendientes despliegue general, IA/elección de relevos,
compatibilidad entre mecánicas y todas las excepciones de los informes anteriores.

Siguiente trabajo recomendado: consolidar el perfil de individuales (18 pilotos)
con la sesión, interfaz y decisión de relevos de la IA, conservando restricciones
según formato. Ally Switch no debe entrar al sorteo de individuales como si fuera
un cambio de reserva. Dobles completo necesita su propia integración posterior;
no ampliar ahora este adaptador a todas las mecánicas sin contratos y pruebas.

Regresiones anteriores sin fallos nuevos: motor 472, comandos 56, cambios 49,
captura 68, huida 94, vertical slice 62, guardado 40, campo 45, playback 19.726,
bindings previos 407 e IA 628. DATA V3 mantiene **624 PASS / los mismos 9 FAIL
previos**, verificados contra la referencia aislada; no se regeneran datos.

Informes: `docs/current/ALLY_SWITCH_PILOT.json`, `SWITCH_MOVE_PILOT.json`;
`.godot/ally_switch_checks/gpu.json`, `positions_contact_sheet.png` y
`motion_contact_sheet.png`. Constructor `tools/visual/build_ally_switch_pilot.py`.
Reglas: <https://github.com/smogon/pokemon-showdown/blob/master/data/moves.ts>.


## Bloque anterior: Transformación reversible en F11 — 2026-10-26

F11 recorre Ditto frente a Wailord, Pikachu y Charizard en la demo existente.
Activa `transform_rules_enabled` y los pilotos anteriores solo para nuevos
encuentros de este ensayo. Reiniciar restaura el equipo/learnsets naturales;
no despliega la interfaz/IA de entrenadores ni habilita Transform globalmente.
La clasificación canónica `UNSUPPORTED` permanece congelada.

La transformación copia especie/tipos estáticos representados, estadísticas
excepto PS, niveles de estadísticas, habilidad, movimientos y el volátil crítico
`focus_energy` representado. Los movimientos copiados empiezan con min(5, PP base),
incluso si el rival había agotado los suyos. Conserva PS actuales/máximos, nivel,
identidad, objeto y su consumo, estado persistente, IV/EV, naturaleza y progresión.
No copia los demás volátiles del rival; conserva su propio sustituto. Falla ante
un objetivo con sustituto (también con Infiltrator), otro transformado o una
transformación ya activa; contextos no soportados de Illusion/Dynamax/Tera se
rechazan expresamente. Arrancan solo los callbacks de habilidad ya representados,
como Intimidate, sin repetir triggers de entrada de objetos.

La criatura guarda una base temporal separada de sus volátiles, con sus PP
originales DESPUÉS de pagar Transformación. Se restaura al cambiar, caer KO,
terminar el combate, expulsar, capturar o huir, y en reconciliación poscombate.
Snapshots JSON conservan la copia y esa base; un Relevo copiado puede pausar,
guardar/restaurar y continuar el turno, pasando etapas/sustituto sin transmitir
la transformación. La captura usa la especie original para su probabilidad y
entrega la misma instancia restaurada; experiencia/identidad también usan la
especie original. La restauración precede la reconciliación de progresión.

Imagen y menú siguen eventos confirmados y una proyección separada del estado.
Ditto conserva su nombre y su nivel/PS mientras usa el sprite correcto frontal
o trasero de la especie copiada. Los botones se actualizan con sus ataques y PP
temporales; al volver recupera Transformación con el PP gastado. Tras captura se
conserva la imagen original confirmada del equipo, aunque BattleState ya se haya
liberado. El replay no ejecuta mecánicas ni consume RNG.

Adaptación visual registrada: los dos clips originales `TRANSFORM` contienen
15 frames a 20 fps, solo cuerpos, SIN partículas. Se conserva el handoff del
laboratorio en el frame 8 y se utiliza una breve compresión/desvanecimiento con
los sprites existentes. No se anuncia como VFX nativo completo ni se generan
imágenes/PNGs. El renderer, catálogo, clips fuente y datasets siguen intactos.

Validación: **1.221 comprobaciones, 72 casos servidor y 12 capturas GPU**.
Tres especies, ambos lados y doce semillas, PP, tipos/STAB, objetos/progresión,
JSON, efectos de habilidad, Relevo copiado, cambio/KO, captura del rival transformado,
huida y limpieza real de sesión. Las capturas frontales son proyecciones aisladas;
las traseras y el menú se comprueban en encuentros reales. También se ejecuta
Transformación del rival dentro de la demo antes de capturarlo.

Acumulado F7–F11: **6.367 comprobaciones, 480 casos y 61 capturas**, para
**18 mecánicas base opt-in de los 19 casos**. Resta `ally_switch`, que necesita
formato de dobles/posiciones de aliados; no fingirlo como un relevo de reserva en
individuales. Continúan pendientes el despliegue general/interfaz/IA y certificar
las interacciones completas. Los 19 handoffs de producción no se declaran cerrados.
Transform no añade automatización de Imposter, tipos dinámicos/Tera, cambios de
forma avanzados ni todas las excepciones y ciclos de habilidades.

Regresiones del motor, comandos, cambios, captura, huida, guardado, campo,
19.726 checks de playback, 407 de bindings anteriores y 628 de evaluación IA sin
fallos nuevos. Auditoría DATA V3: **624 PASS / los mismos 9 FAIL previos**, comprobados
contra la referencia aislada. No se regeneran datos para ocultarlos.

Evidencia: `docs/current/TRANSFORM_PILOT.json`, `SWITCH_MOVE_PILOT.json`,
`.godot/transform_checks/gpu.json` y `.godot/transform_checks/contact_sheet.png`.
Constructor `tools/visual/build_transform_pilot.py`: fija las dos líneas de tiempo
originales y su procedencia, sin regenerar el catálogo ni copiar nuevos PNGs.
Referencia: Pokémon Showdown, `sim/pokemon.ts::transformInto` y `data/moves.ts`:
<https://github.com/smogon/pokemon-showdown/blob/master/sim/pokemon.ts>.


## Bloque anterior: Sustituto y Autotomía (Shed Tail) conectados en F10 — 2026-10-26

F10 alterna `substitute` y `shed_tail` en la demo existente. Habilita
`substitute_rules_enabled` y los relevos solo en encuentros nuevos de ese ensayo;
reiniciar devuelve el equipo/learnsets naturales y desactiva el piloto. F7/F8/F9
conservan sus ensayos. No se habilita la interfaz/IA de entrenadores.

Sustituto paga floor(PS máximos/4), falla sin PS suficientes o con otro muñeco,
y conserva sus propios PS. Cada golpe se limita a los PS restantes del muñeco:
el exceso no pasa al Pokémon; un golpe posterior de un ataque múltiple sí puede
alcanzarlo tras romperlo. Bloquea los efectos sobre el objetivo de las familias
representadas (estado, retroceso de turno y cambios de estadísticas), incluso
cuando el mismo golpe lo rompe; no consume la tirada de una secundaria bloqueada.
Drenaje/recoil usan el daño realmente recibido por el muñeco. No dispara la
represalia de contacto del defensor por un golpe absorbido. Daño residual,
sonido, Infiltrator y los bypass declarados siguen su ruta correspondiente.
La expulsión dañina no atraviesa un muñeco roto por ese mismo golpe.

Shed Tail paga ceil(PS máximos/2), exige reserva viva y espera una elección real.
Transfiere únicamente el sustituto, con sus PS restantes, antes de los triggers
de entrada; no pasa estadísticas ni otros volátiles. El turno continúa sin otro
PP/tick; un guardado durante la elección produce los mismos eventos al restaurar.
Relevo conserva el muñeco mediante su whitelist ya existente; el cambio ordinario
lo retira. No hay certificación de todas las interacciones competitivas.

Presentación: cuatro clips de creación originales (ambos lados), el muñeco
original frontal/trasero y persistencia proyectada desde eventos auténticos.
Ajuste de cámara al punto de apoyo real del muñeco y ocultación de la copia
persistente durante la creación nativa: se detectó/corrigió el duplicado durante
la revisión. Los impactos contra el muñeco usan la receta genérica existente por
tipo; no se presentan como una certificación de todas las animaciones originales
sobre objetivos de ese tamaño. No se modifican PNGs, renderer congelado ni catálogo.

Validación: **453 comprobaciones, 48 casos servidor, 9 capturas GPU** para este
bloque. Acumulado F7–F10: **5.146 comprobaciones, 408 casos y 49 capturas** para
**17 mecánicas base opt-in**. Restan sin implementar `transform` y `ally_switch`
(este último requiere dobles). Los 19 handoffs de producción siguen abiertos
hasta integrar/certificar su alcance completo; no son 17 movimientos competitivos
terminados. Siguen pendientes supresión/Mold Breaker, excepciones de movimientos,
Dynamax y el despliegue general/IA. No reabrir los cientos de clips ya revisados.

Evidencia: `docs/current/SUBSTITUTE_PILOT.json`, `docs/current/SWITCH_MOVE_PILOT.json`,
`.godot/substitute_checks/gpu.json` y `.godot/substitute_checks/contact_sheet.png`.
Constructor local: `tools/visual/build_substitute_pilot.py`; copia los cuatro clips
y el muñeco desde los recursos existentes sin regenerar datasets ni catálogo.
Referencia de reglas: Pokémon Showdown, `data/moves.ts` (2026-10-26, SHA256
`43b516fdc01721f53f01de555479dd3d248e5e29d2a6f5072a7bd4a3585a5027`).

Regresiones del motor/presentación/captura/huida/guardado/campo/IA sin fallos nuevos.
La auditoría DATA V3 mantiene sus **624 PASS / 9 FAIL previos**, con los mismos IDs
que la referencia aislada; no se regeneran datos para ocultarlos. Raw, normalized,
índice de clips, planes/reviews congelados y renderer conservan sus SHA anteriores.


## Bloque anterior: climas y Fría Acogida conectados en F9 — 2026-10-26

F9 recorre rain_dance, hail, sandstorm, snowscape y chilly_reception. Equipo
Charizard/Lapras/Golem nivel 50, Wailord al 100 %, con Pistola Agua, Lanzallamas
y Placaje para contrastar el clima. Reiniciar desactiva el piloto y restaura
los learnsets naturales del equipo seleccionado. F7/F8 conservan los diez casos
anteriores. El formato entrenador se prueba en el motor, pero no se habilita
todavía en interfaz/IA.

Estado de clima serializado, cambio/sustitución, duración cinco turnos u ocho
con roca válida no consumida, y mismo clima sin reiniciar contador. Expiración
antes de su último callback residual, conforme al orden de referencia: el turno
de activación cuenta y no se añade daño una vez terminado el clima. Fría Acogida
establece nieve antes de pedir reserva; espera esa elección sin gastar otro
turno y también releva si ya nevaba, sin prolongarla. Los metadatos numéricos del
clima se restauran como enteros para conservar eventos idénticos tras JSON.

Implementado en este alcance: lluvia potencia Agua/reduce Fuego; arena mejora
Defensa Especial de Roca; nieve mejora Defensa física de Hielo. Granizo/arena
aplican daño residual y sus inmunidades declaradas; nieve no causa daño de
granizo. Cloud Nine/Air Lock anulan efectos sin borrar el contador. Rain Dish e
Ice Body curan en el clima apropiado. Un relevo por KO climático no recibe un
segundo tick de estado/objeto ese mismo turno.

Fuentes visuales originales: diez activaciones y cuatro bucles comunes,
442.397 bytes PNG copiados. Common:Sandstorm conserva 20 frames; los otros tres
30, todos a 20 fps. Nieve/granizo comparten el arte original, con reglas distintas.
El efecto sigue visible entre acciones y durante la captura hasta cerrarla.
No se han regenerado catálogos ni sustituido dibujos.

`WEATHER_PILOT.json`: **1.523 PASS, 120 casos del servidor, 11 capturas GPU**.
Observadas lámina de cinco activaciones/persistencia y nieve antes de elegir
reserva. Las nuevas capturas de activación son back; ambos lados se verifican
en el motor, sin atribuir a esta fase una nueva certificación visual front.
Acumulado V3 en `SWITCH_MOVE_PILOT.json`: **4.693 checks, 360 casos, 40 capturas,
15 movimientos**, componentes separados. Regresiones: F7 1.844, F8 1.326,
reproducción 19.726, enlaces previos 407, modo predeterminado 475, corpus IA 628,
núcleo 472, comandos 56, cambio 49, captura 68, huida 94, vertical 62, guardado
40 y campo 45 PASS. Auditoría de datos: mismos 624 PASS/9 FAIL preexistentes.

**Quedan cuatro IDs sin mecánica propia:** substitute, shed_tail, transform y
ally_switch. Siguiente grupo: substitute/shed_tail comparten protección y PS
del muñeco. Después transformación y cambio de aliado (dobles). Separadamente
queda el despliegue de estos 15 en entrenador/IA, y completar interacciones:
habilidades de velocidad/evasión, Dry Skin/Hydration, movimientos dependientes
del clima, cambios de clima por habilidades y supresión de habilidades/objetos.
No certificar todos esos casos por tener el clima base. Los 19 handoffs globales
siguen abiertos; se han implementado 15 mecánicas base en pilotos explícitos.
Datos, imágenes originales, renderer, índice y reglas del pool intactos.
Sin commit/push/merge.

## Tramo anterior conservado: cinco movimientos de estado añadidos; diez mecánicas en piloto — 2026-10-26

Se ha cerrado el bloque interrumpido de Rugido, Remolino, Teletransporte, Relevo
y Última Palabra. **F8** recorre estos cinco en encuentros salvajes individuales
con tres Pokémon propios de nivel 50. F7 conserva los cinco ataques anteriores;
F6 sigue siendo el contraste SOLO DAÑO. Reiniciar restaura los learnsets
naturales del equipo seleccionado y desactiva las mecánicas del piloto.

Rugido/Remolino expulsan a una reserva viva aleatoria en formato entrenador o
cierran el encuentro salvaje si cumplen nivel y bloqueos. Ambos atraviesan el
marcador de sustituto; Rugido respeta Insonorización. Teletransporte sigue la
regla moderna: el Pokémon del jugador releva incluso contra salvajes; solo un
usuario salvaje termina el encuentro. Relevo pasa etapas de estadísticas y el
subconjunto explícito de volátiles admitidos, antes de las habilidades de entrada;
no transmite el problema de estado persistente. Última Palabra baja Ataque y
Ataque Especial antes de pedir reserva; si no hay reserva, conserva la bajada.
Se prueban sus bloqueos y reflejos, Contrario, Simple, Competitive y Defiant,
sin certificar todas las interacciones futuras.

Corregido el cierre numérico de snapshots del piloto: JSON convierte números
en float; los enteros exactos del payload se normalizan para que Relevo restaure
idéntico estado. Se conservan fracciones y el formato histórico deshabilitado.

Evidencia: `STATUS_SWITCH_MOVES.json`, **1.326 PASS, 120 casos del servidor,
diez clips y 18 capturas GPU**. Dos láminas observadas (ambos lados y combate
salvaje/elección); textos de cambios de estadísticas legibles en español.
Acumulado `SWITCH_MOVE_PILOT.json`: **3.170 comprobaciones, 240 casos, 29 capturas,
diez movimientos**, con los componentes separados. Regresiones finales PASS:
núcleo 472; comandos 56; cambio normal 49; captura 68; huida 94; vertical 62;
guardado 40; campo 45; reproducción 19.726; enlaces anteriores 407; modo
predeterminado de los 19 casos 475; corpus IA/entrenadores 628. Auditoría de datos
624 PASS/9 FAIL, mismos nueve que el núcleo anterior; no se ocultan ni regeneran.

**Quedan nueve IDs sin mecánica propia:** ally_switch, chilly_reception, hail,
rain_dance, sandstorm, shed_tail, snowscape, substitute y transform. Siguiente
grupo propuesto: estado/eventos/duración/interacciones de los cuatro climas,
aprovechándolo para Fría Acogida. Después substitute y shed_tail (comparten el
estado de sustituto), transform y ally_switch en dobles. Usar los IDs canónicos
para identificar con precisión los movimientos pendientes.

**También queda el despliegue:** interfaz/elección del entrenador y sus
simulaciones de IA no gestionan todavía estas pausas. Los diez solo se habilitan
en el ensayo salvaje F7/F8; el motor en formato entrenador se ha probado en ambos
lados. No activar globalmente ni cerrar los 19 handoffs por este piloto. También
faltan interacciones completas de sustituto/Dynamax, Prankster, supresión de
habilidades/Mold Breaker, Magic Coat y escudos de lado. La cola global permanece
en 19 IDs/38 clips; el recuento de mecánicas base pasa de cinco a diez.

Fuentes, PNG, renderer, índice, datos y reglas del pool intactos. Se copian diez
clips ya revisados, 12.277 bytes PNG; Whirlwind conserva la equivalencia GUST ya
seleccionada. Inventario de alternativas sin aumento: 41 IDs/49 familias/98 clips.
Sin commit/push/merge.

## Tramo anterior conservado: piloto de cinco mecánicas de relevo/expulsión — 2026-10-25

**F7 en la demo:** Llave Giro, Cola Dragón, Viraje, Ida y Vuelta y Voltiocambio.
Ensayo individual explícito con Charizard, Pikachu y Blastoise nivel 50 y Wailord
salvaje al 100 %. Tres movimientos permiten elegir reserva antes de continuar
el mismo turno; dos terminan el encuentro salvaje si se cumplen las condiciones.
Reiniciar reconstruye el equipo seleccionado con su learnset natural y desactiva
el piloto. F6 conserva el contraste anterior SOLO DAÑO.

Motor autoritativo: fase `waiting_for_switch`, petición con dueño/candidatos,
elección validada y acciones restantes serializadas. Restaurar un servidor a
mitad del turno conserva la continuación/RNG. Ningún turno, PP ni tick de estado
adicional por elegir reserva. Expulsión en formato entrenador selecciona una
reserva viva con RNG del combate; en salvaje individual cierra sin XP/captura
si nivel usuario >= objetivo. KO, inmunidad, fallo, falta de reserva y represalia
de contacto probados. Cuatro marcas de contacto erróneas del snapshot se corrigen
en copias de ejecución, exclusivamente dentro del piloto; datos originales intactos.

Evidencia `SWITCH_MOVE_PILOT.json`: **1.844 PASS, 120 casos del motor, 11 capturas
GPU**. Lámina de golpes/elección y entrada de Blastoise observadas. Regresiones:
núcleo 472, comandos 56, cambio normal 49, captura 68, huida 94, vertical 62,
guardado 40, campo 45, reproducción 19.726, enlaces anteriores 407, auditoría
predeterminada de los 19 casos 475, corpus IA/entrenadores 628 PASS.

La batería de datos da 624 PASS/9 FAIL tanto antes como después: seis referencias
ausentes en `data/api` y tres discrepancias de informes locales. Comparación
aislada con los cinco archivos originales del núcleo/sesión, sin alterar el
workspace. No regenerar el dataset para ocultar esos fallos.

**Pendiente inmediato: consumidores de entrenador/IA.** El motor admite elegir
reserva para ambos lados y el formato entrenador se ha probado, pero el piloto
solo se activa en encuentros salvajes F7. La interfaz del entrenador y sus
simulaciones necesitan resolver esa petición y continuar el turno sin escoger
silenciosamente la primera reserva. No activar globalmente antes de integrar ese
contrato. Después, implementar los otros 14: Rugido/Remolino, relevos de estado,
climas, sustituto, transformación y Ally Switch. No atribuir a estos cinco el
soporte de Substitute, Dynamax o supresión de habilidades; sus interacciones
completas todavía no están certificadas.

Recuento: cinco mecánicas base en piloto, 14 IDs sin implementación propia y
despliegue global todavía pendiente para los cinco. La cola global de 19 IDs/
38 clips permanece abierta; no equivale a cero progreso mecánico. Inventarios
artísticos intactos, sin nuevas imágenes, datos ni catálogo. Sin commit/push/merge.

## Tramo anterior conservado: integración parcial contrastada con el motor real — 2026-10-25

Se han conectado diez clips (cinco movimientos, ambos lados) al daño confirmado
del combate: circle_throw, dragon_tail, flip_turn, u_turn y volt_switch. F6 en
la demo ofrece un ensayo desechable explícitamente marcado SOLO DAÑO. Reiniciar
restaura el learnset. No ejecuta todavía el relevo ni la expulsión.

**Los 19 efectos especiales siguen pendientes; ninguno se cierra como completo.**
Las 38 pruebas del servidor autoritativo muestran cinco movimientos con daño
ordinario y otros catorce que consumen PP sin producir su efecto especial.
Cuatro etiquetas RUNTIME_SUPPORTED cubren aquí solo daño; no certifican el
relevo/expulsión. Trece DATA_ONLY y Transform/UNSUPPORTED resultan sin efecto en
estas pruebas. No se han cambiado sus etiquetas ni las definiciones canónicas.

Informe reproducible: `BATTLE_EXTERNAL_INTEGRATION.json`, status PARTIAL,
validación PASS; detalle por ID y hashes. Gate GPU: 475 comprobaciones, 38 casos
del motor, 11 impactos nativos en combates reales, 12 capturas; lámina de diez
vistas y mapa observados. Regresiones PASS: reproducción 19.726; cinco rutas
anteriores 407; recetas visuales 4.949; ruta/mapa 45.

**Próxima fase para discutir: Battle Core, antes de completar estos enlaces.**
Agrupar los relevos y expulsiones con su elección de reserva/continuación de
turno y diferencias salvaje/entrenador; después estado, eventos, duración e
interacciones de clima; sustituto con PS/protección; transformación con estado
copiado; Ally Switch requiere el contrato de dobles. El motor resuelve el turno
atómicamente y no tiene los estados/eventos necesarios para varios de estos
casos. No resolverlos escogiendo silenciosamente el primer Pokémon de reserva
ni simulando resultados dentro del reproductor de imágenes.

La cola artística permanece en 74 IDs/118 clips cerrados y 19 IDs/38 clips
externos abiertos. El inventario de sustituciones sigue en 41 IDs/49 familias/
98 clips. Hay diez IDs/20 clips enlazados a presentación de combate en total,
pero los cinco añadidos ahora tienen alcance SOLO DAÑO. Catálogo, fuentes,
renderer, datos, learnsets, IA y mecánicas intactos. Sin commit/push/merge.

## Tramo anterior conservado: revisados los 24; cinco contrastes cerrados y 19 integraciones pendientes — 2026-10-25

Revisados los 24 IDs/48 vistas. Fragor Escamas corrige el ancla del receptor en
ambos lados; Cambio de Cancha vuelve suavemente a sus plazas en los ocho últimos
frames. Aerochorro, Mismo Destino y el recurso DOOMDESIRE se contrastan con la
fuente sin sustitución. Nueve clips de cola cerrados: Clanging back también se
corrige, pero no estaba en esa cola y no se descuenta otra vez.

Acumulado **74 IDs/118 clips cerrados**. Quedan **19 IDs/38 clips de presentación
externa**, cero contrastes pendientes. Las 38 fuentes nativas de esos 19 ya se
han revisado en grupo; no repetir ese barrido como si faltaran imágenes. No
contarlos como resueltos solo por reproducir su archivo: falta el resultado
externo real. Hay seis muestras LAB opcionales, no seis integraciones completas.

**Siguiente trabajo: conectar presentación con el estado/eventos del combate.**
Agrupar por relevo del usuario, expulsión del rival, clima, sustituto,
transformación y aliado en dobles. Antes de ampliar bindings, comprobar qué
eventos emite realmente el motor para cada clasificación; DATA_ONLY no se vuelve
ejecutable por tener animación. Empezar por los contratos de expulsión de
circle_throw/dragon_tail y por los climas que ya tienen muestra; no recrear
sprites ni simular que se ha cambiado de equipo sin un resultado autoritativo.
Los IDs/requisitos por vista están en `CONTENT_POOL_AUDIT.json`, campo
`external_presentation_handoffs`, y la tabla humana en VISUAL_CATALOG.

Descubrimientos para esa fase: existen `Move:DOOMDESIRE` y las variantes
`Move:DOOMDUMMY`/`OppMove:DOOMDUMMY` de 42 frames. Hay que verificar su asignación
final a carga/impacto y conectar las fases con eventos reales; esta auditoría
no certifica esa correspondencia solo por los nombres. `Common:Sandstorm` existe
con 20 frames y no entra en el adaptador
actual de tres climas/30 frames. Integrar sus tiempos explícitamente; no alargar
ni recortar silenciosamente para encajar un contrato de 30 frames. No son nuevos
huecos del dataset ni se han conectado por esta auditoría.

Review `.godot/move_general_checks/418254331eca04dc/gpu/review.json`, SHA
`208ad6d39b44df9741027494f35c502158b96252f0a2aa5bef0575927f1addc5`.
Nueve láminas: cinco contrastes y cuatro de contexto agrupado, observadas.
Gate GPU **593.828 PASS**, 2.532 estados de captura, 960 pares/1.920 PNG;
contrato 12.660 estados, cinco parejas/dos arenas, 540 anclas de receptor y
40 finales de Cambio de Cancha comprobados, cuatro exports alterados rechazados.
Repetición headless final: 591.908 PASS, incluyendo los avisos finales del laboratorio.
48 exports contrastados con fuentes inertes; conserva la reparación histórica
de 11 focos de Fría Acogida front. Sin visionado de movimiento en tiempo real.

Renderer `7674d3a61e113e085d12132a4e10461aedd3a760516ab68700f2868f0f3fd4de`;
contexto `e1221ddaae3b2375`, mismos arte/frames/bindings. Catálogo completo
5.366.237 PASS/118.766 estados/1.822 clips; lote Z 317.062; contexto 6.442;
cinco rutas 407; perfil/laboratorio 1.898 PASS. Inventario de alternativas sigue
en 41 IDs/49 familias/98 clips; aquí no se sustituyen imágenes. Datos, fuentes,
índice, reglas del pool, mecánicas, workflows y HEAD intactos. Sin commit/push/merge.

## Tramo anterior conservado: lote de siete Z cerrado — 2026-10-25

El usuario autorizó retomar los Z. Se revisaron siete IDs/14 clips: cinco opciones
artísticas parciales, salto de Marshadow encuadrado y Guardián de Alola verificado
sin alterar sus transparencias originales. Las opciones están etiquetadas como
PARCIAL/EQUIVALENTE ARTÍSTICO en laboratorio; ninguna mecánica o ruta nueva.

Acumulado **69 IDs/109 clips cerrados**. Quedan **24 IDs/47 clips: cinco de
contraste +19 de contexto**. Los siete Z ya no están en espera artística. La
decisión sobre incluir todos los Z en el juego sigue pendiente: `pending` en
el perfil solo expresa esa decisión, no una revisión visual pendiente.

Review `.godot/move_z_checks/c2a52b27e855bafa/gpu/review.json`, SHA
`1be9f5844bbe15fd7eb487d01c8a07d36eed7f8ab0ebfa911518112347793913`.
Siete láminas observadas, 280 pares/560 PNG iguales al candidato seleccionado;
gate GPU 317.622 PASS, captura de 2.724 estados y contrato de 16.320 estados,
cinco parejas/dos arenas. Las 80 poses de emergencia de Marshadow caben con
margen de 8px, incluidos cuerpos grandes. Guardián conserva alpha225/255 en
el receptor del último frame; no se ha fingido una fuente final totalmente opaca.

**Siguiente lote activo:** aeroblast, clanging_scales, court_change, destiny_bond
y doom_desire. Comparar fases/roles y agrupar causas comunes. Mantener los
19 contextos separados de los huecos de fuentes: cinco Torque y un Z todavía
sin fuente propia, de prioridad secundaria. No volver a buscar los 13 Let's Go
descartados. Leer RANDOMLOCK_RULES y registrar toda sustitución en VISUAL_SUBSTITUTIONS.

Renderer `16892e3fcdd25ab448a42e45d1a96f48dba4863ed28adddf1863bf23de770c26`.
Contexto actualizado `3bcab4075e9a7662`, mismos recursos/frames/bindings.
Regresiones: catálogo 1.822 clips/118.766 estados/5.366.237 PASS; motivos previos
92.247; contexto 6.442; cinco rutas 407; perfil/laboratorio 1.898, todas PASS.
El menor contador del catálogo refleja partículas auxiliares omitidas, sin
retirar clips. Inventario: 41 IDs/49 familias/98 clips con selección alternativa.
Fuentes, datos, índices, snapshots anteriores y mecánicas intactos. Sin commit/push/merge.

## Tramo anterior conservado: aplicar exclusiones — 2026-10-25

Reglas en `../project_book/RANDOMLOCK_RULES.md`; configuración ejecutable
`config/randomlock_content_v1.json`; cruce reproducible `CONTENT_POOL_AUDIT.json`.
Confirmada la exclusión de Nincada, Ninjask y Shedinja, además de Wishiwashi,
Minior, Castform/todas sus formas y los ocho Pikachu con gorra. 16 habilidades
únicas vetadas. No borrar datos, recursos ni modificar daño/tabla de tipos.

15 movimientos locales descartados: Splash, Power Shift y 13 exclusivos de
Let's Go. Los 18 oscuros de Colosseum/XD no están en los datos, pero quedan
registrados para futuras importaciones. No excluir por generación ni por el
prefijo shadow_. No seguir buscando los 13 huecos de Let's Go.

**Z: decisión pendiente del usuario.** Sus siete casos pendientes se ponen en
espera, sin contarlos como PASS ni como descartes definitivos. Los 19 Max se
mantienen. De los seis huecos de fuentes restantes: cinco Torque activos y
10,000,000 Volt Thunderbolt en espera Z.

**Siguiente lote activo:** aeroblast, clanging_scales, court_change, destiny_bond
y doom_desire. Comparar fases/roles y agrupar solo causas comunes; registrar
cualquier sustitución en VISUAL_SUBSTITUTIONS. Quedan aparte los 19 contextos.
No revisar los siete Z mientras su decisión siga pendiente.

El laboratorio abre con el filtro del pool: 846 IDs/1.714 clips; desactivarlo
permite investigación completa de los 900 IDs/1.822 clips. Este es un filtro
de selección, no el randomizador final ni soporte mecánico nuevo. Los futuros
productores del Randomlock deben consumir la misma política y la frontera runtime.

Contrato de perfil/laboratorio 1.898 PASS; contexto 6.442 PASS; cinco rutas de
combate 407 PASS. Auditoría verifica fuentes inmutables. Histórico conservado:
62 IDs/95 clips cerrados; cola original 31 IDs/61 clips, ahora 24 activos/47 clips
y siete Z en espera/14 clips. Sin nuevos arreglos artísticos, commit, push o merge.

## Tramo anterior conservado: motivos específicos sustituidos — 2026-10-25

Octavo tramo terminado: Embate Supremo back/front usa impacto metálico neutro
del mismo atlas; Pikavoltio Letal back/front conserva fase eléctrica sin insignia.
Elecciones artísticas parciales etiquetadas en UI, sin modificar fuentes ni
datos. Dos IDs/cuatro clips cerrados: **62 IDs/95 clips cerrados**, pendientes
**31 IDs: 12 de contraste y 19 de contexto**, 61 clips.

Review `.godot/move_art_motif_checks/21fa00b2ed6f3953/gpu/review.json`, SHA
`9967c418ad6de0b6a3d4905f998beb09139e96fefd7288692614737f570efe96`.
Dos láminas antes/después, 88 pares; gate 92.447/2.136 estados PASS y 64 muestras
coincidentes con candidatos observados. Catálogo 1.822 clips PASS y regresiones
de los siete grupos previos. Renderer `a9e655948ae2…`, contexto `d45df89b77577919`.
Inventario actualizado: 36 IDs/44 familias/88 clips con alguna alternativa;
no confundir dos selecciones parciales del renderer con nuevos exports nativos.

**Siguiente lote previsto entonces (sustituido por la cola vigente de arriba):** `extreme_evoboost`, `genesis_supernova`,
`lets_snuggle_forever`, `savage_spin_out_physical` y `savage_spin_out_special`.
Comparten duda de especies fijas incrustadas. Revisar sus motivos en grupo y usar
los recursos existentes; para Z secundarios/excluidos se permiten equivalentes
genéricos del tipo según la instrucción del usuario. No perseguir fidelidad Z
exacta ni modificar el pool final. Mantener IDs/lados separados y registrar cada
elección; no reutilizar una omisión de patrones sin comprobar fuente y fases.

Separar de ese lote `guardian_of_alola` (transparencia final) y
`soul_stealing_7_star_strike` (encuadre), que tienen dudas diferentes. Después
quedan aeroblast, clanging_scales, court_change, destiny_bond y doom_desire.
Los 19 contextos siguen separados de los 19 huecos secundarios de recursos.
Sin regenerar datasets/catálogo ni commit/push/merge; originales conservados.

## Tramo anterior conservado: recorridos/reentradas cerrados — 2026-10-25

Séptimo tramo terminado. Treparrocas y Derribo back/front corrigen trayectoria
del usuario y transición entre bordes; Derribo front también el ancla del impacto.
Llave Corsé back/front verificada sin cambiar su lanzamiento. Cuatro clips
corregidos y dos comprobados: **60 IDs/91 clips cerrados**, pendientes **33 IDs:
14 de contraste y 19 de contexto**, 65 clips. No descontarlos otra vez.

Registro acumulado `.godot/move_motion_path_checks/4a0319aad2f9b423/gpu/review.json`,
SHA `f1aaf72792fb5aee488fb252941713cd668af6e142a71a800102099922d6df47`.
Tres láminas antes/después, 88 pares completos; gate 53.759/1.600 estados PASS.
80 capturas GPU de extremos discontinuos tienen alpha cero en cinco parejas/dos
arenas, incluido Wailord. No afirmar que toda la animación permanece dentro:
las salidas de pantalla son parte de la coreografía, se corrige el salto visible.

**Siguiente grupo:** cargas/cinemáticas restantes, empezando por `behemoth_bash`
y `catastropika`; después las otras 12 entradas de contraste. Contrastar fuentes,
roles y fases antes de reutilizar una política de cámara/fundido. Conservar los
19 contextos separados de los huecos secundarios de recursos; no activar mecánicas.
Anotar cualquier ajuste de imagen/visibilidad y mantener los snapshots anteriores.

Renderer `d934d0ccf43b…`, contexto derivado `eac61685a8e18a2f`, mismos recursos/
frames/bindings. Catálogo y regresiones de los seis grupos anteriores PASS.
Sin regenerar datasets/catálogo ni commit/push/merge.

## Tramo anterior conservado: efectos locales cerrados — 2026-10-25

Sexto tramo terminado: Acupresión back/front corrige el cuerpo que destella en
la referencia de uso sobre uno mismo; Danza Amiga front conserva su descenso
dentro de pantalla; Camelo back/front evita sangrado del atlas. Niebla Aromática
back/front verificada sin cambios de recurso. Tres IDs corregidos y uno comprobado,
siete clips de cola cerrados: acumulado **57 IDs/85 clips**; pendientes **36 IDs:
17 de contraste y 19 de contexto**, 71 clips.

Registro acumulado `.godot/move_local_effect_checks/58e91f150a8fc69c/gpu/review.json`,
SHA `1c8f2e209169d09f6425bb3febefcf31806a70a81f81498048a778adcd02d9d1`.
Evidencia `local_effects_before_after.png`; gate GPU 55.939/1.800 estados y oráculo
de atlas completo en 96 pares PASS. Recortes 30 → 0 en tres parejas/dos arenas.
Catálogo completo y regresiones anteriores PASS. Renderer `b7da766584d9…`,
contexto derivado `93cac9b62b9b823b`. Fuentes y cinco grupos anteriores intactos.

**Siguiente grupo:** desplazamientos/encuadres de `rock_climb`, `storm_throw`
y `take_down`. Comparar todos los frames y roles antes de extender ningún límite
de movimiento; no aplicar automáticamente el ajuste de Danza Amiga. Después,
seguir las geometrías/coreografías especiales de los otros 14 IDs de contraste.
Los 19 casos de contexto permanecen separados de los 19 huecos secundarios de
recursos diferidos. No habilitar mecánicas ni sustituir imágenes sin anotarlo.

Acupresión es solo referencia visual sobre uno mismo: la rama sobre aliado no
se da por implementada. La prueba de Niebla Aromática cierra la duda de ausencia
de capas, no sus reglas de equipo. Conservar fuentes, snapshots y cadena de
reviews. Sin regenerar datos/catálogo ni commit/push/merge.

## Tramo anterior conservado: bloque de agua cerrado — 2026-10-25

Quinto tramo terminado. Hidrovórtice físico/especial y Maxichorro front ocultan
solo la franja secundaria repetida antes de f12; después conservan el relleno
original. Surf y Onda Tóxica front verificados sin alterar su orientación nativa.
No volver a descontarlos: **53 IDs/78 clips cerrados**, incluyendo comprobados;
**40 IDs pendientes: 21 de contraste y 19 de contexto**, 78 clips.

Lista acumulada `.godot/move_water_checks/085180c565bcc21c/gpu/review.json`.
SHA `19cdc8f753ece18fc18a2357e5055358420cc471f609a7b1b679e6d68a1101ce`.
Antes/después en `water_before_after.png`, 90 pares/180 PNG; todos los estados
focales y regresiones PASS. Renderer `c712c423db4a…`, contexto `7a6f7eeb596fe91a`.

**Siguiente:** contrastar gestos/efectos locales pendientes, empezando por
`acupressure`, `aromatic_mist`, `entrainment` y `flatter`. Agrupar solo después de
demostrar causa común. Conservar IDs y lados separados, originales y cadena de
revisiones. Después siguen encuadres, geometrías y coreografías especiales.
No habilitar mecánicas ni confundir los 19 contextos con los 19 huecos secundarios
de recursos diferidos. Anotar toda sustitución o limpieza parcial de imagen.

La comparación canónica usa nuestros cuerpos y capas precocinadas; no certifica
equivalencia completa con la reproducción Ruby de Essentials. No regenerar el
catálogo ni cambiar globalmente bake_layers como consecuencia de esta limpieza.
Sin commit/push/merge; cinco rutas reales de combate conservadas.

## Tramo anterior conservado: tres dudas de haces cerradas — 2026-10-25

Cuarto tramo terminado: Láser Doble front recalibra el extremo horizontal de su
export nativo, por SHA de fuente; los dos núcleos finales x176/178 pasan a la
referencia del objetivo manteniendo Y/forma/tamaño. Pulso Dragón (contacto tardío
f35) y Lanza Glacial front (fragmentos/reacción f18) quedan comprobados sin cambios.
No eran efectos completamente ausentes; no alterar sus fuentes para centrar cada
partícula en el cuerpo. **48 IDs / 73 clips cerrados**, contando revisiones.

**Pendientes 45 casos: 26 de contraste y 19 de contexto**, 83 clips. Listado
acumulado `.godot/move_beam_endpoint_checks/9a306b629ccf3cfa/gpu/review.json`.
La nueva evidencia distingue reparación de `twin_beam/front` y verificación sin
cambio de `dragon_pulse/{back,front}` y `glacial_lance/front`. No descontarlos otra vez.
Dos láminas antes/después, 20 vistas/60 tiempos/120 PNG. Dos diagnósticos de tres
modos de cámara y todos los frames (630 estados), cuatro láminas adicionales.

**Siguiente grupo autorizado:** capas/transiciones de Hidrovórtice Abisal físico
y especial y Maxichorro; contrastar después orientación de Surf y Onda Tóxica.
Mantener IDs separados aunque compartan fuente y demostrar causa común antes de
reparar en lote. Conservar baselines y anotar cualquier sustitución artística.
Después siguen encuadres/coreografías, geometrías específicas y decisiones de arte;
los contextos de relevo/clima/forma permanecen separados, sin activar mecánicas.

Renderer `d1861790b5291352cf21c4517158682a7254ea23e10736920917af021ea99e18`,
contexto opcional `92770bfa947e9143` sin recursos distintos. GPU del arreglo
157.995 PASS/3.240 estados y sondeo 8.536 PASS/630; catálogo 1.822 clips/5.368.625
PASS. Gates anteriores, piloto, rutas y contexto PASS. Pulso Dragón intacto ocupa
el control antes reservado a Láser Doble; fuentes anteriores de los tests guardadas.
No sobrescribir baselines ni migrar sus revisiones. Sin commit/push/merge.

## Tramo anterior conservado: escudos y Sombra Vil — 2026-10-25

Tercer grupo cerrado: Pantalla de Luz, Escudo Tatami, Anticipo, Reflejo y Sombra
Vil, solo front. Los cuatro campos dejan quieto al cuerpo trasero no implicado;
Sombra Vil usa línea para el óvalo viajero y ancla local para destellos. Políticas
fijadas por SHA de fuente, sin modificar recursos ni aplicar reglas globales.

**45 IDs / 69 clips señalados cerrados**. Quedan **48 casos: 29 de contraste y
19 de contexto**, 87 clips. Lista exacta acumulada:
`.godot/move_projection_checks/c7fb45d23f10eccb/gpu/review.json`. No descontar
otra vez los grupos anteriores. Tres láminas observadas, 15 IDs/30 vistas,
96 tiempos/192 PNG; Sombra Vil f5/f10/f16/f20 ampliada. GPU 200.653 PASS/4.428
estados por tres parejas/dos arenas. Catálogo 1.822 clips/5.368.625 PASS;
regresiones de anclas, cuerpos, cámaras, piloto, rutas y contexto PASS.

**Siguiente trabajo:** contrastar Láser Doble con su recorrido/offset nativo y
otros haces pendientes (Pulso Dragón/Lanza Glacial, según la causa que se demuestre).
Láser Doble sigue idéntico, no cerrado ni cambiado para centrarlo a ojo. Conservar
el contacto parcial ya observado; no declararlo totalmente ausente. Después,
capas de agua/olas y encuadres. Relevos, clima y cambios de apariencia mantienen
su cola separada. Registrar sustituciones si hubiera, sin habilitar mecánicas.

Renderer `81cb49e7e0b2594181ebec834f5fa3c58bbffa036e7fb02a0e13a3d31d10a074`,
contexto opcional `acb25776afb63cda`, mismos recursos. El test de anclas anteriores
usa ahora Rayo Hielo de control en lugar de Sombra Vil, que tiene su propio
oráculo de corrección; copia del test previo junto al baseline nuevo. Capturas,
registros e índice antiguos preservados. Sin commit/push/merge ni cambios de datos.

## Tramo anterior conservado: anclas frontales corregidas — 2026-10-25

Segundo grupo cerrado: **13 casos frontales** por referencia local incorrecta de
partículas en exports nativos OppMove. Agarrón, Taladradora, Ala Bis, Palmeo,
Picotazo Veneno, Cola Veneno, Bola de Polen, Latigazo, Cara Susto, Residuos,
Relámpago Súbito, Ataque Ala y Abatidoras. Política por SHA de frames completos;
solo cambia posición de partículas con foco1, conservando origen local/foco3,
arte, geometría, cuerpos y capas. Fuente distinta se rechaza, sin adivinar anclas.

**40 IDs / 64 clips de la cola cerrados en dos grupos**. Quedan **53 casos:
34 de contraste y 19 de contexto**, 92 clips. Listado exacto y separación de
cerrados/abiertos en `.godot/move_anchor_checks/4cba2c2b751a2842/gpu/review.json`.
No volver a descontar los 27 del primer grupo. El barrido original conserva 523
registros y renderer antiguo; las aprobaciones no se migran automáticamente.

Evidencia nueva: `result.json` y cinco láminas en `sheets/`, 23 IDs/46 vistas
(13 focales y diez controles), 138 muestras temporales/276 PNG. GPU 296.099 PASS,
6.552 estados en tres parejas/dos arenas; catálogo 1.822 clips/5.368.625 PASS.
Los grupos propio, cámara previa, piloto prioritario, cinco rutas y contexto
opcional pasan. Latigazo ampliado f0 SÍ toca; separación f6 durante retroceso
de fuente X128→62/Y224→242. No arrastrar VFX detrás de cada reacción del cuerpo.

**Siguiente subgrupo autorizado:** trayectorias de Sombra Vil y Láser Doble y
campos/escudos propios desplazados (Pantalla de Luz, Escudo Tatami, Anticipo,
Reflejo). Contrastar por fuente/export antes de decidir si comparten arreglo.
Sombra Vil mueve óvalo de origen a destino: no aplicarle sin más el ancla rígida
del grupo anterior. Láser Doble usa foco3 y necesita revisar trayectoria/basis.
Mantener después agua/encuadres y casos artísticos específicos. Conservar los
baselines y registrar todo antes/después, incluidas sustituciones si las hubiera.

Renderer actual `b2610a303d30411b07100f985133cbd0a644ebccbbd4f5f4623349cc92845302`;
contexto opcional `d96f2f29fcdf3855`, mismo arte/frames. Sin nuevas mecánicas, rutas,
dataset/IA/workflows, commit/push/merge. No recapturar encima de evidencia antigua.

## Tramo anterior conservado: cuerpos propios corregidos — 2026-10-25

Primera reparación por grupo terminada tras autorización del usuario. Una base
primaria por Pokémon propio; conservar pista con gesto/tinte/fundido y celdas
adicionales intencionales. **27 IDs / 51 clips de la cola cerrados para duplicado
primario**. Quedan **66 casos del baseline: 47 de contraste y 19 de contexto**,
105 clips. Las cifras 807/74/19 del barrido inferior son históricas del renderer
anterior, no una revisión gráfica nueva de los 900 con el código actual.

Evidencia final `.godot/move_self_body_checks/e6bb10786f264b35/gpu/`: `result.json`,
`review.json`, ocho láminas antes/después; 27 IDs focales y 11 controles, ambos
lados, 76 vistas. El gate revisa todos los frames de 194 clips propios y controles
en dos arenas, 10.004 estados/387.922 checks GPU PASS. Catálogo completo headless:
1.822 clips/5.368.625 PASS; piloto prioritario 444.079, combate real 407 y contexto
opcional 6.442 PASS. Danza Lunar conserva azul y Venganza alterna pistas; la primera
regla que elegía siempre un rol fue descartada al revisar imágenes. No repetirla.

**Siguiente trabajo autorizado: efectos desplazados del objetivo**, agrupando por
export/foco/cámara. Comparar dos o tres representantes front/back (Ataque Ala,
Relámpago Súbito, Abatidoras, Palmeo, etc.), demostrar causa antes de aplicar un
arreglo común; proteger trayectorias y fases de retroceso. No declarar impacto
ausente por una miniatura. Conservar las fuentes y el baseline de los 18 bloques;
generar evidencia nueva para cada renderer. Mantener aparte capas de agua,
encuadres, decisiones artísticas y presentaciones externas. Doble Equipo/Pesadilla
mantienen sus ecos; Sustituto/Relevo/Teletransporte mantienen contexto pendiente.

Renderer actual `4fb1e38b88cd6e2d34a92c414d21fdadf4544cd6daaacfc6460f592d4aab893e`.
Contexto opcional actualizado a `67ab17c8a7c5e617`, con el mismo arte/frames y sin
activar mecánicas. Las herramientas del barrido original rechazarán el renderer
distinto: usar sus archivos como baseline histórico, no reconstruirlos encima.
Registro técnico también en VISUAL_SUBSTITUTIONS; sin sustitución artística nueva.

## Baseline conservado: barrido cerrado y cola original — 2026-10-25

El usuario prioriza revisar TODO el catálogo antes de concentrarse en reparaciones
aisladas; lo ha reconfirmado: **guardar primero los casos, corregir después del
barrido**. Plan completo: **18 bloques de 50 IDs / 1.822 clips**, con ambos lados y
todas las variantes. No confundir los 19 secundarios sin etiqueta de recurso con
19 animaciones terminadas pendientes de ver. Su investigación sigue diferida.

**Dieciocho bloques observados: 900/900 IDs, de absorb a zing_zap.** Captura GPU de todos
sus **59.383 frames / 1.822 clips**, 317.099 checks PASS acumulados; trescientas sesenta y seis
láminas de hasta cinco familias, 16 momentos por vista. **807 IDs sin fallo evidente en
las muestras, setenta y cuatro con dudas y diecinueve con presentación externa pendiente**.
Por clips: 1.666 muestras sin fallo evidente / ciento dieciocho dudas / treinta y ocho de contexto.
Bloque 18 aporta 50 IDs: **42 sin fallo evidente, cinco dudas y tres de contexto**;
100 clips / 2.802 frames / 16.121 checks PASS. No significa haber visto toda la
película a velocidad real ni probado sus mecánicas en combate.

**Barrido 18/18 completo: 0 IDs sin esta revisión temporal ampliada**. El último
bloque cubre trump_card a zing_zap. Quedan **93 casos de contraste/contexto**,
no 93 bugs confirmados. No generar un bloque 19 ni repetir el barrido para borrar
la cola. Siguiente: diagnóstico por causas comunes y correcciones verificadas.
Empezar por bases propias duplicadas y anclas/impactos frontales; luego capas,
encuadres y casos específicos. Preservar ecos deliberados y evidencia original.
Las decisiones artísticas de especies fijas y los contextos de clima/relevo/forma
mantienen su alcance separado; no habilitar mecánicas. Cola y evidencia en
`docs/project_book/VISUAL_CATALOG.md`:
Barrera front duplica Charizard; Acupresión tiene marca/destello en cuerpos
distintos; Aerochorro y Niebla Aromática difieren en capas entre vistas; Cambio
de Banda termina ocultando al usuario y requiere contexto de aliado. Nuevos:
Corpulencia superpone dos dibujos del usuario durante el crecimiento en ambos
lados; Embate Supremo tiene un escudo con rostro específico, duda artística de
idoneidad; Relevo necesita contexto de sustitución. El usuario principal de Relevo
permanece al terminar; no interpretar sus celdas fantasma ocultas como cuerpo ausente.

Bloque 3: Celebración y Copión, contornos dobles del usuario, candidatos al mismo
diagnóstico conjunto que Corpulencia; Fragor Escamas front, objetivo recortado por
borde superior; Cambio de Cancha, posiciones intercambiadas al acabar, contrastar
coreografía; Pikavoltio Letal, insignia con Pikachu, duda artística secundaria y
sin prioridad para buscar alternativa. Llave Giro necesita presentar el siguiente
combatiente; Fría Acogida conserva clima/retirada ya pendientes. No añadir Confusión
a la cola por su disparador automático: las celdas base terminan visibles/opacas.

Bloque 4: Detección front, copia extra junto al rival; Danza Dragón, contornos
dobles en ambos lados; Agarrón front, mano y objetivo encogido separados. Mismo
Destino (elipse gris), Deseo Oculto (trazos convergentes) y Pulso Dragón (aros en
usuario sin impacto claro) necesitan cotejar fuente/fase antes de llamarlos fallos
técnicos. Cola Dragón requiere entrada posterior a la expulsión. **No borrar todos
los cels de copias** al reparar objetivos propios: Doble Equipo usa celdas extra
2/3 deliberadas; sus capturas f12 son una referencia para proteger esa coreografía.

Bloque 5: Taladradora/Ala Bis front, efectos separados del objetivo; Aguante y
Deslome, cuerpos base superpuestos en ambos lados; Danza Amiga front, recorte del
objetivo por abajo en f29; Novena Potencia, otras especies incrustadas, duda de uso
final secundaria. No añadir Paranormal por su aviso de opacidad: al acabar son
sus copias extra las ocultas, los cuerpos principales están visibles y opacos.

Bloque 6: Palmeo front, mano separada del objetivo; Camelo ambos lados, líneas
finas junto a partículas sobre negro, cotejar fuente/filtrado antes de diagnóstico;
Viraje ambos lados, presentación del relevo tras salir de escena. Mantener los
equivalentes ya declarados de Truco Floral (solo fondo) y Premonición (solo impacto
FUTUREDUMMY); sus huecos originales permanecen. No añadir Rayo Fusión por el halo
que toca el borde: no se confirmó recorte del cuerpo o pérdida del núcleo en f15.

Bloque 7: Supernova Original, Mew fijo incrustado, duda artística secundaria en
ambos lados. Lanza Glacial front, posible desfase de contacto en f16/f17; fragmentos
sí rodean al objetivo en f18/f20, cotejar trayectoria frente a back. Cólera del
Guardián, opacidad final del objetivo 0,88235 en ambos f65 antes de limpieza PASS;
contrastar fase/fuente, no cuerpo desaparecido ni copia extra oculta. Granizo
conserva su contexto de clima ya conocido. No reabrir Martillo Colosal por ausencia
de martillo literal; conservar HEAVYSLAM de Prensa Metálica y SPITE de Infortunio.

Bloque 8: Hidrovórtice Abisal físico/especial front, capas rectangulares parciales
durante transición de agua (f3/f7/f12), contrastar export OppMove/fases/capas con
back antes de diagnosticar renderer. Mantener ambos IDs separados, DATA_ONLY.
No añadir Cola Férrea por la miniatura: ambos PNG f4 muestran una sola silueta;
Defensa Férrea front f5 tampoco prueba cuerpo desfasado. Garrote Liana incluye
base/fuego/roca/agua por ambos lados, ocho clips, sin activar máscaras ni más enlaces.

Bloque 9: Capa Mágica front, otro Charizard junto a Ogerpon; Pantalla de Luz front,
Ogerpon desplazado de la sombra. Aguzar, Danza Lunar y Levitón, cuerpos base propios
superpuestos con distinta escala/posición en ambos lados, candidatos al diagnóstico
conjunto. Somanta Amistosa, Mimikyu fijo, duda artística secundaria; back f76 incluye
un trazo horizontal fino que cotejar con la fuente/fase. No buscar reemplazo ahora.
No añadir Ciclón de Hojas por miniaturas: front f22/f25 muestran un solo objetivo;
Patada Baja front f4/f5/f6 tampoco confirma efecto separado.

Bloque 10: Escudo Tatami front, cuerpo desplazado de sombra como Pantalla de Luz;
Maxichorro front, franja de agua parcial de HYDROVORTEX, diagnosticar junto a
Hidrovórtice físico/especial sin deduplicar sus IDs. Meditación ambos lados,
cuerpo normal y aplastado superpuestos; Reducción, celdas base a escalas distintas
y eco extra, contrastar coreografía antes de borrar copias. Legado no añade deuda:
sus cuerpos base terminan presentes/opacos y el aviso es de una celda extra.
Mantener los 19 equivalentes Max y SILVERWIND de Maxinsecto, sin nuevas sustituciones.

Bloque 11: Luz Lunar, cuerpos base del usuario desfasados 11,25 px verticales;
Bastión Final, cuerpo amarillo y normal separados 22,5 px horizontales, ambos lados.
Última Palabra necesita presentar el relevo tras retirada (ambos finales f25).
Conservar los ecos laterales 2/3 de Pesadilla, diez clips de las cinco referencias
manuales de Adaptación y geometrías ya corregidas de Rayo Umbrío/Ala Mortífera.
Presa Espectral mantiene franjas cinematográficas nativas: su descarte histórico
como equivalente Maxiespectro no ordena borrar sus dos recursos Z.

Bloque 12: Picotazo Veneno front f14, Cola Veneno front f13 y Latigazo front f6,
efectos separados del objetivo; Bola de Polen front, proyectil sí llega en f17,
explosión desplazada en f19/f21. Conservar 40/30 frames back/front. Truco Fuerza
ambos f7, dos cuerpos base superpuestos con escalas distintas. Cinco IDs/seis
clips guardados para contraste; no reparar durante el barrido. Proliferación sí
tiene impacto en PNG nativo f22 ambos lados, no añadir falso vacío a la cola.
Mantener PSYBEAM explícito de Láser Prisma, su hueco nativo abierto y tonos
previos de Poltergeist/Asalto Barrera; sin nueva sustitución artística.

Bloque 13: Danza Aleteo ambos f3, Polvo Ira ambos f13 y Pulimento ambos f12,
dos cuerpos base opacos separados 30/15/7,5 px verticales. Anticipo front f12 y
Reflejo front f16, cuerpo desplazado de sombra como Pantalla de Luz. Treparrocas
ambos f20, recorte del usuario al salir por arriba o abajo/izquierda, con retorno.
Danza Lluvia conserva su presentación de clima pendiente; Rugido necesita relevo
tras expulsar, front fuera de pantalla sin bandera de ocultación. Golpe Roca front
f7 sí superpone puño y objetivo: no añadir falso impacto ausente por f3.
Giro Rápido ambos f13/f18 conserva arcos abiertos que se separan; no agruparlos
con rectángulos de agua de HYDROVORTEX. Imitación conserva la silueta transferida
intencional y Rodar la esfera temporal. No borrar copias globalmente.

Bloque 14: Afilar ambos f2, cuerpos base propios opacos a escalas relativas 0,75/1;
Cara Susto front f9, cara grande lateral; Sombra Vil front f20, óvalo y destello
desplazados hacia la derecha. Guadaña Sedosa físico/especial ambos f32 incluye
especies fijas, duda artística secundaria, sin buscar alternativa ahora. Tormenta
de Arena conserva presentación de clima y shed_tail necesita contexto de sustituto/
relevo. Daño Secreto: cinco referencias manuales, diez clips; la celda extra oculta
de CONFUSION no es cuerpo base desaparecido. Arañazo ambos f3 sí tiene trazos;
Simún ambos f16 desplaza el remolino a la izquierda en esa fase, sin nuevo caso
unilateral. Conservar cubo/atlas/escala uniforme de Disruptor Psíquico y SILVERWIND
de Maxinsecto; el descarte de SAVAGESPINOUT para Max no elimina estos dos IDs Z.

Bloque 15: Relajo ambos f8, Robo ambos f4 y Salpicadura ambos f3, dos bases propias
opacas con distinta posición/escala. Residuos front f16, burbujas laterales;
Onda Tóxica front f14, orientación de ola desde borde superior por contrastar.
Constelación Robaalmas ambos f48/f50, usuario recortado en bordes durante impacto,
posición fija f48–51 y retorno final. Paisaje Nevado conserva contexto externo de
clima. Chorro de Vapor ambos f46/f60 tiene estallido/reacción tardíos; no declarar
impacto totalmente ausente ni igualar 74/77 frames. Mantener Cuchilla Solar y
ecos deliberados de Cuerno Certero/Golpe Rastrero, sin borrar todas las copias.

Bloque 16: Llave Corsé ambos f20, objetivo recortado durante lanzamiento, vuelve
a plaza f23/final f25; pendiente contraste de encuadre, no expulsión definitiva.
Surf front f14, masa superior/cresta hacia abajo, contrastar orientación con fuente
como Onda Tóxica. Sustituto ambos f5 sí muestra muñeco; f13 falta persistencia de
esa presentación, contexto externo ya conocido. Día Soleado actual f8 tiene pulso
amarillo y contrato de capa 0→200→0; no reabrir antigua nota de opacidad cero como
si describiera esta evidencia. Tragar ambos f15/f16 no confirma doble silueta por
diferencia Y 1,20/1,19; Plumerazo f3 sí tiene trazo gris. Picado Supersónico físico/
especial conserva SKYATTACK, hueco Z sin reparar; no habilitar mecánicas por el pase.

Bloque 17: Limpieza General ambos f2, contornos dobles con bases propias opacas
separadas 7,5 px; Relámpago Súbito front f9, destello separado de Ogerpon frente
a back. Derribo back f8/front f9 recorta usuario durante embestida, retorna f19;
contrastar encuadre/coreografía. Teletransporte final f20 sí conserva usuario:
base0 oculta, base1 propia opaca, no confundir aviso con plaza vacía. Necesita
contexto de retirada/relevo. Transformación muestra blanco y vuelve a la misma
especie, cambio externo de apariencia pendiente. Sin nueva sustitución ni reparación.

Bloque 18: Danza Triunfal ambos f2, dos bases propias opacas desplazadas 15 px
verticales/laterales; Avivar ambos f4, roja elevada 15 px y normal. Ataque Ala
front f5, arcos separados; Abatidoras front f18, humo separado. Láser Doble front
f20/f27, contacto descentrado/roce parcial frente a back, no impacto ausente.
Ida y Vuelta f27 y Voltiocambio f25 necesitan relevo tras ocultar usuario;
Remolino GUST termina con ambos presentes y aún necesita contexto de expulsión.
Llave Vital f19/f20 muestra retroceso simétrico y estrella fija, no fallo unilateral;
Shuriken de Agua front f11 sí toca cabeza. Guardado sin reparar ni sustituir arte.

Plan y registro reanudables:
`.godot/move_temporal_batches/c5b2756454290487/{plan,review}.json`.
Bloque 1: `batch_01_4cf3260effe18266/result.json`; bloque 2:
`batch_02_10a1e33372afa525/result.json`; bloque 3:
`batch_03_e38f080272506981/result.json`; bloque 4:
`batch_04_1079a5033beb90ec/result.json`; bloque 5:
`batch_05_2d69da14cc4d3101/result.json`; bloque 6:
`batch_06_f35e7337d8d5fa4d/result.json`; bloque 7:
`batch_07_bdcca293bf7e0494/result.json`; bloque 8:
`batch_08_893feae099e0ac4f/result.json`; bloque 9:
`batch_09_9714ca1f03cfdad5/result.json`; bloque 10:
`batch_10_8a14891a453467f5/result.json`; bloque 11:
`batch_11_cd63d28ef7302e9e/result.json`; bloque 12:
`batch_12_a63b37636b784d0e/result.json`; bloque 13:
`batch_13_7278a2576c29cd40/result.json`; bloque 14:
`batch_14_ec10470a5f9268c2/result.json`; bloque 15:
`batch_15_cd00d3a51c3f0d2b/result.json`; bloque 16:
`batch_16_04b20632f90276f1/result.json`; bloque 17:
`batch_17_646e014ce71e52f7/result.json`; bloque 18:
`batch_18_c117b669d6cfdbec/result.json`; láminas en `sheets/boards.json` dentro
de cada bloque. El registro distingue clips de una misma página: no aprobar
vecinos dudosos por haber revisado otros. Las notas están ligadas al SHA de plan,
reporte, catálogo, renderer y lámina; si cambian, no reutilizar la aprobación.

```powershell
# Solo reconstruir láminas de evidencia existente si se necesitan; no recapturar
# encima del baseline para diagnosticar o certificar una corrección.
python tools/visual/review_move_temporal_batches.py --report .godot/move_temporal_batches/c5b2756454290487/batch_18_c117b669d6cfdbec/result.json
```

Observar TODAS las láminas generadas, ampliar dudas a PNG nativo, y registrar
cada página con `--report ... --page ... --status ... --note ...`; `--clip ID`
repetible permite separar hallazgos de vecinos. Estados: temporal_samples_checked,
needs_targeted_review, requires_external_presentation. No conectar 900 a combate
por un PASS de laboratorio. Toda sustitución futura sigue en VISUAL_SUBSTITUTIONS.

Complemento de inspección sin editar herramientas: consultar `frames[].bodies`
para buscar celdas base 0/1 del mismo lado, visibles y opacas, con posición/escala
distinta. Orientó ampliaciones de Aguzar, Danza Lunar y Levitón en bloque 9, y de
Meditación/Reducción en bloque 10 y Luz Lunar/Bastión Final en bloque 11; comprobar
el PNG nativo y la coreografía antes de registrar una duda. No es diagnóstico
automático ni autoriza eliminar copias intencionales; mantener generación y fuentes.

Si falta un impacto en las miniaturas, consultar también cambios de posición/tono
del objetivo y ampliar esos PNG: Proliferación reaccionaba entre f21 y f23 (máximo
7,5 px Y en f22, retorno f24); el PNG f22 muestra el impacto que las 16 muestras
no incluían. No certificar por ello número de golpes ni mecánica multigolpe.

Continuidad verificada tras el corte de contexto al cerrar el bloque 12: todos los bloques generados
1–12 tienen reporte, láminas y registro completo, hashes coherentes y ningún clip
huérfano. 336 entradas, primeros 310 registros intactos. Solo faltaba poner al día
estos cuadernos, ya completado. Entonces quedaban seis bloques 13–18, 300 IDs;
no eran capturas abandonadas. Bloque 13 cerrado con 34 entradas nuevas (370 totales)
y prefijo de 336 intacto. Bloque 14 añade otras 34 (404 totales), prefijo de 370
intacto y 22 láminas/108 clips completos. Bloque 15 añade 32 (436 totales),
prefijo de 404 intacto, 20 láminas/100 clips completos. Bloque 16 añade 25
(461 totales), prefijo de 436 intacto, 20 láminas/100 clips completos.
Bloque 17 añade 29 (490 totales), prefijo de 461 intacto, 20 láminas/100 clips completos.
Bloque 18 añade 33 (523 totales), prefijo de 490 intacto, 20 láminas/100 clips completos.
Los 18 bloques están cerrados, 900 IDs/1.822 clips/366 páginas registrados.
Conservar los 93 casos y su baseline antes de corregir por grupos, sin rehacer
imágenes individuales cuando la causa sea de presentación compartida.

## Antecedente: primera pasada artística cerrada; preparar integración sin ampliar mecánicas — 2026-10-24

**Regla del usuario (2026-10-24):** anotar toda sustitución visual, vigente e
histórica, en `docs/project_book/VISUAL_SUBSTITUTIONS.md`. Inventario inicial
verificado: 34 IDs / 42 familias / 84 clips de referencias alternativas, no 34
dibujos repintados. Mantener antes/después y distinguir correcciones técnicas.

**900/919 IDs / 1.822 clips**, sin nuevos enlaces de combate. Láser Prisma usa
ahora **PSYBEAM como equivalente explícito**, no su láser nativo incompleto.
Además, **Ala Mortífera** conserva su vuelo nativo y corrige solo la base
geométrica del haz: reproducción FAIL y corrección PASS, referencia de cámara,
ambos lados y regresiones. **1.820 contratos/capturas restantes idénticos**.
No reabrir estas dos decisiones sin evidencia nueva.
Registro vigente: `.godot/move_contact_review/c673840caea21b70/sheets_20/index.md`.
**1.810 muestras sin fallo evidente / doce requieren presentación externa**;
cero needs_motion_review/suspected_issue de los casos señalados. Las tres dudas
artísticas se cierran por comparación: Cañón Armadura → FLAMEBURST; Maxibicho /
Maxinsecto → SILVERWIND, ambos equivalentes explícitos. Martillo Colosal conserva
su golpe metálico nativo: no contiene un martillo literal, límite aceptado y
anotado. No es aprobación de toda la película ni de 900 mecánicas.

Siguiente trabajo por familias, sin volver a mirar las 92 páginas:

1. **Siguiente paso seguro: inventario de integración por familias**, sobre las
   clasificaciones ya existentes. Separar efectos simples de cuerpos/capas/
   presentación persistente y estados externos; no conectar 900 de golpe por
   haber pasado un muestreo. Cinco rutas reales siguen siendo solo cinco. No
   promover DATA_ONLY/UNSUPPORTED ni ampliar IA/datos por una animación bonita.
2. **Seis presentaciones externas revisadas, integración real pendiente**: Danza
   Lluvia, Granizo, Paisaje Nevado, Fría Acogida, Sustituto y Transformación.
   Ya hay modo opcional del laboratorio: activar «Catálogo por lotes» y
   «Contexto visual opcional · NO mecánicas». Muestra climas, retirada, muñeco
   y cambio de apariencia. No repetir la revisión como si fueran atlas rotos.
   El estado `requires_external_presentation` conserva la deuda real; no admite
   DATA_ONLY/UNSUPPORTED a combate. Son cinco DATA_ONLY y Transformación UNSUPPORTED.
3. Los **19 exclusivos/secundarios** sin etiqueta siguen fuera de prioridad.
   Las **diez incidencias nativas** cubiertas por equivalentes siguen anotadas;
   no rellenar atlas con transparencias ni repetir descargas ya investigadas.

Para comparaciones pequeñas, `move_temporal_review.gd -- --moves=ID,REFERENCIA`
captura todos los frames de las parejas ya anotadas, comprueba reloj/limpieza y
vincula la selección al hash de generación (máximo diez IDs, sin duplicados o
parejas parciales). Sin ese argumento mantiene la cola completa de excepciones.
Las láminas muestran ocho tiempos, no una película observada a velocidad normal.

No repetir por defecto los tres casos artísticos resueltos. El piloto histórico
de 70 clips queda intacto; su Maxibicho/SAVAGESPINOUT está rotulado HISTÓRICO,
no se ofrece como la selección artística vigente. Usar el catálogo por lotes.
Sin cola artística, la captura temporal se ejecuta SOLO con `--moves=...` si hay
una duda nueva concreta; el modo sin parámetros exige una cola no vacía.

Contexto opcional vigente: `.godot/move_external_context/08bf4875daf81fcf/context.json`.
Prueba CPU/GPU y cuatro láminas: `.godot/move_external_checks/466c9a2439f4f43e/`.
Si cambia índice/renderer, el modo se bloquea hasta reconstruir sus recursos con
`python tools/visual/build_move_external_context.py --source-root 'D:/Proyectos/Pokemon Calvo Auditoria Visual/comparacion_ataques_v1'`.
Esto NO reconstruye ni cambia el catálogo nativo. Datos/turnos/IA y las cinco
rutas reales de combate siguen iguales.

## Antecedente: revisar las once excepciones visuales — 2026-10-24

**900 IDs reproducibles / 1.822 clips**; veinte nuevos clips de diez equivalentes
explícitos, pruebas y dos láminas PASS salvo dudas anotadas. Registro vigente
`.godot/move_contact_review/b6183b56e397801b/sheets_20/index.md`.
No quedan huecos prioritarios sin una referencia visual para probar, pero las
diez fuentes originales siguen sin reparar: no confundir cobertura por
equivalente con recuperación nativa ni con nuevos enlaces de combate.

Siguiente tramo por familias, sin recorrer otras 92 páginas:

1. **Láser Prisma**: equivalente Géiser Fotónico apartada en ambos lados por
   silueta muy grande/estirada en f44. Ver secuencia y valorar Psicorrayo si no
   encaja; es idoneidad artística del sustituto, no permiso para retocar el atlas
   de todos los Pokémon ni reabrir el Photon Geyser original. Priorizar esta
   decisión acotada antes de proclamar acabado el lote de diez equivalentes.
2. **Ala Mortífera**: ascenso fuera de pantalla, retorno y haz; comparar con
   coreografía de origen. No copiarle automáticamente la reparación de Rayo Umbrío.
3. **Seis presentaciones externas**: Danza Lluvia, Granizo, Paisaje Nevado,
   Fría Acogida, Sustituto y Transformación. No habilitar mecánicas DATA_ONLY/
   UNSUPPORTED al resolver su presentación. Tres asuntos de arte: Cañón Armadura,
   Martillo Colosal y Maxibicho; este último sin Pokémon ajenos incrustados.
4. Los **19 exclusivos/secundarios** sin etiqueta siguen fuera de prioridad;
   no alterar catálogo/pool. No gastar otra fase descargando los mismos atlas
   incompletos: la investigación y límites están documentados. Si en el futuro
   aparece una corrección compatible del autor, se compara y sustituye el
   equivalente con nueva evidencia; no es un bloqueo para seguir ahora.

Premonición/FUTUREDUMMY representa SOLO el impacto; preparación/espera externas
siguen pendientes al conectar el movimiento real. Remolino/Tornado tampoco
certifica una retirada o cambio de Pokémon. Descanso/Sonámbulo solo aporta el
símbolo Z, no cura/sueño ejecutados. Siguen cinco rutas de combate, sin nuevos
contratos de soporte. Los apartados siguientes son antecedentes, no órdenes de
deshacer las equivalencias ni de repetir la investigación cerrada.

## Antecedente: cerrar huecos reales sin repetir diagnósticos — 2026-10-24

Vigente: **890/919 IDs, 1.802 clips**; registro
`.godot/move_contact_review/493b98955b31aa33/sheets_20/index.md`.
Resueltos Estruendo Implacable (fallback de prioridad), Gigaimpacto (fondo rival),
Lengüetazo (dependencia siempre invisible) y Resplandor (hoja blanca). Nuevas
láminas vistas, pruebas focales/barridos/regresiones PASS. No reabrir esos cuatro
como ausencias sin evidencia nueva. La cola visual sigue en diez IDs / 20 clips.

Siguiente paso por familias, no otras revisiones individuales de todo el catálogo:

1. **Cinco atlas incompletos / ocho IDs**: Brave Bird (también los dos IDs de
   Supersonic Skystrike), Grudge/Hex, Prismatic Laser, Slack Off/Rest y
   Twister/Whirlwind. Tabla de dimensiones y patrones ausentes en cuaderno.
   Faltan celdas que la fuente usa con opacidad positiva. El ZIP original y
   PokéRogue tienen la misma cobertura incompleta: no descargar el mismo atlas
   ni rebajar el validador a «transparente» como supuesta solución. Buscar versión
   corregida del autor/Reborn con animación y PNG compatibles; si no existe,
   evaluar un equivalente artístico explícito, conservando la limitación nativa.
2. **Dos fondos ausentes**: `uwu.png` de Truco Floral y `PRAS- Darkness BG.png`
   de Premonición. `uwu.png` ya está denunciado en el hilo del recurso. No elegir
   un negro/genérico por similitud de nombre sin confirmar contenido/intención.
3. Las **19 etiquetas** Let's Go/Torque/Z especial siguen fuera de prioridad
   artística según usuario. No borrarlas de datos/pool ni fingir fuente nativa;
   cualquier fallback por tipo requiere declararlo como equivalente.
4. Cola visual separada: seis presentaciones externas (Danza Lluvia, Granizo,
   Paisaje Nevado, Fría Acogida, Sustituto y Transformación), tres de arte
   (Cañón Armadura, Martillo Colosal, Maxibicho) y Ala Mortífera por vuelo/retorno/
   haz. No reabrir las cinco trayectorias ya contrastadas ni aplicarles reparaciones
   por compartir un atlas. Siguen solo cinco rutas de combate, sin soporte nuevo.

Las hojas suplementarias se recuperan con `fetch_move_gap_sheets.py` ANTES del
constructor offline si falta `.godot/move_gap_sources/`. No se descarga un juego
entero ni se publica arte. Atribuciones y revisión de condiciones pendientes de
distribución en cuaderno. Los párrafos siguientes son antecedentes, no órdenes
de repetir el trabajo cerrado.

## Antecedente: continuar por causas compartidas — 2026-10-24

**Cerrado el grupo masivo de 30 hue**: 886/919 IDs, 1.794 clips. Último registro
`.godot/move_contact_review/a5a29f4db6b47005/sheets_20/index.md`.
Cuatro láminas nuevas observadas; 1.734 revisiones anteriores conservadas con
prueba por clip, sin volver a recorrerlas. 1.774 muestras sin fallo evidente,
12 clips necesitan movimiento/contexto y ocho sospechosos: diez IDs apartados.
Esto NO habilita más de las cinco rutas de combate existentes.

Siguiente trabajo acotado, sin reconstruir dibujos ni tocar mecánicas:

1. Investigar conjuntamente los ocho `missing_pattern` y cinco `missing_sheet`
   usando el archivo ya descargado: comprobar nombre/ruta, atlas y versión antes
   de elegir equivalentes. No rellenar silenciosamente con un patrón cualquiera.
   `clangorous_soulblaze` sigue aparte por modo de celda no soportado.
2. Las otras 19 excepciones son etiquetas de Let's Go/Torque/Z especial ya
   apartadas del objetivo artístico prioritario por el usuario. No gastar otra
   fase en rehacerlas ni eliminarlas del catálogo/pool; un fallback genérico
   explícito por tipo es un trabajo separado, no cobertura nativa ficticia.
3. Cola visual independiente: seis presentaciones externas (Danza Lluvia,
   Granizo, Paisaje Nevado, Fría Acogida, Sustituto y Transformación), tres de
   arte/equivalencia (Cañón Armadura, Martillo Colosal y Maxibicho) y ahora
   Ala Mortífera, ambos lados: confirmar ascenso, retorno y haz en movimiento
   frente a la fuente. No llamarlo fallo de hue o copiarle una reparación por
   compartir atlas. No reabrir las otras cinco trayectorias ya contrastadas.

Los apartados siguientes son antecedentes del primer barrido, no el estado vigente.

## Antecedente: barrido y láminas por lotes — 2026-10-24

El usuario prioriza comprobar funcionamiento y después revisar imágenes agrupadas,
anotando sospechosos para corregirlos juntos. Implementado y ejecutado el barrido
y la captura/composición de 44 lotes × dos lados × tres momentos por clip.
No se inició la corrección hue de 30 IDs durante este tramo de observación.

**Primer barrido de láminas TERMINADO: lotes 01–44, ambos lados.** Registro vigente en
`.godot/move_contact_review/de7c04174963c920/sheets_20/index.md` y `review_log.json`.
Tras contraste de cámaras y geometría del haz: 1.734 clips / 5.202 muestras, 1.716 sin fallo
evidente en las muestras, diez necesitan contexto/movimiento y ocho sospechosos de presentación/
artísticos. Cero clips convertidos pendientes de este primer vistazo. Los 18 apartados son nueve IDs, no defectos
confirmados. Ninguno adquiere soporte mecánico o aprobación de la secuencia
completa por una lámina. Las 63 excepciones de conversión siguen pendientes.

Siguiente tramo: inspección focal en movimiento y corrección por familias, NO
volver a recorrer las 88 láminas ni hacer otra whitelist artesanal:

1. Día Soleado/Deseo RESUELTOS en laboratorio: Set BG no cancela fades activos y
   partículas de pantalla de movimientos al usuario no usan la línea de longitud
   cero. Deseo tiene ahora tres muestras distintas. No reabrir como clips inmóviles.
   Focal 8.025 GPU PASS, barridos y regresiones PASS. Cuatro láminas delta vistas;
   1.674 anotaciones equivalentes conservadas con prueba por clip, sin aprobar vecinos.
2. Captura temporal de los 17 anteriores ya realizada: 1.300 frames/34 clips,
   cuatro láminas de ocho tiempos vistas, 5.879 checks PASS antes/después.
   Cadena Virulenta y bocadillo de Fría Acogida SOLO rival corregidos con anclas
   rígidas, focal 4.630 GPU PASS. Restauración de Llama Final/Electropalmas
   comprobada, no reabrir como textura perdida ni borrar su duración original.
   Las cinco trayectorias/escala ya se contrastaron en lote (Orbes Espectro,
   Cañón Dinamax, Rayo Infinito, Rayo Umbrío, Cuchilla Solar): 1.248 estados GPU,
   13.655 checks, tres cámaras. Solo Rayo Umbrío requería base afín de partículas
   fijada por hash; focal 1.372 PASS, otros 1.732 clips equivalentes. Los grandes
   haces son grandes en la fuente y la hoja cruza el cuerpo en f16/f17: el
   compositor ahora captura el pico de silueta. No reabrir esas cinco dudas sin
   evidencia nueva ni llamar daño a una máscara alfa.
   Quedan seis presentaciones externas (Danza Lluvia,
   Granizo, Paisaje Nevado, Fría Acogida, Sustituto, Transformación); tres de
   arte/equivalencia (Cañón Armadura, Martillo Colosal, Maxibicho). Usar la
   secuencia temporal `.godot/move_temporal_checks/b40991f55c3e7b6c/` para los
   nueve que no cambian; comparación final de haces en
   `.godot/move_trajectory_checks/885e8512d3f02db4/`. No empezar
   otra vez por tres muestras ni declarar observada una película continua.
   Maxibicho necesita referencia Bicho genérica sin otros Pokémon incrustados.
   No activar
   Sustituto DATA_ONLY o Transformación UNSUPPORTED por revisar sus imágenes.
   El muñeco de Sustituto ya aparece; queda comprobar su transición/sustitución
   visual externa, no buscar una textura perdida. No cambiar dibujos por ello.
3. Abordar las 63 excepciones de conversión por causa compartida, empezando por
   los 30 hue, sin fingir aprobación artística de los recursos nuevos. Tras
   cambios, recapturar/migrar solo evidencia idéntica y revisar lo que cambie.

Los párrafos siguientes son antecedentes de generaciones anteriores; no reabren
los casos resueltos arriba ni sustituyen el registro vigente.

RESUELTO el contraste de foco/cámara de Hipertaladro, Patada Giro y Palma Rauda
SOLO rivales: tres exports fijados por hash, una adaptación compartida de sus
partículas al espacio canónico, sin cambiar el renderer global. Prueba focal
antes FAIL / después 1.684 PASS; barridos completo headless/GPU y regresiones
PASS. Nueva generación `84cfcc27cf596d4c`: tres páginas cambiadas vistas de nuevo;
85 idénticas conservaron 1.674 anotaciones con prueba por clip/hojas/muestras GPU
y renderer idénticos. No se hereda el registro de imágenes cambiadas. Las notas
de sospechas del barrido original más abajo son antecedentes, no fallos reabiertos.

Nuevos apartados 13–20: Granizo por ambos lados se revisa con presentación de
clima (fuente cuerpo-solo); Martillo Colosal por ambos lados por legibilidad del
golpe a velocidad normal, no textura perdida demostrada. Hipertaladro SOLO rival:
impactos separados a la derecha de Ogerpon; contrastar foco/coordenadas del
OppMove propio y adaptación de cámara antes de corregir. Paranormal, Láser
Veleidoso rival y Geocontrol rival no conservan las dudas iniciales de miniatura
tras ampliar/contrastar fuente. No reabrirlos como errores confirmados.

Aerochorro rival no conserva la sospecha de dirección tras ampliación. Cañón
Armadura se revisa por el motivo del impacto original; Danza Lluvia necesita la
parte visual de clima fuera de la danza corporal. No atribuir ambos a fallos de
importación. La auditoría suplementaria previa detectó casos de clima cuerpo-solo
y la posible interacción de dos timings de Día Soleado en frame 0; sus láminas
ya se han visto y anotado durante el cierre. No corregir el orden de timings sin
contrastar antes la semántica de la fuente; detalles en el cuaderno.

Llama Final y Electropalmas: comprobar duración del oscurecimiento, no corregir
una textura perdida que no se ha demostrado; el último frame de fuente vuelve
a tono/color cero y opacidad 255. Fría Acogida: revisar presentación de clima/
retirada. Doble Patada NO se aparta como estática: se corrigió el selector de
capturas que, con dos estados distintos, elegía tres veces f0. Nueva generación
con f0/f1/f1; 86 láminas idénticas conservaron 440 anotaciones por hash y las dos
del lote 11 se volvieron a mirar. Mantener historial previo, no reiniciar revisión.

Reproducir: `tools/visual/run_move_contacts.ps1 -BatchSize 20` (también 10).
Primero barrido técnico, después captura GPU y composición; no vuelve a importar
datasets ni conecta recursos masivos al combate. Detalles/registro en el cuaderno.

## Cambio de escala autorizado — 2026-10-24

Sustituye el siguiente paso de pequeños lotes manuales descrito más abajo.
Implementado el conversor/auditor del catálogo completo: 856 de 919 IDs,
1.734 clips en 28 bloques; 63 excepciones explícitas. No añadir otra whitelist
artesanal de dos/tres movimientos como flujo principal.

Reproducir con `tools/visual/run_move_batch.ps1 -Capture`; `-OpenLab` abre el
laboratorio al terminar. También sigue disponible `JUGAR_PRUEBA_ATAQUES.cmd`:
activar «Catálogo por lotes», buscar nombre o ID. El comando convierte primero,
comprueba después y genera un informe agrupado; no usa evidencia de otro índice.

Continuación: corregir familias compartidas (primero soporte de hue: 30 IDs de
una vez), revisar solo los disparadores del informe y diseñar la promoción por
lotes a combate con contrato de metadatos/eventos y sincronía verificable. Los
recursos convertidos NO se consideran aprobados por ausencia de errores técnicos.
El combate mantiene cinco rutas revisadas. No activar automáticamente DATA_ONLY,
UNSUPPORTED, delegación de Adaptación, contexto de Daño Secreto, Tera completa o
Dinamax. Los nombres exclusivos ignorados pueden recibir equivalencias visuales
explícitas de laboratorio en otro lote, sin alterar todavía el pool final.

Runbook, procedencia y cola: `../project_book/VISUAL_CATALOG.md`, sección del
2026-10-24; `.godot/move_batch_checks/summary.md` y `review_queue.json`.

## Continuación visual local — 2026-10-19

Conectadas las poses corporales existentes y la cronología visual compartida
de PS/mensajes con reacciones genéricas para las 1.025 especies. Conectados también
captura, retirada/aparición, KO/cambio forzado y huida. Validados retorno a reposo,
cancelación, routing al PC y reconciliación tras KO/progresión. No descargar datos brutos:
los datos procesados necesarios ya están presentes. Estado local, no nueva certificación
remota; ver `../project_book/VISUAL_CATALOG.md`.

Añadidos efectos geométricos compartidos para los 18 tipos, distinguiendo acción
física, especial y estado. Se ha comprobado el mapeo de metadatos de los 919
movimientos, no sus mecánicas completas, y ejecutado 20 turnos de muestra reales.
Gate gráfico focal: 5.001 PASS / 0 FAIL, 46 capturas. No son animaciones individuales
ni arte final. Los impactos requieren daño positivo del evento correspondiente.

Petición posterior: comparados los archivos comunitarios EBDX y Gen 9, sin instalar.
Inventario y registro de créditos en `VISUAL_CATALOG.md`: 554/841 coincidencias
directas con los 919 IDs, no cobertura certificada. Gen 9 es candidato provisional;
faltan piloto visual equivalente y revisión de procedencias/condiciones antes de adoptar.
Restricción inicial: no construir todavía créditos finales ni un importador
completo; la petición del 2026-10-24 autoriza después la conversión masiva visual,
no cambia por ello las reglas de combate o distribución.

Prioridades posteriores del usuario sustituyen el filtro anterior: los 19 Max/
Dinamax, Garrote Liana de Toxillian y Adaptación/Daño Secreto son prioritarios.
Descargados fuera del juego los ocho exports de Toxillian (cuatro variantes por
dos lados); localizadas equivalencias candidatas para los 19 Max dentro de Gen 9.
Auditoría externa: 125 comprobaciones PASS, no reproducción ni integración.
Laboratorio disponible en `JUGAR_PRUEBA_ATAQUES.cmd`: los 19 equivalentes Max y
Garrote Liana base, cada uno desde ambos lados (40 selecciones), sin combate ni
audio. Diez Max tienen export rival propio y nueve están marcados como adaptados.
Vuelo usa Huracán y Fantasma Bola Sombra tras revisar los primeros candidatos.
Gate gráfico: 296.712 PASS / 0 FAIL, 404 capturas; regresiones focales verdes.
Ver cuaderno para reconstruir con `--include-max` y localizar los artefactos actuales.
Añadidas después Teraexplosión con un solo equivalente y cinco referencias
contextuales manuales por lado para cada uno de Adaptación/Daño Secreto: 62 clips
en total. No amplían contratos mecánicos; la UI lo advierte. Corregido el cubo
ensanchado, conservando su proporción original sin deformar el mosaico de fondo.
Gate actualizado: 399.949 PASS / 0 FAIL GPU, 628 capturas; headless 399.194 PASS.
Actualización 2026-10-20: añadidas las tres variantes restantes de Garrote (sus
exports rivales propios) y un equivalente HEAVYSLAM para Prensa Metálica, con lado
rival adaptado. Son 70 clips; se corrige además la deformación de proporciones de
los garrotes al tratar objetos como mosaicos. Gate vigente: 445.694 PASS / 0 FAIL
GPU, 708 capturas; 444.843 headless. Reconstruir con
`--include-max --include-context --include-extras`. Advertencias separan variantes
del efecto y mecánicas DATA_ONLY. La delegación/contexto reales siguen pendientes
del dominio. Primer enlace real ya probado: Garrote Liana base, solo tras daño
confirmado y con metadato RUNTIME_SUPPORTED. PS/mensaje esperan al impacto de la
secuencia, sin repetir turno/RNG. Gate focal: 104 PASS GPU, ocho capturas; 80
headless. Pack pequeño opcional separado del laboratorio; detalles/reconstrucción
en el cuaderno. Para probar: `JUGAR_DEMO.cmd`, F1 Ogerpon nivel 50 y salvaje Wailord
nivel 50, entrar en hierba y elegir Garrote Liana. No se cambian learnsets.
**Teraexplosión normal ya conectada el 2026-10-23**, con un único equivalente
TECHNOBLAST y contrato explícito PARTIAL_RUNTIME/normal/especial/80/sin efectos.
El fallo de descensos se corrigió antes; no se habilitan otros PARTIAL_RUNTIME,
Tera/Astral ni aprendizaje al azar. Tiene marcadores propios (47/59, 70 frames),
sin reutilizar Garrote. Revisadas capturas y corregidos fondo que tapaba cuerpos
y trayectoria que no alcanzaba al rival en nuestra cámara. Gate focal: 237 PASS
GPU / 17 capturas y 180 headless; regresiones focales verdes, sin nueva CI.
Para verlo: `JUGAR_DEMO.cmd`, F4 «Ensayo Tera (reinicia)», entrar en la hierba y
elegir Teraexplosión. Es un preset temporal, no una regla de aprendizaje; Reiniciar
lo elimina. El pack sigue siendo opcional. Detalles/reconstrucción en el cuaderno.
La batería DATA completa mantiene como límite nueve fallos ambientales previos;
no presentarla como verde ni reabrir otros movimientos durante el ajuste visual.
**Lote posterior ya conectado:** Lanzallamas/Rayo/Rayo Hielo, los tres con
RUNTIME_SUPPORTED y datos sin alterar. F5 «Elementales (reinicia)» recorre sus
presets temporales; F4 se mantiene. Cinco IDs/diez clips, no habilitación masiva.
Gate vigente: 542 PASS GPU, 40 capturas y 407 headless; estados secundarios reales
del motor y conservación del estado/RNG comprobados. Ver el cuaderno.
Siguiente paso: revisión humana de estos ensayos y siguiente lote acotado de
efectos ejecutables, manteniendo contratos. Adaptación sigue sin llamada delegada,
Daño Secreto sin contexto/efecto ambiental y Max sin su sistema completo. Sus
recursos preparados permanecen en el laboratorio; no activar mecánicas por tener
una animación ni sustituir esa carencia por un efecto aparentemente correcto.
Antes de una adopción final/conexión general faltan aprobación artística y contraste
EBDX; no construir aún un importador universal ni afirmar cobertura definitiva.
Las entradas de un fotograma delegan animación en Essentials; no estirarlas ni
inventar ejecución mecánica. `nature_power` sigue UNSUPPORTED, `secret_power`
PARTIAL_RUNTIME y `hard_press` DATA_ONLY en nuestro dominio.

Teraexplosión puede usar una sola variante/equivalente (candidato TECHNOBLAST);
Prensa Metálica queda después (candidato HEAVYSLAM). Los demás ignorados pueden
usar efectos genéricos por tipo para pruebas; el usuario los excluye del juego
final, pero no se ha cambiado el pool. Conservar créditos y revisar condiciones
antes de adoptar código/recursos. No implementar aún aprendizaje aleatorio:
mantener niveles/huecos y sortear movimientos es contexto pendiente, no cambio actual.

Después: revisar el alcance de formas alternativas ya preparadas y el
pulido visual pendiente; audio continúa sin conectar y shiny diferido. No ampliar IA ni
regenerar datasets como parte de estos ajustes de presentación.

## Prioridad actualizada — 2026-10-18

Tramo actual: `fix/map-runtime-hardening-v1`, sobre la primera demo certificada.
Prioridad: cerrar regresiones de salto/movimiento/transiciones y trasladar la copia
activa a SSD como clon independiente. Conservar F2 como herramienta de prueba humana.

La `main` actual en `e98e09f75b3f55c7d170f8f9906d49792cef5a6c` ya incorpora la línea
moderna y tiene CI correcto; no repetir la antigua operación de promoción descrita abajo.
El usuario prioriza empezar con imagen: probar `scenes/visual/field_demo.tscn`,
validar controles/legibilidad y ajustar frecuencia de encuentros antes de ampliar campaña.
Rama y guía: `../project_book/VISUAL_FIELD.md`. GF1-A..F sigue como roadmap posterior.

## Paso inmediato — consolidar `main`

La línea moderna está cerrada y certificada en:

`8552f52158ffc21c27b4e8f1dbc7caa63ac1a467`

La operación separada de promoción vive en:

`chore/main-baseline-consolidation-v1`

Merge histórico inicial:

`2f63312e8dc3e61c8fadbd02e97972fff6d0eacc`

Ese commit conserva como padres la antigua `main` y el freeze moderno, pero usa exactamente el árbol moderno certificado; el único commit exclusivo de la `main` antigua añadía un archivo vacío sin funcionalidad.

Para cerrar la promoción:

1. terminar la actualización documental de esta rama;
2. abrir PR contra `main` para disparar la matriz normal;
3. exigir **18/18 workflows SUCCESS** sobre el HEAD final exacto;
4. comprobar que no existe regresión funcional;
5. mover `main` por fast-forward al HEAD certificado de la rama;
6. cerrar el PR de consolidación sin crear un SHA adicional no certificado;
7. desde ese momento, `main` vuelve a ser el baseline de desarrollo normal.

No introducir features nuevas dentro de esta operación.

## Después — Game Foundation V1

Trainer AI ya no tiene trabajo obligatorio pendiente. El siguiente workstream de producto debe ser **Game Foundation V1**.

### Objetivo

Llegar a una primera mini-campaña jugable real, aunque use arte provisional, que demuestre el flujo:

`nueva partida -> inicial -> mapa/pueblo -> ruta -> encuentro/captura -> entrenador -> servicio -> guardar -> cargar -> continuar`

### Orden de construcción

1. **GF1-A — Game State + contrato de campaña**
   - identidad de partida;
   - mapa actual / spawn point;
   - flags de historia;
   - entrenadores derrotados;
   - inicial escogido;
   - progreso mínimo de campaña.

2. **GF1-B — mapas y transiciones**
   - mapas configurables;
   - puertas/warps;
   - spawn points;
   - zonas de encuentro;
   - triggers de entrenador/NPC.

3. **GF1-C — NPC, diálogo y eventos data-driven**
   - diálogo;
   - condiciones por flags;
   - acciones/eventos;
   - entrenador una vez / diálogo posterior;
   - objetos o desbloqueos simples.

4. **GF1-D — Save V3 de mundo/campaña**
   - extender el save sin romper identidad de criaturas;
   - persistir posición/mapa/flags/entrenadores/progreso;
   - carga transaccional y migración explícita desde V2.

5. **GF1-E — servicios y UI mínima**
   - curación;
   - tienda;
   - acceso a PC/storage;
   - party/bolsa básicas;
   - menús suficientes para la vertical slice.

6. **GF1-F — vertical slice de campaña**
   - escena inicial;
   - elección de inicial;
   - primer pueblo;
   - primera ruta;
   - encuentro salvaje y captura;
   - entrenador real con Trainer AI;
   - servicio de curación/tienda;
   - save/load E2E.

Cada tramo debe quedar importable, probado y certificado antes del siguiente. El arte final no bloquea esta fase.

## Después de Game Foundation V1

Solo cuando exista esa mini-campaña estable tiene sentido abrir workstreams separados para:

- rival autónomo de overworld/campaña;
- más mapas, gimnasios e historia;
- arte/sprites/audio final;
- ampliar mecánicas Pokémon concretas exigidas por el contenido;
- builds/distribución.

No reabrir DATA V3 ni Trainer AI por inercia.
