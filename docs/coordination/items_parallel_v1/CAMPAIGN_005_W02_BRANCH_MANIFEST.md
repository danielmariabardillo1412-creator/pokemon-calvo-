# IA6 — MANIFIESTO RAMA / CAMPAÑA_005 W02

**Fecha:** 2026-11-03. **Estado:** ACTIVADA Y BOOTSTRAP VERIFICADO.

- **Rama exclusiva:** `codex/calvo-items-20261103-w02-camp005`, creada desde HEAD completo de CAMP004 `ec1d6d98172281d01175c8824024085b446f9b98`. Conserva pruebas, resultados y progreso de CAMP004 sin alteración de rama origen.
- **Autoridad actual:** [gate](CAMPAIGN_005_W02_GATE.md), [cola](CAMPAIGN_005_W02_QUEUE_APPROVED.csv), [encargo](campaigns/CAMP_005_W02.md), [activación](CAMPAIGN_005_W02_ACTIVATION_MESSAGE.md); copias de gate/cola/encargo en la rama W propia.
- **Reserva:** 10 microbloques / 40 objetos de entrenamiento nuevos. 40 IDs TRAINING nuevos; no incluyen Caramelo Dinamax.
- **Scaffolding:** `reports/W02/CAMP_005_PROGRESO.csv` solo cabecera; fixture `tests/fixtures/parallel_items/w02_campaign_005.json` con `blocks=[]`; validador `tests/tools/test_parallel_items_w02_campaign_005_manifest.py`; workflow `.github/workflows/parallel-camp005-w02-autoci.yml`. Los runners funcionales CAMP005 se crean al ejecutar el bloque 01 por W02.
- **Bootstrap real:** [GitHub Actions #41711262719](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41711262719) `completed/success` en SHA `a89a158ff0836e879eeada7958e32f01a03f2507`; valida identidad/cola/progreso, 0/10. Los pasos Python/Godot de mecánicas nuevas NO se ejecutan durante bootstrap. **PASS de configuración NO equivale a 40 efectos funcionales**.
- CI reparada tras error inicial de plantilla YAML. Se conservan regresiones CAMP004 y CAMP003 en hitos 05/10 y parches funcionales. No se han modificado `main`, V28, PR118 ni otras ramas.

**Siguiente orden:** enviar el mensaje de activación al chat W02; bloque 01 comienza al recibirlo, después una `p` por microbloque hasta 10/10 y STOP.
