# Auditoría 12 — clasificación de los 125 condicionales

Fecha: 2026-11-01. Alcance: selección documental de Pokémon Calvo.

## Resultado
- PERMITIR: 778.
- DESCARTAR: 1340.
- APARCADO_MEGA: 104.
- CONDICIONAL: 0.
- Total: 2222 ID sin borrar. De los 125 pendientes ordinarios, 68 se proponen permitidos y 57 descartados.

## Familias
- Cristales Z: 32 permitidos; solo acciones Z ofensivas.
- Máquinas históricas: 19 libros útiles permitidos; hm02, hm03 y hm07 descartadas por repetir un ataque enseñado en MT activa.
- Cambios de forma: 12 permitidos, 9 descartados. Fragmento Meteorito es historia, mientras Meteorito cambia forma de Deoxys. Crin Blanca y Crin Negra son materiales de Riendas Unión. Máscara Turquesa es forma base de Ogerpon.
- Tesoros: 5 permitidos (big_nugget, rare_bone, pretty_wing, nugget y heart_scale), 35 descartados. Los primeros cuatro necesitan verificar equipamiento y Lanzamiento; la Escama Corazón necesita servicio de reaprendizaje.
- Poké Balls de Hisui: 9 descartadas al no haber captura libre con distancia y sigilo.
- Superpulsera Z: descartada como objeto generable, sin excluir el sistema Z.

## Mega separada
Los 92 ID históricos de megapiedras y 12 accesorios se guardan como APARCADO_MEGA en archivo propio, no son condicionales. El usuario reafirma la futura creación de un tipo de piedra Mega universal con dos copias por partida. El ID universal todavía no existe y la mecánica no se ha implementado. Las reglas de elegibilidad y una Mega activa por combate deben definirse/verificarse en esa fase.

## Archivos
- RANDOMLOCK_ITEMS_SCOPE_V1.csv: catálogo canónico con los 2222 ID.
- RANDOMLOCK_ITEMS_BUILD_SCOPE_V1.csv: 778 objetos seleccionados para trabajo.
- RANDOMLOCK_ITEMS_MEGA_APARCADO_V1.csv: 104 referencias originales Mega.
- RANDOMLOCK_ITEMS_AUDIT_PASS12_CHANGES.csv: estado y motivo de cada uno de los 125 cambios.

Todas las decisiones de esta auditoría son preselecciones técnicas reversibles, salvo las reafirmadas por el usuario. No se ha alterado la rama principal, V28, motor, política activa, escenas, inventarios ni guardados. Los objetos funcionales previos se conservan conectados. Queda revisión inversa de los 778 permitidos y 1340 descartados, y verificación funcional de los elegidos.
