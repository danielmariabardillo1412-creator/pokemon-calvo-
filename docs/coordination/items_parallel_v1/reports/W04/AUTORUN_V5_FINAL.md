# IA4/W04 — TANDA 05 — INFORME FINAL
Fecha de cierre: 2026-11-11. Rama exclusiva: `codex/calvo-items-20261104-w04-camp006`.

## Dictamen
**10/10 hitos investigados. Dos contratos nuevos L2, cero productores L3 de evolución regional.** La T04 permanece 55/56 identidades regionales con guardia nativa positiva; Exeggutor de Alola continúa bloqueado (no atribuir `harvest` oculta por defecto).

En `config/pokemon_variants_v1.json`, la especie `slowpoke_galar` (PokéAPI `10164`, `form_id=slowpoke-galar`) tiene dos `EvolutionRecord` auténticos:
1. `galarica_cuff` → `slowbro_galar` (`slowbro-galar`), `use_item`, `version_group=the_isle_of_armor`, sin condiciones adicionales.
2. `galarica_wreath` → `slowking_galar` (`slowking-galar`), `use_item`, `version_group=the_isle_of_armor`, sin condiciones adicionales.

Ambos objetos existen en el catálogo probado en Godot; `EvolutionSystem.classify_record` y `evolution_candidates` reconocen estas rutas. Sin embargo, **el consumidor nativo no es correcto aún**: `EvolutionSystem.apply_evolution` devuelve el destino con `form_id` vacío; no asigna la forma regional exacta de destino. No se autoriza cambiar EvolutionSystem, el inventario, Factory, SaveV2 central ni CreatureInstance en esta tanda. Además, no se ha demostrado una operación real mochila→consumo→reemplazo→native SaveV2 para esas dos rutas.

## Hitos autorizados (10/10)
| # | Hito | Resultado |
|---|---|---|
| 01 | Datos Slowpoke/Slowbro/Slowking Galar, PokeAPI y metadata | VERIFICADO |
| 02 | Ítems, `EvolutionRecord`, triggers y clasificación | VERIFICADO |
| 03 | Helper puro W04 especie+forma+ítem+destino | L2 CERTIFICADO |
| 04 | Contratos positivos para `galarica_cuff` y `galarica_wreath` | 2 L2 POSITIVOS; L3 BLOQUEADO |
| 05 | Negativos base, forma ajena, objeto ausente/incorrecto y destino equivocado | PASS |
| 06 | Evitar heredar `slowpoke-galar` en Slowbro/Slowking; defecto actual del motor | CONTRATO VALIDADO, SEAM NATIVA BLOQUEADA |
| 07 | Naturaleza original y efectiva | `nature_id` existente conservada por motor; naturaleza efectiva W02 no integrada/verificada en la rama W04, PENDIENTE IA6 |
| 08 | Party/Storage SaveV2 y datos legacy/corruptos | PASS en fuente y destinos creados independientemente por Factory; **NO** round-trip de evolución real |
| 09 | Regresión 55/56 formas, Exeggutor bloqueado, CAMP003–006 | PASS |
| 10 | CI y entrega documental | PASS |

## Evidencia reproducible
- CI completa [#42921791683](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42921791683): **COMPLETED / SUCCESS**, SHA funcional `8a93b82503d7ba5b96b40211f1417ca27ea093c7`.
- Helper de solo lectura `modules/creatures/progression/regional_evolution_contract_w04.gd`: exige el origen regional exacto y forma canónica, objeto en catálogo, dos registros autorizados en condiciones compatibles, destino y forma auténtica; no muta la criatura, la mochila, RNG ni SaveV2.
- Godot `tests/gameplay/w04_autorun_v5_regional_evolution.gd`: 2 contratos, negativos, origen y destinos separados con Party/Storage y SaveV2, y diagnóstico automatizado de la carencia de forma en `apply_evolution`. Los targets creados por Factory validan forma/saves, **no** prueban ejecución nativa del ítem.
- Workflow V5 `.github/workflows/parallel-w04-autorun-v5.yml` ejecuta prueba de la tanda, V4 (cuatro habilidades normales), V3 (55/56 positivas), piloto T02, Python CAMP003–006 y V1/V2, Godot CAMP003–006 y resolvers. Todos los steps completaron SUCCESS.
- Regresión Python V1 actualizada **solo** para reconocer la sucesión autorizada TANDA05; no se modificaron fixtures históricos.

## Ticket para IA6 — SEAM de evolución regional
**Problema:** el registro de evolución de `slowpoke_galar` es válido y tiene un destino específico. `EvolutionSystem.apply_evolution` crea `CreatureInstance` de destino, preserva `instance_id`, atributos y `nature_id`, pero omite `form_id`; con ello no garantiza una identidad `slowbro-galar`/`slowking-galar` persistente, aunque el destino exista en el catálogo. Para evolución desde la mochila es imprescindible además un consumidor que exija forma origen y objeto antes del gasto, sustituya una sola vez al propietario y haga rollback ante errores; ni ese consumidor ni una operación native completa quedan certificados aquí.

**Cambio mínimo a autorizar a IA6/integrador:** proporcionar una ruta de evolución para registros regionales que invoque el helper L2 antes del gasto, asigne explícitamente la forma **del destino** verificándola en el catálogo (nunca copiar la anterior), preserve naturaleza original/efectiva y estado persistente, y aplique reemplazo/consumo atomizados. No relajar `DATA_ONLY`, no ejecutar por nombre de objeto solamente, no cambiar reglas generales para especies ordinarias. Validación conjunta con W02/W03 de naturaleza efectiva y ledger de capturas obligatoria. La aprobación de ese cambio corresponde a IA6, no a W04.

## Integridad
**0 objetos nuevos**, 0 evoluciones regionales L3, 2 contratos L2, 0 modificaciones a módulos protegidos. No se tocaron `main`, V28, PR118 ni otras ramas. No hay ejecución autónoma entre turnos. Tras este cierre W04 se detiene hasta publicación de otra tanda en `IA6_AUTORUN.md`.

El commit documental de cierre puede ser posterior al SHA funcional; recertificar HEAD documental con CI antes de atribuirle SUCCESS.
