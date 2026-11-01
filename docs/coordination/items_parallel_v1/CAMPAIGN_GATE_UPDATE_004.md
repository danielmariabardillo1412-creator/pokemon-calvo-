# CAMPAÑA_001 — GATE_004 / revisión de IA6, 2026-11-02

**Estado vigente y orden más reciente.** Sustituye los estados transitorios de `CAMPAIGN_GATE_UPDATE_003.md`, sin ampliar los encargos originales. **En total 13 de 15 microbloques publicados.**

## Verificación nueva
[CI Godot 4.7 #41362240030](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41362240030) `completed/success` del staging `codex/calvo-items-20261102-ci-w03-w05-final`, SHA `3dba61641f285300375220c6fc9f3fcc25b89dac`.
- W03 ITER_03: suite nueva Net Ball `CAMP_001_W03_NET` **60 checks, 0 errores, PASS**. Python estático y prueba original Net 34/0 PASS.
- W05 ITER_02: presentación textual por movimiento/tipo **959 checks, 0 errores, PASS**; Python máquina: 14 tests PASS. Cobertura declarada: 229 máquinas activas y 19 heredadas rechazadas.
- Importados los **mismos blobs** del staging, secuencialmente, en rama árbitra: W03 `60e2082e0a0652581afc56f3b27434b7ec9728b7`, W05 `5ebc65b47e8480a9193880dfca8fb6cfe34e1231`. Acta detallada [integration/CAMP_001_W03_ITER03_W05_ITER02.md](integration/CAMP_001_W03_ITER03_W05_ITER02.md). Sin editar ramas W.

## Estado y permiso para el próximo `p`
- **W01 (IA1): 03/03, `CAMPAÑA_001_FINALIZADA`. STOP.** No enviar otra `p`.
- **W02 (IA2): 03/03, `CAMPAÑA_001_FINALIZADA`. STOP.** Corrección de arnés propia validada #41354434516 y ya integrada por IA6; no iniciar cuarta iteración.
- **W03 (IA3): 03/03, `CAMPAÑA_001_FINALIZADA`. STOP.** ITER_03 ya ha pasado CI #41362240030 y sus dos archivos han sido integrados. No iniciar campaña 002 sin nueva autorización.
- **W04 (IA4): 02/03, `CONGELADA_A_PETICION_USUARIO`. STOP.** No abrir un nuevo chat, asignar reemplazo, modificar su rama ni ordenar bloque 03 ahora. Su trabajo está preservado.
- **W05 (IA5): 02/03, `ITER_02_INTEGRADA_VERIFICADA`. AUTORIZADO un `p` exclusivamente para ITER_03 de `campaigns/CAMP_001_W05.md`**. Antes debe leer este gate y comparar HEADs, sincronizar solo mediante merge no destructivo si procede, preservar sus informes y las dos rutas autorizadas. No repetir el bloque 02 ni cambiar políticas. La iteración 03 se limita a validar la enseñanza y consumo de MT con el servicio `FieldItemService.teach` **sin editar ese servicio**. Al terminar, publicar informe final y detenerse: no iniciar lote 002 por cuenta propia.

**Godot headless ≠ prueba visual:** sigue pendiente el arte de los seis modelos y la interfaz real; no crear diseños sin aprobación. No tocar `main`, V28, PR #118, fuentes canónicas, guardados ni ramas de otras IAs. Ninguna comprobación realizada aquí certifica el conjunto del juego.

**Rol IA6:** inspeccionar y probar ITER_03 de W05 cuando se publique, y mantener IA4 congelada. No hacer trabajo en segundo plano; la nueva `p` debe enviarse manualmente a W05.
