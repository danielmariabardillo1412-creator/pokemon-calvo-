# Novena auditoría — decisión confirmada: excluir los 15 fósiles (2026-11-01)

**DECISIÓN EXPRESA DEL USUARIO.** Pokémon Calvo es un randomlocke que permite obtener los Pokémon mediante encuentros aleatorios. **No se implementará restauración de fósiles como fuente adicional de criaturas**, porque no aporta obtención necesaria de especies y añadiría un camino paralelo/redundante que exige laboratorio, canjes, reglas y pruebas.

### Acción documental ejecutada
- Los **15 IDs** de la pasada 4 que estaban `CONDICIONAL` pasan a **`DESCARTAR`** en el **catálogo maestro propuesto** `RANDOMLOCK_ITEMS_SCOPE_V1.csv`. No se eliminan sus definiciones originales, imágenes o datos canónicos.
- Motivo uniforme y rastreable: `FOSIL_REDUNDANTE_RANDOMLOCK`, nota `DECISION_USUARIO_CONFIRMADA_2026_11_01_FOSILES_SIN_RESTAURACION_REVERSIBLE`.
- Se ha creado [matriz vigente V3 de los condicionales](./RANDOMLOCK_ITEMS_CONDITIONAL_MATRIX_V3.csv): **275** IDs; la [matriz V2 de 290](./RANDOMLOCK_ITEMS_CONDITIONAL_MATRIX_V2.csv) se conserva como fotografía histórica antes de esta decisión.
- **Nuevo contador verificado: 706 PERMITIR + 275 CONDICIONAL + 1241 DESCARTAR = 2222**, cero IDs duplicados. **171 condicionales ordinarios** más **104 elementos Mega aparcados**. Candidatos ordinarios: **877 = 706 permitidos + 171 condicionales**.
- No implica cambios en `config/item_selection_v1.json`, ni `main`, V28, el generador de botín o la lógica Godot. El cambio de estado es una **decisión de contenido en rama documental**, no un efecto ejecutable probado.

### Los 15 objetos excluidos

`armor_fossil`, `claw_fossil`, `cover_fossil`, `dome_fossil`, `fossilized_bird`, `fossilized_dino`, `fossilized_drake`, `fossilized_fish`, `helix_fossil`, `jaw_fossil`, `old_amber`, `plume_fossil`, `root_fossil`, `sail_fossil`, `skull_fossil`.

**Precisión funcional:** un fósil no es un Revivir de combate para un Pokémon debilitado: su función canónica es **restaurar una especie a partir del fósil**. Precisamente por eso aquí sobra: las especies pueden aparecer por el randomizador y no se desea otra vía de obtención.

### Criterio de auditoría corregido

**Pregunta 1:** ¿Hay una mecánica concreta aprobada para Pokémon Calvo que utilice este objeto? **Pregunta 2:** ¿Esa mecánica aporta algo distinto de lo que ya permite el randomlocke? **Pregunta 3:** ¿El efecto mantiene la estrategia sin crear atajos, duplicados o progresión/obtención extra sin control? Si las respuestas son negativas, **proponer DESCARTAR** y explicar qué función sobra; no aparcar automáticamente una categoría entera por «podría servir».

Proteger igualmente objetos raros o débiles que **sí** tengan función estratégica distinta. El criterio no autoriza eliminar por categoría si hay otras rutas (Lanzamiento, cambio de forma, tutor, aprendizaje, captura o evolución). Toda propuesta ajena a esta decisión requiere comprobación y validación del usuario.

### Próximos controles por la misma lógica (NO descartes confirmados)

1. `oval_charm` y `roto_hatch`: si no existe crianza/huevos, carecen de función. En cambio `roto_friendship` puede apoyar evoluciones por amistad y **no** debe caer por la misma regla.
2. `lapoke_ball`, `lagreat_ball`, `laultra_ball`: si el juego usa captura por turnos y ya incluye Poké/Super/Ultra Ball normales, las variantes Hisui podrían ser redundantes; las otras seis Hisui **no** se equiparan automáticamente, pues tienen funciones de alcance/sigilo.
3. `fishing_rod`, `fishing_rod_galar`, `old_rod`, `good_rod`, `super_rod`: decidir si pesca es una mecánica del mapa; si la hay, no crear cinco herramientas sin progresión real.
4. `pokemon_box_link`: acceso remoto a cajas podría alterar la dificultad/las restricciones randomlocke; no equiparar a un accesorio inocuo.
5. `park_ball` y `cherish_ball` (ya PERMITIR): revisar si hay sistema de transferencia/eventos o una función propia; no confundir presencia de un perfil de captura con autorización de distribución.
6. `roto_encounter`, `roto_exp_points`, `roto_prize_money`, `vs_seeker`: evaluar posibilidad de farmeo y de alterar capturas/encuentros y límites de nivel.

**Conclusión:** cerrada la decisión del lote de fósiles; las propuestas de arriba quedan para auditorías posteriores. Mantener revisión inversa obligatoria de permitidos y descartados para detectar otras redundancias reales antes de pasar a implementación.
