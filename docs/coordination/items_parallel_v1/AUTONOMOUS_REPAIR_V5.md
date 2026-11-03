# IA6 — AUTONOMÍA DE REPARACIÓN V5 / CAMPAÑA_003 (2026-11-03)

**ESTADO: ACTIVADO POR AUTORIZACIÓN EXPRESA DEL USUARIO.** Esta norma reemplaza las prohibiciones anteriores que impedían reparar código necesario para la **propia familia**. No cambia la asignación de IDs, el orden de bloques ni la propiedad de las ramas. Objetivo: una `p` ejecuta un bloque; una incidencia local se diagnostica y repara por su misma IA, sin convertirse en una solicitud administrativa a IA6.

## Principio central
**Cada trabajadora es un agente técnico completo, no una auxiliar que solo escribe tests.** Si encuentra un defecto real, puede investigar y corregirlo **en su propia rama** dentro del componente y comportamiento directamente asociado a los IDs de su campaña, acompañándolo de pruebas reales y revisión del impacto. No necesita pedir permiso a IA6 para cada parche local. No existe permiso para alterar el código de otra trabajadora, ni las reglas globales, ni `main`/V28.

**IMPORTANTE:** una instrucción de IA6 no cambia la ACL real de GitHub. Si una operación devuelve 403/insufficient permissions, rama protegida, token sin escritura o fallo del conector, no afirmar que queda desbloqueada: diagnosticar API, rama, ruta, SHA y permisos; probar solo operaciones permitidas. Si no se puede escribir en su propia rama, reportar bloqueo técnico con mensaje literal; no eludir seguridad ni hacer force push. Commits exitosos previos prueban escritura en esa rama, no autorización para cada endpoint.

## Matriz de propiedad funcional para reparaciones autónomas
| IA | Dominio propio en CAMPAÑA_003 | Reparaciones de producción permitidas **solo en su rama** |
| --- | --- | --- |
| W01 | Objetos equipables reservados | Corregir exclusivamente condiciones, activaciones, consumo y efectos de SUS IDs en el motor/adaptador de equipables, sin modificar bayas, captura, MT ni otras reglas |
| W02 | Bayas reservadas | Corregir exclusivamente disparadores, curación, resistencia/consumo de SUS bayas, sin tocar equipables ajenos, captura, evolución o enseñanza |
| W03 | Poké Balls reservadas | Corregir cálculos, contexto y rechazo/captura dentro de `modules/capture/` para SUS bolas, respaldados por reglas reales; si se requiere editar productores compartidos de sesión/batalla, tratarlo como frontera de integración |
| W04 | Objetos de evolución reservados | Corregir reglas/condiciones de `modules/creatures/progression/evolution_system.gd` y, **solo para rutas de evolución**, `modules/inventory/field_item_service.gd` y helpers específicos, respetando modalidad de nivel, intercambio, objeto equipado, región, tiempo y SaveV2 |
| W05 | MT y libros reservados | Corregir `modules/inventory/field_machine_book_profile.gd` y, **solo para enseñanza de MT**, la sección `teach` del servicio de inventario; mantener las 19 máquinas históricas inactivas, sin cambiar compatibilidades arbitrariamente |

**Propiedad por función, no por archivo completo.** `field_item_service.gd` es compartido: W04 solo evolución y W05 solo enseñanza. W01/W02 pueden compartir subsistema de combate: no reescribir funciones ajenas ni interferir en IDs fuera de su reserva. Una edición de fichero compartido debe registrar diff mínimo y revisar antes si otras ramas activas lo han modificado. Si dos IAs necesitan cambiar la misma función/API, **parar esa modificación concreta y elevar conflicto a IA6**, pero continuar otros bloques independientes si están autorizados.

## Circuito obligatorio de autorreparación (sin IA6 por rutina)
1. **Diagnóstico:** leer error exacto (Godot, Python, Github API, workflow), SHA de tests y log; aislar causa y reproducir. Distinguir error del arnés, regresión real, dependencia del contrato y problema de permisos. No confundir CI `queued` o `cancelled` por nuevo push con fallo.
2. **Corrección mínima:** modificar el test/fixture propio, o el comportamiento de producción de su familia permitido arriba, en su rama exclusiva. Los archivos nuevos y helpers deben estar en el dominio asignado; no crear otro motor paralelo, ni refactor global, ni cambiar catálogo canónico o versiones. Verificar antes de editar una ruta compartida.
3. **Prueba real:** añadir caso que falle antes de la reparación y pase después, conservar todos los casos anteriores y negativos, comprobar consumo/propiedad/SaveV2 si aplica. Publicar commit, diff, recibos y CI automática en último SHA que incluya el código de producción. Afirmar PASS solo de checks ejecutados en ese SHA.
4. **Continuación:** una vez `success` en CI de su rama y sin conflicto, ejecutar el bloque siguiente con `p` sin nueva puerta IA6. Si CI sigue ejecutándose, preparar solo un bloque independiente; si `failure`, intentar repararlo en la misma conversación (hasta encontrar causa), NO esperar por permiso administrativo.
5. **Escalación genuina:** conflicto de edición concurrente de la misma función, cambio de arquitectura/API compartida, norma de combate/Randomlock ambigua, nuevo sistema de evolución no especificado, migración de saves, modificación de políticas/datos, acceso GitHub realmente denegado o fallo no reproducible tras investigar. Parar solo la operación afectada; entregar diagnóstico, paths, SHAs y propuesta mínima, mientras otros trabajos independientes pueden seguir.

## Caso práctico: W04 / Piedra Oval
La modalidad correcta de Piedra Oval NO es automáticamente `use_item` en bolsa: puede depender de **objeto equipado + subir de nivel + condiciones**. W04 **sí está autorizada** a investigar y, si el catálogo y las reglas canónicas del proyecto permiten una implementación inequívoca, corregir la ruta de evolución dentro de su subsistema en su rama, añadiendo positivos/negativos de nivel, tiempo y equipamiento, preservando identidad, consumo y SaveV2 y regresionando las seis piedras previas. **No** inventar una regla alternativa más fácil ni afirmar PASS de un caso documentado como dependencia; si la política de consumo o modalidad del juego no está decidida, registrar la pregunta concreta y seguir el bloque independiente. IA6 no necesita revisar cada paso de diagnóstico ni cada parche de test.

## CI y trazabilidad
- El workflow por rama se debe disparar no solo por tests/fixtures/progreso, sino también por cambios en los **módulos de producción propios**. IA6 actualizará los filtros de CI; ninguna trabajadora ha de modificar workflows arbitrariamente.
- Los runs se validan por **SHA del árbol** que contiene tests **y** el parche funcional. Si se corrige producción, una CI anterior solo de tests no sirve.
- Una CI por familia es una puerta local, **no** aprobación de integración global. Ninguna trabajadora hace merge a árbitra, `main`, V28 ni PR #118; IA6 integra y revisa conflictos **por lote o al cerrar la campaña**, no después de cada `p`.
- Se permite anotar dependencia, pero no sustituir una prueba de comportamiento esperado por un test que solamente verifica que existe un archivo, si la tarea afirma funcionalidad.
- Respetar la cola 01..10 y el límite 10/10; una reparación técnica no consume un nuevo bloque ni da derecho a inventar IDs. Al completar 10/10 STOP hasta un nuevo encargo.

**Prevalencia:** este protocolo V5 y la actualización de `CAMPAIGN_GATE_003.md` prevalecen sobre las frases antiguas `NO MODIFICAR PRODUCCIÓN`, `solo tests` y `STOP ante cualquier dependencia` en los encargos CAMP003, **solo para reparaciones demostrablemente propias**. Siguen vigentes las restricciones de `main`, V28, otras ramas, trabajo de otra IA, política y entregas sin CI.
