# Orden de trabajo — continuar de forma autónoma por familias

## O100 — reconciliar inventario y contratos

Estado inicial contrastado: 2.222 entradas canónicas; 77 efectos de campo (42
recuperación y 35 entrenamiento), 16 bolas en calvo_capture_v1, 229 máquinas
enseñables en el perfil activo, 618/625 equipables presentes en nativo, 18 usos
directos de mochila nativa (15 medicinas y 3 huida). No sumar categorías con
IDs repetidos. Los informes V1–V21 son evidencia de su alcance, no autorización
para reabrir migraciones. V19 clasifica una familia, no certifica todo el catálogo.

Los siete huecos son amulet_coin, cleanse_tag, exp_share, linking_cord,
luck_incense, pure_incense, smoke_ball. Los ocho potenciadores de mochila siguen
pendientes aunque sus descriptores equipados existan. Se ha corregido en la
preparación de esta misión una lista antigua que aún contenía diecinueve IDs;
ambos nombres del pendiente actual deben seguir coincidiendo con los siete.

Crear `tools/item_import/audit_item_closure_v2.py`, su prueba y COVERAGE.json/CSV
en esta carpeta. Barrido automático de los 2.222 IDs a partir del catálogo,
políticas, conexiones vigentes y registros reales. Por ID separar al menos:
permiso, arte, equipar, metadato nativo, uso de campo, uso en combate, evolución,
máquina y escenario ejecutado. Estados por contexto: IMPLEMENTED_VERIFIED,
IMPLEMENTED_UNVERIFIED, PARTIAL_VERIFIED, DEPENDENCY_MISSING, EXCLUDED,
NOT_APPLICABLE, UNKNOWN_REQUIRES_REVIEW. Indicar fuente/evidencia y dependencia.
No convertir la ausencia en un informe histórico en fallo del juego; no convertir
un ID presente en «funciona». Extraer por programa; no escribir 2.222 juicios a mano.

No rehacer funciones cerradas ni alterar los datasets para resolver el inventario.
Guardar evidencia de O100 y continuar directamente con O110.

## O110 — once usos de combate en un lote

Ver O110_BATTLE_SUPPORT.md. Seis X + Dire Hit + Guard Spec + tres flautas.
Trabajar por comportamiento compartido y probar todas las filas en lote.
Se permiten comprobaciones internas pequeñas; la entrega es la familia completa,
con contextos que de verdad no puedan soportarse explícitamente pendientes.
Al cerrar sus puertas, hacer checkpoint local y continuar con O120 sin consultar.

## O120 — equipados con contexto existente

Ver O120_HELD_CONTEXTS.md. Prioridad: Bola Humo; después Amuleto/Puro (Cleanse Tag
y Pure Incense) si su contexto puede representarse fielmente dentro del perfil
existente. No registrar esos IDs como neutros para reducir el contador. Procesar
la familia completa; documentar diferencias de perfil y partes no soportadas.

Los otros cuatro huecos no se activan arbitrariamente: Amulet Coin/Luck Incense
requieren premios/economía y posiblemente crianza; Exp. Share necesita un perfil
de reparto coherente con calvo_progression_v1 (ya hay reparto de equipo); Linking
Cord necesita una ruta evolutiva expresa, sin cambiar intercambio por nivel/objeto
en los datos canónicos. Auditar consumidores y dejar explicación precisa. No
crear esos sistemas ni rediseñar el reparto/evolución para resolver esta misión.

## O190 — cierre conjunto, sin huecos ocultos

Actualizar COVERAGE y contadores desde el código final, sin duplicados. Por cada
DEPENDENCY_MISSING explicar el dato/sistema/decisión que falta y el rechazo sin
consumo. La lista UNKNOWN debe tener investigación concreta; no usarla como
cajón automático para todo lo que no aparezca en V19.

Fuera de implementación: mentas/IV con campos persistentes nuevos, condiciones
evolutivas/formas nuevas, crianza/concursos/economía, mapas finales, Cuerda Huida,
historial de capturas, fidelity de todas las bolas/XP por generación, multijugador,
IA, nuevas reglas randomlocke y arte. Si un sistema ya soporta otro caso y solo
hay que identificarlo, reflejarlo en el inventario; no implementarlo fuera de scope.

Crear `tools/verification/run_opencode_closure_v2.py`: orquestar las pruebas
nuevas y regresiones relevantes con procesos reales, logs por ejecución,
timeouts y conteos. Reutilizar `LocalPhase.run_godot`, no falsificar salidas.
No ejecutar los runners históricos como si fueran guards de la versión nueva:
sus baselines y allowlists son históricos. Sí reutilizar sus scripts de pruebas
sin editar expectativas. Guard de esta misión antes/después, completo al cerrar.

Mínimos conjuntos: nuevos runners O110/O120; core; medicina nativa y visual;
aventura nativa; campo/restauración; V21 huida y GPU; V19 recuperación; V18
progresión si cambia proyección de amistad/objetos; pruebas de encuentros si se
toca ese contexto; guards de esquema/compatibilidad de guardados afectados.
No repetir indefinidamente suites ya verdes si el código no ha cambiado.

Conservar resultados anteriores y capturas antes de sobrescribir salidas raíz.
Un exit 0 sin comprobaciones no es PASS; timeout no es PASS; no sumar casos no
ejecutados. Los resultados deben identificar SHA de fuentes y código probado.
Documentar toda sustitución de recurso si ocurriese, pero esta misión no autoriza
cambiar arte. Revisar capturas de mochila y estados antes de declarar revisión visual.

Entregar FINAL_REVIEW.md y FINAL_RESULTS.json: rango de commits; tareas completas,
parciales y dependencias; IDs por contexto; comandos, conteos, logs, duración,
fuentes/créditos; incidencias corregidas y riesgos. Nunca ACCEPTED_BY_CODEX.

## Ritmo y recuperación

- Mantener STATE.json/PROGRESS.md tras cada familia y antes de un corte. Al
  reanudar, leerlos y cotejar git diff, logs y procesos reales antes de repetir.
- Continuar de O100 a O190 sin informes finales por objeto ni espera de Codex.
- Las dependencias detectadas antes de implementar se anotan y se sigue con
  trabajo independiente. No detener toda la misión porque falte una mecánica.
- Si una familia falla, corregirla dentro del contrato. No dejar un cableado a
  medias que afecte al resto. Si no se puede aislar de forma segura, parar con el
  motivo concreto, el diff y evidencia; no restaurar ni eliminar trabajo ajeno.
- Parar ante cambios ajenos inesperados, falta de integridad o necesidad real
  de salir de los archivos/funciones autorizados. No ampliar tu propio contrato.
- No alterar fixtures, tests antiguos, paquetes o políticas para obtener verde.
