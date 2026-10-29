# Guardado: tipo de region — 2026-10-29

Correccion autorizada despues de cerrar T001–T006. Un archivo con checksum
correcto y region numerica provocaba una comparacion String/float invalida.
El validador ahora rechaza region ausente o de tipo distinto a String como
`world_shape`. Una region de texto que no corresponde a la posicion conserva
`world_position`. No cambia schema, checksum, RNG ni publicacion de partidas validas.

Pruebas nuevas: region null/bool/int/float/Array/Dictionary/ausente en contrato
nativo y legado y carga real. La carga fallida conserva dueños, equipo, mochila,
relojes, posicion, RNG y referencias; durante combate mantiene el checkpoint y
el worker anterior operativo y libera busy/working. Se comprueba despues que
ese combate sigue aceptando una accion y que una partida valida sigue cargando.

Resultados: contrato 1172 nativo / 1172 legado; integracion 912; guardado V2
40/0; adversarial 8/0. Importacion PASS, sin errores de script. Verificador
arquitectonico completo PASS, 23.063 archivos protegidos y funciones selladas.
Evidencia separada: `docs/kilo/evidence/T006B/save_region_fix_2026-10-29/`.
Se conserva intacta la auditoria anterior de 25 grupos sobre 208c06c0.

Revision adicional del vecino validador: posicion verifica numero y finitud antes
de construir Vector2; config, rng y next_seed comprueban tipos antes del uso.
No se encontro otro fallo concreto de la misma comparacion al revisar esa ruta.
Esto no certifica cualquier entrada arbitraria de todo el juego.
