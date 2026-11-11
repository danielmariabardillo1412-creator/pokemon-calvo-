# IA6 — W02 · NUEVA MISIÓN CONTINUA V4 EN RAMA STAGING
**Estado:** PENDIENTE_ACTIVACION. **Rama ÚNICA de esta misión:** codex/calvo-ia6-staging-20261111-w02-growth.
**Origen de confianza:** plan IA6 en rama árbitra codex/calvo-items-20261101-arbitro: docs/coordination/items_parallel_v1/CONTINUOUS_V4/PLAN_W02.md; reglas generales docs/coordination/items_parallel_v1/CONTINUOUS_V4/README.md. **Base fija** e63b2e6c7e175fba318cc2f562bebd1769589092 (IA6 integradora, conserva exclusión dynamax_candy).

**PUERTA OBLIGATORIA:** NO ejecutar V4 ni sustituir la rama histórica mientras V3 esté sin cierre READY_FOR_IA6 y CI/ledger validado. Primero terminar trabajo de la nota original y verificar CI. Cuando la puerta pase, activar ESTA misión con una p sin pedir otra orden IA6.

**Seguridad:** Si el workspace local contiene cambios no subidos, primero guardar checkpoint en su rama original; no cambiar rama con working tree sucio. Esta staging es un ensayo y no modifica ni fusiona la rama integradora oficial IA6, main, V28, PR118 u otras ramas. Evitar copiar archivos enteros de origen, usar diff por funciones, tests rojos y CI del SHA exacto. Registrar STATE_W02.md en esta misma staging. Sin trabajo asíncrono; p reanuda desde checkpoint.

**Métrica:** fases A/B/C | funcionalidades ya existentes vs integradas en ensayo | L3 y regresiones CI | conflictos bloqueados | integración oficial IA6: NO. Al terminar READY_FOR_IA6_MERGE (sin generar más rondas de QA vacías).

---

# W02 V4 — NATURALEZA/GROWTH STAGING (PENDIENTE, NO ACTIVAR AÚN)
Destino: codex/calvo-ia6-staging-20261111-w02-growth. Origen codex/calvo-items-20261109-w02-mints-integration. Base IA6 e63b2e6c7e175fba318cc2f562bebd1769589092.
CONDICIÓN: finalizar primero CONTINUOUS_V3 EXP SHARE PARTICIPATION, estado READY_FOR_IA6 y CI SHA exacta; hoy V3 sigue al inicio. No abandonar V3.

FASE A: diff de las mejoras de mentas, FieldGrowthEffects, FieldMochiEffects, FieldTrainingEffects y EvolutionSystem para effective_nature_id. IA6 ya contiene parte: solo trasladar funciones faltantes, con prueba roja. No mover EXP Share de simulador a producto ni cambiar reparto XP.
FASE B: escenarios menta -> caramelo raro/exp -> mochi -> vitaminas -> evolución por nivel/ítem -> SaveV2, Party/Storage, HP/IV/EV/PP, casos legacy/corruptos y recálculo único; conservar naturaleza efectiva, preparada para form_id W04. No copiar clases completas o sobrescribir IA6.
FASE C: CI staging con T01–04, V2/V3, CAMP003–006, selección Dynamax Candy. Informe reports/W02/CONTINUOUS_V4_STAGING_FINAL.md, STATE_W02, SHA/run, ticket y READY_FOR_IA6_MERGE.

PERMISOS: solo segmentos W02 de Growth/Mochi/Training/EvolutionSystem, helpers y tests W02. ProgressionSystem, XP global, FieldItemBag, SaveV2 central, CreatureInstance y otros workers solo lectura. No main/V28/PR118.
