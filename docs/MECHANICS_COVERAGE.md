# Pokémon Calvo — Mechanics Coverage

Fecha de sincronización: 2026-08-30  
Dataset: PokéAPI `api-data` @ `784c50b3ad27d0390d3b047fc4c4511f71edd049` (BSD 3-Clause)  
Runtime baseline: FASE 18 / `calvo_v1` + `calvo_capture_v1` + `calvo_escape_v1`

Este documento separa **datos disponibles** de **gameplay realmente ejecutable**. Importar una definición o conservar `effect_summary` no equivale a soportar su mecánica.

## Terminología

| Label | Significado |
|---|---|
| `DATA_READY` | El dato está importado/modelado y puede ser consumido por runtime futuro. |
| `RUNTIME_SUPPORTED` | El comportamiento reclamado para ese ID está ejecutado por runtime y cubierto por tests. |
| `PARTIAL_RUNTIME` | Parte del comportamiento funciona pero quedan efectos/condiciones sin modelar. |
| `DATA_ONLY` | La definición existe, pero no tiene comportamiento de gameplay completo. |
| `UNSUPPORTED` | El modelo/runtime actual no puede representar o ejecutar esa mecánica. |

## Dataset importado

| Categoría | Cantidad |
|---|---:|
| Species base | 986 |
| Forms diferidas | 39 |
| Types | 21 |
| Moves | 937 |
| Abilities | 373 |
| Items | 2222 |
| Learnset entries | 129390 |
| Imported evolution edges | 476 |
| Broken references | 0 |
| Rejected entries | 0 |

PokéAPI no aporta status conditions utilizables en el snapshot fijado; los status canónicos del ruleset se modelan internamente.

## Moves — 937 DATA_READY

Cobertura actual documentada por FASE 5:

| Cobertura | Cantidad |
|---|---:|
| `RUNTIME_SUPPORTED` | 541 |
| `PARTIAL_RUNTIME` | 60 |
| `DATA_ONLY` | 327 |
| `UNSUPPORTED` | 9 |
| **TOTAL** | **937** |

Los effects soportados se derivan de metadata estructurada / `BattleEffectSpec` y mappings explícitos. Nunca se ejecuta `effect_summary` como reglas.

Detalle: `MOVE_EFFECT_COVERAGE.md` y ADR-004.

## Abilities — 373 DATA_READY

| Cobertura | Cantidad |
|---|---:|
| `RUNTIME_SUPPORTED` | 6 |
| `DATA_ONLY` | 367 |

Runtime soportado explícitamente: `blaze`, `intimidate`, `levitate`, `overgrow`, `static`, `torrent`.

No se debe asumir que una ability importada funciona por estar presente en la especie.

## Items — 2222 DATA_READY

| Cobertura | Cantidad |
|---|---:|
| held-item runtime soportado | 2 |
| resto importado / sin comportamiento general completo | 2220 |

Held items soportados actualmente: `leftovers`, `sitrus_berry`.

Además, Capture usa definiciones de ball propias del ruleset (`poke_ball`, `great_ball`, `ultra_ball`, `master_ball`) y el inventario controla ownership/cantidad. Esto **no** significa que exista un sistema general de Bag/consumibles de Battle para los otros miles de items.

## Status

IDs internos principales:

- burn;
- poison;
- badly_poisoned;
- paralysis;
- sleep;
- freeze;
- flinch/confusion como estado volátil donde corresponde.

Burn, poison, badly poisoned, paralysis y sleep tienen comportamiento probado. Freeze permanece parcial en el conjunto actual de moves y confusion no constituye todavía una implementación completa de la mecánica oficial.

## Evolutions — 476 imported edges

Cobertura runtime de Progression Core:

| Cobertura | Cantidad |
|---|---:|
| `RUNTIME_SUPPORTED` | 464 |
| `DATA_ONLY` | 9 |
| `UNSUPPORTED` | 3 |
| **TOTAL** | **476** |

Los 464 runtime-supported incluyen triggers representados por level-up, trade y use-item según el contrato actual. Permanecen diferidos triggers especiales y las forms excluidas por la política de importación.

Detalle: `EVOLUTION_COVERAGE.md`.

## Forms

39 formas regionales/alternativas/mega/gigantamax/totem/cosméticas están diferidas por la política actual. El catálogo runtime contiene la variedad base/default y mantiene integridad referencial; no se afirma soporte de esas forms.

## Progresión

Soportado en dominio:

- seis curvas de XP;
- level cap 100;
- IV/EV/naturalezas;
- recálculo de stats;
- learnsets y moveset individual con PP;
- eventos de level-up/aprendizaje;
- `MOVE_LEARN_CHOICE_REQUIRED`;
- `EVOLUTION_AVAILABLE`;
- aplicación validada de evolución preservando identidad.

**Pendiente de flujo jugador completo:** las decisiones de reemplazar/declinar movimiento y aceptar/declinar evolución no tienen todavía cola de aplicación + presentación que garantice su resolución antes de volver al Overworld. Ver `ROADMAP.md`.

## Capture

`calvo_capture_v1` está ejecutado y probado:

- capture rate de especie;
- Poke/Great/Ultra/Master Ball;
- bonus de status;
- HP factor;
- trainer target rechazado;
- Master Ball garantizada sin RNG probabilístico;
- fracaso consume ball y, desde Battle Commands, provoca exactamente una respuesta rival;
- éxito conserva la misma `CreatureInstance` y enruta a Party/Storage;
- Party llena -> Storage;
- UI técnica lista balls realmente poseídas.

Esto no equivale a Bag general ni economía/tiendas.

## Switch

Battle Core soporta SWITCH electivo y reemplazo automático tras KO. La presentación permite elegir un miembro vivo de la party mediante `instance_id` estable.

**No soportado todavía:** elección manual de reemplazo forzado tras KO. Introducirla requiere un estado explícito de Battle (`replacement_required` o equivalente) y no debe implementarse solo en UI.

## RUN

`calvo_escape_v1` está ejecutado y probado para encuentros salvajes:

- huida garantizada por Speed/odds cuando corresponde;
- RNG inyectado para caso probabilístico;
- contador de intentos y bonus acumulativo;
- fallo -> exactamente una respuesta rival;
- éxito -> `FLED`, sin XP/captura/heal;
- separación total de Capture RNG/inventario;
- botón Run y feedback técnico en Battle Presentation.

No incluye Run Away, Smoke Ball, Poké Doll, trapping/Mean Look ni trainer-battle escape. La fórmula es política explícita del proyecto, no paridad bit-perfect declarada con una generación oficial.

## Overworld / Wild Adventure

Soportado técnicamente:

- movimiento cardinal físico;
- colisiones;
- pasos por distancia real;
- encounter zones;
- tablas salvajes ponderadas deterministas;
- creación de criatura vía `CreatureFactory`;
- Battle visible;
- MOVE/CAPTURE/SWITCH/RUN;
- settlement y retorno explícito al Overworld.

No soportado todavía:

- mapa romano final;
- NPCs/diálogo;
- puertas/transiciones entre mapas;
- world-state persistente;
- trainer-battle loop;
- audio/animaciones/assets finales.

## Save / colección

Soportado:

- Party máx. 6;
- Storage 30 slots por caja, cajas dinámicas;
- Inventory;
- Savegame V2;
- migración real V1 -> V2;
- registro canónico de criaturas;
- último save bueno protegido;
- load transaccional;
- rechazo de corrupción/double ownership;
- save bloqueado durante Battle activa.

No soportado todavía:

- autosave;
- múltiples perfiles;
- cloud;
- UI de Party/Storage/Save;
- serialización de Battle activa;
- política para decisiones de progresión post-battle aún pendientes.

## Estado de presentación

La UI técnica actual ya expone:

- HP/nivel/turno;
- moves + PP;
- BattleEvent log;
- Capture balls + cantidad;
- Switch;
- Run;
- resultado + Continue.

Por tanto, referencias históricas que digan que no existe UI de captura/switch/run describen fases antiguas, no el baseline actual.

## Criterio para ampliar cobertura

Una mecánica solo pasa a `RUNTIME_SUPPORTED` cuando existe:

1. dato/contrato estructurado suficiente;
2. handler/regla explícita;
3. integración con lifecycle/autoridad correcta;
4. tests positivos + negativos/adversariales;
5. CI verde sobre el HEAD final.

No se debe aumentar cobertura mediante parsing de texto descriptivo, flags inferidos sin provenance o excepciones de UI que el dominio no entienda.