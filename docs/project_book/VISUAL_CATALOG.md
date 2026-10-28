# Integración local del catálogo visual — 2026-10-18

## Hito acordado para guardar la versión completa en GitHub — 2026-10-26

El usuario decide terminar y revisar la parte visual antes de limpiar/subir la
versión completa. Se sigue en local. El hito no depende de terminar toda la
programación: depende de tener los recursos visuales del alcance elegido listos,
con procedencias/condiciones/créditos revisados y empaquetados de forma reproducible.

Queda pendiente reunir los recursos que hoy viven en packs locales y `.godot`,
separar los necesarios del juego de capturas/pruebas temporales y comprobar una
copia independiente sin acceso a las rutas originales de D: o F:. La subida futura
debe guardar también los recursos necesarios, preservando los datos grandes y
evitando carpetas de versiones antiguas mezcladas con el proyecto activo.

La revisión de permisos/créditos y el empaquetado siguen abiertos. No se ha
publicado arte ni limpiado GitHub. Mantener el alcance shiny confirmado: usar
recursos existentes, sin generar las 14 variantes ausentes. Los recursos ya
integrados no se rehacen por esta decisión de publicación.

## Vigente: clips conectados a modificadores reales — 2026-10-26

Ocho movimientos comprobados en combate normal con los clips existentes:
Niebla, Reversión, Cambiaalmas, Cambiafuerza, Cambiadefensa, Acupresión,
Niebla Clara y Robasombra. Los seis primeros se añaden al perfil; los dos últimos
ya hacían daño, pero ahora ejecutan también sus efectos sobre las etapas.

Las reasignaciones tienen evento propio `STAT_STAGES_REASSIGNED`, enlazado al
reproductor solo tras resolución auténtica. Fallos, inmunidades y sustitutos no
simulan un efecto exitoso. Robasombra roba antes del daño; el clip se vincula al
daño confirmado. Acupresión mantiene la referencia propia de individuales. No
se añade un dibujo, fondo, recolor ni sustitución al ledger.

Gate: 2.005 comprobaciones PASS / 192 casos / 16 capturas GPU. Contact sheet y
fuentes verificadas en `../current/STAT_STAGE_MOVES.json`. Revisión visual de las
ocho muestras nativas y sus estados posteriores. La captura de la primera Niebla
espera al layout del panel para evitar medir un preview de tamaño cero.
Interoperabilidad comprobada con Vulpix de Alola shiny. Pack base, variants,
catálogo de movimientos y renderer congelado permanecen intactos.

Perfil actual: **585 admitidos / 265 pendientes de mecánica**. La biblioteca
visual sigue en 900 IDs / 1.822 clips; no confundir ambas coberturas. Informe live
regenerado: 9.750 PASS, 585 fixtures y diez capturas del gate general. Las pruebas
del lote se suman como evidencia separada, sin inventar recuentos acumulados.

## Bloque anterior: regionales y shiny de fuentes existentes — 2026-10-26

Integrados en el juego local: 57 regionales ordinarias (18 Alola, 19 Galar,
16 Hisui, 4 Paldea) con estadísticas/tipos/learnset propios; 1.011 parejas shiny
base y 57 regionales shiny, frente/espalda. Se preservan todos los frames y tiempos
de las fuentes. No se dibuja ni recolorea para cubrir los 14 shiny ausentes.

Pack adicional `assets/local_battle_variants/`: 2.250 PNG / 127.138 regiones;
constructor `tools/visual/build_pokemon_variants.py`. Registro de procedencia SHA
en `.godot/pokemon_variant_checks/build.json`; informe reproducible en
`../current/POKEMON_VARIANTS_INTEGRATION.json`. Pack base y renderer congelado
permanecen intactos. Carga perezosa con caché limitada y bounds medidos, conservando
la perspectiva de la arena; las escalas nuevas no se anuncian como medidas oficiales.

F3 añade botón Shiny y las 57 entradas regionales. F1 admite `vulpix_alola` y
`vulpix_alola__shiny`. Los combates reales muestran el aspecto elegido durante
ataques, cambio, captura y resultados; UI marca ★. El color persiste al guardar,
cargar, enviar al PC y evolucionar, y se copia/restaura temporalmente con Transformación.
Sorteo 1/4.096 configurable y aislado del RNG mecánico.

Validación GPU: 13.807 comprobaciones / cuatro capturas PASS. Todos los atlas nuevos
cargan y sus envelopes caben en tres tamaños de arena. Captura/PC/save, evolución,
Transformación y entrenador probados. La revisión visual humana cubre las muestras,
no todos los fotogramas. Otras formas especiales siguen aparte. Los recursos de
terceros siguen locales, sin exportación/publicación. No se amplía el ledger de
sustituciones de movimientos: no se ha reemplazado ningún dibujo de ataque.

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


**Registro único solicitado por el usuario:** [VISUAL_SUBSTITUTIONS.md](VISUAL_SUBSTITUTIONS.md).
Reúne todas las equivalencias vigentes de movimientos y cambios anteriores;
separar dibujos sustituidos de ajustes de cámara/tono. Toda sustitución futura
de imagen/animación/fondo debe añadir su antes/después, motivo, alcance y evidencia
al registro; para especies, indicar también ID y manifiesto. No hacerlo solo en chat.

Se amplía la demo existente `scenes/visual/field_demo.tscn`, no se crea otro juego.
Se conserva el proyecto clonado de GitHub y su motor de datos, progresión, captura,
encuentros y Trainer AI. No se descargan ni regeneran snapshots de datos brutos.

## Bloque anterior: F9 conecta cuatro climas y Fría Acogida — 2026-10-26

Diez activaciones nativas de rain_dance/hail/sandstorm/snowscape/chilly_reception
enlazadas a WEATHER_CHANGED confirmado; Fría Acogida ya bajo nieve conserva su
activación al relevar, sin duplicar la animación al crear nieve nueva. Cuatro
bucles comunes se reproducen desde el estado proyectado y persisten entre
acciones, sin cuerpos nativos duplicados ni reiniciar el turno del motor.
Se conservan durante la captura hasta el paso de captura completada.

Recursos `.godot/battle_weather/`: casts.json SHA
`c14aa0a4adae54e980a82ab2dad18b0c7c3dbb684fc847b73cbd5f18875d0704`;
common.json SHA `044675099b36945a28c7838a8d1a5a59257167aa0ce26d5d94fec3970e2ad42d`.
442.397 bytes PNG copiados. Se reutilizan los tres bucles ya exportados; se
convierte Common:Sandstorm desde su fuente local fijada por SHA, conservando
20 frames (los otros tienen 30), sin regenerar catálogo ni datos. Todos a 20 fps.
Nieve y granizo comparten el arte original, con estados/mecánicas diferentes.

`../current/WEATHER_PILOT.json`: 1.523 PASS/120 casos/11 capturas GPU; lámina de
activación/persistencia y elección de reserva con nieve observadas. Nuevas
capturas de activación back; ambos lados comprobados en el motor, sin nueva
certificación front completa. Fuentes de reglas:
[condiciones de Showdown](https://github.com/smogon/pokemon-showdown/blob/master/data/conditions.ts),
[Fría Acogida](https://github.com/smogon/pokemon-showdown/blob/master/data/moves.ts)
y [orden residual](https://github.com/smogon/pokemon-showdown/blob/master/sim/battle.ts).

Acumulado: 15 mecánicas base en pilotos F7/F8/F9, 4.693 checks, 360 casos y
40 capturas. Enlaces visuales totales: 20 IDs/40 clips de activación contando
los cinco elementales anteriores, más cuatro bucles de clima; no equivale a
20 movimientos competitivos completos. Restan cuatro IDs sin mecánica propia
y el despliegue/interacciones pendientes; los 19 handoffs globales siguen abiertos.
Inventario de alternativas intacto en 41 IDs/49 familias/98 clips.

## Tramo anterior conservado: F8 conecta cinco movimientos de estado — 2026-10-26

Se añaden los diez clips ya revisados de roar, whirlwind, teleport, baton_pass
y parting_shot, solo sobre eventos MOVE_EFFECT_RESOLVED del motor del piloto.
No se activan por PP, ACTION_USED aislado ni movimiento fallido. Se omiten los
cuerpos/fondos nativos y se conservan los cuerpos reales; retirada/entrada y
fin del encuentro provienen de eventos autoritativos. Sin glifos genéricos
duplicados en esos pasos ni daño inventado para animar movimientos de estado.

Pack `.godot/battle_status_switch/manifest.json`, SHA
`6e6255dee81de130110edb89c3fa8ca5b161ce72a05524d9d2b4e54bf41ffb81`;
diez clips/12.277 bytes PNG copiados. Fuentes sin cambios: ROAR, GUST (equivalente
ya seleccionado para Whirlwind), TELEPORT, BATONPASS y PARTINGSHOT. Relevo usa
31 frames back y 35 front; no se recorta para igualarlos. Detalle en el registro
VISUAL_SUBSTITUTIONS. No hay nuevas sustituciones ni créditos externos.

`../current/STATUS_SWITCH_MOVES.json`: 1.326 PASS/120 casos/diez clips y 18
capturas GPU. Dos láminas observadas, vistas back/front y flujo F8 salvaje con
elección de reserva. Acumulado con F7: diez mecánicas en piloto, 3.170 checks,
240 casos y 29 capturas. El reproductor de daño anterior, la ruta, los comandos
y el corpus IA/entrenadores pasan sus regresiones; detalle en PROJECT_STATE.

Restan nueve IDs sin mecánica propia y el despliegue/interacciones de estos diez.
La interfaz y búsqueda de entrenador no se habilitan todavía. Los 19 handoffs
globales permanecen abiertos. Fuentes y datos canónicos intactos; mismos
41 IDs/49 familias/98 clips en el inventario de alternativas.

## Tramo anterior conservado: F7 conecta cinco mecánicas individuales — 2026-10-25

El pack y sus diez clips no cambian. En F7 se habilitan las mecánicas de
u_turn/volt_switch/flip_turn y circle_throw/dragon_tail en encuentros salvajes
individuales. La petición de reserva, pausa y continuación son del servidor;
la presentación reproduce los eventos SWITCHED reales con retirada/entrada.
La expulsión salvaje cierra sin XP/captura y reproduce la salida del objetivo.
Ya no se muestra el aviso de efecto pendiente en este modo explícito; F6 conserva
el aviso porque continúa siendo el contraste SOLO DAÑO.

No se han sustituido imágenes ni cambiado sus tiempos/impactos. La progresión
de PS y las partículas se mantienen; la transición depende del resultado del
motor. Fuente de mecánicas: [Showdown moves](https://github.com/smogon/pokemon-showdown/blob/master/data/moves.ts),
[acciones y relevos](https://github.com/smogon/pokemon-showdown/blob/master/sim/battle-actions.ts)
y [regla del encuentro salvaje](https://bulbapedia.bulbagarden.net/wiki/Dragon_Tail).

Informe `../current/SWITCH_MOVE_PILOT.json`: GPU 1.844 PASS/120 casos/11 capturas.
Observadas las cinco partículas, tres pantallas de elección y entrada de la
reserva seleccionada. Modo entrenador del motor probado en ambos lados;
interfaz/IA/planificación del entrenador todavía sin desplegar. Tampoco certifica
interacciones completas de Substitute, Dynamax ni supresión de habilidades.

Cinco mecánicas base en piloto, 14 IDs sin mecánica propia; la cola global de
19 IDs/38 clips permanece abierta por despliegue/interacciones. Los inventarios
artísticos siguen iguales. Detalle de validaciones y nueve fallos de auditoría
de datos preexistentes (comparados antes/después) en PROJECT_STATE/NEXT_STEPS.

## Tramo anterior conservado: primera conexión parcial al combate real — 2026-10-25

Los 19 se prueban con el servidor autoritativo, ambos lados y reservas: cinco
aplican solo daño y catorce consumen PP sin efecto especial en estos casos.
No se cierra ningún efecto especial. La presentación no puede completar
estados/eventos que el motor no produce. Detalle reproducible en
`../current/BATTLE_EXTERNAL_INTEGRATION.json` (PARTIAL, validación PASS).

Se conectan las partículas revisadas de circle_throw, dragon_tail, flip_turn,
u_turn y volt_switch al daño confirmado; diez clips, ambos lados. Se omiten los
cuerpos y fondos nativos, para que solo el combate real cambie Pokémon/estado.
No se activan por PP consumidos, fallo, inmunidad, daño cero o daño reactivo.
Pack `.godot/battle_external_damage/manifest.json`, SHA
`175ceb67c22c67ec90aca69eb79697b5a4c95f2568226d04c8e82c03079e6105`,
179.921 bytes PNG copiados, sin regenerar el catálogo. Registro de tiempos y
adaptación en VISUAL_SUBSTITUTIONS. F6: ensayo parcial desechable SOLO DAÑO.

Prueba GPU 475 PASS: 38 casos del motor, 11 impactos reproducidos (diez vistas
salvajes y un KO de entrenador), 12 capturas. Lámina de diez vistas y mapa
observados. Regresiones PASS: 407 enlaces anteriores; 19.726 reproducción;
4.949 recetas; 45 campo. Estos controles certifican el alcance probado, no
relevos, climas, sustituto, transformación ni dobles completos.

La cola permanece en 19 IDs/38 clips externos abiertos, 74 IDs/118 cerrados.
Inventario de alternativas 41 IDs/49 familias/98 clips; archivo 900 IDs/1.822
clips. Diez IDs/20 clips con enlaces de combate, cinco de ellos solo daño.
No cambian las fuentes, PNG originales, renderer, datos, clasificaciones o IA.

## Tramo anterior conservado: los 24 contrastados; cinco cerrados y 19 dependencias externas — 2026-10-25

Se revisan los 24 IDs/48 vistas restantes en bloque. Dos correcciones de
presentación y tres verificaciones cierran los cinco contrastes:

- `clanging_scales`: el cuerpo del receptor estaba anclado al usuario; corregido
  back/front sin mover partículas ni el gesto del usuario. Back no era un clip
  pendiente y no se descuenta otra vez.
- `court_change`: conserva la metáfora inicial de cruce hasta f13 y vuelve a las
  plazas propias con interpolación suave en f14..21; no ejecuta intercambio real
  de condiciones del campo.
- `aeroblast`: la diferencia de fondos back/front está en los exports nativos,
  cotejados con sus capas originales. Se conserva.
- `destiny_bond`: la elipse gris procede del patrón0 de PRAS- Shadow Sneak; no es
  una textura rota ni un recorte introducido por el visor. Se conserva el estilo
  de esta fuente, sin prometer una animación más elaborada.
- `doom_desire`: los trazos vienen del atlas GEN8- Doom Desire y se conservan.
  Se localizan DOOMDUMMY back/front, con otra hoja PRAS y 42 frames. Su asignación
  final por fase y enlace al combate todavía se deben verificar; el nombre del
  recurso no basta para certificar que sea la fase correcta.

Detalle de los cambios y procedencias en VISUAL_SUBSTITUTIONS. Inventario de
alternativas sin aumento: 41 IDs/49 familias/98 clips. Se cierran nueve clips
de cola: **74 IDs/118 clips cerrados**, quedan **19 IDs/38 clips externos**.

### Los 19 contextos: fuente revisada, integración abierta

Las 38 fuentes nativas se revisaron en cuatro láminas de 10/9 IDs por lado y
se cotejaron frame a frame. No equivalen al resultado completo de cada movimiento:
un cuerpo puede salir correctamente del clip y faltar la entrada de su relevo.
El laboratorio muestra el requisito concreto en «CONTEXTO DE COMBATE PENDIENTE».

| Grupo para integrar | IDs | Resultado externo pendiente |
| --- | --- | --- |
| Relevo del usuario | baton_pass, flip_turn, parting_shot, teleport, u_turn, volt_switch | Entrada del siguiente Pokémon; efectos transferidos cuando corresponda; Teleport distingue salida/relevo según combate |
| Relevo combinado | chilly_reception, shed_tail | Relevo con nieve o sustituto, respectivamente |
| Expulsión del objetivo | circle_throw, dragon_tail, roar, whirlwind | Resolver relevo o salida del encuentro y presentar el resultado real |
| Clima persistente | hail, rain_dance, sandstorm, snowscape | Estado meteorológico y duración reales, no solo invocación |
| Aliado en dobles | ally_switch | Necesita un segundo aliado y sus plazas; no fingirlo en la escena individual |
| Sustituto persistente | substitute | Muñeco ligado al estado autoritativo, no solo el efecto de aparición |
| Transformación | transform | Apariencia y datos copiados según la mecánica real |

Se preservan seis muestras LAB opcionales (lluvia, granizo, nieve, Fría Acogida,
Sustituto y Transformación). Son composiciones visuales, no seis integraciones
completas. Los otros trece no tienen ese contexto de muestra. La lista por vista,
duración de la fuente y requisito está en `CONTENT_POOL_AUDIT.json`, campos
`native_context_reviewed_clip_ids` y `external_presentation_handoffs`.

Common:Sandstorm ya existe como secuencia de 20 frames; el adaptador actual
solo admite tres climas comunes de 30. No convertirlo a 30 por repetición o
recorte sin una política explícita de tiempo. Los DOOMDUMMY se registran como
candidatos separados sin importarlos al catálogo ni cambiar el dataset.

Como referencia de arquitectura, [Essentials separa carga e impacto diferido](https://github.com/Maruno17/pokemon-essentials/blob/8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b/Data/Scripts/011_Battle/003_Move/005_MoveEffects_Misc.rb)
en su lógica de Future Sight/Doom Desire (`futureSight`/`hitNum`), blob
`fd09682914419ce42bd3008e0406d4a1965f81a9`. Esa referencia no certifica por sí
sola cómo se corresponden los nombres de este pack comunitario con cada fase.
No se ha ejecutado Ruby descargado; los datos de animación se leen como datos inertes.

### Evidencia del barrido

`.godot/move_general_checks/418254331eca04dc/gpu/`: result/boards/review y nueve
láminas observadas. Review SHA
`208ad6d39b44df9741027494f35c502158b96252f0a2aa5bef0575927f1addc5`.
593.828 checks GPU PASS; 2.532 estados de captura, 960 pares/1.920 PNG y 12.660
estados de contrato en cinco parejas/dos arenas. 540 anclas del receptor y 40
retornos finales correctos; cuatro exports manipulados rechazados. Repetición
headless final: 591.908 PASS, incluida la aclaración sobre las fases de DOOMDESIRE.
El cotejo upstream de 48 vistas conserva la reparación histórica de 11 focos de Fría
Acogida front. Las capturas por fases no certifican visionado en tiempo real.

Baseline, atlas y pruebas de origen en `.godot/move_general_checks/reference/`.
Reproducir: `move_general_review_runner.gd -- --all`, luego
`build_move_general_sheets.py --report .../result.json`; el cierre se registra
con `close_move_general_review.py --report .../result.json --sheets-observed`.
Este último mantiene los 19 externos pendientes aunque sus fuentes estén vistas.

Renderer `7674d3a61e113e085d12132a4e10461aedd3a760516ab68700f2868f0f3fd4de`;
contexto `e1221ddaae3b2375`, mismos arte/frames/bindings. Regresiones PASS:
catálogo completo 5.366.237/118.766 estados/1.822 clips; Z 317.062; contexto
6.442; cinco rutas 407; perfil/laboratorio 1.898. No se cambian datos canónicos,
soporte mecánico, pool, daño, IA o créditos; sin commit/push/merge.

## Tramo anterior conservado: siete Z revisados — 2026-10-25

Los siete casos Z pendientes se han retomado y cerrado: 14 clips; cinco IDs con
equivalentes parciales del mismo atlas, dos vistas del salto de Marshadow
encuadradas y Guardián de Alola verificado sin alterar alpha ni fases.
Véase el detalle por ID y patrón en [VISUAL_SUBSTITUTIONS.md](VISUAL_SUBSTITUTIONS.md).
Esta revisión no resuelve la inclusión Z del perfil de juego, que sigue `pending`.
Para verlos en laboratorio, desactivar «Solo pool de juego» y buscar su ID.

Review `.godot/move_z_checks/c2a52b27e855bafa/gpu/review.json`, siete láminas
observadas y 280 pares iguales al candidato; 317.622 checks GPU PASS y contrato
de 16.320 estados con cinco parejas/dos arenas. Guardián conserva el receptor a
225/255 en el frame final original; su fuente no se redibuja ni se hace opaca.
No confundir fase estática contrastada con visionado de toda la animación a
velocidad normal. Nuevo total: **69 IDs/109 clips cerrados**, pendientes
**24 IDs/47 clips: cinco contraste +19 contexto**. Inventario artístico:
**41 IDs/49 familias/98 clips**. Los datasets, shards, índice y créditos no cambian.

El contexto opcional se refresca a `3bcab4075e9a7662` para el renderer
`16892e3fcdd25ab448a42e45d1a96f48dba4863ed28adddf1863bf23de770c26`,
sin cambiar arte/frames/bindings. Catálogo, motivos anteriores, contexto,
cinco rutas y perfil/laboratorio pasan sus regresiones.

Reproducción local: `tests/visual/move_z_review_runner.gd` con Godot GPU;
`tools/visual/build_move_z_sheets.py --report .../result.json` reconstruye las
comparativas. `tools/visual/close_move_z_review.py --phase-sheets-observed`
registra el cierre solo después de observarlas. Baseline congelado y fuentes
en `.godot/move_z_checks/reference/`; un candidato inicial de capullos duplicados
se rechazó y se conserva como diagnóstico, no como selección final.

## Tramo anterior conservado: filtrar trabajo según el contenido confirmado — 2026-10-25

Consultar [RANDOMLOCK_RULES.md](RANDOMLOCK_RULES.md) antes de seguir buscando
recursos. Splash, Power Shift y 13 exclusivos Let's Go están descartados; los
13 Let's Go estaban entre los huecos de fuentes y dejan de buscarse. Los Z están
pendientes de decisión, con siete casos artísticos en espera; Max se mantiene.

El launcher de ataques abre el catálogo por lotes con «Solo pool de juego»:
846 IDs/1.714 clips elegibles. El archivo completo sigue accesible desactivando
esa casilla: 900 IDs/1.822 clips. No se borra ni cambia ninguna imagen/animación,
ni se modifica el registro de sustituciones. Una exclusión no es una revisión PASS.
La cola activa es cinco contrastes más 19 contextos; siete Z quedan en espera.
El cruce reproducible está en `docs/current/CONTENT_POOL_AUDIT.json`.

## Tramo anterior conservado: elecciones artísticas parciales de motivos — 2026-10-25

Embate Supremo y Pikavoltio Letal se señalaron por rostros específicos, no por
fallos de reproducción. Se inspeccionaron celdas originales de ambos atlas y
candidatos GPU. No se descargan/redibujan imágenes ni se regeneran shaders,
datasets, shards o índice. Solo dos políticas de presentación, fijadas por SHA
completo de frames/capas/atlas, nombre Move y lado sintetizado esperado:

- `behemoth_bash/back` y `/front`: fuente `Move:BEHEMOTHBASH`, 51 frames,
  atlas `0358ed475071f6b278eecf7ea8f76ee1389172deacfca061f46a9449ec116f85`.
  El patrón8 contiene el rostro/escudo de Zamazenta. Se dibuja con el **patrón9
  del mismo atlas**, destello metálico neutro. Mantiene su trayectoria, escalas,
  tiempos, tintes/opacidades y cuerpos. La huella pintada es menor; es un impacto
  genérico de acero, no un escudo nuevo ni reproducción nativa exacta. Filtrado
  aislado de la región para evitar contaminación de la celda vecina con el rostro.
- `catastropika/back` y `/front`: fuente `Move:CATASTROPIKA`, 50 frames,
  atlas `06d5c56c0bf6101af4678080a411d28baf15b85ff727c8a06717995abc048339`.
  **Omitir únicamente las celdas visibles con patrón10/11/12**, que componen la
  insignia de Pikachu. Se conservan los demás rayos/partículas, BG/FG, tintes y
  movimiento corporal. Hay preparación sin insignia; no se acorta la duración.
  Quedan 30 frames de partículas y 44 con capas por vista. Es una fase eléctrica
  genérica para el Z secundario, conforme a la preferencia del usuario; no elimina
  el movimiento de los datos ni decide su inclusión en el pool final.

Los originales permanecen completos en los atlas y frames; `visual_art_choice`
declara `pinned_partial_motif_choice_v1`, `partial_motif_only`, fuente y estado
renderable_but_art_rejected. El laboratorio muestra EQUIVALENTE ARTÍSTICO EXPLÍCITO
y PARCIAL en ambas vistas. No hay OppMove nativo de estas parejas; se mantiene
el rival sintetizado declarado. PARTIAL_RUNTIME de Embate y RUNTIME_SUPPORTED
de Pikavoltio no cambian. Ninguna mecánica ni ruta de combate añadida.

La selección se aplica al cargar/renderizar, conservando el índice
`bb327ada0e33347980260a7e4a8af65e8622171002c64d3ecf56759aa92dbee1` y todos los
shards. El inventario de alternativas pasa de **34 IDs/42 familias/84 clips a
36 IDs/44 familias/88 clips**: dos IDs nuevos con elección parcial, sin inventar
fuentes nuevas o sumar familias al catálogo global. El registro y sus tablas se
actualizan en VISUAL_SUBSTITUTIONS. Autores/PRAS/Essentials ya acreditados;
sin recursos o créditos nuevos. La lista de alternativas no es soporte de combate.

Prueba preliminar `.godot/move_art_motif_checks/8a1434b41c22a68d/`, **963 PASS/808
estados**, fuentes y candidatos en ambas vistas/dos arenas. Observados atlas,
antes/después nativos f7 de Embate y f4 de Pikavoltio, además de fase eléctrica
f20. Original renderer `d934d0ccf43b955c1a055e2415bbd54e01ec4b8d56ed4eb9b8c08e792d6ef3a9`
en `reference/preview_before.gd`; actual
`a9e655948ae20b50b2f2d8ee34b906f3729db6e29d0bb7b9a45b1a704aca9ce2`.
`reference/source_proof.json` conserva políticas, fuentes y recuento del inventario.

Gate final `.godot/move_art_motif_checks/21fa00b2ed6f3953/gpu/`:
**92.447 PASS/2.136 estados**, tres parejas/dos arenas, ocho vistas incluyendo
controles Tajo Supremo (atlas compartido) y Rayo. 504 celdas de motivo reemplazadas
y 468 omitidas a lo largo de esa matriz, no 972 archivos ni movimientos nuevos.
Todos los demás sprites/capas conservan geometría, tintes, opacidades y duración;
fuentes originales idénticas. Rechazo de cuatro exports alterados; prueba real
de etiquetas parciales en UI, final limpio y efectos no vacíos/monofotograma.
Embate conserva 42 frames de partículas por vista.

88 pares/176 PNG completos, dos láminas antes/después observadas; 64 capturas
finales coinciden con el candidato previamente observado. Controles con hashes
GPU idénticos. No certificar una película completa observada a tiempo real.
Regresiones PASS: catálogo **5.368.157/118.766 estados/1.822 clips**. El contador
baja respecto al tramo anterior porque se omiten celdas visibles declaradas;
clips/frames y controles se mantienen. Cache de límites alfa corregida para
usar la región realmente dibujada, no un número de patrón fuente sustituido.

Piloto 444.079, cuerpos 387.764, anclas 303.509, proyección 207.382, haz 157.818,
agua 183.731, locales 55.543, recorridos 53.319, cámaras 4.620, cinco rutas 407,
contexto 6.442/1.164, todo PASS. Contexto derivado `d45df89b77577919`, mismos
recursos/frames/bindings. Baseline original y siete grupos previos conservados.

**Dos IDs/cuatro clips cerrados por elección artística**, no reparación de
fuente. Acumulado **62 IDs/95 clips cerrados**, pendientes **31 IDs: 12 contraste
+19 contexto**, 61 clips. Review final SHA
`9967c418ad6de0b6a3d4905f998beb09139e96fefd7288692614737f570efe96`, encadenado
al grupo de recorridos. Datos, IA, clasificación, cinco rutas, workflows y HEAD
intactos. Siguiente lote: cinco Z con especies incrustadas; guardar separados
los problemas de transparencia/encuadre. Sin commit/push/merge.

## Tramo anterior conservado: recorridos largos y reentradas — 2026-10-25

Tres IDs/seis vistas contrastadas: Treparrocas, Llave Corsé y Derribo. La fuente
ya contiene salidas fuera de 512×384. Treparrocas salta de un extremo al otro
entre f23/f24; Derribo entre f9/f10. Los puntos opacos cambian, por ejemplo,
de (584,-48) a (-96,376) en Derribo back, y de (-72,277) a (590,80) en front.
Eso se interpreta como salida/reentrada; no imponer aquí la política de mantener
el cuerpo dentro de Danza Amiga, pues expondría el salto entre bordes.

El sondeo `.godot/move_motion_path_checks/adc95fa7a8cd1694/`, **1.209 PASS/800
estados**, compara puestos canónicos, layout anterior y propuesta de trayectoria
en 640×360/400×300. Referencia geométrica con nuestros sprites, no grabación del
juego original. Tres láminas observadas. En la pareja Ogerpon/Charizard la cámara
canónica ya oculta al usuario en las fases de cambio; la adaptación local dejaba
una porción visible: caja de Treparrocas f20 ~81 % back/~61 % front a 640×360;
Derribo f9 ~55 %/~87 %. Son porcentajes de caja delimitadora, NO cobertura de
píxeles de silueta ni daño. No transformar esas cifras en aprobación artística.

**Treparrocas y Derribo, ambos lados:** proyección por línea entre actores
solo para la celda corporal del usuario (-1 normal, -2 en OppMove nativo).
`rear + (point-(128,224))/(256,-128)*(front-rear)` conserva inicio/final y adapta
el recorrido de pantalla completo. No escala cuerpo/partículas ni cambia sus
giros, tintes, prioridades o número de frames. Las cuatro fuentes se fijan por
nombre, lado/export, atlas y SHA completo de frames. En Derribo front se corrige
además la estrella nativa escrita alrededor de SOURCE_BACK a foco local del
receptor; no se altera su dibujo o duración.

La primera propuesta corregía la pareja básica, pero cinco parejas/dos arenas
detectaron **16 intersecciones residuales de caja** con cuerpos grandes. La caja
girada es conservadora y no equivale a píxeles visibles; tampoco basta para
garantizar que la discontinuidad queda oculta. Se añade una adaptación explícita
de opacidad únicamente en ese tramo de fuente fijado:

- Treparrocas: peso 0 en f20..24, 0,5 en f19/f25, 1 en el resto.
- Derribo: peso 0 en f9..13, 0,5 en f8/f14, 1 en el resto.

El fundido multiplica la opacidad renderizada del usuario; no modifica las
opacidades exportadas ni oculta el impacto/reacción del otro actor. Preserva las
fases originales de salida/retorno y evita que un resto de Wailord u otro cuerpo
ancho salte visiblemente entre bordes. No presentar la adaptación como copia
exacta del reproductor original. No se aplica al resto del catálogo.

**Llave Corsé, ambos lados:** fuente con foco3, lanzamiento continuo del objetivo
hasta x560/y0 y retorno a su plaza f23; ambos cuerpos recuperan el estado inicial
f25. El recorte durante la salida ya está en la referencia; no hay salto entre
bordes, pérdida permanente de sprite ni relevo. Se cierra la duda comprobada
sin modificar fuente, trayectoria, opacidad ni efecto.

Renderer anterior `b7da766584d96b4a5d809738b7c68cdb9031f35a05faa828a37869a80e064505`,
preservado en `.godot/move_motion_path_checks/reference/preview_before.gd`;
actual `d934d0ccf43b955c1a055e2415bbd54e01ec4b8d56ed4eb9b8c08e792d6ef3a9`.
`reference/source_proof.json` registra saltos originales opacos, políticas y
hallazgo de cuerpos grandes. Candidatos sin fundido y gates intermedios no son
la revisión final. Índice, PNG y exportaciones originales permanecen intactos.

Gate final `.godot/move_motion_path_checks/4a0319aad2f9b423/gpu/`:
**53.759 PASS/1.600 estados**, seis vistas, cinco parejas/dos arenas; ecuación
independiente de posición, forma/rotación/tinte/recursos conservados, rechazo de
cuatro exports alterados, final limpio. Opacidad solo cambia en las fases citadas.
**80 PNG GPU de cuerpo aislado** en ambos extremos de cada discontinuidad tienen
alfa completamente cero, comprobado en todos sus píxeles, incluido Wailord en
ambos roles. No es solo un flag de visibilidad o la caja fuera de pantalla.

88 pares/176 PNG completos y tres láminas antes/después observadas; también se
amplió Derribo front f4 para comprobar el impacto sobre el receptor. Las 84
muestras comunes con el candidato inicial coinciden en la pareja básica; el
fundido añade seguridad para modelos grandes. Llave Corsé conserva hashes GPU
idénticos. Se observaron seis láminas entre diagnóstico/final, no película completa.

Regresiones PASS: catálogo **5.368.625/118.766 estados/1.822 clips**, piloto
444.079, cuerpos propios 387.764, anclas 303.509, proyección 207.382, extremo de
haz 157.818, agua 183.731, locales 55.543, cámaras 4.620, cinco rutas 407, contexto
6.442/1.164. Contexto derivado `eac61685a8e18a2f`, mismos arte/frames/bindings.

**Tres IDs/seis clips cerrados**, cuatro corregidos y dos comprobados. Acumulado
**60 IDs/91 clips cerrados**, pendientes **33 IDs: 14 contraste +19 contexto**,
65 clips. Review final SHA
`f1aaf72792fb5aee488fb252941713cd668af6e142a71a800102099922d6df47`, encadenado
al grupo local. Baseline original y seis grupos anteriores preservados. Cuatro
vistas registradas también en VISUAL_SUBSTITUTIONS; 34 equivalencias completas
sin cambios. Datos, IA, mecánicas, workflows, cinco rutas y HEAD intactos.
Siguiente: behemoth_bash/catastropika y cinematográficas restantes. Sin commit/push.

## Tramo anterior conservado: efectos locales y atlas — 2026-10-25

Cuatro IDs auditados, siete clips pendientes. Las cuatro parejas usan fuente
Move y rival sintetizado declarado; no convertirlos en exports OppMove nativos.
Tres causas diferentes se corrigen de forma acotada, no con una regla global.

- **Acupresión, back/front:** fuente user-or-ally con marca foco2 sobre usuario,
  pero el destello tonal estaba en el cuerpo de objetivo. Para la referencia
  sobre uno mismo del laboratorio se intercambian únicamente los tintes de las
  dos celdas corporales principales. La marca no se mueve, el cuerpo ajeno queda
  neutro y destella el señalado. No cambiar target_scope, lados, trayectoria,
  opacidad, sprites, datos ni mecánicas. La rama sobre aliado y subida de stats
  siguen fuera de esta aprobación visual; DATA_ONLY conservado.
- **Danza Amiga, solo front:** el rival sintetizado lleva al receptor trasero
  80 px de fuente hacia abajo. El cuerpo de Ogerpon excedía el borde inferior
  31,80 px en 640×360 y 26,50 px en 400×300, cinco frames por arena. Se comprime
  solo la excursión positiva Y por un factor constante calculado del espacio
  disponible: `(arena.y - 8 - actor.center.y - half_height)/(80*screen_gain)`,
  acotado a [0,1]. half_height viene de la envolvente de presentación ya medida.
  X, ascensos, poses, tamaño y tiempos permanecen; f0/final conservan plaza.
  El test usa además rectángulos alfa independientes del sprite para comprobar
  que realmente cabe. No es una política universal para saltos/lanzamientos.
- **Camelo, back/front:** los patrones 4/5/6/8/9 tienen bordes transparentes y
  confeti diminuto central, sin líneas largas en las celdas de origen. Con
  filtrado lineal del atlas se muestreaban texels vecinos y aparecían marcos.
  `region_filter_clip_enabled=true` solo en sus partículas elimina ese sangrado.
  Se restablece por uso para cuerpos/otros clips. No borrar confeti, cambiar
  filtro global, atlas, posiciones, colores ni geometría. [Propiedad de Sprite2D,
  documentación primaria de Godot](https://docs.godotengine.org/en/stable/classes/class_sprite2d.html#class-sprite2d-property-region-filter-clip-enabled).
- **Niebla Aromática, back/front:** frames, capas y referencias de textura iguales;
  niebla/rosa visibles en ambas vistas en f20 y f40. Capturas GPU de capas aisladas
  idénticas por vista en ambas arenas. La ausencia anotada en el barrido no se
  reproduce; se cierra esa duda sin modificar arte ni aprobar destinatario aliado.

Las políticas se activan solo con nombre Move esperado, lado sintetizado esperado
y SHA completos de frames/capas/hoja. Se conserva el índice y todos sus shards;
la normalización privada ocurre en el renderer. Fuente anterior `c712c423db4a45d7287a2c658505e311b03267391b85c8f3b1674b436f0fe4ad`
preservada en `.godot/move_local_effect_checks/reference/preview_before.gd`;
actual `b7da766584d96b4a5d809738b7c68cdb9031f35a05faa828a37869a80e064505`.
Prueba de celdas aisladas y referencias en `reference/source_proof.json` y
`flatter_source_tiles.png`. Ninguna imagen descargada o retocada.

Sondeo inicial `e761bf78c0468ccf`, final `a62342ccd21cad1f`, en
`.godot/move_local_effect_checks/`: **782 PASS/600 estados** cada uno, cuatro IDs,
ambos lados/dos arenas; límites alfa de cuerpos de todos los frames, capturas
de fases y candidatos de filtrado. 98 PNG de muestra iguales, 42 diferentes.
La opción de recorte de región se probó antes de modificar el renderer.

Gate final `.godot/move_local_effect_checks/58e91f150a8fc69c/gpu/`: **55.939 PASS/
1.800 estados**, tres parejas/dos arenas, rechazo de cinco exports modificados.
Recortes de receptor medidos por alfa: **30 antes / 0 después**. 84 pares/168 PNG
completos; 96 pares/192 PNG de partículas, todos los 24 frames de Camelo por
vista y arena. Oráculo independiente: recortar físicamente cada celda del atlas
en memoria, sin usar la nueva opción de filtrado. El comparador verifica todos
los píxeles RGBA; error máximo **1/255** de canal, tolerancia 2/255. No basta un
hash distinto para aprobar una corrección: se conserva el confeti de la fuente.

`boards.json` vincula fuente del builder, informe, PNG y resultado del oráculo;
`local_effects_before_after.png` observado completo. Ampliados nativos f8 de
Acupresión back, f29 de Danza Amiga front y f12 de Camelo back antes/después;
también observada niebla frontal f20 y candidato de aislamiento. Es revisión de
muestras y estados, no película completa observada ni mecánicas aprobadas.

Regresiones PASS: catálogo **5.368.625/118.766 estados/1.822 clips**, piloto
444.079, cuerpos 387.764, anclas 303.509, proyección 207.382, extremo de haz
157.818, agua 183.731/2.868 estados, cámaras 4.620, cinco rutas 407, contexto
6.442/1.164 estados. Contexto derivado `93cac9b62b9b823b`, mismos recursos,
frames y bindings. Los cinco grupos previos y el baseline original conservados.

**Cuatro IDs/siete clips cerrados**: cinco clips corregidos (Acupresión x2,
Danza Amiga front, Camelo x2), Niebla Aromática x2 comprobada sin cambios.
Acumulado **57 IDs/85 clips cerrados**; pendientes **36 IDs: 17 contraste y
19 contexto**, 71 clips. Review encadenado al de agua, SHA
`1c8f2e209169d09f6425bb3febefcf31806a70a81f81498048a778adcd02d9d1`.
Registro técnico también en VISUAL_SUBSTITUTIONS; 34 equivalencias completas
intactas. Datos, IA, mecánicas, workflows, cinco rutas y HEAD conservados.
Siguiente: desplazamientos de rock_climb, storm_throw y take_down. Sin commit/push.

## Tramo anterior conservado: entrada de agua y olas — 2026-10-25

Cinco IDs investigados juntos sin fusionar entradas: Hidrovórtice físico y
especial, Maxichorro, Surf y Onda Tóxica. Los tres primeros comparten exactamente
frames/capas y fuente HYDROVORTEX por vista. Maxichorro sigue siendo una
equivalencia declarada, no una animación Max nativa. Clasificaciones intactas.

La textura rival `PRAS- Surf FG Opp.png`, SHA
`09da26c53034515f626d168e7c304c0cdd7656e1f37b840b0994462b0a0da6c4`, tiene
610×1151 píxeles: cresta/componente superior opaco en filas [0,140), espacio
transparente [140,524), segunda masa de agua [524,1151). La repetición y offsets
precocinados hacen aparecer esta última como rectángulo gris f3 y franja inferior
f7 antes de la cresta principal de HYDROVORTEX. Las cámaras canónica y adaptada
presentan el mismo fenómeno: no era una imagen de Pokémon ni un foco de actor.

**Corrección acotada de presentación:** solo `hydro_vortex_physical/front`,
`hydro_vortex_special/front` y `max_geyser/front`, capa FG citada y f0..11,
descartar fragmentos con `fract(UV.y) >= 524/1151`. Desde f12 conservar la textura
completa, incluida su repetición, para llenar el agua por encima de la cresta.
Shader derivado del tint existente; no cambiar el shader común, el PNG ni las
capas precocinadas. Valida nombre OppMove:HYDROVORTEX, export nativo, PNG exacto,
SHA de frames `0ec2a1e281c22e0cca403466a6041b4dc3e3a66bf85c7e759e44e23307396a56`
y capas `2eb7a2a414b5f659d5ca158240a2a05a462417f05fe65c99c286e015ee8770bf`.

Un candidato que ocultaba la franja durante toda la animación se descartó:
la ampliación f14 reveló que el relleno tardío sí es necesario. Sus evidencias
intermedias quedan conservadas pero no aprobadas. También se corrigió el gate
de rechazo: el manifiesto alterado necesita sus PNG hermanos para comprobar
el SHA del export, en lugar de fallar primero por recursos ausentes. El gate
final pasa las seis alteraciones de frames/capas.

**Surf y Onda Tóxica front:** la cresta orientada hacia abajo ya está dibujada en
las fuentes rivales y los offsets la hacen avanzar desde arriba hacia el jugador.
Se cierran las dudas concretas de orientación sin modificar recursos ni girar
la imagen. Su segunda masa de agua se conserva también en la fase final; no
extenderles la máscara de HYDROVORTEX. Sus capturas y las cinco vistas back
permanecen idénticas antes/después.

Fuente primaria consultada: [BattleAnimationPlayer de Essentials, Maruno17](https://github.com/Maruno17/pokemon-essentials/blob/master/Data/Scripts/011_Battle/007_Other%20battle%20code/007_BattleAnimationPlayer.rb),
blob `7f98e089e90bc3f95801d201833382ef3e9ad18f`. BG/FG se reproducen con
AnimatedPlane repetida. Copia de código, timings inertes, prueba de componentes
y renderer anterior en `.godot/move_water_checks/reference/`. No ejecutar Ruby.
La cámara de referencia usa nuestros cuerpos y el bake existente; no es una
captura de Essentials ni valida equivalencia exacta de todos sus timings.
En particular, el código primario interpola ox/oy y el bake interpola bgX/bgY:
una auditoría global de signos/estado requeriría un tramo propio y no se hace
pasar por resuelta mediante estas capturas. Esta es una limpieza de presentación
local, con fuentes y tiempos precocinados conservados.

Evidencia final `.godot/move_water_checks/085180c565bcc21c/gpu/`:
`result.json`, `boards.json`, `review.json`, `water_before_after.png`, 90 tiempos
por dos renderers = 180 PNG. Lámina antes/después observada. Gate **8.907.974 PASS**,
2.868 estados de diez vistas/tres parejas/dos arenas. Compara cuerpos, partículas,
transformaciones, tintes, capas/frames y recursos. Muestreo GPU de la capa aislada
en los 51 frames de cada frontal corregido a 640×360, todos los Y y X cada cuatro
píxeles: 745.440 muestras opacas retiradas de la franja prematura y 1.152.741
conservadas. No son cifras de daño ni un porcentaje de aprobación artística.

Sondeos antes `0e74983d44234990` y final `fa75bd02eb57c456`: **4.192 PASS/1.434
estados** cada uno, ambos lados y tres cámaras, 30 clips de cámara. Cuatro láminas
observadas, más la comparación final. Métricas de partículas idénticas; 290 PNG
idénticos y 18 diferentes exclusivamente durante la entrada de los tres IDs.
Todas las capturas f12+ conservan su hash; no fingir película completa observada.

Renderer anterior `d1861790b5291352cf21c4517158682a7254ea23e10736920917af021ea99e18`,
actual `c712c423db4a45d7287a2c658505e311b03267391b85c8f3b1674b436f0fe4ad`.
Regresiones PASS: catálogo 5.368.625/118.766 estados/1.822 clips; piloto 444.079;
cuerpos propios 387.764; anclas 303.509; proyección 207.382; extremo de haz
157.818; cámaras anteriores 4.620; cinco rutas 407; contexto 6.442/1.164 estados.
Contexto derivado `7a6f7eeb596fe91a`, mismo arte/frames/bindings.

**Cinco IDs/cinco clips cerrados**: tres corregidos y Surf/Onda Tóxica comprobados.
Acumulado **53 IDs/78 clips**, pendientes **40 IDs (21 contraste + 19 contexto),
78 clips**. Registro enlazado al review previo; baseline original de 523 entradas
y cuatro grupos anteriores conservados. Limpieza parcial anotada también en
VISUAL_SUBSTITUTIONS; 34 equivalencias completas sin cambios. Datos, IA,
mecánicas, cinco rutas y workflows intactos; sin commit/push/merge.

## Tramo anterior conservado: Láser Doble e impactos tardíos — 2026-10-25

Sondeo GPU de todos los frames de **twin_beam, dragon_pulse y glacial_lance**,
ambos lados en referencia de puestos canónicos y arenas 640×360/400×300. La
referencia usa nuestro catálogo en posiciones canónicas, no una captura del juego
original. Máscara alfa del cuerpo y disco de ancla se miden por separado: disco
vacío no implica ausencia de contacto con silueta. Diagnóstico inicial
`.godot/move_pending_beam_checks/c60749ecda70ec7e/`, **8.534 PASS/630 estados**;
fuente del probe preservada en `move_beam_endpoint_checks/reference/probe_before.gd`.

Hallazgos y cierre:

- **Pulso Dragón, ambos lados:** esfera inicial propia, pero aros alcanzan al
  objetivo después. En 640×360, pico f35 con 625/331 píxeles de máscara solapados
  (back/front), 15,13 %/6,77 %. PNG nativo front f35 confirma aro sobre contorno
  de cabeza. Coincide con fase tardía de fuente y cámara canónica. Se cierra
  duda de ausencia/anclaje, sin cambiar arte ni aprobar toda la coreografía.
- **Lanza Glacial, front:** fragmentos y reacción en f18; 488 píxeles/10,00 % de
  silueta frente al 9,38 % de la referencia canónica. La lanza separada en f16
  no demuestra impacto totalmente ausente. Export, orientación y tiempos intactos.
- **Láser Doble, front:** los dos núcleos finales del export terminan x178/176,
  mientras el origen corporal trasero es x128. La proyección horizontal anterior
  deja solo seis píxeles/0,12 % de solapamiento en f19 a 640×360; la referencia
  canónica ya tiene contacto débil (3,93 %). Se aplica **recalibración explícita
  del extremo horizontal**, fijada por SHA del array completo, nombre y export:
  `x = rear.x + (source_x-176)/(384-176)*(forward.x-rear.x)`. Así el núcleo x176
  llega al objetivo y el x178 conserva su separación. No redibujar ni estirar
  partículas, no cambiar Y, tintes, cuerpos o fuente. El contrato no pretende
  reproducir sin cambios el encuadre nativo: es una mejora acotada del adaptador.

Tras calibrar: **24,96 %/1.221 píxeles** de silueta en 640×360 f19 y **32,96 %**
en 400×300, frente a 0,12 %/2,69 % anteriores. Cifras diagnósticas de los actores
del probe, no daño ni aprobación de las 1.025 especies. Back de Láser Doble,
referencias canónicas sin calibrar y todos los estados de Pulso Dragón/Lanza
Glacial conservan métricas y PNG idénticos. El probe canónico desactiva solo
el ajuste de extremo para mantener la referencia de fuente sin modificar.

Antes renderer `81cb49e7e0b2594181ebec834f5fa3c58bbffa036e7fb02a0e13a3d31d10a074`,
preservado en `.godot/move_beam_endpoint_checks/reference/preview_before.gd`;
actual `d1861790b5291352cf21c4517158682a7254ea23e10736920917af021ea99e18`.
Evidencia de reparación `.godot/move_beam_endpoint_checks/9a306b629ccf3cfa/gpu/`:
`{result,review}.json`, dos láminas observadas, 10 IDs/20 vistas y 60 tiempos por
dos renderers = 120 PNG. Diagnóstico posterior
`.godot/move_pending_beam_checks/748c927261000e64/`, **8.536 PASS/630 estados** y
dos láminas; también observadas las dos iniciales, seis en total. Ampliados los
PNG nativos f35 de Pulso Dragón, f18 de Lanza Glacial y f19 de Láser Doble front.

**Tres IDs/cuatro clips de cola cerrados**: reparación `twin_beam/front`;
comprobados sin cambio `dragon_pulse/back`, `dragon_pulse/front`,
`glacial_lance/front`. Acumulado **48 IDs/73 clips cerrados**; quedan **45 IDs:
26 de contraste y 19 de contexto**, 83 clips. El registro nuevo conserva los
69 cierres anteriores y diferencia corrección de recurso ya válido. No migrar
automáticamente el baseline de los 900 al nuevo renderer.

Gate del extremo: **157.995 checks GPU PASS/3.240 estados/2.520 celdas comprobadas**,
tres parejas/dos arenas, todos los frames, eje Y y apariencia conservados,
controles idénticos y rechazo de export alterado. Regresiones: catálogo completo
headless **5.368.625 PASS/118.766 estados/1.822 clips**, piloto **444.079**,
anclas **303.509/6.816 estados**, proyección **207.382/4.752**, cuerpos propios
**387.764**, cámaras anteriores **4.620**, cinco rutas **407**, contexto
**6.442/1.164**, todo PASS. Láser Doble, ahora reparado, pasa de control antiguo
a gate propio; Pulso Dragón intacto lo sustituye en los tests de ancla y proyección.
Copias anteriores de ambos tests y del probe preservadas junto al baseline nuevo.

Contexto derivado `92770bfa947e9143`, mismo arte/frames/bindings y versiones previas
intactas. Índice, hojas, datos, IA, mecánicas, cinco rutas, workflows y HEAD sin
cambios. Siguiente grupo: transiciones de agua y olas. Registro técnico también
en VISUAL_SUBSTITUTIONS; inventario artístico intacto. Sin commit/push/merge.

## Tramo anterior conservado: escudos y Sombra Vil — 2026-10-25

Cinco casos frontales resueltos en este tramo, con dos políticas acotadas por
ID/nombre/export/SHA completo de frames (`NATIVE_PROJECTION_EXPORTS`). En
**light_screen, mat_block, quick_guard y reflect**, la celda0/-1 del actor no
implicado usa foco1 aunque sus coordenadas siguen en (128,224): trasladarla con
origen trasero mantiene al Pokémon sobre su plaza/sombra. Cuerpo del usuario,
partículas de escudo, capas, colores y geometría permanecen iguales. No tratar
users-field como si fueran movimientos propios de un único cuerpo.

**shadow_sneak/front:** patrón0 es un óvalo que viaja desde (384,160) a (128,280),
no una partícula rígida junto al destino. Proyectarlo por línea canónica3;
los destellos patrón1 usan ancla trasera2. Celdas, alfa, tamaño, prioridad, tintes
y cuerpos originales intactos. No cambiar las otras exportaciones globalmente.

Antes `.godot/move_projection_checks/reference/preview_before.gd`, SHA
`b2610a303d30411b07100f985133cbd0a644ebccbbd4f5f4623349cc92845302`;
actual `81cb49e7e0b2594181ebec834f5fa3c58bbffa036e7fb02a0e13a3d31d10a074`.
Evidencia final `.godot/move_projection_checks/c7fb45d23f10eccb/gpu/`:
`{result,review}.json`, `sheets/boards.json`, **tres láminas observadas**,
15 IDs/30 vistas. Capturados inicio/foco/final y fases extra de Sombra Vil:
96 muestras por dos renderers, **192 PNG**. Ampliados f5 antes/después y f10,
f16, f20 después: sombra parte del usuario, cruza la escena, llega al objetivo
y presenta destello. Los cuatro escudos mantienen al otro actor en su plaza.
Back y diez controles conservados; azul de Danza Lunar, ecos de Doble Equipo
y arreglos de anclas anteriores presentes sin diferencias en muestras de control.

**Cinco IDs/clips de cola cerrados**: light_screen/front, mat_block/front,
quick_guard/front, reflect/front, shadow_sneak/front. Acumulado **45 IDs /
69 clips cerrados**. Restantes **48 IDs: 29 de contraste/19 de contexto**,
87 clips. Láser Doble sigue idéntico y abierto; su foco3 y desplazamiento nativo
no justifican centrarlo a ojo ni afirmar impacto totalmente ausente. Quedan
haces/impactos por contraste, agua/olas, encuadres y decisiones artísticas.

Gate GPU **200.653 PASS / 4.428 estados / 780 posiciones corregidas comprobadas**,
tres parejas/dos arenas, todos los frames. Oráculos independientes de línea y
ancla; aparición, aspecto, trayectorias no afectadas, capas, limpieza y rechazo
de export alterado. Regresiones: catálogo headless **5.368.625 / 118.766 estados /
1.822 clips**; prioritario **444.079**; cuerpos propios **387.764**; cámaras previas
**4.620**; cinco rutas reales **407**; contexto **6.442**, todo PASS. Test de anclas
anteriores **296.513 / 6.492 estados PASS** tras sustituir el control Sombra Vil
por Rayo Hielo: la ruta reparada ahora tiene su propio oráculo y ya no debe
exigirse idéntica a la versión defectuosa. La primera ejecución identificó ese
contrato antiguo; copia exacta del test anterior preservada en
`reference/anchor_runner_before.gd`, SHA coincide con el reporte del segundo grupo.

Contexto derivado `acb25776afb63cda`, mismo arte/frames/bindings, versiones previas
intactas. Los registros del barrido y dos reparaciones previas no se sobrescriben
ni se migran al renderer nuevo. Índice, fuentes, datos, IA, mecánicas, cinco rutas,
workflows y HEAD intactos. Ajuste técnico también en VISUAL_SUBSTITUTIONS;
ninguna sustitución artística ni nuevo crédito. Sin commit/push/merge.

## Tramo anterior conservado: anclas frontales — 2026-10-25

Causa demostrada en trece exports nativos: partículas con foco1 escritas alrededor
del origen canónico trasero (128,224), mientras el adaptador las trasladaba respecto
al delantero (384,96). La diferencia de cámara añadía un desplazamiento común.
Se corrige únicamente la referencia de posición al origen trasero con escala
uniforme, conservando el desplazamiento local. No modificar celdas fuente, hojas,
colores, forma, tamaños, rotación, prioridad, cuerpos, capas o trayectorias foco3.

Selección cerrada de IDs front: **crush_grip, drill_run, dual_wingbeat, force_palm,
poison_sting, poison_tail, pollen_puff, power_whip, scary_face, sludge, thunderclap,
wing_attack, worry_seed**. Cada entrada de `NATIVE_TARGET_EXPORTS` fija SHA de
`JSON.stringify(frames)` de Godot 4.7; el cargador exige además nombre, ID, export
nativo y ausencia de reflejo mapeado. Fuente distinta se rechaza. No es una regla
para todos los OppMove ni inferencia automática por proximidad de coordenadas.

Antes preservado en `.godot/move_anchor_checks/reference/preview_before.gd`, SHA
`4fb1e38b88cd6e2d34a92c414d21fdadf4544cd6daaacfc6460f592d4aab893e`;
actual `b2610a303d30411b07100f985133cbd0a644ebccbbd4f5f4623349cc92845302`.
Evidencia final `.godot/move_anchor_checks/4cba2c2b751a2842/gpu/`: `result.json`,
`review.json`, `sheets/boards.json`, **cinco láminas observadas**. 23 IDs/46 vistas,
13 focales y diez controles; captura de inicio/foco/final, 138 muestras por dos
renderers = 276 PNG. Las láminas muestran el fotograma focal; no película completa.

Ampliaciones: Ataque Ala front f5 ahora superpone arcos a borde de cabeza; Agarrón
f10 y Palmeo f7 manos sobre cuerpo; burbujas venenosas rodean al objetivo; Abatidoras
f18 humo sobre cabeza; Bola de Polen f19 estallido sobre cabeza, trayectoria foco3
intacta. Latigazo front f6 sigue separado durante retroceso: ampliar f0 antes y
después confirma contacto ahora presente; fuente desplaza cuerpo X128→62/Y224→242
en f6, conservando VFX en lugar de golpe. No declarar ausencia total ni perseguir
el cuerpo en cada frame. Colores y efectos locales de la fuente se mantienen.

**13 casos de la cola cerrados / 13 clips frontales**. Acumulado con cuerpos
propios: **40 IDs / 64 clips cerrados**. Restantes **53 IDs: 34 de contraste y
19 de contexto**, 92 clips. Registro nuevo conserva cierres anteriores por SHA
y enumera los pendientes. Sombra Vil y Láser Doble son controles idénticos en GPU
y siguen abiertos: el óvalo de Sombra Vil viaja entre ambos actores, y Láser Doble
ya usa foco3. No aplicarles la referencia rígida usada aquí sin estudiar su ruta.
También quedan campos/escudos desplazados, agua, encuadres y casos particulares.

Gate nuevo: **296.099 checks GPU PASS / 6.552 estados / 4.284 celdas comprobadas
con referencia corregida**; todos los frames por dos arenas/tres parejas, incluida
Pikachu/Wailord. Oráculo independiente `rear_center + (point-(128,224))*gain`,
reproduce desfase anterior y comprueba cuerpos, trayectorias foco3, textura,
transformación local/tinte, capas y limpieza. Prueba real de export alterado
rechazado. Back y los diez controles son idénticos en las muestras GPU. La primera
captura tenía dos muestras repetidas de Láser Doble por elegir el último frame
como focal; seleccionadas fases distintas y repetida la colección completa.

Regresiones finales: catálogo headless **5.368.625 PASS / 118.766 estados /
1.822 clips**; piloto prioritario **444.079**; cuerpos propios **387.764 / 10.004**;
cámaras anteriores **4.620**; cinco rutas reales **407**; contexto opcional
**6.442 / 1.164 estados**, todo PASS. Contexto derivado nuevo `d96f2f29fcdf3855`,
sin cambios de arte/frames/bindings; anteriores intactos. Los dos grupos previos
de evidencia (18 bloques y cuerpos propios) conservan sus hashes, sin sobrescribir
ni migrar aprobaciones. Datos, índice, IA, mecánicas, cinco rutas, workflows y HEAD
intactos. Registro técnico también en VISUAL_SUBSTITUTIONS. Sin commit/push/merge.

## Tramo anterior conservado: reparación de cuerpos propios — 2026-10-25

Autorizado empezar las reparaciones por grupos después del barrido. Causa:
el adaptador dibujaba dos bases independientes aunque ambas representaban al
mismo Pokémon. [El reproductor de Essentials](https://github.com/Maruno17/pokemon-essentials/blob/master/Data/Scripts/011_Battle/007_Other%20battle%20code/007_BattleAnimationPlayer.rb)
vincula las celdas 0/1 a usuario/objetivo; su
[llamador intercambia roles en OppMove](https://github.com/Maruno17/pokemon-essentials/blob/master/Data/Scripts/011_Battle/004_Scene/004_Scene_PlayAnimations.rb).
Inferencia aplicada en nuestra cámara: un propio tiene una base primaria, con
roles invertidos para export nativo contrario. La inspección encontró recursos
que animan la otra pista (Danza Lunar) o alternan pistas (Venganza): conservar la
que tiene pose/tinte/fundido si la preferida sigue por defecto. Si ambas están
animadas, desempatar por rol del export. Política acotada del adaptador, no
reproducción íntegra del motor de origen. Celdas 2+ y partículas permanecen intactas.

**27 IDs de la cola corregidos para duplicado primario / 51 clips señalados**:
barrier, bulk_up, celebrate, copycat, detect, dragon_dance, endure, fillet_away,
laser_focus, lunar_dance, magic_coat, magnet_rise, meditate, minimize, moonlight,
no_retreat, power_trick, quiver_dance, rage_powder, rock_polish, sharpen, slack_off,
snatch, splash, tidy_up, victory_dance y work_up. Comparados ambos lados (54 vistas),
más 22 vistas de once controles. **66 casos del baseline siguen abiertos: 47 de
contraste/19 de contexto, 105 clips**. Es cierre del defecto primario, no aprobación
de toda coreografía o mecánica. Los 97 IDs propios/194 clips están cubiertos por
el gate; solo los 38 IDs de las láminas tienen revisión gráfica nueva explícita.

Evidencia final `.godot/move_self_body_checks/e6bb10786f264b35/gpu/`: `result.json`,
`review.json` y `sheets/boards.json`, ocho láminas observadas, 76 vistas/152 PNG.
Renderer anterior preservado en `reference/preview_before.gd`, SHA
`9636af2c5cba04511e4dbb48c92411564bf64bf2e738695a39aabd5542f55334`;
actual `4fb1e38b88cd6e2d34a92c414d21fdadf4544cd6daaacfc6460f592d4aab893e`.
Prueba nueva reproduce el fallo anterior, compara todos los frames propios y
controles por dos arenas, conserva geometría/tinte/partículas/capas activas y
ejercita 694 instancias de cuerpos extra. **387.922 checks GPU PASS, 10.004 estados**.
Las láminas muestran un fotograma focal por vista, no película completa observada.

Rechazada primera versión de rol fijo: perdía azul de Danza Lunar; corregida antes
de aprobar. Corregido también el selector de Relevo (31/35 frames): faltaba su
vista corta en la primera captura. Artefactos fallidos conservados, no evidencia
final. Doble Equipo retiene dos ecos y un cuerpo; Pesadilla permanece idéntica;
Cola Férrea y Día Soleado idénticos en GPU. Reducción conserva su eco deliberado.
Teletransporte ahora deja plaza vacía al terminar, conforme a su pista de fundido;
Relevo deja salir usuario. Sus contextos siguen abiertos. Sustituto conserva muñeco
y deuda de persistencia, sin activar coste de PS/protección. Se mantiene azul de
Danza Lunar y secuencia alternada de Venganza, tintes/giros/aplastamientos del grupo.

Regresiones finales: catálogo completo headless **5.368.625 PASS / 118.766 estados /
1.822 clips**, piloto prioritario **444.079**, cinco conexiones reales **407**,
contexto opcional **6.442 / 1.164 estados**, dos tests Python de evidencia externa
PASS. El contexto detectó correctamente hash obsoleto del renderer: nuevo pack
derivado `67ab17c8a7c5e617`, mismo arte/frames/bindings; generaciones anteriores
intactas. El generador incluye renderer en identidad y comprueba estabilidad.

El barrido original conserva índice, plan, 523 registros y sus PNG. SHA del
registro `ee4600561c352615f147387e367e871bea61b0783c5fbc51cf77e8884b8e904c`.
Las cifras inferiores 807/74/19 describen ese baseline; no se migran automáticamente
al renderer nuevo. La cola restante está enumerada por ID/lado en el `review.json`
nuevo, junto a los 51 clips cerrados. Próximo grupo: impactos/anclas frontales,
antes de agua/encuadres. Sin arte nuevo, datasets/IA/mecánicas/workflows ni cambio
de las cinco rutas reales. CI del HEAD previo no certifica cambios locales.
Registro técnico en VISUAL_SUBSTITUTIONS; sin commit/push/merge.

## Baseline conservado: barrido temporal en bloques de 50 IDs — 2026-10-25

**Progreso: 900/900 IDs / 1.822 clips**, dieciocho bloques observados; **0 IDs restantes**.
Acumulado: 807 IDs sin fallo evidente en muestras, setenta y cuatro dudas y diecinueve presentaciones
externas pendientes. Por clip: 1.666/118/38; 93 casos guardados. No significa 900 mecánicas certificadas.

Solicitud actual reconfirmada por el usuario: revisar los 900 de forma sistemática,
guardar los casos y **corregirlos después del barrido**. Se conserva el muestreo anterior, pero esta fase nueva recorre todas
las familias con mayor cobertura temporal. Los 19 secundarios siguen fuera de
prioridad: faltan etiquetas de recursos, no son 19 animaciones listas por revisar.

`review_move_temporal_batches.py --plan` valida catálogo/shards/texturas y fija
los 900 IDs, 911 familias y 1.822 clips en 18 bloques de 50 IDs ordenados. Incluye
variantes/contextos bajo el mismo ID; no deduplicar ataques por parecido artístico.
Cada familia conserva ambos lados, sin repeticiones ni huecos. La generación del
plan depende del índice, renderer y herramienta; no migrar notas sin comprobar
identidad real de la evidencia.

`move_temporal_batch_runner.gd` exige GPU, plan actual y pertenencia exacta.
Captura cada frame de cada clip seleccionado a 640×360, valida reloj de 20 fps,
limpieza de sprites/capas y retorno a píxeles de referencia; fija hashes PNG y
fuentes. El compositor elige 16 muestras por vista: extremos, máximo de celdas de
partículas, mayores transiciones de píxeles y sus vecinos, más tiempos repartidos.
Para clips de 16 frames o menos muestra TODOS y rellena con el último, sin inventar
fotogramas. Cinco familias por lámina, dos láminas por grupo. Los disparadores
automáticos son pistas, no diagnósticos ni aprobaciones artísticas.

### Bloque 1: observado y anotado

Plan `.godot/move_temporal_batches/c5b2756454290487/plan.json`; progreso en
`review.json`. Resultado `batch_01_4cf3260effe18266/result.json`: **16.756 checks
PASS / 3.014 frames / 100 clips / 50 IDs**. Sus veinte láminas `sheets/boards.json`
se observaron completas. Se ampliaron PNG nativos de Acupresión back/front f8,
Barrera front f6 y Al Ataque back f9. Al Ataque contiene motivos verdes pequeños,
no un atlas vacío; su estilo sencillo no demuestra un fallo técnico.

| ID / nombre | Vistas | Hallazgo y estado |
| --- | --- | --- |
| acupressure / Acupresión | back y front | La marca está sobre un cuerpo y el destello sobre el otro en f8. Contrastar roles y fuente; needs_targeted_review, DATA_ONLY sin habilitar |
| aeroblast / Aerochorro | back y front | Back tiene nubes/oscurecimiento de carga; front carece de esa capa visible, aunque conserva tornado/haz/flash. Contrastar exports; needs_targeted_review, no defecto confirmado |
| aromatic_mist / Niebla Aromática | back y front | Back presenta niebla/capa rosa global; front no muestra esa capa. Contrastar exports/capas y contexto aliado; needs_targeted_review, DATA_ONLY |
| barrier / Barrera | solo front | Dos Charizard simultáneos, uno en plaza y otro junto a Ogerpon (f6). Investigar cel de cuerpo/foco; needs_targeted_review. Back sin duplicación evidente |
| ally_switch / Cambio de Banda | back y front | Usuario oculto al acabar f14; la limpieza lo restaura pero no representa intercambio con compañero. requires_external_presentation, DATA_ONLY |

**91 clips sin fallo evidente en las 16 muestras / siete dudas / dos de contexto**.
Por ID: **45 sin fallo evidente, cuatro con duda y uno de contexto**. Dos dudas de
capas y una de roles necesitan investigación, no se afirman tres defectos nativos.
No se han alterado fuentes o arte. Cambio de Banda añade una deuda nueva de
presentación en esta fase; no modifica retroactivamente los doce clips de los seis
contextos del registro inicial. Al cerrar este bloque quedaban 850 IDs y cinco
incidencias; el progreso vigente incluye también el bloque 2 descrito debajo.

### Bloque 2: observado y anotado — 2026-10-25

Mismo plan/renderer/catálogo, sin modificar herramientas, arte o clasificaciones.
Resultado `batch_02_10a1e33372afa525/result.json`, bajo la generación del plan:
**17.369 checks PASS / 3.218 frames GPU / 100 clips / 50 IDs**, de baton_pass a
burn_up. Veinte láminas observadas completas, cinco familias por página, dos
lados y 16 muestras. Treinta disparadores de cambios de pantalla y dos de cuerpos
ocultos/fundidos: no son treinta y dos defectos, ni una secuencia estática.

| ID / nombre | Vistas | Hallazgo y estado |
| --- | --- | --- |
| bulk_up / Corpulencia | back y front | PNG f7: dos dibujos superpuestos del usuario, de escalas distintas, con contornos desfasados durante el crecimiento. needs_targeted_review; contrastar cuerpos/celdas y objetivo propio. RUNTIME_SUPPORTED conservado |
| behemoth_bash / Embate Supremo | back y front | Escudo grande con rostro específico superpuesto al usuario y después al objetivo (back f7 ampliado). Duda de idoneidad para usuarios aleatorios, no fallo de conversión demostrado; needs_targeted_review. PARTIAL_RUNTIME conservado |
| baton_pass / Relevo | back y front | Bastón/guante y ecos visibles, sin sustituir al usuario. En PNG final f30/f34 el cuerpo principal permanece normal; son algunas celdas fantasma las que terminan ocultas. requires_external_presentation, DATA_ONLY; no confundir con atlas roto ni con usuario desaparecido |

**94 clips temporal_samples_checked / cuatro needs_targeted_review / dos
requires_external_presentation**; **47 IDs sin fallo evidente en las muestras,
dos dudas y uno de contexto**. Sin sustituciones ni reparaciones en este bloque.
Corpulencia requiere investigación antes de asumir si el defecto procede del
renderer o del tratamiento de cuerpos de origen. El escudo puede ser intencional;
se anota la duda artística sin descartarlo ni buscar otra imagen todavía.

Ampliaciones adicionales para descartar falsas alarmas de las miniaturas:
Atadura back/front f13 muestra la compresión en el objetivo además de movimiento
del usuario; Pájaro Osado back f4/f19 conserva las siluetas de usuario y objetivo
en carga/reacción respectivamente, no un cambio arbitrario de especie; Demolición
back f7/f14 y sus coordenadas mantienen al usuario en su plaza, sin demostrar
recorte del cuerpo por borde. No se añaden esas tres familias a la cola de fallos.
Se vieron además Corpulencia front f0/f7/f8, back f7, escudo back f7 y ambos finales
de Relevo. Esta inspección nativa evita corregir a ojo una lectura dudosa de miniaturas.

Registro acumulado **185/11/4 clips, 92/6/2 IDs**, 40 páginas anotadas. Los registros
anteriores del bloque 1 se conservan íntegros. Total de gates: **6.232 frames /
34.125 checks GPU PASS**, sin certificar fluidez a velocidad real ni mecánicas.
Al cerrar el bloque 2 quedaban 800 IDs y ocho casos, antes del bloque 3 de debajo.
No editar índice/renderer ni vaciar la cola para aumentar contadores. Los 19
workflows del HEAD previo se consultaron otra vez: SUCCESS; no certifican evidencia
o documentación local sin commit. Fuentes canónicas raw/normalized intactas.

### Bloque 3: observado y anotado — 2026-10-25

Mismo plan y herramientas. Resultado `batch_03_e38f080272506981/result.json` bajo
la generación del plan: **17.842 checks PASS / 3.376 frames GPU / 100 clips / 50
IDs**, de burning_bulwark a cross_chop. Veinte láminas observadas completas, ambos
lados y 16 muestras; incluso Hélice Trepanadora físico/especial de 120 frames se
captura íntegra. Veinte disparadores de cambios grandes de pantalla y seis de
opacidad/visibilidad: pistas analizadas, no veintiséis defectos confirmados.

| ID / nombre | Vistas | Hallazgo y estado |
| --- | --- | --- |
| celebrate / Celebración | back y front | PNG f7: cuerpos base -1 y -2 opacos, mismo lado y desplazados 7,5 px en cada eje. Dos contornos del usuario; needs_targeted_review, DATA_ONLY |
| copycat / Copión | back y front | PNG f10 y celdas base: dos dibujos opacos del mismo usuario separados 3,75 px en horizontal. Contrastar objetivo propio/coreografía; needs_targeted_review, UNSUPPORTED |
| clanging_scales / Fragor Escamas | solo front | PNG f5: Ogerpon objetivo se eleva hasta quedar recortado por arriba. Back eleva a Charizard sin ese recorte; contrastar foco/export/geometría. needs_targeted_review, RUNTIME_SUPPORTED |
| court_change / Cambio de Cancha | back y front | PNG final f21: plazas intercambiadas; la limpieza devuelve cuerpos a plazas originales. Revisar coreografía/contexto antes de integrar; needs_targeted_review, DATA_ONLY. No ordenar cambiar posiciones mecánicas por una imagen |
| catastropika / Pikavoltio Letal | back y front | Insignia con Pikachu muy grande (PNG back f4) sobre usuarios distintos. Duda artística secundaria de idoneidad/uso final, no fallo del renderer; needs_targeted_review, RUNTIME_SUPPORTED. No investigar alternativa ahora |
| chilly_reception / Fría Acogida | back y front | Retirada y falta de presentación posterior de clima/entrada, deuda YA conocida de la fase inicial. PNG back f29 muestra usuario ausente. requires_external_presentation, DATA_ONLY |
| circle_throw / Llave Giro | back y front | Objetivo gira, sale del viewport y queda oculto en f18; PNG front y estado final lo confirman. Necesita presentación del siguiente combatiente. requires_external_presentation, RUNTIME_SUPPORTED; no fallo de atlas ni soporte nuevo |

**87 clips temporal_samples_checked / nueve needs_targeted_review / cuatro
requires_external_presentation**, es decir, **43 IDs sin fallo evidente, cinco dudas
y dos contextos**. Clasificaciones, arte y cinco rutas reales de combate intactos.
Celebración/Copión comparten indicios con Corpulencia: celdas base de usuario y
objetivo propio que dibujan el mismo actor en dos posiciones. Candidatos a diagnóstico
conjunto al acabar el barrido; no se afirma aún una reparación común probada.

Ampliaciones observadas: Paz Mental front f10, Llama Protectora front f6,
Camuflaje back f20; Celebración ambos f7; Fragor Escamas ambos f5; Copión ambos f10;
Cambio de Cancha ambos f21; Pikavoltio Letal back f4; Llave Giro front f18 y Fría
Acogida back f29. Se contrastaron además los estados de celdas para separar cuerpos
principales de copias. **Confusión no añade deuda externa**: en f28 ambos cuerpos
base están visibles y con opacidad 1; el aviso procede de una celda extra oculta
con opacidad 0,2. Camuflaje vuelve al cuerpo normal al terminar. No interpretar
todos los disparadores de opacidad como Pokémon desaparecidos.

Registro acumulado **272/20/8 clips, 135/11/4 IDs**, sesenta páginas anotadas. Los
55 registros de los dos primeros bloques permanecen íntegros. Tres gates suman
**9.608 frames / 51.967 checks GPU PASS**. Al cerrar el bloque 3 quedaban 750 IDs,
antes del bloque 4 de debajo, más quince casos de contraste/contexto
acumulados. Son categorías de seguimiento, no quince fallos técnicos probados.
No se han sustituido imágenes ni editado renderer, herramientas, tests, datasets,
workflows o mecánicas. CI del HEAD previo consultado: 19 SUCCESS, sin certificar
las notas o la evidencia local. Mantener el barrido antes de reparaciones aisladas.

### Bloque 4: observado y anotado — 2026-10-25

Resultado `batch_04_1079a5033beb90ec/result.json`, bajo la misma generación del
plan: **16.559 checks PASS / 2.948 frames GPU / 100 clips / 50 IDs**, de cross_poison
a draining_kiss. Veinte láminas observadas, ambos lados y 16 muestras. Dieciocho
disparadores de transición de pantalla y cuatro de cuerpos ocultos/fundidos, sin
secuencias GPU completamente estáticas. Se separan disparadores de diagnósticos.

| ID / nombre | Vistas | Hallazgo y estado |
| --- | --- | --- |
| detect / Detección | solo front | PNG f7: Charizard en su plaza y otro junto a Ogerpon; celdas base -1/-2 mapeadas a front pero en (242, 254.6) y (482, 134.6). Contrastar foco/objetivo propio. needs_targeted_review, DATA_ONLY. Back coincidente sin separación visible |
| dragon_dance / Danza Dragón | back y front | PNG f20: usuario normal y segundo cuerpo rosado desplazado, dos contornos durante danza. Contrastar origen/celdas, candidato al grupo de cuerpos base superpuestos. needs_targeted_review, RUNTIME_SUPPORTED |
| crush_grip / Agarrón | solo front | PNG f10: mano cerrada a la derecha del objetivo encogido, sin mantenerlo dentro; back f10 sirve de referencia con mano/cuerpo juntos. Contrastar anclaje OppMove y deformación. needs_targeted_review, DATA_ONLY |
| destiny_bond / Mismo Destino | back y front | Destaca una elipse gris plana desplazándose en fondo negro (back f17 ampliado). Cotejar textura/capas y coreografía antes de asumir que es intencional o que falta un recurso. Duda de presentación, no fallo técnico probado; needs_targeted_review, DATA_ONLY |
| doom_desire / Deseo Oculto | back y front | PNG f20: trazos rígidos blancos/violetas convergentes, impacto poco identificable. Cotejar fuente y fase de preparación/impacto antes de intervenir. needs_targeted_review, RUNTIME_SUPPORTED; no afirmar fallo de su daño diferido |
| dragon_pulse / Pulso Dragón | back y front | PNG f25 y muestras: esfera/aros rosados concentrados en el usuario, sin trayectoria/impacto claros sobre objetivo. Contrastar fase, export y focos. needs_targeted_review, RUNTIME_SUPPORTED; no significa fallo mecánico demostrado |
| dragon_tail / Cola Dragón | back y front | Objetivo expulsado y oculto al finalizar f19; PNG front y estados confirman plaza vacía. Requiere presentar al siguiente combatiente, como Llave Giro. requires_external_presentation, RUNTIME_SUPPORTED; no atlas roto ni soporte nuevo |

**88 clips temporal_samples_checked / diez needs_targeted_review / dos
requires_external_presentation**, equivalentes a **43 IDs sin fallo evidente,
seis dudas y uno de contexto**. Los tres casos de aspecto/fase no tienen el mismo
grado de evidencia que la copia extra visible; conservar sus notas diferenciadas.
No buscar otras imágenes ni reparar a ojo antes del diagnóstico de fuente.

Ampliaciones: Doble Equipo ambos f12; Rizo Defensa front f7; Detección front f7;
Agarrón ambos f10; Danza Dragón ambos f20; Deseo Oculto ambos f20; Pulso Dragón
ambos f25; Mismo Destino back f17; Cola Dragón front f19. Se contrastaron estados
de cuerpo de Detección, Doble Equipo y Cola Dragón. No inferir usuario/objetivo
solo por patrón -1/-2 en exports OppMove: usar el lado y rol reales del clip.

**Referencia para las reparaciones futuras:** Doble Equipo muestra tres imágenes
del usuario como coreografía del recurso; sus dos copias laterales son celdas
adicionales 2/3 con patrón -1. Al acabar se ocultan, pero el cuerpo principal
permanece. Su disparador automático no añade deuda de presentación externa.
Las celdas base 0/1 coinciden; no existe contorno doble desplazado en esa coincidencia.
Proteger estas copias deliberadas al investigar los casos de objetivo propio:
una regla que suprima todas las copias de cuerpo rompería esta animación.
Dig y Dive se revisan como tramo de salida/impacto/retorno, sin aprobar por ello
la selección de su fase previa. Los vuelos/giros que salen y vuelven a entrar al
viewport tampoco son automáticamente un error de cámara.

Acumulado: **360/30/10 clips, 178/17/5 IDs**, ochenta páginas anotadas. Los 88
registros previos se mantienen íntegros. Cuatro gates suman **12.556 frames /
68.526 checks GPU PASS**. Al cerrar el bloque 4 quedaban **700 IDs pendientes de
este barrido**, antes del bloque 5 de debajo, más veintidós casos apartados;
no veintidós defectos técnicos confirmados. Sin sustituir imágenes ni modificar
herramientas, renderer, mecánicas, datos, IA, tests o workflows. CI del mismo HEAD
previo: 19 SUCCESS; no certifica este registro/documentación local sin commit.

### Bloque 5: observado y anotado — 2026-10-25

Resultado `batch_05_2d69da14cc4d3101/result.json` bajo la misma generación del
plan: **17.674 checks PASS / 3.320 frames GPU / 100 clips / 50 IDs**, de dream_eater
a fillet_away. Veinte láminas observadas completas, ambos lados y 16 muestras.
Veintiún disparadores de transición de pantalla y dos de opacidad/visibilidad;
no son veintitrés defectos. No hay secuencia GPU completamente estática.

| ID / nombre | Vistas | Hallazgo y estado |
| --- | --- | --- |
| drill_run / Taladradora | solo front | PNG f12: motivo dentado separado a la derecha del objetivo que cambia de tono; back mantiene motivo junto al cuerpo. Contrastar anclaje/foco de OppMove, candidato al grupo de Agarrón. needs_targeted_review, RUNTIME_SUPPORTED |
| dual_wingbeat / Ala Bis | solo front | PNG f6: arco blanco a la derecha y debajo de Ogerpon, sin tocarlo; back coloca el arco sobre Charizard. Contrastar export/anclaje. needs_targeted_review, RUNTIME_SUPPORTED |
| endure / Aguante | back y front | PNG f6: dos cuerpos opacos del mismo usuario a la misma posición, escalas distintas (front 1.2/1.0). Doble contorno visible; contrastar objetivo propio. needs_targeted_review, DATA_ONLY |
| fillet_away / Deslome | back y front | PNG f10: usuario de pie y otro cuerpo girado encima; las dos celdas base -1/-2 apuntan al mismo lado y están visibles/opacas. La rotación se ve en PNG, no se deduce solo de posición/escala. needs_targeted_review, DATA_ONLY |
| entrainment / Danza Amiga | solo front | PNG f29: Ogerpon objetivo desciende a y305.35 y queda recortado por abajo; back f29 no recorta a Charizard. Cotejar foco/movimiento del objetivo; needs_targeted_review, DATA_ONLY |
| extreme_evoboost / Novena Potencia | back y front | PNG back f45: fila fija de evoluciones de Eevee sobre usuarios distintos, independiente de combatientes. Duda artística secundaria de uso final/exclusión, no fallo técnico probado. needs_targeted_review, DATA_ONLY; sin buscar alternativa ahora |

**91 clips temporal_samples_checked / nueve needs_targeted_review / cero contextos
nuevos**, **44 IDs sin fallo evidente / seis dudas**. El resto de deudas de contexto
de los bloques anteriores permanece íntegro. Todas las clasificaciones y las cinco
rutas visuales reales de combate se conservan.

Ampliaciones observadas: Explosión back f64; Campo Eléctrico back f24; Aguante
ambos f6; Deslome ambos f10; Taladradora ambos f12; Ala Bis ambos f6; Danza Amiga
ambos f10 y f29, back f20 y front f25/f30; Novena Potencia back f45. En Danza Amiga,
la primera sospecha de recorte en back se descarta con el PNG: sus movimientos
permanecen dentro del viewport. **El recorte confirmado es front al descender**;
f25/f30 muestran el tramo, y el retorno final se ve en f35 de la lámina. No confundir
un salto momentáneo con una desaparición permanente.

Se contrastaron además estados de cuerpos de Aguante/Deslome y los rangos de
movimiento de Danza Amiga. **Paranormal no añade deuda externa**: al terminar,
sus dos cuerpos base están visibles y con opacidad 1; el aviso corresponde a una
celda extra oculta con opacidad aproximada 0.1647. Campo Eléctrico se revisa como
invocación, sin aprobar la permanencia del terreno; el recurso de Explosión vuelve
al escenario, sin que ese retorno certifique debilitamiento o resolución mecánica.

Los nuevos contornos dobles y anclajes de OppMove se guardan para diagnóstico
conjunto tras el barrido, manteniendo las referencias que sí encajan. No se ha
corregido ningún caso ni sustituido imágenes. Acumulado **451/39/10 clips,
222/23/5 IDs**, cien páginas anotadas y los 120 registros anteriores íntegros.
Cinco gates: **15.876 frames / 86.200 checks GPU PASS**. Al cerrar el bloque 5 quedaban
**650 IDs pendientes**, antes del bloque 6 de debajo, más veintiocho casos de contraste/
contexto, no veintiocho bugs probados. Mismas herramientas, renderer y datasets;
CI del HEAD anterior vuelto a consultar: 19 SUCCESS, sin certificar las notas
o capturas locales sin commit. Sin cambios de mecánicas, IA, tests o workflows.

### Bloque 6: observado y anotado — 2026-10-25

Resultado `batch_06_f35e7337d8d5fa4d/result.json` bajo el mismo plan: **17.132
checks PASS / 3.139 frames GPU / 100 clips / 50 IDs**, de final_gambit a gear_up.
Veinte láminas observadas completas, ambos lados y 16 muestras por vista. Veinte
disparadores de cambio de pantalla y dos de visibilidad/fin de celda, sin secuencias
GPU completamente estáticas. Los avisos no se cuentan automáticamente como fallos.

| ID / nombre | Vistas | Hallazgo y estado |
| --- | --- | --- |
| force_palm / Palmeo | solo front | PNG f7: mano centrada a la derecha de Ogerpon, separada del objetivo; back la superpone a Charizard. Contrastar anclaje/foco de OppMove, posible grupo con Agarrón/Taladradora/Ala Bis. needs_targeted_review, RUNTIME_SUPPORTED |
| flatter / Camelo | back y front | PNG f12: líneas finas horizontales/verticales formando trazos y marcos cerca de las partículas sobre fondo negro. Cotejar gráfico original, recorte/filtrado y coreografía antes de borrarlas o llamarlas artefactos. needs_targeted_review, RUNTIME_SUPPORTED; causa no demostrada |
| flip_turn / Viraje | back y front | Esfera de agua, impacto/retorno y salida del usuario; f29 deja su plaza vacía. Necesita presentar el relevo posterior, como Relevo/Cambio de Banda. requires_external_presentation, PARTIAL_RUNTIME; no atlas roto ni soporte nuevo |

**95 clips temporal_samples_checked / tres needs_targeted_review / dos
requires_external_presentation**, **47 IDs sin fallo evidente / dos dudas / uno de
contexto**. Los 28 casos anteriores se conservan. No se ha modificado fuente,
renderer o clasificación para cerrar ninguno de estos tres.

Ampliaciones observadas: Foco Energía front f7; Señuelo front f12; Piñón Auxiliar
front f30; Viraje ambos f29; Plancha Voladora ambos f0; Palmeo ambos f7; Camelo
ambos f12; Rayo Fusión ambos f15. Se contrastaron los estados de cuerpo iniciales
de Plancha Voladora (ambos en sus plazas al empezar). No atribuir un recorte a
miniaturas sin comprobar el PNG; las salidas y retornos durante saltos/giros se
revisan como coreografía, no se declaran automáticamente fallos de cámara.

En Rayo Fusión, el halo de carga toca el borde superior de la vista front en f15;
se conservan núcleo y cuerpos visibles. No se confirmó pérdida del cuerpo ni se
añade una incidencia por el halo aislado. Juego Sucio conserva sus copias temporales
del atacante durante la acometida; no aplicar una eliminación global de copias
para resolver los otros casos de objetivo propio. Sacrificio se revisa como recurso
de carga/reacción, sin que el usuario visible/tintado al acabar certifique su
debilitamiento ni su resolución mecánica. Vuelo se observa como tramo de descenso,
impacto y retorno, sin certificar por ello las fases del combate.

**Equivalentes previos conservados**, cotejados con metadatos del catálogo:
Truco Floral mantiene únicamente el cambio de fondo `uwu.png` ausente por
`PRAS- Petal BG.png` (petal_background_equivalent_only), sin recuperar el fondo
nativo; Premonición usa `Move:FUTUREDUMMY` como fase de impacto explícita, sin
recuperar preparación ni `PRAS- Darkness BG.png` ausente. Ambos declaran
`native_gap_fixed=false`, `mechanics_enabled=false`. Este barrido no realiza una
sustitución nueva ni altera el registro de cambios artísticos.

Acumulado **546/42/12 clips, 269/25/6 IDs**, ciento veinte páginas anotadas;
los 150 registros anteriores permanecen íntegros. Seis gates suman **19.015 frames /
103.332 checks GPU PASS**. Al cerrar el bloque 6 quedaban **600 IDs pendientes**,
antes del bloque 7 de debajo, más treinta y un casos de contraste/contexto,
no treinta y un bugs probados.
Sin editar herramientas, renderer, arte, datos, mecánicas, IA, tests o workflows.
CI del mismo HEAD anterior: 19 SUCCESS, sin certificar notas/evidencia local sin
commit. Mantener primero el barrido y después las correcciones, como pide el usuario.

### Bloque 7: observado y anotado — 2026-10-25

Resultado `batch_07_bdcca293bf7e0494/result.json` bajo el mismo plan: **17.503
checks PASS / 3.263 frames GPU / 100 clips / 50 IDs**, de genesis_supernova a hex.
Veinte láminas completas observadas, ambos lados, 16 momentos por vista.
Veintiocho disparadores de transición amplia y dos de opacidad final; ninguna
secuencia GPU completamente estática. Los disparadores no son diagnósticos.

| ID / nombre | Vistas | Hallazgo y estado |
| --- | --- | --- |
| genesis_supernova / Supernova Original | back y front | Mew fijo en cinematografía de estrellas/ADN aunque usuario actual sea otra especie. PNG nativo back f50 y ambas láminas observados. Duda artística secundaria de idoneidad para usuarios aleatorios; needs_targeted_review, RUNTIME_SUPPORTED intacto. No fallo de renderer demostrado ni búsqueda de reemplazo ahora |
| glacial_lance / Lanza Glacial | solo front | PNG f16: lanza separada a la derecha del objetivo; f17: punta próxima pero fuera de su contorno durante reacción. Fragmentos sí rodean al objetivo en f18/f20. Back f16/f20 sirve de referencia. Cotejar trayectoria, fase de contacto y anclaje OppMove; needs_targeted_review, RUNTIME_SUPPORTED. No declarar impacto totalmente ausente |
| guardian_of_alola / Cólera del Guardián | back y front | Último PNG f65: ambos cuerpos visibles, objetivo a opacidad 0,88235294 y usuario a 1. Leve transparencia residual antes de limpieza PASS. Contrastar fin de fuente/fase; needs_targeted_review, DATA_ONLY conservado. No es cuerpo desaparecido ni el caso de una celda extra oculta |
| hail / Granizo | back y front | Invocador/tinte sin precipitación persistente; PNG front f6 ampliado. Dependencia de clima YA conocida, requires_external_presentation, DATA_ONLY. El contexto LAB opcional existente está desactivado en este pipeline; no se ha perdido otro atlas ni se aprueba clima de combate |

**93 clips temporal_samples_checked / cinco needs_targeted_review / dos
requires_external_presentation**, **46 IDs sin fallo evidente / tres dudas / uno
de contexto**. Los 31 casos anteriores permanecen íntegros. Se guarda la duda leve
de opacidad de Cólera del Guardián sin convertirla en fallo técnico confirmado;
su objetivo está presente y la limpieza recupera exactamente el escenario base.
El puño dorado y la cortina de ese recurso usan el objetivo actual en las muestras,
no se ha confirmado un Tapu incrustado. El Mew de Supernova sí está dibujado en el
recurso; mantener su prioridad secundaria, como las insignias de otros exclusivos.

Ampliaciones observadas: Supernova Original back f50; Lanza Glacial ambos f16/f20
y front f17/f18; Cólera del Guardián back f30 y ambos finales f65; Granizo front f6;
Fortaleza front f5 y Desarrollo front f10. Fortaleza/Desarrollo no muestran otro
cuerpo en esas ampliaciones. La sospecha de Lanza Glacial se limita a trayectoria/
contacto, pues sus fragmentos finales sí están junto al objetivo.

**Decisiones y equivalentes previos intactos:** Martillo Colosal conserva su fuente
de 23 frames, compresión/esquirlas metálicas aceptadas, sin exigir ahora martillo
literal. Prensa Metálica conserva `Move:HEAVYSLAM` como equivalente explícito;
Infortunio `Move:SPITE`, con `native_gap_fixed=false`. No se cambia fórmula de daño,
clasificación, imágenes ni registro de sustituciones durante este barrido.

Acumulado **639/47/14 clips, 315/28/7 IDs**, ciento cuarenta páginas anotadas.
Los 175 registros previos permanecen íntegros; se añaden 27 entradas para separar
excepciones de vecinos en las páginas mixtas. Siete gates suman **22.278 frames /
120.835 checks GPU PASS**. Al cerrar el bloque 7 quedaban **550 IDs pendientes**,
antes del bloque 8 de debajo, más **35 casos acumulados** de contraste/contexto,
no 35 bugs probados.
Sin editar herramientas, renderer, arte, datasets, mecánicas, IA, tests o workflows.
Los 19 workflows del HEAD previo se volvieron a consultar: SUCCESS; no certifican
notas o evidencia local sin commit. Revisar primero el resto; corregir después.

### Bloque 8: observado y anotado — 2026-10-25

Resultado `batch_08_893feae099e0ac4f/result.json` bajo el mismo plan: **18.977
checks PASS / 3.746 frames GPU / 106 clips / 50 IDs**, de hidden_power a jet_punch.
Sus **53 familias y 22 láminas** se han observado completas, ambos lados y 16
momentos por vista. Las cuatro variantes de Garrote Liana añaden tres familias
al par base; no son seis IDs nuevos. Treinta y dos disparadores de transición
amplia, ninguno de secuencia completamente estática o cuerpo oculto/fundido al final.
Los avisos automáticos no sustituyen el contraste visual.

| ID / nombre | Vistas | Hallazgo y estado |
| --- | --- | --- |
| hydro_vortex_physical / Hidrovórtice Abisal físico | solo front | Transición de agua con rectángulos parciales: capa gris desde y104 en f3, franja azul inferior desde y267 en f7, ola en banda superior en f12. PNG nativos f3/f7/f12 y back f3 observados. Contrastar export OppMove, fases y transformación/capas; needs_targeted_review, DATA_ONLY intacto. No se atribuye aún a renderer ni se sustituye |
| hydro_vortex_special / Hidrovórtice Abisal especial | solo front | Mismo patrón de transición parcial en lámina; PNG nativo f7 también muestra franja inferior con borde horizontal. Se conserva su ID/clip independiente aunque comparta fuente con físico. needs_targeted_review, DATA_ONLY intacto. Back sin esa transición parcial evidente en las muestras |

**104 clips temporal_samples_checked / dos needs_targeted_review / cero nuevos
requires_external_presentation**, **48 IDs sin fallo evidente y dos dudas**. Los
35 casos anteriores permanecen íntegros. Los recortes de la lámina de Hidrovórtice
están también en PNG a 640×360; pendiente distinguir intención/fase de la fuente
de un defecto de transformación/capas. Los cuerpos vuelven visibles/opacos al
final y la limpieza pasa; no se confunde con una retirada sin presentación posterior.

Ampliaciones para descartar falsas alarmas: Cola Férrea ambos f4 muestran una
sola silueta blanca del usuario; la miniatura front no demuestra dos Charizard.
Defensa Férrea front f5 muestra una silueta dentro del resplandor; las celdas base
coinciden en posición/escala, sin un segundo contorno desfasado demostrado. Sellar
entra desde arriba, y los saltos/portales de Fuerza Equina, Patada Salto Alta,
Cerco Dimensión y Paso Dimensional salen y retornan en sus coreografías; no declarar
un fallo de cámara por cada salida transitoria. No se certifican mecánicas de
aliados, bloqueo, carga, estados o repetición por estos recursos.

Garrote Liana base/fuego/roca/agua: **ocho clips observados**, exports de Toxillian,
38 frames por clip. Se conservan proporciones/paletas y nombres de origen;
no activa máscaras ni conecta variantes nuevas a combate. Hipertaladro conserva
el ajuste de foco previo, sin una nueva sustitución. No se ha cambiado imagen,
renderer, herramienta, dato canónico, clasificación, test, workflow o mecánica.

Acumulado **743/49/14 clips, 363/30/7 IDs**, **162 páginas anotadas**. Los **202
registros previos** permanecen íntegros; 24 entradas nuevas separan las dos vistas
dudosas de sus vecinos. Ocho gates suman **26.024 frames / 139.812 checks GPU PASS**.
Al cerrar el bloque 8 quedaban **500 IDs pendientes**, antes del bloque 9 de debajo, más
**37 casos acumulados** de contraste/contexto, no 37 bugs confirmados. Los 19
workflows del mismo HEAD previo se consultaron otra vez: SUCCESS; no certifican
las notas/capturas locales sin commit. Continúa primero el barrido y después las
correcciones; no se vacía ni migra la cola.

### Bloque 9: observado y anotado — 2026-10-25

Resultado `batch_09_9714ca1f03cfdad5/result.json` bajo el mismo plan: **17.996
checks PASS / 3.427 frames GPU / 100 clips / 50 IDs**, de judgment a malicious_moonsault.
Veinte láminas observadas completas, ambos lados y 16 momentos por vista. Treinta
disparadores de transición amplia, ninguno de secuencia estática o cuerpo oculto/
fundido al acabar; no son treinta defectos. Las diferencias de duración de Patada
Salto, Última Baza y Hoja Aguda entre lados se conservan, sin igualarlas a la fuerza.

| ID / nombre | Vistas | Hallazgo y estado |
| --- | --- | --- |
| laser_focus / Aguzar | back y front | PNG f23: cuerpos base del mismo usuario opacos, uno con escala relativa 1,15x/0,70y y otro normal. Dos contornos superpuestos, especialmente alas en front. Cotejar grupo de objetivo propio; needs_targeted_review, DATA_ONLY intacto |
| lets_snuggle_forever / Somanta Amistosa | back y front | PNG f76: dibujo fijo de Mimikyu en lugar del usuario actual Ogerpon/Charizard. Duda artística secundaria para usuarios aleatorios; needs_targeted_review, RUNTIME_SUPPORTED intacto. Back f76 muestra además un trazo horizontal fino sobre la figura, cotejar capa/fase. No buscar reemplazo durante barrido |
| light_screen / Pantalla de Luz | solo front | PNG final f20: Ogerpon en (242,254,6), separado de su sombra en la plaza (145,666/230,350). Back f20 de referencia sin desplazamiento. Cotejar export OppMove/foco/cuerpos; needs_targeted_review, DATA_ONLY. Limpieza PASS, no cambio mecánico de posición |
| lunar_dance / Danza Lunar | back y front | PNG f9: cuerpo azul y cuerpo normal desfasados, celdas base opacas. Diferencia 5,625 px horizontal y 1,875 px vertical. Contrastar fuente/cuerpos/fase antes de borrar ecos; needs_targeted_review, DATA_ONLY. No certifica debilitamiento ni relevo |
| magic_coat / Capa Mágica | solo front | PNG f7: Charizard en su pantalla y otro junto a Ogerpon; celdas base front en (482,134,6) y (242,254,6). Back f7 sin copia extra. Candidato al grupo de objetivo propio/exports OppMove; needs_targeted_review, DATA_ONLY |
| magnet_rise / Levitón | back y front | PNG f14: cuerpo gris elevado y normal superpuestos, ambos visibles/opacos; celdas base separadas 18,75 px verticales. Contrastar grupo de objetivo propio, no aprobar levitación mecánica; needs_targeted_review, DATA_ONLY |

**90 clips temporal_samples_checked / diez needs_targeted_review / cero nuevos
requires_external_presentation**, **44 IDs sin fallo evidente y seis dudas**.
Los 37 casos previos permanecen íntegros. Aguzar/Danza Lunar/Levitón añaden indicios
al grupo de cuerpos propios superpuestos; Capa Mágica se parece a Barrera/Detección,
sin afirmar todavía que una reparación única resuelva todos. Somanta conserva
prioridad secundaria por su carácter exclusivo; no se declara bug de renderer
porque su dibujo represente otra especie. Ninguna imagen se ha sustituido.

Consulta adicional de los **estados ya capturados**: cuerpos base 0/1 del mismo
lado, visibles con opacidad >0,8, cuyas posiciones difieren >1 px o escalas >0,01.
Solo selecciona candidatos para ampliación; no cambia herramienta, generación,
muestreo ni contrato. Así se ampliaron Aguzar ambos f23, Danza Lunar ambos f9 y
Levitón ambos f14, comprobando el contorno visible antes de añadirlos. Mantener
los ecos deliberados de otras coreografías; no eliminar todas las copias.

Otras ampliaciones: Ciclón de Hojas front f22/f25 y back f22 no muestran segundo
cuerpo en la vista rival; la proximidad de miniaturas creó esa sospecha. Patada
Baja front f4/f5/f6 y back f5: pie junto/al borde del cuerpo y luego oculto por él,
sin confirmar separación como en Palmeo. Gota Vital ambos f6 conserva sus motivos
de agua/brillos; no se afirma cuerpo duplicado. Se vieron además Somanta ambos
f76, Pantalla de Luz ambos f20 y Capa Mágica ambos f7. Lengüetazo conserva su hoja
principal: solo se omite la dependencia rival ausente de opacidad siempre cero,
como ya estaba documentado. Resplandor conserva su fondo recuperado previo.

Acumulado **833/59/14 clips, 407/36/7 IDs**, **182 páginas anotadas**. Los **226
registros anteriores** permanecen íntegros; 30 entradas nuevas separan los diez
clips dudosos de sus vecinos. Nueve gates suman **29.451 frames / 157.808 checks
GPU PASS**. Al cerrar el bloque 9 quedaban **450 IDs pendientes**, antes del bloque
10 de debajo, más **43 casos acumulados** de contraste/contexto, no 43 bugs confirmados. Sin
editar herramientas, renderer, imágenes, datos, mecánicas, IA, tests o workflows.
Los 19 workflows del mismo HEAD previo se consultaron: SUCCESS; no certifican
las notas o evidencia local sin commit. Primero acabar el barrido, luego corregir.

### Bloque 10: observado y anotado — 2026-10-25

Resultado `batch_10_8a14891a453467f5/result.json` bajo el mismo plan: **19.756
checks PASS / 4.014 frames GPU / 100 clips / 50 IDs**, de malignant_chain a mist_ball.
Veinte láminas observadas completas, ambos lados y 16 momentos por vista. Cincuenta
y ocho disparadores de transición amplia y dos de cuerpo oculto/fundido al acabar;
ninguna secuencia estática. No son sesenta defectos. Los avisos de opacidad se
contrastan con los cuerpos principales, las celdas extra y el PNG nativo.

| ID / nombre | Vistas | Hallazgo y estado |
| --- | --- | --- |
| mat_block / Escudo Tatami | solo front | PNG f7: Ogerpon en (242,254,6), separado de sombra/plaza (145,666/230,350). Back f7 sin ese desplazamiento. Candidato al grupo OppMove de Pantalla de Luz; needs_targeted_review, DATA_ONLY intacto. No cambiar posiciones mecánicas por la imagen |
| max_geyser / Maxichorro | solo front | Equivalente HYDROVORTEX: PNG f7 con franja inferior rectangular; back f7 tiene ola/inundación continua. Mismo patrón de transición de Hidrovórtice Abisal físico/especial (lámina f3/f7/f12). Guardar ID propio y contrastar fuente/capas juntos; needs_targeted_review, PARTIAL_RUNTIME intacto. Causa no probada |
| meditate / Meditación | back y front | PNG f4: cuerpo normal y cuerpo aplastado debajo, ambos opacos. Celda base -1 desplazada +37,5 px vertical y a mitad de escala Y; -2 normal. Contrastar objetivo propio/coreografía con grupo de contornos dobles; needs_targeted_review, RUNTIME_SUPPORTED |
| minimize / Reducción | back y front | PNG f3: contorno múltiple durante encogimiento. Celdas base opacas a escalas relativas 0,82/0,77; celda extra 2 a escala 1 y opacidad 0,490196. Contrastar bases y eco antes de decidir si hay defecto; needs_targeted_review, DATA_ONLY. No borrar todo eco deliberado |

**94 clips temporal_samples_checked / seis needs_targeted_review / cero nuevos
requires_external_presentation**, **46 IDs sin fallo evidente y cuatro dudas**.
Los 43 casos previos se conservan. Maxichorro añade otro ID al grupo de HYDROVORTEX,
no otra fuente independiente; Escudo Tatami se parece a Pantalla de Luz. Eso orienta
el diagnóstico conjunto posterior, sin afirmar una reparación única ya probada.
Reducción necesita distinguir transición/eco deliberado de los cuerpos base: los
contornos múltiples no se convierten automáticamente en bugs.

Ampliaciones observadas: Escudo Tatami ambos f7; Maxichorro ambos f7; Meditación
ambos f4; Reducción ambos f3. Consulta de posiciones/escalas de celdas base del
mismo lado, ya capturadas, seleccionó esos dos últimos candidatos; no se modificó
la herramienta ni el plan para añadir otra aprobación automática.

Legado: ambos f0/f18/f24 ampliados y estados finales cotejados. Sus cuerpos base
siguen presentes, visibles y a opacidad 1; la celda extra 2 del objetivo acaba a
0,54902 y produce el aviso. El objetivo oscurecido no equivale a Pokémon ausente.
No añade contexto externo por ese disparador, ni se aprueba debilitamiento/relevo
mecánico del usuario. Asalto Estelar back f11 conserva el cuerpo completo; front
f23 muestra Charizard completo y al objetivo en salida transitoria. No se confirmó
el supuesto recorte del atacante sugerido por las miniaturas; retorno/limpieza PASS.

Los **19 Maxi/Dinamax conservan equivalentes explícitos**, no animaciones Max
nativas ni implementación de clima/estadísticas/Dinamax. Maxinsecto mantiene
SILVERWIND, front sintetizado declarado; no se restaura SAVAGESPINOUT histórico.
La caja psíquica de Maxionda y las salidas/retornos de otras secuencias se revisan
como coreografía. Cadena Virulenta conserva el foco corregido previo, sin nueva
sustitución ni reinterpretar sus cadenas horizontales como atlas roto.

Acumulado **927/65/14 clips, 453/40/7 IDs**, **202 páginas anotadas**. Los **256
registros previos** permanecen íntegros; 26 entradas nuevas separan los seis clips
dudosos de sus vecinos. Diez gates suman **33.465 frames / 177.564 checks GPU PASS**.
Al cerrar el bloque 10 quedaban **400 IDs pendientes**, antes del bloque 11 de debajo, más
**47 casos acumulados** de contraste/contexto, no 47 bugs confirmados. Ningún cambio
de herramientas, renderer, imágenes, datos, mecánicas, IA, tests o workflows.
Los 19 workflows del mismo HEAD previo se consultaron: SUCCESS; no certifican
las notas/capturas locales sin commit. Primero terminar el barrido y luego corregir.

### Bloque 11: observado y anotado — 2026-10-25

Resultado `batch_11_cd63d28ef7302e9e/result.json` bajo el mismo plan: **19.345
checks PASS / 3.866 frames GPU / 108 clips / 50 IDs**, de misty_explosion a petal_blizzard.
Sus **54 familias y 22 láminas** se observaron completas, ambos lados y 16 momentos
por vista. Adaptación incluye cinco contextos, diez clips: son cuatro familias
adicionales bajo un único ID, no cuatro movimientos nuevos. Cuarenta y dos avisos
de transición amplia y dos de cuerpo oculto/fundido al acabar, sin secuencia estática.
Los disparadores se contrastan con PNG y estados, no equivalen a defectos.

| ID / nombre | Vistas | Hallazgo y estado |
| --- | --- | --- |
| moonlight / Luz Lunar | back y front | PNG f15: dos cuerpos base del mismo usuario opacos separados 11,25 px verticales; doble contorno de patas/alas. Cotejar grupo de objetivo propio con Levitón/Danza Lunar; needs_targeted_review, PARTIAL_RUNTIME intacto. No habilita ni certifica curación |
| no_retreat / Bastión Final | back y front | PNG f9: cuerpo amarillo y normal superpuestos, celdas base opacas separadas 22,5 px horizontales, con distinto signo por lado. Contrastar fuente/foco/coreografía; needs_targeted_review, DATA_ONLY conservado |
| parting_shot / Última Palabra | back y front | PNG final f25: plaza del usuario vacía tras retirada, objetivo presente. Back usuario x=-116,834 oculto a opacidad 0,2; front usuario Charizard x707/y74,6 oculto. Necesita presentación del relevo, como Viraje; requires_external_presentation, DATA_ONLY. No es atlas roto ni soporte nuevo |

**102 clips temporal_samples_checked / cuatro needs_targeted_review / dos
requires_external_presentation**, **47 IDs sin fallo evidente, dos dudas y uno
de contexto**. Los 47 casos anteriores permanecen íntegros. Las dos dudas de
contornos se guardan para diagnóstico conjunto, sin afirmar reparación común
ni borrar ecos deliberados. Última Palabra añade otra necesidad de relevo en esta
fase; no modifica retroactivamente los seis contextos del registro inicial.

Ampliaciones observadas: Luz Lunar ambos f15; Bastión Final ambos f9; Última
Palabra ambos f25; Pesadilla ambos f9; Rayo Umbrío front f15; Ala Mortífera back
f18; Agua Lodosa front f14. Consulta de estados de celdas base del mismo lado
seleccionó Luz Lunar/Bastión Final, confirmados después en imagen nativa. No se
ha cambiado herramienta, generación o muestreo para convertir esa pista en diagnóstico.

Pesadilla conserva **dos celdas extra 2/3 del objetivo**, a ±90 px en f9, además
del cuerpo central; su usuario se oculta durante esa coreografía y las bases
vuelven visibles/opacas al final. No se añade a contornos dobles de objetivo propio
ni a retiradas pendientes de relevo. Presa Espectral físico/especial conserva
sus franjas/cadenas cinematográficas originales: su descarte como equivalente
genérico de Maxiespectro no elimina estos dos IDs Z ni prueba un atlas roto.
Agua Lodosa entra desde arriba en la vista rival; no agrupar cualquier borde de
ola con los saltos de capas de HYDROVORTEX sin contrastar sus fases.

Adaptación mantiene las cinco referencias manuales: **TRIATTACK, THUNDERBOLT,
ENERGYBALL, MOONBLAST y PSYCHIC**. No se activa detección automática del entorno,
otra clasificación ni otro enlace de combate. Rayo Umbrío y Ala Mortífera conservan
sus correcciones previas de geometría y dibujos originales; las muestras nativas
mantienen haces continuos. Octopresa/Amplificador conservan sus tonos nativos.
No hay nuevas sustituciones ni cambios en el registro artístico.

Acumulado **1.029/69/16 clips, 500/42/8 IDs**, **224 páginas anotadas**. Los **282
registros anteriores** permanecen íntegros; 28 entradas nuevas separan los seis
clips señalados de sus vecinos. Once gates suman **37.331 frames / 196.909 checks
GPU PASS**. Al cerrar el bloque 11 quedaban **350 IDs pendientes**, antes del
bloque 12 documentado debajo, petal_dance a purify,
más **50 casos acumulados** de contraste/contexto, no 50 bugs confirmados.
Sin modificar herramientas, renderer, imágenes, datos, mecánicas, IA, tests o
workflows. Los 19 workflows del mismo HEAD previo se consultaron: SUCCESS; no
certifican estas notas/capturas locales sin commit. Primero acabar el barrido,
después las correcciones, conservando la cola y su evidencia.

### Bloque 12: observado y anotado — 2026-10-25

Resultado `batch_12_a63b37636b784d0e/result.json` bajo el mismo plan: **16.630
checks PASS / 2.972 frames GPU / 100 clips / 50 IDs**, de petal_dance a purify.
Sus **50 familias y 20 láminas** se observaron completas, ambos lados, 16 momentos
por vista. Veintidós avisos de transición amplia, ninguno de final oculto/fundido
ni de secuencia estática. Los avisos automáticos no equivalen a fallos.

| ID / nombre | Vistas | Hallazgo y estado |
| --- | --- | --- |
| poison_sting / Picotazo Veneno | solo front | PNG f14: burbujas moradas a la derecha de Ogerpon, cerca de x242 frente a cuerpo en x145; back rodea Charizard. Cotejar foco/anclaje/fase OppMove como Palmeo/Agarrón; needs_targeted_review, RUNTIME_SUPPORTED intacto |
| poison_tail / Cola Veneno | solo front | PNG f13: motas moradas concentradas a la derecha del objetivo; back sobre el cuerpo. Mismo grupo de contraste posible, ID separado; needs_targeted_review, RUNTIME_SUPPORTED intacto |
| pollen_puff / Bola de Polen | solo front | PNG f17: el proyectil pequeño sí llega al borde superior de Ogerpon. Explosión f19/f21 a su derecha cerca de x242, mientras back f21 se centra en Charizard. Limitar duda a explosión; conservar duraciones 40 back / 30 front. needs_targeted_review, RUNTIME_SUPPORTED intacto |
| power_whip / Latigazo | solo front | PNG f6: Ogerpon rojizo retrocede hacia x90, látigo verde lejos a la derecha cerca de x300; back junto a Charizard. Cotejar fase de reacción/anclaje sin cambiar mecánicas; needs_targeted_review, RUNTIME_SUPPORTED intacto |
| power_trick / Truco Fuerza | back y front | PNG f7: cuerpo normal y azul ancho/aplastado superpuestos, dos celdas base del mismo lado visibles/opacas en la misma posición. Escala relativa 1,45 X / 0,70 Y. Diagnóstico conjunto de objetivos propios, sin borrar ecos deliberados; needs_targeted_review, DATA_ONLY intacto |

**94 clips temporal_samples_checked / seis needs_targeted_review / cero
requires_external_presentation**, **45 IDs sin fallo evidente y cinco dudas**.
Los 50 casos anteriores permanecen íntegros. No se ha reparado ni sustituido
ningún dibujo para cerrar la cola; las coincidencias de síntoma no prueban causa común.

Ampliaciones observadas: Picotazo Veneno ambos f14, Cola Veneno ambos f13,
Bola de Polen front f17/f19/f21 y back f17/f21, Latigazo ambos f6, Truco Fuerza
ambos f7, Proliferación ambos f7/f22 y Géiser Fotónico back f33. Todas las láminas
y estas ampliaciones se observaron antes de registrar sus conclusiones.

**Proliferación no es un caso de impacto ausente**: las miniaturas mostraban
principalmente carga blanca/chispas sobre el usuario. Consultar estados del
objetivo encontró reacción f21–f23, máximo 7,5 px Y en f22, retorno f24. Ese PNG
nativo ambos lados muestra impacto amarillo sobre el objetivo, entre los 16
tiempos seleccionados. No añadir a la cola ni certificar número/repetición de golpes.

Géiser Fotónico usa su motivo nativo de púas blancas/negras del suelo; el f33
no representa un nuevo dibujo defectuoso del Pokémon. Su descarte histórico
como sustituto de Láser Prisma no elimina el movimiento nativo. Láser Prisma
mantiene **PSYBEAM como equivalente explícito, native_gap_fixed=false**;
Psicorrayo conserva ID separado y también se revisó. Poltergeist/Asalto Barrera
conservan tonos previos. Golpe Fantasma mantiene su desaparición/retorno de fuente.
Arrojo Intempestivo usa los actores actuales en las muestras, sin Snorlax fijo
confirmado; no inventar una deuda por la especie del movimiento original.

Acumulado **1.123/75/16 clips, 545/47/8 IDs**, **244 páginas anotadas**. Los **310
registros anteriores** permanecen idénticos; 26 entradas nuevas separan los seis
clips señalados de sus vecinos: **336 entradas**. Doce gates suman **40.303 frames /
213.539 checks GPU PASS**. Al cerrar el bloque 12 quedaban **300 IDs pendientes**, pursuit
a safeguard, más **55 casos acumulados** de contraste/contexto, no 55 bugs probados.
Renderer, herramientas, sprites, datos, clasificaciones, cinco rutas reales,
mecánicas, IA, tests y workflows intactos. Los 19 checks del mismo HEAD previo
se consultaron: SUCCESS; no certifican las notas locales sin commit.

### Comprobación de continuidad tras corte de contexto, cierre del bloque 12 — 2026-10-25

Al cerrar el bloque 12, inspeccionadas todas las carpetas de la generación: **solo bloques
1–12**, cada uno con reporte GPU PASS, membresía exacta del plan y `sheets/boards.json`.
Los SHA de los 244 PNG de lámina, reportes y entradas son coherentes; cobertura
exacta de los 1.214 clips / 600 IDs, sin página sin registrar ni clip fuera del plan.
Los 336 registros mantienen mechanics_approved=false y realtime_motion_watched=false.
El prefijo de 310 entradas conserva SHA
`e2dd7717cb3bff56c40521721099904d279140504b50d66dd588e7a28c02ba68`.
La validación focal del bloque 12 comprueba además todos sus PNG de frames,
fuentes, reloj y limpieza. Fuentes congeladas, datos, rama y HEAD no cambiaron.

No quedó un lote generado a medias ni una captura producida sin revisión registrada.
El bloque 12 ya tenía sus 26 entradas al recuperar el trabajo; faltaba actualizar
los tres documentos de estado/continuación/cuaderno, completado ahora. Los bloques
13–18 (300 IDs) eran trabajo futuro previsto; los 55 casos guardados esperaban el
final del barrido. No se presenta esta auditoría documental como nueva observación
a velocidad real ni como nueva certificación de mecánicas.

### Bloque 13: observado y anotado — 2026-10-25

Resultado `batch_13_7278a2576c29cd40/result.json` bajo el mismo plan: **16.151
checks PASS / 2.812 frames GPU / 100 clips / 50 IDs**, de pursuit a safeguard.
Sus **50 familias y 20 láminas** se observaron completas, ambos lados y 16 momentos
por vista. Once avisos de transición amplia, uno de final oculto/fundido
(Rugido back) y ninguna secuencia estática. Rugido front demuestra que la bandera
visible/opaca no garantiza que el cuerpo permanezca dentro de pantalla.

| ID / nombre | Vistas | Hallazgo y estado |
| --- | --- | --- |
| quick_guard / Anticipo | solo front | PNG f12: Ogerpon en (242,254,6), sombra/plaza en (145,666/230,350); back conserva cuerpo/sombra. Cotejar OppMove/foco como Pantalla de Luz/Escudo Tatami; needs_targeted_review, DATA_ONLY intacto |
| quiver_dance / Danza Aleteo | back y front | PNG f3: dos cuerpos base propios opacos, separados 30 px verticales y 3,75 px horizontales. Contraste de fuente/coreografía junto a otros contornos dobles; needs_targeted_review, RUNTIME_SUPPORTED intacto |
| rage_powder / Polvo Ira | back y front | PNG f13: cuerpo rojo elevado y normal superpuestos, dos bases opacas del mismo lado separadas 15 px verticales. No borrar ecos globalmente ni habilitar redirección; needs_targeted_review, DATA_ONLY intacto |
| reflect / Reflejo | solo front | PNG f16: Ogerpon desplazado a (242,254,6), separado de sombra en plaza. Back de referencia sin ese desplazamiento. Candidato al mismo diagnóstico de Anticipo, causa común sin demostrar; needs_targeted_review, DATA_ONLY intacto |
| rock_climb / Treparrocas | back y front | PNG f20: usuario Ogerpon en (580,666/5,350), recortado por arriba en back; Charizard en (62/337,1), recortado abajo/izquierda en front. Retorno final presente. Contrastar recorrido/encuadre de fuente antes de modificar cámara; needs_targeted_review, RUNTIME_SUPPORTED intacto |
| rock_polish / Pulimento | back y front | PNG f12: doble contorno de cabeza/alas, dos bases propias opacas separadas 7,5 px verticales. Grupo de objetivo propio; needs_targeted_review, RUNTIME_SUPPORTED intacto |
| rain_dance / Danza Lluvia | back y front | Láminas y PNG f7 muestran gesto corporal, fuente RAINDANCE sin partículas opacas de lluvia. Conserva presentación externa conocida de clima; requires_external_presentation, DATA_ONLY. No es nuevo atlas roto ni clima habilitado |
| roar / Rugido | back y front | PNG final f20: objetivo expulsado y plaza vacía. Back x624,5, oculto/opacidad 0,19608; front Ogerpon x−64,334 fuera de pantalla aunque visible/opaco. Necesita entrada posterior a expulsión, como Cola Dragón/Llave Giro; requires_external_presentation, DATA_ONLY intacto |

**86 clips temporal_samples_checked / diez needs_targeted_review / cuatro
requires_external_presentation**, **42 IDs sin fallo evidente, seis dudas y dos
de contexto**. Los 55 casos anteriores permanecen íntegros; son ahora 63 IDs
para contraste/contexto, no 63 fallos confirmados ni 63 causas diferentes.

Ampliaciones observadas: Anticipo ambos f12; Reflejo ambos f16; Danza Aleteo
ambos f3; Polvo Ira ambos f13; Pulimento ambos f12; Treparrocas ambos f20;
Giro Rápido ambos f13/f18; Golpe Roca ambos f3/f5/f6 y front f7; Rugido ambos
f20; Danza Lluvia ambos f7. Consulta de estados guio selección y medidas,
seguida de observación real de los PNG; no se añadieron diagnósticos automáticos.

**Golpe Roca no añade deuda de impacto ausente**: front f3 muestra puño separado,
pero f5/f6 se aproxima y f7 lo superpone a la roca/objetivo. Back f3/f5/f6 sirve
de contraste. No registrar un fotograma de aproximación como impacto final roto.
Giro Rápido f13/f18 dibuja dos arcos abiertos que se separan en ambas vistas,
sin recortar el cuerpo. No agruparlos con franjas rectangulares de HYDROVORTEX.
Imitación conserva la silueta del objetivo proyectada al usuario como coreografía;
Rodar cambia temporalmente a esfera y retorna. Fertilizante conserva franjas de
suelo de fuente. Estos efectos no certifican habilidad, persistencia o terreno.

Canto Arcaico conserva fondo de mosaico/notas; Represalia su cuadrícula roja;
Fuego Sagrado sus llamas multicolores. No sustituir arte solo por geometría o
color de fuente. Plegaria Vital no habilita resurrección, ni esta revisión
certifica curación, sueño, fórmula de daño, aprendizaje o nuevos enlaces de combate.

Acumulado **1.209/85/20 clips, 587/53/10 IDs**, **264 páginas anotadas**. Los **336
registros anteriores** conservan SHA
`5905b14ef77532b909e77037c2109f6e43ff27a455f79c01944a2f6109bc5234`;
34 entradas nuevas separan los 14 clips señalados: **370 entradas**. Trece gates
suman **43.115 frames / 229.690 checks GPU PASS**. Al cerrar el bloque 13 quedaban
**250 IDs pendientes**, salt_cure a sky_attack, más los 63 casos guardados.
Fuentes, plan, renderer, herramientas, sprites, datos, clasificaciones, cinco
rutas reales, mecánicas, IA, tests y workflows intactos. Los 19 workflows del
HEAD previo se consultaron: SUCCESS, sin certificar estas notas locales.
Sin nuevas sustituciones, commit, push o merge. Primero terminar barrido.

### Bloque 14: observado y anotado — 2026-10-25

Resultado `batch_14_ec10470a5f9268c2/result.json` bajo el mismo plan: **18.772
checks PASS / 3.675 frames GPU / 108 clips / 50 IDs**, de salt_cure a sky_attack.
Sus **54 familias y 22 láminas** se observaron completas, ambos lados y 16 momentos
por vista. Daño Secreto aporta cinco referencias manuales bajo el mismo ID, diez
clips; no son cinco movimientos nuevos. Treinta y ocho avisos de transición amplia,
dos de final oculto/fundido (referencia psíquica), ninguna secuencia estática.

| ID / nombre | Vistas | Hallazgo y estado |
| --- | --- | --- |
| scary_face / Cara Susto | solo front | PNG f9: centro de ojos/boca cerca de x265, lateral a Ogerpon en x145; back centrado sobre Charizard. Cotejar anclaje/foco OppMove, sin afirmar impacto ausente; needs_targeted_review, RUNTIME_SUPPORTED intacto |
| shadow_sneak / Sombra Vil | solo front | PNG f20: óvalo cerca de x242 a la derecha del cuerpo x145, destello lateral cerca de x202; back sombra bajo Charizard y destello en cuerpo. Contrastar fase/anclaje, no impacto totalmente ausente; needs_targeted_review, RUNTIME_SUPPORTED intacto |
| sharpen / Afilar | back y front | PNG f2: dos bases propias opacas en misma posición y escalas relativas 0,75/1; front muestra doble contorno de alas/cola junto al cubo azul. Diagnóstico conjunto de objetivo propio, sin sustituir cubo o borrar ecos deliberados; needs_targeted_review, RUNTIME_SUPPORTED intacto |
| savage_spin_out_physical / Guadaña Sedosa físico | back y front | PNG f32: Scizor/Joltik y otras especies fijas alrededor del capullo, distintas de actores actuales. Duda artística secundaria para usuarios aleatorios, mismo motivo histórico de descarte como equivalente Maxinsecto; needs_targeted_review, DATA_ONLY intacto |
| savage_spin_out_special / Guadaña Sedosa especial | back y front | Lámina y PNG f32 propios confirman el mismo arte incrustado; conservar ID separado. Duda de idoneidad, no fallo técnico probado ni sustitución ahora; needs_targeted_review, DATA_ONLY intacto |
| sandstorm / Tormenta de Arena | back y front | Remolino dorado local en usuario y retorno al escenario inicial; presentación externa/persistente de clima ya conocida. requires_external_presentation, DATA_ONLY; no atlas vacío ni clima habilitado |
| shed_tail | back y front | PNG f14: muñeco sustituto superpuesto al usuario; final f19 cuerpos presentes/opacos, no usuario perdido. Necesita presentar sustituto persistente y relevo en contexto; requires_external_presentation, DATA_ONLY. Se conserva ID/título del catálogo, sin editar datos |

**96 clips temporal_samples_checked / ocho needs_targeted_review / cuatro
requires_external_presentation**, **43 IDs sin fallo evidente, cinco dudas y dos
de contexto**. Los 63 casos anteriores permanecen íntegros. Ahora 70 IDs guardados,
no 70 bugs probados ni 70 causas distintas. No buscar reemplazos de arte durante el barrido.

Ampliaciones observadas: Cara Susto ambos f9; Guadaña Sedosa físico y especial
ambos f32; Arañazo ambos f3; Afilar ambos f2; Sombra Vil ambos f20; shed_tail ambos
f14; Simún de Arena ambos f16. Estados de cuerpos completan medidas/visibilidad;
las conclusiones se registraron después de observar los PNG, no solo por disparadores.

**Daño Secreto conserva sus cinco referencias manuales**: BODYSLAM, THUNDERSHOCK,
VINEWHIP, FAIRYWIND y CONFUSION. Todas las vistas de la página 4 se observaron.
En la referencia psíquica final f28 los dos cuerpos base están presentes/opacos;
solo la celda extra 2 termina oculta con opacidad 0,2. No añadir una falsa
desaparición a la cola. PARTIAL_RUNTIME intacto, sin selector automático del entorno
ni nuevos efectos ambientales. Los otros diez clips manuales de Adaptación ya
documentados en bloque 11 no se sustituyen ni se deduplican por estas referencias.

Arañazo f3 sí dibuja trazos amarillos sobre ambos objetivos: poco visibles en
miniatura back por tamaño/color, no ausencia de recurso. Simún f16 desplaza su
remolino a la izquierda del cuerpo en ambas vistas: no añadir un desfase unilateral
por ese momento aislado. Chirrido conserva 26/28 frames y Sísmico 67/66 back/front;
no igualar duraciones para aprobar muestras. Golpe Umbrío conserva desaparición
inicial y retorno de fuente. Golpe Rastrero usa un eco oscuro del actor que ataca;
no retirarlo por parecido con cuerpos base duplicados en efectos propios.

Disruptor Psíquico físico/especial conserva el cubo de atlas original y la escala
uniforme corregida previamente; no nueva sustitución. Viento Plata mantiene la
fuente y su referencia rival declarada; Maxinsecto continúa usando SILVERWIND.
El descarte histórico de SAVAGESPINOUT como equivalente Max no elimina sus dos
recursos Z nativos: se anotan para idoneidad final, baja prioridad. Se conservan
portal/cilindro de Embestida Solar, flash de Bomba Ígnea y caparazones de fuente,
sin convertir geometrías observadas en errores automáticos ni aprobar sus mecánicas.

Acumulado **1.305/93/24 clips, 630/58/12 IDs**, **286 páginas anotadas**. Los **370
registros anteriores** conservan SHA
`a67188fce6d0387e1b47d25610563209c3f4049c4b80deac57889b35d7ff95f8`;
34 entradas nuevas separan los doce clips señalados: **404 entradas**. Catorce gates
suman **46.790 frames / 248.462 checks GPU PASS**. Al cerrar el bloque 14 quedaban
**200 IDs pendientes**, sky_drop a steamroller, más los 70 casos guardados.
Entonces todos los bloques generados 1–14 tenían reporte/láminas/registro completo;
15–18 eran trabajo futuro previsto. Fuentes, plan, renderer, herramientas, sprites, datos,
clasificaciones, cinco rutas reales, mecánicas, IA, tests y workflows intactos.
Los 19 workflows del mismo HEAD previo se consultaron: SUCCESS, sin certificar
estas notas locales. Sin sustituciones nuevas, commit, push o merge.

### Bloque 15: observado y anotado — 2026-10-25

Resultado `batch_15_cd00d3a51c3f0d2b/result.json` bajo el mismo plan: **17.374
checks PASS / 3.220 frames GPU / 100 clips / 50 IDs**, de sky_drop a steamroller.
Sus **50 familias y 20 láminas** se observaron completas, ambos lados y 16 momentos
por vista. Veintiséis avisos de transición amplia, ninguno de final oculto/fundido
ni de secuencia estática. No equivalen a 26 fallos ni descartan cuerpos recortados
durante una fase intermedia.

| ID / nombre | Vistas | Hallazgo y estado |
| --- | --- | --- |
| slack_off / Relajo | back y front | PNG f8: dos bases propias opacas. Back ambas aplastadas al 70% Y y separadas solo 1,875 px; front cuerpo normal y aplastado al 70% Y separados 16,875 px. Cotejar fuente/cuerpos sin igualar geometría de lados; needs_targeted_review, RUNTIME_SUPPORTED intacto |
| snatch / Robo | back y front | PNG f4: dos bases propias opacas coincidentes a escalas relativas 0,8/1, contorno oscuro de patas/alas/cola superpuesto. Grupo de contraste de objetivo propio, sin borrar ecos globalmente; needs_targeted_review, DATA_ONLY intacto |
| splash / Salpicadura | back y front | PNG f3: dos bases propias opacas coincidentes, escalas relativas (1/0,75) y (1,15/0,60), distinta anchura y doble contorno de siluetas aplastadas. Conservar gotas y cotejar coreografía; needs_targeted_review, DATA_ONLY intacto |
| sludge / Residuos | solo front | PNG f16: tres burbujas violetas alrededor de x242 a la derecha de Ogerpon x145; back rodea Charizard. Limitar duda a fase de burbujas/anclaje OppMove, no proyectil ausente; needs_targeted_review, RUNTIME_SUPPORTED intacto |
| sludge_wave / Onda Tóxica | solo front | PNG f14: masa de ola desde borde superior con cresta hacia abajo, frente a masa desde abajo/cresta hacia arriba en back. Cotejar orientación/capas con fuente OppMove antes de decidir cambio; needs_targeted_review, RUNTIME_SUPPORTED intacto. No afirmar causa del renderer ni equipararla automáticamente a HYDROVORTEX |
| soul_stealing_7_star_strike / Constelación Robaalmas | back y front | PNG f48/f50: usuario recortado, Ogerpon en (629,146/72,512) por derecha en back; Charizard en (−1,480/292,438) por izquierda/abajo en front. Posiciones fijas f48–51 durante impacto, objetivo iluminado presente y retorno final f90. Contrastar recorrido/encuadre cinematográfico; needs_targeted_review, RUNTIME_SUPPORTED intacto |
| snowscape / Paisaje Nevado | back y front | Tono frío del usuario y retorno en 13 frames, sin resolver nieve/clima persistente. Conserva contexto externo ya conocido, no atlas roto nuevo; requires_external_presentation, DATA_ONLY intacto |

**88 clips temporal_samples_checked / diez needs_targeted_review / dos
requires_external_presentation**, **43 IDs sin fallo evidente, seis dudas y uno
de contexto**. Los 70 casos anteriores permanecen íntegros: **77 IDs guardados**,
no 77 bugs confirmados ni 77 causas diferentes. Ninguna corrección o sustitución
artística aplicada durante el barrido.

Ampliaciones observadas: Relajo ambos f8; Robo ambos f4; Salpicadura ambos f3;
Residuos ambos f16; Onda Tóxica ambos f14; Constelación Robaalmas ambos f48/f50;
Chorro de Vapor ambos f46/f60. La consulta de estados confirmó posición/escala de
bases y pausa del usuario de Constelación en borde f48–51. No confundir ese caso
con cuerpos ausentes definitivamente: ambas plazas se restauran al final.

**Chorro de Vapor no se anota como impacto totalmente ausente**: el f46 muestra
el chorro entre los combatientes; f60 aporta estallido y reacción rojiza del
objetivo en ambos lados. No certificar contacto mecánico por ese tintado ni
afirmar que todo el estallido esté centrado en el cuerpo. Se conservan sus
74/77 frames back/front. La muestra tardía evita inferir ausencia por una fase
intermedia, como la comprobación de Proliferación del bloque 12.

Caída Libre conserva entrada aérea/descenso/retorno de fuente; las fases fuera
de pantalla no prueban por sí solas una retirada pendiente de relevo. Cuerno
Certero conserva ecos deliberados de movimiento; Barrera Espinosa y Quemarrueda
usan esfera/rueda temporal y vuelven al cuerpo. Cuchilla Solar mantiene su
geometría previa sin sustituir dibujos; una punta de partícula fuera de encuadre
no se registra como cuerpo recortado. Robasombra conserva ocultación/sombras/retorno.
Sonámbulo sigue UNSUPPORTED: ver sus letras de sueño no ejecuta un movimiento
delegado. Púas/Trampa Rocas no aprueban persistencia de trampas ni nueva mecánica;
Púas conserva 30/31 frames. No habilitar clima, curación, movimiento Z o robo de estadísticas.

Acumulado **1.393/103/26 clips, 673/64/13 IDs**, **306 páginas anotadas**. Los **404
registros anteriores** conservan SHA
`82e7f7a0f023aff5eb353006ad85404030772b7c1c6c22be84528d8a36072981`;
32 entradas nuevas separan los doce clips señalados: **436 entradas**. Quince gates
suman **50.010 frames / 265.836 checks GPU PASS**. Al cerrar el bloque 15 quedaban
**150 IDs pendientes**, steel_beam a tail_whip, más los 77 casos guardados.
Entonces todos los bloques generados 1–15 tenían reporte/láminas/registro completo;
16–18 eran trabajo futuro previsto. Fuentes, plan, renderer, herramientas, sprites,
datos, clasificaciones, cinco rutas reales, mecánicas, IA, tests y workflows intactos.
Los 19 workflows del mismo HEAD previo se consultaron: SUCCESS, sin certificar
estas notas locales. Sin sustituciones nuevas, commit, push o merge.

### Bloque 16: observado y anotado — 2026-10-25

Resultado `batch_16_04b20632f90276f1/result.json` bajo el mismo plan: **17.021
checks PASS / 3.102 frames GPU / 100 clips / 50 IDs**, de steel_beam a tail_whip.
Sus **50 familias y 20 láminas** se observaron completas, ambos lados y 16 momentos
por vista. Once avisos de transición amplia, ninguno de final oculto/fundido
ni de secuencia estática. Las alertas no prueban un fallo y su ausencia no descarta
el recorte de una fase intermedia.

| ID / nombre | Vistas | Hallazgo y estado |
| --- | --- | --- |
| storm_throw / Llave Corsé | back y front | PNG f20: objetivo Charizard en (655,422/80,741) recortado por derecha en back; Ogerpon en (−27,756/284,209), por izquierda/abajo en front. Trayectoria f18–22 llega a x713,229 / −85,563 en f19 y vuelve a plaza f23, final f25 presente/opaco. Contrastar encuadre/coreografía del lanzamiento; needs_targeted_review, RUNTIME_SUPPORTED intacto. No expulsión definitiva ni relevo externo |
| surf / Surf | solo front | PNG f14: masa desde borde superior con cresta hacia abajo; back masa inferior/cresta hacia arriba. Grupo de contraste de orientación/capas OppMove con Onda Tóxica, sin causa común ni defecto HYDROVORTEX probados; needs_targeted_review, RUNTIME_SUPPORTED intacto |
| substitute / Sustituto | back y front | PNG f5 sí muestra muñeco encima del usuario; f13 termina con cuerpos base presentes/opacos sin muñeco persistente. Conserva transición/persistencia externa pendiente, no textura ausente ni secuencia vacía; requires_external_presentation, DATA_ONLY intacto |

**95 clips temporal_samples_checked / tres needs_targeted_review / dos
requires_external_presentation**, **47 IDs sin fallo evidente, dos dudas y uno
de contexto**. Los 77 casos anteriores permanecen íntegros: **80 IDs guardados**,
no 80 bugs confirmados ni 80 causas distintas. Sin reparaciones durante el barrido.

Ampliaciones observadas: Tragar ambos f15/f16; Llave Corsé ambos f20; Día Soleado
ambos f8; Surf ambos f14; Sustituto ambos f5/f13; Plumerazo ambos f3. Estados de
cuerpos confirman recorrido de Llave Corsé y el retorno; no se infiere retirada
permanente por una salida temporal. Son dudas de presentación, no fallo del gate GPU.

**Día Soleado no añade una duda por capa invisible en esta generación**. PNG f8
muestra pulso amarillo en ambos lados. El contrato vigente de `PRAS- Sunny Day BG.png`
sube de opacidad 0 en f0 a 200 en f10/f11 y vuelve a 0 en f19; las láminas muestran
entrada y salida del brillo. La antigua anotación de opacidad cero/timings describe
evidencia histórica y no se reproduce aquí. No se ha reparado ni regenerado código,
renderer, catálogo o fuente en este tramo. DATA_ONLY intacto, sin activar clima
persistente ni certificar reglas por observar una iluminación.

**Tragar tampoco añade un falso positivo de doble silueta**: dos bases propias
tienen diferencia mínima en Y relativa 1,20/1,19 en f15, pero los PNG f15/f16 de
ambos lados muestran una silueta aparente sin doble contorno claro. El disparador
numérico es pista, no diagnóstico; no se suma por una desigualdad de floats.
Plumerazo f3 sí contiene trazo gris fino sobre ambos objetivos, discreto en miniatura;
no declarar un atlas ausente por tamaño/color. Sustituto sí dibuja el muñeco durante
el clip, por lo que no se arrastra como ausencia completa de recurso.

Picado Supersónico físico/especial mantiene **SKYATTACK como equivalente explícito**,
ambos lados observados y ambos IDs separados. Su hueco Z original sigue abierto;
el descarte de SUPERSONICSKYSTRIKE como referencia Maxiciclón no lo repara ni cambia
HURRICANE de Maxiciclón. Crioaliento Despiadado físico/especial también conserva IDs
separados. Surfeo Galvánico usa actores actuales en las muestras, sin Raichu fijo
confirmado; entradas/salidas aéreas no se convierten por sí solas en fallo. Allanador
Férreo conserva rueda temporal y retorno. Red Viscosa no certifica trampas persistentes;
Atiborramiento no consumo de baya; Metaláser no recoil; Tragar/Fotosíntesis no curación.
Supersónico conserva 26/28 frames back/front, sin igualar lados para aprobarlos.

Acumulado **1.488/106/28 clips, 720/66/14 IDs**, **326 páginas anotadas**. Los **436
registros anteriores** conservan SHA
`06e2219a94f2ab20205d3c5dce8f0a003fa370ff6da642f9fb9f4b1effd58874`;
25 entradas nuevas separan los cinco clips señalados: **461 entradas**. Dieciséis gates
suman **53.112 frames / 282.857 checks GPU PASS**. Siguiente bloque 17:
**100 IDs pendientes**, tailwind a trop_kick, más los 80 casos guardados.
Todos los bloques generados 1–16 tienen reporte/láminas/registro completo; 17–18
son trabajo futuro previsto. Fuentes, plan, renderer, herramientas, sprites, datos,
clasificaciones, cinco rutas reales, mecánicas, IA, tests y workflows intactos.
Los 19 workflows del mismo HEAD previo se consultaron: SUCCESS, sin certificar
estas notas locales. Sin sustituciones nuevas, commit, push o merge.

### Bloque 17: observado y anotado — 2026-10-25

Evidencia: `batch_17_646e014ce71e52f7/result.json` y `sheets/boards.json`, bajo
la misma generación. **50 IDs / 100 clips / 20 láminas**, tailwind a trop_kick;
**3.469 frames / 18.121 checks GPU PASS**, sin fallos técnicos. Todas las láminas
observadas, 16 muestras por vista; ampliaciones nativas de las dudas, sin afirmar
película vista a velocidad real ni mecánicas aprobadas. Resultado: **45 IDs sin
fallo evidente, tres pendientes de contraste y dos de contexto**; **91/5/4 clips**.

Casos guardados para después del barrido:

- **Limpieza General, ambos lados:** PNG nativo f2 muestra doble contorno del
  usuario, claro en cabeza/alas de Charizard y perfil/piernas de Ogerpon. Bases
  0/1 propias opacas, misma escala, separación vertical de 7,5 px f0–6. Contrastar
  con otros objetivos propios; no borrar ecos intencionales globalmente.
- **Relámpago Súbito, front:** PNG f9 deja destello amarillo separado, a la derecha
  de Ogerpon; back f9 sí lo superpone a Charizard. Cotejar ancla/export OppMove y
  fases antes de diagnóstico; no afirmar ausencia de todo el impacto.
- **Derribo, ambos lados:** PNG back f8 recorta casi todo Ogerpon por arriba
  (y −32,15); front f9 recorta Charizard abajo/izquierda (x54,5/y304,29). Hay
  embestida, giro del objetivo y retorno final f19. Contrastar encuadre/coreografía
  antes de declarar defecto; no es una expulsión definitiva.
- **Teletransporte, ambos lados:** final f20 ampliado conserva usuario visible.
  Base0 oculta/opacidad 0,12549, base1 propia opaca en la misma plaza. El aviso
  automático no demuestra desaparición total. Contexto de retirada/relevo y
  control del cuerpo pendientes; DATA_ONLY intacto.
- **Transformación, ambos lados:** blanco f7–11 y retorno a la misma especie
  f12–14. Necesita sustitución externa de apariencia, no atlas ausente ni nueva
  especie aprobada. UNSUPPORTED intacto; contexto ya conocido conservado.

Los 28 avisos de transición grande son pistas, no fallos por sí mismos. El abismo
de Barrena Telúrica no es cuerpo deformado; ave de Canto Ardiente y pie de Patada
Relámpago no prueban especies fijas incrustadas. Triple Patada tiene siete frames,
todos mostrados; no se certifica multigolpe. El salto transitorio de Patada Tropical
no demuestra recorte mantenido. Teraexplosión conserva variante única TECHNOBLAST;
no habilita 19 tipos ni mecánicas Tera. No aprobar clima, objetos, trampas o turnos
por sus presentaciones. Sin nueva sustitución artística.

Acumulado **1.579/111/32 clips, 765/69/16 IDs**, **346 páginas anotadas** y
**85 casos de contraste/contexto**, no bugs confirmados. Los **461 registros
anteriores** conservan SHA serializado
`97cbc8612962d6b9ab459e347e1aa799e3485e97b215a1a98b56cfa8cb9bf239`;
29 entradas nuevas separan nueve clips señalados: **490 entradas**. Diecisiete
gates suman **56.581 frames / 300.978 checks GPU PASS**. Al cerrar el bloque 16
quedaban 100 IDs; ahora solo queda **bloque 18, 50 IDs, trump_card a zing_zap**.
Todos los bloques generados 1–17 tienen reporte/láminas/registro completo.
Fuentes, plan, renderer, herramientas, sprites, datos, clasificaciones, cinco rutas
reales, mecánicas, IA, tests y workflows intactos. Los 19 workflows del mismo HEAD
previo consultados: SUCCESS, sin certificar estas notas locales. Sin commit/push/merge.

### Bloque 18 y cierre del barrido — 2026-10-25

Evidencia: `batch_18_c117b669d6cfdbec/result.json` y `sheets/boards.json`, bajo
la generación fijada. **50 IDs / 100 clips / 20 láminas**, trump_card a zing_zap;
**2.802 frames / 16.121 checks GPU PASS**, sin errores. Todas las láminas vistas
por ambos lados, con ampliaciones nativas de las dudas. Resultado: **42 IDs sin
fallo evidente, cinco pendientes de contraste y tres de contexto**; **87/7/6 clips**.

Casos guardados para la fase de diagnóstico:

- **Danza Triunfal, ambos lados:** PNG f2 confirma bases 0/1 propias opacas de
  misma escala, separadas 15 px arriba y lateralmente (izquierda back/derecha
  front). Dos cuerpos visibles, no solo bandera numérica. DATA_ONLY intacto.
- **Avivar, ambos lados:** PNG f4 superpone cuerpo rojizo elevado 15 px y cuerpo
  normal opaco. Mismo grupo de objetivos propios, sin borrar todos los ecos.
- **Ataque Ala, front:** PNG f5 deja arcos blancos claramente separados a la
  derecha de Ogerpon; back f5 los superpone al pecho/cabeza de Charizard.
- **Abatidoras, front:** PNG f18 deja humo a la derecha de la cabeza, separado;
  back f18 lo coloca sobre Charizard. Cotejar export/ancla/fase, no habilidad aprobada.
- **Láser Doble, front:** PNG f20/f27 muestra haz/orbes junto al borde derecho,
  con roce parcial de Ogerpon frente a back f27 superpuesto al cuerpo. Contrastar
  contacto descentrado; no declarar impacto totalmente ausente.
- **Ida y Vuelta, ambos lados:** PNG final f27 con plaza del usuario vacía y
  objetivo presente. Usuario oculto con opacidad 0,24706 y escala reducida;
  presentación del relevo pendiente, no atlas perdido.
- **Voltiocambio, ambos lados:** PNG final f25 confirma plaza del usuario vacía,
  salida izquierda/back o derecha/front y ocultación; objetivo presente. Relevo
  pendiente, RUNTIME_SUPPORTED no implica una nueva ruta visual real.
- **Remolino/Whirlwind, ambos lados:** conserva equivalente explícito Move:GUST;
  final f25 con ambos cuerpos presentes/opacos. La animación no presenta expulsión
  ni entrada del siguiente; necesita contexto externo. DATA_ONLY y hueco nativo
  intactos, sin nueva sustitución.

No añadir falso desfase unilateral de Llave Vital: PNG f19/f20 deja estrella en
lugar de contacto mientras el objetivo retrocede en ambos lados; f20 X524,04
desde482 en back y X103,62 desde145,67 en front. Shuriken de Agua front PNG f11
sí superpone estrella sobre cabeza. Los 18 avisos de transición grande y cuatro
de ocultación son pistas, no diagnósticos automáticos. Conservar 69/78 frames
back/front de Arrumaco Sideral y 35/31 de Tijera X; los motivos de fuego/madera
no prueban especies fijas. Sin sustituciones ni reparaciones durante el bloque.

**Cierre 18/18: 900 IDs / 1.822 clips / 366 láminas / 59.383 frames y 317.099 checks
GPU PASS.** Último estado por clip: **1.666/118/38**; por ID, dando prioridad a duda
sobre contexto sobre muestra: **807/74/19**. Quedan **93 casos de contraste/contexto**,
no 93 bugs confirmados. Los 19 contextos visuales no son los 19 secundarios sin
etiqueta de recurso: son listas distintas y estos últimos siguen diferidos.
Los **490 registros anteriores** conservan SHA serializado
`9623ceda0c513fe74bfaaea18ba61285ee7b215dd3bf39c531495dc47736686f`;
33 entradas nuevas separan trece clips señalados: **523 entradas**. Los 18 bloques
tienen reportes/láminas/registro con pertenencia exacta, sin generación a medias.
Plan, catálogo, renderer, herramientas, datos, sprites, clasificaciones, cinco
rutas reales, mecánicas, IA, tests, workflows y HEAD intactos. Los 19 workflows
del HEAD previo consultados: SUCCESS; no certifican estas notas locales.

Siguiente fase: **diagnóstico por causas comunes antes de corregir en lote**.
Empezar por bases propias duplicadas (Corpulencia, Celebración, Danza Triunfal,
Avivar, etc.) y anclas/impactos frontales. Después contrastar capas/transiciones
de agua, encuadres/coreografías, geometrías dudosas y casos artísticos de especies
fijas de baja prioridad. Mantener aparte los contextos de clima, relevo y cambio
de apariencia. El registro original conserva todos los IDs y lados afectados.
No borrar clones intencionales de Doble Equipo/Pesadilla ni ecos adicionales en
otros movimientos. No reabrir falsos avisos ya descartados. Toda corrección debe
guardar antes/después, prueba focal y regresión del grupo protegido; si cambian
renderer/fuentes, crear evidencia nueva sin sobrescribir estos 18 bloques ni
migrar sus aprobaciones como si el SHA fuera el mismo. Toda sustitución de arte
sigue exigiendo anotación en VISUAL_SUBSTITUTIONS. Sin commit/push/merge.

Registrar solo las vistas observadas: estados temporal_samples_checked,
needs_targeted_review o requires_external_presentation; `--clip` repetible separa
resultados distintos dentro de una página. El registro comprueba hash de reporte,
plan, herramienta y PNG, y siempre conserva `mechanics_approved=false` y
`realtime_motion_watched=false`. La revisión de 16 muestras NO certifica toda la
fluidez entre ellas; la captura técnica de todos los frames tampoco aprueba daño,
selección de objetivo o estados del combate. No aumentar las cinco rutas reales
por este barrido. 61 tests Python y gate GPU de bloque 1 PASS.

## Antecedente: últimas tres dudas artísticas revisadas — 2026-10-24

**900/919 IDs / 1.822 clips / 911 familias / 29 shards**, sin conexiones nuevas
al combate. Se cierra la primera pasada artística de los casos señalados, NO
la aprobación de cada fotograma ni todas las mecánicas del juego.

### Comparación conjunta y decisiones

Primer focal `.godot/move_temporal_checks/51441b54e1ec2a99/`: tres familias,
**290 frames GPU / 2.836 checks PASS**, reloj/limpieza. Comparación de opciones
`.godot/move_temporal_checks/7307dd03983f4acc/`: cinco familias, **440 frames /
3.308 PASS**, dos láminas de ocho tiempos por lado observadas. Registros de
selección previos guardados en `source_review_snapshot.json` de ambas carpetas.

| Caso | Decisión | Límite explícito |
| --- | --- | --- |
| Cañón Armadura | FLAMEBURST / Pirotecnia, ambos exports | Proyectil y explosión de fuego equivalentes; NO secuencia nativa exacta |
| Maxibicho / Maxinsecto | SILVERWIND / Viento Plata, front sintetizado declarado | Viento/brillos de tipo Bicho sin Pokémon ajenos; NO animación Max nativa |
| Martillo Colosal | Conservar GIGATONHAMMER, 23 frames | Impacto/compresión y esquirlas metálicas; NO hay un martillo literal dibujado |

En Cañón Armadura el aspecto rectangular/moteado está en el motivo de veneno de
`firepoison.png`, no hay fallo demostrado del renderer. Precisión: PNG indexado,
varios colores de fondo del visor (azul/amarillo/teal) son de alfa cero; **no son
un fondo opaco que debamos borrar**. Se cambia la referencia artística, no alfa,
shader ni textura. FLAMEBURST conserva su fuente completa de 29 frames/20 fps.
SAVAGESPINOUT incrustaba Beedrill/Scizor/etc. y capullo aunque los combatientes
fueran otros; no servía como Max genérico. SILVERWIND dura 35 frames/20 fps.
BUGBUZZ se comparó pero sus ondas se concentran en el usuario; no se eligió como
la mejor referencia de ataque Max de este lote. No se retargetea una fuente a ojo.

### Equivalencia artística no es reparación nativa

`move_art_choices.py` enumera SOLO dos selecciones, fija SHA de atributos completos
de las fuentes rechazadas Y elegidas, copia inerte sin mutar y forma pares atómicos.
Cambio de fuente, export ausente/ambiguo o caso no enumerado se rechaza. El builder
las aplica explícitamente antes de la referencia histórica, no como consecuencia
ficticia de un error de conversión. `visual_art_choice` declara procedencia,
motivo, fuente sustituida reproducible, `native_source_repaired=false` y
`mechanics_enabled=false`. No se inventa `missing_pattern` ni cuarentena nativa.

Índice/informe separan **dos selecciones artísticas** de los **diez huecos de
fuente cubiertos por equivalentes**; los equivalentes previos de prioridad siguen
siendo otra colección, no se afirma que el resto de los 900 sea todo nativo.
No cambia pool, aprendizaje, clasificaciones ni reglas. Reusar arte de un
movimiento antiguo no lo habilita en el pool. UI informa equivalente artístico
explícito y errores de metadatos sin crash.

Piloto histórico de 70 clips INTACTO: contiene todavía la referencia anterior
de Maxibicho para comparación, con advertencia HISTÓRICA y remisión al catálogo
actual. No se regenera con el antiguo helper de capas. Pack independiente de
cinco rutas reales también intacto; no se cambia un contrato de combate para
resolver una selección artística del laboratorio.

`audit_move_art_sources.py`: **1.818 contratos previos idénticos / cuatro
reemplazados**, incluidos Martillo Colosal y seis fuentes de contexto sin tocar.
Prueba independiente de arrays/capas/cadencia/gráficos/roles/títulos/clasificaciones
y fuente rechazada; no reutiliza el selector para fabricar sus esperados. Verifica
piloto anterior intacto, diez incidencias nativas retenidas, conteos sin inflación.
Informe `.godot/move_art_checks/bb327ada0e333479/sources.json`, SHA
`2615ac6fdbd0a4b3705b73c26e3d2d834682caba2b59d05571ccef6c26afdbda`.

### Gates y cierre honesto de la cola

Barridos finales **5.397.041 headless / 5.412.459 GPU PASS**, 118.766 estados
frame/lado/arena, 1.822 capturas técnicas. Se comprueban cuatro rótulos artísticos,
metadatos malformados y aviso histórico, además de la colección previa de huecos.
Regresiones: combate 407, pantalla/capas 8.025, cámara 4.630, geometría 2.743,
selector cinco y **57 tests Python PASS**. No se modificaron fuentes para hacer
pasar tests; negativos de cambio/ambigüedad/selección no enumerada y no mutación.

1.818 capturas/momentos/títulos idénticos permiten migrar sus notas por prueba.
Dos nuevas láminas delta observadas y cuatro notas trasladadas sin aprobar
vecinos. Focal final `.godot/move_temporal_checks/7be53573ed2e97d1/result.json`:
**174 imágenes GPU / 2.476 checks PASS**, seis clips completos, reloj y limpieza;
ambas láminas de ocho tiempos observadas. No es ver la película a velocidad real.

**1.822 anotados: 1.810 sampled_no_obvious_issue y doce
requires_external_presentation**, cero needs_motion_review/suspected_issue de la
cola señalada. Primera pasada artística cerrada CON equivalentes y límites,
no perfección artística total. Siguen seis integraciones externas, cinco DATA_ONLY
y Transformación UNSUPPORTED, solo demo opcional. Siguen 19 etiquetas secundarias
en cuarentena y diez huecos originales cubiertos, no reparados. No reabrir esos
grupos para hacer crecer una cifra ni admitirlos a combate por estética.

Recursos de contexto renovados para el nuevo índice: `08bf4875daf81fcf`, sin cambiar
su composición. Focal `466c9a2439f4f43e`: **6.442 headless / 8.048 GPU PASS**,
**1.164 hashes de píxeles-frame idénticos** a `5a810aa399c4aa7c`, cuatro PNG de
lámina idénticos y notas migradas por igualdad verificada, no como integración real.

Pack `generation_66381a70b65ea385`; índice
`bb327ada0e33347980260a7e4a8af65e8622171002c64d3ecf56759aa92dbee1`.
Capturas `c673840caea21b70`, manifiesto SHA
`fec5f425b46ed1596ad84c85b5bb3b52f95088460db88bd40fc218205959cad0`.
Registro `.godot/move_contact_review/c673840caea21b70/sheets_20/index.md`.
Contexto `.godot/move_external_context/08bf4875daf81fcf/context.json` y focal
`.godot/move_external_checks/466c9a2439f4f43e/gpu/result.json`.

Sin descargas/arte/créditos nuevos, F:, datos canónicos, mecánicas, IA, workflows,
commit/push/merge. HEAD previo y 19 SUCCESS remotos verificados, no certifican
cambios locales. El siguiente paso es inventariar conexión visual por familias
y soporte ya existente; no activar las 900 referencias ni DATA_ONLY de golpe.

## Antecedente: seis presentaciones externas y laboratorio opcional — 2026-10-24

Los **900/919 IDs y 1.822 clips nativos no cambian**. Se revisan juntos Danza
Lluvia, Granizo, Paisaje Nevado, Fría Acogida, Sustituto y Transformación: 222 frames
GPU / 2.653 PASS, `.godot/move_temporal_checks/fef7086e03940040/result.json`, dos
láminas de ocho tiempos vistas. Registro original de selección fijado por SHA
en `source_review_snapshot.json` antes de añadir las nuevas notas.

### Qué falta realmente y qué se muestra

| Caso | Fuente nativa | Vista opcional, NO mecánica |
| --- | --- | --- |
| Danza Lluvia | Invocación corporal; sin partículas/capas de lluvia | Common:Rain durante 30 frames extra |
| Granizo / Paisaje Nevado | Invocación/tono; sin precipitación propia | Common:Hail / Common:Snow, 30 frames extra |
| Fría Acogida | Bocadillo/hielo/retirada intencionada | Se conserva retirada, luego muestra Common:Snow; no cambia equipo |
| Sustituto | Muñeco de entrada; sin reemplazo persistente del cuerpo | Se coloca la vista original del muñeco en los pies del usuario; sin PS/protección |
| Transformación | Destello, no apariencia posterior | Se muestra la vista correcta del rival bajo el destello en f8 y se mantiene la muestra; sin copiar atributos |

Hallazgo importante: **Common:Snow y Common:Hail tienen los mismos frames y PNG
en este pack**. Se usan con sus nombres propios y se declara esa coincidencia;
no demuestra que las reglas de nieve/granizo sean iguales ni que haya un recurso
artístico exclusivo de nieve. No se instala/ejecuta Ruby descargado. La
[implementación oficial de Essentials para animaciones](https://github.com/Maruno17/pokemon-essentials/blob/8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b/Data/Scripts/011_Battle/004_Scene/004_Scene_PlayAnimations.rb)
distingue reproducción de movimientos y Common; consulta de formato, no código
copiado ni una promesa de replicar su motor. Fuente visual: Gen9/Reborn ya
acreditados; Maruno17/Essentials ya registrado. Sin descargas de arte/créditos
nuevos; revisión de licencias sigue obligatoria antes de distribuir.

### Implementación y guardas

`build_move_external_context.py` convierte SOLO Common:Rain/Hail/Snow desde datos
inertes, fijados por SHA de atributos completos; copia la hoja original de
Sustituto y deriva límites de alfa, no tamaños dibujados a ojo. Tres clips de
clima y doce bindings a los shards/clips nativos, con título/cadencia/clasificación
preservados; no se modifica el índice principal. Recursos acotados y PNG verificados.

`move_external_context.gd` es composición exclusiva del laboratorio, no se carga
desde combate. El renderer nativo no cambia. Checkbox **apagado por defecto**;
activar «Catálogo por lotes» y «Contexto visual opcional · NO mecánicas». La UI
muestra explícitamente simulación local y límites de cada caso. Contexto bloqueado
si cambian índice/renderer, fuente/shard o metadatos; no dibuja con otro clip.

La muestra adicional dura 30 frames/20 fps (1,5 s), no cinco turnos ni persistencia
de clima real. El muñeco usa ambas vistas originales, pies según alfa y perspectiva
del laboratorio. Transformación toma la apariencia/vista del lado correcto desde
el catálogo, no espeja un frontal ni modifica las especies de los datos. El gancho
de apariencia en f8 es **una decisión de demo bajo el flash**, no un evento nativo
importado: evita que reaparezca Ditto unos frames antes del cambio. Opción apagada
conserva el original; no se altera ningún array/fuente/clasificación.

Defecto detectado al inspeccionar la UI real: su cambio de tamaño programaba una
restauración nativa diferida y reaparecía Ditto debajo de Charizard. Ahora el
adaptador reaplica su último frame después de ese refresco, también pausado.
Prueba provoca resize real, verifica ausencia del original y guarda screenshot.
No se parchea el renderer global. Fuente/overlay se limpian al desactivar,
retroceder, cambiar filtro o seleccionar otro recurso.

### Prueba masiva, evidencia y deuda explícita

Focal final **6.442 checks headless / 8.048 GPU PASS**, **1.164 estados / 24 variantes**,
los seis movimientos, ambos lados, arenas 640×360 y 400×300. Captura cada frame;
comprueba índices, solo overlay declarado, cuerpos sin duplicados, vistas correctas,
clip intacto, scrub/toggle, fuente ajena rechazada y limpieza GPU. Prefijo nativo
idéntico por píxeles excepto gancho de Transformación declarado. Prueba UI real
con checkbox/buscador/slider y resize; dos vistas diferentes para apreciar la copia.
Compositor exige matriz completa/única, fases/orden, longitudes nativas de bindings,
hashes de índice/renderer/adaptador/UI/test/manifiesto y cada PNG real.

**55 tests Python PASS** (negativos de captura/duplicados/longitudes/fases/rutas/hash),
barrido nativo headless **5.396.926 PASS**, 118.998 estados; combate 407 y selector
cinco. No se repite un barrido GPU de 1.822 clips: índice, renderer y runner de
ese barrido no cambiaron; su evidencia previa sigue fijada. Los tests nuevos
certifican solo la composición opcional local, no el motor ni toda la worktree.

Observadas cuatro láminas finales (seis familias × dos lados × dos arenas × ocho
tiempos) y screenshot de la UI. Registro separado `gpu/sheets/review.json`, con
SHA de páginas y alcance limitado. No se confunde muestreo con ver la película
continua. Prototipos `220d0eec15b34a01` y `a2df8b7e54c9ea5d` quedan HISTÓRICOS;
para UI pausada/redimensionada prevalece el focal final.

Estado nuevo `requires_external_presentation`: fuente revisada, resultado externo
todavía requiere integración real. **NO es aprobado**, ni habilita cinco DATA_ONLY
o Transformación UNSUPPORTED. Registro completo actual: **1.804 sampled_no_obvious_issue,
cuatro needs_motion_review, dos suspected_issue y doce requires_external_presentation**
(1.822 anotados). Quedan tres IDs artísticos y seis de integración; no se ocultan
estos seis para proclamar que solo quedan tres pendientes totales.

Pack nativo/índice siguen `generation_97c85debdd57429f` /
`cd2ac8ce68742e8c285d0ac6088abe093817ed98732f7461478da230a6f554ae`;
capturas nativas `582da8379b6b4de9` (solo cambia ledger, no PNG/manifiesto).
Contexto `.godot/move_external_context/a2c3d4e515738f2f/context.json`;
focal `.godot/move_external_checks/5a810aa399c4aa7c/gpu/result.json`, cuatro
láminas `sheets/`, UI `lab_transform_context.png`. Para reconstruir recursos
opcionales tras otro catálogo: `python tools/visual/build_move_external_context.py
--source-root 'D:/Proyectos/Pokemon Calvo Auditoria Visual/comparacion_ataques_v1'`.

Sin datos/learnsets/HP/turnos/RNG/clima/IA/reglas nuevos, siguen cinco rutas de
combate. Diez huecos nativos cubiertos por equivalentes y 19 secundarios sin
etiqueta intactos. Biblioteca F:, workflows, Git remoto y HEAD intactos; sin
commit/push/merge. CI 19 SUCCESS del HEAD previo verificada antes de editar no
certifica estos cambios locales. Siguiente lote: Cañón Armadura, Martillo Colosal,
Maxibicho, sin reabrir los seis como supuestos atlas rotos.

## Antecedente: Ala Mortífera, vuelo nativo y corrección geométrica del haz — 2026-10-24

**900/919 IDs / 1.822 clips / 911 familias / 29 shards**, sin ampliar las cinco
rutas de combate. Diez huecos nativos cubiertos por equivalentes y 19 etiquetas
secundarias siguen tal cual. No se cambia la selección de Láser Prisma/PSYBEAM.

### Reproducción y diagnóstico independiente

Captura previa `.godot/move_temporal_checks/ed5caba9deee82b8/`: **70 frames GPU /
2.142 PASS**, ambos lados, reloj y limpieza. Dos láminas de ocho tiempos vistas.
La fuente de Ala Mortífera mueve al emisor desde f8 hasta y=-88 y lo devuelve
en f27–30; en f34 termina en su puesto normal. Esto no es una desaparición
accidental ni se corrige congelando/recortando cuerpos. Cada lado conserva sus
propios tiempos de ascenso, no se le copian los de Rayo Umbrío.

El haz sí tiene un fallo de adaptación. Se amplía la sonda anterior a seis
familias / 36 variantes de lado-cámara; la referencia fija usa puestos canónicos
512×384 y nuestros sprites, NO captura de Essentials/juego oficial. Antes:
`.godot/move_trajectory_checks/c85690267bd46bb3/result.json`, **1.458 estados /
14.083 checks diagnósticos PASS** (no significa que la geometría fuera correcta).
En 640×360 cubría el disco del objetivo ocho frames, pico 66 % back / 43 % front,
frente a quince y 100 % en referencia. En 400×300 eran doce frames. La silueta
del objetivo ya se solapaba quince frames: el defecto NO demuestra falta de daño.

Se añade Ala Mortífera al oráculo independiente de cuatro esquinas y centro de
cada partícula, ambas vistas, tres arenas y tres parejas de especies (incluye
Wailord). **FAIL antes**, 2.743 checks, primeras veinte discrepancias acotadas;
evidencia `.godot/move_beam_checks/9915078aee64b7db_9636af2c5cba_159a18b7c1ee/`.
No basta con compartir GEN8- Moongeist Beam.png: se verifica que todas sus celdas
de partícula usan foco de línea 3, se miden los desajustes y se fijan sus arrays
propios. Las fuentes llevan hue140, sin cambiarlo.

### Corrección acotada y guardas

Solo se enumeran dos exports más en `NATIVE_GEOMETRY_REPAIRS`. El renderer ya
soporta la base completa `cámara * rotación * escala`; no cambia. Se publican
metadatos para patrones 0–4 de estos exports. SHA del array completo:

- `Move:OBLIVIONWING`: `e9cd57608d129b10080b6376fee93f91f7de76e32e91ccf741bcdf14f8f748ab`.
- `OppMove:OBLIVIONWING`: `c22a3f81cb5bb7c7e92c229c6534e7cdbfc41f76ffa46aa31edb3c1a791c61bf`.

`audit_move_geometry_sources.py` coteja por separado los atributos completos
fijados por SHA, arrays/capas/cadencia/roles/título/objetivo/clasificación y hue.
Prueba **1.820 contratos íntegros idénticos**, dos con SOLO metadatos/flag de
geometría; mismos PNG/dependencias/celdas/cuerpos. Rechaza otros cambios,
altas/bajas, medio par, gráficos/celdas/flags alterados. Informe
`.godot/move_geometry_checks/cd2ac8ce68742e8c/sources.json`, SHA
`0dc491639f03e0900577f7eb85e40094c66e73c256fbe5a2c9ae019f7b7126bf`.
No se ocultan partículas ni retocan cuerpos para encajar una captura.

Después: **2.743 checks geométricos PASS**, Rayo Umbrío y Ala Mortífera, nueve
combinaciones de arena/especies por lado. Sonda GPU
`.godot/move_trajectory_checks/38d5789d80e3e643/result.json`: **1.458 estados /
14.082 PASS**. El haz de Ala Mortífera cubre el ancla quince frames con pico
100 % en ambos lados/cámaras, igual que referencia. Vistas capturas nativas
del pico de silueta en 640×360 y 400×300, comparadas con referencia/antes. Son
medidas de presentación, no una hitbox, daño o aprobación mecánica.

### Regresión y registro vigente

Barridos **5.396.926 headless / 5.412.340 GPU PASS**, 118.998 estados y 1.822
capturas técnicas. Regresiones PASS: combate 407, pantalla/capas 8.025, cámara
4.630, selector cinco y **53 tests Python**. Matriz de la sonda completa/única
ampliada, conservación de fuente y negativos de metadatos cubiertos.

Nuevas 5.466 capturas muestreadas; prueba de migración conserva **1.820 PNG,
momentos, títulos y notas idénticos**, sin heredar aprobación a otros vecinos.
Dos láminas delta observadas, luego temporal final
`.godot/move_temporal_checks/ccdea9d8b1063905/result.json`: **2.142 checks / 70
imágenes GPU PASS**, dos clips completos, reloj a 20 fps y limpieza. Vistas
ambas láminas de ocho momentos, regreso conservado. No se afirma observar cada
fotograma a velocidad normal ni certificar toda la fluidez por una tira.

Registro: **1.822 anotados / 1.804 sampled_no_obvious_issue / diez
needs_motion_review / ocho suspected_issue**, dieciocho clips apartados /
nueve IDs. Quedan seis presentaciones externas y tres elecciones artísticas;
no se borran sus dudas ni se activan mecánicas al migrar notas.

Pack `generation_97c85debdd57429f`; índice
`cd2ac8ce68742e8c285d0ac6088abe093817ed98732f7461478da230a6f554ae`.
Capturas `582da8379b6b4de9`, manifiesto SHA
`122b8735aead4ca2937355e3a4ba313c39e62eb0768a1f84360aa8b91370e43f`.
Registro `.godot/move_contact_review/582da8379b6b4de9/sheets_20/index.md`.
Fuentes/capturas anteriores preservadas. Sin descargas/arte/créditos nuevos.
Datos canónicos, mecánicas, UI, IA, workflows y biblioteca F: intactos;
sin commit/push/merge.
Los 19 checks remotos del HEAD previo fueron verificados; no certifican la
worktree local. Siguiente grupo: las seis presentaciones externas juntas.

## Antecedente: revisión del sustituto de Láser Prisma — 2026-10-24

Sin ampliar alcance mecánico: **900/919 IDs reproducibles, 1.822 clips / 911
familias / 29 shards**. Diez fuentes nativas siguen con huecos aunque haya
equivalentes; 19 etiquetas secundarias continúan en cuarentena. Solo cambia
Láser Prisma, de PHOTONGEYSER a **PSYBEAM**, ambos lados. Referencia psíquica de
anillos, NO su láser original. Géiser Fotónico original no se modifica.

### Comparación y causa de la figura exagerada

`move_temporal_review.gd` admite ahora `-- --moves=prismatic_laser,psybeam` para
capturar una comparación acotada de parejas ya anotadas (máximo diez IDs). La
selección ordenada entra en la generación; desconocidos, duplicados y parejas
incompletas son error antes de escribir evidencia. Sin parámetro sigue escogiendo
todas las excepciones. El constructor temporal exige cobertura de la selección.

Comparación anterior `.godot/move_temporal_checks/2a1d494c6d5f49f8/result.json`:
**2.434 checks / 164 imágenes GPU**, cuatro clips, reloj a 20 fps y limpieza PASS.
Vistas ambas láminas de ocho momentos y f44 nativo del sustituto anterior.
Precisión frente a la sospecha inicial: la figura gris ampliada NO es un cuerpo
de Pokémon deformado. En f44 los cuerpos de PHOTONGEYSER conservan 100×100 %;
las celdas positivas del **patrón 23 de PRAS- Photon Guyser.png**, un pico del
efecto, se amplían al **317×442 %**. El atlas contiene ese dibujo. Se rechaza por
idoneidad artística como sustituto de Láser Prisma, no como fallo probado del
renderer ni como permiso para retocar Géiser Fotónico original o mil Pokémon.

PSYBEAM contiene anillos dirigidos al rival, sin ese pico; fuente completa sin
redibujar, recortar ni ocultar partículas. Cada export tiene **25 frames a 20 fps**
(1,25 s frente a 2,85 s del candidato anterior). Solo cambia duración visual en
laboratorio; no se conecta al daño/turnos. `target=selected-pokemon`, nombre y
clasificación de Láser Prisma preservados. El rótulo sigue declarando equivalente
explícito y hueco original sin resolver.

SHA de atributos completos, no solo frames:

- `Move:PSYBEAM`: `1f4c8e7f286d76936c7e6d3004925791ba89f4233fa6afcc4cb6a70cb5f6db44`.
- `OppMove:PSYBEAM`: `84ebcdd2163973200f3de4a643d9218f8188af9249f073fce877139206249ab5`.

### Pruebas, conservación y siguiente cola

`audit_move_equivalents.py --replace-moves prismatic_laser` conserva el modo de
alta inicial, pero permite SOLO la pareja de sustitución declarada. Rechaza
altas/bajas, un solo lado cambiado, otros contratos modificados o IDs no enumerados.
Fuente inerte independiente coteja celdas/capas/tiempos/hojas/roles/título/objetivo/
clasificación, manteniendo `missing_pattern:11`, `native_gap_fixed=false` y
`mechanics_enabled=false`. **1.820 contratos idénticos / dos sustituidos**;
100 estados de referencia frame/lado/arena. Informe separado para no sobrescribir
la prueba histórica de las veinte altas:
`.godot/move_equivalent_checks/replacement_9915078aee64b7db.json`.

Barridos finales **5.396.926 headless / 5.412.340 GPU PASS**, 118.998 estados y
1.822 capturas técnicas; no aprobaciones artísticas automáticas. Regresiones
PASS: combate 407, pantalla/capas 8.025, cámara 4.630, haz 1.372, selector cinco,
**49 tests Python**. Negativos de CLI duplicada/desconocida PASS por rechazo
previo, sin guardar supuestas capturas. Renderer y UI sin cambios.

Nuevas 5.466 capturas muestreadas; **1.820 PNG, momentos y títulos idénticos**
a `b6183b56e397801b`, no solo mismo nombre de archivo. Registro migrado por
contratos/dependencias/renderer/píxeles; dos nuevas láminas delta observadas.
Comparación final `.godot/move_temporal_checks/5459bd9cffc51881/result.json`:
**2.242 checks / 100 imágenes GPU de cuatro clips PASS**. Vistas las dos láminas
de ocho tiempos; Láser Prisma coincide con su referencia psíquica declarada y
retorna a la escena limpia en ambos lados. Capturar cada frame y ver muestras
NO es observar la película a velocidad normal ni certificar toda la fluidez.

Registro vigente **1.822 anotados: 1.802 sampled_no_obvious_issue / 12
needs_motion_review / ocho suspected_issue**, veinte clips apartados / diez IDs.
Permanecen Ala Mortífera; seis presentaciones externas (Danza Lluvia, Granizo,
Paisaje Nevado, Fría Acogida, Sustituto, Transformación); tres elecciones artísticas
(Cañón Armadura, Martillo Colosal, Maxibicho). No se rehabilitan por migrar páginas.

Pack `generation_7db488fb7d72d2de`, índice
`9915078aee64b7db908e5ad303961d3e52dcbe6dae5d406c68c3d371a38c9518`;
capturas **`b762b7d359665bfc`**, manifiesto SHA
`e4a58198252593aa903d07f5a6860aa011ed057e2cabe2bb236813e86d154f57`.
Registro `.godot/move_contact_review/b762b7d359665bfc/sheets_20/index.md`.
Snapshots de índice/renderer preservados. Los antecedentes siguientes conservan
la selección PHOTONGEYSER y cifras anteriores como historia, no estado vigente.
Sin arte nuevo, descargas, créditos nuevos, mecánicas ni rutas nuevas. Sin
commit/push/merge o CI nueva; no confundir pruebas locales con certificación del
HEAD remoto. Datos canónicos y biblioteca F: intactos.

## Antecedente: diez equivalentes explícitos y cierre de huecos reproducibles — 2026-10-24

Petición «sigue»: no se localizaron hojas completas compatibles en las fuentes
consultadas. Se toma la alternativa ya autorizada por el usuario de reutilizar
arte parecido para huecos, declarando sus límites. **900/919 IDs reproducibles
para laboratorio, 1.822 clips / 911 familias / 29 shards**. Diez referencias nuevas
NO son diez reparaciones nativas: permanecen sus motivos originales, más 19
etiquetas sin referencia reproducible. El conjunto prioritario anterior ya incluía
equivalencias/manuales propias; este contador diez se refiere a este nuevo grupo,
no a una afirmación de que todo lo demás sea animación original exacta.

### Investigación acotada y selección

PokéRogue sigue referenciando varios patrones fuera de sus hojas y Descanso no
aporta una secuencia utilizable. No se importa su JSON ni se ejecuta código suyo.
Consultada la [distribución oficial de Reborn](https://www.rebornevo.com/pr/download/)
por rangos HTTP: índice del parche 19.5, 742 entradas, sin PNG de Animations.
49.658 bytes transferidos para ese índice; inspección inerte del bootstrap/updater
(13.199.530 bytes en memoria) no aporta las hojas. No se instala/ejecuta ni guarda
el actualizador, no se descarga el juego entero, ni se afirma haber agotado todas
sus distribuciones o que no puedan existir correcciones en otra versión.

Con los recursos ya descargados se selecciona este grupo coherente de candidatos:

| Destino | Referencia visual explícita | Límite |
| --- | --- | --- |
| brave_bird y dos supersonic_skystrike | SKYATTACK, ambos exports | Ataque volador equivalente, mismo atlas PRAS Brave Bird pero sin pedir el patrón ausente. Los Z son secundarios. |
| hex | SPITE | Fantasma sobre el objetivo; no usar Grudge sin retarget, pues sus partículas van al usuario. |
| prismatic_laser | PHOTONGEYSER, ambos exports | Psíquico; idoneidad artística pendiente por silueta exagerada en f44. |
| rest | SLEEPTALK | Z de sueño sobre el usuario, no implementación de curación/sueño. |
| twister | HURRICANE, ambos exports | Vórtices de viento equivalentes, no la secuencia nativa. |
| whirlwind | GUST | Viento sobre el objetivo, no una retirada/cambio externo. |
| future_sight | FUTUREDUMMY del propio pack | Export existente usado aquí solo como referencia de impacto; NO sustituye preparación/espera ni implementa daño diferido. |
| flower_trick | FLOWERTRICK + PRAS- Petal BG | Celdas/timing originales; SOLO fondo uwu.png ausente sustituido por fondo de pétalos. No se conoce el original. |

Se descartó Grudge como sustituto directo de Infortunio porque afecta al usuario;
Rencor/SPITE está dirigido al objetivo. No se intercambian focos a ojo para hacerlo
parecer correcto. No se dibujan imágenes, rellenan atlas de transparencia,
duplican patrones ni ocultan partículas que la fuente nativa intentaba mostrar.
El fondo de pétalos es una elección artística explícita, no un supuesto alias
de uwu.png. No hay nuevas descargas de arte ni atribuciones externas que añadir:
se mantienen las de Gen9/Reborn ya registradas.

### Contrato de equivalencia, guardas y UI

`move_visual_equivalents.py`: diez decisiones enumeradas, SHA completo de cada
export seleccionado (incluye frames, gráfico, hue y timings), razón de fallo
original exacta y cambios permitidos. El constructor intenta la conversión nativa
primero. Solo estos casos/fallos concretos pueden usar alternativa; error distinto,
fuente cambiada o export ausente/ambiguo mantienen cuarentena. Una pareja es
atómica, sin publicar un solo lado. No se ejecuta Ruby descargado.

Cada clip tiene `visual_equivalent`: fuente, SHA, tipo de equivalente, motivo
nativo conservado y modificaciones declaradas; `native_gap_fixed=false`,
`mechanics_enabled=false`. El índice conserva `primary_source_gaps_retained`
(diez) y `visual_equivalent_moves` (diez). Informes separan 19 no convertidos de
diez fuentes originales cubiertas por equivalentes. Son las 29 incidencias de
conversión anteriores, no una afirmación de recuperación de todas las fuentes.
La cola `native_gap_covered_by_equivalent` significa reproducible con equivalente,
no «reparado» ni «sin convertir». Cinco enlaces de combate permanecen iguales.

La UI del laboratorio muestra **EQUIVALENTE VISUAL EXPLÍCITO · hueco original
NO resuelto**, fuente escogida, y aviso de solo impacto para Premonición. Maneja
metadatos malformados sin crash ni aprobación automática. El renderer no cambia.
No se modifica ningún dibujo, dato canónico, clasificación, daño, turnos o RNG.

### Evidencia de fuente, regresiones y revisión por lote

`audit_move_equivalents.py`: **1.802 contratos anteriores idénticos**, veinte
clips nuevos exactos, 1.480 estados frame/lado/arena de las nuevas referencias.
Compara con fuente inerte arrays/capas/timing/hojas/roles/clasificaciones; la
única modificación de fuente permitida es el nombre del fondo de Truco Floral.
No reutiliza select_equivalent para fabricar el resultado esperado. Fuente
de cada lado y cadencia preservadas; las fuentes elegidas tienen hojas completas
para las celdas que realmente usan.

Barridos finales **5.403.992 headless / 5.419.406 GPU PASS**, 119.126 estados,
1.822 capturas técnicas. Comprobados los veinte rótulos de equivalencia, roles,
metadatos malformados y conservación de incidencias. Regresiones PASS: prioridad
445.698 GPU / 708 capturas; combate 407; pantalla 8.025; cámara 4.630; haz 1.372;
selector cinco; **45 tests Python**. Tests negativos para fuente/razón/etiqueta/
ambigüedad incorrectas, no mutación, cambio exclusivo del fondo e informes que
mantienen el hueco nativo sin dar soporte mecánico.

Pack **`generation_f5531ada8334529b`**; índice SHA
`44c5c0cbf81d5cf9a130c161167ec768e6eb87f84febd744f4d1a86e192a1529`.
Capturas **`b6183b56e397801b`**, `captures.json` SHA
`903d21cb939cf47d4770887a0248dba7b7a900f867b49c50c489c45050f6bc3d`.
Prueba de fuentes `.godot/move_equivalent_checks/sources.json` SHA
`f7d0557500aa51c80658e0c07d16f7eb011c4655531a8110ff0648167539b736`.
Los 1.802 PNG/muestras/títulos previos son idénticos; notas conservadas por prueba
individual, incluidas todas las excepciones, sin revisar otra vez las 92 páginas.

Dos láminas delta de diez familias observadas, veinte anotaciones trasladadas al
registro completo. **1.822 clips anotados: 1.800 sampled_no_obvious_issue,
14 needs_motion_review y ocho suspected_issue; 22 apartados / once IDs.** Nueve
alternativas nuevas sin fallo evidente en tres momentos. Láser Prisma ambos
lados se aparta por silueta muy aumentada/estirada en f44: revisar la secuencia
y si Géiser Fotónico encaja como sustituto; Psicorrayo es otra opción a comparar.
No se declara defecto del conversor ni se reabre automáticamente el movimiento
Photon Geyser original. No se certifica una película continua por estas láminas.

Reproducción desde D: (constructor offline, imágenes suplementarias previas ya
en caché; no se necesitan nuevos datos):

```powershell
python tools/visual/build_move_batch.py --source-root 'D:/Proyectos/Pokemon Calvo Auditoria Visual/comparacion_ataques_v1'
python tools/visual/audit_move_equivalents.py --source-root 'D:/Proyectos/Pokemon Calvo Auditoria Visual/comparacion_ataques_v1' --baseline .godot/move_contact_review/493b98955b31aa33/catalog_index.json
python -m unittest discover -s tools/visual -p 'test_move*.py' -q
```

Siguiente tramo: idoneidad de Láser Prisma y las diez dudas visuales anteriores,
agrupadas, no búsqueda indefinida de hojas exactas ni otra whitelist de mecánicas.
Conservar los 19 secundarios fuera de prioridad. Sin cambios de core/datos/IA/
workflows/biblioteca F:, sin commit/push/merge ni CI nueva. La CI del HEAD previo
no certifica los cambios locales.

## Antecedente: atlas/fondos diagnosticados y cuatro recuperaciones — 2026-10-24

Petición «sigue»: investigados juntos ocho `missing_pattern`, cinco `missing_sheet`
y el modo de celda restante. **890/919 IDs convertidos para laboratorio, 1.802
clips / 901 familias / 29 shards**. Se recuperan ambos lados de Estruendo Implacable,
Gigaimpacto, Lengüetazo y Resplandor. Restan **29 excepciones**: 19 etiquetas,
ocho patrones y dos hojas. Sin nuevas rutas de combate o mecánicas habilitadas.

### Qué faltaba realmente, y qué NO se ha «arreglado»

Comprobados nombres, dimensiones, celdas, visibilidad/opacidad, timings y listado
del ZIP fijado. No era un fallo general de extracción: el propio archivo trae
estas cinco hojas sin las celdas que usa el export con opacidad positiva:

| Hoja original | Tamaño | Patrones fuera de hoja | IDs afectados |
| --- | --- | --- | --- |
| PRAS- Brave Bird.png | 192×192 | 1 | brave_bird, supersonic_skystrike_physical, supersonic_skystrike_special |
| PRAS- Grudge.png | 768×192 | 4 | hex |
| PRAS- Prismatic Laser.png | 960×384 | 10 y 11 | prismatic_laser |
| PRAS- Slack Off.png | 960×192 | 5 | rest |
| PRAS- Twister.png | 960×576 | 18 | twister, whirlwind |

Las hojas de PokéRogue también tienen esa cobertura de celdas (a media resolución),
no aportan los patrones ausentes. No se importan ni se usan como supuesto arreglo.
No se rellena el atlas de transparencia, se duplica otro dibujo ni se omiten las
partículas para subir el contador. Ocho IDs siguen explícitamente en cuarentena.
Faltan además `uwu.png` (Truco Floral) y `PRAS- Darkness BG.png` (Premonición).
La ausencia de `uwu.png` ya se señaló en el [hilo del autor, mensaje #7](https://eeveeexpo.com/threads/7890/).
No se ha
confirmado que otro fondo de nombre parecido sea el mismo recurso.

### Reparaciones acotadas, no aproximaciones silenciosas

- **Lengüetazo:** la hoja principal `PRAS- Sketch + Lick.png` sí existe. SOLO el
  export rival menciona otro nombre de fondo ausente, `PRAS- Sketch and Lick.png`,
  pero su opacidad es cero en los 15 estados horneados. Se omite ese nombre de
  dependencia; no cambian las celdas ni los demás campos de las capas. Se conserva
  metadato de nombre original, usos, opacidad máxima y SHA de estados originales.
  La regla exige que TODOS los usos sean invisibles: un fade que se hace visible
  más tarde impide omitirla y mantiene el error. No se elimina una imagen visible.
- **Estruendo Implacable:** prioridad 4 en dos exports, antes rechazada. El
  [reproductor primario de Essentials](https://github.com/Maruno17/pokemon-essentials/blob/master/Data/Scripts/011_Battle/007_Other%20battle%20code/007_BattleAnimationPlayer.rb)
  manda las prioridades fuera de 0–3 a z80. Se normalizan SOLO esos exports fijados
  por SHA completo de arrays: 1.968 campos 4→1, mismo z80, sin alterar otros campos,
  atlas o timings. No se admite arbitrariamente cualquier modo desconocido ni se
  cambia el renderer. Pruebas cubren alias de celdas Marshal y fuente no mutada.
- **Resplandor:** encontrada la hoja blanca real de 512×384 en el repositorio de
  recursos de PokéRogue. Se incorpora el PNG intacto fijado por commit/SHA, no
  se genera otro por el nombre. Su uso se etiqueta como fuente suplementaria.
- **Gigaimpacto:** la fuente trae fondo propio pero omite el rival. Se adopta la
  [corrección publicada por geefuoco, PR #1584](https://github.com/pagefaultgames/pokerogue/pull/1584),
  no una rotación inventada aquí. El proveedor la publica a 256×192; se recupera
  el canvas de 512×384 con réplica entera nearest ×2, sin inventar colores ni arte.
  Los frames/timings de nuestro export Gen9 se conservan; no se importa otro motor.

### Procedencia, créditos y condiciones pendientes

Dos imágenes, **46.501 bytes originales**, guardadas en caché ignorada
`.godot/move_gap_sources/`. `fetch_move_gap_sheets.py` descarga solo esos PNG de
URLs con commit inmutable, límite de tamaño y SHA esperado; no sobrescribe una
entrada existente que no coincide. El constructor sigue siendo offline. Archivo
`provenance.json` conserva fuentes, receta de canvas y necesidad de revisar
condiciones antes de distribución.

| Recurso | Commit del proveedor | SHA-256 original |
| --- | --- | --- |
| PRAS- White BG.png | 41cc6cfd9b625b4f46cf3a5cb220cc1c3ee788cf | b274056661a104584b1c6eb5816fe5bc21dc44afc4a065b3cec01723235234cc |
| PRAS- Giga Impact Opp BG.png | 95845e7df6e032423818dd49ecbe317df05af668 | 6545ea60c2c46ad75d501cfa933445de73607dbf042dc5ce56dd879c6777eb65 |

Giga rival normalizado: SHA
`7aeda9be09d5a931133c62748f62fbbec9f0a31792a302b170b5326a8e8cefc8`.
Conservar **geefuoco** por la corrección rival, **Pagefault Games / colaboradores
de PokéRogue** por la distribución/adaptación y las atribuciones originales de
**Pokémon Reborn / proyecto Gen8–Gen9** ya registradas abajo. No adjudicar todo el
arte a quien distribuye el paquete ni al conversor. El [README del proveedor](https://github.com/pagefaultgames/pokerogue-assets#license)
describe CC-BY-NC-SA-4.0 para recursos cuando es aplicable y excepciones en REUSE;
eso no acredita por sí solo derechos de terceros ni permiso comercial universal.
No se redistribuye arte en Git ni se instala código/JSON de animaciones de ese
repositorio. Consultados como referencia sus metadatos; solo se adoptan dos PNG.

### Pruebas y revisión agrupada

`audit_move_gap_sources.py`: ocho clips nuevos exactos, **1.794 contratos previos
idénticos**, arrays/timings/capas comparados con Marshal inerte, únicas diferencias
permitidas de prioridad y nombre de capa invisible, hashes/datos canónicos.
**589.824 comparaciones de píxeles de proveedor** (tres usos de dos hojas, no
589.824 píxeles únicos) mediante oráculo independiente por coordenada entera,
sin llamar al resize del importador. Rechazo de hash/tamaño desconocidos.
`move_gap_test_runner.gd`: **4.666 PASS**, todos los frames nuevos/dos arenas,
prioridad efectiva z80 y capas omitidas nunca visibles. No prueba impacto o daño.

Barridos completos **5.334.273 headless / 5.349.507 GPU PASS**, 117.646 estados
frame/lado/arena, 1.802 capturas técnicas. Regresiones: prioridad 445.698 GPU /
708 capturas; combate 407; pantalla 8.025; cámara 4.630; haz 1.372; selector cinco;
**41 tests Python PASS**. Negativos: fuente de prioridad alterada, prioridad 4 de
otro movimiento, una capa que reaparece por fade, ruta insegura, fuente ausente/
hash roto/dimensiones incorrectas. Casos de réplica comprueban todos los canales
y alpha, no mutación y cero remuestreo cuando escala=1.

Pack **`generation_f2709ae56368fe60`**, índice SHA
`05200ba888a068878464a4eba5097305951ae3309435deb2a993f17782a3aa4b`.
Captura **`493b98955b31aa33`**, `captures.json` SHA
`3bf7d23665d8d9828fe73d8429b21f293d959783213af474c93a2fe7e815e179`.
Oráculo `.godot/move_gap_checks/sources.json` SHA
`58a7819b20adff6585e7139219740c3a90de28483554d486c99813d465e63a03`;
resultado focal SHA `320c6a78523ab3edc5e334ba9a7d450ca93469b7409e8bda144a36858e2a45fa`.
Renderer global idéntico; tiras/muestras GPU de los 1.794 clips anteriores
idénticas. Sus notas, incluidas las diez excepciones visuales, se conservan con
prueba por clip. Solo compuestas/vistas dos láminas delta de cuatro familias.

**1.802 clips anotados: 1.782 sampled_no_obvious_issue, 12 needs_motion_review y
ocho suspected_issue**, cero nuevos pendientes de primer vistazo. Los ocho nuevos
no muestran defecto evidente en tres momentos; no se certifica su película
continua, gusto artístico ni sincronización mecánica. Cola visual sin cambios:
20 clips / diez IDs, separada de las 29 excepciones de conversión.

Reproducción local desde D: (si falta la caché suplementaria, primero fetch):

```powershell
python tools/visual/fetch_move_gap_sheets.py
python tools/visual/build_move_batch.py --source-root 'D:/Proyectos/Pokemon Calvo Auditoria Visual/comparacion_ataques_v1'
python tools/visual/audit_move_gap_sources.py --source-root 'D:/Proyectos/Pokemon Calvo Auditoria Visual/comparacion_ataques_v1' --baseline .godot/move_contact_review/a5a29f4db6b47005/catalog_index.json
& 'C:/Godot/4.7/Godot_v4.7-stable_win64_console.exe' --headless --path . --script tests/visual/move_gap_test_runner.gd
python -m unittest discover -s tools/visual -p 'test_move*.py' -q
```

Sin cambio de los cinco enlaces de combate, datos raw/normalized, mecánicas, IA,
workflows o biblioteca F:. Sin commit/push/merge/CI nueva. La CI en el HEAD
previo no certifica los cambios locales. Siguiente grupo: buscar revisión de
autor con atlas/celdas completos o equivalente explícito para esos cinco atlas,
y verificar los dos fondos reales; no repetir el diagnóstico ni bajar guards.

## Antecedente: conversión agrupada de los 30 hue — 2026-10-24

Petición «sigue»: se aborda una causa compartida de conversión, no otra lista
manual de dos ataques. Los 30 IDs antes bloqueados por `unsupported_hue` pasan
con sus dos exports: **886/919 IDs, 1.794 clips, 897 familias, 29 shards**. Cada
pareja sigue siendo atómica: las demás validaciones no se relajan ni un lado
correcto tapa al otro. Restan **33 excepciones** (19 etiquetas, ocho patrones,
cinco hojas, un modo de celda). No hay nuevas rutas ni soporte mecánico añadido.

### Semántica y seguridad del color

Contrastadas fuentes primarias: [Essentials BattleAnimationPlayer](https://github.com/Maruno17/pokemon-essentials/blob/master/Data/Scripts/011_Battle/007_Other%20battle%20code/007_BattleAnimationPlayer.rb)
aplica `animation.hue` al bitmap del efecto; reemplaza aparte las celdas de cuerpo
por sus bitmaps originales. Sus fondos se cargan por separado.
[Bitmap::hueChange](https://github.com/Ancurio/mkxp/blob/master/src/bitmap.cpp)
y el [shader HSV de mkxp-z](https://github.com/mkxp-z/mkxp-z/blob/dev/shader/hue.frag)
confirman giro HSV positivo, grados enteros y vuelta modular de 360 grados.
Son referencias de comportamiento consultadas; no se copia su código GPL al
proyecto. El conversor propio usa `colorsys` de Python, conservando la precisión
de color hasta redondear a ocho bits; se admite diferencia RGB de un byte frente
al oráculo independiente de Godot, no diferencia de alpha.

`move_sheet_hue.py` rota RGB sin cambiar geometría, escala, alpha, tamaño o número
de frames. `build_move_batch.py` hornea copias PNG RGBA content-addressed en
`.godot/move_batch_catalog/hue_sheets/`; las fuentes no se reescriben. El hue cero
conserva el PNG/contrato original, ni siquiera se vuelve a guardar. Cache por hash
de fuente + grados normalizados; helper incluido en la huella de generación.
Cada clip nuevo con color registra política, grados, SHA original y SHA derivado.
BG/FG conservan sus hojas sin hue incluso si comparten nombre con el efecto.
No se cambia el shader ni renderer global; no hay filtro de pantalla que tiña
por error Pokémon/fondos. Se rechazan bool, texto, floats, None y valores no finitos.

De los 60 exports nuevos, **59 usan hue y uno no**: `meteor_assault/front` ya
es cero en la fuente, mientras el otro lado usa 215. Se respeta el recurso, no
se fuerza simetría. Son 28 combinaciones hoja/hue únicas, no 60 PNG distintos.
Todos los arrays de celdas nuevos son idénticos al export; los 1.734 contratos
previos completos y sus tiras/muestras GPU siguen idénticos.

### Pruebas y evidencia reproducible

`audit_move_hue_sources.py` enlaza cada export nuevo con Marshal inerte leído por
el helper local auditado, comprueba cuarentena de origen, unicidad de etiqueta,
celdas, hue, SHA original/derivado y **todos los 38.707.200 píxeles de alpha**,
dimensiones y datos canónicos. No ejecuta Ruby descargado.
`move_hue_test_runner.gd` calcula el color esperado independientemente mediante
HSV de Godot: **114.688 muestras / 458.838 checks PASS**. Alfa exacta, RGB ±1/255.
Pruebas Python: primarios/secundarios, signo, vuelta modular, tonos grises/negro/
blanco, 256 valores de alpha, cero idéntico, no mutación, cache/repetibilidad,
BG sin hue y rechazo de datos malformados/patrones aún inexistentes.

Barridos completos finales: **5.298.025 headless / 5.313.187 GPU PASS**, 116.998
estados frame/lado/arena y 1.794 capturas técnicas. Prioridad **445.698 GPU PASS**,
708 capturas; combate 407; pantalla 8.025 GPU; cámara 4.630 GPU; haz 1.372;
selector cinco; **34 tests Python PASS**. No implica comparar cada movimiento
contra un juego oficial ni aprobar estéticamente todos sus frames.

Pack **`generation_130268d20a3cf430`**, índice SHA
`44e83333eef36d88bc79924aa2be73759c857d5e3bd510fa3c2b46eb2f6e97cc`.
Captura **`a5a29f4db6b47005`**, `captures.json` SHA
`e61eca82702bf79a2c558dd57ec00d739bf371db90a0f01dfa539d375f90bcc5`;
renderer inalterado `9636af2c5cba04511e4dbb48c92411564bf64bf2e738695a39aabd5542f55334`.
Oráculo `.godot/move_hue_checks/sources.json` SHA
`6fe21c47aad2c83b0a7de67b3d924d363fb4543fa12cea41579bca869ad22d11`,
y `result.json`, cero fallos.

La composición completa tiene 90 páginas. Para no repetirlas, el modo explícito
`--same-renderer-clips` permite reagrupar las notas por clip SOLO con snapshots
reales de renderer idénticos, contratos completos idénticos, hojas PNG reales
revalidadas, captura/muestras/título idénticos y tableros fijados por SHA. Protege
notas nuevas, conserva excepciones y es idempotente; pruebas con renderer,
snapshot, muestras y PNG alterados. No cambia la ruta estricta de prueba de
equivalencia para renderers diferentes ni hereda revisión a vecinos nuevos.

Migradas **1.734** notas; compuestas SOLO las 30 familias pendientes en cuatro
láminas (`delta_sheets_20`), todas observadas. Sus 60 anotaciones se trasladan al
registro completo por la misma prueba individual. Resultado **1.794 anotados:
1.774 sampled_no_obvious_issue, 12 needs_motion_review, ocho suspected_issue**.
29 movimientos nuevos no muestran defecto evidente en tres muestras; Ala Mortífera
se aparta ambos lados por ascenso fuera de pantalla/retorno y haz cruzando borde.
Puede ser la coreografía original: no se declara error confirmado ni se le aplica
la base afín de Rayo Umbrío automáticamente. Cola: **20 clips / diez IDs**,
nueve anteriores más `oblivion_wing`; no se observó una película continua.

Comandos desde la raíz D: (Godot 4.7 local, Python 3.12 + Pillow):

```powershell
python tools/visual/build_move_batch.py --source-root 'D:/Proyectos/Pokemon Calvo Auditoria Visual/comparacion_ataques_v1'
python tools/visual/audit_move_hue_sources.py --source-root 'D:/Proyectos/Pokemon Calvo Auditoria Visual/comparacion_ataques_v1' --baseline .godot/move_contact_review/de7c04174963c920/catalog_index.json
& 'C:/Godot/4.7/Godot_v4.7-stable_win64_console.exe' --headless --path . --script tests/visual/move_hue_test_runner.gd
python -m unittest discover -s tools/visual -p 'test_move*.py' -q
```

Fuentes/artistas/créditos siguen siendo los del pack Gen 9 ya registrado: no se
descarga nuevo arte, no se compra ni presume licencia comercial. Arte derivado
en caché ignorada, no redistribuido. Sin commit/push/merge ni cambio de workflows.
Datos raw/normalized, dominio, IA, cinco rutas de combate y biblioteca F: intactos.
Siguiente grupo: ocho patrones/cinco hojas + modo de celda aparte; las 19 etiquetas
Let's Go/Torque/Z especial siguen fuera de prioridad artística según usuario,
sin borrarlas de datos/pool ni fingir animaciones nativas mediante fallback.

## Antecedente: contraste de cinco trayectorias y base afín del haz — 2026-10-24

Petición «sigue»: investigadas conjuntamente las cinco dudas de trayectoria/
escala. **Estado vigente: 1.734 clips anotados; 1.716 sin fallo evidente en
muestras, diez necesitan contexto/movimiento y ocho sospechosos: 18 apartados /
nueve IDs, no 18 defectos confirmados.** 856/919 IDs convertidos; 63 excepciones
sin cambio. Registro `.godot/move_contact_review/de7c04174963c920/sheets_20/index.md`.

### Comparación geométrica, no falsa certificación de combate

`move_trajectory_probe.gd` compara diez clips de cinco IDs en tres cámaras:
puestos fijos 512×384 y adaptación 640×360/400×300, todos los frames. La referencia
fija usa el mismo catálogo de cuerpos, no una captura de Essentials ni del juego
oficial; el lado sintetizado sigue indicado como tal. Oráculo de centros independiente
de map_position, VFX aislados en viewport transparente, discos de ancla y máscara
alfa de la silueta del cuerpo con sus transformaciones de frame. Usa la pose fija
del laboratorio, no una hitbox de combate. Calibrados disco opaco/transparente,
64 píxeles de cuerpo, ausencia de VFX y cuerpo invisible. Las medidas son
diagnósticos de solapamiento visual: NO deducen impacto, daño o soporte mecánico.

Resultado final: **1.248 estados frame/lado/cámara / 13.655 checks GPU PASS**.
`.godot/move_trajectory_checks/885e8512d3f02db4/result.json`, SHA
`0168e4721f2bd4a7f7e1263b0d6b332aea3eb87572e497865c03709213fb86b3`.
Compositor `build_move_trajectory_sheets.py`: matriz completa/única de 30 variantes,
orden/cobertura de frames, índices/renderer/runner actuales y PNG fijados por hash.
Dos láminas de ambos lados observadas. Selecciona automáticamente el pico real
de máscara corporal además de los intervalos, para no saltar un cruce de un frame;
no inventa por ello un «momento de daño». Tests de matriz incompleta/duplicada,
modos desconocidos, orden/conteo/muestras incorrectos y pico fuera de rango PASS.

Hallazgos:

- Orbes Espectro: trayectoria y expansión sobre el objetivo coherentes; 20 frames
  con solapamiento de silueta en ambas vistas y arenas adaptadas. No deriva un
  fallo de colocación por ser grandes los orbes finales.
- Cañón Dinamax/Rayo Infinito: son haces muy grandes también en referencia.
  En 640×360 solapan la silueta durante 50/55 frames por lado; referencia 50/51.
  Se conserva el recurso, sin reducirlo arbitrariamente ni aprobar arte final.
- Cuchilla Solar: comprobar solo el centro del Pokémon daba un falso indicio de
  fallo. La silueta SÍ se cruza brevemente: pico en f17 back y f16 front, misma
  fase que la referencia. Capturas de esos picos incluidas y observadas; en
  640×360 el máximo aproximado de silueta es 16 % / 23 %. No es una métrica de
  daño. Se cierra la duda espacial, no se certifica toda la fluidez o la estética.
- Rayo Umbrío: defecto real de adaptación. Se trasladaba el centro del sprite
  por la cámara afín pero se mantenía la rotación/escala uniforme de su haz
  oblicuo. En 640×360 la cobertura del disco de ancla caía de 15 a ocho frames,
  con pico 66 % / 43 %, frente al 100 % de referencia. Diagnóstico anterior
  conservado en `.godot/move_trajectory_checks/833e3f48d0e48716/`.

### Corrección limitada y prueba de geometría completa

Dos exports de Rayo Umbrío fijados por SHA de TODO el array (Move/OppMove);
`native_particle_geometry` agrega política `pinned_canonical_affine_particle_basis_v1`
y patrones 0–4. Si cambia el array/foco nativo, rechaza la adaptación. No modifica
celdas, hojas, tiempos, cuerpos, clasificación o la fuente. Solo dos contratos
ganan metadatos/flag; los demás 1.732 conservan sus contratos completos.

Renderer aplica a esas partículas declaradas la misma base afín que a sus centros:
`A * rotación * escala`, con pivote/crop preservados. No se aplica a todos los
haces, ni a cadenas rígidas, ni a cuerpos. Normaliza enteros de patrones leídos
de JSON y rechaza declaraciones inválidas, focos distintos de 3 y exports
reflejados sintéticamente. Resetea skew al reutilizar un slot para que la
deformación no contamine el siguiente cuerpo/clip.

Nuevo `move_beam_geometry_test_runner.gd`: antes FAIL / después **1.372 PASS**,
todos los frames, ambas vistas, tres arenas y tres parejas de especies.
Compara cuatro esquinas y centro con la transformación independiente de cada
punto de fuente, no map_position contra sí misma. Antes:
`.godot/move_beam_checks/f525fb6474e0e23f_1f7ea312de81/`; después:
`.godot/move_beam_checks/d1fd83c7dc3e7b7a_9636af2c5cba/`.
Tras corrección, ancla cubierta **15/35 frames y pico 100 % en ambas vistas y
las dos arenas**, igual que referencia; silueta solapada durante esos 15 frames.
Conserva el salto del emisor que ya existía en la puesta en escena original.

### Regresión, revisión y memoria fijada

Pack `generation_919cbce496ac8777`; índice SHA
`d1fd83c7dc3e7b7aabefc6288ccbfa8e763b6ba8ea1f12ed60c4fb0dc9f29aad`.
Renderer SHA `9636af2c5cba04511e4dbb48c92411564bf64bf2e738695a39aabd5542f55334`.
Barridos finales: **5.108.930 headless / 5.123.576 GPU PASS**, 112.934 frame/lado/
arena; siete rechazos adicionales de geometría inválida. Regresiones: prioridad
445.698 GPU / combate 407 / pantalla 8.025 GPU / cámara previa 4.630 GPU /
selector cinco PASS; 27 tests Python PASS. El fixture de export reflejado se
configura explícitamente como reflejado, no supone que Absorber rival lo sea.

Comparador de dibujo reforzado: incluye matriz completa, no solo rotación/escala
que podrían omitir skew; `--baseline` permite elegir el snapshot anterior real.
Contra `799684ccaf13e9d0`, **1.732 clips equivalentes / dos distintos**, todos los
frames/dos arenas (112.934). Esto también descarta contaminación posterior de slots.
Prueba SHA `a1daa5856d96f09b409d590161c1c00f9e210bb57069226d0774dfd5048a8e20`.

Capturas vigentes `de7c04174963c920`; manifiesto SHA
`6516acdd253833c9ae09ad21305e49bbacca9c47dba3ac20dd06c194819529d0`.
Solo las dos tiras de Rayo Umbrío cambian; se conservaron **1.732** anotaciones
con prueba completa por clip/hojas/fuente/muestras GPU, matrices y hashes. Las
dos tiras nuevas se observaron en `delta_sheets_20` y en comparación de cámaras.
Se anotaron los diez clips contrastados sin dar nueva aprobación a sus vecinos.
Índice completo, snapshot del renderer y prueba de equivalencia quedan dentro
de esa generación. No se aprueba toda una página nueva porque un clip sea igual.

Salen las cinco dudas espaciales de la cola focal; «sin fallo evidente en muestras»
NO significa arte final/fluidez/daño certificados. Cola de nueve IDs, ambos lados:

| Pendiente | IDs | Clips |
| --- | --- | ---: |
| Presentación externa de clima/cuerpo/salida | chilly_reception, hail, rain_dance, snowscape, substitute, transform | 12 |
| Arte/legibilidad/equivalente genérico | armor_cannon, gigaton_hammer, max_flutterby | 6 |

Los seis externos no adquieren mecánica por tener un laboratorio visual.
Maxibicho aún necesita una referencia de Bicho genérica sin otros Pokémon
incrustados. Siguiente grupo de conversión: 30 hue dentro de las 63 excepciones;
no repetir por defecto las cinco trayectorias ya contrastadas. Reproducir el probe
con Godot GPU, después compositor con `--report`; focal y barridos siguen siendo
necesarios al cambiar geometría. Las cinco rutas de combate siguen intactas.

Datos canónicos/raw/normalized, originales F:, learnsets, IA, reglas y workflows
sin cambios en este tramo. Sin commit/push/merge/descargas de arte. Verificados
19 checks SUCCESS del HEAD exacto `0902de4c10d34a2a451c9acad83fbfea765ef270` antes
de editar; no certifican estos cambios locales posteriores.

## Antecedente: captura temporal de los apartados y anclas rígidas rivales — 2026-10-24

**Estado vigente: 1.734 clips anotados; 1.706 sin fallo evidente en muestras,
20 necesitan movimiento/contexto, ocho sospechosos. 28 apartados / 14 IDs, no
28 defectos confirmados.** 856/919 IDs convertidos; 63 excepciones sin resolver.
Registro `.godot/move_contact_review/799684ccaf13e9d0/sheets_20/index.md`.

Petición «sigue»: añadidos `move_temporal_review.gd` y
`build_move_temporal_sheets.py`. Seleccionan los apartados reales del registro
vigente; no vuelven a capturar todo el catálogo para investigar 17 IDs. Preflight
exige manifiesto/láminas/renderer/índice correctos; captura nativa GPU de TODOS
los frames, verifica reloj de 20 fps en cada intervalo y limpieza de sprites,
capas y píxeles respecto a arena vacía de referencia. Eso no prueba la ejecución
de mecánicas ni que el usuario deba reaparecer: Fría Acogida sale intencionadamente.

Evidencia temporal anterior al ajuste de anclas: **34 clips / 1.300 frames /
5.879 checks PASS**, en `.godot/move_temporal_checks/d2e85ca7c766e1f3/`.
Reporte SHA `f598b2c226dd6445b916bba03f17228e3edc0eae948ac1e0e5e9fd2e3a4b487f`.
Cuatro láminas `sheets/temporal_01_back/front` y `temporal_02_back/front` observadas:
17 familias, ocho tiempos por clip (272 miniaturas); se guardan también todos
los PNG nativos. Ocho muestras no equivalen a haber visto reproducción continua.
El compositor fija hashes, orden/tiempos, fuente, cobertura completa, limpieza,
extremos y pico de partículas para no saltarse un impacto breve. Tests rechazan
captura fallida/obsoleta/incompleta, IDs duplicados, orden incorrecto, limpieza
fallida y PNG modificado. No asigna aprobación artística automáticamente.

### Hallazgos agrupados y corrección

- Llama Final/Electropalmas: la fuente oscurece al usuario durante 61 frames
  con tono RGB <= -128, f14–74 (3,05 s de 4 s). No es un color perdido para
  siempre: f79 muestra ambos cuerpos, opacidad render 1 y tono cero; se aprecia
  el retorno en las láminas y cleanup GPU pasa. Se conserva esa duración de la
  fuente, sin acortar una animación para hacerla parecer aprobada.
- Cadena Virulenta rival: el export usa foco 1 pero está dibujado alrededor del
  puesto canónico trasero (objetivo). Se ligaba al centro frontal y quedaba a la
  derecha. Debe conservar una transformación rígida respecto al puesto trasero:
  trasladar foco 1→2 en sus 169 celdas positivas. No estirar distancias entre
  piezas de la cadena ni tocar la escala o los PNG.
- Fría Acogida rival: solo las once celdas del bocadillo, patrón 2, están
  dibujadas en el puesto frontal pero marcadas con foco 2 trasero. Adaptación
  2→1. Las siete celdas de hielo, patrón 1, sí pertenecen al puesto trasero y
  quedan intactas. La retirada/clima externo sigue siendo un apartado separado.

Se amplía la política ya existente de exports nativos fijados por SHA de todo el
array, no se cambia el renderer global ni se infieren focos por cercanía. Política
`pinned_native_particle_slot_anchor_v1`, con filtro por patrón para el bocadillo.
Se cuentan campos antes de mutar porque Marshal puede compartir el mismo objeto
cel entre frames y deepcopy conserva sus alias. Test con referencias compartidas,
cuerpos intactos y patrón excluido evita contar/cambiar solo la primera aparición.

Primer candidato descartado: convertir estos objetos rígidos al foco afín 3
colocaba las cadenas sobre el objetivo, pero abría huecos entre sus tiles, al
escalar distancias y no las imágenes. Generación `generation_b0f49dbef6eb247c`
NO es vigente. Se detuvo su barrido GPU y se sustituyó por anclas rígidas; no
se heredó esa revisión como arreglo válido. El oráculo final exige posición
respecto al puesto correcto Y escala uniforme, no solo cercanía al objetivo.

Prueba focal ampliada: todos los frames, dos arenas, tres parejas de especies,
ambos lados, cinco familias (incluidas las tres correcciones anteriores).
Oráculo independiente de `map_position`: FAIL en índice original y **4.630 PASS
GPU** en el final. Antes: `.godot/move_camera_checks/73396d5c2711242a_fb1f6b3f6938/`;
después: `.godot/move_camera_checks/f525fb6474e0e23f_fb1f6b3f6938/`. Tiras ampliadas
antes/después observadas: bocadillo junto al emisor, hielo sin mover y cadenas
continuas sobre el objetivo. Guardado por índice + hash del test para no
sobrescribir resultados al ampliar el focal.

Pack final `generation_602a92ba9cd5dee8`, índice SHA
`f525fb6474e0e23f15cfa68d53d3cf5cfa89e1ed2c5858ac264674b45bbc588f`.
Comparación completa contra `a3427d2cdeb633d9`: SOLO dos clips cambian,
`chilly_reception/front` y `malignant_chain/front`; SOLO 180 campos de foco
(11 + 169) y sus metadatos de auditoría. Otros 1.732 clips, cuerpos, posiciones,
escalas, rotaciones, tiempos, capas y hojas idénticos. No hay nueva ruta de combate,
clima, retirada, daño o RNG. Clasificaciones y datos canónicos intactos.

Reproducir la captura temporal antes de modificar el registro:
`Godot --path . --script tests/visual/move_temporal_review.gd --resolution 64x64 --disable-render-loop --disable-vsync --max-fps 0`;
después `python tools/visual/build_move_temporal_sheets.py --report <salida>/result.json`.
El oráculo de cámara acepta `-- --capture --index=res://<snapshot>/catalog_index.json`
para reproducir el baseline, manteniendo los shards en `.godot/move_batch_catalog/`.
La evidencia temporal anterior es HISTÓRICA para los dos clips cambiados; para
ellos prevalece el focal posterior. Los otros 32 conservan contrato/renderer.

### Cierre de revalidación y cola actual

Repetida la captura temporal sobre el índice final: **34 clips / 1.300 frames /
5.879 PASS**, `.godot/move_temporal_checks/b40991f55c3e7b6c/`. Reporte SHA
`da7d1d079d940a877a871094ad68afc4fb569a41f519dfdc3752a74d6268d059`;
snapshot exacto del registro usado para seleccionar en `source_review_snapshot.json`.
Comparación por píxeles de cada frame: solo cambian los once del bocadillo rival
y 25 frames de cadenas rivales; otras 32 secuencias completas idénticas. De cuatro
láminas temporales finales, solo cambian las dos front; observadas de nuevo.
No se hereda la película cambiada desde las láminas anteriores.

Barridos finales completos: **5.108.923 headless / 5.123.569 GPU PASS**, 112.934
frame/lado/arena, 1.734 capturas técnicas. Regresiones: prioridad 445.698 GPU,
combate comunitario 407, pantalla/capas 8.025 GPU, selector cinco, 22 tests Python
PASS. Datos canónicos mantienen raw `2efc1538081e7849d6e04555570ca28c19b13f09f0fe0c7ce38329881972f24a`
y normalized `719d14c082bdba03b26e801d23fb8887d0a0f4376348cf4a27e79a4b0a3c08b3`.

Capturas generales `799684ccaf13e9d0`, manifiesto SHA
`d542af2515fa3098d41b393ce82f2e593fd9beeab0f28283fba09eda5f9e90dc`.
Solo dos tiras y dos páginas (`batch_01_front`, `batch_08_front`) cambian respecto
a `a3427d2cdeb633d9`: 86 páginas idénticas conservaron **1.694** anotaciones con
el migrador estricto, índice anterior fijado, contratos completos/hojas y muestras
GPU idénticos y renderer igual. Dos páginas completas vistas de nuevo, manteniendo
sus excepciones. Después se anotan los 34 clips focales por evidencia temporal
real y hash de lámina; no se aprueba automáticamente a sus vecinos.

Salen de la cola las dudas de restauración de burn_up/double_shock y colocación
de malignant_chain. Eso no certifica gusto artístico, fluidez completa o mecánica.
chilly_reception conserva su apartado externo aun con bocadillo corregido.
Cola de 14 IDs, todos por ambos lados:

| Grupo pendiente | IDs | Clips |
| --- | --- | ---: |
| Trayectoria/escala/puesta en escena | astral_barrage, dynamax_cannon, eternabeam, moongeist_beam, solar_blade | 10 |
| Presentación externa de clima/sprite/salida | chilly_reception, hail, rain_dance, snowscape, substitute, transform | 12 |
| Arte/legibilidad/equivalencia genérica | armor_cannon, gigaton_hammer, max_flutterby | 6 |

Maxibicho conserva Pokémon incrustados del recurso Z: buscar equivalente genérico
de Bicho, no redibujar/borrar nombres del arte ni dar ese recurso como final.
Las 63 excepciones de conversión (incluidos 30 hue) siguen como cola independiente.
Sin nueva descarga de arte, tocar F:, regenerar datasets, cambiar reglas,
learnsets, IA o workflows. Sin commit/push/merge. Verificados 19 checks SUCCESS
del HEAD exacto `0902de4c10d34a2a451c9acad83fbfea765ef270` antes de editar;
no certifican el árbol local posterior. Se conserva todo el historial anterior.

## Antecedente: fades conservados y pantalla sin línea usuario-objetivo — 2026-10-24

Investigación y corrección agrupadas de Día Soleado y Deseo, extendidas por causa,
no por listas manuales de ataques. Resultado: **1.734 clips anotados / 5.202 muestras,
1.700 sin fallo evidente en muestras, 26 necesitan movimiento y ocho sospechosos**.
Los 34 apartados son 17 IDs por ambos lados; cero pendientes de primer vistazo.
No son 34 defectos confirmados. Las 63 excepciones de conversión siguen pendientes.
Las cifras de 38/19 y el registro `84cfcc27cf596d4c` de la siguiente sección son
antecedentes anteriores a esta corrección, no el estado vigente.

### Causas y alcance

Contrastado el [reproductor original de Essentials](https://github.com/Maruno17/pokemon-essentials/blob/master/Data/Scripts/011_Battle/007_Other%20battle%20code/007_BattleAnimationPlayer.rb).
Avanza transiciones activas antes de procesar eventos del frame; cargar BG/FG no
elimina fades programados. El helper de conversión anterior sí los cancelaba.
Día Soleado tiene Mod y Set en f0: terminaba con opacidad cero en todos los frames.
Nuevo baker local `tools/visual/move_layer_timing.py`, sin modificar fuentes externas:
preserva esas transiciones y separa BG/FG. El builder fija su hash en el índice.
Oráculo de opacidad de Día Soleado: f0/1/10/11/12/19 = 0/20/200/200/175/0.
No se afirma equivalencia completa con toda la semántica del reproductor original:
se conserva el modelo de interpolación por propiedad; se corrige la cancelación.

Deseo sí tenía estrellas opacas en su hoja. Foco 4 de pantalla se adaptaba a la
línea entre actores; cuando usuario y objetivo son el mismo, dicha línea es cero.
Así desaparecían sus partículas por escala cero. Renderer: solo foco 4 + destino
usuario usa ahora el espacio fijo 512×384, ajuste uniforme y centrado en viewport,
sin depender de distancia entre actores. El resto de cámaras/mosaicos no cambia.
Ocho clips afectados por esta causa: Deseo, Sustituto, Mismo Destino, Novena Potencia,
ambos lados. Mantiene tamaño proporcional, no redibuja ni cambia hojas.

Nuevo focal `move_self_screen_test_runner.gd`: reproducción anterior FAIL;
**8.025 PASS GPU** tras el arreglo, todos los frames de diez clips / dos arenas,
oráculos independientes de posición y escala de pantalla, fade y estrellas distintas.
Tiras antes: `.godot/move_layer_checks/fd6f5b114c04_6edf0bd2bf2a/`; después:
`.godot/move_layer_checks/73396d5c2711_1f7ea312de81/`. Tres tests Python de timings
incluyen Set durante fade, BG/FG independientes, desplazamiento simultáneo,
destino cero y aislamiento de snapshots. El programa externo de investigación,
archivo de recursos y sus fuentes permanecen intactos.

### Revalidación y continuidad de revisión

Catálogo `generation_12f04d8d133befc0`; índice SHA-256
`73396d5c2711242aa9308ebe44cdf8b089b1d1bd920905cff90264cd86c028f2`.
Barridos completos: **5.108.923 headless / 5.123.569 GPU PASS**, 112.934 frames/
lado/arena. Selección prioritaria 445.698 PASS GPU (708 capturas), combate
comunitario 407 PASS, cámara focal 1.678 headless / 1.684 GPU PASS, selector cinco PASS;
17 tests Python PASS. Comprobaciones locales, no CI del árbol sucio.

Comparador `move_render_equivalence_runner.gd` ejecuta renderer y catálogo anterior/
nuevo sobre todos los frames en dos arenas. Compara entradas visibles de dibujo,
texturas/shaders por hash, transformación, regiones, orden, opacidad/tono/color:
**1.678 equivalentes / 56 distintos**, 112.934 comparaciones. No sustituye ver
movimiento. Contratos completos de clips: cambian 52 por el horneado de capas;
tiras GPU muestreadas: cambian 60, pues el selector también puede elegir otro
frame tras cambiar estados. Nada de estas imágenes nuevas se hereda sin revisión.

Migrador: por defecto sigue rechazando renderer distinto. Opción explícita
`--render-equivalence` exige reporte completo sin fallos, hash del runner actual,
ambos índices/renderers fijados, cobertura única y número de frames esperado;
además contrato completo/hojas idénticos, datos canónicos iguales, tira GPU,
muestras/título y archivos reales con hashes correctos. Conserva SOLO notas de
ese clip, no nuevos vecinos ni páginas completas. Protege revisiones del destino,
conserva excepciones y es idempotente. Pruebas rechazan prueba incompleta/adulterada,
datos distintos aunque den igual miniatura, cambio de muestras y PNG adulterado.

Conservadas **1.674 anotaciones**. `--pending-only` compone únicamente familias
pendientes y su lado parejo para contexto: **cuatro láminas delta, 31 familias,
62 clips (60 cambios y dos vecinos parejos)** observados de nuevo. Sus notas por
clip enlazan la lámina delta y su SHA, no afirman nueva revisión del resto de
la página general. Antes y después, 88 páginas generales / 1.734 tiras preservadas.

Capturas vigentes `a3427d2cdeb633d9`, SHA del manifiesto:
`84796a87dc5e7ff663b921ca419e4cd4fc4f9b7b077477acb294a8bda5ccec39`.
En esa carpeta quedan índice completo, snapshot del renderer y prueba de equivalencia
SHA `9be325c5e9f34c695c2b6f8efdc810c01a515ac5ef33d9da803cc687fe5c1ff6`.
El baseline conserva también índice y renderer anterior. Registro actual:
`.godot/move_contact_review/a3427d2cdeb633d9/sheets_20/index.md`; delta en
`delta_sheets_20/`. Verificados hashes/membresía de todas las tiras y láminas.

### Qué queda y qué NO cambia

Día Soleado y Deseo salen de la cola de sospechas al desaparecer sus causas y
verse las capas/estrellas; esto no certifica toda su fluidez o sus mecánicas.
Sustituto ya muestra muñeco, pero se mantiene para transición/sustitución visual
externa y persistencia del cuerpo. Mismo Destino recupera sus partículas sobre
negro; Novena Potencia muestra la composición original de evoluciones de Eevee:
es un recurso Z específico, NO una referencia genérica admitida para cualquier Pokémon
ni una modificación del pool final. Cañón Armadura mantiene la duda artística
del motivo del impacto original, no un nuevo fallo del renderer demostrado.

Cola focal vigente de 17 IDs: armor_cannon, astral_barrage, burn_up, chilly_reception,
double_shock, dynamax_cannon, eternabeam, gigaton_hammer, hail, malignant_chain,
max_flutterby, moongeist_beam, rain_dance, snowscape, solar_blade, substitute, transform.
Revisar agrupando trayectoria/escala, oscurecimiento, clima/contexto, arte/equivalentes.
Después, 30 hue y demás causas de las 63 excepciones de conversión. No repetir
el primer vistazo de las 88 páginas por defecto.

Reproducción: reconstruir con `build_move_batch.py --source-root` como en el runbook;
ejecutar focal con GPU `-- --capture`, barrido GPU, captura/compositor y regresiones.
Para conservar evidencia: `build_move_contact_sheets.py --migrate-from` con
`--review-folder`, `--previous-index` anterior y `--render-equivalence` fijada;
después `--batch-size 20 --pending-only` y observar antes de anotar. El gate
prioritario usa render loop normal: NO pasar `--disable-render-loop` a un test
que espera `frame_post_draw`; sí lo usan los capturadores con `force_draw` explícito.

Clasificaciones DATA_ONLY/UNSUPPORTED, cinco rutas de combate, raw/normalized,
learnsets, IA, F: y workflows no cambian en este tramo. Sin commit/push/merge.
Se verificaron 19 checks SUCCESS del HEAD exacto `0902de4c10d34a2a451c9acad83fbfea765ef270`
antes de editar; no certifican estos cambios locales posteriores.

## Corrección compartida de foco en tres exports rivales — 2026-10-24

Petición «sigue»: investigada y corregida la causa de los desplazamientos de
`hyper_drill/front`, `rolling_kick/front` y `upper_hand/front`. No se redibujan
sprites ni se modifican ataques/reglas. Estado vigente del registro: **1.734 clips
/ 5.202 muestras, 1.696 sin fallo evidente en las muestras, 30 necesitan movimiento,
ocho sospechosos; 38 apartados de 19 IDs, todos por ambos lados.** Cero pendientes
del primer vistazo. Las 63 conversiones en cuarentena no cambian. Esto cierra
estas tres sospechas de colocación, no certifica arte/fluidez/combate completos.

### Causa, alcance y prueba reproducible

Contraste con el [reproductor de Essentials](https://github.com/Maruno17/pokemon-essentials/blob/master/Data/Scripts/011_Battle/007_Other%20battle%20code/007_BattleAnimationPlayer.rb)
y su [llamador de animaciones](https://github.com/Maruno17/pokemon-essentials/blob/master/Data/Scripts/011_Battle/004_Scene/004_Scene_PlayAnimations.rb).
Los exports OppMove conservan los puestos canónicos trasero/delantero; estos tres
usan partículas con foco 1, pero coordenadas de impacto hacia el puesto trasero.
En la cámara canónica ambas traslaciones pueden ser identidad; al cambiar nuestra
distancia/altura entre Pokémon aparece el desplazamiento. No es una textura
perdida ni se justifica invertir TODO OppMove o cambiar el motor global.

`tools/visual/build_move_batch.py` adapta las partículas de esos exports al foco
3 (línea canónica), mediante una sola política explícita y el SHA-256 del array
de frames de cada fuente. Si el array cambia, rechaza la adaptación y deja el
par en cuarentena, no aplica una corrección silenciosa. No infiere focos por
proximidad para todos los ataques. Copia profunda antes de normalizar para no
mutar datos de la fuente inerte. Registro `camera_repair` y bandera de auditoría
en cada clip corregido; imágenes/archivo de origen quedan intactos.

Comparación exhaustiva anterior/nueva: solo esos tres clips cambian, en 128/5/14
celdas respectivamente (147 en total). Solo campo de foco 1→3 y metadatos de
adaptación; todos los demás campos, cuerpos, frames, hojas, clasificación y los
otros 1.731 clips son idénticos. Prioridades de partículas 0/1: el cambio de foco
no cambia su profundidad relativa. Raw/normalized mantienen hashes anteriores.

Nueva prueba `tests/visual/move_camera_repair_test_runner.gd`: oráculo independiente
de la línea canónica, NO map_position comparada consigo misma; todos los frames,
dos arenas (640×360/400×300), tres parejas (Ogerpon/Charizard, Pikachu/Wailord,
Charizard/Ogerpon), ambos lados. Falla en el índice anterior; tras la adaptación,
**1.684 comprobaciones GPU PASS**, incluidas seis tiras nativas antes/después.
Evidencia focal anterior `.godot/move_camera_checks/2455bf1d94b3f2f6/` y corregida
`.godot/move_camera_checks/fd6f5b114c047824/`. Tiras ampliadas comparadas visualmente:
los impactos ya se superponen/alinean con el objetivo. No certifica sincronía
con daño ni toda la legibilidad temporal con una tira de tres imágenes.

### Revalidación sin repetir el catálogo a mano

Pack actual `generation_754ad3a47d8239f2`, índice SHA-256
`fd6f5b114c04782471d9dee742edfbcfb668dd5ddbe6e5793878aca67d1edb5a`.
Barrido completo de 112.934 frame/lado/tamaño: **5.108.923 headless / 5.123.569 GPU
PASS**, 1.734 capturas técnicas. Regresiones de selección prioritaria 444.847 y
combate comunitario 407 PASS; 13 tests Python y cinco del selector PASS.

Recapturados 1.734 clips / 5.202 muestras. Generación vigente **`84cfcc27cf596d4c`**,
manifiesto SHA-256 `0677dbae6a291814556cdea2c5e40629acee65b0ae8a3fc7d173ec7fc8c90be4`.
Solo tres tiras cambian. Solo páginas `batch_20_front`, `batch_32_front` y
`batch_42_front` cambian: observadas completas de nuevo y anotadas en su propio
registro, sin heredar aprobación. Las otras 85 páginas son byte-idénticas.

El migrador mantiene por defecto el rechazo ante índices distintos. Nueva opción
explícita `--previous-index`: exige índice anterior con el hash del manifiesto
antiguo, ambos manifiestos de capturas/índices correctos, renderer igual, hashes
de todos los shards verificados y datasets iguales, contrato COMPLETO por clip + hojas
(hash/dimensiones), muestras GPU/tira idénticas y página/membresía idénticas.
No permite heredar cambios de renderer, de datos de clip aunque den la misma
miniatura, ni tiempos/píxeles distintos. Conserva excepciones y anotaciones nuevas
del destino. Pruebas de cambio de fuente invisible en miniatura, cambio de
muestras, índice adulterado, idempotencia y excepciones pasan.

Con estas guardas migradas **1.674 anotaciones** de las 85 páginas idénticas;
los 60 clips de las tres páginas cambiadas se vuelven a observar. El índice
anterior completo se conserva en
`.godot/move_contact_review/10e44facd52c5103/catalog_index.json`, con todos sus
shards de generación anterior preservados. No se reinicia la revisión ni se
convierten capturas nuevas en aprobación automática.

Registro actual `.godot/move_contact_review/84cfcc27cf596d4c/sheets_20/index.md`.
Siguiente: timings/capas de Día Soleado/Deseo, después demás familias; conversión
de 30 hue como grupo separado. Las cinco conexiones de combate permanecen iguales.
Sin descargar nuevos recursos de arte, tocar F:, regenerar datasets, cambiar
workflows, commit o push. Se consultaron 19 checks SUCCESS del HEAD exacto
`0902de4c10d34a2a451c9acad83fbfea765ef270` antes de editar, no certificación remota
del trabajo local actual. Las cifras/colas de 41 clips y 22 IDs más abajo son
el cierre histórico anterior, no pendientes reabiertos tras este arreglo.

## Cierre del primer barrido de láminas, 21–44 — 2026-10-24

Petición «sigue»: observados los 24 lotes restantes por ambos lados, 934 clips /
2.802 muestras nuevas. **Barrido de láminas 01–44 COMPLETO: 88 páginas, 1.734 clips,
5.202 muestras. 1.693 sin fallo evidente en las muestras, 30 necesitan movimiento,
11 sospechosos de presentación/artísticos; cero pendientes de este primer vistazo.**
Los 41 apartados son 22 IDs: 19 por ambos lados y tres solo rival. No son 41
defectos confirmados. Las 867 familias / 856 IDs de laboratorio no certifican los
919 movimientos: 63 excepciones de conversión siguen en cuarentena y fuera de las
láminas. No se ha completado la aprobación artística, de fluidez o de combate.

Nuevas excepciones registradas con ampliación/contraste focal:

- `rolling_kick/front`: huella separada a la derecha de Ogerpon en f5/f7 de la
  tira nativa; export OppMove propio. Patrón 11 en [152,241], foco 1; lado back
  [360,121], foco 3, superpuesto al objetivo en las muestras. Sospecha de
  colocación, misma investigación de foco/cámara que Hipertaladro rival.
- `upper_hand/front`: mano se aproxima pero queda a la derecha del objetivo al
  final muestreado (f0/f2/f12). Fuente de 15 frames, 14 celdas positivas, export
  OppMove propio y puntos hasta [128,224] con foco 1. Sospecha de colocación,
  no cambiar el mapeo global sin contrastar semántica y evidencia reproducible.
- `max_flutterby/back` y `/front`: necesita revisión de idoneidad/legibilidad
  como equivalente Max genérico. La referencia SAVAGESPINOUT contiene capullo y
  otros Pokémon dibujados (incluidos Beedrill/Scizor), visibles en la tira nativa
  aunque los combatientes sean Ogerpon/Charizard. Fuente `PRAS- Savage Spin Out.png`.
  No es animación nativa Dinamax ni fallo de renderer demostrado. La misma fuente
  aparece en ambas variantes de Guadaña Sedosa del lote 33; allí es el recurso Z
  original, no una nueva equivalencia Max aprobada por similitud.
- `snowscape/back` y `/front`: sospecha de presentación de clima incompleta.
  Tono azul/balanceo sin nieve. DATA_ONLY, 13 frames, cero celdas positivas;
  agrupar con Granizo y Danza Lluvia, no certificar ni implementar clima aquí.
- `sunny_day/back` y `/front`: necesita inspección de timings/capas. 20 frames,
  cero celdas positivas, opacidad horneada cero para Sunny Day BG. Fuente ya
  contrastada con dos eventos de timing en f0: resolver semántica/orden antes de
  atribuir causa o corregir. DATA_ONLY intacto.
  **Contraste posterior:** el bloque 16 de la revisión temporal vigente observa
  el pulso amarillo y contrato de capa 0→200→0. Esta nota histórica no añade una
  duda de capa ausente a esa generación; no se ha reparado código en ese bloque.
- `substitute/back` y `/front`: necesita revisión de transición externa del
  muñeco; no se ve en estas tres muestras. Fuente de 14 frames, diez celdas
  positivas, patrón 1/back o 0/front. No deducir ausencia de textura o de muñeco
  en TODO el clip solo de las muestras. DATA_ONLY, sin implementación de reglas.
- `transform/back` y `/front`: desvanecimiento, sin cambio de especie en las
  muestras; 15 frames, cero celdas positivas. Necesita transición externa de
  forma/sprite, no retoque de imagen. UNSUPPORTED intacto, no activar mecánica.
- `wish/back` y `/front`: ampliadas tiras nativas. Tres muestras f3/f4/f15 con
  el mismo hash de píxeles (1/3 distinto), pese a 20 estados de fuente y 39 celdas
  positivas. Se ve fondo estrellado fijo. Revisar secuencia completa, solapamiento,
  capas y muestreo antes de declarar inmovilidad global. DATA_ONLY, sin aprobar
  curación diferida. A diferencia de Doble Patada, aquí sí hay muchos estados de
  fuente: no aplicar a ciegas el arreglo previo del selector de dos estados.

Dudas de miniatura descartadas al ampliar: Ciclon Hojas/back sí cubre al objetivo;
Somanta Amistosa/back oscurece la vista completa, no un rectángulo opaco aislado;
Metrónomo/front sí tiene dedo sobre Charizard. Rayo Meteórico/front tiene haz y
reacción final sobre Ogerpon, pero la tira no certifica la dirección temporal de
un haz sin punta. Erupción de Ira tiene dos imágenes GPU distintas por lado en
sus tres muestras: no se afirma globalmente estática. Cadenas/fogonazos/cajas de
referencias Z no se declaran arte corrupto por ser grandes o cubrir cuerpos.

### Cola focal agrupada tras las 44 láminas

No volver a revisar todo el catálogo por defecto. Registro exacto por clip y notas
en `.godot/move_contact_review/10e44facd52c5103/sheets_20/review_log.json`.

| Familia de investigación | IDs apartados | Clips |
| --- | --- | ---: |
| Foco/cámara de export rival | hyper_drill, rolling_kick, upper_hand (solo front) | 3 |
| Presentación de clima / salida | rain_dance, hail, snowscape, chilly_reception | 8 |
| Timings/capas y muestras iguales | sunny_day, wish | 4 |
| Transición externa de sprite | substitute, transform | 4 |
| Oscurecimiento y restauración | burn_up, double_shock | 4 |
| Trayectoria/escala/lectura en movimiento | dynamax_cannon, eternabeam, malignant_chain, moongeist_beam, solar_blade, astral_barrage | 12 |
| Legibilidad/arte/equivalencia | armor_cannon, gigaton_hammer, max_flutterby | 6 |

Total 41 clips de 22 IDs, no 41 causas ni errores confirmados. Mantener la
separación entre recurso/render, presentación delegada y mecánicas. La cola de
63 conversiones fallidas es otra dimensión: 30 hue, 19 etiquetas, ocho patrones,
cinco hojas y un modo de celda. Primero evidencia focal, después arreglo de causa
compartida y regresión; recapturar lo que cambie y migrar solo láminas idénticas.

Verificación del cierre: once tests Python PASS; hashes de las 88 láminas,
manifiestos captura/catálogo y membresía/estados del registro correctos; fuentes
raw/normalized conservan los hashes previos. Ninguna página sin abrir recibió
aprobación. No se regeneraron imágenes ni se cambiaron renderer, datos, reglas,
learnsets, sonidos o las cinco rutas de combate. Sin nuevas descargas/F:, commit,
push o CI nueva. Consulta read-only previa: 19 checks SUCCESS del HEAD exacto
`0902de4c10d34a2a451c9acad83fbfea765ef270`; no certifica estos cambios locales.

## Continuación 13–20: muestras ampliadas y excepciones agrupadas — 2026-10-24

Petición «sigue»: observados ocho lotes nuevos, ambas caras, 160 familias / 320
clips / 960 muestras. Acumulado al cierre de ese tramo: **lotes 01–20, 800 clips / 2.400 muestras:
773 sin fallo evidente en las muestras, 20 necesitan movimiento y siete
sospechosos de presentación/artísticos**. Quedan 934 clips; próximo lote: **21**.
Los 27 apartados corresponden a 14 IDs: trece por ambos lados y Hipertaladro
solo rival. No son 27 defectos confirmados ni una certificación estética/mecánica.

Ampliados los casos dudosos a tiras nativas de 1.920×360; no se regeneraron
capturas ni se modificaron assets/exportador/renderer:

- `hail/back` y `/front`: sospecha de presentación incompleta. Balanceo/tono azul
  del usuario, sin granizo visible. Contraste de fuente completa: 13 frames,
  cero celdas positivas y ninguna capa visible. DATA_ONLY. Misma familia pendiente
  de presentación de clima que Danza Lluvia; no fallo de renderer demostrado.
- `gigaton_hammer/back` y `/front`: necesita movimiento. Se ve aplastamiento del
  objetivo y polvo, sin martillo reconocible en las tres muestras ampliadas.
  Fuente de 23 frames, 56 celdas positivas y patrones 23/24/26/28/29 de la hoja
  Metal Burst. Comprobar legibilidad del golpe a velocidad normal; no afirmar
  ausencia de martillo durante TODO el clip ni textura perdida a partir de esto.
- `hyper_drill/front`: sospecha de colocación. Impactos de f0/f7/f28 separados a
  la derecha de Ogerpon mientras el objetivo recibe el tono del golpe. Tiene
  exportación `OppMove:HYPERDRILL` propia, `slot_sides=[back,front]`, no reflejo
  sintetizado. Celdas de partículas con foco 1 y coordenadas próximas al puesto
  trasero (p. ej. patrón 21 en [148,221] en f0), mientras el mapeo foco 1 toma
  como referencia SOURCE_FRONT. Hay que contrastar semántica de fuente/cámara
  antes de corregir: esto no demuestra por sí solo fallo del importador. El lado
  back no muestra este desplazamiento evidente y no queda apartado.

Dudas descartadas tras ampliar/contrastar:

- Paranormal: el anillo aparece sobre el usuario, pero el objetivo sí se deforma.
  Fuente con 20 poses/estados distintos del objetivo, zoom 60–100 y desplazamiento
  vertical. No se mantiene una acusación de objetivo equivocado/ausencia de
  reacción. No equivale a certificar la fluidez de la secuencia.
- Láser Veleidoso rival: el haz sí se superpone al cuerpo de Ogerpon en la tira
  nativa; la miniatura sugería una trayectoria inferior que no demuestra un fallo.
- Geocontrol rival: cristales alrededor de Charizard y dentro de la vista nativa,
  no recorte del efecto demostrado.

Las páginas completas 13–20 se anotan primero y luego se aplican las cinco
excepciones de clip anteriores; el último estado de cada clip prevalece. Se
conserva historial y relación SHA de imágenes/índice en
`.godot/move_contact_review/10e44facd52c5103/sheets_20/review_log.json`.
Once tests Python PASS. Verificados los hashes de las 88 láminas, manifiestos de
captura/catálogo, membresía del registro y hashes raw/normalized sin cambios.
Ningún lote posterior al 20 recibe anotaciones. No se repiten gates de mecánica por anotar láminas; las
cinco rutas de combate y la cuarentena de 63 IDs siguen iguales. Sin nuevas
descargas, cambios de datos/reglas/sonidos, F:, commit, push o CI nueva. Los 19
checks SUCCESS del HEAD exacto `0902de4c10d34a2a451c9acad83fbfea765ef270` se
consultaron antes de editar; no certifican el trabajo local sin commit.

## Continuación 07–12 y corrección del muestreo de dos estados — 2026-10-24

Petición «sigue»: observados ambos lados de seis lotes más, 120 familias / 240
clips / 720 muestras nuevas. Estado al cierre de ese tramo: **lotes 01–12, 480 clips /
1.440 muestras: 458 sin fallo evidente en las muestras, 18 necesitan movimiento,
cuatro sospechosos de presentación/artísticos**. 1.254 sin revisión humana;
próximo lote sin abrir: 13. No interpretar como aprobación completa de animación,
sincronía o mecánica. Los 22 clips apartados corresponden a once IDs por ambos
lados, no a 22 defectos confirmados.

Nuevos casos apartados:

- `burn_up/back` y `/front`: silueta oscurecida prolongada en las muestras. Revisar
  duración a velocidad normal, sin suponer textura ausente. Fuente frame 38:
  tono del usuario `[-170,-170,-170,255]`, objetivo `[-144,-144,-144,0]`.
  Último frame (79): ambos cuerpos con overlay/tono cero y opacidad 255.
- `double_shock/back` y `/front`: familia visual parecida a Burn Up, mismas cifras
  de tono observadas y restauración final. Sus frames/hoja/capas no son todos
  idénticos: no fusionarlos como un único clip ni cambiar el tipo del movimiento.
- `chilly_reception/back` y `/front`: bocadillo y retirada, no nieve en las
  muestras. Recurso DATA_ONLY, 30 frames, 18 celdas de partículas visibles por
  lado y ninguna capa visible. Revisar la presentación completa de clima/retirada
  como familia con Rain Dance, no activar clima/retirada por tener una lámina.

Hallazgo del propio auditor, ya corregido: Doble Patada parecía inmóvil en su
lámina porque los tres cuadros eran f0. Su recurso sí tiene seis frames, patrón
11 de impacto visible y dos estados distintos de opacidad (150/255). La selección
`floor((n-1)*0.2/0.5/0.8)` con n=2 elegía siempre el estado cero. No era ausencia
de animación ni fallo del Pokémon. Escaneados los 1.734 clips: solo Double Kick
por ambos lados tiene n<=3 (n=2). Selector actualizado para cubrir TODOS los
estados cuando son uno/dos/tres; repite únicamente cuando faltan estados para
llenar tres cuadros. En n=2 muestra f0/f1/f1 y etiqueta esos tiempos; no inventa
un tercer estado ni certifica dos impactos de combate con una tira de un impacto.

Pruebas nuevas del selector en modo `--self-test`: uno/dos/tres/cien estados y
efecto visible de un único frame tardío entre estados ocultos, cinco PASS Godot.
El wrapper `run_move_contacts.ps1` ejecuta primero esta prueba y aborta si falla.
Once tests Python PASS, incluida migración de anotaciones con excepciones,
idempotencia, rechazo por índice/renderer distinto y no herencia de imágenes
cambiadas. Fuente de assets, renderer y motor no se modifican.

Regeneración GPU completa correcta: 1.734 tiras / 5.202 capturas, 88 láminas,
generación **`10e44facd52c5103`**. Manifiesto capturas SHA-256:
`9e3331cdf6c053d7e2e63dbaeee6fc64046a00eda701a1d23692a96cf8dd70ce`.
Comparación anterior/nueva: solo cambian muestras/tiras de `double_kick/back` y
`/front`; ambos pasan a dos muestras GPU distintas. 86 láminas tienen exactamente
los mismos bytes y las dos páginas 11 cambian. Se migran 440 anotaciones vigentes
SOLO de páginas idénticas, con mismos IDs/índice/renderer y manifiestos verificados;
se conservan las excepciones y una segunda migración no duplica anotaciones. Las
dos páginas 11 nuevas se vuelven a observar, también Doble Patada ampliada a
resolución nativa; no queda apartada como estática. No se da por revisado ningún
clip no visto. Registro/capturas anteriores conservados, sin borrado.

Índice/registro vigente:
`.godot/move_contact_review/10e44facd52c5103/sheets_20/index.md`.
Para una futura mejora del exportador, `build_move_contact_sheets.py` permite
`--review-folder NUEVO --migrate-from ANTERIOR`: conserva solamente anotaciones
de láminas exactamente iguales. Imágenes cambiadas quedan PENDING; no copiar el
JSON del registro sin estas guardas. Las anotaciones manuales ya vigentes en el
destino tienen prioridad sobre la migración.

Apartados al cierre de ese tramo: Armor Cannon, Astral Barrage, Burn Up, Chilly Reception,
Double Shock, Dynamax Cannon, Eternabeam, Malignant Chain, Moongeist Beam,
Rain Dance y Solar Blade. Los estados anteriores y las rutas a la generación
`af49ff4239c69913` más abajo son historia de la revisión, no el punto de reanudación.
No se vuelve a ejecutar el barrido mecánico ni CI por revisar imágenes; el gate
GPU previo y el índice del pack siguen iguales. Sin cambios de datos, learnsets,
reglas, cinco conexiones al combate, workflows o F:, ni commit/push/CI nueva.

## Barrido primero, láminas de veinte y registro persistente — 2026-10-24

El usuario propone revisar en grupos de diez/veinte sin saturar contexto y anotar
los fallos para centrarse después en ellos. Se adopta: barrido técnico exhaustivo,
hojas de contacto temporales, revisión humana priorizada y ampliación solo de los
casos sospechosos. Las láminas no prueban la fluidez, la sincronía del impacto ni
la mecánica; no hay un certificado estético automático.

Implementado:

- `tests/visual/move_contact_capture.gd`: exige GPU y barrido GPU previo correcto
  del mismo índice, valida cada bloque y copia tres capturas reales de Godot a
  una tira de 1.920×360 por clip. SubViewport/dibujo explícito, sin depender de
  la ventana enfocada. Incluye índices/tiempos/hash de píxeles, PNG, fuentes y
  software; comprueba de nuevo índice y datos canónicos al terminar.
- Muestreo de estados VISIBLES distintos (20/50/80 % del conjunto) más el pico
  de partículas cuando existe; orden temporal preservado. Evita que un efecto
  corto quede entre tres porcentajes de reloj elegidos sobre reposo. No garantiza
  capturar cada anomalía breve; conservar reproducción completa del laboratorio.
- `tools/visual/build_move_contact_sheets.py`: hasta 20 familias, tres muestras
  por fila, dos columnas de diez filas y páginas separadas por lado. Pueden ser
  diez por página sin recapturar GPU. Tiras originales disponibles para ampliar.
  Prioriza los 41 IDs con avisos; títulos/ID/frames/segundos y aviso naranja.
- `review_log.json`: historial explícito por lámina/clip/estado/nota, ligado a
  SHA-256 de imagen e índice. Estado inicial PENDING. Anotación de una muestra
  sin fallo NO significa aprobada; admite sospechoso, revisar movimiento o fallo
  confirmado. Una imagen nueva no hereda la anotación anterior: se marca histórica.
- No se usa generación de imágenes ni se alteran píxeles de assets. Son capturas
  del laboratorio completo (incluidos cuerpos/capas de la fuente), no nuevas
  integraciones en el combate de partículas donde siguen las cinco rutas revisadas.

Resultados ejecutados:

- Barrido previo repetido: 5.108.923 PASS headless / 112.934 fotogramas/lado/tamaño.
- 1.734 clips / 5.202 capturas GPU en 1.734 tiras; **867 familias, 44 lotes,
  88 láminas**. Base: 856 IDs; el resto de familias son contextos/variantes previos.
  63 IDs en cuarentena siguen fuera de estas láminas, no se oculta su carencia.
- Capturas generación `af49ff4239c69913`; índice canónico del pack sigue
  `2455bf1d94b3f2f6e7fd1af1ceaf0d73601a44df92153f8deab81bb971d842d8`.
- Los cuatro avisos anteriores de muestras GPU iguales se vuelven a comprobar:
  Mimético 3/3, Danza Lluvia 3/3, Forcejeo 2/3 y Danza Caos 3/3 muestras distintas,
  por AMBOS lados. Prueba que no son globalmente estáticos, no su calidad completa.
  Hallazgo separado en `boards.json` (`sampling_rechecks`); informe anterior intacto.
- Diez tests Python PASS, incluidos agrupación/límites/lados, advertencias sin
  aprobación automática, persistencia, ID ajeno, hash cambiado y notas históricas.
  Regeneradas las 88 láminas: hashes verificados y conservadas las 40 anotaciones
  vigentes (32 sin fallo evidente / ocho revisar movimiento),
  `CONTACT_REBUILD_KEEPS_NOTES PASS`. No se duplica ni reinicia la revisión.

Revisión humana efectuada en este tramo: `batch_01_back` y `batch_01_front`,
20 familias / 40 clips / 120 muestras. 32 clips sin fallo evidente en estas
muestras. Ocho anotados `needs_motion_review`: `dynamax_cannon`, `eternabeam`,
`malignant_chain`, `moongeist_beam`, por ambos lados. Haces grandes y cadenas
atraviesan bordes/ocultan actores; hay que comprobar la trayectoria completa y la
intención del recurso antes de cambiarla. No etiquetarlos como ocho defectos
confirmados ni desactivarlos por esta observación. Los 1.694 clips restantes
siguen PENDING para revisión humana. Próximo lote sin abrir: 02.

### Continuación: lotes 02–06, revisión y descarte de falsas alarmas

Petición posterior «sigamos»: observadas diez láminas nuevas, ambos lados de los
lotes 02–06, 100 familias / 200 clips / 600 muestras. Estado acumulado vigente:
**lotes 01–06, 240 clips / 720 muestras: 224 sampled_no_obvious_issue,
12 needs_motion_review, cuatro suspected_issue**. Quedan 1.494 clips PENDING;
siguiente lote sin ver: 07. El registro previo del lote 01 se conserva como
historial del primer tramo, no se reinicia. No son porcentajes extrapolables al
resto: al principio estaban priorizados los 41 IDs con avisos automáticos.

Excepciones nuevas registradas por clip, con evidencia:

- `solar_blade/back` y `/front`: hoja luminosa larga sale del encuadre; revisar
  movimiento/contacto antes de ajustar escala o trayectoria. No fallo confirmado.
- `astral_barrage/back` y `/front`: orbes grandes se superponen al objetivo y
  cruzan bordes; revisar duración/recorrido. No se declaran incorrectos por tamaño.
- `rain_dance/back` y `/front`: carencia de presentación de clima en este recurso.
  Tres muestras muestran danza corporal. Inspección de TODOS sus 26 frames:
  cero celdas de patrón positivo visibles, ninguna hoja de capa y opacidad máxima
  de capas 0. La fuente inerte RAINDANCE contiene aquí solo timing de sonido,
  además de cuerpos; no se ejecutó Ruby. Necesita localizar la referencia visual
  de lluvia/clima delegada antes de aprobar su presentación completa, no cambiar
  el daño/estado ni activar clima DATA_ONLY. Se registra como sospechoso de
  recurso parcial/delegación, no error confirmado del renderer.
- `armor_cannon/back` y `/front`: aspecto moteado/rectangular del impacto. Ampliada
  la tira y vista la fuente `Gen9_Move_Animations/Graphics/Animations/firepoison.png`
  (960×576, PNG indexado con transparencia). Frame 14 usa el patrón 14 al 100 %,
  con tono de la fuente; el motivo ya está en el PNG original. No hay duplicación
  demostrada del importador. Solo ARMORCANNON usa esta hoja en este catálogo.
  Revisión artística/secuencia pendiente, no corrección ciega del shader ni PNG.

Falsa alarma descartada antes de apartar recursos: al ver Aerochorro rival en la
lámina parecía que la ráfaga quedaba cerca del atacante. La tira nativa ampliada
f16/f67/f70 muestra al final los tornados sobre Ogerpon objetivo. Se conserva
`aeroblast/front` como sin fallo evidente EN LAS MUESTRAS, no aprobado en combate.

También se observaron como coherentes en las muestras varias ondas/fondos que
cruzan bordes (Surf, Onda Tóxica, Viento Afín, etc.). No se convierten sus avisos
geométricos en defectos confirmados. Los ocho IDs aún apartados por ambos lados
son Dynamax Cannon, Eternabeam, Malignant Chain, Moongeist Beam, Solar Blade,
Astral Barrage, Rain Dance y Armor Cannon: 12 clips de movimiento + cuatro de
presentación/artísticos. No se eliminaron archivos ni se cambiaron animaciones.

Análisis suplementario de familia de clima (NO revisión visual de otras páginas):
Hail y Snowscape también tienen cero partículas/capas visibles, ambos lados;
Sandstorm sí tiene 136 celdas positivas visibles por lado, por lo que no se
generaliza el hallazgo a todo clima. Sunny Day tiene una hoja BG nombrada pero
opacidad horneada máxima 0: sus timings de fuente incluyen transición a opacidad
200 y un set de capa a 0 en el mismo frame 0, seguido de fade a 0 en frame 11.
Esto requiere comprobar la semántica/orden de timings nativos antes de atribuirlo
al pack o al horneador; no se ha reproducido ni corregido esa hipótesis en este
tramo. Los cinco movimientos de esta comprobación son DATA_ONLY actualmente.
No marcar sus láminas no vistas como revisadas ni habilitar mecánicas de clima.

Verificados hashes de las 88 láminas contra el manifiesto y pertenencia del
registro al índice. Diez tests Python PASS. Sin cambios del conversor/renderer,
fuentes, datos, cinco conexiones al combate, mecánicas o workflows; no nueva
captura/barrido GPU por anotar observaciones estáticas. Índice del pack y hashes
raw/normalized permanecen iguales; sin commit/push/CI nueva.

Runbook, dentro del proyecto:

```powershell
.\tools\visual\run_move_contacts.ps1 -BatchSize 20
python -m unittest discover -s tools/visual -p 'test_move*.py' -v
```

El wrapper hace barrido -> captura -> composición, deteniéndose al fallar.
También pueden regenerarse solo las láminas con `build_move_contact_sheets.py`;
exige que índice, renderer, manifiesto y evidencia GPU coincidan con la captura.
Índice humano actual:
`.godot/move_contact_review/af49ff4239c69913/sheets_20/index.md`.
Para registrar otra observación usar el mismo script con `--review-folder`,
`--board`, `--status`, `--note` y opcional `--clip`. No añadir por costumbre una
anotación de lámina completa que no se haya visto. No hay que leer todas las
imágenes en una sesión: índice/registro conservan dónde continuar y qué ampliar.

Sin cambios del renderer, conexiones al combate, dominios/learnsets/RNG, datos,
workflows o F:. Sin nuevos assets dibujados, descargas, commit/push o CI. Comprobado
otra vez HEAD remoto y sus 19 checks SUCCESS antes de editar herramientas locales;
eso no certifica estos nuevos archivos sin subir.

## Cambio a procesamiento masivo y cola de excepciones — 2026-10-24

El usuario solicita automatizar y preparar grupos grandes, en lugar de continuar
con dos/tres movimientos por turno. Este permiso sustituye la limitación inicial
del importador pequeño; no autoriza dar por ejecutables mecánicas ausentes.

Implementación reproducible:

- `tools/visual/build_move_batch.py`: recorre los 919 IDs normalizados; lector
  inerte y horneado de capas ya auditados en el caché externo. No ejecuta Ruby,
  plugins descargados, `eval` ni `Marshal.load`. No regenera datasets ni imágenes.
- Coincidencia exacta; alias explícitos de VICE/VISE y sufijo físico/especial Z.
  No se adivinan alias arbitrarios ni se cambia el tipo del movimiento. Conserva
  los 70 clips prioritarios previos de Toxillian/Max/Tera/contextos/Hard Press.
- Cada pareja se valida de forma atómica: si falla uno de los lados se aparta el
  ID completo y se conserva el motivo. Un recurso defectuoso no frena los demás.
- 856 IDs / 1.734 clips, 28 bloques de hasta 64 clips y 32.000.000 píxeles de
  hojas por bloque. Generación actual `generation_864af7d95357bb18`: 942 archivos,
  59.158.490 bytes, incluidas las copias locales repetidas entre bloques. Imágenes
  originales copiadas sin cambiar píxeles, nombres de salida SHA-256 y verificación.
- Metadatos de fuente/ayudantes/datos extraídos/constructor fijados en el índice.
  Directorio por contenido de todos los clips, hashes y dependencias; índice
  publicado al final de forma atómica. Se conservan generaciones anteriores.
- `community_move_preview.gd` admite bloques marcados LAB_ONLY, bajo los límites
  anteriores, sin ampliar la selección de `battle_community_move_pilot.gd`.
- `move_resource_lab.gd`: conmutador «Catálogo por lotes», búsqueda nombre/ID,
  ambos lados, cambio perezoso de bloque. El laboratorio previo de 70 clips y
  `JUGAR_PRUEBA_ATAQUES.cmd` siguen operativos.

Resultado de conversión: **63 IDs en cuarentena** por cinco familias: hue 30,
nombre ausente/ambiguo 19, patrón fuera de hoja ocho, PNG ausente cinco y modo
de celda no implementado uno. Todos tienen ID/motivo en `index.json`; no se
ocultan sustituyéndolos por una falsa animación certificada.

Auditor `tests/visual/move_batch_audit_runner.gd`:

- Barre TODOS los fotogramas de ambos lados, en 640×360 y 400×300, y comprueba
  visibilidad esperada, textura, valores finitos, posición según cámara, limpieza
  de celdas y final. 112.934 fotogramas/lado/tamaño; 5.108.923 checks headless PASS.
- Mide partículas con su rectángulo alfa real, incluyendo pivote de recorte.
  El primer detector usaba la caja de 192px con márgenes transparentes y producía
  328 avisos de borde; la corrección compartida los reduce a 37 IDs. Son avisos:
  un barrido fuera de pantalla puede ser intencionado, no error automáticamente.
- GPU: muestrea inicio/pico/mitad/final desde ambas proporciones y guarda un PNG
  por clip en `captures/`. El cambio entre muestras no aprueba el arte ni prueba
  que un efecto breve haya quedado correctamente representado.
  Usa SubViewport fuera de pantalla y dibujo explícito: no espera un repintado
  de una ventana visible. Una ejecución intermedia quedó detenida esperando
  `frame_post_draw`; se detuvo solo ese proceso propio y se eliminó esa dependencia.
  Gate final: **5.123.569 PASS / 0 FAIL**, 1.734 capturas. Los 37 avisos de borde
  y cuatro de muestras sin cambio (mimic, rain_dance, struggle, teeter_dance) suman
  41 IDs convertidos para revisión. Otros 815 no disparan estas heurísticas:
  NO se certifica por ello que sean artísticamente correctos ni aptos para combate.
- Inyecta recurso ausente, contenido con hash incorrecto, ID duplicado, clip de
  un frame y lote excesivo; exige rechazo y recuperación. Prueba UI de búsqueda,
  ambos lados, bloque distante y resultado vacío. Seis tests Python cubren además
  hue/cadencia/patrones/NaN/modos/flash/padding activo, alpha y evidencia obsoleta.
- `summarize_move_batch.py` genera `summary.md` + `review_queue.json`: agrupa
  causas por IDs, no pide revisar manualmente miles de capturas. Rechaza evidencia
  de otro índice, incompleta o con fallos fatales; distingue avisos de aprobación.

Hallazgos del desarrollo del automatismo: corregida una caché de metadatos de
PNG prioritario que aún no tenía calculado alfa, con test de regresión. Una
ejecución temprana detectó hashes distintos porque se reconstruían los mismos
directorios durante el barrido; se resolvió con generaciones por contenido e
índice atómico, no silenciando hashes. No conservar ese primer intento como PASS.

Runbook desde PowerShell, dentro del proyecto:

```powershell
.\tools\visual\run_move_batch.ps1 -Capture
# Añadir -OpenLab para abrir el catálogo después del gate.
python -m unittest discover -s tools/visual -p 'test_move_batch*.py' -v
```

El comando tiene que terminar antes de iniciar otra reconstrucción. Sin `-Capture`
solo se certifica el barrido headless, no se inventa evidencia GPU. Salidas propias
en `.godot/move_batch_catalog/` y `.godot/move_batch_checks/`. Fuentes del caché
externo ya descargado; no nueva descarga ni publicación de assets. Se mantienen
los créditos/condiciones de Gen 9 y Toxillian recogidos más abajo.

Índice final SHA-256:
`2455bf1d94b3f2f6e7fd1af1ceaf0d73601a44df92153f8deab81bb971d842d8`.
Los resultados headless/GPU fijan ese índice y el hash del auditor. Las capturas
no fueron revisadas manualmente una por una; comprobadas muestras reales de
Lanzallamas jugador y Rayo Aurora rival, no aprobación de todo el catálogo.
Probado también el comando completo `run_move_batch.ps1` sin GPU: reconstrucción,
auditor y resumen verdes; segundo índice byte-idéntico al primero
(`BATCH_REBUILD_IDENTICAL PASS`). Se restauró después el resumen de la evidencia
GPU válida del mismo índice, no se mezclan sus avisos con una certificación headless.

Regresiones del tramo: laboratorio previo 444.847, combate comunitario 407,
cronología 19.726 y VFX 4.949 PASS headless. El combate mantiene cinco IDs/diez
clips revisados; **cero rutas nuevas** en este tramo. Conversión masiva no significa
856 ataques con mecánica certificada. No sonidos, aprende-movimientos aleatorios,
contextos delegados, Dynamax o Tera completos. Raw/normalized sin cambios respecto
al inicio. Los nueve fallos ambientales DATA previos permanecen documentados.
Comprobados 19 checks SUCCESS del HEAD remoto exacto `0902de4c10d34a2a451c9acad83fbfea765ef270`
antes de editar; no es nueva CI de este trabajo local. Sin commit/push/workflows,
snapshot inmutable o F:.

## Cobertura y uso

- 1.025 especies base normales del catálogo local, frontal y espalda.
- 1.011 parejas existentes de renders Showdown; 14 parejas nuevas de candidatos
  3D. En estas 14 se usa el candidato por ambos lados, sin mezclar el frontal
  existente de Scavio con una espalda de otro acabado.
- 2.106 atlas PNG / 119.917 regiones; 283.569.505 bytes de atlas (270,43 MiB).
- Reposo en todas; Ferroseed tiene una sola imagen por vista y sigue estático.
  Los 14 candidatos incorporan además ataque corporal y daño, consultables en
  la galería y enlazados ahora a los eventos de combate salvaje/entrenador.
- Las especies sin poses específicas conservan sus fotogramas de reposo con una
  reacción compartida (desplazamiento de acción, temblor/destello de impacto).
  No se dibujan ni sustituyen imágenes. No son VFX específicos de 919 movimientos
  ni equivalen a certificar sus mecánicas.
- Formas alternativas, shiny y aprobación artística final no se certifican aquí.
  Los cinco candidatos de formas del registro previo siguen conservados fuera
  del juego: no se confunden con especies adicionales ni se activan sus mecánicas.

Abrir `JUGAR_DEMO.cmd` en la carpeta del juego. F3: galería con búsqueda por nombre
español o ID canónico (`iron_moth`, `castform`…). F1: configuración real de equipo,
entrenador y especie salvaje fija; vacío permite el pool real según nivel de zona.
La galería compara espalda/frontal de la misma especie, no cambia el equipo.

También permite introducir ID o nombre en **Comparar**, contrastando con otra
especie. **Invertir lados** cambia cuál se ve de frente/espalda y **Misma especie**
restaura el modo habitual. La referencia permanece explícitamente en reposo al
probar ataque/daño del seleccionado. No se alteran equipos ni RNG de la partida.

Revisión posterior de los 14 renders propios: 84 clips, 252 muestras temporales
y 70 capturas reales, con 1.005 PASS / 0 FAIL. Se conserva su escala relativa;
no se presenta como tabla externa ni aprobación artística final. Se solicita
redibujado inmediato al cambiar IDs, incluso con reproducción detenida.

### Evaluación de paquetes comunitarios de ataques y créditos (2026-10-19)

Petición del usuario: comparar Gen 9 Move Animation Project y EBDX Move & Common
Animation Pack antes de sustituir los efectos provisionales; conservar agradecimientos
para futuros créditos accesibles del juego. No se implementa aún la pantalla de créditos.

Descargas de investigación separadas en
`D:\Proyectos\Pokemon Calvo Auditoria Visual\comparacion_ataques_v1\`.
No se instala ningún plugin, ejecuta Ruby del paquete ni cambia el juego. Los datos
Marshal se leen con un parser propio limitado a estructuras inertes, sin `eval` ni
`Marshal.load`. No hay compras ni publicación de recursos. `inventory.json` conserva
fuentes, tamaños, SHA-256, listas de coincidencias y pendientes; se reproduce con
`audit_pack_inventory.py` en esa misma carpeta. SHA del branch remoto comprobado:
`0902de4c10d34a2a451c9acad83fbfea765ef270`; esta evaluación no es nueva certificación CI.

| Criterio del archivo descargado | EBDX | Gen 9 |
| --- | --- | --- |
| Tamaño comprimido | 17.072.391 bytes | 53.537.466 bytes |
| Formato | Ruby dependiente de Elite Battle DX; 597 IDs registrados únicos | 1.532 slots de datos, 883 nombres `Move:` únicos |
| Coincidencias normalizadas con los 919 IDs del juego | 554 | 841 |
| IDs sin coincidencia directa | 365 | 78 |
| PNG / audio incluidos | 573 / 229 | 682 / 1.479 |

Los recuentos son inventario estático, no cobertura ejecutada ni garantía de calidad.
EBDX es un complemento: no se atribuyen al archivo los recursos de su motor base.
Gen 9 tiene 37 candidatos adicionales de alias —variantes físicas/especiales de
movimientos Z y `vice_grip`/`VISEGRIP`—, todavía sin integrar ni certificar. No son
37 animaciones ausentes que haya que dibujar. Quedan 41 IDs sin etiqueta equivalente
tras ese cruce candidato, principalmente Max/Let's Go/Torque y algunos movimientos
recientes. Esto tampoco significa que solo falten 41 animaciones utilizables:
`NATUREPOWER` y `SECRETPOWER` tienen un solo fotograma y necesitan revisión funcional.
No se cambian IDs canónicos, reglas ni la selección de ataques del randomlocke.

Las hojas referenciadas por los nombres de animación Gen 9 están presentes en ese
archivo; no certifica fondos/sonidos, targeting o reproducción. En EBDX se detecta
una referencia PNG constante ajena al archivo (`Graphics/EBDX/Pictures/impact`) y
siete IDs con registro duplicado; pueden depender de su base/orden de carga y no se
declaran automáticamente bugs. No se importan archivos en bloque para resolverlos.

Inspección artística acotada: revisadas hojas originales de Lanzallamas, Rayo,
Rayo Hielo y Bola Sombra en ambos, y Truco Floral en Gen 9. Ambos mezclan recursos
pixelados; no son efectos HD de Switch. En las piezas de fuego Gen 9 se aprecian
siluetas y luces más definidas; EBDX compone muchas partículas y transformaciones
mediante código. Una partícula simple no equivale a una animación fea: no se comparan
un punto de EBDX y una hoja completa como si fueran efectos finales equivalentes.
Las demos GIF enlazadas de EBDX fallaron al cargar, también en navegador. No se ha
reproducido fielmente ninguno de los dos sistemas dentro de Godot, por tanto no hay
ganador visual definitivo ni aprobación de todas las animaciones.

Recomendación provisional: Gen 9 como primer candidato por cobertura y formato
de fotogramas/tiempos, EBDX como alternativa a contrastar, no complemento automático.
Antes de elegir: un piloto pequeño del mismo movimiento en ambos, con idénticos
Pokémon, arena, escala y criterio de targeting, incluyendo acción desde ambos lados,
fallo y daño real. Mantener la separación entre VFX y reglas/RNG ya implementada.
No ampliar un importador completo antes de que esa muestra justifique el trabajo.

#### Prioridades vigentes — instrucciones posteriores del usuario (2026-10-19)

Este criterio sustituye el filtro histórico de la sección siguiente: los 19 Max/
Dinamax vuelven a ser prioritarios. Se priorizan también Garrote Liana de Toxillian
y la revisión de Adaptación/Daño Secreto. Teraexplosión puede usar una sola variante
o una equivalente; Prensa Metálica queda en prioridad baja. Los demás movimientos
antes ignorados pueden tener una representación genérica compatible con su tipo
para pruebas; el usuario indica que no se usarán en el juego final. Se registra esa
intención, sin borrar entradas ni modificar ahora el pool o reglas de selección.

Garrote Liana descargado desde el [aporte de Toxillian](https://eeveeexpo.com/threads/5817/page-14):
`Teal_Mask_Move_Anims_-_Toxillian.rar`, 17.758 bytes, SHA-256
`b3711c0a01585ea625d7d170704582daab31e373f2da4ffbb314149ffaa75435`.
Conservado y extraído en la carpeta externa de comparación. Incluye ocho exports
`.anm`: base/fuego/roca/agua y sus vistas rivales, 38 fotogramas cada uno, con su
hoja PNG presente y válida. Validado el formato mediante lectura inerte; no se ha
ejecutado ni instalado Ruby. Las variantes no base necesitan enlaces explícitos:
sus nombres no usan todos el registro automático `Move:`. Crédito: Toxillian,
además de las procedencias aplicables del paquete, si finalmente se utiliza.

`priority_resource_plan.json`, reproducible con `audit_priority_resources.py` en
la misma carpeta externa, registra **125 comprobaciones PASS** de disponibilidad,
formato, integridad y correspondencias. No son pruebas de reproducción en Godot.
Hay recursos candidatos de varios fotogramas y hojas presentes para los 19 Max
en el paquete Gen 9, siguiendo equivalencias consultadas en
[Showdown](https://github.com/smogon/pokemon-showdown-client/blob/master/play.pokemonshowdown.com/src/battle-animations-moves.ts).
Son reutilizaciones de movimientos Z y de Barrera Espinosa para Max Guard, no
19 animaciones Max nativas nuevas ni aprobación artística. Los 19 son 18 ofensivos
por tipo y Max Guard; no se añaden tipos al catálogo de 18. El manifiesto conserva
cada correspondencia para preparar un piloto, sin darla por integrada.

Teraexplosión: candidato único neutral `TECHNOBLAST`, también presente en Gen 9;
no implica implementar teracristalización ni cambiar el tipo real del movimiento.
Prensa Metálica: candidato similar de acero `HEAVYSLAM`, sin declarar que sea aún
el mejor resultado artístico. Una fórmula de daño distinta no determina por sí
misma la calidad o existencia de una animación: dominio y presentación son aparte.

La revisión del [código de Essentials](https://github.com/Maruno17/pokemon-essentials/blob/master/Data/Scripts/011_Battle/003_Move/012_MoveEffects_ChangeMoveEffect.rb)
explica las dos entradas de un fotograma: Adaptación llama otro movimiento según
el entorno y usa su animación; Daño Secreto selecciona otra animación según el
entorno. No se corrigen alargando artificialmente ese fotograma. Referencias
neutrales: Triataque y Golpe Cuerpo, respectivamente. El futuro selector visual
debe respetar la acción/entorno resueltos por el dominio, sin simular su ejecución.
En nuestro catálogo siguen `nature_power = UNSUPPORTED`, `secret_power =
PARTIAL_RUNTIME` y `hard_press = DATA_ONLY`; los recursos no amplían esos contratos.
El soporte declarado de `ivy_cudgel`/`tera_blast` tampoco certifica máscaras o Tera.

No se ha copiado código ejecutable de Showdown; se ha usado como referencia de
equivalencias. Su cliente tiene [licencia AGPL-3.0](https://github.com/smogon/pokemon-showdown-client/blob/master/LICENSE):
revisar obligaciones antes de portar implementación, además de revisar las
procedencias separadas de gráficos/sonidos. Acreditar no sustituye esa revisión.

Este tramo prepara recursos y documentación: sin cambios de runtime, atlas,
datasets, mecánicas ni aprendizaje. La regla comunicada de conservar los niveles
de aprendizaje y sortear el movimiento en cada hueco queda como contexto, no
implementada. No se han vuelto a ejecutar los gates Godot de las secciones inferiores.

#### Historial: piloto inicial de reproducción de recursos — 2026-10-19

El primer piloto fue una muestra aislada y silenciosa en
`scenes/visual/move_resource_lab.tscn`. Abrir `JUGAR_PRUEBA_ATAQUES.cmd` en la raíz
del juego. Ofrece cuatro secuencias: Garrote Liana base de Toxillian y el candidato
Inferno Overdrive para Maxignición, cada uno en versión jugador/rival. Selector,
pausa/reproducción, reinicio y barra por fotograma. No sustituye `JUGAR_DEMO.cmd`
ni añade estos efectos a la resolución de un combate. Garrote usa Ogerpon y el
candidato de fuego Charizard, con las mismas vistas/escalas del catálogo existente.

`community_move_preview.gd` interpreta solo los modos seleccionados: celdas de
192 px, focos, giro, espejo, escala/opacidad, tono/color, orden de capas y fondos
con transiciones simultáneas de desplazamiento/opacidad. Usa exports `OppMove`
propios, no un simple volteo de la versión del jugador. Los slots canónicos siguen
siendo espalda/frontal porque esos exports ya invierten la coreografía. Cámara
adaptada a los centros estables de nuestro catálogo; no es reproducción certificada
de la cámara de Essentials. Las imágenes corporales se mantienen en su primer
fotograma de reposo para hacer repetible la comparación; sus transformaciones
temporales proceden de las celdas de cada secuencia, no son nuevas poses nativas.

Datos y cuatro PNG copiados byte a byte se preparan en
`.godot/move_resource_pilot/`, fuera de Git, sin modificar las fuentes descargadas.
El generador externo `build_resource_pilot.py` limita el alcance a estos cuatro
clips, falla ante modos no incluidos, registra hashes/procedencias y publica el
manifiesto al final: **660 comprobaciones PASS**. Reconstrucción tras borrar caché:

```powershell
python 'D:\Proyectos\Pokemon Calvo Auditoria Visual\comparacion_ataques_v1\build_resource_pilot.py' --output 'D:\Proyectos\Pokemon Calvo\.godot\move_resource_pilot'
```

Referencia del formato:
[reproductor de Essentials, Maruno17](https://github.com/Maruno17/pokemon-essentials/blob/master/Data/Scripts/011_Battle/007_Other%20battle%20code/007_BattleAnimationPlayer.rb),
cuya fuente consultada indica [CC BY-NC-SA 4.0](https://github.com/Maruno17/pokemon-essentials/blob/master/LICENSE).
El adaptador local es acotado y cambia cámara/interfaz; conservar referencia y
revisar condiciones aplicables antes de distribuir. No se copia implementación de
Showdown. Gráficos/coreografías conservan además sus atribuciones de Toxillian y
Gen 9 descritas arriba. Esto no resuelve permisos de todos los recursos del juego.

Gate `community_move_preview_test_runner.gd`: examina los 180 fotogramas fuente
en dos tamaños de arena (640×360 y 400×225), regiones, visibilidad, transformaciones,
capas, limpieza entre clips, cadencia, manifiestos inválidos e interfaz. Pasada GPU:
**25.331 PASS / 0 FAIL**, **41 capturas**, 24 comparaciones que confirman cambios
visibles respecto del inicio. Pasada headless: **25.266 PASS / 0 FAIL**. Artefactos
en `.godot/community_move_checks/`, incluida `lab_ui.png`. Revisadas visualmente
muestras intermedias de ambos lados y la interfaz, no todos los recursos del pack.

Regresión en esta pasada: efectos compartidos headless **4.955 PASS / 0 FAIL**,
20 turnos reales de muestra; mapa visual **45 PASS / 0 FAIL**. Importación del
editor correcta. Comprobados rama/HEAD remotos y sus 19 checks SUCCESS en el SHA
`0902de4c10d34a2a451c9acad83fbfea765ef270`; el trabajo nuevo sigue local, sin
commit/push y sin heredar esa certificación. No se vuelve a ejecutar toda la matriz.

Pendiente: aprobación artística del piloto y comparación equivalente con EBDX
antes de elegir pack final; los otros 18 Max, las variantes restantes de Garrote,
Teraexplosión y los selectores de Adaptación/Daño Secreto aún no se reproducen en
este laboratorio. Son candidatos inventariados, no tareas ya terminadas. Audio
omitido expresamente. Sin dominio, RNG, daño, learnsets ni selección de movimientos.
No se amplía ahora a importador general ni se cambia el contrato de soporte.

#### Laboratorio ampliado: 19 candidatos Max desde ambos lados — 2026-10-19

Continuación autorizada por el usuario: el mismo `JUGAR_PRUEBA_ATAQUES.cmd` ahora
ofrece **40 secuencias**: 19 equivalentes Max por dos lados y el par base de Garrote
Liana. No se conecta a los controladores de combate, no activa Dinamax, no cambia
tamaños base, daño, secundarios, learnsets ni pool. En los datos canónicos los Max
siguen siendo 18 PARTIAL_RUNTIME y Maxibarrera DATA_ONLY; no se certifican sus reglas.

Hay diez exports rivales propios entre los Max y nueve adaptaciones de la versión
del jugador. Estas últimas se identifican como **rival adaptado** en el selector y
con `mapped_opponent` en el manifiesto: reasignan origen/destino, reflejan posiciones
horizontales locales, giros y partículas sin sustituir la espalda por un frontal.
No se presentan como coreografías rivales originales ni aprobación artística.
Maxibarrera se enfoca en quien la usa y conserva al oponente en reposo; no se
representa como ataque contra él. No implica que su protección esté implementada.

Correcciones demostradas durante preparación/revisión:

- Vuelo: la referencia SUPERSONICSKYSTRIKE pide 39 celdas de un patrón totalmente
  ajeno a su hoja de 192×192. Se elige HURRICANE, con export rival propio. Se conserva
  el motivo del cambio en `candidate_adjustment`, sin editar el paquete fuente.
- Fantasma: se descarta para este laboratorio la composición cinematográfica de
  NEVERENDINGNIGHTMARE tras revisar sus franjas/mosaicos en nuestra cámara; se usa
  SHADOWBALL, también con export rival propio. Es una equivalencia visual más simple,
  no el Max original ni nueva aprobación del estilo de todo el pack.
- Roca: la hoja de CONTINENTALCRUSH mide 960×1144, no un múltiplo completo de 192.
  Se muestra la intersección real de la última celda, conservando su centro y sin
  estirar píxeles ni dibujar fuera del atlas. El manifiesto registra los recortes.
- Roca/acero contienen padding nulo más allá de los 60 slots del reproductor:
  solo se omiten esos espacios vacíos, nunca celdas activas. El generador lo exige.
- Se incorporan capas de color sin hoja, mezcla aditiva/sustractiva y escala de
  mosaicos de pantalla coherente con la cámara para no abrir separaciones entre
  sus piezas. Los tres modos de mezcla tienen prueba GPU con colores conocidos;
  referencia técnica: [CanvasItem de Godot](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html).

Reconstrucción vigente (el comando histórico sin opción solo prepara el piloto inicial):

```powershell
python 'D:\Proyectos\Pokemon Calvo Auditoria Visual\comparacion_ataques_v1\build_resource_pilot.py' --include-max --output 'D:\Proyectos\Pokemon Calvo\.godot\move_resource_pilot'
```

Generador: **12.734 comprobaciones PASS**, 43 PNG de copia exacta, 811.990 bytes
comprimidos en total; se decodifican unos 106,59 MiB RGBA. SHA-256 del manifiesto
validado: `19415b7aa8edd458ffd3bf43fc86e2a8aaa574d5bcb38f950d62864f6067169f`.
El paquete sigue en caché ignorada y conserva las procedencias/créditos anteriores.
No se descarga nada nuevo ni se toca la biblioteca original de F:.

Gate actualizado: **296.712 PASS / 0 FAIL con GPU**, **404 capturas**, 286 muestras
con diferencias respecto del inicio; **296.225 PASS / 0 FAIL headless**. Recorre
2.405 fotogramas fuente en dos arenas, 40 selecciones, lados, recortes, limpieza,
destino propio de Maxibarrera y calibración de mezcla. Las capturas incluyen cinco
fases de cada clip/tamaño, tres calibraciones y una de interfaz. Resultados actuales
en `.godot/community_move_checks/19415b7aa8ed/`; el `result.json` del directorio padre
apunta a la última pasada para no confundir imágenes históricas con las vigentes.
Revisadas muestras de vuelo, defensa, siniestro, fantasma, roca, acero, tierra,
veneno, hada, eléctrico, psíquico y la interfaz; no revisión manual exhaustiva.

Regresiones focales repetidas: efectos compartidos **4.955 PASS / 0 FAIL**, 20 turnos
reales; mapa visual **45 PASS / 0 FAIL**. Rama/HEAD remotos y sus 19 checks SUCCESS
verificados de nuevo; el trabajo añadido continúa local, sin commit/push ni CI nuevo.
Pendientes: revisión artística final/comparación EBDX, conexión real de recursos,
audio, variantes restantes de Garrote, Teraexplosión, selectores de Adaptación/
Daño Secreto y Prensa Metálica de baja prioridad. La presencia de una animación
en este laboratorio no modifica el soporte mecánico ni cierra esos pendientes.

#### Corrección del cubo y referencias contextuales — 2026-10-19

Tras la observación del usuario se confirma que el cubo de SHATTEREDPSYCHE sí
pertenece al recurso original, pero el adaptador lo ensanchaba. Se conserva la
escala afín para los mosaicos de fondo y se declara el patrón 0 de esa secuencia
como forma de escala uniforme. No se modifica su PNG, transparencia ni fotogramas.
Además, los números JSON se normalizan a enteros al cargar la lista de patrones:
la búsqueda en Array distinguía `0` de `0.0` y podía ignorar la declaración. Se
añade una prueba directa del cubo visible, independiente de esa declaración,
desde ambos lados y en ventanas 4:3 y ultrapanorámicas, además de las dos arenas
generales. La proporción original queda preservada; no es aprobación artística
completa de su tamaño, opacidad, cámara ni del resto de recursos. Las cadenas
descartadas siguen fuera de la selección vigente.

El laboratorio amplía su selector a **62 secuencias**: las 40 anteriores, un solo
equivalente de Teraexplosión (TECHNOBLAST por ambos lados) y 20 referencias manuales
de Adaptación/Daño Secreto. Se escogen cinco casos de referencia por movimiento:

| Referencia | Adaptación | Daño Secreto |
| --- | --- | --- |
| Neutra | TRIATTACK | BODYSLAM |
| Campo eléctrico | THUNDERBOLT | THUNDERSHOCK |
| Campo de hierba | ENERGYBALL | VINEWHIP |
| Campo de niebla | MOONBLAST | FAIRYWIND |
| Campo psíquico | PSYCHIC | CONFUSION |

Basado en el [selector de Essentials consultado](https://github.com/Maruno17/pokemon-essentials/blob/master/Data/Scripts/011_Battle/003_Move/012_MoveEffects_ChangeMoveEffect.rb),
con URL/hash conservados en el manifiesto. Son muestras de laboratorio, no un
selector de entorno ejecutado por Battle Core ni cobertura de todos los biomas.
CONFUSION sigue la referencia expresada por el comentario/condición de la fuente;
no se porta su errata `CONFUSIO` ni se cambia código ajeno. La UI muestra
**REFERENCIA VISUAL MANUAL · no ejecuta ni habilita este movimiento**. No se
resuelve un movimiento invocado, tira RNG, aplica daño o cambia clasificación:
Adaptación sigue UNSUPPORTED y Daño Secreto PARTIAL_RUNTIME. Teraexplosión no
activa Tera ni modifica su tipo. CONFUSION no requiere hoja de partículas: se
reproducen sus transformaciones/tono y fondo, sin crear un efecto ficticio.

Reconstrucción vigente:

```powershell
python 'D:\Proyectos\Pokemon Calvo Auditoria Visual\comparacion_ataques_v1\build_resource_pilot.py' --include-max --include-context --output 'D:\Proyectos\Pokemon Calvo\.godot\move_resource_pilot'
```

Generador: **16.511 comprobaciones PASS**, 59 PNG de copia exacta (929.228 bytes),
3.225 fotogramas fuente. Manifiesto SHA-256:
`ea59473cfcc99a3bd0509589c4a79f6c5d48b48031990cb5b9065ffeb400df4b`.
Gate GPU: **399.949 PASS / 0 FAIL**, **628 capturas**; headless: **399.194 PASS /
0 FAIL**. Artefactos vigentes en `.godot/community_move_checks/ea59473cfcc9/`;
`result.json` registra también hashes del renderer y del test, no solo del pack.
Se mantienen calibraciones de mezcla, 19 Max, roles y limpieza; se añaden referencias,
etiquetas de soporte y regresión específica de proporción del cubo. Revisadas
muestras de ambos cubos, variante Tera, Adaptación y Daño Secreto y la advertencia
de interfaz. No equivale a revisar manualmente las 628 imágenes ni a aprobar el pack.

Regresiones repetidas: mapa visual **45 PASS / 0 FAIL**, efectos compartidos
**4.955 PASS / 0 FAIL** con 20 turnos de muestra. Sin cambios en datos, dominio,
IA, workflows, biblioteca F: ni nuevas imágenes; sin commit/push ni nueva CI.
Los recursos permanecen en caché ignorada y conservan los créditos/procedencias
previos. Quedan conexión real, audio, revisión artística/EBDX, variantes restantes
de Garrote y candidato de Prensa Metálica de prioridad baja. La delegación real
de Adaptación y el contexto de Daño Secreto requieren su contrato de dominio:
no se implementan implícitamente al disponer de estas referencias.

#### Variantes de Garrote y candidato de Prensa Metálica — 2026-10-20

El mismo laboratorio amplía la selección a **70 secuencias**. Ya usa los ocho
exports originales de Toxillian: base/fuego/roca/agua por jugador y rival, todos
de 38 fotogramas. Se conservan nombre de archivo y SHA-256 de cada export en el
manifiesto. Las variantes rivales tienen nombres como `Ivy Cudgel Fire Opp`, no
el prefijo `OppMove:`: el enlace ahora reconoce su archivo `_Opp.anm` y no las
trata erróneamente como una adaptación de la versión del jugador.

La revisión visual detectó un estiramiento en esos efectos enfocados a pantalla:
el garrote es un objeto, no un mosaico de fondo. Se conserva la proporción de
escala X/Y indicada por sus celdas para las cuatro paletas, incluido el par base.
Una regresión comprueba esa proporción en cada celda visible, además de los
patrones de color exactos: base 0/4, agua 1/5, fuego 2/6, roca 3/7. No se modifica
el PNG ni se uniforman a la fuerza deformaciones que ya contenga la animación fuente.

Las tres variantes adicionales se rotulan como **VARIANTE DEL EFECTO · no cambia
la forma ni activa máscaras de Ogerpon**. Se sigue usando la especie base del
catálogo para comparar; no se han conectado sus formas alternativas ni mecánicas.
Sus créditos permanecen en Toxillian y las procedencias ya anotadas.

Prensa Metálica incorpora un candidato equivalente HEAVYSLAM de 27 fotogramas
por lado. No hay export rival propio en el paquete: ese lado está marcado como
adaptado. Se comprueban origen, destinatario y limpieza entre clips. No se afirma
que sea una animación propia de Hard Press ni la mejor alternativa definitiva.
Su fórmula de daño no se implementa ni altera: conserva clasificación DATA_ONLY,
con advertencia explícita en la UI. No se añade al pool final por esta muestra.

Reconstrucción vigente:

```powershell
python 'D:\Proyectos\Pokemon Calvo Auditoria Visual\comparacion_ataques_v1\build_resource_pilot.py' --include-max --include-context --include-extras --output 'D:\Proyectos\Pokemon Calvo\.godot\move_resource_pilot'
```

Generador: **17.428 comprobaciones PASS**, 60 PNG de copia exacta, 930.030 bytes
comprimidos; 3.507 fotogramas fuente. Manifiesto SHA-256:
`b0fb641710512bfca59544ef3b70f4f989a493548f9cfa123d08ace586fcb6d9`.
Gate GPU: **445.694 PASS / 0 FAIL**, **708 capturas** y 494 diferencias visibles
respecto del inicio; headless **444.843 PASS / 0 FAIL**. Artefactos actuales en
`.godot/community_move_checks/b0fb64171051/`, con hashes del pack, renderer y test.
Revisadas muestras de las nuevas paletas desde ambos lados, el equivalente de
Prensa Metálica y las advertencias de interfaz. No revisión humana exhaustiva de
las 708 capturas ni aprobación artística final. Se mantienen los casos anteriores
de Max, Tera y referencias manuales; los contratos de dominio siguen intactos.

Regresiones repetidas: mapa visual **45 PASS / 0 FAIL**, efectos compartidos
**4.955 PASS / 0 FAIL** con 20 turnos. Comprobados HEAD/rama remotos y sus 19 checks
SUCCESS; el trabajo sigue local, sin commit/push ni CI nueva. Sin datos brutos,
dominio, IA, learnsets, workflows o biblioteca F: modificados. Recursos fuera de Git.

La lista prioritaria tiene ahora candidatos reproducibles en el laboratorio,
no implementación completa de los movimientos. Siguiente prueba acotada posible:
conectar un movimiento ya soportado a eventos reales de la demo, manteniendo las
referencias DATA_ONLY/UNSUPPORTED fuera de cualquier habilitación implícita. Antes
de una conexión general/adopción definitiva quedan revisión artística/comparación
EBDX, permisos/procedencias y empaquetado; audio continúa pendiente.

#### Primer lote elemental en combate real — 2026-10-23

La continuación prioriza gráficos sin implementar otro sistema de combate.
Adaptación aún es UNSUPPORTED sin llamada delegada; Daño Secreto conserva solo
daño Normal sin contexto/efecto ambiental, y Max no implica que exista Dinamax.
No se cambian esos límites ni se les inventa un contexto a partir del mapa.
Se añade un lote acotado de tres movimientos existentes RUNTIME_SUPPORTED:
Lanzallamas, Rayo y Rayo Hielo, con sus efectos originales de Gen 9. El registro
visual ahora admite cinco IDs (incluidos Ivy/Tera) y diez clips, no los 919 moves.

| Movimiento | Frames back/front | Impacto back/front | Fin PS | Recurso rival |
|---|---:|---:|---:|---|
| Lanzallamas | 19 / 20 | 7 / 8 | 18 | OppMove propio |
| Rayo | 27 / 27 | 14 / 14 | 23 | Export de usuario adaptado |
| Rayo Hielo | 28 / 28 | 6 / 6 | 22 | OppMove propio |

Todo a 20 fps. El marcador de fuego coincide con la primera reacción/partícula
del destinatario en cada export; Rayo usa la señal fuente Thunderbolt1 en 14;
Hielo la primera cel de impacto visible (patrón 12) en 6. El builder valida esas
señales y el binding valida referencias, longitudes y marcadores por lado.
No alargar artificialmente el export de usuario de Lanzallamas para igualarlos.
Los tres contratos exigen tipo correcto, categoría especial, potencia 90,
selected-pokemon y RUNTIME_SUPPORTED; no se amplía la excepción parcial de Tera.
Se conservan partículas nativas y su trayectoria; BG/FG y cuerpos del export
siguen omitidos en combate, pero no en el laboratorio completo. Rayo tiene una
pausa auténtica antes de su segundo golpe: frame sin partículas no es fallo ni
motivo para generar fotogramas nuevos. La esfera de hielo pertenece al ataque,
no certifica por sí misma que el motor haya aplicado congelación.

**Prueba manual:** `JUGAR_DEMO.cmd`, F5 o «F5 · Elementales (reinicia)»; cada
pulsación válida prepara el siguiente de los tres, ciclando después al primero.
El aviso indica cuál. Entrar en la hierba y usar el ataque. Es el mismo preset
temporal Charizard/Wailord Nv.50, encuentros al 100 %, PP tomados de la definición
(15/15/10), no un cambio de aprendizaje. Reiniciar reconstruye el moveset natural.
F4 conserva Tera normal. Durante combate/ajustes/transición/galería no reinicia
ni avanza la selección; IDs no permitidos o recursos ausentes tampoco se habilitan.

Pack opcional `.godot/battle_elemental_pilot/`: nueve PNG originales, 271.844 bytes;
manifiesto 336.904 bytes (608.748 en total), 1.742 comprobaciones del conversor.
SHA-256 `a6534d9b1e26691b37582b4b5091940d04df0168e6cde342a77e6cffd4c7c3a0`.
Conserva los paquetes de cuatro y dos clips como fallback por ausencia; un pack
inválido sigue sin habilitarse. No se instala Ruby ni un importador general.
Fuentes, créditos y condiciones siguen siendo los del archivo Gen 9 ya registrado;
no se descargan nuevos recursos ni se presupone permiso de distribución comercial.

```powershell
python 'D:\Proyectos\Pokemon Calvo Auditoria Visual\comparacion_ataques_v1\build_resource_pilot.py' --battle-elemental-set --output 'D:\Proyectos\Pokemon Calvo\.godot\battle_elemental_pilot'
```

Gate focal final: **542 PASS / 0 FAIL GPU**, 40 capturas, 19 clips muestreados;
**407 PASS / 0 FAIL headless**. Incluye las pruebas anteriores de Ivy/Tera y el
nuevo lote por ambos lados. Las fixtures ajustan PS/abilities/movesets solo en
memoria. Se buscan semillas en un servidor clonado y luego se ejecuta el comando
real con ese RNG para observar quemadura/parálisis/congelación nativas: sin forzar
el estado, cambiar la probabilidad ni usar un mock del movimiento. En replay se
comprueba igualdad del snapshot completo, incluyendo RNG/estados/PP; un congelado
que no responde no recibe una animación de ataque inventada. Los secundarios y
el residual de quemadura no duplican el golpe. STATUS_APPLIED lleva move_id vacío
en nuestro motor, así que la prueba usa actor/destinatario del evento real, no un
ID de movimiento que el evento no contiene. No se cambia ese contrato del motor.
Verifica además contratos alterados, daño cero/miss/reactivo, presets/restauración,
trayectorias próximas al cuerpo real y compatibilidad de los packs anteriores.
Resultados con hashes y capturas siguen en `.godot/battle_community_checks/`.
Revisadas las seis muestras de impacto desde ambos lados, preset de mapa y una
muestra de secundario de hielo; no se certifica artísticamente todo el pack.

Regresiones ejecutadas: cronología headless **19.726 PASS**, VFX **4.949 PASS**,
laboratorio **444.847 PASS**, mapa **45 PASS**, runtime de mapa **103 PASS**;
Tera **66 PASS** y tres tests Python. VFX conserva las 919 comprobaciones de
metadatos y los 20 turnos de muestra: Rayo Hielo sustituye cast/hit genéricos por
preparación/clip comunitario y se comprueba esa sustitución, por eso cambia el
contador en lugar de forzarlo al número anterior. No se repite la batería DATA
completa ni su CI: los nueve fallos ambientales previamente documentados no se
presentan como resueltos. Hashes raw/normalized idénticos al tramo de Tera.
Sin cambios en dominio, aprendizaje, RNG, probabilidades, datasets, F:, main,
workflows, commit/push o publicación. Los otros movimientos conservan su fallback.

#### Segundo enlace a combate real: Teraexplosión normal — 2026-10-23

Tras la corrección de datos del apartado siguiente, se conecta su único equivalente
TECHNOBLAST al mismo `field_demo.tscn`, sin otra demo ni plugin. El piloto acepta
solo dos IDs: Garrote base mantiene RUNTIME_SUPPORTED/grass/physical; Tera exige
**PARTIAL_RUNTIME/normal/special/80/selected-pokemon/effect_specs vacío**. Los
metadatos de presentación añaden power/effects_empty como valores primitivos,
no referencias al dominio. Si cambia cualquiera de esos requisitos, vuelve al
efecto genérico; no se admite globalmente PARTIAL_RUNTIME ni el conjunto del lab.

El binding decora copias del plan solo para DAMAGE_APPLIED positivo, relacionado
por el plan con la acción/origen/destinatario correctos. Miss, cero, residual,
retroceso y daño reactivo no reproducen un golpe comunitario. Se suprime el doble
efecto geométrico de preparación/impacto, no el intento fallido. Los snapshots,
resultados, PP, IA y RNG siguen siendo del turno original; el replay no los ejecuta.

**Tiempo propio:** TECHNOBLAST consta de 70 frames a 20 fps (3,5 s), tanto export
normal como OppMove nativo. La señal fuente «PRSFX- Techno Blast 2.wav» está en 47;
se usa como marcador visual de impacto (2,35 s, audio aún omitido). El mensaje
espera ese punto y los PS interpolan la cantidad real hasta 59 (2,95 s), señal
de inicio de fade del recurso. Las entradas de la cronología llevan sus tiempos
individuales, no constantes globales de Garrote. Garrote conserva 29/37/38.
Un KO de un solo PS puede seguir mostrando 1 por redondeo durante la primera mitad
de la interpolación: no significa que el motor haya ignorado el daño.

La revisión GPU inicial detectó dos defectos que un PASS numérico no descartaba:

- Las placas BG del export quedaban sobre los cuerpos de la arena existente y
  los ocultaban casi totalmente. El modo effects_only ahora omite placas BG/FG
  además de los cels corporales negativos. Conserva solo partículas originales
  sobre los cuerpos/reacciones del juego; no es una reproducción integral del
  motor Essentials ni su cambio cinematográfico de fondo.
- La trayectoria del export de usuario está codificada con focus de usuario,
  aunque viaja hasta el otro actor de la cámara original. Escalar esos offsets
  uniformemente dejaba el estallido arriba/a la izquierda de Wailord. El binding
  solicita explícitamente affine_particle_path para Tera: adapta posiciones entre
  los dos centros reales sin estirar la forma de las partículas. El rival nativo
  ya usa trayectoria entre focos. Se contrasta el cel de impacto con el centro
  real del destinatario en capturas de ambos lados, incluido entrenador.

Estos cambios solo se aplican en el modo acotado de combate. La previsualización
completa del laboratorio mantiene sus cuerpos, fondos y geometría originales;
no se han modificado imágenes ni creado sprites.

**Prueba manual:** en `JUGAR_DEMO.cmd`, pulsar F4 o «F4 · Ensayo Tera (reinicia)»
y entrar en la hierba derecha. El preset reinicia explícitamente la prueba con
Charizard Nv.50, Wailord salvaje Nv.50 y encuentros al 100 %. Asigna Teraexplosión
solo al Pokémon temporal en memoria; el catálogo no tiene especies que la aprendan
por nivel. El rótulo avisa de ensayo sin Tera y el diagnóstico registra el preset.
«Reiniciar»/aplicar ajustes reconstruye el moveset natural. No cambia learnsets,
reglas de TM, juego guardado o dataset. El botón se bloquea durante combate,
transición, galería o ajustes abiertos; sin pack/contrato válido no reinicia nada.
Los rivales manuales mantienen sus ataques normales; las respuestas Tera de las
pruebas automáticas son fixtures explícitas en memoria, no asignación al pool.

**Pack pequeño opcional:** `.godot/battle_base_pilot/manifest.json`, cuatro clips
(Ivy/Tera por ambos lados), cuatro PNG originales con suma de 55.349 bytes,
manifiesto 184.288 bytes, 835 comprobaciones de conversión. SHA-256 del pack:
`4901b01b3e21d4d08e212716962bab578e4f6cef9d11a377fb960734b99521c0`.
Reconstrucción independiente del laboratorio:

```powershell
python 'D:\Proyectos\Pokemon Calvo Auditoria Visual\comparacion_ataques_v1\build_resource_pilot.py' --battle-base-pair --output 'D:\Proyectos\Pokemon Calvo\.godot\battle_base_pilot'
```

Se validan selección exacta, tiempos, referencias y clasificaciones, además de
los hashes PNG ya verificados por el renderer. Sin el nuevo manifiesto se intenta
el pequeño pack anterior de Garrote; sin ambos permanece el fallback genérico.
Un pack inválido no se habilita. Reejecutado el generador legado de dos clips:
conserva exactamente su hash d1a8622e…; no se pierde el piloto anterior. Los recursos
siguen en caché ignorada, con fuentes/créditos/condiciones del cuaderno, sin
publicación ni licencia comercial presumida.

**Gate final** `battle_community_pilot_test_runner.gd`: **237 PASS / 0 FAIL GPU**,
17 capturas, ocho clips muestreados y dos KO adicionales con reloj natural;
**180 PASS / 0 FAIL headless**. Cubre ambos movimientos/lados, sincronía distinta,
ausencia de placas/cuerpos duplicados, destino real, bloqueo de comandos, miss
real, cancelación, retorno tras captura/KO de entrenador y settlement sin estado
vivo. Verifica también el preset/restauración natural, rechazo de metadatos Tera
alterados, de otros PARTIAL_RUNTIME y compatibilidad del pack legado. Muestras
revisadas visualmente (incluidos fondo corregido, ambos impactos y el HUD de F4),
no aprobación artística de todos los recursos. Artefactos en
`.godot/battle_community_checks/`: gpu_result.json/headless_result.json conservan
resultados separados; result.json es el último. Incluyen hashes de pack, binding,
renderer, playback, escena de campo, dataset y test.

Regresiones ejecutadas: cronología headless **19.726 PASS**, VFX **4.955 PASS**,
laboratorio **444.847 PASS**, mapa visual **45 PASS**, runtime de mapa **103 PASS**;
datos Tera **66 PASS** y tres tests Python. No se repitió aquí el gate GPU completo
de 70 clips ni la batería DATA completa. Sus nueve fallos ambientales previos
documentados siguen fuera de esta certificación focal. Los hashes raw/normalized
siguen siendo los del tramo de corrección: este enlace no modifica datos ni motor.
Sin cambios en F:, Ruby ejecutado, workflows, main, commit/push o CI nueva.

Quedan audio, aprobación artística, contraste EBDX y más conexiones acotadas.
Nature/Secret necesitan resolver delegación/contexto en el dominio; Max/Dynamax,
Prensa Metálica, máscaras y Tera/Astral no se habilitan por contar con clips.

#### Corrección acotada de Teraexplosión normal — 2026-10-23

Tras el «sigue» posterior al diagnóstico, se corrige la conversión de ese único
movimiento, sin añadir teracristalización. `tools/pokeapi_adapter.py` valida el
contrato del origen fijado (ID 851, Normal/especial/80/100/10, target selected-
pokemon, meta null y dos stat_changes -1) y la forma de los efectos heredados.
Si cambia ese contrato, aborta: no elimina silenciosamente efectos desconocidos.
Solo para `tera_blast` descarta los dos descensos que pertenecen al caso Astral.
No se retargetean a SELF de forma incondicional. La cobertura se corrige de
RUNTIME_SUPPORTED a **PARTIAL_RUNTIME**: el daño normal es el subconjunto válido,
no el cambio de tipo/categoría, la potencia Astral ni sus descensos condicionados.
Referencia contrastada de nuevo el 2026-10-23:
[implementación de Showdown](https://github.com/smogon/pokemon-showdown/blob/master/data/moves.ts#L19167).

No se regenera el dataset completo ni se descarga/checkout el snapshot de GB.
`tools/refresh_tera_blast_v3.py` lee el blob inmutable
`121f719bc1b51595e5229f5f9a422786cce69073` (69.344 bytes, SHA-256
`eeca6b6db91b92f8009472a09b801a1146d4be2b49513e50f9c1e8e8bb4cce26`)
desde Git, valida el hash y lo ofrece en un directorio temporal byte-idéntico
al **build_moves** canónico de V3. Sustituye solo la fila derivada de Tera si
coincide exactamente con la anterior conocida o la ya corregida; rechaza cambios
locales inesperados. No altera data/api ni data/schema y es idempotente.
Después se usa `tools/run_import.gd`, sin editar el JSON normalizado a mano.

```powershell
python tests/data/test_tera_blast_adapter.py
python tools/refresh_tera_blast_v3.py          # dry run
python tools/refresh_tera_blast_v3.py --apply
& 'C:\Godot\4.7\Godot_v4.7-stable_win64_console.exe' --headless --path . --script tools/run_import.gd
& 'C:\Godot\4.7\Godot_v4.7-stable_win64_console.exe' --headless --path . --script tests/data/tera_blast_test_runner.gd
```

La comparación semántica raw/normalized contra HEAD confirma **solo**
`tera_blast.effect_specs` y `.classification` modificados. Sin cambios de los
otros 918 movimientos, especies, learnsets, objetos, habilidades, tipos o
manifest. Importación: 1.025 especies, 919 movimientos, 61.102 entradas de
learnset, 554 evoluciones, cero rechazos/referencias rotas. SHA-256 raw:
`2efc1538081e7849d6e04555570ca28c19b13f09f0fe0c7ce38329881972f24a`;
normalized: `719d14c082bdba03b26e801d23fb8887d0a0f4376348cf4a27e79a4b0a3c08b3`.
El cierre estructural actualiza solo sus buckets esperados 590/71 -> 589/72
(RUNTIME_SUPPORTED/PARTIAL_RUNTIME), sin debilitar verificaciones.

Pruebas red/green: el test Python reproduce los efectos incorrectos antes del
cambio; después pasan sus tres métodos (incluidas ocho mutaciones rechazadas,
origen sin mutar y controles Psychic/Overheat/Noble Roar). La regresión Godot
parte de 38 PASS / 28 FAIL y termina **66 PASS / 0 FAIL**. Comprueba importación
raw y catálogo normalizado, ambos lados del servidor y semillas reales 1/42/2026:
daño positivo, ausencia de eventos de descenso, etapas de ambos sin cambios,
PP consumido una sola vez y valores/cobertura correctos. Las criaturas son
fixtures en memoria; ninguna definición del movimiento se reemplaza por un mock.
La suite se añade al runner DATA existente para ejecutarse también en su ruta
normal de CI, sin cambiar workflows.

Regresiones headless ejecutadas: Garrote **80 PASS**, VFX **4.955 PASS** (20 turnos
de muestra), laboratorio **444.847 PASS**, mapa visual **45 PASS** y runtime del
mapa **103 PASS**. El laboratorio se reconstruye con las
mismas opciones previas; el diff del pack solo modifica classification_unchanged
en `tera_blast/back` y `/front`. Los 70 clips, todos sus frames e imágenes son
idénticos; no se repite GPU ni se declara nueva aprobación artística. Pack nuevo:
`9122c8ba07b23b33f89fce7d41523d8c62658882febafd4fa780abcc87f61033`.
El pequeño pack de combate de Garrote y su binding/cronología/renderer no cambian.

**Límite de validación completa:** antes de tocar código, el runner DATA completo
dio 558 PASS / 9 FAIL en esta copia sparse. Después: 624 PASS / exactamente los
mismos nueve IDs. Dos verificaciones de ability_contract usan el informe antiguo
sin clasificación de habilidades; seis contratos necesitan fuentes de habilidades
ausentes (Bad Dreams, Rain Dish, Ice Body, Merciless, Rivalry, Stakeout); el cierre
global usa auditoría ausente/informe antiguo. Logs comparables en
`.godot/tera_fix_baseline_data.log` y `.godot/tera_fix_after_data.log`. No se han
omitido, rebajado o «arreglado» esos tests, ni modificado habilidades para callarlos.
No hay certificación completa nueva ni CI sobre estos cambios locales. Los
fixtures históricos de CI no se sobrescriben con un informe parcial inventado.

Siguiente paso visual seguro: contrato explícito del subconjunto Normal de
Teraexplosión y marcadores de su clip TECHNOBLAST (la fuente contiene señales en
32 y 47; falta decidir/revisar el impacto en nuestra cámara). No reutilizar las
constantes temporales de Garrote ni habilitar genéricamente PARTIAL_RUNTIME.
La animación de Tera continúa en el laboratorio, no en combate real. Sin cambios
de motor, F:, mecánicas Tera/Astral, main, workflows, commit/push o publicación.

#### Hallazgo mecánico al preparar Teraexplosión — 2026-10-20

La conexión de Teraexplosión al combate real se detiene antes de editar el
binding/cronología o generar otro pack. `data/normalized/pokemon_api.json`
declara `tera_blast` RUNTIME_SUPPORTED, Normal/especial, potencia 80, pero sus
dos `effect_specs` son `modify_stat_stage`, destinatario `opponent`, valor -1,
chance 10000, para `attack` y `special_attack`, sin condición alguna.
Disponibilidad de un efecto visual y clasificación declarada no certifican
corrección semántica del movimiento. Garrote base sigue siendo el único enlace.

Reproducción diagnóstica fuera del repositorio:

```powershell
& 'C:\Godot\4.7\Godot_v4.7-stable_win64_console.exe' --headless --path 'D:\Proyectos\Pokemon Calvo' --script 'D:\Proyectos\Pokemon Calvo Auditoria Visual\comparacion_ataques_v1\audit_tera_blast_runtime.gd'
```

El script crea tres escenas/encuentros nuevos de hierba de la demo existente;
Charizard Nv.50 usa la definición real de Teraexplosión contra Wailord Nv.50.
Las únicas fixtures son movesets temporales en memoria (rival con Recuperación)
y PS del rival a 2000 para evitar KO; no cambian JSON, reglas ni learnsets.
El replay queda detenido; se examinan los eventos ya resueltos del dominio.
En las tres reproducciones: daño 66 y dos STAT_STAGE_CHANGED sobre el rival,
etapas 0/0 -> -1/-1. Son repeticiones del mismo encuentro determinista, no
tres semillas diferentes ni una auditoría completa. Resultado
`DEFECT_CONFIRMED`, no un gate de mecánicas PASS. Evidencia externa:
`tera_blast_runtime_probe.json` junto al script. Hash del catálogo sin cambios:
`3038155b218e7fd1192090e003b45e59bb187d790a54c54272008fd3cedc764f`;
SHA-256 del diagnóstico:
`c31b016ecb4196b8d0ead2817007eefa4f9148599f448e7070698c20f73ed7a9`.

Contraste con implementación primaria, consultada 2026-10-20:
[Pokémon Showdown, `terablast`](https://github.com/smogon/pokemon-showdown/blob/master/data/moves.ts#L19167).
Sin Tera no hay bajada; en Astral añade `move.self` con ambos descensos,
no al oponente. Las condiciones de tipo/categoría y la potencia Astral son
otro alcance: no se ha implementado teracristalización aquí.

Origen probable localizado: el helper archivado
`tools/archive/pokeapi_adapter_v2_legacy.py::generate_move_specs` infiere el
destinatario de cambios de etapas del target general del movimiento y transforma
`stat_chance == 0` en 10000. El shim V3 `tools/pokeapi_adapter.py` lo llama;
su reparación `damage-raise` no protege este caso. Evaluación diagnóstica del
helper sobre [PokéAPI actual, movimiento 851](https://pokeapi.co/api/v2/move/851/)
produce en memoria los mismos dos efectos al rival y RUNTIME_SUPPORTED.
La API consultada devuelve `meta: null`, dos stat_changes -1 y target
selected-pokemon. Esta consulta viva no sustituye el snapshot fuente fijado ni
demuestra qué contenía históricamente; no se descargaron snapshots ni se ejecutó
el adaptador completo. El defecto del catálogo y su efecto real sí están probados.

El blob Git del catálogo local coincide con el de HEAD
`0902de4c10d34a2a451c9acad83fbfea765ef270`:
`74ab908e113490f3a8fabafeac4c410bcbbe2b6c`. Por tanto, esta entrada no fue
introducida por el trabajo visual local. Los 19 checks remotos de ese SHA siguen
SUCCESS; no cubren este caso semántico. Reejecutado tras el diagnóstico el gate
headless de Garrote: **80 PASS / 0 FAIL**, mismos hashes del pack/binding/playback/
renderer. No se repitió GPU ni se certificó el conjunto de movimientos.

Siguiente decisión necesaria: autorizar un tramo separado/acotado de corrección
de conversión/dato derivado con prueba de regresión y proceso canónico; no
parchear el JSON inmutable a mano, ocultar eventos con VFX ni implementar Tera
completa por accidente. Hasta entonces se conserva el candidato TECHNOBLAST en
el laboratorio y no se incorpora al piloto de combate. No hay cambios de
dominio, generación masiva, commit/push, workflows ni biblioteca de F:.

#### Primer enlace a combate real: Garrote Liana base — 2026-10-20

La demo existente (`JUGAR_DEMO.cmd` / `field_demo.tscn`) enlaza ahora **solo Garrote
Liana base** con los eventos resueltos del combate salvaje y de entrenador. No es
otra demo ni una habilitación de los 70 clips. Para verlo sin cambiar learnsets:
F1, primer Pokémon `ogerpon` a nivel 50, salvaje fijo `wailord` a nivel 50, aplicar
y entrar en la hierba; elegir Garrote Liana. Se ha comprobado que el moveset normal
de Ogerpon a ese nivel ya lo contiene. F3 sigue siendo galería de cuerpos, no VFX.

`battle_community_move_pilot.gd` decora copias de la cronología únicamente si el
movimiento coincide con la lista blanca de un ID, su metadato actual es
RUNTIME_SUPPORTED/grass/physical y existe DAMAGE_APPLIED positivo, correlacionado
por el plan con la acción/origen/destinatario visibles. Fallo, daño cero/inmunidad,
retroceso, residual, daño reactivo y clasificaciones no soportadas no activan ese
clip. No se cambia la resolución del turno, daño, precisión, IA, PP ni RNG.

El enlace reproduce las partículas originales sobre los cuerpos ya existentes,
no los sprites/cambios de tono corporales del export. Las poses/reacciones de la
demo siguen siendo suyas. No se duplican criaturas ni se reproduce además el
efecto geométrico de hierba para ese golpe confirmado. Los intentos sin daño
conservan su representación compartida; no se inventa una secuencia de impacto.
Es una adaptación experimental, no reproducción íntegra del motor de Essentials.

Duración del efecto: 38 fotogramas a 20 fps (1,9 s). Se comprueba la señal original
de impacto en el fotograma 29 (1,45 s); la barra empieza entonces a interpolar la
cantidad real del evento, hasta el fotograma 37. El mensaje de daño también espera
a ese punto. Cancelar/ocultar limpia las partículas y reconcilia PS/mensajes reales
sin perder el texto aún pendiente, gastar otra vez recursos ni repetir el turno.
Los comandos permanecen bloqueados hasta terminar. Se mantiene correctamente KO,
settlement que libera BattleState y retorno al mapa, también con reloj natural.

El pack activo es pequeño y separado del laboratorio: dos clips, un PNG original
de 10.085 bytes, `.godot/battle_ivy_pilot/`. Si no existe, el combate usa los efectos
compartidos previos: no se hace obligatorio para la CI normal ni se habilitan otros
movimientos. Reconstrucción independiente (sin las opciones del laboratorio):

```powershell
python 'D:\Proyectos\Pokemon Calvo Auditoria Visual\comparacion_ataques_v1\build_resource_pilot.py' --battle-ivy-only --output 'D:\Proyectos\Pokemon Calvo\.godot\battle_ivy_pilot'
```

Generador: 267 comprobaciones registradas PASS y señal de impacto verificada;
SHA-256 del manifiesto:
`d1a8622ef73a8f45620742b90d1bd715bd831fd4663f5621d0d78dfbb8779d64`.
No se copian nuevos gráficos al repositorio ni se importan Ruby/plugins. Se mantienen
atribución de Toxillian, fuente/hash y condiciones anotadas; no hay publicación.

Gate local `battle_community_pilot_test_runner.gd`: **80 PASS / 0 FAIL headless**;
**104 PASS / 0 FAIL con GPU**, ocho capturas, cuatro clips muestreados y un KO
salvaje adicional con procesamiento normal de frames y moveset natural del jugador.
Incluye turno real por ambos lados, miss real, cancelación antes de impacto,
mensajes/PS temporizados, trainer KO, disponibilidad opcional y snapshots de
dominio/RNG. Las fixtures de respuesta predecible asignan Ivy a criaturas solo
en memoria de test y ajustan PS; no alteran datos ni reglas de aprendizaje.

La comprobación gráfica encontró un fallo al redimensionarse el panel de entrenador:
las coordenadas de partículas aún correspondían al tamaño anterior. Corregido
recalculando el fotograma visible tras NOTIFICATION_RESIZED; se comparan ahora los
centros con los cuerpos realmente dibujados, no solo con valores del adaptador.
También beneficia al laboratorio pausado. Artefactos/resultado con hashes del pack,
binding, cronología y renderer en `.godot/battle_community_checks/`. Revisadas las
ocho muestras de preparación/impacto salvaje y KO de entrenador; no aprobación de
todas las especies/poses/tamaños ni de todo el estilo artístico.

Regresiones repetidas: cronología headless **19.726 PASS**, efectos **4.955 PASS**,
catálogo **26.042 PASS**, mapa visual **45 PASS**, runtime mapa **103 PASS**; todas
0 FAIL. Laboratorio GPU **445.694 PASS / 0 FAIL**, 708 capturas. Sin nueva CI ni
commit/push; HEAD remoto certificado no certifica estos cambios locales. Permanecen
sin cambios datos, dominio, IA, workflows, pool, learnsets y originales F:.

Tera, Max, Prensa Metálica y referencias contextuales siguen fuera de esta conexión.
Las variantes de máscara de Ivy tampoco se seleccionan por omisión. Próximo paso
acotado: evaluar otra conexión soportada (p. ej. un solo equivalente neutral de
Teraexplosión), no habilitar la biblioteca entera. Audio, aprobación/comparación
artística, revisión de condiciones y empaquetado final siguen pendientes.

#### Historial del filtro de huecos — sustituido por las prioridades anteriores

El texto siguiente conserva el estado de investigación anterior; no es la lista
activa. En particular, Toxillian ya está descargado y los Max ya no se excluyen.

El usuario pide ignorar ataques exclusivos de un juego/modo concreto al preparar
la lista visual pendiente. Interpretación operativa explícita: apartar exclusivos
Let's Go, Max/Dinamax, Z y Torque de los vehículos; no eliminar automáticamente
ataques por haberse estrenado en una generación ni por ser propios de una especie.
Es un filtro de investigación artística, no una modificación del catálogo, reglas,
learnsets o pool aleatorio. Tampoco aprueba la teracristalización por omisión.

De los 41 IDs sin etiqueta tras los alias candidatos, se apartan 38: 19 Max,
13 Let's Go, 5 Torque y el Z especial `10_000_000_volt_thunderbolt`.
Queda esta lista de huecos de etiqueta en el archivo Gen 9 descargado:

| Movimiento | ID canónico | Situación |
| --- | --- | --- |
| Prensa Metálica / Hard Press | `hard_press` | Falta en el archivo base; referencias de Showdown localizadas, no adaptadas. En nuestro catálogo es `DATA_ONLY`, asunto mecánico separado. |
| Garrote Liana / Ivy Cudgel | `ivy_cudgel` | Falta en el archivo base. [Toxillian publicó una animación por máscara](https://eeveeexpo.com/threads/5817/page-14); candidato sin descargar/validar en esta revisión. Atribución adicional: Toxillian y procedencias que incluya ese aporte, si se adopta. No se excluye solo por ser característico de Ogerpon. |
| Teraexplosión / Tera Blast | `tera_blast` | Caso condicionado por su relación con teracristalización. Mantener separado hasta confirmar si el criterio del usuario también lo excluye; no se elimina unilateralmente ni se presenta como función de Tera ya implementada. |

La [lista de pendientes del autor del paquete](https://eeveeexpo.com/resources/1480/)
también identifica esos tres movimientos. Estado resumido: **dos candidatos
principales y uno condicionado**, no una certificación de que todo lo demás funciona.
Las dos entradas de un fotograma (`nature_power` / Adaptación y `secret_power` /
Daño Secreto) siguen como revisiones, no como ausencias confirmadas. Los 37 alias
candidatos siguen pendientes de validación y no se convierten en cobertura ejecutada.

#### Registro de créditos condicionado al uso efectivo

No significa que estos paquetes ya se utilicen ni que baste acreditar para cualquier
redistribución. Conservar autores, fuente, versión/hash y qué archivos se adopten.
Los nombres deben poder consultarse en créditos/menú; el usuario acepta un roll final
y agradecimientos en el mapa, sin construir ahora esas pantallas.

- **EBDX:** la [página del autor](https://eeveeexpo.com/resources/1230/) solicita
  acreditar a **NikDie** y **Luka S.J.**. Si se toman componentes de la base, conservar
  también sus [créditos de procedencia](https://luka-sj.com/essentials/resources/ebdx):
  GameFreak, Pokecheck.org, PinkCatDragon, Tebited15, WolfPP, Issei Hyoudou, Nasasu,
  luckygirl88, Spriters-Resource/redblueyellow, Damien, BadSamaritan, Pokémon Essentials,
  Maruno, Marin y Golisopod User, según los recursos finalmente usados.
- **Gen 9:** conservar los créditos publicados en la
  [página del proyecto](https://eeveeexpo.com/resources/1480/): equipo de Pokémon
  Reborn; StCooler, DarrylBD99, WolfPP, ardicoozer, riddlemeree y Drake Baku;
  BellBlitzKing por el pack de sonidos; KRLW890, Nut0066, Toxillian,
  QuahogTheCreator, Lcorp y Shashu-Greninja. Mantener cualquier atribución adicional
  de los archivos concretos que se elijan, sin adjudicar su autoría al adaptador.

Las páginas ofrecen recursos para Essentials/EBDX, no una licencia universal de
todo el contenido en cualquier motor. Los archivos contienen gráficos/sonidos de
distinta procedencia. Algunos nombres de Gen 9 coinciden con nomenclatura de RTP
(`015-Fire01`, `016-Ice01`, etc.): es un indicio que exige comprobar origen, no una
identificación jurídica por nombre. Las
[condiciones actuales de materiales de RPG Maker](https://rpgmakerofficial.com/en/support/rule/)
permiten usos en otros motores a usuarios con la adquisición autorizada correspondiente;
no se ha comprobado que el usuario tenga esa licencia ni se compra nada. Si un recurso
exige una licencia no disponible, excluirlo o buscar alternativa permitida. Revisar
también condiciones de autores y derechos originales de Pokémon antes de distribuir;
gratuito y con créditos no equivale automáticamente a libre de condiciones.

### Efectos compartidos por tipo y categoría (2026-10-19, estado actual del juego)

`battle_move_visuals.gd` selecciona una receta geométrica a partir del tipo y la
categoría de la definición real del movimiento, no del tipo de la especie.
Los 18 tipos reutilizan familias de formas y paletas: llamas, burbujas, rayos,
hojas, fragmentos, anillos, remolinos, cortes y destellos. No son imágenes nuevas,
animaciones individuales de 919 ataques ni arte final. La galería sigue mostrando
solo los clips originales, sin añadir estos efectos de combate.

- La acción física muestra un signo próximo al atacante; la especial proyecta
  formas hasta antes del contorno del destinatario. La aparición en el blanco
  es un paso separado que requiere `damage_applied` positivo, con actor,
  movimiento y destinatario coincidentes con la acción real.
- Fallos, inmunidad/daño cero, acciones impedidas, retroceso y daño reactivo no
  inventan un impacto elemental. El daño residual conserva su reacción genérica.
- Los movimientos de estado muestran una señal suave en el emisor. Los eventos
  de cambio efectivo de estadísticas o recuperación con `move_id` coincidente
  permiten una señal de apoyo en el destinatario real, incluida curación propia.
  No se infiere procedencia cuando falta el ID: por ejemplo, el sistema de estados
  actual emite `status_applied` sin movimiento y conserva su mensaje sin este
  destello de apoyo. Tipos/IDs desconocidos no se sustituyen por uno inventado.
- Los centros y radios se leen del encuadre estable de las imágenes. Los efectos
  no cambian tamaños, filtrado ni atlas. En poses corporales largas el lanzamiento
  ocupa los últimos 0,6 s como máximo, no toda la duración del clip.
- La representación lee copias de metadatos y eventos ya resueltos. No ejecuta
  reglas, consume RNG, cambia PS ni alarga la cronología existente. Se limpia al
  finalizar/cancelar y al abrir otro combate; continúa el bloqueo de entradas.

Gate focal `battle_move_visuals_test_runner.gd`: **5.001 PASS / 0 FAIL**, 46 capturas
OpenGL en `.godot/move_vfx_checks/`. Comprueba metadatos de los 919 movimientos,
recetas de los 18 tipos, propiedad de instancias visibles, ausencia de impactos
falsos y destino de apoyo. Ejecuta 18 movimientos representativos —uno por tipo—
más Gruñido y Recuperación en encuentros reales, comparando estado final y RNG
antes/después de reproducir. No ejecuta los 919 ni certifica todas sus mecánicas.
Pasada headless del mismo gate: 4.955 PASS / 0 FAIL, sin capturas.

Regresión gráfica de cronología/ciclo de combate: 19.790 PASS / 0 FAIL, 64 capturas.
Se mantienen los gates de catálogo, mapa, captura, huida, cambios, sesión de
entrenador, clips, filtro y encuadre descritos debajo; todos 0 FAIL en la nueva
pasada. Revisadas muestras de fuego, agua, electricidad y apoyo, no todas las
especies manualmente. Trabajo local sin commit/push ni nueva certificación remota.
Siguen pendientes audio, formas alternativas y pulido/aprobación artística final.

### Captura, cambios y debilitamiento compartidos (2026-10-19)

La presentación añade ciclo visual reutilizable para las 1.025 especies base,
sin nuevas imágenes ni edición de atlas. `battle_timeline_plan.gd` proyecta los
resultados del dominio y `battle_art.gd` dibuja una Ball geométrica provisional
y transforma temporalmente las imágenes existentes. El tamaño base no cambia.

- Captura aceptada: lanzamiento, absorción, asentamiento, tantas sacudidas como
  `CaptureResult.shake_count` y éxito o salida según `status`. No se consulta la
  probabilidad ni se sortea otra vez. IDs ajenos, resultados inválidos o números
  de sacudidas fuera del contrato no generan una secuencia inventada.
- Si falla, el Pokémon recupera su imagen antes del mensaje de liberación y la
  respuesta real del oponente. Si se captura, permanece oculto y queda la Ball;
  el mensaje final y el botón de retorno esperan a que termine la secuencia.
- Cambio voluntario: retirada por reducción/desvanecimiento y aparición del
  sustituto. Tras un KO se desvanece el debilitado y entra el sustituto que haya
  elegido el dominio, sin una segunda retirada del Pokémon ya oculto.
- La huida exitosa reproduce la salida del jugador; una huida fallida no lo
  oculta. Visibilidad e identidad se restauran al abrir el siguiente combate.
- Ocultar durante una captura ya resuelta termina su representación de acuerdo
  con el resultado real, sin duplicar criaturas, gastar otra Ball ni consumir RNG.

Las identidades visibles se copian antes del comando y las banderas de ocultación
se conservan entre mensajes. El dominio, routing a party/PC, settlement y diagnósticos
siguen resolviendo inmediatamente una sola vez. Las APIs de comando de la demo
rechazan entradas mientras se reproduce; por eso los tests de captura del mapa y
catálogo ahora esperan el final visual antes de solicitar el retorno. No se cambian
los tests de los controladores canónicos ni sus reglas. Los controles deshabilitados
de PP/mochila siguen reflejando el resultado real; no hay animación de sus cantidades.

Duraciones: retirada 0,32 s, aparición 0,35 s, KO 0,5 s; captura 0,4 s de lanzamiento,
0,3 s de absorción, 0,2 s de asentamiento, 0,3 s por sacudida y 0,4/0,3 s de
éxito/salida. Son parámetros provisionales de presentación, no reglas de captura.
La Ball usa color básico para Poké/Super/Ultra/Master Ball; no es arte final.

Gate actual: **19.790 PASS / 0 FAIL**, 64 capturas OpenGL. Los planes comprueban
captura/cambios/KO en las 1.025 especies; las pruebas reales cubren éxito, fallo,
equipo lleno con routing al PC, cambio forzado tras KO del jugador, cancelación,
huida, progresión y las invariantes de identidad, inventario y RNG. Las capturas
muestrean el render real, no son una revisión artística manual de las 1.025.

Regresiones: catálogo headless 26.042 PASS, mapa visual 45, runtime mapa 103,
captura canónica 68, huida canónica 94, cambios canónicos 49, Trainer Battle Session
66, clips headless 935, filtro headless 144 y encuadre 53.309 PASS. Todos 0 FAIL.
El aumento de los gates de mapa/catálogo corresponde a comprobar la espera visual,
no a una ampliación de las reglas. Sin commit/push ni nueva certificación remota.
Los VFX por familias se añaden en el tramo superior; siguen audio, formas y pulido final.

### Historial: cronología compartida de PS/mensajes y reacciones (2026-10-19)

`battle_timeline_plan.gd` proyecta los eventos ya resueltos a una cola visual para
las 1.025 especies base. Usa las poses nativas de los 14 candidatos cuando existen;
para el resto conserva reposo y añade una reacción procedimental común en Godot.
El impacto incluye un destello y marcas simples; la curación tiene un indicador
verde. Las poses nativas no reciben un desplazamiento de ataque adicional.
No se regeneran atlas ni cambia la política de tamaños. La galería conserva su
función de revisar las imágenes/poses originales sin estas reacciones de combate.

El motor sigue resolviendo el comando una sola vez y los diagnósticos completos
siguen emitiéndose inmediatamente. Solo la presentación vuelve al HUD previo y
muestra después los mensajes, cambios e impactos en el orden de los eventos.
Los PS visibles interpolan desde el valor anterior usando únicamente el importe
del evento. No se vuelve a calcular daño, precisión, curación, IA ni RNG. Las barras
y etiquetas coinciden al avanzar; una actualización externa no revela valores
futuros ni desbloquea la entrada antes de acabar. PP y mochila siguen reflejando
el resultado real sin interpolación propia. `pp_changed` y `turn_ended` permanecen
en los diagnósticos, pero no se muestran como ruido técnico en la cola de mensajes.

Los fallos no generan impacto; daño cero tampoco. Se cubren daño residual,
retroceso, varios golpes, curación, destinatarios fuera de pantalla y cambios
entre dos instancias de la misma especie. Al acabar se reconcilia con los valores
finales reales. Si settlement libera BattleState y sube de nivel a la criatura,
el HUD lee los PS/nivel finales de la colección del jugador, sin repetir progresión.
Ocultar cancela y muestra el resultado completo sin perder los mensajes pendientes.

Duraciones comunes: acción 0,42 s, impacto/curación 0,6 s, cambio 0,25 s, mensaje
0,28–0,3 s. Las poses nativas mantienen su duración original. No se han añadido
animaciones de captura, retirada/debilitamiento ni efectos particulares de cada
movimiento. Formas alternativas/shiny y revisión artística completa siguen aparte.

Gate de aquel tramo: **13.551 PASS / 0 FAIL**, 23 capturas OpenGL en
`.godot/animation_checks/`. Incluye planes de todas las especies, avance automático,
HUD intermedio/final, mensajes sin anticipación, bloqueo, cancelación, turno salvaje,
entrenador autónomo, captura fallida/exacta, cambio, KO y subida de nivel reales.
La prueba usa un frame GPU explícito para las capturas en vez de depender de una
espera indefinida de `frame_post_draw`; no cambia el bucle de render del juego.
Se revisan muestras gráficas, no los 1.025 Pokémon manualmente ni todos los VFX.

Regresiones del tramo: catálogo 26.037, mapa visual 43, runtime mapa 101,
presentación base 43, cambios 49, captura 68, huida 94 y Trainer Battle Session 66
PASS; clips headless 935 y filtro headless 144 PASS. Todos con 0 FAIL. Las cifras
sin capturas no se confunden con las ejecuciones gráficas históricas.
Cambios locales sin commit/push; DATA V3, IA, reglas, workflows y F: intactos.

### Historial: primera conexión de poses (2026-10-19)

`battle_animation_playback.gd` observa los eventos diagnósticos existentes antes
y después de cada comando. Copia identidades/vistas, nunca conserva BattleState
entre fotogramas ni ejecuta reglas o consume RNG. `action_used` reproduce ataque;
daño positivo (`damage_applied`, `status_damage`, `recoil_damage`) reproduce daño
en su destinatario real. Fallos, acciones impedidas, curaciones y daño cero no
inventan un impacto. Los clips disponibles conservan duración y fotogramas nativos.

La cola respeta el orden real, las sustituciones y los IDs de instancia, incluso
al cambiar entre dos criaturas de la misma especie. Durante la secuencia se
bloquean los botones y las APIs de comandos de estas dos presentaciones visuales;
al terminar vuelve reposo y se restauran controles según el estado real. Ocultar
la presentación cancela sin temporizadores pendientes. El cierre del dominio
puede liberar BattleState antes de acabar la animación de un KO: se retienen solo
las identidades copiadas para no perder las imágenes ni repetir el settlement.

En aquel primer tramo los PS, PP, texto y settlement se actualizaban síncronamente.
Todavía no había una cronología completa sincronizada de barras/texto, efectos por
movimiento, animación de retirada/debilitamiento ni VFX de captura. Este tramo
solo conecta las poses corporales existentes; no modifica reglas, IA o learnsets.

Gate nuevo: 193 PASS / 0 FAIL con 15 capturas OpenGL en
`.godot/animation_checks/`. Incluye planes de las 14 especies, turno salvaje y
entrenador autónomo reales, captura fallida/exacta, cambio, KO, bloqueo de comandos,
cancelación/reapertura, retorno y reposo para especies sin esas poses. También
comprueba avance natural por fotogramas y que reproducir no vuelve a mutar el
estado ni consume RNG. Movimientos/PS especiales se preparan solo en fixtures
en memoria del test, no alterando archivos de datos ni la configuración normal.

Regresiones del tramo: catálogo completo 26.037 PASS; mapa visual 43 PASS;
runtime de mapa 101 PASS; presentación base 43 PASS; cambios 49 PASS; captura
68 PASS; huida 94 PASS; Trainer Battle Session 66 PASS. Revisión de clips en
headless 935 PASS (84 clips / 252 muestras, sin las 70 capturas del gate histórico)
y filtro headless 144 PASS (sin las 12 capturas del gate gráfico). Todos con
0 FAIL. No hay commit/push ni certificación nueva de CI de estos cambios locales.

## Adaptador y memoria

`battle_sprite_catalog.gd` resuelve IDs exactos del catálogo normalizado. No usa
RNG del juego. Respeta los tiempos de cada fotograma, bucles y estados no cíclicos.
Una vista ausente muestra un aviso: no usa otro Pokémon ni un frontal como espalda.
La caché compartida mantiene hasta ocho atlas / 128 MiB de píxeles RGBA estimados;
este límite no representa toda la memoria del proceso ni el overhead del driver.

GIF se convierte sin cambiar píxeles RGBA ni eliminar fotogramas, en atlas PNG
de resolución nativa. Las 14 parejas candidatas conservan sus atlas ya calibrados.
El pack conserva la calibración antigua por altura, pero la presentación actual
la compensa con `scale_reference.json` para mantener las proporciones de la familia
de origen. No se ajusta cada fotograma al hueco ni se alteran atlas/pivotes/cadencias.
Anclas/levitación y acabado no equivalen a aprobación artística exhaustiva.

### Suavizado compartido de combate (2026-10-19)

`battle_art.gd` usa filtrado lineal al dibujar las imágenes, también en la galería,
para reducir bordes escalonados con escalas fraccionarias. No modifica los atlas,
la tabla de tamaños, fotogramas, tiempos ni el filtrado del mapa/interfaz. Suaviza
los píxeles existentes; no reconstruye líneas o detalle ausentes en el original.
La prueba `battle_sprite_filter_test_runner.gd -- --capture` compara el filtro
anterior y el actual en seis especies, frente/espalda y dos tamaños de arena:
156 PASS / 0 FAIL y 12 capturas en `.godot/filter_checks/`. Revisión visual de
muestras, no aprobación de todo el arte. Regresión: catálogo completo headless
26.037 PASS / 0 FAIL; mapa y encuentros 43 PASS / 0 FAIL.

### Estado actual: referencia compatible de Showdown (2026-10-19)

Se descarga la tabla pública `https://play.pokemonshowdown.com/data/pokedex-mini.js`
y se conserva junto con los fuentes del adaptador/cámara y CSS en
`D:\Proyectos\Pokemon Calvo Auditoria Visual\referencias_escalas_v2`. El informe
`reference_report.json` fija URL y SHA de cada archivo. No se ejecuta JavaScript
descargado: se analiza únicamente el objeto de datos mediante JSON estricto.

Cobertura: **1.011 especies / 2.022 vistas externas**. Coinciden identidad e
ID de especie; 2.003 vistas también coinciden en dimensiones. Las otras 19 vistas
de diez especies se adaptan conservando proporción a la silueta mediana de sus
GIF de referencia actuales. Se descargan solo esos 19 GIF como referencia, fuera
del juego. No se sustituyen las imágenes del pack. Las diferencias de pose/acabado
de esas versiones siguen señaladas para revisión artística.

En las vistas coincidentes, el factor compensa exactamente la normalización por
altura anterior: un píxel de la imagen vuelve a representar una unidad del pack.
La referencia de encuadre es 640×360, con perspectiva 1,0 frontal / 1,5 trasera,
adaptada al tamaño de nuestra arena. Se mantienen límites de seguridad de huella
y márgenes, no se reproduce toda la cámara de Showdown ni la de un juego oficial.

Los **14 renders propios no tienen entrada animada de esa familia**. Se conserva
su calibración relativa de frente/espalda/estados, con una conversión común de
unidad de 0,5972377242585095 (mediana del pack coincidente). No se presentan como
referencias externas verificadas; la galería lo indica explícitamente.

Wailord en arena 674×359: frontal de 145,59 px y espalda de 255,79 px de ancho de
envolvente, frente a los 202,20 / 262,08 del ajuste previo V1. La imagen frontal
es de 146×81 y deja de ampliarse por su altura de Pokédex. Son unidades canvas;
en ventana 1280/960 equivale aproximadamente a 194 px de ancho frontal. No se
añade detalle a la imagen ni se afirma que pase a ser HD.

Últimos gates: referencia **8.225 PASS / 0 FAIL**, encuadre **53.309 PASS / 0 FAIL**
(cinco arenas), integración OpenGL con capturas **26.055 PASS / 0 FAIL** y regresión
visual **43 PASS / 0 FAIL**. Las 1.025 especies continúan cargando; ninguna regla,
dato de combate, IA o workflow ha cambiado.

### Historial: ajuste V1 anterior a importar referencias

`presentation_metrics.json` mide la unión opaca de los 119.917 fotogramas de todos
los estados por especie/vista, en unidades calibradas relativas al pivote. No
cambia PNG, resolución, tiempos ni pivotes. Su SHA del manifiesto evita aplicar
mediciones obsoletas después de cambiar el pack.

`battle_sprite_layout.gd` añade una perspectiva frontal de 0,78 frente a 1,0 del
lado del jugador. Limita la silueta a 30 % de ancho/40 % de alto de la arena para
el rival y 40 %/56 % para el jugador, además de márgenes para poses asimétricas.
Se usa una envolvente común para todos los estados de una vista: la escala no
varía al cambiar fotograma, atacar o recibir daño. Las proporciones no se estiran.

En arena de referencia 674×359, la envolvente de Wailord rival baja de 276,91 a
202,20 px de ancho (−26,98 %); la espalda permanece en 262,08 px. Son unidades del
canvas, no necesariamente píxeles físicos de la ventana. En esa arena, 21 vistas
frontales y 25 traseras necesitan un límite adicional al de perspectiva.

Referencia consultada: el [renderizador de Showdown](https://github.com/smogon/pokemon-showdown-client/blob/master/play.pokemonshowdown.com/src/battle-dex.ts)
usa las dimensiones de su animación para sprites modernos; no deriva el tamaño
en píxeles de la altura de Pokédex. Los `pokemon_metrics.txt` locales de Essentials
contienen posiciones/sombras de sus propios sprites y no se importan como tabla
de escala compatible con estos renders. Nuestra adaptación no se presenta como
una reproducción certificada de cámaras/tamaños de los juegos originales.

Los archivos generados viven en `assets/local_battle_catalog/`. `.gdignore` evita
la importación masiva del editor; se leen PNG directamente bajo demanda. Las rutas
de ejecución son relativas al juego: una vez construido, no requiere leer F:.
Originales F: y candidatos de auditoría D: permanecen intactos.

El pack queda fuera de Git para evitar publicar arte de terceros sin revisar sus
condiciones y créditos. El código/README no son el pack. No se ha hecho commit,
push, merge ni cambio de workflows. Exportar una build autónoma necesita una fase
explícita de empaquetado: no se afirma que `.gdignore` se incluya en un export.

## Reconstrucción local

Python 3.12 y Pillow. Desde la carpeta del proyecto, en PowerShell:

```powershell
python tools/visual/build_battle_sprite_pack.py `
  --source-manifest 'D:\Proyectos\Pokemon Calvo Auditoria Visual\internet\rendered_asset_manifest_candidate.json' `
  --candidate-registry 'D:\Proyectos\Pokemon Calvo Auditoria Visual\cierre_visual_v2\candidate_registry.json' `
  --pokemon-height-directory 'F:\pokemon roma el calvo\POKEMON_DATA_LIBRARY\01_POKEAPI_DATA\data\api\v2\pokemon' `
  --report 'D:\Proyectos\Pokemon Calvo Auditoria Visual\integracion_catalogo_v1\build_report.json'
```

El constructor comprueba SHA-256 de entradas, cobertura exacta y límites del atlas.
Solo publica el manifiesto al completar todo el catálogo. El informe conserva la
procedencia y hashes; las fuentes originales nunca se mueven ni modifican.

Si ya existe el pack y solo faltan sus mediciones de presentación:

```powershell
python tools/visual/build_battle_sprite_metrics.py --report 'D:\Proyectos\Pokemon Calvo Auditoria Visual\ajuste_escalas_v1\metrics_build.json'
python tools/visual/build_showdown_scale_reference.py --reference-directory 'D:\Proyectos\Pokemon Calvo Auditoria Visual\referencias_escalas_v2' --apply
```

## Validación local, no certificación de todas las mecánicas

```powershell
godot --headless --path . --script res://tests/visual/catalog_integration_test_runner.gd
godot --headless --path . --script res://tests/visual/battle_sprite_layout_test_runner.gd
godot --headless --path . --script res://tests/visual/scale_reference_test_runner.gd
godot --path . --script res://tests/visual/battle_sprite_filter_test_runner.gd -- --capture
godot --path . --script res://tests/visual/battle_animation_playback_test_runner.gd -- --capture
godot --path . --script res://tests/visual/battle_move_visuals_test_runner.gd -- --capture
godot --path . --script res://tests/visual/custom_sprite_review_test_runner.gd -- --capture
godot --path . --script res://tests/visual/catalog_integration_test_runner.gd -- --capture
godot --headless --path . --script res://tests/gameplay/visual_field_test_runner.gd
godot --headless --path . --script res://tests/gameplay/overworld_test_runner.gd
```

El gate nuevo exige el pack local completo; no es una dependencia nueva de los
tests existentes ni se añade automáticamente a CI. Comprueba SHA/carga/regiones/
cadencia de todos los atlas, límite de caché y construcción real de las 1.025
especies a nivel 50 con referencias válidas de sus movimientos. Prueba galería y
bloqueos, cinco encuentros/capturas reales (Castform, Ferropolilla, Terapagos,
Pecharunt, Wailord), la presentación del entrenador y una resolución con su IA existente.
No simula todas las combinaciones, niveles, movimientos ni reglas de randomlocke.

Resultados/capturas reproducibles en `.godot/catalog_checks/`; los tests anteriores
del mapa siguen siendo necesarios. Su runner de overworld tiene avisos históricos
de recursos/RID al salir, separados del resultado de sus comprobaciones.

Pasada histórica V1 del 2026-10-19, antes de importar la tabla: integración con render OpenGL y capturas,
21.933 PASS / 0 FAIL; gate de encuadre, 53.308 PASS / 0 FAIL en cinco tamaños
de arena; regresión visual existente, 43 PASS / 0 FAIL. Las comprobaciones de
encuadre no sustituyen una revisión humana exhaustiva de todas las especies.
