# CAMPAÑA_001 — Gate 005, verificación final de IA5 (2026-11-02)

**Fuente de verdad actual.** Esta puerta sustituye los estados transitorios de `CAMPAIGN_GATE_UPDATE_004.md` para IA5. No crea nuevos lotes ni autoriza ampliar funciones.

## Estado de los cinco trabajadores

| Trabajador | Entrega CAMP_001 | Decisión IA6 |
|---|---:|---|
| W01 / IA1 | 03/03 | `CAMPAÑA_001_FINALIZADA`, STOP |
| W02 / IA2 | 03/03 | `CAMPAÑA_001_FINALIZADA`, STOP |
| W03 / IA3 | 03/03 | `CAMPAÑA_001_FINALIZADA`, STOP |
| W04 / IA4 | 02/03 | `CONGELADA_A_PETICION_USUARIO`, STOP; **no reemplazar ni tocar su rama** |
| W05 / IA5 | 03/03 | `CAMPAÑA_001_FINALIZADA`, STOP |

**Total: 14/15 microbloques publicados.** CAMPAÑA_001 no puede cerrarse globalmente como 15/15 mientras W04 siga congelada; no reanudarla sin decisión explícita de la persona usuaria. Cuatro campañas de trabajadoras terminadas, quinta suspendida de forma consciente.

## W05 — evidencia de Godot real, tercera iteración
- Fuente: rama propia W05 `codex/calvo-items-20261101-w05`, HEAD `2f7e2d32368916d7df01c13f8234ee24981d1bc4`, microbloque 03 con exclusivamente un archivo de pruebas nuevo, blob `10c1d7a7eeac79a83a2e9a1183f1c663aaf1955e`.
- Staging [Actions #41364434498](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41364434498): `completed/success`, SHA `83cb84fa25fbe3bd47bdfc0c35de298f953c0a7d`, Godot 4.7 **1083 comprobaciones / 0 errores**, Python **14 tests OK**, máquina 248=229 activas SV+19 heredadas rechazadas.
- Producción `FieldItemService.teach()` **NO se cambió**. Cobertura real de tm01/tm02/tm77, PP y movimiento, propiedad, consumo 2→1, rechazo atómico, guardado/carga de prueba, y 19 IDs históricos sin activar. No asegura 229 rutas de enseñanza con todas las especies.
- Integra ese mismo blob de la suite W05 en la rama árbitra commit `a8e09dbf8b15c61f1b18207d34548ff8a7ca46e4`, con actualización de la CI permanente para exigir `CAMP_001/03` en lugar de `CAMP_001/01`. Acta [integration/CAMP_001_W05_ITER03.md](integration/CAMP_001_W05_ITER03.md).
- La nueva CI sobre **ese mismo commit integrado** [#41364601482](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41364601482) concluyó `completed/success` (suites W03/W05 independientes).
- La regresión histórica simultánea [#41364601486](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41364601486) sigue **pendiente** de veredicto cuando se escribe esta puerta; verificar al reabrir auditoría y no inventar PASS.

## Política de cierre
- **Nadie** debe recibir una `p` para CAMPAÑA_001: W01/02/03/05 por agotamiento 03/03, W04 por congelación de la persona usuaria.
- **No iniciar CAMPAÑA_002 automáticamente**. Abrir una nueva campaña requeriría autorización de IA6 y encargo delimitado; no cambiar política de selección, ni Megas ni 19 máquinas antiguas.
- Ningún PASS headless acredita UI/GPU, ilustraciones ni seis modelos definitivos de libros. `main`, V28 y PR #118 permanecen fuera del alcance de esta auditoría.
