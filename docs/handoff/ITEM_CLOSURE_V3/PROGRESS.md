# Progreso y continuidad — ITEM_CLOSURE_V3

2026-10-31: rama remota `codex/organized-update-v27` comprobada, HEAD = checkpoint revisado `e10b79a5eb8c3e83975a9f4f5b48d6615a85e1b7`, sin cambios posteriores. PR original #116 sigue en borrador. Creada rama única `codex/item-closure-v3`. Leídos los ocho documentos obligatorios; partes históricas no se toman como inventario vigente.

Hallazgos: catálogo con 2.222 IDs y 44 exclusiones; de los 624 equipables permitidos, 621 tienen descriptor nativo. Únicos huecos de descriptor: `amulet_coin`, `exp_share`, `luck_incense`. Esto NO significa que solo queden tres usos. En V27 los 14 evolutivos originales se conservan, `linking_cord` excluido, y adaptación de intercambio aplazada.

Estructura observada: `CreatureSpecies.ev_yield`; `ProgressionSystem.reconcile_battle_result` distribuye XP a supervivientes de la colección; `BattleOutcome.defeated` conserva IDs de especies; los tres cierres (salvaje legado, entrenador legado y nativo) ya pasan por la progresión con guardas de cierre. `CreatureInstance` ya persiste EV y recalcula stats, sin necesitar schema nuevo. Evitar duplicar el cierre.

Referencia generación B: EV modernos Gen VII–IX, Power +8, Macho Brace x2, Gen VI+ 252/510, EV nivel 100. Fuente comunitaria: https://bulbapedia.bulbagarden.net/wiki/Effort_values y https://bulbapedia.bulbagarden.net/wiki/Power_items . El simulador `@pkmn/sim@0.10.11` queda fijado. La variante Macho Brace es una decisión de compatibilidad para un objeto heredado, no prueba de presencia en todos los títulos Gen IX.

Limitación del entorno de esta ejecución: el conector GitHub permite leer y modificar el repositorio; el runtime de contenedor no puede resolver github.com ni tiene `godot` instalado, de modo que el checkout local y el gate portable no están disponibles aquí. Las pruebas remotas se ejecutarán únicamente si GitHub Actions las programa y aportará enlaces; cualquier ejecución no comprobada se registrará pendiente.

**Siguiente paso exacto:** automatizar inventario A con clasificación conservadora, y después conectar EV B con pruebas reproducibles; publicar CI y esperar resultados observables antes de cambiar el estado a READY_FOR_REVIEW.
