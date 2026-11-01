# Sexta revisión de objetos — registro de tandas de 25 y 46 (2026-11-01)

**Auditoría documental; propuestas no aplicadas.** Rama `codex/item-catalog-randomlock-v1-20261101`. Este informe consolida las 71 entradas revisadas en la conversación posterior a la quinta auditoría. No confirma efectos nuevos en Godot ni cambia la política de selección, los guardados, el randomizador o `main`.

## Regla obligatoria de persistencia

- **Fuente maestra**: [RANDOMLOCK_ITEMS_SCOPE_V1.csv](./RANDOMLOCK_ITEMS_SCOPE_V1.csv), una fila por cada uno de los 2.222 IDs.
- **Revisiones recientes por ID**: [RANDOMLOCK_ITEMS_REVIEW_LOG_V1.csv](./RANDOMLOCK_ITEMS_REVIEW_LOG_V1.csv), 71 IDs distintos. `estado_maestro_v4` es el valor vigente antes de estas propuestas; `propuesta_revision` no se considera una decisión confirmada.
- **Auditorías anteriores**: [pasada 4](./RANDOMLOCK_ITEMS_AUDIT_PASS4_2026-11-01.md) y [pasada 5](./RANDOMLOCK_ITEMS_AUDIT_PASS5_2026-11-01.md). La quinta pasada suspendió los descartes económicos masivos al identificar Lanzamiento.
- **Contador vigente sin modificaciones**: **706 PERMITIR, 290 CONDICIONAL, 1.226 DESCARTAR** = 2.222. Dentro de CONDICIONAL, 104 objetos Mega aparcados y 186 de fase ordinaria. No restar 71 a los 290: **33 de esos 71 ya figuraban PERMITIR; los 38 restantes son CONDICIONAL**, y las propuestas aún no están aprobadas.

## Tanda de 25 tesoros

| Propuesta | Cantidad | IDs | Nota |
|---|---:|---|---|
| Proponer PERMITIR | 3 | `big_nugget`, `rare_bone`, `pretty_wing` | Lanzamiento 130, 100 y 20. Mantener alcance condicionado hasta certificar combate/consumo; la potencia más baja puede tener usos situacionales. |
| Mantener CONDICIONAL | 8 | `nugget`, `stardust`, `pearl`, `big_pearl`, `pearl_string`, `balm_mushroom`, `comet_shard`, `star_piece` | Economía con precios diferenciados y Lanzamiento genérico; Trozo Estrella tuvo canjes particulares. |
| Mantener CONDICIONAL | 7 | `relic_band`, `relic_copper`, `relic_crown`, `relic_gold`, `relic_silver`, `relic_statue`, `relic_vase` | Reliquias de venta, posible selección representativa para economía romana/vikinga si existe tienda. |
| Proponer DESCARTAR | 7 | `beach_glass`, `big_bamboo_shoot`, `chalky_stone`, `gold_leaf`, `lone_earring`, `marble`, `polished_mud_ball` | Valor estratégico diferenciado no localizado. Hay potencia 30 de Lanzamiento en seis; el bambú grande tiene potencia sin registrar en datos PokeAPI. No ejecutar antes de auditoría de redundancia. |

**Corrección respecto a pasada 5**: `rare_bone` ya no es un descarte sugerido por simple venta: tiene potencia 100; `big_nugget` 130. `pretty_wing` merece evaluación independiente por menor potencia. Cualquier descarte es **provisional y reversible**; no equiparar `sin otra función identificada` a `sin función`.

## Tanda de 46 formas y objetos especiales

| Propuesta | Cantidad | IDs/familia | Observación |
|---|---:|---|---|
| Mantener PERMITIR preexistente | 17 | `*_memory` de Silvally | Tipo de Silvally/Multiataque; dependen de especie y habilidad. |
| Mantener PERMITIR preexistente | 4 | ROM de Genesect | Cambios de Tecno Shock; no certificar formas solo por descriptor. |
| Mantener PERMITIR preexistente | 4 | Néctares de Oricorio | Uso desde mochila, cambios de forma. |
| Mantener PERMITIR preexistente | 3 | Máscara Fuente/Cimiento/Horno | Cambios de forma y efectos de Ogerpon; rutas especiales pendientes. |
| Mantener PERMITIR preexistente | 2 | Espada y Escudo Oxidados | Zacian y Zamazenta coronados; ruta de forma pendiente. |
| Mantener CONDICIONAL | 11 | Origen de Dialga/Palkia/Giratina (3), Prismas Rojo/Azul (2), Catálogo Rotom, Espejo Veraz, Punta ADN, Riendas Unión, Gracídea, Arca Zygarde | Cambios de forma, regresión primigenia o fusión condicionados al sistema/especie correspondiente. |
| Proponer DESCARTAR | 2 | `prison_bottle`, `teal_mask` | Vasija Castigo requiere Hoopa Desatado (forma ligada a veto previo); Máscara Turquesa no cumple el mismo papel que las otras tres. Revisar excepciones. |
| Confirmar PERMITIR previo | 3 | `adamant_orb`, `lustrous_orb`, `griseous_orb` | Ya tenían función ofensiva en matriz histórica; no son tres adiciones nuevas. |

**Control aritmético del log**: 25 + 46 = 71 IDs únicos. 33 `PERMITIR` existentes y 38 `CONDICIONAL` existentes; 0 `DESCARTAR` de partida en estos lotes. Las propuestas agregadas son 36 de mantener/promover a PERMITIR, 26 de mantener CONDICIONAL y 9 de descartar, **no autorizadas todavía como cambios del CSV maestro**.

## Auditoría final obligatoria

Al terminar los condicionales, revisar **cada permitido y cada descartado** para detectar errores, redundancias, diferencias por generación, falta de contexto, economía y peligros de desequilibrio. Criterio del usuario: conservar objetos con utilidad estratégica aunque sean malos o poco comunes; vetar solo por regla expresa, mecánica imposible/no prevista o redundancia demostrada. Registrar `ID -> efecto real -> contexto -> dependencia -> evidencia -> propuesta -> decisión humana -> estado de prueba Godot`.

**No tocar `main`, `codex/items-v28-from-main`, filtros reales ni datos canónicos.** El CSV de 71 filas es un registro auxiliar vinculado 1:1 al maestro y permite retomar en futuras conversaciones sin recomponer listas a mano.
