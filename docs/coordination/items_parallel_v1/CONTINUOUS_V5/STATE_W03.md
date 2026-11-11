# IA3/W03 — ACTUALIZACIÓN IA6 (2026-11-11) · V5 NO CERTIFICADA, FIJACIÓN DE ZONA AUTORIZADA

- Estado comprobado en GitHub: código V5 para FieldItemBag / FieldDemo / FieldNativeBridge presente; pruebas y workflows V5 publicados. **Todavía NO se ha certificado cierre V5.**
- CI histórica W03 Repel V5: #43073388744 `completed/failure` (step `Repel original W03 native + bag + world + SaveV2`). CI anterior #43072852369 `completed/cancelled`; ninguna equivale a PASS.
- Causa contrastada: fixture original `parallel_items_w03_repel_l3.gd` usa `registered_zone_ids()[0]` (cueva ordenada) pero prueba posición `EncounterZone` (hierba); ticket `CONTINUOUS_V5/W03_REPEL_HISTORICAL_TEST_ZONE_TICKET.md`. El test independiente `parallel_items_w03_v5_repel_grass.gd` usa zona real, pero su CI no está acreditada por este checkpoint.
- IA6 AUTORIZÓ la reparación **de una línea y una sola** en el fixture histórico y adaptación de la guarda de fuente, con registro `CONTINUOUS_V5/IA6_W03_REPEL_FIXTURE_ONE_LINE_AUTH_20261111.md` en rama árbitra.
- **Siguiente p:** aplicar esa corrección exacta, mostrar diff una línea vs blob histórico, ejecutar CI histórica ESTRICTA y CI grass con regresiones y verificar `completed/success` en SHA funcional; si verde, publicar `reports/W03/CONTINUOUS_V5_FINAL.md` con alcances/limitaciones, 3/3 repelentes L3 y READY_FOR_IA6_MERGE_REPEL_CANDIDATE; si rojo, no falsear cierre.
- Integración IA6 oficial: **NO**. Libros staging W05 más recientes no están mezclados; requieren CI conjunta IA6. `main`, V28, PR118, W01/W02/W04/W05 protegidos.

---

# IA3/W03 — CONTINUOUS_V5 · CHECKPOINT INICIAL (11-11-2026)
- worker: W03
- branch: codex/calvo-items-20261111-w03-repel-staging-v5
- phase: A / prueba roja real + diff por función, PENDIENTE
- mission: CONTINUOUS_V5/PLAN_W03.md (árbitra IA6)
- preceding_stage: codex/calvo-ia6-staging-20261111-w03-capture
- v4_capture_code_sha: 5a82da2a9dd1a868c3f8af9d73551fe16571adea
- v4_capture_ci: #43068968046 completed/success (no equivale a CI V5)
- v4_state: READY_FOR_IA6_MERGE_CAPTURE / REPEL_SHARED_SEAM_PENDING
- source_repel: codex/calvo-items-20261104-w03-camp006 (CAMP006)
- gap: CONTINUOUS_V4/W03_REPEL_BAG_GAP.md
- planned: repel(100), super_repel(200), max_repel(250) — existentes; 0 nuevos IDs
- L3_repel_on_V5: 0/3 hasta CI real
- V5_green_code_sha: ninguno
- V5_ci: ninguna
- shared_W05: libro y Cuerda Huida presentes en base V4 W03; **staging W05 más reciente NO integrada**
- integration_official_IA6: NO
- next_safe_action: recuperar test inalterado parallel_items_w03_repel_l3.gd de origen y mostrar RED contra baseline de esta rama; después diff y trasplante de mínimos
- protection: main, V28, PR118, W05, IA6, policy, save core, battle JS, captura previamente certificada intactos
- STOP: al acabar fases A/B/C con CI o dependencia genuina y ticket; nunca por 10/10 artificial.
