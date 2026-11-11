# IA6 — RELEVO W03 V5 ACTIVO · 11-11-2026 · LEER PRIMERO

**NO REPETIR CAMPAÑAS V3/V4 YA CERTIFICADAS.** La captura native/legacy V4 W03 está cerrada y certificada con CI #43068968046 (SHA funcional `5a82da2a9dd1a868c3f8af9d73551fe16571adea`). Los repelentes siguen pendientes. IA6 ha creado **rama NUEVA de trabajo autorizada** `codex/calvo-items-20261111-w03-repel-staging-v5`, sin alterar esta rama histórica.

**SIGUIENTE `p`:** primero comprobar que cualquier cambio local pendiente está publicado en su rama original y que el working tree está limpio. Después cambiar a la rama NUEVA `codex/calvo-items-20261111-w03-repel-staging-v5`, abrir allí `docs/coordination/items_parallel_v1/IA6_AUTORUN.md` y `CONTINUOUS_V5/STATE_W03.md`, empezar directamente la fase A de integración Repel/Súper/Máximo con mochila W05+Cuerda Huida, y seguir A→B→C sin parar cada diez. No editar esta rama antigua, `main`, V28, PR118, staging W05 ni IA6 oficial. Una `p` no ejecuta trabajo en segundo plano.

---

# ACTUALIZACIÓN IA6 — 2026-11-11: DESBLOQUEO W03 LEGACY (leer primero)

IA6 ha AUTORIZADO **tres y solo tres seams** de `modules/gameplay/wild_adventure_session.gd` exclusivamente en tu rama `codex/calvo-ia6-staging-20261111-w03-capture`. La orden de IA6 está publicada en la rama árbitra `codex/calvo-items-20261101-arbitro`:

`docs/coordination/items_parallel_v1/CONTINUOUS_V4/IA6_W03_LEGACY_WILD_SEAM_AUTH_20261111.md`

Tu siguiente `p` debe recuperar esa orden, comparar el blob fuente con staging y ejecutar los tres hunks con el test histórico `parallel_items_w03_repeat_history_v2.gd` **obligatoriamente verde**, sin aceptar las seis aserciones rojas antiguas como excepción. No tocar mochila/repelentes ni módulos fuera de permiso. La autorización no es merge oficial IA6.

---

# IA6 — W03 · NUEVA MISIÓN CONTINUA V4 EN RAMA STAGING
**Estado:** ACTIVA. **Rama ÚNICA de esta misión:** codex/calvo-ia6-staging-20261111-w03-capture.
**Origen de confianza:** plan IA6 en rama árbitra codex/calvo-items-20261101-arbitro: docs/coordination/items_parallel_v1/CONTINUOUS_V4/PLAN_W03.md; reglas generales docs/coordination/items_parallel_v1/CONTINUOUS_V4/README.md. **Base fija** e63b2e6c7e175fba318cc2f562bebd1769589092 (IA6 integradora, conserva exclusión dynamax_candy).

**PUERTA SUPERADA:** fuente histórica V3 completada y CI verificada. Al recibir p/sigue, trabajar inmediatamente en la rama staging siguiendo fases A → B → C; no detener cada diez hitos.

**Seguridad:** Si el workspace local contiene cambios no subidos, primero guardar checkpoint en su rama original; no cambiar rama con working tree sucio. Esta staging es un ensayo y no modifica ni fusiona la rama integradora oficial IA6, main, V28, PR118 u otras ramas. Evitar copiar archivos enteros de origen, usar diff por funciones, tests rojos y CI del SHA exacto. Registrar STATE_W03.md en esta misma staging. Sin trabajo asíncrono; p reanuda desde checkpoint.

**Métrica:** fases A/B/C | funcionalidades ya existentes vs integradas en ensayo | L3 y regresiones CI | conflictos bloqueados | integración oficial IA6: NO. Al terminar READY_FOR_IA6_MERGE (sin generar más rondas de QA vacías).

---

# W03 V4 — CAPTURA STAGING (ACTIVA)
Destino: codex/calvo-ia6-staging-20261111-w03-capture. Base IA6 e63b2e6c7e175fba318cc2f562bebd1769589092. Fuente W03 código ef63e824069aa27ce957e99997df8e7a50c78524, CI #42958535816 SUCCESS.

FASE A: diff selectivo de la captura W03 contra IA6. Portar únicamente lo que falte de Repeat Ball+ledger real, Net Ball, Moon Ball x4 con origen EvolutionRecord, persistencia opcional SaveV2 y pruebas. IA6 ya tiene Cuerda Huida: NO duplicarla. Identificar gap de repeles, pero NO modificar FieldItemBag (es W05).
FASE B: test captura real ShowdownAdventureSession.capture: primera captura, guardar/cargar, Repeat misma especie x3.5, Net por tipo Agua/Bicho, Moon según Piedra Lunar; stock, RNG, Party/Storage, especie base, corrupción/legacy y rollback. Conservar naturaleza efectiva de IA6. Mantener Heavy/Beast/Dive/Dusk/Lure/Love bloqueadas si productor real falta, sin flags fingidos.
FASE C: CI staging CAMP003–006 y W03 V1–V3, reporte reports/W03/CONTINUOUS_V4_STAGING_FINAL.md + STATE_W03. Entregar hunks exactos, ticket separado para repeles de mochila, READY_FOR_IA6_MERGE.

PERMISOS: cambios localizados al ledger en PlayerCollection, SaveGameData/Repository y FieldNativeSave (NO _valid_creature); CaptureBattleContext, CaptureRuleset, CaptureContextBallEffects y ShowdownAdventureSession.capture; helpers y tests propios. FieldItemBag, CreatureInstance, motor Showdown global, RNG, W04 y W05 solo lectura. No copiar archivos enteros; no main/V28/PR118. La staging no es IA6 integrada.
