# IA4/W04 — CAMPAÑA_004 / ITER_01

**Rama:** `codex/calvo-items-20261103-w04-camp004`.  
**IDs autorizados:** `berry_sweet`, `clover_sweet`, `flower_sweet`.  
**Estado:** `EN_CI_AUTOMATICA`; no afirmar PASS hasta consultar resultados del SHA `037b88fad887813b3c8ec996e1d2b2a22e542c65`.

## Diagnóstico del contrato existente

Los originales `data/api/v2/item/1169/index.json`, `1170/index.json` y `1171/index.json` catalogan esos objetos como `evolution` y sus descripciones en inglés dicen que **Milcery lleva el confite equipado y gira**. El módulo `modules/creatures/progression/evolution_system.gd` clasifica `spin` en `UNSUPPORTED_TRIGGERS`. No se puede convertir sin decisión técnica la evolución de Milcery a Alcremie en `use_item` directo ni prometer elección de forma/sabor. La categoría EVOLUTION seleccionada **no equivale a ruta funcional**.

## Evidencia que se prepara para Godot 4.7

El runner `tests/gameplay/parallel_items_w04_campaign_004.gd` (commit `a3bf04448bc58e4e516101ebf37ab6f3fc5399c7`) verifica en el catálogo activo cada item, clasifica sus registros de evolución, comprueba que `spin` no sea tomado por `use_item`, y usa Milcery y Eevee para probar rechazos sin consumo ni mutación, incluso mediante `use_item` y `evolve`. Si el perfil permite equipar el objeto, prueba equipamiento, ninguna evolución por el mero hecho de equiparlo, recuperación del objeto y SaveV2. Solo si se encuentra una ruta positiva `TRIGGER_USE_ITEM` + `RUNTIME_SUPPORTED` en datos reales comprueba evolución, inventario, identidad, IV/EV/experiencia/amistad/movimientos y SaveV2.

Validador `tests/tools/test_parallel_items_w04_campaign_004.py` (commit `f1ad82bc7813af374f82aadb1722a55a6d363559`): coteja reserva, progreso, fixture, selección, fuente PokeAPI y contratos reales de EvolutionSystem/FieldItemService; no simula un PASS Godot.

Fixture `tests/fixtures/parallel_items/w04_campaign_004.json` (commit `8974983555a2d7cac6d39bf66b31781696d5d3b7`), registra el primer bloque y las restricciones. CSV progreso publicado en `037b88fad887813b3c8ec996e1d2b2a22e542c65`.

## Regresión y límites

El workflow de la rama debe ejecutar además la regresión acumulativa **CAMPAÑA_003 W04 10/10**. La CAMPAÑA_001 histórica se ejecuta en las puertas de bloques 05 y 10. **Las 16 dependencias funcionales anteriores de CAMP003 siguen abiertas**; no se repiten ni se atribuye ninguna corrección.

Ningún cambio a `main`, V28, rama árbitra, otros workers, catálogos canónicos, política ni producción. Las próximas `p` avanzan **una fila** en la cola, comenzando por bloque 02 después de un resultado aceptable de la CI 01. Ante fallo de Python/Godot, reparar antes de continuar si está dentro de la especialidad V5.

**CI propia:** [#41575404407](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41575404407).
