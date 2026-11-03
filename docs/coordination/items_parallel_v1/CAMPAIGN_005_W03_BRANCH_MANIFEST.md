# IA6 — MANIFIESTO RAMA / CAMPAÑA_005 W03

**Fecha:** 2026-11-03. **Estado:** ACTIVADA Y BOOTSTRAP VERIFICADO.

- **Rama exclusiva:** `codex/calvo-items-20261103-w03-camp005`, creada desde HEAD completo de CAMP004 `6c8de327286f5b020b0c94355da7455367a97b0f`. Conserva pruebas, resultados y progreso de CAMP004 sin alteración de rama origen.
- **Autoridad actual:** [gate](CAMPAIGN_005_W03_GATE.md), [cola](CAMPAIGN_005_W03_QUEUE_APPROVED.csv), [encargo](campaigns/CAMP_005_W03.md), [activación](CAMPAIGN_005_W03_ACTIVATION_MESSAGE.md); copias de gate/cola/encargo en la rama W propia.
- **Reserva:** 10 microbloques / 28 objetos ya auditados para integración pendiente. NO son IDs nuevos. Se autorizan tareas de integración con contratos funcionales o dependencias concretas, sin contar como implementado un negativo.
- **Scaffolding:** `reports/W03/CAMP_005_PROGRESO.csv` solo cabecera; fixture `tests/fixtures/parallel_items/w03_campaign_005.json` con `blocks=[]`; validador `tests/tools/test_parallel_items_w03_campaign_005_manifest.py`; workflow `.github/workflows/parallel-camp005-w03-autoci.yml`. Los runners funcionales CAMP005 se crean al ejecutar el bloque 01 por W03.
- **Bootstrap real:** [GitHub Actions #41711308425](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41711308425) `completed/success` en SHA `22625c9e2a83af2c71e383291f3d8c18f4376cd8`; valida identidad/cola/progreso, 0/10. Los pasos Python/Godot de mecánicas nuevas NO se ejecutan durante bootstrap. **PASS de configuración NO equivale a 28 efectos funcionales**.
- CI reparada tras error inicial de plantilla YAML. Se conservan regresiones CAMP004 y CAMP003 en hitos 05/10 y parches funcionales. No se han modificado `main`, V28, PR118 ni otras ramas.

**Siguiente orden:** enviar el mensaje de activación al chat W03; bloque 01 comienza al recibirlo, después una `p` por microbloque hasta 10/10 y STOP.
