# IA6 — DECISIÓN VINCULANTE: EXCLUIR CARAMELO DINAMAX · 2026-11-11

**Orden expresa del usuario:** Caramelo Dinamax queda DESCARTADO del catálogo jugable de Pokémon Calvo. ID canónico `dynamax_candy` (PokeAPI item 1187, nombre ES `Caramelo Dinamax`). No implementar, no dibujar un icono nuevo por encargo, no asignar microbloques ni comprar/generar/activar su efecto. Se excluye **solo este objeto**, no los caramelos EXP, Rare Candy, mentas, ni por inferencia los movimientos/batallas Dinamax tratados en otras políticas.

## Causa de la contradicción encontrada
Los informes **históricos de arte/inventario** conservan `dynamax_candy` en el universo de 2.222 elementos PokeAPI, como `TRAINING,CANDIDATE,DATA_ONLY` (`docs/current/ITEM_INVENTORY.csv`) o `RETAIN_FOR_FUNCTIONAL_REVIEW` (`ITEM_ART_SCOPE.csv`). Otros planes registran `original_target_ids` pero `target_ids` ya lo eliminó, y `deferred_art_ids` marca la mecánica nivel Dinamax pendiente. **Una inclusión en una auditoría antigua NO equivale a selección vigente ni a permiso de implementación.** Esos registros se conservan como evidencia histórica y no se vuelven a presentar como backlog autorizado.

## Política activa — corrección publicada
En `config/item_selection_v1.json::excluded_ids` se añadió:

`"dynamax_candy": "user_explicitly_excludes_dynamax_candy_without_dynamax_level_mechanic"`

`ItemSelectionPolicy.configure` valida que el ID exista y `content_allowed(dynamax_candy)` pasa a `false`; `can_generate(dynamax_candy, {"dynamax_candy":true})` también resulta `false`. Se actualizó `tests/gameplay/item_selection_policy_test_runner.gd` con verificación explícita y el alcance exacto de **45 IDs excluidos** (9 exclusiones explícitas + 36 cartas), en vez de 44. No se cambia la definición canónica, inventarios de guardado, motores, arte instalado ni reglas de otras mecánicas.

La política y prueba fueron sincronizadas en **siete ramas**, todas fuera de `main`: árbitra `codex/calvo-items-20261101-arbitro`, integradora `codex/calvo-ia6-integration-20261109`, y W01 a W05 en sus ramas exclusivas. Los commits de distribución W están marcados `[skip ci]`; la prueba ampliada fue subida, pero **no afirmar CI nueva PASS hasta observar una ejecución en SHA correcto**. El `main` histórico sigue sin tocarse y debe incorporar esta exclusión antes de un lanzamiento o merge final autorizado.

## Reglas para las trabajadoras y contabilidad
- IA1: no equipable; IA2: excluido de bayas, medicinas, entrenamiento; IA3 captura, IA4 formas/evoluciones e IA5 libros: no incluir el ID por herencia de un CSV antiguo.
- Si cualquier cola/tabla/conteo incluye `dynamax_candy` en `SELECTED`, `CANDIDATE`, `RETAIN_FOR_FUNCTIONAL_REVIEW`, tratarlo como `EXCLUIDO_POR_USUARIO` **a partir de esta fecha**, sin borrar ni reescribir retrospectivamente los documentos de 2026-10-28.
- Restar ese ID de la **selección pendiente actual** si el recuento lo incluía; no cambiar el universo canónico de ítems ni retroceder una CI histórica por un recuento distinto. Para el nuevo conteo, declarar explícitamente fuente, fecha y política.
- Si una prueba histórica trata el ítem como elegible, crear un ajuste/regresión nuevo o un fixture compatible; **no** sustituirlo por implementación ficticia. No iniciar trabajos de nivel Dinamax, Gigamax o cristales por este informe; cualquier otra exclusión requiere una decisión específica del usuario.

**Control pendiente de IA6:** CI integradora sobre el SHA de política/probador actualizado, y auditoría de conteo actual de objetos útiles cuando las ramas estén reconciliadas. Esta orden prevalece sobre los listados históricos anteriores. `main`, V28 y PR #118 protegidos.
