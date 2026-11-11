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