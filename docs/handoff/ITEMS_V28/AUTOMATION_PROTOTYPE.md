# Automatizador declarativo V28 — dos familias verificadas

## Segunda familia verificada — ampliación desde 648a2c86

El mismo comando y runner reciben ahora dos descriptores: Elección (schema 1,
sin cambiar sus bytes) y `passive_items.json` (schema 2). Se conserva la API
Python del primer contrato y sus 14 pruebas. Múltiples familias se validan por
particiones completas; Elección mantiene 15 escenarios y al menos 665 aserciones
incluyendo sus dos comprobaciones de preparación originales. No hay fallback
equip-only para los casos de la segunda familia.

`item_automation_effects_v28.gd` contiene solo predicados de prueba por opcode;
`automation_contracts_v28.py` valida contratos y observaciones con la evidencia
nativa. Ambos carecen de simulación, UI o escritura en la campaña. La orquestación,
fixture, equipamiento, inventario, captura de evidencia, SaveV2, restauración y
mochila siguen en el runner común. La restauración previamente interna de la
prueba de bloqueo se extrajo para que las dos familias usen la misma operación.

| Objeto | Contratos nuevos, cada uno con active/none/reserve |
| --- | --- |
| Restos | Recuperación parcial en dos turnos; límite con un PS faltante; sin curación a PS completos; efecto del objeto en el nuevo activo después de cambiar |
| Vidasfera | Aumento físico y retroceso en dos turnos; aumento especial; movimiento de estado sin retroceso; ataque inmune sin daño/retroceso |
| Casco Dentado | Contacto en dos turnos; especial sin contacto; físico sin contacto; daño al atacante cuando el nuevo activo es el portador |

Cada objeto también recorre la misma quinta ruta física mapa/mochila/portador/
guardar/cargar/cierre. Se añaden verificaciones de PS reales publicados y
persistidos a esa ruta común, también para Elección. El mapa sigue sin sustituir
los disparadores específicos de las pruebas nativas.

Los escenarios de efectos restauran desde disco antes de comenzar y después de
cada paso. Cada variante tiene owner y worker nuevos, revisiones obsoletas se
rechazan sin mutación y la campaña no se publica durante el ensayo. Los checkpoints
nativos inicial/final corroboran PS, identidad y equipo medidos; el informe no
puede inventar observaciones distintas de su timeline o de esos checkpoints.
Las fracciones 1/16, 1/10 y 1/6 son expectativas de prueba del efecto conocido;
no hay nuevo cálculo productivo, callbacks, RNG, protocolo o schema de guardado.

Los tres objetos se conservan sin consumir. Habilidades vacías: sin Magic Guard,
Sheer Force, Long Reach, supresión o transferencias especiales. Dobles, GPU/manual
y todas las combinaciones siguen fuera. Contratos seguros, sin dependencias nuevas.
Casco Dentado PokéAPI 583 tiene `attributes: []`; excepción de metadatos revisada
solo para su registro fijado: categoría held-items, índice 540 Gen V–IX y efecto
inglés explícito de contacto. No se modifica ese snapshot ni las reglas de selección.

Resultado real: código `7f973f5bfb63cfae12f1dbaa956512e5291df0aa`, [Actions #41241062641](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41241062641),
20/20 workflows PASS, 1935 comprobaciones y 30 escenarios en Ubuntu y Windows,
31 tests del contrato por plataforma. Se revalidaron los dos ZIP y sus 178 archivos
por ejecución, incluyendo deltas/propietarios desde checkpoints nativos. La evidencia
del primer piloto que sigue abajo es histórica. Detalles y límites en AUTOMATION_RESULTS.json.

## Alcance y arquitectura

Tres objetos oficiales y permitidos: Cinta Elegida `choice_band` (PokéAPI 197),
Gafas Elegidas `choice_specs` (274), Pañuelo Elegido `choice_scarf` (264).
No se implementa ninguna mecánica productiva. El piloto automatiza la preparación,
equipamiento, ejercicio y verificación de conexiones ya disponibles. No convierte
automáticamente un objeto desconocido en un efecto funcional.

Una tabla, `tests/fixtures/item_automation_v28/choice_items.json`, describe
semilla, formato, especies, movimientos, controles y expectativas. Un único
`tests/gameplay/item_automation_v28.gd` ejecuta los mismos cinco escenarios por ID.
Las expectativas se seleccionan por comportamiento, no por ramas de código que
vuelvan a programar cada objeto. El validador Python restringe este piloto a los
tres contratos revisados y rechaza campos, IDs, controles o expectativas desconocidos.

Se heredan helpers V3/V18 existentes (fabricación, servicio, mochila y reproducción),
SaveGameData/SaveGameRepository y la sesión nativa del juego. Esta última ya delega
en NativeEngine y @pkmn/sim 0.10.11; no hay un segundo motor de reglas. El workflow
continúa ejecutando SIN CAMBIOS `held_effect_sweep_v3.cjs`, proyección Godot,
inventario V3 y todas las regresiones previas. No se importa ese CJS como biblioteca
porque su top-level dispara el barrido completo y no expone una API de escenarios.

## Escenarios comunes y postcondiciones específicas

| Escenario por ID | Comprobación |
| --- | --- |
| physical_damage | Cinta aumenta daño físico; Gafas/Pañuelo lo igualan al control |
| special_damage | Gafas aumentan daño especial; Cinta/Pañuelo lo igualan al control |
| speed_order | Solo Pañuelo invierte el orden Mew/Gengar con igual prioridad |
| lock_restore_switch | Movimiento alternativo bloqueado, revisión obsoleta rechazada sin mutación, checkpoint en disco restaura bloqueo, cambio de ida/vuelta libera elección |
| map_bag_owner_save | Mochila física: equipar A, quitar, equipar B, quitar, volver a A; mapa, guardar/cargar antes/durante/después de batalla, propietario, cierre repetido y existencias |

Los tres primeros y el bloqueo se ejecutan en variantes **active / none / reserve**:
objeto en el actor, sin equipar, y en otro Pokémon de la reserva. Cada variante
construye colección, inventario, criaturas y worker nuevos; no comparte estado
mutable. Habilidades vacías en todos los controles para no certificar sinergias.
La campaña permanece intacta durante pruebas activas sin liquidación. Los objetos
no se consumen: dos unidades físicas, una en mochila y otra equipada donde procede.
Las tres escenas de mapa sí recorren el cierre real y el guardado completo.

El comando de cambio se resuelve por identidad en el roster ACTUAL: Showdown
intercambia posiciones entre activo y reserva. Nunca se confunde el índice de
comando con la identidad persistente del propietario.

El mapa usa Caterpie para cerrar combate; ese encuentro verifica conexión física,
no el bonus. La prueba del efecto usa pares nativos adecuados, con misma semilla,
especies, nivel, estadísticas y movimientos. No se exige un cociente exacto de PS
porque el daño incluye redondeos; se observa aumento específico y ausencia de
aumento en categoría incorrecta/control. No se reimplementa la fórmula de daño.

## Ejecución y evidencia

Con recursos/runtime YA instalados:

```text
python -B tests/tools/test_item_automation_v28.py
python -B tools/item_audit/automation_v28.py --godot <godot-console> --node <node>
```

Cada ejecución crea `.godot/item_automation_v28/runs/<id>/` con inputs/procedencia,
recibos SHA-256, checkpoints y partidas, `godot.json`, `results.json` y log completo.
Los 15 recibos (3 IDs × 5 escenarios) incluyen comprobaciones, errores, observaciones
y controles. El Python vuelve a contrastar el efecto declarado con los valores,
rechaza casos omitidos/duplicados, hashes incorrectos, cero aserciones y evidencia
ausente. Un rótulo verde no sustituye la ejecución ni la evidencia.

La procedencia se lee de los blobs originales PokéAPI fijados en Git y de la
clasificación de inventario existente. No se materializan snapshots ausentes ni
se descargan datos. Un guard limita diferencias al WORK_ORDER exacto, comprueba
runtime antes/después y conservación de skip-worktree. Cuatro UID antiguos que el
editor puede generar automáticamente se inventarían aparte y no se versionan.

CI añade la misma prueba tanto en Ubuntu Godot 4.7 como en Windows después del gate
portable anterior. Se conservan artefactos y consola, SHA funcional de la PR y SHA
del checkout probado (el merge temporal de Actions puede ser distinto), hash de
descriptor/código y URL de ejecución. Los avisos PID conocidos se registran como
deuda técnica, no se borran del log ni se presentan como consola limpia. Cualquier
error de script, parser, aserción, protocolo, hash o evidencia invalida el piloto.

## Límites y continuación

El piloto no importa todos los objetos ni habilita IDs. No modifica datos,
selección, RNG, protocolo, schema, callbacks, UI o baselines. No certifica Gorilla
Tactics, Klutz, Trick/Knock Off/supresión, todas las generaciones o GPU/manual.
Conservar el alcance competitivo de 61 candidatos; no ampliar a 2.222 por catálogo.
El resultado aprobado debe ligarse a CI real en AUTOMATION_RESULTS.json, no al
último commit documental. Hasta entonces no reducir los 38 pendientes de la auditoría.

Después del piloto, diseñar opcodes/expectativas para otra familia coherente usando
el mismo aislamiento, propiedad, persistencia e informe; no convertir un fallback
genérico en éxito ni eliminar pruebas excepcionales para aumentar el lote.

Habilidades quedan separadas: `codex/ability-audit-v1`, funcional `72548cde`, nota
de reanudación `5d5f8ae` (234 escenarios / 231 habilidades / 65 pendientes).
No se han incorporado a esta PR. No fusionar PR #118 ni modificar main.
