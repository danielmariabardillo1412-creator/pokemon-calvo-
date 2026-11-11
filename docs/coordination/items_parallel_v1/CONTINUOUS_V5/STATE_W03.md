# IA3/W03 — CONTINUOUS_V5 · VERIFICACIÓN FIXTURE EN COLA; INTEGRACIÓN IA6 YA CERTIFICADA
date: 2026-11-11
branch: codex/calvo-items-20261111-w03-repel-staging-v5
phase: A/B/C 3/3 implemented; L3 functional in W03 prior green; strict historical one-line-fix QA pending
next_id: no new task outside current two queued CI
last_functional_W03_sha: e7b4235788b200a946030a248b33cc4a20535359
current_W03_documentation_sha_before_this_update: 32364daf97facc7f3b8b6fb2da771ea48863d99a
arbiter_authorization: CONTINUOUS_V5/IA6_W03_REPEL_FIXTURE_ONE_LINE_AUTH_20261111.md
fixture_repair: ONLY registered_zone_ids()[0] -> scene.TECHNICAL_ZONE_ID (one line)
original_fixture_blob: 318ee45f60d9ee046bcb048019337524acfb4844
new_fixture_blob: 91ec4cca45b0a398597dd352f10d4bcfec4b3353
guard: reconstruct original SHA from new file by reversing only approved line; preserve 7 protected module hashes and Dynamax Candy veto
specific_W03_strict_run: 43095883086
specific_W03_strict_status: QUEUED with no jobs at last check; NOT CERTIFIED
specific_W03_scoped_run: 43095882953
specific_W03_scoped_status: QUEUED with no jobs at last check; NOT CERTIFIED
last_W03_scoped_green_before_repair: 43084807955 SUCCESS at 1fc5d7fdba3a9b84a4c04fc88a24ea3c8d1bb579
W03_repel_existing_items: repel 100; super_repel 200; max_repel 250
new_item_ids: 0
official_IA6_integration_branch: codex/calvo-ia6-integration-20261109
official_IA6_integration_sha: ddc8a1af56c5fe7e950bee5bf3986d8e62261f8f
official_IA6_repel_books_rope_ci: 43106031150 SUCCESS; CAMP006_W03_REPEL_L3 PASS checks=66; IA6_BOOK_BAG PASS checks=20; IA6_INTEGRATION PASS checks=65; Dynamax Candy exclusion
official_IA6_capture_ci: 43106031155 SUCCESS; Repeat legacy=37; Repeat native=26+18; Net native=79+19; Moon=41; SaveV2 40+8; Mint=18; Books=20; Repel=66
official_IA6_status: functionality integrated and independently CI-certified on official tree; NOT a substitute for the two pending W03 V5 SHA-specific runs
official_IA6_test_difference: official historical-repel test blob f542f6aef303caa12812714415846bcf16bb2bcf (chooses zone from real grass position); W03 corrected fixture blob 91ec4cca45b0a398597dd352f10d4bcfec4b3353 (IA6 authorized one-line scene.TECHNICAL_ZONE_ID)
unverified: W03 pending two runs, W04 7 routes and CAMP003-006 full on latest official tree
protected: main, V28, PR118, independent workers' branches, native engine untouched
next_safe_action: inspect W03 queue; if completed, inspect full logs for exact commit and certify/fix as appropriate; otherwise no speculative repair or new commits
STOP_V6: yes

## Interpretación
- El árbol oficial IA6 tiene funcionalidad de Repel, W05 libros y Rope con pruebas reales SUCCESS. Esto actualiza el estado anterior 'integración oficial pendiente'.
- La modificación de una sola línea del test histórico en W03 no está aún individualmente certificada: GitHub mantiene sus dos jobs en 'queued'. No atribuir la CI IA6 a ese SHA W03.
- Si se reciben nuevas órdenes IA6, priorizar la más reciente y verificar ramas/SHAs antes de actuar.
