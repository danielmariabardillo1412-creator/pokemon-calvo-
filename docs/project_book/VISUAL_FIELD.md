# Prueba visual de ruta

## Vigente: perfil conjunto en el mismo mapa — 2026-10-28

`JUGAR_DEMO.cmd` inicia Gen9 + Dinamax (`gen9calvounifiedv1`); el mismo control
Dinamax ofrece los Maxi derivados del movimiento base. Guardar/cargar durante
Dinamax y capturar vuelven a datos canónicos de colección. Los guardados viejos
conservan su formato. F12 usa la variante del perfil con cuatro activos, aún
como ensayo sin consecuencias para la campaña.

Se conservan PNG y clips. La única corrección visual de este cierre es mostrar
«Sol intenso» al activar ese clima, antes sin etiqueta. Las capturas reales del
mapa y su registro se encuentran en `.godot/unified_profile_checks/`.
Informe vigente `UNIFIED_MOVE_SWEEP.json`; detalles en `BATTLE_PROFILE.md`.

## Antecedente: F12 de dobles nativos — 2026-10-27

En `JUGAR_DEMO.cmd`, F12 permite escoger uno de los 11 movimientos pendientes,
prepararlo desde cualquiera de los lados y elegir cuatro acciones con objetivos
y reservas. Guardar/cargar ensayo usa un archivo independiente; Esc cierra el
trabajador y vuelve al mapa sin cambiar la colección real.

La presentación reutiliza clips existentes y posiciones de cuatro Pokémon.
Conserva cels de cuerpo (inclinación, desplazamiento, tinte y opacidad), partículas
y la niebla original de Niebla Aromática. Los otros dos participantes se dibujan
a la profundidad correcta. Se omite la placa negra opaca de Foco para mantener
el contexto de cuatro puestos. Cambio de Banda conserva las curvas fijadas.
Los OppMove nativos no asignan slots como los clips espejados: usuario se vincula
por `actor_side`, objetivo/aliado por identidad real y efectos locales conservan
su vertical, incluido el cono de Foco. No se sustituyen imágenes.

66 capturas (11 × 2 lados × 3 tiempos), seis hojas de revisión y pruebas
reproducibles en `.godot/native_doubles_checks/`. No es revisión de todas las
combinaciones posibles. Informe vigente `NATIVE_DOUBLES_INTEGRATION.json`.

## Antecedente: combate nativo y guardado en este mapa — 2026-10-27

La escena principal y `JUGAR_DEMO.cmd` usan el MISMO campo ya construido. Los
encuentros de hierba y el rival pasan por la conexión nativa con la colección
real; el laboratorio aislado ya no es la única forma de usar ese motor.
El modo histórico queda disponible solo para diagnóstico con `--legacy-field`.

La pantalla reutiliza Pokémon, clips y composición anteriores; no se generan
ni sustituyen imágenes. Bloquea movimiento/configuración durante el combate,
permite volver al mismo punto al terminar y conserva daños/PP/estados del equipo
y del entrenador. Galería/configuración/dobles de diagnóstico impiden iniciar
combates o cargar mientras están abiertos.

Guardar/cargar mediante botones y Ctrl+S/Ctrl+L usa una envoltura atómica con
colección SaveV2, posición/RNG, entrenador y combate activo. Puede recuperarse
un trabajador muerto sin inventar un turno. Capturas se enrutan al equipo o PC;
experiencia y gastos se publican una vez. El sueño entre encuentros conserva
únicamente su reloj nativo observado, también después de guardar/cargar.

Pruebas y cinco capturas revisadas en `../current/FIELD_NATIVE_INTEGRATION.json`;
reproducir con `tools/showdown_engine_probe/run_field_integration.py`.
La prueba predeterminada usa Gen9; Gen8/Dinamax permanece como perfil explícito.
Siguen pendientes perfil conjunto y camino nativo de dobles. La IA rival nativa
es básica; no se reemplaza ni reentrena la profesional histórica en esta fase.

## Movimientos de etapas en la sesión normal — 2026-10-26

El perfil live admite ahora 585 movimientos. Niebla, Reversión, Cambiaalmas,
Cambiafuerza, Cambiadefensa y Acupresión se habilitan sin presets; Niebla Clara y
Robasombra reciben sus efectos faltantes además del daño. Clips existentes
confirmados en ocho encuentros reales con Vulpix de Alola shiny: 2.005 checks /
192 casos / 16 capturas PASS. No se cambia la imagen ni el tamaño de Wailord.
Evidencia y límites en `../current/STAT_STAGE_MOVES.json`.

## Regionales y shiny disponibles — 2026-10-26

La demo carga las 57 regionales ordinarias como definiciones propias y añade los
shiny existentes: 1.011 base + 57 regionales. F3 permite alternar el color. En F1,
`vulpix_alola` elige la forma; `vulpix_alola__shiny` fuerza su variante disponible
en equipo, entrenador o salvaje fijo. Sin forzar, el sorteo cosmético es 1/4.096,
configurable y separado del RNG mecánico. No hay shiny inventados de los 14 propios.

Captura, PC, guardado/carga, evolución y Transformación mantienen la identidad y
el color. Las seis especies descartadas se filtran del selector ordinario, aunque
sus imágenes históricas se conservan. Gate: 13.807 checks GPU PASS y cuatro capturas;
campo original 45 PASS. Detalles: `../current/POKEMON_VARIANTS_INTEGRATION.json`.
Otras formas especiales y sus mecánicas siguen fuera de este cierre.

## Integración ordinaria, sin presets — 2026-10-26

La demo y el mapa técnico habilitan el perfil live al crear las sesiones normales:
18 mecánicas individuales especiales, filtros de movimientos, relevo elegido por
el jugador y elección automática del NPC dentro del mismo turno. La IA principal
sigue siendo el pipeline profesional existente; sus forks heredan las reglas y
completan las elecciones pendientes sin alterar el estado/RNG reales.

El catálogo general conecta 900 movimientos / 1.822 clips, cargados por shard con
SHA y sobre eventos confirmados. Conserva las rutas previas de impacto fino; el
registro general muestra los PS al terminar el clip. Los sprites propios/rivales
se coordinan con el preview para evitar duplicados y desapariciones del rival en
movimientos propios. Cinco Torque usan el efecto genérico por tipo. F4–F11 quedan
como comparaciones explícitas; F12 sigue siendo el ensayo limitado de dobles.

585 movimientos admitidos en individuales; 334 no disponibles, separados por
contenido, lógica faltante/parcial y formato en `LIVE_MOVE_UNAVAILABLE.csv`.
El catálogo visual completo no equivale a lógica completa de 919 movimientos.
Sin movimientos admitidos con PP se ofrece Esfuerzo temporal, sin alterar learnset.

9.750 checks del gate actual / 585 ejecuciones deterministas / 1.822 clips / 10 capturas.
Informe `docs/current/LIVE_MOVE_INTEGRATION.json`; hoja
`.godot/live_integration_checks/contact_sheet.png`. No se ha creado un ejecutable
exportado; los recursos nativos siguen siendo la caché local ya existente.


## Ensayo F12: Cambio de Banda con cuatro Pokémon — 2026-10-26

F12 abre un panel de dobles dentro de esta demo, con Gardevoir/Pikachu frente a
Charizard/Blastoise. Se eligen las cuatro acciones y sus puestos rivales; Resolver
turno envía el paquete al adaptador real. Esc/Volver al mapa cierra la prueba y
restaura movimiento; reabrir inicia una prueba nueva. La party principal no cambia.

Cambio de Banda intercambia a los dos aliados vivos con prioridad +2. Los ataques
se ligan al puesto elegido, de modo que recibe el golpe quien lo ocupa después
del intercambio. Conserva identidad/PS/PP/estados/etapas; no es un relevo de reserva.
Repeticiones pueden fallar, con denominador hasta 729. UI y replay solo muestran
los resultados resueltos; tras un KO se desactiva ese objetivo y actúan los vivos.

Este es un ensayo de posiciones 2 contra 2: no contiene reservas, habilidades,
objetos, movimientos de área, captura/progresión ni IA. Cuatro ataques diagnósticos
acompañan a Cambio de Banda. No habilita aquí los otros 18 pilotos individuales.
Cámara/movimiento de cuatro cuerpos y curva de fade original reflejada, registrada
como adaptación; no hay partículas nativas en los clips fuente ni dibujos nuevos.

1.044 checks / 48 casos base / 16 capturas. Informe `ALLY_SWITCH_PILOT.json`;
hojas `.godot/ally_switch_checks/positions_contact_sheet.png` y
`motion_contact_sheet.png`. Los 19 casos originales tienen ya pilotos base
(18 individuales y 1 de dobles); sigue abierta su integración/certificación de
producción, particularmente interfaz/IA y compatibilidad entre mecánicas.


## Ensayo F11: Transformación — 2026-10-26

F11 recorre Ditto contra Wailord, Pikachu y Charizard, nivel 50 y encuentro al
100 %. Reiniciar devuelve el equipo/learnsets naturales y desactiva el piloto.
Se conserva la identidad/nombre/PS/nivel de Ditto, mientras la imagen y sus
botones muestran la copia real confirmada por el motor. Los ataques prestados
usan min(5, PP base); cambiar/capturar/huir/terminar restaura la base y los PP
originales ya gastados. El rival transformado se captura como su especie original.

Clip original de 15 frames/20 fps sin partículas; handoff en el frame 8 con breve
compresión/desvanecimiento de sprites existentes. Adaptación de presentación,
no una nueva imagen ni un VFX nativo completo. Se usan ambas vistas correctas.

1.221 checks / 72 casos / 12 capturas; `.godot/transform_checks/contact_sheet.png`.
Informe `docs/current/TRANSFORM_PILOT.json`. Acumulado: 18 mecánicas base opt-in;
falta Ally Switch y su formato de dobles, además del despliegue general/IA y
certificación de interacciones. Las proyecciones de tres frentes se capturan
aparte; los encuentros reales, ataques copiados y retorno a Ditto se prueban en
F11, junto con Transform del rival antes de capturarlo y limpieza tras huida.


## Ensayo F10: Sustituto / Autotomía — 2026-10-26

F10 alterna ambos movimientos en el mismo mapa/demo: Charizard y reservas frente
a Wailord, nivel 50 y encuentro al 100 %. Incluye Placaje, Lanzallamas y Relevo
para contrastar protección/transferencia. Reiniciar restaura el equipo natural y
desactiva el piloto. Solo nuevos encuentros salvajes individuales.

Muñeco con PS propios, coste real y elección de reserva en Shed Tail. La barra
de PS del Pokémon no baja por los golpes absorbidos; al romperse reaparece su
sprite original. Clips de creación y muñeco frontal/trasero originales; cámara
anclada a sus pies, sin duplicar la copia persistente durante la creación nativa.
Impactos contra el muñeco: efecto genérico existente por tipo, registrado como
adaptación de presentación. No hay imágenes nuevas ni cambios del renderer base.

453 checks / 48 casos / 9 capturas. Informe `docs/current/SUBSTITUTE_PILOT.json`;
hoja `.godot/substitute_checks/contact_sheet.png`. Acumulado F7–F10: 17 mecánicas
base opt-in. Quedan Transform y Ally Switch, además del despliegue general/IA y
las interacciones aún no certificadas. Véase `NEXT_STEPS.md` para el alcance exacto.


## Objetivo y estado

Primer laboratorio con imagen para probar el bucle `moverse → hierba → encuentro
→ combate/captura → volver al mapa`, solicitado el 2026-10-18.
Rama: `feature/visual-field-lab-v1`. Parent: `e98e09f75b3f55c7d170f8f9906d49792cef5a6c`.
Ese parent coincide con la `main` remota consultada y tiene los 18 workflows de
regresión y la build de Windows correctos (20 runs, incluyendo un Godot duplicado).

La primera entrega quedó en `62468af2d52081b95129c435c43323a69d94105a`, PR #114,
con 19/19 workflows SUCCESS. La continuación `fix/map-runtime-hardening-v1`
parte de ese SHA y responde a la prueba humana de salto cercano.

Esta capa visual reutiliza la vertical slice técnica, sus colisiones, tablas,
sesiones, captura, inventario, Trainer AI y recorder. No reabre DATA V3 ni IA.
No representa todavía GF1-A..F ni una campaña con guardado de mundo.

## Ejecutar

En Windows: doble clic en `JUGAR_DEMO.cmd`. El lanzador usa Godot 4.7 del entorno
local o `godot` en PATH e importa las clases antes de iniciar la escena.
En cualquier plataforma, tras importar:

```sh
godot --path . res://scenes/visual/field_demo.tscn
```

La escena principal histórica se mantiene en `technical_overworld.tscn` para
conservar el contrato de regresión del laboratorio. La demo es una escena heredada.
La copia local de trabajo puede usar sparse checkout para omitir el snapshot de
API/schema inmutable; los datos raw/normalized/manifests sí están presentes.

## Cómo probar

- **F9 / Clima:** recorre Danza Lluvia, Granizo, Tormenta de Arena, Paisaje
  Nevado y Fría Acogida. Equipo Charizard/Lapras/Golem nivel 50 frente a Wailord
  al 100 %. Se añaden Pistola Agua, Lanzallamas y Placaje para comparar efectos.
  El encabezado muestra el clima y sus turnos restantes; el efecto visual persiste
  entre acciones. Fría Acogida pide reserva después de poner nieve, y el contador
  espera a que la elijas. Reiniciar restaura los learnsets naturales y desactiva
  el piloto. La interfaz/IA de entrenador sigue pendiente. Informe
  `../current/WEATHER_PILOT.json`: 1.523 PASS/120 casos/11 capturas GPU.
  Solo se certifica el alcance descrito, no todos los ataques/habilidades que
  dependen del clima. Acumulado con F7/F8: quince mecánicas base de prueba.

- **F8 / Cambios de estado:** recorre Rugido, Remolino, Teletransporte, Relevo y
  Última Palabra. Usa el mismo equipo de tres y Wailord al 100 % que F7. Elige la
  reserva y pulsa Enviar cuando se solicite; la elección continúa el turno.
  Relevo empieza con +2 Ataque/+1 Velocidad en este preset para probar su
  transferencia. Teletransporte propio releva incluso contra un salvaje;
  solo un usuario salvaje huye con él (regla moderna). Rugido/Remolino pueden
  cerrar el encuentro por expulsión, sin XP ni captura. Última Palabra baja
  Ataque/Ataque Especial antes de elegir reserva. Reiniciar restaura los
  learnsets naturales y desactiva el piloto. Los demás contratos de entrenador
  siguen pendientes. Informe `../current/STATUS_SWITCH_MOVES.json`: 1.326 PASS,
  120 casos, diez clips/18 capturas GPU. Sumando F7: diez movimientos de prueba.

- **F7 / Relevos:** recorre los mismos cinco ataques con su mecánica base
  habilitada en encuentros salvajes individuales. Equipo de prueba Charizard,
  Pikachu y Blastoise nivel 50; Wailord al 100 %. Viraje/Ida y Vuelta/Voltiocambio
  piden elegir reserva y pulsar Enviar; el rival continúa el mismo turno contra
  quien haya entrado. Llave Giro/Cola Dragón terminan el encuentro salvaje si
  cumplen nivel/impacto y el objetivo sobrevive. Sin XP ni captura por expulsión.
  Reiniciar desactiva el piloto y reconstruye el equipo seleccionado con sus
  learnsets naturales. No habilita las mecánicas en la interfaz/IA del entrenador.
  Evidencia: `../current/SWITCH_MOVE_PILOT.json`, 1.844 PASS/120 casos/11 capturas
  GPU; motor en formato entrenador probado por separado en ambos lados.

- F6 / Ensayo parcial: recorre Llave Giro, Cola Dragón, Viraje, Ida y Vuelta y
  Voltiocambio. Reinicia una prueba temporal con Charizard/Wailord nivel 50 y
  encuentro al 100 %. El aviso SOLO DAÑO indica el alcance: partículas y PS
  conectados, relevo/expulsión todavía pendientes. Durante combate no cambia el
  preset. Reiniciar restaura el learnset; no se guardan movimientos nuevos.
- El estado de los 19 casos está en `../current/BATTLE_EXTERNAL_INTEGRATION.json`:
  integración parcial, cinco daños conectados y ningún efecto especial cerrado.
  GPU 475 PASS, once impactos reales, doce capturas; regresiones de campo 45,
  reproducción 19.726, recetas 4.949 y enlaces anteriores 407 PASS. Las pruebas
  de daño y reproducción no certifican las mecánicas todavía ausentes.

- Flechas: caminar. La hierba está a la derecha, el rival arriba a la izquierda.
- Refugio abajo a la izquierda: entrar/salir sin encuentros; no ofrece aún curación.
- Cueva abajo a la derecha: transición y encuentros de nivel 8–12.
- Frecuencia: alternar 0, 5, 15, 30 y 100 %. Reinicia equipo, mochila y métricas.
- Reiniciar: empezar una prueba nueva con la configuración vigente.
- F1 / Ajustes: panel avanzado de especies, niveles, equipos e IA; pausa el movimiento.
- F2 / Colisiones: superponer las formas físicas reales (muros, hierba, saltos,
  puertas, rival y personaje). No altera el RNG ni añade colisionadores.
- Informe: exportar el recorder existente. Su ruta se comunica en el panel técnico.
- En combate: ataques, cambio, balls, huida y retorno al mapa usan el dominio real.

El ejemplo inicial contiene Bulbasaur y Charmander Nv.5, Pidgey Nv.4–6 y la mochila
histórica (3 Poké Balls, 1 Super Ball, 1 Master Ball). La Master Ball sirve para
comprobar un recorrido de captura garantizado; las otras conservan el cálculo real.
Los RNG usan las semillas reproducibles del laboratorio: reiniciar reproduce la prueba.

## Frecuencia y tiempos

Se tira por distancia real recorrida (cada 32 px), solo dentro de una zona válida.
Con 96 px/s son 3 pasos/s. A 15 % por paso, la espera geométrica tiene media de
6,67 pasos / 2,22 segundos caminando continuamente dentro de hierba, excluyendo
combates, pausas, colisiones y camino sin encuentros. No garantiza que aparezca
antes de ese tiempo. El valor inicial es una propuesta de prueba, no un balance final.

La HUD muestra configuración, media teórica, tiradas, encuentros, capturas y tiempo
de desplazamiento en zona. Las métricas proceden del recorder/runtime existente.
Con 0 % no hay espera finita ni encuentros; con 100 % aparece en el primer paso válido.

## Imagen y límites

Mapa, personaje calvo, rival, refugio y cueva se dibujan en código Godot. La hierba
anima visualmente al pasar sin consumir RNG de juego. Los seis PNG históricos
siguen conservados; atribución en `assets/prototype/README.md`.
La integración local del catálogo completo usa ahora `battle_sprite_catalog.gd`
para las 1.025 especies base con frontal/espalda y cadencia de sus recursos.
Las presentaciones salvaje y de entrenador leen los IDs de sus sesiones reales;
no modifican Battle Core ni Trainer AI. F3 abre una galería con búsqueda dentro
de esta misma demo y pausa al jugador. F1 permite configurar equipos/encuentros.
El pack local no se publica automáticamente y no está certificado para exportar:
véase [VISUAL_CATALOG.md](VISUAL_CATALOG.md). Sin pack, se marca recurso pendiente,
sin sustituir espaldas por frontales ni una especie por otra.
Ya hay lanzamiento/captura, retirada/aparición, debilitamiento y huida con efectos
compartidos sobre los recursos existentes. También hay efectos geométricos
provisionales para los 18 tipos de movimientos, según su categoría y los eventos
reales, sin sustituir imágenes ni certificar las mecánicas de todos los movimientos.
Los resultados siguen siendo del dominio;
véase el gate y los límites en el cuaderno visual. Aún no hay sonido, tienda,
servicio de curación ni save de mapa.

## Validación

Gate focal: `tests/gameplay/visual_field_test_runner.gd` integrado en Godot CI.
Comprueba input real, colisión, 0/100 %, encuentro, identidad de captura, consumo de
ball, vuelta a exploración, cuatro portales, salto y pausa por ajustes.

```sh
godot --headless --path . --script res://tests/gameplay/visual_field_test_runner.gd
godot --path . --script res://tests/gameplay/visual_field_test_runner.gd -- --capture
```

El segundo comando produce capturas reales en `.godot/visual_checks/` para revisión
de ruta, colisiones, combate, resultado de captura, refugio y cueva. No se versionan esas salidas.
La certificación remota pertenece siempre al SHA exacto del PR; los resultados locales
no sustituyen una matriz completa en GitHub. El runner histórico de overworld ya
emitía avisos de recursos/RID al salir en el parent; se distinguen de fallos de gameplay.

## Precisión y correcciones del mapa

`tests/gameplay/map_runtime_test_runner.gd` prueba el salto mediante señales físicas
Area2D y movimiento/input real, no solo invocando `jump_ledge()` directamente.
La reproducción inicial dio 12 fallos: partir ya solapando el trigger mirando a
otro lado no reintentaba; se desplazaba al centro del marcador; un spawn quieto
podía saltar. Se corrige evaluando intención de movimiento dentro de la zona,
comprobando geometría actual para evitar señales de solape retrasadas y conservando
el desplazamiento lateral al aterrizar. No se exige carrerilla.

La ampliación también encontró y corrigió:

- aterrizaje/puerta con destino ocupado: rechazar antes de bloquear o trasladar;
- frame largo que inicia encuentro: detener el movimiento en el primer paso y no
  publicar pasos posteriores mientras el combate ya bloquea al personaje;
- apertura de ajustes por ratón durante fundidos: aplicar la misma guarda de bloqueo
  que al teclado;
- medición de tiempo en hierba: recortar cada segmento a los límites reales, incluyendo
  entradas/salidas parciales, sin aproximarlo por su punto final;
- diagnóstico de dirección de salto rechazada: no escribir una línea redundante por frame.

La matriz cubre distancias de 1/8/32/56 px; cinco posiciones de ancho; salto
horizontal; sentido inverso; bloqueo/desbloqueo; quietud; tecla mantenida; paredes
en los cuatro bordes; movimiento simulado a 20/30/60/120 Hz; pasos exactos;
bordes de hierba; puerta activada caminando; pausa y Escape; captura duplicada;
retorno a exploración y ausencia de encuentro por estar quieto.

Las frecuencias se prueban con el servicio real y RNG de semilla fija:

| Probabilidad configurada | Tiradas | Encuentros | Observado |
|---|---:|---:|---:|
| 0 % | 40 | 0 | 0 % |
| 5 % | 4.000 | 181 | 4,525 % |
| 15 % | 4.000 | 587 | 14,675 % |
| 30 % | 4.000 | 1.147 | 28,675 % |
| 100 % | 40 | 40 | 100 % |

El margen de regresión es cinco desviaciones binomiales respecto a la configuración;
la secuencia es reproducible, no una certificación de todas las posibles semillas
ni un argumento para considerar cerrado el balance. No se modifica la probabilidad
del juego para forzar los resultados de la muestra.

```sh
godot --headless --path . --script res://tests/gameplay/map_runtime_test_runner.gd
```

El gate queda incluido en Godot CI. El traslado solicitado al SSD se realiza después
de validar la entrega: la copia activa será un clon independiente, sin depender del
repositorio antiguo de `F:` para sus objetos Git. No se mezclan sus cambios locales.

## Siguiente trabajo de producto

Primero jugar y ajustar legibilidad, escala y frecuencia con esta demo. Mantener
la superposición F2 y las pruebas de movimiento como gate al cambiar geometría.
Quedan pruebas de contenido para cada mapa futuro (spawns/puertas, destinos libres,
zonas, NPC y rutas de escape), pulido del feedback visual y servicios de curación. Después,
GF1-A..F del roadmap para inicial, mapas configurables, NPC/eventos, servicios y
save de mundo. El contenido/arte final se incorpora de forma selectiva.
