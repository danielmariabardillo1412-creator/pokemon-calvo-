# W04 — CAMPAÑA_001 — INFORME FINAL

**Estado de entrega: 03/03 PREPARADOS; verificación funcional final IA6 PENDIENTE.**

| Microbloque | Cobertura | Evidencia |
|---|---|---|
| 01 | Fuego, Agua, Trueno; seis rutas positivas y rechazos | `CAMP_001_ITER_01.md`; 40/40 estructurales de aquella iteración |
| 02 | Hoja, Hielo, Lunar; cinco rutas y condicionante Vulpix-Alola | `CAMP_001_ITER_02.md`; 44/44 estructurales de aquella iteración |
| 03 | SaveV2 de seis piedras en PARTY/STORAGE (12), consumo único, atributos, ID, carga y rechazo | `CAMP_001_ITER_03.md`; **no ejecutado todavía en Godot/Python** |

IA6 documentó **313 checks PASS / 12 casos** del runner previo, en staging #41350981613; run global fallido por W02. No atribuir esas 313 pruebas a ITER_03.

**Resultado de preparación:** los scripts y reportes exclusivos de W04 se publicaron en su rama; sin modificación de sistemas de evolución, guardados de producción, `main`, V28 o árbitra.

**Para cierre funcional IA6:** integrar de forma controlada, importar Godot 4.7, ejecutar validador Python y runner Godot en SHA integrado, comprobar 12 `save_results` y ausencia de FAIL, publicar CI y SHA exactos. Si no se cumple, mantener PENDIENTE_CI.

**Decisión de clasificación:** rutas por piedra previamente soportadas en el runner; persistencia SaveV2 **preparada pero no certificada**; ruta regional Vulpix-Alola **condicionada**, sin simplificación de reglas. Sin nueva programación de producción.

**STOP W04: CAMPAÑA_001_FINALIZADA (entrega documental y tests; no certificado funcional).**
