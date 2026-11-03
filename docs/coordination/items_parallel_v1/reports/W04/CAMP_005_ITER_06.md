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

## CI06 real — ejecutado sin inventar evolución

[GitHub Actions #41733707261](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41733707261), SHA `c570b7ea746a93a6995f9cdb9cc92af1344e41a7`, terminó `completed/success`.

Recibos de los logs:
- `CAMP005_W04_MANIFEST_PASS reserved=10 completed=6 ids=46 kind=FUNCTIONAL_BACKLOG`.
- `CAMP005_W04_PY PASS blocks=6 checks=356`.
- `CAMP005_W04_GODOT PASS blocks=6 checks=611`.
- `CAMP005_W04_ITEM id=whipped_dream status=BLOQUEADO_POR_CONTRATO source=swirlix target=slurpuff need=approved_level+held_item`.
- `CAMP005_W04_ITEM id=leaders_crest status=DEPENDENCIA_COMBATE source=bisharp target=kingambit need=three_qualified_battle_events`.

Esta CI comprueba fuente, condiciones, rechazos seguros, equipamiento/retirada, identidad y SaveV2. **No comprueba evolución positiva porque el contrato sigue sin implementarse**. En bloque 06 el workflow **no ejecutó** regresiones CAMP004/CAMP003/CAMP001; las pruebas acumulativas CAMP005 de bloques 01–06 sí se ejecutaron completas. Las regresiones históricas siguen preservadas para hitos 10 o parches autorizados.

El CSV se consolidó como `DEPENDENCIA_DOCUMENTADA` con el recibo anterior (commit `d55808c3d11e3000b9266f31c9ac9ca6f6519f19`); dicho commit desencadena segunda CI que debe comprobarse separadamente. Bloque 04 sin modificar por la incidencia de permiso anterior.

## CI06 de progreso consolidado

La segunda CI [#41734006254](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41734006254), SHA `d55808c3d11e3000b9266f31c9ac9ca6f6519f19`, terminó **completed/success** sobre el CSV ya marcado `DEPENDENCIA_DOCUMENTADA`. Recibos idénticos: `CAMP005_W04_MANIFEST_PASS reserved=10 completed=6 ids=46 kind=FUNCTIONAL_BACKLOG`, `CAMP005_W04_PY PASS blocks=6 checks=356` y `CAMP005_W04_GODOT PASS blocks=6 checks=611`. Los dos casos conservan `BLOQUEADO_POR_CONTRATO` y `DEPENDENCIA_COMBATE` respectivamente; ninguna evolución positiva inventada.

**Bloque 06/10 cerrado como diagnóstico de dependencia, no como implementación funcional.** Fila 04 sin tocar. Próximo bloque reservado 07, exclusivamente cuando llegue la siguiente `p`.
