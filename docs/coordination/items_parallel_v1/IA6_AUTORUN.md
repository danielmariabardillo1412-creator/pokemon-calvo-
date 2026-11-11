# IA6 — W04 · NUEVA MISIÓN CONTINUA V4 EN RAMA STAGING
**Estado:** ACTIVA. **Rama ÚNICA de esta misión:** codex/calvo-ia6-staging-20261111-w04-evolution.
**Origen de confianza:** plan IA6 en rama árbitra codex/calvo-items-20261101-arbitro: docs/coordination/items_parallel_v1/CONTINUOUS_V4/PLAN_W04.md; reglas generales docs/coordination/items_parallel_v1/CONTINUOUS_V4/README.md. **Base fija** e63b2e6c7e175fba318cc2f562bebd1769589092 (IA6 integradora, conserva exclusión dynamax_candy).

**PUERTA SUPERADA:** fuente histórica V3 completada y CI verificada. Al recibir p/sigue, trabajar inmediatamente en la rama staging siguiendo fases A → B → C; no detener cada diez hitos.

**Seguridad:** Si el workspace local contiene cambios no subidos, primero guardar checkpoint en su rama original; no cambiar rama con working tree sucio. Esta staging es un ensayo y no modifica ni fusiona la rama integradora oficial IA6, main, V28, PR118 u otras ramas. Evitar copiar archivos enteros de origen, usar diff por funciones, tests rojos y CI del SHA exacto. Registrar STATE_W04.md en esta misma staging. Sin trabajo asíncrono; p reanuda desde checkpoint.

**Métrica:** fases A/B/C | funcionalidades ya existentes vs integradas en ensayo | L3 y regresiones CI | conflictos bloqueados | integración oficial IA6: NO. Al terminar READY_FOR_IA6_MERGE (sin generar más rondas de QA vacías).

---

# W04 V4 — EVOLUCIÓN REGIONAL STAGING (ACTIVA)
Destino: codex/calvo-ia6-staging-20261111-w04-evolution. Base IA6 e63b2e6c7e175fba318cc2f562bebd1769589092. Fuente W04 código db24e6f38943e5782b0d028b2d6553267adecd6f, CI #42959076143 SUCCESS.

FASE A: reproducir prueba roja sobre base IA6 y comparar por función W04 CreatureInstance.form_id, productor real de forma en Factory, EvolutionSystem.apply_evolution, FieldItemService.evolution_options/evolve y validaciones SaveV2. IA6 ya tiene effective_nature_id W02: conservarlo, nunca copiar clase entera ni convertir forma de origen a forma de destino.
FASE B: trasplantar solo los cambios estrictamente necesarios. Probar siete evoluciones desde servicio real: Darumaka Galar, Growlithe Hisui, Sandshrew Alola, Slowpoke Galar a Slowbro/Slowking, Voltorb Hisui, Vulpix Alola; stock=1, Party/Storage, rollback, forma destino exacta, SaveV2, naturaleza original+efectiva, IV/EV/PP. Revalidar matriz 55/56; Exeggutor Alola continúa bloqueado sin Harvest oculta. No reivindicar UI de mochila hasta prueba integrada.
FASE C: CI staging con W04 T02–V3, CAMP003–006, veto dinamax_candy, informe reports/W04/CONTINUOUS_V4_STAGING_FINAL.md + STATE_W04, lista de funciones/hunks, CI SHA y READY_FOR_IA6_MERGE.

PERMISOS: CreatureInstance solo form_id aditivo preservando naturaleza W02, EvolutionSystem.apply_evolution, FieldItemService.evolve/evolution_options, identidad Factory regional, FieldNativeSave._valid_creature solo guardia de forma, SaveGameData.validate solo forma, helpers y tests W04. NO modificar ledger W03, estados de W02, FieldItemBag W05, datos/política, motor global, main/V28/PR118. Sin merge a ciegas.
