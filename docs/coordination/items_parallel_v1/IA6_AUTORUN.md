# IA6 — W05 · NUEVA MISIÓN ACTIVA · 12-11-2026

**Rama ÚNICA NUEVA:** `codex/calvo-items-20261112-w05-legacy-books-v5`.
**ANTERIOR:** W05 V4 (229/229 libros SV ya certificados). No repetir hitos cerrados ni reutilizar su CI como certificación de esta misión.
**SIGUIENTE `p`:** FASE A: construir tabla 19/19 de versiones + learnsets PokeAPI canónicos y RED de enseñanza histórica.
**TRABAJO FUNCIONAL:** 19 libros históricos fuera SV: 14 candidatos TM/TR para versión opt-in y 5 HM separados.
**CHECKPOINT:** `docs/coordination/items_parallel_v1/CONTINUOUS_V5/STATE_W05.md`. Plan de autoridad IA6: `docs/coordination/items_parallel_v1/CONTINUOUS_V5/PLAN_W05.md` en `codex/calvo-items-20261101-arbitro`.
**AUTONOMÍA:** ejecutar A→B→C en varios `p`, sin STOP artificial por bloques. Respetar literalmente permisos de rutas, conservar `dynamax_candy` excluido y no editar IA6 oficial, main/V28/PR118 ni ramas ajenas. Una `p` no ejecuta IA en segundo plano.

---

# IA6 / W05 — CONTINUOUS_V5 · LIBROS HISTÓRICOS OPCIONALES (SIN ROMPER LAS 229 MT SV)

**Autorizado 2026-11-12 · Rama exclusiva nueva** `codex/calvo-items-20261112-w05-legacy-books-v5`, basada en **rama oficial IA6** `codex/calvo-ia6-integration-20261109` SHA `ddc8a1af56c5fe7e950bee5bf3986d8e62261f8f`. La versión oficial ya ha pasado CI integrada W03/W05 #43106031150 y #43106031155 (Repeat/Net/Moon, Repel, libros, Rope). W05 V4 propia #42965926888 SUCCESS, 229/229 MT activas, 0 nuevos ID. No volver a implementar ni contar esas 229.

## Frontera pendiente identificada en los 248 objetos MACHINE seleccionados
- **229 tienen mapeo activo `scarlet-violet`, ya están operativas.**
- **19 están seleccionados pero SIN mapeo SV** y la implementación actual rechaza perfiles históricos con `machine_profile_rules_pending`. IDs exactos: `hm01,hm04,hm05,hm06,hm08,tm00,tr13,tr19,tr28,tr31,tr39,tr41,tr44,tr50,tr72,tr83,tr85,tr91,tr93`.
- Separación OBLIGATORIA: 14 libros históricos de enseñanza candidatos (`tm00` + 13 `tr*` de Sword/Shield) y 5 `hm*` de varias generaciones con posibles acciones de mapa; **no asignar las MO como campo abierto ni asumir que todas deben enseñarse**. No alterar la identidad de esas máquinas ni renombrar TR/CDs; en Pokémon Calvo su **presentación visual es libro**, no tecnología moderna.

## Fase A — matriz fuente real y prueba RED
Leer `modules/inventory/item_connections_v1.json::machine_rows` y los métodos reales `FieldItemService.teach`, `machine_move`, `FieldMachineBookProfile.consultar`, el panel y `CreatureSpecies.learnset` + `LearnSetEntry.version_group`. Crear una matriz **19/19** con ID, movimiento canónico, versión que realmente contiene ese mapping, y cantidad de especies que en el catálogo cargado tienen licencia `method=machine` exacta para esa misma versión y movimiento. Registrar si la metadata está disponible; no inventar compatibilidad universal ni usar learnset SV para enseñanzas de Galar. Reproducir intento RED actual con **perfil opt-in explícito `sword-shield`**, al menos un TR real elegible y uno incompatible, y preservar test negativo del perfil desconocido/SV.

## Fase B — funcionalidad nueva, NO auditoría repetida
Autorizar **solo en staging W05**:
1. Añadir un adaptador explícito de elección de versión de libros por sesión/formulario (modo histórico **opt-in**, SV por defecto inalterado). Rechazar cambio de versión durante operación pendiente; no cambiar `_shared_profile` global de otra sesión o guardar la preferencia como decisión oculta. No permitir por comandos de UI hacer bypass de reglas de inventario. Versiones admitidas solo si datos exactos están presentes.
2. Hacer viable el aprendizaje histórico si el catálogo acredita de verdad movimiento, tipo, política de contenido, especie propietaria y `LearnSetEntry.method/version_group` exactos. Permiso de hunk mínimo en `modules/inventory/field_item_service.gd::configure` (argumento opcional, sin romper API) y `::teach`/profile, `modules/inventory/field_machine_book_profile.gd::consultar/presentacion`, y panel `scenes/visual/field_machine_book_panel.gd` exclusivamente en selección y enseñanza del perfil. No tocar `FieldGrowth`, `EvolutionSystem`, `CreatureInstance`, guardado core, física de mundo, batalla ni `ItemSelectionPolicy`; mantener el motor de transacción de servicio, una enseñanza/consumo, sustitución slot0–3, PARTY/STORAGE/SaveV2. Si la versión requiere un usuario/pantalla que todavía no existe, definir una elección explícita reversible de UI de libros (no modo global automático).
3. Para HMs, **sólo** enseñar cuando exista contexto real de versión/learnset y ninguna regla especial pendiente; los efectos de cortar/volar/fuerza/flash/etc. en mundo son de otro subsistema y no cuentan como L3 hasta que existan. No modificar mapa ni ofrecer funciones MO ficticias. No activar de golpe los 19 en perfil SV ni cambiar `machine_rows` del catálogo canónico.

## Fase C — CI y entrega
CI Godot 4.7/Python con entradas realmente compatibles, incompatibles, inventario sin stock, bloqueo, elección cancelada, contenido excluido, duplicado, max4 y elección de slot, versión alterada, persistencia SaveV2 manual. **Gates de no regresión obligatorias**: 229 MT SV vigentes, 229 nombres ES fuente PokeAPI, libros existentes W05 V4, Cuerda Huida, Repel W03, naturaleza W02, veto `dynamax_candy`; CI de árbol actual, no reaprovechar la CI antigua. Si falta learnset exacto `sword-shield` en el catálogo, escribir dependencia de **importación canon** y NO fabricar filas/activar enseñanza sin evidencia; buscar otro perfil histórico que sí tenga datos sin salir de alcance. La misión no se rellena con diez repeticiones QA sin implementación.
Publicar `CONTINUOUS_V5/STATE_W05.md`, `reports/W05/CONTINUOUS_V5_FINAL.md`: 19 examinados, **X/14 libros históricos enseñables L3 (no afirmar 14 hasta probar)**, `hm*` como enseñanza certificada o dependencia, 229 SV intactas, CI URL/SHA, número de objetos nuevos de producción 0 (IDs ya en catálogo), y **NO INTEGRADO IA6**. IA6 integra selectivamente una vez que haya CI y contrato verificado.

**Seguridad:** no tocar main, V28, PR118, ramas ajenas, `codex/calvo-ia6-integration-20261109`. Una `p` recupera el plan y continúa A→B→C sin nuevas autorizaciones por hito; al llegar a dependencia real dejar ticket exacto, no un PASS falso.

