# IA5/W05 — CAMPAÑA_003 · ITER_01/10 — MT Scarlet/Violet

**Estado: EN_CI_AUTOMATICA.** Publicación de tests y progreso; NO se ha confirmado ejecución funcional ni PASS de este bloque.

## Autoridad y propiedad
- Rama exclusiva: `codex/calvo-items-20261103-w05-camp003`.
- Base de campaña: `41c1efeba0346349490f863131179ed7a8fc274c`; bootstrap IA6 de esta rama pasó solo el gate documental: [#41551975872](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41551975872).
- Contrato: `CAMPAIGN_GATE_003.md`, manifiesto `CAMPAIGN_003_BRANCH_MANIFEST.md`, cola `CAMPAIGN_003_QUEUE_APPROVED.csv`, `campaigns/CAMP_003_W05.md` (rama árbitra).
- IDs bloque 01 exactos: **tm07;tm16;tm18;tm21;tm22;tm23**. No se han reutilizado tests ni IDs de enseñanza individual de CAMP002 ni `tm01/tm02/tm77`.

## Evidencia de fuente ya consultada (sin suponer éxito funcional)
`modules/inventory/item_connections_v1.json` contiene mapeo activo `scarlet-violet`:
- `tm07 → protect`
- `tm16 → psybeam`
- `tm18 → thief`
- `tm21 → pounce`
- `tm22 → chilling_water`
- `tm23 → charge_beam`

El catálogo normalizado `data/normalized/pokemon_api.json` es demasiado grande para lectura textual completa mediante este conector en esta sesión. **No se han inventado especies ni PP**. El validador Python de CI inspeccionará el JSON original completo, su política y learnsets `machine/scarlet-violet`; el runner Godot selecciona especie compatible real del catálogo. Si falta learnset, prohíbe PASS y registra fallo `SIN_LEARNSET`.

## Entregables propios nuevos
- `tests/fixtures/parallel_items/w05_campaign_003.json`: seis IDs + movimientos originales, sólo bloque 01.
- `tests/tools/test_parallel_items_w05_campaign_003.py`: contrato acumulativo de la cola exacta, IDs, versión activa, movimiento permitido, metadatos `type_id/damage_class/pp` y especie con learnset real; modo `--ci` da recibo `CAMP003_W05_PY PASS blocks=N checks=M` sólo al verificar.
- `tests/gameplay/parallel_items_w05_campaign_003.gd`: arnés acumulativo, invoca exclusivamente `FieldItemService.teach`, rechaza sin stock/propietario/incompatibilidad, verifica PP inicial/max, gasto 2→1, identidad y propiedad, rechazo por repetición, SaveV2 aislado mediante `SaveGameRepository.save_collection/load`; limpia temporal de `user://`. Recibo `CAMP003_W05_GODOT PASS blocks=N checks=M` sólo si todas las aserciones pasan.
- `CAMP_003_PROGRESO.csv`: 1 fila publicada, `EN_CI_AUTOMATICA`.

### Commits de pruebas y activación
- Fixture `2623f184e5bdc45d5f89e514f7745bfb09a9575d`.
- Python creación `56992fffd00a52da95c8e12512d9c75ea8bc2308` y ajuste de control acumulativo `c622e29bd06c5a40c189ff780a4effc8755d0275`.
- Godot creación `0cf477b18e77587d6c8b170c40189475a1060b7c`; ajuste lectura CSV `a43b182e532d9bc123d64acc9a89bdc602bad08d`.
- CSV progreso que habilita CI real `a2047a58a02760380b3a55f4620417051984dea7`.

## Reproducción
```bash
python -B tests/tools/test_parallel_items_w05_campaign_003.py --ci
python -B tests/tools/test_parallel_items_w05_campaign_003.py --report
godot --headless --path . --script res://tests/gameplay/parallel_items_w05_campaign_003.gd
```

Workflow inmutable de IA6: `.github/workflows/parallel-camp003-worker-autoci.yml`. El gate externo exige `blocks=1` concordante con progreso y comprobaciones positivas. **No equivale a CI PASS** hasta verificar ejecución y SHA. La próxima `p` deberá consultar último resultado; si es success, avanzar al bloque 02 `tm24;tm25;tm26;tm27;tm28;tm29`. Si está en curso, solo una iteración independiente; si fallo de motor/datos compartidos, STOP y elevar a IA6.

**Prohibiciones cumplidas:** sin cambios en `main`, V28, PR118, producción, selección, `modules/`, `data/`, `config/`, ramas ajenas ni partidas reales. Las 19 máquinas legadas continúan inactivas. No se ha ensayado GPU/arte/UI.
