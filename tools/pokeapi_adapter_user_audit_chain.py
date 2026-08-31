#!/usr/bin/env python3
"""Deterministic coordinator for narrow DATA V3 user-target semantic audits."""
from __future__ import annotations

import pokeapi_adapter_user_hp_cost as user_hp_cost
import pokeapi_adapter_user_mandatory_state as user_mandatory_state
import pokeapi_adapter_user_persistent_state as user_persistent_state


def apply_user_audits(move: dict, generated: tuple):
    audited = user_hp_cost.apply_user_hp_cost(move, generated)
    audited = user_mandatory_state.apply_user_mandatory_state(move, audited)
    audited = user_persistent_state.apply_user_persistent_state(move, audited)
    return audited
