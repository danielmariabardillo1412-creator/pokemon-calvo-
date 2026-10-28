# CUADERNOS DEL PROYECTO

Esta carpeta contiene **memoria temática consolidada**, no diarios cronológicos.

Base de objetos 2026-10-28: inventario de 2.222 IDs, cruce de 565 entradas nativas
y primer piloto de 21 equipados (42 casos / 461 checks Godot). Se reconoce el
mensaje de Hierba Blanca y se prepara política de 43 exclusiones sin borrar datos.
Estado/límites en `../current/ITEM_FOUNDATION.md` y `ITEM_FOUNDATION_V1.json`;
lista completa `ITEM_INVENTORY.json/CSV`, muestra artística de 24 IDs aún sin
descargar imágenes. La presencia de datos no equivale a todos los objetos jugables.

Último cierre 2026-10-28: perfil conjunto Gen9 + Dinamax ya operativo en el mapa
y variante F12. Los 900 movimientos permitidos tienen ensayo nativo positivo
y proyección Godot; 19 exclusiones conservadas. Informe vigente
`../current/UNIFIED_MOVE_SWEEP.json/CSV`, contrato `../current/BATTLE_PROFILE.md`.
El catálogo de ataques y su barrido quedan cerrados a este nivel. No equivale a
certificar todas las combinaciones ni a integrar Mega/Ultra/teracristalización.
El siguiente bloque es el resto de objetos. El contenido posterior es histórico.

Último cierre 2026-10-27: F12 conecta los 11 movimientos de dobles a cuatro
activos nativos, con objetivos, reservas y guardado de ensayo independiente.
No altera la campaña. PASS 44 casos nativos / 454 checks Godot / 130 UI / 196 GPU;
66 muestras temporales revisadas. Informe vigente:
`../current/NATIVE_DOUBLES_INTEGRATION.json`. Quedan perfil conjunto y barrido
final de ataques; no volver a presentar estos 11 como pendientes de conexión.
Los párrafos siguientes conservan el antecedente de la migración del mapa.

Estado 2026-10-27: el mapa habitual ya usa el combate nativo para salvajes y
entrenadores. Ctrl+S/Ctrl+L conserva colección SaveV2, posición/RNG, entrenador y
combate activo en una envoltura atómica. Evidencia vigente:
`../current/FIELD_NATIVE_INTEGRATION.json` (118 headless / 123 GPU / cinco capturas).
Pendientes de ataques: perfil final conjunto, camino nativo de dobles (11) y
barrido final. Catálogo anterior: 889 acciones ensayadas + 11 de dobles + 19
excluidas. No importar formas para recuperar las tres firmas descartadas.
La IA nativa sigue básica; profesional, randomización y reglas custom son fases
posteriores. `RANDOMLOCK_RULES.md` conserva las decisiones de contenido.

## Regla principal

No crear un cuaderno por cada PR, microfase o sesión. Un cuaderno existe mientras un tema necesite memoria operativa propia; al cerrar, queda como resumen humano y la evidencia detallada permanece en `../history/worklogs/`.

GitHub/CI/artefactos del SHA exacto tienen prioridad sobre cualquier cuaderno.

## Vigente: movimientos conectados por grupos — 2026-10-27

El usuario aporta conversación del amigo: **19 Maxi incluidos y prioritarios**.
Para los 53 Z no hay decisión inequívoca del conjunto; se mantienen pendientes
como indica el usuario hasta consultarlo. El de 10 millones de voltios citado
como ignorado sigue sin habilitarse. No excluir Maxi ni añadir otros descartes.

Se resuelven los 12 bloqueos del primer barrido por protocolos/alias/PS y estados
temporales. PP originales pagados, transformación, captura, sustituto que nace/
recibe daño/se rompe, relevo, guardado y limpieza probados sobre estado nativo.
Los sustitutos se observan con eventos privados exactos; no se reprograma daño.

`MOVE_CONNECTION_REPAIR.json/CSV`: **820** ordinarios ensayados en individuales,
**19 Maxi** en Gen8 explícito, **11** de dobles con positivo nativo pero sin UI
doble, **1** Cerco Dimensión condicionado a Hoopa Desatado que falta en datos/
arte, **53 Z pendientes**, **15 descartados**. No certificar todas las semánticas
por pasar fixtures, ni excluir los que requieren otra modalidad/forma.

`JUGAR_COMBATE_MAXI.cmd` usa la misma escena con Dinamax, PP/PS reales, tres turnos,
guardado propio, vuelta a HP base y clips existentes. Separado de Gen9; no se
activa globalmente la aventura ni un perfil mixto. Tamaño gráfico 1,35 provisional,
sin sustituir imágenes. IA básica, reglas propias/vidas después de la base.

Gate vigente: 99 dedicados + 51 GPU/8 capturas; 3.362 casos generales, 74 contextos,
11 dobles nativos; regresiones 100 backend, 86 aventura, 120 medicinas, 23 GPU
mochila y 20.809 playback PASS. Dos consumidores visuales compartidos amplían
metadatos nativos; fórmulas, datos, arte y política preservados. Faltan forma
Hoopa, modalidad dobles/perfil conjunto, Z y propietario real mapa/guardado.

## Antecedente: movimientos antes de continuar objetos — 2026-10-27

El usuario pide un barrido completo para evitar dar los movimientos por cerrados.
Se crea una herramienta de solo lectura, reutilizando el motor y adaptador
actuales: `audit_moves.py` y `verify_move_audit.py`. Guía en
`tools/showdown_engine_probe/MOVE_AUDIT.md`; resumen y CSV completo de 919 IDs
en `../current/MOVE_FUNCTIONAL_AUDIT.*`.

3.343 casos, 13.372 decisiones/round trips y 3.338 continuaciones guardadas;
15 contratos independientes PASS y cero errores nativos. Resultado conservador:
772 pasan contextos de integración, 48 requieren otros escenarios y 12 tienen
bloqueos. 19 Maxi: perfil pendiente; 53 Z pendientes; 15 excluidos. No confundir
integración en fixtures con certificación completa de todos los efectos.

Bloqueos agrupables: OHKO, intercambiar condiciones, mensaje de animación,
PS simultáneos, alias Vice/Vise y estados temporales (Mimic/Transform/Sustituto).
No se corrige ni admite automáticamente nada durante el barrido. Objetos en
pausa hasta esclarecer esto; IA básica y novedades propias para después. Datos,
arte, código de juego y perfil sin cambios. El servidor histórico sigue separado.

## Antecedente: base de Pokémon antes de novedades — 2026-10-27

El usuario fija el orden: terminar primero sistemas básicos (combate, objetos,
etc.) y mantener la IA básica. Su revisión profesional y las reglas propias se
aplazan. Para después quedan **cuatro vidas** y retirar/desaparecer los Pokémon
muertos en lugar de conservarlos debilitados. No interpretar esto como cambios
ya implementados ni inventar reglas adicionales de vidas/multijugador/PC.

Mochila del launcher Showdown: **15 medicinas**, objetivo activo/reserva y slot
de PP. Cinco pociones conservan las cantidades del proyecto (20/60/120/total);
seis remedios y cuatro recuperadores de PP completan este grupo. Sin efecto o
acción rechazada, no se consume objeto ni turno. Una preparación nativa incluye
medicina, rival y residuales; confirmación publica después el diario de consumos.
Schema 2 rechaza perfiles/versiones incompatibles; no migra SaveV2. Marcadores
horarios se normalizan para un replay independiente de la hora real.

Evidencia `../current/SHOWDOWN_MEDICINE_INTEGRATION.json`: 120 Godot, 21 Node,
23 GPU/5 capturas, regresiones 86 aventura y 100 backend PASS. Se contrastaron
reglas en la referencia local Essentials, sin copiar código ni importar assets;
los valores iniciales proceden del registro propio. Datos y arte intactos.
No son todos los objetos: quedan Revivir/otros grupos, uso fuera de combate,
mapa/guardado y fronteras del motor. No adelantar IA profesional ni randomlock.

## Antecedente: encuentros y colecciones con Showdown — 2026-10-27

Se ha conectado una sesión optativa de salvajes/entrenadores a PlayerCollection,
reutilizando nuestros servicios de captura/inventario/PC/huida/progresión.
`JUGAR_AVENTURA_SHOWDOWN.cmd` permite encuentros sucesivos dentro del proyecto
con un equipo e inventario compartidos en memoria. Animaciones de captura/huida
existentes, sin nueva ilustración ni cambio del mapa/guardado habitual.

Captura fallida y huida fallida/bloqueada consumen una reacción nativa del rival
y un fin de turno. Bola/RNG/inventario se confirman después de validar. Los
resultados conservan referencias/identidad/KO y conceden experiencia solo en
victoria, sin duplicar al repetir la liquidación. Checkpoints de sesión incluyen
la transacción de bolsa y RNG, y se rechazan sobre otra colección base.

`../current/SHOWDOWN_ADVENTURE_INTEGRATION.json`: 86 sesión, 28 GPU/5 capturas,
7 Node y regresiones 100 Showdown/13 capturas, 472 core, 20.809 playback y 628
corpus IA PASS. Tres fuentes del piloto anterior cambian; servidor/sesiones
históricos, datos y arte conservan hashes. Los informes anteriores son evidencia
de esas versiones; el verificador vigente es `verify_adventure.py`.

Faltan medicinas, IA profesional y propietarios reales de mapa/guardado/reglas
de campaña. No activar globalmente por el resultado de este piloto. Siguen
sueño heredado, formas/sustitutos, perfil Dinamax/Gen9 y empaquetado pendientes.
Sin GitHub ni sustituciones visuales.

## Antecedente: combate Showdown jugable optativo — 2026-10-27

Entrada: `JUGAR_COMBATE_SHOWDOWN.cmd`, mismo proyecto y recursos. La escena de
prueba resuelve un combate de dos Pokémon por lado con Showdown, permite ataques,
curas, cambios y continuaciones, termina con KO/victoria y guarda/carga incluso
durante Ida y Vuelta. Los guardados de prueba son independientes de campaña.
No se ha sustituido todavía el backend de la aventura habitual.

[Backend y guía](../../modules/battle/backends/showdown/README.md): proceso
persistente compartido con el laboratorio anterior, preparación/validación/
confirmación, snapshot versionado con perfil y hashes, errores atómicos y
recuperación del último estado confirmado. El mirror BattleState es una vista
para presentación, no el estado autoritativo para simulaciones de IA.

Evidencia `../current/SHOWDOWN_BACKEND_INTEGRATION.json`: **100 checks GPU y
13 capturas**, 10 transacciones Node; core/playback/corpus de IA 472/20.809/628
PASS. La prueba anterior pasa con el núcleo compartido: 39 Node, 27 Godot y
2.496 ejecuciones/snapshots. Regionales/shiny, exclusiones, pérdida del proceso,
replay/RNG y guardado a mitad de turno incluidos. No hay sustituciones de imágenes.

Los 233 archivos de producción existentes mantuvieron sus hashes; se añadieron
cinco fuentes GDScript optativas y auxiliares. El juego normal sigue con 620
admitidos/230 pendientes y conserva sus partidas/formato histórico. No se toca
F:, no se regeneran datos y GitHub sigue aplazado.

Próximo: adaptador de sesiones reales para captura/mochila/huida/conciliación de
resultados, y conexión de la IA profesional por acciones/observaciones/mundos
plausibles. El rival actual de laboratorio no la sustituye. Mantener límites de
formas temporales, sustitutos, relojes heredados y perfil Dinamax/Gen9, así como
licencias/empaquetado. Se reutiliza el simulador; no volver a construir ataques
por familias mientras se cierra esta ruta.

## Decisión vigente: reutilizar el sistema estándar de combate — 2026-10-26

El usuario solicita evaluar la reutilización de un sistema completo y de otros
componentes estándar, en lugar de seguir reproduciendo efectos en lotes pequeños.
Se construyó el [laboratorio Showdown](../../tools/showdown_engine_probe/README.md):
su API nativa funciona en Godot 4.7 mediante un proceso local persistente.
Resultado: **viable para avanzar con un backend experimental opcional**, sin
sustituir todavía el servidor de producción. Evidencia:
`../current/SHOWDOWN_BACKEND_FEASIBILITY.json`.

39 comprobaciones Node/27 Godot, importación de criaturas reales, PS/PP/
estadísticas/identidad, snapshots/RNG, decisiones atómicas, cambios y 64 forks
en un solo lote. Un turno se proyecta a BattleEvent y nuestra línea de animación.
Barrido de 832 movimientos con tres semillas: 2.496 ejecuciones y snapshots sin
errores; no equivale a certificar todas sus reglas ni a admitirlos en el juego.
Los 19 Maxi se prueban por Dinamax Gen8; combinarlo con el perfil moderno Gen9
requiere una decisión/versionado de reglas. No se elige una mezcla silenciosa.

Los 919 IDs de movimientos están presentes. Los 1.025 base y 57 regionales
coinciden en estadísticas base/tipos tras alias explícitos; los pesos también
están disponibles. 60 diferencias de campos de movimientos quedan inventariadas
(54 corresponden a variantes Z, seis son otras filas). 313 habilidades tienen
entrada directa; 59 ausentes son ajenas a la serie principal según PokeAPI y
Evocarrecuerdos necesita una variante contextual. 530 objetos tienen entrada,
principalmente reutilizables como objetos equipados en combate.

La biblioteca puede ahorrar lógica de movimientos/habilidades/objetos equipados
y reglas de combate. No incorpora nuestra mochila, captura/huida, experiencia,
evolución de campaña, PC, mundo o reglas randomlock. Mantener esas piezas y la
política/memoria de IA, adaptando interfaces y mundos plausibles sanitizados.
No usar snapshots secretos reales para las decisiones de entrenadores.

Próximo: fachada optativa y versión de backend, traducción de los eventos
compartidos y combate visible completo; luego reacciones de captura/mochila,
persistencia temporal e IA. Mantener el backend anterior para sesiones antiguas.
Dejar de ampliar muchas fórmulas propias hasta medir esta integración. El juego
actual conserva 620 admitidos/230 pendientes y sus 233 archivos protegidos.

Créditos de Showdown/pkmn y dependencias MIT conservados en
`tools/battle_reference/THIRD_PARTY_NOTICES.md`; no se ha copiado código de los
ports con condiciones pendientes. Para distribuir el nuevo backend hará falta
empaquetar el trabajador/Node y sus avisos, o evaluar PSVM nativo posteriormente.
El comparador no certificará reglas comparando el mismo motor consigo mismo:
mantener resultados esperados independientes e invariantes de integración.

## Integración vigente de movimientos — 2026-10-26

Último lote: **ocho curaciones** — Aromaterapia, Cascabel Cura, Alivio, Gota
Vital, Cura Selvática, Plegaria Lunar, Purificación y Descanso. Perfil:
**620 admitidos / 299 no disponibles / 230 pendientes de mecánica**.
`../current/HEALING_MOVES.json`: 2.546 checks, 192 casos y 16 capturas GPU
revisadas; general 9.890 checks y 1.822 clips. Se separan activos/reservas,
debilitados, estados, redondeos de PS, reflejo/sustituto e inmunidades. Descanso
tiene sueño fijo probado con Madrugar, cambio a reserva, save/replay y cura de
equipo; su marcador aditivo no cambia los snapshots históricos cuando está apagado.

Comparador ampliado: **7.284/7.284 MATCH**, incluidos 1.374 escenarios nuevos.
Los primeros barridos encontraron errores de habilidades de reservas y redondeo
de Gota Vital que se corrigieron antes del cierre. 42 controles unitarios + tres
negativos reales PASS. El ciclo completo de sueño se comprueba en el servidor;
no se expone el reloj privado rival ni se amplía la estrategia de IA. Core/
playback/IA: 472/20.809/628 PASS. DATA V3 sigue en 624 PASS / nueve fallos conocidos.
No hubo sustituciones de imágenes ni copias de motores externos al runtime.

Lote anterior: diez de atrapamiento integrados con un sistema compartido.
Perfil: **612 admitidos / 307 no disponibles, 238 pendientes de mecánica**.
Evidencia: `../current/BINDING_MOVES.json` (1.883 checks, 240 casos, 20 capturas
GPU) e informe live (9.858 checks). Duración/daño, bloqueo, retirada/KO del origen,
objetos/excepciones y Relevo probados. RUN bloqueado consume turno sin RNG de
huida; captura real limpia los estados. La IA recibe un reloj estimado y hechos
anunciados, no duración/divisor secretos. Datos, arte y política sin cambios.

Lote anterior: once de potencia variable, con cierre de 602 admitidos /
317 no disponibles, 248 pendientes de mecánica.
Evidencia: `../current/VARIABLE_POWER_MOVES.json` (1.854 checks, 264 casos, 22
capturas GPU) y `../current/LIVE_MOVE_INTEGRATION.json` (9.818 checks).
Incluye PS, velocidades, amistad, PP tras consumirlos y etapas positivas del
rival; potencia/contacto se resuelven en copias. La velocidad live individual
corrige el redondeo racional y se comparte con el orden; el flag apagado conserva
el comportamiento previo. PS recibidos antes en el turno y continuaciones JSON
se prueban en el servidor real. Pesos, move-calling y otras familias siguen aparte.

Lote anterior: seis de daño fijo habilitados y Calamidad corregido, con cierre
de 591 admitidos / 328 no disponibles, 259 pendientes de mecánica.
Evidencia: `../current/FIXED_DAMAGE_MOVES.json` (1.364 checks, 168 casos y 14
capturas GPU PASS) y `../current/LIVE_MOVE_INTEGRATION.json` (9.774 checks).
Se respetan inmunidades/sustitutos y precisión/PP, sin escalar daño fijo por
estadísticas, STAB, resistencia, quemadura o críticos. Calamidad aplica la mitad
de PS actuales; su potencia 1 canónica permanece congelada. Contacto de
Superdiente corregido en una copia. La fixture visual usa Danza Espada del rival:
Splash excluido se convertía en Esfuerzo y añadía retroceso al escenario.

El lote anterior de etapas permanece en `../current/STAT_STAGE_MOVES.json`:
2.005 checks, 192 casos y 16 capturas GPU; seis habilitados/dos corregidos en
aquel cierre de 585 admitidos. No sumar esas cifras a las nuevas como si todos
los ejemplos fueran movimientos distintos.

También están integradas 57 regionales ordinarias y las parejas shiny
existentes (1.011 base + 57 regionales). F3 alterna normal/shiny; captura/PC/save
conservan forma y color. No se generan shiny de los 14 recursos propios ni se dan
por resueltas otras formas especiales. Evidencia:
`../current/POKEMON_VARIANTS_INTEGRATION.json`; detalles en `VISUAL_CATALOG.md`.

Juego local: perfil de individuales habilitado, 620 movimientos admitidos y
catálogo visual de 900 IDs / 1.822 clips. Los 19 pilotos no significaban que
estuvieran completas las 919 mecánicas canónicas. Consultar el
[informe live](../current/LIVE_MOVE_INTEGRATION.json) y la
[lista de 299 no disponibles](../current/LIVE_MOVE_UNAVAILABLE.csv).
`NEXT_STEPS.md` / `PROJECT_STATE.md` conservan alcance, evidencia y pendientes.

## Cuadernos actuales

### Herramientas externas para acelerar validación de combate — 2026-10-26

**Fuentes de fans descargadas y auditadas por petición del usuario:**
`D:\Proyectos\Pokemon Calvo Referencias\README.md`. Se conservan fuera del juego
Kurokamori/Pokemon-Godot-Essentials (GDScript), Decryptu/pokerecomp (GDScript Gen
1/2, MIT) y Maruno17/pokemon-essentials (Ruby v21.1/Gen 8, CC BY-NC-SA 4.0), con
commits, avisos/créditos, tamaños e inventario fijados. El port Godot no incluye
licencia general explícita: aclarar condiciones antes de copiar código y
conservar los créditos originales de su README/Essentials/Gen9.

Cruce estático: 208 de los 238 pendientes tienen datos en las dos variantes de
Essentials y clase de efecto en Ruby; 194 tienen mención exacta del código de
función en scripts del port. No son 208 movimientos ya validados o integrados.
Los 19 Maxi y otros once siguen sin entrada en esas tablas. Hay referencias
útiles para protecciones, pantallas/terrenos, estados, objetos y otras familias.

Se detectaron nueve rutas de registro inexistentes en el propio árbol del port
Godot y una fórmula de Protección con factor 2/tope 8 frente a la moderna con
factor 3. Godot 4.8 y reglas antiguas de pokerecomp tampoco se trasladan tal cual
a nuestro 4.7/perfil moderno. No se ejecutó código ajeno ni se importó al motor.
Los 232 archivos protegidos mantienen sus hashes; admitidos/pendientes no cambian.
Evidencia: `../current/EXTERNAL_SOURCE_AUDIT.json` y los inventarios/cruce detallado
de la carpeta de referencias. Se mantienen nuestro motor y el comparador externo;
el ahorro será adaptar familias y contrastar casos, no sustituir el proyecto.

Petición: investigar ayuda existente sin deteriorar el juego ni reemplazar el
motor por una promesa de automatización. Se revisan fuentes de sus autores:

| Proyecto | Encaje evaluado |
| --- | --- |
| [Pokémon Showdown](https://github.com/smogon/pokemon-showdown/blob/master/sim/SIMULATOR.md) | Simulador ejecutable/API/CLI y [tests específicos](https://github.com/smogon/pokemon-showdown/blob/master/test/TESTS.md). Candidato principal como referencia independiente para comparar lotes. Ya se consultaba su código; ejecutar escenarios es un paso adicional. |
| [@pkmn/sim](https://github.com/pkmn/ps/tree/main/sim) | Extracción modular de Showdown. Probada versión exacta 0.10.11 como referencia aislada. Generaciones 1–9; generador de equipos aleatorios es otro paquete, innecesario para fixtures explícitas. |
| [PSVM](https://github.com/ethanl21/psvm) | Integra Showdown mediante biblioteca nativa; su autor advierte que sigue en construcción y que el ejemplo Godot 4 está previsto. No adoptarlo como atajo garantizado. |
| [Pokémon Essentials](https://github.com/Maruno17/pokemon-essentials) | Referencia útil de efectos/familias, pero pertenece a RPG Maker XP/Ruby; no es un plugin de nuestro Godot. |
| [PokemonBattleEngine](https://github.com/Kermalis/PokemonBattleEngine) | C# y alcance B2W2/Gen 5, con mecánicas pendientes declaradas. No cubre por sí solo el alcance Gen 1–9. |
| [pokerecomp](https://github.com/Decryptu/pokerecomp) | Godot/GDScript, pero reproduce Gen 1–2, requiere datos del usuario y su README pide Godot 4.8; no es sustitución directa para el juego actual en 4.7 y nueve generaciones. |

**Herramienta reutilizable ya construida, autorizada por el usuario:**
[`tools/battle_reference/README.md`](../../tools/battle_reference/README.md).
Referencia fijada `@pkmn/sim@0.10.11` en `.godot/battle_reference/runtime/`, mediante
`npm ci --ignore-scripts`. El juego mantiene su motor. Se guardan manifiestos,
observaciones de ambos motores, diferencias por campo en JSON/CSV, versiones,
tiempos y hashes, con salida de error si falta un resultado o no es comparable.

Barrido de las primeras dos familias: **1.932 coincidencias / cero diferencias / cero casos no
comparables**, lotes de 150, 37,491 s locales. Incluye 600 de etapas y 1.332 de
daño fijo: siete movimientos más, PS exactos de cuerpo/muñeca, KO, niveles
1/50/100, PS impares, STAB/resistencias sin multiplicación, inmunidades,
Allanamiento, Potencia/Multiescamas sin escalar y contacto con Punta Acero cuando
el defensor sobrevive. 24 pruebas de controles + tres con motores reales PASS.
Evidencia: `../current/BATTLE_REFERENCE_VALIDATION.json`. Datos y arte intactos;
la implementación live de daño fijo se valida aparte en `FIXED_DAMAGE_MOVES.json`.

Optimización posterior de tamaño de lote: los mismos 1.932 casos con
`--batch-size 500` tardan 13,597 s en cuatro arranques por motor, frente a los
37,491 s de 13 lotes de 150. Manifiesto, observaciones completas de ambos motores,
veredictos y fuentes protegidas idénticos; evidencia en
`.godot/battle_reference/batch_size_500/comparison.json`. Dos mediciones locales,
sin atribuirles un ahorro garantizado en futuros lotes. Usar 500 explícitamente
para estos barridos; conservar grupos pequeños para aislar diferencias. La
implementación puede agrupar más movimientos cuando comparten infraestructura;
el tamaño de los casos de prueba no equivale al número de movimientos añadidos.

Ampliación anterior: **4.950 coincidencias** (600 etapas, 1.332 daño fijo y
3.018 potencia variable) con lotes de 500. 30 controles unitarios y tres de
adaptadores reales PASS. La potencia nueva se observa en el evento `BasePower`
del simulador original, sin alterarlo, y en los eventos reales de daño de Godot;
no se vuelve a implementar la fórmula de referencia en Python. Se comparan
contacto, impacto y PP, no los HP ordinarios finales entre motores con distinto
RNG. Este cierre se amplía a continuación.

Vigente: **5.910 coincidencias**, incorporando 960 de atrapamiento y 60 ciclos
de ocho turnos con Garra Garfio. 36 controles unitarios y tres con adaptadores
reales PASS. La duración natural se valida en rango, sin igualar RNG. El daño
residual se observa en `damage`: AfterDamage del ataque no lo notificaba, por lo
que se corrige ese observador antes de validar. No se altera el simulador ni se
compara daño ordinario exacto. Evidencia y límites en el JSON actual de referencia
y `BINDING_MOVES.json`; la implementación sigue en el motor propio de Godot.

Acupresión solo compara cero o una elección posible; Robasombra acierta con
seguridad en estos fixtures. No se intenta igualar tiradas entre RNG distintos.
Solo compara daño/HP exactos para la familia fija, no daño ordinario, animaciones
ni todas las interacciones. Se amplía por familias según se implementen, sin dar
por comprobados todos los movimientos
ni sustituir los tests propios. Este tiempo medido no cuantifica un ahorro frente
a la revisión humana. Créditos/avisos MIT de Showdown, pkmn contributors y Mykola
Bubelich (ts-chacha20), con versiones de las cinco dependencias, conservados en
[`THIRD_PARTY_NOTICES.md`](../../tools/battle_reference/THIRD_PARTY_NOTICES.md).

**Prueba histórica de viabilidad:** `@pkmn/sim@0.10.11` instalado con versión
exacta/lockfile y `--ignore-scripts` solo bajo `.godot/showdown_research/` de D:.
No dependencias globales ni ejecución de servidor público. Se ejecutan ocho
movimientos del lote reciente y cinco variantes de sustituto/Simple/Respondón.
Los **13 escenarios coinciden en las siete etapas finales de ambos activos**.
Resultados y diferencias por caso en `comparison.json`; scripts `probe.cjs` y
`godot_probe.gd`, inputs y resultados individuales en esa misma carpeta temporal.
El lockfile fija también dependencias transitivas. Código declarado MIT por
Showdown/pkmn: si se incorpora a una herramienta permanente, conservar sus avisos
y atribuciones; la prueba no incorpora ni publica gráficos de terceros.

El experimento usa estados sintéticos y acciones inertes de referencia; Splash
y Run Away no se habilitan en el juego. No compara daño, PP, precisión, distribución
de RNG, persistencia ni todas las interacciones. No deducir paridad competitiva
de 13 ejemplos, ni convertir estos números en un nuevo contador acumulado de tests.

La conclusión de aquella investigación fue construir un adaptador por familias;
su primera versión operativa se describe arriba. No hay migración de motor ni
importación automática de los 265 pendientes. El experimento de 13 ejemplos no
se suma al contador operativo de 600 como si fueran escenarios nuevos distintos.

### `RANDOMLOCK_RULES.md`

Reglas de selección confirmadas de movimientos, habilidades, especies y formas;
decisión Z pendiente, Max conservados y cruce con la cola artística. La política
ejecutable y el informe de estado están enlazados en el cuaderno. Consultarlo
antes de ampliar pools o seguir buscando recursos de movimientos descartados.

### Catálogo visual y su registro de sustituciones

`VISUAL_CATALOG.md` conserva decisiones y pruebas del catálogo.
`VISUAL_SUBSTITUTIONS.md` es su índice humano de equivalencias/cambios, solicitado
por el usuario; no un cuaderno de otra microfase. Toda sustitución futura se
registra allí con antes/después, motivo, alcance y evidencia.

### `VISUAL_FIELD.md`

Estado: **PRIMERA PRUEBA VISUAL / VALIDACIÓN** (2026-10-18).

Ruta con imagen sobre el laboratorio real, movimiento, hierba, encuentros regulables,
captura y transiciones. Incluye cómo ejecutar y distinguir esta prueba de GF1.

### `DATA_V3.md`

Estado: **CERRADO / CERTIFICADO**.

Resume fuente, contrato estructural, fronteras runtime, certificación final y condiciones para reabrir DATA V3.

### `TRAINER_AI.md`

Estado: **CERRADO / COMPLETED**.

Conserva la memoria completa de la línea FASE19–33 y C1–C3f que culminó en el cierre runtime 26.67.

### `TRAINER_AI_GAME_READY.md`

Estado: **CERRADO / VALIDATED**.

Conserva la fase post-cierre que añadió desempate game-ready, full-battle adversarial y benchmark, congelada en 27.1.

### `TRAINER_AI_EXPERTISE.md`

Estado: **CERRADO / CERTIFIED / FROZEN**.

Separa estilo táctico de competencia/expertise sin modificar la frontera anti-cheat.

### `TRAINER_AI_CAMPAIGN_PERSISTENCE.md`

Estado: **CERRADO / CERTIFIED / FROZEN**.

Conserva el cierre P1-A..P1-D de ownership, persistencia de consecuencias entre combates, recovery/replacement explícitos y rematch E2E.

### `TRAINER_AI_HANDOFF_2026-09-03.md`

Referencia histórica de relevo. No representa estado vivo posterior al freeze final.

## Próximo cuaderno

No existe todavía `GAME_FOUNDATION.md` durante la consolidación de `main`. Debe crearse al abrir formalmente Game Foundation V1, una vez la nueva `main` haya sido promovida y certificada.

## Cuándo crear otro cuaderno

Solo cuando empiece un workstream suficientemente grande y distinto como para que mezclarlo en otro cuaderno cree confusión.

## Diferencia con otras carpetas

- `../current/`: dónde estamos y qué toca ahora.
- `../architecture/`: cómo está construido el sistema.
- `../adr/`: por qué se tomó una decisión arquitectónica.
- `../history/`: evidencia y diarios cerrados.
