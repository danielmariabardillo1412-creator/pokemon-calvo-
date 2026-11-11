# IA6 — RELEVO W03 V5 ACTIVO · 11-11-2026 · LEER PRIMERO

**NO REPETIR CAMPAÑAS V3/V4 YA CERTIFICADAS.** La captura native/legacy V4 W03 está cerrada y certificada con CI #43068968046 (SHA funcional `5a82da2a9dd1a868c3f8af9d73551fe16571adea`). Los repelentes siguen pendientes. IA6 ha creado **rama NUEVA de trabajo autorizada** `codex/calvo-items-20261111-w03-repel-staging-v5`, sin alterar esta rama histórica.

**SIGUIENTE `p`:** primero comprobar que cualquier cambio local pendiente está publicado en su rama original y que el working tree está limpio. Después cambiar a la rama NUEVA `codex/calvo-items-20261111-w03-repel-staging-v5`, abrir allí `docs/coordination/items_parallel_v1/IA6_AUTORUN.md` y `CONTINUOUS_V5/STATE_W03.md`, empezar directamente la fase A de integración Repel/Súper/Máximo con mochila W05+Cuerda Huida, y seguir A→B→C sin parar cada diez. No editar esta rama antigua, `main`, V28, PR118, staging W05 ni IA6 oficial. Una `p` no ejecuta trabajo en segundo plano.

---

# IA6 — V4 STAGING ACTIVA · W03 · 2026-11-11
**Tu misión histórica V3 ha cerrado READY_FOR_IA6 y fue verificada por IA6.** No repetir QA ni empezar otra tanda en ESTA rama histórica. **IA6 ya creó una RAMA NUEVA EXCLUSIVA**: codex/calvo-ia6-staging-20261111-w03-capture; el plan completo está en docs/coordination/items_parallel_v1/IA6_AUTORUN.md de ESA rama y el estado en docs/coordination/items_parallel_v1/CONTINUOUS_V4/STATE_W03.md. En la siguiente p: conservar el working tree original y comprobar que no hay modificaciones sin subir; cambiar a la staging asignada, leer allí IA6_AUTORUN.md y empezar fase A, B, C sin STOP cada diez. No modificar la rama oficial codex/calvo-ia6-integration-20261109, main, V28 ni PR118. La CI de V3 no certifica la staging.

---

# IA6 — VETO CARAMELO DINAMAX / dinamax_candy — 2026-11-11

**ORDEN VINCULANTE A W03:** el usuario descartó `dynamax_candy`. Ya está en `config/item_selection_v1.json::excluded_ids` de TU rama y el test de política exige rechazo de generación. No seleccionarlo, no incluirlo en nuevas colas de objetos ni invertir trabajo en su arte/función; los CSV antiguos `CANDIDATE`/`RETAIN_FOR_FUNCTIONAL_REVIEW` son auditorías HISTÓRICAS, no autorización. Excluye solo este ítem, no Rare Candy/Exp Candy/otras mecánicas no discutidas. Dictamen completo en rama árbitra: `docs/coordination/items_parallel_v1/IA6_EXCLUSION_DYNAMAX_CANDY_20261111.md`. El resto de TU plan continuo sigue vigente.

---

# IA6 — W03 · CAMPAÑA CONTINUA V3 AUTORIZADA

**IA6 REVISÓ TU CAMPAÑA V2 Y TE ASIGNA ESTA NUEVA MISIÓN, NO ESTÁS EN ESPERA.** El archivo que estás leyendo en TU propia rama `codex/calvo-items-20261104-w03-camp006` es la orden vigente. El plan V2 anterior está agotado y se conserva en GitHub para trazabilidad; **NO repetir IDs o pruebas certificadas de V2**. La misión V3 tiene tres fases y no termina artificialmente al completar 10/10. Cada `p`/`sigue` recupera `docs/coordination/items_parallel_v1/CONTINUOUS_V3/STATE_W03.md` y reanuda la primera fase/tarea pendiente; al finalizar una fase con CI correcta empieza inmediatamente la siguiente sin esperar a IA6, en el mismo turno si es posible.

**Autoridad y política:** protocolo árbitra `docs/coordination/items_parallel_v1/CONTINUOUS_V3/README.md`, plan central `docs/coordination/items_parallel_v1/CONTINUOUS_V3/PLAN_W03.md`, rama árbitra `codex/calvo-items-20261101-arbitro`. La copia íntegra del plan está debajo. Esta autorización es expresa para los módulos/funciones enumerados, pero NO permite cambios globales ajenos, ni tocar `main`, V28, PR118, ni ramas de otras W. No atribuir CI a SHA distinta ni integración final a IA6 sin ver su CI. Si todas las fases posibles se agotan o dependen de seam protegida, publicar READY_FOR_IA6 con ticket real y STOP. Si el turno se agota antes, checkpoint GitHub y siguiente `p`, sin otra autorización ni promesa de background.

**Barra correcta:** campaña fase A/B/C + tareas | objetos nuevos | L3 comprobados | bloqueados | integración IA6 pendiente. **No usar 10/10 como sinónimo de 10 objetos.**

---

# IA6 W03 · CAMPAÑA CONTINUA V3 — PESO, PIEDRA LUNAR Y ULTRAENTES COMO FUENTE DE CAPTURA
Rama: codex/calvo-items-20261104-w03-camp006.
Baseline: campaña V2 completada 25/25 bolas examinadas, 16 con ruta L3, siete BLOCKED_CONTEXT y dos PARCIAL_ZONE; CI #42931723587 SUCCESS. No repetir los 25 como nuevos objetos.

OBJETIVO: desbloquear primero las tres bolas cuya fuente podría venir del catálogo de especie sin un evento artificial de mapa: heavy_ball, moon_ball, beast_ball. No inventar productor para ninguna.

FASE A — DATOS AUTÉNTICOS:
- Heavy Ball: comprobar peso de forma activa en PokeAPI local (peso en hectogramos) y posibilidad REAL de alcanzarlo desde CreatureSpecies.source_metadata o DefinitionCatalog en runtime; no existe propiedad explícita weight en CreatureSpecies. Si falta el seam en runtime, ticket y L2 solamente, sin inventar valor.
- Moon Ball: recorrer EvolutionRecord y Stone canon para especies que evolucionan con Piedra Lunar; contrastar forma/version_group con fuente real, no decidir por nombre.
- Beast Ball: buscar clasificación Ultraente real en fuente; no confundir legendario con Ultraente, ni inventar whitelist.
Validar negativas, datos ausentes, especie equivocada y política Randomlock.

FASE B — DISPATCH Y PRUEBAS:
Solo SI el productor se deriva de un estado autoritativo existente, IA6 autoriza campos aditivos y validados en CaptureBattleContext, registro de ID en CaptureRuleset y cálculo específico en CaptureContextBallEffects, siempre limitado a heavy/moon/beast. Modificar showdown_adventure_session.gd::capture SOLO para proyectar esos datos; preservar tasas RNG, el ledger, Repeat y Net. Fuente de reglas exacta versionada; Heavy puede requerir tasa/offset en vez de multiplicador, no falsearlo. Test positivo Godot/Showdown real de fuente, consumo, owner, captura, SaveV2 y negativo.
FASE C — RESTO DE CONTEXTO:
Crear un solo ticket por productor mundo para Dive/Dusk/Lure/Love y zona Safari/Sport, sin cambiar reloj, mapas, pesca o sexo. Reproducir Magikarp L5 move_policy como defecto independiente antes del lanzamiento, sin editar contenido global. Preservar regresiones W03 T01–05, V2, CAMP003–006 y campo. CI final y reports/W03/CONTINUOUS_V3_FINAL.md separando L2/L3/blocked.

PERMISOS: nuevos helpers y tests W03; CaptureBattleContext solo campos aditivos de esos tres IDs, CaptureRuleset y CaptureContextBallEffects SOLO esas tres ramas, showdown_adventure_session.gd::capture SOLO contexto específico probado. PROHIBIDO FieldItemBag, CreatureInstance, PlayerCollection, SaveV2 central, RNG, native_engine, mundo/reloj/pesca/sexo, cualquier otra bola, main/V28/PR118 y otras ramas. Si falta productor o contrato canónico, marcar BLOCKED_CONTEXT y continuar fase independiente. No inventar un bucle interminable de auditorías.

Campaña continua sin STOP tras 10. Checkpoint CONTINUOUS_V3/STATE_W03.md; p/sigue continúa hasta agotar backlog. Nuevas bolas L3 solo si ruta de producción completa y CI SHA real; integración IA6 NO hasta su propia CI.
