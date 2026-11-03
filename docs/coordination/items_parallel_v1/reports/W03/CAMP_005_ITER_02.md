# IA3/W03 — CAMPAÑA_005, bloque 02 — Luxury Ball y Lure Ball

**Rama exclusiva:** `codex/calvo-items-20261103-w03-camp005`. **Backlog**, no dos objetos nuevos. Cola oficial: `luxury_ball;lure_ball`.

## Diagnóstico nuevo: Luxury Ball

La ruta existente `CaptureSystem.resolve()` invoca `CaptureBallEffects.on_catch()` **solo al capturar**, conservando identidad de criatura. Sin embargo, `CreatureInstance` **no dispone de `original_capture_ball_id`** ni lo guarda en `to_dict/from_dict`. Su `friendship` sí persiste. `FieldFriendshipEffects.increase()` implementa ganancia base por tramo y Campana Alivio, pero no un bonus por bola de origen; tampoco debe confundirse ese origen con `held_item_id`.

**Productor faltante:** la transacción exitosa de captura debe publicar la bola de origen en un campo persistente de criatura con validación y serialización. **Consumidor:** el cálculo de ganancias futuras de amistad en `FieldFriendshipEffects.increase()`, además de otros productores de amistad que IA6 considere. **Decisiones requeridas:** regla/versionado del factor Luxury, interacción y orden con Campana Alivio, migración de criaturas antiguas y SaveV2. Insertar un factor en el momento de captura sería incorrecto: Luxury mejora ganancias posteriores y no equivale a Friend Ball que fija amistad al capturar.

## Diagnóstico nuevo: Lure Ball

`ShowdownAdventureSession.capture()` crea un `CaptureBattleContext` con turno y nivel, pero no incluye origen por pesca. `CaptureBattleContext` carece de `encounter_method` y `fishing_provenance`. `WildEncounterSystem` produce especies desde tablas de zona, pero no entrega a la captura un contrato autenticado de caña/pesca. No es correcto inferir pesca por ser de tipo Agua, por la especie o por encontrarse cerca del agua.

**Productor faltante:** controlador de encuentros en el mundo que certifique `encounter_method=fishing` y la procedencia de la caña al abrir la batalla. **Consumidor:** `ShowdownAdventureSession.capture → CaptureBattleContext → CaptureSystem`. **Decisiones requeridas:** regla de bonificación/versionado, fuente autoritativa de origen, sesión/restauración y protección frente a datos arbitrarios del cliente.

## Evidencia nueva y alcance

El runner `tests/gameplay/parallel_items_w03_campaign_005.gd` bloque 02 prueba **positivamente** `FieldFriendshipEffects.increase()` con amistad inicial 0 y `[5,3,2]`: +5 sin objeto equipado y +7 con Campana Alivio, sin modificar el Pokémon original. Verifica un roundtrip `CreatureInstance.from_dict(to_dict())` de identidad y amistad; inspecciona los metadatos que faltan en criatura y contexto. Python rastrea `CaptureSystem.resolve/on_catch`, `FieldFriendshipEffects`, guardado de criatura, ausencia de fuente de pesca y propuesta de contratos por ID; **no repite matrices de `unknown_ball`**.

**Resultado por ambos IDs: `DEPENDENCIA_CONCRETA`.** Los positivos corresponden a la mecánica de amistad ya presente, **no** demuestran Luxury Ball funcional. Tampoco se ha activado Lure Ball. La serialización de criatura existente no acredita migración SaveV2 ni persistencia de nuevos metadatos.

### Bloqueo de integración a IA6

Hace falta propietario de metadatos de criatura y SaveV2 (para Luxury) y del origen de pesca con sesión/encuentro (para Lure). W03 puede integrar sus reglas dentro de `modules/capture/` cuando los productores y decisiones estén aprobados, pero no debe cambiar sistemas compartidos ni política global unilateralmente.

No se ha alterado código de producción, `main`, V28, PR #118, catálogos, workflows ni ramas ajenas. CI Godot/Python pendiente de confirmación en el SHA final del progreso.
