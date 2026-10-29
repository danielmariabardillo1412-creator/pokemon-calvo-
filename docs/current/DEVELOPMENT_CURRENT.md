# Desarrollo actual — 2026-10-29

Copia activa: D:/Proyectos/Pokemon Calvo - Arquitectura Kilo.
Arquitectura T001–T006 aceptada: 208c06c0. Correccion de region: 0e2cd3a.
El original permanece aparte. OpenCode no tiene otra tarea en curso.

Autorizacion actual: Codex corrige el fallo de region, revisa la ruta vecina y
continua con objetos mientras el usuario esta ausente. No es un nuevo encargo de
reestructurar el juego ni de completar sistemas del mundo todavia inexistentes.

Historico V5: 23 bebidas/alimentos/bayas de PS, estados y PP fuera de combate,
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

V5 cerrado en 5bbf7d1 (23 IDs nuevos, 44 efectos de campo totales). V6 terminado por pruebas:
Energy Powder, Energy Root y Heal Powder; perdidas de amistad con umbral 200,
sin bonus positivos, sin revivir. Superficie: field_item_effects.gd, descripcion
field_item_bag.gd, pruebas/contrato/runner V6 y docs. Se generaliza solo la firma
del verificador de alcance V5 para declarar base y allowlist sin cambiar su modo
historico por defecto. No se modifica autoridad de inventario ni guardado.

Preparacion del siguiente lote (solo investigado, aun sin implementar): 6 vitaminas
(+10 EV) y 6 plumas (+1 EV), limite moderno 252 por estadistica/510 total.
Referencia local Essentials 8c5911e: Item Effects 714–829, Item Utilities 401–439,
Pokemon.changeHappiness 929–968. Vitaminas base amistad [5,3,2], plumas [3,2,1]
con cortes 100/200; Campana Alivio multiplica ganancias positivas. El perfil
competitivo local no usa affection/soft cap (002_BattleSettings.rb: AFFECTION_EFFECTS
false; APPLY_HAPPINESS_SOFT_CAP enlazado). Bonus por origen de captura siguen
pendientes como V4, porque CreatureInstance no los almacena. No implementar IV o
mints cambiando IV/naturaleza real: distinguir datos originales/efectivos antes.
XP y nuevas evoluciones requieren respetar las decisiones de movimientos y forma;
no consumir caramelos simulando solamente un cambio de nivel.

V6 terminado: 3 IDs nuevos, 47 efectos de campo totales. Evidencia e integridad
PASS; queda pendiente iniciar vitaminas/plumas bajo un contrato propio V7.

V7 terminado contra 87a96506: doce vitaminas/plumas (IDs canonicos *_wing).
Nuevo helper puro field_training_effects.gd; facade FieldItemEffects valida EV
originales antes de serializar para no truncar valores invalidos. El servicio
mantiene sus transacciones y guard de identidad. Archivos runtime autorizados:
helper nuevo, field_item_effects.gd, field_item_service.gd y descripcion de bag.
Tambien runner/pruebas/contrato V7 nuevos y docs de estado. Sin cambios a datos,
politicas, arquitectura de mundo, schema, motor de combate o arte.

Peticion posterior del usuario — comparador general (2026-10-29): despues de
terminar el lote actual, preparar comprobacion automatica amplia entre la base
anterior (spaghetti) y esta copia organizada. No se inicia durante V7. Probar en
copias aisladas, nunca contra partidas reales: mismas semillas/acciones, comparar
estado de equipo/PC, inventario, campo, progresion, combate y guardado/carga.
Las funciones nuevas introducen diferencias esperadas que deben declararse.
Anadir resultados independientes conocidos: equivalencia entre dos versiones no
prueba ausencia de errores compartidos. Informar cobertura y dependencias sin
presentar PASS de unos escenarios como garantia universal.

V7 cerrado por pruebas: 12 IDs nuevos, 59 efectos de campo totales (41 de
recuperacion y 18 EV/amistad base). 6990/6991 checks, 10 grupos y hash completo
PASS. Siguiente trabajo autorizado por el usuario: comparador general de las dos
versiones en copias aisladas. Aun no hay un comparador general certificado.
