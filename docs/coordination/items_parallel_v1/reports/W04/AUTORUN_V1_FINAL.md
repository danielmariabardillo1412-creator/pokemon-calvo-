# IA4/W04 — TANDA 01 FINALIZADA (AUTORUN V1, 2026-11-10)

**Repositorio:** `danielmariabardillo1412-creator/pokemon-calvo-`  
**Rama exclusiva:** `codex/calvo-items-20261104-w04-camp006`  
**Protocolo:** `docs/coordination/items_parallel_v1/AUTONOMY_V1/README.md` de la rama árbitra, SHA de blob `8b4bc113e510c379f4a5345b4d08c16b25811898`.  
**Orden:** `docs/coordination/items_parallel_v1/IA6_AUTORUN.md` en la propia W04, SHA de blob `c3c9aa6610948120a8000349e6e2c32c8cf10b6d`.  

## Resultado inequívoco

**10/10 filas examinadas. 2/10 frentes de QA con funcionalidad real existente recertificada. 0/10 nuevas evoluciones, cambios de forma o fusiones L3 añadidas en la tanda.**

- **2 certificados QA ya existentes:** fila05 — evolución real de especie mediante manzanas desde mochila + gasto uno + SaveV2; fila07 — equipar, quitar y reequipar Dragon Scale/Electirizer con SaveV2, sin evolucionar por nivel.
- **4 BLOQUEADOS:** filas01–04 B07–B10 (regional, formas de campo, Origen/Primal y fusiones), porque falta identidad de forma persistente, disparador de mundo/batalla o API de dos ejemplares. No suman efectos.
- **1 PARCIAL:** fila06 B02, 4 cambios de especie desde mochila existentes pero no autenticidad de forma antigua/phony o artisan/counterfeit; **no** cuenta como mecánica completa.
- **2 L2 verificados:** fila08 (sexo/día/luna) y fila09 (Milcery/63 formas); sin productores del juego, **no** son evolución L3.
- **1 auditoría no funcional:** fila10, 18 IDs únicos y 23 rutas con contrato productor→consumidor→persistencia→rollback y ticket IA6. Sin efecto L3 acreditado.

**Campaña histórica CAMP006 se conserva sin cambio:** `completed=3`; 04 aplazado por V27; 05 y 06 bloqueados a pesar de resolvers L2 PASS. Los dos QA funcionales de la Tanda 01 **no** suman a `completed` de la campaña ni implican dos evoluciones adicionales.

| Fila | Frente | Estado final | Funcional real acreditado en esta tanda |
| --- | --- | --- | --- |
| 01 | CAMP006 B07 Galarica y pergaminos Urshifu | BLOQUEADO por forma regional/estilo persistente | 0 |
| 02 | CAMP006 B08 Gracídea/meteorito/cristal, catálogo Rotom/Cubo Zygarde | BLOQUEADO por reloj, selección, celda y forma | 0 |
| 03 | CAMP006 B09 orbes y gemas Origen/Primal | BLOQUEADO efecto de forma; held previo existente | 0 |
| 04 | CAMP006 B10 fusiones Kyurem/Calyrex/Necrozma | BLOQUEADO por par de identidades y SaveV2 | 0 |
| 05 | QA CAMP006 B01 manzanas | CERTIFICADO_QA_L3_EXISTENTE | 1 (existente) |
| 06 | QA CAMP006 B02 cuatro tazas | PARCIAL_VERIFICADO_SIN_FORMA | 0 (solo especie) |
| 07 | QA CAMP006 B03 Dragon Scale/Electirizer | CERTIFICADO_QA_EQUIPAMIENTO | 1 (existente, no evolución) |
| 08 | Resolver sexo/día/luna CAMP006 B05 | L2_VERIFICADO_NO_L3 | 0 |
| 09 | Resolver Milcery CAMP006 B06 | L2_VERIFICADO_NO_L3 | 0 |
| 10 | Auditoría transversal B07–B10 | AUDIT_VERIFICADO_NO_L3 | 0 |

**Detalle permanente:** `reports/W04/AUTORUN_V1_PROGRESS.csv` (10 filas, estados, nivel de evidencia, `sha_ci` y `run_ci`); `reports/W04/AUTORUN_V1_MATRIX.json` (18 ID/23 rutas). **Ticket IA6 único:** `reports/W04/AUTORUN_V1_SHARED_PRODUCER_TICKET.md`. Este ticket concentra todas las dependencias y evita repetirlas en nuevas tareas.

## Evidencia CI — sobre estado definitivo de filas

### Certificación final sobre SHA de progreso consolidado

**GitHub Actions [#42729967922](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42729967922) — COMPLETED / SUCCESS**  
**SHA probado:** `3385011da12ed6f3d0d68a82c33348c7c23e17fc`.

Recibos observados:
- `W04_AUTORUN_V1_PY PASS rows=10 ids=18 routes=23 completed_historical=3 qa_functional=2 checks=202`
- `CAMP006_W04_PY PASS completed=3 last_executed=06 deferred=04 checks=211`
- `CAMP006_W04_GODOT PASS completed=3 last_executed=06 deferred=04 checks=326`
- `CAMP006_W04_RESOLVER_L2 PASS completed=3 last_executed=06 deferred=04 checks=91`
- `CAMP006_W04_MILCERY_L2 PASS completed=3 last_executed=06 deferred=04 blocked=05,06 checks=150`
- `CAMP005_W04_PY PASS blocks=10 checks=673`
- `CAMP005_W04_GODOT PASS blocks=10 checks=1423`
- `CAMP004_W04_PY PASS blocks=10 checks=387`
- `CAMP004_W04_GODOT PASS blocks=10 checks=1090`
- `CAMP003_W04_PY PASS blocks=10 checks=120`
- `CAMP003_W04_GODOT PASS blocks=10 checks=270`

**Primera CI para esta tanda:** [#42729727141](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42729727141), SHA `313ca28b88ba4f645c0a7349b4519adad50d266c`, **SUCCESS** sobre estados de QA todavía pendientes; se repitió la CI después de clasificar QA05 y QA07, por lo que la anterior **no** se usa como certificación de los estados finales.

**Importante:** PASS significa que todas las aserciones exigidas, incluido el bloqueo de mecánicas no conectadas, han pasado. No se interpreta como ejecución real de formas/fusiones.

## Integridad, permisos y trabajo de la tanda

- **No modificado:** `main`, V28, PR#118, otras ramas, `CreatureInstance`, Factory, SaveV2, escena/mundo, `FieldItemService`, motor global, política V27, código de `EvolutionSystem`.
- **Nuevos archivos W04:** `.github/workflows/parallel-w04-autorun-v1.yml`, `tests/tools/test_parallel_items_w04_autorun_v1.py`, `reports/W04/AUTORUN_V1_MATRIX.json`, `reports/W04/AUTORUN_V1_PROGRESS.csv`, `reports/W04/AUTORUN_V1_SHARED_PRODUCER_TICKET.md`, este informe. La orden `IA6_AUTORUN.md` ya fue publicada por IA6 y se mantuvo intacta.
- Fixture histórico CAMP005 **congelado**, comprobado contra su SHA blob `a504b65c73a399ab6c00e80b02481fe26392ec0e`; no se alteraron pruebas viejas ni se aplicaron saltos `continue-on-error` o `|| true`.
- Python nuevo comprueba rutas canónicas Galar/Urshifu, formas Pokémon de B08–B10, 18 IDs, cadenas que no son evoluciones, productores ausentes y retrocompatibilidad de los artefactos; Godot reejecuta mochila/SaveV2 real y todas las campañas históricas.

## Próximo paso para IA6

Revisar matriz y ticket, seleccionar productores de `form_id` real, reloj/giro/selección de forma, Primal/Origen y transacción reversible de fusión de dos ejemplares. Integrar solo las funciones autorizadas en la rama central con nueva CI L3. W04 no debe extender la tanda por iniciativa propia ni repetir los 10 bloques ya auditados.

**ESTADO:** `TANDA 01 FINALIZADA`. Detener ejecución W04 hasta que IA6 publique la siguiente tanda en `docs/coordination/items_parallel_v1/IA6_AUTORUN.md`.
