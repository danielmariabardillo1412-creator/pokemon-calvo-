# W04 (IA4) — CUADERNO DE CONTINUIDAD

## 1. Identidad, autoridad y estado

- Identidad: IA4 / W04, especialista en evoluciones por objetos, tres IDs activos auspicious_armor, malicious_armor, black_augurite.
- Rama propia y única de escritura: codex/calvo-items-20261101-w04.
- Última orden oficial: docs/coordination/items_parallel_v1/assignments/LOTE_002_W04.md en rama codex/calvo-items-20261101-arbitro. Blob leído: 9840c0d6c1a64fd35de3325d2b1f2426e283bb90.
- Estado: LISTA_PARA_REVISION tras preparar LOTE_002. **No INTEGRADO ni FUNCIONALES_CERTIFICADOS.**
- Checkpoint común de IA6: 38188cc208e67b19002437ac75160898ce332ec2; merge exclusivo W04 05ae7fdc74aa117a213ae2d09b34c1dbbe8e78c3, dos padres, sin force/rebase.
- Informe LOTE_001 aceptado por IA6 en HEAD 26eabd19cea4f2b9c88961e3b03852b32eaf8ea4; blob conservado e452f523a3965c0ca53f34a689b76fb4c38b5b7f.
- Último commit propio del cuaderno: ver historial de este fichero (no se puede referenciar su propio SHA sin modificarlo); los SHAs de los scripts se indican a continuación.
- Último PASS funcional Godot específico en rama W04 combinada: **NINGUNO**. PASS histórico de conexiones V27 en 6629fe570cdf4c891a937c3f2a74b45e960dc902, no trasladable sin ejecución al nuevo árbol.
- Escritura SOLO en tests/gameplay/parallel_items_w04_evolution_v1.gd; tests/tools/test_parallel_items_w04_evolution_v1.py; reports/W04/LOTE_002.md; reports/W04/CONTINUIDAD.md durante LOTE_002.

## 2. Mapa técnico — leer solo cuando se necesite

| Tramo | Fuente y símbolo que ya existe |
| --- | --- |
| Definición primaria | data/api/v2/evolution-chain/490/index.json (Charcadet → Armarouge/Ceruledge); 58/index.json (Scyther → Kleavor). Normalización local data/normalized/pokemon_api.json, no modificar. |
| Catálogo | GameData.from_dict → DefinitionCatalog, CreatureSpecies.evolutions / EvolutionRecord; política RandomlockContentPolicy. |
| Elegibilidad | modules/creatures/progression/evolution_system.gd: classify_record, evolution_candidates (trigger use_item), apply_evolution. |
| Uso en mochila | modules/inventory/field_item_service.gd: evolution_options, use_item y evolve; validan criatura propia/stock/objetivo/política; realizan retirada de una unidad y sustitución de misma identidad. |
| Propietario y PC | modules/creatures/storage/player_collection.gd: owned_creature, deposit, replace_owned_same_identity, location_of. El servicio puede evolucionar una criatura del PC; la UI de campo no expone esa lista directamente. |
| Persistencia | modules/save/save_game_repository.gd: save_collection, load; SaveGameData.build; PlayerInventory; módulos de guardado protegidos. |
| Vista | scenes/visual/field_item_bag.gd delega en service.use_item, pero solo permite seleccionar Pokémon del equipo. |
| Test histórico | tests/gameplay/item_connections_test_runner.gd: _test_evolutions y _test_field_and_save; V27 conexiones 4993 checks, 57 rutas positivas, algunas dependencias. |
| Test nuevo W04 | tests/gameplay/parallel_items_w04_evolution_v1.gd; test Python complementario tests/tools/test_parallel_items_w04_evolution_v1.py. |

**Diferencia crítica:** las dos armaduras están en holdable_ids y son transferibles como equipamiento, pero eso no provoca evolución; black_augurite no aparece en holdable_ids ni entrada nativa y su uso directo por mochila Godot puede funcionar. NO construir tres conectores nuevos; reutilizar FieldItemService y EvolutionSystem.

## 3. Estado por ID

| ID | Existe antes de W04 | Evidencia / SHA | Pendiente |
| --- | --- | --- | --- |
| auspicious_armor | Charcadet → Armarouge por uso directo; 1 ruta V1 con status de evolución de mochila | ITEM_CONNECTIONS_V1.json blob 59a90a0cb9adc03810d06bbcc44f97e51f85e1c2; runner V27 Godot PASS histórico | Ejecutar test nominal Godot 4.7 en combinación aprobada; guardar/cargar + control negativo/KO/PC; UI GPU no verificada |
| malicious_armor | Charcadet → Ceruledge por uso directo; 1 ruta V1 | Mismas fuentes; no confundir con otro destino alternativo | Igual; estado PENDIENTE_CI |
| black_augurite | Scyther → Kleavor por uso directo; 1 ruta V1 | Mismas fuentes, sin nativo equipable | Igual; evitar crear puente nativo innecesario |

Los tres constan como SELECCIONADO en RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv. Los estados de ITEM_INVENTORY.csv son pistas históricas; no son certificados ni autoridad sobre la implementación real.

## 4. Historial de lotes y cambios REALES

| Lote | Entrega, informe y commits | Evidencia hoy | Aceptación |
| --- | --- | --- | --- |
| LOTE_001 | Auditoría documental solo en reports/W04/LOTE_001.md; commit final 26eabd19cea4f2b9c88961e3b03852b32eaf8ea4. | 17 checks estructurales en lectura; Godot SIN_EJECUTAR. | ACEPTADO como auditoría por IA6 en STATUS.md. |
| LOTE_002 | Merge de base 05ae7fdc74aa117a213ae2d09b34c1dbbe8e78c3; script GDScript commit 3ed3f27cfa20fa7153c0cfa1f48c5e55ffd15ec3; script Python commit 9c859514a567ed8bd0c43a50e6c015c5625ba67f con corrección de columna CSV commit 743914c218e118cd2aca275c18f32e9699a89fa9; informe LOTE_002.md en esta rama. | Cotejo estructural desde GitHub 21/21; Python y Godot SIN_EJECUTAR; GPU NO REALIZADA. | LISTA_PARA_REVISION, a la espera de IA6. |

Blobs de pruebas al cerrar LOTE_002:
- GDScript: ab947ef6fcd739e3ccefc75e888621ad23c716ac.
- Python: d637870c5bf66d2eddad8753d1aba56e18755749.

**NO se tocó** modules/, scenes/, config/, data/, docs/current/, .github/workflows/, tests V27/V28 preexistentes, fuentes o políticas; tampoco main, V28, ramas ajenas ni árbitra.

## 5. Validación, límites y riesgos

1. Cotejo de 21/21 comprobaciones **estructurales reales** sobre fuentes GitHub y scripts añadidos, ejecutado con un comparador independiente en memoria. No es ejecución del nuevo script Python ni del runtime.
2. Prueba del validador Python en checkout: SIN_EJECUTAR, falta checkout completo montado en este entorno; el conector permite lectura/escritura de ficheros concretos.
3. Godot 4.7 headless en este lote: SIN_EJECUTAR / PENDIENTE_CI. El checkpoint combinado V27+V28 carece de CI propia. No atribuirle los resultados de la V27 ni V28 independientes.
4. GPU/visual: NO REALIZADA. La UI de almacenamiento sigue siendo distinto al servicio PC.
5. Riesgos: errores de importación/GDScript del nuevo corredor pendientes de descubrir con ejecución real; posibles problemas de compatibilidad del guardado en combinación; no falsear PASS editando resultados. Guardado test limitado a user://w04_evolution_<item>.json.
6. Integración de archivos compartidos: EvolutionSystem, FieldItemService, serializer, progression_system y UI pertenecen a la coordinadora/propietario asignado; W04 no puede editarlos sin orden expresa.
7. Política cerrada: NO fijar niveles para evoluciones por intercambio; conservar objeto original equipado cuando se adapte en fase posterior. No tocar Mega ni Z ni beast_ball.

## 6. Retomar sin perder contexto

1. Leer en rama árbitra STATUS.md, NOTEBOOK_PROTOCOL_V1.md y la asignación oficial más reciente de W04. Si no hay LOTE_003 publicado, **NO trabajar otro lote** por intuición.
2. Verificar HEAD de W04 y que su historia incluye ambos padres del merge, además del LOTE_001 aceptado.
3. Leer reports/W04/LOTE_002.md y únicamente los dos scripts de test. No cargar 2.222 entradas ni auditar desde cero.
4. Cuando IA6 autorice ejecución consolidada, con checkout completo + Godot 4.7, preparar import y correr:

        python -B tests/tools/test_parallel_items_w04_evolution_v1.py
        godot --headless --path . --import
        python -B tests/tools/test_parallel_items_w04_evolution_v1.py --godot godot

5. Registrar SHA, comando, exit code, salida real y escenarios. Si FAIL, reportar a IA6; no cambiar producción sin autorización. Revisar difusión de los cambios solo en la rama de integración de IA6.
6. Solo después de nuevo encargo actualizar este cuaderno y crear el informe del lote siguiente. No modificar informes ya aceptados retroactivamente.

**Último siguiente paso reproducible:** revisión de IA6, integración secuencial y una CI consolidada con import Godot 4.7 + pruebas W04. **PENDIENTE_CI**.

**No tocar:** main, V28, rama árbitra, ramas W01/W02/W03/W05, datasets, política, guardados de usuario, engine/producción y workflows sin asignación explícita.

---

## 7. CAMPAÑA_001 ACTIVADA: seguimiento desde microbloque 01 (2026-11-01)

- Autoridad oficial superior: `CAMPAIGN_GATE_001.md` blob `3ef0b39f7eb74f3ebcb688f279c254daec981f8e` y `campaigns/CAMP_001_W04.md` blob `42a8cb9db9bdbe34c607d745da6b97e107b621bf`. Rango exclusivo: `fire_stone`, `water_stone`, `thunder_stone`, `leaf_stone`, `ice_stone`, `moon_stone`. Máximo 3 microbloques; solo uno por `p`.
- Bloqueo anterior de sincronización resuelto de forma verificable: antes de trabajar, GitHub comparó W04 y árbitra como **idénticas**, SHA `1b52fdd0b7b89e468811a17ad83a917ec7107735`. LOTE_001/002 conservados sin alterar.
- Gate actual IA6 CI PASS en `ac34fabbe1a27e69614f0239abee21c29d6fe65e`, run [#41341842320](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41341842320): W04 anterior 100 checks reales, tres IDs del LOTE_002. No confundirlos con los nuevos tests de piedras.
- **Microbloque 01 realizado: PREPARADO_PENDIENTE_CI.** Fuego/Agua/Trueno con Eevee, Growlithe, Shellder, Pikachu (6 pares); destino obtenido de `FieldItemService.evolution_options` y contrastado contra `EvolutionSystem.classify_record`. No se implementó producción ni se adelantó Leaf/Ice/Moon.
- Nuevos tests propios: `tests/gameplay/parallel_items_w04_campaign_001.gd` commit `7f667ba453d0b80a862b1565d17e1c9849d38768` y `tests/tools/test_parallel_items_w04_campaign_001.py` commit `63d396ab0b85401f9e83b319c58bd5efa28dcc8f`. Informes: `reports/W04/CAMP_001_ITER_01.md` y `reports/W04/CAMP_001_PROGRESO.csv`.
- Evidencia nueva: comprobación estructural independiente sobre datos GitHub y código de test **40/40 PASS**, NO ejecución de Python ni Godot. Nuevos scripts GDScript/Python: **SIN_EJECUTAR**; requieren CI Godot 4.7 en checkpoint integrado de IA6. No GPU.
- Ejecutar cuando IA6 consolide: `python -B tests/tools/test_parallel_items_w04_campaign_001.py`; `godot --headless --path . --import`; `python -B tests/tools/test_parallel_items_w04_campaign_001.py --godot godot`. Si falla, registrar SHA/log/condición y detener, sin tocar motor.
- **Estado actual:** microbloque 01 publicado, **02 y 03 PENDIENTES**. Siguiente `p` autorizado: **02 piedras Hoja/Hielo/Lunar**, siempre que el gate/encargo sigan vigentes y no haya FAIL. Microbloque 03 reservado a SaveV2 y clasificación de rutas. Tras 03 entregar `CAMP_001_FINAL.md` y detenerse.
- Rutas escribibles solo las listadas en campaña (dos tests antiguos propios, dos tests nuevos, informes propios, progreso y cuaderno). Resto de motores/producción/datos/políticas/saves/otros W, branch main/V28/arb: SOLO LECTURA.

**Nota de vigencia:** las secciones anteriores de este cuaderno reflejan la situación histórica al cerrar LOTE_002, cuando todavía no se había ejecutado su CI. La evidencia actual de aquel lote es el PASS confirmado por IA6; la campaña 001 es una cobertura distinta pendiente de ejecución.

## 8. CAMPAÑA_001 — microbloque 02 (2026-11-01)

- **Estado:** 02 `PREPARADO_PENDIENTE_CI` y registrado en `CAMP_001_ITER_02.md` / `CAMP_001_PROGRESO.csv`; 01 igualmente preparado, 03 PENDIENTE.
- **Autoridad:** `campaigns/CAMP_001_W04.md` blob `42a8cb9db9bdbe34c607d745da6b97e107b621bf`, puerta IA6 `ACTIVADA`. Rama W04 conserva íntegro el checkpoint árbitra; no se modifican ramas ajenas.
- **IDs 02:** `leaf_stone`, `ice_stone`, `moon_stone`. Las rutas fuente son Eevee→Leafeon/Glaceon, Gloom→Vileplume, Clefairy→Clefable y Jigglypuff→Wigglytuff (PokeAPI cadenas 67,18,14,16).
- **Caso especial:** Vulpix común con `ice_stone` no debe evolucionar/gastar por la ruta del Vulpix de Alola (cadena 15, base_form regional); el test diferencia `CONDITIONAL_ROUTE_REJECTED` de `CONDITIONAL_ROUTE_NOT_IN_ACTIVE_CATALOG`. El segundo estado NO certifica ruta condicionada.
- **Tests extendidos, sin producción:** `tests/gameplay/parallel_items_w04_campaign_001.gd`, commit `b11e53b3811bb23c2d23ff76b5aba5a27a2ee45e`, blob `c78d1642c0e1f67c4510e2f3f1b338b5c70daae1`; `tests/tools/test_parallel_items_w04_campaign_001.py`, commits `98e0748698911c65da01d3328dc11e43039d1b25` y corrección null `2db1acfe7e1b433db2ebbdc7bf8f5ec8393ca13c`, blob `ffd348c51bab97095eb30c3e3c4f8e25674c684e`.
- **Nuevos escenarios:** 5 rutas positivas en equipo y PC, stock 0/2→1, propietario erróneo, destino falsificado, repetición sin gasto, ubicación/identidad/datos preservados y rechazo para especies incorrectas. Persistencia real SaveV2 reservada para 03.
- **Pruebas:** comprobación independiente de metadatos y presencia de escenarios en GitHub `44/44 PASS ESTRUCTURAL`. Python del checkout y GDScript Godot `SIN_EJECUTAR`; `PENDIENTE_CI`. La CI base anterior #41341842320 no cubre nuevos commits. GPU/visual sin probar.
- **Siguiente `p`:** SOLO microbloque 03, ampliar el mismo corredor con persistencia SaveV2, clasificar rutas, preparar `CAMP_001_FINAL.md` y DETENER. Si un test o contrato falla, elevar a IA6; NO modificar `modules/`, `data/`, `config/`, guardados, main, V28, árbitra u otras W.
