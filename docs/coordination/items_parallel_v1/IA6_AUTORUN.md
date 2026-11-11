# IA6 — VETO CARAMELO DINAMAX / dinamax_candy — 2026-11-11

**ORDEN VINCULANTE A W05:** el usuario descartó `dynamax_candy`. Ya está en `config/item_selection_v1.json::excluded_ids` de TU rama y el test de política exige rechazo de generación. No seleccionarlo, no incluirlo en nuevas colas de objetos ni invertir trabajo en su arte/función; los CSV antiguos `CANDIDATE`/`RETAIN_FOR_FUNCTIONAL_REVIEW` son auditorías HISTÓRICAS, no autorización. Excluye solo este ítem, no Rare Candy/Exp Candy/otras mecánicas no discutidas. Dictamen completo en rama árbitra: `docs/coordination/items_parallel_v1/IA6_EXCLUSION_DYNAMAX_CANDY_20261111.md`. El resto de TU plan continuo sigue vigente.

---

# IA6 — W05 · CAMPAÑA CONTINUA V3 AUTORIZADA

**IA6 REVISÓ TU CAMPAÑA V2 Y TE ASIGNA ESTA NUEVA MISIÓN, NO ESTÁS EN ESPERA.** El archivo que estás leyendo en TU propia rama `codex/calvo-items-20261109-w05-books-ui` es la orden vigente. El plan V2 anterior está agotado y se conserva en GitHub para trazabilidad; **NO repetir IDs o pruebas certificadas de V2**. La misión V3 tiene tres fases y no termina artificialmente al completar 10/10. Cada `p`/`sigue` recupera `docs/coordination/items_parallel_v1/CONTINUOUS_V3/STATE_W05.md` y reanuda la primera fase/tarea pendiente; al finalizar una fase con CI correcta empieza inmediatamente la siguiente sin esperar a IA6, en el mismo turno si es posible.

**Autoridad y política:** protocolo árbitra `docs/coordination/items_parallel_v1/CONTINUOUS_V3/README.md`, plan central `docs/coordination/items_parallel_v1/CONTINUOUS_V3/PLAN_W05.md`, rama árbitra `codex/calvo-items-20261101-arbitro`. La copia íntegra del plan está debajo. Esta autorización es expresa para los módulos/funciones enumerados, pero NO permite cambios globales ajenos, ni tocar `main`, V28, PR118, ni ramas de otras W. No atribuir CI a SHA distinta ni integración final a IA6 sin ver su CI. Si todas las fases posibles se agotan o dependen de seam protegida, publicar READY_FOR_IA6 con ticket real y STOP. Si el turno se agota antes, checkpoint GitHub y siguiente `p`, sin otra autorización ni promesa de background.

**Barra correcta:** campaña fase A/B/C + tareas | objetos nuevos | L3 comprobados | bloqueados | integración IA6 pendiente. **No usar 10/10 como sinónimo de 10 objetos.**

---

# IA6 W05 · CAMPAÑA CONTINUA V3 — MONTAJE REAL DE LIBROS EN MOCHILA
Rama: codex/calvo-items-20261109-w05-books-ui.
Baseline: V2 final CI #42929830881 SUCCESS. 229 MT enseñables, 229 nombres españoles en PCK Windows y consumidor aislado; 0 MT nuevas. Falta panel montado dentro de FieldItemBag.

PERMISO EXCEPCIONAL IA6 EN RAMA W05: editar SOLO scenes/visual/field_item_bag.gd en funciones _ready, open_bag, _refresh_choices, _apply y callback LOCAL NUEVO de enseñanza, exclusivamente para libros. Nunca copiar el archivo entero a la integración: IA6 trasplantará únicamente los cambios precisos. Los cambios W03 de repelentes/Cuerda Huida pueden no estar presentes en la rama W05.

FASE A: prueba roja con FieldItemBag real, leer W05_IA6_ACCEPTANCE.md y las APIs FieldMachineBookPanel.bind_existing_service, select_book, select_creature, select_replacement_slot, teaching_finished. Crear una sola instancia de panel y compartir el mismo FieldItemService; usar IDs de libro y de Pokémon reales, nunca índices inestables. El callback SOLO refresca; no hace un segundo teach/use_item. Bloquear clic doble.
FASE B: pruebas nativas Godot de mochila, cuatro movimientos y slot 0–3, Party/Storage y retiro del elegido, stock agotado, bloqueo, cambios durante selección, cancelación, PP, dueño, SaveV2 manual sin autosave, reabrir y no duplicar señales ni gastos. Mantener 229 enseñanzas anteriores, traducciones ES, export PCK y CAMP003–006.
FASE C: CI de W05, informe reports/W05/CONTINUOUS_V3_FINAL.md y diff mínimo para IA6; verificar estructuralmente colisiones con Cuerda Huida y repelentes según rama integración, SIN decir que están realmente integrados en W05. Windows GPU y Android no certificados hasta prueba real. No añadir MT inventadas.

PROTEGIDOS: FieldItemService, FieldNativeSave, PlayerCollection, GameData, SaveV2, Showdown, otras ramas, main/V28/PR118. El objetivo es L3 en mochila de rama W05, NO en producto integrado hasta CI posterior de IA6. Fases continuas, p/sigue reanuda STATE_W05.md, STOP solo al agotar misión READY_FOR_IA6 o bloqueo técnico sin filas independientes.
