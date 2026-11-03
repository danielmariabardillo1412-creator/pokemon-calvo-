# IA4/W04 — CAMPAÑA_005 / Bloque 01 — adaptación de intercambio a nivel

**Rama exclusiva:** `codex/calvo-items-20261103-w04-camp005`  
**Objetos ya auditados y NO nuevos:** `dragon_scale`, `dubious_disc`, `electirizer`, `magmarizer`.  
**Estado inicial:** `EN_CI_AUTOMATICA`; clasificación funcional prevista `BLOQUEADO_POR_CONTRATO` si se confirman estas dependencias. No declarar reparación de evolución sin positivo.

## Hallazgo autoritativo que impide implementar aún el cambio por nivel

El documento vigente `docs/current/ITEM_TRADE_RESTORATION_V27.json`, ratificado por `docs/current/TRADE_EVOLUTIONS_FUTURE.md`, fija la conversión **intercambio → subir de nivel con el mismo objeto evolutivo equipado**; **no permite quitar el objeto ni inventar un nivel universal**. Los niveles no están elegidos: `level_values_selected: null`; la implementación aparece `DEFERRED`. En `ITEM_SCOPE_V25.json`, `trade_level_conversion.levels_selected: null`. La evidencia antigua V26 de excluir los objetos fue revocada expresamente en V27.

| Ítem | Origen autorizado | Destino autorizado | Cadena PokeAPI | Condición original |
| --- | --- | --- | --- | --- |
| `dragon_scale` | `seadra` | `kingdra` | `data/api/v2/evolution-chain/54/index.json` | `trade` + `dragon-scale` equipado, `min_level=null` |
| `dubious_disc` | `porygon2` | `porygon_z` | `data/api/v2/evolution-chain/68/index.json` | `trade` + `dubious-disc` equipado, `min_level=null` |
| `electirizer` | `electabuzz` | `electivire` | `data/api/v2/evolution-chain/60/index.json` | `trade` + `electirizer` equipado, `min_level=null` |
| `magmarizer` | `magmar` | `magmortar` | `data/api/v2/evolution-chain/61/index.json` | `trade` + `magmarizer` equipado, `min_level=null` |

Los **niveles 32 y 30 de etapas anteriores de algunas cadenas no son mínimos autorizados para la evolución por intercambio**. Tampoco se adopta el nivel 37 de los randomizadores como norma del proyecto.

## Diagrama de frontera y dependencia concreta

```text
[Datos PokeAPI / reglas V27]
          |
          | (falta definir nivel aprobado + regla de consumo)
          v
[ProgressionSystem.gain_experience]
          |
          | contexto EvolutionSystem.level_up_context(creature):
          | nivel, bloqueo Everstone, ataque y defensa;
          | falta held_item_id / held_item como requisito exportado
          v
[EvolutionSystem.classify_record / evolution_candidates]
          |
          | "held_item" solo sería una condición level_up;
          | actualmente se clasifica como DATA_ONLY
          v
[ProgressionEvent.EVOLUTION_AVAILABLE]
          |
          v
[Propietario de criatura / SaveV2]
          |
          | falta decidir consumo/retención de objeto equipado
          v
[Evolución real con identidad estable, inventario coherente]
```

**Productor:** `modules/creatures/progression/progression_system.gd` llama a `EvolutionSystem.level_up_context` al subir de nivel y genera `EVOLUTION_AVAILABLE`.  
**Consumidor:** `modules/creatures/progression/evolution_system.gd` únicamente reconoce condiciones `base_form` y `relative_physical_stats`; no permite `held_item` con `level_up`.  
**Frontera de aplicación:** `modules/gameplay/wild_adventure_session.gd` y `modules/creatures/progression/progression_system.gd` deben observar política de consumo/propiedad del objeto; no editar esos productores compartidos desde W04 sin contrato y coordinación de IA6.

### Decisiones necesarias para una futura reparación positiva
1. Nivel aprobado para cada una de las cuatro parejas (o tabla común aprobada explícitamente), **sin deducirlo** de etapas anteriores.
2. Semántica exacta de consumo, permanencia o devolución del objeto equipado tras evolucionar, y comportamiento en evoluciones rechazadas/canceladas.
3. Confirmar la integración del contexto de objeto equipado desde el productor de subida de nivel y su validación en `EvolutionSystem`, con test positivo en el nivel aprobado, negativo sin objeto y un nivel antes, conservación de identidad, guardado SaveV2 y regresiones.

## Pruebas nuevas publicadas (no se repite la vieja auditoría de catálogo)

- `tests/fixtures/parallel_items/w04_campaign_005.json`, commit `4e6e13f983a472c19b98d8cffa8da48a94165d6a`: rutas exactas, cadenas originales y `approved_level=null` para cada una. No contabilizar estos IDs como nuevos.
- `tests/tools/test_parallel_items_w04_campaign_005.py`, commit `8c19acdaf36d392cf992a715a268c426c1177ce5`: inspección recursiva de las cuatro cadenas PokeAPI, selección/restauración V27, objeto equipado, niveles nulos, y localización de interfaz productor/consumidor.
- `tests/gameplay/parallel_items_w04_campaign_005.gd`, commit `a18457aa93ad45dbcfdfc18b62bbada42e597f6e`: prueba de runtime con especies y registros trade+held canónicos; demuestra que un registro `level_up` con requisito `held_item` es `DATA_ONLY`, que no se inventa una evolución al nivel máximo, y que equipar el objeto original sí funciona y se conserva en SaveV2 sin transformar la criatura por mochila.
- `reports/W04/CAMP_005_PROGRESO.csv`, commit `44b0208269af6ae8a9245e77c511f448a59725d5`: una única fila 01, `EN_CI_AUTOMATICA`, hasta contrastar CI.

**CI pendiente:** [#41716388712](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41716388712). Exigir `CAMP005_W04_MANIFEST_PASS reserved=10 completed=1 ids=46`, `CAMP005_W04_PY PASS blocks=1 checks=N` y `CAMP005_W04_GODOT PASS blocks=1 checks=N`. Regresiones CAMP004/CAMP003 obligatorias si se cambia producción, y en hitos 05/10, según workflow. Este bloque no ha modificado ningún módulo funcional, por falta de requisitos aprobados.

**Siguiente `p` autorizado:** solo bloque 02 (`protector;reaper_cloth;prism_scale;sachet;up_grade`), previa verificación de CI01. No avanzar hasta el siguiente turno.
