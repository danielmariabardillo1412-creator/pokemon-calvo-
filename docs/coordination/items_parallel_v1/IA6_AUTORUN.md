# IA6 — W05 · NUEVA MISIÓN CONTINUA V4 EN RAMA STAGING
**Estado:** ACTIVA. **Rama ÚNICA de esta misión:** codex/calvo-ia6-staging-20261111-w05-books.
**Origen de confianza:** plan IA6 en rama árbitra codex/calvo-items-20261101-arbitro: docs/coordination/items_parallel_v1/CONTINUOUS_V4/PLAN_W05.md; reglas generales docs/coordination/items_parallel_v1/CONTINUOUS_V4/README.md. **Base fija** e63b2e6c7e175fba318cc2f562bebd1769589092 (IA6 integradora, conserva exclusión dynamax_candy).

**PUERTA SUPERADA:** fuente histórica V3 completada y CI verificada. Al recibir p/sigue, trabajar inmediatamente en la rama staging siguiendo fases A → B → C; no detener cada diez hitos.

**Seguridad:** Si el workspace local contiene cambios no subidos, primero guardar checkpoint en su rama original; no cambiar rama con working tree sucio. Esta staging es un ensayo y no modifica ni fusiona la rama integradora oficial IA6, main, V28, PR118 u otras ramas. Evitar copiar archivos enteros de origen, usar diff por funciones, tests rojos y CI del SHA exacto. Registrar STATE_W05.md en esta misma staging. Sin trabajo asíncrono; p reanuda desde checkpoint.

**Métrica:** fases A/B/C | funcionalidades ya existentes vs integradas en ensayo | L3 y regresiones CI | conflictos bloqueados | integración oficial IA6: NO. Al terminar READY_FOR_IA6_MERGE (sin generar más rondas de QA vacías).

---

# W05 V4 — MOCHILA/LIBROS STAGING (ACTIVA)
Destino: codex/calvo-ia6-staging-20261111-w05-books. Base IA6 e63b2e6c7e175fba318cc2f562bebd1769589092. Fuente W05 código 803561dd6a0253458c576762d74b3c62435299fa, CI #42957930359 SUCCESS.

FASE A: prueba roja sobre FieldItemBag real de base IA6. Ya existe un panel llamado _books_panel, botón Abrir libro y Cuerda Huida (_apply_escape_rope). No crear un segundo panel ni copiar field_item_bag.gd entero desde W05. Leer CONTINUOUS_V3/W05_COLLISION_AUDIT.md. Traer solo garantías ausentes: IDs estables de libro/creatura, slot de sustitución 0–3, selección caducada, única ruta de gasto, callback refresco-only y nombres ES/PokeAPI sin sobrescribir localización global.
FASE B: Godot headless con FieldItemBag verdadero, 229 IDs, cancelación, stock, Party/Storage, PP, lock, doble clic, SaveV2 manual y Rope existente con rollback. W03 aún tiene repelentes ausentes en base IA6: prepararse para test de convivencia, pero NO atribuir L3 conjunto ni modificar la ruta de repeles desde W05. Python test de integridad y export Windows PCK si el entorno tiene plantillas; no afirmar GPU/Android.
FASE C: CI staging con W05 T01–V3, CAMP003–006 y veto dynamax_candy, informe reports/W05/CONTINUOUS_V4_STAGING_FINAL.md + STATE_W05, hunks exactos y ticket de integración de repelentes, READY_FOR_IA6_MERGE.

PERMISOS: exclusivamente funciones de libros _ready/open_bag/_refresh_choices/_apply/callback de FieldItemBag sin alterar Rope, FieldMachineBookPanel, FieldMachineBookProfile.presentacion, helper ES y tests/workflow W05. FieldItemService, SaveV2, FieldNativeSave, GameData, W03 repelentes, EvolutionSystem y demás ramas solo lectura. Ni main/V28/PR118; staging NO es integración central.

