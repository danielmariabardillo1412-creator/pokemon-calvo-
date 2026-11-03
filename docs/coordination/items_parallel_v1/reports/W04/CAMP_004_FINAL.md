# IA4/W04 — CAMPAÑA_004_FINALIZADA

**Trabajadora:** IA4/W04 — evoluciones, formas y objetos especiales.  
**Rama exclusiva:** `codex/calvo-items-20261103-w04-camp004`.  
**Encargo:** `CAMPAIGN_004_W04_GATE.md`, `CAMPAIGN_004_W04_QUEUE_APPROVED.csv` y `campaigns/CAMP_004_W04.md`.  
**Alcance cerrado:** **10/10 microbloques, 36/36 IDs únicos**, sin duplicados de campañas anteriores; 36 evidencias individualizadas en el runner.

## Puertas de CI realmente aprobadas

1. Primera CI de código/fixture/CSV completos: [#41610829772](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41610829772), SHA `eb7f9046cb1a0cc04e0ea15764dbf32646925033` — `completed/success`.
2. **CI final sobre el progreso reconciliado:** [#41611102944](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41611102944), SHA `1f4021c4ec00f26a4df3e24428e53b0989caabe8` — **`completed/success`**.

Ambos logs han demostrado los recibos:
- `CAMP004_W04_MANIFEST_PASS reserved=10 completed=10 ids=36`.
- `CAMP004_W04_PY PASS blocks=10 checks=387`.
- `CAMP004_W04_GODOT PASS blocks=10 checks=1090`.
- Regresión de CAMPAÑA_003: `CAMP003_W04_PY PASS blocks=10 checks=120` y `CAMP003_W04_GODOT PASS blocks=10 checks=270`.
- Regresión histórica de CAMPAÑA_001: `PARALLEL_ITEMS_W04_CAMP_001_GODOT PASS iteration=3 checks=559 cases=12`.

**Son pruebas ejecutadas en Godot 4.7 headless y Python**, no inferencias desde el código. No equivalen a comprobación visual/GPU ni al efecto funcional de cada objeto seleccionado.

## Clasificación REAL de los 36 IDs según los logs

| Estado observado | IDs | Qué está certificado |
| --- | ---: | --- |
| `RECUPERACION_VERIFICADA` | **1** | `rage_candy_bar`: cura realmente una quemadura, consume una unidad, rechaza segundo uso ineficaz, conserva criatura/inventario/SaveV2 |
| `DEPENDENCIA` | **31** | Rechazos sin consumo o transferencias/guardados según perfil; **no** mecanismo principal de forma/fusión/evolución, venta, entrenamiento o contexto especial |
| `AUDITORIA_DE_DATOS` | **1** | `catching_charm`, sin certificar efecto de captura (dominio W03) |
| `AUDITORIA_LEGACY` | **3** | `roto_catch`, `roto_exp_points`, `roto_friendship`: auditoría de campo, sin certificar captura/EXP/amistad |

**Suma:** 1 + 31 + 1 + 3 = **36**. No afirmar 36 objetos jugables por un CI PASS. Los efectos de `rage_candy_bar` **ya existían** en el sistema de recuperación; esta campaña los ha probado, no implementado de nuevo.

### Dependencias agrupadas para IA6
- **Milcery/Alcremie y dulces:** siete `*_sweet`; requieren `spin`, objeto equipado y forma, no `use_item` inventado.
- **Evoluciones con modalidad especial:** `whipped_dream` (intercambio con equipo) y `leaders_crest` (Bisharp y derrotas).
- **Formas y fusiones:** `adamant_crystal`, `blue_orb`, `dna_splicers`, `gracidea`, `griseous_core`, `lustrous_globe`, `meteorite`, `red_orb`, `reins_of_unity`, `reveal_glass`, `rotom_catalog`, `zygarde_cube`, `n_lunarizer_merge`, `n_solarizer_merge`. Cuatro orbes/cristales tienen transferencia equipable real; esto no valida formas en combate. Fusiones requieren dos criaturas y un contrato específico.
- **Servicios de terceros:** `catching_charm`, `exp_charm`, y tres cupones `roto_*`: captura W03; experiencia y amistad W02. No modificar sus subsistemas desde W04.
- **Tesoros/coleccionables bloque 10:** `big_nugget`, `bottle_cap`, `gold_bottle_cap`, `heart_scale`, `nugget`, `pretty_wing`, `rare_bone`. Cuatro figuran como equipables y con entrada nativa; tres como `DATA_ONLY`. Ninguna venta, economía, Hyper Training, IV o reaprendizaje está certificada por esta campaña; entrenamiento corresponde a W02 y economía necesita contrato propio.
- **Metadatos pendientes:** `rotom_catalog` tiene `missing_description`; los cinco legacy de bloque 09 tienen `placeholder_description` y `source_category=unused`. **No borrarlos por ese solo motivo**, porque están seleccionados en la cola autorizada.

**CAMPAÑA_003 anterior, independiente:** conserva sus 30 IDs auditados (14 rutas evolutivas positivas y **16 dependencias funcionales**: 10 sin regla normalizada, 6 `DATA_ONLY`), con advertencia adicional sobre restricciones de formas de ciertas rutas positivas. Esta campaña NO ha resuelto ni reabierto esos 16 casos; IA6 debe conservar el backlog.

## Evidencia publicada y aislamiento

Archivos propios:
- `tests/gameplay/parallel_items_w04_campaign_004.gd`
- `tests/tools/test_parallel_items_w04_campaign_004.py`
- `tests/fixtures/parallel_items/w04_campaign_004.json`
- `docs/coordination/items_parallel_v1/reports/W04/CAMP_004_PROGRESO.csv`
- `docs/coordination/items_parallel_v1/reports/W04/CAMP_004_ITER_01.md` a `CAMP_004_ITER_10.md`
- `docs/coordination/items_parallel_v1/reports/W04/CONTINUIDAD.md` y este `CAMP_004_FINAL.md`.

No se modificaron producción, datos canónicos, workflows, `main`, etiqueta V28, PR #118, rama árbitra ni ramas de W01/W02/W03/W05. No se ha integrado nada; corresponde a IA6 auditar y coordinar dependencias de APIs compartidas.

**Cierre oficial: `CAMPAÑA_004_FINALIZADA` — 10/10, CI doble verificada, 36/36 auditados, STOP W04.** No ejecutar bloque 11 ni crear CAMPAÑA_005 sin encargo explícito de IA6.
