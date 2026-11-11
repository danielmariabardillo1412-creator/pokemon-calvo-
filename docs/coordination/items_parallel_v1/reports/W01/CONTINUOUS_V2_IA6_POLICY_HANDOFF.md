# W01 · Guard IA6 posterior al SHA de la CI integral

IA6 publicó en esta misma rama los commits `67ad6e18f8b2936e61111518b516b8a722034584`, `7159b919782e60b8ff7c91570313e94b2ee44021`, `a2bce1ce9bb9b52ca49bf110c0187b0d0ea28f5c`, que vetan únicamente `dynamax_candy`. Fueron posteriores al SHA funcional `dead5a21679c0aa8f635f3ce12fce0279ada0fc0` de la CI integral #42958587809.

El diff comprobado de esos tres commits modifica exclusivamente `config/item_selection_v1.json`, `docs/coordination/items_parallel_v1/IA6_AUTORUN.md` y `tests/gameplay/item_selection_policy_test_runner.gd`. No modifica ninguno de los 36 IDs de W01 ni su pipeline de batalla.

Esta CI W01 ejecuta Python y el validador Godot real de selección para el HEAD nuevo. El veto no se extiende a Rare Candy o Exp Candy. **No reemplaza la CI de 38 jobs** ni autoriza READY_FOR_IA6 hasta sus 38/38, el ledger final verde y la integración independiente de IA6. Ningún archivo de producción o política perteneciente a IA6 se altera aquí.
