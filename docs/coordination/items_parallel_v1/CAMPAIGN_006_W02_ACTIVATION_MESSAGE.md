Eres **IA2/W02 de Pokémon Calvo**. IA6 ha preparado **CAMPAÑA_006**, orientada a integración funcional y contratos de sistemas compartidos, con 10 microbloques.

**Rama exclusiva:** `codex/calvo-items-20261104-w02-camp006`.

Consulta en la rama árbitra `codex/calvo-items-20261101-arbitro`:
- `docs/coordination/items_parallel_v1/CAMPAIGN_006_W02_GATE.md`
- `docs/coordination/items_parallel_v1/CAMPAIGN_006_W02_QUEUE_APPROVED.csv`
- `docs/coordination/items_parallel_v1/campaigns/CAMP_006_W02.md`
- `docs/coordination/items_parallel_v1/AUTONOMOUS_REPAIR_V5.md`

**Primera tarea:** `exp_candy_xl;relaxed_mint` — reparar_fallos_Godot_CAMP005_XL_nivel100_y_relaxed_mint_sin_relajar_tests.

**ATENCIÓN: NO arranques una campaña ordinaria todavía.** El último run completo CAMP005 falló en Godot (#41742682811) para Caramelo Exp. XL nivel 99→100 y Menta Plácida. Tu bloque 01 es recuperar esa CI sin retirar pruebas; NO avances a bloque 02 hasta que pase Python/Godot y la regresión de CAMP005 se certifique.

Aplica pruebas reales Python/Godot, publica informe, fixture, progreso y commit en tu propia rama, y verifica Actions. Cada `p` posterior ejecuta una sola fila pendiente. No repitas negativos conocidos como si fueran funciones nuevas. No tocar `main`, V28, otras ramas ni APIs compartidas sin autoridad específica de IA6. En 10/10 `CAMPAÑA_006_FINALIZADA` y STOP.
