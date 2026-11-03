# IA5/W05 — CAMPAÑA_003 · ITER_02/10 — seis MT Scarlet/Violet

**Estado de entrega: EN_CI_AUTOMATICA, no PASS funcional comprobado.** Se ejecutó exclusivamente el microbloque 02 de la cola IA6; se conserva bloque 01 sin modificación de sus filas ni de sus seis casos.

## Identidad y fuentes
- Rama exclusiva: `codex/calvo-items-20261103-w05-camp003`.
- Encargo W05 vigente: `campaigns/CAMP_003_W05.md`; cola `CAMPAIGN_003_QUEUE_APPROVED.csv` en `codex/calvo-items-20261101-arbitro`.
- Antes del bloque 02 había exactamente un registro en `CAMP_003_PROGRESO.csv`. No se inventaron IDs ni se avanzó al bloque 03.
- Movimientos `scarlet-violet` comprobados directamente en `modules/inventory/item_connections_v1.json`:
  - `tm24 → fire_spin`
  - `tm25 → facade`
  - `tm26 → poison_tail`
  - `tm27 → aerial_ace`
  - `tm28 → bulldoze`
  - `tm29 → hex`

## Cambios propios publicados
1. **Fixture acumulativo** `tests/fixtures/parallel_items/w05_campaign_003.json`: añadidas seis entradas al bloque 02, preservando literalmente las seis del 01. Commit **`f006f83ab42290609c65ab159652a68dc9017d64`**.
2. **Progreso** `docs/coordination/items_parallel_v1/reports/W05/CAMP_003_PROGRESO.csv`: añadida solo la segunda fila, `EN_CI_AUTOMATICA`. Commit **`131b4420e2d4878972199bec9aa6fb4ccf86ae4a`**. El push de progreso/fixture dispara el workflow sin editar su YAML.
3. Se reutilizan íntegros los tests acumulativos existentes W05, sin duplicar motor o código de campaña anterior:
   - `tests/tools/test_parallel_items_w05_campaign_003.py --ci` exige exactamente **2 bloques** según el progreso y fixture, 12 IDs autorizados, correspondencia con perfil activo, metadatos de movimientos y especies con learnset `machine/scarlet-violet`.
   - `tests/gameplay/parallel_items_w05_campaign_003.gd` exige exactamente **2 bloques** y **12 enseñanzas**, cada una con PP, gasto 2→1, propietario, incompatibilidad, rechazo de duplicación, SaveV2 y limpieza de guardado temporal `user://`.
4. **Comprobación documental de esta entrega:** la lectura de los archivos GitHub verificó que ambos bloques, los 12 IDs, los 12 movimientos, el progreso y las filas de la cola IA6 **coinciden exactamente**. Esta consistencia **no certifica** learnset ni ejecución funcional.

## CI, límites y siguiente bloque
- Último estado comprobable al publicar: el conector disponible no aportó veredicto de workflow/commit del bloque 01; **no inferir success ni failure**. Se avanzó un único bloque independiente de pruebas conforme al gate, sin modificar producción.
- Verificar el último workflow `.github/workflows/parallel-camp003-worker-autoci.yml` en la rama propia, especialmente conclusión y SHA del push del progreso **`131b4420e2d4878972199bec9aa6fb4ccf86ae4a`**. Un run intermedio del fixture podría quedar cancelado al llegar el progreso; **solo cuenta el último SHA de tests/fixture/progreso**.
- **No se ha ejecutado Godot 4.7 en esta conversación** ni se ha verificado manualmente el fichero normalizado completo de especies. Si faltan learnsets, falla la prueba: no fabricar especies compatibles ni declarar las 12 enseñanzas como realizadas.
- Al recibir la próxima `p`, verificar CI; si PASS, ejecutar **bloque 03** `tm30;tm32;tm33;tm34;tm35;tm37`. Si existe FAIL real, reparar únicamente arnés propio sin reducir pruebas o STOP ante dependencia compartida. Si el último estado sigue inaccesible y ya no hay certeza para avanzar, elevar a IA6 antes de nuevas acumulaciones.
- Protección: ninguna escritura en `main`, V28, PR118, otras ramas, `modules/`, `data/`, `config/`, catálogo canónico, `FieldItemService`, CI global, partidas reales, 19 máquinas históricas ni arte/GPU/UI.

**Entrega: bloque 02/10 publicado; CI funcional todavía NO acreditada.**
