# IA3/W03 — CAMPAÑA_005 / continuidad bloque 01

**Rama exclusiva:** `codex/calvo-items-20261103-w03-camp005`. **Identidad:** IA3/W03. **Último microbloque entregado:** 01 `dive_ball;dusk_ball;repeat_ball` — remedición de dependencias, NO tres objetos nuevos.

Verificar en este orden: `CAMP_005_PROGRESO.csv`, `tests/fixtures/parallel_items/w03_campaign_005.json`, tests propios Python/Godot y `CAMP_005_ITER_01.md`. Los tres siguen en `DEPENDENCIA_CONCRETA`. Se identificaron exactamente los productores que faltan: origen fiable del encuentro en agua, reloj y oscuridad/cueva del mundo, y Pokédex con historial de especies capturadas y SaveV2. La ruta existente de `ShowdownAdventureSession.capture` solo produce turno/nivel y datos básicos; no admite inferencias ficticias. Ningún módulo de producción ha cambiado.

**CI:** ejecutar/verificar `CAMP005_W03_PY PASS blocks=1` y `CAMP005_W03_GODOT PASS blocks=1`, más gate oficial en último SHA del CSV. Si falla, diagnosticar la prueba exacta y corregir en W03 antes de afirmar éxito. Un PASS valida el contrato pendiente, **no** efecto funcional de Dive/Dusk/Repeat.

**Siguiente `p` si procede:** bloque 02 `luxury_ball;lure_ball`. Un único bloque por `p`; no tocar `main`, V28, PR #118 ni otras ramas. Al llegar a 10/10, STOP y `CAMPAÑA_005_FINALIZADA`.
