# IA6 — V4 STAGING PREASIGNADA, PERO TODAVÍA NO ACTIVA · W02 · 2026-11-11
**NO ABANDONES TU CAMPAÑA ACTUAL.** IA6 ha preparado un relevo para DESPUÉS del cierre real READY_FOR_IA6 de tu misión V3 (participación real EXP Share, sin activar XP global). Continúa EN ESTA RAMA original y completa las pruebas/CI y checkpoint antes de cambiar.
Cuando esté cerrada, **sin esperar otra nota IA6**, puedes usar la rama nueva ya creada codex/calvo-ia6-staging-20261111-w02-growth; allí te espera docs/coordination/items_parallel_v1/IA6_AUTORUN.md con plan íntegro y docs/coordination/items_parallel_v1/CONTINUOUS_V4/STATE_W02.md. Activación condicionada a SHA+CI y working tree limpio. Si no está cerrada, la siguiente p sigue TU trabajo actual. Nunca reportar la staging como integrada en IA6.

---

# IA6 — VETO CARAMELO DINAMAX / dinamax_candy — 2026-11-11

**ORDEN VINCULANTE A W02:** el usuario descartó `dynamax_candy`. Ya está en `config/item_selection_v1.json::excluded_ids` de TU rama y el test de política exige rechazo de generación. No seleccionarlo, no incluirlo en nuevas colas de objetos ni invertir trabajo en su arte/función; los CSV antiguos `CANDIDATE`/`RETAIN_FOR_FUNCTIONAL_REVIEW` son auditorías HISTÓRICAS, no autorización. Excluye solo este ítem, no Rare Candy/Exp Candy/otras mecánicas no discutidas. Dictamen completo en rama árbitra: `docs/coordination/items_parallel_v1/IA6_EXCLUSION_DYNAMAX_CANDY_20261111.md`. El resto de TU plan continuo sigue vigente.

---

# IA6 — W02 · CAMPAÑA CONTINUA V3 AUTORIZADA

**IA6 REVISÓ TU CAMPAÑA V2 Y TE ASIGNA ESTA NUEVA MISIÓN, NO ESTÁS EN ESPERA.** El archivo que estás leyendo en TU propia rama `codex/calvo-items-20261109-w02-mints-integration` es la orden vigente. El plan V2 anterior está agotado y se conserva en GitHub para trazabilidad; **NO repetir IDs o pruebas certificadas de V2**. La misión V3 tiene tres fases y no termina artificialmente al completar 10/10. Cada `p`/`sigue` recupera `docs/coordination/items_parallel_v1/CONTINUOUS_V3/STATE_W02.md` y reanuda la primera fase/tarea pendiente; al finalizar una fase con CI correcta empieza inmediatamente la siguiente sin esperar a IA6, en el mismo turno si es posible.

**Autoridad y política:** protocolo árbitra `docs/coordination/items_parallel_v1/CONTINUOUS_V3/README.md`, plan central `docs/coordination/items_parallel_v1/CONTINUOUS_V3/PLAN_W02.md`, rama árbitra `codex/calvo-items-20261101-arbitro`. La copia íntegra del plan está debajo. Esta autorización es expresa para los módulos/funciones enumerados, pero NO permite cambios globales ajenos, ni tocar `main`, V28, PR118, ni ramas de otras W. No atribuir CI a SHA distinta ni integración final a IA6 sin ver su CI. Si todas las fases posibles se agotan o dependen de seam protegida, publicar READY_FOR_IA6 con ticket real y STOP. Si el turno se agota antes, checkpoint GitHub y siguiente `p`, sin otra autorización ni promesa de background.

**Barra correcta:** campaña fase A/B/C + tareas | objetos nuevos | L3 comprobados | bloqueados | integración IA6 pendiente. **No usar 10/10 como sinónimo de 10 objetos.**

---

# IA6 W02 · CAMPAÑA CONTINUA V3 — EXP SHARE, PARTICIPACIÓN AUTORITATIVA
Rama: codex/calvo-items-20261109-w02-mints-integration.
Baseline: campaña V2 de 42 bayas cerrada, 0 efectos nuevos de producción, CI #42937706214 SUCCESS. EXP SHARE todavía L1; no afirmar efecto real por simple equipamiento.

AUTORIZACIÓN NUEVA IA6, LIMITADA: el contrato IA6_EXP_SHARE_PARTICIPATION_CONTRACT_20261109.md continúa protegiendo la experiencia global. Se autoriza W02 a crear y probar un productor de participación solo lectura, y a proponer perfil EXP Share OPT-IN sin activarlo en el juego, sin cambiar reparto XP legado.

FASE A — RECIBO: crear helper nuevo modules/creatures/progression/battle_participation_receipt_w02.gd de registro validado y detached con battle_id, side_id, roster_ids, deployed_ids, eligible_alive_ids, starting_held_items y outcome hash. Derivar desplegados de eventos reales de batalla, no de UI ni de todo el equipo. Pruebas de al menos 10 escenarios: titular, cambio, dos rivales, debilitamiento, reserva sin salir, nivel 100, Transformación, restauración, derrota, equipo mixto. Rechazar adversario, duplicados, Storage, IDs desconocidos, batalla distinta y reordenación.
FASE B — XP Y POLÍTICA: demostrar que ProgressionSystem.reconcile_battle_result actualmente reparte experiencia entre supervivientes de todo el array y Lucky Egg tiene contrato previo. Construir simulador PURO para comparar política legada vs alternativa claramente versionada, con party A desplegado, B reserva EXP Share y C reserva sin objeto. Sin fórmula canónica decidida, POLÍTICA PENDIENTE: NO activar ni adjudicar efecto al EXP Share, NO sumar experiencia dos veces.
FASE C — TESTS DE INTEGRACIÓN: si los eventos existentes permiten participación real, proyección de eventos SOLO LECTURA en función auxiliar de ShowdownAdventureSession, sin tocar _finish, capture, RNG, inventario ni batalla. Contrato para sesiones nativa/salvaje/entrenador, restauración de combate y SaveV2. Si no hay eventos suficientes, ticket bloqueante con APIs mínimas y casos rojos. CI completa W02 T01–04+CAMP003–006+V2, informe reports/W02/CONTINUOUS_V3_FINAL.md.

ARCHIVOS: helper nuevo, tests, fixtures, workflow/report W02. Puede añadirse método AUXILIAR de lectura de eventos a showdown_adventure_session.gd SIN modificar _finish/capture y solo con prueba que derive de acciones reales; si hace falta otro archivo compartido, ticket IA6. PROHIBIDO editar ProgressionSystem, motores Showdown, CreatureInstance, FieldItemService, SaveGameData, SaveV2, FieldItemBag, EXP Share de producción, Lucky Egg, ramas ajenas, main/V28/PR118.

No STOP por bloque de diez. Checkpoint CONTINUOUS_V3/STATE_W02.md; p/sigue retoma fase pendiente. READY_FOR_IA6 al agotar fases; L3 EXP Share seguirá bloqueado hasta política e integración de IA6. No atribuir QA como objetos nuevos.
