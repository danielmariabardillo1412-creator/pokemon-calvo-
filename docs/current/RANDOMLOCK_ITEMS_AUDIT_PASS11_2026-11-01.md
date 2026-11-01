# Auditoría 11 — lote de 41 condicionales y elección de Cola Skitty (2026-11-01)

**Alcance:** inventario de contenido futuro de Pokémon Calvo. No se toca ni desconecta ninguno de los módulos implementados en Godot, ni los importadores, guardados, IDs oficiales o pruebas. Los 41 condicionales se revisan por **función estratégica concreta** para un randomlocke competitivo, evitando introducir una segunda representación física de la misma herramienta, sistemas de encuentros ajenos y curas duplicadas.

## Decisión expresa del usuario: huida

- `fluffy_tail` (Cola Skitty): **PERMITIR**, representante único de huida segura consumible por encajar mejor en una ambientación con romanos/vikingos/posibles mayas.
- `poke_doll` (Poké Muñeco): **DESCARTAR** de contenido *generable futuro*, conservando la ruta de combate actual.
- `poke_toy` (Pokéseñuelo): continúa **DESCARTAR** desde la auditoría 10; ninguna desconexión técnica.
- **V21 confirma** que los tres objetos comparten la misma acción de huida y consumo; no existe necesidad de programar/desprogramar ninguno por esta decisión. `max_mushrooms` (Maxiseta) **PERMITIR**, confirmado por el usuario: sube cinco estadísticas +1 en combate. Mantener controles de cantidad/balance para la fase de diseño, no crear un veto.

## Lote actual: 41 condicionales examinados y reclasificados en la propuesta de catálogo

- **9 pasan a PERMITIR:** `n_solarizer_merge`, `n_lunarizer_merge`, `golden_razz_berry`, `silver_razz_berry`, `roto_catch`, `roto_exp_points`, `roto_friendship`, `catching_charm`, `exp_charm`.
- **32 pasan a DESCARTAR:** `dna_splicers_merge`, `dna_splicers_split`, `reins_of_unity_merge`, `reins_of_unity_split`, `meteorite_2`, `meteorite_3`, `meteorite_4`, `n_solarizer_split`, `n_lunarizer_split`, `fishing_rod`, `fishing_rod_galar`, `old_rod`, `good_rod`, `super_rod`, `oval_charm`, `roto_hatch`, `golden_nanab_berry`, `silver_nanab_berry`, `golden_pinap_berry`, `silver_pinap_berry`, `roto_encounter`, `roto_stealth`, `roto_bargain`, `roto_prize_money`, `roto_boost`, `roto_hp_restore`, `roto_pp_restore`, `honey`, `poke_radar`, `shiny_charm`, `pokemon_box_link`, `vs_seeker`.
- Se trata de **preselección técnica a revisar**, distinta de la decisión humana explícita sobre la Cola Skitty.
- Motivos por ID: [RANDOMLOCK_ITEMS_AUDIT_PASS11_CHANGES.csv](./RANDOMLOCK_ITEMS_AUDIT_PASS11_CHANGES.csv), incluida evidencia de redundancia, especialidad original y dependencia.
- **Nuevo contador:** **710 PERMITIR + 229 CONDICIONAL + 1283 DESCARTAR = 2.222.** Mega aparcadas: 104; condicionales ordinarios: **125**; candidatos de la fase ordinaria: **835 = 710+125**.

## Precauciones y excepciones que evitan errores

1. `n_solarizer_merge` y `n_lunarizer_merge`: **PERMITIR como representación futura** de los objetos Necrosol y Necroluna. No existe un ID de objeto base para esos dos en el CSV. Sus variantes `_split` se mantienen como datos de operaciones reversibles, **no como nuevos objetos que diseñar**. Punta ADN, Riendas Unión y Meteorito ya tienen su propio ID base, por eso sus alias se descartan solo del contenido físico distribuible.
2. `roto_boost` y `max_mushrooms` son equiparables en uso de bolsa: ambos suben Ataque, Defensa, At. Esp., Def. Esp. y Velocidad **una etapa en el combate**. Se mantiene Maxiseta por selección expresa; no hace falta una segunda ficha con igual efecto. Referencias: https://bulbapedia.bulbagarden.net/wiki/Roto_Boost y https://bulbapedia.bulbagarden.net/wiki/Max_Mushrooms.
3. `golden_razz_berry` y `silver_razz_berry` **sí** mejoran probabilidad de captura y se permiten como objetivo de contenido; no significa que su adaptador a captura clásica esté implementado. `golden_nanab_berry`, `silver_nanab_berry` requieren minijuego de apuntar; `golden_pinap_berry`, `silver_pinap_berry` son para recompensa de objeto al capturar en Let's Go. No trasladar de forma incorrecta los efectos de las versiones de Pokémon GO. https://www.serebii.net/letsgopikachueevee/items.shtml.
4. `roto_catch`, `roto_exp_points`, `roto_friendship` tienen efectos directos sobre captura, experiencia y amistad del Pokémon. `exp_charm` y `catching_charm` actúan sobre experiencia/captura crítica respectivamente. **Conservar**, pero cualquier implementación o distribución exige contratos, pruebas y política antiacumulación en experiencia.
5. `roto_hp_restore` y `roto_pp_restore`: se elige no diseñar objetos separados al disponer ya de Poción Máxima y Elixir Máximo. Sus efectos no son idénticos en todas las interfaces/generaciones, de modo que la conclusión es **de diseño de esta aventura**, no afirmación de igualdad universal.
6. Las cinco cañas de pescar, Miel y Pokéradar no son necesarias en un pool que ya sortea Pokémon por encuentros; no prohibir que el escenario tenga agua, pesca ambiental o estética, solo se evita convertir esas herramientas en objetos de generación obligatorios.
7. `oval_charm` y `roto_hatch` solo sirven para cría/huevos, sin sistema aprobado. `shiny_charm` solo eleva presencia de variocolores; interesante para coleccionismo pero sin ventaja competitiva en la regla actual. La reclasificación es reversible si después se incorpora un sistema propio.
8. `pokemon_box_link` y `vs_seeker` dan acceso remoto al equipo o revanchas: una función de interfaz/mapa o sistema de entrenadores, no un efecto de objeto Pokémon para un randomlocke.
9. `roto_bargain`, `roto_prize_money` solo alteran economía del jugador; no se excluyen dinero/tiendas *como sistemas*, sino estos dos consumibles indirectos.
10. **No se han tomado decisiones sobre las nueve bolas Hisui en este lote.** El sistema original de PLA funciona dentro y fuera de combate con fórmulas/bonificaciones distintas, así que no sería riguroso llamar duplicadas a las nueve sin revisar cómo capturará Pokémon Calvo. https://www.serebii.net/legendsarceus/capture.shtml.

## Contabilidad y continuidad

El catálogo maestro `RANDOMLOCK_ITEMS_SCOPE_V1.csv` conserva **2.222 IDs canónicos únicos**, sin borrar filas. Se actualizan estados *solo en la rama documental* `codex/item-catalog-randomlock-v1-20261101`, no se modifica `config/item_selection_v1.json`, `main`, la rama V28 ni ninguna escena Godot. **El motor sigue admitiendo los objetos de huida y las bolas técnicas previamente conectadas** aunque se hayan excluido de distribución futura en la lista.

La [matriz vigente V5](./RANDOMLOCK_ITEMS_CONDITIONAL_MATRIX_V5.csv) tiene exactamente 229 condicionales. Las matrices V1-V4 y auditorías anteriores quedan como registro histórico; el presente documento prevalece para las nuevas propuestas. **Próximo lote recomendado:** las nueve bolas Hisui, seis objetos de campo equipables, tesoros por Lanzamiento y MT antiguas sin equivalente; no descartar por nombre ni solo por tener función en otro sistema.
