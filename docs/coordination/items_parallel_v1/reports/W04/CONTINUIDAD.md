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

## ACTUALIZACIÓN 2026-11-03 — CIERRE CAMPAÑA_003

**Prevalece sobre los datos históricos LOTE_001/002 de este cuaderno.** La identidad sigue siendo **IA4/W04**, especialista en evolución. Rama de escritura actual y exclusiva: `codex/calvo-items-20261103-w04-camp003` (no reabrir `codex/calvo-items-20261101-w04`).

**Estado:** 10/10 bloques y 30 IDs entregados; CI final [#41573737061](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41573737061), `completed/success` en SHA `5622c3d3e8927b7da4cba8c587c81ab4997c5bab`: Python 120 comprobaciones, Godot 270; regresión CAMPAÑA_001: 559 comprobaciones y 12 casos SaveV2 correctos. Informe técnico y clasificación de los 30 IDs: `docs/coordination/items_parallel_v1/reports/W04/CAMP_003_FINAL.md`.

**Resultado técnico:** 14 objetos con evolución positiva en motor; 10 sin regla catalogada; 6 con ruta `DATA_ONLY`. Los dos pergaminos de Kubfu tienen diferenciación de forma en catálogo que no soporta actualmente el runtime. Las condiciones de autenticidad de ciertas teteras no están definidas en los registros examinados. No confundir pruebas PASS con 30 evoluciones jugables.

**Restricciones conservadas:** `main`, V28, producción, catálogo canónico, workflow y ramas ajenas sin tocar. No crear nuevos bloques ni modificar otros objetos. IA6 revisa la integración global y el backlog de dependencias. Al completar 10/10, **W04 se detiene** hasta nuevo encargo oficial. El último documento de referencia del protocolo es `AUTONOMOUS_REPAIR_V5.md` en la rama árbitra.

**Rutas de recuperación:** `tests/gameplay/parallel_items_w04_campaign_003.gd`, `tests/tools/test_parallel_items_w04_campaign_003.py`, `tests/fixtures/parallel_items/w04_campaign_003.json`, `docs/coordination/items_parallel_v1/reports/W04/CAMP_003_PROGRESO.csv` y `CAMP_003_FINAL.md`. Todos los informes ITER_01..ITER_10 permanecen en la misma carpeta.


---

## CAMPAÑA_004 — Bloque 01 (2026-11-03)

Esta sección reemplaza exclusivamente la indicación anterior de STOP tras CAMPAÑA_003; **no** borra ni corrige retroactivamente el cierre de CAMP003. Identidad **IA4/W04**, única rama activa de escritura: `codex/calvo-items-20261103-w04-camp004`. Encargo autorizado por IA6: `CAMPAIGN_004_W04_GATE.md`, `CAMPAIGN_004_W04_QUEUE_APPROVED.csv` y `campaigns/CAMP_004_W04.md` en rama árbitra.

**Estado CAMP004:** **01/10 entregado** (`berry_sweet;clover_sweet;flower_sweet`). CI real [#41575404407](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41575404407), PASS: Python 48, Godot 101, regresión CAMP003 Python 120 / Godot 270. Los tres confites están presentes pero tienen **0 registros evolutivos por item en catálogo runtime** y la mecánica canónica de giro de Milcery no tiene ruta positiva soportada. Resultado: `DEPENDENCIA_DOCUMENTADA`; no son tres evoluciones funcionales.

**Rutas de trabajo nuevo:** `tests/gameplay/parallel_items_w04_campaign_004.gd`, `tests/tools/test_parallel_items_w04_campaign_004.py`, `tests/fixtures/parallel_items/w04_campaign_004.json`, `reports/W04/CAMP_004_PROGRESO.csv`, `reports/W04/CAMP_004_ITER_01.md`. Conservar intactos CAMP003 (10/10 y 16 dependencias) y CAMP001 (6 piedras). No editar producción, ramas ajenas ni datasets canónicos sin motivo y límites V5.

**Siguiente orden `p`:** ejecutar únicamente CAMP004 bloque **02/10** `love_sweet;ribbon_sweet;star_sweet`, verificando primero el último run de CI en rama. Seguir los IDs exactos por cola oficial, no anticipar bloques 03–10 ni declarar PASS sin Godot.


---

## CAMPAÑA_004 — Bloque 02 (2026-11-03)

**IA4/W04**, rama exclusiva `codex/calvo-items-20261103-w04-camp004`. Nuevo bloque **02/10** con `love_sweet;ribbon_sweet;star_sweet`, en runner y validador acumulativos de CAMP004 y fixture `tests/fixtures/parallel_items/w04_campaign_004.json`. Informes en `reports/W04/CAMP_004_ITER_02.md`. La CI de entrega [#41575954355](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41575954355) terminó PASS (Python 65, Godot 200, regresión CAMP003 Python 120/Godot 270). Los tres confites nuevos tienen 0 registros de evolución directa y quedan DEPENDENCIA_DOCUMENTADA. No se ha editado producción ni ramas ajenas.

Todos los confites probados están asociados al requisito de giro `spin` de Milcery, clasificado `UNSUPPORTED`, sin inventar `use_item`. **CI PASS de pruebas negativas no implica evolución positiva ni selección de formas**. Continúan las tres dependencias del bloque 01 y las dieciséis de CAMP003. Próximo `p`: únicamente bloque **03** (`strawberry_sweet;whipped_dream;leaders_crest`), comprobando primero CI02. Mantener intactos CAMP003 y CAMP001.


---

## CAMPAÑA_004 — Bloque 03 (2026-11-03)

**Identidad:** IA4/W04. **Única rama de escritura activa:** `codex/calvo-items-20261103-w04-camp004`.

**Estado:** 03/10 microbloques publicados, 9 IDs auditados en CAMP004. La CI [#41576674332](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41576674332) finalizó `completed/success` con Python 88, Godot 292 y regresión CAMP003 Python 120 / Godot 270. Tres IDs añadidos: `strawberry_sweet`, `whipped_dream`, `leaders_crest`. Los tres presentan `status=DEPENDENCIA records=0`; no hay evolución directa ejecutable en datos, aunque se validan rechazos, inventario y SaveV2.

**Dependencias CAMPAÑA_004:** siete confites de Milcery requieren `spin` y selección de forma; `whipped_dream` necesita la modalidad original de intercambio/objeto equipado; `leaders_crest` requiere contexto de Bisharp y 3 derrotas. Los 9 IDs son auditorías con tests negativos, **0 evoluciones nuevas certificadas**. Las 16 dependencias de CAMPAÑA_003 siguen sin resolver. Ninguna mecánica nueva ha sido inventada o implementada por W04.

**Rutas:** `tests/gameplay/parallel_items_w04_campaign_004.gd`, `tests/tools/test_parallel_items_w04_campaign_004.py`, `tests/fixtures/parallel_items/w04_campaign_004.json`, `reports/W04/CAMP_004_PROGRESO.csv`, `reports/W04/CAMP_004_ITER_03.md`. Mantener intactas las pruebas CAMP003/CAMP001.

**Siguiente `p`:** bloque 04/10 `adamant_crystal;blue_orb;catching_charm`, previa verificación de la CI posterior a la reconciliación CSV. No editar `main`, V28, rama árbitra, ramas de otras trabajadoras, catálogo ni arquitectura.


---

## CAMPAÑA_004 — Bloque 04 (2026-11-03)

**IA4/W04**, rama exclusiva `codex/calvo-items-20261103-w04-camp004`. El microbloque **04/10** está publicado con `adamant_crystal;blue_orb;catching_charm`, fixture 04, runner Godot acumulativo y Python, CSV `CAMP_004_PROGRESO.csv` e informe `CAMP_004_ITER_04.md`. CI del primer SHA completo [#41578460848](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41578460848) PASS (Python 114, Godot 382, regresiones CAMP003 120/270); CI tras consolidación del CSV [#41578687219](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41578687219) también PASS en SHA `4b93b0af42bebc2c5298fe26f384e191a84bdafa`. Tres IDs revisados, dos dependencias de forma y auditoría de datos del amuleto sin certificar captura.

**Hechos comprobados en perfiles:** `adamant_crystal` y `blue_orb` figuran como equipables, pero la transferencia del objeto no certifica forma de Dialga ni reversión primigenia de Kyogre; `catching_charm` no está entre los equipables. El runner prueba uso directo/evolución falsa rechazados sin gasto, propiedad, equipamiento y SaveV2 cuando corresponde. **No prueba ni modifica efectos de captura de W03**. Son revisiones de contexto, no implementaciones de formas o mejoras de captura.

Las **16 dependencias CAMP003** y **9 dependencias CAMP004 bloques 01–03** siguen intactas. No se ha tocado producción, políticas, datasets, otras ramas, `main` ni V28. La cola sigue la puerta de IA6, siguiente `p` **bloque 05/10**: `dna_splicers;exp_charm;gracidea`, previa verificación de CI04 y reparación si procede.


---

## CAMPAÑA_004 — Bloque 05 (2026-11-03)

**IA4/W04**, rama exclusiva `codex/calvo-items-20261103-w04-camp004`. Bloque 05 **publicado en pruebas**: `dna_splicers;exp_charm;gracidea`. Los 3 son `STORY_KEY_OR_FORM_REVIEW` y están seleccionados; en el inventario canónico aparecen `DATA_ONLY` y el perfil no los permite equipar. Pruebas Godot/Python acumulativas, fixture, CSV e informe `CAMP_004_ITER_05.md` publicados.

**CI inicial:** [#41579180249](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41579180249), SHA `26da57ec3496f03b728cc60f4ffc9206ec71a485`, `completed/success`: CAMP004 Python **147**, Godot **455**, regresión CAMP003 Python **120** y Godot **270**, regresión CAMP001 SaveV2 seis piedras **559 comprobaciones/12 casos**. Tres objetos clasificados DEPENDENCIA por ausencia de sistema propio de fusión/EXP/forma; CSV consolidado a DEPENDENCIA_DOCUMENTADA. No se atribuyen fusiones Kyurem, efectos EXP ni forma Shaymin por un PASS negativo.

**CI consolidada:** [#41579352482](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41579352482), SHA `ba870381e0a5b2215a925be44487e5613157b777`, `completed/success`. Repite CAMP004 Python 147/Godot 455; regresiones CAMP003 120/270 y CAMP001 559 comprobaciones/12 casos. Bloque 05 terminado como auditoría y dependencias documentadas; próxima `p` ejecuta exclusivamente bloque 06. Próximo `p`: **bloque 06**, `griseous_core;lustrous_globe;meteorite`. No actuar sobre otros bloques ni tocar producción compartida, main, V28 o ramas ajenas. 16 dependencias CAMP003 siguen pendientes.


---

## CAMPAÑA_004 — Bloque 06 (2026-11-03)

**IA4/W04**, rama exclusiva `codex/calvo-items-20261103-w04-camp004`. Bloque **06/10 publicado** para `griseous_core;lustrous_globe;meteorite`, en `tests/gameplay/parallel_items_w04_campaign_004.gd`, `tests/tools/test_parallel_items_w04_campaign_004.py`, `tests/fixtures/parallel_items/w04_campaign_004.json`, `reports/W04/CAMP_004_PROGRESO.csv` y `reports/W04/CAMP_004_ITER_06.md`. La primera CI [#41584213703](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41584213703) falló por un literal obsoleto `blocks=5` del validador. Se reparó sin debilitar contratos en commit `64f688735428722fb0f5970a0be0f9ebb11a42e1`. La CI corregida [#41584355240](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41584355240) terminó `completed/success`: CAMP004 Python 181 y Godot 565, regresión CAMP003 Python 120 / Godot 270. Los tres ítems quedan DEPENDENCIA_DOCUMENTADA por falta de forma ejecutable. CSV actualizado en `ce99a4a70514b3d952a59ee863f07f770af71f6a`.

**Contratos del bloque 06:** Gran Griseosfera y Gran Lustresfera son equipables y su transferencia está documentada `VERIFIED`, pero su forma especial/efecto continúa `NATIVE_ENTRY_REQUIRES_EFFECT_CASE`; Meteorito no es equipable y aparece `DATA_ONLY`. El runner rechaza falsos cambios de forma y consumo desde mochila, controla equipar/retirar e identidad/SaveV2. No se han implementado transformaciones ni manipulado producción.

**Incidencia previa:** el intento de escritura anterior del runner fue bloqueado por un control de seguridad. Con el nuevo `p` se reintentó la **misma operación normal en la rama propia** y funcionó (commit `4940c32e47488bc24d606876f3f5c127344b6433`); no hubo modificación de permisos ni derivación. Regresiones CAMP003 y CAMP001 preservadas.

**Al siguiente `p`:** comprobar la CI definitiva del bloque 06 y reparar errores propios si los hay. Si CI correcta, ejecutar solamente **bloque 07/10** `rage_candy_bar;red_orb;reins_of_unity`. Mantener backlog de 16 dependencias CAMP003 sin repetir su trabajo. No editar `main`, V28, rama árbitra o ramas ajenas.


**CI posterior de CSV consolidado (bloque 06):** [#41584473320](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41584473320), SHA `ce99a4a70514b3d952a59ee863f07f770af71f6a`, `completed/success`: CAMP004 Python 181, Godot 565 y regresiones CAMP003 120/270. **Cierre del bloque 06 verificado 6/10**, 18 IDs auditados en CAMP004 y 16 dependencias heredadas de CAMP003 sin resolver. Siguiente `p` exclusivamente bloque 07: `rage_candy_bar;red_orb;reins_of_unity`.


---

## CAMPAÑA_004 — Bloque 07 (2026-11-03)

**Identidad:** IA4/W04. **Rama exclusiva:** `codex/calvo-items-20261103-w04-camp004`. Bloque **07/10 publicado** para `rage_candy_bar;red_orb;reins_of_unity`: runner Godot, Python, fixture, CSV e informe `reports/W04/CAMP_004_ITER_07.md`. La ejecución que contiene toda la entrega es [#41589367209](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41589367209), commit `0c02e95ba2d13f726dfb4c02cb692946680bd990`. **Comprobar estado y logs antes de aceptar.**

**Hallazgo diferenciador:** `rage_candy_bar` **sí está conectado** en `modules/inventory/imported_recovery_v19.json`: curación de estados/confusión, consume al funcionar. El registro `ITEM_INVENTORY.csv` como `DATA_ONLY` se refiere a su entrada de otro motor, y no debe interpretarse como ausencia de recuperación de campo. Las pruebas publicadas verifican cura positiva de quemadura y no doble gasto, junto a SaveV2. **No modificar sistema de medicina de W02.** `red_orb` es equipable, sin reversión primigenia certificada; `reins_of_unity` no es equipable, fusión de Calyrex sin contrato funcional. No inventar transformaciones de forma.

**Regresiones:** CAMPAÑA_003 mantiene 10/10 y sus 16 dependencias funcionales. CAMPAÑA_001 está conservada y se ejecuta específicamente en bloques 05 y 10. Sin cambios en producción, catálogo, workflow, `main`, V28, rama árbitra u otras trabajadoras.

**Próxima `p`:** revisar CI07, reparar fallos propios; después ejecutar **solo bloque 08/10** `reveal_glass;rotom_catalog;zygarde_cube`. No repetir los 7 bloques ni avanzar antes de aceptar.


---

## CAMPAÑA_004 — Bloque 08 (2026-11-03)

**Identidad:** IA4/W04, rama exclusiva `codex/calvo-items-20261103-w04-camp004`.

**Puerta previa:** CI de bloque 07 consolidado [#41589609852](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41589609852), `completed/success` en SHA `dc2b596533dac833ccb509753e93847b391c67a6`, Python CAMP004 **211** comprobaciones, Godot **656**, regresión CAMP003 Python **120** / Godot **270**. `rage_candy_bar` tiene efecto de recuperación de quemadura y consumo unitario **positivo verificado**; `red_orb` y `reins_of_unity` conservan dependencias. Este dato reemplaza la nota anterior del bloque 07 que decía comprobar su estado.

**Bloque 08/10 publicado**, IDs autorizados `reveal_glass;rotom_catalog;zygarde_cube`, pruebas en `tests/gameplay/parallel_items_w04_campaign_004.gd`, validador `tests/tools/test_parallel_items_w04_campaign_004.py`, fixture `tests/fixtures/parallel_items/w04_campaign_004.json`, estado `reports/W04/CAMP_004_PROGRESO.csv`, informe `reports/W04/CAMP_004_ITER_08.md`. CI de entrega [#41591880287](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41591880287), SHA `2ac9b2cef1486e074f57ecf01232333bbaf793e7` — comprobar final y corregir errores si procede.

**Contratos:** los tres objetos están seleccionados y tienen `DATA_ONLY`, no son equipables bajo el perfil actual. `rotom_catalog` conserva `missing_description`. El runner comprueba origen/controles de Tornadus, Rotom, Zygarde y Eevee, rechazos sin consumo, identidad y SaveV2, y no promete cambios de formas sin motor. No se han tocado las 16 dependencias CAMP003, las pruebas de CAMP001, `main`, V28, rama árbitra, producción ni ramas ajenas.

**Siguiente `p`:** una vez comprobada CI08, ejecutar exclusivamente el bloque **09/10**: `n_lunarizer_merge;n_solarizer_merge;roto_catch;roto_exp_points;roto_friendship`. No adelantar trabajo de captura/entrenamiento de W03/W02.
