# IA5/W05 — CAMPAÑA_002 · continuidad vigente a 2026-11-02

**Estado actual: 02/03 publicados; ITER02 `PREPARADO_PENDIENTE_CI`; STOP hasta gate expreso de IA6.** Esta sección reemplaza el estado anterior de 01/03.

- Rama exclusiva: `codex/calvo-items-20261102-w05-camp002`; antes de esta entrega HEAD `16b4b6ec4f595cbb0306cec68dba7b0b6f18365a`. No utilizar rama CAMP001 anterior.
- IA6 confirmó ITER01: [CI #41484879741](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41484879741), 11 unittest Python y selección de 12 MT con learnsets reales. **No probó todavía enseñanza Godot de esos pares**.
- ITER02: runner `tests/gameplay/parallel_items_w05_campaign_002.gd`, commit de creación `61caf12770e0d70c6d0d41dc0e6d5402596429cd`. Al ejecutar selecciona seis parejas compatibles nuevas desde los candidatos del fixture validado y llama a `FieldItemService.teach`.
- Cobertura prevista: stock 0/2/1, falta de propiedad, incompatibilidad SV, PP, aprendizaje, no duplicación, identidad en equipo, SaveV2 lectura/escritura aislada en `user://` y limpieza del temporal. Ningún resultado funcional de ITER02 está acreditado todavía.
- Comando IA6: `godot --headless --path . --script res://tests/gameplay/parallel_items_w05_campaign_002.gd`. Revisar `user://w05_camp002_iter02_reporte.json` (ruta del ejecutor), stdout, código de salida y comparar parejas con `python tests/tools/test_parallel_items_w05_campaign_002.py --report`.
- Si falla Godot, drift de datos o divergencia de selección: **STOP y diagnóstico IA6**, sin asumir éxito. Solo después de gate positivo y nueva orden específica, realizar ITER03 de ampliación hasta 12 y regresión SaveV2/19 legacy.
- Archivos tocados exclusivamente W05 CAMP002: runner GDScript; informes `CAMP_002_ITER_02.md`, `CAMP_002_PROGRESO.csv` y este cuaderno. Fixture y generador Python de ITER01 permanecen intactos.
- Intocables: `main`, V28, árbitra, rama antigua, otras W, PR118, producción, `FieldItemService`, catálogo normalizado, partida real, 19 legacy y reglas Mega.
