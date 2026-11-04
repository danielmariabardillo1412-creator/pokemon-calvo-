# IA1/W01 — CAMPAÑA_005 — Continuidad y bloqueo CI

**Repositorio:** `danielmariabardillo1412-creator/pokemon-calvo-`
**Rama exclusiva:** `codex/calvo-items-20261104-w01-camp005`
**Coordinación/solo lectura:** `codex/calvo-items-20261101-arbitro`

## Estado real tras primer encargo
- CAMPAÑA_004 previa: 10/10 CI aprobada #41733777992, evidencias heredadas, NO se recontarán como nuevos.
- CAMP005 bloque 01 autorizado `black_glasses;dragon_fang;hard_stone`. Fixture, validador Python y runner Godot funcional diseñados para 9 escenarios, 12 pares semilla, 36 controles de equipamiento con SaveV2; además progreso e informe `CAMP_005_ITER_01.md`.
- **No existe workflow aplicable a `codex/calvo-items-20261104-w01-camp005`**. El heredado `parallel-camp004-w01-autoci.yml` solo escucha la rama antigua y ejecuta contrato CAMP004. CI inicial de CAMP005: ningún run.
- El bloque 01 queda `DEPENDENCIA_DOCUMENTADA`, no `CI_PASS_VERIFICADO`; **no se ha observado ningún resultado funcional nuevo**. Ejecutar/crear CI corresponde a IA6 por V5. Los errores concretos de Godot, si los hubiera, solo podrán diagnosticarse tras el primer run.
- Invariantes: una `p` autoriza solo un bloque; sin CI 01 no avanzar a 02. No tocar `main`, V28, la rama árbitra, otras ramas, políticas comunes, ni producción ajena.
- Próximo paso de IA6: workflow con Godot 4.7, Python 3.11, Node22, recibos `CAMP005_W01_PY/GODOT PASS blocks=1` con checks positivos y **regresión CAMP004 completa en el mismo run** (hito 01), además de 05/10.
- Una vez CI tenga resultado, W01 diagnostica/recupera bloqueo, certifica 01 con SHA/run y queda preparada para bloque 02 `miracle_seed;mystic_water;never_melt_ice`.

Consultar para detalles mecánicos y requisitos de CI `CAMP_005_ITER_01.md`. Sin permiso nuevo de IA6 no modificar workflows.
