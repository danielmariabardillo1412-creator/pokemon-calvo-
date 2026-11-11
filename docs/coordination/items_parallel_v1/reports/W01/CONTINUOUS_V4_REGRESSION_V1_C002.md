# IA1/W01 V4 · Regresión histórica adicional en staging IA6

La rama integradora base ya incorpora el motor native held completo y el parche Transformación (blob SHA idéntico W01). La staging tiene además revisiones compartidas IA6 de `CreatureInstance`, `FieldItemService`, `FieldNativeSave` y `FieldItemBag`. Por eso es necesario repetir las **pruebas funcionales con el HEAD staging**, no citar solo CI V2 histórica.

Este workflow ejecuta test W01 held V1 (Chaleco Asalto, Dado Trucado, Banda Focus) y CAMP002 (Escudo Habilidad, Tubérculo Absorbente, Nerviosfera), que ya existen idénticos en staging y source, sin copiar archivos. Cada fase usa los validadores Python completos y los escenarios originales Godot/nativo, con informes y evidencia SaveV2. Sin `continue-on-error`. La cobertura se añade a los tests nuevos de Restos/Baya Zidra/Tabla Draco.

**No declara PASS antes de GitHub Actions**. La fase B V4 necesita comprobar CI y después valorar regresión del resto de CAMP003–005/T01–04 mediante pruebas nuevas o tests incorporados selectivamente, evitando merge completo. Solo tests/workflow en staging; producción, IA6 central y main protegidas.
