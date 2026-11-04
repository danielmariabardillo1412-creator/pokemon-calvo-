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

## Recuperación CI y bloque 02 — trabajo autorizado

- IA6 instaló workflow propio `.github/workflows/parallel-camp005-w01-autoci.yml` en W01; la antigua dependencia de CI **queda resuelta**. Run [#41767517526](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41767517526), SHA `bd33aeb3f993804c3c85217b81892356af39aac5`, **SUCCESS**: bloque 01 Python 88 PASS / Godot 1109 PASS, regresión CAMP004 íntegra Python 1028 PASS / Godot 16816 PASS. Registrar fila 01 `CI_PASS_VERIFICADO`.
- Con esta `p` se autoriza exactamente el bloque 02 `miracle_seed;mystic_water;never_melt_ice`. Positivos: `energy_ball`, `surf` e `ice_beam`; negativos `tackle` y `reflect` por objeto. Cada caso en modos activo/ausente/reserva con misma semilla; SaveV2, identidad y consumo. Nueve escenarios, doce pares, 36 variantes. Acumulado: seis objetos, 18 casos, 24 pares, 72 variantes. Código de producción inalterado.
- Esperar recibos `CAMP005_W01_PY PASS blocks=2 checks=N` y `CAMP005_W01_GODOT PASS blocks=2 checks=N` con N positivo y run `completed/success` sobre SHA del bloque 02. Si falla, diagnosticar y reparar rama propia según V5, no reducir aserciones.
- Regresión completa CAMP004 aprobada hito 01; nueva ejecución obligatoria en hitos 05 y 10 o tras cambios de producción. No inventar integración global, UI o GPU. Incidencia anterior SaveV2 en carga intermedia de Rayo Solar continúa pendiente para IA6.
- **Próxima `p` solo después de CI positiva:** bloquear cierre documental de 02 con SHA/run y ejecutar bloque 03 `poison_barb;sharp_beak;silk_scarf`. Nunca tocar `main`, V28, árbitra ni ramas ajenas.
