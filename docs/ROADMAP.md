# Pokémon Calvo — Roadmap por dependencias

Fecha: 2026-08-30  
Baseline funcional validado: **FASE 18 — Battle Run Presentation V1**  
Estado de este documento: **PLANNING / no autoriza por sí solo una nueva fase**

Este roadmap no numera trabajo futuro por inercia. Ordena fronteras según dependencias reales del código actual y distingue entre una recomendación técnica y una fase ya aprobada/abierta.

## Principio de planificación

El baseline actual ya demuestra:

`Overworld -> encounter -> Battle -> MOVE / CAPTURE / SWITCH / RUN -> settlement -> confirmación -> Overworld`

El siguiente trabajo no debe reimplementar esos sistemas ni saltar prematuramente a assets finales. La prioridad es cerrar agujeros de flujo donde el dominio ya produce una decisión que la capa de aplicación/presentación todavía puede perder o ignorar.

## Próxima frontera recomendada — Post-Battle Progression Flow

**Estado: RECOMENDADA, NO ABIERTA.**

### Por qué va primero

`ProgressionSystem.reconcile_battle_result()` ya puede emitir:

- `EXPERIENCE_GAINED`;
- `LEVEL_UP`;
- `STAT_CHANGED`;
- `MOVE_LEARNED`;
- `MOVE_LEARN_CHOICE_REQUIRED`;
- `EVOLUTION_AVAILABLE`.

Sin embargo, el settlement actual devuelve esos eventos al caller y `BattlePresentationController` solo registra `Victory. Progression has been reconciled.`. No existe una cola persistente de decisiones post-battle ni una UX que obligue a resolver `MOVE_LEARN_CHOICE_REQUIRED`/`EVOLUTION_AVAILABLE` antes de abandonar la pantalla.

Eso significa que el dominio sabe que hay una elección, pero el flujo jugable todavía no la convierte en una decisión del jugador. Es una frontera de corrección de aplicación, no un problema cosmético.

### Subbloque A — Progression Decision Queue V1

Objetivo: formalizar la semántica de decisiones post-battle antes de dibujar botones.

Debe definir:

- dónde viven los `ProgressionEvent` pendientes tras settlement;
- cuáles son informativos y cuáles requieren decisión;
- contrato canónico para `MOVE_LEARN_CHOICE_REQUIRED` (`LEARN`, `REPLACE`, `DECLINE`);
- contrato canónico para evolución (`ACCEPT`, `DECLINE`) sin confiar en species forjada;
- orden determinista si aparecen varias decisiones;
- qué ocurre con Continue mientras existen decisiones obligatorias;
- política de Save: o bien serializar pendientes o bloquear guardado hasta resolverlos; nunca perderlos silenciosamente;
- reset/lifecycle entre encuentros;
- tests adversariales de identidad, orden, rechazo sin mutación y reapertura.

No debe añadir UI final ni rediseñar `ProgressionSystem` si sus primitivas existentes bastan.

### Subbloque B — Progression Presentation V1

Solo después del contrato anterior.

Debe presentar:

- XP/level-up y cambios de stats;
- movimiento aprendido automáticamente cuando hay hueco;
- selector explícito cuando hay que reemplazar/declinar movimiento;
- oferta de evolución y aceptar/declinar;
- bloqueo de `Return to overworld` mientras quede una decisión requerida;
- retorno al Overworld únicamente cuando el estado de aplicación esté resuelto.

La UI debe consumir el contrato de aplicación, no manipular directamente moveset/species.

## Fronteras posteriores candidatas

El orden exacto entre estas líneas se revisará después de cerrar Progression Flow:

### Battle Bag / consumibles

Hoy Capture expone balls, pero no existe un Bag general de combate. Antes de UI debe existir semántica de comando para objetos consumibles: target válido, ownership, consumo, prioridad/turno, respuesta rival, fracaso transaccional y efectos soportados. La mayoría de items importados siguen siendo DATA_ONLY, por lo que el alcance debe empezar pequeño y explícito.

### Forced Switch Choice

El reemplazo tras KO es automático. Una elección manual requiere cambiar la máquina de estados/contrato de Battle para representar `replacement_required`; no debe fingirse como un simple selector visual.

### Party / Storage / Save Presentation

El dominio y Savegame V2 existen, pero falta UX para revisar party, depositar/retirar, inspeccionar storage y guardar/cargar. Debe respetar identidad única, transacciones y restricciones de save durante estados transitorios.

### Overworld state y navegación real

Antes del mapa romano final hacen falta contratos para:

- cambios de mapa/puertas;
- posición y world-state persistente;
- NPCs/interacción/diálogo;
- triggers no-encounter;
- recuperación segura después de load.

Estos sistemas deben mantenerse desacoplados de los assets definitivos.

### Trainer Battles

Requieren lifecycle propio: ownership rival, reglas de captura prohibida, política de huida, recompensas/progresión, party rival y finalización. No deben implementarse reutilizando por accidente semánticas exclusivas de `WildAdventureSession`.

### Cobertura mecánica

Ampliar moves/abilities/items/forms/evoluciones especiales debe hacerse por familias de mecánicas con datos estructurados + handlers + tests, no por parsing de `effect_summary` ni por un listado de excepciones sin contrato.

### Producción visual/audio y assets locales

Sprites, tilesets, animaciones, VFX, audio y mapa romano final se integrarán cuando los loops que representan estén estables. La biblioteca pesada local no debe convertirse en dependencia de CI; GitHub conserva código, datos mínimos y fixtures verificables.

## Gates permanentes para cualquier bloque nuevo

Todo bloque futuro debe:

- partir de un HEAD validado y documentar su base exacta;
- vivir en rama propia; no merge a `main` sin autorización explícita;
- auditar primero el contrato existente y comparar alternativas;
- añadir tests del caso feliz y adversariales;
- conservar todos los gates históricos relevantes;
- usar mínimos (`>= N PASS / 0 FAIL`) en CI cuando futuras fases puedan añadir checks;
- ejecutar GitHub Actions sobre el HEAD final de código + documentación;
- registrar run/job/artifact y defectos encontrados;
- cerrar el PR sin merge si se mantiene la estrategia stacked;
- actualizar `STATUS.md` y este roadmap cuando cambie la frontera real.

## No aprobado todavía

No existe una `FASE 19` oficial en este documento. El nombre/número de la siguiente fase se fija únicamente después de auditar el diseño del **Post-Battle Progression Flow** y definir un alcance cerrado con tests y stop conditions.