# IA1/W01 — TANDA 04 · checkpoint inicial (fila 01 en CI)

- **Orden vigente:** `IA6_AUTORUN.md` TANDA04, cola maestra `QUEUE_W01_TANDA_04.md`. Rama exclusiva `codex/calvo-items-20261110-w01-gems-autobatch01`.
- **TANDA03 certificada por IA6:** CI #42918737459 SUCCESS sobre `dd0eab2509e50e44597de3d8d39366b7f3f823b3`. No se repiten gemas.
- **Diez IDs:** `leftovers`, `life_orb`, `choice_band`, `choice_specs`, `choice_scarf`, `shell_bell`, `eviolite`, `safety_goggles`, `black_sludge`, `sitrus_berry`.
- **Política auditada:** los 10 figuran `SELECCIONADO` en `RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`, `native_entry=True` en `ITEM_INVENTORY.csv` y están `holdable_ids`. Esta verificación L1 **no** significa funcionalidad L3.
- **Histórico:** Restos, Vidasfera, Cinta Elegida y Baya Zidra constan con piloto nativo previo en `tools/item_audit/held_pilot.cjs`; Lodo Negro, Campana Concha, Mineral Evolutivo y Gafas Protectoras tienen matrices antiguas en `w01_campaign_001`. Falta cotejar si algún efecto ya tiene L3 equivalente. No sumar nuevos objetos por volver a probar.
- **Fila 01 Restos:** fixture, validador Python, prueba nativa y GDScript L3 nuevo con cuatro variantes (portador, ninguno, reserva, PS completos). La prueba enlaza `FieldItemService.equip`, `FieldNativeSession`, turno natural y `settle_finished_battle`, `SaveGameRepository` en disco.
- **Estado:** fila 01 `EN_CI_AUTOMATICA` hasta verificar run y su SHA. Ningún PASS afirmado. Filas 02–10 pendientes.
- **Siguiente p:** consultar estado de la CI V4; corregir solo runner/tests/workflow propios si hay fallo. Certificar fila 01 únicamente con SUCCESS y evidencia; continuar filas siguientes sin permisos nuevos. Si hay bloqueo de productor protegido, ticket claro.
- **Limitación:** sin ejecución de GitHub Actions no se asume que la nueva prueba funcione; no se ha tocado código de producción ni otras ramas.
