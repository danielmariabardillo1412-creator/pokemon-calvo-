# IA2/W02 — CAMPAÑA_002_FINALIZADA

**Estado de entrega:** ITER_01, ITER_02 e ITER_03 completadas en `codex/calvo-items-20261102-w02-camp002`. **STOP**; no ITER_04 ni CAMP_003.

**Alcance:** Sitrus/Zidra, Lum/Ziuela, Leppa/Zanama y Figy/Higog. Nueve escenarios específicos, 27 variantes de combate en modos activo, ausente y reserva. Contratos individuales de curación, estado, PP, naturaleza, consumo y persistencia SaveV2.

**CI histórica vigente:** [run #41539808520](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41539808520) `completed/success`, SHA `6373ea47cac3069b120e9e2102f49d100ea14698`. No certifica automáticamente el código añadido en ITER_03.

**ITER_03:** se añadieron contrato global de 4 IDs, trazabilidad de fixture por SHA-256, 27 recibos obligatorios SaveV2 y 5 pruebas negativas adicionales. Inspección estática 24/24 PASS; Python 22 tests definidos, CI del nuevo SHA por verificar.

**Archivos:** fixture blob `767b5998483e9710c1e9c6d1aacb0b2375f35e6c`; Godot blob `67d2d0b79568e31eca24fb2d70aab3de5f156106`; Python blob `a3fe65ae70eeeb201a58c7918de30e4db8414346`.

**Limitaciones:** no se han probado efectos de mochila/campo, UI, GPU ni todos los formatos. Figy carece de perfil de recuperación de campo registrado; Persim de CAMPAÑA_001 sigue intacta. Sin escrituras en producción, `main`, V28, PR #118 ni otras ramas.

**Pendiente de CI:** confirmar que el último run automático de esta rama usa el SHA nuevo y supera import Godot 4.7, Python unit tests, 9 escenarios y verificador SHA256 de las 27 variantes. Ante FAIL funcional, no certificar ni promover; comunicar a IA6.

**Documentación:** `CAMP_002_ITER_01.md`, `CAMP_002_ITER_02.md`, `CAMP_002_ITER_03.md`, `CAMP_002_PROGRESO.csv` y `CONTINUIDAD.md`.

**CAMPAÑA_002_FINALIZADA — STOP de W02.**
