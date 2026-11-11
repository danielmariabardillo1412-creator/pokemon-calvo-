# IA6 — W01 · NUEVA MISIÓN CONTINUA V4 EN RAMA STAGING
**Estado:** PENDIENTE_ACTIVACION. **Rama ÚNICA de esta misión:** codex/calvo-ia6-staging-20261111-w01-held.
**Origen de confianza:** plan IA6 en rama árbitra codex/calvo-items-20261101-arbitro: docs/coordination/items_parallel_v1/CONTINUOUS_V4/PLAN_W01.md; reglas generales docs/coordination/items_parallel_v1/CONTINUOUS_V4/README.md. **Base fija** e63b2e6c7e175fba318cc2f562bebd1769589092 (IA6 integradora, conserva exclusión dynamax_candy).

**PUERTA OBLIGATORIA:** NO ejecutar V4 ni sustituir la rama histórica mientras V2 esté sin cierre READY_FOR_IA6 y CI/ledger validado. Primero terminar trabajo de la nota original y verificar CI. Cuando la puerta pase, activar ESTA misión con una p sin pedir otra orden IA6.

**Seguridad:** Si el workspace local contiene cambios no subidos, primero guardar checkpoint en su rama original; no cambiar rama con working tree sucio. Esta staging es un ensayo y no modifica ni fusiona la rama integradora oficial IA6, main, V28, PR118 u otras ramas. Evitar copiar archivos enteros de origen, usar diff por funciones, tests rojos y CI del SHA exacto. Registrar STATE_W01.md en esta misma staging. Sin trabajo asíncrono; p reanuda desde checkpoint.

**Métrica:** fases A/B/C | funcionalidades ya existentes vs integradas en ensayo | L3 y regresiones CI | conflictos bloqueados | integración oficial IA6: NO. Al terminar READY_FOR_IA6_MERGE (sin generar más rondas de QA vacías).

---

# W01 V4 — HELD STAGING (PENDIENTE, NO ACTIVAR AÚN)
Destino: codex/calvo-ia6-staging-20261111-w01-held. Origen W01 codex/calvo-items-20261110-w01-gems-autobatch01. Base IA6 e63b2e6c7e175fba318cc2f562bebd1769589092.
CONDICIÓN: no abandonar V2 hasta STATE_W01 READY_FOR_IA6, gate 38/38 #42958587809 SUCCESS comprobado, guard #42960157622 SUCCESS y ledger final reconciliado/CI actual. Si no se cumple, continuar V2.

FASE A: diff por función del held W01 vs IA6. 18 gemas, TANDA04 10 equipables y FASE B 26 candidatos; distinguir QA de implementación. Prueba roja de lo ausente en IA6. No copiar native_engine.cjs íntegro ni atribuir objetos nuevos.
FASE B: portar solo hooks específicos de held que falten; verificar FieldItemService.equip -> combate nativo -> settle_finished_battle -> SaveV2, consumo, cambios de equipo, Transformación, PP y casos negativos. Si la ruta IA6 ya pasa, documentar NO_DIFF_NEEDED.
FASE C: CI staging con T01–04, V2, CAMP003/004/005, veto dynamax_candy y reporte reports/W01/CONTINUOUS_V4_STAGING_FINAL.md más STATE_W01. Listar hunks, SHA, run y bloqueos; READY_FOR_IA6_MERGE.

OWNERSHIP: adaptadores held específicos W01 y tests/workflow propios. SaveV2, CreatureInstance, FieldItemBag, PlayerCollection, FieldItemService y reglas globales de motor SOLO LECTURA. Nunca tocar main, V28, PR118 ni ramas ajenas. No STOP por grupos de diez; tampoco trabajo en background.
