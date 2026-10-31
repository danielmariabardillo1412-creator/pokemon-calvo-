# Backend nativo de combate

## Vigente: perfil conjunto y barrido final — 2026-10-28

`unified_profile.cjs` registra `gen9calvounifiedv1` y
`gen9calvounifieddoublesv1` mediante `Dex.formats.extend`. Su único hook de
disponibilidad permite Dinamax en esos perfiles Gen9, conservando condiciones,
fórmulas y permisos por equipo del runtime fijado. No cambia el comportamiento
de Gen8/Gen9 históricos ni copia archivos de mods comunitarios. Los snapshots
unificados fijan el orden de `formatid` también antes del primer turno.

El mapa normal usa el perfil conjunto; los guardados anteriores conservan su
formato. El backend valida Z por puesto activo, incluidos objetivos y bloqueo
de Z de estado en el segundo activo. Los 900 permitidos pasan ejecución positiva
y proyección Godot; informe `docs/current/UNIFIED_MOVE_SWEEP.json/CSV`.
Gate `run_unified_sweep.py`; límites y políticas en `docs/current/BATTLE_PROFILE.md`.
No se habilitan Mega/Ultra/Tera ni el presupuesto común propuesto en este bloque.

## Antecedente: camino nativo de dobles — 2026-10-27

`doubles_backend.gd` reutiliza transporte, prepare/commit y proyección del backend
común, con formato `gen9doublescustomgame` y header `showdown_doubles_v1` separados
de individuales. Se envían cuatro acciones y objetivos firmados en una transacción;
no se reimplementan mecánicas en GDScript. El mirror conserva cuatro identidades
activas, posición de cada cambio y eventos nativos `swap`. Individuales rechaza
checkpoints de dobles. Las reacciones de aventura y mecánicas especiales quedan
fuera de este perfil explícito.

F12 del mapa normal usa clones y checkpoint atómico propio; el modo histórico
queda bajo `--legacy-field`. 44 casos nativos / 454 checks Godot / 130 UI / 196 GPU;
regresiones de mapa y persistencia PASS. Gate vigente `run_doubles_integration.py`,
informe `docs/current/NATIVE_DOUBLES_INTEGRATION.json`.

## Antecedente: dueño de mapa y guardado — 2026-10-27

La entrada principal y `JUGAR_DEMO.cmd` abren el mismo campo con conexión nativa.
`field_native_bridge.gd` enlaza pasos/encuentros/entrenador y la presentación
existente; `field_native_session.gd` conserva además consecuencias del entrenador
sobre sus objetos originales y contadores de sueño observados. La IA sigue básica.

`field_native_save.gd` encapsula la colección SaveV2 existente y mapa/RNG/entrenador/
combate nativo/bolsa provisional en una escritura atómica del serializador
existente. El repositorio SaveV2 expone su reconstrucción sin IO para esa carga;
no se reimplementan inventario, PC ni fórmulas. Se valida y restaura un candidato
antes de sustituir la campaña activa. No se importan automáticamente archivos del
laboratorio ni se cambia el contenido de guardados anteriores.

Sueño importado requiere `{version,start_time,time}` observado por el nativo;
el estado inicial se restaura sin un nuevo sorteo. Un contador histórico sin
procedencia continúa rechazado. PP/PS temporales y gastos usan los contratos
anteriores; el diario se reconstruye con cantidades enteras al cargar JSON.

Default Gen9; `--battle-format=gen8customgame` prueba el campo en Gen8 con Dinamax.
No supone un perfil híbrido decidido. Once acciones de dobles aún requieren su
camino nativo Godot; la IA profesional y reglas custom no se activan aquí.
Compatibilidad histórica solo con `--legacy-field`, sin fallback ante errores.

Gate/reporte: `run_field_integration.py`, `verify_field_integration.py`,
`docs/current/FIELD_NATIVE_INTEGRATION.json`. 118 checks headless, 123 GPU/cinco
capturas, ocho checks de reloj y regresiones de SaveV2/núcleo/combate PASS.

## Antecedente: Z de daño — 2026-10-27

`JUGAR_COMBATE_Z.cmd` equipa cristales existentes. `canZMove` nativo decide
compatibilidad; `z_move_id` aplica daño-only y resuelve aliases físicos/especiales.
Z de estado/Extreme Evoboost se rechazan antes de preparar y en la proyección;
los normales de estado permanecen. Cristales `_z_held` tienen alias explícito;
`_z_bag` no se convierte en objeto equipado. La escena carga la capa regional
validada para Raichu de Alola. Se reutilizan clips, sin sustituciones de imágenes.

Uso único por equipo, PP, cristal conservado y snapshots siguen siendo nativos.
Protección recibe daño reducido; inmunidad puede consumir Z sin daño. No se
implementa un presupuesto compartido Mega/Z/Max. 50 Z con usuarios actuales.
El usuario excluye los ataques de Ultra-Necrozma y Pikachu con gorra y Cerco
Dimensión de Hoopa Desatado: no importar las formas para habilitarlos. Son
exclusiones, no pendientes. Extreme Evoboost sigue excluido por ser de estado.
Quedan 889 acciones de individuales ensayadas, 11 de contexto doble y 19 excluidas.

Gate actual: `python tools/showdown_engine_probe/run_z_moves.py`, o verificar
evidencia con `verify_z_moves.py`. Reporte consolidado: `Z_MOVE_INTEGRATION`.
Los informes previos son históricos y esperaban Z pendientes. El mapa habitual
no cambia de backend en este lote. No confundir integración opt-in con migración.

## Vigente: conexión de movimientos y perfiles

Los 12 bloqueos identificados están corregidos por protocolos compartidos, alias,
PS y estados temporales. Divide Dolor conserva PS de ambos; copias usan slots
nativos y al persistir se leen baseMoveSlots. Transformación copia apariencia/
estadísticas/PP y revierte; Sustituto/Relevo usan observaciones nativas de PS con
creación/daño/rotura múltiples en el mismo turno. No se sustituye el motor ni se
reprograman sus fórmulas. La interfaz compartida añade metadatos de salud y una
marca visual Dinamax; el mirror sigue siendo solo presentación.

`Backend.new(catalog, format)` y `Session.new(catalog, player, format)` admiten
`gen9customgame` (default) y `gen8customgame` explícito. Encabezado e interior del
guardado deben coincidir con el perfil: no mezclar Gen8/Gen9. Los 19 Maxi son
acciones **generadas al activar Dinamax**, no slots aprendidos como un ataque
normal. `JUGAR_COMBATE_MAXI.cmd` abre la misma escena con Gen8 y el selector
Dinamax; usa clips existentes, PS nativos y vuelta a HP base mediante la función
nativa getUndynamaxedHP. Representación de tamaño 1,35 provisional, sin crear arte.

Plegaria Vital permite elegir una identidad KO cuando el request nativo indica
`reviving`; no se interpreta como relevo ordinario. Se prueba KO real, sustitución,
elección, revivir y liquidación. Las restricciones custom de muerte/vidas se
definirán después; esta ruta normal no las inventa. Importar KO inicial de un
guardado previo y otros límites declarados siguen siendo trabajo independiente.

Evidencia vigente `MOVE_CONNECTION_REPAIR.json/CSV`: 820 ordinarios ensayados en
individuales, 19 Maxi Gen8, 11 positivos en dobles nativos sin UI doble Godot,
1 exige Hoopa Desatado que falta en datos/arte, 53 Z pendientes y 15 descartados.
El texto del usuario confirma Maxi; no autoriza decidir el conjunto de Z.
No se sustituye la imagen de una forma ausente ni se eliminan ataques por necesitar
otro escenario. Un positivo de fixture no certifica todas las interacciones.

Reproducción completa: `python tools/showdown_engine_probe/run_move_connections.py`.
Verificar evidencia existente: `python tools/showdown_engine_probe/verify_move_connections.py`.
Gate: 99 dedicados, 51 GPU/8 capturas, 100 backend, 86 aventura, 120 medicinas,
23 GPU mochila y 20.809 playback, más Node 21/10/7 PASS. La aventura habitual
mantiene el backend anterior; no se migran partidas ni se publica en GitHub.

## Antecedente: medicinas básicas

La prueba de aventura incorpora Mochila y `ShowdownAdventureSession.use_item`:
15 objetos, objetivos vivos propios activos/reserva, slot para Éter. Perfil
compartido `modules/inventory/battle_medicine_profile.json`; valores de las cinco
pociones comprobados contra BattleEffectRegistry. Las descripciones canónicas
antiguas de Super/Hiperpoción no gobiernan las cantidades modernas 60/120.

El trabajador aplica HP/estado/PP sobre un candidato nativo, seguido de una sola
respuesta rival y residuales. No existe un parche arbitrario de HP desde Godot.
No efecto/Embargo/KO/objetivo ajeno/slot inválido rechazan sin gasto. Bloqueo Cura
no bloquea pociones. Los eventos de una reserva se limitan a su propietario.
La capa de inventario valida posesión; este RPC local no es un límite de seguridad
multijugador. Se mantiene NPC básico y no se toca la IA profesional.

Checkpoint de aventura schema 2 añade hash de perfil y diario de consumos, validado
contra la bolsa original. Esquemas previos se rechazan explícitamente. Las marcas
horarias `t:` se canonizan al serializar: no son estado de juego y ya no causan
divergencia entre dos continuaciones separadas por un segundo real. Reglas/RNG
se conservan. Gate actual `SHOWDOWN_MEDICINE_INTEGRATION.json`: 120 Godot,
21 Node, 23 GPU/5 capturas, 86 aventura y 100 backend PASS; informes previos históricos.

Faltan otros grupos de objetos (incluido Revivir), uso fuera de combate,
propietario de mapa/SaveV2 y fronteras previas del motor. La colección del launcher
continúa en memoria, no una partida persistida de campaña. Prioridad: base de
Pokémon primero; IA profesional, cuatro vidas y desaparición de muertos después.

Estado: 2026-10-27. Combate jugable independiente dentro del mismo proyecto,
con nuestros Pokémon, datos, recursos revisados y reproducción visual existente.
El arranque habitual y `AuthoritativeBattleServer` conservan su comportamiento.

## Antecedente: sesión de aventura optativa

`JUGAR_AVENTURA_SHOWDOWN.cmd` abre `showdown_adventure_lab.tscn`: encuentros
sucesivos sobre una colección real en memoria con captura, bolas, PC, huida,
PS/PP persistentes y experiencia. Reutiliza nuestros servicios de dominio,
incluidas las animaciones de captura/huida. No guarda la colección en disco ni
activa el backend en el mapa habitual. El laboratorio anterior sigue disponible.

La API `modules/gameplay/showdown_adventure_session.gd` ofrece `begin_wild`,
`begin_trainer`, `submit`, `capture`, `flee`, `settle_finished_battle` y
`snapshot`/`restore_saved`. Cada instancia representa un combate. Inyectar la
colección, catálogos, semilla nativa y semilla de aventura desde su propietario.
No filtrar equipos con KO borrando criaturas: se omiten solo al iniciar el motor
y se conservan en el equipo real, sin revivir ni recibir experiencia.

La sesión mantiene clones y una bolsa transaccional. Publica sobre los objetos
originales una sola vez al capturar, escapar o liquidar un combate terminado.
Comprueba cambios de colección al entrar, antes de confirmar una preparación
nativa y antes de publicar el resultado. Un cambio concurrente bloquea la
publicación; nunca sobrescribe una mochila ajena. El guardado de sesión exige
la misma colección base, partida nativa, bolsa gastada y estados RNG como strings
de 64 bits. Es un checkpoint complementario a SaveV2, no una migración de ese
formato ni una garantía contra manipulación de archivos locales.

Showdown no incluye captura/mochila/huida de aventura. El puente añade solamente
una reacción de singles al inicio del turno: un pass interno de la acción externa
ya validada, elección legal rival y turnLoop/residuales/RNG originales. Rechaza
reemplazos pendientes, continuaciones, órdenes del jugador adicionales y tipos
externos desconocidos. La API pública de juego obliga a pasar por capture/flee;
el usuario no puede elegir pass ni obtener turnos gratis.

Liquidación usa BattleOutcome/ProgressionSystem existentes. Adapta la etiqueta
de ganador de la vista a la identidad que espera el contrato histórico; derrota
y empate no conceden experiencia. PS/PP/estado/objeto retenido se conservan;
se restauran identidad, habilidad original y estadísticas base antes de limpiar
estados temporales. La bolsa solo consume bolas por ahora, no medicinas.

Gate vigente: `docs/current/SHOWDOWN_ADVENTURE_INTEGRATION.json`, 86 sesión,
28 GPU/5 capturas, 7 transacciones de reacción, y regresiones 100 Showdown,
472 core, 20.809 playback y 628 corpus IA PASS. `verify_adventure.py` verifica
logs sin errores inesperados, hashes y límites. Los informes previos reflejan
sus versiones de código, no los hashes actuales.

Pendientes antes de usarlo como aventura normal: medicinas, IA profesional,
propietario de mapa/SaveV2, cuotas por zona/vidas y demás reglas de campaña.
No se afirma equivalencia completa de todas las normas de Pokémon. Capturar
un Pokémon dormido conserva el estado y reloj observado; su reentrada al motor
sigue bloqueada hasta definir la conversión del sueño persistente. Los límites
de formas/sustitutos y de perfil Dinamax/Gen9 siguen vigentes.

## Abrir la prueba

Ejecutar `JUGAR_COMBATE_SHOWDOWN.cmd` en la raíz del proyecto, o abrir
`res://scenes/visual/showdown_battle_lab.tscn` con Godot 4.7.

El equipo de prueba es Charizard/Blastoise contra Snorlax/Gengar. Se pueden
elegir movimientos, hacer cambios voluntarios o continuar cambios obligatorios,
terminar el combate y guardar/cargar. El botón de guardado utiliza únicamente
`user://showdown_lab_battle_v1.json`; no escribe en las partidas de campaña.
El rival de laboratorio elige su primer movimiento legal a partir de su propia
solicitud; todavía no utiliza nuestra IA profesional.

Dependencias actuales: Node en `D:/Herramientas/NodeJS/node.exe` (se puede
sobrescribir con `POKEMON_CALVO_NODE`) y la instalación fijada de
`@pkmn/sim@0.10.11` en `.godot/battle_reference/runtime`. El launcher usa el
Godot instalado en C:. Es una prueba local de desarrollo, no un exportado
autónomo para entregar al amigo. Los avisos MIT y las versiones siguen en
`tools/battle_reference/THIRD_PARTY_NOTICES.md` y su package-lock.json.

## Fronteras

- `native_engine.cjs`: implementación compartida con el laboratorio anterior.
  Showdown calcula las mecánicas; aquí se convierten entradas, decisiones,
  checkpoints y vistas. No se vuelven a escribir fórmulas de movimientos.
- `worker.cjs` / `pipe_client.gd`: proceso local persistente y RPC JSONL, sin
  sockets. Handshake antes de transmitir equipos/snapshots; fragmentos de 1 KiB
  para los límites de pipe de Windows, espera por frames y cierre del proceso
  propio. Límites actuales: 256 KiB por petición y 8 MiB por respuesta.
- `showdown_backend.gd`: fachada asíncrona opcional. Conserva autoridad en el
  snapshot nativo. `presentation_state` es una copia BattleState para la UI,
  nunca una partida que deba ejecutar el servidor histórico o usar la IA para
  acceder a secretos. Los CreatureInstance originales no se modifican.
- `event_adapter.gd`: traduce mensajes comunes a BattleEvent, con PS/PP
  observados y sin recalcular efectos. Las transiciones no representadas se
  rechazan explícitamente, no se habilitan por tener una fila en el catálogo.
- `showdown_battle_playback.gd`: reutiliza la reproducción y los clips actuales;
  añade confirmación de los efectos nativos de protección/pantalla y el rótulo
  de rival. No modifica renderer, sprites, manifiestos ni admisión del backend viejo.

Cada turno pasa por **preparar → validar proyección/eventos → confirmar**.
El trabajador calcula un candidato separado; el combate original no cambia
hasta que la fachada lo acepta. Tokens caducados/repetidos y revisiones antiguas
se rechazan. Se descartan candidatos al abortar/cerrar. Un efecto de forma no
representado, por ejemplo Transformación, no deja un turno parcialmente aplicado.

Si el trabajador desaparece o una confirmación es incierta, se conserva la
última acción confirmada, se bloquean nuevas acciones y aparece «Reanudar
combate». Reanudar restaura ese checkpoint en un proceso nuevo. No se cambia
silenciosamente al otro simulador ni se inventa una continuación de RNG.

El guardado tiene identificador y versión de backend, versión de simulador,
perfil Gen9, revisión, hashes de datos/política, criaturas de origen y estado
nativo. Rechaza archivos de otra versión, reglas distintas y orígenes malformados.
Se prueba también guardar/cargar durante el relevo de Ida y Vuelta, antes de
que el rival complete el turno.

## Evidencia cerrada

`docs/current/SHOWDOWN_BACKEND_INTEGRATION.json` contiene el informe vigente.
Gate GPU: 100 comprobaciones, 13 capturas revisadas y victoria del equipo de
prueba. Incluye:

- Protección sin pérdida de PS; Reflejo con el clip revisado; PP exactos.
- Cambio voluntario/Ida y Vuelta, solicitudes de sustitución por KO y respuesta
  pendiente del rival; los botones corresponden a solicitudes nativas.
- Curación, PS exactos del HUD de ambos lados, KO, victoria y guardado terminal.
- Guardado/repetición con eventos y RNG iguales; guardado a mitad de relevo.
- Rechazo atómico de cambios inválidos, revisiones antiguas y transformaciones
  aún no representadas; la siguiente orden válida sigue funcionando.
- Muerte del trabajador y recuperación del último estado confirmado.
- Exclusión de Splash, sin lanzar un proceso al rechazar el equipo.
- Regionales Vulpix de Alola/Darmanitan de Galar, apariencia shiny y su guardado.
- La reproducción visual no modifica el snapshot ni el RNG.

Diez comprobaciones Node independientes cubren preparar/abortar/confirmar,
efectos laterales de Reflejo, tokens repetidos/caducados y limpieza.
La prueba anterior comparte ahora el mismo núcleo y mantiene sus 39 aserciones
Node, 27 Godot y 2.496 ejecuciones/serializaciones nativas. Esto sigue siendo
robustez/conexión, no certificación independiente de todos los efectos del simulador.
Regresiones: 472 core, 20.809 playback y 628 corpus de IA PASS. No se regeneran
datos para ocultar los nueve fallos DATA V3 conocidos; sus fuentes no cambiaron.

Los 233 archivos de código/configuración/datos/manifiestos que ya existían al
iniciar el trabajo conservan sus hashes. Se añaden los módulos y escenas
optativos. El juego habitual sigue en 620 movimientos admitidos y 230 pendientes
de mecánica; esas cifras no se reducen por esta prueba.

## Fronteras del laboratorio de combate anterior

Conectar captura/mochila/huida y conciliación de resultados de campaña, sin
rehacer sus sistemas. Conectar después los espacios de acciones, observaciones,
mundos plausibles y presupuesto de búsqueda de la IA profesional. Nunca enviar
el snapshot secreto real a una búsqueda que deba trabajar con incertidumbre.

El perfil de este piloto es Gen9 de individuales. Dinamax/Maxi siguen probados
en el laboratorio Gen8 y pendientes de un perfil conjunto explícito. También
quedan formas y movimientos temporales, sustitutos y otros mensajes no
representados, relojes heredados, objetos ajenos al simulador como Bola Humo y
empaquetado/distribución. No se inicia esta vía con Pokémon ya debilitados de
campaña ni se convierten sus partidas históricas; los KO ocurridos dentro de la
prueba sí se resuelven y guardan nativamente. El mirror no reproduce todos los
campos internos del simulador y no sirve como modelo autoritativo de búsqueda.

El objetivo de esta fase está cumplido: un combate completo visible y guardable
con Showdown dentro del proyecto, sin sustituir todavía las sesiones normales.
