#!/usr/bin/env python3
"""Deterministic coordinator for narrow DATA V3 post-stat semantic audits.

The function name is retained for compatibility with the certified call chain. User
families run first; the remaining all-pokemon audit and final DATA_ONLY effect audit
run last and handle only their explicit allowlists.
"""
from __future__ import annotations

import pokeapi_adapter_all_pokemon as all_pokemon
import pokeapi_adapter_final_data_only_effects as final_data_only_effects
import pokeapi_adapter_user_hp_cost as user_hp_cost
import pokeapi_adapter_user_mandatory_state as user_mandatory_state
import pokeapi_adapter_user_persistent_state as user_persistent_state
import pokeapi_adapter_user_terminal_state as user_terminal_state


def apply_user_audits(move: dict, generated: tuple):
    audited = user_hp_cost.apply_user_hp_cost(move, generated)
    audited = user_mandatory_state.apply_user_mandatory_state(move, audited)
    audited = user_persistent_state.apply_user_persistent_state(move, audited)
    audited = user_terminal_state.apply_user_terminal_state(move, audited)
    audited = all_pokemon.apply_all_pokemon(move, audited)
    audited = final_data_only_effects.apply_final_data_only_effects(move, audited)
    return audited
