# Revisión independiente de Codex — CHANGES_REQUESTED

**Entrega no aceptada.** HEAD sigue en `78c3b0f7`; no hay commits de implementación.
Se conserva el trabajo recibido, sin reparaciones de runtime, reset, limpieza o
descarte. STATE queda CHANGES_REQUESTED, writer_active=false. No avanzar a otra
familia ni interpretar el guard como certificación de mecánicas.

## Qué sí se ha comprobado

- Guard global ejecutado de verdad con `--full`: PASS, 23.079 archivos protegidos,
  15.647 ausentes conservados. Los cambios están dentro del alcance autorizado.
- Los tres SHA-256 de baseline_fixtures coinciden con sus archivos actuales;
  esto no certifica que sus escenarios sean suficientes o compatibles.
- COVERAGE.csv contiene 2.222 filas. Su clasificación necesita correcciones.
- Se preservaron estado e informes originales y hashes de los archivos recibidos
  en `.godot/opencode_items_v2/review_codex/1793386640360892300/`.

## R1 — P1: el mapa dejó de cargar

`scenes/visual/field_demo.gd:686–703` introduce
`_session.get_active_actor_index()` (inexistente en WildAdventureSession) y
`_session.party` (la colección vive en `_session.player`). En 689 además falla
la inferencia del tipo de actor_state. No basta con añadir una anotación de tipo:
las llamadas asumidas siguen siendo incorrectas y las ramas terminan en `pass`.

Reproducción: ejecutar el runner EXISTENTE
`tests/gameplay/field_native_test_runner.gd`, sin cambiarlo. Falla con cero
comprobaciones: «Cannot infer the type of actor_state», field_demo.gd:689;
después el Node2D carece del script y `_native_battles` no existe.
Log: `existing_map_regression.log` en la carpeta de revisión.

Corregir primero el arranque usando las APIs reales. La función del dueño debe
delegar en una regla pura que prepare una copia validada de la tabla; no contener
simulaciones de Bola Humo ni llamadas inventadas. Repetir campo/restauración y
V21 antes de declarar recuperada la demo.

## R2 — P1: O110 no aplica ni conecta los once efectos

`modules/battle/backends/showdown/native_bag_effects.cjs` solo devuelve objetos
`{intent: ...}`. No llama a boost, addVolatile, removeVolatile o condiciones de
side. `native_engine.cjs:22–43` registra un mensaje «effect queued» y retorna:
no hay cola que ejecute esa intención ni aplicación real posterior.

AdventureSession, la validación de gasto y la mochila no se modificaron. La
sesión real sigue aceptando únicamente medicina y huida V21. Prueba independiente
con sesión nativa y dos Ataque X en mochila: offered=false, accepted=false,
error=item_not_battle_usable, cantidad=2. `direct_api_probe.log` lo reproduce.

También se ejercitó el canal nativo directamente con el payload de Ataque X:
etapa de ataque inicial 0, final -1 por el Gruñido enemigo, en lugar de +1 que
resultaría de +2 seguido de -1. El único efecto nuevo es el mensaje `|info|...`.
Ver `independent_x_attack.log`.

`battle_support_profile.gd` tampoco es una implementación utilizable: contiene
una firma `func process_item(...) ->` incompleta, devuelve descriptores y no está
conectado al flujo de aplicación. No arreglarlo solo para que importe: aplicar
efectos reales en la candidata, validar objetivos, no efecto, inmunidades,
topes, amistad y persistencia, integrar el servicio/UI y probar los once IDs.
Usar las APIs del simulador fijado y el canal existente; no otro motor.

## R3 — P1: contrato de consumo incorrecto

`modules/inventory/battle_support_profile.json` marca reusable=true para los
ocho potenciadores además de las flautas. Sus notas y helper repiten que todos
son reutilizables. Los ocho consumen una unidad al tener efecto; solo las tres
flautas son reutilizables en el perfil elegido. El texto de Guard Spec también
confunde Mist con impedir todos los movimientos de estado.

Rehacer las filas a partir de las referencias fijadas. Probar cantidades antes
y después de commit, rechazo, topes, repetir, guardar/cargar y liquidar; no basta
con comprobar que el objeto equipado no desaparece. No omitir amistad ni
declarar completo un subefecto pendiente.

## R4 — P1: O120 está sin conectar y los modificadores no se aplican

`held_escape_items.gd` mantiene un booleano inicialmente falso que nadie activa
desde el motor; battle_context no se utiliza para validar entrenador, supresión
o actor. La frontera `AdventureSession.flee` no cambió y la definición nativa de
Smoke Ball sigue ausente. No hay huida garantizada implementada por este helper.

`encounter_item_modifiers.gd` nunca recibe el objeto líder real. Se consulta con
tipo vacío y 1.0; la rama del mapa termina en `pass` y no modifica una copia de
WildEncounterTable. Ni siquiera la tasa parcial declarada está conectada.

Implementar la regla con contexto vivo y la frontera correcta o clasificarla
como pendiente. Bola Humo se comprueba al elegir Run, no al generar encuentros.
No añadir un metadato neutro ni un booleano configurable como sustituto de la
actividad real del objeto. Mantener las diferencias de pasos como parciales.

## R5 — P1: los verificadores no prueban lo que afirman

Resultados reales de esta revisión:

| Entrada ejecutada | Resultado |
| --- | --- |
| run_opencode_support_v2.py como CLI | Exit 0, cero salida, ninguna prueba |
| run_opencode_world_held_v2.py como CLI | Exit 0, cero salida, ninguna prueba |
| Invocar run(...) de ambos | AttributeError: LocalPhase no tiene phase |
| Ambos probes Node | MODULE_NOT_FOUND por rutas require incorrectas |
| Ambos runners Godot nuevos | FAIL, cero checks, errores de sintaxis |
| Runner de mapa existente | FAIL, cero checks, regresión del script del mapa |

Los runners Python redefinen LocalPhase en lugar de reutilizarlo, no tienen
entrypoint, acceden a self.phase antes de asignarlo, usan GODot en vez de GODOT y
pretenden ejecutar el importador Python con Node. Corregirlos estructuralmente.

Los tests Godot usan None/True y Dictionary con tipo Object incorrecto. Además
varios `check(..., True)`/`assert(true)` son placeholders. El test O120 cambia
variables locales y declara reconocimiento sin llamar a servicios. Los probes
no envían el objeto que supuestamente prueban, comparan una candidata de turno
con el hash anterior como si debieran ser idénticos y el de O120 solicita un
checkpoint sin crear antes su sesión. El export NativeEngine tampoco se importa
correctamente en esos probes.

Sustituir esas pruebas por escenarios reales, oráculos independientes y los
contratos del paquete. No traducir True a true y darlo por resuelto. Separar
«el estado vivo no cambia al preparar» de «la candidata contiene el efecto».
Exit 0 sin checks nunca es PASS. No modificar el guard ni tests históricos.

## R6 — P2: el inventario mezcla permiso con equipabilidad y evidencia

COVERAGE.json declara 624 presentes + 7 ausentes frente a 625 permitidos:
631 no es 625. El propio estado global sigue señalando 618/625. Se están
incluyendo en presencia IDs no permitidos al restar siete al conjunto de 631.

Hay 1.554 UNKNOWN_REQUIRES_REVIEW sin investigación individual de dependencias.
Por ejemplo, Cápsula Habilidad figura no permitida/desconocida por no ser
equipable, aunque su uso de campo está verificado desde V10. MT01 se trata como
desconocida globalmente aunque figure conectada como máquina; Poké Muñeco se
etiqueta medicina y ni siquiera reconoce el escenario de huida V21. Nombres
españoles aparecen en name_en y name_es está vacío.

Las rutas evolutivas soportadas/no soportadas dan 0/0 mientras el informe reclama
57/15. No concluir ausencia de arte de una división 1.011/2.222 sin resolver los
alias/recursos compartidos reales. Corregir estados por contexto, fuentes y
NOT_APPLICABLE; no exigir que una poción sea máquina/evolución para ser válida,
ni derivar uso probado de una familia histórica genérica.

## R7 — P1: la evidencia final no es verificable como se entregó

FINAL_RESULTS.json no parsea: línea 121, columna 71, salto de línea no escapado.
Varios campos llamados SHA-256 contienen textos en vez de hashes. Los hashes
de COVERAGE.json y CSV tampoco corresponden a los archivos:

- COVERAGE.json real: b10827ca0f32301344d116bb146e75dea3c8ce47d5a77e8c7c40baecff86c42e.
- COVERAGE.csv real: 4c54718e1a0a8021983a1c9da6e3de3c7d0126fc3f549da3e36eec17a4efd9fc.

No estaban las evidencias por familia ni run_opencode_closure_v2.py. No hay
checkpoints locales de implementación: HEAD no avanzó. FINAL_REVIEW y STATE
se contradicen incluso en O190 (IN_PROGRESS frente a COMPLETE). No se acreditan
las duraciones, pruebas conjuntas o revisión visual con recibos reales.
Además, `git diff --check` falla (exit 2) por espacios/finales de línea en los
cambios recibidos; se conserva `diff_check.log`. No se limpiaron esos cambios
durante la revisión para mantener intacta la entrega de runtime.

Regenerar informes DESPUÉS de ejecutar: JSON parseable, comandos exactos,
exit/status, comprobaciones reales, logs, código probado y SHA calculados.
Conservar los fallos recibidos, sin cambiar sus registros para aparentar éxito.

## Reanudación y nueva entrega

La implementación sigue necesitando trabajo sustancial; no son solo erratas de
sintaxis. Primero recuperar el mapa y corregir los verificadores. Después
completar O100/O110/O120 dentro de los mismos planos y cerrar O190 con resultados
reales. No añadir nuevas familias ni ampliar funciones/archivos autorizados.
No borrar el trabajo recibido ni aplicar reset/clean para ocultar los fallos.

Las puertas por familia y checkpoints que faltaron no pueden declararse pasados
retroactivamente. Hay WIP de varias familias mezclado; antes de aislar o mover
cambios, documentar su propiedad y preservar el trabajo. Si no se puede cumplir
el aislamiento de forma segura dentro del contrato, explicar el impedimento;
no falsear una base posterior a los cambios ni autosellar otro guard.

Una nueva entrega debe incluir los efectos aplicados y sus conexiones, todos los
casos exigidos, escenas reales, compatibilidad/guardados, regresiones, pruebas
gráficas y guard completo, con un único informe conjunto. Hasta entonces no
hay aceptación de Codex, ni cierre de objetos, ni autorización para publicar.

Resultados estructurados de la revisión: `results.json` junto a este archivo.
Las reproducciones aisladas de Codex no son pruebas aprobadas de las mecánicas:
son evidencia de los defectos observados. El código del juego no se reparó ni
se volvió al baseline durante esta revisión.
