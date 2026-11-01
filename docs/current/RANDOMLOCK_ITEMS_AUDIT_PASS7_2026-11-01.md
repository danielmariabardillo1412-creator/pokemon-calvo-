# Séptima revisión — matriz de los 290 condicionales (1-XI-2026)

**Carácter: auditoría documental, no cambios de mecánica ni política activa.** Se han tomado los 290 IDs `CONDICIONAL` de [RANDOMLOCK_ITEMS_SCOPE_V1.csv](./RANDOMLOCK_ITEMS_SCOPE_V1.csv) y añadido la [matriz de revisión V2](./RANDOMLOCK_ITEMS_CONDITIONAL_MATRIX_V2.csv) con una fila por ID, función, dependencia, riesgo y propuesta. **Todas las 38 entradas condicionales de la sexta auditoría mantienen su propuesta previa**; no se reescriben por una regla familiar.

## Estado de control

- Catálogo maestro sin cambios: **706 PERMITIR, 290 CONDICIONAL, 1.226 DESCARTAR = 2.222**, todos identificados.
- **290 condicionales** clasificados por puerta de decisión: **104 Mega aplazados** y **186 de la fase ordinaria**, de los que **38 ya tenían revisión individual V6**.
- De los 186 ordinarios, los 148 sin revisión individual de la última conversación tienen una **primera propuesta familiar explícita**. No equivalen a 148 decisiones aprobadas ni a pruebas Godot.
- El movimiento `fling` / Lanzamiento puede dar función extra a tesoros; el juicio por venta o metadato vacío **no basta** para excluir. Conservar especialmente `rare_bone` (100), `big_nugget` (130) y diferencias bajas de potencia que puedan activar efectos entre aliados.

## Familias que pueden resolverse como bloque

| IDs | Familia/criterio | Propuesta revisable |
|---:|---|---|
| **104** | Megapiedras y activadores | **Apartados, no descartados**. Mantener Mega para una fase posterior con compañero y sistema propio. |
| **32** | Cristales Z restantes | **Conservar condicionales por conexión**, ya se aprobaron Z ofensivos y se vetaron Z de estado. No repetir debate sobre ataques Z. |
| **22** | MT/MO/DT antiguas | 19 libros con movimiento sin equivalente en el perfil activo; 3 MO que sí duplican ataque pero podrían conservar uso de campo. No eliminar movimientos. |
| **15** | Fósiles restaurables | No son objetos de revivir a un Pokémon derrotado. Decidir si fósil restaurado cuenta como encuentro, si se randomiza y si hay límite. |
| **9** | Bolas Hisui | 3 tradicionales con alternativa ya presente; 6 especiales de distancia/sigilo. Proponer retirar 3 duplicados **solo si no hay captura estilo Hisui**. |
| **6** | Bayas de captura Let's Go | Frambu dorada/plateada aumentan facilidad de captura; Latano calma al objetivo y Pinia cambia recompensas. Requieren contexto propio. |
| **23** | Legado y objetos Roto | Fusionar/separar son representaciones internas, no varios objetos a distribuir; 11 poderes Roto requieren reglas propias de aventura/PvP. El aro Z no es botín ordinario. |
| **41** | Tesoros | Conservar las 25+ revisiones específicas de pasada 5/6; los siete recursos de tutor, tres materiales útiles y economía necesitan dependencias. |
| **53** | Llaves/forma/mapa fuera de Mega | Incluye 15 fósiles ya contados: estudiar formas, pesca, transporte, captura, XP, acceso remoto, revanchas, etc. No sumar familias solapadas. |

## Hallazgos concretos y no equivalencias

1. **Poké Balls Hisui**: `lapoke_ball`, `lagreat_ball` y `laultra_ball` tienen fórmulas originales de Hisui, pero si la aventura solo tiene captura por turnos serían candidatas a retiro como variantes redundantes. **No marcarlo como veto aprobado**. `lafeather_ball`, `lawing_ball`, `lajet_ball`, `laheavy_ball`, `laleaden_ball` y `lagigaton_ball` tienen condiciones de distancia, movilidad o sigilo. Referencias: https://legends.arceus.pokemon.com/en-us/gameplay/ y https://www.serebii.net/legendsarceus/capture.shtml.
2. **Bayas Let's Go**: `golden_razz_berry` y `silver_razz_berry` sí facilitan capturar; `golden_nanab_berry`/`silver_nanab_berry` calman al objetivo en la interfaz de lanzamiento; `golden_pinap_berry`/`silver_pinap_berry` mejoran recompensas. **No programar las cuatro últimas como un bonus genérico de captura**. Fuente: https://www.serebii.net/letsgopikachueevee/items.shtml.
3. **MT/MO/DT**: conservar como libros solo el movimiento realmente útil y compatible; no recuperar 87 DT redundantes. De los 22 condicionales, **19 enseñan movimientos sin MT activa equivalente**, y `hm02/hm03/hm07` ya tienen ataque compartido y son candidatos solo por reglas de campo. Referencia: [cuarta auditoría](./RANDOMLOCK_ITEMS_AUDIT_PASS4_2026-11-01.md) y https://bulbapedia.bulbagarden.net/wiki/List_of_TMs_and_TRs_in_Pok%C3%A9mon_Sword_and_Shield.
4. **Fósiles**: restaurar fósiles crea un Pokémon; no cura ni revive uno caído en combate. El randomlocke debe decidir si es encuentro válido, premio adicional o fuente excluida. Las cuatro piezas de Galar tienen reglas de combinación distintas.
5. **Fusiones/alias**: `dna_splicers_merge/split`, `reins_of_unity_merge/split`, `n_solarizer_merge/split`, `n_lunarizer_merge/split` y `meteorite_2/3/4` son **11 IDs de representación/operación**, no 11 herramientas físicas distintas. No borrar IDs canónicos, pero no generarlos como objetos independientes del jugador.
6. **Poderes Roto**: separar recompensa/dinero/encuentro/XP/amistad/cura/PP/eclosión/boost; algunos son estratégicos, otros incompatibles con combate PvP o pueden permitir farmeo ilimitado. Registrar efectos y límites antes de permitir.
7. **Accesorios Z**: `z_ring`, `z_power_ring`, `sparkling_stone` no son nuevos cristales ni ataques. Deberá elegirse una representación de activación sin repartir objetos duplicados. La existencia de 32 cristales condicionales no reabre los 3 excluidos.
8. **Interfaz y mapa**: bicicletas, cañas, Zahorí, Mapa, Buscapelea, Caja de Pokémon pueden ser funciones de mundo/UI y no botín aleatorio. Ninguno debe activarse hasta fijar si el mapa necesita esa herramienta. `pokemon_box_link` merece especial cuidado porque el acceso remoto puede evitar restricciones del randomlocke.
9. **Equilibrio**: Amuleto Captura, Amuleto Exp., Pokéradar, Amuleto Iris y Roto Refuerzo no son automáticamente descartables, pero requieren reglas específicas para evitar capturas/XP o mejoras infinitas. No introducir sistemas imaginarios para justificar objetos.

## Cómo usar el resultado sin perder continuidad

El CSV maestro sigue siendo la **fuente de estados vigentes**, la sexta auditoría conserva la **revisión concreta de 71 IDs**, y la matriz V2 adjunta una **puerta de resolución a cada uno de los 290 condicionales**. La decisión `PROPONER_...` no cambia ni el CSV maestro ni `config/item_selection_v1.json`; la propuesta `CONSERVAR_CONDICIONAL` tampoco certifica mecánica.

**Siguiente trabajo**: resolver decisiones de diseño transversales (captura estilo Hisui, fósiles como encuentros, tutores, economía, poderes Roto, campo y formas). Después aplicar únicamente lo aprobado a un **borrador de catálogo nuevo**, auditoría inversa de 706 permitidos y 1.226 descartados, comprobar conteos y finalmente contrastar con motor Godot. La rama principal y V28 están fuera de alcance.

No se han ejecutado pruebas Godot ni modificado el motor en esta auditoría.
