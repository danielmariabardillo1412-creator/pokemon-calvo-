# Progreso y continuidad — ITEM_CLOSURE_V3

**Inicio rápido para otra conversación:** [CONTEXT_CONTROL.md](CONTEXT_CONTROL.md). Leer ese protocolo y `STATE.json` antes de pedir logs o inventarios de nuevo. No constituye una misión adicional ni cambia el estado READY_FOR_REVIEW.

2026-10-31: rama remota `codex/organized-update-v27` comprobada, HEAD = checkpoint revisado `e10b79a5eb8c3e83975a9f4f5b48d6615a85e1b7`, sin cambios posteriores. PR original #116 sigue en borrador. Creada rama única `codex/item-closure-v3`. Leídos los ocho documentos obligatorios; partes históricas no se toman como inventario vigente.

Hallazgos: catálogo con 2.222 IDs y 44 exclusiones; de los 624 equipables permitidos, 621 tienen descriptor nativo. Únicos huecos de descriptor: `amulet_coin`, `exp_share`, `luck_incense`. Esto NO significa que solo queden tres usos. En V27 los 14 evolutivos originales se conservan, `linking_cord` excluido, y adaptación de intercambio aplazada.

Estructura observada: `CreatureSpecies.ev_yield`; `ProgressionSystem.reconcile_battle_result` distribuye XP a supervivientes de la colección; `BattleOutcome.defeated` conserva IDs de especies; los tres cierres (salvaje legado, entrenador legado y nativo) ya pasan por la progresión con guardas de cierre. `CreatureInstance` ya persiste EV y recalcula stats, sin necesitar schema nuevo. Evitar duplicar el cierre.

Referencia generación B: EV modernos Gen VII–IX, Power +8, Macho Brace x2, Gen VI+ 252/510, EV nivel 100. Fuente comunitaria: https://bulbapedia.bulbagarden.net/wiki/Effort_values y https://bulbapedia.bulbagarden.net/wiki/Power_items . El simulador `@pkmn/sim@0.10.11` queda fijado. La variante Macho Brace es una decisión de compatibilidad para un objeto heredado, no prueba de presencia en todos los títulos Gen IX.

Limitación del entorno de esta ejecución: el conector GitHub permite leer y modificar el repositorio; el runtime de contenedor no puede resolver github.com ni tiene `godot` instalado, de modo que el checkout local y el gate portable no están disponibles aquí. Las pruebas remotas se ejecutarán únicamente si GitHub Actions las programa y aportará enlaces; cualquier ejecución no comprobada se registrará pendiente.

**Siguiente paso exacto:** automatizar inventario A con clasificación conservadora, y después conectar EV B con pruebas reproducibles; publicar CI y esperar resultados observables antes de cambiar el estado a READY_FOR_REVIEW.

## Diagnóstico CI real y corrección de preparación Windows (2026-10-31)

Sobre `94aca849`: **19 de 20 workflows PASS**; el único FAIL es [Item Closure V3 #41216383124](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41216383124) por el job Windows. El job Ubuntu de esa misma ejecución PASÓ: inventario 2.222 IDs, native 908 PASS/0 FAIL (65 IDs), IPC 23.434 checks, 12 bayas, EV 94 checks, V18 8.755 checks y 72 IDs con pruebas V3 delimitadas.

Windows restauró los 6.643 recursos, importó Godot 4.7, instaló la simulación fijada y pasó los primeros grupos del verificador portable. El grupo `item_connections_test_runner` produjo 0 checks, JSON ausente y Nil en `item_connections_test_runner.gd` al abrir `source_machine_rows.json`, `godot_inventory.json` y `machine_fixtures.json` bajo `.godot`. El gate no prepara esas salidas históricas desde un checkout limpio: fallo de fixture, no prueba de fallo funcional de la mecánica. No reducir guardas ni declarar PASS.

Corrección CI limitada a `.github/workflows/item-closure-v3.yml` y nuevo `tools/item_audit/stage_item_connections_ci_v3.py`, añadidos a la lista permitida. Reconstruye las dos fixtures de máquina desde los CSV primarios verificados usando el preparador existente, verifica que coinciden con el perfil versionado y ejecuta el exportador Godot existente para obtener el inventario evolutivo. Comprueba los tres archivos antes del gate original. **No regenera ni escribe `modules/inventory/item_connections_v1.json`, ningún dataset ni verificador histórico.**

**Siguiente paso exacto:** comprobar los jobs Windows y Ubuntu de la siguiente ejecución asociada al commit de esta reparación. Si el portable falla en otro grupo, investigar su log antes de declarar READY_FOR_REVIEW. Si pasa, actualizar conjuntamente `STATE.json`, `RESULTADOS.json`, `PROGRESS.md` y esta PR en borrador; queda pendiente GPU/visual en el PC.

## Resultado CI del commit de implementación `c554ab76` (2026-10-31)

**20/20 workflows PASS**, sin pendientes ni fallos en [Actions #41217120667](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41217120667) (incluye compilación Windows y pruebas Godot 4.7). El job Ubuntu de Item Closure V3 pasó 908 escenarios nativos/65 IDs, 23.434 comprobaciones IPC Godot, 12 bayas, 94 comprobaciones EV y 8.755 de regresión V18. Matriz V3: 2.222 inventariados, 72 IDs con prueba V3 delimitada; no todos los efectos completos. Siete equipables EV probados en dominio; únicamente `power_weight` en la batería concreta mapa/mochila/combate nativo/guardado.

**Windows PASS**: el nuevo preparador derivó 338 relaciones de máquinas y 229 casos activos de Scarlet/Violet desde CSV verificados, y el exportador Godot obtuvo 72 referencias evolutivas. El gate histórico `tools/distribution/verify_update.py` terminó literalmente `PUBLICATION_V27 PASS`. El antes fallido `item_connections_test_runner` ejecutó 4.993 comprobaciones PASS. Se conservó el fallo previo y no se alteraron datasets, el verificador, motor de combate ni sus umbrales.

**Estado de entrega:** READY_FOR_REVIEW con alcance acotado, PR #117 en borrador hacia `codex/organized-update-v27`, sin merge. La aprobación visual/GPU y el juego manual en Godot local continúan pendientes. No se afirma certificación total de los 2.222 objetos, ni equivalencia generacional universal de recompensas/EV. Este commit documental final solo actualiza STATE/RESULTADOS/PROGRESS y se basará en la evidencia obtenida en `c554ab76`.

**Continuación exacta:** revisar manualmente pantallas, sprites, mochila y combate con Godot 4.7 local; solo después el propietario decide si solicita cambios adicionales o si la PR se considera revisada. Mantener separados los sistemas de economía, Exp. Share y la evolución por intercambio futura.
