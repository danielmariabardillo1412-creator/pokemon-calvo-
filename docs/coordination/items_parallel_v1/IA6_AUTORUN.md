# IA6 — RELEVO DIRECTO 12-11-2026 · W04 · PRÓXIMA p

**Esta rama histórica ya está cerrada y los relevos V3/V4/V5 previos que se leen más abajo son HISTÓRICOS Y ESTÁN SUPERADOS.** IA6 ha entregado una nueva misión funcional en rama exclusiva `codex/calvo-items-20261112-w04-evolution-consumer-v6`.

**PRÓXIMA `p`:** guardar/publicar cambios locales pendientes de esta rama si los hubiera; después cambiar directamente a `codex/calvo-items-20261112-w04-evolution-consumer-v6`, abrir allí `docs/coordination/items_parallel_v1/IA6_AUTORUN.md` y `docs/coordination/items_parallel_v1/CONTINUOUS_V6/STATE_W04.md`, iniciar fase A y seguir A→B→C. No repetir bloques anteriores ni pedir otra autorización por cada diez. La rama antigua NO se modifica en código, IA6 oficial/main/V28/PR118 son solo lectura. Las CI anteriores no acreditan la misión nueva.

---

# IA6 — W04 · SALTO DIRECTO A NUEVA MISIÓN V5 (2026-11-11)

La V3 de esta rama histórica y la V4 de staging `codex/calvo-ia6-staging-20261111-w04-evolution` ya terminaron. **No repetir ni V3 ni V4.** La entrega V4 está pendiente de integración central por IA6.

**PRÓXIMA `p`:** comprobar y publicar cualquier cambio local no subido; con working tree limpio, cambiar a la rama NUEVA exclusiva `codex/calvo-items-20261111-w04-regional-level-v5`; leer allí `docs/coordination/items_parallel_v1/IA6_AUTORUN.md` y `CONTINUOUS_V5/STATE_W04.md`; ejecutar inmediatamente fase A de evoluciones regionales por nivel y continuar A→B→C sin solicitar otra tanda. No modificar `main`, V28, PR118, ramas ajenas ni integración oficial.

---

# IA6 — V4 STAGING ACTIVA · W04 · 2026-11-11
**Tu misión histórica V3 ha cerrado READY_FOR_IA6 y fue verificada por IA6.** No repetir QA ni empezar otra tanda en ESTA rama histórica. **IA6 ya creó una RAMA NUEVA EXCLUSIVA**: codex/calvo-ia6-staging-20261111-w04-evolution; el plan completo está en docs/coordination/items_parallel_v1/IA6_AUTORUN.md de ESA rama y el estado en docs/coordination/items_parallel_v1/CONTINUOUS_V4/STATE_W04.md. En la siguiente p: conservar el working tree original y comprobar que no hay modificaciones sin subir; cambiar a la staging asignada, leer allí IA6_AUTORUN.md y empezar fase A, B, C sin STOP cada diez. No modificar la rama oficial codex/calvo-ia6-integration-20261109, main, V28 ni PR118. La CI de V3 no certifica la staging.

---

# IA6 — VETO CARAMELO DINAMAX / dinamax_candy — 2026-11-11

**ORDEN VINCULANTE A W04:** el usuario descartó `dynamax_candy`. Ya está en `config/item_selection_v1.json::excluded_ids` de TU rama y el test de política exige rechazo de generación. No seleccionarlo, no incluirlo en nuevas colas de objetos ni invertir trabajo en su arte/función; los CSV antiguos `CANDIDATE`/`RETAIN_FOR_FUNCTIONAL_REVIEW` son auditorías HISTÓRICAS, no autorización. Excluye solo este ítem, no Rare Candy/Exp Candy/otras mecánicas no discutidas. Dictamen completo en rama árbitra: `docs/coordination/items_parallel_v1/IA6_EXCLUSION_DYNAMAX_CANDY_20261111.md`. El resto de TU plan continuo sigue vigente.

---

# IA6 — W04 · CAMPAÑA CONTINUA V3 AUTORIZADA

**IA6 REVISÓ TU CAMPAÑA V2 Y TE ASIGNA ESTA NUEVA MISIÓN, NO ESTÁS EN ESPERA.** El archivo que estás leyendo en TU propia rama `codex/calvo-items-20261104-w04-camp006` es la orden vigente. El plan V2 anterior está agotado y se conserva en GitHub para trazabilidad; **NO repetir IDs o pruebas certificadas de V2**. La misión V3 tiene tres fases y no termina artificialmente al completar 10/10. Cada `p`/`sigue` recupera `docs/coordination/items_parallel_v1/CONTINUOUS_V3/STATE_W04.md` y reanuda la primera fase/tarea pendiente; al finalizar una fase con CI correcta empieza inmediatamente la siguiente sin esperar a IA6, en el mismo turno si es posible.

**Autoridad y política:** protocolo árbitra `docs/coordination/items_parallel_v1/CONTINUOUS_V3/README.md`, plan central `docs/coordination/items_parallel_v1/CONTINUOUS_V3/PLAN_W04.md`, rama árbitra `codex/calvo-items-20261101-arbitro`. La copia íntegra del plan está debajo. Esta autorización es expresa para los módulos/funciones enumerados, pero NO permite cambios globales ajenos, ni tocar `main`, V28, PR118, ni ramas de otras W. No atribuir CI a SHA distinta ni integración final a IA6 sin ver su CI. Si todas las fases posibles se agotan o dependen de seam protegida, publicar READY_FOR_IA6 con ticket real y STOP. Si el turno se agota antes, checkpoint GitHub y siguiente `p`, sin otra autorización ni promesa de background.

**Barra correcta:** campaña fase A/B/C + tareas | objetos nuevos | L3 comprobados | bloqueados | integración IA6 pendiente. **No usar 10/10 como sinónimo de 10 objetos.**

---

# IA6 W04 · CAMPAÑA CONTINUA V3 — 7 evoluciones regionales L3
Rama: codex/calvo-items-20261104-w04-camp006.
Baseline: V2 completada; 57 especies regionales, 28 EvolutionRecord y 7 rutas use_item L2, CERO L3, CI #42945615987 SUCCESS. No volver a contar los mismos contratos como objetos nuevos.

AUTORIZACIÓN EXCEPCIONAL IA6 EN RAMA EXCLUSIVA W04: se permite editar SOLO EvolutionSystem.apply_evolution y FieldItemService.evolve / evolution_options para garantizar identidad de forma de DESTINO y consumo real en estas siete rutas concretas:
- darumaka_galar + ice_stone → darmanitan_galar_standard
- growlithe_hisui + fire_stone → arcanine_hisui
- sandshrew_alola + ice_stone → sandslash_alola
- slowpoke_galar + galarica_cuff → slowbro_galar
- slowpoke_galar + galarica_wreath → slowking_galar
- voltorb_hisui + leaf_stone → electrode_hisui
- vulpix_alola + ice_stone → ninetales_alola

FASE A: demostrar en prueba roja la pérdida actual de form_id al evolucionar; validar cada EvolutionRecord, forma de origen y destino, política, ítem. No recrear el destino directamente con Factory y decir que ha evolucionado. Conservar evolución normal y DATA_ONLY.
FASE B: resolver form_id destino desde metadatos canónicos, NUNCA copiar forma del origen. FieldItemService.evolve debe verificar especie+forma+ítem y propietario antes del gasto, reemplazar una sola vez con instance_id estable y rollback ante error. Probar las siete con Party/Storage, stock, SaveV2, negativos de forma/target/item/sesión; ambos Galarica ensayados por separado.
FASE C: regresiones de 55/56 formas, Exeggutor Alola bloqueada sin Harvest oculta, rutas estándar y CAMP003–006. CI con SHA funcional, report reports/W04/CONTINUOUS_V3_FINAL.md. Distinguir L2 de L3 y mantener integración IA6 como pendiente.

PROTECCIONES: editar solo las funciones citadas y helpers/tests/workflow W04. CreatureInstance, SaveGameData, FieldNativeSave, PlayerCollection, Factory, catálogos, Showdown, FieldItemBag y ramas ajenas SOLO LECTURA. El esquema W04 puede carecer del effective_nature_id de W02: NO falsificar integración conjunta. IA6 trasplantará por función sin merge a ciegas.
OPERACIÓN: fases continuas sin STOP por diez hitos, checkpoints en STATE_W04.md, p/sigue reanuda automáticamente. Si una ruta requiere otro módulo protegido, ticket y siguiente ruta independiente, nunca afirmar L3 falso. No main/V28/PR118 ni cambios fuera de autorización. Al agotar READY_FOR_IA6.
