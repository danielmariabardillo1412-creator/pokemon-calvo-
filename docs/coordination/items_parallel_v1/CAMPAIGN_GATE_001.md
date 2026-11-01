# Puerta de campaña delegada 001 — IA6
**ESTADO GLOBAL: PREPARADA_SIN_ACTIVAR**
**Razón:** el CI conjunto de 2026-11-01 ha validado W01/W02/W04 y localizado un fallo de *test fixture* W03; nuevo run #41341842320 sobre `ac34fabbe1a27e69614f0239abee21c29d6fe65e` está en curso.
**Requisito de activación:** CI completo de W01–W04 PASS en el mismo SHA de pruebas (W03 puede declarar Malla Ball no implementada, pero caracterización actual debe ser PASS, no una falsa certificación); Python de W05 PASS. Una vez verificado, IA6 actualizará este archivo con `ESTADO GLOBAL: ACTIVADA`, `CHECKPOINT AUTORIZADO`, run, SHA y límites. Sin esa frase exacta, ni `p` ni `sigue` habilitan la campaña.
**Antes de habilitar código de producción:** solo W03 puede editar `modules/capture/capture_ball_effects.gd` y W05 puede crear `modules/inventory/field_machine_book_profile.gd`. W01/W02/W04 añaden pruebas y documentación, jamás implementaciones duplicadas.
**Límites:** máximo 3 microbloques por W y 1 por cada `p`, revisión por excepciones, no modificar `main`, V28 original, ramas ajenas ni PR #118.
**Cuando termine cada W:** `CAMPAÑA_001_FINALIZADA` y esperar nueva orden; no inventar CAMPAÑA_002. En caso de FAIL, detener la W concreta y enviar incidencia a IA6.
