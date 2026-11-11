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