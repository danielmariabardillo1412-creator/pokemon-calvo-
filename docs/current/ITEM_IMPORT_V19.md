# V19 — Importación automática por familias

Base `0a139088`, copia organizada en D:. El piloto convierte reglas declarativas
existentes en un manifiesto que usa el servicio real, por petición del usuario.

## Resultado

42 IDs compilados: **41 efectos anteriores preservados y una ruta nueva**.
Flauta Azul despierta, limpia el reloj de sueño y se reutiliza sin gastar
unidades. Debe poseerse y tener efecto. El total de efectos de campo pasa de 76
a **77**, sin bolas ni máquinas. Los 19 equipables sin definición nativa siguen
pendientes; el uso de campo de Flauta Azul no añade su definición equipada.

Las cantidades HP, estados, confusión, PP de uno/todos y penalización de amistad
proceden de máscaras y argumentos, no de descripciones. Las 41 expectativas
anteriores siguen como contraste independiente: un conflicto aborta la generación.
Perfil explícito: cantidades modernas, Sitrus de un cuarto y disponibilidad de
campo de RHH. No certifica disponibilidad de cada objeto en cada juego oficial;
la Flauta Azul sigue la disponibilidad de esta referencia comunitaria.

El barrido clasifica 2.222 IDs: 42 compilados, 43 excluidos por política, 691
fuera de esta familia y 1.446 sin ID exacto en la fuente fijada. Los dos últimos
estados no significan roto o ausente en el juego: muchos usan otros sistemas.
Los 874 registros de fuente reconocidos son entradas literales; no se expanden
macros ni se adivinan alias. No es un recuento del catálogo completo de RHH.

## Diseño y límites

`tools/item_import/import_recovery.py` lee texto inerte y exige SHA-256 de tres
fuentes. No ejecuta C/Ruby ni usa eval. Exige IDs exactos sin colisiones y rechaza
expresiones, banderas, rutas y argumentos desconocidos. Condicionales de precio
o texto no deciden efectos; si una ruta depende de un condicional desconocido,
no se compila. No es un traductor general de código.

El manifiesto vive en `modules/inventory/imported_recovery_v19.json`.
FieldItemEffects aplica sobre una criatura candidata; el servicio publica y
consulta si debe consumir. La mochila solo consulta, presenta y solicita.
Los demás sistemas mantienen sus transacciones. Las hierbas amargas usan la
cola de amistad importada y solo pierden amistad tras recuperación real.

Amarilla, Roja y Baya Caquic no se habilitan en campo: la fuente las declara
fuera de ese contexto. Revivir y los demás vetos se apartan antes de convertir.
Mundo, huida, mentas, IV, formas, potenciadores de combate y efectos equipados
requieren sus propias capacidades. Adaptada una familia, sus IDs se procesan
en bloque sin escribir otra conexión por cada objeto.

## Reproducir

Se reutilizan las fuentes fijadas en `.godot/item_mochi_v13/references/`, sin
descargas nuevas. `--source-dir` acepta otra carpeta con los mismos encabezados.

```text
python tools/item_import/import_recovery.py --check
python tests/tools/test_item_import_v19.py
python tools/verification/run_item_import_v19.py
```

`--check` recompila y compara sin escribir. `--write` actualiza exclusivamente el
manifiesto propio y el informe. No regenera el dataset canónico ni políticas.
La generación es determinista; para jugar basta el manifiesto incluido, sin
fuentes externas. No repetir `--prepare` sobre un sello existente.

## Verificación

[ITEM_IMPORT_V19.json](ITEM_IMPORT_V19.json) registra los grupos reales;
[ITEM_IMPORT_V19_AUDIT.json](ITEM_IMPORT_V19_AUDIT.json) clasifica cada ID.
Logs y capturas: `.godot/item_import_v19_validation/runs/`, sin borrar fallos.
El sello preliminar `.godot/item_import_v19/scope_base.json` se conserva; se creó
otro antes de tocar la vista al comprobar que debía explicar el uso sin consumo.
Ningún sello anterior se reescribió.

El lote prueba todos los IDs en equipo/almacén y mochila real: cantidades, estados
correctos/incorrectos, PP, amistad, unidades, original intacto, identidad, bloqueo,
KO, falta de objeto, movimiento inválido, reutilización, guardado/carga y entrada
nativa. Regresiones: medicinas, recuperación, entrenamiento, medicina nativa,
campo/restauración y prueba gráfica. El guard conserva el resto por hash.
Resultado final: **11 grupos PASS**, 2.386 comprobaciones del lote sin ventana,
2.387 en GPU y 10 métodos de prueba del compilador. Las regresiones incluidas
suman 15.776 comprobaciones Godot con el lote y su pasada gráfica. Se revisó la
captura de la mochila: texto de reutilización correcto y dos flautas conservadas.
El guard comprobó 23.044 archivos protegidos con hash de contenido completo.

El primer intento falló por una comparación de tipos en el runner y detectó la
regla de consumo colocada en otra transacción. Ambos se corrigieron antes del
PASS del lote; los intentos fallidos no se contaron como aprobados.
La primera regresión completa detectó además la consulta antigua que distinguía
hierbas/medicina nativa de recuperación adicional. Se conservó ese contrato de
consulta, manteniendo por debajo el ejecutor común; la prueba histórica no cambió.

## Fuentes y créditos

RHH / rh-hideout y colaboradores de **pokeemerald-expansion**, commit
`8654616bd38d9b28cc7dd8f3d0b4cb030aa2d40c`:

- `src/data/items.h`: ruta, objetivo, referencia de efecto y consumo.
- `src/data/pokemon/item_effects.h`: máscaras y argumentos.
- `include/constants/item_effects.h`: significado de máscaras y constantes.

Procedencia y SHA-256 incorporados al manifiesto. Fuente:
[pokeemerald-expansion](https://github.com/rh-hideout/pokeemerald-expansion/tree/8654616bd38d9b28cc7dd8f3d0b4cb030aa2d40c).
Conservar este crédito para los agradecimientos del juego.

Se examinaron también Godot Essentials y Pokémon Essentials locales. La tabla de
uso de objetos por IA de Godot Essentials no se usó como contrato: contiene
heurísticas y diferencias de versión. Los contratos anteriores de medicinas
permanecen inmutables como contraste.
