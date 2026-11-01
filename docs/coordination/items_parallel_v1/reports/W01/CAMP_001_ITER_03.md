# IA1/W01 — CAMPAÑA_001 · ITER_03 — Consolidación de seis equipables

**Estado:** CAMPAÑA_001_FINALIZADA (entrega de tres microbloques). **Alcance de pruebas:** VERIFICADO_EN_STAGING, no GPU ni campaña completa.
**Autoridad:** `campaigns/CAMP_001_W01.md` blob `4faaae234c3021944d7f4724789c3b2c5d0652fd`, `CAMPAIGN_GATE_001.md` y última `CAMPAIGN_GATE_UPDATE_003.md` (blob `59c553bd7a931ebe4ac10bf4b2b3ce43815220dc`).
**Rama propia:** `codex/calvo-items-20261101-w01`; HEAD árbitra sincronizado `8e170550881861daa3a3aefe8aa91909decf84af` mediante merge no destructivo `1f783cdb0ab5ddcacdd80a9deb81d4ae0e947100`.

## Auditoría de matriz y límites
- IDs exactos: `black_sludge` (3 escenarios/5 pares), `shell_bell` (3/4), `big_root` (2/3), `eviolite` (4/6), `expert_belt` (2/3), `safety_goggles` (3/3).
- **17 casos únicos, 24 pares caso-semilla únicos, 72 variantes nativas** (activo/ninguno/reserva), etapas `01=8` y `02=9`; cada semilla es entera 0–65535, ninguna duplicada por caso.
- **Auditoría estática de este cierre: 15/15 invariantes PASS** por lectura directa de fixture, runner y validador en GitHub: IDs, cobertura, semillas, operaciones, restauración, digest de descriptor y hashes de evidencia. No se modificaron estos tres archivos funcionales.
- Blobs comprobados **idénticos** en staging de CI, árbitra y rama W01: fixture `c8360512855aa2339e8644e0fe4f117542985866`; GDScript `d2a4bae5e99182c55d37c01c1f67f075bc41ea43`; Python `d6f5cd51d8d9141a1f691f613bad47216f586a22`.

## Evidencia funcional delimitada
- [Actions #41350981613](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41350981613), staging SHA `6ea4cb1b9b68e0d1e33ef6a5228dcf57503a3456`: paso **W01 SUCCESS**, `W01_CAMP_001 PASS checks=2428 rows=24 errors=0`; Python `CONTRACT_PASS cases=17 runs=24 variants=72`, `CONTRACT_NEGATIVES_PASS count=6` (seis manipulaciones deliberadas **rechazadas**), `NATIVE_EVIDENCE_PASS runs=24 variants=72` con comprobación SHA-256.
- **Run completo #41350981613 = FAILURE por otra familia W02**; no confundir con el éxito independiente de W01.
- IA6 integró exactamente esos blobs en árbitra `7b360f90b74e18085f5b741722fd67fded88d23b`. [Regresión base #41353674663](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41353674663) SUCCESS en ese SHA; [regresión #41354759130](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41354759130) SUCCESS en `52a5515e7615f988c3da907930979b86664a6430`. Esas dos regresiones ejecutaron el runner anterior de LOTE_002; **no sustituyen el PASS de la campaña en staging**.

## Riesgos y entrega
- **No probado:** GPU/UI, interacción con habilidades y supresión, portador cambiante en combate, todos los movimientos/climas/RNG, asentamiento de victoria, persistencia de campaña hasta mapa. El contrato verifica SaveV2 durante batalla, no el ciclo completo del juego.
- **Sin cambios de producción** ni selección/guardados/workflows. LOTE_001, LOTE_002, ITER_01 e ITER_02 no se reescribieron. No se han creado nuevas reglas ni aplicaciones de objetos.
- **Cierre:** `reports/W01/CAMP_001_FINAL.md`, CSV de progreso y `CONTINUIDAD.md` documentan los 3/3 bloques. No iniciar ITER_04 ni CAMPAÑA_002: detenerse hasta orden explícita de IA6.
