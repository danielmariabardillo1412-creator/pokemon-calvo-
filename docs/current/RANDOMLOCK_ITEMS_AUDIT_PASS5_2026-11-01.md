# Quinta revisión: utilidad real frente a venta redundante (2026-11-01)

**Estado: informe de auditoría, no filtro aplicado.** El CSV maestro continúa en el cierre verificado de la pasada 4: **706 PERMITIR, 290 CONDICIONAL, 1.226 DESCARTAR; total 2.222**. La fase Mega (92 piedras + 12 accesorios) queda separada. La fase normal tiene 892 candidatos (706 + 186).

## Hallazgo: Duralium descartado erróneamente

`armorite_ore` está marcado `DESCARTAR` por «SIN_INCURSIONES». **Propuesta: devolver a CONDICIONAL**, porque en Espada/Escudo también permite pagar tutores de movimientos y el reinicio de EV, independientemente de cuál fuese su origen. En el juego sin incursiones solo tendría utilidad si existe un tutor o servicio de reajuste EV. No activar por ahora. Referencia: https://bulbapedia.bulbagarden.net/wiki/Armorite_Ore.

## 41 tesoros todavía condicionales: clasificación más rigurosa

**7 vinculados a tutores o reaprendizaje**: `big_mushroom,tiny_mushroom,heart_scale,blue_shard,red_shard,green_shard,yellow_shard`. Mantener como condicionales. En Rojo Fuego/Verde Hoja el Recordador consumía una Seta Grande o dos Minisetas por movimiento; Escama Corazón y fragmentos también tienen rutas reales de aprendizaje en varios juegos. No decidir costes sin crear el sistema. Fuentes: https://bulbapedia.bulbagarden.net/wiki/Big_Mushroom, https://bulbapedia.bulbagarden.net/wiki/Tiny_Mushroom.

**3 materiales con resultado útil**: `galarica_twig` produce Brazal/Corona Galanuez para evolucionar; `shoal_salt,shoal_shell` permiten obtener Cascabel Concha. Los tres quedan condicionales hasta decidir si dichos objetos finales se consiguen directamente; evitar que el propio material se convierta en otro objeto sin mecanismo.

**5 representantes de posible economía**: `nugget,big_nugget,stardust,star_piece,comet_shard`. Mantener de momento condicionales. No afirmar que son equivalentes perfectos: se venden a precios distintos y Trozo Estrella tuvo canjes adicionales. No distribuir sin decidir tiendas/dinero y si esos niveles de recompensa son necesarios.

**25 tesoros sin beneficio diferente a venta/recuerdo, propuestos para DESCARTAR reversible**:
`balm_mushroom,beach_glass,big_bamboo_shoot,big_pearl,chalky_stone,gold_leaf,lone_earring,marble,pearl,pearl_string,polished_mud_ball,pretty_wing,rare_bone,relic_band,relic_copper,relic_crown,relic_gold,relic_silver,relic_statue,relic_vase,silver_leaf,strange_souvenir,stretchy_spring,tiny_bamboo_shoot,tropical_shell`.
**Precaución**: su precio y rareza no son idénticos. La propuesta simplifica la economía, conserva definiciones canónicas y deja algunas categorías de tesoros representativos. No implicaría que antes no fueran vendibles. Fuentes: https://bulbapedia.bulbagarden.net/wiki/Valuable_item y https://www.serebii.net/letsgopikachueevee/partner.shtml.

**1 descuento de ropa**: `discount_coupon` → propuesta DESCARTAR. Aplica a boutiques de vestimenta, no a tienda de objetos estratégicos; no trasladar su efecto a cualquier tienda sin diseño explícito. Fuente: https://bulbapedia.bulbagarden.net/wiki/Discount_Coupon.

**Aritmética si se aprobara el lote**: 706 PERMITIR, **265 CONDICIONAL**, **1.251 DESCARTAR**. Fase normal **867 candidatos** (706 + 161), Mega 104. **NO son los recuentos actuales del CSV**. Operación intencional pendiente de aplicar y cotejar: 25 descartes de venta + 1 cupón descartado + 1 recuperación de Duralium.

## Auditoría final obligatoria tras seleccionar el catálogo

El usuario ha pedido explícitamente una **auditoría inversa**: no basta con buscar objetos útiles entre descartados y condicionales; hay que recorrer los **PERMITIR**, detectar falsos positivos, ítems sin función vigente, duplicados por efecto, incompatibilidades de generación, economía desequilibrada y efectos solo decorativos. Después, volver a revisar descartados para detectar falsos negativos. Exigir `objeto_id → efecto/propiedad → contexto → dependencia → evidencia → reglas randomlock → estado funcional Godot`; no confundir `PERMITIR` con `TEST PASS`.

**Trabajo técnico separado:** la clasificación no modifica `config/item_selection_v1.json`, `main`, el generador de loot, los ataques permitidos ni los workflows V28. Después de resolver objetos y comprobar la lista completa, la siguiente fase será Mega, incluida la propuesta no aprobada de dos unidades de una piedra universal.

**Fuente principal:** [CSV de 2.222 entradas](./RANDOMLOCK_ITEMS_SCOPE_V1.csv), [cuarta auditoría](./RANDOMLOCK_ITEMS_AUDIT_PASS4_2026-11-01.md). El archivo presente registra las propuestas sin imponerlas al juego.
