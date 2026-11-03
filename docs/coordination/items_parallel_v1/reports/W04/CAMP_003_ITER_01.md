# W04 — CAMPAÑA_003 / ITER_01

**Bloque:** 01/10. **Estado:** EN_CI_AUTOMATICA, sin PASS funcional confirmado.

**IDs exactos:** dawn_stone, dusk_stone, shiny_stone. Fuentes: cola oficial aditiva W04, catálogo de especies normalizado, `EvolutionSystem.classify_record`, `FieldItemService.evolution_options/evolve`.

**Pruebas publicadas:** fixture `tests/fixtures/parallel_items/w04_campaign_003.json`; Godot `tests/gameplay/parallel_items_w04_campaign_003.gd`; Python `tests/tools/test_parallel_items_w04_campaign_003.py`.

**Cobertura programada:** localizar reglas reales use_item por objeto y su clasificación; si hay ruta ejecutable, escoger origen/destino del catálogo y comprobar elegibilidad, rechazo de propietario y objetivo incorrectos sin gasto, evolución con inventario 2→1, identidad IV/EV experiencia amistad y movimientos, segundo uso sin gasto, guardado y carga SaveV2 con ruta de prueba aislada. Si solo hay reglas condicionadas, mostrar DEPENDENCIA y no inventar éxito de evolución.

**Registro de publicación:** fixture `fd12c94260f2bc20691c3f025e149c1acd3429ce`, GDScript `09ac06b96d7577c94fff9d1f3e1f57e2578c8f84`, Python `dd082b0cdca4e684283272d4cf58786836ba16eb`. Progreso en commit `6f20282aee7229849e482bf2294c18ce8b403976`.

**Pruebas ejecutadas por esta conversación:** ninguna; la ejecución de Godot/Python y el resultado de Actions están pendientes. No se cambiaron producción, datos, workflow ni otras ramas. Ante FAIL funcional, escalar a IA6 sin alterar el contrato.
