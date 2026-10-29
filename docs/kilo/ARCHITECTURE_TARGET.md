# Mapa de la reorganización T001–T006B — histórico cerrado

Plan aceptado en 208c06c0. El texto siguiente conserva el diseño y los límites
de cada etapa; sus frases de autorización no son tareas vigentes. Estado actual:
`docs/current/START_HERE.md`. No relanzar ejecutores ni repetir etapas cerradas.

## Recorrido real de la demo

`project.godot` abre `scenes/visual/field_demo.tscn`. Su script
`scenes/visual/field_demo.gd` hereda `scenes/overworld/technical_overworld.gd`.
La base inicializa catálogos, colección, encuentros, herramientas técnicas y
sesiones anteriores. La derivada añade arte, HUD, teclas de ensayo, galerías,
mochila y `field_native_bridge.gd`.

Con la configuración normal, el puente abre `modules/gameplay/field_native_session.gd`,
que amplía `showdown_adventure_session.gd` y `showdown_backend.gd`. El worker Node
resuelve el combate nativo; su checkpoint se traduce en eventos y una vista
BattleState. Al finalizar, la sesión publica consecuencias en la colección.
Los relojes observados de sueño pertenecen al puente de campo y se conservan
en su guardado. No mover esta propiedad durante el piloto.

La mochila visual usa `modules/inventory/field_item_service.gd` sobre
PlayerCollection. Este servicio valida, prepara y publica los cambios de equipo,
MT, evolución y efectos de campo. `field_item_effects.gd` trabaja sobre una copia
preparada. La UI no debe convertirse en una autoridad nueva de esos cambios.

## Problemas de integración observados

Hay separación útil en dominio, datos, reglas y almacenamiento. Las conexiones
del mapa acceden a bastantes miembros internos de la escena y del director.
La escena heredada mezcla laboratorio, configuración y puesta en marcha. La
construcción del HUD, sus textos y controles de ensayo viven en field_demo.
Parte de la arquitectura escrita aún describe el motor anterior como actual.

El objetivo es reducir conocimiento cruzado por etapas, sin cambiar reglas.

## Destino propuesto

1. HUD como vista de presentación: construye controles y recibe datos/callbacks.
2. Diagnóstico como componente separado: ensayos explícitos, fuera del flujo de partida.
3. Interfaz pública de campo para colección, estado de actividad y servicios de UI.
4. Coordinación de combate con un contrato de campo explícito, sin buscar miembros
   internos del laboratorio. La propiedad y publicación del estado conservan su autoridad.
5. Ruta anterior claramente identificada como laboratorio, conservada hasta probar
   qué dependencias se pueden retirar o aislar.
6. Documentación vigente y puntos de entrada únicos para cada recorrido.

T001–T005 y T006A están aceptados. Solo persistencia/publicación/recuperación del
punto 4 según el contrato T006B están autorizadas; no reformar el arranque.

## Contrato histórico del piloto T001/T002 (aceptado)

Crear `scenes/visual/field_hud.gd`, una vista que extiende Control. Su interfaz
pública debe permitir construir los controles con Theme y un diccionario de
Callables, exponer las referencias UI necesarias y crear botones de acción.
La escena conserva los callbacks de juego y los datos. La vista no retiene una
referencia al mapa, a PlayerCollection, al director o a una sesión de combate.

Durante T001 se conservan los alias existentes `_hud`, `_place_label`,
`_frequency_label`, `_observed_label`, `_collection_label`, `_chance_button` y
`_notice_label`. Es una compatibilidad de transición deliberada: el puente y
varias pruebas los usan. No eliminar alias ni migrar sus consumidores todavía.

`_build_hud` se convierte en un ensamblador breve de la vista y sus callbacks.
`_hud_button` puede quedar como delegación a la creación de botones de la vista.
`_refresh_hud`, las teclas, la lógica de ensayos y los guardados permanecen en su
sitio en este primer paso. No mover toda la escena a otra clase con referencia
al mapa como forma de aparentar una separación.

## Superficies protegidas

Datos, catálogos, arte, manifiestos/packs, vetos, perfiles, motor nativo, módulos
de dominio, guardado y pruebas existentes. Las dependencias de Node pueden estar
fuera de res:// como ejecutable, pero el worker y su paquete deben cargar desde
esta copia. No reinstalar ni actualizar paquetes. No borrar archivos por parecer
antiguos, duplicados o desconectados sin un contrato posterior que lo autorice.

## Contrato T003 (aceptado)

El contrato anterior describe lo que ya quedó aceptado. Ahora se autoriza mover
solo el formateo de `_refresh_hud` a FieldHud mediante datos simples, según
`tasks/T003_HUD_RENDER.md`. Las consultas, los cálculos de encuentros y la
traducción de especies siguen en field_demo. El resto del mapa propuesto espera
otra revisión. No cambiar el constructor de controles ya aceptado.

## Contrato T004 (aceptado)

La selección de ensayos se separa en FieldDiagnostics, un RefCounted sin referencia
al mapa ni a sus servicios: catálogo constante, planes de ensayo y siete cursores.
La escena conserva la autoridad sobre configuración, packs, colección, registros,
avisos y reinicio. No mover esos efectos a un objeto que reciba self ni duplicarlos.
Las firmas de entrada y alias existentes se conservan por compatibilidad.
El contrato completo está en tasks/T004_FIELD_DIAGNOSTICS.md.

## Contrato T005 (aceptado)

La UI de mochila usa una interfaz pública en field_demo. Las lecturas resuelven
la colección actual por llamada; no existe otra colección ni un estado de combate
copiado. El dueño enlaza FieldItemService con la colección y el diccionario de
relojes originales, y un guard vivo de actividad e identidad. La mochila conserva
su servicio compatible, sin leer miembros privados del mapa o del puente.
La carga/publicación del puente permanece intacta hasta T006. Contrato completo:
tasks/T005_FIELD_API.md. No se autoriza la migración general de todos los consumidores.

## Contrato T006A (aceptado)

El puente conserva orquestación, sesión nativa, presentación, busy/kind y relojes.
El mundo conserva colección, director/RNG de encuentros, métricas y recorder.
Las operaciones del mundo se expresan en métodos públicos concretos del dueño,
sin exponer director/sesiones/recorder a consumidores. Las cuatro funciones de
persistencia/recuperación del puente quedan textualmente intactas hasta T006B.
No eliminar herencia/laboratorio: documentar el recorrido real y sus dependencias.
Contrato: tasks/T006A_NATIVE_BRIDGE_RUNTIME.md. Aceptar A no cierra todo T006.

## Contrato vigente T006B

El dueño valida el mundo/tablas y publica las referencias de mapa en una operación
síncrona con precondiciones ya satisfechas. El puente mantiene disco, candidato,
worker, relojes y presentación; sus esperas de restore y cierre preceden a la
publicación del mapa. El serializer, esquema, hashes y settlement no se cambian.
La actualización final de presentaciones heredadas mantiene su posición después
de asignar clocks/view del puente. Contrato: tasks/T006B_NATIVE_PERSISTENCE.md.
No equivale a borrar legado, empaquetar, publicar en GitHub o cerrar mecánicas pendientes.
