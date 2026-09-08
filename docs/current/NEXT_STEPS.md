# SIGUIENTE TRABAJO

## Paso inmediato — consolidar `main`

La línea moderna está cerrada y certificada en:

`8552f52158ffc21c27b4e8f1dbc7caa63ac1a467`

La operación separada de promoción vive en:

`chore/main-baseline-consolidation-v1`

Merge histórico inicial:

`2f63312e8dc3e61c8fadbd02e97972fff6d0eacc`

Ese commit conserva como padres la antigua `main` y el freeze moderno, pero usa exactamente el árbol moderno certificado; el único commit exclusivo de la `main` antigua añadía un archivo vacío sin funcionalidad.

Para cerrar la promoción:

1. terminar la actualización documental de esta rama;
2. abrir PR contra `main` para disparar la matriz normal;
3. exigir **18/18 workflows SUCCESS** sobre el HEAD final exacto;
4. comprobar que no existe regresión funcional;
5. mover `main` por fast-forward al HEAD certificado de la rama;
6. cerrar el PR de consolidación sin crear un SHA adicional no certificado;
7. desde ese momento, `main` vuelve a ser el baseline de desarrollo normal.

No introducir features nuevas dentro de esta operación.

## Después — Game Foundation V1

Trainer AI ya no tiene trabajo obligatorio pendiente. El siguiente workstream de producto debe ser **Game Foundation V1**.

### Objetivo

Llegar a una primera mini-campaña jugable real, aunque use arte provisional, que demuestre el flujo:

`nueva partida -> inicial -> mapa/pueblo -> ruta -> encuentro/captura -> entrenador -> servicio -> guardar -> cargar -> continuar`

### Orden de construcción

1. **GF1-A — Game State + contrato de campaña**
   - identidad de partida;
   - mapa actual / spawn point;
   - flags de historia;
   - entrenadores derrotados;
   - inicial escogido;
   - progreso mínimo de campaña.

2. **GF1-B — mapas y transiciones**
   - mapas configurables;
   - puertas/warps;
   - spawn points;
   - zonas de encuentro;
   - triggers de entrenador/NPC.

3. **GF1-C — NPC, diálogo y eventos data-driven**
   - diálogo;
   - condiciones por flags;
   - acciones/eventos;
   - entrenador una vez / diálogo posterior;
   - objetos o desbloqueos simples.

4. **GF1-D — Save V3 de mundo/campaña**
   - extender el save sin romper identidad de criaturas;
   - persistir posición/mapa/flags/entrenadores/progreso;
   - carga transaccional y migración explícita desde V2.

5. **GF1-E — servicios y UI mínima**
   - curación;
   - tienda;
   - acceso a PC/storage;
   - party/bolsa básicas;
   - menús suficientes para la vertical slice.

6. **GF1-F — vertical slice de campaña**
   - escena inicial;
   - elección de inicial;
   - primer pueblo;
   - primera ruta;
   - encuentro salvaje y captura;
   - entrenador real con Trainer AI;
   - servicio de curación/tienda;
   - save/load E2E.

Cada tramo debe quedar importable, probado y certificado antes del siguiente. El arte final no bloquea esta fase.

## Después de Game Foundation V1

Solo cuando exista esa mini-campaña estable tiene sentido abrir workstreams separados para:

- rival autónomo de overworld/campaña;
- más mapas, gimnasios e historia;
- arte/sprites/audio final;
- ampliar mecánicas Pokémon concretas exigidas por el contenido;
- builds/distribución.

No reabrir DATA V3 ni Trainer AI por inercia.
