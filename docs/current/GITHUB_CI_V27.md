# Compatibilidad de las pruebas CI con V27

Después de publicar el checkpoint `0fa22f1`, los workflows existentes detectaron
dos precondiciones de prueba desactualizadas y un aborto de importación Linux.
La evidencia previa de 22 grupos/12.546 comprobaciones sigue describiendo su alcance;
no era una ejecución de todos los workflows remotos.

- `visual_field_test_runner` y `map_runtime_test_runner` acceden explícitamente
  a la presentación de combate anterior. El workflow ahora selecciona
  `--legacy-field`. No se cambian sus asserts. El modo nativo tiene sus propias
  integraciones y permanece activado normalmente al jugar.
- Las suites V3 conservaban el contrato previo a la reparación de Tyrogue.
  Se actualizan 165→166 registros condicionados, 2→3 relaciones estadísticas
  y la partición 391/149/14→393/147/14. Solo se admiten como excepciones las tres
  rutas exactas de Tyrogue a nivel 20 con relación -1/0/1; se añade un assert de
  exactamente tres y se conservan los siete selectores base_form redundantes.
  Las otras condiciones siguen protegidas. No se modifica EvolutionSystem,
  el adaptador ni datos raw/normalized. No se adapta ninguna evolución por intercambio.
- El workflow de benchmark salió con 134 durante la importación, sin un error de
  GDScript identificado. No se oculta ni se trata como éxito; se observa la nueva
  ejecución remota antes de decidir si requiere otro cambio.

Validación local suplementaria: **4 grupos PASS / 840 comprobaciones**: datos 634,
reparación Tyrogue 58, visual legado 45 y mapa legado 103. Los intentos fallidos
de preparación se conservan en `.godot/publication_v27/ci_followup/`, sin contarlos
como PASS. Resultados: [JSON](GITHUB_CI_V27_RESULTS.json).

La release de recursos fija el checkpoint inicial V27. Para el código actualizado
con estos ajustes de CI, usar la rama `codex/organized-update-v27` y el PR #116.
Los hashes y paquetes visuales no cambian. Descarga pública sin autenticación y
restauración del paquete de referencias comprobadas, 16 archivos PASS.
