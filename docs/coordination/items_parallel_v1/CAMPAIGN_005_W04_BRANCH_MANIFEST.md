# IA6 — MANIFIESTO RAMA / CAMPAÑA_005 W04

**Fecha:** 2026-11-03. **Estado:** ACTIVADA Y BOOTSTRAP VERIFICADO.

- **Rama exclusiva:** `codex/calvo-items-20261103-w04-camp005`, creada desde HEAD completo de CAMP004 `55e56056d1b97ccca19b7ccad95b71167b0f5863`. Conserva pruebas, resultados y progreso de CAMP004 sin alteración de rama origen.
- **Autoridad actual:** [gate](CAMPAIGN_005_W04_GATE.md), [cola](CAMPAIGN_005_W04_QUEUE_APPROVED.csv), [encargo](campaigns/CAMP_005_W04.md), [activación](CAMPAIGN_005_W04_ACTIVATION_MESSAGE.md); copias de gate/cola/encargo en la rama W propia.
- **Reserva:** 10 microbloques / 46 objetos ya auditados para remediación evolutiva y formas. NO son IDs nuevos. Se autorizan tareas de integración con contratos funcionales o dependencias concretas, sin contar como implementado un negativo.
- **Scaffolding:** `reports/W04/CAMP_005_PROGRESO.csv` solo cabecera; fixture `tests/fixtures/parallel_items/w04_campaign_005.json` con `blocks=[]`; validador `tests/tools/test_parallel_items_w04_campaign_005_manifest.py`; workflow `.github/workflows/parallel-camp005-w04-autoci.yml`. Los runners funcionales CAMP005 se crean al ejecutar el bloque 01 por W04.
- **Bootstrap real:** [GitHub Actions #41711566627](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41711566627) `completed/success` en SHA `c8136c56ec41c8f0d06ac7af98a0d890d422f8c8`; valida identidad/cola/progreso, 0/10. Los pasos Python/Godot de mecánicas nuevas NO se ejecutan durante bootstrap. **PASS de configuración NO equivale a 46 efectos funcionales**.
- CI reparada tras error inicial de plantilla YAML. Se corrigió además la diferenciación de historial frente a nuevos IDs. Se conservan regresiones CAMP004 y CAMP003 en hitos 05/10 y parches funcionales. No se han modificado `main`, V28, PR118 ni otras ramas.

**Siguiente orden:** enviar el mensaje de activación al chat W04; bloque 01 comienza al recibirlo, después una `p` por microbloque hasta 10/10 y STOP.
