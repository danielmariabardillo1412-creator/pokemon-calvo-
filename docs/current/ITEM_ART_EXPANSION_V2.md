# Ampliación de arte de objetos V2 — 2026-10-28

Actualización posterior: `ITEM_ART_UTILITY_V3.md` añade 45 entradas, hasta 654.
Este documento conserva el alcance del lote V2 y sus 609 entradas.

## Resultado integrado

La misma pestaña **F3 → Objetos** pasa de 364 a **609 entradas con imagen**.
Se conservan sin cambios las 364 entradas anteriores y sus PNG. Se añaden:

| Familia | Entradas nuevas |
| --- | ---: |
| Megapiedras | 92 |
| Cristales Z equipados | 32 |
| Entradas de bolsa de esos cristales | 32 |
| Entrenamiento | 63 |
| Objetos de estadísticas en combate | 8 |
| Fragmentos Tera | 18 |
| Total | **245** |

Son 609 entradas canónicas/archivos PNG, **562 hashes de imagen diferentes**:
varios objetos comparten aspecto. Bolsa y equipado mantienen IDs separados;
compartir una imagen no convierte un token de bolsa en un cristal equipado.

El lote nuevo ocupa 2.310.391 bytes. Las imágenes de toda la beta suman
6.594.686 bytes (6,29 MiB), sin contar metadatos/importación Godot.

## Fuentes y control visual

- 92 imágenes de megapiedras de **Z-A**, todas de 160 × 160.
- 77 imágenes de E/P, 72 de Global Link servidas por Serebii y cuatro entradas
  Z que usan dos imágenes Global Link del recopilatorio de TechSkylander1518.
- Los enlaces PGL de Nictostal Z y Electrostal Z devolvían 404. Se recuperan de
  las rutas exactas `v19/80x80/Not in PBS/Z-Crystals/` del paquete
  [Dream World Items](https://eeveeexpo.com/resources/689/).

El índice de Z-A enlaza miniaturas de 40 px. Para sus 92 megapiedras se obtiene
la ruta de tamaño completo correspondiente y se comprueba el mismo diseño
comparando la miniatura con el PNG grande reducido sobre fondo blanco. Se
conservan ambos hashes y el error RGB. No se asignan dibujos por número supuesto.

Se revisaron las 245 entradas en tres hojas y las capturas GPU reales de una
megapiedra y un cristal Z dentro de la galería. No se redibuja ni genera arte.
La aceptación sigue siendo provisional para la beta; los diseños de época se
discutirán más adelante. Algunos nombres de megapiedras nuevas aún proceden del
nombre canónico de los datos; no se inventan traducciones oficiales.

## Selección y límites

Se apartan del plan artístico seis entradas —tres cristales con sus dos roles—
por **reglas ya acordadas**, no por popularidad ni por falta de imagen:

- Eeveestal Z: su Z exclusivo, Novena Potencia, es de estado y está vetado.
- Cristal de Pikachu con gorra (`pikashunium_z`): requiere una forma y un
  movimiento exclusivo descartados por el usuario.
- Ultranecrostal Z: requiere Ultra Necrozma y su movimiento exclusivo excluido.

Los cristales genéricos se mantienen: pueden producir Z de daño aunque también
tuvieran usos de estado en los juegos originales. Absolita Z y las demás
megapiedras cuyo nombre termina en Z siguen siendo **megapiedras**, no cristales Z.

Quedan **20 entradas de esta exploración en revisión**, sin veto definitivo:
18 caramelos de AV de Let's Go, Caramelo Dinamax y Maxisetas. Los AV no son el
sistema de EV/IV del perfil Gen9 actual; los otros dos necesitan decidir su
ruta de progresión de nivel Dinamax/factor Gigamax. No se elimina ningún objeto
ordinario de EV/IV por esta separación. Las imágenes pequeñas encontradas se
conservan solo en investigación; no se hacen pasar por ilustraciones modernas.

La galería indica que Mega y Tera siguen pendientes en el perfil actual. Esta
fase **no habilita** esas mecánicas, cambia efectos, inventarios, guardados,
generadores, Trainer AI ni fórmulas. La regla de Z de daño sigue en el motor ya
integrado. El guardia de selección de Item Foundation conserva sus 43 vetos;
el listado artístico añade estas decisiones a sus 148 descartes previos: 154.

## Créditos y archivos

Arte: The Pokémon Company / Nintendo / Game Freak. Recopilación: Serebii /
Joe Merrick y colaboradores; PokéAPI/sprites para recursos anteriores.
TechSkylander1518 aporta la recopilación de los dos cristales recuperados y
acredita Bulbagarden Staff / Joe Merrick. Se añade a `CREDITS.md` del catálogo
y al manifiesto; cada entrada conserva su URL o procedencia dentro del ZIP.

La investigación está en
`D:\Proyectos\Pokemon Calvo Auditoria Visual\comparacion_objetos_v1\expansion_v2\`.
El ZIP de la recopilación tiene 10.769.038 bytes; se comprueba su CRC y solo se
extraen los dos PNG elegidos. `prepared.json` conserva las fuentes seleccionadas.
`prepare_expansion_v2.py` reproduce la preparación con los índices guardados.

`ITEM_ART_EXPANSION_V2_PLAN.json` fija los 245 IDs, seis descartes y 20 revisiones.
`tools/item_audit/append_art_batch.py --prepared <prepared.json>` añade el lote
verificando que las entradas previas no cambien. El instalador antiguo ahora
rechaza sobrescribir con un catálogo menor una ampliación posterior.

`tests/gameplay/item_art_beta_test_runner.gd -- --art-expansion-v2` comprueba la
ampliación. Con `--capture --art-expansion-v2` toma imágenes GPU del juego real.
Evidencias en `.godot/item_art_expansion_v2/`, informe final en
`ITEM_ART_EXPANSION_V2.json` y estado acumulado en `ITEM_ART_CURRENT_STATUS.json`.

## Pendiente después de este lote

Revisar objetos clave/de utilidad según la historia del juego, tesoros y otros
materiales que realmente se usarán. Resolver las relaciones MT/MO/DT por versión;
338 definiciones no implican 338 dibujos diferentes que haya que crear.
No se da por incluido todo el inventario bruto. Rokikos conserva el icono pequeño
provisional; los 20 anteriores siguen anotados para decidir su necesidad.
