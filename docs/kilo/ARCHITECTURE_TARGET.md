# Mapa actual, destino y límites

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

Los puntos 1/T001–T003 están aceptados. Solo la parte del punto 2 descrita en
el contrato T004 está autorizada ahora. Los puntos siguientes requieren revisión.

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

## Contrato vigente T004

La selección de ensayos se separa en FieldDiagnostics, un RefCounted sin referencia
al mapa ni a sus servicios: catálogo constante, planes de ensayo y siete cursores.
La escena conserva la autoridad sobre configuración, packs, colección, registros,
avisos y reinicio. No mover esos efectos a un objeto que reciba self ni duplicarlos.
Las firmas de entrada y alias existentes se conservan por compatibilidad.
El contrato completo está en tasks/T004_FIELD_DIAGNOSTICS.md.
