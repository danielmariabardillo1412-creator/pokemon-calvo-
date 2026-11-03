# IA5/W05 — CAMPAÑA_003 · ITER_05/10 — seis MT Scarlet/Violet

**Entrega: EN_CI_AUTOMATICA.** La CI de este bloque no se declara PASS hasta obtener conclusión y logs sobre el SHA exacto de pruebas/progreso.

## Autorización
- Rama exclusiva: `codex/calvo-items-20261103-w05-camp003`.
- Autoridad: `CAMPAIGN_GATE_003.md`, `campaigns/CAMP_003_W05.md`, `CAMPAIGN_003_QUEUE_APPROVED.csv` de IA6. Únicamente fila `05,W05,MACHINE`.
- Seis IDs nuevos con movimientos de versión `scarlet-violet` comprobados contra `modules/inventory/item_connections_v1.json`:

| MT | Movimiento |
| --- | --- |
| `tm45` | `venoshock` |
| `tm46` | `avalanche` |
| `tm47` | `endure` |
| `tm48` | `volt_switch` |
| `tm49` | `sunny_day` |
| `tm50` | `rain_dance` |

## Entregables
1. Fixture `tests/fixtures/parallel_items/w05_campaign_003.json`, bloque 05 añadido, sin alterar los bloques 01–04: commit `4c305e29a1b418ccd531593071355220692c8f4b`.
2. Progreso `docs/coordination/items_parallel_v1/reports/W05/CAMP_003_PROGRESO.csv` con **una sola fila nueva** `05`, estado `EN_CI_AUTOMATICA`: commit `7692702bb5969de282a28604a93c44d01a8b092a`.
3. Se conservan los tests acumulativos ya verificados `tests/tools/test_parallel_items_w05_campaign_003.py --ci` y `tests/gameplay/parallel_items_w05_campaign_003.gd`. En CI deben comprobar **5 bloques, 30 MT**, learnsets reales, PP, compatibilidad, propiedad, consumo, rechazo y persistencia SaveV2; si faltan datos, deben fallar, no inventar especies.
4. **Control estático realizado:** los cinco bloques contienen 30 IDs únicos, con asignación, orden y movimientos coincidentes exactamente con la cola aprobada, el CSV de progreso y el perfil SV. Este control **no acredita** el funcionamiento de las seis MT nuevas.

## Evidencia CI
- Los bloques 01–04 fueron verificados realmente en [GitHub Actions #41558194753](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41558194753), SHA `d9c38c6cb606bbe3081eebc16d4560944370a48a`, `completed/success`, con recibos de logs `CAMP003_W05_PY PASS blocks=4 checks=232` y `CAMP003_W05_GODOT PASS blocks=4 checks=876`.
- **La prueba acumulativa del bloque 05 se activa por el push de progreso `7692702bb5969de282a28604a93c44d01a8b092a`.** El workflow `.github/workflows/parallel-camp003-worker-autoci.yml` exige recibos `CAMP003_W05_PY PASS blocks=5 checks=M` y `CAMP003_W05_GODOT PASS blocks=5 checks=M`.
- Un run del commit previo de fixture puede quedar cancelado por `concurrency.cancel-in-progress`. Comprobar el run del **último SHA de progreso**, no interpretar una cancelación intermedia como un error de Godot.

## Siguiente p, límites y STOP
- Próximo microbloque aprobado: **06**, `tm51;tm52;tm53;tm54;tm55;tm56`, solo tras revisar resultado de CI de bloque 05; no adelantar bloques adicionales en esta orden.
- Si el run está `queued/in_progress`, se permite únicamente otro bloque de tests independiente, sin atribuir PASS. Si FAIL, reparar exclusivamente arnés propio sin reducir aserciones, o STOP y escalar IA6 si falla lógica compartida/datos/SaveV2.
- Intocables: `main`, V28, PR #118, ramas ajenas, árbitra, `modules/`, `data/`, `config/`, catálogo canónico, flujo de CI, guardados reales y las 19 máquinas históricas. No se certifican gráficos, libros visibles ni GPU.

**Entrega documental y de pruebas: 05/10 publicada; certificación del bloque nuevo pendiente de CI.**
