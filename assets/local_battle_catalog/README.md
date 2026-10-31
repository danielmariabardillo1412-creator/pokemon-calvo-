# Catálogo visual local

Pack de desarrollo para las 1.025 especies base, color normal. `manifest.json`
y `atlases/` se generan con `tools/visual/build_battle_sprite_pack.py` a partir
de los inventarios ya auditados. No regenera datos Pokémon ni modifica originales.

Los PNG se leen directamente y bajo demanda: `.gdignore` evita importar miles de
recursos al abrir el editor. El pack está excluido de Git deliberadamente: no se
han revisado permisos de redistribución de todo el arte. No está certificado para
exportar una build autónoma; esa fase debe incluir explícitamente estos archivos
y revisar créditos/condiciones de Showdown/PkParaiso/Creatures y de los candidatos.

F1 permite configurar los IDs del catálogo real en equipo, rival y encuentros;
F3 abre la revisión visual de todo el catálogo dentro de la demo existente.
La galería no altera tu equipo ni simula un combate. Una vista ausente se marca
como pendiente, nunca se sustituye la espalda por el frontal ni por otra especie.

La mayoría tiene reposo animado, no ataques corporales específicos. Los 14
candidatos 3D incorporan también ataque/daño, todavía provisionales. Tener imágenes
no certifica reglas, movimientos, IA, formas alternativas o shiny. La escala usa
alturas comprimidas y anclas estables, con perspectiva de rival y límites del
encuadre medidos en todos los estados/fotogramas. `presentation_metrics.json` se
genera sin modificar PNG con `tools/visual/build_battle_sprite_metrics.py` y queda
ligado al SHA del manifiesto. Sigue pendiente la aprobación artística final;
estas son reglas de nuestra arena, no escalas certificadas de un juego oficial.

Actualización de referencias: `scale_reference.json` conserva las proporciones
de Showdown para las 1.011 especies de esa familia (2.003 vistas coincidentes y
19 adaptadas por diferencias de recurso). Anula en presentación la normalización
antigua por altura; no altera imágenes. Los 14 renders propios quedan identificados
como calibración relativa, no como referencia externa. La galería distingue estos
casos. Constructor: `tools/visual/build_showdown_scale_reference.py`.

En F3: **Comparar** acepta otro ID/nombre, **Invertir lados** permite inspeccionar
ambas vistas y **Misma especie** restaura la vista habitual. La referencia se
mantiene en reposo al probar estados del Pokémon seleccionado.
