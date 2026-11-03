# IA3/W03 — CAMPAÑA_005 / BLOQUE 05 — Safari Ball y Sport Ball

**Rama exclusiva:** `codex/calvo-items-20261103-w03-camp005`. **Backlog:** `safari_ball;sport_ball`, no contar como objetos nuevos.

## Hallazgo funcional relevante

En `modules/capture/capture_ball_effects.gd`, ambas bolas están en `BallEffects.IDS` y comparten la rama `&"safari_ball", &"sport_ball": return 1.5`. `CaptureRuleset._init()` registra esas definiciones y `CaptureSystem.resolve()` multiplica la probabilidad con `BallEffects.multiplier`. **Su efecto básico de captura ×1,5 sí existe y funciona en el motor actual.** No hay que volver a calificarlas como bolas genéricamente desconectadas.

**Defecto/decisión pendiente:** el efecto no examina `CaptureBattleContext` ni se restringe por mapa, zona Safari, Concurso Bicho o modalidad. `ShowdownAdventureSession.capture()` construye el contexto a partir de batalla, turno y nivel, pero no produce `is_safari_zone`, `safari_capture_mode`, `is_bug_contest_zone` o `contest_capture_mode`. Se aplica ×1,5 incluso cuando no existe una fuente de zona especial. No está autorizado elegir unilateralmente si la campaña debe conservar ambas bolas como objetos genéricos o reservarlas para actividades especiales.

## Dependencias de integración para IA6

| Objeto | Productor faltante | Consumidor | Decisión necesaria |
|---|---|---|---|
| `safari_ball` | Propietario de zona Safari, modo de captura y perfil de reglas versionado | Sesión → `CaptureBattleContext` → validador/efecto de captura | ¿Permitir uso general con ×1,5 o solo zona/modo Safari? ¿Qué ocurre al intentar usarla fuera? |
| `sport_ball` | Propietario de evento Concurso Bicho, modo activo y perfil versionado | Misma frontera de captura | ¿Mantener efecto universal o restringir al concurso? ¿Quién emite y valida el contexto, incluso tras cargar partida? |

**Importante:** una eventual restricción requiere validación antes de consumir una bola o RNG. El productor de zona deberá ser autoritativo en sesiones/multijugador, no un booleano controlado por el cliente. Tampoco debe reutilizarse `is_wild` como sustituto de una zona especial.

## Nuevas pruebas, sin repetir auditoría CAMP004

- Godot `_block_05`: verifica catálogo y selección, definición de bola en `CaptureRuleset`, validación de captura permitida, multiplicador **real** ×1,5 sobre Caterpie, comparación positiva de probabilidad frente a ×1, integridad del Pokémon original e introspección de ausencia de señales de zona.
- Python: localiza la rama exacta de multiplicador, la conexión real al motor de captura, el consumidor/constructor de contexto y las decisiones precisas sobre uso fuera de zona.
- **Regresión obligatoria del hito 05:** workflow de IA6 ejecuta CAMPAÑA_004 W03 y CAMPAÑA_003 W03 completas, además de la nueva suite CAMP005, Python y Godot.

**Estado:** `PARTIAL_EXISTING_EFFECT_UNGATED`. El factor ×1,5 es funcional; **no se certifica** validación de zona Safari/Concurso Bicho. No se modificó código de producción, políticas, fórmulas, guardado, `main`, V28, PR #118 ni ramas ajenas.

## CI

Requiere `CAMP005_W03_PY PASS blocks=5`, `CAMP005_W03_GODOT PASS blocks=5`, gates IA6 y regresiones CAMP004/CAMP003 PASS sobre SHA final con cinco filas en progreso. No declarar PASS sin leer los recibos.
