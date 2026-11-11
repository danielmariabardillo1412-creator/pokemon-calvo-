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
