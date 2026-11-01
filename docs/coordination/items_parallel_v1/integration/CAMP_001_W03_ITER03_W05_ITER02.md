# IA6 — CAMP_001 nueva entrega W03/ITER_03 y W05/ITER_02

**Fecha:** 2026-11-02. **Estado:** integrado en rama árbitra, prueba acotada positiva en staging. No tocar main/V28, cambios de otras trabajadoras ni selección.

## Fuente exacta
- W03: rama `codex/calvo-items-20261101-w03` HEAD `c2c48204dafdb89571d5a0e74b3226e6e3ca5233`, campaña 03/03 FINALIZADA. Solo se incorporaron nueva prueba `tests/gameplay/parallel_items_w03_net_campaign_001.gd` y ampliación Python `tests/tools/test_parallel_items_w03_net_campaign_001.py`, en commit `60e2082e0a0652581afc56f3b27434b7ec9728b7`.
- W05: rama `codex/calvo-items-20261101-w05` HEAD `fe0ddcb26ea97543979fb20859675ca20d6613e9`, campaña 02/03 preparada. Se incorporaron solo `modules/inventory/field_machine_book_profile.gd` y su prueba `tests/gameplay/parallel_items_w05_machine_books_v1.gd`, en commit `5ebc65b47e8480a9193880dfca8fb6cfe34e1231`.
- Blobs exactos, comprobados con staging `3dba61641f285300375220c6fc9f3fcc25b89dac`. Ningún cuaderno de trabajadora fue sobrescrito; reportes originales permanecen en su rama.

## Ejecución automática
- [Actions #41362240030](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41362240030), SHA staging `3dba61641f285300375220c6fc9f3fcc25b89dac`, Godot 4.7, Node 22, simulator native pinned: `completed/success`.
- W03 nueva suite: `CAMP_001_W03_NET {"checks":60,"errors":[],"status":"PASS"}`; prueba previa 34 checks y Python fase implementación correctas. La suite revisa un doble tipo, captura/SaveV2, fallo, negativas y selector de datos. No implica prueba GPU.
- W05 etiqueta en español y tipo sobre 229 máquinas activas, 19 antiguas rechazadas: `W05 CAMP_001/01: 959 comprobaciones, 0 errores`; Python 14 tests unitarios PASS. **No certifica UI gráfica, aprendizaje ni consumo:** ITER_03 sigue sin ejecutar.
- La regresión de paquete en árbol árbitra no reemplaza estos tests nuevos si workflow principal no los invoca. Las pruebas certificadas son las del staging exacto y los cuatro blobs idénticos que se integraron.

## Autorización
- W03: **STOP** `CAMPAÑA_001_FINALIZADA` (03/03); no cuarto microbloque.
- W05: se levanta `BLOQUEADO_PENDIENTE_CI` del bloque 02 después de comprobar PASS y equivalencia de blobs. **Puede recibir un único `p` para ITER_03**, sujeto a los permisos originales de campaña, sin duplicar `FieldItemService.teach`; exige después CI nueva propia.
- W01 03/03 y W02 03/03: STOP por campaña finalizada. W04 02/03: congelada por decisión de usuario; no intervenir ni reemplazar ahora.
