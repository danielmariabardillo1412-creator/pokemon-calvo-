# ESTADO DE COORDINACIÓN — LÍNEA BASE / SIN LOTES EN CURSO

**Fecha:** 2026-11-01. **Fase:** cuaderno preparado; seis conversaciones se abrirán manualmente por el usuario. Este archivo se actualizará **solo en la rama de la árbitra** después del arranque, no en las ramas operarias.

## Contabilidad que NO debe confundirse
- 2.222 IDs canónicos: 743 PERMITIR, 1.375 DESCARTAR, 104 APARCADO_MEGA, 0 CONDICIONAL.
- 744 tipos en la nueva lista operativa: 743 tipos seleccionados canónicos y 1 tipo Mega universal `mega_stone_universal`.
- Exactamente DOS piedras físicas por partida y HASTA DOS megaevoluciones por entrenador y combate; portadores bloqueados durante batalla.
- 743 IDs ordinarios para **triaje técnico**, NO 743 efectos pendientes de programar. Las familias contienen muchas implementaciones existentes.
- La Mega universal no se programa en esta fase; los otros 104 metadatos Mega tampoco.

## Coordinación (estado inicial, antes de enviar los prompts)

| Conversación | Rama | Familias del ámbito | ID en cola | Lote activo | Resultado actual |
|---|---|---|---:|---|---|
| ÁRBITRA | `codex/calvo-items-20261101-arbitro` | coordinación y merge revisado | 744 | Ninguno | SIN_INICIAR |
| W01 | `codex/calvo-items-20261101-w01` | equipables y potenciadores de batalla | 186 | Ninguno | SIN_INICIAR |
| W02 | `codex/calvo-items-20261101-w02` | medicinas, bayas y entrenamiento | 148 | Ninguno | SIN_INICIAR |
| W03 | `codex/calvo-items-20261101-w03` | captura, campo, Z, Tera | 89 | Ninguno | SIN_INICIAR |
| W04 | `codex/calvo-items-20261101-w04` | evolución, formas, recursos útiles | 72 | Ninguno | SIN_INICIAR |
| W05 | `codex/calvo-items-20261101-w05` | libros de movimientos | 248 | Ninguno | SIN_INICIAR |

**Cómo continuar:** abrir primero el prompt de la ÁRBITRA en `PROMPTS_6_CHATS.md`. La árbitra publica los ficheros `assignments/LOTE_001_W0X.md` y reserva IDs/archivos, después se inicia cada W. Al terminar cada W, sus informes en `reports/W0X/` dan la evidencia para avanzar el tablero. Una W no debe autoadjudicarse trabajo.

**Protecciones:** main intacta, rama V28/PR #118 intactos, motor de Godot intacto, selección activa runtime intacta, nada desconectado por la clasificación documental. No existe una integración aprobada todavía. No presentar documentación como prueba de efectos.
