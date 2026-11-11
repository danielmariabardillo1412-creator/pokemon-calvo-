# W01 V4 — HELD STAGING (PENDIENTE, NO ACTIVAR AÚN)
Destino: codex/calvo-ia6-staging-20261111-w01-held. Origen W01 codex/calvo-items-20261110-w01-gems-autobatch01. Base IA6 e63b2e6c7e175fba318cc2f562bebd1769589092.
CONDICIÓN: no abandonar V2 hasta STATE_W01 READY_FOR_IA6, gate 38/38 #42958587809 SUCCESS comprobado, guard #42960157622 SUCCESS y ledger final reconciliado/CI actual. Si no se cumple, continuar V2.

FASE A: diff por función del held W01 vs IA6. 18 gemas, TANDA04 10 equipables y FASE B 26 candidatos; distinguir QA de implementación. Prueba roja de lo ausente en IA6. No copiar native_engine.cjs íntegro ni atribuir objetos nuevos.
FASE B: portar solo hooks específicos de held que falten; verificar FieldItemService.equip -> combate nativo -> settle_finished_battle -> SaveV2, consumo, cambios de equipo, Transformación, PP y casos negativos. Si la ruta IA6 ya pasa, documentar NO_DIFF_NEEDED.
FASE C: CI staging con T01–04, V2, CAMP003/004/005, veto dynamax_candy y reporte reports/W01/CONTINUOUS_V4_STAGING_FINAL.md más STATE_W01. Listar hunks, SHA, run y bloqueos; READY_FOR_IA6_MERGE.

OWNERSHIP: adaptadores held específicos W01 y tests/workflow propios. SaveV2, CreatureInstance, FieldItemBag, PlayerCollection, FieldItemService y reglas globales de motor SOLO LECTURA. Nunca tocar main, V28, PR118 ni ramas ajenas. No STOP por grupos de diez; tampoco trabajo en background.