# Third-party code and assets

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
