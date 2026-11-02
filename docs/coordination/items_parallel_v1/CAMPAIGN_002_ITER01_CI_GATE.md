# IA6 — CAMPAÑA_002 / ITER_01, CI de las cuatro familias

**Fecha:** 2026-11-02. **Estado:** validación acotada PASS en staging para W01/W02/W03/W05. Esta acta NO certifica iteraciones 02–03 que no existen, no activa otras campañas y no modifica producción.

## Árbols y resultados exactos
- Staging `codex/calvo-items-20261102-ci-camp002-iter01`, SHA **`967002fcbf26a1159d3a14a020e8921b34cfab8f`**, [Actions #41484879741](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41484879741) `completed/success`. Godot 4.7 + Node 22/Simulador nativo, cuatro pasos `success` y puerta general `success`.
- W01: `W01_CAMP002_ITER01_CONTRACT_PASS cases=7 runs=10 variants=30 sources=4`; seis casos negativos del validador `W01_CAMP002_ITER01_NEGATIVE_PASS rejected=6`. **Solo contrato/matriz**; runner Godot W01 está autorizado en ITER_02, no ejecutado aquí.
- W02: `PARALLEL_ITEMS_W02_CAMP002 PASS checks=350 cases=4` en Godot, 13 pruebas Python `OK` y validador de recibos `success` sobre `.godot/parallel_items/w02_campaign_002/godot.json`. **Solo dos bayas `sitrus_berry` y `lum_berry` en contextos de esta iteración**; campo no ensayado.
- W03: `CAMP_002_W03_STATIC_CONTRACT_PASS tests=9; NO_FUNCIONAL_PASS`, detecta contexto ausente para Dusk/Repeat/Dive; **ninguna bola nueva implementada**. No confundir selección con multiplicador funcional.
- W05: 11 unittests Python `OK` incluido catálogo real; muestra reproducible de 12 MT y 12 tipos sin repetir `tm01`, `tm02`, `tm77`, con learnsets reales. **No se ha ejecutado enseñanza de estas 12 en Godot** (ITER_02–03).
- La primera CI [#41484446568](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41484446568) fue `failure` exclusivamente por W02 en Godot: `bootstrap: alcance exclusivo de ITER_01`, `350 checks/4 casos`, al comparar `automation.completed_iterations == [1]` cuando JSON devolvió números `1.0`. Otros tres pasos pasaron. La segunda CI corrige **solo el test**, no el juego ni la semilla, y pasa.

## Regla de sincronización obligatoria W02
- Rama worker W02 `codex/calvo-items-20261102-w02-camp002` conservó **sin corregir** `tests/gameplay/parallel_items_w02_campaign_002.gd` blob original `53b70033578f1a31c13081f558334bacf247ada5`.
- El runner corregido y ensayado es el blob **`2e0ac1d2142dad96f110254e7eb4f2a3c5f04c47`**, con comprobación estrica de `automation.completed_iterations`: array de exactamente un número (int/float) igual a 1.0. No se ignora la iteración, ni se eliminan aserciones.
- IA6 integra ese blob en su rama, pero **no toca la rama W02**, según propiedad exclusiva del protocolo. **Al recibir su próxima `p`, W02 DEBE sincronizar ese archivo exacto desde árbitra o reproducir el mismo parche antes de continuar su ITER_02**, sin sobrescribir tests/reports CAMPAÑA_001 ni hacer merge indiscriminado de ramas. Registrar el SHA de blob reparado y detenerse si no coincide. Si no puede hacerlo, detener W02 y elevar bloqueo a IA6.
- El resto de las W tienen archivos de ITER_01 idénticos a staging, sin cambios por IA6.

## Orden de continuación
**W01, W02, W03 y W05: 01/03 completado.** `p` autoriza ITER_02 **únicamente** de su `CAMP_002_W0X.md`; el próximo bloque debe publicarse en su rama nueva con informe, CSV, SHA y pruebas. W02 debe aplicar la corrección previa del párrafo anterior. IA6 centraliza el siguiente gate al publicar las ITER_02, no afirmar PASS en nuevos scripts sin ejecutarlos.

**IA4/W04: CONGELADA** 02/03 de CAMPAÑA_001, sin nueva rama ni permiso. No tocar `main`, V28, PR #118, rama antigua, datos, motor ni guardados. Arte/UI/GPU no certificado.
