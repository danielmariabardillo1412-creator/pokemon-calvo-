# ORDEN IA6 — RELEVO DIRECTO W03 A V7 · 2026-11-12 · VIGENTE Y PRIORITARIA

**ANTERIOR V6 TERMINADA.** CI V6 #43125138000 SUCCESS para Dusk en cueva; 0 integración V7. No repetir V6; sus pruebas no certifican la nueva campaña. IA6 ha publicado orden con trabajo funcional pendiente.

**SIGUIENTE `p` O `sigue`:** confirmar los cambios locales publicados/working tree limpio; cambiar a RAMA NUEVA EXCLUSIVA `codex/calvo-items-20261112-w03-black-white-flutes-v7`; abrir allí `docs/coordination/items_parallel_v1/IA6_AUTORUN.md` y `docs/coordination/items_parallel_v1/CONTINUOUS_V7/STATE_W03.md`. Ejecutar Fase A inmediatamente y continuar A→B→C con las autorizaciones de ese plan. No trabajar en ESTA V6, en IA6 oficial, main/V28/PR118 ni otra rama W.

---

# IA6 — W03 · NUEVA MISIÓN ACTIVA · 12-11-2026

**Rama ÚNICA NUEVA:** `codex/calvo-items-20261112-w03-dusk-cave-v6`.
**ANTERIOR:** W03 V5 (capturas/repelentes ya integrados y CI oficiales) . No repetir hitos cerrados ni reutilizar su CI como certificación de esta misión.
**SIGUIENTE `p`:** FASE A: demostrar con prueba roja Dusk Ball en cueva frente a hierba, trazando FieldDemo → Showdown → CaptureBattleContext.
**TRABAJO FUNCIONAL:** Dusk Ball en cueva real: emisión contexto de zona desde productor nativo y captura con multiplicador sin inventar.
**CHECKPOINT:** `docs/coordination/items_parallel_v1/CONTINUOUS_V6/STATE_W03.md`. Plan de autoridad IA6: `docs/coordination/items_parallel_v1/CONTINUOUS_V6/PLAN_W03.md` en `codex/calvo-items-20261101-arbitro`.
**AUTONOMÍA:** ejecutar A→B→C en varios `p`, sin STOP artificial por bloques. Respetar literalmente permisos de rutas, conservar `dynamax_candy` excluido y no editar IA6 oficial, main/V28/PR118 ni ramas ajenas. Una `p` no ejecuta IA en segundo plano.

---

# IA6 / W03 — CONTINUOUS_V6 · BOLA OCASO REAL EN CUEVA
**Autorizado: 2026-11-12 · Ejecutar desde la próxima `p` en rama exclusiva** `codex/calvo-items-20261112-w03-dusk-cave-v6`.
**Origen de código:** rama oficial IA6 `codex/calvo-ia6-integration-20261109` a SHA `ddc8a1af56c5fe7e950bee5bf3986d8e62261f8f`. Ese árbol **ya integra** Repeat/Net/Moon/repelentes/libros/Cuerda, CI oficiales #43106031155 y #43106031150 SUCCESS. NO trasladar otra vez ramas W03 V4/V5 ni escribir en oficial, main, V28, PR118 u otras W.

## Objeto nuevo en el backlog: `dusk_ball` (ya seleccionado en los 24 BALL; 0 nuevos ID de catálogo)
A diferencia de otros bloqueos W03, el juego técnico tiene una **cueva física** (`technical_cave_floor`) y una zona de hierba (`technical_grass`). Intentar habilitar Bola Ocaso **solo si** el productor REAL de la zona atraviesa FieldDemo/FieldNativeBridge y se puede reconstruir desde la sesión de captura auténtica. No inventar bandera manual `is_cave=true` en harness ni desde UI, comandos o SaveV2; zona incorrecta/desconocida rechaza o aplica multiplicador normal, sin bonificación.
- V6 A: inspeccionar la ruta nativa `field_prepare_native_encounter(zone_id)` → `field_native_bridge` → sesión Showdown → `CaptureBattleContext` → `CaptureSystem`. Mostrar RED real de `dusk_ball` de cueva frente a hierba con la misma especie, nivel, PS, status y RNG; distinguir suma de metadatos del efecto aplicado. Consultar `CaptureRuleset`, fuentes locales fijadas para el factor por generación (para juego gen7+ usar x3 **solo si** respaldado por fuente interna), y casos de contexto faltante.
- V6 B: implementar **mínimo adaptador auténtico** para conservar zona de encuentro REAL hasta la captura sin dar permisos a UI para mentir. Permiso nuevo SOLO EN ESTA STAGING para hunks estrechos en productor de zona `scenes/visual/field_demo.gd`, apertura/captura `scenes/visual/field_native_bridge.gd` y `modules/gameplay/showdown_adventure_session.gd` si son imprescindibles, y para `modules/capture/capture_battle_context.gd`, `modules/capture/capture_context_ball_effects.gd`, `capture_ruleset.gd` / helpers de captura W03 exclusivamente. No modificar otras funciones de esos módulos. El test positivo debe usar el juego técnico real, combate nativo y `capture(ball_id,..)` real, comparar multiplicador y captura determinista/consumo/propiedad/SaveV2. Probar además hierba (sin bono), ausencia/invalidación del productor, objetivo cambiado, cierre/reapertura, trainer no capturable, intento fallido, stock y RNG. NO habilitar Dive/Lure/Heavy/Beast/Love ni un supuesto reloj nocturno sin productores.
- V6 C: CI Godot 4.7 + Python sobre SHA exacto, regresiones oficiales W03 captura 37 Repeat legacy, Repeat/Net/Moon nativa, 3 repelentes L3 y unión libros+Rope+menta+SaveV2. Si suites ausentes, **NO PROBADO**, no declarar PASS. Registrar hunks y eventual conflicto con IA6 `showdown_adventure_session.gd`; IA6 integrará selectivamente, NO merge completo.
- Si el camino de zona no puede propagarse sin tocar una API compartida protegida distinta de los hunks autorizados, registrar ticket bloqueante y hacer la mínima prueba roja completa; no fabricar un PASS. En ese caso entregar una matriz de fuentes (Dusk/cueva vs Dive/agua, Lure/pesca, Love/género, Heavy/peso, Beast/clase Ultraente), sin convertirla en falsa funcionalidad; pedir permiso IA6 para ruta exacta.
- Escribir `CONTINUOUS_V6/STATE_W03.md`, `reports/W03/CONTINUOUS_V6_FINAL.md` si éxito y CI URL/SHA. Métrica: **dusk_ball L3 (0/1 hasta prueba)**, regresiones, otro ID implementado 0, integración IA6 NO. No rondas de QA vacías. Una `p` continúa A→B→C y no pide nueva autorización entre microbloques; detener solo al terminar o por bloqueo real documentado.

## Invariantes
Mantener `dynamax_candy` excluido, historia de capturas y ledger, propiedad, Party/Storage, SaveV2 legacy y corrupto, semilla de RNG y gestor de combates. No sobrescribir la mochila de W05 ni la lógica de repeles W03 oficial. Sin cambios de reglas generales de captura o Showdown JS. IA6 asume la integración posterior.

