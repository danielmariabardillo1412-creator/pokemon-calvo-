# Etapas posteriores — requieren revisión y nuevos contratos

T001–T004 aceptados. Solo T005 está abierto bajo su contrato específico.
Este mapa no autoriza T006.

T003: separar formateo/renderizado del HUD a partir de una vista de datos
explícita. Contrato ejecutable: tasks/T003_HUD_RENDER.md.

T004 (aceptado): contrato tasks/T004_FIELD_DIAGNOSTICS.md. Separar catálogo,
selección, ciclos y despacho de teclas F4–F11 del flujo normal de la
partida. Preservar el comportamiento explícito de reinicio de los ensayos y todas
las teclas existentes. No confundir presets de prueba con cambios de learnset.

T005 (activo): contrato tasks/T005_FIELD_API.md. Definir la interfaz pública del campo para UI y coordinación: colección,
estado de actividad, servicio de mochila, notificaciones y datos de encuentros.
Revisar propiedad, publicación y sustitución de colección al cargar. Requiere
pruebas de identidad, guardado, reloj de sueño y bloqueo durante combate.

T006: reducir accesos internos en el puente nativo y aclarar la inicialización
del laboratorio anterior. Dibujar primero el recorrido de boot/carga; no borrar
legado. Esta etapa cruza autoridad del estado y exige revisión previa de Codex.

La portabilidad del ejecutable Node, el empaquetado y cualquier eliminación de
motor anterior serán encargos separados. Las mecánicas pendientes de objetos y
la IA de entrenadores tampoco se incorporan como arreglos de arquitectura.
