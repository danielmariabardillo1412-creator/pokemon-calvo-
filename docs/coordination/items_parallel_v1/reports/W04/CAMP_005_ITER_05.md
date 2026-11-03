# IA4/W04 — CAMPAÑA_005 / Bloque 05 — siete confites Milcery

**Rama:** `codex/calvo-items-20261103-w04-camp005`  
**Cola:** 05/10 `berry_sweet;clover_sweet;flower_sweet;love_sweet;ribbon_sweet;star_sweet;strawberry_sweet`  
**Naturaleza:** siete IDs del backlog de CAMP004, **no son siete objetos nuevos**.  
**Estado de entrega inicial:** `EN_CI_AUTOMATICA`; no declarar funcionalidad positiva ni PASS hasta ejecución real.

## Evidencia canónica sin inventar rutas

- `data/api/v2/pokemon-species/868/index.json`: Milcery apunta a cadena `452`.
- `data/api/v2/evolution-chain/452/index.json`: **una** ruta `milcery -> alcremie` con `trigger=spin` en `sword-shield`. Sus `item`, `held_item` y `min_level` vienen como `null`. Por tanto **PokeAPI no acredita siete transiciones use_item**, una por confite, ni determina dirección/duración del giro o la decoración.
- `docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`: siete objetos `EVOLUTION/SELECCIONADO`.
- `modules/inventory/item_connections_v1.json`: los siete son equipables.
- `EvolutionSystem.UNSUPPORTED_TRIGGERS` incluye `spin`; `FieldItemService.evolution_options/evolve` no resuelve ese desencadenante.
- `CreatureInstance.to_dict/from_dict` conserva el objeto equipado, pero no representa `form_id` ni `decoration_id` de Alcremie.

## Frontera nueva: productor -> consumidor -> persistencia

```text
Milcery y confite equipado (PlayerCollection / CreatureInstance)
           |
           v
Evento real de giro (dirección, duración, hora y reglas del juego): NO EXISTE
           |
           v
EvolutionSystem.classify_record / evolution_candidates: spin UNSUPPORTED
           |
           v
Selector de decoración + forma de Alcremie: NO CONTRATADO
           |
           v
FieldItemService / EvolutionSystem.apply_evolution
           |
           v
CreatureInstance + SaveV2: falta estado persistente de forma/decoración
```

**Contrato pendiente para IA6:** decidir mecánica de giro jugable y quién produce el contexto; reglas canónicas de selección de forma/crema/decoración, sin suponer una tabla inexistente en la cadena; representación de forma en criatura y migración SaveV2; consumo/retención del confite en confirmación, cancelación o fallo. No introducir evoluciones automáticas de mochila ni modificar APIs compartidas unilateralmente.

## Cobertura del bloque 05

1. **Fixture acumulativo:** `tests/fixtures/parallel_items/w04_campaign_005.json`: bloque `05`, siete IDs, una cadena `452`, contrato de confite equipado y dependencia de giro/forma, preservando bloques 01–04.
2. **Godot:** `tests/gameplay/parallel_items_w04_campaign_005.gd`: siete parejas Milcery/confite, única ruta `spin`, clasificación `UNSUPPORTED`, ausencia de opción/evolución de bolsillo, negativos sin gasto, propietario ajeno, equipamiento efectivo, atributos persistidos IV/EV/experiencia/amistad/movimientos, guardado/carga SaveV2, retirada que devuelve el estado original.
3. **Python:** `tests/tools/test_parallel_items_w04_campaign_005.py`: contrasta cadena cruda, perfil equipable, selección previa, esquema de criatura y tokens de pruebas observables Godot; recibo esperado `CAMP005_W04_PY PASS blocks=5 checks=N` con N>0.
4. **CSV:** `reports/W04/CAMP_005_PROGRESO.csv`: quinta fila `EN_CI_AUTOMATICA`; fila 04 conserva su estado documental anterior porque su conciliación fue denegada por un control de seguridad. **No se ha eludido ni alterado esa denegación.**

**Condición de aceptación:** CI05 ejecutada sobre el SHA que incluye estos cuatro cambios, `CAMP005_W04_MANIFEST_PASS reserved=10 completed=5 ids=46 kind=FUNCTIONAL_BACKLOG`, Python y Godot con `blocks=5`, y regresiones históricas CAMP004/CAMP003/CAMP001 propias del hito 05 si el workflow las ejecuta. Una CI verde valida *contrato y negativos*, **no** la evolución Alcremie pendiente.

**Aislamiento:** solo pruebas, fixture, CSV e informe W04; no producción, datos, workflows, guardados reales, `main`, V28, PR118 ni ramas ajenas.

**Después de CI05:** próximo bloque 06/10 `whipped_dream;leaders_crest`, únicamente con la siguiente `p`.

## CI05 real — contrato verificado, evolución por giro pendiente

[GitHub Actions #41727839947](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41727839947), SHA `477d737fbc16db580c06d97bda70263538f2b725` (incluye pruebas+fixture+CSV), terminó **completed/success**.

Recibos exactos de los logs:
- `CAMP005_W04_MANIFEST_PASS reserved=10 completed=5 ids=46 kind=FUNCTIONAL_BACKLOG`.
- `CAMP005_W04_PY PASS blocks=5 checks=307`.
- `CAMP005_W04_GODOT PASS blocks=5 checks=560`.
- Los siete IDs `*_sweet` devolvieron `status=DEPENDENCIA_GIRO_FORMA` sin evolución positiva.
- Hito 05, regresiones ejecutadas y correctas: `CAMP004_W04_PY PASS blocks=10 checks=387`, `CAMP004_W04_GODOT PASS blocks=10 checks=1090`, `CAMP003_W04_PY PASS blocks=10 checks=120`, `CAMP003_W04_GODOT PASS blocks=10 checks=270`, `PARALLEL_ITEMS_W04_CAMP_001_GODOT PASS iteration=3 checks=559 cases=12`.

Después de la CI, la fila 05 de `CAMP_005_PROGRESO.csv` quedó `DEPENDENCIA_DOCUMENTADA` con `ci_run=41727839947`. Esa modificación no cambia tests ni producción y **activa otra CI de consolidación**, que requiere su propia comprobación. La fila 04 se conserva sin alterar por la denegación anterior.

**Diagnóstico cerrado:** equipamiento positivo, rechazos negativos seguros y SaveV2 verificados, pero ninguna ruta de evolución `spin` ejecutable. No se consideran los confites funcionales como transformación Alcremie.

**Estado al término del bloque:** 05/10; la siguiente `p` corresponde solo al bloque 06 (`whipped_dream;leaders_crest`).
