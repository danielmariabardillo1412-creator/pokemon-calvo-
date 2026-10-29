# Desarrollo actual — 2026-10-29

Copia activa: D:/Proyectos/Pokemon Calvo - Arquitectura Kilo.
Arquitectura T001–T006 aceptada: 208c06c0. Correccion de region: 0e2cd3a.
El original permanece aparte. OpenCode no tiene otra tarea en curso.

Autorizacion actual: Codex corrige el fallo de region, revisa la ruta vecina y
continua con objetos mientras el usuario esta ausente. No es un nuevo encargo de
reestructurar el juego ni de completar sistemas del mundo todavia inexistentes.

Lote activo V5: 23 bebidas/alimentos/bayas de PS, estados y PP fuera de combate,
reutilizando FieldItemService y FieldItemEffects. Perfil moderno (Gen 7+) basado
en la copia local fijada de Pokemon Essentials; no se ejecuta su Ruby.
Archivos de runtime permitidos: field_item_effects.gd, field_item_service.gd,
field_item_bag.gd y nuevo field_recovery_profile.json. Pruebas/runner/contrato V5
nuevos y documentos de estado. field_demo y puente nativo quedan intactos.
No se modifica el contrato de medicina en combate ni los efectos equipados.

Pendientes conocidos: hierbas amargas y amistad, vitaminas/plumas y entrenamiento,
XP/IV/naturalezas/habilidades, formas por objetos, origen de captura, maquinas
antiguas, evoluciones condicionadas y sistemas del mundo. Consultar estado vigente
ITEM_SYSTEM_CURRENT_STATUS.json y los informes incrementales antes de continuar.
