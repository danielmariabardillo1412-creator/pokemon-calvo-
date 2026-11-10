# IA1/W01 — TANDA03 — CHECKPOINT DE INICIO

- **Tanda vigente:** TANDA 03, orden en `docs/coordination/items_parallel_v1/IA6_AUTORUN.md`.
- **Rama exclusiva:** `codex/calvo-items-20261110-w01-gems-autobatch01`.
- **Hitos TANDA03:** 0/10 certificados; objetos nuevos 0; pruebas/QA por certificar; integración IA6 NO.
- **Histórico:** CAMP005, TANDA01, TANDA02 finalizadas. CI documental TANDA02 #42874605439 SUCCESS, no se repiten pruebas antiguas como nuevas.
- **Nueva entrega en desarrollo:** un fixture de 18 gemas, runner `tests/gameplay/parallel_items_w01_autorun_v3.gd`, audit Python y workflow autónomo propio. El runner usa `FieldItemService.equip`, `FieldNativeSession`, `settle_finished_battle`, `SaveGameRepository.save_collection/load`, ruta legacy V1. Aún NO afirmar que funcione sin CI.
- **Limitación explícita:** el primer runner no cubre todos los terminales derrota/captura/Transformación ni pantalla UI. Hitos 07/09 requieren investigación y evidencia separadas.
- **Al recibir siguiente `p`:** leer orden actual; ver run CI V3 y sus logs; corregir solamente helpers y tests de W01; si hace falta módulo compartido, documentar ticket y continuar otras pruebas independientes.
- **Protecciones:** sin escribir main/V28/PR118, árbitra, otros trabajadores, archivos de producción protegidos, ni tests históricos.
