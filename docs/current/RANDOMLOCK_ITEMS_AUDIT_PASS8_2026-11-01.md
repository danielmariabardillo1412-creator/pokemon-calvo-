# Octava pasada — primera auditoría inversa de permitidos y descartados (2026-11-01)

**Propósito:** comprobar que la selección original no ha mantenido objetos sin encaje real ni descartado alguno con utilidad oculta. Esta **no es la auditoría final exhaustiva**, sino un lote dirigido de anomalías para que ninguna se pierda.

## Control del lote

- Se revisan **15 IDs** por nombre, categoría, evidencia de uso y riesgo: **14 previamente PERMITIR** y **1 previamente DESCARTAR**.
- Fuente por ID y puerta de acción: [RANDOMLOCK_ITEMS_AUDITORIA_INVERSA_V1.csv](./RANDOMLOCK_ITEMS_AUDITORIA_INVERSA_V1.csv).
- El catálogo de **2.222 sigue igual: 706 / 290 / 1.226**. No se han corregido filtros activos ni ejecutado pruebas Godot.
- Un filtro de compatibilidad automática no sustituye a la aprobación humana ni al contraste técnico.

## Sospecha de falso negativo — 1 ID

**`armorite_ore` (Duralium)** figura `DESCARTAR` bajo ausencia de incursiones, pero el recurso también se usa para **tutores de movimientos y reinicio de EV** en Espada/Escudo. **Propuesta: CONDICIONAL**, hasta que exista o se descarte el servicio correspondiente. Ya lo detectó la quinta auditoría; aquí queda individualizado para la auditoría inversa. Referencia: https://bulbapedia.bulbagarden.net/wiki/Armorite_Ore.

## Permisos que merecen nueva comprobación

1. **`park_ball`**: la Parque Ball de Pal Park tiene captura garantizada en su contexto original, pero **no es una Ball normal distribuible**; introducirla en la bolsa sería una decisión de diseño nueva, quizá comparable a añadir otra Master Ball. **Propuesta de descarte de generación si no existe Pal Park**. https://bulbapedia.bulbagarden.net/wiki/Park_Ball
2. **`cherish_ball`**: la Gloria Ball es propia de Pokémon de distribución; normalmente no se obtiene como objeto. En Calvo existe una ruta técnica de captura V15. **No deshacer código**; discutir si es un objeto único de eventos, una recompensa o una Ball normal de aspecto distinto. https://bulbapedia.bulbagarden.net/wiki/Cherish_Ball
3. **`premier_ball`**: Honor Ball tiene modificador ordinario 1x, igual a Poké Ball en juegos principales, aunque la función de premio/coleccionismo puede diferir. Revisar duplicación sin destruirla ni confundir con la Premier Ball de Pokémon GO. https://bulbapedia.bulbagarden.net/wiki/Premier_Ball
4. **`sport_ball`, `safari_ball`**: mantener autorización vigente porque Calvo ya había conectado sus perfiles en V15. Su origen temático no invalida su utilidad real. La distribución por mapa es tema distinto. Ver [ITEM_CAPTURE_V15.md](./ITEM_CAPTURE_V15.md).
5. **`max_mushrooms`**: no descartar como comida de incursión. En batalla puede **subir en un nivel cinco estadísticas**, y fuera de combate se emplea en Maxisopa. Es un objeto estratégico fuerte que requiere límites de acceso, cantidades y compatibilidad PvP. https://www.serebii.net/itemdex/maxmushrooms.shtml
6. **`lure`, `super_lure`, `max_lure`**: los atrayentes de Let's Go cambian encuentros, rareza y duración (100/200/250 pasos aproximadamente). No son exactamente idénticos, pero un randomlocke debe tener reglas de encuentro antes de activarlos. https://www.serebii.net/letsgopikachueevee/lures.shtml
7. **`escape_rope`**: solo es útil si hay mazmorras o una navegación que admita retorno; no considerarla operativa por existir en mochila.
8. **`master_ball`**: se mantiene como recurso estratégico potente; revisar obtención para que el randomlocke no pierda desafío. No prohibir unilateralmente.
9. **`leaders_crest`**: recordar ruta evolutiva de Bisharp; la etiqueta picnic era un falso descarte ya corregido. No volver a descartarlo.
10. **`rage_candy_bar`**: función curativa distinta entre generaciones; no mezclar efectos ni duplicar una medicina si no aporta diferencia por perfil.
11. **`beast_ball`**: conservar la recuperación acordada por usuario para Ultraentes. Falta verificar condiciones completas de captura, no volver a tratarla como objeto de incursión.

## Alcance de la auditoría inversa futura

Este primer lote no acredita haber revisado manualmente los **706 permitidos y 1.226 descartados** uno por uno. Se necesita continuación dirigida a (a) bayas con función de concurso o fuera de combate; (b) entrenamiento y estadísticas por generación; (c) objetos de captura con bonificaciones dependientes del mapa; (d) categorías de historia con funciones ocultas; (e) eliminaciones por similitud nominal; (f) permisos sin sistema real. La pasada 7 ya dejó matriz completa de los 290 condicionales.

Los estados propuestos no se aplican todavía a `RANDOMLOCK_ITEMS_SCOPE_V1.csv`, `config/item_selection_v1.json`, `main` ni V28.
