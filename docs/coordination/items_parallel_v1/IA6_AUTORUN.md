# IA6 — W04 · NUEVA MISIÓN ACTIVA CONTINUOUS_V6/PLAN_W04.md · 12-11-2026

**Rama ÚNICA NUEVA:** `codex/calvo-items-20261112-w04-evolution-consumer-v6`.
**ANTERIOR:** W04 V5 ENTREGADA Y CERRADA. No repetir sus hitos ni declarar su CI aplicable a nuevos commits.
**`p` SIGUIENTE:** FASE A: localizar EVOLUTION_AVAILABLE nativo poscombate y demostrar que falta publicación UI/propiedad; luego implementar y CI.
**TRABAJO FUNCIONAL:** consumidor y decisión real de evolución por XP de combate, con aceptación/rechazo y estado Party/Storage.
**PERMISOS:** solo hunks y pruebas que autoriza el PLAN íntegro siguiente. La rama IA6 oficial y main/V28/PR118 son solo lectura; cada compañera conserva su propia rama. Conservar veto `dynamax_candy`. No se ejecuta en background.
**CHECKPOINT:** `docs/coordination/items_parallel_v1/CONTINUOUS_V6/STATE_W04.md`. El plan es autoridad IA6 en `codex/calvo-items-20261101-arbitro` (también copiado aquí completo).
**AUTONOMÍA:** A→B→C en el máximo trabajo real por turno con commits/CI; sin STOP por diez hitos; detener solo con entrega certificada o bloqueo fuera de permisos verificado.

---

# IA6 / W04 — CONTINUOUS_V6 · DECISIÓN Y PUBLICACIÓN REAL DE EVOLUCIONES POR XP DESPUÉS DEL COMBATE

**Autorizado 2026-11-12. Rama nueva EXCLUSIVA** `codex/calvo-items-20261112-w04-evolution-consumer-v6` basada en `codex/calvo-items-20261111-w04-regional-level-v5`, que conserva las diez correcciones de forma V5. No confundir con el HEAD oficial IA6: W04 V5 **NO** está aún integrada. Su CI certificada #43073026880, SHA de código `2aad1bfa2a5d74adf845699c2f161345177ea622`; en esta misión V6 todavía 0 PASS.

## Defecto que queda por corregir (no repetir diez tests de servicio)
V5 prueba 10/10 rutas regionales por `ProgressionSystem.gain_experience` → `EVOLUTION_AVAILABLE` → `apply_evolution` → `replace_owned_same_identity` en harness Party/Storage. Sin embargo el **consumidor real de eventos tras combate no garantiza al jugador aceptar/rechazar y publicar la evolución**, y no hay L3 visual de esa secuencia. Las 7 evoluciones por objeto V4 eran otro recorrido y no son el objetivo nuevo.

**Fase A — localizar consumidor, reproducir fallo real.** Inspeccionar `ShowdownAdventureSession` / `FieldNativeSession`, `ProgressionSystem.reconcile_battle_result`, `FieldNativeBridge`, campo/presentación y `PlayerCollection`. Registrar el evento real emitido al obtener XP en combate nativo, quién lo recibe, el punto de asentamiento de recompensas, la identidad tras battle settle, y si existe una UI de evolución reutilizable. Crear RED end-to-end real (no llamar `apply_evolution` directamente como sustituto de una decisión). Al menos ruta regional `diglett_alola` 26 y ruta independiente `meowth_galar` 28; rechazos a nivel anterior o Everstone.

**Fase B — solución mínima aplicable.** Permiso exclusivo de staging W04 para **nuevo helper acotado** de resolución de evento/prompt, integrable luego por IA6, y cambios limitados a métodos concretos de salida de combate en `modules/gameplay/showdown_adventure_session.gd`, `scenes/visual/field_native_bridge.gd` y/o presentación de elección, SOLO si la fase A demuestra necesidad. Reutilizar `FieldGrowthChoices` (ya sabe mostrar destinos y no evolucionar) si encaja sin romper el flujo Rare Candy; no duplicar gestor de XP o UI. La ruta debe ofrecer **aceptar / declinar** desde interfaz real, validar que la decisión corresponde al evento y criatura propietaria actual, aplicar `ProgressionSystem.apply_evolution`, publicar sustitución same_identity en Party/Storage y mostrar resultado. En cancelación, bloqueo o fallo de validación NO duplicar ni corromper criatura; guardar manual y cargar SaveV2 con identidad y `form_id` de destino; conservar `effective_nature_id`, IV/EV, EXP, PP, shiny, held item, amistad y PS. Evitar doble emisión/consumo de XP, prompts duplicados tras reapertura, guardado intermedio no confirmado y mutación tras combate aún ocupado.

**Guardas y conflictos:** la función `EvolutionSystem.apply_evolution` V5 se conserva intacta salvo error demostrado; no editar `CreatureInstance`, `PlayerCollection`, `SaveGameData`, `FieldItemService`, `FieldGrowthEffects`, `ProgressionSystem`, battle JS ni cambios compartidos de W02, W03 y W05. En módulos compartidos usar hunks localizados y documentarlos para que IA6 los trasplante, no copiar archivos enteros. El XP de EXP Share está bajo W02 y NO se debe reprogramar aquí. Los 6 level_up con condiciones incompletas, `trade`, evoluciones `spin`/formas, Exeggutor Alola Harvest deben seguir bloqueados, jamás degradados a niveles simples. `dynamax_candy` excluido.

**Fase C — aceptación y entrega.** CI headless real Godot 4.7 + pruebas negativas de recepción/elección/rollback + SaveV2 y regresiones V5 (10 rutas), V4 (7 objetos), compatibilidad menta W02; prueba del flujo visual automatizable si existe, y marcar GPU/visual manual NO CERTIFICADO cuando no se ejecute. Ejecutar regresiones que estén disponibles de CAMP003–006 sin inventar que están en esta base; si para END-TO-END real hay API de otro equipo necesariamente protegida, documentar ticket concreto para IA6 y código aislado listo para trasplante, sin declarar L3 end-to-end.
Publicar `CONTINUOUS_V6/STATE_W04.md`, informe `reports/W04/CONTINUOUS_V6_FINAL.md`, SHA funcional y URL CI. **Métrica: consumidor real de XP y decisión con interfaz (0/2 rutas piloto hasta CI), no objetos nuevos ni nuevos IDs; cobertura extensible a diez rutas tras piloto.** Al terminar entregar READY_FOR_IA6_MERGE_CONSUMER_CANDIDATE (no merge oficial) o BLOCKED_SEAM demostrado.

**Autonomía:** una `p` empieza A y continúa B→C sin nuevos permisos por cada microbloque, pero solo en hunks autorizados; ningún trabajo en segundo plano. No tocar main, V28, PR118, rama IA6 oficial ni ramas ajenas. No prometer que emisión de evento = evolución jugable.

