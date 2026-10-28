# ESTADO ACTUAL DEL PROYECTO

## Vigente: primera base de objetos — 2026-10-28

2.222 IDs inventariados y clasificados, con cruce nativo de 565 entradas y sus
límites. 21 equipados pasan el piloto real (42 casos / 461 checks Godot), con
consumo/restauración y publicación única de la propiedad. La única corrección
del runtime existente es reconocer `-clearnegativeboost` de Hierba Blanca.

43 exclusiones preparadas en política separada: todos los revivificadores,
Lupa/Polvo Brillo según decisión nominal del usuario y cartas. No se eliminan
definiciones o partidas ni se crean pools automáticos. El censo distingue las
15 medicinas/cuatro bolas básicas existentes de otros usos pendientes.
Referencias vigentes: `ITEM_FOUNDATION.md`, `ITEM_FOUNDATION_V1.json`,
`ITEM_INVENTORY.json/CSV`. Hay 24 IDs para comparar arte; aún no se importó.

Pendiente: equipar/quitar en UI y mochila, más contextos de equipados, uso fuera
de combate, relación de máquinas/versiones, bolas especiales y campo/historia.
No presentar presencia en Showdown o datos como implementación completa.

## Antecedente: perfil conjunto y barrido de 900 ataques — 2026-10-28

La demo habitual usa `gen9calvounifiedv1`: Gen9 con compatibilidad acotada para
la activación de Dinamax, conservando el motor nativo. F12 usa la variante de
dobles. Los guardados anteriores conservan su perfil; no hay migración implícita.
Reglas detalladas en `BATTLE_PROFILE.md`, evidencia `UNIFIED_MOVE_SWEEP.json/CSV`.

Cobertura positiva: 820 ordinarios + 50 Z de daño + 19 Maxi + 11 de dobles = 900;
19 exclusiones conservadas, 919 IDs totales. Barrido de 3.358 escenarios generales,
72 preparados, 200 Z y 44 de dobles. Proyección Godot y regresiones PASS. El mapa
permite usar Maxi con movimientos modernos, guardar/cargar durante Dinamax y
capturar sin persistir HP duplicados ni perder su coste de PP.

Este bloque cierra la conexión funcional de ataques y el barrido acordado, no
todas las combinaciones posibles ni todos los sistemas del juego. Mega/Ultra/
teracristalización, resto de objetos, IA profesional, randomización, reglas
custom de vidas/muerte, multijugador y mapas finales siguen aparte. No se han
añadido nuevos descartes, datos brutos ni recursos gráficos en este cierre.

## Antecedente: dobles nativos disponibles en F12 — 2026-10-27

Los 11 movimientos de contexto doble están conectados a Godot y al motor
`gen9doublescustomgame` fijado a `@pkmn/sim@0.10.11`. La pantalla F12 del mismo
mapa controla cuatro acciones con objetivos reales, reservas, KO, intercambio
de posiciones y checkpoint separado. Usa clones, sin modificar la colección,
bolsa o mapa de la campaña ni habilitar recompensas o encuentros dobles.

PASS: 44 casos nativos, 454 checks Godot, 130 UI headless, 196 GPU y 66 muestras
visuales revisadas. Las regresiones de campaña/combate/guardado pasan. Se
conservan los recursos gráficos y datasets originales. Informe actual:
`NATIVE_DOUBLES_INTEGRATION.json`; gate `run_doubles_integration.py`.

Catálogo: 889 acciones de individuales ensayadas + 11 de dobles conectadas + 19
excluidas = 919. No equivale a certificar todas las interacciones posibles.
Quedan el perfil conjunto Gen8/Gen9/mecánicas especiales y su barrido final.
Objetos restantes, IA profesional, reglas custom y multijugador siguen después.

## Antecedente: mapa habitual conectado y partida recuperable — 2026-10-27

La escena principal es `scenes/visual/field_demo.tscn`. Sus combates salvajes y de
entrenador usan ahora el backend nativo ya probado, con la misma colección real.
No se crea otro mapa ni se sustituyen imágenes. El camino histórico se conserva
para diagnóstico y pruebas `--legacy-field`, sin fallback automático.

Guardar/cargar (Ctrl+S/Ctrl+L) incluye SaveV2 de colección, mapa/RNG, entrenador
persistente y combate activo con su bolsa provisional. Validación previa a
publicación y escritura atómica reutilizadas del sistema existente. Captura y XP
no se duplican al cargar, trainer KO no se cura automáticamente, sueño usa solo
su reloj nativo observado, y el trabajador puede recuperarse desde el último
checkpoint confirmado. Se conserva la identidad de objetos al liquidar combate.

118 checks headless / 123 GPU / cinco capturas revisadas / ocho checks nativos
de reloj de sueño. SaveV2 40+8, núcleo 472, visual/mapa histórico 45+103,
conexión 99, aventura 86, medicinas 120 y Node 21/10/7 PASS. Gate/reporte actuales:
`run_field_integration.py`, `FIELD_NATIVE_INTEGRATION.json`.

889 acciones de individuales previamente ensayadas, 11 de contexto doble y
19 excluidas; estas pruebas de mapa no certifican todas sus combinaciones.
Pendientes: perfil final conjunto Gen8/Gen9/mecánicas especiales, conexión nativa
de dobles y barrido final. IA profesional, randomización por niveles, reglas
custom de muerte/vidas y multijugador siguen para después. Las tres firmas de
formas ausentes están excluidas, sin importar/redibujar esas formas.

Los apartados posteriores describen antecedentes de las fases anteriores.

## Conexión de movimientos corregida — 2026-10-27

Los 12 bloqueos del primer barrido ya están corregidos: protocolos compartidos,
PS simultáneos/alias, copias temporales y sustitutos. Snapshot/persistencia conserva
PP originales pagados y limpia forma/copia/PS temporales; PS de sustitutos se
observan del motor, incluidos varios sucesos por turno, sin duplicar fórmulas.

Resultados combinados `MOVE_CONNECTION_REPAIR.json/CSV`: **820** movimientos con
integración ensayada en individuales; **19 Maxi** con perfil Gen8 explícito; **11**
positivos nativos en dobles (sin UI Godot de dobles); **1** requiere Hoopa Desatado
ausente en datos/arte; **53 Z pendientes**, **15 descartados**. Suma 919. Esto no
certifica todas las interacciones posibles ni convierte dobles/formas en descartes.

Maxi confirmado por el usuario al aportar conversación con su amigo. Z pendientes
como pidió si el texto no aclara los 53; no se cambia política ni se habilitan.
`JUGAR_COMBATE_MAXI.cmd`: misma escena del proyecto, Gen8/Dinamax, selección y clips
existentes. Gen9 separado; mapa habitual conserva backend anterior, sin migración.

Gate: 3.362 casos generales/13.448 decisiones, 74 contextos/72 positivos Godot,
11 contextos dobles nativos, 99 dedicados, 51 GPU/8 capturas. Regresiones 100
backend, 86 aventura, 120 medicinas, 23 GPU mochila y 20.809 playback PASS.
Fórmulas históricas, datos, arte y política intactos; presentación compartida
amplía metadatos de PS y tamaño Dinamax. Perfil mixto Gen9/Dinamax, dobles,
Hoopa Desatado, otros límites y mapa/guardado siguen pendientes. No GitHub.

## Antecedente: auditoría completa de movimientos — 2026-10-27

**No están todos funcionales en el juego.** Nuevo barrido reproducible de solo
lectura: 919 IDs inventariados, 3.343 casos, 13.372 decisiones/snapshots y 3.338
continuaciones. 15 resultados esperados independientes PASS, cero errores
nativos. Mismo adaptador/mirror de Godot, ensayado offline en lotes de 32.

772 movimientos pasan los contextos de integración; 48 precisan escenarios
específicos; 12 presentan bloqueos. Maxi 19: native Gen8 sí/perfil Godot pendiente;
Z 53 pendientes y 15 excluidos. No presentar ejecución sin error como prueba de
todas las interacciones. Informe `MOVE_FUNCTIONAL_AUDIT.json`, lista completa
CSV y guía `tools/showdown_engine_probe/MOVE_AUDIT.md`.

Bloqueos: cuatro OHKO, court_change, dragon_darts, pain_split, vice_grip, mimic,
transform, substitute y shed_tail. Agrupar correcciones por protocolo/alias/
estado temporal. Objetos en pausa por petición del usuario hasta esclarecer
movimientos. Ninguna corrección/admisión automática ni cambio de datos/arte/
política/servidor de producción. Admisión histórica 620/230 pendiente sin cambios.

## Antecedente: mochila básica Showdown — 2026-10-27

Conectadas **15 medicinas** en la sesión optativa: Pociones (20/60/120/total),
Restaurar Todo, Antídoto/Antiquemar/Antihielo/Despertar/Antiparalizador/Cura Total,
Éter/Éter Máximo/Elixir/Elixir Máximo. Menú Mochila con objetivo activo/reserva y
selección de movimiento. Se reutilizan los valores del registro existente y el
estado nativo de Showdown; no se descarga otro juego ni se toca el dataset.

Sin efecto, KO, objeto no poseído o slot inválido: no gasta nada. Curación y
respuesta rival se preparan/confirman juntas. Guardado schema 2 con perfil y
diario de consumos. Canonización de marcadores horarios del protocolo para que
repetir tras guardar no dependa de la hora real. No se cambia el RNG nativo.

Evidencia actual `SHOWDOWN_MEDICINE_INTEGRATION.json`: 120 Godot, 21 Node,
23 GPU/5 capturas y regresiones 86 aventura/100 backend PASS. Los informes
anteriores corresponden a sus versiones. Código histórico/datos/arte/IA intactos.
El launcher de aventura conserva equipo/bolsa en memoria; mapa/SaveV2 pendientes.

Orden confirmado: primero sistemas básicos completos, **IA básica por ahora**.
Luego novedades propias. Cuatro vidas y desaparición de Pokémon muertos quedan
anotadas para esa fase, sin aplicarlas ahora. Revivir y otros objetos, uso fuera
de combate, fronteras del motor e integración de campaña siguen pendientes.

## Antecedente: sesiones con colección e inventario — 2026-10-27

Nuevo `ShowdownAdventureSession` optativo, mismo proyecto. Reutiliza nuestros
servicios de captura, consumo de bolas, PC, huida y experiencia sobre resultados
nativos. Conserva identidades y referencias del equipo, KO permanentes, PS/PP y
estados; restaura habilidad original al salir para no persistir cambios temporales.
Publicación al final, sin escrituras parciales al fallar la respuesta del rival.

`JUGAR_AVENTURA_SHOWDOWN.cmd`: encuentros sucesivos con una colección de prueba
compartida en memoria, captura/huida con animaciones existentes, y experiencia
tras la victoria. API de sesión de entrenadores también probada; todavía sin
la IA profesional. No se activa en el mapa habitual ni modifica SaveV2.

Evidencia vigente: `SHOWDOWN_ADVENTURE_INTEGRATION.json`. **86 checks de sesión,
28 GPU/5 capturas, 7 Node**, regresión **100 checks Showdown/13 capturas,
472 core, 20.809 playback, 628 corpus IA**, todos PASS. Fallos de reacción,
captura sin bola, equipo lleno, cambios de campaña durante IPC, recuperación
del trabajador, restauración de inventario/RNG y sustitución obligatoria cubiertos.

Pendientes: medicinas, IA profesional, propietario de mapa/guardado y reglas de
campaña completas; siguen los límites de formas/sustitutos, sueño heredado,
perfil Dinamax/Gen9 y distribución. Informe previo de backend es histórico:
los hashes actuales se comprueban con `verify_adventure.py`. Datos/arte/F: y
backend/arranque habituales permanecen intactos. Sin subida a GitHub.

## Antecedente: combate completo visible y guardable optativo — 2026-10-27

Escena `showdown_battle_lab.tscn` y launcher `JUGAR_COMBATE_SHOWDOWN.cmd`.
Se mantienen el mapa/partida habitual y su backend. El nuevo combate utiliza
Showdown nativo, nuestros catálogos, instancias reales, arte y reproducción
existentes. Cierra ataques/protecciones/pantallas/curación, cambios voluntarios,
Ida y Vuelta con continuación, sustituciones por KO, victoria y guardado/carga
de la prueba. No se concede experiencia ni se escribe en la campaña.

Backend optativo `showdown_singles_v1`, @pkmn/sim 0.10.11, Gen9. Preparación
nativa separada y confirmación después de validar la proyección impiden turnos
parciales por efectos desconocidos. Token/revisión rechazan repeticiones y
órdenes antiguas. Los errores conservan el último snapshot confirmado; un
proceso nuevo puede reanudarlo. El guardado identifica versión, perfil y hashes
de datos/política. No hay migración implícita de Battle Core/LCG ni relojes viejos.

**100 checks GPU / 13 capturas revisadas**, 10 checks Node de transacciones;
regresiones 472 core / 20.809 playback / 628 corpus IA PASS. Prueba compartida
anterior: 39 Node / 27 Godot / 2.496 ejecuciones y snapshots nativos PASS. Se
verifican identidad/PS/PP, mismo replay/RNG, cambios a mitad de turno, rechazo
atómico, pérdida del proceso, exclusiones, regionales/shiny y reproducción sin
mutación. `SHOWDOWN_BACKEND_INTEGRATION.json` guarda evidencia/hashes.

Se conservaron los hashes de los 233 archivos de producción previos; cinco
nuevas fuentes optativas no alteran el arranque normal. Datos brutos/normalizados,
configuración de contenido, imágenes/manifiestos, renderer y F: intactos.
Admisión habitual: **620 / 299 no disponibles / 230 pendientes de mecánica**.
No se dan por resueltos los nueve fallos DATA V3 anteriores ni se ha publicado.

Siguiente frontera: captura/mochila/huida y persistencia de resultados de las
sesiones reales; luego conectar la IA profesional mediante mundos plausibles
sanitizados. El rival del laboratorio es un selector legal simple, no esa IA.
Formas/movimientos temporales, sustitutos y otros protocolos se rechazan cuando
no pueden representarse. Perfil conjunto de Dinamax y exportado portátil siguen
pendientes. Guía en `modules/battle/backends/showdown/README.md`.

## Reutilización de Showdown: viabilidad positiva, backend live conservado — 2026-10-26

Autorizado estudiar sistemas existentes y probar su conexión; no solo consultar
tablas de ataques. El laboratorio `tools/showdown_engine_probe/` ejecuta el
simulador nativo @pkmn/sim 0.10.11 desde Godot 4.7 por pipes locales, con
39 comprobaciones Node y 27 Godot PASS. Importa criaturas reales y sus PS/PP/
estadísticas, conserva identidad, restaura JSON/RNG, valida decisiones de forma
atómica y prueba lotes de forks sin alterar el combate fuente. La proyección
limitada de un turno alimenta la línea de animación existente hasta los PS
finales. No es todavía el backend del juego ni un adaptador de todos los eventos.

Barrido de robustez: **2.496 primeras ejecuciones y snapshots nativos**, 832
movimientos/tres semillas, sin errores del simulador/serialización. 246 contienen
fallos legítimos del movimiento por condiciones de la fixture; no son 832
efectos certificados. Se observan 42 clases de mensajes, no el protocolo entero.
Los 19 Maxi funcionan por Dinamax nativo Gen8; Gen9 nativo lo rechaza.

Datos: correspondencia de los 919 IDs de movimiento y los 1.025 Pokémon base +
57 regionales. Tras alias explícitos de nombres/formas, las seis estadísticas
base y los tipos coinciden en los 1.082. Hay 60 diferencias de campos de
movimientos a resolver según perfil, la mayoría Z y seis filas no Z. 313 de 373
habilidades tienen entrada directa: PokeAPI identifica 59 de las otras 60 como
ajenas a la serie principal; Evocarrecuerdos necesita su variante por forma.
530 objetos tienen entrada; el uso de mochila/captura y la mayoría de los
objetos de aventura no pertenecen al simulador. No se han regenerado datos.

Recomendación: avanzar por una fachada de backend experimental/eventos/guardado
antes de implementar más familias propias. Captura, mochila, progresión,
randomlock, mundo, arte e IA profesional conservan sus sistemas; requieren
conexión donde corresponda. PSVM se mantiene como alternativa de empaquetado
nativo en construcción, sin dar por probado un módulo Godot listo.

Evidencia `SHOWDOWN_BACKEND_FEASIBILITY.json` y README del laboratorio. Las
guardas confirman **233 archivos protegidos intactos** durante la prueba. El
perfil live continúa en 620/299 y 230 pendientes de mecánica, con su cierre de
curación debajo. No hubo publicación, nuevas imágenes ni sustitución del motor.

## Último lote live: ocho movimientos de curación — 2026-10-26

Integrados Aromaterapia, Cascabel Cura, Alivio, Gota Vital, Cura Selvática,
Plegaria Lunar, Purificación y Descanso. Perfil: **620 admitidos / 299 no
disponibles / 230 pendientes de mecánica** (162 DATA_ONLY, 57 parciales, 11 sin
soporte). Clasificaciones canónicas, exclusiones/Z/dobles y arte sin cambios.

`healing_move_rules.gd` distingue cura de equipo y de activos; las reservas
debilitadas no se curan/reviven y sus habilidades inactivas no bloquean las curas
modernas de equipo. Gota Vital redondea los medios hacia arriba; Cura Selvática
y Plegaria Lunar usan el redondeo del modificador nativo, hacia abajo en empate.
Purificación cura antes al objetivo y solo entonces recupera PS para su origen;
se prueban sustituto/Allanamiento, Espejo Mágico y Cuerpo Áureo. Alivio conserva
su lista limitada de estados. Descanso pone sueño fijo sin consumir RNG de
duración y mantiene el reloj al cambiar o guardar; Madrugar pierde una acción,
frente a las dos ordinarias. El nuevo marcador de estado se omite cuando está
apagado y se limpia junto a los demás contadores al curar.

Evidencia `HEALING_MOVES.json`: **2.546 PASS / 192 casos / 16 capturas GPU**
revisadas, reproducción sin mutación, mensajes de curación en español y HUD exacto. General: **9.890 PASS**,
620 movimientos y 1.822 clips. Motor/playback/IA: 472/20.809/628 PASS; DATA V3
conserva 624 PASS y los mismos nueve fallos. No se amplía la estrategia de IA;
el proxy y los relojes generales de sueño rival mantienen sus límites previos.

Referencia externa: **7.284/7.284 MATCH** (1.374 nuevos de curación), 42 controles
unitarios y tres negativos reales. Se observan PS/estado iniciales, PP y
reservas; el ciclo completo de Descanso se prueba aparte en el servidor.
Los fallos iniciales de habilidades de reserva y redondeo se corrigieron antes
de habilitar el cierre. Datos brutos/normalizados, manifiestos, renderer, F: y
GitHub intactos. Próximos pasos en `NEXT_STEPS.md`.

## Referencias de fans descargadas — 2026-10-26

Fuentes aisladas en `D:\Proyectos\Pokemon Calvo Referencias`: Godot Essentials,
pokerecomp y Essentials Ruby, fijadas a commits y con licencias/créditos
registrados. `EXTERNAL_SOURCE_AUDIT.json` resume el cruce con 238 pendientes:
208 entradas coincidentes, sin afirmar compatibilidad o funcionamiento.
Se detectaron rutas internas rotas y diferencias de reglas en el port Godot;
no se ha incorporado ni ejecutado código externo. Los 232 archivos protegidos
del juego conservan sus hashes. No cambia el cierre de atrapamiento ni el perfil
612/307; las fuentes servirán para adaptar familias y contrastarlas con Showdown.

## Decisión de publicación — 2026-10-26

El usuario confirma posponer la limpieza/subida completa a GitHub hasta cerrar
la parte visual del alcance acordado y revisar recursos, procedencias, condiciones
y créditos. La versión que se guarde debe incluir sus imágenes/animaciones y ser
reproducible sin rutas locales externas. Ese hito puede llegar mientras aún quede
programación. Hasta entonces se trabaja en local; no se autoriza ahora borrar ni
reemplazar el contenido remoto. Los datos grandes existentes deben preservarse.
Lista operativa en `NEXT_STEPS.md`; memoria visual en `VISUAL_CATALOG.md`.

## Bloque anterior: diez movimientos de atrapamiento — 2026-10-26

Integrados Atadura, Constricción, Giro Fuego, Torbellino, Tenaza, Bucle Arena,
Lluvia Ígnea, Acoso, Cepo y Electrojaula. `binding_move_rules.gd` comparte contrato,
contacto separado, daño residual y reloj reproducible, con DATA V3 intacto.
Solo aplica tras daño al cuerpo, no al fallar/ser inmune/morir el objetivo ni al
romper un sustituto. Allanamiento lo atraviesa. Repetir golpe no extiende el
efecto. Retirada/KO del origen libera; Relevo transmite; pivotes/expulsiones siguen
sus rutas. Garra Garfio dura siete ticks, Banda Atadura usa un sexto en vez de un
octavo, Muro Mágico evita daño y Fantasma/Muda Concha evitan el bloqueo. Restos
precede al tick. No se amplían pools ni clasificaciones de objetos/habilidades.

Servidor y candidatos de IA comparten la prohibición del cambio manual; UI oculta
reservas prohibidas sin impedir elecciones de pivote. RUN bloqueado consume turno
y respuesta sin RNG de huida ni aumentar intentos. Captura real con Master Ball
permanece válida y limpia ambos estados. La IA recibe hechos anunciados y reloj
estimado; duración/divisor privados no cruzan ni por el roster propio. El proxy
reconstruye la estimación y conserva el vínculo, sin copiar el RNG autoritativo.

**612 admitidos / 307 no disponibles; 238 con mecánica pendiente**
(168 DATA_ONLY, 59 parciales, 11 sin soporte), más 15 excluidos, 53 Z y uno de
dobles. Focal: **1.883 PASS / 240 casos / 20 capturas GPU** revisadas y HUD exacto.
General: **9.858 PASS**, 612 movimientos y 1.822 clips. Core/playback/IA:
472/20.809/628 PASS. DATA V3 mantiene 624 PASS y los mismos nueve fallos previos.

Comparación externa: **5.910/5.910 MATCH**, incluidos 960 de atrapamiento. Estado,
bloqueo y daño residual exactos; duración natural en rango. Sesenta escenarios
comparan ocho turnos nativos con Garra Garfio: siete ticks y liberación sin daño
adicional. El primer observador externo no recogía residuales por AfterDamage;
se corrige para observar `damage` preservando argumentos/receptor/retorno/RNG.
36 controles unitarios y tres con adaptadores reales PASS.

Informes: `BINDING_MOVES.json`, `BATTLE_REFERENCE_VALIDATION.json`, informe live y
CSV vigente. Datos, atlas/manifiestos, fuentes F: e índice/renderer congelados
intactos. Sin nuevas imágenes, exportación ni GitHub. G-Max/Buceo, supresión y
orden global de residuales con estados/habilidades incompletos quedan fuera;
el resto de la huida conserva su sistema anterior. No es certificación de todas
las interacciones competitivas.

## Bloque anterior: once movimientos de potencia variable — 2026-10-26

Se continúa en el mismo proyecto, sin delegar, con un bloque compartido de once:
Bola Voltio, Giro Bola, Azote, Inversión, Agarrón, Estrujón, Prensa Metálica,
Retribución, Frustración, As Oculto y Castigo. Se resuelve la potencia sobre el
estado del momento de ejecución (PS, velocidad, amistad, PP ya consumidos o
mejoras positivas), en una copia del movimiento. Los diez que hacen contacto lo
corrigen en esa copia; Bola Voltio conserva ausencia de contacto. DATA V3 intacto.

**602 admitidos / 317 no disponibles; 248 con mecánica pendiente**:
168 DATA_ONLY, 69 parciales y 11 sin soporte. Se mantienen 15 excluidos, 53
decisiones Z y uno de dobles. Los cuatro dependientes de peso siguen aparte.
No se modifica el randomizador, los niveles/learnsets ni la política de contenido.

`variable_power_move_rules.gd` centraliza fórmulas y contratos. La velocidad del
perfil live de individuales usa razones exactas para etapas, evitando el error
de truncar a puntos básicos (p. ej. 3 a -1 debe ser 2, no 1), con parálisis y
límite 10.000. Orden de turno y potencia comparten este cálculo; el flag apagado
conserva el orden/RNG histórico. No se amplían ahora todas las habilidades u
objetos que modifican velocidad. PS/PP/amistad sobreviven a snapshots y forks.

Gate focal: **1.854 PASS / 264 casos / 22 capturas GPU**, revisadas en láminas.
Prueba que Azote ve el daño recibido antes en el mismo turno, As Oculto usa los
PP posteriores al consumo, el contacto activa el pipeline existente y la
reproducción no cambia estado. Gate general: **9.818 PASS**, 602 movimientos y
1.822 clips. Motor 472, playback 20.809 e IA 628 PASS. DATA V3 mantiene exactamente
624 PASS / los mismos nueve fallos anteriores. Renderer, datos y arte intactos.

Comparación externa: **4.950 MATCH / 0 diferencias / 0 no comparables**, incluidos
**3.018 nuevos de potencia variable**, en lotes de 500. Se observa `BasePower`
durante la ejecución real de Showdown y potencia/contacto en eventos de daño de
Godot. Compara potencia, impacto, contacto y PP; no equipara daño ordinario ni RNG.
30 controles unitarios y tres con adaptadores reales PASS. No se suman estos
casos como si fueran movimientos distintos. Evidencia: `VARIABLE_POWER_MOVES.json`,
`BATTLE_REFERENCE_VALIDATION.json`, informe live y CSV de 317 no disponibles.
Sin nuevas imágenes, descargas grandes, exportación ni GitHub.

## Bloque anterior: daño fijo y proporcional integrado — 2026-10-26

Se habilitan seis movimientos en el perfil live de individuales: Furia Dragón,
Bomba Sónica, Sísmico, Tinieblas, Superdiente y Furia Natural. Calamidad ya estaba
admitido, pero usaba daño ordinario de potencia 1; ahora aplica la mitad de los
PS actuales, mínimo uno. Mismo redondeo para Superdiente/Furia Natural; Sísmico y
Tinieblas usan el nivel, Furia Dragón 40 PS y Bomba Sónica 20 PS.

Nuevo `fixed_damage_move_rules.gd`, con contratos cerrados y definiciones
canónicas intactas. Se conserva precisión/PP, inmunidades y bloqueo/rotura de
sustituto, Allanamiento y el pipeline existente de contacto. Superdiente corrige
contacto en una copia separada. No hay multiplicadores de STAB, resistencias,
etapas, quemadura, críticos o variación aleatoria de daño para estos movimientos.
El comportamiento con el flag live apagado permanece compatible.

**591 admitidos / 328 no disponibles**. Pendientes de mecánica: **259**
(179 DATA_ONLY, 69 parciales, 11 sin soporte); aparte siguen 15 excluidos,
53 decisiones Z y uno de dobles. No cambian reglas randomlock ni learnsets.

Gate focal GPU: **1.364 PASS / 168 casos / 14 capturas**, con regional shiny,
UI real, reproducción sin alterar el estado, snapshots/continuación JSON y fork
aislado para IA. Revisadas las siete parejas de capturas. La primera fixture
visual usaba Splash excluido, que se convertía en Esfuerzo y mataba al rival por
retroceso; se corrige solo esa acción de prueba a Danza Espada y se repite el
gate completo. No era un defecto del daño implementado ni del recurso gráfico.

Gate general: **9.774 PASS**, ejecución de 591 movimientos y registro de 1.822
clips. Regresiones: motor 472, playback 20.809 e IA 628 PASS; DATA V3 mantiene
624 PASS y exactamente los mismos nueve fallos previos. Datos, manifiestos de
Pokémon, índice de movimientos y renderer congelado conservan sus hashes.
Sin nuevas imágenes, regeneración, exportación ni GitHub.

Evidencia: `FIXED_DAMAGE_MOVES.json`, `LIVE_MOVE_INTEGRATION.json` y
`LIVE_MOVE_UNAVAILABLE.csv`. Los límites previos de represalias si cae el
defensor, habilidades/protecciones todavía ausentes y dobles siguen explícitos.
La heurística del entrenador no se recalibra en este lote; los candidatos y las
simulaciones usan el mismo servidor autoritativo.

## Herramienta operativa de comparación externa — 2026-10-26

Vigente: cuatro familias y 5.910 casos, lotes de 500, 36 controles unitarios y
tres con motores reales. Las cifras iniciales que siguen son cierres previos;
el informe JSON actual contiene la ampliación descrita arriba.

Autorizada y construida la primera versión reutilizable en
`tools/battle_reference/`. Compara nuestro servidor autoritativo real con
`@pkmn/sim@0.10.11`, fijado mediante lockfile y instalado como herramienta de
desarrollo en `.godot/battle_reference/runtime/`. No sustituye el motor del juego.

Primer barrido de las dos familias iniciales: **1.932 MATCH / 0 MISMATCH / 0 NOT_COMPARABLE**, lotes de 150,
37,491 s en este equipo. Incluye los 600 de etapas y **1.332 de daño fijo**, ambos
lados y tres semillas. La segunda familia compara PS exactos de cuerpos y
sustitutos, debilitamiento, PP, ejecución y reservas. La primera mantiene sus
campos de etapas/PP/sustitutos. No certifica daño ordinario, distribución de RNG,
animaciones, dobles ni todos los movimientos del juego.

En aquel cierre, **24 pruebas del gate + tres controles con los adaptadores reales PASS**: se
detectan diferencias deliberadas; resultados vacíos/incompletos/duplicados no
pasan; contratos incompatibles quedan como no comparables, nunca coincidencias.
Se verifican sin cambios 230 fuentes/manifiestos durante la comparación. La
normalización explícita de potencia 1 de Calamidad frente a basePower 0 de la
referencia no acepta otros cambios. El barrido no modifica el juego; los cambios
de implementación de este lote constan separados en `FIXED_DAMAGE_MOVES.json`.

Evidencia y comandos: `BATTLE_REFERENCE_VALIDATION.json`,
`tools/battle_reference/README.md` y `.godot/battle_reference/latest/`.
Créditos/licencias conservados en `THIRD_PARTY_NOTICES.md` junto a la herramienta.
El siguiente uso es ampliar el contrato de comparación a una familia concreta
al implementarla, sin dar por resueltos los pendientes ni importar datos. El
informe actual incluye ya tres familias y 4.950 casos, como se describe arriba.

## Bloque anterior: ocho movimientos de modificadores de estadísticas — 2026-10-26

La prueba inicial aislada de 13 escenarios de `.godot/showdown_research/` queda
como evidencia histórica de viabilidad. Su continuación reutilizable y alcance
actual se describen en la sección anterior; no es una migración de arquitectura.

Lote integrado en el juego local con `stat_stage_move_rules.gd`, activado solo
por el perfil live. Se admiten Niebla, Reversión, Cambiaalmas, Cambiafuerza,
Cambiadefensa y Acupresión. Niebla Clara y Robasombra ya estaban admitidos, pero
se detecta/corrige que faltaba borrar/robar modificadores, respectivamente.
El contador aumenta por **seis**, no ocho: **585 admitidos / 334 no disponibles**.
Quedan **265** mecánicas ausentes/parciales (185 DATA_ONLY, 69 PARTIAL_RUNTIME,
11 UNSUPPORTED), más 15 excluidos, 53 decisiones Z y uno limitado a dobles.

Las reasignaciones directas tienen un evento semántico distinto de subir/bajar
niveles: no activan como falsas bajadas Contrary/Simple/inmunidades a descensos.
Niebla borra etapas solo de los activos; intercambios conservan las no afectadas;
Reversión respeta sustituto, Allanamiento y una reflexión por Espejo Mágico.
Acupresión elige entre las siete etapas no maximizadas, usa RNG reproducible y
resuelve sobre el usuario en individuales, incluyendo Simple/Respondón.
Robasombra roba únicamente mejoras positivas antes de calcular daño, respeta
inmunidad/fallo, atraviesa sustituto y corrige contacto en una definición separada.
Niebla Clara restablece etapas tras daño al cuerpo; un sustituto que se rompe
sigue bloqueando ese efecto. Los snapshots/forks conservan etapas y RNG.

Se conectan eventos reales con los clips originales existentes, sin alterar
PNGs, catálogo, renderer o datos canónicos. Prueba GPU: **2.005 PASS / 192 casos /
16 capturas**, con Pokémon regional shiny, y revisión visual de las muestras.
El test espera a completar layout antes de capturar el primer clip; una primera
captura prematura no era un defecto del recurso Niebla. Gate general actual:
**9.750 PASS**, 585 movimientos ejecutados y 1.822 clips validados. Regresiones:
472 motor, 20.809 playback, 628 IA PASS; DATA V3 624 PASS / nueve fallos previos.

Informes: `STAT_STAGE_MOVES.json`, `LIVE_MOVE_INTEGRATION.json` y CSV actualizado.
Límites: base de individuales; no certificación completa de habilidades,
supresión/Mold Breaker, protecciones futuras o dobles. Los límites históricos de
represalias al caer el defensor no cambian. Autosugestión y valores estadísticos
temporales siguen pendientes. Sin publicación/GitHub, regeneración de datos o
imágenes nuevas. Las secciones siguientes conservan los cierres anteriores.

## Bloque anterior: regionales y shiny existentes integrados localmente — 2026-10-26

Se atiende primero la petición de incorporar los recursos disponibles antes de
continuar con movimientos. Juego local: **1.025 especies base + 57 regionales**
(18 Alola, 19 Galar, 16 Hisui, 4 Paldea); **1.011 parejas shiny base + 57 regionales
shiny**. No se generan shiny de los 14 candidatos propios. Las seis especies base
excluidas se conservan en el archivo visual, fuera del selector ordinario:
1.076 entradas permitidas de especie/forma, sin implementar el randomizador final.

`pokemon_variant_catalog.gd` instala `config/pokemon_variants_v1.json` como extensión
separada de DATA V3. Cada regional tiene tipos, estadísticas, habilidades y learnset
propios de una sola versión del snapshot. Las evoluciones usan únicamente registros
que nombran esa forma; requisitos no soportados no se ignoran. Vulpix de Alola usa
Piedra Hielo para Ninetales de Alola, sin heredar el camino de Piedra Fuego.

`is_shiny` persiste con la misma criatura al capturar, enviar al PC, guardar/cargar
y evolucionar. Transformación copia temporalmente el aspecto y restaura el color
original. Sorteo cosmético configurable 1/4.096, sin adelantar el RNG mecánico.
F3 incluye regionales y botón Shiny. F1 acepta `vulpix_alola` y
`vulpix_alola__shiny` en equipo, entrenador o especie salvaje fija. Combate marca ★.

`assets/local_battle_variants/`: 2.250 atlas / 127.138 fotogramas empaquetados de
fuentes existentes, sin dibujar recursos nuevos. Originales de F:, pack base,
DATA V3, índice de movimientos y renderer congelado mantienen sus hashes. Sigue
pendiente empaquetado/distribución del arte local; no se ha subido a GitHub.

Gate GPU: **13.807 comprobaciones PASS / cuatro capturas**; todos los nuevos atlas,
encuadres, captura real, PC, guardado/carga, evolución, Transformación, ataques y
entrenador autónomo. Regresiones PASS: motor 472, campo 45, playback 20.809,
catálogo 27.329, encuadre 56.274, Transformación headless 1.208 e IA 628.
DATA V3 mantiene 624 PASS / los mismos nueve fallos previos.

Evidencia: `POKEMON_VARIANTS_INTEGRATION.json` y `.godot/pokemon_variant_checks/`.
No certifica otras formas especiales ni todas las habilidades/evoluciones. Siguiente:
retomar las mecánicas de movimientos pendientes, manteniendo sus límites anteriores.

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


## Bloque anterior: quince mecánicas base en F7/F8/F9 — 2026-10-26

Se añaden rain_dance, hail, sandstorm, snowscape y chilly_reception. El estado
habilita el clima mediante `weather_rules_enabled`, serializado de forma
aditiva; snapshots predeterminados conservan su forma anterior. F9 habilita
clima y relevo solo en nuevos encuentros salvajes individuales. El motor en
formato entrenador se prueba en ambos lados, sin desplegar interfaz/IA.

Duración, rocas, sustitución de clima, repetición sin prolongación y restauración
de contador/eventos deterministas. Daño de Agua/Fuego bajo lluvia; defensa de
Roca especial bajo arena y Hielo física bajo nieve; residual de granizo/arena,
inmunidades declaradas, anulación por Cloud Nine/Air Lock y curación Rain Dish/
Ice Body. Fría Acogida pone nieve antes de pausar el turno para elegir reserva,
incluida la nieve ya activa. El fin de clima precede su callback residual final.
Se evita repetir efectos de fin de turno sobre una reserva recién enviada por
KO climático. La ruta histórica desactivada conserva sus regresiones.

Presentación: diez clips de activación originales y cuatro bucles comunes que
siguen el estado del servidor y se limpian al terminar/capturar. 442.397 bytes
PNG copiados, sin nuevos dibujos ni cambios del renderer. Arena conserva su
bucle de 20 frames y lluvia/granizo/nieve sus 30 frames. Estos dos últimos
comparten el arte original, no reglas ni daño.

`WEATHER_PILOT.json`: 1.523 PASS/120 casos/11 capturas GPU observadas en lámina,
más estado de nieve antes de relevar. Capturas nuevas de activación back, no
certificación visual front completa; ambas direcciones se prueban en el motor.
`SWITCH_MOVE_PILOT.json` V3: 4.693 checks/360 casos/40 capturas/15 movimientos.
Regresiones PASS: F7 1.844; F8 1.326; reproducción 19.726; enlaces 407; modo
predeterminado 475; IA/entrenadores 628; núcleo 472; comandos 56; cambio 49;
captura 68; huida 94; vertical 62; guardado 40; campo 45. Datos: mismos nueve
fallos de auditoría preexistentes, 624 PASS/9 FAIL, documentados sin regenerar.

Cuatro IDs sin mecánica propia: substitute, shed_tail, transform, ally_switch.
Además faltan despliegue de entrenador/IA e interacciones completas de clima y
otras mecánicas: velocidad/evasión, Dry Skin/Hydration, ataques dependientes de
clima, habilidades que lo establecen y supresión de habilidades/objetos.
Los 19 handoffs globales permanecen abiertos. Sin datos, pool, PNG originales,
atlas, índice o renderer modificados. Sin commit/push/merge.

## Tramo anterior conservado: diez mecánicas base en los pilotos F7/F8 — 2026-10-26

F8 añade roar, whirlwind, teleport, baton_pass y parting_shot, con diez clips
nativos vinculados a MOVE_EFFECT_RESOLVED, independiente de consumir PP. F7
conserva los cinco anteriores. El nuevo nodo de presentación solo se habilita
con la marca del piloto y el pack/metadatos exactos; falta de caché o contrato
distinto conserva el fallback. No se promociona todo DATA_ONLY.

Rugido/Remolino reutilizan la expulsión autoritativa con sus bloqueos de estado.
Teletransporte moderno pivota al Pokémon propio y permite huir al salvaje.
Relevo transfiere etapas/volátiles expresamente admitidos antes de la entrada,
sin copiar estado persistente; Última Palabra aplica las dos bajadas y luego
pide reserva. Se prueban límites, falta de reservas, inmunidad sonora, reflejos,
Contrario/Simple, Defiant/Competitive y Mirror Armor dentro del alcance explícito.
La serialización activada normaliza enteros exactos de JSON para restaurar el
payload transferido; las fracciones y la ruta histórica desactivada se conservan.

`STATUS_SWITCH_MOVES.json`: 1.326 PASS/120 casos/diez clips/18 capturas GPU.
`SWITCH_MOVE_PILOT.json` V2: 3.170 comprobaciones/240 casos/29 capturas, diez IDs,
dos componentes con hashes propios. Láminas de ambos lados y combate/elección
observadas. Packs nuevos: solo 12.277 bytes de PNG copiados del catálogo ya
revisado. Sin cambios de imágenes/atlas/exports/renderer ni clasificaciones.

Regresiones PASS: núcleo 472; comandos 56; cambio 49; captura 68; huida 94;
vertical 62; guardado 40; campo 45; reproducción 19.726; enlaces anteriores 407;
auditoría predeterminada 475; corpus de IA/entrenadores 628. Auditoría de datos
624 PASS/9 FAIL idénticos a la comparación previa con el núcleo original:
referencias ausentes y discrepancias de informes locales, registrados.

Pendientes sin mecánica propia: ally_switch, chilly_reception, hail, rain_dance,
sandstorm, shed_tail, snowscape, substitute y transform. **No hay despliegue
global:** interfaz/planificación de entrenador y todas las interacciones
competitivas todavía necesitan trabajo. Solo F7/F8 salvaje habilitan los diez;
el motor de formato entrenador se ha probado por separado. La cola global
sigue en 19 IDs/38 clips abiertos. Sin commit/push/merge ni cambios de datos.

## Tramo anterior conservado: cinco mecánicas base conectadas en piloto individual F7 — 2026-10-25

Se añade una continuación autoritativa de turno para u_turn, volt_switch y
flip_turn. La fase `waiting_for_switch` conserva dueño, candidatos y cola de
acciones. El jugador elige una reserva viva y se continúa el mismo turno: sin
otro PP, sin otro comando y con fin de turno exactamente una vez. Estado/RNG y
cola sobreviven al round trip JSON/restauración del servidor. Se prueban ambos
lados, velocidades distintas y dos pivotes sucesivos en un turno.

circle_throw/dragon_tail expulsan aleatoriamente a una reserva viva en formato
entrenador; en salvaje individual terminan el encuentro cuando nivel usuario >=
objetivo, sin victoria, derrota, experiencia ni captura. Fallo, inmunidad, KO,
ausencia de reservas y KO por contacto impiden la transición correspondiente.
El snapshot marcaba los cuatro ataques físicos como no contacto: el piloto usa
copias de ejecución corregidas, sin modificar datos/clasificaciones. Se conservan
las limitaciones históricas de represalias cuando el defensor cae por el golpe.

**Alcance explícito:** el estado habilita el piloto solo en los nuevos encuentros
salvajes F7. La IA y la interfaz de entrenador siguen en el contrato anterior;
su motor se prueba directamente, pero sus consumidores todavía no gestionan la
pausa. Snapshots predeterminados mantienen el formato V2 anterior sin campos
extra. F6 sigue disponible como contraste SOLO DAÑO. Reiniciar desactiva F7 y
restaura los learnsets naturales del equipo seleccionado.

`SWITCH_MOVE_PILOT.json`: 1.844 PASS/120 casos/11 capturas GPU. Observadas la
lámina de cinco golpes/tres elecciones y la entrada del Pokémon elegido.
Regresiones PASS: núcleo 472; comandos 56; cambios normales 49; captura 68;
huida 94; vertical 62; guardado 40; campo 45; reproducción 19.726; enlaces 407;
los 19 casos en modo anterior 475; corpus de IA/entrenadores 628.
Auditoría de datos: 624 PASS/9 FAIL idénticos en copia con núcleo anterior y
actual (fuentes `data/api` ausentes y discrepancias de informes), registrados.

Quedan 14 IDs sin mecánica propia y el despliegue/interacciones de los cinco del
piloto. No se cierran aún los 19 handoffs globales. No se han cambiado imágenes,
renderer, atlas, índice, datos, política de contenido o algoritmos de IA. Sin
commit/push/merge. El informe BATTLE_EXTERNAL_INTEGRATION diferencia modo
predeterminado de este piloto y enlaza su evidencia.

## Tramo anterior conservado: cinco enlaces de daño; los 19 efectos especiales siguen abiertos — 2026-10-25

Se verificaron los 19 movimientos contra el servidor autoritativo en ambos
lados, con reservas disponibles: 38 casos. Hallazgo: circle_throw, dragon_tail,
flip_turn, u_turn y volt_switch hacen daño ordinario sin relevo/expulsión. Los
otros catorce consumen PP sin su efecto especial en estas pruebas. La etiqueta
RUNTIME_SUPPORTED de cuatro de los primeros no prueba su mecánica completa.
Se conservan todas las clasificaciones y datos; esta auditoría no los promueve.

Se añaden solo partículas nativas de esos cinco daños confirmados, con tiempos
de impacto/PS fijados y copia local de diez clips (179.921 bytes PNG). Se omiten
cuerpos/fondos del clip para conservar los Pokémon y resultados del combate
autoritativo. Si falta el pack o no corresponde, permanece la presentación
genérica. F6 ofrece el preset temporal SOLO DAÑO, sin guardar otro learnset.

Estado **PARTIAL**, no 19 terminados: `BATTLE_EXTERNAL_INTEGRATION.json` contiene
los 19 requisitos y la evidencia por ID. GPU 475 PASS, 11 impactos reales y 12
capturas; observadas las diez vistas agrupadas y el mapa. Comprobados inmunidad,
cambio ordinario, relevo por KO, captura, cancelación, bloqueos y conservación
del estado/RNG durante reproducción. Regresiones PASS: 407 de enlaces previos,
19.726 reproducción, 4.949 recetas visuales y 45 ruta/mapa.

Pendiente mecánico: elección/continuación de relevos, expulsión, clima,
sustituto, transformación y Ally Switch en dobles. Faltan estados/eventos y
contratos del motor; no es solo una tarea de dibujos. La cola conserva 19 IDs/
38 clips abiertos, 74 IDs/118 cerrados; catálogo 900 IDs/1.822 clips e inventario
de alternativas 41 IDs/49 familias/98 clips sin cambios. Nuevos enlaces de
combate: cinco IDs/diez clips SOLO DAÑO; junto a los anteriores diez IDs/20 clips,
sin certificar diez mecánicas completas. Sin commit/push/merge.

## Tramo anterior conservado: barrido de los 24; solo quedan dependencias de integración — 2026-10-25

Los 24 IDs/48 vistas se contrastaron en lote. Se cierran cinco IDs/nueve clips
de cola: Clanging Scales fija el receptor a su propia plaza (back/front), Court
Change conserva su cruce inicial y devuelve cuerpos a sus plazas al finalizar;
Aeroblast, Destiny Bond y el recurso DOOMDESIRE se verifican contra su fuente.
Clanging back se corrige también pero no se vuelve a contar, pues no estaba
en la cola original pendiente. No se han sustituido PNG, atlas ni exports.

Total **74 IDs/118 clips cerrados**. Restan **19 IDs/38 clips de presentación
externa**; sus fuentes nativas ya están revisadas. No equivale a tener sus
resultados conectados al combate. El laboratorio identifica el requisito exacto
de cada uno; seis conservan su muestra opcional y trece no tienen esa simulación.
La cola sigue abierta hasta implementar los enlaces reales pertinentes.

Review `.godot/move_general_checks/418254331eca04dc/gpu/review.json`, SHA
`208ad6d39b44df9741027494f35c502158b96252f0a2aa5bef0575927f1addc5`.
Nueve láminas observadas, 960 pares/1.920 PNG. 593.828 checks GPU PASS;
2.532 estados de captura +12.660 de contrato con cinco parejas/dos arenas.
540 anclas de receptor, 40 finales de Court Change; cuatro fuentes alteradas
rechazadas. Cotejo con los 48 exports originales, respetando la reparación
histórica de 11 focos de Chilly Reception front. No certifica tiempo real.

Se localizaron DOOMDUMMY back/front (candidato separado, 42 frames) y el clima
Common:Sandstorm (20 frames). Se documentan para integración; no se añaden al
catálogo. La asignación final de los recursos de Deseo Oculto a carga/impacto
también queda pendiente: los nombres por sí solos no certifican esa correspondencia.

Renderer `7674d3a61e113e085d12132a4e10461aedd3a760516ab68700f2868f0f3fd4de`;
contexto `e1221ddaae3b2375`, mismos recursos/frames/bindings. Regresiones PASS:
catálogo 5.366.237/118.766 estados/1.822 clips; Z 317.062; contexto 6.442;
rutas 407; perfil/laboratorio 1.898. Inventario artístico 41 IDs/49 familias/98
clips, intacto. El pool conserva sus exclusiones y los 53 Z pending; la auditoría
no cambia daño, IA, datos, soporte mecánico o HEAD. Sin commit/push/merge.

## Tramo anterior conservado: siete casos Z revisados — 2026-10-25

Por instrucción del usuario se retomaron los siete Z, sin resolver su inclusión
en el pool final. Diez clips de cinco IDs usan opciones artísticas parciales:
energía/orbes/nube de impacto del mismo atlas y eliminación de Pokémon auxiliares.
Dos clips de Marshadow corrigen el encuadre del usuario al emerger más allá del
receptor, manteniendo tamaño, opacidad, tiempos y partículas. Dos clips de
Guardián de Alola se verifican fieles a la fuente, incluida su transparencia final.

Review `.godot/move_z_checks/c2a52b27e855bafa/gpu/review.json`, SHA
`1be9f5844bbe15fd7eb487d01c8a07d36eed7f8ab0ebfa911518112347793913`.
Siete láminas antes/después observadas; 280 pares de muestras iguales al candidato
elegido, 560 PNG. 317.622 checks GPU PASS, 2.724 estados de captura y 16.320 de
contrato, cinco parejas/dos arenas; 80 poses de emergencia sin recorte del cuerpo
en los tamaños probados. No es certificación de visionado de movimiento en tiempo real.

Acumulado: **69 IDs/109 clips cerrados**; quedan **24 IDs/47 clips: cinco contraste
y 19 contexto**. Los siete Z salen de la cola artística por evidencia, no por
exclusión. El perfil conserva 53 Z `pending` para decidir el pool final; la vista
de juego mantiene 846 IDs/1.714 clips y el archivo completo 900 IDs/1.822 clips.
Inventario de opciones artísticas: 41 IDs/49 familias/98 clips. Cada cambio queda
en VISUAL_SUBSTITUTIONS; originales conservados, sin autores/recursos nuevos.

Renderer `16892e3fcdd25ab448a42e45d1a96f48dba4863ed28adddf1863bf23de770c26`;
contexto `3bcab4075e9a7662`, mismas fuentes/frames/bindings. Catálogo completo
5.366.237 PASS/118.766 estados/1.822 clips; motivos previos 92.247; contexto
6.442; rutas 407; perfil/laboratorio 1.898. Los vetos de selección, datos canónicos,
clasificación, daño, IA, workflows y HEAD no cambian. No se han regenerado datasets
ni catálogo. Sin commit/push/merge; CI del HEAD previo no certifica este trabajo local.

## Tramo anterior conservado: política de contenido Randomlock y cola filtrada — 2026-10-25

Decisiones persistidas en `config/randomlock_content_v1.json` y el cuaderno
`docs/project_book/RANDOMLOCK_RULES.md`. Filtro reutilizable de selección en
`modules/gameplay/randomlock_content_policy.gd`, separado de los catálogos fuente.
Confirmados: 15 movimientos presentes excluidos, 16 habilidades, seis especies
(incluidos Nincada/Ninjask/Shedinja) y ocho formas de Pikachu con gorra. Se vetan
todas las formas de las seis especies. No se modifican datos ni reglas de daño.

Los 53 Z siguen pendientes de decisión expresa; 19 Max protegidos. Candidatos:
851 movimientos elegibles, 53 en espera y 15 descartados; 357 habilidades y
1.019 especies elegibles. Elegible no significa mecánica implementada.

El launcher de ataques abre el pool filtrado: 846 IDs/1.714 clips. El archivo
de investigación conserva 900 IDs/1.822 clips. No se ha implementado todavía el
randomizador final ni se han impuesto estos vetos a las demos técnicas históricas.
Las futuras selecciones de contenido deberán consumir la política.

`CONTENT_POOL_AUDIT.json` cruza el perfil con la review del octavo grupo y guarda
SHA de entrada. 13 huecos Let's Go se descartan del trabajo. Permanecen cinco
Torque y un Z pendiente. Cola artística: 24 activos (cinco contraste/19 contexto)
y siete Z en espera; histórico 62 IDs/95 clips cerrados intacto. No sumar vetos
como aprobaciones artísticas ni tocar la review original.

Pruebas locales: contrato 1.898, contexto 6.442 y cinco rutas 407, todas PASS.
Raw, normalized, índice, plan, review original y renderer conservan sus SHA.
HEAD sigue `0902de4c10d34a2a451c9acad83fbfea765ef270`; sus 19 workflows se
comprobaron SUCCESS, pero no certifican estos cambios locales sin commit.
Sin commit/push/merge, sin nuevas imágenes ni sustituciones.

## Tramo anterior conservado: dos elecciones parciales sin rostros ajenos — 2026-10-25

Octavo grupo cerrado: Embate Supremo y Pikavoltio Letal back/front tenían motivos
específicos de Zamazenta/Pikachu, poco adecuados para usuarios aleatorios. No eran
fallos técnicos. Se conserva la animación fuente y se aplican elecciones artísticas
parciales: Embate Supremo dibuja el motivo8 como impacto metálico9 del mismo atlas;
Pikavoltio omite solo las tres celdas de insignia10/11/12, conservando rayos/fondos.
No es un escudo neutro nuevo ni una secuencia Z original reparada. Incluye la
preparación restante, sin recortar la duración ni cambiar cuerpos/mecánicas.

Las cuatro vistas muestran EQUIVALENTE ARTÍSTICO EXPLÍCITO y PARCIAL en el
laboratorio. Fuente fijada por nombre/lado/SHA completos de frames/capas/atlas;
PNG y catálogo inmutables. Inventario: **36 IDs/44 familias/88 clips con selección
alternativa**, los 34 IDs previos más dos elecciones parciales de motivos.

Dos IDs/cuatro clips de cola cerrados. Acumulado **62 IDs/95 clips cerrados**;
pendientes **31 IDs: 12 contraste +19 contexto**, 61 clips. Evidencia
`.godot/move_art_motif_checks/21fa00b2ed6f3953/gpu/`: result/review/boards y dos
láminas antes/después observadas, 88 pares/176 PNG. Gate GPU **92.447 PASS/2.136
estados**, tres parejas/dos arenas; 64 capturas coinciden con los candidatos
observados. Tajo Supremo (atlas compartido) y Rayo permanecen iguales. No quedan
efectos vacíos: 42 frames de partículas en Embate; 30 de partículas/44 de capas
en Pikavoltio. Sondeo inicial 963 PASS/808 estados, fuentes anteriores conservadas.

Regresiones PASS: catálogo 1.822 clips/118.766 estados/**5.368.157 checks**. El
contador baja por las celdas de insignia omitidas, no por retirar clips o tests.
Piloto 444.079, cuerpos 387.764, anclas 303.509, proyección 207.382, haz 157.818,
agua 183.731, locales 55.543, recorridos 53.319, cámaras 4.620, cinco rutas 407,
contexto 6.442. Renderer `a9e655948ae20b50b2f2d8ee34b906f3729db6e29d0bb7b9a45b1a704aca9ce2`;
contexto derivado `d45df89b77577919`, mismo arte/frames/bindings.

Registro actualizado en VISUAL_SUBSTITUTIONS, con originales preservados y sin
créditos nuevos. Datos, IA, clasificación, cinco rutas, workflows y HEAD intactos.
Siguiente: lote de cinco Z con especies incrustadas; separar fases/encuadres de
Guardian of Alola y Soul-Stealing 7-Star Strike. Sin commit/push/merge.

## Tramo anterior conservado: recorridos y reentradas — 2026-10-25

Séptimo grupo cerrado: Treparrocas y Derribo back/front adaptan el recorrido del
usuario a la línea entre actores, conservando forma, rotación, fases y recursos.
La fuente sale de pantalla y salta de un borde a otro; no aplicar el límite de
Danza Amiga. La proyección local anterior dejaba cuerpo visible en ese salto.
Derribo front corrige además las estrellas de impacto al ancla local del receptor.

La prueba ampliada con Wailord detectó restos incluso tras corregir la trayectoria.
Se añade un fundido acotado al cambio de borde: Treparrocas alpha0 f20..24 y media
f19/f25; Derribo alpha0 f9..13 y media f8/f14. Resto de opacidades intacto. No
modifica PNG ni frames de fuente: es una adaptación de presentación explícita.
Llave Corsé back/front comprobada sin cambio: lanzamiento continuo fuera del
encuadre y regreso presentes en fuente; no era expulsión ni pérdida del cuerpo.

Tres IDs/seis clips de cola cerrados, dos corregidos y uno comprobado. Acumulado
**60 IDs/91 clips cerrados**; pendientes **33 IDs: 14 contraste +19 contexto**,
65 clips. Evidencia `.godot/move_motion_path_checks/4a0319aad2f9b423/gpu/`:
result/review/boards, tres láminas, 88 pares/176 PNG completos, 80 PNG de cuerpo
aislado transparentes en ambos extremos del salto, cinco parejas/dos arenas.
Gate GPU **53.759 PASS/1.600 estados**. Sondeo inicial 1.209/800 estados; seis
láminas observadas entre diagnóstico y arreglo, 84 capturas finales coinciden
con la propuesta de recorrido antes de añadir el fundido para cuerpos grandes.

Regresiones PASS: catálogo 1.822 clips/5.368.625, piloto 444.079, cuerpos 387.764,
anclas 303.509, proyección 207.382, extremo de haz 157.818, agua 183.731, locales
55.543, cámaras 4.620, cinco rutas 407, contexto 6.442. Renderer
`d934d0ccf43b955c1a055e2415bbd54e01ec4b8d56ed4eb9b8c08e792d6ef3a9`, contexto
derivado `eac61685a8e18a2f`, mismo arte/frames/bindings. Fuentes de las cuatro
políticas fijadas por nombre/export/SHA completo/atlas; baselines intactos.

Cuatro vistas modificadas registradas en VISUAL_SUBSTITUTIONS; 34 equivalencias
completas intactas. Datos, IA, mecánicas, cinco rutas, workflows y HEAD sin
cambios. Siguiente: cargas/cinemáticas pendientes (behemoth_bash, catastropika).
Sin commit/push/merge; no confundir un recorte intencionado con un fallo permanente.

## Tramo anterior conservado: efectos locales — 2026-10-25

Sexto grupo cerrado: cuatro IDs/siete clips de cola. Acupresión back/front
conserva la marca sobre el usuario y transfiere allí el destello del otro cuerpo,
como referencia de uso sobre uno mismo en el laboratorio; no implementa aliado
ni estadísticas. Danza Amiga front reduce solo la excursión descendente del
receptor para que su envolvente quepa con margen de 8 px; conserva X, ascensos,
tiempos y tamaño. Camelo back/front aísla cada región del atlas al filtrar: elimina
las líneas ajenas a la celda sin borrar confeti ni cambiar imágenes.

Niebla Aromática back/front queda verificada sin cambio: capas de fuente iguales
y capturas GPU de las capas aisladas idénticas en ambas vistas. La ausencia de
niebla no se reproduce en el renderer actual; no equivale a aprobar destino aliado.
**57 IDs/85 clips cerrados**, incluyendo comprobados; quedan **36 IDs: 17 de
contraste y 19 de contexto**, 71 clips. No descontar otra vez estas siete vistas.

Evidencia `.godot/move_local_effect_checks/58e91f150a8fc69c/gpu/`: result/review/
boards, lámina antes/después, 84 pares/168 PNG completos y 96 pares/192 PNG de
oráculo de partículas. Gate GPU **55.939 PASS/1.800 estados**, tres parejas/dos
arenas. Recortes de receptor 30 → 0. Camelo coincide en todos los frames/lados/
arenas con las celdas de fuente aisladas: diferencia máxima de canal 1/255.
Sondeos antes `e761bf78c0468ccf`, después `a62342ccd21cad1f`: 782 PASS/600 estados
cada uno; 98 PNG iguales y 42 cambiados. Lámina y ampliaciones nativas observadas.

Regresiones PASS: catálogo 1.822 clips/5.368.625 checks, piloto 444.079, cuerpos
387.764, anclas 303.509, proyección 207.382, Láser Doble 157.818, agua 183.731,
cámaras 4.620, cinco rutas 407, contexto 6.442. Renderer
`b7da766584d96b4a5d809738b7c68cdb9031f35a05faa828a37869a80e064505`, contexto
derivado `93cac9b62b9b823b`, mismos recursos/frames/bindings. Fuentes de las
políticas fijadas por SHA completo de frames/capas/atlas; ningún PNG modificado.

Baselines, datos, IA, mecánicas, workflows y HEAD conservados. Cinco rutas reales
sin cambios. Registro de las cinco vistas modificadas en VISUAL_SUBSTITUTIONS;
34 equivalencias completas intactas. Siguiente: desplazamientos corporales de
rock_climb, storm_throw y take_down. Sin commit/push/merge.

## Tramo anterior conservado: agua y orientación de olas — 2026-10-25

Quinto grupo cerrado: Hidrovórtice físico/especial y Maxichorro front mostraban
una segunda franja de la textura repetida antes de llegar la cresta. Se ocultan
solo las filas 524..1150 de esa capa durante f0..11. Desde f12 vuelve el relleno
original, necesario para completar la inundación. Cresta, cuerpos, partículas,
offsets, colores, fuentes y tiempos conservados; política por ID/export/SHA de
frames, capas y PNG. No es una corrección global de todas las capas de agua.

Surf y Onda Tóxica front quedan verificados sin cambio: la cresta y el avance
desde arriba están en las fuentes rivales. **Cinco IDs/cinco clips cerrados**,
tres corregidos y dos comprobados. Acumulado **53 IDs/78 clips cerrados**;
quedan **40 IDs: 21 de contraste y 19 de contexto**, 78 clips.

Evidencia `.godot/move_water_checks/085180c565bcc21c/gpu/`: result/review/boards
y `water_before_after.png`; 90 tiempos por dos renderers, 180 PNG. Gate GPU
**8.907.974 PASS/2.868 estados**, tres parejas y dos arenas; máscara contrastada
con coordenadas de textura independientes en todos los frames corregidos a
640×360, muestras cada cuatro píxeles en X. Sondeos antes `0e74983d44234990` y
después `fa75bd02eb57c456`: cada uno **4.192 PASS/1.434 estados**, cinco IDs,
ambos lados y tres cámaras. 290 PNG iguales y 18 diferentes solo en la entrada.

Regresiones PASS: catálogo 1.822 clips/5.368.625 checks; piloto 444.079; cuerpos
propios 387.764; anclas 303.509; proyección 207.382; Láser Doble 157.818; cámaras
4.620; cinco rutas 407; contexto 6.442. Renderer
`c712c423db4a45d7287a2c658505e311b03267391b85c8f3b1674b436f0fe4ad`;
contexto derivado `7a6f7eeb596fe91a`, mismo arte/frames/bindings.

Fuentes/baselines, datos, IA, mecánicas, workflows y HEAD conservados. No se
modifican atlas ni se descargan imágenes nuevas. Limpieza parcial registrada en
VISUAL_SUBSTITUTIONS; equivalencias completas siguen en 34 IDs. Siguiente:
gestos/efectos locales de la cola restante, por causa compartida. Sin commit/push.

## Tramo anterior conservado: Láser Doble y dos dudas de impacto — 2026-10-25

Cuarto grupo: **tres IDs/cuatro clips cerrados**, separando reparación de revisión.
Láser Doble front terminaba en x176/178 de fuente frente a origen trasero x128;
se calibra solo el extremo horizontal para que x176 alcance nuestro objetivo.
Conserva tamaño/forma de partículas, Y, tintes, cuerpos y fuente; export fijado
por SHA completo. Contacto con silueta en 640×360 f19: **0,12 % → 24,96 %**,
diagnóstico visual, no daño. Back permanece idéntico. Pulso Dragón sí alcanza
el objetivo en f35; Lanza Glacial front presenta fragmentos/reacción en f18.
Estas dos dudas se cierran comprobadas, sin sustituir ni mover recursos.

**48 IDs / 73 clips de la cola cerrados** (incluye verificados sin reparación).
Quedan **45 casos: 26 de contraste y 19 de contexto**, 83 clips.
Antes/después `.godot/move_beam_endpoint_checks/9a306b629ccf3cfa/gpu/`:
`{result,review}.json`, dos láminas, 10 IDs/20 vistas, 60 tiempos/120 PNG.
Sondeos completos antes/después en `.godot/move_pending_beam_checks/`
`c60749ecda70ec7e/` y `748c927261000e64/`: 630 estados cada uno, referencia de
fuente sin calibrar y dos arenas adaptadas, sin fingir captura del juego original.
Seis láminas observadas entre diagnóstico y reparación, con ampliaciones nativas.

Gate de reparación GPU **157.995 PASS / 3.240 estados**, tres parejas/dos arenas;
sondeo posterior **8.536 PASS / 630 estados**. Regresiones: catálogo headless
5.368.625/1.822 clips; piloto 444.079; anclas 303.509; proyección 207.382;
cuerpos propios 387.764; cámaras anteriores 4.620; cinco rutas 407; contexto
6.442 PASS. Láser Doble pasa de control a caso reparado; Pulso Dragón intacto
lo sustituye en dos gates, con fuentes anteriores de tests preservadas.

Renderer `d1861790b5291352cf21c4517158682a7254ea23e10736920917af021ea99e18`;
contexto derivado `92770bfa947e9143`, mismo arte/frames/bindings. Índice, fuentes,
datos, IA, mecánicas, cinco rutas, workflows, HEAD y baselines intactos.
Sin commit/push/merge. Siguiente: transiciones de agua y orientación de olas.

## Tramo anterior conservado: escudos y recorrido de Sombra Vil — 2026-10-25

Tercer grupo: **cinco casos frontales cerrados**. Pantalla de Luz, Escudo Tatami,
Anticipo y Reflejo conservaban foco delantero en el cuerpo trasero no implicado:
ahora permanece en su plaza. Sombra Vil separa óvalo viajero (línea entre actores)
y destellos locales del objetivo. Políticas por export/ID/nombre/SHA completo de
frames; arte, cuerpos animados, capas, tintes, escala y fuentes conservados.

**45 IDs / 69 clips señalados cerrados en tres grupos**; quedan **48 casos del
baseline: 29 de contraste y 19 de contexto**, 87 clips. Láser Doble sigue abierto,
sin cambio: el contacto parcial y el offset de fuente requieren contraste propio.
Evidencia nueva `.godot/move_projection_checks/c7fb45d23f10eccb/gpu/`:
`{result,review}.json`, tres láminas observadas en `sheets/`, 15 IDs/30 vistas,
96 tiempos antes/después = 192 PNG. Sombra Vil ampliada f5/f10/f16/f20 confirma
origen, recorrido, llegada y destello; controles y back idénticos en muestras GPU.

Gate GPU: **200.653 PASS / 4.428 estados / 780 posiciones corregidas comprobadas**,
tres parejas y dos arenas. Regresiones: catálogo 5.368.625 PASS/1.822 clips;
prioritario 444.079; anclas anteriores 296.513; cuerpos propios 387.764;
cámaras previas 4.620; cinco rutas reales 407; contexto 6.442, todo PASS.
Sombra Vil pasa de control del test anterior a caso corregido con oráculo propio;
Rayo Hielo ocupa su lugar como control intacto. Test anterior preservado por SHA.

Renderer `81cb49e7e0b2594181ebec834f5fa3c58bbffa036e7fb02a0e13a3d31d10a074`;
contexto derivado `acb25776afb63cda`, mismo arte/frames/bindings. Baselines previos,
datos, índice, IA, mecánicas, rutas, workflows y HEAD intactos. Sin commit/push/merge.
Siguiente: Láser Doble y otros haces/impactos pendientes; después agua/encuadres.

## Tramo anterior conservado: anclas nativas frontales — 2026-10-25

Corregidas **13 exportaciones frontales / 13 casos de la cola** con la misma causa:
partículas locales del objetivo escritas alrededor de (128,224) pero marcadas con
foco de (384,96). En nuestra cámara quedaban separadas del Pokémon trasero. La
corrección usa su ancla trasera y conserva el desplazamiento local de la fuente.
Está limitada a IDs/nombres/tipo de export/SHA completo de frames comprobados.
Rechaza fuentes distintas; no aplica heurísticas globales por coordenadas.

Casos cerrados: Agarrón, Taladradora, Ala Bis, Palmeo, Picotazo Veneno, Cola Veneno,
Bola de Polen, Latigazo, Cara Susto, Residuos, Relámpago Súbito, Ataque Ala y
Abatidoras. **40 IDs cerrados entre ambos grupos / 64 clips señalados**. Quedan
**53 casos del baseline: 34 de contraste y 19 de contexto**, 92 clips.
Sombra Vil y Láser Doble conservan deuda de trayectoria. Latigazo ahora toca cuerpo
en f0; la separación f6 coincide con retroceso nativo, no falta todo el impacto.

Evidencia `.godot/move_anchor_checks/4cba2c2b751a2842/gpu/{result,review}.json` y
`sheets/boards.json`: cinco láminas observadas, 23 IDs/46 vistas, 138 muestras
temporales antes/después (276 PNG). Grupo GPU **296.099 PASS / 6.552 estados /
4.284 celdas desplazadas comprobadas**, tres parejas y dos arenas. Cuerpos, capas,
texturas, colores, tamaños, partículas con foco3 y controles permanecen iguales.
Renderer actual `b2610a303d30411b07100f985133cbd0a644ebccbbd4f5f4623349cc92845302`.

Regresiones: catálogo headless **5.368.625 PASS / 118.766 estados / 1.822 clips**;
piloto prioritario 444.079; grupo propio 387.764; cámaras anteriores 4.620;
cinco rutas reales 407; contexto opcional 6.442/1.164 estados, todos PASS.
Contexto derivado nuevo `d96f2f29fcdf3855`, sin arte/frames/bindings distintos.
Índice, datos, IA, mecánicas, cinco rutas reales, HEAD y evidencia de los dos
baselines intactos. Sin commit/push/merge. Siguiente: trayectorias pendientes y
campos/escudos desplazados, antes de capas de agua y encuadres.

## Tramo anterior conservado: primera reparación, cuerpos propios — 2026-10-25

El usuario autorizó comenzar las correcciones por causas comunes tras cerrar el
barrido. Corregido el dibujo simultáneo de las dos bases de un único Pokémon en
movimientos dirigidos al usuario. El adaptador conserva una base; prioriza la
pista que lleva pose/tinte/fundido cuando la otra sigue en reposo y usa el rol de
la exportación para desempatar (OppMove invierte roles). Conserva celdas extra 2+.
La excepción encontrada de Danza Lunar mantiene su azul; Venganza alterna pistas.
Es política acotada de presentación, sin cambios de mecánicas ni imágenes fuente.

**27 IDs de la cola / 51 clips señalados cerrados para este problema primario**.
Quedan **66 casos del baseline sin cerrar: 47 de contraste y 19 de contexto**,
105 clips. El alcance técnico incluye 97 IDs propios/194 clips; revisión visual
focal antes/después de 27 IDs y 11 controles, 76 vistas/152 PNG en ocho láminas.
Se conservan ecos de Doble Equipo/Pesadilla/Reducción. Los relevos y sustitutos
mantienen su deuda; Teletransporte ahora deja desaparecer al usuario correctamente.

Gate GPU del grupo: **387.922 checks PASS / 10.004 estados**, dos arenas, fuente
anterior frente a actual. Regresión completa headless: **5.368.625 checks PASS /
118.766 estados / 1.822 clips**. Piloto prioritario: 444.079 PASS; cinco conexiones
reales: 407 PASS; contexto opcional: 6.442 PASS/1.164 estados; dos tests Python de
evidencia externa PASS. Renderer actual:
`4fb1e38b88cd6e2d34a92c414d21fdadf4544cd6daaacfc6460f592d4aab893e`.
Comparación y registro: `.godot/move_self_body_checks/e6bb10786f264b35/gpu/`
`{result,review}.json` y `sheets/boards.json`. El barrido original conserva sus 523
anotaciones, 18 reportes y 366 láminas sin migrar aprobaciones al nuevo renderer.

El contexto opcional derivado se reconstruyó en generación `67ab17c8a7c5e617`
porque el hash del renderer cambió; arte, secuencias y bindings idénticos, anteriores
intactos. Su generador incluye ahora el renderer en la identidad. Primeras
comparaciones descartadas y pruebas fallidas se conservan como diagnóstico.
Datos, índice, hojas, IA, cinco rutas reales y HEAD intactos. Sin commit/push/merge.
Siguiente grupo: anclas/impactos separados, empezando por exports frontales.

## Baseline conservado: barrido temporal de los 900 cerrado — 2026-10-25

Nueva prioridad del usuario: comprobar visualmente los **900 IDs reproducibles**
en bloques completos, manteniendo la cola de dudas. Reconfirmado por el usuario:
**primero revisar y guardar todos los casos, después corregirlos**. La primera revisión por
muestras anterior sigue siendo evidencia histórica; no equivale a ver cada
animación entera ni a aprobar mecánicas.

Plan fijado de **18 bloques de 50 IDs**, ambos lados y variantes, sin omisiones:
`.godot/move_temporal_batches/c5b2756454290487/plan.json`.
**900/900 IDs revisados en esta fase / 1.822 clips / 59.383 frames GPU / 317.099
checks PASS**, sumando dieciocho gates. Bloque 1: 3.014 frames / 16.756 checks; bloque 2:
3.218 frames / 17.369 checks; bloque 3: 3.376 frames / 17.842 checks; bloque 4:
2.948 frames / 16.559 checks; bloque 5: 3.320 frames / 17.674 checks; bloque 6:
3.139 frames / 17.132 checks; bloque 7: 3.263 frames / 17.503 checks; bloque 8:
3.746 frames / 18.977 checks; bloque 9: 3.427 frames / 17.996 checks; bloque 10:
4.014 frames / 19.756 checks; bloque 11: 3.866 frames / 19.345 checks; bloque 12:
2.972 frames / 16.630 checks; bloque 13: 2.812 frames / 16.151 checks;
bloque 14: 3.675 frames / 18.772 checks; bloque 15: 3.220 frames / 17.374 checks;
bloque 16: 3.102 frames / 17.021 checks; bloque 17:
3.469 frames / 18.121 checks; bloque 18:
**2.802 frames / 16.121 checks PASS / 100 clips**, de trump_card a zing_zap.
Todos los frames capturados; reloj a 20 fps y
limpieza comprobados. Trescientas sesenta y seis láminas observadas,
16 momentos por vista, incluyendo extremos, picos y transiciones; ampliaciones
de PNG nativos para confirmar o descartar dudas de las miniaturas.

Registro `review.json` acumulado: **1.666 clips temporal_samples_checked, ciento dieciocho
needs_targeted_review y treinta y ocho requires_external_presentation**. Son **807 IDs sin
fallo evidente en las muestras, setenta y cuatro pendientes de contraste focal** y **diecinueve
de contexto**. Bloque 18 aporta **42 IDs sin fallo evidente, cinco dudas y tres de
contexto**, 87/7/6 clips respectivamente. Los 85 casos de los bloques anteriores
permanecen anotados íntegros; no se ha vaciado ni migrado la cola.
La copia extra de Charizard en Barrera front está visible en el PNG nativo f6;
Corpulencia muestra dos dibujos superpuestos del usuario al cambiar escala en f7,
en ambos lados. Embate Supremo muestra un escudo con rostro específico: revisar
su idoneidad para usuarios aleatorios, no es fallo técnico confirmado. Relevo
necesita la sustitución externa: su usuario principal permanece al acabar; las
celdas fantasma que terminan ocultas no prueban que desaparezca. No se ha corregido
ni sustituido arte para cerrar contadores.

Nuevas notas del bloque 3: Celebración y Copión superponen dos cuerpos base del
usuario (f7/f10, ambos lados); Fragor Escamas front eleva/recorta al objetivo por
el borde superior (f5, back no recorta); Cambio de Cancha termina con ambos cuerpos
en plazas intercambiadas (f21, contrastar coreografía); Pikavoltio Letal muestra
una insignia con Pikachu, duda artística secundaria de uso con usuarios aleatorios,
no fallo técnico. Llave Giro expulsa/oculta al objetivo y necesita presentar el
siguiente combatiente. Fría Acogida conserva su deuda ya conocida de clima/retirada.
Confusión NO añade deuda: sus cuerpos principales terminan visibles/opacos; el
disparador de opacidad era una celda extra oculta.

Bloque 4: Detección front dibuja otro Charizard junto a Ogerpon (f7); Danza Dragón
superpone usuario normal y rosado desplazado en ambos lados (f20); Agarrón front
separa la mano cerrada del cuerpo encogido (f10, back sirve de referencia). Dudas
de presentación que necesitan fuente/fase: Mismo Destino muestra una elipse gris
en fondo negro, Deseo Oculto trazos rígidos convergentes, Pulso Dragón esfera/aros
concentrados en el usuario sin trayectoria/impacto claros en las muestras. No son
tres fallos técnicos probados. Cola Dragón necesita la presentación de entrada
posterior a la expulsión del objetivo. Investigar juntos los contornos dobles al acabar el barrido; conservar
los clones intencionales de Doble Equipo (celdas adicionales 2/3, f12 ambos lados).

Bloque 5: Taladradora front (f12) y Ala Bis front (f6), efecto separado del objetivo
frente a sus referencias back; Aguante (f6) y Deslome (f10), cuerpos base del usuario
superpuestos en ambos lados; Danza Amiga front, objetivo recortado por abajo al
descender (f29, y305.35), back sin ese recorte; Novena Potencia, fila de evoluciones
de Eevee incrustada, duda artística secundaria de uso final. Paranormal no añade
deuda: cuerpos base visibles/opacos al acabar y una celda extra oculta/fundida.
Bloque 6: Palmeo front separa la mano del objetivo (f7, back sí la superpone);
Camelo muestra líneas finas sobre fondo negro junto a las partículas (ambos f12),
pendiente cotejar fuente/filtrado antes de considerarlo un artefacto. Viraje sale
de escena y necesita presentar su relevo (ambos f29). Se conservan los equivalentes
previos de Truco Floral (solo fondo) y Premonición (solo impacto FUTUREDUMMY), sin
reparar ficticiamente sus huecos nativos. No añadir la salida de halo de Rayo Fusión
al grupo de cuerpos recortados: PNG f15 mantiene cuerpo/núcleo visibles, no confirma
un defecto de cámara.

Bloque 7: Supernova Original tiene un Mew fijo en su cinematografía de estrellas/ADN
(back f50); duda artística secundaria de uso con usuarios aleatorios, ambos lados.
Lanza Glacial front necesita cotejar trayectoria/contacto: lanza separada en f16,
punta junto al contorno en f17, fragmentos sí rodean al objetivo en f18/f20. No
declarar impacto totalmente ausente. Cólera del Guardián termina con objetivo
visible a opacidad 0,88235 (ambos f65), leve transparencia antes de limpieza PASS;
contrastar fuente/final de fase, no confundir con celda extra ni cuerpo desaparecido.
Granizo conserva su contexto de clima ya conocido, no una nueva pérdida de atlas.
Se mantiene la decisión previa de Martillo Colosal; Prensa Metálica conserva
HEAVYSLAM e Infortunio SPITE como equivalentes explícitos, sin reparar huecos nativos.

Bloque 8: Hidrovórtice Abisal físico/especial front deja capas rectangulares
parciales durante la transición: gris en f3, franja inferior en f7 y ola superior
en f12. Cotejar export OppMove/fases/capas frente a back antes de atribuirlo al
renderer; ambos IDs DATA_ONLY intactos. Cola Férrea no añade contornos dobles:
PNG nativo f4 ambos lados muestra una sola silueta blanca. Defensa Férrea front
f5 tampoco demuestra cuerpo desfasado. Las cuatro variantes de Garrote Liana
están incluidas, ocho clips; no son máscaras nuevas ni nuevas rutas de combate.

Bloque 9: Capa Mágica front duplica Charizard junto a Ogerpon (f7); Pantalla de Luz
front desplaza a Ogerpon de su sombra (f20, cuerpo en 242/254,6). Aguzar f23 tiene
cuerpos base del usuario con escalas distintas, ambos lados; Danza Lunar f9 los
desplaza levemente y Levitón f14 mantiene cuerpo gris elevado y normal superpuestos.
Guardar para diagnóstico conjunto de objetivo propio, sin borrar todos los ecos.
Somanta Amistosa incluye Mimikyu fijo (ambos f76), duda artística secundaria para
usuarios aleatorios, no fallo del renderer probado. Ciclón de Hojas no duplica
objetivo en PNG front f22/f25; Patada Baja front f4/f5/f6 no confirma pie separado.
Consulta adicional de estados de cuerpos guía ampliaciones, no modifica el plan
ni convierte diferencias de posición/escala en defectos automáticos.

Bloque 10: Escudo Tatami front desplaza a Ogerpon de su sombra (f7), como Pantalla
de Luz; Maxichorro front repite la transición parcial de HYDROVORTEX (f7), mismo
grupo que Hidrovórtice físico/especial, conservando ID propio. Meditación ambos
f4 superpone un cuerpo normal y otro aplastado 37,5 px más abajo. Reducción ambos
f3 tiene dos cuerpos base de distinta escala y un eco extra: cotejar la coreografía
antes de borrar ecos deliberados. Legado no añade deuda por el aviso de opacidad:
cuerpos base presentes/opacos al acabar, celda extra del objetivo a 0,54902.
Los 19 Maxi mantienen equivalentes explícitos; Maxinsecto conserva SILVERWIND y
su front sintetizado declarado. No son animaciones Max nativas ni mecánicas nuevas.

Bloque 11: Luz Lunar ambos f15 superpone dos cuerpos base separados 11,25 px en
vertical; Bastión Final ambos f9 superpone cuerpo amarillo y normal separados
22,5 px en horizontal. Última Palabra deja vacía la plaza del usuario tras salir
(ambos f25); requiere presentar el relevo, DATA_ONLY intacto. Pesadilla conserva
sus dos copias laterales extra 2/3 del objetivo: no son el caso de cuerpos base
propios superpuestos. Adaptación incluye sus cinco referencias manuales, diez
clips, sin selección automática del entorno. Rayo Umbrío/Ala Mortífera conservan
geometrías previas, sin nuevas sustituciones ni ampliación de mecánicas.
Bloque 12: Picotazo Veneno front f14 y Cola Veneno front f13 concentran partículas
a la derecha del objetivo; Latigazo front f6 separa el látigo del cuerpo que
retrocede. Bola de Polen front sí alcanza al objetivo con el proyectil f17,
pero su explosión f19/f21 aparece a la derecha: limitar la duda a esa fase y
conservar sus duraciones distintas (40 frames back / 30 front). Truco Fuerza
ambos f7 superpone cuerpo normal y azul ancho/aplastado, escalas relativas
1,45 X / 0,70 Y. Guardados para contraste de fuente/anclaje/coreografía, sin
diagnóstico causal ni corrección. Proliferación NO añade deuda: PNG f22 ambos
lados muestra impacto amarillo en el objetivo, entre las 16 muestras de lámina.
Láser Prisma conserva PSYBEAM explícito y native_gap_fixed=false; Géiser Fotónico
mantiene su motivo nativo de púas, no un nuevo dibujo del Pokémon.

Bloque 13: Danza Aleteo ambos f3 (30 px verticales), Polvo Ira ambos f13 (15 px)
y Pulimento ambos f12 (7,5 px) superponen dos cuerpos base propios opacos.
Anticipo front f12 y Reflejo front f16 desplazan a Ogerpon a (242,254,6) mientras
su sombra permanece en la plaza. Treparrocas ambos f20 recorta al usuario por
arriba en back y por abajo/izquierda en front; retorna al final. Seis IDs para
contraste, sin causa ni reparación certificadas. Danza Lluvia conserva contexto
externo de clima; Rugido necesita entrada tras expulsión: front acaba fuera de
pantalla aunque su bandera visible siga activa. Golpe Roca sí alcanza el objetivo
en front f7; no añadir ausencia de impacto por una fase previa de aproximación.

Bloque 14: Afilar ambos f2 superpone dos bases propias opacas a escalas relativas
0,75/1. Cara Susto front f9 sitúa la cara grande a la derecha del objetivo;
Sombra Vil front f20 desplaza el óvalo de sombra/destello al lateral, sin afirmar
impacto totalmente ausente. Guadaña Sedosa físico/especial incluye otras especies
fijas (ambos f32), dos dudas artísticas secundarias; no sustituir ahora sus recursos Z.
Tormenta de Arena conserva contexto externo de clima y shed_tail necesita presentar
sustituto/relevo, sin usuario perdido: sus cuerpos permanecen al final. Daño Secreto
incluye las cinco referencias manuales, diez clips; alerta psíquica de final oculto
solo de celda extra 2, cuerpos base presentes/opacos. Arañazo sí tiene trazos amarillos
en ambos f3, y Simún f16 sitúa el remolino a la izquierda en ambos lados; no añadir
falsos vacíos ni desfases unilaterales por esas miniaturas/fases.

Bloque 15: Relajo ambos f8, Robo ambos f4 y Salpicadura ambos f3 superponen dos
bases propias opacas con distinta posición/escala. Relajo back tiene desfase leve
de 1,875 px; front separa cuerpo normal y aplastado 16,875 px. Residuos front f16
sitúa burbujas a la derecha; Onda Tóxica front f14 muestra la ola desde arriba con
cresta hacia abajo, pendiente contraste de orientación/capas frente a back.
Constelación Robaalmas ambos f48/f50 recorta al usuario en bordes durante impacto,
posición fija f48–51 y retorno final; cotejar encuadre/coreografía sin declarar
usuario perdido. Paisaje Nevado conserva presentación externa conocida de clima.
Chorro de Vapor ambos f60 sí tiene estallido y reacción rojiza tardía; no añadir
impacto totalmente ausente por las fases anteriores. Conservar 74/77 frames.

Bloque 16: Llave Corsé ambos f20 recorta al objetivo durante lanzamiento por
derecha en back e izquierda/abajo en front; trayectoria alcanza fuera de pantalla
en f19 y vuelve a plaza f23/final f25. Contrastar encuadre/coreografía, no retirada
definitiva. Surf front f14, masa de agua desde arriba/cresta hacia abajo, como
contraste de orientación de Onda Tóxica, sin causa común probada. Sustituto ambos
f5 sí dibuja el muñeco; f13 vuelve a cuerpo sin muñeco persistente, transición
externa pendiente. Día Soleado actual tiene pulso amarillo visible f8 y opacidad
de capa 0→200→0; no arrastrar la antigua ausencia de capa ni afirmar reparación
en este tramo. Tragar f15/f16 no confirma doble silueta pese a diferencia mínima
de escala Y (1,20/1,19); Plumerazo f3 sí muestra trazo gris fino en ambos lados.
Picado Supersónico físico/especial mantiene SKYATTACK explícito y su hueco Z abierto.

Bloque 17: Limpieza General ambos f2 muestra contornos dobles del usuario, bases
propias opacas separadas 7,5 px verticales. Relámpago Súbito front f9 separa el
destello de Ogerpon; back lo superpone a Charizard. Derribo recorta al usuario
por arriba en back f8 y abajo/izquierda en front f9, con retorno final f19:
contrastar encuadre/coreografía antes de declarar fallo. Teletransporte mantiene
usuario visible f20: se oculta base0, base1 sigue opaca, no plaza vacía demostrada;
requiere contexto de retirada/relevo. Transformación vuelve a la misma especie
tras el blanco f7–11, necesita sustitución externa de apariencia. Sin reparaciones.

Bloque 18: Danza Triunfal ambos f2 superpone bases propias separadas 15 px
verticales y laterales; Avivar ambos f4 superpone base roja elevada 15 px y normal.
Ataque Ala front f5 separa arcos del objetivo; Abatidoras front f18 separa humo.
Láser Doble front f20/f27 roza el borde derecho con haz/orbes descentrados frente
a back: contrastar contacto, sin declarar impacto totalmente ausente. Ida y Vuelta
final f27 y Voltiocambio f25 dejan plaza del usuario vacía; necesitan relevo.
Remolino conserva GUST explícito y ambos cuerpos finales presentes, necesita
contexto de expulsión/entrada. Llave Vital f19/f20 deja estrella mientras objetivo
retrocede en ambos lados: no nuevo desfase unilateral. Shuriken de Agua front f11
sí toca cabeza. Sin reparaciones durante el barrido ni sustituciones nuevas.

**0 IDs restantes del barrido ampliado**, con **93 casos acumulados** de
contraste/contexto, no 93 bugs confirmados. Siguiente fase: diagnosticar por causas
comunes, empezando por cuerpos propios duplicados y anclas/impactos frontales.
Conservar la evidencia original; comprobar una causa antes de aplicar arreglos
en lote, con comparación antes/después y protección de ecos intencionales.

Herramientas nuevas de planificación/captura/selección y registro por clip;
**61 tests Python PASS en el tramo anterior**, incluida cobertura de variantes, pares, duplicados,
muestreo y registros mixtos. Evidencia bloque 1:
`batch_01_4cf3260effe18266/result.json` y `sheets/boards.json` bajo la generación.
Bloque 2: `batch_02_10a1e33372afa525/result.json` y `sheets/boards.json`.
Bloque 3: `batch_03_e38f080272506981/result.json` y `sheets/boards.json`.
Bloque 4: `batch_04_1079a5033beb90ec/result.json` y `sheets/boards.json`.
Bloque 5: `batch_05_2d69da14cc4d3101/result.json` y `sheets/boards.json`.
Bloque 6: `batch_06_f35e7337d8d5fa4d/result.json` y `sheets/boards.json`.
Bloque 7: `batch_07_bdcca293bf7e0494/result.json` y `sheets/boards.json`.
Bloque 8: `batch_08_893feae099e0ac4f/result.json` y `sheets/boards.json`.
Bloque 9: `batch_09_9714ca1f03cfdad5/result.json` y `sheets/boards.json`.
Bloque 10: `batch_10_8a14891a453467f5/result.json` y `sheets/boards.json`.
Bloque 11: `batch_11_cd63d28ef7302e9e/result.json` y `sheets/boards.json`.
Bloque 12: `batch_12_a63b37636b784d0e/result.json` y `sheets/boards.json`.
Bloque 13: `batch_13_7278a2576c29cd40/result.json` y `sheets/boards.json`.
Bloque 14: `batch_14_ec10470a5f9268c2/result.json` y `sheets/boards.json`.
Bloque 15: `batch_15_cd00d3a51c3f0d2b/result.json` y `sheets/boards.json`.
Bloque 16: `batch_16_04b20632f90276f1/result.json` y `sheets/boards.json`.
Bloque 17: `batch_17_646e014ce71e52f7/result.json` y `sheets/boards.json`.
Bloque 18: `batch_18_c117b669d6cfdbec/result.json` y `sheets/boards.json`.
Ninguna herramienta ni test se ha editado en estos diecisiete últimos bloques; se reutiliza
el gate GPU y se añaden únicamente evidencia/notas y memoria documental.
No es reproducción observada a velocidad real ni test de daño, objetivo o estado.
Detalle y reglas de continuación en NEXT_STEPS y cuaderno VISUAL_CATALOG.

Auditoría de continuidad al cerrar el bloque 12 tras el corte de contexto: doce carpetas de bloques,
doce reportes GPU PASS, 244 láminas con SHA válido y cobertura exacta de sus
1.214 clips en 336 anotaciones. Ningún bloque generado a medias, página sin
registro o clip ajeno al plan. Los primeros 310 registros siguen idénticos;
el bloque 12 añadió 26 entradas. Se completó la actualización documental que
faltaba. Entonces quedaban bloques 13–18 por generar/revisar, no trabajo perdido.
Validación focal de todos los PNG del bloque 12 PASS; fuentes, datos y HEAD intactos.
Continuación del bloque 13: 34 entradas nuevas, 370 acumuladas, preservados los
336 registros anteriores. Sus 20 láminas y 100 clips están registrados completos;
fuentes, plan, datos y HEAD siguieron intactos. Después quedaban bloques 14–18.
Bloque 14: 34 entradas más, 404 acumuladas, prefijo de 370 intacto; cobertura
completa de sus 108 clips y 22 láminas. Fuentes, datos, plan y HEAD intactos.
Después quedaban bloques 15–18, 200 IDs.
Bloque 15 añade 32 entradas, 436 acumuladas, prefijo de 404 intacto; sus 100 clips
y 20 láminas están registrados completos. Entonces quedaban bloques 16–18, 150 IDs.
Bloque 16 añade 25 entradas, 461 acumuladas, prefijo de 436 intacto; sus 100 clips
y 20 láminas están registrados completos. Entonces quedaban bloques 17–18, 100 IDs.
Bloque 17 añade 29 entradas, 490 acumuladas, prefijo de 461 intacto; sus 100 clips
y 20 láminas están registrados completos. Entonces quedaba bloque 18, 50 IDs.
Bloque 18 añade 33 entradas, 523 acumuladas, prefijo de 490 intacto; sus 100 clips
y 20 láminas están registrados completos. Los 18 bloques tienen cobertura exacta;
sin bloques, láminas ni clips pendientes de registrar. Fuentes, datos, plan y HEAD intactos.

Catálogo, renderer nativo, sprites y cinco rutas visuales reales intactos; ningún
dataset/mecánica/IA/workflow modificado. Los 19 secundarios son recursos sin
etiqueta utilizable, no otros 19 clips terminados que haya que mirar uno a uno.
Sin descarga, sustitución, commit, push o merge. CI del HEAD previo no certifica
este trabajo local; se conserva la evidencia anterior con sus propios hashes.
Los 19 workflows SUCCESS de ese mismo HEAD se volvieron a comprobar el 2026-10-25.

## Antecedente: tres decisiones de arte cerradas, primera pasada completa — 2026-10-24

Registro humano de cambios solicitado por el usuario: `docs/project_book/VISUAL_SUBSTITUTIONS.md`.
Inventario de equivalencias vigente verificado: 34 IDs / 42 familias / 84 clips,
con historial y correcciones técnicas separadas. Toda sustitución futura se
documenta allí; crear el registro no ha cambiado imágenes, datos ni mecánicas.

**900/919 IDs / 1.822 clips / 911 familias / 29 shards**, solo laboratorio.
Cañón Armadura usa **FLAMEBURST**, sin el motivo rectangular de veneno de su
textura anterior; Maxibicho/Maxinsecto usa **SILVERWIND**, sin otros Pokémon
incrustados del anterior SAVAGESPINOUT. Son **dos equivalentes artísticos
explícitos adicionales**, NO reparación de fuentes ni dos mecánicas nuevas.
Los diez huecos nativos cubiertos por equivalentes y 19 secundarios se conservan.
Martillo Colosal mantiene su secuencia nativa de 23 frames: golpe/compresión y
esquirlas metálicas, sin dibujo de martillo literal; límite registrado.

Selección fija fuente original rechazada y alternativa por SHA completo;
ambos lados atómicos, sin recortar/repintar arte. UI distingue elección artística
de hueco de fuente, maneja metadatos inválidos y avisa que el Max histórico del
piloto de 70 clips está superado. Ese piloto y el pack de las cinco rutas reales
permanecen intactos. Prueba independiente: **1.818 contratos idénticos / cuatro
clips reemplazados**, fuentes/celdas/capas/roles/títulos/clasificaciones cotejados.

Barridos **5.397.041 headless / 5.412.459 GPU PASS**, 118.766 estados, 1.822
capturas técnicas. Regresiones PASS: combate 407, pantalla/capas 8.025, cámara
4.630, geometría 2.743, selector cinco y **57 tests Python**. Focal final de tres
familias **2.476 checks / 174 frames GPU PASS**, reloj/limpieza; dos láminas delta
y dos temporales observadas. Los otros 1.818 PNG/momentos/títulos idénticos.

Registro **1.822 anotados: 1.810 sampled_no_obvious_issue / doce
requires_external_presentation**, sin needs_motion_review/suspected_issue de la
cola señalada. Cierra la PRIMERA revisión por muestras; no certifica toda la
fluidez/arte de cada frame ni conecta 900 movimientos a combate. Siguen seis
integraciones externas pendientes y solo cinco rutas reales.

Pack `generation_66381a70b65ea385`; índice
`bb327ada0e33347980260a7e4a8af65e8622171002c64d3ecf56759aa92dbee1`.
Capturas `c673840caea21b70`; registro `sheets_20/index.md` dentro de esa generación.
Focal `.godot/move_temporal_checks/7be53573ed2e97d1/result.json`;
fuente `.godot/move_art_checks/bb327ada0e333479/sources.json`.
Contextos recompuestos para este índice: `08bf4875daf81fcf`; focal `466c9a2439f4f43e`
CPU/GPU PASS (6.442 / 8.048 checks), **1.164 píxeles-frame idénticos** al contexto
anterior; notas de sus cuatro láminas migradas por igualdad real de PNG.

Renderer nativo, datos canónicos, dominio, IA, workflows y biblioteca F: intactos.
Sin descargas/arte nuevo/commit/push/merge; 19 SUCCESS del HEAD previo comprobados,
no certifican estos cambios locales. Siguiente: inventario de conexión por
familias según soporte existente, no admisión masiva ni mecánicas nuevas.

## Antecedente: seis contextos visuales opcionales, no integración de mecánicas — 2026-10-24

Catálogo nativo intacto: **900/919 IDs / 1.822 clips**, mismo índice/renderer y
cinco rutas de combate. Fuentes revisadas juntas: Danza Lluvia, Granizo, Paisaje
Nevado, Fría Acogida, Sustituto y Transformación. **222 frames GPU / 2.653 PASS**,
dos láminas de ocho tiempos por lado observadas. No son seis atlas reparados:
las tres invocaciones de clima no dibujan precipitación; Transformación aporta
el destello; estado posterior depende de la presentación externa.

Nuevo modo **opcional, apagado por defecto**, solo en laboratorio. Reutiliza
Common:Rain/Hail/Snow y dos vistas originales del muñeco; no hay nuevo arte
generado ni descargado. Hail/Snow comparten exactamente el arte del pack, se
declara en UI. Muestra treinta frames adicionales (1,5 s) de contexto; Fría
Acogida conserva la retirada nativa. Transformación copia SOLO apariencia/vista
del rival bajo el destello en f8, gancho de demo declarado; no atributos. No cambia
PS, equipo, clima autoritativo, turnos, RNG, mecánicas o clasificaciones.

Recursos y doce bindings fijados por SHA; contexto obsoleto/clip ajeno se rechaza.
Muñeco colocado por límites alfa reales y pies; copia de aspecto usa el catálogo
y vista del lado correcto, sin espejar un frontal. Corregido fantasma al redimensionar
la UI pausada: restauración nativa diferida deshacía la sustitución; ahora se reaplica
el contexto después. Caso real añadido a la prueba y captura final inspeccionada.

Focal **6.442 headless / 8.048 GPU PASS**, **1.164 estados / 24 variantes** (seis
IDs, dos lados, dos arenas), cada frame capturado. Limpieza/toggle/scrub/filtro,
UI por defecto, imágenes sin duplicados, fuente intacta y prefijo GPU idéntico
salvo el gancho visual de Transformación. **55 tests Python PASS**, barrido nativo
headless **5.396.926 PASS**, combate 407, selector cinco. Cuatro láminas y UI final
observadas; muestras no certifican toda la película. Barrido GPU nativo previo
conserva validez por índice/renderer/runner idénticos; no se proclama una nueva
captura de los 1.822 clips ni certificación global de la worktree.

Registro **1.822 anotados: 1.804 sampled_no_obvious_issue / cuatro needs_motion_review /
dos suspected_issue / doce requires_external_presentation**. Tres dudas artísticas
(Cañón Armadura, Martillo Colosal, Maxibicho) + seis integraciones externas todavía
pendientes. Reetiquetar las seis NO las convierte en aprobadas o ejecutables.
Fuente de selección previa preservada en `fef7086e03940040/source_review_snapshot.json`.

Catálogo/capturas siguen `generation_97c85debdd57429f` / `582da8379b6b4de9`.
Contexto: `.godot/move_external_context/a2c3d4e515738f2f/context.json`.
Focal: `.godot/move_external_checks/5a810aa399c4aa7c/gpu/result.json` y `sheets/`.
Datos raw/normalized, dominio, IA, workflows y biblioteca F: intactos. Sin
commit/push/merge. HEAD previo y sus 19 SUCCESS comprobados; no certifican cambios
locales nuevos. El siguiente lote artístico son los tres IDs señalados arriba.

## Antecedente: encuadre del haz de Ala Mortífera corregido — 2026-10-24

**900/919 IDs reproducibles / 1.822 clips / 911 familias / 29 shards**. Sin más
movimientos conectados a combate: siguen cinco rutas, 19 etiquetas secundarias
en cuarentena y diez fuentes originales cubiertas por equivalentes explícitos.

Ala Mortífera: el ascenso desde f8 y regreso f27–30 son de la fuente. Su haz SÍ
tenía un defecto de adaptación: centro por cámara afín, base de la partícula
uniforme. Reproducido con oráculo de esquinas/centro, no por compartir PNG con
Rayo Umbrío. Ahora la base completa acompaña a la cámara, solo en sus dos exports
fijados por SHA del array. Renderer sin cambios; celdas, vuelo, hue140, capas,
hojas, 35 frames/20 fps, objetivo y clasificación conservados.

Geometría **FAIL antes / 2.743 PASS después**, dos haces, ambas vistas, tres
arenas y tres parejas de especies. Sonda GPU: **1.458 estados / 14.082 PASS**, seis
familias. En 640×360 el disco del objetivo pasa de ocho frames y pico 66 %/43 %
a **15 frames / 100 %**, igual que referencia; 400×300 pasa de doce a quince.
Ya solapaba la silueta quince frames antes: no se confunde alineación con daño
o «antes no acertaba». Referencia de puestos canónicos con nuestros sprites,
no captura del juego oficial/Essentials. Prueba de fuente: **1.820 contratos
idénticos / dos cambios exclusivamente de metadatos geométricos**.

Barridos **5.396.926 headless / 5.412.340 GPU PASS**, 118.998 estados, 1.822
capturas técnicas. Regresiones PASS: combate 407, pantalla/capas 8.025, cámara
4.630, selector cinco y **53 tests Python**. Temporal final **2.142 checks / 70
frames GPU PASS**, reloj/limpieza; observadas dos láminas delta, ocho momentos
por lado y capturas nativas de ambas cámaras. No es aprobación de toda la película.

**1.822 anotados: 1.804 sin fallo evidente en muestras / diez necesitan contexto-
movimiento / ocho sospechosos: dieciocho clips apartados de nueve IDs**. Las
1.820 capturas/momentos/títulos restantes son idénticos y sus notas se conservan.
Siguiente: las seis presentaciones externas juntas; después tres asuntos de arte.

Pack `generation_97c85debdd57429f`; índice
`cd2ac8ce68742e8c285d0ac6088abe093817ed98732f7461478da230a6f554ae`.
Capturas `582da8379b6b4de9`; registro
`.godot/move_contact_review/582da8379b6b4de9/sheets_20/index.md`.
Sonda `.godot/move_trajectory_checks/38d5789d80e3e643/result.json`;
temporal `.godot/move_temporal_checks/ccdea9d8b1063905/result.json`.
Fuentes/pruebas en cuaderno. Datos canónicos, mecánicas, UI, IA, workflows y
biblioteca F: intactos. Sin commit/push/merge; HEAD y sus 19 SUCCESS remotos
verificados antes de editar, no certifican estos cambios locales.

## Antecedente: Láser Prisma cambia a un equivalente más adecuado — 2026-10-24

Se mantienen **900/919 IDs reproducibles / 1.822 clips / 911 familias / 29 shards**,
19 etiquetas secundarias en cuarentena y diez incidencias originales cubiertas
por equivalentes explícitos, NO reparadas. Solo cambia la referencia artística
de **Láser Prisma: PHOTONGEYSER → PSYBEAM**, ambos exports fijados por SHA completo.
Anillos psíquicos equivalentes, no el láser nativo. Cinco rutas reales de combate
sin cambios; ninguna mecánica nueva.

La figura enorme de f44 procede de **un pico del atlas del efecto**, patrón 23
con zoom 317×442 %, no de una deformación de los sprites de Pokémon: los cuerpos
siguen al 100×100 %. Se rechaza para este sustituto; Géiser Fotónico original
permanece intacto. Comparativa previa: 164 frames GPU de cuatro clips; láminas de
ocho tiempos por lado y f44 a resolución nativa observados. Nueva referencia:
25 frames a 20 fps (1,25 s), cadencia del efecto, no cambio en reglas/turnos.

Prueba independiente: **1.820 contratos previos idénticos**, únicamente dos clips
sustituidos; celdas, capas, gráficos, roles, título, objetivo y clasificación
cotejados con fuente inerte. Conserva `missing_pattern:11`, `native_gap_fixed=false`
y `mechanics_enabled=false`. Capturas y muestras de esos 1.820 clips idénticas,
revisiones migradas por prueba, no por cercanía de página.

Barridos **5.396.926 headless / 5.412.340 GPU PASS**, 118.998 estados frame/lado/
arena; 1.822 capturas técnicas. Regresiones: combate 407, pantalla/capas 8.025,
cámara 4.630, haz 1.372, selector cinco y **49 tests Python PASS**. Comparación
focal final **2.242 checks / 100 frames GPU / cuatro clips PASS**, reloj y limpieza
incluidos; peticiones duplicadas o desconocidas rechazadas antes de capturar.

Dos láminas delta y dos temporales finales observadas. **1.822 anotados: 1.802
sin fallo evidente en muestras, 12 necesitan contexto/movimiento y ocho
sospechosos; veinte clips apartados / diez IDs**. No equivale a ver cada frame a
velocidad real ni a aprobar toda la animación o sus mecánicas.

Pack `generation_7db488fb7d72d2de`; índice SHA
`9915078aee64b7db908e5ad303961d3e52dcbe6dae5d406c68c3d371a38c9518`.
Capturas **`b762b7d359665bfc`**; registro
`.godot/move_contact_review/b762b7d359665bfc/sheets_20/index.md`.
Temporal final `.godot/move_temporal_checks/5459bd9cffc51881/result.json`;
prueba `.godot/move_equivalent_checks/replacement_9915078aee64b7db.json`.
Fuentes, evidencias anteriores y límites en cuaderno VISUAL_CATALOG.

Renderer/UI, datos canónicos, mecánicas, IA, workflows y biblioteca F: intactos.
Sin commit/push/merge. HEAD sigue `0902de4c10d34a2a451c9acad83fbfea765ef270`,
rama `fix/map-runtime-hardening-v1`; sus 19 checks remotos SUCCESS se comprobaron
antes de editar y NO certifican estos cambios locales ni la worktree preexistente.

## Antecedente: diez huecos cubiertos por equivalentes explícitos — 2026-10-24

**900/919 IDs reproducibles en laboratorio, 1.822 clips / 911 familias / 29 shards**.
Se añaden diez alternativas explícitas para los ocho movimientos con atlas
incompletos y los dos fondos ausentes. **No se reparan ni se borran esas diez
incidencias de la fuente original.** Quedan 19 IDs sin referencia reproducible,
las etiquetas Let's Go/Torque/Z especial de baja prioridad. Los equivalentes
previos del conjunto prioritario se siguen documentando aparte; no interpretar
«900» como 900 animaciones nativas ni 900 mecánicas completas.

Fuentes del mismo pack: Pájaro Osado y dos Picado Supersónico → Ataque Aéreo;
Infortunio → Rencor; Láser Prisma → Géiser Fotónico; Descanso → Sonámbulo;
Ciclón → Vendaval; Remolino → Tornado. Premonición usa su export FUTUREDUMMY,
**solo impacto, no preparación/espera**. Truco Floral conserva todas sus celdas
y tiempos y sustituye únicamente uwu.png por el fondo Petal BG. No hay nuevo arte
dibujado ni descargado, sustituciones silenciosas, partículas ocultadas o datos
de combate modificados. Tabla y límites en cuaderno.

Selecciones fijadas por SHA de export completo; solo se aplican al error original
exacto. Si la fuente nativa se convierte, gana sobre la alternativa. Las dos
vistas son atómicas. Índice, clips, informe y UI dicen EQUIVALENTE VISUAL y conservan
el motivo original. Nunca marcan native_gap_fixed o mechanics_enabled como true.

Prueba independiente: **1.802 contratos previos intactos**, veinte clips nuevos,
1.480 estados frame/lado/arena de referencia, celdas/capas/cadencia/hojas/roles/
clasificaciones conservados. Barridos **5.403.992 headless / 5.419.406 GPU PASS**,
119.126 estados; UI comprueba los veinte rótulos y metadatos malformados sin crash.
Regresiones: prioridad 445.698, combate 407, pantalla 8.025, cámara 4.630, haz 1.372,
selector cinco y **45 tests Python PASS**.

Dos láminas delta observadas. **1.822 clips anotados: 1.800 sin fallo evidente en
muestras, 14 necesitan movimiento/contexto y ocho sospechosos: 22 apartados /
once IDs.** Se añade Láser Prisma, ambos lados, por la silueta muy aumentada/
estirada de Géiser Fotónico en f44: idoneidad del sustituto pendiente, no fallo
confirmado del conversor. No reabre automáticamente el movimiento original.
Los otros diez IDs apartados y sus notas se conservan; no se aprueba fluidez o
sincronización por tres muestras. Los 1.802 PNG/muestras anteriores son idénticos.

Pack `generation_f5531ada8334529b`; índice SHA
`44c5c0cbf81d5cf9a130c161167ec768e6eb87f84febd744f4d1a86e192a1529`.
Capturas **`b6183b56e397801b`**; registro
`.godot/move_contact_review/b6183b56e397801b/sheets_20/index.md`.
Renderer, cinco rutas de combate, datos canónicos, mecánicas, IA, workflows y
biblioteca F: intactos. Cambia solo el catálogo visual/QA y el rótulo informativo
del laboratorio. Sin commit/push/merge/CI nueva; CI del HEAD previo no certifica
los cambios locales.

## Antecedente: diagnóstico de atlas/fondos y cuatro recuperaciones — 2026-10-24

Investigado el grupo de ocho patrones/cinco hojas y el modo de celda pendiente.
Recuperados **Estruendo Implacable, Gigaimpacto, Lengüetazo y Resplandor**, ambos
lados: **890/919 IDs para laboratorio, 1.802 clips / 901 familias / 29 shards**.
Quedan **29 excepciones de conversión**: 19 etiquetas de baja prioridad, ocho
movimientos afectados por cinco atlas realmente incompletos y dos fondos ausentes
(`flower_trick`: `uwu.png`; `future_sight`: `PRAS- Darkness BG.png`). No se añaden
celdas vacías ni se duplican patrones ni se ocultan partículas para aparentar cierre.

Dos PNG suplementarios fijados por SHA/commit, 46.501 bytes originales, solo caché
ignorada: hoja blanca y corrección rival de Gigaimpacto publicada por geefuoco en
PokéRogue. El fondo rival de 256×192 se adapta por réplica entera ×2 a 512×384;
no dibujo nuevo ni cambio de colores. Créditos/procedencia/condiciones en cuaderno.
Lengüetazo omite SOLO un nombre de fondo inexistente que nunca es visible durante
sus 15 frames. Estruendo normaliza prioridad 4 a 1 SOLO en dos exports fijados por
hash: ambas equivalen a z80 según el fallback original, no una prioridad inventada.

Focal independiente **4.666 PASS**, todos los frames nuevos/dos arenas; 589.824
comparaciones de píxeles de proveedor y 1.968 campos de prioridad comprobados.
Los **1.794 contratos y tiras GPU anteriores permanecen idénticos**. Barridos
completos **5.334.273 headless / 5.349.507 GPU PASS**, 117.646 estados frame/lado/
arena. Regresiones: prioridad 445.698, combate 407, pantalla 8.025, cámara 4.630,
haz 1.372, selector cinco y **41 tests Python PASS**.

Dos láminas delta observadas, ocho clips nuevos sin fallo evidente en tres muestras.
**1.802 clips anotados: 1.782 sin fallo evidente, 12 necesitan movimiento/contexto
y ocho sospechosos: 20 apartados / diez IDs**, sin cambios en esa cola. No se
certifica una película continua ni todas las mecánicas. 1.794 notas conservadas
por prueba individual; las ocho nuevas proceden de las dos láminas observadas.

Pack `generation_f2709ae56368fe60`; índice SHA
`05200ba888a068878464a4eba5097305951ae3309435deb2a993f17782a3aa4b`.
Capturas **`493b98955b31aa33`**; registro
`.godot/move_contact_review/493b98955b31aa33/sheets_20/index.md`.
Renderer, cinco rutas de combate, mecánicas, IA, raw/normalized, workflows y
biblioteca F: intactos. Sin commit/push/merge/CI nueva; la CI del HEAD previo
no certifica estos cambios locales.

## Antecedente: 30 movimientos recuperados por hue, en lote — 2026-10-24

Resuelto el grupo `unsupported_hue` completo: **886/919 IDs convertidos para
laboratorio, 1.794 clips / 897 familias / 29 shards**. Quedan **33 excepciones de
conversión**: 19 etiquetas ausentes/ambiguas, ocho patrones, cinco hojas y un modo
de celda. No confundirlas con la cola visual de recursos que sí se convierten.

El color se hornea SOLO en copias derivadas de las hojas de efectos: HSV entero
en grados, sin remuestreo y con alpha/dimensiones exactos. Nada de teñir cuerpos
o fondos globalmente ni ignorar el hue. Conservados exactamente los 1.734 clips,
dependencias y tiras GPU previos. De los 60 exports nuevos, uno tiene hue cero
en la propia fuente (`meteor_assault/front`); se conserva, no se iguala por gusto.

Prueba independiente: **38.707.200 píxeles alpha exactos**, 28 combinaciones
hoja/hue, 114.688 muestras RGB contra HSV de Godot, **458.838 checks PASS**.
Barridos completos: **5.298.025 headless / 5.313.187 GPU PASS**, 116.998 estados
frame/lado/arena. Regresiones PASS: prioridad 445.698, combate 407, pantalla 8.025,
cámara 4.630, haz 1.372, selector cinco; **34 tests Python PASS**.

Cuatro láminas delta vistas, 30 familias/ambos lados. **1.794 clips anotados:
1.774 sin fallo evidente en muestras, 12 necesitan movimiento/contexto y ocho
sospechosos: 20 apartados / diez IDs.** Se añade solo `oblivion_wing` por ambos
lados para contrastar ascenso fuera de pantalla, retorno y haz en movimiento;
no defecto confirmado ni permiso para copiarle la reparación de Rayo Umbrío.
Los nueve casos anteriores y sus excepciones se conservan sin reabrirlos.

Pack `generation_130268d20a3cf430`; índice SHA
`44e83333eef36d88bc79924aa2be73759c857d5e3bd510fa3c2b46eb2f6e97cc`.
Capturas **`a5a29f4db6b47005`**, registro
`.godot/move_contact_review/a5a29f4db6b47005/sheets_20/index.md`.
Tras reagrupar, notas conservadas por clip con renderer/snapshot, fuente completa,
PNG reales y muestras GPU idénticos; jamás se aprueban sus nuevos vecinos.
Las 60 anotaciones nuevas proceden de las cuatro láminas delta observadas.

Renderer, cinco rutas de combate, mecánicas, IA, datos canónicos, workflows y
originales F: intactos. Sin commit/push/CI nueva: la CI del HEAD anterior no
certifica estos cambios locales. Detalles y comandos en el cuaderno visual.

## Antecedente: contraste de cinco trayectorias y geometría del haz — 2026-10-24

Comparados juntos Orbes Espectro, Cañón Dinamax, Rayo Infinito, Rayo Umbrío y
Cuchilla Solar: diez clips, tres cámaras, todos los frames (**1.248 estados /
13.655 comprobaciones GPU PASS**). Referencia con puestos canónicos fijos,
no captura de un juego oficial. Máscara de silueta/ancla es diagnóstico visual,
NO prueba de impacto mecánico o daño. Láminas incluyen automáticamente el pico
de solapamiento para no saltarse el breve cruce de Cuchilla Solar f16/f17.

Corregida SOLO la geometría de Rayo Umbrío, dos exports fijados por hash. Antes
se adaptaba el centro pero no la forma del haz oblicuo; ahora toda su base sigue
la misma transformación de cámara. Cobertura del ancla en 640×360: de 8/35
frames (pico 66 %/43 %) a 15/35 y pico 100 % ambos lados, igual que referencia.
Focal independiente de esquinas: antes FAIL / después **1.372 PASS**, todos los
frames/tres arenas/tres parejas. No se cambian dibujos, celdas, tiempos o cuerpos.

Las otras cuatro dudas espaciales quedan aclaradas por contraste y muestras:
Orbes llegan al objetivo; los dos grandes haces ya son enormes en la fuente;
Cuchilla Solar sí cruza la silueta brevemente. No se certifica gusto artístico,
fluidez completa ni sincronización de daño por esto. **1.734 clips anotados:
1.716 sin fallo evidente en muestras, diez necesitan contexto/movimiento y ocho
sospechosos: 18 apartados / nueve IDs.** 856/919 IDs convertidos; 63 excepciones
siguen pendientes. Restan seis presentaciones externas y tres decisiones de arte.

Barridos finales: **5.108.930 headless / 5.123.576 GPU PASS**, 112.934 frame/lado/
arena; siete rechazos nuevos de declaraciones afines inválidas. Regresiones:
prioridad 445.698, combate 407, pantalla 8.025, cámara previa 4.630, selector cinco;
27 tests Python PASS. Sin nuevas rutas de combate ni mecánicas.

Pack `generation_919cbce496ac8777`; capturas **`de7c04174963c920`**. Comparación
completa de entradas de dibujo (incluye matriz/skew): otros **1.732 clips
equivalentes en todos los frames/dos arenas**. Conservadas sus notas con fuente,
hojas, PNG/muestras y prueba fijada; solo cambian las dos tiras de Rayo Umbrío,
observadas de nuevo. Limpieza del skew evita contaminar el siguiente clip.
Registro `.godot/move_contact_review/de7c04174963c920/sheets_20/index.md`;
comparaciones `.godot/move_trajectory_checks/885e8512d3f02db4/`.

Fuentes/datos/F: y workflows intactos en este tramo. Sin commit/push/CI nueva.
Detalles, límites y cola de nueve en el cuaderno visual. No reabrir las cinco
trayectorias como fallos de conversión sin evidencia nueva; hue de 30 IDs es el
siguiente grupo masivo de la cola de 63.

## Antecedente: revisión temporal agrupada y anclas rígidas — 2026-10-24

Capturados/comprobados los **1.300 frames de 34 clips / 17 IDs apartados**, antes
y después del ajuste, con ocho tiempos por clip en cuatro láminas. Distinguir
captura completa de revisión temporal muestreada: no se ha observado una película
continua ni se certifica toda la fluidez. Reloj de 20 fps y limpieza: 5.879 PASS.

Corregidos SOLO `malignant_chain/front` (cadenas) y `chilly_reception/front`
(bocadillo): 180 campos de foco + metadatos, exports fijados por hash. Anclas
rígidas, no estirar la separación entre piezas; hielo intacto. Otros 1.732 clips
y renderer global idénticos. Focal antes FAIL / después **4.630 PASS GPU**, todos
los frames/dos arenas/tres parejas. Descartado un primer candidato afín que abría
huecos en las cadenas; no es el catálogo vigente.

Cerradas dudas de restauración de Llama Final/Electropalmas (el oscurecimiento
de 3,05 s está en la fuente y termina con cuerpos/tono/opacidad restaurados) y
colocación de Cadena Virulenta. No se acortan animaciones por gusto. Fría Acogida
sigue apartada por clima/retirada externos, no por el bocadillo ya corregido.
**1.734 clips anotados: 1.706 sin fallo evidente en muestras, 20 necesitan
movimiento/contexto y ocho sospechosos: 28 apartados / 14 IDs.** No aprobación
general de arte/mecánica. 856/919 IDs convertidos; **63 excepciones** sin cambio.

Barridos finales: **5.108.923 headless / 5.123.569 GPU PASS**, 112.934 frame/lado/
arena. Regresiones: prioridad 445.698, combate 407, pantalla 8.025, selector cinco,
22 tests Python PASS. Las cinco rutas de combate, datos, IA y workflows no cambian.

Catálogo `generation_602a92ba9cd5dee8`; capturas **`799684ccaf13e9d0`**. Solo dos
tiras/páginas cambian; 86 páginas idénticas conservaron 1.694 anotaciones con
prueba por contratos/hojas/muestras/renderer. Páginas 01/08 front vistas de nuevo.
Secuencia final `.godot/move_temporal_checks/b40991f55c3e7b6c/`: solo 36 de sus
1.300 imágenes difieren del baseline (once bocadillos, 25 frames de cadenas);
otras 32 secuencias idénticas. Las dos láminas temporales front cambiadas, vistas.

Registro vigente `.godot/move_contact_review/799684ccaf13e9d0/sheets_20/index.md`.
F: y fuentes/arte originales intactos. Sin commit/push ni nueva certificación CI.
Siguiente: cinco puestas en escena de trayectoria, seis presentaciones externas,
tres decisiones de arte/equivalencias; hue de 30 IDs sigue como grupo separado.

## Antecedente: transiciones de capas y partículas de pantalla — 2026-10-24

Corregidas dos causas compartidas: Set BG/FG borraba fades ya programados y los
movimientos sobre el propio usuario reducían partículas de pantalla a escala cero.
Día Soleado recupera iluminación/fade; Deseo recupera estrellas. También vuelven
a verse partículas de Sustituto, Mismo Destino y Novena Potencia. No se redibuja
arte ni se implementan sus mecánicas. Sustituto sigue apartado para revisar la
transición externa del muñeco/cuerpo; no se declara completa por ver su textura.

Estado visual vigente: **1.734 clips anotados, 1.700 sin fallo evidente en las
muestras, 26 necesitan movimiento y ocho sospechosos: 34 apartados / 17 IDs**.
Cero pendientes del primer vistazo estático, NO aprobación de fluidez o mecánica.
Las **63 excepciones de conversión** no cambian: 856/919 IDs convertidos.

Focal antes FAIL / después **8.025 PASS GPU**; barridos completos **5.108.923
headless / 5.123.569 GPU PASS**, 112.934 frame/lado/arena. Regresiones: selección
prioritaria 445.698 PASS GPU, combate comunitario 407 PASS, cámara 1.678 headless /
1.684 GPU PASS, selector cinco y 17 tests Python PASS. No nueva certificación de CI.

Generación de catálogo `generation_12f04d8d133befc0`, capturas **`a3427d2cdeb633d9`**.
Comparación de todos los frames en dos arenas: 1.678 clips con entradas visibles
de dibujo equivalentes, 56 distintos. Cambian 52 contratos de capas y 60 tiras
muestreadas (también puede cambiar el frame elegido). Conservadas **1.674** notas
solo con prueba por clip, fuente/hojas completas, GPU y hashes; no se hereda una
lámina nueva entera por contener un vecino equivalente. Cuatro láminas delta de
31 familias / 62 clips observadas de nuevo (60 cambios y dos lados de contexto).

Registro actual: `.godot/move_contact_review/a3427d2cdeb633d9/sheets_20/index.md`;
comparación y snapshots fijados en esa generación, láminas vistas en
`delta_sheets_20/`. Antecedentes de generaciones previas conservados más abajo.
Datos canónicos, cinco rutas de combate, reglas, F: y workflows sin cambios en
este tramo. Sin commit/push. Detalles y reproducción en el cuaderno visual.

## Antecedente: barrido primero y revisión visual reanudable — 2026-10-24

Repetido el barrido completo antes de preparar láminas: 5.108.923 PASS headless,
112.934 fotogramas/lado/tamaño, cero fallos fatales. Mismo índice de 856 IDs /
1.734 clips; las 63 excepciones de conversión no se representan como funcionando.

Nueva captura GPU fuera de pantalla: 5.202 vistas (tres momentos por clip),
1.734 tiras a resolución nativa. Composición automática en **44 lotes, 88 láminas**
de hasta 20 familias de animación y dos lados. Hay 867 familias por los contextos
y variantes existentes, no nuevas especies/movimientos. Los 41 IDs con avisos
van primero. Registro persistente de estado/notas, ligado al hash de cada lámina:
no se dan por revisadas las páginas no abiertas ni se reutiliza una revisión con
imágenes distintas. Admite diez por lote sin volver a capturar en GPU.

**Primer barrido de láminas completo: lotes 01–44, ambos lados, 1.734 clips /
5.202 muestras.** 1.696 sin fallo evidente en las muestras, 30 necesitan revisar
movimiento y ocho son sospechosos de presentación/artísticos. Los 38 apartados
corresponden a 19 IDs por ambos lados, NO 38 defectos
confirmados. Cero clips convertidos pendientes de este primer vistazo; NO es
aprobación de movimiento completo, sincronía o mecánica. Los 63 IDs en cuarentena
de conversión siguen fuera de las láminas y pendientes, no se dan por validados.

Corregida la familia de desplazamientos de Hipertaladro, Patada Giro y Palma
Rauda SOLO rival. Adaptación de foco de partículas en tres exports fijados por
SHA-256, no heurística global ni cambio de dibujos/mecánicas. Solo 147 campos de
foco en tres clips generados y metadatos de auditoría; otros 1.731 clips idénticos.
Prueba focal antes FAIL / después 1.684 PASS GPU: todos los frames, dos arenas,
tres parejas de especies. Barridos completos: 5.108.923 headless / 5.123.569 GPU
PASS. Regresiones: laboratorio 444.847 / combate comunitario 407 PASS; 13 tests
Python y cinco del selector PASS.

Capturas nuevas: `84cfcc27cf596d4c`, pack `generation_754ad3a47d8239f2`.
Solo cambian las tres tiras rivales y las láminas 20/32/42 front; vistas de nuevo.
85 láminas idénticas conservan 1.674 anotaciones mediante prueba por clip/hojas/
muestras GPU y renderer idénticos, con índice anterior fijado. Sin heredar las
imágenes cambiadas. Se conserva el historial anterior, no se reinicia el catálogo.

Antecedentes del barrido 21–44 (previos a la corrección de foco): Patada Giro y
Palma Rauda SOLO rival se sumaban al contraste de
foco/cámara con Hipertaladro rival. Maxibicho usa una referencia con otros Pokémon
integrados en el efecto: comprobar idoneidad genérica. Paisaje Nevado se une a
presentación de clima; Día Soleado requiere contrastar orden de timings/capa
horneada a opacidad cero. Sustituto y Transformación dependen de transiciones
visuales externas no demostradas aquí; siguen DATA_ONLY/UNSUPPORTED. Deseo tiene
tres muestras GPU idénticas aunque 20 estados de fuente: revisar secuencia/capas,
no declararlo globalmente estático. Cola por familias en el cuaderno visual.
Once tests Python PASS; verificados hashes de las 88 láminas, manifiestos,
membresía del registro y raw/normalized sin cambios. Sin regenerar capturas/arte.

Novedades 13–20: Granizo se une a presentación de clima (fuente de 13 frames sin
partículas/capas visibles, DATA_ONLY). Martillo Colosal necesita comprobar
legibilidad del golpe en movimiento: aplastamiento/polvo, sin martillo reconocible
en las tres muestras; no textura ausente demostrada. Hipertaladro SOLO rival
presenta impactos desplazados a la derecha del objetivo en la tira ampliada;
revisar foco/cámara/export original antes de atribuir causa o corregir. Paranormal
sí deforma al objetivo en la fuente; Láser Veleidoso sí alcanza al rival y los
cristales de Geocontrol caben en la vista: dudas de miniatura descartadas al ampliar.
Once tests Python PASS; sin regenerar capturas, assets o datos en este tramo.

Novedades 07–12: Llama Final/Electropalmas pendientes de duración del oscurecimiento
(el último frame de fuente restaura color/opacidad; no pérdida permanente de
textura demostrada). Fría Acogida queda con la familia de presentación de clima.
Corregido un fallo del selector de capturas, NO del movimiento: dos estados
visibles podían muestrearse tres veces en el primero. Solo afectaba a Doble Patada
en este catálogo. Ahora f0/f1/f1, dos imágenes distintas; no se declara estática.
Cinco pruebas Godot del selector y once tests Python PASS.

Regenerados 1.734 clips / 5.202 capturas y 88 láminas. Solo cambian las dos tiras
de Doble Patada y las dos páginas 11; 86 láminas idénticas. Migradas 440 anotaciones
solo por hash/membresía/índice/renderer iguales, conservando excepciones; lote 11
vuelto a ver con las capturas nuevas. No se heredan revisiones de imágenes nuevas.

Novedades del barrido 02–06: Solar Blade y Astral Barrage pendientes de trayectoria/
escala en movimiento. Danza Lluvia contiene solo danza corporal: verificados 26
frames sin partículas ni capas visibles; falta la referencia visual de clima, no
se declara un fallo del motor. Cañón Armadura tiene un impacto moteado/rectangular
ya presente en patrón 14 de firepoison.png: revisión artística, no duplicación
demostrada del importador. Sospecha inicial de dirección de Aerochorro rival
descartada al ampliar: el último momento sí alcanza a Ogerpon.

Mejor muestreo por estados visibles distintos demuestra cambios de píxeles en
Mimético/Danza Lluvia/Forcejeo/Danza Caos por ambos lados: sus avisos anteriores
de muestras iguales no significaban animación globalmente estática. Es una
aclaración automática, no aprobación artística/mecánica ni supresión del informe.

Capturas/índice/registro vigente en `.godot/move_contact_review/84cfcc27cf596d4c/sheets_20/`.
Generación anterior conservada como historial, no borrada.
Trece tests Python PASS; fuentes y datos intactos. Las comprobaciones extra de clima
anteriores eran análisis de datos, no revisión visual; ahora las 88 láminas sí
están observadas. No se convierten los análisis previos en aprobaciones mecánicas.
No se cambian el renderer,
las cinco conexiones al combate, learnsets, reglas, sonidos o clasificación.
Sin commit/push/CI nueva. Runbook y límites en el cuaderno visual.

## Automatización masiva del catálogo visual — 2026-10-24

Petición expresa del usuario: dejar los lotes de dos/tres movimientos y automatizar
la preparación y detección de excepciones. Barrido de los **919 IDs** actuales:
**856 convertidos para laboratorio / 1.734 clips** contando ambos lados y las
referencias/variantes prioritarias previas. **63 en cuarentena**, agrupados por
cinco causas: 30 hue no soportado, 19 nombres ausentes/ambiguos, ocho patrones
ausentes, cinco hojas ausentes y un modo de celda no soportado. Sin inventar
recursos ni cambiar clasificaciones para aumentar cobertura.

28 bloques opcionales, máximo 64 clips / 32 millones de píxeles de hojas por
bloque. Generación direccionada por contenido e índice publicado al final;
lectura inerte del caché ya descargado, sin ejecutar Ruby ni nuevas descargas.
El laboratorio existente ofrece «Catálogo por lotes» y búsqueda nombre/ID, con
carga bajo demanda. No se cargan los 1.734 clips/texturas en el combate normal.

Auditoría exhaustiva en dos proporciones: 112.934 fotogramas/lado/tamaño,
5.108.923 comprobaciones headless PASS. GPU fuera de pantalla: **5.123.569 PASS,
1.734 capturas**, cero fallos fatales. Los avisos de borde usan límites alfa,
no el rectángulo transparente completo: 37 IDs se señalan para revisión, no se
declaran defectuosos por ello. Cuatro IDs adicionales tienen muestras GPU iguales
(mimic, rain_dance, struggle, teeter_dance): pueden ser efectos breves no muestreados,
no se dan por correctos ni se descartan automáticamente. Total 41 IDs convertidos
con disparadores de revisión y 815 sin estos disparadores, NO 815 aprobados.
Evidencia GPU e informe agrupado actual en
`.godot/move_batch_checks/`; reconstrucción y límites en el cuaderno visual.
Pruebas de inyección: recurso ausente, hash incorrecto, ID duplicado, clip corto,
lote excesivo, valores no finitos/modos/padding activos; rechazo de informes
obsoletos/incompletos. Seis tests Python PASS. Regresiones headless: laboratorio
444.847, combate comunitario 407, cronología 19.726, VFX 4.949 PASS.

**Preparación de recursos no equivale a conexión al combate.** Se conservan las
cinco rutas revisadas anteriores; este tramo no añade rutas, reglas, sonidos,
learnsets ni mecánicas. Raw/normalized mantienen sus hashes previos. Los nueve
fallos DATA ambientales anteriores no se reabren ni se presenta esa suite como
verde. HEAD remoto `0902de4c10d34a2a451c9acad83fbfea765ef270`, 19 checks SUCCESS
consultados antes de editar; no certifican estos cambios locales. Sin commit,
push, workflows, snapshot inmutable o F:.

## Lote visual elemental conectado — 2026-10-23

Añadidos Lanzallamas, Rayo y Rayo Hielo al piloto local de combate. Son tres
movimientos RUNTIME_SUPPORTED existentes: no se cambian daño, probabilidades,
estados, aprendizaje ni datos. El piloto tiene ahora cinco IDs/diez clips,
incluidos Garrote y Tera normal. Lanzallamas/Rayo Hielo usan export rival propio;
Rayo adapta el lado contrario. Duración/marcador dependen también del lado:
Lanzallamas conserva sus 19/20 frames y sus impactos 7/8, sin igualarlos a fuerza.

F5 «Elementales (reinicia)» recorre Lanzallamas -> Rayo -> Rayo Hielo en la demo
existente; enseña un único movimiento temporal al Charizard de la prueba, con
PP canónicos y Wailord Nv.50. Reiniciar restaura el moveset natural. F4 sigue igual.
Gate focal: 542 PASS GPU, 40 capturas, 407 headless. Se prueban ambos lados y
turnos reales con secundarios del motor, sin repetir RNG/estado durante el replay.
Muestras gráficas revisadas, no aprobación de todo el catálogo. Regresiones:
cronología 19.726, VFX 4.949, laboratorio 444.847, mapa 45/runtime 103; Tera 66 y
tres tests Python. El conteo VFX cambia al sustituir sus comprobaciones genéricas
de Rayo Hielo por la preparación comunitaria, no por omitir el movimiento.
Sin nueva CI/commit/push, cambios de motor/datos o F:. Las prioridades especiales
Adaptación/Daño Secreto/Max siguen separadas por sus límites mecánicos.
Reconstrucción y límites en `../project_book/VISUAL_CATALOG.md`.

## Teraexplosión normal conectada a combate — 2026-10-23

El piloto local de la demo existente representa Garrote Liana base y el único
equivalente TECHNOBLAST para Teraexplosión normal, desde ambos lados. Esta última
exige exactamente PARTIAL_RUNTIME/normal/especial/80/selected-pokemon y ausencia
de efectos secundarios. No se abre genéricamente PARTIAL_RUNTIME ni se activa Tera.
PS/mensaje del daño real se sincronizan al marcador 47 de su clip de 70 frames;
no se reutilizan los tiempos de Garrote. Solo partículas: se omiten placas de
fondo que ocultaban los cuerpos y se adapta la trayectoria a nuestra cámara.

`JUGAR_DEMO.cmd`, F4 «Ensayo Tera (reinicia)»: preset explícito Charizard Nv.50 /
Wailord Nv.50, encuentros al 100 %, movimiento temporal en memoria. «Reiniciar»
restaura el learnset; no hay enseñanza por nivel falsa, TM implementada ni saves.
Gate focal: 237 PASS GPU, 17 capturas; 180 headless, turnos reales por ambos lados,
fallo, cancelación, KO de entrenador, captura y KO con reloj natural. Regresiones
headless: cronología 19.726, VFX 4.955, laboratorio 444.847, mapa 45/runtime 103;
regresión de datos Tera 66 + tres tests Python. No se reejecuta la batería DATA
completa: permanecen como límite los nueve fallos ambientales documentados abajo.
Pack opcional de cuatro clips; si falta, puede usarse el pequeño pack previo de
Garrote y después el fallback genérico. Sin nuevos cambios de datos/motor,
workflows, F:, commit/push o CI. Detalles en `../project_book/VISUAL_CATALOG.md`.

## Teraexplosión: corregido el subconjunto normal — 2026-10-23

Autorizada la corrección tras el hallazgo anterior. El shim del conversor V3
elimina los dos descensos incondicionales, con guardas sobre la forma exacta del
snapshot. Teraexplosión conserva Normal/especial/80 y pasa a PARTIAL_RUNTIME:
no se implementan Tera, Astral ni selección dinámica de tipo/categoría.
Refrescado solo ese registro raw mediante el conversor canónico y un blob fijado
de Git (69.344 bytes), seguido del importador Godot normal. Comparación semántica
con HEAD: únicamente effect_specs/classification de tera_blast cambian en raw y
normalized. Resto de movimientos/especies/learnsets/manifest sin cambios.

Regresión nueva: 66 PASS Godot (importado + normalizado, ambos lados, tres semillas)
y tres tests Python, incluidas guardas de origen y controles de otros movimientos.
Garrote 80 PASS, VFX 4.955 PASS; laboratorio 444.847 PASS headless. Su pack solo
cambia dos etiquetas de clasificación, no imágenes/frames. No nueva revisión GPU.
La batería DATA completa tenía antes 558 PASS / 9 FAIL y ahora 624 PASS / los
mismos 9 FAIL: informes antiguos/ausentes y seis fuentes de habilidad no presentes
en el sparse checkout. No se silenciaron ni se considera certificación completa.
Teraexplosión continúa solo en el laboratorio; la conexión real aún es Garrote.
Sin cambios del motor, snapshot, F:, workflows, commit/push ni nueva CI.
Reproducción, hashes y límites en `../project_book/VISUAL_CATALOG.md`.

## Hallazgo previo al enlace de Teraexplosión — 2026-10-20

Se detiene únicamente la nueva conexión visual de `tera_blast`: su definición
actual, aunque declara RUNTIME_SUPPORTED, contiene dos bajadas incondicionales
al rival (Ataque y Ataque Especial, -1). Reproducido en tres encuentros nuevos
del motor real, sin Tera y sin reproducción visual: etapas del rival de 0/0 a
-1/-1 tras daño. No es un fallo del recurso TECHNOBLAST. La implementación de
referencia Showdown solo aplica esas bajadas al usuario bajo Tera Astral.
El conversor de efectos también reproduce la traducción incorrecta al evaluar
en memoria la referencia pública actual de PokéAPI; no se regeneró el catálogo.
Datos, mecánicas y enlace de Garrote permanecen sin cambios. Se requiere decidir
un tramo de corrección de datos/regresión antes de continuar este enlace, no
ocultar el problema en la capa visual ni implementar Tera completa.
Evidencia, reproducción y límites en `../project_book/VISUAL_CATALOG.md`.

## Primer efecto comunitario en combate real — 2026-10-20

La demo existente enlaza solo Garrote Liana base a daño positivo confirmado,
con clasificación RUNTIME_SUPPORTED. Se representan sus partículas sobre los
cuerpos existentes, con PS/mensaje sincronizados al golpe y limpieza al cancelar,
cambiar de fase, KO o regresar al mapa. No repite resolución, daño, PP ni RNG.
Paquete pequeño opcional; sin él siguen los efectos compartidos anteriores.
F1 Ogerpon Nv.50 / Wailord salvaje Nv.50 permite probarlo con el learnset natural.
No se habilitan Max, Tera, máscaras, Prensa Metálica ni referencias contextuales.
Gate focal: 104 PASS / 0 FAIL GPU, ocho capturas; 80 headless, más KO natural.
Corregida desalineación por cambio de tamaño del panel de entrenador. Regresiones
verdes: cronología 19.726, efectos 4.955, catálogo 26.042, mapa 45 y runtime 103;
laboratorio GPU 445.694 / 708 capturas. Solo trabajo local, sin nueva CI/commit/push.
Reconstrucción/procedencias/límites en `../project_book/VISUAL_CATALOG.md`.

## Laboratorio de ataques — actualización 2026-10-20

`JUGAR_PRUEBA_ATAQUES.cmd` ofrece 70 secuencias: se completan los ocho exports
de Garrote Liana de Toxillian y se añade HEAVYSLAM como equivalente de Prensa
Metálica. Corregida la proporción del garrote en vistas rivales. Las variantes
solo cambian el efecto, no la forma de Ogerpon; Prensa Metálica sigue DATA_ONLY.
El laboratorio continúa aislado; el único enlace real es la base de Garrote
descrita arriba, mediante otro pack pequeño. Gate GPU: 445.694 PASS / 0 FAIL,
708 capturas; headless 444.843 PASS. Regresiones de mapa (45) y efectos (4.955)
verdes. Muestras revisadas visualmente, no aprobación artística completa.
Detalles/hashes/reconstrucción en `../project_book/VISUAL_CATALOG.md`.
Sin commit/push, CI nueva ni cambios de dominio, datos o biblioteca de F:.

## Continuación visual local — 2026-10-19

Copia activa independiente: `D:\Proyectos\Pokemon Calvo`, rama
`fix/map-runtime-hardening-v1`, HEAD `0902de4c10d34a2a451c9acad83fbfea765ef270`.
La rama remota coincide con ese HEAD; sus 19 checks constan SUCCESS al consultar
GitHub. Los cambios visuales locales posteriores siguen sin commit/push y no
heredan certificación remota por estar en la misma carpeta.

Catálogo local: 1.025 especies base con frontal/espalda, escala referenciada y
suavizado compartido en combate/galería. Los 14 candidatos con poses adicionales
ya reproducen ataque/daño desde eventos reales, con bloqueo de entrada y retorno
a reposo. Ahora las 1.025 especies tienen una cronología compartida de acción,
impacto/curación, PS y mensajes: el resto usa reacciones procedimentales sobre
sus imágenes originales, no poses inventadas. Dominio/diagnósticos siguen síncronos;
la representación visual se reproduce después sin volver a ejecutar el turno.
Ya se representan captura con sacudidas reales y éxito/salida, retirada/aparición,
KO/cambio forzado y huida exitosa mediante efectos compartidos. El routing al PC,
identidad, inventario y RNG siguen siendo exclusivos del dominio. Gate gráfico
actual: 19.790 PASS / 0 FAIL, 64 capturas; no equivale a certificación remota.
Añadidos VFX geométricos provisionales por tipo/categoría: 18 tipos, sin nuevos
sprites ni poses. Solo el daño confirmado genera impacto elemental; estado y
curación no se presentan como golpes. Gate focal: 5.001 PASS / 0 FAIL, 46 capturas,
20 turnos reales de muestra y mapeo de los 919 metadatos, no certificación de sus
mecánicas ni 919 animaciones individuales. Audio, formas y pulido artístico pendientes.
Detalles y gates: `../project_book/VISUAL_CATALOG.md`.

Evaluados aparte los archivos de animaciones comunitarias EBDX y Gen 9 y anotados
sus créditos/condiciones. Gen 9 es candidato provisional por cobertura y formato,
no ganador artístico certificado. No hay plugin instalado, importador general
ni efectos definitivos sustituidos en el combate; falta comparación equivalente con EBDX.
Existe un laboratorio local aislado (`JUGAR_PRUEBA_ATAQUES.cmd`): Garrote Liana
base y los 19 candidatos Max por ambos lados, 40 secuencias. Diez Max con export
rival propio y nueve marcados como adaptados; no son animaciones Max nativas nuevas.
Recursos copiados sin editar a caché ignorada. Gate GPU: 296.712 PASS / 0 FAIL,
404 capturas; efectos compartidos headless 4.955 PASS y mapa 45 PASS. Se ajustaron
recortes, mezclas y encuadre de mosaicos; vuelo/fantasma usan Huracán/Bola Sombra.
Maxibarrera se dirige a quien la usa sin inventar implementación de protección.
No es conexión a combate, aprobación artística ni certificación CI del trabajo nuevo.

Actualización posterior del laboratorio: 62 secuencias al añadir un equivalente
único de Teraexplosión y cinco referencias manuales por lado para Adaptación y
Daño Secreto. Se advierte explícitamente que no ejecutan ni habilitan movimientos.
Corregida la proporción del cubo psíquico (escala uniforme del objeto, afín solo
para sus mosaicos; normalización int/float al cargar patrones). Gate vigente:
399.949 PASS / 0 FAIL GPU, 628 capturas; 399.194 headless. Regresiones focales
repetidas: efectos 4.955 PASS y mapa 45 PASS. Detalles y hashes en el cuaderno.
Sin dominio/RNG/learnsets ni tipo Tera nuevos; no es cobertura de todos los biomas.

Prioridades revisadas: 19 Max/Dinamax, Garrote Liana y revisión de Adaptación/
Daño Secreto primero; una variante de Teraexplosión basta y Prensa Metálica va
después. Descargado el aporte original de Toxillian (ocho exports de 38 fotogramas)
y localizadas equivalencias de recursos para los 19 Max. Auditoría externa de
disponibilidad/formato: 125 PASS; manifiesto en la carpeta de comparación, detalles
en el cuaderno. No están integrados ni certificados visualmente. Essentials delega
las dos entradas de un fotograma a otras animaciones; no se alargan artificialmente
ni cambia el soporte mecánico del catálogo. El laboratorio no modifica el runtime
de combate, pool final ni implementa la regla de aprendizaje aleatorio comunicada.

Los datos normalizados y Trainer AI ya están en esta copia. El snapshot inmutable
`data/api` y los esquemas `data/schema` siguen excluidos por sparse checkout; no
se necesitan ni se descargan para este tramo visual. No se modifican DATA V3,
reglas, IA, workflows, originales de F: ni se abre/promociona una rama remota.

## Actualización — primera prueba visual (2026-10-18)

Continuación activa: `fix/map-runtime-hardening-v1`, parent certificado
`62468af2d52081b95129c435c43323a69d94105a` (PR #114, 19/19 workflows correctos).
Se corrigen salto cercano/lateral, destinos ocupados, pasos tras iniciar combate,
ajustes durante transiciones y tiempo parcial en hierba. Se añade overlay F2 y gate
`map_runtime_test_runner.gd`. Detalles y límites en `../project_book/VISUAL_FIELD.md`.

Baseline remoto real comprobado: `e98e09f75b3f55c7d170f8f9906d49792cef5a6c` en
`main`; sus 18 workflows de regresión y build Windows están correctos.
La copia local antigua de agosto no se usa como parent de nuevo trabajo.

Se abre `feature/visual-field-lab-v1`: presentación de ruta, personaje, hierba y
sprites mínimos sobre las sesiones existentes. Se ejecuta con `JUGAR_DEMO.cmd`;
`project.godot` conserva la escena técnica histórica. La nueva prueba no implica
que GF1-A..F esté implementada. Estado y límites: `../project_book/VISUAL_FIELD.md`.
La validación remota de esta rama debe consultarse sobre su HEAD exacto.
Los párrafos de consolidación siguientes son contexto histórico del relevo anterior.

## Línea moderna certificada

El último freeze funcional/documental moderno antes de consolidar `main` es:

`8552f52158ffc21c27b4e8f1dbc7caa63ac1a467`

Resultado verificado sobre ese SHA:

- **18/18 workflows SUCCESS**;
- Trainer Evaluation Corpus: **628 PASS / 0 FAIL**;
- Trainer AI runtime 26.67 — CLOSED / COMPLETED;
- Game-Ready 27.1 — CLOSED / VALIDATED;
- Expertise V1 — CLOSED / CERTIFIED / FROZEN;
- Campaign Persistence V1 — CLOSED / CERTIFIED / FROZEN.

No existe P1-E ni queda una tranche Trainer AI obligatoria activa.

## Consolidación de `main`

La antigua `main` estaba en:

`641d4b1fb0bcf964205d616e96f198f05d702197`

Ese commit divergía del linaje moderno únicamente por añadir un archivo vacío `this_should_not_be_called`; no contiene una feature del juego que deba conservarse en el árbol final.

La operación autorizada de consolidación vive en:

`chore/main-baseline-consolidation-v1`

Merge histórico inicial:

`2f63312e8dc3e61c8fadbd02e97972fff6d0eacc`

Propiedades del merge inicial:

- parent 1: antigua `main` `641d4b1f...`;
- parent 2: freeze moderno `8552f521...`;
- tree exacto: `89835a6797989a8ef027b6b17baea206b1f97f74`, el mismo tree del freeze moderno;
- no arrastra `this_should_not_be_called`;
- no introduce cambios de producción respecto de `8552f521...`.

La promoción de `main` solo queda autorizada cuando el HEAD final de esta rama, incluida la actualización documental, pase la matriz normal completa. GitHub/CI sobre ese SHA exacto es la autoridad.

## DATA V3

Estado: **CERRADO / CERTIFICADO**.

Contrato canónico preservado:

- 1.025 especies;
- 326 formas;
- 18 tipos runtime;
- 919 movimientos;
- 373 habilidades;
- 2.222 objetos;
- 61.102 entradas de learnset;
- 554 evoluciones.

Frontera ejecutable relevante:

- Moves: 590 RUNTIME_SUPPORTED / 71 PARTIAL_RUNTIME / 246 DATA_ONLY / 12 UNSUPPORTED;
- Abilities: 21 RUNTIME_SUPPORTED / 14 PARTIAL_RUNTIME / 338 DATA_ONLY;
- Evolutions: 391 RUNTIME_SUPPORTED / 149 DATA_ONLY / 14 UNSUPPORTED;
- held items runtime: `leftovers`, `sitrus_berry`;
- trainer bag runtime: `potion`, `super_potion`, `hyper_potion`, `max_potion`, `full_restore`.

No reabrir DATA V3 por subir contadores. Ampliar mecánicas solo cuando una necesidad concreta del juego lo exija.

## Trainer AI — cerrado

El entrenador de combate dispone de memoria bilateral sanitizada, beliefs sin información oculta, búsqueda acotada, MOVE/SWITCH/ITEM donde corresponda, switching estratégico, loadouts/composición, proposal sobre todas las raíces legales, sustitución autónoma side_b, tie resolution game-ready, integración real Overworld/Battle Core, victoria/derrota/reset, full-battle adversarial, estilos/expertise y persistencia de roster entre combates.

Checkpoint técnico final P1-D:

`b314b8bb81db439e3063433644c691181ed39ef4`

Evidencia final:

- P1-D: **46/46 PASS**;
- Evaluation: **628 PASS / 0 FAIL**;
- full technical CI: **18/18 SUCCESS**.

No reabrir C3f, Game-Ready 27.x, Expertise V1 ni Campaign Persistence V1 salvo regresión reproducible o feature nueva explícita.

## Estado del videojuego visible

El ejecutable actual sigue arrancando en:

`res://scenes/overworld/technical_overworld.tscn`

Ese mundo es una vertical slice técnica asset-free. Ya demuestra movimiento, colisión, encuentros salvajes, captura, switching, combate de entrenador, IA, settlement y revancha/recovery explícitos, pero **no es todavía una campaña completa**.

Los sistemas base ya existentes incluyen:

- Battle Core;
- criaturas/progresión/evolución dentro de la frontera runtime;
- captura;
- party/storage;
- inventario;
- Save V2 de criaturas + party + storage + inventory;
- encuentros/overworld técnico;
- localización base;
- Trainer AI cerrada.

## Siguiente workstream de producto

Tras consolidar `main`, el siguiente trabajo obligatorio deja de ser Trainer AI y pasa a ser **Game Foundation V1**.

Objetivo: convertir los cimientos certificados en una primera mini-campaña reproducible sin depender todavía de arte final.

Orden previsto:

1. game state global y contrato de campaña;
2. infraestructura de mapas/transiciones/spawn points;
3. NPC + diálogo + flags/eventos data-driven;
4. Save V3 para mundo/campaña;
5. servicios básicos (curación, tienda, PC/party UI mínima);
6. vertical slice jugable: inicio + inicial + pueblo + ruta + encuentro salvaje + entrenador + servicio + guardar/cargar;
7. después, rival autónomo de overworld y producción de contenido.

## Invariantes externos durante la consolidación

- PR #105 permanece OPEN / unmerged;
- PR #106 CLOSED / not merged;
- PR #107 CLOSED / not merged;
- no mezclar la consolidación de `main` con nuevas features de Game Foundation hasta certificar la promoción.
