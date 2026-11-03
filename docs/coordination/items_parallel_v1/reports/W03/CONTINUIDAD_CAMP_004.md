# IA3/W03 — CAMPAÑA_004: CONTINUIDAD 01/10

**Rama:** `codex/calvo-items-20261103-w03-camp004`. **Bloque 01:** `dive_ball;dusk_ball;repeat_ball`. **Siguiente `p`**: bloque 02 `black_flute;blue_flute;escape_rope`, tras revisar CI 01. No saltar fila ni recuperar CAMP003.

- Gate/cola: 10 bloques y 36 IDs; autorrreparación V5 aplicada solo en ámbito de captura. El bloque 01 no modificó producción.
- Diagnóstico: tres bolas sin entrada operativa en `CaptureRuleset`; faltan señales autoritativas de medio acuático, noche/cueva y especies capturadas antes. No hay permiso para inventarlas ni modificar productores de sesión.
- Pruebas nuevas: runner Godot real y auditor Python + fixture bloque01; contratos de `INVALID/unknown_ball` sin gasto/uso de RNG ni mutación, dos especies, dos modos PS y negativos prioritarios.
- Informe: `CAMP_004_ITER_01.md`. El CSV debe contener exactamente una fila tras publicar este lote. Verificar workflow sobre SHA final y salidas `CAMP004_W03_PY PASS blocks=1 checks=M`, `CAMP004_W03_GODOT PASS blocks=1 checks=M`, además de regresiones CAMP002/CAMP003.
- Estado: **CI pendiente** hasta validación de ejecución de HEAD. No dar PASS funcional a las tres bolas.
- Protección: `main`, V28, ramas ajenas, catálogo y workflows intactos. Si CI falla por test propio, reparar en esta rama; si se requiere política o productor compartido, documentar para IA6.
