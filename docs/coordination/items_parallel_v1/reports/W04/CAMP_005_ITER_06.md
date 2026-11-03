# IA4 / W04 — CAMPAÑA_005 — Microbloque 06: Whipped Dream y Leader's Crest

**Rama exclusiva:** `codex/calvo-items-20261103-w04-camp005`  
**Bloque:** 06/10 de la cola aprobada, dos IDs ya auditados (no nuevos): `whipped_dream;leaders_crest`  
**Estado inicial:** `EN_CI_AUTOMATICA`. No atribuir PASS antes de leer GitHub Actions.

## Contratos crudos y trazabilidad

| ID | Ruta real | Fuente | Condición cruda | Runtime |
| --- | --- | --- | --- | --- |
| `whipped_dream` | Swirlix → Slurpuff | `data/api/v2/evolution-chain/351/index.json` | `trade` + `held_item=whipped-dream`, nivel `null`, `x-y` | `DATA_ONLY`, conversión nivel+objeto todavía sin umbral aprobado V27 |
| `leaders_crest` | Bisharp → Kingambit | `data/api/v2/evolution-chain/317/index.json` | `three-defeated-bisharp`, sin ítem de uso directo, nivel `null`, `scarlet-violet` | `UNSUPPORTED`, faltan eventos de derrota cualificada |

**No confundir rutas:** el nivel **52** de Pawniard→Bisharp (misma cadena 317) NO es un umbral autorizado de Bisharp→Kingambit. Tampoco existe un nivel numérico aprobado para Swirlix→Slurpuff.

**Diferencia fuente vs diseño:** en Pokémon originales el objeto Leader's Crest interviene en qué Bisharp rivales son elegibles para el requisito de derrotas; el snapshot de esta cadena no trae `item` ni `held_item` para la transformación. La prueba no asume que el Bisharp evolucionado deba llevar `leaders_crest` ni que deba gastarse. Se necesitará un productor de eventos de combate que refleje la condición validada en el diseño Randomlock.

## Frontera funcional y decisiones para IA6

```text
Swirlix + Dulce de Nata equipado
        |
        v
Nivel de sustitución de intercambio: V27 level_values_selected=null
        |
        v
ProgressionSystem.gain_experience → level_up_context
        |  No transmite held_item ni valida condición trade+held
        v
EvolutionSystem.classify_record / evolution_candidates
        |  DATA_ONLY; sin umbral o política de consumo inventados
        v
Slurpuff NO habilitado

Bisharp + tres derrotas de Bisharp cualificados
        |
        v
Evento acumulado de combate (productor aún inexistente)
        |  identidad del combatiente, rival cualificado, origen/guardado del contador
        v
EvolutionSystem three_defeated_bisharp = UNSUPPORTED
        v
Kingambit NO habilitado
```

- `docs/current/ITEM_TRADE_RESTORATION_V27.json`: reemplazar solo intercambio por nivel, mantener objeto original equipado; `level_values_selected=null`, `future_evolution_implementation=DEFERRED`. Se necesita decisión canónica para nivel de Swirlix y consumo/retención al evolucionar.
- `modules/inventory/item_connections_v1.json`: `whipped_dream` equipable; `leaders_crest` NO equipable. No modificar el perfil para aparentar funcionalidad.
- `docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`: `leaders_crest` consta como `FOOD_OR_PICNIC_ACTIVITY`, pero la reserva W04 lo asigna `SPECIAL_EVOLUTION`. **Discrepancia de catalogación para IA6:** decidir si reclasificar globalmente, sin cambiar los datos compartidos aquí.
- Falta fuente autoritativa y contrato persistente de contador de Bisharp derrotados con condición válida. No asumir contador global ni un objeto consumible.

## Evidencias publicadas

1. Fixture acumulativo `tests/fixtures/parallel_items/w04_campaign_005.json` con ambas rutas originales, procedencia, dos condiciones distintas y dependencias concretas; preservados los bloques 01–05.
2. Runner Godot `tests/gameplay/parallel_items_w04_campaign_005.gd`: contrasta `trade+held` y `three_defeated_bisharp` contra registros del catálogo, rechazo de elegibilidad incluso con contexto falso, perfil equipable diferente, mochila/servicio/rechazo por propietario ajeno sin consumo, identidad/IV/EV/amistad/experiencia/movimientos, SaveV2, retirada correcta de Whipped Dream, y control de la etapa Pawniard de nivel 52.
3. Python `tests/tools/test_parallel_items_w04_campaign_005.py`: verifica las cadenas PokeAPI 351 y 317, las clasificaciones de selección reales, la ausencia de niveles aprobados, perfil de equipamiento y aserciones Godot acumulativas.
4. Progreso `reports/W04/CAMP_005_PROGRESO.csv`: fila 06 `EN_CI_AUTOMATICA` a la espera de CI. Fila 04 conservada tal como estaba; su conciliación fue bloqueada antes por seguridad.

## Criterio de cierre

Exigir `CAMP005_W04_MANIFEST_PASS reserved=10 completed=6 ids=46 kind=FUNCTIONAL_BACKLOG`, recibos reales `CAMP005_W04_PY PASS blocks=6 checks=N` y `CAMP005_W04_GODOT PASS blocks=6 checks=N` con N>0. Al tratarse del bloque 06, las regresiones completas de CAMPAÑA_001/003/004 se ejecutan solo si el workflow lo indica o se modifica producción. PASS técnico significa **documentación y comprobación de rechazo/persistencia**, no funcionalidad positiva de las evoluciones.

Sin cambios en `main`, V28, otras ramas, código de producción, datos compartidos, workflows ni guardados reales.

**Tras CI06 válida:** próxima `p` autorizada para bloque 07 `adamant_crystal;blue_orb;griseous_core;lustrous_globe;red_orb` exclusivamente.
