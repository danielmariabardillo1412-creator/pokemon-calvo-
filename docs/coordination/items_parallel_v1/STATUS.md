# ESTADO CENTRAL — CAMPAÑA_001 ACTIVADA (1-XI-2026)

**Resultado de puerta:** PASS GitHub Actions [#41341842320](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41341842320), código `ac34fabbe1a27e69614f0239abee21c29d6fe65e`. Import Godot 4.7 y Node/Python verificados. W01 1332 checks PASS; W02 503 PASS; W03 caracterización de captura PASS **sin implementación de net_ball**; W04 100 PASS; W05 Python 248 MACHINE PASS estático. No se ha hecho GPU/visual.
**Integración de LOTE_002:** commit `30efddb618f0b3f397a3090568a070818c5cc36a` con 29 rutas de las cinco W; cuadernos `reports/W0X/CONTINUIDAD.md` presentes. Se corrigieron exclusivamente errores de test W02 (LoadResult) y W03 (orden constructor WildEncounterSlot) antes de PASS.
**Rama oficial:** `codex/calvo-items-20261101-arbitro`; `main` y V28 original intactas.

## Instrucciones vigentes

- **Puerta actual:** [CAMPAIGN_GATE_001.md](./CAMPAIGN_GATE_001.md) — `ACTIVADA`.
- **Campañas con tres microbloques por IA:** [W01](./campaigns/CAMP_001_W01.md) · [W02](./campaigns/CAMP_001_W02.md) · [W03](./campaigns/CAMP_001_W03.md) · [W04](./campaigns/CAMP_001_W04.md) · [W05](./campaigns/CAMP_001_W05.md).
- **Una sola activación de instrucciones:** [PROMPT_ACTIVACION_CAMP_001.md](./PROMPT_ACTIVACION_CAMP_001.md). Después, cada `p` = exactamente un microbloque de la campaña propia. No anticipar 002, no saltar bloqueo y parar tras 3.
- Las W trabajan **en sus propias ramas**, no en árbitra. Cada iteración publica `reports/W0X/CAMP_001_ITER_0N.md`, `reports/W0X/CAMP_001_PROGRESO.csv`, `CONTINUIDAD.md` y commit. IA6 revisará manifiestos compactos/diffs al cerrar un paquete o por fallo, no cada mensaje.
- **Permisos:** W01/W02/W04 tests propios; W03 captura Net Ball de alcance exacto; W05 perfil de lectura de libros. Modificar módulo compartido, política o guardado requiere nueva orden central.
- Un PASS de preparación sin ejecución real no certifica nuevas mecánicas. Toda nueva función se prueba tras integración en gate con SHA y evidencias.

## Estado inicial
W01, W02, W03, W04, W05: **CAMPAÑA_001_ASIGNADA, microbloque 01 pendiente**. Ninguna trabajadora ha ejecutado sus microbloques por crear estos documentos. Máximo 3 por W (15 totales), sin obligación de gastar toda la cuota de CI por cada documento.
**Conflictos cerrados temporalmente a producción:** `beast_ball` contradictoria, 19 máquinas legacy, Mega universal aplazada, Lujo/Ocaso con dependencias de contexto y guardado.
