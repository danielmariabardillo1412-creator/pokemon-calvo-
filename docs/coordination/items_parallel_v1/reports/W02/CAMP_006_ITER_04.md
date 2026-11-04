# IA2/W02 — CAMPAÑA_006, bloque 04/10 | Piloto de mentas: naturaleza efectiva

**Autoridad:** IA6, `CAMPAIGN_006_W02_EFFECTIVE_NATURE_ARCHITECTURE_GATE.md`. **Rama de escritura exclusiva:** `codex/calvo-items-20261104-w02-camp006`. Fila04 de la cola: `naughty_mint;rash_mint;sassy_mint;serious_mint`. No tocar `main`, V28, PR118, árbitra, otras ramas, `StatCalculator`, `modules/save/**`, sistema de combate ni APIs no autorizadas.

## Objetivo y contrato del piloto

| Ítem | Naturaleza efectiva | Regla canónica | Naturaleza original en el test |
|---|---|---|---|
| `naughty_mint` | `naughty` | +Ataque / −Defensa Especial | Hardy |
| `rash_mint` | `rash` | +Ataque Especial / −Defensa Especial | Hardy |
| `sassy_mint` | `sassy` | +Defensa Especial / −Velocidad | Hardy |
| `serious_mint` | `serious` (neutra) | neutraliza modificadores | Adamant |

**Implementación limitada aprobada (no contada como PASS hasta CI real):**

- Nuevo `modules/inventory/field_mint_effects.gd`: **solamente cuatro IDs**, target de naturaleza de `ProgressionRuleset`, rechazo de estado incoherente/repetido/sin efecto y mutación de *candidata separada*, verificando cambios estadísticos derivados del `StatCalculator` real.
- `modules/creatures/domain/creature_instance.gd`: `nature_id` original inmutable, campo opcional `effective_nature_id` vacío en criatura anterior al piloto, `recalculate_stats` pasando el objetivo efectivo válido al `StatCalculator.compute` existente; `to_dict` solo añade el campo si procede; `from_dict` recupera el dato, y señala naturaleza inválida mediante el valor centinela de identidad vacía ya rechazado por el decoder SaveV2. El código de SaveV2 no se altera.
- `modules/inventory/field_item_service.gd`: despacho exclusivo de esos cuatro ítems; `_apply_mint_item` crea candidata, valida valor y consistencia, prepara bolsa sin tocar estado vivo, vuelve a comprobar sello y propiedad, sustituye por identidad y solo entonces publica la bolsa con **−1**. Error, objetivo extraño, falta de stock y menta idéntica no deben consumir ni modificar.
- No se ha activado por accidente ninguna de las **11 mentas del catálogo de CAMPAÑA_005** ni las seis de las filas02/03 de CAMPAÑA_006.

**Oráculos de prueba acumulativos:**

- Cuatro casos positivos de fuente en `tests/fixtures/parallel_items/w02_campaign_006.json`.
- Cada uno se ejecuta en `active` (PARTY con dos), `reserve` (STORAGE con dos) y `none` (sin stock), más errores por ranura de movimiento no autorizada, repetición sin efecto, comparación independiente de estadísticas calculadas, PS intactos, IV/EV/PP/amistad/experiencia/habilidad/estado/identidad inmutables.
- SaveV2 debe decodificar un estado con naturaleza efectiva aplicada y conservar naturaleza original, estadísticas y stock; también debe aceptar snapshots anteriores sin campo; un snapshot con naturaleza efectiva inventada debe ser rechazado sin publicar dueño.
- La CI `.github/workflows/parallel-camp006-w02-autoci.yml` exige recibos separados `CAMP006_W02_MINT04_CONTRACT READY` (Python) y `CAMP006_W02_MINT04 PASS block=04 ids=4` (**Godot real**) además del gate de 288 escenarios CAMP005 completo, los negativos pendientes CAMP006 filas02/03 y las regresiones CAMP004/CAMP003. No confundir `CONTRACT READY` con efecto positivo certificado.

## Riesgos y extensiones fuera de autorización — elevar a IA6

La arquitectura puntual puede generar un **L2 real en uso directo** y persistencia positiva SaveV2, pero **no garantiza toda la interoperabilidad** mientras otros productores/consumidores usen `nature_id` sin priorizar `effective_nature_id`:

1. **`modules/inventory/field_growth_effects.gd`, `validation_error`:** calcula `StatCalculator.compute(..., c.nature_id, ...)`. Tras una menta estadísticamente efectiva, un caramelo EXP podría rechazarse con `invalid_growth_state`, aunque `CreatureInstance.recalculate_stats` sí respete el campo efectivo. Solicitar a IA6 autorizar reemplazar solo el argumento de naturaleza por `c.effective_nature_id if ... else c.nature_id`, con regresión de EXP sobre criatura minta.
2. **`modules/inventory/field_mochi_effects.gd`, `validation_error`:** compara estadísticas contra el cálculo con `c.nature_id` original, lo cual puede rechazar mochi tras menta. Misma interfaz de naturaleza efectiva (preferible método validado del dominio) y regresión de entrenamiento.
3. **`modules/save/save_game_data.gd`, `validate`:** la validación actual estructural del registro no inspecciona `effective_nature_id` antes de *escribir* snapshots obtenidos de estado arbitrario. La lectura sí invoca `CreatureInstance.from_dict`, que produce rechazo para naturaleza inválida. Para garantía integral de guardado debe autorizarse añadir chequeo de campo opcional y tipo/valor en `SaveGameData.validate` (sin transformar snapshots antiguos). Prueba: guardado inválido rechazado antes de publicación y carga previa compatible.
4. **Consumidores de combate y evolución:** auditar si leen la naturaleza original como regla biográfica (conservar) o como multiplicador de stats (usar efectiva). No editar batalla, `ProgressionSystem` ni `StatCalculator` sin IA6.

Estas son **dependencias de interoperabilidad concretas**, no excusa para dar por funcional un efecto ficticio. Si el piloto falla CI, conservar prueba roja y atender únicamente los puntos de propiedad autorizados.

## Estado de publicación / CI

**Estado previsto al crear este informe:** `PILOTO_L2_EN_CI`, **no `CI_PASS_VERIFICADO`**. Se requiere ejecución real en el SHA del commit y sus logs. Los runs previos [41763921080](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41763921080), [41778869360](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41778869360) y [41784043391](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41784043391) pasaron sus suites respectivas, **no este nuevo piloto**.

**Próxima `p`:** bloque05 `everstone;exp_share;lucky_egg` solo después de verificar el piloto y el contrato adicional para progresión, sin otorgarse a uno mismo permiso sobre `FieldGrowthEffects` u otras APIs ajenas.
