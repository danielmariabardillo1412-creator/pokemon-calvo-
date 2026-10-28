# T001 — extraer la construcción del HUD sin cambiar comportamiento

Autorización: ejecutar después de baseline PASS. Después pasar a T002.

## Propósito

Reducir la responsabilidad de field_demo: la vista construirá sus controles;
el mapa seguirá decidiendo qué hacen y qué datos muestran. El juego debe verse
y responder igual. No se añaden funciones ni se corrigen fallos ajenos al bloque.

## Archivos autorizados

- Modificar `scenes/visual/field_demo.gd` exclusivamente en la precarga de la nueva
  vista, `_build_hud`, la delegación de `_hud_button` y los alias UI necesarios.
- Crear `scenes/visual/field_hud.gd` y su `.uid` persistente.
- Crear `tests/gameplay/field_hud_contract_test_runner.gd` y su `.uid`.
- Actualizar `docs/kilo/PROGRESS.md`, estados de `TASKS.json` y evidencia del bloque.

No modificar `.tscn`, proyecto, datos, servicios, puente, catálogos, módulos,
pruebas existentes, verificadores, sellos o documentos históricos.

## Preparación y mapa de llamadas

Leer la versión de `_build_hud` y `_hud_button` de field_demo, la llamada dentro
de `_ready`, las referencias de `_refresh_hud` y las tres acciones añadidas para
guardar/cargar/mochila después de crear el puente. Leer solo las referencias UI
de field_native_bridge, sin editarlo.

Antes de cambiar, guardar en la evidencia una lista de callbacks y los miembros
que usan otros componentes. Comparar con el mapa previsto; una dependencia
adicional que obligue a editar fuera de la lista exige detener la tarea.

## Pasos de construcción

1. Crear una vista Control con un método de construcción que reciba Theme y
   acciones explícitas. Usar claves `tera`, `elemental`, `external`, `frequency`,
   `restart`, `settings`, `geometry`, `gallery`, `report` para los nueve botones
   originales. No invocar acciones al construir la vista.
2. Trasladar la construcción de controles desde `_build_hud`: textos, estilos,
   tamaños, anclajes, offsets, orden de nodos, mouse_filter y fuentes se conservan.
   El nodo raíz sigue llamándose FieldHUD. La exportación del informe y su aviso
   se proporcionan mediante el callback `report` del mapa.
3. Exponer referencias públicas a place_label, frequency_label, observed_label,
   collection_label, chance_button y notice_label. La escena asigna sus alias a
   estas mismas instancias, no a copias o controles duplicados.
4. Mantener el HUD en el mismo lugar del CanvasLayer. Conservar la adición de
   guardar/cargar/mochila a coordenadas (20,99), su orden y sus callbacks en la
   escena después de crear el puente. No trasladar la inicialización del puente.
5. Mantener `_hud_button` como una delegación breve si sigue siendo necesario
   para esos botones. La vista puede ofrecer `create_action_button(parent,text,callback)`.
   No cambiar los métodos del mapa que reciben los callbacks.
6. Comprobar que `_process`, `_refresh_hud`, configuración, galería, mochila,
   teclado y callbacks de aviso siguen usando los mismos controles.

Los nombres exactos del método de construcción pueden resolverse localmente,
pero los límites de propiedad, callbacks, alias y comportamiento son obligatorios.
Evitar un framework genérico, un bus global, una clase que conozca todo el mapa
o una migración simultánea a señales nuevas.

## Pruebas nuevas con sentido

El contrato aislado debe construir el HUD sin cargar catálogos, partida ni
backend. Confirmar los nueve botones, sus acciones conectadas una sola vez,
que construir no dispara callbacks y que las referencias públicas corresponden
a los controles de la vista. Una acción de prueba debe poder observarse desde
el callback proporcionado. No escribir una prueba por cada línea trasladada.

La conexión con el mapa se comprueba mediante las suites existentes del grupo
quick y después el grupo completo T002. No usar el contrato aislado como prueba
de que mochila/combate/guardado estén integrados.

## Aceptación

- La escena construye una sola vista FieldHUD con el aspecto y orden anteriores.
- Los callbacks de los nueve botones conservan sus destinos.
- Los alias usados por puente y pruebas apuntan a los controles reales.
- La vista no conoce estado mutable de juego ni llama al mapa por miembros internos.
- `python tools/architecture_handoff/run_checks.py --phase T001 --quick` da PASS.
- El test nuevo se ejecuta por Godot y da PASS; se guarda su log.
- El guard de archivos protegidos da PASS y no hay cambios fuera de alcance.

Actualizar progreso con rutas y resultados. No declarar aceptada toda la
reforma. Un commit local descriptivo puede cerrar T001 si sus comprobaciones
pasan; no incorporar recursos generados ni trabajos inesperados.
