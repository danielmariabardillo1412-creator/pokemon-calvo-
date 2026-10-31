# O001 — Cápsula Habilidad y Parche Habilidad

## Entrega y frontera

Conectar únicamente `ability_capsule` y `ability_patch` desde la mochila, con
publicación transaccional, guardado/carga y uso posterior por el combate nativo.
Este bloque incluye reglas, integración y sus pruebas; no entregar solo un helper
desconectado. Detenerse al final para revisión independiente de Codex.

No tocar dataset raw/normalized, políticas, imágenes, backend/paquetes Node,
algoritmos de combate, RNG, schema de guardado, mapa ni evolución. No descargar
otro juego ni ejecutar el adaptador. El original D:/Proyectos/Pokemon Calvo y F:
son fuentes de solo lectura; no ejecutar el juego original. No tocar refs de
arquitectura cerradas ni sus informes. El estado actual sigue siendo 67 efectos
de campo; no actualizar contadores hasta que Codex acepte la entrega.

## Perfil y evidencia de referencia

Perfil objetivo: reglas modernas de Escarlata/Púrpura, respetando los vetos ya
existentes. Los datos canónicos de habilidad están en `ability_ids` y
`ability_slots`, incluidos los de las 57 regionales. PokéAPI usa slots 1/2 para
normales y 3 para oculta; Essentials usa índices 0/1/2. No mezclar las numeraciones.

Fuente local fijada de consulta:
`D:/Proyectos/Pokemon Calvo Referencias/fuentes/pokemon-essentials`, commit
`8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b`,
`Data/Scripts/013_Items/002_Item_Effects.rb`, handlers ABILITYCAPSULE/ABILITYPATCH.
Créditos: Maruno17 y colaboradores. Leer el código como referencia; no ejecutar
Ruby ni importar su UI/motor. La API ya contiene ambos objetos e imágenes.

**Diferencia que no se puede copiar a ciegas:** ese handler de Essentials solo
permite pasar de normal a oculta. En Gen IX el Parche también permite volver de
oculta a normal. Antes de programar, fijar una referencia primaria que compruebe
esta reversión y el slot normal de destino. Registrar URL/commit/hash y qué
regla demuestra. Los proyectos comunitarios pueden tener configuraciones propias:
no convertir una opción de un fangame en una regla oficial sin contrastarla.
Pista de contraste de observaciones de SV:
https://www.smogon.com/forums/threads/read-me-tips-for-simple-hack-checks.3498670/
No sirve por sí sola para inferir el slot de destino. Si falta esa prueba,
detener ese punto y comunicarlo; no implementar otra generación por comodidad.

## Contrato mecánico

1. Cápsula: alterna las dos habilidades normales distintas cuando existen y la
   habilidad actual identifica inequívocamente uno de esos slots. No obtiene ni
   elimina una oculta. Una sola normal, dos normales idénticas o habilidad actual
   no representada no justifican consumir el objeto.
2. Parche: normal a oculta, y reversión de oculta a normal conforme a la
   referencia SV fijada. No recordar un slot previo inexistente en el guardado
   ni elegir una habilidad aleatoria. Si el ID no permite identificar la ruta
   sin ambigüedad, devolver dependencia/contexto explícito, sin consumo.
3. Solo destino permitido por la política actual. Un veto no convierte una
   Cápsula en selector libre ni autoriza saltar a otra habilidad. Ejemplo real:
   Machop tiene Guts/No Guard/Steadfast; No Guard está vetada. No cambiar el veto
   para hacer pasar el caso ni redirigir la Cápsula hacia Steadfast.
4. Sin efecto real: no consumo ni amistad extra. Único dato persistente del
   Pokémon que puede cambiar: `ability_id`; no naturaleza, IV/EV, PP, PS, nivel,
   EXP, amistad, shiny, equipo, identidad o estados. Consumo: una unidad.
5. La frontera del servicio conserva KO/transformación temporal, propiedad,
   inventario, guard de actividad e identidad, y relojes de sueño. Verificar la
   entrada antes de serializar; no reparar datos corruptos automáticamente.
6. No modelar huevos, crianza, formas especiales o slots genéticos que no estén
   representados en el modelo actual. Inventariar esos casos como pendientes.
   Rockruff con Own Tempo ajena a sus slots corrientes no se "normaliza" por
   adivinación. No activar otras variedades por cambiar la habilidad.
7. `EvolutionSystem` actualmente conserva el ID si lo admite el destino o elige
   la primera habilidad. La herencia de slots entre especies con IDs distintos
   es un tema aparte: documentar el límite, no reescribir evolución en O001.

## Plano de integración

- Nuevo módulo puro `modules/inventory/field_ability_effects.gd`: valida los
  slots/estado y calcula el cambio sobre una candidata. Sin UI/IO/inventario/RNG.
  No duplicar el efecto de la habilidad en combate: eso lo hace Showdown.
- Integrarlo por el dispatcher `field_item_effects.gd` y el servicio existente
  `field_item_service.gd`. El servicio aplica la política de destinos, conserva
  la autoridad de propiedad y consume/publica una sola vez sobre éxito real.
- Reutilizar los guards existentes. No usar el helper de caramelos como un
  servicio genérico ni copiar todo su motor; aquí no hay elección de movimientos.
- Mochila: indicar el destino antes de aplicar y el nombre de la nueva habilidad
  al terminar. Usar las traducciones existentes, con fallback conservador si no
  existe nombre español. Usar es la intención explícita del usuario; no hace
  falta inventar otro sistema modal. No alterar las decisiones de caramelos.
- No acumular reglas en `field_demo.gd`; está fuera de la allowlist.

## Archivos de implementación permitidos

El guard es la lista exacta. Producción:

- `modules/inventory/field_ability_effects.gd` y su `.uid` nuevo.
- `modules/inventory/field_item_effects.gd`.
- `modules/inventory/field_item_service.gd`.
- `scenes/visual/field_item_bag.gd`.

Pruebas/evidencia:

- `tests/gameplay/item_field_ability_o001.gd` y su `.uid` nuevo.
- `tools/verification/run_opencode_ability_o001.py` nuevo, usando `LocalPhase`.
- `docs/opencode/evidence/O001/REVIEW.md` y `results.json`.
- Estado y diario: `docs/opencode/TASKS.json`, `docs/opencode/PROGRESS.md`.

Logs/capturas/resultados extensos solo en `.godot/opencode_items_o001/`. No
actualizar documentos de cobertura global ni modificar pruebas ya existentes.
No reescribir el contrato, el guard compartido ni los resultados V9 para dar verde.

## Pruebas necesarias y puertas

Pruebas significativas del módulo y del servicio, basadas en una tabla de casos
esperados independiente. Cubrir catálogo base y regionales, ambos slots normales,
oculta, duplicados/ausencias, habilidad ajena, destino vetado y ambas direcciones
del Parche. Los casos sin metadatos suficientes se rechazan, no cuentan como uso
positivo. Registrar recuentos de cambio/no efecto/veto/dependencia por objeto.

Comparar el estado completo antes/después: solo ability_id y una unidad de
inventario pueden variar. Cubrir equipo/PC, KO, transformación, null slot, guard
cerrado, servicio antiguo tras recarga y referencia de relojes sustituida con
igual contenido. No permitir que tests ajenos a `ability_id` dejen de comprobarse.

Integración real: abrir mochila, aplicar, cerrar, guardar/cargar, entrar en el
worker nativo, verificar habilidad enviada/restaurada y terminar el combate.
Incluir un escenario funcional de una habilidad permitida y control negativo;
no basta con comprobar un texto. Growlithe Intimidate/Flash Fire es un candidato
permitido a contrastar; no hardcodear rutas para esa sola especie.

El nuevo runner debe preservar logs por ejecución, esperar terminación real,
rechazar SCRIPT ERROR/timeouts/cero asserts y verificar integridad antes/después.
Reutilizar `LocalPhase.run_godot`; no copiar un runner histórico con globals de
otra fase ni ejecutar sus guards contra esta fase. Puertas:

1. Importación Godot.
2. Nuevo runner de habilidades headless.
3. `tests/test_runner.gd`.
4. `tests/gameplay/item_field_growth_v9.gd` (regresión de caramelos).
5. `tests/gameplay/item_field_pp_v8.gd` y `item_field_training_v7.gd`.
6. `tests/gameplay/field_native_test_runner.gd` y `field_restore_integration_test_runner.gd`.
7. Nuevo runner de habilidades GPU, con captura legible de mochila.
8. `python tools/verification/opencode_items_guard.py --full` al final.

Godot: `C:/Godot/4.7/Godot_v4.7-stable_win64_console.exe`.
No hacer que todos los tests dependan de una sesión o carpeta que solo existe
después de otra prueba. Saves con nombre exclusivo de O001; nunca tocar
`user://pokemon_calvo_field.json`. Cerrar workers. No descargar dependencias.

## Entrega

Estado `READY_FOR_REVIEW` / O001 `IMPLEMENTED_AWAITING_REVIEW`. Informe con fuentes
de cada regla, archivos, escenarios, comandos, salidas reales, límites y fallos
conservados. Un intento interrumpido no es PASS. Si hay una dependencia legítima,
explicarla sin disfrazarla de caso funcional. No commit ni aceptación propia.

No iniciar O002 (mentas/IV), Cuerda Huida, crianza, mapas u otros objetos. Codex
decidirá el próximo bloque después de revisar O001.
