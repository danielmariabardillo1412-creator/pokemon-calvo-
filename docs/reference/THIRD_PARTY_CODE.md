# Third-party code and assets

## Inventario de objetos (2026-10-28)

El censo y el piloto usan las definiciones canónicas locales y el runtime MIT
`@pkmn/sim@0.10.11` ya fijado. No se copia otro motor ni se ejecuta código nuevo
de paquetes comunitarios. Se reutilizan los callbacks nativos de 21 equipados
y las clases existentes de inventario/propiedad/guardado.

Se consulta como metadato primario el objeto Max Honey de PokeAPI/api-data,
ID 1630, para confirmar su función revivificadora. Copia de investigación y hash
en `.godot/item_audit_v1/sources/max_honey.json` y `ITEM_FOUNDATION_V1.json`.
Fuente: <https://github.com/PokeAPI/api-data/blob/master/data/api/v2/item/1630/index.json>.
No se incorporan imágenes de objetos ni se elige estilo artístico en esta fase.

## Perfil conjunto de combate (2026-10-28)

Se usa `@pkmn/sim@0.10.11`, derivado de Pokémon Showdown (Guangcong Luo y
colaboradores), licencia MIT. El aviso íntegro del runtime está en
`.godot/battle_reference/runtime/node_modules/@pkmn/sim/LICENSE`; conservarlo
al empaquetar el runtime. Fuente: <https://github.com/smogon/pokemon-showdown>.

`modules/battle/backends/showdown/unified_profile.cjs` es una adaptación propia
acotada sobre ese runtime: registra formatos Gen9 identificados y habilita su
entrada nativa de Dinamax. No copia fórmulas, condiciones ni movimientos de
mods externos. Se conservan el cálculo y los efectos del simulador fijado.

Se inspeccionaron Mega Showdown y Gimme That Gimmick como referencias de
compatibilidad, sin incorporar sus archivos. Sus licencias actuales requieren
permiso para reutilizar/distribuir sus cambios; dar créditos no basta. No se
solicitaron permisos ni se enviaron mensajes. Fuentes inspeccionadas:
<https://github.com/yajatkaul/CobblemonMegaShowdown> y
<https://github.com/Provismet/Gimme-That-Gimmick/blob/master/LICENSE>.
No se añade una dependencia de Minecraft/Cobblemon.

## Prueba visual de ruta (2026-10-18)

Se seleccionan seis sprites PNG de `PokeAPI/sprites` desde la biblioteca local
(3.188 bytes). Se conserva el aviso completo del origen en
`assets/prototype/pokemon/LICENCE.txt`; procedencia, rutas exactas y renombrados
en `assets/prototype/README.md`. El copyright de las imágenes pertenece a The
Pokémon Company según ese aviso. Mapa y personaje son dibujos propios en código
Godot. Las secciones siguientes describen fases históricas previas a estos assets.

## Foundation V1

No se copió, adaptó ni vendorizó código de terceros. Tampoco se añadieron plugins,
addons, fuentes, audio, sprites u otros assets. El runner de tests es propio; GUT no
está incluido.

La implementación fue informada por una auditoría local de estos repositorios MIT,
sin reutilización textual:

| Repositorio de referencia | Commit inspeccionado | Uso |
|---|---|---|
| Pokerecomp | `9325ece0ef3537fd2739f6eb6cd68232dd904a30` | Separación conceptual de lógica de batalla y tests |
| Pokemon Battle | `45849e7226a1deb5504e0029788f1b4aad7a8afd` | Referencia conceptual de FSM |
| PokemonGodWhite | `fba69f1710f3d41e6e367539e8e9adb2ab4e551d` | Lecciones de estructura y deuda de autoloads |
| Pokemon FireLeaf | `fe3a84cce2ddc01207375adbd48463a8ca6ec2cc` | Referencia futura de overworld |
| Snowdon Engine | `5daf14ed80ac8b0af8b8aefaf1115a779dba368e` | Solo auditoría histórica |

Godot Engine 4.7 se usa como runtime externo y no está incluido en el repositorio.

Los nombres y datos de Foundation (`Embercub`, `Leafling`, `Strike`, etc.) son
placeholders originales. No hay especies, sprites ni assets propietarios de Pokémon.
Si en el futuro se reutiliza código, este documento deberá registrar repositorio,
commit, archivo, licencia y modificaciones exactas antes de integrar el commit.

## Battle Core V2

No se copió ni adaptó código externo. Pokerecomp no fue consultado durante esta
implementación V2. Los patrones de effects, ruleset, triggers y tests son código
original del proyecto. El dataset PokéAPI ya versionado sigue siendo datos BSD
3-Clause y no código reutilizado por Battle Core.
