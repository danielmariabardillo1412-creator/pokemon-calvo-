# W02 — CAMPAÑA_001 / Informe final

**CAMPAÑA_001_FINALIZADA (trabajo de preparación cerrado)**. **Calificación funcional de seis bayas: `PREPARADO_PENDIENTE_CI`**, no PASS de mecánicas.
**Rama exclusiva:** `codex/calvo-items-20261101-w02`. **Orden:** `campaigns/CAMP_001_W02.md` en árbitra; tres microbloques 01, 02 y 03 cerrados.
**Checkpoint de origen:** árbitra `a710d8abe2e94f11974488c4563b9eb80ede5bbc` incorporado sin fuerza ni pérdida de informes mediante merge `7cbbf780e6cd36251327018f20c127e53a25c415`.

| ID | Escenarios | Positivo / negativos | Campo | Estado nuevo |
| --- | ---: | --- | --- | --- |
| `oran_berry` | 2 | PS bajos / PS llenos | +10 PS donde procede | PREPARADO_PENDIENTE_CI |
| `pecha_berry` | 3 | Veneno / quemadura y sano | Cura solo veneno | PREPARADO_PENDIENTE_CI |
| `cheri_berry` | 3 | Parálisis / veneno y sano | Cura solo parálisis | PREPARADO_PENDIENTE_CI |
| `persim_berry` | 2 | Confusión / sin confusión | **NO REGISTRADA en perfil campo**; rechazo verificado solo como contrato pendiente | PREPARADO_PENDIENTE_CI |
| `chesto_berry` | 3 | Sueño con Spore / quemadura y sano | Cura solo sueño | PREPARADO_PENDIENTE_CI |
| `rawst_berry` | 3 | Quemadura / veneno y sano | Cura solo quemadura | PREPARADO_PENDIENTE_CI |

**Alcance:** 16 escenarios, 48 variantes de portador activo/ausente/reserva y 32 comprobaciones de mochila en equipo/caja **definidas**, no ejecutadas. Todos exigen consumo físico único, propietario y SaveV2; los recibos contienen SHA-256. Matriz cerrada por seis ID independientes.
**Código publicado:** fixture blob `8840b37569270054757dc2728af66f882af44db6`, test Godot `0f66aeab576d099d7de215c27eb5a2746cdcfb0a`, validador Python `aadad7a50e013d831f908c9b4c6585f0a412575b` (18 tests unitarios definidos).
**Evidencias estáticas:** ITER_01 15/15, ITER_02 20/20, ITER_03 25/25 inspecciones GitHub. **Python unittests nuevos: SIN_EJECUTAR. Godot integración nueva: SIN_EJECUTAR. GPU/visual: SIN_EJECUTAR.**
**CI histórica válida solo para previos:** Actions #41341842320, commit `ac34fabbe1a27e69614f0239abee21c29d6fe65e`, W02 503 checks/7 casos para Zidra, Ziuela y Dillo. No certifica esta campaña.
**Documentación:** `CAMP_001_ITER_01.md` → `CAMP_001_ITER_02.md` → `CAMP_001_ITER_03.md`, `CAMP_001_PROGRESO.csv`, `CONTINUIDAD.md` actualizados en rama propia. LOTE_001 y LOTE_002 originales sin reescritura.

## Revisión solicitada a IA6
1. Auditar diff acotado a seis rutas de campaña y docs propios; comprobar que no existen cambios en producción.
2. Ejecutar Python del contrato (`--fixture-only`, `--unittest`) y Godot 4.7 contra SHA integrado; validar `--result .godot/parallel_items/w02_campaign_001/godot.json` y `per_item` para cada uno de los seis IDs.
3. Ante cualquier FAIL real: detener promoción; localizar caso y delegar corrección de tests sin alterar expectativas para fabricar PASS.
4. Decidir, mediante orden futura, si Persim debe poder usarse desde mochila; no convertir el hueco observado en funcionalidad supuesta.

**STOP:** los tres microbloques están consumidos. No hay autorización para un cuarto, otro lote o modificación de producción. Esperar orden de IA6.
