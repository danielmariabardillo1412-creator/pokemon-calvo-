# IA5/W05 — CAMPAÑA_003 · ITER_03/10 — enseñanza MT Scarlet/Violet

**Estado inicial de entrega: EN_CI_AUTOMATICA**, sin afirmar éxito del runner nuevo hasta comprobar la ejecución real sobre SHA `c3c48e92ddf48708d7d941554e58420a994e55ed`.

## Autorización exacta
- Rama exclusiva `codex/calvo-items-20261103-w05-camp003`.
- Cola IA6 `CAMPAIGN_003_QUEUE_APPROVED.csv` filtrada por `W05, bloque 03`.
- Solo seis IDs nuevos: `tm30;tm32;tm33;tm34;tm35;tm37`.
- Mapeo verificado en el perfil `scarlet-violet` de `modules/inventory/item_connections_v1.json`:

| MT | Movimiento canónico |
| --- | --- |
| tm30 | `snarl` |
| tm32 | `swift` |
| tm33 | `magical_leaf` |
| tm34 | `icy_wind` |
| tm35 | `mud_shot` |
| tm37 | `draining_kiss` |

## Trabajo realizado
1. Se amplió **únicamente** `tests/fixtures/parallel_items/w05_campaign_003.json` con el bloque 03, sin cambiar los bloques 01–02. Commit `f4668498b84ca92dc114ed4cac7edff4b001e109`.
2. Se añadió **una sola fila** `03` al progreso `docs/coordination/items_parallel_v1/reports/W05/CAMP_003_PROGRESO.csv` y se disparó la CI automática de rama. Commit `c3c48e92ddf48708d7d941554e58420a994e55ed`.
3. Reutilización legítima: runner acumulativo `tests/gameplay/parallel_items_w05_campaign_003.gd` y validador `tests/tools/test_parallel_items_w05_campaign_003.py`. No se ha reimplementado `FieldItemService.teach` ni alterado contratos de servicio, datos, políticas, GDScript compartido o guardados reales.
4. Se ha contrastado **en el conector de GitHub** que el fixture tiene exactamente tres bloques y 18 IDs distintos, que el progreso y la cola IA6 coinciden exactamente, y que los 18 movimientos corresponden al mapeo SV canónico. Esta es verificación **documental**, no prueba funcional individual.
5. El runner acumulativo exige que Godot 4.7 pruebe 18 pares con especies de learnset SV real, PP correcto, consumo de una MT, rechazos de falta de stock, propietario, especie incompatible y duplicación, además de persistencia SaveV2 aislada. Python valida metadatos y compatibilidad sin inventar especies.

## Evidencia de CI
- **Bloques 01–02 — confirmación real:** [GitHub Actions #41555043090](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555043090), SHA `131b4420e2d4878972199bec9aa6fb4ccf86ae4a`, `completed/success`, `CAMP003_W05_PY PASS blocks=2 checks=116`, `CAMP003_W05_GODOT PASS blocks=2 checks=446`. Las comprobaciones fueron verificadas mediante registros del job, sin inferir el PASS.
- **Bloque 03 — CI propia recién disparada:** [run #41556713903](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556713903), SHA `c3c48e92ddf48708d7d941554e58420a994e55ed`, observada como `pending` en la consulta inicial. La ejecución previa del commit de fixture [#41556696614](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556696614) puede ser cancelada por el sistema `concurrency.cancel-in-progress`; el resultado que cuenta es el del SHA **del progreso**.
- No se atribuye éxito a los 18 casos sin `CAMP003_W05_PY PASS blocks=3` y `CAMP003_W05_GODOT PASS blocks=3` en el mismo SHA de CI.

## Continuación y seguridad
- Siguiente tecla `p`: verificar conclusión y registro más reciente de CI. Con `success`, ejecutar **exclusivamente el bloque 04** (`tm38;tm39;tm40;tm41;tm42;tm43`). Con `queued/in_progress`, solo bloque independiente ya autorizado sin atribuir PASS. Ante `failure`, reparar arnés propio sin reducir aserciones; STOP y aviso IA6 si el fallo es del motor, datos compartidos, guardado o permisos.
- Ningún cambio en `main`, V28, PR #118, rama árbitra, ramas ajenas, `modules/`, `data/`, `config/`, CI global, selección, partida real o 19 legadas. No se certifica pantalla de libros, arte, visual ni GPU.

**Bloque 03/10 publicado.** La campaña continúa solo por la siguiente `p`.
