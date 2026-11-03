# IA3/W03 — CAMPAÑA_003, microbloque 08/10

**IDs de la cola oficial:** `luxury_ball;lure_ball`. **Alcance:** auditoría y regresión de rechazo seguro, NO implementación funcional.

## Diagnóstico comprobado en la rama W03

- `CaptureRuleset` incluye bolas base y los registros de `CaptureBallEffects`/`CaptureContextBallEffects`; `luxury_ball` y `lure_ball` no figuran en ellos.
- `CaptureSystem.validate_attempt` devuelve `unknown_ball` para IDs sin definición, antes del gasto en `CaptureInventoryService`.
- Lujo Ball necesita conservar la bola de origen para el crecimiento **futuro** de amistad. No se ha localizado un contrato autorizado de persistencia/consumo de esa información.
- Cebo Ball necesita una señal de encuentro por pesca procedente de la sesión real; `CaptureBattleContext` solo transporta naturaleza del combate, turnos y nivel del capturador. **No existe señal verificada de pesca**.

## Pruebas nuevas y límites

Suite acumulativa 01–08; se conservan los bloques previos. Fixture añade dos especies reales (Mew/Caterpie), PS completos/1, dos combinaciones de contexto sin inventar pesca. Runner Godot llama al sistema real para cada bola y comprueba `INVALID/unknown_ball`, sin gasto, cambio de criatura, captura, tirada RNG ni modificación del equipo. Python valida las fuentes de producción, la inexistencia del registro/contexto, los IDs y la presencia del test real; falla si cambia el contrato, para exigir reauditoría.

**Resultado interpretativo:** cualquier `PASS` de esta iteración acredita solo el rechazo seguro de estas bolas **todavía no operativas**, jamás el bono de amistad ni pesca. No se han modificado `modules/`, `main`, V28, workflows ni ramas ajenas. Se requiere IA6 únicamente para la frontera de integración: origen de bola y persistencia SaveV2, fuente fiable de pesca en ambas sesiones, reanudación tras cargar, y condiciones sin consumo para contexto no disponible.

**CI:** publicación por el CSV de progreso; pendiente comprobar el run de rama W03 sobre el SHA con tests y fixture. No afirmar PASS antes de revisar Python y Godot del mismo commit. Siguiente `p`: bloque 09, solo si cumple gate de CI o es independiente.
