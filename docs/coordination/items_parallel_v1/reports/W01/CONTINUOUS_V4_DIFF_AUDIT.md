# IA1/W01 · CONTINUOUS_V4 · Fase A — comparación funcional selectiva

**Misión V4 activada tras cerrar V2**: [READY_FOR_IA6 en rama histórica](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261110-w01-gems-autobatch01/docs/coordination/items_parallel_v1/CONTINUOUS_V2/READY_FOR_IA6.md). Gates V2: #42958587809 38/38 SUCCESS; policy #42960157622 SUCCESS; ledger #42964085232 SUCCESS (`total_certified=32 external=4`). La staging **no** es integración oficial IA6.

- Origen W01 exacto: `f73f775a183382607d0eacb450ce25eead1851e3`, solo tras V2 completa.
- Base IA6 exacta: `e63b2e6c7e175fba318cc2f562bebd1769589092`; staging creada desde ella. Inspección de árboles Git `recursive=1`, sin truncación; origen 35.808 entradas, base IA6 35.649.
- **Motor nativo `modules/battle/backends/showdown/native_engine.cjs`: IGUAL** en origen y staging, Git blob SHA `073e5c8523f47a477735b98a766437392c201e33`. Incluye ya el arreglo de snapshot tras Transformación. **NO_DIFF_NEEDED; prohibido copiar toda la clase o repetir parche genérico**.
- **Conexiones held `modules/inventory/item_connections_v1.json`: IGUAL**, blob SHA `0525b37021edfc2e74c4fc2cb96e62f6f5b3e261`.
- **Política `config/item_selection_v1.json`: IGUAL** (incluye veto `dynamax_candy`), blob SHA `bf76a361b30e158f613f31ef275006862562cea8`.
- De `modules/`, `scenes/`, `config/` y `data/`, solo nueve diferencias de blobs entre origen y base integradora: cuatro ficheros compartidos tienen revisiones propias IA6 (`modules/creatures/domain/creature_instance.gd`, `modules/inventory/field_item_service.gd`, `modules/save/field_native_save.gd`, `scenes/visual/field_item_bag.gd`); cinco existen solo en IA6 (mentas, Cuerda Huida, repelente, transacción de campo y panel libros). **NO sobrescribirlos desde W01**: pertenecen a dependencias cruzadas W02/W03/W05. Las pruebas L3 se repetirán contra estas revisiones de staging.
- Las 60 rutas de test W01 compartidas entre origen y staging tienen exactamente el mismo Git blob; tests V2 nuevos no están en staging. En staging ya existen `tests/gameplay/parallel_items_w01_campaign_001.gd`, fixture, validador Python y `tests/tools/repro_w01_camp005_b06_transform.cjs`; se reutilizan para ensayar producción sin copiar suites enteras.

**Conclusión PRELIMINAR FASE A:** No hay un hunk específico de held de W01 ausente en los archivos de producción comparados. **No declarar aún integración funcional local ni `READY_FOR_IA6_MERGE`**: falta ejecutar regresiones nativas y L3 sobre las diferencias compartidas de IA6. Si salen PASS, registrar `NO_DIFF_NEEDED` sin transplantar producción.

**Ámbito:** staging exclusiva `codex/calvo-ia6-staging-20261111-w01-held`, cero edición de `main`, V28, PR118, rama integradora IA6, o staging ajena. La CI nueva es de ensayos locales, no sustituye la CI fuente ya cerrada.
