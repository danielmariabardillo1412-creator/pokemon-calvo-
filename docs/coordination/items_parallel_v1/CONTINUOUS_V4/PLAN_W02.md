# W02 V4 — NATURALEZA/GROWTH STAGING (PENDIENTE, NO ACTIVAR AÚN)
Destino: codex/calvo-ia6-staging-20261111-w02-growth. Origen codex/calvo-items-20261109-w02-mints-integration. Base IA6 e63b2e6c7e175fba318cc2f562bebd1769589092.
CONDICIÓN: finalizar primero CONTINUOUS_V3 EXP SHARE PARTICIPATION, estado READY_FOR_IA6 y CI SHA exacta; hoy V3 sigue al inicio. No abandonar V3.

FASE A: diff de las mejoras de mentas, FieldGrowthEffects, FieldMochiEffects, FieldTrainingEffects y EvolutionSystem para effective_nature_id. IA6 ya contiene parte: solo trasladar funciones faltantes, con prueba roja. No mover EXP Share de simulador a producto ni cambiar reparto XP.
FASE B: escenarios menta -> caramelo raro/exp -> mochi -> vitaminas -> evolución por nivel/ítem -> SaveV2, Party/Storage, HP/IV/EV/PP, casos legacy/corruptos y recálculo único; conservar naturaleza efectiva, preparada para form_id W04. No copiar clases completas o sobrescribir IA6.
FASE C: CI staging con T01–04, V2/V3, CAMP003–006, selección Dynamax Candy. Informe reports/W02/CONTINUOUS_V4_STAGING_FINAL.md, STATE_W02, SHA/run, ticket y READY_FOR_IA6_MERGE.

PERMISOS: solo segmentos W02 de Growth/Mochi/Training/EvolutionSystem, helpers y tests W02. ProgressionSystem, XP global, FieldItemBag, SaveV2 central, CreatureInstance y otros workers solo lectura. No main/V28/PR118.