# IA4/W04 — LOTE_002 / Pruebas parametrizadas de evolución

**Estado final: LISTA_PARA_REVISION (PENDIENTE_CI, SIN PASS FUNCIONAL NUEVO).** Fecha: 2026-11-01.

Rama exclusiva: codex/calvo-items-20261101-w04.
Asignación oficial: docs/coordination/items_parallel_v1/assignments/LOTE_002_W04.md de la rama árbitra; blob SHA 9840c0d6c1a64fd35de3325d2b1f2426e283bb90.
IDs: auspicious_armor, malicious_armor y black_augurite.

## 1. Sincronización obligatoria comprobada

- Checkpoint IA6: 38188cc208e67b19002437ac75160898ce332ec2.
- Merge solo en rama W04: 05ae7fdc74aa117a213ae2d09b34c1dbbe8e78c3. Sus padres son el HEAD propio aceptado de LOTE_001 (26eabd19cea4f2b9c88961e3b03852b32eaf8ea4) y el checkpoint IA6. Actualización no forzada con expected_sha.
- W04 quedó cero commits detrás de ambos padres. Al comparar su árbol con la base de IA6, solo difería LOTE_001.md. Blob LOTE_001 intacto: e452f523a3965c0ca53f34a689b76fb4c38b5b7f.
- Verificados en W04: tools/item_audit/automation_v28.py (blob ae181662b315f033172a5cfef4a87961088fe8fd); docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv (8b9b723bf5944bbbde39aa2d49dfbb2f2a64e11b); NOTEBOOK_PROTOCOL_V1.md (4fac0eba28ea30dc6d3a3bd749699874cf446e66).
- Base fusionada V27+V28: BASE_COMBINADA_SIN_CI. Ninguna prueba histórica certifica esta fusión.

## 2. Contrato previo y detección de duplicados

| ID | Ruta canónica de uso | Evidencia previa (HISTÓRICA, no PASS hoy) |
| --- | --- | --- |
| auspicious_armor | Charcadet → Armarouge, use_item | Una ruta positiva en ITEM_CONNECTIONS_V1; equipamiento transferible |
| malicious_armor | Charcadet → Ceruledge, use_item | Una ruta positiva V1; equipamiento transferible |
| black_augurite | Scyther → Kleavor, use_item | Una ruta positiva V1; NO tiene definición nativa equipable |

Referencias: data/api/v2/evolution-chain/490/index.json y 58/index.json; docs/current/ITEM_CONNECTIONS_V1.json (blob 59a90a0cb9adc03810d06bbcc44f97e51f85e1c2); docs/current/ITEM_INVENTORY.csv; modules/inventory/item_connections_v1.json (blob 0525b37021edfc2e74c4fc2cb96e62f6f5b3e261).

La ruta preexistente es EvolutionSystem.classify_record/evolution_candidates/apply_evolution → FieldItemService.evolution_options/evolve/use_item → PlayerInventory y PlayerCollection.replace_owned_same_identity → SaveGameRepository.save_collection/load → campo y UI mediante field_item_bag.gd. No se creó otro motor, ni funciones productivas por ID.

El runner existente tests/gameplay/item_connections_test_runner.gd ya cubría evoluciones, guardado y casos negativos genéricos. El checkpoint histórico V27 6629fe570cdf4c891a937c3f2a74b45e960dc902 informa Godot Windows 4.7, ITEM_CONNECTIONS 4993 checks PASS (equip=624, evolutions=72, machines=229), más 89+20 checks de grupos distintos. Es una prueba real anterior, no una prueba del código combinado.

## 3. Cambios exactos autorizados

1. tests/gameplay/parallel_items_w04_evolution_v1.gd — blob ab947ef6fcd739e3ccefc75e888621ad23c716ac. Un SceneTree con 3 casos en una tabla común, sin tocar lógica de producción. Emite un JSON de resultado con marcador PARALLEL_ITEMS_W04_EVOLUTION_V1 y exit distinto de cero al fallar.
2. tests/tools/test_parallel_items_w04_evolution_v1.py — blob d637870c5bf66d2eddad8753d1aba56e18755749. Valida contratos desde datos existentes del checkout; opcionalmente invoca Godot con --godot y exige JSON PASS, 3 casos y al menos 55 aserciones sin errores. El modo estático NO certifica ejecución GDScript.
3. docs/coordination/items_parallel_v1/reports/W04/LOTE_002.md — este informe.
4. docs/coordination/items_parallel_v1/reports/W04/CONTINUIDAD.md — cuaderno mutable, memoria de relevo.

**Cobertura prevista de GDScript POR CADA OBJETO:** origen/destino permitidos; cero unidades rechaza sin gastar; criatura ajena rechazada sin gastar; alternativa equivocada rechazada sin mutación; bloqueo en actividad; éxito que consume exactamente una unidad y conserva identidad, IV, EV, amistad y movimientos; segunda evolución no válida; KO sin reanimación; propiedad en PC; guardar/cargar primero el Pokémon sin evolucionar y luego el evolucionado, conservando ubicación y cantidad. Usa SaveGameRepository y datos reales, no mocks de la lógica. Los guardados aislados de test son user://w04_evolution_<item>.json y se borran tras el caso.

**Ejecución reproducible para revisión, desde un checkout completo con Godot 4.7:**

    python -B tests/tools/test_parallel_items_w04_evolution_v1.py
    godot --headless --path . --import
    python -B tests/tools/test_parallel_items_w04_evolution_v1.py --godot godot

O directamente: godot --headless --path . --script res://tests/gameplay/parallel_items_w04_evolution_v1.gd

Para Windows indicar la ruta completa a Godot_v4.7-stable_win64_console.exe. Si la base exige restaurar recursos, seguir el workflow V28 antes de importar. Ejecutar una única CI consolidada tras aceptación por IA6, no multiplicar workflows.

## 4. Evidencias nuevas, separadas por fiabilidad

- **Git/GitHub, PASS real:** merge correcto, conservación de LOTE_001, presencia de fuentes y publicación de scripts.
- **Cotejo estructural ejecutado por conexión GitHub y comprobador independiente en memoria: 21/21 PASS**, tres cadenas originales con fuente, catálogo/selección, inventario, reporte V1, diferencia held y escenarios presentes en los dos nuevos scripts. Esto es evidencia de consistencia de archivos, NO GDScript ejecutado, y no equivale a haber ejecutado el nuevo validador Python.
- **Python en checkout completo: SIN_EJECUTAR.** En este entorno solo hay acceso conector a los ficheros, no checkout local íntegro.
- **Godot 4.7 headless sobre este commit: SIN_EJECUTAR / PENDIENTE_CI.** No hay binario Godot ni checkout; no se lanzó Actions para no consumir CI individual.
- **GPU e interfaz gráfica: NO REALIZADA.** La prueba creada es headless; PC se refiere a propiedad de almacenamiento, no interfaz visual.

## 5. Riesgos y traspaso IA6

- El código GDScript debe importarse y ejecutarse de verdad antes de concluir PASS. Si presenta Parse Error o una aserción FAIL, registrar log completo, SHA, escenario y no maquillar resultados ni reescribir motor fuera del encargo.
- Archivos compartidos protegidos: modules/inventory/field_item_service.gd; modules/creatures/progression/evolution_system.gd y progression_system.gd; modules/save/*; scenes/visual/field_item_bag.gd; test V27/V28; datasets y políticas. Solicitar propiedad exclusiva a IA6 para cualquier eventual arreglo productivo.
- La ruta de Mineral Negro funciona por uso directo y no requiere entrada de equipamiento nativa. Las dos armaduras son equipables por metadatos, pero equiparlas no activa la evolución.
- Las evoluciones por intercambio y niveles futuros permanecen aplazadas. No inventarlos.
- Siguiente paso: IA6 revisa diffs, integra scripts secuencialmente, ejecuta import y validador + Godot 4.7 en una batería conjunta. Si falla, documentar fallo nominal y asignar reparación en un lote nuevo. No comenzar LOTE_003 por iniciativa propia.

**Autocontrol:** únicamente cuatro rutas de escritura autorizadas; LOTE_001 preservado; cero cambios a producción, datos, CI, selección, main, V28, árbitra o ramas ajenas.

**LISTA_PARA_REVISION — pruebas preparadas, sin PASS funcional nuevo.**
