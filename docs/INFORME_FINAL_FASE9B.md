# INFORME FINAL — FASE 9B: Inventory + Savegame V2

Fecha: 2026-08-29  
Rama: `feature/inventory-savegame-v2`  
Base: `feature/inventory-core-v1`  
PR: #3  
Motor CI: `4.7.stable.official.5b4e0cb0f`

## Estado

**FASE_9B_STATUS = CLOSED / VALIDATED**

## Resultado funcional

- `PlayerCollection` agrupa Party + Storage + Inventory.
- Savegame actual: `schema_version = 2`, `format_id = calvo_save_v2`.
- `PlayerInventory` se persiste y restaura con cantidades exactas.
- V2 exige bloque `inventory`; ausencia o corrupción se rechaza, no se repara silenciosamente.
- La carga sigue siendo transaccional: Party, Storage e Inventory solo se publican si todo es válido.
- Se mantiene el registro canónico único de criaturas; Party/Storage siguen referenciando por `instance_id`.

## Migración V1 → V2

Se reconoce únicamente el formato histórico real:

- `schema_version = 1`
- `format_id = calvo_save_v1`

Migración:

- ocurre en memoria;
- no reescribe el fichero al cargar;
- conserva Party, Storage y criaturas;
- crea inventario vacío porque V1 nunca almacenó objetos;
- no infiere Poké Balls ni confía en un campo `inventory` inyectado en V1;
- el siguiente guardado explícito escribe V2.

Combinaciones mixtas, formatos desconocidos y schemas futuros se rechazan.

## Hardening adicional

Durante la QA final se endurecieron los límites de confianza de JSON:

- `SaveGameMigration` valida tipos de `format_id` y `schema_version` antes de convertirlos.
- `PlayerInventory.from_dict` valida tipos de schema/ruleset/item IDs/cantidades antes de cast.
- Payloads parseables pero hostiles deben producir rechazo explícito, no excepción de runtime.
- La suite adversarial tiene watchdog y el CI limita su tiempo para que un fallo de script no bloquee el job sin logs.

## Incidencias detectadas por CI

1. Un test histórico usaba `calvo_save_v2` como ejemplo de formato inválido. Al convertirse V2 en el formato real, el test pasó a ser obsoleto. Se cambió por un ID realmente ajeno (`calvo_save_foreign`); no se relajó producción.
2. La primera versión de la suite adversarial tenía una inferencia de tipo inválida de GDScript. El watchdog convirtió el cuelgue en un fallo acotado con logs y se corrigió tipando explícitamente los campos del caso.

## Gates finales

- Regresión histórica: **470 PASS / 0 FAIL**
- Inventory 9A: **47 PASS / 0 FAIL**
- Savegame V2: **40 PASS / 0 FAIL**
- Savegame V2 adversarial: **8 PASS / 0 FAIL**
- Import Godot headless: **PASS**
- Workflow final: **SUCCESS**
- Parse/runtime inesperados: **0**
- Merge a `main`: **NO**

Nota: el test negativo de JSON corrupto sigue provocando el diagnóstico esperado de parser de Godot y después valida correctamente `json_parse_error`; no es un error inesperado del runtime.

## Garantías conservadas de FASE 8C

- último save bueno protegido durante reemplazo;
- rollback mediante backup ante fallo de publicación;
- party duplicada/over-capacity/IDs vacíos rechazados;
- referencias inexistentes/doble ownership rechazados;
- no publicación parcial.

## Fuera de alcance

No autosave, perfiles múltiples, nube, UI, tiendas/economía ni nuevos efectos de objetos.

## Siguiente paso

**FASE 10 — Wild Encounters Core**

Objetivo: tablas de encuentros por zona, probabilidad y selección ponderada deterministas, nivel salvaje, validación contra catálogo y creación del `CreatureInstance` mediante `CreatureFactory`, todavía sin mapas/UI/assets.
